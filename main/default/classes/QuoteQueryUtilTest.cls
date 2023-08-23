/**************************************************************************************************
* Class Name: QuoteQueryUtilTest
* Author: RINKU SAINI
* Date: Dec 24, 2021
* Description: 
**************************************************************************************************/
@isTest
public class QuoteQueryUtilTest {
    
    public static testmethod void testMethod1() {
        
        Test.startTest();
        
        //Create Account
        Account acc1 = new Account();
        acc1.Name = 'Test account 2';
        acc1.BillingStreet = '11 Tran Duy Hung';
        acc1.BillingCity = 'Westminster';
        acc1.BillingState = 'California';
        acc1.BillingPostalCode = '90000';
        acc1.BillingCountry = 'United States';
        //acc1.Billing_County__c;
        acc1.IsMailingSameWithBillingAddress__c = true;
        acc1.Date_Started__c = Date.today().addYears(-2);
        insert acc1;
        
        // Create contact
        Contact con = new Contact(
            Lastname = 'Test broker',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
        );
        insert con;
        
        Product2 product = TestUtil.createProduct('MPL Standalone');
        insert product; 
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc1.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Prospect';
        insert opp;
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'Bound';
        quote1.Rating_Status__c = 'Clear';
        quote1.Quote_Type__c = 'New Business';
        insert quote1; 
        
        Policy_Incremental_Setting__c pInSet = new Policy_Incremental_Setting__c();
        pInSet.Name = 'Test PIS';
        pInSet.Product_Name__c = 'MPL';
        pInSet.Policy_Format__c = '5DA3PL{0}';
        pInSet.Start_Number__c = '0000050';
        pInSet.End_Number__c = '0000998';
        pInSet.Active__c = true;
        pInSet.Suffix__c = '00';
        pInSet.Spacing__c = '-';
        insert pInSet;
        
        // create policy  
        Policy__c policy = new Policy__c();
        policy.Account__c = acc1.Id;
        policy.Product_Name__c = 'MPL';
        policy.Expiration_Date__c = Date.today().addDays(100);
        policy.Total_Premium__c = 2000;
        policy.Initial_Premium__c = null;
        insert policy;
        
        // create policy  
        Policy__c policy1 = new Policy__c();
        policy1.Account__c = acc1.Id;
        policy1.Product_Name__c = 'MPL';
        policy1.Expiration_Date__c = Date.today().addDays(100);
        policy1.Total_Premium__c = 2000;
        policy1.Initial_Premium__c = null;
        policy1.RecordTypeId = Schema.SObjectType.Policy__c.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
        insert policy1;
        update policy1;
        
        QuoteQueryUtil.fetchQuoteMapByOpportunity( New Set<Id>{quote1.Id},New List<String>{'Bound'});
        QuoteQueryUtil.fetchQuotesByOpportunties( New Set<Id>{opp.Id});
        QuoteQueryUtil.fetchQuotesForQuoteIds(new set<id>{quote1.Id},'Id');
        QuoteQueryUtil.fetchNonPIandPCCQuotes(new set<id>{quote1.Id});
        QuoteQueryUtil.fetchPIQuotedQuotes(New Set<Id>{opp.Id});
        QuoteQueryUtil.fetchActiveQuotesOfOpportunities(New Set<Id>{opp.Id});
        QuoteQueryUtil.fetchCyberMPLQuotesByQuoteIDs(new set<id>{quote1.Id});
        QuoteQueryUtil.fetchQuotesForOppsAndStatus(New Set<Id>{opp.Id},New Set<String>{'Bound'});
        QuoteQueryUtil.fetchOpenQuotesForOpps(New Set<Id>{opp.Id});
        QuoteQueryUtil.fetchOpenQuotesForOpps(opp.id, New List<String>{'Rated'});
        QuoteQueryUtil.fetchQuotesAndQuoteOprions(new List<id>{quote1.Id});
        QuoteQueryUtil.fetchQuoteById(quote1.Id);
        QuoteQueryUtil.fetchQuotesByOpportunty(opp.Id);
        QuoteQueryUtil.fetchQuoteWithPolicy(quote1.Id);
        QuoteQueryUtil.fetchExistingQuotesByOpportunty(opp.Id,quote1.Id);
        // Added By RINKU SAINI 11th Jan 2022
        QuoteQueryUtil.fetchQuoteInfo( New List<Quote>{quote1});
        System.assert(policy.Policy_Number__c == null);
        
        Test.stopTest();
    }
}