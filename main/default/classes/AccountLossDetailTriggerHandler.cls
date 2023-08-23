/**
 * @description       : 
 * @author            : Hang Lam
 * @group             : 
 * @last modified on  : 09-07-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   09-03-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public with sharing class AccountLossDetailTriggerHandler extends TriggerHandler{
    private List<Account_Loss_Detail__c> oldDataList;
	private List<Account_Loss_Detail__c> newDataList;
	private Map<Id, Account_Loss_Detail__c> newDataMap;
	private Map<Id, Account_Loss_Detail__c> oldDataMap;
	
    public AccountLossDetailTriggerHandler (){  
		this.oldDataList = (List<Account_Loss_Detail__c>) Trigger.old;
		this.newDataList = (List<Account_Loss_Detail__c>) Trigger.new;
		this.newDataMap = (Map<Id, Account_Loss_Detail__c>) Trigger.newMap;
        this.oldDataMap = (Map<Id, Account_Loss_Detail__c>) Trigger.oldMap;
        // this.newDataMap = new Map<Id, Account_Loss_Detail__c>([SELECT Id
        //                                                         FROM Account_Loss_Detail__c 
        //                                                         WHERE Id IN :Trigger.new]);
    }

    public override void afterInsert(){
		createSubmissionLossDetails(this.newDataMap);
	}

	public override void afterUpdate(){
        updateSubmissionLossDetails(this.newDataMap);
    }

    /*************************************************
    * Method Name: createSubmissionLossDetails
    * Author: Hang Lam
    * Date: 07/09/2020
    * Params: newDataMap - Map AccountLossDetail
    * Return: 
    * Description: 28736 - create SubmissionLossDetail when Account Loss Details were created and Quote Process already had Submission 
    **********************************************/
    public static void createSubmissionLossDetails(Map<Id, Account_Loss_Detail__c> newDataMap){
        Set<String> accountIds = new Set<String>();
        List<Submission_Loss_Detail__c> listSubmissionLoss = new List<Submission_Loss_Detail__c>();
        for(Account_Loss_Detail__c accLossDetail : newDataMap.values()){
            if(String.isNotBlank(accLossDetail.Account__c))
                accountIds.add(accLossDetail.Account__c);
        }
        List<Opportunity> listOpps = [SELECT Id, AccountId, Product_Name__c,StageName 
                                        FROM Opportunity WHERE AccountId IN :accountIds AND StageName = 'Qualified'];
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
    **********************************************/
    public static void updateSubmissionLossDetails(Map<Id, Account_Loss_Detail__c> newDataMap){
        List<Submission_Loss_Detail__c> listSubmissionLoss = [SELECT Id, Loss_Amount__c, Number_of_Losses__c,
                                                                    Product__c, Status__c, Year__c, Submission__c, Account_Loss_Detail__c,
                                                                    Account_Loss_Detail__r.Loss_Amount__c, Account_Loss_Detail__r.Number_of_Losses__c,
                                                                    Account_Loss_Detail__r.Product__c, Account_Loss_Detail__r.Status__c,
                                                                    Account_Loss_Detail__r.Year__c, Submission__r.StageName
                                                                FROM Submission_Loss_Detail__c
                                                                WHERE Account_Loss_Detail__c IN: newDataMap.keySet()
                                                                AND Submission__r.StageName = 'Qualified'];
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