/**************************************************************************************************
 * Class Name: ContactTriggerHandler_Business
 * Author: 
 * Date: 
 * Description: Class to keep Business related common methods
 * Test Class : ContactTriggerHandlerTest
 **************************************************************************************************/
public with sharing class ContactTriggerHandler_Business extends TriggerHandler {
    private List<Contact> oldDataList;
    private List<Contact> newDataList; 
    private Map<Id, Contact> newDataMap;
    private Map<Id, Contact> oldDataMap; 
    
    public ContactTriggerHandler_Business(List<Contact> newDataList, List<Contact> oldDataList, Map<Id, Contact> newDataMap, Map<Id, Contact> oldDataMap){
        this.oldDataList = oldDataList;
        this.newDataList = newDataList;
        this.newDataMap = newDataMap;
        this.oldDataMap = oldDataMap;
    } 

	public override void beforeInsert()	{
        //generate external id (Azure)
        CommonUtil.generateExternalID('Azure_ID__c', newDataList);
    }

    public override void beforeUpdate(){
        //generate external id (Azure)
        CommonUtil.generateExternalID('Azure_ID__c', newDataList);
    }

	public override void afterInsert(){
        //Update quote with broker's mail address
        CommonContactUtil.updateQuoteWithBrokerEmail(newDataMap);
    }

	public override void afterUpdate(){
        //Check if contact email is changing
        CommonContactUtil.emailChangeContactHandler(newDataList, oldDataMap);
    }
}