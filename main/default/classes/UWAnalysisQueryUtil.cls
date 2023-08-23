/**************************************************************************************************
 * Class Name: UWAnalysisQueryUtil
 * Author: 
 * Date: Dec 27, 2021
 * Description: Class to keep UW Analysis queries
 * Test Class : 
 **************************************************************************************************/
public with sharing class UWAnalysisQueryUtil {
    /*************************************************
    * Method Name: fetchUWAnalysisForOpps
    * Author: 
    * Date: 27th Dec 2021
    * Params: Opportunity Id
    * Return: list of UW Analysis
    * Exceptions:
    * Revision: 
    * Description: Fetch UW Analysis by opportunity
     *************************************************/
    public static List<UW_Analysis__c> fetchUWAnalysisForOpps(List<String> oppIds){
        return [SELECT Id, UW_Analysis_Name__c, Criteria__c
                FROM UW_Analysis__c 
                Where Submission__c IN:oppIds];
    }
}