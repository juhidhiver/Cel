/**************************************************************************************************
 * Class Name: QuotePremiumQueryUtil
 * Author: Vinay
 * Date: Dec 22, 2021
 * Description: Class to keep quote premium queries
 * Test Class :  QuotePremiumQueryUtilTest
 **************************************************************************************************/
public with sharing class QuotePremiumQueryUtil {
    /*************************************************
    * Method Name: fetchQuotePremiumsByProductNamesAndQuotes
    * Author: 
    * Date: 
    * Params: list of product names and quote ids
    * Return: 
    * Exceptions:
    * Description: list of quote premiums
    * Revision: 
     *************************************************/
    public static list<Quote_Premium__c> fetchQuotePremiumsByProductNamesAndQuotes(List<String> prodNames, Set<Id> quoteIds){
        return [Select Id from Quote_Premium__c where Product_Name__c in :prodNames and Quote__c in: quoteIds]; 
    }
}