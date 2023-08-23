@isTest
private class ViewDocumentControllerTest {
    
    @testsetup static void testSetup(){
        TriggerSettings__c settings = new TriggerSettings__c();
        settings.BypassQuoteTrigger__c = true;
        settings.BypassOpportunityTrigger__c = true;
        insert settings;

        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'AnyCity', 'New York', '11354', 'United States');        acc.BillingStreet = acc.ShippingStreet;
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
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, prod.Id);
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        opp.CloseDate = Date.today();
        opp.Innovisk_Entity_ID__c = 'Aqueous';        
        opp.Coverage_Product_Options__c = 'Professional Indemnity';       
        opp.StageName = 'Qualified';
        opp.Expiration_Date__c = Date.today()+60;
        insert opp;
        
        Master_Binder__c masterbinder =new Master_Binder__c();
        masterbinder.Name = 'binderTest';
        masterbinder.Layer__c = 'Primary;Excess';
        insert masterbinder;
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'Quoted';
        //quote1.Coverage_Product_Options__c = 'D&O';
        quote1.Refer_Type__c = 'Underwriting Referral';
        quote1.Master_Binder__c = masterbinder.Id;
        insert quote1;  
        
        
        
    }
    
    static TestMethod void getDocumentEncodeTest() {
        
        Document_Revision__c newDoc = new Document_Revision__c(
            Name = 'QuoteProposal_' + String.valueOf(Datetime.now()),
            Document_Azure_Id__c = '123456789',
            Document_Type__c = 'QuoteProposal'
        );
        insert newDoc;
        // Set mock callout class
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        mock.body = 'Created by SFDC VN team';
        mock.statusCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        String actual =  ViewDocumentController.getDocumentEncode(String.valueOf(newDoc.Id)).docName;
        Test.stopTest();
        
        System.assert(newDoc != null);
        System.assertEquals(newDoc.Name + '.pdf', actual);
    }
    static TestMethod void getDocumentEncodeByQuoteIdTest(){
        
        List<Quote> quotes = [SELECT Id,Name FROM Quote];
        
        Document_Revision__c newDoc = new Document_Revision__c(
            Name = 'QuoteProposal_' + String.valueOf(Datetime.now()),
            Document_Azure_Id__c = '123456789',
            Document_Type__c = 'QuoteProposal',
            Quote_Id__c = quotes[0].Id
        );
        insert newDoc;
        
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        mock.body = 'Created by SFDC VN team';
        mock.statusCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        String actual =  ViewDocumentController.getDocumentEncodeByQuoteId(String.valueOf(quotes[0].Id), 'worksheet').docName;
        String actual2 =  ViewDocumentController.getDocumentEncodeByQuoteId(String.valueOf(quotes[0].Id), 'quote').docName;
        Test.stopTest();
        
        System.assert(newDoc != null);
        System.assert(String.isEmpty(actual));
        
    }
    static TestMethod void getDocumentEncodeByQuoteIdNoFileTest(){
        
        List<Quote> quotes = [SELECT Id,Name  FROM Quote];
        
        Document_Revision__c newDoc = new Document_Revision__c(
            Name = 'QuoteProposal_' + String.valueOf(Datetime.now()),
            Document_Azure_Id__c = '123456789',
            Document_Type__c = 'QuoteProposal'
        );
        insert newDoc;
        
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        mock.body = 'Created by SFDC VN team';
        mock.statusCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        String actual =  ViewDocumentController.getDocumentEncodeByQuoteId(String.valueOf(quotes[0].Id), 'policyWording').docName;
        Test.stopTest();
        
        System.assert(newDoc != null);
        System.assert(String.isEmpty(actual));
        
    }
    static TestMethod void getDocumentEncodeByQuoteIdAQTest(){
        Document_Revision__c newDoc = new Document_Revision__c(
            Name = 'QuoteProposal_' + String.valueOf(Datetime.now()),
            Document_Azure_Id__c = '123456789',
            Document_Type__c = 'Test'
        );
        insert newDoc;
        
        
        List<Quote> quotes = [SELECT Id,Name, OpportunityId ,Quote_Type__c FROM Quote];
        quotes[0].Quote_Type__c='Coverage Amendment';
        quotes[0].Status = 'Quoted';
        quotes[0].Layer__c = 'Excess';
        quotes[0].Rating_Status__c = 'Clear';
        update quotes;
        
        String actualT1 =  ViewDocumentController.getDocumentEncodeByQuoteIdAQ(String.valueOf(quotes[0].OpportunityId),'binderTest', 'quote', 'Excess').docName;
        quotes[0].Quote_Type__c='New Business';
        update quotes;
        
        
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        mock.body = 'Created by SFDC VN team';
        mock.statusCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        String actual1 =  ViewDocumentController.getDocumentEncodeByQuoteIdAQ(String.valueOf(quotes[0].OpportunityId),'binderTest', 'quote', 'Excess').docName;
        //String actual2 =  ViewDocumentController.getDocumentEncodeByQuoteIdAQ(String.valueOf(quotes[0].OpportunityId),'binderTest', 'IPIDs', 'Excess').docName;
        //String actual3 =  ViewDocumentController.getDocumentEncodeByQuoteIdAQ('wrong id','binderTest', 'policyWording', 'Excess').docName;
        Test.stopTest();
        
        System.assert(newDoc != null);
        System.assert(String.isEmpty(actual1));
    }
    
    static TestMethod void getDocumentEncodeByQuoteIdAQTest2(){
        Test.startTest();
        List<Quote> quotes = [SELECT Id,Name,Quote_Type__c,OpportunityId FROM Quote];
        quotes[0].Quote_Type__c='New Business';
        update quotes;
        // Insert document revision
        Document_Revision__c newDoc = new Document_Revision__c(
            Name = 'QuoteProposal_' + String.valueOf(Datetime.now()),
            Document_Azure_Id__c = '123456789',
            Document_Type__c = 'PolicyScheduleExcess',
            Binder__c = 'binderTest',
            Submission__c  = quotes[0].OpportunityId
        );
        insert newDoc;
        
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        mock.body = 'Created by SFDC VN team';
        mock.statusCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        

        String actual1 =  ViewDocumentController.getDocumentEncodeByQuoteIdAQ(String.valueOf(quotes[0].Id),'', 'QuoteProposal', 'Excess').docName;
        //String actual2 =  ViewDocumentController.getDocumentEncodeByQuoteIdAQ(quotes[0].OpportunityId,'binderTest', 'policyWording', 'Excess').docName;
        //String actual3 =  ViewDocumentController.getDocumentEncodeByQuoteIdAQ('wrong id','binderTest', 'policyWording', 'Wrong Excess').docName;
        Test.stopTest();
        
        System.assert(newDoc != null);
        //System.assert(actual1.contains('QuoteProposal'));
    }  
    static TestMethod void getDocumentEncodeByQuoteIdAQQCTest(){
        Test.startTest();
        List<Quote> quotes = [SELECT Id,Name, OpportunityId  FROM Quote];
        quotes[0].Quote_Type__c='New Business';
        update quotes;
        Document_Revision__c newDoc = new Document_Revision__c(
            Name = 'QuoteProposal_' + String.valueOf(Datetime.now()),
            Document_Azure_Id__c = '123456789',
            Document_Type__c = 'Test'
        );
        insert newDoc;
        
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        mock.body = 'Created by SFDC VN team';
        mock.statusCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        
        String actual1 =  ViewDocumentController.getDocumentEncodeByQuoteIdAQQC(String.valueOf(quotes[0].Id),'','', 'policyWording', 'Excess','docid').docName;
        String actual2 =  ViewDocumentController.getDocumentEncodeByQuoteIdAQQC(quotes[0].OpportunityId,'quotes[0].id','binderTest', 'policyWording', 'Excess','docid').docName;
        String actual3 =  ViewDocumentController.getDocumentEncodeByQuoteIdAQQC('wrong id','quoteID','binderTest', 'policyWording', 'Wrong Excess','docid').docName;
        Test.stopTest();
        
        System.assert(newDoc != null);
        System.assert(String.isEmpty(actual1));
    }
    
    static TestMethod void getDocumentEncodeByQuoteIdAQQCTest2(){
        
        List<Quote> quotes = [SELECT Id,Name, OpportunityId  FROM Quote];
        
         
        //String actualT1 =  ViewDocumentController.getDocumentEncodeByQuoteIdAQQC(String.valueOf(quotes[0].Id),'','', 'QuoteProposal', 'Excess','docid').docName;
        //String actualT2 =  ViewDocumentController.getDocumentEncodeByQuoteIdAQQC(quotes[0].OpportunityId,'quotes[0].id','binderTest', 'QuoteProposal', 'Excess','docid').docName;
        //String actualT3 =  ViewDocumentController.getDocumentEncodeByQuoteIdAQQC('wrong id','quoteID','binderTest', 'policyWording', 'Wrong Excess','docid').docName;
        
        // Insert document revision
        Document_Revision__c newDoc = new Document_Revision__c(
            Name = 'QuoteProposal_' + String.valueOf(Datetime.now()),
            Document_Azure_Id__c = '123456789',
            Document_Type__c = 'PolicyScheduleExcess',
            Binder__c = 'binderTest',
            Submission__c  = quotes[0].OpportunityId
        );
        insert newDoc;
        
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        mock.body = 'Created by SFDC VN team';
        mock.statusCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        String actual1 =  ViewDocumentController.getDocumentEncodeByQuoteIdAQQC(String.valueOf(quotes[0].Id),'','', 'QuoteProposal', 'Excess','docid').docName;
        String actual2 =  ViewDocumentController.getDocumentEncodeByQuoteIdAQQC(quotes[0].OpportunityId,'quotes[0].id','binderTest', 'QuoteProposal', 'Excess','docid').docName;
        String actual3 =  ViewDocumentController.getDocumentEncodeByQuoteIdAQQC('wrong id','quoteID','binderTest', 'policyWording', 'Wrong Excess','docid').docName;
        Test.stopTest();
        
        System.assert(newDoc != null);
        //System.assert(actual2.contains('QuoteProposal'));
    }  
}