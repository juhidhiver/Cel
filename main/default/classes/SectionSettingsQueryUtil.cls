/**************************************************************************************************
 * Class Name: SectionSettingsQueryUtil
 * Author: 
 * Date: Dec 27, 2021
 * Description: Class to keep UW Analysis Template queries
 * Test Class : 
 **************************************************************************************************/
public with sharing class SectionSettingsQueryUtil {
    /*************************************************
    * Method Name: fetchCeleritySubmissionInfoSettings
    * Author: 
    * Date: 27th Dec 2021
    * Params: 
    * Return: list of Section Settings
    * Exceptions:
    * Revision: 
    * Description: Fetch Section Settings for Celerity Submission Info Component
     *************************************************/
    public static List<SectionSetting__c> fetchCeleritySubmissionInfoSettings(){
        return [SELECT Id,Source_Field_API__c FROM SectionSetting__c 
                WHERE Component__c = 'Submission Info' AND Main_Section__c != 'Broker Account'
                AND Record_Type__c = 'Celerity' And Source_Object__c = 'Opportunity'
                And Profile_Name_for_Read_Only__c =null/* ORDER BY Order__c ASC*/];
    }
}