@isTest
public class SectionSettingVSLwcControllerTest {
	@testSetup
    public static void setup() {
        List<SectionSetting__c> secLst = new List<SectionSetting__c>();
        
        SectionSetting__c secSetting = new SectionSetting__c();
        secSetting.Component__c = 'Submission Info';
        secSetting.Main_Section__c = 'Broker Account';
        secSetting.Source_Object__c = 'Broker_Account__c';
        secSetting.Order__c = 4;
        secSetting.Source_Field_Label__c = 'Relationship Type';
        //secSetting.Source_Field_API__c = 'Relationship_Type__c';
        secSetting.Format__c = 'Picklist';
        secSetting.Product__c = 'MPL';
        secSetting.Record_Type__c = 'Celerity';
        secLst.add(secSetting);
        
        
        SectionSetting__c secSetting1 = new SectionSetting__c();
        secSetting1.Component__c = 'Submission Info';
        secSetting1.Main_Section__c = 'Contact Info';
        secSetting1.Sub_Section__c = 'Insured Contact Info';
        secSetting1.Source_Object__c = 'Contact';
        secSetting1.Order__c = 1;
        secSetting1.Source_Field_Label__c = 'Salutation';
        //secSetting1.Source_Field_API__c = 'Salutation';
        secSetting1.Format__c = 'Text';
        secSetting1.Product__c = 'MPL';
        secSetting1.Record_Type__c = 'Celerity';
        secLst.add(secSetting1);
        
        SectionSetting__c secSetting2 = new SectionSetting__c();
        secSetting2.Component__c = 'Submission Test Info';
        secSetting2.Main_Section__c = 'Broker Account';
        secSetting2.Source_Object__c = 'Broker_Account__c';
        secSetting2.Order__c = 4;
        secSetting2.Source_Field_Label__c = 'Relationship Type';
        secSetting2.Source_Field_API__c = 'Relationship_Type__c';
        secSetting2.Format__c = 'Picklist';
        secSetting2.Product__c = 'MPL';
        secSetting2.Record_Type__c = 'Celerity';
        secLst.add(secSetting2);
        
        SectionSetting__c secSetting3 = new SectionSetting__c();
        secSetting3.Component__c = 'Test Info';
        secSetting3.Main_Section__c = 'Broker Account';
        secSetting3.Sub_Section__c = 'Insured Contact Info';
        secSetting3.Source_Object__c = 'Contact';
        secSetting3.Order__c = 2;
        secSetting3.Source_Field_Label__c = 'Salutation';
        //secSetting3.Source_Field_API__c = 'Salutation';
        secSetting3.Format__c = 'Text';
        secSetting3.Product__c = 'MPL';
        secSetting3.Record_Type__c = 'Celerity';
       	secLst.add(secSetting3);
        
        SectionSetting__c secSetting4 = new SectionSetting__c();
        secSetting4.Component__c = 'Testing Info';
        secSetting4.Main_Section__c = 'Broker Account';
        secSetting4.Sub_Section__c = 'Insured Contact Info';
        secSetting4.Source_Object__c = 'Contact';
        secSetting4.Order__c = 2;
        secSetting4.Source_Field_Label__c = 'Salutation';
        secSetting3.Source_Field_API__c = 'Salutation';
        secSetting4.Format__c = 'Text';
        secSetting4.Product__c = 'MPL';
        secSetting4.Record_Type__c = 'Celerity';
       	secLst.add(secSetting4);
        insert secLst;
    }
    
    @isTest
    public static void testGetSectionSettingStructure() {
        SectionSettingViewStructureLwcController.getSectionSettingStructure('Celerity','Submission Info');
        
    }
}