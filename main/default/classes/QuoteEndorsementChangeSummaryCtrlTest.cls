@isTest
public class QuoteEndorsementChangeSummaryCtrlTest {
	@testsetup static void testSetup(){
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
		insert acc;
        
        Product2 product = TestUtil.createProduct('MPL Standalone');
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
        
    	Policy__c pol = new Policy__c();
    	pol.Policy_Number__c = '12345';
    	pol.Effective_Date__c = Date.today()+5;
    	pol.Expiration_Date__c = Date.today() + 30;
    	pol.Policy_Status__c = 'Bound';
    	insert pol;
    
    	Policy__c pol2 = new Policy__c();
    	pol2.Policy_Number__c = '123456';
    	pol2.Effective_Date__c = Date.today()+5;
    	pol2.Expiration_Date__c = Date.today() + 30;
    	pol2.Policy_Status__c = 'Bound';
    	insert pol2;
    
        
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'In Progress';
        quote1.Coverage_Product_Options__c = 'MPL';
     	quote1.Refer_Type__c = 'Underwriting Referral';
    	quote1.Policy__c = pol.Id;
        insert quote1;  

		Quote quote2 = Testutil.createQuote('New Quote 2', opp.Id);
        quote2.Status = 'In Progress';
        quote2.Coverage_Product_Options__c = 'MPL';
        quote2.Refer_Type__c = 'Underwriting Referral';
    	quote2.Policy__c = pol2.Id;
        quote2.QuotePremium__c = 222200;
        quote2.Parent_Quote__c = quote1.Id;
        insert quote2;  

        Additional_Interests__c addInt = new Additional_Interests__c();
        addInt.Quote__c = quote2.Id;
        addInt.Loss_Payee_Interest__c = 'Structure';
        addInt.Loan_Reference_number__c = 'Test Add int000';
        addInt.Additional_Interest_Account__c = acc.Id;
        insert addInt;
        
	}
    @isTest
    static void getQuoteEndorsementChangeSummaryTest(){
        Test.startTest();
        Quote q = [Select Id from Quote where name ='New Quote 2'];
        QuoteEndorsementChangeSummaryCtrl.getQuoteEndorsementChangeSummary(q.id, True);
        Test.stopTest();
    } 
     @isTest
    static void getQuoteEndorsementChangeSummaryTest2(){
        Test.startTest();
        QuoteEndorsementChangeSummaryCtrl.getQuoteEndorsementChangeSummary('', True);
        Test.stopTest();
    } 
    
    @isTest
    public static void testCompareQuote() {
        Test.startTest();
        Quote oldQuote = [SELECT id FROM Quote WHERE Name = 'New quote 1'];
        Quote newQuote = [Select Id from Quote where name ='New Quote 2'];
        //QuoteEndorsementChangeSummaryCtrl.compareQuote(oldQuote, newQuote);
        Test.stopTest();
    }
   /*isTest
    static void getCoverageLineItemAllForProductTest(){
        Test.startTest();
        Quote q = [Select Id from Quote Limit 1];
		QuoteEndorsementChangeSummaryCtrl.getCoverageLineItemAllForProduct(q.Id);
        Test.stopTest();
    }*/

}