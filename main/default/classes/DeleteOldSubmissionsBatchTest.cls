@isTest
public with sharing class DeleteOldSubmissionsBatchTest {
    @TestSetup
    static void makeData(){
        
        // Account Business
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
		insert acc;
		
		Product2 product = TestUtil.createProduct('Cyber');
		insert product; 

        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        insert opp;

        Rating_Modifiers__c testRatingModifier =  TestUtil.createRatingModifier('testRatingModifier', product.Name , opp.Id);
        insert testRatingModifier;
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'In Progress';
        quote1.Coverage_Product_Options__c = 'Cyber';
        insert quote1;

        Coverage__c testCoverrage = TestUtil.createCoverage('test coverrage', product.Name);
        insert testCoverrage;

        Coverage_Limits_Deductibles__c testDeductible = TestUtil.creatLimitsDeductibles('testDeductible', testCoverrage.Id);
        insert testDeductible;

        CoveragesLineItem__c coverLineItem =  TestUtil.createCoverageLineItem(quote1.Id, testDeductible.Id, 
        testCoverrage.Id , 'SubCoverage' );
        insert coverLineItem;

        Quote quote2 = TestUtil.createQuote('New quote 2', opp.Id);
        quote2.Status = 'Rated';
        quote2.Coverage_Product_Options__c = 'MPL';
        insert quote2;
        
    }
    @isTest
    static void testRunBatch() {
        Test.startTest();
        DeleteOldSubmissionsBatch b = new DeleteOldSubmissionsBatch(-1);
        DataBase.executeBatch(b);
        Test.stopTest();
        Date dToday = System.Today();
        Datetime dt = datetime.newInstance(dToday.year(), dToday.month(),dToday.day());
        List<Opportunity> opps = [Select Id, createdDate From Opportunity];
        System.debug('=====opps: ' + opps);
        List<Quote> quote = [Select Id, OpportunityId From Quote];
        System.debug('=====quote: ' + quote);
        List<Rating_Modifiers__c> lstRating = [Select Id, Opportunity__c, createdDate From Rating_Modifiers__c];
        System.debug('=====lstRating: ' + lstRating);
        List<CoveragesLineItem__c> lstCoverrageItems = [Select Id, Quote__c, createdDate From CoveragesLineItem__c];
        System.debug('=====lstCoverrageItems: ' + lstCoverrageItems);
        system.assertEquals(true, opps.isEmpty());
        system.assertEquals(true, quote.isEmpty());
        system.assertEquals(true, lstRating.isEmpty());
        system.assertEquals(true, lstCoverrageItems.isEmpty());
        
    }
}