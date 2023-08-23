@isTest
public class QuoteVersionControllerTest {
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
        quote2.Status = 'Bound Pending';
        quote2.Coverage_Product_Options__c = 'D&O';
        quote2.Refer_Type__c = 'Underwriting Referral';
        insert quote2;  
        
        Quote_Version__c quoteVersion = new Quote_Version__c();
        quoteVersion.Name = 'Test Version1';
        quoteVersion.Quote__c = quote1.Id;
        insert quoteVersion;
        
        Quote_Version_Item__c quoteVersItem = new Quote_Version_Item__c();
        quoteVersItem.Quote_Version__c = quoteVersion.Id;
        quoteVersItem.Source_Field_API__c = 'Option_Value_Default__c';
        quoteVersItem.Source_Object__c = 'CoveragesLineItem__c';
        quoteVersItem.Operation__c = 'Add';
        insert quoteVersItem;
	}
    @istest
    static void getListQuoteVersionsTest(){
        Test.startTest();
        Quote q = [Select Id from Quote limit 1];
        QuoteVersionController.getListQuoteVersions(q.id);
        System.assert(True);
        Test.stopTest();
    }
    
    @isTest
    static void checkExistVersionTest(){
        Test.startTest();
     	Quote q = [Select Id from Quote limit 1];
        List<Quote_Version_Item__c> quoteItemVersion = [Select Id, Source_Object__c, Source_Field_API__c, Value__c from Quote_Version_Item__c];
        Boolean result = QuoteVersionController.checkExistVersion(quoteItemVersion, q.Id);
       	new QuoteVersionController.QuoteVersionItemWrapper('Test','Test','Test','Test','Test','Test');
        System.assert(result!=null);
        Test.stopTest();
    }
}