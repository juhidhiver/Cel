/**************************************************************************************************
 * Class Name: AccountLocationQueryUtil
 * Author: Vinay Vernekar
 * Date: 5th Dec 2021
 * Description: Query util class for account location
 **************************************************************************************************/
public with sharing class AccountLocationQueryUtil {
    /*************************************************
    * Method Name: fetchAccountLocations
    * Author: Vinay Vernekar
    * Date: 29th Nov 2021
    * Params: Set<Id> accountIds
    * Return: 
    * Exceptions:
    * Revision: 
    * Description: Fetch account locations by account ids
     *************************************************/
    public static List<Account_Location__c> fetchAccountLocations(Set<Id> accountIds){
        return [Select Id, Account__c, Location__c From Account_Location__c Where Account__c In: accountIds];
    }
}