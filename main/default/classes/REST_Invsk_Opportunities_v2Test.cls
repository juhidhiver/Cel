/**************************************************************************************************
* Class Name: REST_Invsk_Opportunities_v2Test
* Author: Sarthak Roy
* Created date: 12-Nov-2020
* Description: Sync from MW to SF
**************************************************************************************************/
@isTest
public class REST_Invsk_Opportunities_v2Test {
	@testsetup static void testSetup(){
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
		Account acc  =TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster',
												'California','90000', 'United States');
        acc.Azure_ID__c = '8042ac98-ae5a-4692-9880-58d92d0eb9d9';
		insert acc;
    
        Product2 product = TestUtil.createProduct('D&O Standalone');
		insert product; 

        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today()+365;
        opp.StageName = 'New';
        opp.Azure_ID__c = 'f70e4c82-3378-41ce-870b-57f4df415874';
        insert opp;
        
        //Account Product for AccountID
        Account_Product__c accProd1 = new Account_Product__c();
        accProd1.Account_Id__c = acc.Id;
        accProd1.Product_Id__c = product.id;
        insert accProd1;
        
        //Channel Account
		Account chanAcc  =TestUtil.createAccount('Test Channel Account', recordTypeId, '01 Tran Duy Hung','Westminster',
												'California','90000', 'United States');
        chanAcc.Azure_ID__c = '407a8180-7cf0-4c74-99d0-4c194723916e';
		insert chanAcc;
        
		Account_Product__c accProd2 = new Account_Product__c();
        accProd2.Account_Id__c = chanAcc.Id;
        accProd2.Product_Id__c = product.id;
        insert accProd2;

        Id recordTypeBrokerAgency = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        
        Account accBroker = TestUtil.createBusinessAccount('Broker Account Test', 'Broker_Account', '625, South Mill Road', 'Anycity', 'New York', '67074', 'United States');
		accBroker.RecordTypeId = recordTypeBrokerAgency;
		
        insert accBroker;

		Contact contactBroker = TestUtil.createContact(accBroker.Id, 'Broker_Contact', 'New broker contact');
		insert  contactBroker;       
        
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
    static void postMethodTest(){
        Test.startTest();
        REST_Invsk_Opportunities_v2.IncomingRequest incomingRequest = new REST_Invsk_Opportunities_v2.IncomingRequest();
        incomingRequest.brokerKey = [Select Id,Name,Azure_Id__c from Contact Limit 1].Azure_Id__c;
        incomingRequest.channelKey = [Select Id, Name,Azure_Id__c from Account where Name = 'Test Channel Account'].Azure_Id__c;
        incomingRequest.accountId = [Select Id, Name,Azure_Id__c from Account where Name = 'Test account 1'].Azure_Id__c;
        incomingRequest.productId = [Select Id,Azure_Id__c from Product2 Limit 1].Azure_Id__c;
        incomingRequest.opportunityId =[Select Id, Name,Azure_Id__c from Opportunity Limit 1].Azure_Id__c;
        
        System.debug('Result'+JSON.serialize(incomingRequest));
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Opportunities_v2/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(incomingRequest));
        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
        
        REST_Invsk_Opportunities_v2.doPost();
        
      
        System.assertEquals(200, RestContext.response.statusCode);
        Test.stopTest();
    }
    @isTest
    static void postMethodTestOppIdBlank(){
        Test.startTest();
        REST_Invsk_Opportunities_v2.IncomingRequest incomingRequest = new REST_Invsk_Opportunities_v2.IncomingRequest();
        incomingRequest.brokerKey = [Select Id,Name,Azure_Id__c from Contact Limit 1].Azure_Id__c;
        incomingRequest.channelKey = [Select Id, Name,Azure_Id__c from Account where Name = 'Test Channel Account'].Azure_Id__c;
        incomingRequest.accountId = [Select Id, Name,Azure_Id__c from Account where Name = 'Test account 1'].Azure_Id__c;
        incomingRequest.productId = [Select Id,Azure_Id__c from Product2 Limit 1].Azure_Id__c;
        incomingRequest.opportunityId ='';
        
        System.debug('Result'+JSON.serialize(incomingRequest));
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Opportunities_v2/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(incomingRequest));
        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
        
        REST_Invsk_Opportunities_v2.doPost();
        
      
        System.assertEquals(400, RestContext.response.statusCode);
        Test.stopTest();
    }
    @isTest
    static void postMethodTestProdIdBlank(){
        Test.startTest();
        REST_Invsk_Opportunities_v2.IncomingRequest incomingRequest = new REST_Invsk_Opportunities_v2.IncomingRequest();
        incomingRequest.brokerKey = [Select Id,Name,Azure_Id__c from Contact Limit 1].Azure_Id__c;
        incomingRequest.channelKey = [Select Id, Name,Azure_Id__c from Account where Name = 'Test Channel Account'].Azure_Id__c;
        incomingRequest.accountId = [Select Id, Name,Azure_Id__c from Account where Name = 'Test account 1'].Azure_Id__c;
        incomingRequest.productId = '';
        incomingRequest.opportunityId =[Select Id, Name,Azure_Id__c from Opportunity Limit 1].Azure_Id__c;
        
        System.debug('Result'+JSON.serialize(incomingRequest));
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Opportunities_v2/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(incomingRequest));
        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
        
        REST_Invsk_Opportunities_v2.doPost();
        
      
        System.assertEquals(400, RestContext.response.statusCode);
        Test.stopTest();
    }
    @isTest
    static void postMethodTest2(){
        Test.startTest();
        REST_Invsk_Opportunities_v2.IncomingRequest incomingRequest = new REST_Invsk_Opportunities_v2.IncomingRequest();
        incomingRequest.brokerKey = [Select Id,Name,Azure_Id__c from Contact Limit 1].Azure_Id__c;
        incomingRequest.channelKey = [Select Id, Name,Azure_Id__c from Account where Name = 'Test Channel Account'].Azure_Id__c;
        incomingRequest.accountId = [Select Id, Name,Azure_Id__c from Account where Name = 'Test account 1'].Azure_Id__c;
        incomingRequest.productId = [Select Id,Azure_Id__c from Product2 Limit 1].Azure_Id__c;
        incomingRequest.opportunityId ='11f58362-9e18-4b2f-ab96-628a669fff94';
        
        System.debug('Result'+JSON.serialize(incomingRequest));
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Opportunities_v2/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(incomingRequest));
        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
        
        REST_Invsk_Opportunities_v2.doPost();
        
      
        System.assertEquals(200, RestContext.response.statusCode);
        Test.stopTest();
    }
}