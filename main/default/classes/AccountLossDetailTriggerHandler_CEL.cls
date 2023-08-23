/**************************************************************************************************
 * Class Name: AccountLossDetailTriggerHandler_CEL
 * Author: 
 * Date: 
 * Description: Class to keep account loss detail related common methods
 * Test Class : AccountLossDetailTriggerHandlerTest
 **************************************************************************************************/
public with sharing class AccountLossDetailTriggerHandler_CEL  extends TriggerHandler{
    private List<Account_Loss_Detail__c> oldDataList;
    private List<Account_Loss_Detail__c> newDataList; 
    private Map<Id, Account_Loss_Detail__c> newDataMap;
    private Map<Id, Account_Loss_Detail__c> oldDataMap; 
    
    public AccountLossDetailTriggerHandler_CEL(List<Account_Loss_Detail__c> newDataList, List<Account_Loss_Detail__c> oldDataList, Map<Id, Account_Loss_Detail__c> newDataMap, Map<Id, Account_Loss_Detail__c> oldDataMap){
        this.oldDataList = oldDataList;
        this.newDataList = newDataList;
        this.newDataMap = newDataMap;
        this.oldDataMap = oldDataMap;
    }

	public override void beforeInsert()	{
        
    }

    public override void beforeUpdate(){
        
    }

	public override void afterInsert(){
        //create submission loss detail record
        CommonAccountLossDetailUtil.createSubmissionLossDetails(this.newDataMap);
    }

	public override void afterUpdate(){
        //create submission loss detail record
        CommonAccountLossDetailUtil.updateSubmissionLossDetails(this.newDataMap);
    }
}