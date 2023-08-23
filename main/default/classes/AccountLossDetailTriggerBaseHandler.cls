/**************************************************************************************************
* Class Name: AccountLossDetailTriggerBaseHandler
* Author: 
* Date: 
* Description: handler for Account Loss Detail records
* Test Class : AccountLossDetailTriggerHandlerTest
**************************************************************************************************/
public with sharing class AccountLossDetailTriggerBaseHandler extends TriggerHandler {
    private List<Account_Loss_Detail__c> oldDataList;
    private List<Account_Loss_Detail__c> newDataList; 
    private Map<Id, Account_Loss_Detail__c> newDataMap;
    private Map<Id, Account_Loss_Detail__c> oldDataMap;
    
    
    public void runBaseHandler(){
        this.newDataList = Trigger.new;
        this.oldDataList = Trigger.old;
        
        try{
            if( this.newDataList != null && !this.newDataList.isEmpty()){
                newDataMap = new Map<Id, Account_Loss_Detail__c>(this.newDataList);	
            }
        }catch(Exception e){
            this.newDataMap = null;			
        }          
        
        try{   
            if( this.oldDataList != null && !this.oldDataList.isEmpty()){
                oldDataMap = new Map<Id, Account_Loss_Detail__c>(this.oldDataList);
            }
        }catch(Exception e){
            this.oldDataMap = null;
        }    
        new AccountLossDetailTriggerHandler_CEL(newDataList, oldDataList, newDataMap, oldDataMap).run();
    }
}