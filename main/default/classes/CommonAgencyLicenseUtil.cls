/**************************************************************************************************
 * Class Name: CommonAgencyLicenseUtil
 * Author: 
 * Date: 
 * Description: common methods of Agency License Object trigger
 **************************************************************************************************/
public class CommonAgencyLicenseUtil {

	/*************************************************
    * Method Name: updateNIPRAgencyLCByCallOut
    * Author:
    * Date: 
    * Params: List<Agency_License__c>, Map<Id, Agency_License__c>
    * Return: 
    * Exceptions:
    * Description: Call API callout method for NIPR
    * Revision: 
     *************************************************/
	public static void updateNIPRAgencyLCByCallOut(List<Agency_License__c> newDataList, Map<Id, Agency_License__c> oldDataMap){
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
			//call the API call out method
			Invsk_Callout.getNIPRCallOut(listAgencyLCId);
		}
	}
}