@isTest
public class REST_Invsk_QuoteOperation_v2_Test {
@testSetup
    public static void setup() {
       // Test.startTest();
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        Product2 product = TestUtil.createProduct('Celerity');
        insert product; 
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Prospect';
        insert opp;
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'Rated';
        quote1.Rating_Status__c ='Clear';
        quote1.Azure_ID__c = '854db2f3';
        quote1.Coverage_Product_Options__c = 'D&O';
        quote1.Refer_Type__c = 'Underwriting Referral';
        insert quote1;  
        
        Document_Revision__c documentRevision = new Document_Revision__c();
        documentRevision.Quote_Id__c = quote1.Id;
        documentRevision.Document_Azure_Id__c= 'Test Document';
        insert documentRevision;
        
        Subjectivity__c subj = new Subjectivity__c();
        subj.Subjectivity__c = 'Testing';
        subJ.Subjectivity_Status__c = 'Open';
        subJ.Subjectivity_Type__c = 'MPL';
        subJ.Quote__c = quote1.Id;
        subJ.RecordTypeId = Schema.SObjectType.Subjectivity__c.getRecordTypeInfosByName().get(GlobalVariables.RT_NAME_SUBJECTIVITY_CELERITY).getRecordTypeId();
        insert subJ;
        
        Policy__c policy = new Policy__c();
        policy.Account__c = acc.Id;
        policy.Product_Name__c = 'MPL';
        policy.Expiration_Date__c = Date.today().addDays(100);
        policy.Total_Premium__c = 2000;
        policy.Initial_Premium__c = null;
        insert policy;
      //  Test.stopTest();
    }
    
    @isTest
    static void testQuoteInvalidAzureId() {
       Test.startTest();
        REST_Invsk_QuoteOperation_v2.CommingRequest com = new REST_Invsk_QuoteOperation_v2.CommingRequest();
        Opportunity currentOpp = [SELECT Azure_ID__c FROM Opportunity];
        com.quoteAzureId = currentOpp.Azure_ID__c;
        com.operation = 'FinalizeQuote';
        com.status = '';

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_QuoteOperation_v2';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(com));

        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
        
        REST_Invsk_QuoteOperation_v2.doPost();
        Test.stopTest();
        
        System.assertEquals(400, RestContext.response.statusCode);
    }
    @isTest
    static void testQuoteFinalizeError() {
       
        REST_Invsk_QuoteOperation_v2.CommingRequest com = new REST_Invsk_QuoteOperation_v2.CommingRequest();
        Quote currentQuote = [SELECT Azure_ID__c FROM Quote];
        currentQuote.Status ='In Progress';
        update currentQuote;
        com.quoteAzureId = currentQuote.Azure_ID__c;
        com.operation = 'FinalizeQuote';

        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_QuoteOperation_v2';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(com));
        RestResponse response = new RestResponse();
        
        RestContext.request = request;
        RestContext.response = response;
        Test.startTest();
        REST_Invsk_QuoteOperation_v2.doPost();
        Test.stopTest();
        
        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testStatusUpdateQuoted() {
         Test.startTest();

        REST_Invsk_QuoteOperation_v2.CommingRequest com = new REST_Invsk_QuoteOperation_v2.CommingRequest();
        Quote currentQuote = [SELECT Azure_ID__c FROM Quote];
        com.quoteAzureId = currentQuote.Azure_ID__c;
        com.operation = 'StatusUpdate';
        com.status = 'Quoted';
        
        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_QuoteOperation_v2';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(com));

        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
       
        REST_Invsk_QuoteOperation_v2.doPost();
        Test.stopTest();
        
        System.assertEquals(200, RestContext.response.statusCode);
    }
    @isTest
    static void testStatusUpdateClosed() {

        REST_Invsk_QuoteOperation_v2.CommingRequest com = new REST_Invsk_QuoteOperation_v2.CommingRequest();
        Quote currentQuote = [SELECT status,Azure_ID__c FROM Quote];
        com.quoteAzureId = currentQuote.Azure_ID__c;
        com.operation = 'StatusUpdate';
        com.status = 'Closed';
        com.closedReason ='Closed';

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_QuoteOperation_v2';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(com));

        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
        Test.startTest();
        REST_Invsk_QuoteOperation_v2.doPost();
        Test.stopTest();
        
        System.assertEquals(currentQuote.status, 'Rated');
    }

    @isTest
    static void testAzureIDempty() {
        List<String> errors = new List<String>();
        REST_Invsk_QuoteOperation_v2.CommingRequest com = new REST_Invsk_QuoteOperation_v2.CommingRequest();
        com.quoteAzureId = '';
        com.operation = '';
        com.status = '';

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_QuoteOperation_v2';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(com));

        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
        Test.startTest();
        REST_Invsk_QuoteOperation_v2.doPost();
        Test.stopTest();
        
        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testQuoteOperationCaseStatusUpdateEmpty() {
        
        REST_Invsk_QuoteOperation_v2.CommingRequest com = new REST_Invsk_QuoteOperation_v2.CommingRequest();
        Quote currentQuote = [SELECT Azure_ID__c FROM Quote];
        com.quoteAzureId = currentQuote.Azure_ID__c; 
        com.operation = 'StatusUpdate';
        com.status = '';

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_QuoteOperation_v2';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(com));

        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
        Test.startTest();
        REST_Invsk_QuoteOperation_v2.doPost();
        Test.stopTest();
        
        System.assertEquals(200, RestContext.response.statusCode);
    }
    @isTest
    static void testQuoteInvalidOperation() {
        
        REST_Invsk_QuoteOperation_v2.CommingRequest com = new REST_Invsk_QuoteOperation_v2.CommingRequest();
        Quote currentQuote = [SELECT Azure_ID__c FROM Quote];
        com.quoteAzureId = currentQuote.Azure_ID__c; 
        com.operation = 'Invalid';

        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_QuoteOperation_v2';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(com));

        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
        Test.startTest();
        REST_Invsk_QuoteOperation_v2.doPost();
        Test.stopTest();
        
        System.assertEquals(200, RestContext.response.statusCode);
    }
    @isTest
    static void testQuoteOperationChangeSummary() {
        
        List<String> errors = new List<String>();
        REST_Invsk_QuoteOperation_v2.CommingRequest com = new REST_Invsk_QuoteOperation_v2.CommingRequest();
        Quote currentQuote = [SELECT Azure_ID__c FROM Quote];
        com.quoteAzureId = currentQuote.Azure_ID__c; 
        com.operation = 'ChangeSummary';
        com.status = '';

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_QuoteOperation_v2';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(com));

        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
        Test.startTest();
        REST_Invsk_QuoteOperation_v2.doPost();
        Test.stopTest();
        
        System.assertEquals(200, RestContext.response.statusCode);
    }   

    @isTest 
    static void bindQuoteTest(){
       
        Policy__c policy = [Select Id FROM Policy__c];
        policy.Policy_Status__c = 'Cancelled';
        update policy;
        Quote quo =  [SELECT Id,Azure_Id__c FROM Quote Limit 1];
        quo.Status = 'Quoted';
        quo.Policy__c = policy.Id;
        update quo;
        Test.startTest();
        REST_Invsk_QuoteOperation_v2.CommingRequest comingReq = new REST_Invsk_QuoteOperation_v2.CommingRequest();
		comingReq.quoteAzureId = quo.Azure_ID__c;
        comingReq.operation = 'BindQuote';
        Payment_Detail__c paymentDetails = new Payment_Detail__c();
        paymentDetails.Transaction_ID__c = 'abcdef';
        paymentDetails.Card_Holder_Name__c = 'HolderName';
        paymentDetails.Processor_Response_Type__c = 'Test process';
        paymentDetails.Amount__c = 200;
        paymentDetails.Processor_Response_Type__c = 'Monthly'; 
        comingReq.paymentDetails = paymentDetails;

        String myJSON = JSON.serialize(comingReq);
        RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();
        request.requestUri = '/services/apexrest/Invsk_QuoteOperation_v2/';
        request.httpMethod = 'POST';
		request.requestBody = Blob.valueof(myJSON);
		request.addHeader('Content-Type', 'application/json'); 
        RestContext.request = request;
		RestContext.response = res;

        REST_Invsk_QuoteOperation_v2.doPost();
        system.assertEquals('Quoted', [Select Status FROM Quote WHERE ID =: quo.Id].Status);
    	test.stopTest();
    }   
    @isTest 
    static void bindQuoteTestException(){
       
        Policy__c policy = [Select Id FROM Policy__c];
        Quote quo =  [SELECT Id,Azure_Id__c FROM Quote Limit 1];
        
        Test.startTest();
        REST_Invsk_QuoteOperation_v2.CommingRequest comingReq = new REST_Invsk_QuoteOperation_v2.CommingRequest();
		comingReq.quoteAzureId = quo.Azure_ID__c;
        comingReq.operation = 'BindQuote';
 
        String myJSON = JSON.serialize(comingReq);
        RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();
        request.requestUri = '/services/apexrest/Invsk_QuoteOperation_v2/';
        request.httpMethod = 'POST';
		request.requestBody = Blob.valueof(myJSON);
		request.addHeader('Content-Type', 'application/json'); 
        RestContext.request = request;
		RestContext.response = res;

        REST_Invsk_QuoteOperation_v2.doPost();
        system.assertEquals('Rated', [Select Status FROM Quote WHERE ID =: quo.Id].Status);
    	test.stopTest();
    }   
}