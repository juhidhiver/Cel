/**************************************************************************************************
 * Class Name: UWAnalysisTemplateQueryUtil
 * Author: 
 * Date: Dec 27, 2021
 * Description: Class to keep UW Analysis Template queries
 * Test Class : 
 **************************************************************************************************/
public with sharing class UWAnalysisTemplateQueryUtil {
    /*************************************************
    * Method Name: fetchUWAnalysisTemplatesByCriteria
    * Author: 
    * Date: 27th Dec 2021
    * Params: Criterias
    * Return: list of UW Analysis Templates
    * Exceptions:
    * Revision: 
    * Description: Fetch UW Anlalysis Templates by Criteria
     *************************************************/
    public static List<UW_Analysis_Template__c> fetchUWAnalysisTemplatesByCriteria(List<String> oppMainProfessions){
        return [SELECT Id, Name, UW_Analysis_Name__c, Criteria__c, 
                UW_Analysis_Code__c,Default_Split_Percentage__c, Rating_Factor__c, Sort_Order__c 
                FROM UW_Analysis_Template__c 
                Where Criteria__c IN: oppMainProfessions
                ORDER BY Sort_Order__c ASC];
    }
}