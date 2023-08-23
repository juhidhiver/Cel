@isTest
private class GenerateDocumentApiHandlerTest {  
         public class DocumentV2MockResponse implements HttpCalloutMock {
         public HTTPResponse respond(HTTPRequest req) {
        
         HttpResponse res = new HttpResponse();
         String baseUri = '';
             
        API_Configuration__mdt apiSettingGenerateDocV2 = CommonUtil.getAPIconfiguration('Generate_Document_V2');
		baseUri = apiSettingGenerateDocV2.Base_Url__c + apiSettingGenerateDocV2.Endpoint__c;

		if(req.getEndPoint().contains(baseUri) ) {
			System.debug('==Generate_Document==');
			res.setHeader('Content-Type', 'application/json');
			Map<String, Object> mapData = new Map<String, Object>();
			mapData.put('documentId','id-document');
			res.setBody(JSON.serialize(mapData));
			res.setStatusCode(200);
}
         return res;
    	}
    }
     static {
         
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
        
        // create opportunity        
        Opportunity opp = TestUtil.createOpportunity('Test Opportunity', accBroker.Id, product.Id);
        opp.StageName = 'Qualified';
        insert opp;
         
        // create Quote
        Quote q = TestUtil.createQuote('Test Quote', opp.Id);
        q.Rating_Status__c = 'Refer';
        q.Status = 'Rated';
        q.Azure_ID__c = '854db2f3-d6ab-43e3-9250-798669922dca';
        q.Coverage_Product_Options__c = 'D&O';
        q.Refer_Type__c = 'Underwriting Referral';
        insert q;
         
         // create policy  
        Policy__c policy = new Policy__c();        
        policy.Azure_ID__c = '123456';
        policy.Account__c = accBroker.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);           
        insert policy;
         
        Document_Revision__c documentRevision = new Document_Revision__c();
        documentRevision.Quote_Id__c = q.Id;
        documentRevision.Document_Azure_Id__c= 'Test Document';
        documentRevision.Name= 'Document Revision';
        documentRevision.Document_Type__c = 'QuoteProposal';
        //documentRevision.Submission__c = q.Id; 
        insert documentRevision;
         
         
        Account acc = TestUtil.createBusinessAccount('AQ Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
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
        
        Quote quoteaq = Testutil.createQuote('AQ Quote', oppaq.Id);
        quoteaq.Rating_Status__c = 'Clear';
        quoteaq.Status = 'Quoted';       
        quoteaq.Layer__c='Excess';
        quoteaq.Azure_ID__c = 'aq-quote-azure-id';
        insert quoteaq;
         
        Policy__c policyaq = new Policy__c();        
        policyaq.Azure_ID__c = 'contact-azure';
        policyaq.Account__c = acc.Id; 
        policyaq.Expiration_Date__c = Date.today().addDays(100);           
        insert policyaq;
         
        Document_Revision__c documentRevision2 = new Document_Revision__c();
        documentRevision2.Quote_Id__c = quoteaq.Id;
        documentRevision2.Document_Azure_Id__c= 'Test Document AQ';
        documentRevision2.Name= 'Document Revision AQ';
        documentRevision2.Document_Type__c = 'QuoteScheduleExcess';
        documentRevision2.Submission__c = oppaq.Id; 
        insert documentRevision2;
         
		ContentVersion contentVersion = new ContentVersion(
			Title = 'ACMP 27 03 Coverage Name', 
			PathOnClient = 'ACMP 27 03 Coverage Name', 
			VersionData = Blob.valueOf('ACMP 27 03 Coverage Name')
		);
		insert contentVersion;
         
    }  
    static testMethod void testgenerateDocId1() {        
        String docType = 'SOA';
        String contractAzureId = 'contact-azure';
        String bodyRequest = '{}';
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());             
        
        Test.startTest();        
        GenerateDocumentApiHandler.GenerateResult res = GenerateDocumentApiHandler.generateDocId(contractAzureId, bodyRequest);        
        System.assertEquals(res.errMsg, null);
        Test.stopTest();    
    }
    
    static testMethod void testGenerateDocId2() {        
        String docType = 'QuoteProposal';
        String parentAzureId = '123456';
        String bodyRequest = '{}';
        Test.setMock(HttpCalloutMock.class, new DocumentV2MockResponse());             
       
        Quote q = [SELECT Id FROM Quote WHERE Name='Test Quote']; 
        
        Test.startTest();                
        GenerateDocumentApiHandler.GenerateResult res = GenerateDocumentApiHandler.generateDocId('Quote_Id__c', q.Id, parentAzureId, docType, bodyRequest);  
      //  System.assertEquals(res.errMsg, null);
        Test.stopTest();    
    }
    static testMethod void testGetDocumentEncode() {   
        Document_Revision__c docRevision = [select Id,Quote_Id__c,Document_Azure_Id__c from Document_Revision__c Where Name= 'Document Revision'][0];
        String docType = 'SOA';
        String contractAzureId = 'contact-azure';
        String bodyRequest = '{}';
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());             
        
        Test.startTest();                        
        GenerateDocumentApiHandler.GenerateResult res = GenerateDocumentApiHandler.getDocumentEncode(docRevision.Document_Azure_Id__c);   
        System.assert(res != null);
        Test.stopTest();    
    }
    static testMethod void testGenerateDocRevisionPolicy() {        
        Policy__c po = [SELECT Id FROM Policy__c WHERE Azure_ID__c='123456' limit 1];        
        String docType = 'SOA';     
        String bodyRequest = '{}';
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());             
        
        Test.startTest();                
        Document_Revision__c res = GenerateDocumentApiHandler.generateDocRevisionPolicy(po.Id, 'contactId', docType, bodyRequest);        
        System.assertNotEquals(res, null);
        Test.stopTest();    
    }
    
    static TestMethod void testException() {
        Document_Revision__c docRevision = [select Id,Quote_Id__c,Document_Azure_Id__c from Document_Revision__c][0];
        String bodyRequest = '{}';
        String contractAzureId = '//' ;
        String parentAzureId = '123456';
        String docType = '//' ;
        Quote q = [SELECT Id FROM Quote WHERE Name='Test Quote'];
        //string quoteId = [Select Id, Name,Quote_Id__c, Document_Azure_Id__c FROM Document_Revision__c Limit 1].Quote_Id__c;
        Test.startTest();        
        GenerateDocumentApiHandler.generateDocId(contractAzureId, bodyRequest);
        GenerateDocumentApiHandler.generateDocId('Quote_Id__c', q.Id, contractAzureId, docType, bodyRequest);
        GenerateDocumentApiHandler.GenerateResult res = GenerateDocumentApiHandler.getDocumentEncode(docRevision.Document_Azure_Id__c);
        GenerateDocumentApiHandler.generateDocRevisionPolicy(contractAzureId, 'contactId', docType, bodyRequest);
        //GenerateDocumentApiHandler.GenerateResult res1 = GenerateDocumentApiHandler.getDocumentEncode(null);
        System.assert(res != null);
        Test.stopTest();  
    }
        static testMethod void testgenerateDocIdAQ() {    
        Document_Revision__c docRevision = [select Id,Quote_Id__c,Document_Azure_Id__c from Document_Revision__c where Name='Document Revision AQ' Limit 1];
        Quote q = [Select id, Azure_id__c From Quote Where Name= 'AQ Quote' Limit 1];
       	Account a = [SELECT id from Account Where Name='AQ Bussiness Account Test' Limit 1];
        Opportunity opp = [SELECT id from Opportunity Where Innovisk_Entity_ID__c = 'Aqueous' Limit 1];
        String bodyRequest = '{"DocumentType":"Binder","Quotes":["'+q.Azure_id__c+'"],"ProductClassCd":"Aqueous_PI","OutputFileName" : "Binder.pdf","RequestType" : "Quote","AccountId": "'+a.Id+'"}';
        String parentAzureId = '123456';
        String docType = 'Binder';
        String contractAzureId = 'contact-azure';
        
        Test.setMock(HttpCalloutMock.class, new DocumentV2MockResponse());             
        
        Test.startTest();        
        GenerateDocumentApiHandler.GenerateResult res = GenerateDocumentApiHandler.generateDocIdAQ('Policy__c',opp.Id,contractAzureId,docType, bodyRequest,'Binder');        
        System.assert(res != null);
        Test.stopTest();    
    }
    
    static testMethod void testGetDocumentEncodeAQ() {   
        Document_Revision__c docRevision = [select Id,Quote_Id__c,Document_Azure_Id__c from Document_Revision__c][0];
        String docType = 'SOA';
        String contractAzureId = 'contact-azure';
        String bodyRequest = '{}';
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());     
		Test.startTest(); 

        ContentVersion cv = [select Id, ContentDocumentId, VersionData, Title from ContentVersion][0];
                               
        GenerateDocumentApiHandler.GenerateResult res = GenerateDocumentApiHandler.getDocumentEncodeAQ(docRevision.Document_Azure_Id__c); 
        GenerateDocumentApiHandler.GenerateResult res1 = GenerateDocumentApiHandler.getQuoteDocumentEncode(cv.ContentDocumentId);
       //GenerateDocumentApiHandler.GenerateResult res1 =GenerateDocumentApiHandler.getQuoteDocumentEncode('Test');
        System.assert(res != null);
        Test.stopTest();    
    }
        static testMethod void testGetDocumentEncode2() {   
            
        
        Document_Revision__c docRevision = [select Id,Quote_Id__c,Document_Azure_Id__c from Document_Revision__c where Document_Azure_Id__c ='Test Document AQ' Limit 1 ];
        String docType = 'SOA';
        String contractAzureId = 'contact-azure';
        String bodyRequest = '{}'; 
            
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());     
        Test.startTest();                      
        GenerateDocumentApiHandler.GenerateResult res = GenerateDocumentApiHandler.getDocumentEncode(docRevision.Document_Azure_Id__c); 
		Test.stopTest();
        System.assert(res != null);
            
    }
}