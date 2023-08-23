@isTest
public class QuoteComparisonLWCTest {
	@testSetup
    public static void setup() {
        TriggerSettings__c setting = new TriggerSettings__c();
        setting.BypassQuoteTrigger__c = true;
        insert setting;
        
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert accBroker;              	
        
        // create product
        Product2 product = TestUtil.createProduct('MPL');
		insert product;
        
		// create opportunity        
        Opportunity opp = TestUtil.createOpportunity('Test Opportunity', accBroker.Id, product.Id);
        opp.StageName = 'Qualified';
        insert opp;
        
        // create Quote
        Quote q = TestUtil.createQuote('Test Quote', opp.Id);
        q.Rating_Status__c = 'Refer';
        q.Status = 'Rated';
        insert q;
        
        Quote_Process__c qp = new Quote_Process__c();
        qp.Account__c = accBroker.Id;
        qp.Submission__c = opp.Id;
        insert qp;
        
        List<SectionSetting__c> secSetLst = new List<SectionSetting__c>();
        SectionSetting__c secSetting0 = new SectionSetting__c();
        secSetting0.Component__c = 'Rate Quotes';
        secSetting0.Main_Section__c = 'Quote Data';
        secSetting0.Source_Object__c = '';
        secSetting0.Order__c = 4;
        secSetting0.Source_Field_Label__c = '';
        //secSetting.Source_Field_API__c = 'Relationship_Type__c';
        secSetting0.Format__c = '';
        secSetting0.Product__c = 'MPL';
        secSetting0.Active__c = true;
        secSetting0.Record_Type__c = 'Celerity';
        secSetting0.Quote_Layer__c = 'Excess';
        secSetLst.add(secSetting0);

        SectionSetting__c secSetting = new SectionSetting__c();
        secSetting.Component__c = 'Rate Quotes';
        secSetting.Main_Section__c = 'Quote Data';
        secSetting.Source_Object__c = 'Broker_Account__c';
        secSetting.Order__c = 4;
        secSetting.Source_Field_Label__c = 'Relationship Type';
        //secSetting.Source_Field_API__c = 'Relationship_Type__c';
        secSetting.Format__c = 'Picklist';
        secSetting.Product__c = 'MPL';
        secSetting.Active__c = true;
        secSetting.Record_Type__c = 'Celerity';
        secSetting.Quote_Layer__c = 'Excess';
        secSetLst.add(secSetting);
        
        SectionSetting__c secSetting1 = new SectionSetting__c();
        secSetting1.Component__c = 'Rate Quotes';
        secSetting1.Main_Section__c = 'Quote Data';
        secSetting1.Source_Object__c = 'Quote';
        secSetting1.Order__c = 4;
        secSetting1.Source_Field_Label__c = 'Override Premium';
        secSetting1.Source_Field_API__c = 'Override_Premium__c';
        secSetting1.Format__c = 'Number';
        secSetting1.Product__c = 'MPL';
        secSetting1.Active__c = true;
        secSetting1.Record_Type__c = 'Celerity';
        secSetting1.Quote_Layer__c = 'Excess';
        secSetLst.add(secSetting1);
        
        SectionSetting__c secSetting2 = new SectionSetting__c();
        secSetting2.Component__c = 'Rate Quotes';
        secSetting2.Main_Section__c = 'Quote Data';
        secSetting2.Sub_Section__c = 'Insured Contact Info';
        secSetting2.Source_Object__c = 'Quote';
        secSetting2.Order__c = 4;
        secSetting2.Source_Field_Label__c = 'Override Premium';
        //secSetting2.Source_Field_API__c = 'Override_Premium__c';
        secSetting2.Format__c = 'Number';
        secSetting2.Product__c = 'MPL';
        secSetting2.Active__c = true;
        secSetting2.Record_Type__c = 'Celerity';
        secSetting2.Quote_Layer__c = 'Excess';
        secSetLst.add(secSetting2);
        
        SectionSetting__c secSetting3 = new SectionSetting__c();
        secSetting3.Component__c = 'Rate Quotes';
        secSetting3.Main_Section__c = 'Quote Data';
        secSetting3.Sub_Section__c = 'Insured Contact Info';
        secSetting3.Source_Object__c = 'Quote';
        secSetting3.Order__c = 2;
        secSetting3.Source_Field_Label__c = 'Quote Type';
        secSetting3.Source_Field_API__c = 'Quote_Type__c';
        secSetting3.Format__c = 'Picklist';
        secSetting3.Product__c = 'MPL';
        secSetting3.Active__c = true;
        secSetting3.Record_Type__c = 'Celerity';
        secSetting3.Quote_Layer__c = 'Excess';
        secSetLst.add(secSetting3);
        
        insert secSetLst;
    }
    
    @isTest
    public static void testInitValues() {
        Opportunity sub = [SELECT id FROM Opportunity LIMIT 1];
        QuoteComparisonLWC.initValues(sub.Id, false);
    }
    
    @isTest
    public static void testGetFieldType() {
        String resultStr = QuoteComparisonLWC.getFieldType('Name','Account');
        System.assertEquals('String',resultStr);
        String resultPcklst = QuoteComparisonLWC.getFieldType('Country_Code__c','Account');
        System.assertEquals('Picklist',resultPcklst);
        String resultNull = QuoteComparisonLWC.getFieldType('NumberOfEmployees','Account');
        System.assertEquals(null,resultNull);
    }
    
    @isTest
    public static void testUpdateQuote() {
        QuoteComparisonLWC.updateQuote('{}', 'Testing');
        QuoteComparisonLWC.updateQuote('', 'Testing');
    }
}