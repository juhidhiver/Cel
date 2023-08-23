/**************************************************************************************************
 * Class Name: AdditionalInterestQueryUtil
 * Author: 
 * Date: 15th Dec 2021
 * Description: Query util for additional interests
 * Test Class : AdditionalInterestQueryUtilTest
 **************************************************************************************************/
public with sharing class AdditionalInterestQueryUtil {
    /*************************************************
    * Method Name: fetchAdditionalInterestsByQuote
    * Author: Vinay
    * Date: 15 Dec 2021
    * Params: List<Id>
    * Return: list<Additional_Interests__c>
    * Exceptions:
    * Revision: 
    * Description: Fetch additional interests by quotes
     *************************************************/
    public static List<Additional_Interests__c> fetchAdditionalInterestsByQuote(Set<id> quoteIds){
        return [Select Id, Quote__c, Additional_Interest_Account__c From Additional_Interests__c Where Quote__c In :quoteIds];
    }
}