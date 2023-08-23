@isTest
private class GenerateQuoteDocumentControllerTest {
    
    @testSetup
    public static void testSeupMethod() {
        TriggerSettings__c setting = new TriggerSettings__c();
        setting.BypassQuoteTrigger__c = true;
        setting.BypassContentDocumentLinkTrigger__c = false;
        insert setting;
        
        // create broker account        
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert accBroker;              	
        
        // create product
        Product2 product = TestUtil.createProduct('MPL Standalone');
        insert product;
        
        Account acc = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
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
        
        // create opportunity        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, prod.Id);
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        opp.StageName = 'Qualified'; 
        opp.Innovisk_Entity_ID__c = 'Aqueous';                            
        opp.Product__c = prod.Id;
        opp.Submission_Status__c = 'Quoted';
        opp.Transaction_Status__c = 'Active';
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
		insert opp;             				
        
        Subjectivity_Template__c subjectivityTemplate = new Subjectivity_Template__c();
        subjectivityTemplate.Subjectivity_Name__c = 'Signed / Dated Proposal';
        subjectivityTemplate.Subjectivity_Text__c = 'Test';
        subjectivityTemplate.Profession_Criteria__c = 'Engineers';
        insert subjectivityTemplate;
        
        //create Quote
        Quote q = TestUtil.createQuote('Test Quote', opp.Id);
        q.Rating_Status__c = 'Clear';
        q.Status = 'Quoted';       
        insert q;
        
        Subjectivity__c subj = new Subjectivity__c();
        subj.Subjectivity__c = 'Testing';
        subJ.Subjectivity_Status__c = 'Open';
        subJ.Subjectivity_Type__c = 'MPL';
        subJ.Quote__c = q.Id;
        subJ.RecordTypeId = Schema.SObjectType.Subjectivity__c.getRecordTypeInfosByName().get(GlobalVariables.RT_NAME_SUBJECTIVITY_CELERITY).getRecordTypeId();
        insert subJ;
        
        Quote q1 = TestUtil.createQuote('InProgress Quote', opp.Id);
        q1.Rating_Status__c = 'Clear';
        q1.Status = 'In Progress';
        q1.Layer__c = 'Primary';
        insert q1;
        
    }
    
    
    @isTest static void generateDocIdTest() {
        
        Quote quote = [SELECT Id, Status, Rating_Status__c,Master_Binder__c FROM Quote WHERE Name='Test Quote' limit 1];
        Master_Binder__c masterbinder =new Master_Binder__c();
        masterbinder.id= quote.Master_Binder__c;
        quote.Quote_Type__c = 'Amendment';
        update quote;   
        
        String quoteAzureId = [SELECT Id, Azure_Id__c FROM Quote WHERE Id=: quote.Id].Azure_Id__c;
        Opportunity opp =[Select id from Opportunity limit 1];
        
        
        Test.startTest();
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setMock(HttpCalloutMock.class, mock);
        
        GenerateQuoteDocumentController.generateDocId(quote.Id, 'quote');
        GenerateQuoteDocumentController.generateDocId(quote.Id, 'worksheet');
        GenerateQuoteDocumentController.getBinder(opp.id,'quote','Primary');
        GenerateQuoteDocumentController.getBinder(opp.id,'quote','Excess');
        GenerateQuoteDocumentController.getBinder('','quote','Excess');
        
        //List<Master_Binder__c> listMasterBinder =[Select Id, Name from Master_Binder__c limit 1];
        GenerateQuoteDocumentController.getMastreBinderName(masterbinder.Id);
        
        //GenerateQuoteDocumentController.generateDocId(quote.Id,quoteAzureId);
        
        Test.stopTest();
        System.Assert(quote.Id != null);
        
    }
    
    @isTest static void generateDocIdTest1() {
        
        Quote quote = [SELECT Id, Status, Rating_Status__c FROM Quote WHERE Name='Test Quote' limit 1];
        quote.Quote_Type__c = 'Amendment';
        quote.Rating_Status__c = 'Refer';
        quote.Status = 'In Progress';    
        update quote;   
        
        String quoteAzureId = [SELECT Id, Azure_Id__c FROM Quote WHERE Id=: quote.Id].Azure_Id__c;
        
        Test.startTest();
        
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setMock(HttpCalloutMock.class, mock);
        GenerateQuoteDocumentController.generateDocId(quote.Id, 'quote');
        Test.stopTest();
        System.assertEquals('In Progress', quote.Status);
        
    }
    
    @isTest static void generateDocIdAqueous() {                  
        Test.startTest();
        
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setMock(HttpCalloutMock.class, mock);
        
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
        
        Opportunity oppaq = TestUtil.createOpportunity('Aqueous Test',acc.Id, prod.Id);
        oppaq.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        oppaq.Innovisk_Entity_ID__c = 'Aqueous';        
        oppaq.Coverage_Product_Options__c = 'Professional Indemnity';
        oppaq.StageName = 'Qualified';
        insert oppaq;
        
        Quote quoteaq = Testutil.createQuote('New Quote 2', oppaq.Id);
        quoteaq.Rating_Status__c = 'Clear';
        quoteaq.Status = 'Quoted';       
        insert quoteaq;
        quoteaq.Layer__c='Excess';
        update quoteaq;
        
        GenerateQuoteDocumentController.generateDocId(quoteaq.Id,'quote');
     
        Master_Binder__c mb = new Master_Binder__c(Name='Test Master Binder');
        insert mb;
        
        Quote quote = quoteaq;
        quote.Quote_Type__c = 'Amendment';
        quote.Rating_Status__c = 'Clear';
        quote.Status = 'Quoted'; 
        quote.Layer__c = 'Primary';
        quote.Master_Binder__c = mb.Id;
        update quote;   
        
        quote = [SELECT Id, Azure_Id__c,Quote_Type__c, opportunityId, Master_Binder__r.Name FROM Quote WHERE Id=: quote.Id];
        String quoteAzureId = quote.Azure_Id__c;
        GenerateQuoteDocumentController.generateDocId(quote.Id,'quote');
        GenerateQuoteDocumentController.generateDocIdAQ(quote.opportunityId, quote.Master_Binder__r.Name,'worksheet', 'Primary');
        
        Test.stopTest();
        System.assert(quote.Quote_Type__c == 'Amendment');
    }
    
    @isTest static void generateDocIdAQTest() {
        
        Master_Binder__c mb = new Master_Binder__c(Name='Test Master Binder');
        insert mb;
        
        Quote quote = [SELECT Id, Status, Rating_Status__c,Quote_Type__c FROM Quote WHERE Name='InProgress Quote' limit 1];
        quote.Quote_Type__c = 'Amendment';
        quote.Rating_Status__c = 'Clear';
        quote.Status = 'Quoted'; 
        quote.Layer__c = 'Primary';
        quote.Master_Binder__c = mb.Id;
        update quote;   
        
        quote = [SELECT Id, Azure_Id__c, opportunityId, Master_Binder__r.Name FROM Quote WHERE Id=: quote.Id];
        String quoteAzureId = quote.Azure_Id__c;
        
        Test.startTest();
        
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setMock(HttpCalloutMock.class, mock);
        
        GenerateQuoteDocumentController.generateDocIdAQ(quote.opportunityId, quote.Master_Binder__r.Name,'worksheet', 'Primary');
        //GenerateQuoteDocumentController.generateDocIdAQQC(quote.opportunityId, quote.Id, quote.Master_Binder__r.Name, 'worksheet',' Primary');
        //GenerateQuoteDocumentController.generateDocId(quote.Id,  quoteAzureId);
        
        Test.stopTest();
        System.Assert(quote.Id != null);
        
    }
    
    @isTest static void generateDocIdAQQCTest() {
        
            Master_Binder__c mb = new Master_Binder__c(Name='Test Master Binder');
            insert mb; 
            
            Quote quote1 = [SELECT Id, Status,opportunityId, quote.Master_Binder__r.Name, Layer__c,Rating_Status__c,Quote_Type__c,Azure_Id__c FROM Quote WHERE Name='InProgress Quote' limit 1];
            quote1.Quote_Type__c = 'Amendment';
            quote1.Rating_Status__c = 'Clear';
            quote1.Status = 'Quoted'; 
            quote1.Layer__c = 'Excess';
            quote1.Master_Binder__c = mb.Id;
        	quote1.Quote_Type__c = 'Coverage Amendment';
            update quote1;             
            
            String quoteAzureId1 = quote1.Azure_Id__c;     
        	
            MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
            Test.setMock(HttpCalloutMock.class, mock);
            Test.startTest();
            GenerateQuoteDocumentController.generateDocIdAQQC( quote1.opportunityId, quote1.Id, 'Test Master Binder', 'worksheet','Excess');
            
            Test.stopTest();
            System.Assert(quote.Id != null);
        
    }
    
    @isTest static void generateDocIdAQQCTest2() {
        
            Master_Binder__c mb = new Master_Binder__c(Name='Test Master Binder');
            insert mb; 
            
            Quote quote1 = [SELECT Id, Status,opportunityId, quote.Master_Binder__r.Name, Layer__c,Rating_Status__c,Quote_Type__c,Azure_Id__c FROM Quote WHERE Name='InProgress Quote' limit 1];
            quote1.Quote_Type__c = 'Amendment';
            quote1.Rating_Status__c = 'Clear';
            quote1.Status = 'Quoted'; 
            quote1.Layer__c = 'Excess';
            quote1.Master_Binder__c = mb.Id;
        	quote1.Quote_Type__c = 'New Business';
            update quote1;             
            
            String quoteAzureId1 = quote1.Azure_Id__c;     
        	
            MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
            Test.setMock(HttpCalloutMock.class, mock);
            Test.startTest();
            GenerateQuoteDocumentController.generateDocIdAQQC( quote1.opportunityId, quote1.Id, 'Test Master Binder', 'worksheet','Excess');
            
            Test.stopTest();
            System.Assert(quote.Id != null);
        
    }
    
    @isTest static void ExceptionTest(){
        String quoteId = '//'; 
        
        Test.startTest();               
        GenerateQuoteDocumentController.generateDocId(quoteId, ''); 
        Test.stopTest();  
        
        System.assertEquals('//', quoteId);
    }
    
    
    @isTest static void generateDocIdAqueoustest() {                  
        Test.startTest();
        
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setMock(HttpCalloutMock.class, mock);
        
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
        
        Opportunity oppaq = TestUtil.createOpportunity('Aqueous Test',acc.Id, prod.Id);
        oppaq.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        oppaq.Innovisk_Entity_ID__c = 'Aqueous';        
        oppaq.Coverage_Product_Options__c = 'Professional Indemnity';
        oppaq.StageName = 'Qualified';
        insert oppaq;
        
        Quote quoteaq = Testutil.createQuote('New Quote 2', oppaq.Id);
        quoteaq.Rating_Status__c = 'Clear';
        quoteaq.Status = 'Quoted';       
        insert quoteaq;
        quoteaq.Layer__c='Excess';
        update quoteaq;
        
        GenerateQuoteDocumentController.generateDocId(quoteaq.Id,'quote');
        
        Master_Binder__c mb = new Master_Binder__c(Name='Test Master Binder');
        insert mb;
        
        Quote quote = quoteaq;
        quote.Quote_Type__c = 'New Business';
        quote.Rating_Status__c = 'Clear';
        quote.Status = 'Quoted'; 
        quote.Layer__c = 'Primary';
        quote.Master_Binder__c = mb.Id;
        update quote;   
        
        quote = [SELECT Id, Azure_Id__c,Quote_Type__c, opportunityId, Master_Binder__r.Name FROM Quote WHERE Id=: quote.Id];
        String quoteAzureId = quote.Azure_Id__c;
        
        GenerateQuoteDocumentController.generateDocIdAQ(quote.opportunityId, quote.Master_Binder__r.Name,'quote', 'Primary');
        
        Test.stopTest();
        System.assert(quote.Quote_Type__c == 'New Business');
    }
    
    @isTest static void generateDocIdAQQCTest1() {
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setMock(HttpCalloutMock.class, mock);
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
        
        Opportunity oppaq = TestUtil.createOpportunity('Aqueous Test',acc.Id, prod.Id);
        oppaq.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        oppaq.Innovisk_Entity_ID__c = 'Aqueous';        
        oppaq.Coverage_Product_Options__c = 'Professional Indemnity';
        oppaq.StageName = 'Qualified';
        insert oppaq;
        
        Quote quoteaq = Testutil.createQuote('New Quote 2', oppaq.Id);
        quoteaq.Rating_Status__c = 'Clear';
        quoteaq.Status = 'Quoted';       
        insert quoteaq;
        quoteaq.Layer__c='Excess';
        update quoteaq;
        
        GenerateQuoteDocumentController.generateDocId(quoteaq.Id,'quote');
        
        Master_Binder__c mb = new Master_Binder__c(Name='Test Master Binder');
        insert mb;   
        
        Quote quote = [SELECT Id, Azure_Id__c,Quote_Type__c, opportunityId, Master_Binder__r.Name FROM Quote WHERE Id=: quoteaq.Id];
        String quoteAzureId = quote.Azure_Id__c;
        List<Quote> quoteList = new List<Quote>(); 
       Quote quote1 = quoteaq;
        quote1.Quote_Type__c = 'New Business';
        quote1.Rating_Status__c = 'Clear';
        quote1.Status = 'Quoted'; 
        quote1.Layer__c = 'Primary';
        quote1.Master_Binder__c = mb.Id;
        update quote1;   
        quoteList.add(quote1);  
        upsert quoteList;
       
        
   
        quoteList = [SELECT Id, Azure_Id__c, opportunityId, Master_Binder__r.Name FROM Quote WHERE Id=: quoteList[0].Id];
        String quoteAzureId1 = quoteList[0].Azure_Id__c;     
        
        Test.startTest();
  
        //GenerateQuoteDocumentController.generateDocIdAQ(quote.opportunityId, quote.Master_Binder__r.Name,'worksheet', 'Primary');
        GenerateQuoteDocumentController.generateDocIdAQQC( quoteList[0].opportunityId,  quoteList[0].Id,  quoteList[0].Master_Binder__r.Name, 'worksheet',' Primary');
        //GenerateQuoteDocumentController.generateDocId(quote.Id,  quoteAzureId);
        //delete quoteList;
        Test.stopTest();
        System.Assert(quote.Id != null);
        
    }
    
}