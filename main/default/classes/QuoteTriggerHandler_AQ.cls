/**************************************************************************************************
 * Class Name: QuoteTriggerHandler_AQ
 * Author: 
 * Date: 
 * Description: Class to keep Aqueous related methods
 * Test Class: QuoteTriggerHandlerTest
 **************************************************************************************************/
public class QuoteTriggerHandler_AQ extends TriggerHandler{
	private List<Quote> oldDataList;
    private List<Quote> newDataList; 
    private Map<Id, Quote> newDataMap;
    private Map<Id, Quote> oldDataMap;
    
    public QuoteTriggerHandler_AQ(List<Quote> newDataList, List<Quote> oldDataList, 
                                         Map<Id, Quote> newDataMap, Map<Id, Quote> oldDataMap){
                                             this.oldDataList = oldDataList;
                                             this.newDataList = newDataList;
                                             this.newDataMap = newDataMap;
                                             this.oldDataMap = oldDataMap;
                                         }

    public override void beforeInsert(){

        //Method to update Broker Name and Broker Email on Quote
        QuoteTriggerHandler_Common.updateQuoteWithBrokerName(newDataList);
        //Method to update Broker Name and Broker Email on Quote
        QuoteTriggerHandler_Common.updateCommission(newDataList);
        //Method to set Retroactive date and Retro date on Quote
        setRetroactiveDate(newDataList);

    }

    public override void beforeUpdate(){

        //Method to update Broker Name and Broker Email on Quote
        //Bypass for recursive
        //Move to Submission Trigger??
        QuoteTriggerHandler_Common.updateQuoteWithBrokerName(newDataList);
        //Method to add error on Quote if status = 'Quoted\' or \'Presented\' or \'Bound\'
        //Optimized-- to be tested
        QuoteTriggerHandler_Common.lockEditOnQuote(newDataList,oldDataMap);
        //Method to send email to Submitter on Approval/Rejection
        QuoteTriggerHandler_Common.sendEmailToApprovalSubmitter(newDataList,oldDataMap);
        //Method to set Force_Rating__c whici is sent to and used by M/W.
        QuoteTriggerHandler_Common.checkForceRating(newDataList,oldDataMap);
        //Method to set/reset binder assignment for quote
        //can be Optimized
        checkBinderAssignForQuote(newDataList,oldDataMap);
        //Method to set Policy_Wording_Document__c,Policy_Wording_ContentDoc_Id__c, IPID_Document__c,IPID_ContentDoc_Id__c on Quote
        checkQuoteDocLinksAssign(newDataList,oldDataMap);
        //Method to auto approve reject Referal Reasons 
        approveRejectReferralReasons(newDataList);
        //Method to populate Premium fields on Amendments and Cancellation quotes
        populatePremiumFields(newDataList,oldDataMap);
        //Method to populate Endorsement_Quote_Bound_Date__c on quotes
        updateQuoteBoundDate(newDataList,oldDataMap);

    }

    public override void afterInsert(){

        //Method to add Insurer_Layer_Limit__c record for Excess quotes
        createInsurerExcess(newDataList);
        //Method to Create CoverageLineItems from Coverage for each Quote
        QuoteTriggerHandler_Common.AddCoverageLineItems(newDataList); 
        //Method to add Quote Locations 
        QuoteTriggerHandler_Common.createPrimaryLocation(newDataList);
        //Method to create rating modifier factor from template for each quote
        QuoteTriggerHandler_Common.AddRatingModifierFactor(newDataList); 
        //Method to create Subjectivities for each quote
        //Can be Optimized??
        createSubjectivityIfProposalFormDateEmpty(newDataList);
        //Method to set Opp status to 'Bound - In Waiting'
        //Is 'Bound - In Waiting' used for aqueous?? Can be removed?? can save 13 queries from opp trigger
        updateBoundSubmissionStatus(newDataList);
        //Method to get Quote Options for each Quote
        addQuoteOptions(newDataList);
        //Method to add Default coverages to quotes bases on croiteria mentioned in Endorsement Matrix
        addDefaultCoverages(newDataList);
    }

    public override void afterUpdate(){

        //Method to delete and reinsert Insurer_Layer_Limit__c records for Quotes
        handleExcessInsurerUnderlying(newDataList,oldDataMap);
        //Method to generate Quote Documanet for each quote
        QuoteTriggerHandler_Common.generatedQuoteDocument(oldDataMap, newDataMap);
        //Method to create Coverage Line Items from Coverage for each Quote
        QuoteTriggerHandler_Common.updateCoverageLineItems(newDataList, newDataMap);
        //Method to Count open Subjectivities on quote and update on Policy
        QuoteTriggerHandler_Common.countOpenSubjectivityOnBoundQuote(newDataList);
        //Method to update Coverage_Effective_Date__c of CoveragesLineItem__c when quote is update
        QuoteTriggerHandler_Common.updateCliEffectiveDate(newDataList, oldDataMap);
        //Method to set Opp status to 'Bound'
        updateSubmissionStatusToBound(newDataList);
        //Method to set Opp status to 'Quoted'
        updateQuoteStatusToQuoted(newDataList,oldDataMap);
        //Method to set Opp status to 'Referred'
        updateQuoteStatusToReferred(newDataList,oldDataMap);
        //Method to set Opp status, StageName,Loss_Reason__c
        //Optimized to run only on Quote status change-- to be tested
        updateSubmissionStatus(newDataList,oldDataMap); 
        //Method to calculate Premium field on Quote Option records for each quote
        calculatePremiumFields(newDataList,oldDataMap);
        //Method to remove Duplicate Quote Options
        removeDuplicateQuoteOption(newDataList,oldDataMap);
        //Method to remove approval request from Quote when quote status is chaned from referred
        //method placed in without sharing class for system mode
        CommonUtilAQ.removeApprovalRequestsFromQuote(newDataList,oldDataMap);
        //Method to make sync Callout
        QuoteTriggerHandler_Common.syncCallout(newDataList,oldDataMap);
        
        //Allow Renewal on parent policy CD-141 created By Navdeep
        allowRenewalOnParentPolicy(newDataList,oldDataMap);

    }

    public override void beforeDelete(){}

    /*************************************************
    * Author: Altaf Pawaskar
    * Date: 
    * Params: aqueousQuote - List of Quotes
    * Return: none
    * Description: Method to set Retroactive date and Retro date on Quote
    * Revision:
    *************************************************/
    public static void setRetroactiveDate(List<Quote> aqueousQuote){
        
        Map<String,Master_Binder__c> mapMasterBinder = getMasterBinderName();

        for(Quote objQuote : aqueousQuote){
            if(!mapMasterBinder.isEmpty() && mapMasterBinder.containsKey(objQuote.Master_Binder__c) && mapMasterBinder.get(objQuote.Master_Binder__c).Name.contains('GAIC') && objQuote.Quote_Type__c == 'New Business'){
                objQuote.Retroactive_Date__c = 'Retro - Inception date';
                objQuote.RetroDate__c = objQuote.Effective_Date__c;
            }
        }

    }

    /*************************************************
    * Author: Altaf Pawaskar
    * Date: 
    * Return: Map<String,Master_Binder__c>
    * Description: Method to get Map of available master Binders
    * Revision:
    *************************************************/
    public static Map<String,Master_Binder__c> getMasterBinderName(){

        Map<String,Master_Binder__c> mapMasterBinder = new Map<String,Master_Binder__c>([Select Id, Name from Master_Binder__c] );

        return mapMasterBinder;

    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: newList - List of New Quotes
    * Params:  oldQuoteMap - Map of old Quote
    * Return: none
    * Description: Method to set/reset binder assignment for quote
    * Revision:
    *************************************************/
    private static void checkBinderAssignForQuote(List<Quote> newList,Map<Id, Quote> oldQuoteMap){        
        System.debug('Inside Method for Before Update');
        List<Master_Binder__c> binderList = [Select Id,Name,Inception_Date__c,Expiry_Date__c,MGA_Commission__c,Layer__c,
                                             Coverholder_Name__c,Coverholder_Pin__c from Master_Binder__c];
        List<Id> binderIdList = new List<Id>();
        List<Decimal> mgaCommissionValueList = new List<Decimal>();
        for(Quote quote : newList) {     
            if(oldQuoteMap.get(quote.Id).Effective_Date__c != quote.Effective_Date__c && quote.Product_Name__c == 'Professional Indemnity'){
                Integer binderCount = 0;     
                binderIdList = new List<Id>();
                for(Master_Binder__c binder : binderList){
                    if(binder.Inception_Date__c <= quote.Effective_Date__c && binder.Layer__c.contains(quote.Layer__c)
                       && binder.Expiry_Date__c >= quote.Effective_Date__c){
                           binderCount++;	    
                           binderIdList.add(binder.Id);
                           mgaCommissionValueList.add(binder.MGA_Commission__c);
                       }
                }
                if(binderCount == 1 && binderIdList.size() == 1){
                    quote.Master_Binder__c = binderIdList[0];
                    quote.Policy_Wording_Document__c = null;
                    quote.IPID_Document__c = null;
                    Quote quoteDoc = QuoteCompareItemWrapper.getQuoteDocumentLinks(quote);
                    quote.Policy_Wording_Document__c = quoteDoc.Policy_Wording_Document__c;  
                    if(quote.Layer__c != 'Excess')	quote.IPID_Document__c = quoteDoc.IPID_Document__c;  	                    
                }	                
                if(binderCount == 1 && mgaCommissionValueList.size() == 1)	quote.MGA_Commission__c = mgaCommissionValueList[0];
                if(binderCount > 1){
                    if(quote.Status == 'In Progress'){
                        quote.Is_Inception_Date_Edited__c = true;
                    }
                    quote.Master_Binder__c = null;
                    quote.Policy_Wording_Document__c = null;
                    quote.IPID_Document__c = null;
                    //quote.MGA_Commission__c = null;   //Commented as per #51580
                }	
                //if(binderCount > 1)	quote.MGA_Commission__c = null;
            }
            if(quote.Product_Name__c == 'Professional Indemnity' && oldQuoteMap.get(quote.Id).Status != quote.Status
                && oldQuoteMap.get(quote.Id).Status == 'In Progress' && quote.Status == 'Rated'){
                    quote.Is_Inception_Date_Edited__c = false;
            }
            if(quote.Product_Name__c == 'Professional Indemnity' && oldQuoteMap.get(quote.Id).Status != quote.Status && quote.Status == 'Quoted'){
                if(quote.Retroactive_Date__c == 'Retro - Inception date'){
                    quote.RetroDate__c = quote.Effective_Date__c;
                }
                else if(quote.Retroactive_Date__c == 'None'){
                    quote.RetroDate__c = null;
                }
            }
        }
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: newList - List of New Quotes
    * Params:  oldQuoteMap - Map of old Quote
    * Return: none
    * Description: Method to set Policy_Wording_Document__c,Policy_Wording_ContentDoc_Id__c, IPID_Document__c,IPID_ContentDoc_Id__c on Quote
    * Revision:
    *************************************************/
    private static void checkQuoteDocLinksAssign(List<Quote> newList,Map<Id, Quote> oldQuoteMap){
        for(Quote quote : newList) {     
            if((oldQuoteMap.get(quote.Id).Policy_Wording__c != quote.Policy_Wording__c || (quote.Status != oldQuoteMap.get(quote.Id).Status && quote.Status == 'Rated' && quote.Policy_Wording_Document__c == null)) && quote.Product_Name__c == 'Professional Indemnity'){
                if(String.isNotBlank(quote.Master_Binder__c)){
                    Quote quoteDoc = QuoteCompareItemWrapper.getQuoteDocumentLinks(quote);
                    quote.Policy_Wording_Document__c = quoteDoc.Policy_Wording_Document__c;
                    quote.Policy_Wording_ContentDoc_Id__c = quoteDoc.Policy_Wording_ContentDoc_Id__c;
                    if(quote.Layer__c != 'Excess')	{
                        quote.IPID_Document__c = quoteDoc.IPID_Document__c; 
                        quote.IPID_ContentDoc_Id__c = quoteDoc.IPID_ContentDoc_Id__c;
                    }
                }
            }
        }   
    } 
    
    /*************************************************
    * Author: 
    * Date: 
    * Params: newList - List of New Quotes
    * Return: none
    * Description: Method to auto approve reject Referal Reasons 
    * Revision:
    *************************************************/
    private static void approveRejectReferralReasons(List<Quote> newList){       
        System.debug('(((((((-->start');
        List<Quote> aprrovalFieldsQuoteList = new List<Quote>();
        Map<Id, List<Referral_Reason__c>> quoteIdToReferralReasonMap = new Map<Id, List<Referral_Reason__c>>();
        List<Referral_Reason__c> referralReasonsToUpdateList = new List<Referral_Reason__c>();
        Set<Id> quoteIds = new Set<Id>();
        
        for(Quote quote:newList){
            if(String.isNotBlank(quote.Is_Quote_Approved_AQ__c)){
                quoteIds.add(quote.Id);
            }            
        }
        
        if(quoteIds.size() > 0){
            User currentUserObj = [Select Id,Name,Level__c from User where Id =: UserInfo.getUserId()];
            List<Referral_Reason__c> referralReasonList = [SELECT Id,Name,Approval_Level_Required__c,Approval_Status__c,Quote__c,
                                                           Approval_Rejected_Date__c, Approver_Level__c,Approved_By__c, Entity_Path__c,
                                                           Reason__c,Reason_Type__c, Status__c,Approved_By__r.Name,
                                                           Quote_Option__c,Option_Type__c,Option_Limit__c,Option_Id__c,Quote_Option__r.Selected__c  
                                                           FROM Referral_Reason__c 
                                                           WHERE Approval_Status__c != 'Approved' 
                                                           //AND Quote_Option__c = null
                                                           //AND Quote_Option__r.Selected__c = true
                                                           AND Approval_Status__c != 'Rejected' 
                                                           AND Quote__c IN:quoteIds];
            
            for(Referral_Reason__c referralReasonQuo : referralReasonList){  
                if(referralReasonQuo.Quote_Option__r.Selected__c || String.isBlank(referralReasonQuo.Quote_Option__c)){
                    if(quoteIdToReferralReasonMap.containsKey(referralReasonQuo.Quote__c)){
                        quoteIdToReferralReasonMap.get(referralReasonQuo.Quote__c).add(referralReasonQuo);
                    }else{
                        quoteIdToReferralReasonMap.put(referralReasonQuo.Quote__c, new List<Referral_Reason__c>{referralReasonQuo});
                    }    
                }                
            }
            system.debug('((((((quoteIdToReferralReasonMap -- '+quoteIdToReferralReasonMap);
            for(Quote quote : newList) {
                system.debug('((((((quoteIdToReferralReasonMap -- '+quoteIdToReferralReasonMap.get(quote.Id));
                if(quote.Is_Quote_Approved_AQ__c == 'Approved'){ 
                    system.debug('((((((quoteIdToReferralReasonMap --Approved ');
                    List<Referral_Reason__c> referralReasonsToUpdate = updateReferralReasons(quoteIdToReferralReasonMap.get(quote.Id),quote.Is_Quote_Approved_AQ__c,currentUserObj);
                    referralReasonsToUpdateList.addAll(referralReasonsToUpdate);                    
                    quote.Is_Quote_Approved_AQ__c = null;
                }else if(quote.Is_Quote_Approved_AQ__c == 'Rejected'){
                    system.debug('((((((quoteIdToReferralReasonMap --Rejected ');
                    List<Referral_Reason__c> referralReasonsToUpdate = updateReferralReasons(quoteIdToReferralReasonMap.get(quote.Id),quote.Is_Quote_Approved_AQ__c,currentUserObj);
                    referralReasonsToUpdateList.addAll(referralReasonsToUpdate);
                    quote.Is_Quote_Approved_AQ__c = null;
                }     
                aprrovalFieldsQuoteList.add(quote);
            } 
            if(!referralReasonsToUpdateList.isEmpty()){
                system.debug('((((((referralReasonsToUpdateList-- '+referralReasonsToUpdateList);
                GlobalStaticVar.byPassQuoteTrigger = true;
                update referralReasonsToUpdateList;
            }
            //if(!aprrovalFieldsQuoteList.isEmpty())	update aprrovalFieldsQuoteList;
        }              
    }

    private static List<Referral_Reason__c> updateReferralReasons(List<Referral_Reason__c> refReasonList, String quoteApprovedRejected,User currentUser){
        System.debug('refReasonList-->'+refReasonList);
        for(Referral_Reason__c refReason: refReasonList){
            refReason.Approval_Rejected_Date__c = System.Date.today();
            refReason.Approved_By__c = currentUser.Id;
            refReason.Approval_Status__c = quoteApprovedRejected;
            refReason.Approver_Level__c = currentUser.Level__c;
        }
        return refReasonList;
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: listNewQuote - List of New Quotes
    * Params:  oldQuoteMap - Map of old Quote
    * Return: none
    * Description: Method to populate Premium fields on Amendments and Cancellation quotes
    * Revision:
    *************************************************/
    public static void populatePremiumFields(List<Quote> listNewQuote,Map<Id, Quote> mapOldQuote){
        
        Set<String> setQuoteId = new Set<String>();
        Map<String,Quote_Option__c> mapQO = new Map<String,Quote_Option__c>();
        
        for(Quote objQuote : (List<Quote>)Trigger.new){
            if(objQuote.Status == 'Quoted' && mapOldQuote.get(objQuote.Id).Status != 'Quoted' 
               && (objQuote.Quote_Type__c == 'Full Amendment' || objQuote.Quote_Type__c == 'Coverage Amendment'
                   || objQuote.Quote_Type__c == 'Midterm Cancellation' || objQuote.Quote_Type__c == 'Flat Cancellation'
                   || objQuote.Quote_Type__c == 'Reinstatement' || objQuote.Quote_Type__c == 'Policy Duration Change')
              ){
                  
                  setQuoteId.add(objQuote.Id);
                  
              }
            
        }
        if(!setQuoteId.isEmpty())
        for(Quote_Option__c objQO : [Select Id, Bound__c, Quote__c, Actual_Premium__c, Broker_Netted_Down_Premium__c
                                     , Fee__c, Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c
                                     , Override_Fee_Percent__c, IPT_on_Broker_Netted_Down_Premium__c
                                     , Total_Cost_to_Client__c, Technical_Fee__c, Technical_Premium__c
                                     , NonProrated_Actual_Premium__c, NonProRated_BNDP__c
                                     from Quote_Option__c where Quote__c in :setQuoteId and Bound__c = true]){
                                         
                                         mapQO.put(objQO.Quote__c,objQO);
                                         
                                     }
        
        if(!mapQO.isEmpty()){
            
            for(Quote objQuote : listNewQuote){
                
                if(mapQO.containsKey(objQuote.Id)){
                    Quote_Option__c boundQuoteOption = mapQO.get(objQuote.Id);
                    objQuote.Actual_Premium__c = boundQuoteOption.Actual_Premium__c;
                    objQuote.Broker_Netted_Down_Premium__c = boundQuoteOption.Broker_Netted_Down_Premium__c;
                    objQuote.Fee__c = boundQuoteOption.Fee__c;
                    objQuote.IPT_on_Broker_Netted_Down_Premium__c = boundQuoteOption.IPT_on_Broker_Netted_Down_Premium__c;
                    objQuote.Total_Cost_to_Client__c = boundQuoteOption.Total_Cost_to_Client__c;
                    objQuote.Technical_Fee__c = boundQuoteOption.Technical_Fee__c;
                    objQuote.Technical_Premium__c = boundQuoteOption.Technical_Premium__c;
                    objQuote.NonProrated_Actual_Premium__c = boundQuoteOption.NonProrated_Actual_Premium__c;
                    objQuote.NonProRated_BNDP__c = boundQuoteOption.NonProRated_BNDP__c;
                }
                
            }
            
        }
        
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: listNewQuote - List of New Quotes
    * Params:  oldQuoteMap - Map of old Quote
    * Return: none
    * Description: Method to populate Endorsement_Quote_Bound_Date__c on quotes
    * Revision:
    *************************************************/
    private static void updateQuoteBoundDate(List<Quote> newQuoteList, Map<ID,Quote> oldQuoteMap){
        for(Quote quote: newQuoteList){
            if(quote.Status == 'Bound' && oldQuoteMap.get(quote.Id).Status != 'Bound' && quote.Product_Name__c == 'Professional Indemnity'){
                quote.Endorsement_Quote_Bound_Date__c = Datetime.now();
            }
        }
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: newList - List of New Quotes
    * Return: none
    * Description: Method to add Insurer_Layer_Limit__c record for Excess quotes
    * Revision:
    *************************************************/
    private static void createInsurerExcess(List<Quote> newList){
        
        List<Insurer_Layer_Limit__c> createInsurerLimit = new List<Insurer_Layer_Limit__c>();
        
        for(Quote quote : newList) {
            if(quote.Layer__c == 'Excess'){
                if (quote.Insurer_Layer_Limit__r.size() == 0) {
                    Insurer_Layer_Limit__c insurerLayer = new Insurer_Layer_Limit__c();
                    insurerLayer.Layer__c = 'Primary Insurer';
                    insurerLayer.Insurer_Layer_Limit__c = 5000000;
                    insurerLayer.Quote__c = quote.Id;
                    createInsurerLimit.add(insurerLayer);
                }
                
            }
        }
        
        if(!createInsurerLimit.isEmpty()){
            insert createInsurerLimit;
        }
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: newList - List of New Quotes
    * Return: none
    * Description: Method to set Opp status to 'Bound - In Waiting'
    * Revision:
    *************************************************/
    private static void updateBoundSubmissionStatus(List<Quote> newQuotes){
        Set<Id> oppIds = new Set<Id>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for(Quote quote:newQuotes){
            oppIds.add(quote.OpportunityId);
        }
        if(!oppIds.isEmpty())
            for(Opportunity opp : [Select Id, Submission_Status__c from Opportunity where ID IN:oppIds]){
                if(opp.Submission_Status__c == 'Bound'){
                    opp.Submission_Status__c = 'Bound - In Waiting';
                }      
                oppsToUpdate.add(opp);
            }
        if(oppsToUpdate.size() > 0){
            update oppsToUpdate;
        }
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: newList - List of New Quotes
    * Return: none
    * Description: Method to Create Quote Options for each Quote
    * Revision:
    *************************************************/
    public static void addQuoteOptions(List<Quote> newQuoteList){
        
        List<Quote_Option__c> listQuoteOptions = new List<Quote_Option__c>();
        for(Quote newQuote : newQuoteList){
            Integer count;
            if(newQuote.Product_Name__c == 'Professional Indemnity'){
                if(newQuote.Layer__c == 'Primary'){
                    count = 10;
                    //Method to get Quote Options for each Quote
                    listQuoteOptions.addAll(createQuoteOptions(count,newQuote.Id,'Fixed Limit'));
                    listQuoteOptions.addAll(createQuoteOptions(1,newQuote.Id,'Free Form'));
                    
                }else{
                    count = 6;
                    //Method to get Quote Options for each Quote
                    listQuoteOptions.addAll(createQuoteOptions(count,newQuote.Id,'Fixed Limit'));
                    listQuoteOptions.addAll(createQuoteOptions(1,newQuote.Id,'Free Form'));
                }
            }
        }
        
        if(!listQuoteOptions.isEmpty()){
            insert listQuoteOptions;
        }
        
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: count - Integer
    * Params: quoteId - Quote Id
    * Params: type - Quote Option Type
    * Return: List of Quote_Option__c
    * Description: Method to get Quote Options for each Quote
    * Revision:
    *************************************************/
    public static List<Quote_Option__c> createQuoteOptions(Integer count, Id quoteId, String type){
        List<Quote_Option__c> lstQuoteOptions = new List<Quote_Option__c>();
        for(Integer i = 0 ; i < count ; i++){
            Quote_Option__c objQuoteOption = new Quote_Option__c(Quote__c = quoteId, Option_Type__c = type);
            lstQuoteOptions.add(objQuoteOption);
        }
        
        return lstQuoteOptions;
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: lstAqQuotes - List of Quotes
    * Return: none
    * Description: Method to add Default coverages to quotes bases on croiteria mentioned in Endorsement Matrix
    * Revision:
    *************************************************/
    public static void addDefaultCoverages(List<Quote> lstAqQuotes){
        Map<Id, Set<String>> mapOfQuoteIdVsSetOfCoverageIds = new Map<Id, Set<String>>();

        for(Quote objQuote: lstAqQuotes){
            Set<String> setOfDefaultCoverageIds = new Set<String>();
            setOfDefaultCoverageIds.addAll(DefaultCoveragesUtil_AQ.GetDefaultCoveragesForQuote(objQuote.Id));
            if(!setOfDefaultCoverageIds.isEmpty()){
                mapOfQuoteIdVsSetOfCoverageIds.put(objQuote.Id,setOfDefaultCoverageIds);
            }
        }

        if(!mapOfQuoteIdVsSetOfCoverageIds.isEmpty()){
            DefaultCoveragesUtil_AQ.addEndorsementCLI(mapOfQuoteIdVsSetOfCoverageIds);
        }
    }

    /*************************************************
    * Author: Tuan.d.Nguyen
    * Date: 17-Mar-2020
    * Params: quotes - list of Quotes
    * Return: Void
    * Description: Method to create Subjectivities for each quote
    * Revision: 
    *************************************************/
    public static void createSubjectivityIfProposalFormDateEmpty(List<Quote> quotes) {
        List<Rating_Modifier_Template__c> templates = new List<Rating_Modifier_Template__c>();
        List<Subjectivity__c> subjectivityListToCreate = new List<Subjectivity__c>(); 
        map<Id,Quote> qMap = new map<Id,Quote>(); 
        List<Id> quoteIdsList = new List<Id>();
        Map<Id,Id> oppIdsMap = new Map<Id,Id>();
        
        try {
            for (Quote q : quotes) {
                oppIdsMap.put(q.OpportunityId,q.Id);
                qMap.put(q.Id, q);
            }
            
            // added by RINKU SAINI In Query Util 3rd Jan 2022
            for(Rating_Modifiers__c rateMod: RatingModifierQueryUtil.fetchRatingModifiersByNameAndOppId(oppIdsMap.keySet()) ){
                if(rateMod.Rating_Modifier_Value__c == null || rateMod.Rating_Modifier_Value__c == ''){
                    quoteIdsList.add(oppIdsMap.get(rateMod.Opportunity__c));
                }
            }
            
            List<Subjectivity_Template__c> subjTemp = [SELECT Id, Name, Profession_Criteria__c, Subjectivity_Name__c, Subjectivity_Text__c 
                                                       FROM Subjectivity_Template__c 
                                                       WHERE Subjectivity_Name__c ='Signed / Dated Proposal'];
            if(subjTemp != null && subjTemp.size() > 0){
                for(Id qId: quoteIdsList){
                    Subjectivity__c subRec = new Subjectivity__c(); 
                    subRec.Quote__c = qId;
                    subRec.Subjectivity__c = subjTemp[0].Subjectivity_Name__c;
                    subRec.Subjectivity_Text__c = subjTemp[0].Subjectivity_Text__c;
                    subRec.Stage__c = 'Pre-Bind';
                    subRec.Cleared__c = false;
                    subRec.Cleared_Date__c = null;
                    subRec.Subjectivity_Template__c = subjTemp[0].Id;
                    if(qMap.containsKey(qId) ){
                        Quote q = qMap.get(qId);
                        if( q.Product_Name__c == GlobalVariables.PROD_NAME_FOR_CYBER ||
                            q.Product_Name__c == GlobalVariables.PROD_NAME_FOR_MPL ||
                            q.Product_Name__c == GlobalVariables.PROD_NAME_FOR_PCC
                        ){
                            subRec.RecordTypeId = Schema.SObjectType.Subjectivity__c.getRecordTypeInfosByName().get(GlobalVariables.RT_NAME_SUBJECTIVITY_CELERITY).getRecordTypeId();
                        }else if(q.Product_Name__c == GlobalVariables.PROD_NAME_FOR_PI){
                            subRec.RecordTypeId = Schema.SObjectType.Subjectivity__c.getRecordTypeInfosByName().get(GlobalVariables.RT_NAME_SUBJECTIVITY_AQUEOUS).getRecordTypeId();
                        }
                    }

                    subjectivityListToCreate.add(subRec);
                } 
            }
            
            if(!subjectivityListToCreate.isEmpty()) insert subjectivityListToCreate;
            
        } catch (Exception ex) {
            system.debug('## ex'+ ex.getLineNumber());
            system.debug('## ex'+ ex.getStackTraceString());
            system.debug('## ex'+ ex.getMessage());
            String errorMsg = 'Failed to create Subjectivity.<br/>Please contact your administators.';
            for(Quote item : (List<Quote>)Trigger.new ){
                item.addError(errorMsg);
            }
        }   
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: newList - list of NewQuotes
    * Params: olddataMap - map of OldQuotes
    * Return: Void
    * Description: Method to delete and reinsert Insurer_Layer_Limit__c records for Quotes
    * Revision: 
    *************************************************/
    private static void handleExcessInsurerUnderlying(List<Quote> newList,Map<Id, Quote> olddataMap){
        List<Insurer_Layer_Limit__c> createInsurerLimit = new List<Insurer_Layer_Limit__c>();
        set<string> insurerDelete = new set<string>();
        
        for(Quote quote : newList) {
            if(olddataMap.get(quote.Id).Layer__c != quote.Layer__c && quote.Layer__c == 'Excess'){
                if (quote.Insurer_Layer_Limit__r.size() == 0) {
                    Insurer_Layer_Limit__c insurerLayer = new Insurer_Layer_Limit__c();
                    insurerLayer.Layer__c = 'Primary Insurer';
                    insurerLayer.Insurer_Layer_Limit__c = 5000000;
                    insurerLayer.Quote__c = quote.Id;
                    createInsurerLimit.add(insurerLayer);
                }
                
            }
            if(olddataMap.get(quote.Id).Layer__c != quote.Layer__c && quote.Layer__c == 'Primary'){
                insurerDelete.add(quote.Id);
            } 
        }
        
        if(!createInsurerLimit.isEmpty()){
            insert createInsurerLimit;
        }
        
        if(!insurerDelete.isEmpty()){
            List<Insurer_Layer_Limit__c> removeInsurerList = [select Id,Insurer__c,Quote__c from Insurer_Layer_Limit__c where Quote__c IN: insurerDelete];  
            if(!removeInsurerList.isEmpty()){
                delete removeInsurerList;
            }
        }
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: newList - List of New Quotes
    * Return: none
    * Description: Method to set Opp status to 'Bound'
    * Revision:
    *************************************************/
    private static void updateSubmissionStatusToBound(List<Quote> newQuotes){
        Set<Id> oppIds = new Set<Id>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for(Quote quote: newQuotes){
            if(quote.Status == 'Bound'){
                oppIds.add(quote.OpportunityId);
            }
        }
        if(!oppIds.isEmpty())
            for(Opportunity opp : [Select Id, Submission_Status__c from Opportunity where ID IN:oppIds]){
                opp.Submission_Status__c = 'Bound';
                oppsToUpdate.add(opp);
            }
        if(oppsToUpdate.size() > 0){
            update oppsToUpdate;
        }
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: newList - List of New Quotes
    * Params: oldQuoteMap - Map of Old Quotes
    * Return: none
    * Description: Method to set Opp status to 'Quoted'
    * Revision:
    *************************************************/
    private static void updateQuoteStatusToQuoted(List<Quote> newQuote, Map<ID,Quote> oldQuoteMap){
        Set<Id> oppIds = new Set<Id>();
        List<Opportunity> updateOpp = new List<Opportunity>();
        for(Quote quote: newQuote){
            if(quote.Status == 'Quoted' && oldQuoteMap.get(quote.Id).Status != 'Quoted' && quote.Product_Name__c == 'Professional Indemnity'){
                oppIds.add(quote.OpportunityId);
            }
        }
        if(!oppIds.isEmpty())
            for(Opportunity opp: [Select Id, Submission_Status__c from Opportunity where ID IN:oppIds]){
                if(opp.Submission_Status__c != 'Quoted'){
                    opp.Submission_Status__c = 'Quoted';
                }
                updateOpp.add(opp);
            }
        if(updateOpp.size() > 0){
            update updateOpp;
        }
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: newList - List of New Quotes
    * Params: oldQuoteMap - Map of Old Quotes
    * Return: none
    * Description: Method to set Opp status to 'Referred'
    * Revision:
    *************************************************/
    private static void updateQuoteStatusToReferred(List<Quote> newQuote, Map<ID,Quote> oldQuoteMap){
        Set<Id> oppIds = new Set<Id>();
        List<Opportunity> updateOpp = new List<Opportunity>();
        for(Quote quote: newQuote){
            if(quote.Status == 'Referred' && oldQuoteMap.get(quote.Id).Status != 'Referred' && quote.Product_Name__c == 'Professional Indemnity'){
                oppIds.add(quote.OpportunityId);
            }
        }
        if(!oppIds.isEmpty())
            for(Opportunity opp: [Select Id, Submission_Status__c from Opportunity where ID IN:oppIds]){
                if(opp.Submission_Status__c != 'Referred'){
                    opp.Submission_Status__c = 'Referred';
                }
                updateOpp.add(opp);
            }
        if(updateOpp.size() > 0){
            update updateOpp;
        }
    }
    
    /*************************************************
    * Author: 
    * Date: 
    * Params: newList - List of New Quotes
    * Params: oldQuoteMap - Map of Old Quotes
    * Return: none
    * Description: Method to set Opp status, StageName,Loss_Reason__c
    * Revision:
    *************************************************/
    private static void updateSubmissionStatus(List<Quote> newQuotes, Map<Id,Quote> quoteOldMap){
        Set<Id> oppIds = new Set<Id>();
        Boolean isOpenQuotes = false;
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        
        for(Quote quote:newQuotes){
            if(quoteOldMap.get(quote.Id).Status != quote.Status){
                oppIds.add(quote.OpportunityId);
            }
        }
        
        if(!oppIds.isEmpty()){
            List<Quote> quoteList = [Select Id,Status from Quote where OpportunityId IN: oppIds];
            if(!quoteList.isEmpty()){
                for(Quote quote:  quoteList){
                    if(quote.Status != 'Bound' && quote.Status != 'Closed'){
                        isOpenQuotes = true;
                        break;
                    }
                } 
            }
            
             // added by RINKU SAINI In Query Util 3rd Jan 2022
            for(Opportunity opp : OpportunityQueryUtil.fetchSubmissionsWithRelatedQuotes(oppIds) )//---CD-103 - Gaurish Goel 14th Sep 2021 -- Added inner query on Quote
            {
                String strSubStatus = opp.Submission_Status__c;
                if(!isOpenQuotes && opp.StageName == 'Qualified'){
                    opp.StageName = 'Closed Won';
                    opp.Submission_Status__c = 'Bound';
                }
                if(opp.Quotes != null && opp.Quotes.size() > 0){//---CD-103 - Gaurish Goel 14th Sep 2021 -- If all quotes are closed then Opp's Stage is set to "Closed Lost"
                    Boolean allClosed = true;
                    String closedReason = '';
                    for(Quote q: opp.Quotes){
                        if(q.Status != 'Closed'){
                            allClosed = false;
                            break;
                        }
                    }
                    if(allClosed){
                        for(Quote q: opp.Quotes){
                            if(q.Status == 'Closed' && quoteOldMap.containsKey(q.Id) && quoteOldMap.get(q.Id).Status != q.Status){
                                closedReason = q.Closed_Reason__c;
                                break;
                            }
                        }
                        opp.StageName = 'Closed Lost';
                        opp.Loss_Reason__c = closedReason;
                        opp.Submission_Status__c = strSubStatus;
                    }
                }
                oppsToUpdate.add(opp);
            }
            
            if(oppsToUpdate.size() > 0){
                GlobalStaticVar.byPassOpportunityTrigger = true;
                update oppsToUpdate;
            }
        }
        
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: listNewQuote - List of New Quotes
    * Params: mapOldQuote - Map of Old Quotes
    * Return: none
    * Description: Method to calculate Premium field on Quote Option records for each quote
    * Revision:
    *************************************************/
    public static void calculatePremiumFields(List<Quote> listNewQuote, Map<Id,Quote> mapOldQuote){
        
        Set<String> setQuoteId = new Set<String>();
        Set<String> setOppId = new Set<String>();
        Map<String,Decimal> mapAnnualGrossFee = new Map<String,Decimal>();
        List<Quote_Option__c> listQuoteOptiontoUpdate = new List<Quote_Option__c>();
        Map<String,Integer> termLengthforQuote = new Map<String,Integer>();
        Map<String,List<Quote_Option__c>> mapQuoteOption = new Map<String,List<Quote_Option__c>>();
        List<String> listQuoteIdtoQuery = new List<String>();
        for(Quote objQuote : listNewQuote){
            if(objQuote.Status !=  mapOldQuote.get(objQuote.Id).Status){
                System.debug('objQuote.Status--->'+objQuote.Status);
                System.debug('mapOldQuote.get(objQuote.Id).Statu--->'+mapOldQuote.get(objQuote.Id).Status);
                listQuoteIdtoQuery.add(objQuote.Id);
            }
        }
        if(!listQuoteIdtoQuery.isEmpty()){
            // added by RINKU SAINI In Query Util 3rd Jan 2022
            for(Quote objQuote : QuoteQueryUtil.fetchQuotesAndQuoteOprions(listQuoteIdtoQuery)){
                if(objQuote.Status == 'Rated' && mapOldQuote.get(objQuote.Id).Status == 'In Progress'){
                    setQuoteId.add(objQuote.Id);
                    setOppId.add(objQuote.OpportunityId);
                    Integer termLength;
                    if(objQuote.Effective_Date__c != null && objQuote.ExpirationDate != null){
                        termLength = objQuote.Effective_Date__c.daysBetween(objQuote.ExpirationDate) + 1;
                        termLengthforQuote.put(objQuote.Id,termLength);
                    }
                }
            }
            // added by RINKU SAINI In Query Util 3rd Jan 2022
            for(Rating_Modifiers__c objRM : RatingModifierQueryUtil.fetchRatingModifiersByCodeAndOppId(setOppId)){
                if(objRM.Rating_Modifier_Value__c != null){
                    mapAnnualGrossFee.put(objRM.Opportunity__c, Decimal.valueOf(objRM.Rating_Modifier_Value__c));
                }
            }
            if(!setQuoteId.isEmpty())
            for(Quote_Option__c objQuoteOption : [Select Id, Limit__c, Minimum_Premium__c, Book_Premium__c, Technical_Premium__c
                                                , Actual_Premium_Annual__c, Broker_Netted_Down_Premium_Annual__c, Fee_Annual__c,Quote__r.layer__c
                                                , Technical_Premium_Discretion__c, Final_Discretion__c, Price_Adequacy__c
                                                , Actual_Premium_Final__c, Broker_Netted_Down_Premium_Final__c, Fee_Final__c
                                                , Book_Premium_Annual__c, Minimum_Premium_Annual__c, Technical_Premium_Annual__c
                                                , Bound__c, Selected__c, Option_Type__c, Final_Technical_Premium__c
                                                , Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c, Override_Fee_Percent__c
                                                , Technical_Fee__c, IPT__c, Total_Cost_To_Client__c ,Tax_Percent__c
                                                , Actual_Premium__c, Broker_Netted_Down_Premium__c, Fee__c
                                                , Change_In_Actual_Premium__c, Change_In_Broker_Netted_Down_Premium__c, Change_In_Fee__c
                                                , Change_in_IPT__c, Change_in_Total_Cost_to_Client__c
                                                , Netted_Down_Commission_Percent__c, Netted_Down_Commission_Amount__c, Netted_Down_MGA_Commission_Percent__c, Netted_Down_MGA_Commission_Amount__c
                                                , IPT_on_Broker_Netted_Down_Premium__c, Quote__c, Quote__r.Parent_Quote__c, Quote__r.Parent_Quote__r.Actual_Premium__c
                                                , Quote__r.Parent_Quote__r.Broker_Netted_Down_Premium__c, Quote__r.Parent_Quote__r.Fee__c,Quote__r.Parent_Quote__r.Rate__c
                                                , Quote__r.Parent_Quote__r.IPT_on_Broker_Netted_Down_Premium__c, Quote__r.Parent_Quote__r.Total_Cost_To_Client__c
                                                , Quote__r.Parent_Quote__r.MGA_Commission__c, Quote__r.Quote_Type__c, Quote__r.Commission_percentage__c, Quote__r.MGA_Commission__c 
                                                , NonProrated_Actual_Premium__c, NonProRated_BNDP__c, Increased_Limit_Factor__c, Rate__c, Rate_Change__c
                                                , (Select Id,Code__c,Value__c,Quote__c from Factor_Summary_Items__r where Code__c = 'Tax Percent')  from Quote_Option__c  
                                                where Quote__c in :setQuoteId Order By Option_Type__c Asc, Limit__c Asc]){
                                                    
                                                    List<Quote_Option__c> listQuoteOption = new List<Quote_Option__c>();
                                                    if(mapQuoteOption.containsKey(objQuoteOption.Quote__c)){
                                                        listQuoteOption = (mapQuoteOption.get(objQuoteOption.Quote__c));
                                                        listQuoteOption.add(objQuoteOption);
                                                        mapQuoteOption.put(objQuoteOption.Quote__c,listQuoteOption);
                                                    }
                                                    else{
                                                        listQuoteOption.add(objQuoteOption);
                                                        mapQuoteOption.put(objQuoteOption.Quote__c,listQuoteOption);
                                                    }
                                                    
                                                }
            
            Map<String,Integer> mapSelectedQO = new Map<String,Integer>();
            
            for(String quoteId : mapQuoteOption.keySet()){
                
                for(Quote_Option__c objQO : mapQuoteOption.get(quoteId)){
                    
                    if(objQO.Selected__c){
                        
                        if(mapSelectedQO.containsKey(objQO.Quote__c)){
                            Integer selectedCount = mapSelectedQO.get(objQO.Quote__c);
                            selectedCount += 1;
                            mapSelectedQO.put(objQO.Quote__c, selectedCount);
                        }
                        else{
                            mapSelectedQO.put(objQO.Quote__c, 1);
                        }
                        
                    }
                    else{
                        
                        if(!mapSelectedQO.containsKey(objQO.Quote__c)){
                            mapSelectedQO.put(objQO.Quote__c, 0);
                        }
                        
                    }
                    
                }
            }
            
            if(!mapSelectedQO.isEmpty()){
                
                for(String quoteId : mapSelectedQO.keySet()){
                    
                    if(mapSelectedQO.get(quoteId) == 0){
                        for(Quote_Option__c objQO : mapQuoteOption.get(quoteId)){
                            
                            if(objQO.Quote__r.layer__c == 'Primary'){
                                if(objQO.Limit__c == 1000000){
                                    objQO.Selected__c = true;
                                }
                            }
                            else{
                                if(objQO.Limit__c == 5000000){
                                    objQO.Selected__c = true;
                                }
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
            if(!mapQuoteOption.isEmpty()){
                
                for(Quote objQuote : listNewQuote){
                    
                    if(mapQuoteOption.containsKey(objQuote.Id)){
                        List<Quote_Option__c> listQuoteOption = new List<Quote_Option__c>();
                        listQuoteOption = QuoteOptionsTableController.calculatePremiumFields(mapQuoteOption.get(objQuote.Id),termLengthforQuote.get(objQuote.Id),mapAnnualGrossFee.get(objQuote.OpportunityId));
                        listQuoteOptiontoUpdate.addAll(listQuoteOption);
                    }
                    
                }
                
            }
            
            if(!listQuoteOptiontoUpdate.isEmpty()){
                update listQuoteOptiontoUpdate;
            }

        }
        
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: listNewQuote - List of New Quotes
    * Params: mapOldQuote - Map of Old Quotes
    * Return: none
    * Description: Method to remove Duplicate Quote Options
    * Revision:
    *************************************************/
    public static void removeDuplicateQuoteOption(List<Quote> listNewQuote, Map<Id,Quote> mapOldQuote){

        Set<String> setQuoteId = new Set<String>();
        Map<String,List<Quote_Option__c>> mapQO = new Map<String,List<Quote_Option__c>>();
        Map<String,Quote_Option__c> mapFreeFormQO = new Map<String,Quote_Option__c>();
        List<Quote_Option__c> listQOtoUpdate = new List<Quote_Option__c>();
        List<String> listQOIdsforReferrals = new List<String>();
        List<Referral_Reason__c> listReferralReasonstoDelete = new List<Referral_Reason__c>();
        
        for(Quote objQuote : (List<Quote>)Trigger.new){
            
            if(objQuote.Status == 'Rated' && mapOldQuote.get(objQuote.Id).Status != 'Rated' 
               && (objQuote.Quote_Type__c == 'Renewal' || objQuote.Quote_Type__c == 'New Business')
              ){
                  
                  setQuoteId.add(objQuote.Id);
                  
              }
            
        }

        if(!setQuoteId.isEmpty()){
            
            for(Quote_Option__c objQO : [Select Id, Limit__c, Minimum_Premium__c, Book_Premium__c, Technical_Premium__c
                                        , Actual_Premium_Annual__c, Broker_Netted_Down_Premium_Annual__c, Fee_Annual__c,Quote__r.layer__c
                                        , Technical_Premium_Discretion__c, Final_Discretion__c, Price_Adequacy__c
                                        , Actual_Premium_Final__c, Broker_Netted_Down_Premium_Final__c, Fee_Final__c
                                        , Book_Premium_Annual__c, Minimum_Premium_Annual__c, Technical_Premium_Annual__c
                                        , Bound__c, Selected__c, Option_Type__c, Final_Technical_Premium__c
                                        , Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c, Override_Fee_Percent__c
                                        , Technical_Fee__c, IPT__c, Total_Cost_To_Client__c ,Tax_Percent__c
                                        , Actual_Premium__c, Broker_Netted_Down_Premium__c, Fee__c
                                        , Change_In_Actual_Premium__c, Change_In_Broker_Netted_Down_Premium__c, Change_In_Fee__c
                                        , Change_in_IPT__c, Change_in_Total_Cost_to_Client__c, NonProrated_Actual_Premium__c, NonProRated_BNDP__c
                                        , IPT_on_Broker_Netted_Down_Premium__c, Quote__c, Quote__r.Parent_Quote__c, Quote__r.Parent_Quote__r.Actual_Premium__c
                                        , Quote__r.Parent_Quote__r.Broker_Netted_Down_Premium__c, Quote__r.Parent_Quote__r.Fee__c
                                        , Quote__r.Parent_Quote__r.IPT_on_Broker_Netted_Down_Premium__c, Quote__r.Parent_Quote__r.Total_Cost_To_Client__c
                                        , Quote__r.Quote_Type__c  from Quote_Option__c  where Quote__c in :setQuoteId ]){
                                            
                                            if(objQO.Limit__c != null){
                                                if(mapQO.containsKey(objQO.Quote__c)){
                                                    List<Quote_Option__c> listQO = new List<Quote_Option__c>();
                                                    listQO = mapQO.get(objQO.Quote__c);
                                                    listQO.add(objQO);
                                                    mapQO.put(objQO.Quote__c,listQO);
                                                    if(objQO.Option_Type__c == 'Free Form'){
                                                        mapFreeFormQO.put(objQO.Quote__c,objQO);
                                                    }
                                                }
                                                else{
                                                    List<Quote_Option__c> listQO = new List<Quote_Option__c>();
                                                    listQO.add(objQO);
                                                    mapQO.put(objQO.Quote__c,listQO);
                                                    if(objQO.Option_Type__c == 'Free Form'){
                                                        mapFreeFormQO.put(objQO.Quote__c,objQO);
                                                    }
                                                }
                                            }
                                        }
            
            if(!mapQO.isEmpty()){

                for(String quoteId : mapQO.keySet()){

                    if(mapFreeFormQO.containsKey(quoteId)){
                        
                        List<Quote_Option__c> listQO = mapQO.get(quoteId);
                        Quote_Option__c objFreeFromQO = mapFreeFormQO.get(quoteId);
                        for(Quote_Option__c objQO : listQO){
                            if(objQO.Option_Type__c == 'Fixed Limit' && objQO.Limit__c == objFreeFromQO.Limit__c){
                                listQOIdsforReferrals.add(objFreeFromQO.Id);
                                SObject currentRecord = (SObject)objFreeFromQO;
                                Set<String> fieldsToExcludeForClearOut = new Set<String>{'Azure_ID__c', 'Option_Type__c',
                                'Quote__c'};
                                SObjectType objToken = Schema.getGlobalDescribe().get('Quote_Option__c');
                                DescribeSObjectResult objDef = objToken.getDescribe();
                                Map<String, SObjectField> fieldsSobject = objDef.fields.getMap();
                                Map<String, Object> fields = currentRecord.getPopulatedFieldsAsMap();
                                System.debug('fields--->'+fields);
                                Type classType = Type.forName('Quote_Option__c');
                                SObject freeFormQO = (SObject)JSON.deserialize('{}', classType);
                                SObject fixedLimitQO = (SObject)JSON.deserialize('{}', classType);
                                for (String field : fields.keySet()){
                                    if (!fieldsToExcludeForClearOut.contains(field) && !field.contains('__r')){
                                        if (currentRecord.get(field)!=null && fieldsSobject.get(field).getDescribe().isUpdateable()){
                                            if ('Bound__c'.equals(field)){
                                                freeFormQO.put(field, false);
                                                fixedLimitQO.put(field, true);
                                            }else if ('Selected__c'.equals(field)){
                                                freeFormQO.put(field, false);
                                                fixedLimitQO.put(field, true);
                                            }else {
                                                freeFormQO.put(field, null);
                                                fixedLimitQO.put(field, currentRecord.get(field));
                                            }
                                        } 
                                        else if ('Id'.equals(field)){
                                            freeFormQO.put(field, currentRecord.get(field));
                                            fixedLimitQO.put(field, objQO.Id);
                                        }
                                    }
                                }
                                Quote_Option__c tempFreeFormQO = new Quote_Option__c();
                                tempFreeFormQO = (Quote_Option__c)freeFormQO;
                                //listQOtoUpdate.add(tempFreeFormQO);
                                Quote_Option__c tempFixedLimitQO = new Quote_Option__c();
                                tempFixedLimitQO = (Quote_Option__c)fixedLimitQO;
                                System.debug('tempFixedLimitQO'+tempFixedLimitQO);
                                listQOtoUpdate.add(tempFixedLimitQO);
                                listQOtoUpdate.add(tempFreeFormQO);
                            }
                        }
                        
                    }

                }

                if(!listQOIdsforReferrals.isEmpty()){
                    listReferralReasonstoDelete = [Select Id from Referral_Reason__c where Quote_Option__c in :listQOIdsforReferrals];
                }

            }

            if(!listQOtoUpdate.isEmpty()){
                update listQOtoUpdate;
            }

            if(!listReferralReasonstoDelete.isEmpty()){
                delete listReferralReasonstoDelete;
            }

        }

    }
    public static void allowRenewalOnParentPolicy(List<Quote> listNewQuote, Map<Id,Quote> mapOldQuote){
        Set<Id> quoteIds = new Set<Id>();
        for(Quote quote : listNewQuote){
            if(mapOldQuote.get(quote.Id).Status != quote.Status && quote.Status=='Closed'){
                 quoteIds.add(quote.Id);    
            }
        }
        
        List<Policy__c> policyList = new List<Policy__c>();
        Set<Id> policyIds = new Set<Id>();
        Set<Id> activeOppIds = new Set<Id>();
        List<Opportunity> OpportunityList = new List<Opportunity>();
        
        for(Quote quot : [select id,Parent_Quote__c,OpportunityId,Opportunity.Transaction_Status__c,Policy__c
                          from quote where Id IN:quoteIds And Parent_Quote__c!=null ]){
                              
            Quote parentQuote  = handleParentPolicyUpdate(quot);
            
            if(parentQuote != null){
                Policy__c pol = new Policy__c();
                pol.Id =  parentQuote.Policy__c;
                pol.Renewal_Completed__c = false;     
                policyIds.add(pol.Id);
                policyList.add(pol);
                                
                Opportunity opp = new Opportunity();
                opp.Id =  parentQuote.OpportunityId; 
                opp.Transaction_Status__c = 'Active';   
                activeOppIds.add(opp.Id);                             
                OpportunityList.add(opp); 
            }     
        }
        
        if(!policyIds.isEmpty()){
            for(Transactions__c transrecord : [select id,Submission__c from Transactions__c where Submission__c Not IN:activeOppIds And Policy__c In: policyIds]){
                Opportunity opp = new Opportunity();
                opp.Id =  transrecord.Submission__c; 
                opp.Transaction_Status__c = 'InActive';
                OpportunityList.add(opp);
            }
        }
        
        if(!policyList.isEmpty()){
            update policyList;
        }
        
        if(!OpportunityList.isEmpty()){
            update OpportunityList;
        }
       
   }
    public static Quote handleParentPolicyUpdate(Quote quote){
        
        for(Quote parentQuotes : [select id,Parent_Quote__c,OpportunityId,Parent_Quote__r.Policy__c,Opportunity.Transaction_Status__c,Opportunity.Id,Policy__c,status from Quote where Id=:quote.Parent_Quote__c]){
            if(parentQuotes.Policy__c != quote.Policy__c && parentQuotes.status=='Bound'){
                return parentQuotes;
            }
            else if(parentQuotes.Parent_Quote__r.Policy__c != null){
              return  handleParentPolicyUpdate(parentQuotes);
            }
        }
        return null;
    }

}