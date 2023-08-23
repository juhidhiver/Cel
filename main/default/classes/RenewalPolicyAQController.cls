public with sharing class RenewalPolicyAQController {
    
    @AuraEnabled
    public static ResultWrapper renewalController(String policyId) {
        
        ResultWrapper resResult = new ResultWrapper();
        if(String.isBlank(policyId)) {
            return resResult;
        }
                
        List<Transactions__c> submissionPolicy = [SELECT Name, Id, Policy__c, Submission__c 
                                                  FROM Transactions__c 
                                                  WHERE Policy__c =:policyId 
                                                  AND Submission__r.Transaction_Status__c = 'Active' LIMIT 1];
        List<Policy__c> policy = [SELECT Id,Policy_Status__c,Expiration_Date__c,Renewal_Completed__c FROM Policy__c WHERE Id =: policyId];

        //Validations.
        if(policy.isEmpty()){
            resResult.error = 'Policy Not Found.';
            resResult.isSuccess = false;
            return resResult;   
        }
        
        /*if(policy[0].Expiration_Date__c < Date.today()){
            resResult.error = 'Expired Policy Cannot be Renewed.';
            resResult.isSuccess = false;
            return resResult;   
        }*/
        
        if(policy[0].Renewal_Completed__c){
            resResult.error = 'Renewal is already initiated on this Policy.';
            resResult.isSuccess = false;
            return resResult;   
        }
        
        if(policy[0].Policy_Status__c == 'Cancelled'){
            resResult.error = 'Cancelled Policy cannot be renewed.';
            resResult.isSuccess = false;
            return resResult;
        }
        
        if(submissionPolicy.isEmpty()){
            resResult.error = 'No Active Submission/Transaction record found on this Policy';
            return resResult;
        }
        
        
        if(!submissionPolicy.isEmpty()){
            List<Quote> quoteList = [select Id, status from Quote where OpportunityId =: submissionPolicy[0].Submission__c
                                     AND Status NOT IN ('Bound','Closed','Cancelled','Correction')];
            
            if(!quoteList.isEmpty()){
                resResult.error = 'All open Quotes on related Submission must be bind or closed before initiating Renewal.';
                return resResult;
            }
        }
        
      if(policy[0].Expiration_Date__c  != null){
             Integer numberDaysDue = Date.today().daysBetween(policy[0].Expiration_Date__c);
            if(numberDaysDue > 45){
            resResult.error = 'Renewal can be done 45 days prior to the expiry date of the policy';
            resResult.isSuccess = false;
            return resResult;
            }
        }
       

        ResultWrapper renewalSubmission;
        try {
             renewalSubmission = cloneRecords.policyRenewal(policyId);
        }catch(exception ex){
            system.debug('error: '+ex.getMessage()+' '+ex.getLineNumber());
        }
        
        /*** Added If Else i.e. fix for CD-157****/
        if(renewalSubmission!=null && renewalSubmission.quoteList != null){
            resResult.quoteList = renewalSubmission.quoteList;
            resResult.layer = renewalSubmission.layer;
            resResult.oppId = renewalSubmission.oppId;
            resResult.isSuccess = true;
            
            //Binder
            ResultWrapper binderList = getMasterBinders(policyId);
            resResult.masterBinder = binderList.masterBinder;
            resResult.showBinder = binderList.showBinder;
            resResult.error = binderList.error;
            system.debug('resResult-->'+resResult);
            return resResult;
        }
        else{
            resResult.error = 'There is no bound quote on submission';
            return resResult;
        }
    }
    
    @AuraEnabled
    public static ResultWrapper createRenewalQuote(string clonedoppId,String policyId,List<Quote> quoteList,string binderPrimary, string binderExcess) {
        ResultWrapper resResult = new ResultWrapper();
        
        ResultWrapper renewalSub;
        try {
            renewalSub = cloneRecords.createRenewalQuotes(clonedoppId,policyId,quoteList,binderPrimary,binderExcess);
            system.debug('renewalSub-->'+renewalSub);
        }catch(exception ex){
            system.debug('error: '+ex.getMessage()+' '+ex.getLineNumber());
            resResult.error = ex.getMessage();
        }
        if(renewalSub == null){
            resResult.isSuccess = false;
        }else{
            if(string.isNotBlank(renewalSub.oppId)){
                resResult.isSuccess = renewalSub.isSuccess;
                resResult.error = '';
                resResult.oppId = renewalSub.oppId;
                resResult.listCloneQuoteId = renewalSub.listCloneQuoteId;
            }else{
                resResult.isSuccess = false;
                resResult.error = renewalSub.error;
            }
        }
        /*Change_Log__c changelog = CommonUtil.createChangeLog(policyId, 'Renewal', clonedoppId);
        if(changelog != null){
            insert changelog;
        }*/
         system.debug('resResult-->'+resResult);
        return resResult;
    }
    
    @AuraEnabled
    public static ResultWrapper getMasterBinders(String policyId) {
        ResultWrapper resResult = new ResultWrapper();
        List<Master_Binder__c> binderList = new List<Master_Binder__c>();
        try{
            List<Transactions__c> submissionPolicy = [SELECT Name, Id, Policy__c, Submission__c 
                                                      FROM Transactions__c 
                                                      WHERE Policy__c =:policyId 
                                                      AND Submission__r.Transaction_Status__c = 'Active' LIMIT 1];
            system.debug('submissionPolicy '+submissionPolicy);
            if(submissionPolicy.isEmpty()){
                resResult.error = 'No Active Submission/Transaction record found on this Policy';
                return resResult;
            }
            String oppId = submissionPolicy[0].Submission__c;
            Opportunity opp = [Select Id,Account.BillingCountry,Effective_Date__c,Expiration_Date__c from Opportunity where 
                               Id =: oppId];
            Policy__c policy = [select Id,Expiration_Date__c from Policy__c where Id =:policyId limit 1];
            String accountBillingCountry = opp.Account.BillingCountry;
            Date inceptionDate = Date.valueOf(policy.Expiration_Date__c + 1);
           system.debug('inceptionDate-->'+inceptionDate);
            system.debug('policyId-->'+policyId);
            
            binderList = [Select Id,Name,Inception_Date__c,Expiry_Date__c,MGA_Commission__c,Layer__c,Country__c,
                          Coverholder_Name__c,Coverholder_Pin__c from Master_Binder__c 
                          where Inception_Date__c <= :inceptionDate AND 
                          Expiry_Date__c >= :inceptionDate AND Country__c includes (:accountBillingCountry)];
          system.debug('binderList-->'+binderList);
            if(!binderList.isEmpty()){
                if(binderList.size() >1){                    
                    resResult.masterBinder = binderList;
                    resResult.showBinder = true;
                    return resResult;
                }else{
                    resResult.masterBinder = binderList;
                    resResult.showBinder = false;
                    return resResult;
                }
            }else{
                resResult.masterBinder = binderList;
                resResult.showBinder = false;
            }
        }catch (Exception ex) {
            system.debug(ex.getMessage() + 'Master Binder Error:' + ex.getLineNumber());
            throw new AuraHandledException(CommonUtil.getExceptionMessage(ex)); 
        }        
        return resResult;
    }
    
    @AuraEnabled
    public static ResultWrapper deleteClonedOpp(String clonedoppId) {
        ResultWrapper resResult = new ResultWrapper();
        List<Opportunity> oppList = [Select Id,Effective_Date__c,Expiration_Date__c from Opportunity where Id =: clonedoppId];
        
        if(!oppList.isEmpty()){
            delete oppList;
            resResult.isSuccess = true;
        }
        return resResult;
    }

	@AuraEnabled
	public static ResultResponse ratingQuoteRenewal(List<String> listQuoteId) {
        List<String> listPrimaryQuoteId = new List<String>();
        List<String> listExcessQuoteId = new List<String>();
        ResultResponse result = new ResultResponse();
        for(Quote objQuote :[Select Id, Layer__c from Quote where Id in :listQuoteId]){
            if(objQuote.Layer__c == 'Primary'){
                listPrimaryQuoteId.add(objQuote.Id);
            }
            else{
                listExcessQuoteId.add(objQuote.Id);
            }
        }
        System.debug('listPrimaryQuoteId'+listPrimaryQuoteId);
        System.debug('listExcessQuoteId'+listExcessQuoteId);
        String quoteId = !listPrimaryQuoteId.isEmpty() ? listPrimaryQuoteId[0] : listExcessQuoteId[0];
        
        result = RateController.getRatingFromCallOut(quoteId);
        System.debug('result'+result);
		//return result.errors.isEmpty() ? '' : result.errors[0];
        return result;
	}
    
    public class ResultWrapper {
        @AuraEnabled public String cloneQuoteId {get; set;}
        @AuraEnabled public List<String> listCloneQuoteId {get; set;}
        @AuraEnabled public String resultAccId {get; set;}
        @AuraEnabled public String oppId {get; set;}
        @AuraEnabled public String error {get; set;}
        @AuraEnabled public Boolean isSuccess {get; set;}
        @AuraEnabled public Boolean showBinder {get; set;}
        @AuraEnabled public string layer {get; set;}
        @AuraEnabled public List<Quote> quoteList {get; set;}
        @AuraEnabled public List<Master_Binder__c> masterBinder {get; set;}
        public ResultWrapper() {
            error = '';
            isSuccess = false;
        }
    }
}