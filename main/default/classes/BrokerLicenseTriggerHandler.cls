/*************************************************
* Class Name: BrokerAccountTriggerHandler 
* Author: Long Ly
* Date: 2019 August 08
* Requirement/Project Description: Trigger to handle automation on Broker Account
*************************************************/
public class BrokerLicenseTriggerHandler extends TriggerHandler {
    
    private List<Broker_License__c> oldDataList;
    private List<Broker_License__c> newDataList;
    private Map<Id, Broker_License__c> newDataMap;
    private Map<Id, Broker_License__c> oldDataMap;
    
     public BrokerLicenseTriggerHandler () {
        this.oldDataList = (List<Broker_License__c>) Trigger.old;
        this.newDataList = (List<Broker_License__c>) Trigger.new;
        this.newDataMap = (Map<Id, Broker_License__c>) Trigger.newMap;
        this.oldDataMap = (Map<Id, Broker_License__c>) Trigger.oldMap;
    }
    
    public override void beforeInsert(){
       
    }

    public override void afterInsert(){
		//7760: Change NIPR run from Contact to Broker License (Binh Dang: 1 Nov 2019)
		if(!system.isBatch()) updateNIPRFlafByCallOut(newDataList, null);
    }

     public override void beforeUpdate(){
	  
    }

    public override void afterUpdate(){
		//7760: Change NIPR run from Contact to Broker License (Binh Dang: 1 Nov 2019)
		if(!system.isBatch()) updateNIPRFlafByCallOut(newDataList, oldDataMap);
    }
    
	//7760: Change NIPR run from Contact to Broker License (Binh Dang: 1 Nov 2019)
	private static void updateNIPRFlafByCallOut(List<Broker_License__c> newDataList,Map<Id, Broker_License__c> oldDataMap) {
  		List<Id> listBrokerLCId = new List<Id>();
        if(oldDataMap == null) { //Insert case
            for(Broker_License__c license :newDataList) {
				if(String.isNotBlank(license.License_Number__c) && String.isNotBlank(license.License_State__c)) 
					listBrokerLCId.add(license.Id);
	        }
        }else{
            for(Broker_License__c license : newDataList) { //Update Case
                String oldLicenseNumber = oldDataMap.get(license.Id).License_Number__c;
                String newLicenseNumber = license.License_Number__c;

				String oldLicenseState = oldDataMap.get(license.Id).License_State__c;
                String newLicenseState = license.License_State__c;

                if(	(String.isNotBlank(newLicenseNumber) && newLicenseNumber != oldLicenseNumber)
					||  (String.isNotBlank(newLicenseState) && newLicenseState != oldLicenseState)
				  ) 
                    listBrokerLCId.add(license.Id);
            }
        }
        if(!listBrokerLCId.isEmpty()){
        Invsk_Callout.getNIPRCallOut(listBrokerLCId);
        /*NIPRLisenceBatch b = new NIPRLisenceBatch();
        database.executebatch(b,1);*/
        } 
    }

}