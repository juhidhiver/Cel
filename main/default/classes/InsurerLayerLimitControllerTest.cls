@isTest
public class InsurerLayerLimitControllerTest {
	@testSetup 
    static void createData(){
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        Product2 product = TestUtil.createProduct('AQ');
        insert product;   
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        opportunity.Coverage_Product_Options__c = 'D&O;MPL';
        insert opportunity;
        
        Subjectivity_Template__c subjectivityTemplate = new Subjectivity_Template__c();
        subjectivityTemplate.Subjectivity_Name__c = 'Signed / Dated Proposal';
        subjectivityTemplate.Subjectivity_Text__c = 'Test';
        subjectivityTemplate.Profession_Criteria__c = 'Engineers';
        insert subjectivityTemplate;
        
        Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote.Coverage_Product_Options__c ='D&O;MPL';   
        insert quote;
        
        quote.Status = 'Quoted';
        update quote;
    }
    
    @isTest
    static void fetchInsurerLimitTest(){
        Test.startTest();
        List<Quote> quotes = [Select Id from Quote];
        decimal totalUnderlyingLayer = InsurerLayerLimitController.fetchInsurerLimit(quotes[0].Id);
        Test.stopTest(); 
        System.assertEquals(0, totalUnderlyingLayer);
    }
    
    @isTest
    static void getInsurerLayerTest(){
        Test.startTest();
        List<Quote> quotes = [Select Id from Quote];
        List<Insurer_Layer_Limit__c> insurerList= InsurerLayerLimitController.getInsurerLayer(quotes[0].Id);
        Test.stopTest();    
        System.assert(insurerList != null);
    }
    
    @isTest
    static void saveAndDeleteInsurerLayerTest(){
        Test.startTest();
        List<Quote> quotes = [Select Id from Quote];
        List<Insurer_Layer_Limit__c> insurerList = new List<Insurer_Layer_Limit__c>();
        Insurer_Layer_Limit__c insurerLayerLimit = new Insurer_Layer_Limit__c();
            insurerLayerLimit.Quote__c = quotes[0].Id;
            insurerLayerLimit.Layer__c = 'Test';
            insurerLayerLimit.CurrencyIsoCode = 'GBP';
        insurerList.add(insurerLayerLimit);
        InsurerLayerLimitController.saveInsurerLayer(insurerList);
        InsurerLayerLimitController.saveInsurerLayer(insurerList);
        InsurerLayerLimitController.deleteInsurer(insurerList[0].Id);
        Test.stopTest(); 
        System.assert(insurerList != null);
    }
}