/**
 * @description       : 
 * @author            : Maeran Shaikh
 * @group             : 
 * @last modified on  : 01-28-2022
 * @last modified by  : Maeran Shaikh
**/
public with sharing class CloneOpportunityController {
    
    @AuraEnabled
    public static ResponseResult cloneOpportunity(String oppId) {
        ResponseResult resResult = new ResponseResult();
        if(String.isBlank(oppId)) {
            return resResult;
        }
        
        List<Opportunity> oppList = [SELECT Id,Account.Name,Account.BillingAddress,Account.KYC_Date__c, AccountId, RecordType.Name, Name, StageName, Amount, CloseDate, Type, Pricebook2Id, ContactId, 
                                     ContractId, Attachment_Point__c, Eligibility_Approver__c, Eligibility_Approval_Date_Time__c, Loss_Reason__c, 
                                     Innovisk_Entity_ID__c, Product__c, Azure_ID__c, Create_From_Quote_Process__c, Account_Clearance__c,Current_Liabilities__c,
                                     Renewed__c,Competition_Target_Price__c, Policy_Link__c, Expiration_Date__c, MPL_Professional_Services__c, Effective_Date__c, Service_Classification__c,
                                     Industry__c, Prior_Policy__c, Retroactive_Date__c, Retroactive_Date_Docs__c, Eplace_Score__c, Service_to_Run__c,Current_Assets__c,
                                     Parent_Opportunity__c, Agency__c, Received_Date__c, Source__c, Effective_Date_Docs__c, UW_Status__c, Coverage_Product_Options__c,
                                     Policy__c, Product_Name__c, AnnualRevenue__c, Cash_Flow_From_Operating_Activities__c, Total_Assets__c, Total_Revenues__c,Total_Liabilities__c,
                                      Main_Profession__c, Largest_Work_Type__c, Professional_Business_Description__c, Tax_Country__c,Net_Income__c,Retained_Earnings__c,Long_Term_Debt__c,
                                     Competing_Insurer__c,Transaction_Status__c, Submission_Status__c, (select Id,Rating_Modifier_Code__c,Rating_Modifier_Value__c,Name from Rating_Modifiers__r)
                                     FROM Opportunity WHERE Id =: oppId limit 1];
        
        
        if(oppList.isEmpty()){
            return null;
        }
        Integer numberDaysDue;
        if( oppList[0].Received_Date__c != null ){ //added by Jai #54985
            numberDaysDue = oppList[0].Received_Date__c.daysBetween(Date.today());
        }
        //validations
        system.debug('numberDaysDue-->'+numberDaysDue);
        if(numberDaysDue > 365){
            resResult.msgError = 'Can not clone Submission older than 1 year';
            resResult.isSuccess = false;
            return resResult;
        }
        resResult = cloneOpportunityDetails(oppList);
        return resResult;
    }
    
    private static ResponseResult cloneOpportunityDetails(List<Opportunity> oppList){
        Savepoint sp = Database.setSavepoint();
        ResponseResult resResult = new ResponseResult();
        set<string> Ids = new set<string>();
        try{
            
            // generate new opportunity
            Map<Id, Opportunity> parentOpptId_newOpptMap = new Map<Id, Opportunity>();
            for(Opportunity opp : oppList) {
                Opportunity newOppt = generateOpportunity(opp);
                Ids.add(opp.Id);
                parentOpptId_newOpptMap.put(opp.Id, newOppt);
            }
            
            if(parentOpptId_newOpptMap.isEmpty()) {
                resResult.msgError = 'Copy Submission Failed.';
                return resResult;
            }
            if(!parentOpptId_newOpptMap.values().isEmpty()) insert parentOpptId_newOpptMap.values();
            
            //Quote Process
            List<Quote_Process__c> quoteProcessClone = new List<Quote_Process__c>();
            List<Opportunity> newOpp = [SELECT Id,AccountId FROM Opportunity WHERE Id =: parentOpptId_newOpptMap.values()[0].Id];
            
            List<Quote_Process__c> oldQuoteProcess = [SELECT Id,Account__c,Status__c,Submission_Product__c,Submission_Stage__c,Submission__c,Record_Type__c,Product__c FROM Quote_Process__c 
                                                      WHERE Submission__c IN:Ids];
            Quote_Process__c qp = new Quote_Process__c();
            if(!oldQuoteProcess.isEmpty()){
                qp = oldQuoteProcess[0].clone(false, true, false, false);
                if(!newOpp.isEmpty()){
                    qp.Account__c = newOpp[0].AccountId;
                }
                quoteProcessClone.add(qp);
            }
            if(!quoteProcessClone.isEmpty()){
                TriggerHandler.bypass('QuoteProcessTriggerBaseHandler');  
                insert quoteProcessClone;
                TriggerHandler.clearBypass('QuoteProcessTriggerBaseHandler');
            }
            
            //Update Quote Process to get QP link on submission
            qp.Submission__c = newOpp[0].Id;
            TriggerHandler.bypass('QuoteProcessTriggerBaseHandler');  
            update quoteProcessClone;
            TriggerHandler.clearBypass('QuoteProcessTriggerBaseHandler');
            
            
            //Clone Additional Insured
            List<Additional_Insured__c> addInsured = [select Id,Name,Additional_Insured_Account__c,Submission__c 
                                                      from Additional_Insured__c where Submission__c IN: Ids];  
            List<Additional_Insured__c> additionalInsuredList = new List<Additional_Insured__c>();
            for(Additional_Insured__c addIn: addInsured)  {
                Additional_Insured__c addInsurer =  addIn.clone(false, true, false, false);
                addInsurer.Submission__c = newOpp[0].Id;
                additionalInsuredList.add(addInsurer);
            }   
            if(!additionalInsuredList.isEmpty()){
             //  TriggerHandler.bypass('AdditionalInterestTriggerBaseHandler');
                insert additionalInsuredList;   
             //  TriggerHandler.clearBypass('AdditionalInterestTriggerBaseHandler');
			
            }
            
            //Old Rating Modifiers
            Map<string,string> oldratmodMap = new  Map<string,string>();
            List<Rating_Modifiers__c> ratingModList = [SELECT Id,Name,Rating_Modifier_Code__c,Rating_Modifier_Value__c FROM Rating_Modifiers__c 
                                                       WHERE Opportunity__c IN: Ids];
            for(Rating_Modifiers__c rad: ratingModList){
                oldratmodMap.put(rad.Rating_Modifier_Code__c, rad.Rating_Modifier_Value__c);
            }
            
            //New Rating Modifiers
            List<Rating_Modifiers__c> newRatingModList = [SELECT Id,Name,Rating_Modifier_Code__c,Rating_Modifier_Value__c FROM Rating_Modifiers__c 
                                                          WHERE Opportunity__c =: parentOpptId_newOpptMap.values()[0].Id];
            List<Rating_Modifiers__c> updateRatingMod = new List<Rating_Modifiers__c>();
            
            for(Rating_Modifiers__c newRat : newRatingModList){
                if(string.isNotBlank(oldratmodMap.get(newRat.Rating_Modifier_Code__c))){
                    newRat.Rating_Modifier_Value__c = oldratmodMap.get(newRat.Rating_Modifier_Code__c);
                    updateRatingMod.add(newRat);
                }
            }
            if(!updateRatingMod.isEmpty()) {
                TriggerHandler.bypass('RatingModifiersTriggerBaseHandler'); 
                update updateRatingMod;
                TriggerHandler.clearBypass('RatingModifiersTriggerBaseHandler');
            }
            
            //Old UW Analysis
            Map<string,UW_Analysis__c> oldUWAnalysisMap = new  Map<string,UW_Analysis__c>();
            List<UW_Analysis__c> oldUWAnalysisList = [SELECT Id,UW_Analysis_Name__c,Rating_Factor__c,UW_Analysis_Template__c,Sort_Order__c,UW_Analysis_Code__c,Split_Percentage__c,Amount__c,Base_Rates__c,Criteria__c FROM UW_Analysis__c 
                                                      WHERE Submission__c IN: Ids];
            for(UW_Analysis__c uw: oldUWAnalysisList){
                oldUWAnalysisMap.put(uw.UW_Analysis_Name__c, uw);
            }
            
            //New UW Analysis
            List<UW_Analysis__c> newUWAnalysisList = [SELECT Id,UW_Analysis_Name__c,Split_Percentage__c,Amount__c FROM UW_Analysis__c 
                                                      WHERE Submission__c =: parentOpptId_newOpptMap.values()[0].Id];
            List<UW_Analysis__c> updateUWAnalysisList = new List<UW_Analysis__c>();
            set<string> newUWAnalysisName = new set<string>();
            
            for(UW_Analysis__c newUW : newUWAnalysisList){
                newUWAnalysisName.add(newUW.UW_Analysis_Name__c);
                if(oldUWAnalysisMap.containsKey(newUW.UW_Analysis_Name__c) && string.isNotBlank(oldUWAnalysisMap.get(newUW.UW_Analysis_Name__c).UW_Analysis_Name__c)){
                    newUW.Split_Percentage__c = oldUWAnalysisMap.get(newUW.UW_Analysis_Name__c).Split_Percentage__c;
                    newUW.Amount__c = oldUWAnalysisMap.get(newUW.UW_Analysis_Name__c).Amount__c;
                    updateUWAnalysisList.add(newUW);
                }
            }
            if(!updateUWAnalysisList.isEmpty()) {
                TriggerHandler.bypass('UWAnalysisTriggerHandler');
                update updateUWAnalysisList;
                TriggerHandler.clearBypass('UWAnalysisTriggerHandler');
                
            }
            
            List<UW_Analysis__c> newUWList = new List<UW_Analysis__c>();
            for(UW_Analysis__c oldUW : oldUWAnalysisList){
                if(!newUWAnalysisName.isEmpty() ){
                    if(!newUWAnalysisName.contains(oldUW.UW_Analysis_Name__c)){
                        UW_Analysis__c uwClone = oldUW.clone(false, true, false, false);
                        uwClone.Submission__c = parentOpptId_newOpptMap.values()[0].Id;
                        newUWList.add(uwClone);
                    } 
                }
                
            }
            if(!newUWList.isEmpty()){
                TriggerHandler.bypass('UWAnalysisTriggerHandler');
                insert newUWList; 
                TriggerHandler.clearBypass('UWAnalysisTriggerHandler');
            } 
            
            
            List<Id> oppIds = new List<Id>(parentOpptId_newOpptMap.keySet());
            resResult.oppClonedId = parentOpptId_newOpptMap.values()[0].Id;
            
            Map<String, Object> fieldUpdateMap = new Map<String, Object>();
            fieldUpdateMap.put('Policy__c', null);
            fieldUpdateMap.put('Parent_Quote__c', null);
            
            //Quote
            List<Quote> quoteBusiness = getQuotes(oppIds);
            
            Map<String, Quote> quoteBusinessMap = generateQuoteMap(quoteBusiness);
            Map<String, Quote> quoteBusinessIdMap = quoteBusinessIdMap(quoteBusiness);
            
            for(String key : quoteBusinessMap.keySet()){
                if(parentOpptId_newOpptMap.containsKey(key)) {
                    fieldUpdateMap.put('OpportunityId', parentOpptId_newOpptMap.get(key).Id);
                    fieldUpdateMap.put('Effective_Date__c', parentOpptId_newOpptMap.get(key).Effective_Date__c);
                    fieldUpdateMap.put('ExpirationDate', parentOpptId_newOpptMap.get(key).Expiration_Date__c);
                    fieldUpdateMap.put('CloseDate__c', parentOpptId_newOpptMap.get(key).CloseDate);
                    fieldUpdateMap.put('Quote_Type__c', 'New Business');
                    fieldUpdateMap.put('Broker__c', null);
                    fieldUpdateMap.put('Commission_percentage__c', null);
                }
            }
            
            for(String quoteId : quoteBusinessIdMap.keySet()){
                GlobalStaticVar.byPassQuoteTrigger = true;
                GlobalStaticVar.byPassFreeFormEndorsementTrigger = true;
                GlobalStaticVar.byPassSubjectivityTrigger = true;
                TriggerHandler.bypass('QuoteTriggerBaseHandler');
                TriggerHandler.bypass('AdditionalInterestTriggerBaseHandler');
                TriggerHandler.bypass('SubjectivityTriggerBaseHandler');
                TriggerHandler.bypass('InsurerLayerLimitTriggerHandler');
                //TriggerHandler.bypass('CoverageLineItemTriggerBaseHandler');
                TriggerHandler.bypass('FreeFormEndorsementTriggerBaseHandler');
                //TriggerHandler.bypass('RatingModifierFactorTriggerHandler');
                //TriggerHandler.bypass('QuoteOptionTriggerHandler');
                                
                ResultResponse response = CloneQuoteHandler.cloneQuoteWithChildren(quoteId, fieldUpdateMap);
                
                TriggerHandler.clearBypass('QuoteTriggerBaseHandler');
                TriggerHandler.clearBypass('AdditionalInterestTriggerBaseHandler');
                TriggerHandler.clearBypass('SubjectivityTriggerBaseHandler');
                TriggerHandler.clearBypass('InsurerLayerLimitTriggerHandler');
                //TriggerHandler.clearBypass('CoverageLineItemTriggerBaseHandler');
                TriggerHandler.clearBypass('FreeFormEndorsementTriggerBaseHandler');
                //TriggerHandler.clearBypass('RatingModifierFactorTriggerHandler');
                //TriggerHandler.clearBypass('QuoteOptionTriggerHandler');

                if(response.data != null){
                    Quote testQuote = (Quote)response.data;
                    
                    /******* New Lines for 54090 Ticket *****/
                    testQuote.Master_Binder__c = null;
                    testQuote.Policy_Wording_Document__c =  null;
                    testQuote.IPID_Document__c = null;
                    
                    update testQuote;
                    
                    
                    
                    Quote objClonedQuote = [SELECT Id, Layer__c, Quote_Type__c FROM Quote WHERE Id =: testQuote.Id];
                    if(objClonedQuote.Quote_Type__c == 'New Business'){
                        List<Quote_Option__c> lstExistentQuoteOptions = [SELECT Id FROM Quote_Option__c WHERE Quote__c =: testQuote.Id];
                        if(!lstExistentQuoteOptions.isEmpty()){
                            delete lstExistentQuoteOptions;
                        }
                        Integer count = 0;
                        count = (objClonedQuote.Layer__c == 'Primary') ? 10 : 6;
                        List<Quote_Option__c> lstQuoteOptionsForInsert = new List<Quote_Option__c>();
                        lstQuoteOptionsForInsert.addAll(cloneRecords.createQuoteOptions(count,testQuote.Id,'Fixed Limit'));
                        lstQuoteOptionsForInsert.addAll(cloneRecords.createQuoteOptions(1,testQuote.Id,'Free Form'));
                        if(!lstQuoteOptionsForInsert.isEmpty()){
                            //TriggerHandler.bypass('QuoteOptionTriggerHandler');
                            insert lstQuoteOptionsForInsert;
                            //TriggerHandler.clearBypass('QuoteOptionTriggerHandler');
                            
                        }
                    }
                }
            }
            
            resResult.msgError = '';
            resResult.isSuccess = true;
            System.debug('resResult: ' + resResult);
            return resResult;
            
            
        } catch (Exception ex) {
            System.debug('@@@Exception: ' + ex.getMessage() + '--' + ex.getLineNumber());
            resResult.msgError = ex.getMessage();
            Database.rollback(sp);
            return resResult;
        }
    }
    
    private static Opportunity generateOpportunity(Opportunity obj) {
        Opportunity result = new Opportunity();
        if (obj == null) return result;
        
        result = obj.clone(false, true, false, false);
        result.Name = obj.Account.Name + ' PI '+ datetime.now().format('MM/dd/yyyy');
        if(obj.StageName == 'New')  result.StageName = 'New';
        else result.StageName = 'Qualified';
        result.Type = 'New Business';
        result.Submission_Status__c = null;
        result.Received_Date__c = Date.today();
        result.CloseDate = Date.today() + 90;
        result.Effective_Date__c = Date.today();
        result.Expiration_Date__c  = Date.today()+364;
        result.Policy__c = null;
        result.Azure_ID__c = null;
        result.Transaction_Status__c = 'Active';
        return result;
    }
    
    private static List<Quote> getQuotes(List<Id> ids) {
        List<Quote> result = new List<Quote>();
        List<Quote>  excess = [SELECT Id,OpportunityId, Status, Layer__c, CreatedDate FROM Quote where OpportunityId IN: ids 
                               AND Layer__c = 'Excess' 
                               AND Status != 'Closed' order by CreatedDate asc Limit 1];
        List<Quote> primary = [SELECT Id,OpportunityId, Status, Layer__c, CreatedDate FROM Quote where OpportunityId IN: ids 
                               AND Layer__c = 'Primary' 
                               AND Status != 'Closed' order by CreatedDate asc Limit 1];
        if(!excess.isEmpty()) result.add(excess[0]);
        if(!primary.isEmpty()) result.add(primary[0]);
        
        system.debug('result getQuote-->'+result);
        return result;
    }
    
    private static Map<String, Quote> generateQuoteMap(List<Quote> items) {
        Map<String, Quote> result = new Map<String, Quote>();
        for (Quote item : items) {
            result.put(item.OpportunityId, item);
        }
        return result;
    }
    
    private static Map<String, Quote> quoteBusinessIdMap(List<Quote> items) {
        Map<String, Quote> result = new Map<String, Quote>();
        for (Quote item : items) {
            result.put(item.Id,item);
        }
        return result;
    }
        
    public class ResponseResult {
        @AuraEnabled public Boolean isSuccess {get; set;}
        @AuraEnabled public String msgError {get; set;}
        @AuraEnabled public String oppClonedId {get; set;}
        public ResponseResult() {
            isSuccess = false;
            msgError = '';
            oppClonedId = '';
        }
    }
}