/**************************************************************************************************
* Class Name: FreeFormEndorsementTriggerHandler
* Author: Ashik Zahir
* Created date: 06-April-2021
* Description: TriggerHandlerTest for Free_Form_Endorsements__c Object
**************************************************************************************************/
@isTest
public class FreeFormEndorsementTriggerHandlerTest {
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
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.StageName = 'Qualified'; 
        opp.Innovisk_Entity_ID__c = 'Aqueous';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();                            
        opp.Product__c = product.Id;
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        insert opp;
        
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
        
        // By pass trigger to insert quote
        TriggerSettings__c settings = new TriggerSettings__c();
        settings.BypassQuoteTrigger__c = true;
        insert settings;
        System.assert(settings != null);
        
        //Quote
        Quote quote = TestUtil.createQuote('New Quote Test',opp.Id);
        quote.Coverage_Product_Options__c ='Professional Indemnity'; 
        quote.Status = 'In Progress';
        quote.OpportunityId = opp.Id;
        insert quote;
        
        //quote.Endorsement_Type__c='New Business';
        update quote;
        
    }
    
    @isTest
    static void testFreeformEndorsement(){
        Test.startTest();
        Id quoteId = [Select Id from Quote Limit 1].Id;
        system.debug('quoteId '+quoteId);
        Free_Form_Endorsements__c free = new Free_Form_Endorsements__c();
        free.Quote__c = quoteId;
        insert free;
        
        free.Endorsement_Name__c = 'Free_Form_Endorsements';
        update free;
        
        System.assertEquals(1, [Select id from Free_Form_Endorsements__c Where Quote__c = :quoteId].size());
        
        //delete free;  
        Test.stopTest();
    }
}