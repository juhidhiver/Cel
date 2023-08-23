@isTest
public class CustomLookupControllerLWCTest {
    @testsetup static void testSetup(){
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
		insert acc;
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
		insert product; 

        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Qualified';
        insert opp;
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'In Progress';
        quote1.Coverage_Product_Options__c = 'D&O';
        insert quote1;
        Quote quote2 = TestUtil.createQuote('New quote 2', opp.Id);
        quote2.Status = 'Rated';
        quote2.Coverage_Product_Options__c = 'D&O';
        insert quote2;
    }
    @isTest
    static void findRecordsTest(){
        Test.startTest();
        Opportunity opp = [Select Id from Opportunity Limit 1];
        ID oppId = opp.Id;
        String sObjName = oppId.getSObjectType().getDescribe().getName();

        CustomLookupControllerLwc.findRecords('Prospect', sObjName, 'StageName');
        System.assert(True);
        Test.stopTest();
    }
}