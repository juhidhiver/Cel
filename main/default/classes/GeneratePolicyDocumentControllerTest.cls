@isTest
private class GeneratePolicyDocumentControllerTest {
      static {
        // create broker account        
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert accBroker;              	
        
        // create product
        Product2 product = TestUtil.createProduct('Test Product');
		insert product;
        
		// create opportunity        
        Opportunity opp = TestUtil.createOpportunity('Test Opportunity', accBroker.Id, product.Id);
        opp.StageName = 'Qualified';
        insert opp;               				
          
        // create Quote
        Quote q = TestUtil.createQuote('Test Quote', opp.Id);
        q.Rating_Status__c = 'Refer';
        q.Status = 'Bound';       
        insert q;
          
    }
    
    static testMethod void testGetListTypeDocument() {
        // create policy  
        Policy__c policy = new Policy__c();                
        insert policy;
                
        Quote quote = [SELECT Id,Policy__c FROM Quote WHERE Name='Test Quote' limit 1];
        quote.Policy__c = policy.Id;
        update quote;                    
		
        
        String bodyRequest = '{}';
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());             
        
        Test.startTest();        
        List<PicklistOption> res = GeneratePolicyDocumentController.getListTypeDocument();  
        System.assertNotEquals(res, null);
        Test.stopTest();  
    }
    
    static testMethod void testGenerateDocumentId() {
        Account acc = [SELECT Id FROM Account WHERE Name='Account_Business_Test_01' limit 1];
        
		// create policy  
        Policy__c policy = new Policy__c();        
        policy.Azure_ID__c = '123456';
        policy.Account__c = acc.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);           
        insert policy;
                
        Quote quote = [SELECT Id,Policy__c FROM Quote WHERE Name='Test Quote' limit 1];
        quote.Policy__c = policy.Id;
        update quote;                    

        /*
        String bodyRequest = '{}';
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
        */

        String policyId = policy.Id;
        String docType = 'SOA';

        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        mock.body = '{"isValidOFAC":"True"}';
        mock.statusCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();                
        GenerateDocumentApiHandler.GenerateResult res = GeneratePolicyDocumentController.generateDocumentId('', policyId,docType);
        system.debug('==resresres==' + res);
        System.assertEquals('{"message":"Unexpected Endpoint"}', res.errMsg);        
        Test.stopTest();  
    }

    static testMethod void testGenerateDocumentIdWithQuoteId() {
        Account acc = [SELECT Id FROM Account WHERE Name='Account_Business_Test_01' limit 1];
        
		// create policy  
        Policy__c policy = new Policy__c();        
        policy.Azure_ID__c = '123456';
        policy.Account__c = acc.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);           
        insert policy;
                
        Quote quote = [SELECT Id,Policy__c FROM Quote WHERE Name='Test Quote' limit 1];
        quote.Policy__c = policy.Id;
        update quote;                    

        /*
        String bodyRequest = '{}';
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
        */

        String policyId = policy.Id;
        String docType = 'SOA';

        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        mock.body = '{"isValidOFAC":"True"}';
        mock.statusCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        
        List<Quote> quotes = GeneratePolicyDocumentController.getBoundQuotes(policyId);

        Test.startTest();                
        GenerateDocumentApiHandler.GenerateResult res = GeneratePolicyDocumentController.generateDocumentId(quote.id, policyId,docType);
        system.debug('==resresres==' + res);
        System.assertEquals('{"message":"Unexpected Endpoint"}', res.errMsg);        
        Test.stopTest();  
    }
    
    static testMethod void Exception(){
        Test.startTest();                
        GenerateDocumentApiHandler.GenerateResult res = GeneratePolicyDocumentController.generateDocumentId('', '//','//');
        System.assert(res != null);
        Test.stopTest();  
    }
}