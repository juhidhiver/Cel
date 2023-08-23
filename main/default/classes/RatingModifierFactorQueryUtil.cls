/**************************************************************************************************
 * Class Name: RatingModifierFactorQueryUtil
 * Author: Vinay
 * Date: Dec 22, 2021
 * Description: Class to keep rating modifier factors queries
 * Test Class : RatingModifierFactorQueryUtilTest
 **************************************************************************************************/
public with sharing class RatingModifierFactorQueryUtil {
    /*************************************************
    * Method Name: fetchFatorsByProductNamesAndQuotes
    * Author: 
    * Date: 
    * Params: list of product names and quote ids
    * Return: 
    * Exceptions:
    * Description: list of rating modifier factors
    * Revision: 
     *************************************************/
    public static list<Rating_Modifier_Factor__c> fetchNewCLIs (List<String> prodNames, Set<Id> quoteIds){
        return  [SELECT id from Rating_Modifier_Factor__c where Rating_Modifier__r.Product__c in: prodNames and Quote__c in: quoteIds]; 
    }
}