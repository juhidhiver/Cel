/**************************************************************************************************
 * Class Name: QuoteProcessQueryUtil
 * Author: Vinayesh
 * Date: Dec 27, 2021
 * Description: Class to keep Quote Process(UW workbench) queries
 * Test Class : 
 **************************************************************************************************/

public with sharing class QuoteProcessQueryUtil {
    
    /*************************************************
    * Method Name: fetchQPForSubmissions
    * Author: 
    * Date: 
    * Params: set<Id> oppIds
    * Return: 
    * Exceptions:
    * Description: Get QP records by Submission.
    * Revision: 
     *************************************************/
    public static List<Quote_Process__c> fetchQPForSubmissions (set<Id> oppIds){
        return [SELECT Id, Name, Submission__c FROM Quote_Process__c WHERE Submission__c IN :oppIds];
    }
}