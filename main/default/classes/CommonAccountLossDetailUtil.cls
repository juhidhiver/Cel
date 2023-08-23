/**************************************************************************************************
 * Class Name: CommonAccountLossDetailUtil
 * Author: 
 * Date: 
 * Description: Utility class to hold all methods related to Account Loss Detail methods
 * Test Class : 
 **************************************************************************************************/
public with sharing class CommonAccountLossDetailUtil {
    /*************************************************
    * Method Name: createSubmissionLossDetails
    * Author: Hang Lam
    * Date: 07/09/2020
    * Params: newDataMap - Map AccountLossDetail
    * Return: 
    * Description: 28736 - create SubmissionLossDetail when Account Loss Details were created and Quote Process already had Submission 
    * Can be converted to a flow : Yes
    **********************************************/
    public static void createSubmissionLossDetails(Map<Id, Account_Loss_Detail__c> newDataMap){
        Set<Id> accountIds = new Set<Id>();
        List<Submission_Loss_Detail__c> listSubmissionLoss = new List<Submission_Loss_Detail__c>();
        for(Account_Loss_Detail__c accLossDetail : newDataMap.values()){
            if(String.isNotBlank(accLossDetail.Account__c))
                accountIds.add(accLossDetail.Account__c);
        }
        List<Opportunity> listOpps = OpportunityQueryUtil.fetchOpportunitiesByAccountAndStage(accountIds, 'Qualified');
        Map<String, List<Opportunity>> accOppMap = new Map<String, List<Opportunity>>();
        if(!listOpps.isEmpty()){
            for(Opportunity opp : listOpps){
                if(accOppMap.containsKey(opp.AccountId)){
                    accOppMap.get(opp.AccountId).add(opp);
                }else{
                    accOppMap.put(opp.AccountId, new List<Opportunity>{opp});
                }
            }
        }
        
        for(Account_Loss_Detail__c accLoss : newDataMap.values()){
            if(accOppMap.get(accLoss.Account__c) != null){
                for(Opportunity opp : accOppMap.get(accLoss.Account__c)) {
                    if(opp.AccountId == accLoss.Account__c) {
                        Submission_Loss_Detail__c subLoss = new Submission_Loss_Detail__c();
                        subLoss.Loss_Amount__c = accLoss.Loss_Amount__c;
                        subLoss.Number_of_Losses__c = accLoss.Number_of_Losses__c;
                        subLoss.Product__c = accLoss.Product__c;
                        subLoss.Status__c = accLoss.Status__c;
                        subLoss.Year__c	 = accLoss.Year__c;
                        subLoss.Submission__c = opp.Id;
                        subLoss.Account_Loss_Detail__c = accLoss.Id;
                        listSubmissionLoss.add(subLoss);
                    }
                } 
            }
        }
        if(!listSubmissionLoss.isEmpty())
            insert listSubmissionLoss;
        
    }

    /*************************************************
    * Method Name: updateSubmissionLossDetails
    * Author: Hang Lam
    * Date: 07/09/2020
    * Params: newDataMap - Map AccountLossDetail
    * Return: 
    * Description: 28736 - update SubmissionLossDetail when Account Loss Details were created and Quote Process already had Submission 
    * Can be converted to a flow : Yes
    **********************************************/
    public static void updateSubmissionLossDetails(Map<Id, Account_Loss_Detail__c> newDataMap){
        List<Submission_Loss_Detail__c> listSubmissionLoss = SubmissionLossDetailQueryUtil.fetchByAccountLossAndOppStage(newDataMap.keySet(), 'Qualified');
        if(!listSubmissionLoss.isEmpty()){
            for(Submission_Loss_Detail__c subLossDetail : listSubmissionLoss){
                subLossDetail.Loss_Amount__c = subLossDetail.Account_Loss_Detail__r.Loss_Amount__c;
                subLossDetail.Number_of_Losses__c = subLossDetail.Account_Loss_Detail__r.Number_of_Losses__c;
                subLossDetail.Product__c = subLossDetail.Account_Loss_Detail__r.Product__c;
                subLossDetail.Status__c = subLossDetail.Account_Loss_Detail__r.Status__c;
                subLossDetail.Year__c = subLossDetail.Account_Loss_Detail__r.Year__c;
            }
        }
        update listSubmissionLoss;
    }
}