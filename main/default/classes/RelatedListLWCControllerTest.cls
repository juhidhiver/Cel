@isTest
public class RelatedListLWCControllerTest {
	@testsetup static void testSetup(){
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
		insert acc;
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
		insert product; 

        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Closed Won';
    	opp.Expiration_Date__c = Date.today()+60;
        insert opp;
        
        
        Opportunity opp2 = TestUtil.createOpportunity('Opp Test2',acc.Id, product.Id);
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
    static void getOpportunityListTest(){
        Test.startTest();
        Account acc = [Select Id from Account Limit 1];
        List<Opportunity> lstOfOpps = RelatedListLWCController.getOpportunityList(acc.Id);
        System.assert(!lstOfOpps.isEmpty());
        Test.stopTest();        
    }
    @isTest
    static void deleteOpportunityTestExcep(){
        Test.startTest();
        
        
        List<Id> oppIds = new List<id>();
        RelatedListLWCController.deleteOpportunity(oppIds);
        Test.stopTest();
    }
     @isTest
    static void deleteOpportunityTest(){
        Test.startTest();
        
        
        List<Id> oppIds = new List<id>();
        for(Opportunity opp : [Select Id from Opportunity]){
            oppIds.add(opp.Id);
        }
        RelatedListLWCController.deleteOpportunity(oppIds);
        Test.stopTest();
    }
    
    @isTest
    static void getDataTableTest(){
        Test.startTest();
        Account acc = [Select Id from Account Limit 1];
        Opportunity opp = [Select Id from Opportunity Limit 1];
        
        String json ='{"pageNumber":2,"recordToDisplay":2,"objectType":"Opportunity","parentRecordId":"'+acc.Id+'","recordId":"'+opp.Id+'","fields":"Id","orderBy":""}';
        RelatedListLWCController.getDataTable(json);
        Test.stopTest();
    }
    @isTest
    static void getDataTableTestforExcep(){
        Test.startTest();
        Account acc = [Select Id from Account Limit 1];
        Opportunity opp = [Select Id from Opportunity Limit 1];
        
        String json ='{"pageNumber":2,"recordToDisplay":2,"objectType":"Opportunity","parentRecordId":"'+acc.Id+'","recordId":"'+opp.Id+'","fields":"Id","orderBy":""}';
        RelatedListLWCController.getDataTable('');
        Test.stopTest();
    }
        @isTest
    static void getDataTableTestforNullValues(){
        Test.startTest();
        Account acc = [Select Id from Account Limit 1];
        Opportunity opp = [Select Id from Opportunity Limit 1];
        
        String json ='{"pageNumber":2,"recordToDisplay":2,"objectType":"Opportunity","parentRecordId":"","recordId":"'+opp.Id+'","fields":"","orderBy":""}';
        RelatedListLWCController.getDataTable(json);
        Test.stopTest();
    }
    @isTest
    static void initialiseComponentInfo(){
        Test.startTest();
        try{
  			RelatedListLWCController.ComponentInfo obj = new RelatedListLWCController.ComponentInfo();
            obj.pageNumber = 0;
            obj.recordToDisplay = 0;
            obj.objectType = '';
            obj.parentRecordId = '';
            obj.recordId = null;
            obj.fields = 'Id, Name';
            obj.orderBy = 'DESC';
        }
        catch(Exception ex){
            
        }
        Test.stopTest();
    }
}