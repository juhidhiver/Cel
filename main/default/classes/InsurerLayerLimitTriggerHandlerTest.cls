/**************************************************************************************************
* Class Name: InsurerLayerLimitTriggerHandlerTest
* Author: Ashik Zahir
* Created date: 15-April-2021
* Description: TriggerHandlerTest for InsurerLayerLimit__c Object
**************************************************************************************************/
@isTest
public class InsurerLayerLimitTriggerHandlerTest {

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
        static void testFInsurerLayerLimit(){
        Test.startTest();
        Id quoteId = [Select Id from Quote Limit 1].Id;
        
        Insurer_Layer_Limit__c insurerLimit = new Insurer_Layer_Limit__c();
    	insurerLimit.Quote__c = quoteId;
        insert insurerLimit;
            
         insurerLimit.Insurer__c = 'Insurer';
         update insurerLimit;

        System.assertEquals(1, [Select id from Insurer_Layer_Limit__c Where Quote__c = :quoteId].size());
        delete insurerLimit;
         
        Test.stopTest();
    }
}