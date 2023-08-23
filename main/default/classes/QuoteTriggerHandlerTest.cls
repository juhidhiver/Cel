/**************************************************************************************************
* Class Name: QuoteTriggerHandlerTest
* Author: Hoang Bui
* Date: 28-Aug-2019
* Description: QuoteTriggerHandlerTest Test
**************************************************************************************************/
@isTest
private class QuoteTriggerHandlerTest {
    public static Product2 product;
    public static Account acc;
    
    static {
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassQuoteTrigger__c = false;
        update setting;
        
        acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingCountry = acc.ShippingCountry;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        //acc.BillingStateCode = 'NY';
        insert acc;
        
        product = TestUtil.createProduct('D&O');
        insert product;   
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        opportunity.Coverage_Product_Options__c = 'D&O;MPL';
        opportunity.LeadSource = 'Shopping X';
        insert opportunity;
        
        //Create coverage
        List<Coverage__c> lCov = new List<Coverage__c>();
        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'D&O');
        cov.Coverage_Product__c = 'D&O';
        lCov.add(cov);
        Coverage__c cov1 = TestUtil.createCoverage('Coverage test', 'MPL');
        cov1.Coverage_Type__c='Endorsement';
        cov1.RecordTypeId = Schema.SObjectType.Coverage__c.getRecordTypeInfosByName().get('Sub Coverage').getRecordTypeId();
        lCov.add(cov1);
        insert lCov;
        
        //create limit deductables
        Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
        insert ded;
        
        
        List<Subjectivity_Template__c> sunTemp = New List<Subjectivity_Template__c>();
        Subjectivity_Template__c subjectivityTemplate = new Subjectivity_Template__c();
        subjectivityTemplate.Subjectivity_Name__c = 'Completed Surplus Lines Tax Form';
        subjectivityTemplate.Subjectivity_Text__c = 'Test';
        subjectivityTemplate.Default_Load__c = true;
        subjectivityTemplate.Profession_Criteria__c = 'Engineers';
        subjectivityTemplate.Product__c = 'Celerity';
        subjectivityTemplate.State__c = 'NY';
        sunTemp.add(subjectivityTemplate);
        
        // added by RINKU SAINI 03/01/2022
        Subjectivity_Template__c subjectivityTemplate1 = new Subjectivity_Template__c();
        subjectivityTemplate1.Subjectivity_Name__c = 'Signed / Dated Proposal';
        subjectivityTemplate1.Subjectivity_Text__c = 'Test';
        subjectivityTemplate.Default_Load__c = true;
        subjectivityTemplate1.Profession_Criteria__c = 'Engineers';
        subjectivityTemplate1.Product__c = 'Celerity';
        sunTemp.add(subjectivityTemplate1);
        Insert sunTemp;

        
        
        Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote.Coverage_Product_Options__c ='D&O;MPL';
        quote.Layer__c = 'Excess';
        quote.Is_Quote_Approved_AQ__c = 'Approved';
        quote.Pending_or_Prior_Proceedings_Date__c=date.today();
        insert quote;
        
        quote.Is_Quote_Approved_AQ__c = 'Rejected';
        quote.Status = 'Rated';
        update quote;
        
        /*Subjectivity__c subj = new Subjectivity__c();
subj.Subjectivity__c = 'Testing';
subJ.Subjectivity_Status__c = 'Open';
subJ.Subjectivity_Type__c = 'MPL';
subJ.Quote__c = quote.Id;
insert subJ;*/
        
        Referral_Reason__c refReason = new Referral_Reason__c();
        refReason.Name = 'Ref reason';
        refReason.Approval_Level_Required__c = '1';
        refReason.Approval_Status__c = 'Approved';
        refReason.Approval_Rejected_Date__c = date.today();
        refReason.Approver_Level__c = '2';
        refReason.Entity_Path__c = 'Entity';
        refReason.Reason__c = ' reason';
        refReason.Reason_Type__c = 'Refer';
        refReason.Status__c = 'Cleared';
        refReason.Quote__c= quote.Id;
        insert refReason;
        
        
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
    @isTest static void testCreateQuote() {
        //change another product to get the list products from quote.Coverage_Product_Options__c
        product.Name ='D&O Standalone';
        update product;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        insert opportunity;
        
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
        Test.startTest();
        Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote.Coverage_Product_Options__c ='D&O;MPL';       
        insert quote;
        
        quote.Status = 'Rated';
        update quote;
        
        /*Subjectivity__c subj = new Subjectivity__c();
subj.Subjectivity__c = 'Testing';
subJ.Subjectivity_Status__c = 'Open';
subJ.Subjectivity_Type__c = 'MPL';
subJ.Quote__c = quote.Id;
insert subJ;*/
        
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
        
        quote.Name = 'test';
        update quote;
        List<Quote> lstQuote = [SELECT Id FROM Quote Where Id =:quote.Id];
        Test.stopTest();
        
        System.assertEquals(true,lstQuote[0].Id != null);
    }
    
    /** Try to run CreateQuote with the product of Oppotunity */
    @isTest static void testCreateQuote1() {
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        insert opportunity;
        
        //Create coverage
        List<Coverage__c> lCov = new List<Coverage__c>();
        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'D&O');
        lCov.add(cov);
        Coverage__c cov1 = TestUtil.createCoverage('Coverage test without deductible', 'MPL');
        lCov.add(cov1);
        insert lCov;
        
        
        
        //create limit deductables
        Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
        insert ded;
        
        Test.startTest();
        
        Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote.Coverage_Product_Options__c ='D&O;MPL';
        insert quote;
        
        // Coverages Line Item
        CoveragesLineItem__c coverLi = new CoveragesLineItem__c();
        coverLi.Coverage__c  = cov.Id; 
        coverLi.Quote__c = quote.Id;
        coverLi.Coverage_Premium__c  = 'Text Premium'; 
        coverLi.Min_amt__c  = 1000;
        coverLi.Max_amt__c  = 5000;
        coverLi.Deductible_Frequency__c  = 'Daily';
        coverLi.Options_Value_Percent__c  = 5;
        //coverLi.Parent_Coverages_Line_Item__c = '';
        insert coverLi;
        quote.Quote_Type__c = 'New Business';
        quote.Pending_or_Prior_Proceedings_Date__c=date.today();
        quote.Effective_Date__c = Date.today();
        coverLi.Coverage_Effective_Date__c = Date.today();                  
        
        quote.Coverage_Product_Options__c = 'D&O;MPL;Cyber';
        List<Quote> lstQuote = [SELECT Id,Quote_Type__c,Pending_or_Prior_Proceedings_Date__c,Effective_Date__c FROM Quote Where Id =:quote.Id];
       // QuoteTriggerHandler.pendingOrPriorProceedingsDate(lstQuote);
        QuoteTriggerHandler_CEL.pendingOrPriorProceedingsDate(lstQuote);
        quote.Quote_Type__c='Renewal';
        update quote;
        
        Rating_Modifiers__c rateMod = TestUtil.createRatingModifier('test Rate Mod', 'MPL', opportunity.id);
        rateMod.Display_Format__c ='Primary Modifiers';
        rateMod.Rating_Modifier_Code__c = 'Test 1';
        insert rateMod;
        
        Rating_Modifier_Factor__c rateFac = new Rating_Modifier_Factor__c();
        rateFac.Rating_Modifier__c = rateMod.Id;
        rateFac.Quote__c = quote.Id;
        rateFac.Factor_Default_Value__c = 1;
        rateFac.Factor_Max__c=2;
        rateFac.Factor_Min__c =3;
        rateFac.Factor_Value__c= 4;
        insert rateFac;
        
        List<Quote> lstQuotes = [SELECT Id,OpportunityId,Product_Name__c,Coverage_Product_Options__c,Quote_Type__c,Pending_or_Prior_Proceedings_Date__c,Effective_Date__c FROM Quote Where Id =:quote.Id];
       // QuoteTriggerHandler.pendingOrPriorProceedingsDate(lstQuotes);
        QuoteTriggerHandler_CEL.pendingOrPriorProceedingsDate(lstQuote);
       // QuoteTriggerHandler.processPoliCleanup(lstQuotes);
        QuoteTriggerHandler_Common.processPoliCleanup(lstQuotes);
        QuoteTriggerHandler_Common.AddCoverageLineItems(null);
        QuoteTriggerHandler_Common.AddCoverageLineItems( New List<Quote>());
        Test.stopTest();
        System.assertEquals(true,lstQuote[0].Id != null);
    }
    
    //Try to run CreateQuote with coverageLineItem without Coverage_Limits_Deductibles__c
    @isTest static void testCreateQuote2() {
        //update product
        
        product.Name='MPL Standalone';
        
        List<Opportunity> lO = new List<Opportunity>();
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        opportunity.Coverage_Product_Options__c = 'D&O;MPL;Cyber';
        lO.add(opportunity);	
        Opportunity opportunity1 = TestUtil.createOpportunity('Opp Test1',acc.Id, product.Id);
        lO.add(opportunity1);
        insert lO;
        
        //Create coverage
        List<Coverage__c> lCov = new List<Coverage__c>();
        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'D&O');
        lCov.add(cov);
        Coverage__c cov1 = TestUtil.createCoverage('Coverage test without deductible', 'MPL');
        lCov.add(cov1);
        insert lCov;
        
        //create limit deductables
        Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
        insert ded;
        
        Location__c location = TestUtil.createNewLocation(acc.BillingStreet, acc.BillingCity, acc.BillingCountry, acc.BillingPostalCode, acc.BillingState);
        insert location;
        
        Test.startTest();
        
        List<Quote> quotes = new  List<Quote>();
        Quote quote1 = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote1.Quote_Type__c='New Business';
        quote1.Coverage_Product_Options__c ='D&O;MPL';
        quote1.Pending_or_Prior_Proceedings_Date__c=date.today();
        quote1.Effective_Date__c=date.today();
        quotes.add(quote1);
        Quote quote2 = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote2.Coverage_Product_Options__c ='MPL;Cyber';
        quotes.add(quote2);
        insert quotes;
        
        Test.stopTest();
        
        List<Quote> lstQuote = [SELECT Id FROM Quote Where Id =:quotes[0].Id];
        System.assertEquals(true,lstQuote[0].Id != null);
        
    }
    @isTest static void testCreateQuote2forError() {
        //update product
        product.Name='MPL Standalone';
        
        List<Opportunity> lO = new List<Opportunity>();
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        opportunity.Coverage_Product_Options__c = 'D&O;MPL;Cyber';
        lO.add(opportunity);	
        Opportunity opportunity1 = TestUtil.createOpportunity('Opp Test1',acc.Id, product.Id);
        lO.add(opportunity1);
        insert lO;
        
        //Create coverage
        List<Coverage__c> lCov = new List<Coverage__c>();
        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'D&O');
        lCov.add(cov);
        Coverage__c cov1 = TestUtil.createCoverage('Coverage test without deductible', 'MPL');
        lCov.add(cov1);
        insert lCov;
        
        //create limit deductables
        Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
        insert ded;
        
        Location__c location = TestUtil.createNewLocation(acc.BillingStreet, acc.BillingCity, acc.BillingCountry, acc.BillingPostalCode, acc.BillingState);
        insert location;
        
        Test.startTest();
        
        List<Quote> quotes = new  List<Quote>();
        Quote quote1 = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote1.Coverage_Product_Options__c ='D&O;MPL';
        quotes.add(quote1);
        Quote quote2 = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote2.Coverage_Product_Options__c ='MPL;Cyber';
        quotes.add(quote2);
        insert quotes;
        
        Test.stopTest();
        
        List<Quote> lstQuote = [SELECT Id FROM Quote Where Id =:quotes[0].Id];
        System.assertEquals(true,lstQuote[0].Id != null);
    }
    
    @isTest static void testCreateQuote4() {
        
        Account acc2 = new Account();
        acc2.Name = 'Test Account';
        acc2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Account').getRecordTypeId();
        insert acc2;
        
        product.Name ='D&O Standalone';
        update product;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc2.Id, product.Id);
        opportunity.StageName = 'Qualified';
        insert opportunity;
        
        //Creating Account product
        Account_Product__c accProd = new Account_Product__c();
        accProd.Product_Id__c = product.Id;
        accProd.Account_Id__c = acc2.Id;
        insert accProd;
        
         //Creating Account product
        Account_Product__c accProd1 = new Account_Product__c();
        accProd1.Product_Id__c = product.Id;
        accProd1.Account_Id__c = acc2.Id;
        insert accProd1;
        
        
        //Create Contact
        Contact con = new Contact();
        con.LastName = 'Test Contact';
        con.RecordTypeId =Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        con.AccountId = acc2.Id; 
        insert con;
        
        //Create broker 
        Broker_Account__c broAcc = TestUtil.createBrokerAccount(con.id, opportunity.id);
        insert broAcc;
        
        //Create coverage
        List<Coverage__c> lCov = new List<Coverage__c>();
        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'D&O');
        lCov.add(cov);
        Coverage__c cov1 = TestUtil.createCoverage('Coverage test', 'MPL');
        lCov.add(cov1);
        insert lCov;
        
        //create limit deductables
        Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
        insert ded;
        
        Test.startTest();
        Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote.Coverage_Product_Options__c ='D&O;MPL';
        insert quote;
        QuoteTriggerHandler_Common.updateQuoteWithBrokerName( New List<Quote>{quote});
        QuoteTriggerHandler_Common.updateCommission( New List<Quote>{quote});
        Test.stopTest();
        
        List<Quote> lstQuote = [SELECT Id FROM Quote Where Id =:quote.Id];
        System.assertEquals(true,lstQuote[0].Id != null);
    }
    
    /* @isTest
public static void testGenerateQuoteDocument() {

product.Name ='D&O Standalone';
update product;

Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
opportunity.StageName = 'Qualified';
insert opportunity;
//5/1/21
Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
acc.BillingStreet = acc.ShippingStreet;
acc.BillingCity = acc.ShippingCity;
acc.BillingState = acc.ShippingState;
acc.BillingPostalCode = acc.ShippingPostalCode;
acc.BillingCountry = acc.ShippingCountry;
insert acc;


Policy__c pol = new Policy__c();
pol.Account__c = acc.Id;
insert pol;

Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
quote.Coverage_Product_Options__c ='D&O;MPL';
quote.Status = 'Bound';
quote.Policy__c = pol.Id;

insert quote;



//Create coverage
List<Coverage__c> lCov = new List<Coverage__c>();
Coverage__c cov = TestUtil.createCoverage('Coverage test', 'D&O');
lCov.add(cov);
Coverage__c cov1 = TestUtil.createCoverage('Coverage test', 'MPL');
lCov.add(cov1);
insert lCov;
//create limit deductables
Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
insert ded;

Rating_Modifiers__c rateMod = TestUtil.createRatingModifier('test Rate Mod', 'MPL', opportunity.id);
rateMod.Display_Format__c ='Primary Modifiers';
rateMod.Rating_Modifier_Code__c = 'Test 1';
insert rateMod;

Rating_Modifier_Factor__c rateFac = new Rating_Modifier_Factor__c();
rateFac.Rating_Modifier__c = rateMod.Id;
rateFac.Quote__c = quote.Id;
rateFac.Factor_Default_Value__c = 1;
rateFac.Factor_Max__c=2;
rateFac.Factor_Min__c =3;
rateFac.Factor_Value__c= 4;
insert rateFac;

Rating_Modifier_Template__c rateTemp = TestUtil.createRatingModifierTemplate('Rate Temp', 'MPL', 'Picklist');
rateTemp.Rating_Modifier_Code__c = 'Test 1';
insert rateTemp;


Test.startTest();



Quote updateQuote = [SELECT Id,QuoteNumber,ContactId,Product_Name__c,UW_Reason__c,
Rating_Status__c,BillingName,Commission_percentage__c,Status FROM Quote WHERE Id =:quote.Id];
updateQuote.Generate_Quote_Document__c = true;
updateQuote.Coverage_Product_Options__c = 'MPL;';
update updateQuote;
Test.stopTest();

System.assertEquals('MPL;',  updateQuote.Coverage_Product_Options__c);
}*/
    
    @isTest
    static void forApprovalTest(){
        Test.startTest();
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Closed Won';
        opp.Expiration_Date__c = Date.today()+60;
        insert opp;
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'Referred';
        quote1.Rating_Status__c = 'Refer';
        quote1.Coverage_Product_Options__c = 'D&O';
        quote1.Refer_Type__c = 'Underwriting Referral';
        quote1.Quote_Type__c='Amendment';
        quote1.Is_Quote_Approved_AQ__c = 'Aprroved';
        insert quote1;  
        
        quote1.Status = 'In Progress';
        quote1.Coverage_Product_Options__c = 'D&O;MPL';
        update quote1;
        
       /* Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
        app.setObjectId(quote1.id);
        
        app.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        Approval.ProcessResult result = Approval.process(app);
        
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setComments('Approving request.');
        req.setAction('Approve');
        ProcessInstanceWorkitem pItem = [Select Id from ProcessInstanceWorkitem  where ProcessInstance.TargetObjectId =: quote1.id][0];
        req.setWorkitemId(pItem.Id);
        Approval.ProcessResult result2 = Approval.process(req);*/
        
        List<ProcessInstance> processInstances = [SELECT TargetObjectId, SubmittedBy.Email, SubmittedBy.Name FROM ProcessInstance];
        System.debug('processInstances'+processInstances+opp.RecordTypeId);
        
        Map<id,Quote> quoteMap = new Map<Id, Quote>([Select Id, Status from Quote where Id = :quote1.Id]);
        QuoteTriggerHandler.updateQuoteStatusToInProgress([Select Id, Status from Quote where Id = :quote1.Id], quoteMap);
        Test.stopTest();
        System.assertEquals('New quote 1',  quote1.Name);
        
    }
    
    //For Celerity Approval
     @isTest
    static void forApprovalTest2(){
       // Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
        Test.startTest();
        product = TestUtil.createProduct('Cyber Standalone');
        insert product; 
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Closed Won';
        opp.Expiration_Date__c = Date.today()+60;
        insert opp;
        
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'Referred';
        quote1.Rating_Status__c = 'Refer';
        quote1.Coverage_Product_Options__c = 'D&O';
        quote1.Refer_Type__c = 'Underwriting Referral';
        quote1.Quote_Type__c='Amendment';
        quote1.Azure_ID__c = '9042ac98-ae5a-4692-9880-58d92d0eb9d9';
        //quote1.Is_Quote_Approved_AQ__c = 'Aprroved';
        insert quote1;  
        
        quote1.Status = 'Rated';
        quote1.Rating_Status__c = 'Clear';
        quote1.Coverage_Product_Options__c = 'D&O;MPL';
        update quote1;
        
        //String azureid = quote1.Azure_ID__c;
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
        ResultResponse res = new ResultResponse();  
        //FinalizeServiceHandler_Common.finalizeAndGenerateDoc(quote1);
        Test.stopTest();
        System.assertEquals('New quote 1',  quote1.Name);
        
    }
    
    
    @isTest
    static void forRejectedTest(){
        Test.startTest();
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test 2',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Closed Won';
        opp.Expiration_Date__c = Date.today()+60;
        insert opp;
        
        Quote quote1 = TestUtil.createQuote('New quote 2', opp.Id);
        quote1.Status = 'In Approval';
        quote1.Coverage_Product_Options__c = 'D&O';
        quote1.Refer_Type__c = 'Underwriting Referral';
        insert quote1;  
        
        quote1.Status = 'Rated';
        update quote1;
        
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
        app.setObjectId(quote1.id);
        
        app.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        Approval.ProcessResult result = Approval.process(app);
        
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setComments('Rejecting request.');
        req.setAction('Reject');
        ProcessInstanceWorkitem pItem = [Select Id from ProcessInstanceWorkitem  where ProcessInstance.TargetObjectId =: quote1.id][0];
        req.setWorkitemId(pItem.Id);
        Approval.ProcessResult result2 = Approval.process(req);
        
        List<ProcessInstance> processInstances = [SELECT TargetObjectId, SubmittedBy.Email, SubmittedBy.Name FROM ProcessInstance];
        System.debug('processInstances'+processInstances+opp.RecordTypeId);
        
        Map<id,Quote> quoteMap = new Map<Id, Quote>([Select Id, Status from Quote]);
        QuoteTriggerHandler.updateQuoteStatusToInProgress([Select Id, Status from Quote], quoteMap);
        Test.stopTest();
        system.assertNotEquals(result2, null);
        
    }
    
    @isTest static void addRatingModifierQuote() {
        //change another product to get the list products from quote.Coverage_Product_Options__c
        Test.startTest();
        
        Subjectivity_Template__c subjectivityTemplate = new Subjectivity_Template__c();
        subjectivityTemplate.Subjectivity_Name__c = 'Signed / Dated Proposal';
        subjectivityTemplate.Subjectivity_Text__c = 'Test';
        subjectivityTemplate.Profession_Criteria__c = 'Engineers';
        subjectivityTemplate.Default_Load__c = true;
        insert subjectivityTemplate;
        
        product.Name ='D&O Standalone';
        update product;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        insert opportunity;
        
        //Create coverage
        List<Coverage__c> lCov = new List<Coverage__c>();
        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'D&O');
        cov.Coverage_Type__c='Endorsement';
        cov.RecordTypeId = Schema.SObjectType.Coverage__c.getRecordTypeInfosByName().get('Sub Coverage').getRecordTypeId();
        lCov.add(cov);
        Coverage__c cov1 = TestUtil.createCoverage('Coverage test', 'MPL');
        lCov.add(cov1);
        insert lCov;
        
        //create limit deductables
        Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
        insert ded;
        
        Rating_Modifiers__c ratMod = TestUtil.createRatingModifier('Test Rat Modifier', 'MPL Standalone', opportunity.id);
        ratMod.Display_Format__c ='Primary Modifiers';
        ratMod.Rating_Modifier_Code__c = '22';
        ratMod.Name='Proposal Form Date';
        ratMod.Opportunity__c = opportunity.Id;
        ratMod.Rating_Modifier_Value__c = null;
        insert ratMod;
        
        
        
        Rating_Modifier_Template__c rateTemp = TestUtil.createRatingModifierTemplate('Test Rate Mod Temp', 'MPL', 'Number');
        rateTemp.Rating_Modifier_Code__c = '22';
        rateTemp.Display_Format__c = 'Eligibility';
        insert rateTemp;       
        
        
        Master_Binder__c masterBind =  new Master_Binder__c();
        masterBind.Name = 'masterBind Name';
        masterBind.Expiry_Date__c = Date.today()+365;
        masterBind.Inception_Date__c = Date.today();
        masterBind.MGA_Commission__c = 15;
        masterBind.Layer__c = 'Primary;Excess';
        masterBind.Coverholder_Name__c = ' masterBind Holder';
        masterBind.Coverholder_Pin__c = 'masterBind Pin';
        insert masterBind;  
        
        Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote.Coverage_Product_Options__c ='D&O;MPL';
        quote.Layer__c='Excess';
        quote.Master_Binder__c=masterBind.Id;
        quote.Is_Quote_Approved_AQ__c='Approved';
        insert quote;
        
        Test.stopTest();
        
        List<Quote> lstQuote = [SELECT Id FROM Quote Where Id =:quote.Id];
        System.assertEquals(true,lstQuote[0].Id != null);
    }
    
    @isTest static void testEndorseQuote() {
        //change another product to get the list products from quote.Coverage_Product_Options__c
        product.Name ='D&O Standalone';
        update product;
        Test.startTest();
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        insert opportunity;
        
        Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote.Coverage_Product_Options__c ='D&O;MPL'; 
        quote.Endorsement_Effective_Date__c = date.today();
        quote.Is_Quote_Approved_AQ__c='Rejected';
        insert quote;
        
        quote.Status = 'Rated';
        quote.Effective_Date__c= Date.today();
        update quote;
        
        quote.Quote_Type__c = Label.Quote_Type_Amendment;
        quote.Endorsement_Effective_Date__c = date.today()+10;
        update quote;
        quote.Layer__c = 'Excess';
        update quote;
        Test.stopTest();
        //
        System.assertEquals(true,quote.Id != null);
    }
    
    @isTest static void createSubjectivityIfProposalFormDateEmptyExceptionTest(){
        Test.startTest();
        List<Subjectivity_Template__c> subjectivityTemplates = [Select Id from Subjectivity_Template__c];
        delete subjectivityTemplates;
        
        opportunity oppo = [Select Id From opportunity][0];
        
        try{
            Quote quote = TestUtil.createQuote('New Quote Test',oppo.Id);
            quote.Coverage_Product_Options__c ='D&O;MPL';
            quote.Layer__c = 'Excess';
            quote.Is_Quote_Approved_AQ__c='';
            insert quote;
        }catch(Exception e){}
        test.stopTest(); 
    }
    
    
    @isTest static void updateInsurerExcessTest(){
        
        acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
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
        
        String rdPolicyId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId(); 
        Policy__c policy = new Policy__c();
        policy.Account__c = acc.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);
        insert policy;
        
        //Create Transaction
        Transactions__c transactions = new Transactions__c();
        transactions.Policy__c=policy.Id;
        transactions.Submission__c=opp.Id;
        insert transactions;
        
        Test.startTest();
        Quote quote1 = TestUtil.createQuote('New quote', opp.Id);
        quote1.Layer__c = 'Primary';
        quote1.Coverage_Product_Options__c = 'Professional Indemnity';
        quote1.Status = 'In Approval';
        quote1.Refer_Type__c = 'Underwriting Referral';
        insert quote1; 
        quote1.Layer__c = 'Excess';
        quote1.Status = 'Quoted';
        update quote1;
        
        quote1.Layer__c = 'Primary';
        quote1.Policy__c=policy.Id;
        quote1.Status = 'Bound';
        update quote1;
        Test.stopTest();
        System.assertEquals(quote1.Layer__c, 'Primary');
        
    }
    
    @isTest static void  InsurerExcessTest(){
            
            acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
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
            
            String rdPolicyId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId(); 
            Policy__c policy = new Policy__c();
            policy.Account__c = acc.Id; 
            policy.Expiration_Date__c = Date.today().addDays(100);
            insert policy;
            
            //Create Transaction
            Transactions__c transactions = new Transactions__c();
            transactions.Policy__c=policy.Id;
            transactions.Submission__c=opp.Id;
            insert transactions;
            
            Test.startTest();
            Quote quote1 = TestUtil.createQuote('New quote', opp.Id);
            quote1.Coverage_Product_Options__c = 'Professional Indemnity';
            quote1.Layer__c = 'Excess';
            quote1.Status = 'In Approval';
            quote1.Refer_Type__c = 'Underwriting Referral';
            insert quote1;
            
            Referral_Reason__c refReason = new Referral_Reason__c();
            refReason.Name = 'Ref reason';
            refReason.Approval_Level_Required__c = '1';
            refReason.Approval_Status__c = 'Not used';
            refReason.Approval_Rejected_Date__c = System.Date.today();
            refReason.Approver_Level__c = '2';
            refReason.Entity_Path__c = 'Entity';
            refReason.Reason__c = ' reason';
            refReason.Reason_Type__c = 'Refer';
            refReason.Status__c = 'Cleared';
            refReason.Quote__c= quote1.Id;
            insert refReason;
            
            quote1.Is_Quote_Approved_AQ__c = 'Approved';
            quote1.Status = 'In Progress';
            update quote1;
            
            quote1.Is_Quote_Approved_AQ__c = 'Rejected';
            quote1.Status = 'Rated';
            update quote1;
            Test.stopTest();
            system.assertEquals(quote1.Refer_Type__c, 'Underwriting Referral');
        }
    
    @isTest static void createInsurerExcessTest2(){
        
        acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        Location__c location = TestUtil.createNewLocation(acc.BillingStreet, acc.BillingCity, acc.BillingCountry, acc.BillingPostalCode, acc.BillingState);
        insert location;
        
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
        
  
        
        // added by RINKU SAINI 03/01/2022
        Rating_Modifiers__c ratMod = TestUtil.createRatingModifier('Test Rat Modifier', 'MPL Standalone', opp.id);
        ratMod.Display_Format__c ='Primary Modifiers';
        ratMod.Rating_Modifier_Code__c = '22';
        ratMod.Name='Proposal Form Date';
        ratMod.Opportunity__c = opp.Id;
        ratMod.Rating_Modifier_Value__c = null;
        insert ratMod;
        
        Rating_Modifier_Template__c rateTemp = TestUtil.createRatingModifierTemplate('Test Rate Mod Temp', 'MPL', 'Number');
        rateTemp.Rating_Modifier_Code__c = '22';
        rateTemp.Display_Format__c = 'Eligibility';
        insert rateTemp; 
        
        String rdPolicyId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId(); 
        Policy__c policy = new Policy__c();
        policy.Account__c = acc.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);
        insert policy;
        
        //Create Transaction
        Transactions__c transactions = new Transactions__c();
        transactions.Policy__c=policy.Id;
        transactions.Submission__c=opp.Id;
        insert transactions;
        
       
       
        
        Test.startTest();
        Quote quote1 = TestUtil.createQuote('New quote', opp.Id);
        quote1.Coverage_Product_Options__c = 'Professional Indemnity';
        quote1.Layer__c = 'Excess';
        quote1.Status = 'In Progress';
        quote1.Refer_Type__c = 'Underwriting Referral';
        insert quote1;
        
        QuoteTriggerHandler_Common.generatedQuoteDocument( New Set<Id>{quote1.Id});
        
        
        Referral_Reason__c refReason = new Referral_Reason__c();
        refReason.Name = 'Ref reason';
        refReason.Approval_Level_Required__c = '1';
        refReason.Approval_Rejected_Date__c = System.Date.today();
        refReason.Approver_Level__c = '2';
        refReason.Entity_Path__c = 'Entity';
        refReason.Reason__c = ' reason';
        refReason.Reason_Type__c = 'Refer';
        refReason.Status__c = 'Cleared';
        refReason.Quote__c= quote1.Id;
        insert refReason;
        
        Quote_Option__c quoteOption = new Quote_Option__c(Quote__c = quote1.Id, Bound__c = true);
        quoteOption.Limit__c = 123;
        quoteOption.Option_Type__c = 'Free Form';
        insert quoteOption;
        
        Quote_Option__c quoteOption1 = new Quote_Option__c(Quote__c = quote1.Id, Bound__c = true);
        quoteOption1.Limit__c = 123;
        quoteOption1.Option_Type__c = 'Fixed Limit';
        insert quoteOption1;
        
        quote1.Status = 'Rated';
        quote1.Quote_Type__c = 'Renewal';
        update quote1;
        
        quote1.Status = 'Quoted';
        quote1.Quote_Type__c = 'Reinstatement';
        update quote1;
        
        Test.stopTest();
        system.assertEquals(quote1.Refer_Type__c, 'Underwriting Referral');
    } 
    
    /* @isTest static void testCreateAmendment() {
Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
opportunity.StageName = 'Qualified';
insert opportunity;

//Create coverage
List<Coverage__c> lCov = new List<Coverage__c>();
Coverage__c cov = TestUtil.createCoverage('Coverage test', 'D&O');
lCov.add(cov);
Coverage__c cov1 = TestUtil.createCoverage('Coverage test without deductible', 'MPL');
lCov.add(cov1);
insert lCov;



//create limit deductables
Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
insert ded;



Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
quote.Coverage_Product_Options__c ='D&O;MPL';
insert quote;



// Coverages Line Item
CoveragesLineItem__c coverLi = new CoveragesLineItem__c();
coverLi.Coverage__c  = cov.Id; 
coverLi.Quote__c = quote.Id;
coverLi.Coverage_Premium__c  = 'Text Premium'; 
coverLi.Min_amt__c  = 1000;
coverLi.Max_amt__c  = 5000;
coverLi.Deductible_Frequency__c  = 'Daily';
coverLi.Options_Value_Percent__c  = 5;
//coverLi.Parent_Coverages_Line_Item__c = '';
insert coverLi;
Test.startTest();
quote.Quote_Type__c = 'Amendment';
quote.Endorsement_Effective_Date__c= Date.today()+10;
quote.Effective_Date__c = Date.today()+10;
//coverLi.Coverage_Effective_Date__c = Date.today();                  
Test.stopTest();
quote.Coverage_Product_Options__c = 'D&O;MPL;Cyber';
List<Quote> lstQuote = [SELECT Id FROM Quote Where Id =:quote.Id];

System.assertEquals(true,lstQuote[0].Id != null);
} */
    @isTest static void updateInsurerExcessTest2(){
        
        acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
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
        
        String rdPolicyId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId(); 
        Policy__c policy = new Policy__c();
        policy.Account__c = acc.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);
        insert policy;
        
        //Create Transaction
        Transactions__c transactions = new Transactions__c();
        transactions.Policy__c=policy.Id;
        transactions.Submission__c=opp.Id;
        insert transactions;
        
        Test.startTest();
        Quote quote1 = TestUtil.createQuote('New quote', opp.Id);
        quote1.Coverage_Product_Options__c = 'Professional Indemnity';
        quote1.Layer__c = 'Primary';
        quote1.Status = 'Rated';
        quote1.Refer_Type__c = 'Underwriting Referral';
        //quote1.Is_Quote_Approved_AQ__c = 'Approved';
        insert quote1;
        
        Quote quote = [select Id,Is_Quote_Approved_AQ__c from Quote where Id=:quote1.Id];    
        system.debug('value: '+quote); 
        quote1.Layer__c = 'Excess';
        quote1.Status = 'Quoted';
        quote1.Effective_Date__c = date.today() + 24;
        
        
        
        Master_Binder__c masterBind =  new Master_Binder__c();
        masterBind.Name = 'masterBind Name';
        masterBind.Expiry_Date__c = Date.today()+365;
        masterBind.Inception_Date__c = Date.today();
        masterBind.MGA_Commission__c = 15;
        masterBind.Layer__c = 'Primary;Excess';
        masterBind.Coverholder_Name__c = ' masterBind Holder';
        masterBind.Coverholder_Pin__c = 'masterBind Pin';
        insert masterBind;  
        quote1.Master_Binder__c = masterBind.Id;
        update quote1;
        
        
        Referral_Reason__c refReason = new Referral_Reason__c();
        refReason.Name = 'Ref reason';
        refReason.Approval_Level_Required__c = '1';
        refReason.Approval_Status__c = 'Approved';
        refReason.Approval_Rejected_Date__c = System.Date.today();
        refReason.Approver_Level__c = '2';
        refReason.Entity_Path__c = 'Entity';
        refReason.Reason__c = ' reason';
        refReason.Reason_Type__c = 'Refer';
        refReason.Status__c = 'Cleared';
        refReason.Quote__c= quote1.Id;
        insert refReason;
        
        quote1.Layer__c = 'Primary';
        update quote1;
        
        test.stoptest();
        System.assertEquals( quote1.Layer__c, 'Primary');
    } 
    @isTest static void updateInsurerExcessTestCUAQ(){
        acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
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
        
        String rdPolicyId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId(); 
        Policy__c policy = new Policy__c();
        policy.Account__c = acc.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);
        insert policy;
        
        //Create Transaction
        Transactions__c transactions = new Transactions__c();
        transactions.Policy__c=policy.Id;
        transactions.Submission__c=opp.Id;
        insert transactions;
        
        Quote quote1 = TestUtil.createQuote('New quote', opp.Id);
        quote1.Coverage_Product_Options__c = 'Professional Indemnity';
        quote1.Layer__c = 'Primary';
        quote1.Status = 'Rated';
        quote1.Refer_Type__c = 'Underwriting Referral';
        //quote1.Is_Quote_Approved_AQ__c = 'Approved';
        insert quote1;
        Referral_Reason__c refReason = new Referral_Reason__c();
        refReason.Name = 'Ref reason';
        refReason.Approval_Level_Required__c = '1';
        refReason.Approval_Status__c = 'Approved';
        refReason.Approval_Rejected_Date__c = date.today()+365;
        refReason.Quote__c= quote1.Id;
        insert refReason;
        
        quote1.Layer__c = 'Primary';
        update quote1;
        Referral_Reason__c refReason1 = new Referral_Reason__c();
        refReason1.Name = 'Ref reason';
        refReason1.Approval_Level_Required__c = '2';
        refReason1.Approval_Status__c = 'Rejected';
        refReason1.Approval_Rejected_Date__c = date.today()+365;
        refReason1.Quote__c= quote1.Id;
        insert refReason1;
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
        app.setObjectId(quote1.id);
        app.setNextApproverIds(new List<Id>{userInfo.getUserId()});
        Approval.ProcessResult result = Approval.process(app);
        quote1.Status = 'Referred';
        update quote1;
        Test.startTest();
        quote1.Layer__c = 'Excess';
        quote1.Status = 'Quoted';
        quote1.Effective_Date__c = date.today() + 24;
        
        Master_Binder__c masterBind =  new Master_Binder__c();
        masterBind.Name = 'masterBind Name';
        masterBind.Expiry_Date__c = Date.today()+365;
        masterBind.Inception_Date__c = Date.today();
        masterBind.MGA_Commission__c = 15;
        masterBind.Layer__c = 'Primary;Excess';
        masterBind.Coverholder_Name__c = ' masterBind Holder';
        masterBind.Coverholder_Pin__c = 'masterBind Pin';
        insert masterBind;  
        quote1.Master_Binder__c = masterBind.Id;
        update quote1;
        test.stoptest();
        System.assertEquals( quote1.Layer__c, 'Excess');
    } 
    public static testmethod void coverprocessQuotePremiums(){
        Test.startTest();
        
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        Product2 product = TestUtil.createProduct('Private Company Combo');
        insert product;   
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        opportunity.Coverage_Product_Options__c = 'D&O;MPL';
        insert opportunity;
        
        Product_Option_Line_Item__c prodItem = New Product_Option_Line_Item__c();
        prodItem.Submission__c = opportunity.Id;
        prodItem.Account__c = acc.Id;
        prodItem.Clearance_Status__c = 'Cleared';
        Insert prodItem;
        
        //Create coverage
        List<Coverage__c> lCov = new List<Coverage__c>();
        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'D&O');
        cov.Coverage_Product__c = 'D&O';
        lCov.add(cov);
        
        Coverage__c cov1 = TestUtil.createCoverage('Coverage test', 'MPL');
        cov1.Coverage_Type__c='Endorsement';
         cov.Coverage_Product__c = 'Private Company Combo';
        cov1.RecordTypeId = Schema.SObjectType.Coverage__c.getRecordTypeInfosByName().get('Sub Coverage').getRecordTypeId();
        lCov.add(cov1);
        insert lCov;
        
        Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote.Coverage_Product_Options__c ='D&O;MPL';
        quote.Layer__c = 'Excess';
        quote.Is_Quote_Approved_AQ__c = 'Approved';
        quote.Pending_or_Prior_Proceedings_Date__c=date.today();
        insert quote;
        
        quote.Coverage_Product_Options__c = 'MPL';
        update quote;
        QuoteTriggerHandler_Common.AddCoverageLineItems( New List<Quote>{quote});
        system.debug('quote '+quote);
        Test.stopTest();
    }
    
    @isTest static void updateInsurerExcessTestCUAQ1(){
        acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 prod = TestUtil.createProduct('Private Company Combo');
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
         
          //Create coverage
        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'Professional Indemnity');
        cov.Coverage_Type__c = 'Endorsement';
        insert cov;
        
       
        
        String rdPolicyId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId(); 
        Policy__c policy = new Policy__c();
        policy.Account__c = acc.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);
        insert policy;
        
        //Create Transaction
        Transactions__c transactions = new Transactions__c();
        transactions.Policy__c=policy.Id;
        transactions.Submission__c=opp.Id;
        insert transactions;
        
        Quote quote1 = TestUtil.createQuote('New quote', opp.Id);
        quote1.Coverage_Product_Options__c = 'Professional Indemnity';
        quote1.Layer__c = 'Primary';
        quote1.Status = 'In Approval';
        quote1.Refer_Type__c = 'Underwriting Referral';
        insert quote1;
         
         // Coverages Line Item
         CoveragesLineItem__c coverLi = new CoveragesLineItem__c();
         coverLi.Coverage__c  = cov.Id; 
         coverLi.Quote__c = quote1.Id;
         coverLi.Coverage_Premium__c  = 'Text Premium'; 
         coverLi.Min_amt__c  = 1000;
         coverLi.Max_amt__c  = 5000;
         coverLi.Deductible_Frequency__c  = 'Daily';
         coverLi.Options_Value_Percent__c  = 5;
         coverLi.Parent_Coverages_Line_Item__c = null;
         insert coverLi;
         
          // Coverages Line Item
         CoveragesLineItem__c coverLi1 = new CoveragesLineItem__c();
         coverLi1.Coverage__c  = cov.Id; 
         coverLi1.Quote__c = quote1.Id;
         coverLi1.Coverage_Premium__c  = 'Text Premium'; 
         coverLi1.Min_amt__c  = 1000;
         coverLi1.Max_amt__c  = 5000;
         coverLi1.Deductible_Frequency__c  = 'Daily';
         coverLi1.Options_Value_Percent__c  = 5;
         coverLi1.Parent_Coverages_Line_Item__c = null;
         insert coverLi1;
         
        Referral_Reason__c refReason = new Referral_Reason__c();
        refReason.Name = 'Ref reason';
        refReason.Approval_Level_Required__c = '1';
        refReason.Approval_Status__c = 'Approved';
        refReason.Approval_Rejected_Date__c = date.today()+365;
        refReason.Quote__c= quote1.Id;
        insert refReason;
        
        quote1.Layer__c = 'Primary';
        update quote1;
         
        Referral_Reason__c refReason1 = new Referral_Reason__c();
        refReason1.Name = 'Ref reason';
        refReason1.Approval_Level_Required__c = '2';
        refReason1.Approval_Status__c = 'Rejected';
        refReason1.Approval_Rejected_Date__c = date.today()+365;
        refReason1.Quote__c= quote1.Id;
        insert refReason1;
         
         quote1.Approval_Status__c = 'Approved';
         quote1.Status = 'Rated';
         update quote1;
         
         Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
         app.setObjectId(quote1.id);
         app.setComments('Approving request.');
         app.setNextApproverIds(new List<Id>{userInfo.getUserId()});
         Approval.ProcessResult result = Approval.process(app);         
         
        Test.startTest();
        quote1.Layer__c = 'Excess';
        quote1.Status = 'In Progress';
        quote1.Effective_Date__c = date.today() + 24;
        
        Master_Binder__c masterBind =  new Master_Binder__c();
        masterBind.Name = 'masterBind Name';
        masterBind.Expiry_Date__c = Date.today()+365;
        masterBind.Inception_Date__c = Date.today();
        masterBind.MGA_Commission__c = 15;
        masterBind.Layer__c = 'Primary;Excess';
        masterBind.Coverholder_Name__c = ' masterBind Holder';
        masterBind.Coverholder_Pin__c = 'masterBind Pin';
        insert masterBind;
         
        quote1.Master_Binder__c = masterBind.Id;
        update quote1;
         
         QuoteTriggerHandler_Common.isProductChanged(null,null);
        test.stoptest();
        System.assertEquals( quote1.Layer__c, 'Excess');
    } 
    
    
    @isTest static void testQuoteError() {
        //change another product to get the list products from quote.Coverage_Product_Options__c
        product.Name ='D&O Standalone';
        update product;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        insert opportunity;
        
        //Create coverage
        List<Coverage__c> lCov = new List<Coverage__c>();
        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'D&O');
        cov.Coverage_Product__c = 'D&O';
        lCov.add(cov);
        Coverage__c cov1 = TestUtil.createCoverage('Coverage test', 'MPL');
        lCov.add(cov1);
        insert lCov;
        delete lcov;
        //create limit deductables
        //Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
        //insert ded;s
        Test.startTest();
        Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote.Quote_Type__c='New Business';
        
        //quote.Coverage_Product_Options__c ='D&O;MPL';       
        insert quote;
        quote.Name = 'test';
        quote.Status = 'Quoted';
        quote.Generate_Quote_Document__c=true;
        update quote;
        
        Test.stopTest();
        System.assertEquals( quote.Status,'Quoted');
    }
    
    @isTest static void testAddDefaultCoverages() {
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 prod = TestUtil.createProduct('Professional Indemnity');
        prod.RecordTypeId = aqueousRecordTypeId;
        prod.Innovisk_Entity_ID__c = 'Aqueous';
        insert prod;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, prod.Id);
        opportunity.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        opportunity.StageName = 'Qualified';
        opportunity.Main_Profession__c = 'Architects';
        opportunity.Innovisk_Entity_ID__c = 'Aqueous';
        insert opportunity;
        
        //Create coverage
        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'Professional Indemnity');
        cov.Coverage_Type__c = 'Endorsement';
        insert cov;
        
        
        
        //create limit deductables
        Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
        insert ded;
        
        Coverage_Matrix__c objCM = new Coverage_Matrix__c();
        objCM.Coverage__c = cov.Id;
        objCM.Coverage_Product__c = 'Professional Indemnity';
        objCM.IsActive__c = true;
        objCM.Unique_Identifier__c = 'CM_1';
        insert objCM;
        
        Coverage_Matrix_Rule__c objCMR = new Coverage_Matrix_Rule__c();
        objCMR.Coverage_Matrix__c = objCM.Id;
        objCMR.Field_API_Name__c = 'Main_Profession__c';
        objCMR.Field_Type__c = 'Text';
        objCMR.IsActive__c = true;
        objCMR.Object_API_Name__c = 'Opportunity';
        objCMR.Operat__c = 'in';
        objCMR.RecordTypeId = Schema.SObjectType.Coverage_Matrix_Rule__c.getRecordTypeInfosByName().get('Field Query').getRecordTypeId();
        objCMR.Rule_Type__c = 'Field Query';
        objCMR.Value__c = 'Architects;Engineers;Design & Construct';
        insert objCMR;
        
        Test.startTest();
        Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote.Quote_Type__c='New Business';
        insert quote;
        QuoteTriggerHandler_Common obj = New QuoteTriggerHandler_Common();
        try{
        QuoteTriggerHandler_Common.createPrimaryLocation(null);
        }catch(exception exp){}
        try{
        QuoteTriggerHandler_Common.updateCoverageLineItems(null,null);
        }catch(exception exp){}
        
        
        try{
        QuoteTriggerHandler_Common.AddRatingModifierFactor(null);
        }catch(exception exp){}
        
        
        Test.stopTest();
        
        List<CoveragesLineItem__c> lstCLI = [SELECT Id FROM CoveragesLineItem__c WHERE Quote__c =: quote.Id AND Coverage__c =: cov.Id];
        System.assertEquals(true, lstCLI.size() > 0);
    }
    
    @isTest static void testcleanupRMFAndCLI() {
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 prod = TestUtil.createProduct('Professional Indemnity');
        prod.RecordTypeId = aqueousRecordTypeId;
        prod.Innovisk_Entity_ID__c = 'Aqueous';
        insert prod;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, prod.Id);
        opportunity.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        opportunity.StageName = 'Qualified';
        opportunity.Main_Profession__c = 'Architects';
        opportunity.Innovisk_Entity_ID__c = 'Aqueous';
        insert opportunity;
        
        //Create coverage
        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'Professional Indemnity');
        cov.Coverage_Type__c = 'Endorsement';
        insert cov;
        
        
        
        //create limit deductables
        Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
        insert ded;
        
        Coverage_Matrix__c objCM = new Coverage_Matrix__c();
        objCM.Coverage__c = cov.Id;
        objCM.Coverage_Product__c = 'Professional Indemnity';
        objCM.IsActive__c = true;
        objCM.Unique_Identifier__c = 'CM_1';
        insert objCM;
        
        Coverage_Matrix_Rule__c objCMR = new Coverage_Matrix_Rule__c();
        objCMR.Coverage_Matrix__c = objCM.Id;
        objCMR.Field_API_Name__c = 'Main_Profession__c';
        objCMR.Field_Type__c = 'Text';
        objCMR.IsActive__c = true;
        objCMR.Object_API_Name__c = 'Opportunity';
        objCMR.Operat__c = 'in';
        objCMR.RecordTypeId = Schema.SObjectType.Coverage_Matrix_Rule__c.getRecordTypeInfosByName().get('Field Query').getRecordTypeId();
        objCMR.Rule_Type__c = 'Field Query';
        objCMR.Value__c = 'Architects;Engineers;Design & Construct';
        insert objCMR;
        
          Coverage__c cov1 = TestUtil.createCoverage('Coverage test', 'MPL');
          cov1.Coverage_Type__c = 'EndorSement';
          cov1.Additional_Requirements__c = 'Load by Default';
          cov1.Coverage_Product__c = 'Professional Indemnity';
          cov1.Product__c = prod.Id;
          insert cov1;
          
          Test.startTest();
          List<Quote> QuoteList = new List<Quote>();
          Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
          quote.Quote_Type__c='New Business';
          insert quote;
          QuoteList.add(quote);
          
        QuoteTriggerHandler_Common obj = New QuoteTriggerHandler_Common();
        try{
        QuoteTriggerHandler_Common.createPrimaryLocation(null);
        }catch(exception exp){}
        try{
      //  QuoteTriggerHandler_Common.updateCoverageLineItems(null,null);
        }catch(exception exp){}
        
        
        try{
            QuoteTriggerHandler_Common.AddRatingModifierFactor(null);
            QuoteTriggerHandler_Common.cleanupRMFAndCLI(QuoteList);
            QuoteTriggerHandler_Common.updateCoverageLineItems(QuoteList,null);
        }catch(exception exp){}
        
        
        Test.stopTest();
        
        //List<CoveragesLineItem__c> lstCLI = [SELECT Id FROM CoveragesLineItem__c WHERE Quote__c =: quote.Id AND Coverage__c =: cov.Id];
       // System.assertEquals(true, lstCLI.size() > 0);
    }
    
    @isTest static void testupdateCovLineItem() {
           Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
           Product2 prod = TestUtil.createProduct('Professional Indemnity');
           prod.RecordTypeId = aqueousRecordTypeId;
           prod.Innovisk_Entity_ID__c = 'Aqueous';
           insert prod;
           
           Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, prod.Id);
           opportunity.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
           opportunity.StageName = 'Qualified';
           opportunity.Main_Profession__c = 'Architects';
           opportunity.Innovisk_Entity_ID__c = 'Aqueous';
           insert opportunity;
           
           //Create coverage
           Coverage__c cov = TestUtil.createCoverage('Coverage test', 'Professional Indemnity');
           cov.Coverage_Type__c = 'Endorsement';
           insert cov;
           
           
           
           //create limit deductables
           Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
           insert ded;
           
           Coverage_Matrix__c objCM = new Coverage_Matrix__c();
           objCM.Coverage__c = cov.Id;
           objCM.Coverage_Product__c = 'Professional Indemnity';
           objCM.IsActive__c = true;
           objCM.Unique_Identifier__c = 'CM_1';
           insert objCM;
           
           Coverage_Matrix_Rule__c objCMR = new Coverage_Matrix_Rule__c();
           objCMR.Coverage_Matrix__c = objCM.Id;
           objCMR.Field_API_Name__c = 'Main_Profession__c';
           objCMR.Field_Type__c = 'Text';
           objCMR.IsActive__c = true;
           objCMR.Object_API_Name__c = 'Opportunity';
           objCMR.Operat__c = 'in';
           objCMR.RecordTypeId = Schema.SObjectType.Coverage_Matrix_Rule__c.getRecordTypeInfosByName().get('Field Query').getRecordTypeId();
           objCMR.Rule_Type__c = 'Field Query';
           objCMR.Value__c = 'Architects;Engineers;Design & Construct';
           insert objCMR;
           
           Coverage__c cov1 = TestUtil.createCoverage('Coverage test', 'MPL');
           cov1.Coverage_Type__c = 'EndorSement';
           cov1.Additional_Requirements__c = 'Load by Default';
           cov1.Coverage_Product__c = 'Professional Indemnity';
           cov1.Product__c = prod.Id;
           cov1.Apply_to_Quote__c = 'Primary';
           insert cov1;
           
         
          Test.startTest();
           List<Quote> QuoteList = new List<Quote>();
           Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
           quote.Quote_Type__c='New Business';
           quote.Coverage_Product_Options__c = 'Professional Indemnity';
           upsert quote;
           Map<Id,quote> oldmap = new Map<Id,Quote>();
           oldmap.put(quote.Id,quote);

                   
           Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
           acc.BillingStreet = acc.ShippingStreet;
           acc.BillingCity = acc.ShippingCity;
           acc.BillingState = acc.ShippingState;
           acc.BillingPostalCode = acc.ShippingPostalCode;
           acc.BillingCountry = acc.ShippingCountry;
           insert acc;
           
           Policy__c pol = new Policy__c();
           pol.Account__c = acc.Id;
           insert pol;
           
           quote.Name = 'test'; 
           quote.Coverage_Product_Options__c = 'Private Company Combo';
           quote.Status = 'Bound';
           quote.Policy__c = pol.Id;
           update quote;
                      
           QuoteList.add(quote);
           
           
        try{
          QuoteTriggerHandler_Common.updateCoverageLineItems(QuoteList,oldmap);
            QuoteTriggerHandler_Common.countOpenSubjectivityOnBoundQuote(QuoteList);

        }catch(exception exp){}
        
        
        Test.stopTest();
        
        //List<CoveragesLineItem__c> lstCLI = [SELECT Id FROM CoveragesLineItem__c WHERE Quote__c =: quote.Id AND Coverage__c =: cov.Id];
       // System.assertEquals(true, lstCLI.size() > 0);
    } 

}