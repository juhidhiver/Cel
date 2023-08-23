/**************************************************************************************************
* Class Name: REST_Invsk_CoveragesQuote_V2Test
* Author: Ashik Zahir
* Created date: 04-Feb-2021
* Description: Broker Agency Account Test
**************************************************************************************************/
@isTest
public with sharing class REST_Invsk_BrokerAgencyAccountTest {
    
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
        
        Account accBroker = TestUtil.createBusinessAccount('Account_Broker_Test_01', 'Broker_Account', '625, South Mill Road', 'Anycity', 'New York', '67074', 'United States');
		accBroker.RecordTypeId = recordTypeBrokerAgency;
		
        insert accBroker;

		Contact contactBroker = TestUtil.createContact(accBroker.Id, 'Broker_Contact', 'New broker contact');
		insert  contactBroker;  
        
      TriggerSettings__c setting = new TriggerSettings__c();
           setting.BypassQuoteTrigger__c = true;
           insert setting;
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'In Progress';
        quote1.Coverage_Product_Options__c = 'D&O';
        quote1.Quote_Type__c = 'New Business';
     	quote1.Refer_Type__c = 'Underwriting Referral';
        quote1.Azure_ID__c = 'Testing-Quote';
        insert quote1; 
       
        //Data for get Request
        Quote quote2 = TestUtil.createQuote('New quote 2', opp.Id);
        quote2.Status = 'In Progress';
        quote2.Coverage_Product_Options__c = 'D&O';
        quote2.Quote_Type__c = 'New Business';
     	quote2.Refer_Type__c = 'Underwriting Referral';
        quote2.Azure_ID__c = 'Test2-Quote';
        quote2.Parent_Quote__c= quote1.Id;
        insert quote2;

		Coverage__c cov1 = TestUtil.createCoverage('Coverage test', 'MPL');
		insert cov1;

        Quote quote = TestUtil.createQuote('New Quote Test',opp.Id);
		quote.Coverage_Product_Options__c ='D&O;MPL';
        quote.Parent_Quote__c = quote1.Id;
		insert quote;
        
        quote.Status = 'Rated';
        update quote;
        
        //create limit deductables
		Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov1.Id);
        insert ded;
        
         // Coverages Line Item
        CoveragesLineItem__c coverLi = new CoveragesLineItem__c();
        coverLi.Coverage__c  = cov1.Id; 
        coverLi.Quote__c = quote.Id;
        coverLi.Limits_Deductibles__c = ded.Id;
        coverLi.Coverage_Premium__c  = 'Text Premium'; 
        coverLi.Min_amt__c  = 1000;
        coverLi.Max_amt__c  = 5000;
        coverLi.Deductible_Frequency__c  = 'Daily';
        coverLi.Options_Value_Percent__c  = 5;
        insert coverLi;
      
        ded.LmtDedCode__c = coverLi.Limits_Deductibles__c;
        update ded;
        
        cov1.Coverage_Code__c = coverLi.Coverage__c;
        update cov1;
     }
    
    
    @isTest
    public static void testGetBrokerAgencyAccount() {
        
		RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_BrokerAgencyAccount';
        request.httpMethod = 'GET';
        request.params.put('FEIN', '2000');
        
        RestResponse response = new RestResponse();
        
        RestContext.request = request;
        RestContext.response = response;

		Test.startTest();
        REST_Invsk_BrokerAgencyAccount.getBrokerAgencyAccount();
        Test.stopTest();
        
        System.assertEquals(200, RestContext.response.statusCode);
        
       
	}
    
    @isTest
    public static void testGetBrokerAgencyAccountByName() {
		RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_BrokerAgencyAccount';
        request.httpMethod = 'GET';
        request.params.put('AgencyName', 'Account_Broker_Test_01');
        
        RestResponse response = new RestResponse();
        
        RestContext.request = request;
        RestContext.response = response;

		Test.startTest();
        REST_Invsk_BrokerAgencyAccount.getBrokerAgencyAccount();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
        
       
	}
    
    @isTest
    public static void testGetBrokerAgencyAccountByNameState() {
		RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_BrokerAgencyAccount/';
        request.httpMethod = 'GET';
        request.params.put('AgencyName', 'Account_Broker_Test_01');
        request.params.put('City','Leon');
        request.params.put('State','Kansas');
        RestResponse response = new RestResponse();
        
        RestContext.request = request;
        RestContext.response = response;

		Test.startTest();
        REST_Invsk_BrokerAgencyAccount.getBrokerAgencyAccount();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
        
       
	}
    
    @isTest
    public static void testGetBrokerAgencyAccountFEINNone() {
		RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_BrokerAgencyAccount';
        request.httpMethod = 'GET';
        request.params.put('FEIN', '');
        
        RestResponse response = new RestResponse();
        
        RestContext.request = request;
        RestContext.response = response;

		Test.startTest();
        REST_Invsk_BrokerAgencyAccount.getBrokerAgencyAccount();
        Test.stopTest();
        
        System.assertEquals(200, RestContext.response.statusCode);
	}
    
    @isTest
	static void testBrokerAgencyAccountException() {
		REST_Invsk_BrokerAgencyAccount.AccountRequest accountReq = new REST_Invsk_BrokerAgencyAccount.AccountRequest();
		accountReq.ChannelID = '';		

		RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_BrokerAgencyAccount';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(accountReq));

        RestResponse response = new RestResponse();
        
        RestContext.request = request;
        RestContext.response = response;

		Test.startTest();
        REST_Invsk_BrokerAgencyAccount.createBrokerAgencyAccount();
        Test.stopTest();
        
        System.assertEquals(200, RestContext.response.statusCode);
	}
    
     @isTest
    static void testCreateBrokerAgencyAccount() {

		Account act = [SELECT Id,Azure_Id__c FROM Account WHERE Name = :'Account_Broker_Test_01' limit 1];
		System.debug('==act==' + act);

		REST_Invsk_BrokerAgencyAccount.AddressInfo billingAddress = new REST_Invsk_BrokerAgencyAccount.AddressInfo();
		billingAddress.addressLine1 = 'Billing Street Test 11';
		billingAddress.city = 'HCM';
		billingAddress.state = 'WA';
		billingAddress.postalCode = '70001';
		billingAddress.country = 'US'; 
        
        List<String> doingBusisness = new List<String>();
        doingBusisness.add('test1');
        doingBusisness.add('test2');
        doingBusisness.add('test3');
        
		REST_Invsk_BrokerAgencyAccount.AccountRequest accountReq = new REST_Invsk_BrokerAgencyAccount.AccountRequest();
		accountReq.AgencyName = 'Broker Test 11';
		accountReq.BillingAddress = billingAddress;
		accountReq.PhoneNo = '1-215-640-1000';
		accountReq.ChannelID = act.Azure_Id__c;
		accountReq.FEIN = 2004;
		accountReq.SanctionsDate = Date.newInstance(2018,01,01);
		accountReq.SanctionsStatus = 'sample';
		accountReq.AppointedFlag = true;
        accountReq.DoingBusinessAs = doingBusisness;

		RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_BrokerAgencyAccount';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json'); 
        request.requestBody = Blob.valueOf(JSON.serialize(accountReq));
        
        RestResponse response = new RestResponse();
        
        RestContext.request = request;
        RestContext.response = response;
        
		Test.startTest();
        REST_Invsk_BrokerAgencyAccount.createBrokerAgencyAccount();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
        
	}

}