/**************************************************************************************************
 * Class Name: CommonBrokerLicenseUtil
 * Author: 
 * Date: 
 * Description: 
 **************************************************************************************************/
public with sharing class CommonBrokerLicenseUtil {
    //7760: Change NIPR run from Contact to Broker License (Binh Dang: 1 Nov 2019)
	public static void updateNIPRFlafByCallOut(List<Broker_License__c> newDataList,Map<Id, Broker_License__c> oldDataMap) {
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