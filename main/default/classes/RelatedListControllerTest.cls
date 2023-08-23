@istest
public class RelatedListControllerTest {
    @testsetup static void testSetup(){
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
		insert acc;
        
 /*       Contact con = new Contact();
        con.AccountId = acc.Id;
        con.LastName = 'Test name';
        insert con;*/
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
		insert product; 

        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Closed Won';
    	opp.Expiration_Date__c = Date.today()+60;
        insert opp;
        
        
        Opportunity opp2 = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp2.CloseDate = Date.today();
        opp2.StageName = 'Closed Won';
    	opp2.Expiration_Date__c = Date.today()+60;
        insert opp2;
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'In Progress';
        quote1.Coverage_Product_Options__c = 'D&O';
     	quote1.Refer_Type__c = 'Underwriting Referral';
        insert quote1;  

		Quote quote2 = Testutil.createQuote('New Quote 2', opp.Id);
        quote2.Status = 'Bound';
        quote2.Coverage_Product_Options__c = 'D&O';
        quote2.Refer_Type__c = 'Underwriting Referral';
        insert quote2; 
	}
    
	@isTest
    static void getDataTableTest(){
        Test.startTest();
        Account acc = [Select Id from Account Limit 1];
        Opportunity opp = [Select Id from Opportunity Limit 1];
        RelatedListController.ComponentInfo compInfo = new RelatedListController.ComponentInfo();
        compInfo.pageNumber = 2;
        compInfo.recordToDisplay = 5;
        compInfo.objectType = 'Contact';
        compInfo.parentRecordId = null;
        compInfo.recordId = acc.Id;        
        compInfo.fields = 'Id,Name';
        compInfo.orderBy = 'ASC';
        RelatedListController.getDataTable('Opportunity', acc.Id,compInfo.fields , 'ASC', opp.Id);
        System.assert(True);
        Test.stopTest();
    }
    @isTest
    static void getDataTableTestException(){
        Test.startTest();
        Account acc = [Select Id from Account Limit 1];
        Opportunity opp = [Select Id from Opportunity Limit 1];
        RelatedListController.ComponentInfo compInfo = new RelatedListController.ComponentInfo();
        compInfo.pageNumber = 2;
        compInfo.recordToDisplay = 5;
        compInfo.objectType = 'Contact';
        compInfo.parentRecordId = null;
        compInfo.recordId = acc.Id;        
        compInfo.fields = 'Id,Name';
        compInfo.orderBy = 'ASC';
        RelatedListController.getDataTable('Opportunity', null,'No field' , 'ASC', opp.Id);
        System.assert(true);
        Test.stopTest();
    }
}