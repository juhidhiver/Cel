@isTest
public class InsureAccountControllerTest {
	@testSetup
    public static void setup() {
        TriggerSettings__c setting = new TriggerSettings__c();
        setting.BypassContactTrigger__c = true;
        setting.BypassAccountTrigger__c = true;
        insert setting;
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert accBroker;
        
        // Create contact
		Contact con = new Contact(
			Lastname = 'Test broker',
			RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
		);
		insert con;
        
        // create product
        Product2 product = TestUtil.createProduct('MPL Standalone');
		insert product;
        
		// create opportunity        
        Opportunity opp = TestUtil.createOpportunity('Test Opportunity', accBroker.Id, product.Id);
        opp.StageName = 'Qualified';
        insert opp;
        
        Quote_Process__c qp = new Quote_Process__c();
        qp.Account__c = accBroker.Id;
        qp.Submission__c = opp.Id;
        insert qp;
        
        Account_Loss_Detail__c accLossDet = new Account_Loss_Detail__c();
        accLossDet.Loss_Amount__c = 1000;
        accLossDet.Account__c = accBroker.Id;
        accLossDet.Number_of_Losses__c = 2;
        accLossDet.Product__c = 'MPL';
        accLossDet.Status__c = 'Open';
        insert accLossDet;
    }
   /* 
    @isTest
    public static void testGetListSectionSetting() {
         SectionSetting__c secSetting = new SectionSetting__c();
        secSetting.Component__c = 'Account Info';
        secSetting.Main_Section__c = 'Broker Account';
        secSetting.Source_Object__c = 'Account';
        secSetting.Order__c = 4;
        secSetting.Source_Field_Label__c = 'Relationship Type';
        //secSetting.Source_Field_API__c = 'Relationship_Type__c';
        secSetting.Format__c = 'Picklist';
        secSetting.Product__c = 'MPL';
        secSetting.Active__c = true;
        secSetting.Record_Type__c = 'Celerity';
        insert secSetting;
        
        Quote_Process__c qp = [SELECT id FROM Quote_Process__c LIMIT 1];
        InsureAccountController.getListSectionSetting(qp.Id);
        
        Opportunity opp = [SELECT id FROM Opportunity LIMIT 1];
        InsureAccountController.getListSectionSetting(opp.Id);
        
        Account acc = [SELECT id FROM Account LIMIT 1];
        InsureAccountController.getListSectionSetting(acc.Id);
    } 
    
    @isTest
    public static void testGetListSectionSetting2() {
        SectionSetting__c secSetting = new SectionSetting__c();
        secSetting.Component__c = 'Account Info';
        secSetting.Main_Section__c = 'Contact Info';
        secSetting.Sub_Section__c = 'Account Info';
        secSetting.Source_Object__c = 'Account';
        secSetting.Order__c = 2;
        secSetting.Source_Field_Label__c = 'Account Name';
        //secSetting.Source_Field_API__c = 'Id';
        secSetting.Format__c = 'Lookup';
        secSetting.Product__c = 'MPL';
        secSetting.Active__c = true;
        secSetting.Record_Type__c = 'Celerity';
        insert secSetting;
        
        Quote_Process__c qp = [SELECT id FROM Quote_Process__c LIMIT 1];
        InsureAccountController.getListSectionSetting(qp.Id);
        
    }
    
     @isTest
    public static void testGetListSectionSetting3() {
        SectionSetting__c secSetting = new SectionSetting__c();
        secSetting.Component__c = 'Account Info';
        secSetting.Main_Section__c = 'Contact Info';
        secSetting.Sub_Section__c = 'Account Info';
        secSetting.Source_Object__c = 'Account';
        secSetting.Order__c = 2;
        secSetting.Source_Field_Label__c = 'Account Name';
        secSetting.Source_Field_API__c = 'Id';
        secSetting.Format__c = 'Lookup';
        secSetting.Product__c = 'MPL';
        secSetting.Active__c = true;
        secSetting.Record_Type__c = 'Celerity';
        insert secSetting;
        
        Quote_Process__c qp = [SELECT id FROM Quote_Process__c LIMIT 1];
        InsureAccountController.getListSectionSetting(qp.Id);
        
    } */
    
    @isTest
    public static void testGetListSectionSetting4() {
        SectionSetting__c secSetting = new SectionSetting__c();
        secSetting.Component__c = 'Account Info';
        secSetting.Main_Section__c = 'Contact Info';
        secSetting.Source_Object__c = 'Account';
        secSetting.Order__c = 4;
        secSetting.Source_Field_Label__c = 'Relationship Type';
        //secSetting.Source_Field_API__c = 'Relationship_Type__c';
        secSetting.Format__c = 'Picklist';
        secSetting.Product__c = 'MPL';
        secSetting.Active__c = true;
        secSetting.Record_Type__c = 'Celerity';
        secSetting.DisplayType__c = 'Open';
        insert secSetting;
        
        SectionSetting__c secSetting2 = new SectionSetting__c();
        secSetting2.Component__c = 'Account Info';
        secSetting2.Main_Section__c = 'Contact Info';
        secSetting2.Sub_Section__c = 'Account Info';
        secSetting2.Source_Object__c = 'Account';
        secSetting2.Order__c = 3;
        secSetting2.Source_Field_Label__c = 'Account Name';
        //secSetting.Source_Field_API__c = 'Id';
        secSetting2.Format__c = 'Number';
        secSetting2.Product__c = 'MPL';
        secSetting2.Active__c = true;
        secSetting2.Record_Type__c = 'Celerity';
        secSetting2.DisplayType__c = 'Component';
        insert secSetting2;
        
        SectionSetting__c secSetting1 = new SectionSetting__c();
        secSetting1.Component__c = 'Account Info';
        secSetting1.Main_Section__c = 'Contact Info';
        //secSetting.Sub_Section__c = 'Account Info';
        secSetting1.Source_Object__c = 'Account';
        secSetting1.Order__c = 2;
        secSetting1.Source_Field_Label__c = 'Account Name';
        secSetting1.Source_Field_API__c = 'Id';
        secSetting1.Format__c = 'Lookup';
        secSetting1.Product__c = 'MPL';
        secSetting1.Active__c = true;
        secSetting1.Record_Type__c = 'Celerity';
        secSetting1.Profile_Name_for_Read_Only__c = 'All';
        secSetting1.DisplayType__c = 'Component';
        insert secSetting1;
        
         SectionSetting__c secSetting3 = new SectionSetting__c();
        secSetting3.Component__c = 'Account Info';
        secSetting3.Main_Section__c = 'Contact Info';
        secSetting3.Sub_Section__c = 'Account Info';
        secSetting3.Source_Object__c = 'Account';
        secSetting3.Order__c = 1;
        secSetting3.Source_Field_Label__c = 'Account Name';
        secSetting3.Source_Field_API__c = 'Id';
        secSetting3.Format__c = 'Text';
        secSetting3.Product__c = 'MPL';
        secSetting3.Active__c = true;
        secSetting3.Record_Type__c = 'Celerity';
        secSetting3.DisplayType__c = 'Component';
        insert secSetting3;
        
        Quote_Process__c qp = [SELECT id FROM Quote_Process__c LIMIT 1];
        InsureAccountController.getListSectionSetting(qp.Id);
        
        Opportunity opp = [SELECT id FROM Opportunity LIMIT 1];
        InsureAccountController.getListSectionSetting(opp.Id);
    }
    
    @isTest
    public static void testGetPicklistValues() {
        InsureAccountController.getPicklistValues('Policy__c','Cancellation_Reason__c','','');
    }
    
    @isTest
    public static void testGetRecordInfos() {
         
        
        Quote_Process__c qp = [SELECT id FROM Quote_Process__c LIMIT 1];
        InsureAccountController.getRecordInfos(qp.Id);
        
        Opportunity opp = [SELECT id FROM Opportunity LIMIT 1];
        InsureAccountController.getRecordInfos(opp.Id);
        
    }
    
    @isTest
    public static void testGetAccountInfos() {
       	SectionSetting__c secSetting = new SectionSetting__c();
        secSetting.Component__c = 'Account Info';
        secSetting.Main_Section__c = 'Contact Info';
        secSetting.Source_Object__c = 'Account';
        secSetting.Order__c = 4;
        secSetting.Source_Field_Label__c = 'Name';
        secSetting.Source_Field_API__c = 'Name';
        secSetting.Format__c = 'Text';
        secSetting.Product__c = 'MPL';
        secSetting.Active__c = true;
        secSetting.Record_Type__c = 'Celerity';
        insert secSetting;
        
        Account acc = [SELECT id FROM Account LIMIT 1];
        InsureAccountController.getAccountInfos(acc.Id); 
    }
    
    @isTest
    public static void testGetRecordTypeInfo() {
        InsureAccountController.getRecordTypeInfo('Broker','Contact');
    }
    
    @isTest
    public static void testGetAccountLossDetailByAccount() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        InsureAccountController.getAccountLossDetailByAccount(acc.Id);
    }
    
    @isTest
    public static void testGetObjectRecordTypeId() {
        InsureAccountController.getObjectRecordTypeId('Contact','Broker');
    }
    
    @isTest
    public static void testGetListSectionSettingNeg() {
        SectionSetting__c secSetting1 = new SectionSetting__c();
        secSetting1.Component__c = 'Account Info';
        secSetting1.Main_Section__c = 'Contact Info';
        //secSetting.Sub_Section__c = 'Account Info';
        secSetting1.Source_Object__c = 'Account';
        secSetting1.Order__c = 2;
        secSetting1.Source_Field_Label__c = 'Account Name';
        secSetting1.Source_Field_API__c = 'Id';
        secSetting1.Format__c = 'Lookup';
        secSetting1.Product__c = 'MPL';
        secSetting1.Active__c = true;
        secSetting1.Record_Type__c = 'Celerity';
        secSetting1.Profile_Name_for_Read_Only__c = 'Celerity Senior Underwriter';
        insert secSetting1;
        
        Quote_Process__c qp = [SELECT id FROM Quote_Process__c LIMIT 1];
        InsureAccountController.getListSectionSetting(qp.Id);
    }
    
    @isTest
    public static void testWrapperUsed() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        InsureAccountController.SelectOptionWrapper optionWrap = new InsureAccountController.SelectOptionWrapper();
        InsureAccountController.AccountLossDetailWrapper accLstWrap = new InsureAccountController.AccountLossDetailWrapper();
        InsureAccountController.Section sec = new InsureAccountController.Section();
        sec.order = 12;
        sec.compareTo(sec);
        
        InsureAccountController.SubSectionChild secChild = new InsureAccountController.SubSectionChild();
        secChild.order = 1;
        secChild.compareTo(secChild);
        InsureAccountController.updateQuoteInProgress('Test');
        InsureAccountController.SectionWrapper secWrap = new InsureAccountController.SectionWrapper(acc.Id,new List<InsureAccountController.Section>{sec});
    }
    @isTest
    static void testgetRecordInfos2(){        
       	SectionSetting__c secSetting = new SectionSetting__c();
        secSetting.Component__c = 'Account Info';
        secSetting.Main_Section__c = 'Contact Info';
        secSetting.Source_Object__c = 'Contact';
        secSetting.Order__c = 4;
        secSetting.Source_Field_Label__c = 'Name';
        secSetting.Source_Field_API__c = 'Name';
        secSetting.Format__c = 'Text';
        secSetting.Product__c = 'MPL';
        secSetting.Active__c = true;
        secSetting.Record_Type__c = 'Celerity';
        insert secSetting;
        Test.startTest();
        Contact con = [Select Id from Contact Limit 1];
        Contact result = InsureAccountController.getRecordInfos(String.valueOf(con.Id));
        System.assert(result!=null);  
        Test.stopTest();
    }
    @isTest
    static void checkQuotedQuoteTest(){
        Test.startTest();
        Id accId = [Select id From Account Limit 1].Id;
        Quote_Process__c qouProc = [Select id from Quote_Process__c Limit 1];
        ResultResponse result = InsureAccountController.checkQuotedQuote(accId, qouProc.Id);
        InsureAccountController.getProductName(qouProc.Id);
        System.assert(result!=null);
        Test.stopTest();
    }
    @isTest
    static void TestAqueous(){
        Test.startTest();
       
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 prod = TestUtil.createProduct('Professional Indemnity');
        prod.RecordTypeId = aqueousRecordTypeId;
        prod.Innovisk_Entity_ID__c = 'Aqueous';
		insert prod;
        
        
        Opportunity oppaq = TestUtil.createOpportunity('Opportunity',acc.Id, prod.Id);
        oppaq.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        oppaq.Innovisk_Entity_ID__c = 'Aqueous';        
        oppaq.Coverage_Product_Options__c = 'Professional Indemnity';
        oppaq.StageName = 'Qualified';
        insert oppaq;
        
        Quote quoteaq = Testutil.createQuote('New Quote 2', oppaq.Id);
        quoteaq.Status = 'Quoted';
        quoteaq.Refer_Type__c = 'Underwriting Referral';
        quoteaq.Coverage_Product_Options__c = 'Professional Indemnity';
        insert quoteaq; 
        quoteaq.Layer__c='Excess';
        update quoteaq;
        
       
        
        //Opportunity oppaq = [Select Id,StageName from Opportunity where Name='Aqueous Test' Limit 1];
        InsureAccountController.updateQuoteStatusForAQ(oppaq.Id);
        Test.stopTest();
        
    }
 
    
}