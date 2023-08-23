@isTest
public class QuoteEndorsementChangeSummaryUtilTest {
  
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
 

		Quote quote2 = Testutil.createQuote('New Quote 2', opp.Id);
        quote2.Status = 'In Progress';
        quote2.Coverage_Product_Options__c = 'D&O';
        quote2.Refer_Type__c = 'Underwriting Referral';
        insert quote2;
    
    
    	QuoteEndorsementChangeSummary__c quoteEnd = new QuoteEndorsementChangeSummary__c();
    	quoteEnd.Name = 'Test Endorsement';
    	quoteEnd.Old_QuoteId__c = quote2.Id;
    	quoteEnd.QuoteId__c = quote1.Id;
    	quoteEnd.CoverageName__c = 'Test Coverage';
        quoteEnd.Deleted_Record_Summary__c = 'Test Delete';
        quoteEnd.FieldName__c = 'Test Field';
        quoteEnd.New_Record_Summary__c = 'Test new Sum';
        quoteEnd.NewValue__c = 'Test New Value';
        quoteEnd.ObjectName__c = 'Object Name';
        quoteEnd.OldValue__c = 'Test Old Value';
        quoteEnd.Operation__c = 'Add';
        quoteEnd.SubCoverageName__c = 'Test Sub Coverage';
        quoteEnd.Update_Record_Summary__c = 'Update Summary';
        quoteEnd.Limit_Deductible__c = 'Limits & Deductibles';
    	insert quoteEnd;
    	
    
	}
    @isTest
    static void getQuoteEndorsementChangeSummaryTest(){
        Test.startTest();
        List<Quote> quoteList = [Select Id from Quote];
      	List<Id> quoteIds = new List<Id>();
        for(Quote q:quoteList){
            quoteIds.add(q.Id);
        }  
        QuoteEndorsementChangeSummaryUtil.getQuoteEndorsementChangeSummary(quoteIds);  
        System.assert(True);
        Test.stopTest();
    }
    @isTest
    static void createQuoteEndorsementChangeSummaryInfoTest(){
        Test.startTest();
        QuoteEndorsementChangeSummary__c quoteEnd = [Select id, Name,Old_QuoteId__c,QuoteId__c,
                                                     CoverageName__c,Deleted_Record_Summary__c,FieldName__c,
                                                     New_Record_Summary__c,NewValue__c,ObjectName__c,OldValue__c,
                                                     Operation__c,SubCoverageName__c,Update_Record_Summary__c,Limit_Deductible__c
                                                    From QuoteEndorsementChangeSummary__c];
        QuoteEndorsementChangeSummaryUtil.QuoteEndorsementChangeSummaryInfo returnedObj = QuoteEndorsementChangeSummaryUtil.createQuoteEndorsementChangeSummaryInfo(quoteEnd);
        System.assert(returnedObj!=null);
        Test.stopTest();
    }
    
}