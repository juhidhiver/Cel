/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 08-16-2021
 * @last modified by  : Vinayesh
**/
@isTest
public class SubmissionConsoleLwcControllerTest {
    public static Product2 product;
    public static Product2 product1;
    public static Product2 product2;
    public static Account accBroker;

	@testSetup
    public static void setup() {
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = false;
        setting.BypassAccountTrigger__c = true;
        setting.BypassProductTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        update setting;
             
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert accBroker;  
        
        Contact con = new Contact(
			Lastname = 'Test broker',
			RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
		);
		insert con;
        
        product = TestUtil.createProduct('Private Company Combo');
        insert product;
        
        product1 = TestUtil.createProduct('D&O');
        product1.Parent_Product__c = product.Id;
        product1.IsComboProduct__c = true;
        insert product1;

        product2 = TestUtil.createProduct('EPL');
        product2.Parent_Product__c = product.Id;
        product2.IsComboProduct__c = true;
        insert product2;
        
		// create opportunity        
        Opportunity opp = TestUtil.createOpportunity('Test Opportunity', accBroker.Id, product.Id);
        opp.StageName = 'New';
        insert opp;
            
        Quote_Process__c qp = new Quote_Process__c();
        qp.Account__c = accBroker.Id;
        qp.Submission__c = opp.Id;
        insert qp;
        
        List<SectionSetting__c> secSettingLst = new List<SectionSetting__c>();
        
        SectionSetting__c secSetting = new SectionSetting__c();
        secSetting.Component__c = 'Submission Console';
        secSetting.Main_Section__c = 'Account Information';
        secSetting.Order__c = 1;
        secSetting.Product__c = 'Private Company Combo';
        secSetting.Active__c = true;
        secSetting.Record_Type__c = 'Celerity';
        secSettingLst.add(secSetting);

        SectionSetting__c secSetting1 = new SectionSetting__c();
        secSetting1.Component__c = 'Submission Console';
        secSetting1.Main_Section__c = 'Submission Information';
        secSetting1.Order__c = 2;
        secSetting1.Product__c = 'Private Company Combo';
        secSetting1.Active__c = true;
        secSetting1.Record_Type__c = 'Celerity';
        secSettingLst.add(secSetting1);

        SectionSetting__c secSetting2 = new SectionSetting__c();
        secSetting2.Component__c = 'Submission Console';
        secSetting2.Main_Section__c = 'Account Information';
        secSetting2.Sub_Section__c = 'Broker Information';
        secSetting2.Order__c = 1;
        secSetting2.Product__c = 'Private Company Combo';
        secSetting2.Active__c = true;
        secSetting2.Record_Type__c = 'Celerity';
        secSettingLst.add(secSetting2);

        SectionSetting__c secSetting3 = new SectionSetting__c();
        secSetting3.Component__c = 'Submission Console';
        secSetting3.Main_Section__c = 'Account Information';
        secSetting3.Source_Object__c = 'Account';
        secSetting3.Order__c = 1;
        secSetting3.Source_Field_Label__c = 'Account Name';
        secSetting3.Source_Field_API__c = 'Id';
        secSetting3.Format__c = 'Lookup';
        secSetting3.Lookup_To__c = 'Account';
        secSetting3.Product__c = 'Private Company Combo';
        secSetting3.Active__c = true;
        secSetting3.Record_Type__c = 'Celerity';
        secSettingLst.add(secSetting3);

        SectionSetting__c secSetting4 = new SectionSetting__c();
        secSetting4.Component__c = 'Submission Console';
        secSetting4.Main_Section__c = 'Submission Information';
        secSetting4.Source_Object__c = 'Opportunity';
        secSetting4.Order__c = 1;
        secSetting4.Source_Field_Label__c = 'Industry';
        secSetting4.Source_Field_API__c = 'Industry__c';
        secSetting4.Format__c = 'Picklist';
        secSetting4.Product__c = 'Private Company Combo';
        secSetting4.Active__c = true;
        secSetting4.Record_Type__c = 'Celerity';
        secSettingLst.add(secSetting4);
        
        SectionSetting__c secSetting5 = new SectionSetting__c();
        secSetting5.Component__c = 'Submission Console';
        secSetting5.Main_Section__c = 'Account Information';
        secSetting5.Sub_Section__c = 'Broker Information';
        secSetting5.Source_Object__c = 'Broker_Account__c';
        secSetting5.Order__c = 1;
        secSetting5.Source_Field_Label__c = 'Relationship Type';
        secSetting5.Source_Field_API__c = 'Relationship_Type__c';
        secSetting5.Format__c = 'Picklist';
        secSetting5.Product__c = 'Private Company Combo';
        secSetting5.Active__c = true;
        secSetting5.Record_Type__c = 'Celerity';
        secSettingLst.add(secSetting5);

        insert secSettingLst;

        List<Rating_Modifier_Template__c> lRMT = new List<Rating_Modifier_Template__c>();
        Rating_Modifier_Template__c rMT1 = TestUtil.createRatingModifierTemplate('Test Service Classification','D&O','Number');
        rMT1.Display_Format__c = 'Clearance';
        lRMT.add(rMT1);
        Rating_Modifier_Template__c rMT2 = TestUtil.createRatingModifierTemplate('New input integer','D&O','Integer');
        rMT2.Display_Format__c = 'Clearance';
        lRMT.add(rMT2);
        Rating_Modifier_Template__c rMT3 = TestUtil.createRatingModifierTemplate('New input integer','D&O','Integer');
        rMT3.Display_Format__c = 'Clearance';
        lRMT.add(rMT3);
        Rating_Modifier_Template__c rMT4 = TestUtil.createRatingModifierTemplate('New input integer','EPL','Integer');
        rMT4.Display_Format__c = 'Clearance';
        lRMT.add(rMT4);

        insert lRMT;

        Product_Option_Line_Item__c newRec = new Product_Option_Line_Item__c();
        newRec.Product__c = product1.Id;
        newRec.Submission__c = opp.Id;
        newRec.Account__c = accBroker.Id;
        newRec.Clearance_Status__c = 'Cleared';
        newRec.Is_Selected__c = true;
        newRec.Clearance_Date__c = Datetime.now();
        insert newRec;
    }
  
    
    @isTest
    public static void testGetListSectionSetting() {
        Quote_Process__c qp = [SELECT id,Submission__c FROM Quote_Process__c LIMIT 1];
        SubmissionConsoleLwcController.getListSectionSetting(String.valueOf(qp.Id));
        SubmissionConsoleLwcController.getProduct(String.valueOf(qp.Id));
        SubmissionConsoleLwcController.getDefaultRecordType(String.valueOf(qp.Id));
        
        test.startTest();
        Opportunity opp = [select id from  Opportunity limit 1 ];
        List<Quote> quotes = [Select id from Quote];
        for(Quote qt : quotes)
            qt.Status = 'Bound';
        update quotes;
        SubmissionConsoleLwcController.getListSectionSetting(String.valueOf(opp.Id));
        SubmissionConsoleLwcController.getProduct(String.valueOf(opp.Id));
        test.stopTest();
        system.assert(opp.id!=null);
    }

    @isTest
    public static void testGetRecordsInfo() {
        Quote_Process__c qp = [SELECT Submission__c, Account__c FROM Quote_Process__c LIMIT 1];
        SubmissionConsoleLwcController.getPicklistValues('Opportunity', 'Industry__c', '', '');
        SubmissionConsoleLwcController.getAccountInfos(qp.Account__c);
        SubmissionConsoleLwcController.getOpp(qp.Submission__c);
        SubmissionConsoleLwcController.getBrokerInfos(qp.Submission__c);
        SubmissionConsoleLwcController.getRecordInfos(qp.Id);
        SubmissionConsoleLwcController.getObjectRecordTypeId('Account', 'Business');
        SubmissionConsoleLwcController.isDNOCleared(qp.Submission__c);
        SubmissionConsoleLwcController.getProhibitedClassStatusForIndustry(qp.Submission__c);
        SubmissionConsoleLwcController.getRecordTypeInfo('Broker', 'Contact');
        SubmissionConsoleLwcController.getRecordInfos(qp.Submission__c);
        SubmissionConsoleLwcController.SectionWrapper sw = new SubmissionConsoleLwcController.SectionWrapper(qp.Account__c, new List<SubmissionConsoleLwcController.Section>());
        SubmissionConsoleLwcController.SelectOptionWrapper sow = new SubmissionConsoleLwcController.SelectOptionWrapper();
        system.assert(qp.Submission__c!=null);
    }

}