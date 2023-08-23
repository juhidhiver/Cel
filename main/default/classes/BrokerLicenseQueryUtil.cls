/**************************************************************************************************
 * Class Name: BrokerLicenseQueryUtil
 * Author: 
 * Date: Jan 4th, 2022
 * Description: Class to keep Broker license queries
 * Test Class : BrokerLicenseQueryUtilTest
 **************************************************************************************************/
public with sharing class BrokerLicenseQueryUtil {
    /*************************************************
    * Method Name: fetchLicencesForBroker
    * Author: 
    * Date: 6th Jan 2022
    * Params: String brkContactId
    * Return: list of broker licenses
    * Exceptions:
    * Revision: 
    * Description: Fetch all broker licenses
     *************************************************/
    public static List<Broker_License__c> fetchLicencesForBroker(String brkContactId){
        return [SELECT Id,License_Number__c, License_State__c,License_Type__c, NPN__c 
                FROM Broker_License__c 
                WHERE Broker__c =:brkContactId];
    }
}