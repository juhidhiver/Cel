/**
 * Class Name: REST_Invsk_UpdateDocumentIdTest 
* Author: Vinith K
* Date: 15-Feb-2021
* Requirement/Project Name: Innovisk
*/
@isTest
private class REST_Invsk_UpdateDocumentIdTest {
	public Static String azureId = ''; 
	static{
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
        
     /*   Subjectivity_Template__c subjectivityTemplate = new Subjectivity_Template__c();
        subjectivityTemplate.Subjectivity_Name__c = 'Signed / Dated Proposal';
        subjectivityTemplate.Subjectivity_Text__c = 'Test';
        subjectivityTemplate.Profession_Criteria__c = 'Engineers';
        insert subjectivityTemplate;*/
        
        // create Quote
        Quote q = TestUtil.createQuote('Test Quote', opp.Id);
        q.Rating_Status__c = 'Clear';
        q.Status = 'Bound';
        insert q;
         
         // create policy  
        Policy__c policy = new Policy__c();        
        policy.Azure_ID__c = '123456';
        policy.Account__c = accBroker.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);           
        insert policy;
		
        azureId = new GuidUtil().NewGuid();
        Quote newQuote = [Select Id, Azure_ID__c from Quote limit 1 ];
        newQuote.Azure_ID__c = azureId;
        newQuote.Policy__c = policy.Id;
        update newQuote;

    }

	@isTest
    static void testDoPostReqNull() {
        
        // Set up a test request
		RestRequest request = new RestRequest();
		request.requestUri = '/services/apexrest/Invsk_UpdateDocumentId';
		request.httpMethod = 'POST';
		request.requestBody = Blob.valueOf(JSON.serialize(null));
		RestContext.request = request;


    	RestResponse response  = new RestResponse();
		RestContext.response = response; 

		Test.startTest();
        REST_Invsk_UpdateDocumentId.doPost();
        Test.stopTest();
		System.assertEquals(200, RestContext.response.statusCode);     
    }

	@isTest
    static void testDoPost() {
        Test.startTest();
        Quote newQuote = [Select Id,Azure_Id__c From Quote Where Azure_Id__c = :azureId];
        
        Document_Revision__c tranSitD = new Document_Revision__c();
		tranSitD.Quote_Id__c = newQuote.Id;
		tranSitD.Document_Type__c = 'QuoteProposal';
		insert tranSitD;
		        
		REST_Invsk_UpdateDocumentId.ComingRequestWrapper requestWrapper = new REST_Invsk_UpdateDocumentId.ComingRequestWrapper(); 
		requestWrapper.docType = 'QuoteProposal';
		requestWrapper.quoteId = newQuote.Azure_ID__c;
		requestWrapper.docId = tranSitD.Id;
        requestWrapper.Name = requestWrapper.docType  + '.pdf';
        
        REST_Invsk_UpdateDocumentId.ComingRequestWrapper requestWrapper2 = new REST_Invsk_UpdateDocumentId.ComingRequestWrapper(); 
		requestWrapper2.docType = 'Binder';
		requestWrapper2.quoteId = newQuote.Azure_ID__c;
		requestWrapper2.docId = tranSitD.Id;
        requestWrapper2.Name = requestWrapper2.docType  + '.pdf';

		String q = '"quoteId":"'+ newQuote.Azure_ID__c + '"'; 
		String d = '"docId":"' + tranSitD.Id + '"'; 
		String p = '"docType":"QuoteProposal"';
        String n = '"Name":"QuoteProposal.pdf"';

		String reqString = '[{' + q + ',' + d + ',' + p + ', ' + n + '}]';
        
      

     // Set up a test request
		RestRequest request = new RestRequest();
		request.requestUri = '/services/apexrest/Invsk_UpdateDocumentId';
		request.httpMethod = 'POST';
		request.requestBody = Blob.valueOf(reqString);
		RestContext.request = request;

    	RestResponse response  = new RestResponse();
		RestContext.response = response; 

		
        REST_Invsk_UpdateDocumentId.doPost();
        Test.stopTest();
		System.assertEquals(200, RestContext.response.statusCode);     
    }
    @isTest
    static void testDoPost2() {
        Test.startTest();
        Quote newQuote = [Select Id,Azure_Id__c From Quote Where Azure_Id__c = :azureId];
        
        Document_Revision__c tranSitD = new Document_Revision__c();
		tranSitD.Quote_Id__c = newQuote.Id;
		tranSitD.Document_Type__c = 'QuoteProposal';
		insert tranSitD;
		        
		REST_Invsk_UpdateDocumentId.ComingRequestWrapper requestWrapper = new REST_Invsk_UpdateDocumentId.ComingRequestWrapper(); 
		requestWrapper.docType = 'QuoteProposal';
		requestWrapper.quoteId = newQuote.Azure_ID__c;
		requestWrapper.docId = tranSitD.Id;
        requestWrapper.Name = requestWrapper.docType  + '.pdf';
        
        REST_Invsk_UpdateDocumentId.ComingRequestWrapper requestWrapper2 = new REST_Invsk_UpdateDocumentId.ComingRequestWrapper(); 
		requestWrapper2.docType = 'Binder';
		requestWrapper2.quoteId = newQuote.Azure_ID__c;
		requestWrapper2.docId = tranSitD.Id;
        requestWrapper2.Name = requestWrapper2.docType  + '.pdf';

		String q = '"quoteId":"'+ newQuote.Azure_ID__c + '"'; 
		String d = '"docId":"' + tranSitD.Id + '"'; 
		String p = '"docType":"Binder"';
        String n = '"Name":"QuoteProposal.pdf"';

		String reqString = '[{' + q + ',' + d + ',' + p + ', ' + n + '}]';
        

     // Set up a test request
		RestRequest request = new RestRequest();
		request.requestUri = '/services/apexrest/Invsk_UpdateDocumentId';
		request.httpMethod = 'POST';
		request.requestBody = Blob.valueOf(reqString);
		RestContext.request = request;

    	RestResponse response  = new RestResponse();
		RestContext.response = response; 

		
        REST_Invsk_UpdateDocumentId.doPost();
        Test.stopTest();
		System.assertEquals(200, RestContext.response.statusCode);     
    }


 	@isTest
    static void testDoGetEmptyQuoteId() {

        // Set up a test request
		RestRequest request = new RestRequest();
		request.requestUri = '/services/apexrest/REST_Invsk_UpdateDocumentId';
		request.httpMethod = 'GET';
		request.addParameter('quoteId', '');

		RestResponse response  = new RestResponse();

		RestContext.request = request;
		RestContext.response = response; 

		Test.startTest();
        REST_Invsk_UpdateDocumentId.doGet();
        Test.stopTest();
		System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testDoGetEmptyDoc() {
        
  		Quote newQuote = [Select Id,Azure_Id__c From Quote limit 1];

        REST_Invsk_UpdateDocumentId.ResponseBodyWrapper responseBodyWrapper = new REST_Invsk_UpdateDocumentId.ResponseBodyWrapper(); 
        responseBodyWrapper.docRevisionId = newQuote.Azure_ID__c;
        responseBodyWrapper.docType = '';
        responseBodyWrapper.docName = '';

        // Set up a test request
		RestRequest request = new RestRequest();
		request.requestUri = '/services/apexrest/REST_Invsk_UpdateDocumentId';
		request.httpMethod = 'GET';
		request.addParameter('quoteId', newQuote.Azure_ID__c);

		RestResponse response  = new RestResponse();

		RestContext.request = request;
		RestContext.response = response; 

		Test.startTest();
        REST_Invsk_UpdateDocumentId.doGet();
        Test.stopTest();
		System.assertEquals(200, RestContext.response.statusCode);
    }

     @isTest
    static void testDoGet() {
        
  		Quote newQuote = [Select Id,Azure_Id__c, Policy__c From Quote limit 1];

  		// Create new Transit Detail
		Document_Revision__c tranSitD = new Document_Revision__c();
		tranSitD.Quote_Id__c =  newQuote.Id;
		tranSitD.Policy__c = newQuote.Policy__c;
		insert tranSitD;

        REST_Invsk_UpdateDocumentId.ResponseBodyWrapper responseBodyWrapper = new REST_Invsk_UpdateDocumentId.ResponseBodyWrapper(); 
        responseBodyWrapper.docRevisionId = newQuote.Azure_ID__c;
        responseBodyWrapper.docType = '';
        responseBodyWrapper.docName = '';

        // Set up a test request
		RestRequest request = new RestRequest();
		request.requestUri = '/services/apexrest/Invsk_UpdateDocumentId';
		request.httpMethod = 'GET';
		request.addParameter('quoteId', newQuote.Azure_ID__c);

		RestResponse response  = new RestResponse();

		RestContext.request = request;
		RestContext.response = response; 

		Test.startTest();
        REST_Invsk_UpdateDocumentId.doGet();
        Test.stopTest();
		System.assertEquals(200, RestContext.response.statusCode);    
    }

    @isTest
    static void TestValidRequest1(){
    	REST_Invsk_UpdateDocumentId.ComingRequestWrapper commingRequest = new REST_Invsk_UpdateDocumentId.ComingRequestWrapper();
    	commingRequest.quoteId = '';
        REST_Invsk_UpdateDocumentId.OutComingResponse outComingResponse = new REST_Invsk_UpdateDocumentId.OutComingResponse();
        RestRequest req = new RestRequest();
    
    	REST_Invsk_UpdateDocumentId.validRequest(commingRequest, outComingResponse, req, 0);
    }

    @isTest
    static void TestValidRequest2(){
    	REST_Invsk_UpdateDocumentId.ComingRequestWrapper commingRequest = new REST_Invsk_UpdateDocumentId.ComingRequestWrapper();
        commingRequest.quoteId = 'string';
        commingRequest.docId = 'string';
        commingRequest.docType = '';
        
        REST_Invsk_UpdateDocumentId.OutComingResponse outComingResponse = new REST_Invsk_UpdateDocumentId.OutComingResponse();
        RestRequest req = new RestRequest();
    
    	REST_Invsk_UpdateDocumentId.validRequest(commingRequest, outComingResponse, req, 1);
    }

    @isTest
    static void TestValidRequest3(){
    	REST_Invsk_UpdateDocumentId.ComingRequestWrapper commingRequest = new REST_Invsk_UpdateDocumentId.ComingRequestWrapper();
        commingRequest.quoteId = 'string';
        commingRequest.docType = 'string';
        commingRequest.docId = '';

        REST_Invsk_UpdateDocumentId.OutComingResponse outComingResponse = new REST_Invsk_UpdateDocumentId.OutComingResponse();
        RestRequest req = new RestRequest();
    
    	REST_Invsk_UpdateDocumentId.validRequest(commingRequest, outComingResponse, req, 2);
    }

    
}