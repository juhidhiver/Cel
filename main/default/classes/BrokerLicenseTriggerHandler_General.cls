public with sharing class BrokerLicenseTriggerHandler_General extends TriggerHandler {
    private List<Broker_License__c> oldDataList;
    private List<Broker_License__c> newDataList; 
    private Map<Id, Broker_License__c> newDataMap;
    private Map<Id, Broker_License__c> oldDataMap; 
    
    public BrokerLicenseTriggerHandler_General(List<Broker_License__c> newDataList, List<Broker_License__c> oldDataList, Map<Id, Broker_License__c> newDataMap, Map<Id, Broker_License__c> oldDataMap){
        this.oldDataList = oldDataList;
        this.newDataList = newDataList;
        this.newDataMap = newDataMap;
        this.oldDataMap = oldDataMap;
    }

    /*************************************************
    * Method Name: beforeInsert
    * Author:
    * Date: 
    * Params: 
    * Return: 
    * Exceptions:
    * Description: To execute functionalities in before insert context
    * Revision: 
     *************************************************/
	public override void beforeInsert()	{
        
    }

	/*************************************************
    * Method Name: beforeUpdate
    * Author:
    * Date: 
    * Params: 
    * Return: 
    * Exceptions:
    * Description: To execute functionalities in before update context
    * Revision: 
     *************************************************/
    public override void beforeUpdate(){
        
    }

	/*************************************************
    * Method Name: afterInsert
    * Author:
    * Date: 
    * Params: 
    * Return: 
    * Exceptions:
    * Description: To execute functionalities in after insert context
    * Revision: 
     *************************************************/
    public override void afterInsert(){
        //7760: Change NIPR run from Contact to Broker License (Binh Dang: 1 Nov 2019)
        if(!system.isBatch()) CommonBrokerLicenseUtil.updateNIPRFlafByCallOut(newDataList, null);
    }

	/*************************************************
    * Method Name: afterUpdate
    * Author:
    * Date: 
    * Params: 
    * Return: 
    * Exceptions:
    * Description: To execute functionalities in after update context
    * Revision: 
     *************************************************/
	public override void afterUpdate(){
		//7760: Change NIPR run from Contact to Broker License (Binh Dang: 1 Nov 2019)
		if(!system.isBatch()) CommonBrokerLicenseUtil.updateNIPRFlafByCallOut(newDataList, oldDataMap);
    }
}