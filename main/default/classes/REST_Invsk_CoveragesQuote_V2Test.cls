/**************************************************************************************************
* Class Name: REST_Invsk_CoveragesQuote_V2Test
* Author: Ashik Zahir
* Created date: 03 Feb-2021
* Description: Coverage Quote Test Class
**************************************************************************************************/
@isTest
public class REST_Invsk_CoveragesQuote_V2Test {
    
    @testsetup static void testSetup(){
        Test.startTest();
        GlobalStaticVar.byPassAccountProductTrigger = true;
       	TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        update setting;
        
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
		
        Account acc  = TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster',
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
        
        //Setip Account Commision Table
	    Account_Commission_Template__c ac = new Account_Commission_Template__c();
        ac.Wholesaler__c = 'New_J_Account_123';
        ac.Cyber_Default__c = 20;
        insert ac;
               
         //Account Product for AccountID
        Account_Product__c accProd1 = new Account_Product__c();
        accProd1.Account_Id__c = acc.Id;
        accProd1.Product_Id__c = product.id;
        insert accProd1; 
        
        
       /* Product2 product2 = TestUtil.createProduct('Cyber Standalone');
		insert product2; 

        Account_Product__c accProd3 = new Account_Product__c();
        accProd3.Account_Id__c = acc.Id;
        accProd3.Product_Id__c = product2.id;
        accProd3.Commission_percentage__c = ac.Cyber_Default__c;
        insert accProd3; */
        
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
        Coverage__c cov2 = TestUtil.createCoverage('Coverage test2', 'MPL');
		insert cov2;

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
        coverLi.isSelected__c = true;
        insert coverLi;
        
        CoveragesLineItem__c coverLi2 = new CoveragesLineItem__c();
        coverLi2.Coverage__c  = cov2.Id; 
        coverLi2.Quote__c = quote.Id;
        //coverLi.Limits_Deductibles__c = NULL;
        coverLi2.Coverage_Premium__c  = 'Text Premium'; 
        coverLi2.Min_amt__c  = 1000;
        coverLi2.Max_amt__c  = 5000;
        coverLi2.Deductible_Frequency__c  = 'Daily';
        coverLi2.Options_Value_Percent__c  = 5;
        coverLi2.isSelected__c = true;
        insert coverLi2;
      
        ded.LmtDedCode__c = coverLi.Limits_Deductibles__c;
        update ded;
        
        cov1.Coverage_Code__c = coverLi.Coverage__c;
        update cov1;
        
        cov2.Coverage_Code__c = coverLi2.Coverage__c;
        update cov2;
        
        
         
        /*Subjectivity__c subj = new Subjectivity__c();
        subj.Subjectivity__c = 'Testing';
        subJ.Subjectivity_Status__c = 'Open';
        subJ.Subjectivity_Type__c = 'MPL';
        subJ.Quote__c = quote1.Id;
        insert subJ;*/
        Test.stopTest();
    }
    
    @isTest
    public static void testgetQuotesFromId() {
        Test.startTest();
        List<Quote> quoteList = REST_Invsk_CoveragesQuote_V2.getQuotesFromId('Testing-Quote'); 
        Test.stopTest();
        System.assertEquals(true, quoteList != null);
    }
    
    @isTest
    public static void testgetQuoteCLIs() {
        Test.startTest();
        List<CoveragesLineItem__c> CLIList = REST_Invsk_CoveragesQuote_V2.getQuoteCLIs('Testing-Quote'); 
        Test.stopTest();
        System.assertEquals(true, CLIList != null);
    }
    
    @isTest
    static void postMethodTest1(){
        Test.startTest();
        REST_Invsk_CoveragesQuote_V2.IncomingRequest incomingRequest = new REST_Invsk_CoveragesQuote_V2.IncomingRequest();
        
        //Quote
        Quote quote = [SELECT Id, Parent_Quote__c FROM Quote WHERE Azure_Id__c='Test2-Quote' LIMIT 1];
        system.debug('parentQuote--'+quote.Parent_Quote__c);
        List<Quote> quoteAzureId = [SELECT Azure_Id__c FROM Quote WHERE Id = :quote.Id LIMIT 1];
        incomingRequest.quote = quote;
        
        //UWReason
        List<REST_Invsk_CoveragesQuote_V2.UWReason> uwReason = new List<REST_Invsk_CoveragesQuote_V2.UWReason>();
        REST_Invsk_CoveragesQuote_V2.UWReason reason = new REST_Invsk_CoveragesQuote_V2.UWReason();
        reason.OverallUWCodes = '';
        reason.UWReason = '';
        uwReason.add(reason);
        incomingRequest.reasons= uwReason;
        
        //CLI
        List<CoveragesLineItem__c> coverageLineItem = [ SELECT Quote__c,Coverage__c,Limits_Deductibles__c,Coverage_Premium__c,
                                                       Min_amt__c,Max_amt__c,Deductible_Frequency__c,Options_Value_Percent__c,isSelected__c
                                                       FROM CoveragesLineItem__c limit 2];
        incomingRequest.coverageLineItem = coverageLineItem;
        

        system.debug('incomingRequest--'+incomingRequest);

        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_CoveragesQuote_v2/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(incomingRequest));
      	
        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;

        REST_Invsk_CoveragesQuote_V2.doPost();
        System.assert(incomingRequest != null);
        Test.stopTest();
    }
        
 
    @isTest
    static void postMethodTest2(){
        Test.startTest();
        
        REST_Invsk_CoveragesQuote_V2.IncomingRequest incomingRequest = new REST_Invsk_CoveragesQuote_V2.IncomingRequest();
        
        //Quote
        Quote quote = [SELECT Id, Parent_Quote__c,Azure_Id__c FROM Quote WHERE Azure_Id__c='Testing-Quote' LIMIT 1];
        delete quote;
        incomingRequest.quote = quote;
        
        //UWReason
        List<REST_Invsk_CoveragesQuote_V2.UWReason> uwReason = new List<REST_Invsk_CoveragesQuote_V2.UWReason>();
        REST_Invsk_CoveragesQuote_V2.UWReason reason = new REST_Invsk_CoveragesQuote_V2.UWReason();
        reason.OverallUWCodes = 'Test';
        reason.UWReason = 'Test';
        uwReason.add(reason);
        incomingRequest.reasons= uwReason;
        
        //CLI
        List<CoveragesLineItem__c> coverageLineItem = [ SELECT Quote__c,Coverage__c,Limits_Deductibles__c,Coverage_Premium__c,
                                                       Min_amt__c,Max_amt__c,Deductible_Frequency__c,Options_Value_Percent__c
                                                       FROM CoveragesLineItem__c];
        incomingRequest.coverageLineItem = coverageLineItem;

        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_CoveragesQuote_v2/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(incomingRequest));
      	
        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;

        REST_Invsk_CoveragesQuote_V2.doPost();
        System.assert(incomingRequest != null);
        Test.stopTest();
    }
        
    @isTest
    static void postMethodTest4(){
        Test.startTest();
        
        REST_Invsk_CoveragesQuote_V2.IncomingRequest incomingRequest = new REST_Invsk_CoveragesQuote_V2.IncomingRequest();
        
        //Quote
        Quote quote = [SELECT Id, Parent_Quote__c FROM Quote WHERE Azure_Id__c='Test2-Quote' LIMIT 1];
        system.debug('parentQuote--'+quote.Parent_Quote__c);
        incomingRequest.quote = quote;
        
        //UWReason
        List<REST_Invsk_CoveragesQuote_V2.UWReason> uwReason = new List<REST_Invsk_CoveragesQuote_V2.UWReason>();
        REST_Invsk_CoveragesQuote_V2.UWReason reason = new REST_Invsk_CoveragesQuote_V2.UWReason();
        reason.OverallUWCodes = '';
        reason.UWReason = '';
        uwReason.add(reason);
        incomingRequest.reasons= uwReason;
        
         //Create coverage
		List<Coverage__c> lCov = new List<Coverage__c>();
		Coverage__c cov = TestUtil.createCoverage('Coverage test', 'D&O');
        cov.Coverage_Product__c = 'D&O';
		lCov.add(cov);
		Coverage__c cov1 = TestUtil.createCoverage('Coverage test', 'MPL');
		lCov.add(cov1);
		insert lCov;
        
        CoveragesLineItem__c coverLi = new CoveragesLineItem__c();
        coverLi.Coverage__c  = cov.Id; 
        coverLi.Quote__c = quote.Id;
        coverLi.Coverage_Premium__c  = 'Text Premium'; 
        coverLi.Min_amt__c  = 1000;
        coverLi.Max_amt__c  = 5000;
        coverLi.Deductible_Frequency__c  = 'Daily';
        coverLi.Options_Value_Percent__c  = 5;
        insert coverLi;
        
        cov.Coverage_Code__c = coverLi.Coverage__c;
        update cov;
        
        Rest_Invsk_CoveragesQuote_V2.generateCoverageLineItems(lCov,quote);
        test.stopTest();
    }
     @isTest
    static void postMethodTest5(){
        Test.startTest();
        
        REST_Invsk_CoveragesQuote_V2.IncomingRequest incomingRequest = new REST_Invsk_CoveragesQuote_V2.IncomingRequest();
        
        //Quote
        Quote quote = [SELECT Id, Parent_Quote__c,Quote_Type__c,Effective_Date__c,Endorsement_Effective_Date__c FROM Quote WHERE Azure_Id__c='Test2-Quote' LIMIT 1];
        incomingRequest.quote = quote;
        quote.Quote_Type__c='New Business';
        quote.Effective_Date__c=Date.today()+15;
        update quote;
        quote.Quote_Type__c='Amendment';
        quote.Endorsement_Effective_Date__c=Date.today()+20;
        update quote;
        
        Coverage_Limits_Deductibles__c covlid =[select id from Coverage_Limits_Deductibles__c limit 1];
        
        //UWReason
        List<REST_Invsk_CoveragesQuote_V2.UWReason> uwReason = new List<REST_Invsk_CoveragesQuote_V2.UWReason>();
        REST_Invsk_CoveragesQuote_V2.UWReason reason = new REST_Invsk_CoveragesQuote_V2.UWReason();
        reason.OverallUWCodes = '';
        reason.UWReason = '';
        uwReason.add(reason);
        incomingRequest.reasons= uwReason;
        
         //Create coverage
		
		Coverage__c cov = TestUtil.createCoverage('Coverage test', 'D&O');
        cov.Coverage_Product__c = 'D&O';
		insert cov;
	
        
        CoveragesLineItem__c coverLi = new CoveragesLineItem__c();
        coverLi.Coverage__c  = cov.Id; 
        coverLi.Quote__c = quote.Id;
        coverLi.Coverage_Premium__c  = 'Text Premium'; 
        coverLi.Min_amt__c  = 1000;
        coverLi.Max_amt__c  = 5000;
        coverLi.Deductible_Frequency__c  = 'Daily';
        coverLi.Options_Value_Percent__c  = 5;
        insert coverLi;
        
        cov.Coverage_Code__c = coverLi.Coverage__c;
        update cov;
        
        Rest_Invsk_CoveragesQuote_V2.GenerateCLIByCoverage(cov,quote);
        Test.stopTest();
    }
}