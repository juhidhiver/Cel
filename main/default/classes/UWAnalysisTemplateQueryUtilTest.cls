/**************************************************************************************************
 * Class Name: UWAnalysisTemplateQueryUtilTest
 * Author:  RINKU SAINI
 * Date: Dec 30, 2021
 * Description:
 **************************************************************************************************/

@isTest
public class UWAnalysisTemplateQueryUtilTest {

    public static testmethod void coverUWAnalysisTemplate(){
        Test.startTest();
        
        UW_Analysis_Template__c TempList = new UW_Analysis_Template__c();
        TempList.UW_Analysis_Name__c = 'Test';
        TempList.Criteria__c = 'Engineers';
        TempList.UW_Analysis_Code__c ='Code';
        TempList.Rating_Factor__c= 5000;
        TempList.Sort_Order__c = 100;
        insert TempList;
        
        UWAnalysisTemplateQueryUtil.fetchUWAnalysisTemplatesByCriteria( New List<String>{'Engineers'});
        Test.stopTest();
    }
}