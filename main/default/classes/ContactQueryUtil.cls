/**************************************************************************************************
 * Class Name: ContactQueryUtil
 * Author: Vinay
 * Date: Dec 22, 2021
 * Description: Class to keep Contact queries
 * Test Class : 
 **************************************************************************************************/
public with sharing class ContactQueryUtil {
    
    /*************************************************
    * Method Name: fetchContactFromBrokerAccount
    * Author: Vinay
    * Date: 22 Dec 2021
    * Params: broker contact id
    * Return: Contact
    * Exceptions:
    * Revision: 
    * Description: Fetch broker account's contact
     *************************************************/
    public static Contact fetchContactFromBrokerAccount(Id brokerContactId){
        return [select Id,AccountId from contact where Id =:brokerContactId];
    }

     /*************************************************
    * Method Name: fetchContactWithBrokerLicenseById
    * Author: 
    * Date: 22 Dec 2021
    * Params: Id brokerContactId, String insuredState
    * Return: Contact
    * Exceptions:
    * Revision: 
    * Description: Fetch broker account's contact
     *************************************************/
    public static Contact fetchContactWithBrokerLicenseById(Id brokerContactId, String insuredState){
        return [SELECT AccountId, 
                (SELECT Id 
                FROM Broker_Licenses__r 
                WHERE License_Type__c = 'Admitted Lines' 
                AND License_State__c=:insuredState 
                AND RecordType.DeveloperName = 'MRe_Appointment'
                AND MRe_Appointment_Status__c = 'Appointed'
                LIMIT 1) 
                FROM Contact 
                WHERE Id =: brokerContactId];
    }
}