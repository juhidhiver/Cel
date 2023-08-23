public with sharing class AgencyLicenseTriggerHandler extends TriggerHandler{
	private List<Agency_License__c> oldDataList;
	private List<Agency_License__c> newDataList;
	private Map<Id, Agency_License__c> newDataMap;
	private Map<Id, Agency_License__c> oldDataMap;

	public AgencyLicenseTriggerHandler(){
		this.oldDataList = (List<Agency_License__c>)Trigger.old;
		this.newDataList = (List<Agency_License__c>)Trigger.new;
		this.newDataMap = (Map<Id, Agency_License__c>)Trigger.newMap;
		this.oldDataMap = (Map<Id, Agency_License__c>)Trigger.oldMap;
	}

	public override void afterInsert(){
        updateNIPRAgencyLCByCallOut(newDataList, oldDataMap);
	}

	public override void afterUpdate(){
        updateNIPRAgencyLCByCallOut(newDataList, oldDataMap);
	}

	private static void updateNIPRAgencyLCByCallOut(List<Agency_License__c> newDataList, Map<Id, Agency_License__c> oldDataMap){
		List<Id> listAgencyLCId = new List<Id>();
		if (oldDataMap == null){
			 //Insert case
			for (Agency_License__c license : newDataList){
				if (String.isNotBlank(license.License_Number__c) && String.isNotBlank(license.License_State__c))
					listAgencyLCId.add(license.Id);
			}
		} else{
			for (Agency_License__c license : newDataList){
				 //Update Case
				String oldLicenseNumber = oldDataMap.get(license.Id).License_Number__c;
				String newLicenseNumber = license.License_Number__c;

				String oldLicenseState = oldDataMap.get(license.Id).License_State__c;
				String newLicenseState = license.License_State__c;

				if ((String.isNotBlank(newLicenseNumber) && newLicenseNumber != oldLicenseNumber) || (String.isNotBlank(newLicenseState) && newLicenseState != oldLicenseState))
					listAgencyLCId.add(license.Id);
			}
		}
		if (!listAgencyLCId.isEmpty()){
			Invsk_Callout.getNIPRCallOut(listAgencyLCId);
			/*NIPRLisenceBatch b = new NIPRLisenceBatch();
			 database.executebatch(b,1);*/
		}
	}
}