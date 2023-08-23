@isTest
public class SectionSettingLwcControllerTest {
	@testSetup
    public static void setup() {
        
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
        insert secSetting;
        
        SectionSetting__c secSetting1 = new SectionSetting__c();
        secSetting1.Component__c = 'Account Info';
        secSetting1.Main_Section__c = 'Contact Info';
        secSetting1.Sub_Section__c = 'Insured Contact Info';
        secSetting1.Source_Object__c = 'Contact';
        secSetting1.Order__c = 1;
        secSetting1.Source_Field_Label__c = 'Salutation';
        //secSetting1.Source_Field_API__c = 'Salutation';
        secSetting1.Format__c = 'Text';
        secSetting1.Product__c = 'MPL';
        secSetting1.Record_Type__c = 'Celerity';
        insert secSetting1;
    }
    
    @isTest
    public static void testGetComponentList() {
        List<sectionSettingLwcController.OptionWrapper> result = sectionSettingLwcController.getComponentList('Celerity');
        System.assertEquals(true,result.size() > 0);
    }
    
    @isTest
    public static void testGetProductList() {
       List<sectionSettingLwcController.OptionWrapper> result = sectionSettingLwcController.getProductList('Celerity');
       System.assertEquals(true,result.size() > 0); 
    }
    
    @isTest
    public static void testGetSectionList() {
       List<sectionSettingLwcController.OptionWrapper> result = sectionSettingLwcController.getSectionList('Celerity,Submission Info');
       System.assertEquals(true, result.size() > 0);
       List<sectionSettingLwcController.OptionWrapper> resultNew = sectionSettingLwcController.getSectionList('Celerity,Account Info,Contact Info');
       System.assertEquals(true, resultNew.size() > 0); 
    }
    
    @isTest
    public static void testGetMainSectionList() {
       List<sectionSettingLwcController.OptionWrapper> result =  sectionSettingLwcController.getMainSectionList('Celerity','Submission Info');
       System.assertEquals(true,result.size() > 0); 
    }
    
    @isTest
    public static void testGetSubSectionList() {
       List<sectionSettingLwcController.OptionWrapper> result =  sectionSettingLwcController.getSubSectionList('Celerity','Account Info','Contact Info');
       System.assertEquals(true,result.size() > 0); 
    }
    
    @isTest
    public static void testGetFieldList() {
        SectionSetting__c sec = [SELECT id,Name,Sub_Section__c,Source_Field_API__c
                                 FROM SectionSetting__c
                                 WHERE Component__c = 'Account Info' LIMIT 1];
        sec.Source_Field_API__c = 'Salutation';
        update sec;
        
        List<SectionSetting__c> result = sectionSettingLwcController.getFieldList('CelerityAccount InfoContact InfoInsured Contact Info');
        System.assertEquals(true,result.size() > 0);
    }
    
    @isTest
    public static void testUpdateSectionRelatedData() {
        String result = sectionSettingLwcController.updateSectionRelatedData('Celerity,Account Info,Contact Info,Insured Contact Info','');
        System.assertEquals('deleted Sub Section',result);
        String resultDelete = sectionSettingLwcController.updateSectionRelatedData('Celerity,Submission Info,Broker Account','');
        System.assertEquals('deleted Main Section',resultDelete);
    }
    
    @isTest
    public static void testUpdateSectionRelatedData2() {
        String result = sectionSettingLwcController.updateSectionRelatedData('','Celerity,Account Info,Contact Info,Insured Contact Info');
        System.assertEquals('added SubSection',result);
        String resultEdited = sectionSettingLwcController.updateSectionRelatedData('Celerity,Account Info,Contact Info,Insured Contact Info','Celerity,Account Info,Contact Info,Insured Contact Info');
        System.assertEquals('edited SubSection',resultEdited);
        String resultEditedMS = sectionSettingLwcController.updateSectionRelatedData('Celerity,Account Info,Contact Info','Celerity,Account Info,Contact Info,Insured Contact Info');
        System.assertEquals('edited MainSection',resultEditedMS);
    }
    
    @isTest
    public static void testUpdateComponentRelatedData() {
        String resultEdited = sectionSettingLwcController.updateComponentRelatedData('Celerity','Submission Info,Account Info','Edit');
        System.assertEquals('Updated success',resultEdited);
        String resultInserted = sectionSettingLwcController.updateComponentRelatedData('Celerity','Submission Info','Edit');
        System.assertEquals('Inserted success',resultInserted);
        String resultDeleted = sectionSettingLwcController.updateComponentRelatedData('Celerity','Submission Info','Delete');
        System.assertEquals('Deleted success',resultDeleted);
    }
}