/*************************************************
* Class Name: REST_Invsk_Quote_V2Test
* Author: Sarthak Roy
* Updated: 10-Nov-2020
* Description: Test Class for REST_Invsk_Quote
*
*************************************************/
@isTest
public class REST_Invsk_Quote_V2Test {
	@testsetup static void testSetup(){
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
		insert acc;
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
		insert product; 

        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Prospect';
        insert opp;
     
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'In Progress';
        quote1.Coverage_Product_Options__c = 'D&O';
        quote1.Quote_Type__c = 'New Business';
     	quote1.Refer_Type__c = 'Underwriting Referral';
        insert quote1; 
        //Data for get Request
		
        //Create coverage
		List<Coverage__c> lCov = new List<Coverage__c>();
		Coverage__c cov = TestUtil.createCoverage('Coverage test', 'D&O');
        cov.Coverage_Product__c = 'D&O';
		lCov.add(cov);
		Coverage__c cov1 = TestUtil.createCoverage('Coverage test', 'MPL');
		lCov.add(cov1);
		insert lCov;
        
        //create limit deductables
		Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
        insert ded;

        Quote quote = TestUtil.createQuote('New Quote Test',opp.Id);
		quote.Coverage_Product_Options__c ='D&O;MPL';       
		insert quote;
        
        quote.Status = 'Rated';
        update quote;
        
         // Coverages Line Item
        CoveragesLineItem__c coverLi = new CoveragesLineItem__c();
        coverLi.Coverage__c  = cov.Id; 
        coverLi.Quote__c = quote.Id;
        coverLi.Coverage_Premium__c  = 'Text Premium'; 
        coverLi.Min_amt__c  = 1000;
        coverLi.Max_amt__c  = 5000;
        coverLi.Deductible_Frequency__c  = 'Daily';
        coverLi.Options_Value_Percent__c  = 5;
        insert coverLi;
        
    }
    @isTest
    static void postRequest(){
        Test.startTest();
        Quote quote = [Select id, Azure_Id__c from Quote where Name = 'New quote 1'];
        Opportunity opp = [Select Id, Azure_Id__c  from Opportunity Limit 1];
        
        String reqBody = '{"OpportunityId": '+'"'+opp.Azure_Id__c+'"'+',"Azure_ID__c":'+'"'+quote.Azure_Id__c+'"'+',"Parent_Quote__c": "","Quote_Type__c": "New Business"}';
        System.debug('reqBody'+reqBody);
         // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Quote_V2/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(reqBody);
        // Set up a test response
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
        
        REST_Invsk_Quote_V2.createQuote();
        
      
        System.assertEquals(200, RestContext.response.statusCode);
        Test.stopTest();
    }
    @isTest
    static void postRequestforEmptyOpp(){
        Test.startTest();
        Quote quote = [Select id, Azure_Id__c from Quote where Name = 'New quote 1'];
        Opportunity opp = [Select Id, Azure_Id__c  from Opportunity Limit 1];
        
        String reqBody = '{"OpportunityId": '+'""'+',"Azure_Id__c":'+'"'+quote.Azure_Id__c+'"'+',"Parent_Quote__c": "","Quote_Type__c": "New Business"}';
        System.debug('reqBody'+reqBody);
         // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Quote_V2/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(reqBody);
        // Set up a test response
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
        
        REST_Invsk_Quote_V2.createQuote();
      
        System.assertEquals(200, RestContext.response.statusCode);
        Test.stopTest();
    }
    /*
    @isTest
    static void postRequestforExcep(){
        Test.startTest();
        Quote quote = [Select id, Azure_Id__c from Quote where Name = 'New quote 1' LIMIT 1];
        Opportunity opp = [Select Id, Azure_Id__c  from Opportunity Limit 1];
        
        String reqBody = '{"OpportunityId": '+'"'+opp.Azure_Id__c+'"'+',"Id":'+quote.Azure_Id__c+',"Parent_Quote__c": "","Quote_Type__c": "New Business"}';
        System.debug('reqBody'+reqBody);
         // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Quote_V2/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(reqBody);
        // Set up a test response
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
        
        REST_Invsk_Quote_V2.createQuote();
        
      
        System.assertEquals(500, RestContext.response.statusCode);
        Test.stopTest();
    }
    */
     @isTest
    static void postRequestforNoOpp(){
        Test.startTest();
        Quote quote = [Select id, Azure_Id__c from Quote where Name = 'New quote 1'];
        Opportunity opp = [Select Id, Azure_Id__c  from Opportunity Limit 1];
        
        String reqBody = '{"OpportunityId": '+'"b67df444-dc91-4c88-a84a-2064808a963"'+',"Azure_Id__c":'+'"'+quote.Azure_Id__c+'"'+',"Parent_Quote__c": "","Quote_Type__c": "New Business"}';
        System.debug('reqBody'+reqBody);
         // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Quote_V2/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(reqBody);
        // Set up a test response
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
        
        REST_Invsk_Quote_V2.createQuote();
        
      
        System.assertEquals(200, RestContext.response.statusCode);
        Test.stopTest();
    }
    @isTest
    static void getMethodTest(){
        Test.startTest();
        Quote quote = [Select Id, Azure_ID__c from Quote where Name = 'New Quote Test'];
        
         // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Quote_V2/';
        request.httpMethod = 'GET';
        request.addParameter('quoteId', quote.Azure_ID__c);
        
        // Set up a test response
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
       
        REST_Invsk_Quote_V2.getQuoteDetail();          
        Test.stopTest();
        System.assertEquals(500, RestContext.response.statusCode);
    }

    @isTest
    static void getMethodTestforExcep(){
        Test.startTest();
        Quote quote = [Select Id, Azure_ID__c from Quote where Name = 'New Quote Test'];
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
         // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Quote_V2/';
        request.httpMethod = 'GET';
        request.addParameter('quoteId', quote.id);
        
        // Set up a test response
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
       
        REST_Invsk_Quote_V2.getQuoteDetail();          
        Test.stopTest();
        System.assertEquals(500, RestContext.response.statusCode);
    }


       @isTest
    static void getMethodTestforBlankQouteId(){
        Test.startTest();
        Quote quote = [Select Id, Azure_ID__c from Quote where Name = 'New Quote Test'];
       
        
         // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Quote_V2/';
        request.httpMethod = 'GET';
        request.addParameter('quoteId', '');
        
        // Set up a test response
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
       
        REST_Invsk_Quote_V2.getQuoteDetail();   
       
        Test.stopTest();
        System.assertEquals(500, RestContext.response.statusCode);
    }
}