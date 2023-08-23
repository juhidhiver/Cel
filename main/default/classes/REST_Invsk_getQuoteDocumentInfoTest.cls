/**************************************************************************************************
 * Class Name: REST_Invsk_getQuoteDocumentInfoTest
 * Author: Giang Phan
 * Date: 04-Nov-2019
 * Description: REST_Invsk_getQuoteDocumentInfoTest Test
 **************************************************************************************************/
@isTest
public with sharing class REST_Invsk_getQuoteDocumentInfoTest {
    @TestSetup
    private static void setupData(){
        // Create Account
        Account acc = new Account(
            Name = 'Test acc',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId(),
            BillingStreet = '25 Taylor Street',
            BillingCity = 'San Francisco',
            BillingState = 'California',
            BillingPostalCode = '94102',
            BillingCountry = 'United States'
            //IsMailingSameWithBillingAddress__c = true,
            //Date_Started__c = Date.today().addYears(-2)
        );
        insert acc;

        // Create Product2
        Product2 prd = new Product2(
            Name = 'Test product',
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Celerity').getRecordTypeId(),
            Innovisk_Entity_ID__c = 'Celerity',
            Package_Indicator__c = true,
            IsActive = true,
            Expiration_Date__c = Date.today().addDays(200),
            Effective_Date__c = Date.today().addDays(-1),
            Writing_Company__c = acc.Id
        );
        insert prd;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test opp',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId(),
            AccountId = acc.Id,
            //Coverage_Product_Options__c = 'D&O',
            //Pricebook2Id = Test.getStandardPricebookId(),
            Product__c = prd.Id,
            //Received_Date__c = Date.today(),
            CloseDate = Date.today().addDays(30),
            //Effective_Date__c = Date.today().addDays(1),
            //Type = 'New Business',
            //LeadSource = 'Email',
            StageName = 'New'
        );
        insert opp;

        // Create Contact
        Contact con = new Contact(
            Lastname = 'Test broker',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId(),
            AccountId = acc.Id
        );
        insert con;

        // Create Broker_Account__c
        Broker_Account__c brokerAccount = new Broker_Account__c(
            Broker_Contact__c = con.Id,
            Opportunity__c = opp.Id,
            IsPrimaryBroker__c = true,
            Relationship_Type__c = 'Broker'
        );
        insert brokerAccount;

        // After insert broker, opp stage will change to 'Prospect'
        // Update opp stage again to 'Qualified' to create quote
        opp.StageName = 'Qualified';
        update opp;

        // Create pricebook entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(), 
            Product2Id = prd.Id, 
            UnitPrice = 10000, 
            IsActive = true
        );
        insert pbe;

        // Create Quote
        Quote quote = new Quote(
            OpportunityId = opp.Id,
            Name = 'Test quote',
            Coverage_Product_Options__c = 'D&O',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert quote;

        // Create QuoteLineItem
        // QuoteLineItem qli = new QuoteLineItem(
        //     QuoteId = quote.Id,
        //     Product2Id = prd.Id,
        //     Quantity = 10,
        //     UnitPrice = 10
        // );
        // insert qli;

        // Create Rating_Modifiers__c
        Rating_Modifiers__c rm = new Rating_Modifiers__c(
            Name = 'Test Rating Modifiers',
            Sort_Sub_Section__c = 1,
            Sub_Section__c = 'SubsectionCmpController',
            Page_Section__c = 'Rate Modifiers',
            Product__c = 'MPL Standalone',
            Opportunity__c = opp.Id
        );
        insert rm;

        // Create Location
        Location__c newLocation = TestUtil.createNewLocation('131, 1st Avenue Test','New York', 'United States', '10093', 'New York');
        insert newLocation;

        // Create Quote Location
        Quote_Location__c newQuoteLoc = TestUtil.createQuoteLocation(quote.Id, newLocation.Id, true);
        newQuoteLoc.put('Quote__c', quote.Id);
        insert newQuoteLoc;

        // Create Coverage__c
        Coverage__c cov = TestUtil.createCoverage('Test Coverage','D&O');
        insert cov;

        // Add CoveragesLineItem__c
        CoveragesLineItem__c coverLi = new CoveragesLineItem__c(
            Coverage__c  = cov.Id,
            Quote__c = quote.Id,
            Coverage_Premium__c  = 'Text Premium',
            Min_amt__c  = 1000,
            Max_amt__c  = 5000,
            Deductible_Frequency__c  = 'Daily',
            Options_Value_Percent__c  = 5
        );
        insert coverLi;
    }

    public static testMethod void getDocumentInfoV2Test() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        List<Quote> quoteAzureId = [SELECT Azure_Id__c FROM Quote WHERE Id = :quote.Id LIMIT 1];

        Test.startTest();
        //Set up REST request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_getQuoteDocumentInfo/';
        request.httpMethod = 'GET';
        request.params.put('quoteId', quoteAzureId[0].Azure_Id__c);

        RestResponse response  = new RestResponse();

        //Assign the request to RestContext
        RestContext.request = request;
        RestContext.response = response;

        REST_Invsk_getQuoteDocumentInfo.getDocumentInfoV2();
        Test.stopTest();
        API_Log__c logs = [SELECT Id, Response_Body__c, Status_Code__c FROM API_Log__c WHERE Function_Name__c = 'REST_Invsk_getQuoteDocumentInfo.getDocumentInfoV2' LIMIT 1];
        System.debug('@@@Logs: ' + logs);
        
        System.assertEquals(200, logs.Status_Code__c);
    }

    public static testMethod void getDocumentInfoV2_WithNullQuoteId() {
        Test.startTest();
        
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        List<Quote> quoteAzureId = [SELECT Azure_Id__c FROM Quote WHERE Id = :quote.Id LIMIT 1];
        //Set up REST request
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/Invsk_getQuoteDocumentInfo/';
        request.httpMethod = 'GET';
        request.params.put('quoteId', null);

        RestResponse response  = new RestResponse();

        //Assign the request to RestContext
        RestContext.request = request;
        RestContext.response = response;

       REST_Invsk_getQuoteDocumentInfo.getDocumentInfoV2();
        Test.stopTest();
         
        API_Log__c logs = [SELECT Id, Status_Code__c, Function_Name__c FROM API_Log__c WHERE Function_Name__c = 'REST_Invsk_getQuoteDocumentInfo.getDocumentInfoV2' LIMIT 1];
        
        //API_Log__c logs = [SELECT Id, Status_Code__c, Function_Name__c FROM API_Log__c WHERE Function_Name__c = 'getRatedQuote' LIMIT 1];
        //System.debug('@@@Logs: ' + logs);

        System.assertEquals(200, logs.Status_Code__c);
    }
}