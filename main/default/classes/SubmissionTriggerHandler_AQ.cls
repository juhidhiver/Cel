/**************************************************************************************************
 * Class Name: SubmissionTriggerHandler_AQ
 * Author: 
 * Date: 
 * Description: Class to keep Aqueous related methods
 * Test Class: OpportunityTriggerHandlerTest
 **************************************************************************************************/
public class SubmissionTriggerHandler_AQ extends TriggerHandler {
    private List<Opportunity> oldDataList;
    private List<Opportunity> newDataList; 
    private Map<Id, Opportunity> newDataMap;
    private Map<Id, Opportunity> oldDataMap;
    
    public SubmissionTriggerHandler_AQ(List<Opportunity> newDataList, List<Opportunity> oldDataList, 
                                         Map<Id, Opportunity> newDataMap, Map<Id, Opportunity> oldDataMap){
                                             this.oldDataList = oldDataList;
                                             this.newDataList = newDataList;
                                             this.newDataMap = newDataMap;
                                             this.oldDataMap = oldDataMap;
                                         }  


    public override void beforeInsert(){
       //Generate Azure Id for Submission
       CommonUtil.generateExternalID('Azure_Id__c', newDataList);

       //Update fields in Submission from Account details(Is it needed for AQ?)
       SubmissionTriggerHandler_Common.updateDnbInfoFromAccount(newDataList);
       
       //Generate name for Submission
       //SubmissionTriggerHandler_Common.generateOpportunityName(newDataList, oldDataMap);
        
       //Update submission tax country
       if(!newDataList.isEmpty()) updateAQTaxCountry(newDataList);
    }
    
    public override void beforeUpdate(){
        
        List<Opportunity> updateList = new List<Opportunity>();
        List<String> deleteExistingUWOppIds = new List<String>();

        for (Opportunity obj : newDataList){
            if (obj.Product__c != oldDataMap.get(obj.Id).Product__c) updateList.add(obj);
            if (obj.Main_Profession__c != oldDataMap.get(obj.Id).Main_Profession__c){
                deleteExistingUWOppIds.add(obj.Id);                
            }
        }    
        
        //Delete UW analysis records for Submission
        deleteExistingUWAnalysis(deleteExistingUWOppIds);

        //Generate new submission name even for update.
        SubmissionTriggerHandler_Common.generateOpportunityName(newDataList, oldDataMap);

        //Generate Azure Id for Submission
        CommonUtil.generateExternalID('Azure_Id__c', newDataList);
 
        //Logic to update expiration date value.
        SubmissionTriggerHandler_Common.updateExpirationDate(newDataList, oldDataMap);
        
        //When value of object AccountClearance is Closed Market, StageName change is New
        //Is this method needed?
        SubmissionTriggerHandler_Common.accountClearancetoStagechange(newDataList);
        
        //Validation for status update of quoted submission
        validateQuotedOpportunity(newDataList,oldDataMap);
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

        //Create UW analysis records for submission.
        createUWAnalysis(this.newDataMap.values(), false);
    }
    
    public override void afterUpdate(){
       
        //Recreate newDataMap to include related fields
        this.newDataMap = SubmissionTriggerHandler_Common.createNewDataMap(this.newDataList);
        List<Opportunity> AQPIOpp = new List<Opportunity>();
        
        //Check to see if product or coverage products have changed.
        List<Opportunity> items = getChangedOpportunities(this.newDataMap.values());
        for(Opportunity op: items){
            AQPIOpp.add(op);
        }

        //Update rating modifiers
        if(!AQPIOpp.isEmpty()) updateRatingModifierForAQPI(AQPIOpp);
        //Update policy wording docs.
        if(!AQPIOpp.isEmpty())	updatePolicyWordingDocs(this.newDataMap.values(), oldDataMap);	//Opp Ids used to update related quote's Policy Wording
       
        //Update rating Modifiers with Name ='Service Classification'. (is it needed for AQ?)
        SubmissionTriggerHandler_Common.updateServiceClassificationRattingModifiers((Map<Id, Opportunity>)Trigger.newMap,oldDataMap);


        //When StageName is Unqualified to Close all the Quote associated with the Submission. Is CEL or AQ?Check method.
        SubmissionTriggerHandler_Common.stageUnqualifiedCloseAllQuote(newDataList, oldDataMap);

        //Create UW Analysis records on submission update.
        createUWAnalysisAfterUpdate(this.newDataMap.values(), oldDataMap);

        //Update Status of Closed won submissions
        updateClosedWonSubmissions(newDataList, oldDataMap);
        
         if(!newDataList.isEmpty()){
            //When Submission Stage is decline then update related quote status
            UpdateRelatedQuoteStatusAQ(newDataList, oldDataMap);
         }
         //SubmissionTriggerHandler_Common.updateOpenQuoteForDeclinedSub(newDataList);
    }
    
    
    public override void beforeDelete(){
        //Delete associated quote process record when submission deleted
        SubmissionTriggerHandler_Common.deleteQuoteProcess(this.oldDataMap);
    }
    
    //Commneted because only celerity is using this.
    // public static void updateQuotesToInProgress(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap){ 
    //     System.debug('inprogress newMap'+newMap);
    //     try { 
    //         Map<Id, Opportunity> opportunityIdsToUpdateQuotes = new Map<Id, Opportunity>();
    //         for(Id recordId : newMap.keyset()){
    //             Opportunity newOpp = newMap.get(recordId);
    //             Opportunity oldOpp = oldMap.get(recordId);
    //             if(newOpp.Innovisk_Entity_ID__c == 'Celerity' && newOpp.StageName == 'Bound Pending'){
    //                 List<SectionSetting__c> sourceFieldAPIs = [SELECT Id,Source_Field_API__c FROM SectionSetting__c 
    //                                                            WHERE Component__c = 'Submission Info' AND Main_Section__c != 'Broker Account'
    //                                                            AND Record_Type__c = 'Celerity' And Source_Object__c = 'Opportunity'
    //                                                            And Profile_Name_for_Read_Only__c =null/* ORDER BY Order__c ASC*/];
                    
    //                 for (SectionSetting__c section : sourceFieldAPIs) {
    //                     String str = section.Source_Field_API__c;
    //                     if(str != 'Retroactive_Date__c' && str != 'Retroactive_Date_Docs__c' && str != 'Effective_Date_Docs__c' && str != 'StageName'){
    //                         if(newOpp.get(str) != oldOpp.get(str)){
    //                             opportunityIdsToUpdateQuotes.put(newOpp.Id, newOpp);
    //                         } 
    //                     }                   
    //                 }
    //             }
    //         }
    //         if(opportunityIdsToUpdateQuotes.size()>0 ){
    //             Set<String> statusQts = new Set<String>{'Rated', 'Referred', 'Quoted', 'Presented', 'Bound Pending'};
    //                 List<Quote> quotes = [Select Id,Status, Product_Name__c, OpportunityId From Quote Where OpportunityId IN :opportunityIdsToUpdateQuotes.keySet() And Status IN: statusQts]; 
    //             List<Quote> updateQuotes = new List<Quote>();
    //             for(Opportunity opp : opportunityIdsToUpdateQuotes.values()){
    //                 for(Quote q: quotes) {
    //                     if(q.OpportunityId == opp.Id && q.Status == 'Bound Pending') {
    //                         q.Status = 'In Progress';
    //                         updateQuotes.add(q);
    //                     }
    //                 }
    //             }       
    //             if(!updateQuotes.isEmpty())	 update updateQuotes;
    //         }
    //     } catch (Exception e) { 
    //         System.debug('Error: ' + e); 
    //     } 
    // }
    
    /*************************************************
    * Method Name: getChangedOpportunities
    * Author: 
    * Date: 
    * Params: List<Opportunity> items
    * Return: 
    * Exceptions:
    * Description: Check to see if product or coverage products have changed.
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
        if(oldItem.Innovisk_Entity_ID__c == 'Aqueous'){
            if(oldItem.Main_Profession__c != newItem.Main_Profession__c){
                return true;
            }
        }else if (oldItem.Product__c != newItem.Product__c || oldItem.Coverage_Product_Options__c != newItem.Coverage_Product_Options__c){
            return true;
        }			
        return false;
    }

    /*************************************************
    * Method Name: generateOppMap
    * Author: 
    * Date: 
    * Params: List<Opportunity> items
    * Return: 
    * Exceptions:
    * Description: Generated Submission Id Map
    * Revision: 
     *************************************************/
    private Map<String, Opportunity> generateOppMap(List<Opportunity> items){
        Map<String, Opportunity> result = new Map<String, Opportunity>();
        if (items.isEmpty())
            return result;
        for (Opportunity item : items){
            result.put(item.Id, item);
        }
        return result;
    }

   /*************************************************
    * Method Name: createUWAnalysis
    * Author: 
    * Date: 
    * Params: List<Opportunity> opps, Boolean isUpdate
    * Return: 
    * Exceptions:
    * Description: Create UW records for Submission
    * Revision: 
     *************************************************/
    private static void createUWAnalysis(List<Opportunity> opps, Boolean isUpdate){
        List<String> oppMainProfession = new List<String>{'Territory','D&C Turnover Split'};
            if(isUpdate) oppMainProfession.remove(0);
        List<UW_Analysis_Template__c> uwTempTerritory = new List<UW_Analysis_Template__c>();
        List<UW_Analysis_Template__c> uwTempTerritoryAndDC = new List<UW_Analysis_Template__c>();
        List<UW_Analysis__c> uwAnalysisListToInsert= new List<UW_Analysis__c>();
        for(UW_Analysis_Template__c uwTemp : UWAnalysisTemplateQueryUtil.fetchUWAnalysisTemplatesByCriteria(oppMainProfession))
        {
            if(uwTemp.Criteria__c == 'Territory'){
                uwTempTerritory.add(uwTemp);
            }
            uwTempTerritoryAndDC.add(uwTemp);
        }
        
        system.debug('uwTempTerritory== '+uwTempTerritory);
        system.debug('uwTempTerritoryAndDC== '+uwTempTerritoryAndDC);
        for(Opportunity opp : opps){
            if(opp.Product_Name__c == 'Professional Indemnity' && opp.Main_Profession__c != null){
                if(opp.Main_Profession__c == 'Design & Construct' && !uwTempTerritoryAndDC.isEmpty()){
                    for(UW_Analysis_Template__c uwTemp:uwTempTerritoryAndDC){
                        UW_Analysis__c uwAnalysis = new UW_Analysis__c ();
                        uwAnalysis.UW_Analysis_Name__c = uwTemp.UW_Analysis_Name__c;
                        uwAnalysis.Criteria__c = uwTemp.Criteria__c;
                        uwAnalysis.UW_Analysis_Code__c = uwTemp.UW_Analysis_Code__c;
                        uwAnalysis.Rating_Factor__c = uwTemp.Rating_Factor__c;
                        uwAnalysis.Sort_Order__c = uwTemp.Sort_Order__c;
                        uwAnalysis.Submission__c = opp.Id;
                        uwAnalysis.UW_Analysis_Template__c = uwTemp.Id;
                        uwAnalysis.Split_Percentage__c = uwTemp.Default_Split_Percentage__c;
                        uwAnalysis.Amount__c = 0;
                        uwAnalysisListToInsert.add(uwAnalysis);
                    }
                }else{
                    if(!uwTempTerritory.isEmpty()){
                        for(UW_Analysis_Template__c uwTemp:uwTempTerritory){
                            UW_Analysis__c uwAnalysis = new UW_Analysis__c ();
                            uwAnalysis.UW_Analysis_Name__c = uwTemp.UW_Analysis_Name__c;
                            uwAnalysis.Criteria__c = uwTemp.Criteria__c;
                            uwAnalysis.UW_Analysis_Code__c = uwTemp.UW_Analysis_Code__c;
                            uwAnalysis.Rating_Factor__c = uwTemp.Rating_Factor__c;
                            uwAnalysis.Sort_Order__c = uwTemp.Sort_Order__c;
                            uwAnalysis.Submission__c = opp.Id;
                            uwAnalysis.UW_Analysis_Template__c = uwTemp.Id;
                            uwAnalysis.Split_Percentage__c = uwTemp.Default_Split_Percentage__c;
                            uwAnalysisListToInsert.add(uwAnalysis);
                        }
                    }                    
                }                
                system.debug('uwAnalysisListToInsert== '+uwAnalysisListToInsert);
            }
        }
        if(!uwAnalysisListToInsert.isEmpty()){
            insert uwAnalysisListToInsert;
        }
    }
    
    /*************************************************
    * Method Name: createUWAnalysisAfterUpdate
    * Author: 
    * Date: 
    * Params: List<Opportunity> opps, Map<Id, Opportunity> oldDataMap
    * Return: 
    * Exceptions:
    * Description: Create UW records when submission updatd
    * Revision: 
     *************************************************/
    private static void createUWAnalysisAfterUpdate(List<Opportunity> opps, Map<Id, Opportunity> oldDataMap){
        List<String> oppMainProfession = new List<String>{'D&C Turnover Split'};
            
            List<UW_Analysis_Template__c> uwTempTerritoryAndDC = new List<UW_Analysis_Template__c>();
        List<UW_Analysis__c> uwAnalysisListToInsert= new List<UW_Analysis__c>();
        for(UW_Analysis_Template__c uwTemp : UWAnalysisTemplateQueryUtil.fetchUWAnalysisTemplatesByCriteria(oppMainProfession)){
                                                  uwTempTerritoryAndDC.add(uwTemp);
                                              }
        
        system.debug('uwTempTerritoryAndDC== '+uwTempTerritoryAndDC);
        for(Opportunity opp : opps){
            if(opp.Product_Name__c == 'Professional Indemnity' && opp.Main_Profession__c != null 
               && opp.Main_Profession__c != oldDataMap.get(opp.Id).Main_Profession__c){                
                   if(opp.Main_Profession__c == 'Design & Construct' && !uwTempTerritoryAndDC.isEmpty()){
                       for(UW_Analysis_Template__c uwTemp:uwTempTerritoryAndDC){
                           UW_Analysis__c uwAnalysis = new UW_Analysis__c ();
                           uwAnalysis.UW_Analysis_Name__c = uwTemp.UW_Analysis_Name__c;
                           uwAnalysis.Criteria__c = uwTemp.Criteria__c;
                           uwAnalysis.UW_Analysis_Code__c = uwTemp.UW_Analysis_Code__c;
                           uwAnalysis.Rating_Factor__c = uwTemp.Rating_Factor__c;
                           uwAnalysis.Sort_Order__c = uwTemp.Sort_Order__c;
                           uwAnalysis.Submission__c = opp.Id;
                           uwAnalysis.UW_Analysis_Template__c = uwTemp.Id;
                           uwAnalysis.Split_Percentage__c = uwTemp.Default_Split_Percentage__c;
                           uwAnalysis.Amount__c = 0;
                           uwAnalysisListToInsert.add(uwAnalysis);
                       }
                   }                
                   system.debug('uwAnalysisListToInsert== '+uwAnalysisListToInsert);
               }
        }
        if(!uwAnalysisListToInsert.isEmpty()){
            insert uwAnalysisListToInsert;
        }
    }

    /*************************************************
    * Method Name: updatePolicyWordingDocs
    * Author: 
    * Date: 
    * Params: List<Opportunity> opps, Map<Id, Opportunity> oldDataMap
    * Return: 
    * Exceptions:
    * Description: update policy wording docs when submission updated
    * Revision: 
     *************************************************/
    private static void updatePolicyWordingDocs(List<Opportunity> opps, Map<Id, Opportunity> oldDataMap){
        Set<Id> oppIds = new Set<Id>();
        for(Opportunity opp : opps){
            if(opp.Product_Name__c == 'Professional Indemnity' && opp.Main_Profession__c != null 
               && opp.Main_Profession__c != oldDataMap.get(opp.Id).Main_Profession__c){      
                   oppIds.add(opp.Id);
               }
        }
        if(oppIds.size() > 0){
            List<Quote> quoteList = QuoteQueryUtil.fetchOpenQuotesForOpps(oppIds);
            for(Quote newQuote : quoteList){
                if(newQuote.Status != 'In Progress'){newQuote.Status = 'In Progress';}
                String mainProfession = newQuote.Opportunity.Main_Profession__c;
                if(newQuote.Layer__c == 'Primary'){
                    if(mainProfession=='Accountants') newQuote.Policy_Wording__c = System.Label.PW_Accountants;//'AQUW/AC/04.19 Accountants';
                    if(mainProfession=='Architects') newQuote.Policy_Wording__c = System.Label.PW_Architects_Engineers;//'AQUW/AE/04.19 Architects & Engineers';
                    if(mainProfession=='Design & Construct') newQuote.Policy_Wording__c = System.Label.PW_Design_Construction;//'AQUW/DC/04.19 Design & Construction';
                    if(mainProfession=='Engineers') newQuote.Policy_Wording__c = System.Label.PW_Architects_Engineers;//'AQUW/AE/04.19 Architects & Engineers';
                    if(mainProfession=='Insurance Brokers') newQuote.Policy_Wording__c = System.Label.PW_Insurance_Brokers;//'AQUW/IB/04.19 Insurance Brokers';
                    if(mainProfession=='IT Consultants') newQuote.Policy_Wording__c = System.Label.PW_Technology_IT;//'AQUW/IT/04.19 Technology & IT';
                    if(mainProfession=='Miscellaneous') newQuote.Policy_Wording__c = System.Label.PW_Miscellaneous_Professions;//'AQUW/MP/04.19 Miscellaneous Professions';
                    if(mainProfession=='Property Professionals') newQuote.Policy_Wording__c = System.Label.PW_Property_Professionals;//'AQUW/PP/04.19 Property Professionals';
                    if(mainProfession=='Media Professionals') newQuote.Policy_Wording__c = System.Label.PW_Media_Marketing_Communication;//'AQUW/AD/04.19 Media, Marketing & Communication';
                }else{
                    newQuote.Policy_Wording__c = System.Label.PW_Excess_Layer;//'AQUW/EX/04.19 Excess Layer';
                }
                Quote quoteDoc = QuoteCompareItemWrapper.getQuoteDocumentLinks(newQuote);
                newQuote.Policy_Wording_Document__c = quoteDoc.Policy_Wording_Document__c;  
                if(newQuote.Layer__c != 'Excess')	newQuote.IPID_Document__c = quoteDoc.IPID_Document__c;  
            }
            if(quoteList.size() > 0)	update quoteList;    
        }        
    }

    /*************************************************
    * Method Name: deleteExistingUWAnalysis
    * Author: 
    * Date: 
    * Params: List<String> oppIds
    * Return: 
    * Exceptions:
    * Description: delete UW records for submission
    * Revision: 
     *************************************************/
    private static void deleteExistingUWAnalysis(List<String> oppIds){
        system.debug('oppIds'+oppIds);
        List<UW_Analysis__c> uwToDelete = new List<UW_Analysis__c>();
        for(UW_Analysis__c uw:UWAnalysisQueryUtil.fetchUWAnalysisForOpps(oppIds)){
                                   if(uw.Criteria__c != 'Territory'){
                                       uwToDelete.add(uw);
                                   }  
                               }
        if(!uwToDelete.isEmpty()){
            GlobalStaticVar.byPassUWAnalysisTrigger = true;
            delete uwToDelete;            
        }
    }
    
    /*************************************************
    * Method Name: updateRatingModifierForAQPI
    * Author: 
    * Date: 
    * Params: List<Opportunity> opps
    * Return: 
    * Exceptions:
    * Description: Update Rating Modifiers for Submission.
    * Revision: 
     *************************************************/
    private void updateRatingModifierForAQPI(List<Opportunity> opps){
        List<Rating_Modifier_Template__c> templates = new List<Rating_Modifier_Template__c>();
        Map<String, Map<String,Rating_Modifiers__c>> oppToRatingModMap = new Map<String, Map<String,Rating_Modifiers__c>>();       
        List<Rating_Modifiers__c> newModifiers = new List<Rating_Modifiers__c>();
        List<Rating_Modifiers__c> deleteModifiers = new List<Rating_Modifiers__c>();
        Set<Rating_Modifiers__c> rateModSetToDelete = new Set<Rating_Modifiers__c>();
        
        // create a save point in case something is wrong during DML process
        Savepoint sp = Database.setSavepoint();
        try{
            system.debug('## opps -- >'+opps);
            if (opps == null || opps.isEmpty())	return;
            List<String> products = SubmissionTriggerHandler_Common.getAllProductOptions(opps);
            if (products.isEmpty()) return;
            system.debug('## products -- >'+products);
            templates = RatingModifierTemplateQueryUtil.fetchRatingModifierTemplatesByProductsForRiskCapture(products);
            
            if (templates.isEmpty()) return;
            system.debug('## templates -- >'+templates);
            // put opportunities into map to get its id set
            Map<String, Opportunity> oppMap = generateOppMap(opps);
            system.debug('## oppMap -- >'+oppMap);
            // get existed rating modifiers
            for(Rating_Modifiers__c rateMod: RatingModifierQueryUtil.fetchRatingModifiersByOpportunityForRiskCapture(oppMap.keySet())){
                                                  rateModSetToDelete.add(rateMod);
                                                  if(oppToRatingModMap.containsKey(rateMod.Opportunity__c)) {
                                                      Map<String,Rating_Modifiers__c> rateModMap = oppToRatingModMap.get(rateMod.Opportunity__c);
                                                      rateModMap.put(rateMod.Rating_Modifier_Code__c,rateMod);
                                                      oppToRatingModMap.put(rateMod.Opportunity__c, rateModMap);
                                                  } else {
                                                      //oppToRatingModMap.put(rateMod.Opportunity__c, new List<Rating_Modifiers__c>{rateMod});
                                                      oppToRatingModMap.put(rateMod.Opportunity__c, new Map<String,Rating_Modifiers__c>());
                                                      system.debug('## oppToRatingModMap IN FOR-- >'+oppToRatingModMap);
                                                      oppToRatingModMap.get(rateMod.Opportunity__c).put(rateMod.Rating_Modifier_Code__c,rateMod);
                                                  }
                                                  
                                                  //deleteModifiers.add(rateMod);  
                                                  // oppToRatingModMap.put(rateMod.Opportunity__c,new List<Rating_Modifiers__c>{rateMod});
                                                  system.debug('## oppToRatingModMap IN -- >'+oppToRatingModMap);
                                              }            
            system.debug('## oppToRatingModMap -- >'+oppToRatingModMap);
            system.debug('## rateModSetToDelete BEFORE -- >'+rateModSetToDelete);
            for(Opportunity opp: opps){
                List<Rating_Modifier_Template__c> templateNew = new List<Rating_Modifier_Template__c>();
                List<Rating_Modifiers__c> rateModsNotToDeleteList = new List<Rating_Modifiers__c>();
                List<Rating_Modifier_Template__c> rateModTemplateToCreate = new List<Rating_Modifier_Template__c>();
                Map<String,Rating_Modifiers__c> exsitingModifierCodeToRateModMap = oppToRatingModMap.get(opp.Id);
                List<Rating_Modifier_Template__c> newAQPITemplates = new List<Rating_Modifier_Template__c>();  
                system.debug('## exsitingModifierCodeToRateModMap -- >'+exsitingModifierCodeToRateModMap);
                for(Rating_Modifier_Template__c AQPITemp: templates){
                    List<String> criteria = AQPITemp.Create_Criteria__c.split(';');
                    if(criteria.contains(opp.Main_Profession__c)){
                        templateNew.add(AQPITemp);
                    }
                }
                for(Rating_Modifier_Template__c rateTemp: templateNew){
                    if(exsitingModifierCodeToRateModMap.containsKey(rateTemp.Rating_Modifier_Code__c)){
                        rateModsNotToDeleteList.add(exsitingModifierCodeToRateModMap.get(rateTemp.Rating_Modifier_Code__c));
                        system.debug('## rateModsNotToDeleteList IN-- >'+rateModsNotToDeleteList);
                    }else{
                        rateModTemplateToCreate.add(rateTemp);
                    }
                }
                rateModSetToDelete.removeAll(rateModsNotToDeleteList);
                newModifiers = SubmissionTriggerHandler_Common.generateRatingModifier(rateModTemplateToCreate,opp);
                system.debug('## rateModSetToDelete -- >'+rateModSetToDelete);
                system.debug('## rateModsNotToDeleteList -- >'+rateModsNotToDeleteList);
            }
            
            List<Rating_Modifiers__c> listFromRateModSetToDelete = new List<Rating_Modifiers__c>(rateModSetToDelete);
            deleteModifiers.addAll(listFromRateModSetToDelete);
            system.debug('## newModifiers -- >'+newModifiers);
            system.debug('## deleteModifiers -- >'+deleteModifiers);
            if(!newModifiers.isEmpty()) insert newModifiers;
            if(!deleteModifiers.isEmpty()) delete deleteModifiers;
            UpdateRatingModifierFactor(newModifiers,opps);
        } catch (Exception ex){
            // rollback data
            Database.rollback(sp);
            system.debug('## ex.getLineNumber() -- >'+ex.getLineNumber());
            system.debug('## ex.getStackTraceString() -- >'+ex.getStackTraceString());
            system.debug('## ex.getMessage() -- >'+  ex.getMessage());  
            String errorMsg = 'Failed to update AQ PI Rating Modifiers.<br/>Please contact your administators.';
            for (Opportunity opp : (List<Opportunity>)Trigger.new){
                opp.addError(errorMsg);
            }
        }
    }
    
    /*************************************************
    * Method Name: updateAQTaxCountry
    * Author: 
    * Date: 
    * Params: List<Opportunity> newAQopp
    * Return: 
    * Exceptions:
    * Description: update Tax country for submission
    * Revision: 
     *************************************************/
    private static void updateAQTaxCountry(List<Opportunity> newAQopp){
        Map<Id,Account> mapAccount = new Map<Id, Account>();
        Set<String> accIds = new Set<String>();
        Set<String> pickListValuesSet = new Set<String>();
        
        for(Opportunity opp: newAQopp){
            accIds.add(opp.AccountId);
        }
        
        for(Account acc : AccountQueryUtil.fetchAccountsById(accIds)){
            mapAccount.put(acc.Id,acc);
        }
        
        for(Opportunity opp: newAQopp){
            if(mapAccount.get(opp.AccountId) != null) {
                if(mapAccount.get(opp.AccountId).BillingCountry != null){
                    String billingCountry = mapAccount.get(opp.AccountId).BillingCountry;
                    opp.Tax_Country__c = billingCountry;
                }
            }
        }
    }

    /*************************************************
    * Method Name: updateClosedWonSubmissions
    * Author: 
    * Date: 
    * Params: List<Opportunity> newOpps, Map<Id, Opportunity> oldMap
    * Return: 
    * Exceptions:
    * Description: Update closed won submission status
    * Revision: 
     *************************************************/
    private static void updateClosedWonSubmissions(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap){
        List<String> closeQuoteStatus = new List<String>{'Bound', 'Bound Pending', 'Closed'};
            Set<Id> closedWonIds = new Set<Id>();
        Set<Id> boundOppsIds = new Set<Id>();
        Set<Id> boundInWaitOppsIds = new Set<Id>();
        for(Opportunity opp: newOpps){
            if(opp.StageName == 'Closed Won' && oldMap.get(opp.Id).StageName != 'Closed Won' && opp.Product_Name__c == 'Professional Indemnity'){
                closedWonIds.add(opp.Id);
            }
        }
        Map<Id, List<Quote>> quoteOppMap = new Map<Id, List<Quote>>();
        //Query in loop!!!!!!!!!!!!!!!!! Needs to be changed.
        for(ID oppID: closedWonIds){
            quoteOppMap.put(oppID, QuoteQueryUtil.fetchOpenQuotesForOpps(oppId, closeQuoteStatus));
        }
        System.debug('quoteOppMap -->'+quoteOppMap);
        for(ID oppId: quoteOppMap.keyset()){
            if(quoteOppMap.get(oppId).size() == 0){
                boundOppsIds.add(oppId);
            }
            else{
                boundInWaitOppsIds.add(oppId);
            }
        }
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        //Update Opportunities To Bound
        if(!boundOppsIds.isEmpty())
            for(Opportunity opp: OpportunityQueryUtil.fetchOpportunityByIds(boundOppsIds)){
                if(opp.Submission_Status__c != 'Bound'){
                    opp.Submission_Status__c = 'Bound';
                }
                oppsToUpdate.add(opp);
            }
        //Update Opportunities To Bound - In Waiting
        if(!boundInWaitOppsIds.isEmpty())
            for(Opportunity opp: OpportunityQueryUtil.fetchOpportunityByIds(boundInWaitOppsIds)){
                if(opp.Submission_Status__c != 'Bound - In Waiting'){
                    opp.Submission_Status__c = 'Bound - In Waiting';
                }
                oppsToUpdate.add(opp);
            }
        
        if(oppsToUpdate.size() > 0){
            update oppsToUpdate;
        }
    }
    
    /*************************************************
    * Method Name: validateQuotedOpportunity
    * Author: 
    * Date: 
    * Params: List<Opportunity> newOpps,Map<id,Opportunity> oldMap
    * Return: 
    * Exceptions:
    * Description: update validation for quoted submission.
    * Revision: 
     *************************************************/
    private static void validateQuotedOpportunity(List<Opportunity> newOpps,Map<id,Opportunity> oldMap){
        for(Opportunity opp:newOpps){
            if((opp.Submission_Status__c == 'Hold Cover' || opp.Submission_Status__c == 'Information Requested' || opp.Submission_Status__c == 'VRI') && oldMap.get(opp.Id).Submission_Status__c == 'Quoted' && opp.Product_Name__c == 'Professional Indemnity'){
                opp.addError('Cannot update the Submission Status of a Quoted Opportunity');
            }
        }
    }

     /*************************************************
    * Method Name: UpdateRatingModifierFactor
    * Author: 
    * Date: 
    * Params: List<Rating_Modifiers__c> newModifiers, List<Opportunity> opps
    * Return: 
    * Exceptions:
    * Description: update rating modifier factors for submission.
    * Revision: 
     *************************************************/
     public static void UpdateRatingModifierFactor(List<Rating_Modifiers__c> newModifiers, List<Opportunity> opps){
         set<Id> oppIds = new set<Id>();
         Set<string> quoteStatus = new Set<String>{'In Progress','Rated','Quoted'};
         Map<String,List<Quote>> oppQuoteListMap = new Map<String,List<Quote>>();
         List<Rating_Modifier_Factor__c> newRMFList = new List<Rating_Modifier_Factor__c>();
         Map<String,List<Rating_Modifier_Factor__c>> quoteRMFMap = new Map<String,List<Rating_Modifier_Factor__c>>();
         for(Opportunity opp: opps){
             oppIds.add(opp.Id);
         }
         List<Quote> quoteList = QuoteQueryUtil.fetchQuotesForOppsAndStatus(oppIds,quoteStatus);
         if(!quoteList.isEmpty()){
             for(Quote quote :quoteList){
                 if(oppQuoteListMap.containsKey(quote.OpportunityId)){
                     oppQuoteListMap.get(quote.OpportunityId).add(quote);
                 }else{
                     oppQuoteListMap.put(quote.OpportunityId,new List<Quote> {quote});
                 }
             }  
         }
        
         for(Opportunity opp: opps){
             if(oppQuoteListMap.containsKey(opp.Id)){
                 if(oppQuoteListMap.get(opp.Id).Size() >0){
                     for(Quote quote: oppQuoteListMap.get(opp.Id)){
                         for(Rating_Modifiers__c ratMod: newModifiers){
                             Rating_Modifier_Factor__c factor = new Rating_Modifier_Factor__c();
                             factor.Factor_Default_Value__c = ratMod.Factor_Default_Value__c;
                             factor.Factor_Max__c = ratMod.Factor_Max__c;
                             factor.Factor_Min__c = ratMod.Factor_Min__c;
                             factor.Quote__c = quote.Id;
                             factor.Rating_Modifier__c = ratMod.Id;
                             newRMFList.add(factor); 
                         } 
                     }
                 }
             }
             
         }
         
         if(!newRMFList.isEmpty()){
             insert newRMFList;
         }
         
    }

    /*************************************************
    * Method Name: UpdateRelatedQuoteStatusAQ
    * Author: 
    * Date: 
    * Params: List<Opportunity> OppListNew, Map<Id, Opportunity> oldDataMap
    * Return: 
    * Exceptions:
    * Description: update status of quotes related to submission
    * Revision: 
     *************************************************/
    public static void UpdateRelatedQuoteStatusAQ(List<Opportunity> OppListNew, Map<Id, Opportunity> oldDataMap){
        Map<Id, String> mapOfOppIdVsStatus = new Map<Id, String>();
        List<Quote> lstQuotesToBeUpdated = new List<Quote>();
        for(Opportunity opp : OppListNew){
            if(opp.StageName == 'Closed Lost' && opp.Submission_Status__c == 'Declined' && opp.Loss_Reason__c == 'Sanctioned Entity'){
                mapOfOppIdVsStatus.put(opp.Id, 'FailedSanction');
            }
            else if(opp.StageName != oldDataMap.get(opp.Id).StageName && opp.StageName =='Declined'){
                mapOfOppIdVsStatus.put(opp.Id, 'Declined');
            }
            else if(opp.StageName != oldDataMap.get(opp.Id).StageName && oldDataMap.get(opp.Id).StageName =='Declined'){
                mapOfOppIdVsStatus.put(opp.Id, 'Undeclined');
            }
        }

        List<Opportunity> Opplist = OpportunityQueryUtil.fetchSubmissionsWithRelatedQuotes(mapOfOppIdVsStatus.keySet());
        for(Opportunity opp : Opplist){
            if(mapOfOppIdVsStatus.get(opp.Id) == 'FailedSanction'){
                if(opp.Quotes != null ){
                    for(Quote objQuote : opp.Quotes){
                        if(objQuote.Status == 'In Progress' || objQuote.Status == 'Rated' || objQuote.Status == 'Referred' || objQuote.Status == 'Quoted'){
                            objQuote.Status='Closed';
                            objQuote.Closed_Reason__c = opp.Loss_Reason__c;
                            lstQuotesToBeUpdated.add(objQuote);
                        }
                    }
                }
            }
            else if(mapOfOppIdVsStatus.get(opp.Id) == 'Declined'){
                for(Quote objQuote : opp.Quotes){
                    objQuote.Status='Rejected';
                    lstQuotesToBeUpdated.add(objQuote);
                }
            }
            else if(mapOfOppIdVsStatus.get(opp.Id) == 'Undeclined'){
                for(Quote objQuote : opp.Quotes){
                    objQuote.Status='In Progress';
                    lstQuotesToBeUpdated.add(objQuote);
                }
            }
        }
        
        if(!lstQuotesToBeUpdated.isEmpty()){
            GlobalStaticVar.byPassQuoteTrigger = true;
            update lstQuotesToBeUpdated;
            GlobalStaticVar.byPassQuoteTrigger = false;
            ID jobID = System.enqueueJob(new SyncQuoteQueueable(lstQuotesToBeUpdated));
        }
    }
 /*************************************************
    * Method Name: onUpdateAccName
    * Author:Mary Elizabeth 
    * Date: 2-2-2022 
    * Params: List<Account> oldAccounts, List<Account> newAccounts 
    * Description: Updates the Quote and Submission Name when Account Name is Updated 
    * Can be moved to Flows: No
     *************************************************/ 

    public static void onUpdateInsuredAccName(list<Opportunity> oldOpp, list<Opportunity> newOpp)
    {

        map<String,String> oppIdToNewMap = new map<String,String>();
        map<String,String> oppIdtoOldMap = new map<String,String>();
        list<Opportunity> oppListRelatedQuote = new list<Opportunity>();
        list<Opportunity> oppR = new list<Opportunity>();
        list<Quote> quoteR  = new  list<Quote>();
        List<String> qStatus = new List<String>{'Bound','Rejected','Closed','Correction','Cancelled'};
        List<String> oppStage = new List<String>{'Closed Lost','Closed Won'};
        for(Opportunity opp : newOpp)
        {
            oppIdToNewMap.put(opp.Id,opp.AccountId);
        }
        for(Opportunity opp : oldOpp)
        {
            oppIdtoOldMap.put(opp.Id,opp.AccountId);
        }
        
        if(oppIdToNewMap.size() > 0)
        {
            oppListRelatedQuote = [Select Name , id , AccountId, createdDate, StageName, Product_Name__c,
                                    (Select Name , id, Status 
                                        from Quotes 
                                        where Status NOT IN:qStatus) 
                                    from Opportunity 
                                    where Product_Name__c='Professional Indemnity'];
            System.debug('oppListRelatedQuote---'+oppListRelatedQuote);
        }

        if(oppListRelatedQuote.size() > 0){
            for(Opportunity opp: oppListRelatedQuote)
            {	
                String oldName = oppIdtoOldMap.get(opp.Id);
                String newName = oppIdToNewMap.get(opp.Id);
                
                if(opp.StageName == 'New' || opp.StageName == 'Qualified' || opp.StageName == 'Declined' ){
                opp.Name = opp.Name.replace(oldName,newName);
                oppR.add(opp);
                }
                for(Quote q : opp.Quotes)
                {   q.Name = q.Name.replace(oldName, newName);
                    quoteR.add(q);   
                }
            }
        }
        if(oppR.size()>0)update oppR;
        if(quoteR.size()>0 && oppR.size()>0)update quoteR;





















/*


        map<String,String> accIdToNewMap = new map<String,String>();
        map<String,String> accIdtoOldMap = new map<String,String>();
        list<Opportunity> oppListRelatedQuote = new list<Opportunity>();
        list<Opportunity> oppR = new list<Opportunity>();
        list<Quote> quoteR  = new  list<Quote>();
        List<String> qStatus = new List<String>{'Bound','Rejected','Closed','Correction','Cancelled'};
        List<String> oppStage = new List<String>{'Closed Lost','Closed Won'};
        for(Quote_Process__c acc : newAccount)
        {
            accIdToNewMap.put(acc.Id,acc.Name);
        }
        for(Quote_Process__c acc : oldAccount)
        {
            accIdtoOldMap.put(acc.Id,acc.Name);
        }
        if(accIdToNewMap.size() > 0)
        {
            oppListRelatedQuote = [Select Name , id , AccountId, createdDate, StageName, Product_Name__c,
                                    (Select Name , id, Status 
                                        from Quotes 
                                        where Status NOT IN:qStatus) 
                                    from Opportunity 
                                    where AccountId =: accIdToNewMap.keyset() and Product_Name__c='Professional Indemnity'];
            System.debug('oppListRelatedQuote---'+oppListRelatedQuote);
        }

        if(oppListRelatedQuote.size() > 0){
            for(Opportunity opp: oppListRelatedQuote)
            {
                String oldName = accIdtoOldMap.get(opp.AccountId);
                String newName = accIdToNewMap.get(opp.AccountId);
                if(opp.StageName == 'New' || opp.StageName == 'Qualified' || opp.StageName == 'Declined' ){
                opp.Name = opp.Name.replace(oldName,newName);
                oppR.add(opp);
                }
                for(Quote q : opp.Quotes)
                {   q.Name = q.Name.replace(oldName, newName);
                    quoteR.add(q);   
                }
            }
        }
        if(oppR.size()>0)update oppR;
        if(quoteR.size()>0 && oppR.size()>0)update quoteR;
        */
    }       
}