/**************************************************************************************************
* Class Name: SubjectivityTriggerTest
* Author: Sarthak Roy
* Created date: 22-Dec-2020
* Description: Test Trigger for Subjectivity__c Object
**************************************************************************************************/
@isTest
public class SubjectivityTriggerTest {
    @testSetup 
    static void createData(){
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        Product2 product = TestUtil.createProduct('D&O');
        insert product;   
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        opportunity.Coverage_Product_Options__c = 'D&O;MPL';
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
        
        Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote.Coverage_Product_Options__c ='D&O;MPL';       
        insert quote;
        
        quote.Status = 'Rated';
        update quote;
    }
    
    @isTest
    static void testSubjectivity(){
        Id quoteId = [Select Id from Quote Limit 1].Id;
        Subjectivity__c sub = new Subjectivity__c();
        sub.Quote__c = quoteId;
        insert sub;
        
        sub.Subjectivity_Status__c = 'Completed';
        update sub;
        
        delete sub;
        System.assertEquals(0, [Select id from Subjectivity__c Where Quote__c = :quoteId].size());   
    }
}