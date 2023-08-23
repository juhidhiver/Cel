/**************************************************************************************************
* Class Name: REST_Invsk_Account_v2
* Author: Sarthak Roy
* Created date: 13-Nov-2020
* Description: REST_Invsk_Account_v2 Test Class
**************************************************************************************************/
@isTest
public class REST_Invsk_Account_v2Test {
	@testsetup static void testSetup(){
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
    	Account acc = TestUtil.createAccount('Bussiness Account Test', recordTypeId, '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
		acc.IsMailingSameWithBillingAddress__c = True;
        acc.Azure_ID__c = '7c4ce4e9-a314-4b7c-ac6f-4f26ab52553c';
        insert acc;   
    }
    @isTest
    static void getMethodTest(){
        Test.startTest();
        Account acc = [Select Id, Azure_ID__c from Account Limit 1];
         // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Account_v2/';
        request.httpMethod = 'GET';
        request.addParameter('AccountId', acc.Azure_ID__c);
        
        // Set up a test response
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
       	REST_Invsk_Account_v2.doGet();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }
     @isTest
    static void getMethodTestforEmptyAzureId(){
        Test.startTest();
        Account acc = [Select Id, Azure_ID__c from Account Limit 1];
         // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Account_v2/';
        request.httpMethod = 'GET';
        request.addParameter('AccountId', '');
        
        // Set up a test response
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
       	REST_Invsk_Account_v2.doGet();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }
     @isTest
    static void getMethodTestforInvalidAccount(){
        Test.startTest();
        Account acc = [Select Id, Azure_ID__c from Account Limit 1];
         // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Account_v2/';
        request.httpMethod = 'GET';
        request.addParameter('AccountId', 'c436b066-4b0d-4788-9fb2-deec3e66d874');
        
        // Set up a test response
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
       	REST_Invsk_Account_v2.doGet();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }
    @istest
    static void doPostTest(){
        Test.startTest();
        String reqBody = '{ "Azure_ID__c": "", "Name": "test acc 3", "Description": "", "BillingLatitude": "33.6184146", "BillingLongitude": "-84.3281757", "BillingStreet": "2000 Anvil Block Road", "BillingCity": "Forest Park", "BillingState": "California", "BillingPostalCode": "30297", "BillingCountry": "United States" }';
          // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Account_v2/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(reqBody);
        // Set up a test response
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
		REST_Invsk_Account_v2.doPost();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }
}