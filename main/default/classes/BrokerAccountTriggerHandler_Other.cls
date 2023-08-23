/**************************************************************************************************
 * Class Name: BrokerAccountTriggerHandler_Other
 * Author: 
 * Date: 
 * Description: Class to keep method related to products other than PCC, MPL, Cyber and Prof Ind.
 * Test Class : BrokerAccountTriggerHandlerTest
 **************************************************************************************************/
public with sharing class BrokerAccountTriggerHandler_Other extends TriggerHandler{
    private List<Broker_Account__c> oldDataList;
    private List<Broker_Account__c> newDataList; 
    private Map<Id, Broker_Account__c> newDataMap;
    private Map<Id, Broker_Account__c> oldDataMap; 
    
    public BrokerAccountTriggerHandler_Other(List<Broker_Account__c> newDataList, List<Broker_Account__c> oldDataList, Map<Id, Broker_Account__c> newDataMap, Map<Id, Broker_Account__c> oldDataMap){
        this.oldDataList = oldDataList;
        this.newDataList = newDataList;
        this.newDataMap = newDataMap;
        this.oldDataMap = oldDataMap;
    } 
	public override void beforeInsert()	{
        //multiple validation on broker account
        CommonBrokerAccountUtil.brokerAccountValidation(newDataList, oldDataMap);
    }


	public override void afterInsert(){
        //Update Primary Broker Name and Email when changing the 'Primary Broker' field
        CommonBrokerAccountUtil.updateQuotesWithPrimaryBrokerName(newDataList, null);  
    }

}