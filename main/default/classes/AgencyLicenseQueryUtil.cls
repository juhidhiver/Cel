/**************************************************************************************************
 * Class Name: AgencyLicenseQueryUtil
 * Author: 
 * Date: Jan 3, 2021
 * Description: Class to keep Agency License queries
 * Test Class : AgencyLicenseQueryUtilTest
 **************************************************************************************************/
public with sharing class AgencyLicenseQueryUtil {
    
    /*************************************************
    * Method Name: fetchLicenseByAgencyId
    * Author: 
    * Date: 22 Dec 2021
    * Params: Id agencyId, String insuredState
    * Return: Contact
    * Exceptions:
    * Revision: 
    * Description: Fetch agency License
     *************************************************/
    public static List<Agency_License__c> fetchLicenseByAgencyId(Id agencyId, String insuredState){
        return [SELECT Id
                FROM Agency_License__c 
                WHERE Agency__c =: agencyId 
                AND License_Type__c = 'Admitted Lines' 
                AND RecordType.DeveloperName = 'MRe_Appointment'
                AND License_State__c=:insuredState
                AND MRe_Appointment_Status__c = 'Appointed'
                LIMIT 1];
    }

}