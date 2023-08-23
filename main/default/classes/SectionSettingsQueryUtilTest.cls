/**************************************************************************************************
 * Class Name: SectionSettingsQueryUtilTest
 * Author: RINKU SAINI
 * Date: Dec 30, 2021
 * Description: 
 *
 **************************************************************************************************/
@isTest
public class SectionSettingsQueryUtilTest {

    public static testmethod void coverfetchCeleritySubmissionInfoSettings(){
        Test.startTest();
        
        SectionSetting__c rmfSection = new SectionSetting__c();
        rmfSection.Component__c = 'Submission Info';
        rmfSection.Main_Section__c = 'Commission';
        rmfSection.Source_Field_API__c = 'Commission_percentage__c';
        rmfSection.Source_Object__c = 'Opportunity';
        rmfSection.Order__c = 4;
        rmfSection.Source_Field_Label__c = 'Commission percentage';
        rmfSection.Format__c = 'Percent';
        rmfSection.Product__c = 'MPL';
        rmfSection.Active__c = true;
        rmfSection.Record_Type__c = 'Celerity';
        rmfSection.DisplayType__c = 'Open';
        rmfSection.Quote_Layer__c = 'Primary';
        insert rmfSection;
        
        SectionSettingsQueryUtil.fetchCeleritySubmissionInfoSettings();
        
        Test.stopTest();
    }
}