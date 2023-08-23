@isTest
public class QuoteInitFormCmpControllertTest2 {
	@testsetup static void testSetup(){
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
		insert acc;
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
		insert product; 

        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Prospect';
        insert opp;
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'In Progress';
        quote1.Coverage_Product_Options__c = 'D&O';
     	quote1.Refer_Type__c = 'Underwriting Referral';
        insert quote1;     
    }
    @isTest
    static void getOpportunityInfoTest(){
        Test.startTest();
        Opportunity opp = [Select Id from Opportunity Limit 1];
        QuoteInitFormCmpController.getOpportunityInfo(opp.Id);
        Test.stopTest();
    }
    @isTest
    static void initializeTest(){
        Test.startTest();
        Opportunity opp = [Select Id from Opportunity Limit 1];
        QuoteInitFormCmpController.initialize(opp.Id);
        Test.stopTest();
    }
    @isTest
    static void initializeExceptionTest(){
        Test.startTest();
        Opportunity opp = [Select Id from Opportunity Limit 1];
        QuoteInitFormCmpController.initialize('');
        Test.stopTest();
    }
}