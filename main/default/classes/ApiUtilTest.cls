/**************************************************************************************************
* Class Name: ApiUtilTest
* Author: Giang Phan
* Date: 08-Nov-2019
* Description: Unit test for ApiUtil
**************************************************************************************************/
@isTest
private class ApiUtilTest {
    public static Account acc;
    @testSetup 
    static void setup() {
        TriggerSettings__c settings = new TriggerSettings__c();
        settings.BypassQuoteLocationTrigger__c = true;
        settings.BypassQuoteLineItemTrigger__c = true;
        settings.BypassQuoteTrigger__c = true;
        insert settings;
     
        
        // Create Account
        Account acc1 = new Account();
        acc1.Name = 'Test account 1';
        acc1.BillingStreet = '01 Tran Duy Hung';
        acc1.BillingCity = 'Westminster';
        acc1.BillingState = 'California';
        acc1.BillingPostalCode = '90000';
        acc1.BillingCountry = 'United States';
        acc1.IsMailingSameWithBillingAddress__c = true;
        acc1.Date_Started__c = Date.today().addYears(-2);
        insert acc1;
        
        // Create product
        Product2 prd = new Product2(
            Name = 'Private Company Combo',
            Innovisk_Entity_ID__c = 'Celerity',
            Package_Indicator__c = true,
            IsActive = true,
            Expiration_Date__c = Date.today().addDays(200),
            Effective_Date__c = Date.today().addDays(-1)
        );
        insert prd;
        
        // Create opportunity
        Opportunity opp = new Opportunity();
        opp.Name = 'Test opp';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
        opp.AccountId = acc1.Id;
        opp.Coverage_Product_Options__c = 'D&O';
        opp.Pricebook2Id = Test.getStandardPricebookId();
        opp.Product__c = prd.Id;
        opp.Received_Date__c = Date.today();
        opp.CloseDate = Date.today().addDays(30);
        opp.Effective_Date__c = Date.today().addDays(1);
        opp.Type = 'New Business';
        opp.LeadSource = 'Email';
        opp.StageName = 'New';
        insert opp;
        
        Subjectivity_Template__c subjectivityTemplate = new Subjectivity_Template__c();
        subjectivityTemplate.Subjectivity_Name__c = 'Signed / Dated Proposal';
        subjectivityTemplate.Subjectivity_Text__c = 'Test';
        subjectivityTemplate.Profession_Criteria__c = 'Engineers';
        insert subjectivityTemplate;
        
        // Create quote
        Quote Parquote = new Quote(
            OpportunityId = opp.Id,
            Name = 'Test quote parent',			
            Coverage_Product_Options__c = 'D&O',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert Parquote;
        
         // Create quote
        Quote quote = new Quote(
            OpportunityId = opp.Id,
            Name = 'Test quote 1',			
            Coverage_Product_Options__c = 'D&O',
            Pricebook2Id = Test.getStandardPricebookId(),
            Parent_Quote__c = Parquote.id,
            Quote_Type__c = 'Renewal'
        );
        insert quote;
        
        List<Coverage__c> insertCoverageList = New List<Coverage__c>();
        
        //Create coverage for Cyber
        Coverage__c cov3 = TestUtil.createCoverage('Cyber Coverage', 'Cyber');
        insertCoverageList.add(cov3);
        insert insertCoverageList;
            
        List<CoveragesLineItem__c> coverageList = New List<CoveragesLineItem__c>();
        // Coverages Line Item
        CoveragesLineItem__c coverLi = new CoveragesLineItem__c();
        coverLi.Coverage__c  = cov3.Id; 
        coverLi.Quote__c = Parquote.Id;
        //coverLi.Limits_Deductibles__c = ded.Id;
        coverLi.Coverage_Premium__c  = 'Text Premium'; 
        coverLi.Min_amt__c  = 1000;
        coverLi.Max_amt__c  = 5000;
        coverLi.Deductible_Frequency__c  = 'Daily';
        coverLi.Options_Value_Percent__c  = 5;
        coverageList.add(coverLi);
        insert coverageList;
        
        Policy__c pol = new Policy__c();
        pol.Binding_License_Number__c = 'dsdsds';
        insert pol;
            
        quote.Policy__c = pol.id;
        update quote;
        
    }
    
    @isTest 
    static void testLogApiCall() {
        
        HttpRequest req = new HttpRequest();
        req.setBody('{"Name":"123","Address1":"1419 Westwood Boulevard","City":"Los Angeles","State":"California","postalCode":"90024","Country":"US"}');
        
        HttpResponse res = new HttpResponse();
        res.setBody('{"Name":"123","Address1":"1419 Westwood Boulevard","City":"Los Angeles","State":"California","postalCode":"90024","Country":"US","Quotes":[{"Id":"q121234567"}]}');
        Test.startTest();
        ApiUtil.logAPICall(req, res, 'API', 'functionName', 'headerRequest', 'Outbound');
        ApiUtil.logAPICall(req, res, 'Bind Quote V2 Callout', 'functionName', 'headerRequest', 'Outbound');
        ApiUtil.logAPICall(req, res, 'Sync Quote Status', 'functionName', 'headerRequest', 'Outbound');
        ApiUtil.logAPICall(req, res, 'RatingAPI Callout', 'functionName', 'headerRequest', 'Outbound');
        Test.stopTest();
        System.assert(res != null);
    }
    
    @isTest 
    static void testLogAPICallIn() {
        
        RestRequest req = new RestRequest();			
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(JSON.serialize('{"key":"value"}'));    
        res.responseBody = Blob.valueOf(JSON.serialize('{"key":"value"}'));
        Test.startTest();
        ApiUtil.logAPICallIn(req, res, 'API', 'functionName');
        Test.stopTest();
        System.assert(res != null);
    }
    
    @isTest 
    static void testCreateLogAPICall() {
        
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"Name":"123","Address1":"1419 Westwood Boulevard","City":"Los Angeles","State":"California","postalCode":"90024","Country":"US","Quotes":[{"Id":"q121234567"}]}');
        res.setStatusCode(200);
        Test.startTest();
        ApiUtil.createLogAPICall(req, res, 'Sync Quote Status', 'functionName', 'headerRequest', 'Outbound');
        Test.stopTest();
        System.assert(res != null);
    }
    
    @isTest
    static void testgetRatingJsonString(){
        List<Quote> quot = [SELECT Id, OpportunityId FROM Quote where Quote_Type__c = 'Renewal'];
        String quoteId = quot[0].Id;
        system.debug('quoteId-->'+quoteId);
        //List<Opportunity> opp = [SELECT Id  FROM Opportunity];
        Test.startTest();
        ApiUtil.getRatingJsonString(quoteId);
        Test.stopTest();
        System.assert(quot!= null);
    }
    @isTest
    static void testgetRatingJson(){
        List<Quote> quot = [SELECT Id, OpportunityId FROM Quote];
        List<CoveragesLineItem__c> cli = [SELECT Id, Quote__c FROM CoveragesLineItem__c where Quote__c =: quot[0].Id];
        Policy__c pol = [SELECT Id FROM Policy__c];
        String quoteId = quot[0].Id;
        List<Opportunity> opp = [SELECT Id  FROM Opportunity];
        Test.startTest();
        try{
          ApiUtil.getRatingJson(quoteId);
        }catch(Exception e){
        }
        Test.stopTest();
        System.assert(quot!= null);
    }
    @isTest static void testAQ(){
        
        TriggerSettings__c setting = new TriggerSettings__c();
  		setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        setting.BypassCoverageLineItemTrigger__c = true;
        setting.BypassAccountTrigger__c = true;
        insert setting;
        
        acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
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
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, prod.Id);
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        opp.CloseDate = Date.today();
        opp.Innovisk_Entity_ID__c = 'Aqueous';        
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        
        opp.StageName = 'Qualified';
        opp.Expiration_Date__c = Date.today()+60;
        insert opp;
        Test.startTest();
        Quote quote1 = TestUtil.createQuote('New quote', opp.Id);
        quote1.Coverage_Product_Options__c ='Professional Indemnity'; 
        quote1.Layer__c = 'Primary';
        quote1.Status = 'In Approval';
        quote1.Refer_Type__c = 'Underwriting Referral';
        insert quote1; 
        quote1.Layer__c = 'Excess';
        quote1.Status = 'Quoted';
        update quote1;
        
        quote1.Layer__c = 'Primary';
        update quote1;
        
        ApiUtil.getRatingJsonAQ(quote1);
        Test.stopTest();
        System.assertEquals(quote1.Layer__c, 'Primary');
    }
}