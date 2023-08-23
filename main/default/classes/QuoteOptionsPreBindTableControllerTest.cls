@isTest
public class QuoteOptionsPreBindTableControllerTest {
    
    @testSetup
    static void testSetup(){
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        setting.BypassCoverageLineItemTrigger__c = true;
        setting.BypassAccountTrigger__c = true;
        update setting;
        
        Account acc = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 product = TestUtil.createProduct('Professional Indemnity');
        product.RecordTypeId = aqueousRecordTypeId;
        product.Innovisk_Entity_ID__c = 'Aqueous';
        insert product;
        
        String rdPolicyId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId();
        Policy__c policy = new Policy__c();
        policy.Account__c = acc.Id;
        policy.Expiration_Date__c = Date.today().addDays(10);
        policy.Policy_Number__c = '12345';
        policy.Effective_Date__c = Date.today()+5;
        policy.Policy_Status__c = 'Bound';
        policy.Renewal_Completed__c = false;
        policy.Policy_Status__c = 'Active';
        insert policy;
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        opp.StageName = 'Closed Won';
        opp.CloseDate = Date.today()+10;
        opp.Innovisk_Entity_ID__c = 'Aqueous';
        opp.Product__c = product.Id;
        opp.Effective_Date__c = Date.today();
        opp.Expiration_Date__c = Date.today()+60;
        opp.Received_Date__c=Date.today()-120;
        opp.Submission_Status__c = 'Quoted';
        opp.Transaction_Status__c = 'Active';
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        opp.Azure_ID__c= 'Test Id';
        opp.Policy__c=policy.Id;
        opp.Probability= 0.5;
        insert opp;
        
        Quote quoteObj = TestUtil.createQuote('TestQuote', opp.Id);
        quoteObj.Status = 'In Progress';
        quoteObj.Coverage_Product_Options__c = 'D&O';
        quoteObj.Refer_Type__c = 'Underwriting Referral';
        quoteObj.Rating_Status__c = 'Refer';
        quoteObj.Last_Quote_Version__c = 'Version 1';
        quoteObj.Policy__c = policy.id;
        quoteObj.CloseDate__c = Date.today() + 120;
        insert quoteObj;
        
        SectionSetting__c sectionSettingObj = new SectionSetting__c();
        sectionSettingObj.Component__c = 'Submission Info';
        sectionSettingObj.Order__c = 7;
        sectionSettingObj.Main_Section__c = 'Submission Status';
        sectionSettingObj.Sub_Section__c = 'Submission Status Sub';
        sectionSettingObj.Source_Object__c = 'Opportunity';
        sectionSettingObj.Source_Field_API__c = 'Amount';
        sectionSettingObj.Source_Field_Label__c = 'Amount';
        sectionSettingObj.Format__c = 'Number';
        sectionSettingObj.Active__c = true;
        sectionSettingObj.Record_Type__c = 'Celerity';
        sectionSettingObj.Product__c = 'Professional Indemnity';
        sectionSettingObj.DisplayType__c = 'Open';
        sectionSettingObj.Quote_Layer__c = 'Primary';
        insert sectionSettingObj;
        
        SectionSetting__c sectionSettingObj2 = new SectionSetting__c();
        sectionSettingObj2.Component__c = 'Quote Console';
        sectionSettingObj2.Order__c = 7;
        sectionSettingObj2.Main_Section__c = 'Quote Options';
        sectionSettingObj2.Sub_Section__c = 'Submission Status Sub';
        sectionSettingObj2.Source_Object__c = 'Quote_Option__c';
        sectionSettingObj2.Source_Field_API__c = 'Minimum_Premium__c';
        sectionSettingObj2.Source_Field_Label__c = 'Minimum_Premium__c';
        sectionSettingObj2.Format__c = 'Number';
        sectionSettingObj2.Active__c = true;
        sectionSettingObj2.Record_Type__c = 'Aqueous';
        sectionSettingObj2.Product__c = 'Professional Indemnity';
        sectionSettingObj2.DisplayType__c = 'Open';
        sectionSettingObj2.Quote_Layer__c = 'Primary';
        insert sectionSettingObj2;
        
        Quote_Option__c quoteOptionObj = new Quote_Option__c();
        quoteOptionObj.Quote__c = quoteObj.Id;
        quoteOptionObj.Option_Type__c = 'Fixed Limit';
        quoteOptionObj.Selected__c = true;
        quoteOptionObj.Bound__c = true;
        insert quoteOptionObj;
    }
    @isTest
    static void runTest(){
        Test.startTest();
        Quote quoteObj = [Select Id, OpportunityId, layer__c from Quote where Name = 'TestQuote'];
        Quote_Option__c quoteOptions = [Select Id,Selected__c from Quote_Option__c where Quote__c =: quoteObj.Id];
        QuoteOptionsPreBindTableController.fetchQuoteOptions(quoteObj.Id);
        QuoteOptionsPreBindTableController.updateQuoteOptions(quoteObj.Id, quoteOptions.Id);
        QuoteOptionsPreBindTableController obj = new QuoteOptionsPreBindTableController();
        QuoteOptionsPreBindTableController.syncQuoteToMiddleware(quoteObj.Id, quoteOptions.Id);
        Test.stopTest();
        System.assert(quoteOptions.Id != null);
    }
}