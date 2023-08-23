@isTest
public class DocumentRevisionTriggerHandlerTest {
@testsetup static void testSetup(){
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
		insert acc;
        
        Product2 product = TestUtil.createProduct('MPL Standalone');
		insert product; 

        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Prospect';
        insert opp;
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'Quoted';
        quote1.Rating_Status__c = 'Clear';
      //  quote1.Coverage_Product_Options__c = 'D&O';
        quote1.Quote_Type__c = 'New Business';
     //	quote1.Refer_Type__c = 'Underwriting Referral';
        insert quote1; 
        //Data for get Request
		
     /*   //Create coverage
		List<Coverage__c> lCov = new List<Coverage__c>();
		Coverage__c cov = TestUtil.createCoverage('Coverage test', 'D&O');
        cov.Coverage_Product__c = 'D&O';
		lCov.add(cov);
		Coverage__c cov1 = TestUtil.createCoverage('Coverage test', 'MPL');
		lCov.add(cov1);
		insert lCov;
        
        //create limit deductables
		Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
        insert ded;

        Quote quote = TestUtil.createQuote('New Quote Test',opp.Id);
		quote.Coverage_Product_Options__c ='D&O;MPL';       
		insert quote;
        
        quote.Status = 'Rated';
        update quote;
        
         // Coverages Line Item
        CoveragesLineItem__c coverLi = new CoveragesLineItem__c();
        coverLi.Coverage__c  = cov.Id; 
        coverLi.Quote__c = quote.Id;
        coverLi.Coverage_Premium__c  = 'Text Premium'; 
        coverLi.Min_amt__c  = 1000;
        coverLi.Max_amt__c  = 5000;
        coverLi.Deductible_Frequency__c  = 'Daily';
        coverLi.Options_Value_Percent__c  = 5;
        insert coverLi; */
        
    }
    
     @isTest
    static void postRequest(){
        
        Quote quote = [Select id, Azure_Id__c from Quote where Name = 'New quote 1'];
        
        Document_Revision__c lstDocumentRevision  = new Document_Revision__c(
        Name = 'QuoteProposal',
        Document_Azure_Id__c = '1',
        Document_Type__c = 'QuoteProposal',
        Quote_Id__c =quote.Id
        );
        Test.startTest();
		insert lstDocumentRevision;
        update lstDocumentRevision;
        Test.stopTest();
        System.assertEquals('QuoteProposal', lstDocumentRevision.Document_Type__c);
    }
}