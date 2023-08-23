/**************************************************************************************************
 * Class Name: CloseOpportunityBatchTest
 * Author: Hoang Bui
 * Date: 21-Oct-2019
 * Description: CloseOpportunityBatchTest Test
 **************************************************************************************************/
@isTest
private class CloseOpportunityBatchTest {
    static {
    	TriggerSettings__c setting = TestUtil.initialTriggerSetting();
		setting.BypassOpportunityTrigger__c = false;
		update setting;

        // Account Business
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
		insert acc;
		
		Product2 product = TestUtil.createProduct('D&O Standalone');
		insert product; 

        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
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
    static void testRunBatch() {
        Test.startTest();
        String cronExpr = '0 0 0 15 3 ? 2022';
        CloseOpportunityBatchScheduleble cloOppSch = new CloseOpportunityBatchScheduleble();
        System.schedule('Close Opp',cronExpr,cloOppSch);
        Test.stopTest();
        List<Opportunity> opps = [Select Id From Opportunity where StageName = 'Closed' and CloseDate = TODAY];
		system.assertEquals(true, opps.isEmpty());
    }
}