/**************************************************************************************************
 * Class Name: SubmissionTriggerHandler_CEL
 * Author: 
 * Date: 
 * Description: Class to keep Celerity related methods
 * Test Class: OpportunityTriggerHandlerTest
 **************************************************************************************************/
public class SubmissionTriggerHandler_CEL extends TriggerHandler {
    private List<Opportunity> oldDataList;
    private List<Opportunity> newDataList; 
    private Map<Id, Opportunity> newDataMap;
    private Map<Id, Opportunity> oldDataMap;
    public static final String DEFAULT_SUBMISSION_NAME_FOR_PCC = System.Label.DEFAULT_SUBMISSION_NAME_PCC; 
    
    public SubmissionTriggerHandler_CEL(List<Opportunity> newDataList, List<Opportunity> oldDataList, 
                                         Map<Id, Opportunity> newDataMap, Map<Id, Opportunity> oldDataMap){
                                             this.oldDataList = oldDataList;
                                             this.newDataList = newDataList;
                                             this.newDataMap = newDataMap;
                                             this.oldDataMap = oldDataMap;
                                         } 
 
    public override void beforeInsert(){
        //Generate Azure Id for Submission
        CommonUtil.generateExternalID('Azure_Id__c', newDataList);

        //Update fields in Submission from Account details.
        SubmissionTriggerHandler_Common.updateDnbInfoFromAccount(newDataList);

        //Generate name for Submission
        SubmissionTriggerHandler_Common.generateOpportunityName(newDataList,oldDataMap);
    }
    
    public override void beforeUpdate(){
        List<Opportunity> updateList = new List<Opportunity>();
        List<String> deleteExistingUWOppIds = new List<String>();

        for (Opportunity obj : newDataList){
            if (obj.Product__c != oldDataMap.get(obj.Id).Product__c) updateList.add(obj);
        }

        // Added for US:52315 
        if(!newDataList.isEmpty()){
            //CLoded reason reset when Submission stage changed to 'Declined'
            resetClosedReason(newDataList, oldDataMap);
        }      

        //Generate new submission name even for update.
        SubmissionTriggerHandler_Common.generateOpportunityName(newDataList,oldDataMap);

        //Generate Azure Id for Submission
        CommonUtil.generateExternalID('Azure_Id__c', newDataList);

        //Logic to update expiration date value.
        SubmissionTriggerHandler_Common.updateExpirationDate(newDataList, oldDataMap);
        
        //When value of object AccountClearance is Closed Market, StageName change is New
        //Is this method needed?
        SubmissionTriggerHandler_Common.accountClearancetoStagechange(newDataList);
        
        //Check if this method is needed for CEL?
        //validateQuotedOpportunity(newDataList,oldDataMap);
    }
    
    public override void afterInsert(){
        //Recreate newDataMap to include related fields
        this.newDataMap = SubmissionTriggerHandler_Common.createNewDataMap(this.newDataList);

        //Generate rating modifiers for submission.
        SubmissionTriggerHandler_Common.AddRatingModifier(this.newDataMap.values());

        //Create quote process object for submission if doesnt exist.
        SubmissionTriggerHandler_Common.createQuoteProcess(newDataList);

        //Create submission loss detail record for submission.(Check its purpose for CEl and AQ)
        SubmissionTriggerHandler_Common.addSubmissionLostDetail(newDataMap);

        //Update rating modifiers for PCC.
        CommonUtil.updateRatingModifiersForOpps(this.newDataMap, this.oldDataMap);
        validateSanctionCheckOnExistingAccount(newDataList);
    }
    
    public override void afterUpdate(){
        //Recreate newDataMap to include related fields
        this.newDataMap = SubmissionTriggerHandler_Common.createNewDataMap(this.newDataList);
        List<Opportunity> celeritOpp = new List<Opportunity>();
        
        //Check to see if product or coverage products have changed.
        List<Opportunity> items = getChangedOpportunities(this.newDataMap.values());
        for(Opportunity op: items){
            celeritOpp.add(op);
        }

        //Update Rating Modifiers for submission
        updateRatingModifier(celeritOpp);
        
        //Update rating Modifiers with Name ='Service Classification'. (is it needed for AQ?)
        SubmissionTriggerHandler_Common.updateServiceClassificationRattingModifiers((Map<Id, Opportunity>)Trigger.newMap,oldDataMap);
        
        //Logic to update quote status to In progress when submission is edited.
        updateQuotesToInProgress((Map<Id, Opportunity>)Trigger.newMap,oldDataMap);

        //When StageName is Unqualified to Close all the Quote associated with the Submission
        SubmissionTriggerHandler_Common.stageUnqualifiedCloseAllQuote(newDataList, oldDataMap);
        
        //When Stage is decline then update related quote status to rejected
        if(!newDataList.isEmpty()){
           UpdateRelatedQuoteStatus(newDataList); 
        }
         //Update rating modifiers for PCC
         CommonUtil.updateRatingModifiersForOpps(this.newDataMap, this.oldDataMap);
 
         //Method to delete product option lines when account changed on submission.
         updateProductOptionLines();
         SubmissionTriggerHandler_Common.updateOpenQuoteForDeclinedSub(newDataList);
    }
    
    
    public override void beforeDelete(){
        //Delete associated quote process record when submission deleted
        SubmissionTriggerHandler_Common.deleteQuoteProcess(this.oldDataMap);
    }
    
   
 
    /*************************************************
    * Method Name: resetClosedReason
    * Author: 
    * Date: 
    * Params: List<Opportunity> newList, Map<Id, Opportunity> oldMap
    * Return: 
    * Exceptions:
    * Description: update submission loss reason.
    * Revision: 
     *************************************************/
    public static void resetClosedReason(List<Opportunity> newList, Map<Id, Opportunity> oldMap){ 
        for(Opportunity opp : newList){
            if(oldMap.get(opp.id).StageName != opp.StageName && oldMap.get(opp.id).StageName == 'Declined'){
                opp.Loss_Reason__c = null;
            }
        }
    }
    
     /*************************************************
    * Method Name: updateQuotesToInProgress
    * Author: 
    * Date: 
    * Params: Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap
    * Return: 
    * Exceptions:
    * Description: Logic to update quote status to In progress when submission is edited.
    * Revision: 
     *************************************************/
    public static void updateQuotesToInProgress(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap){ 
        System.debug('inprogress newMap'+newMap);
        try { 
            Map<Id, Opportunity> opportunityIdsToUpdateQuotes = new Map<Id, Opportunity>();
            for(Id recordId : newMap.keyset()){
                Opportunity newOpp = newMap.get(recordId);
                Opportunity oldOpp = oldMap.get(recordId);
                if(newOpp.Innovisk_Entity_ID__c == 'Celerity' && newOpp.StageName == 'Bound Pending'){
                    List<SectionSetting__c> sourceFieldAPIs = SectionSettingsQueryUtil.fetchCeleritySubmissionInfoSettings();
                    
                    for (SectionSetting__c section : sourceFieldAPIs) {
                        String str = section.Source_Field_API__c;
                        if(str != 'Retroactive_Date__c' && str != 'Retroactive_Date_Docs__c' && str != 'Effective_Date_Docs__c' && str != 'StageName'){
                            if(newOpp.get(str) != oldOpp.get(str)){
                                opportunityIdsToUpdateQuotes.put(newOpp.Id, newOpp);
                            } 
                        }                   
                    }
                }
            }
            if(opportunityIdsToUpdateQuotes.size()>0 ){
                Set<String> statusQts = new Set<String>{'Rated', 'Referred', 'Quoted', 'Presented', 'Bound Pending'};
                    List<Quote> quotes = QuoteQueryUtil.fetchQuotesForOppsAndStatus(opportunityIdsToUpdateQuotes.keySet(), statusQts);
                List<Quote> updateQuotes = new List<Quote>();
                for(Opportunity opp : opportunityIdsToUpdateQuotes.values()){
                    for(Quote q: quotes) {
                        if(q.OpportunityId == opp.Id && q.Status == 'Bound Pending') {
                            q.Status = 'In Progress';
                            updateQuotes.add(q);
                        }
                    }
                }       
                if(!updateQuotes.isEmpty())	 update updateQuotes;
            }
        } catch (Exception e) { 
            System.debug('Error: ' + e); 
        } 
    }

    
    //Keeping this method for both CEL and AQ in their respective classes as logic could change
    /*************************************************
    * Method Name: getChangedOpportunities
    * Author: 
    * Date: 
    * Params: List<Opportunity> items
    * Return: 
    * Exceptions:
    * Description: Get opportunities when product changed
    * Revision: 
     *************************************************/
    private List<Opportunity> getChangedOpportunities(List<Opportunity> items){
        List<Opportunity> result = new List<Opportunity>();
        for (Opportunity item : items){
            if (isProductChanged(item.Id))
                result.add(item);
        }
        return result;
    }
    
     /*************************************************
    * Method Name: isProductChanged
    * Author: 
    * Date: 
    * Params: String id
    * Return: 
    * Exceptions:
    * Description: Logic to check if Submission products changed.
    * Revision: 
     *************************************************/
    private boolean isProductChanged(String id){
        Opportunity oldItem = this.oldDataMap.get(id);
        Opportunity newItem = this.newDataMap.get(id);
        if (oldItem == null || newItem == null) return false;
        if (oldItem.Product__c != newItem.Product__c || oldItem.Coverage_Product_Options__c != newItem.Coverage_Product_Options__c){
            return true;
        }			
        return false;
    }
    
   /*************************************************
    * Method Name: updateRatingModifier
    * Author: 
    * Date: 
    * Params: List<Opportunity> opps
    * Return: 
    * Exceptions:
    * Description: update rating modifiers for submission.
    * Revision: 
     *************************************************/
    private void updateRatingModifier(List<Opportunity> opps){
        List<Rating_Modifier_Template__c> templates = new List<Rating_Modifier_Template__c>();
        Map<String, List<Rating_Modifier_Template__c>> templateMap = new Map<String, List<Rating_Modifier_Template__c>>();
        List<Rating_Modifiers__c> existedModifiers = new List<Rating_Modifiers__c>();
        List<Rating_Modifiers__c> newModifiers = new List<Rating_Modifiers__c>();
        List<Rating_Modifiers__c> deleteModifiers = new List<Rating_Modifiers__c>();
        // create a save point in case something is wrong during DML process
        Savepoint sp = Database.setSavepoint();
        try{
            if (opps == null || opps.isEmpty())
                return;
            List<String> products = SubmissionTriggerHandler_Common.getAllProductOptions(opps);
            //there is no products
            if (products.isEmpty())
                return;
            templates = CommonUtil.getRatingTemplatesByProducts(products);
            // no templates is found
            if (templates.isEmpty())
                return;
            // store all template in map to reduce soql query
            templateMap = SubmissionTriggerHandler_Common.generateTemplateMap(templates);
            List<Rating_Modifier_Template__c> newTemplates = new List<Rating_Modifier_Template__c>();
            // put opportunities into map to get its id set
            Map<String, Opportunity> oppMap = SubmissionTriggerHandler_Common.generateOppMap(opps);           
            // get existed rating modifiers
            existedModifiers = CommonUtil.getRatingModifiersByOppIds(oppMap.keySet());
            // get existed products
            List<String> existedProducts = SubmissionTriggerHandler_Common.getAllProductOptions(existedModifiers);
            // get removed products
            List<String> removedProducts = getRemovedItems(existedProducts, products);
            // get ratings modifiers for deleting
            deleteModifiers = generateModifiersForDelete(existedModifiers, removedProducts);
            // get template for inserting
            Map<String, List<Rating_Modifier_Template__c>> insertTemplateMap = getTemplateForInsert(templateMap, existedProducts);
            // generate new rating modifiers
            newModifiers = SubmissionTriggerHandler_Common.generateModifiersForInsert(insertTemplateMap, opps);
            insert newModifiers;
            delete deleteModifiers;
        } catch (Exception ex){
            // rollback data
            Database.rollback(sp);
            String errorMsg = 'Failed to update Rating Modifiers.<br/>Please contact your administators.';
            for (Opportunity opp : (List<Opportunity>)Trigger.new){
                opp.addError(errorMsg);
            }
        }
    }
 
    
    /*************************************************
    * Method Name: generateModifiersForDelete
    * Author: 
    * Date: 
    * Params: List<Rating_Modifiers__c> items, List<String> products
    * Return: 
    * Exceptions:
    * Description: get rating modifiers to be deleted
    * Revision: 
     *************************************************/
    private List<Rating_Modifiers__c> generateModifiersForDelete(List<Rating_Modifiers__c> items, List<String> products){
        List<Rating_Modifiers__c> result = new List<Rating_Modifiers__c>();
        try{
            for (Rating_Modifiers__c item : items){
                if (!products.contains(item.Product__c))
                    continue;
                result.add(item);
            }
        } catch (Exception ex){
            result.clear();
        }
        return result;
    }
    
   /*************************************************
    * Method Name: getRemovedItems
    * Author: 
    * Date: 
    * Params: List<String> oldItems, List<String> newItems
    * Return: 
    * Exceptions:
    * Description: util method to get removed items from list
    * Revision: 
     *************************************************/
    private List<String> getRemovedItems(List<String> oldItems, List<String> newItems){
        List<String> result = new List<String>();
        try{
            Set<String> oldSet = new Set<String>(oldItems);
            oldSet.removeAll(newItems);
            result = new List<String>(oldSet);
        } catch (Exception ex){
        }
        return result;
    }
    
    /*************************************************
    * Method Name: getTemplateForInsert
    * Author: 
    * Date: 
    * Params: Map<String, List<Rating_Modifier_Template__c>> obj, List<String> products
    * Return: 
    * Exceptions:
    * Description: Get rating modifier template for insert.
    * Revision: 
     *************************************************/
    private Map<String, List<Rating_Modifier_Template__c>> getTemplateForInsert(Map<String, List<Rating_Modifier_Template__c>> obj, List<String> products){
        Map<String, List<Rating_Modifier_Template__c>> result = new Map<String, List<Rating_Modifier_Template__c>>();
        result = obj.clone();
        for (String item : products){
            result.remove(item);
        }
        return result;
    }

    //TRO- AQ?
    // private static void updateClosedWonSubmissions(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap){
    //     List<String> closeQuoteStatus = new List<String>{'Bound', 'Bound Pending', 'Closed'};
    //         Set<Id> closedWonIds = new Set<Id>();
    //     Set<Id> boundOppsIds = new Set<Id>();
    //     Set<Id> boundInWaitOppsIds = new Set<Id>();
    //     for(Opportunity opp: newOpps){
    //         if(opp.StageName == 'Closed Won' && oldMap.get(opp.Id).StageName != 'Closed Won' && opp.Product_Name__c == 'Professional Indemnity'){
    //             closedWonIds.add(opp.Id);
    //         }
    //     }
    //     Map<Id, List<Quote>> quoteOppMap = new Map<Id, List<Quote>>();
    //     for(ID oppID: closedWonIds){
    //         quoteOppMap.put(oppID, [SELECT Id, Status,OpportunityId FROM Quote where OpportunityId =: oppID AND Status NOT IN: closeQuoteStatus]);
    //     }
    //     System.debug('quoteOppMap -->'+quoteOppMap);
    //     for(ID oppId: quoteOppMap.keyset()){
    //         if(quoteOppMap.get(oppId).size() == 0){
    //             boundOppsIds.add(oppId);
    //         }
    //         else{
    //             boundInWaitOppsIds.add(oppId);
    //         }
    //     }
    //     List<Opportunity> oppsToUpdate = new List<Opportunity>();
    //     //Update Opportunities To Bound
    //     if(!boundOppsIds.isEmpty())
    //         for(Opportunity opp: [Select Id, Submission_Status__c from Opportunity where ID IN:boundOppsIds]){
    //             if(opp.Submission_Status__c != 'Bound'){
    //                 opp.Submission_Status__c = 'Bound';
    //             }
    //             oppsToUpdate.add(opp);
    //         }
    //     //Update Opportunities To Bound - In Waiting
    //     if(!boundInWaitOppsIds.isEmpty())
    //         for(Opportunity opp: [Select Id, Submission_Status__c from Opportunity where ID IN:boundInWaitOppsIds]){
    //             if(opp.Submission_Status__c != 'Bound - In Waiting'){
    //                 opp.Submission_Status__c = 'Bound - In Waiting';
    //             }
    //             oppsToUpdate.add(opp);
    //         }
        
    //     if(oppsToUpdate.size() > 0){
    //         update oppsToUpdate;
    //     }
    // }
    
     /*************************************************
    * Method Name: UpdateRelatedQuoteStatus
    * Author: 
    * Date: 
    * Params: List<Opportunity> OppListNew
    * Return: 
    * Exceptions:
    * Description: update related quote status when submission updated
    * Revision: 
     *************************************************/
    public static void UpdateRelatedQuoteStatus(List<Opportunity> OppListNew ){
        Set<Id> ValidId = new Set<Id>();
        List<Quote> QuoteUpdate = new List<Quote>();
        for(Opportunity op : OppListNew){
            if(op.StageName =='Declined'){
                ValidId.add(op.Id);
            }
        }
        list<Opportunity> Opplist = OpportunityQueryUtil.fetchSubmissionsWithRelatedQuotes(validId);
        for(Opportunity opp : Opplist){
            for(Quote q : opp.Quotes){
                q.Status='Rejected';
                QuoteUpdate.add(q);
            }
        }
        if(!QuoteUpdate.isEmpty()){
            //Added by Ashik on 27-July-2021
            GlobalStaticVar.byPassQuoteTrigger = true;
            update QuoteUpdate;
            GlobalStaticVar.byPassQuoteTrigger = false;
            ID jobID = System.enqueueJob(new SyncQuoteQueueable(QuoteUpdate));
        }
        
    }
    
    /**
    * @description : Delete POLI for opportunities where account is updated.
    * @author Vinayesh | 07-22-2021 
    **/
    private void updateProductOptionLines(){
    /* Currently not deleting POLI for account change on submission. */
    
        // Set<Id> changedOpps = new Set<Id>();
        // for(Opportunity opp: newDataMap.values()){
        //     if(oldDataMap.get(opp.Id).AccountId != opp.AccountId){
        //         changedOpps.add(opp.Id);
        //     }
        // }

        // if(changedOpps.size() > 0){
        //     List<Product_Option_Line_Item__c> poliRecList =  [SELECT Id From Product_Option_Line_Item__c
        //                                                       Where Submission__c In :changedOpps];
        //     if(poliRecList.size() > 0){
        //         delete poliRecList;
        //     }
        // }
       
    }
    public static void validateSanctionCheckOnExistingAccount(List<Opportunity> newList){
        Set<Id> setOfAccountIds = new Set<Id>();
        for(Opportunity objOpp: newList){
            if(objOpp.AccountId != null){
                setOfAccountIds.add(objOpp.AccountId);
            }
        }
        List<Sanction_Status__c> sanctionStatus = new List<Sanction_Status__c>();
        List<Account> lstAccount = [SELECT Id, OwnerId, AQ_Sanction_Status__c, CEL_Sanction_Status__c, BillingCountryCode, Action_Point__c FROM Account WHERE Id IN: setOfAccountIds];
        if(!lstAccount.isEmpty()){
           sanctionStatus = CommonAccountUtil.validateSanctionCheckOnInsert(lstAccount, false);
        }
    }
}