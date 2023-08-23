/*************************************************
* Class Name: RenewalPolicyController
* Author: Giang Phan
* Updated: 
* Description: RenewalPolicyController
* 
*************************************************/

public with sharing class RenewalPolicyController {

        @AuraEnabled
        public static ResponseResult renewalController(String policyId) {
            ResponseResult resResult = new ResponseResult();
            if(String.isBlank(policyId)) {
                return resResult;
            }
    
            //Check if Quote Status is Bound Pending show on the message error.
            List<Quote> quots = [SELECT Id,Status FROM Quote WHERE Policy__r.Id =: policyId];
            if(quots[0].Status == 'Bound Pending'){
                resResult.msgError = 'Bound Pending cannot be renewed.';//Label.Renewal_Bound_Pending_Error;
                resResult.isSuccess = false;
                return resResult;
            }
    
            //Renewal manually on Policy query
            String strSoql = getPolicyQuery(policyId);
            List<sObject> oppts = Database.query(strSoql);
            //Call method Clone Opportunity Renewal
            resResult = cloneOpportunityRenewal(oppts);
            return resResult;
        }
        
        //-------------- Clone Opportunity Renewal ----------------------//
        public static ResponseResult cloneOpportunityRenewal(List<sObject> oppts){
            Savepoint sp = Database.setSavepoint();
            ResponseResult resResult = new ResponseResult();
            try{
                
                // generate new opportunity
                Map<Id, Opportunity> parentOpptId_newOpptMap = new Map<Id, Opportunity>();
                for(sObject oppt : oppts) {
                    Opportunity newOppt = generateOpportunity((Opportunity)oppt);
                    parentOpptId_newOpptMap.put(oppt.Id, newOppt);
                }
                
                if(parentOpptId_newOpptMap.isEmpty()) {
                    resResult.msgError = 'Renewal is not created.';//Label.Renewal_Error;
                    return resResult;
                }
                
                insert parentOpptId_newOpptMap.values();
              
                
                List<Id> oppIds = new List<Id>(parentOpptId_newOpptMap.keySet());
                
                resResult.opptClonedId = parentOpptId_newOpptMap.values()[0].Id;
    
                // --- Clone all Broker Account records ---
                // get brokers
                List<Broker_Account__c> brokers = getBrokerAccounts(oppIds);
                // generate new broker accounts
                List<Broker_Account__c> newbrokers = generateNewBrokerAccount(brokers, parentOpptId_newOpptMap);
                
                //put field Update
                Map<String, Object> fieldUpdateMap = new Map<String, Object>();
                fieldUpdateMap.put('Policy__c', null);
                
                // Quote Business
                List<Quote> quoteBusiness = getQuoteBusinessQuery(oppIds);

                Map<String, Quote> quoteBusinessMap = generateQuoteMap(quoteBusiness);
               
                for(String key : quoteBusinessMap.keySet()){
                    if(parentOpptId_newOpptMap.containsKey(key)) {
                        fieldUpdateMap.put('OpportunityId', parentOpptId_newOpptMap.get(key).Id);
                        fieldUpdateMap.put('Effective_Date__c', parentOpptId_newOpptMap.get(key).Effective_Date__c);
                        fieldUpdateMap.put('ExpirationDate', parentOpptId_newOpptMap.get(key).Expiration_Date__c);
                        fieldUpdateMap.put('CloseDate__c', parentOpptId_newOpptMap.get(key).CloseDate);
                        fieldUpdateMap.put('Quote_Type__c', 'Renewal');
                    }
                    GlobalStaticVar.byPassQuoteTrigger = true;
                    CloneQuoteHandler.cloneQuoteWithChildren(quoteBusinessMap.get(key).Id, fieldUpdateMap);
                }
    
                if(!newbrokers.isEmpty()) insert newbrokers;
       
                for(sObject oppt : oppts) {
                    oppt.put('Renewed__c',true);
                }           
                update oppts;
    
                resResult.msgError = '';
                resResult.isSuccess = true;
                return resResult;
    
            } catch (Exception ex) {
                System.debug('@@@Exception: ' + ex.getMessage() + '--' + ex.getLineNumber());
                resResult.msgError = ex.getMessage();
                Database.rollback(sp);
                return resResult;
            }
        }
    
        //-------------- Respon result ------------------//
        public class ResponseResult {
            @AuraEnabled public Boolean isSuccess {get; set;}
            @AuraEnabled public String msgError {get; set;}
            @AuraEnabled public String opptClonedId {get; set;}
            public ResponseResult() {
                isSuccess = false;
                msgError = '';
                opptClonedId = '';
            }
        }
    
        //-------------- Generate Opportunity ------------------//
        public static Opportunity generateOpportunity(sObject obj) {
            Opportunity result = new Opportunity();
            if (obj == null) return result;
    
            Date expDate = (Date)obj.get('Expiration_Date__c');
            Date newExpDatePlusAYear = expDate.addYears(1);
            Date newEffDatePlusAMonth = expDate.addDays(30);
            
            result = (Opportunity)obj.clone(false, true, false, false);
            //result.Parent_Opportunity__c = (String)obj.get('Id');
            result.StageName = 'Qualified';
            result.Type = 'Renewal';
            result.Received_Date__c = Date.today();
            result.CloseDate = newEffDatePlusAMonth;
            result.Effective_Date__c = expDate;
            result.Expiration_Date__c  = newExpDatePlusAYear;
            result.Prior_Policy__c = (String)obj.get('Policy__c');
            result.Policy__c = null;
            result.Azure_ID__c = null;
            result.Probability = 0;
            result.Create_From_Quote_Process__c = false;
            
            return result;
        }
        
        // Crreated by Giang Phan get Policy Query Opportunity Object ---------//
        public static String getPolicyQuery(String policyId){
            String result = '';
            String obj = 'Opportunity';
            List<String> params = new List<String>();
            params.add('Expiration_Date__c != NULL');
            params.add('(Policy__r.Policy_Status__c = \'Active\' Or Policy__r.Policy_Status__c = \'Bound\')');
            params.add('StageName = \'Closed Won\'');
            //params.add('Product__r.Renewable__c = true');
            params.add('Product__r.IsActive = true');
            //params.add('Renewed__c = false');
            //params.add('CreatedBy.IsActive = true'); Removed for US: 53350
            params.add('Policy__r.Id ' + ' = \'' + policyId + '\'');
    
            String condition = String.join(params, ' AND ');
            result = CommonUtil.buildQuerySelectAll(obj, condition);
            return result;
        }
    
        //-------------- Quote ----------------------//
        public static List<Quote> getQuoteBusinessQuery(List<Id> ids) {
            List<Quote> result = new List<Quote>();
            String obj = 'Quote';      
            List<String> params = new List<String>();
            params.add('OpportunityId IN (\''+ String.join(ids,'\',\'') + '\')');
            params.add('Status = \'Bound\'');
    
            String condition = String.join(params, ' AND ');
            condition += ' Order By Endorsement_Effective_Date__c Desc NULLS LAST Limit 1';       
            String query = CommonUtil.buildQuerySelectAll(obj, condition);
            result = Database.query(query);
    
            return result;
        }
    
        //-------------- Generate Quote Map ----------------------//
        public static Map<String, Quote> generateQuoteMap(List<Quote> items) {
            Map<String, Quote> result = new Map<String, Quote>();
            for (Quote item : items) {
                if(!result.containsKey(item.OpportunityId)) {
                    result.put(item.OpportunityId, item);
                } 
            }
            
            return result;
        }
        
        
        //-------------- Broker Account-------------------//
        public static List<Broker_Account__c> getBrokerAccounts(List<Id> ids) {
            List<Broker_Account__c> result = new List<Broker_Account__c>();
            if (ids == null || ids.isEmpty()) return result;
    
            String obj = 'Broker_Account__c';
            String condition = 'Opportunity__c IN (\''+ String.join(ids,'\',\'') + '\')';
            String query = CommonUtil.buildQuerySelectAll(obj, condition);
    
            result = Database.query(query);
    
            return result;
        }
        
        //-------------- Generate New Broker Account-------------------//
        public static List<Broker_Account__c> generateNewBrokerAccount(List<Broker_Account__c> items, 
                                                                Map<Id, Opportunity> parentOpptId_newOpptMap) {
            List<Broker_Account__c> result = new List<Broker_Account__c>();
            for (Broker_Account__c item : items) {
                Broker_Account__c obj = item.clone(false,true,false,false);
                if(parentOpptId_newOpptMap.containsKey(item.Opportunity__c)) {
                    obj.Opportunity__c = parentOpptId_newOpptMap.get(item.Opportunity__c).Id;
                }
                
    
                result.add(obj);
            }
            return result;
        }       
}