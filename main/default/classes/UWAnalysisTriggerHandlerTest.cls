/**************************************************************************************************
* Class Name: UWAnalysisTriggerHandlerTest
* Author: Ashik Zahir
* Created date: 06-April-2021
* Description: TriggerHandlerTest for UW_Analysis__c Object
**************************************************************************************************/
@isTest
public class UWAnalysisTriggerHandlerTest {
    
    @testSetup 
    static void createData(){
      
        Account acc = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 product = TestUtil.createProduct('Professional Indemnity');
        product.RecordTypeId = aqueousRecordTypeId; 
        product.Innovisk_Entity_ID__c = 'Aqueous';
        insert product;   
        
        String rdPolicyId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId(); 
        Policy__c policy = new Policy__c();
        policy.Account__c = acc.Id; 
        policy.Expiration_Date__c = Date.today().addDays(10);
        policy.Policy_Number__c = '12345';
        policy.Effective_Date__c = Date.today()+5;
        policy.Policy_Status__c = 'Bound';
        policy.Renewal_Completed__c = false;
        policy.Policy_Status__c = 'Active'; 
        insert policy;
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.StageName = 'Qualified'; 
        opp.Innovisk_Entity_ID__c = 'Aqueous';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();                            
        opp.Product__c = product.Id;
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        opp.Submission_Status__c = 'Quoted';
        opp.Transaction_Status__c = 'Active';
        opp.Azure_ID__c= 'Test Id';
        opp.Policy__c=policy.Id;
        opp.Probability= 0.5;
        insert opp;

        // By pass trigger to insert quote
        TriggerSettings__c settings = new TriggerSettings__c();
        settings.BypassQuoteTrigger__c = true;
        insert settings;
        System.assert(settings != null);
        
        //Quote
        List<Quote> lstQuote = new List<Quote>();
        Quote quote = TestUtil.createQuote('New Quote Test',opp.Id);
        quote.Coverage_Product_Options__c ='Professional Indemnity'; 
        quote.Status = 'In Progress';
        quote.Layer__c = 'Primary';
        quote.OpportunityId = opp.Id;
        quote.Policy__c = policy.Id;
        lstQuote.add(quote);
        Quote quote2 = TestUtil.createQuote('New Quote Test',opp.Id);
        quote2.Coverage_Product_Options__c ='Professional Indemnity'; 
        quote2.Status = 'Referred';
        quote2.Layer__c = 'Primary';
        quote2.OpportunityId = opp.Id;
        quote2.Policy__c = policy.Id;
        lstQuote.add(quote2);
        insert lstQuote;
        
    }

     @isTest
    static void testUwAnalysisTriggerHandler(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        UW_Analysis__c uwAnalysis = new UW_Analysis__c();
        uwAnalysis.Submission__c = opp.Id;
        uwAnalysis.UW_Analysis_Name__c = 'test';
        insert uwAnalysis;
       
        update uwAnalysis;
        
        delete uwAnalysis;
        Test.stopTest();
    }
}