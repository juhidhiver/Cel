@isTest
public class FactorSummaryControllerTest {
    @testsetup static void testSetup(){
        
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account acc  =TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster',
                                             'California','90000', 'United States');
        acc.Azure_ID__c = '8042ac98-ae5a-4692-9880-58d92d0eb9d9';
        insert acc;
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
        insert product; 
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today()+365;
        opp.StageName = 'New';
        opp.Azure_ID__c = 'f70e4c82-3378-41ce-870b-57f4df415874';
        insert opp;
        
        Opportunity opp1 = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp1.CloseDate = Date.today()+365;
        opp1.StageName = 'New';
        opp1.Azure_ID__c = 'f70e4c82-3378-41ce-870b-57f4df415875';
        opp1.Parent_Opportunity__c=opp.Id;
        insert opp1;
        
        
        TriggerSettings__c setting = new TriggerSettings__c();
        setting.BypassQuoteTrigger__c = true;
        insert setting;
        
        Quote quote1 = TestUtil.createQuote('New quote 2', opp1.Id);
        quote1.Status = 'Bound';
        quote1.Coverage_Product_Options__c = 'D&O';
        quote1.Quote_Type__c = 'New Business';
        quote1.Refer_Type__c = 'Underwriting Referral';
        insert quote1; 
        
        Quote quote = TestUtil.createQuote('New quote 1', opp1.Id);
        quote.Status = 'In Progress';
        quote.Coverage_Product_Options__c = 'D&O';
        quote.Quote_Type__c = 'New Business';
        quote.Refer_Type__c = 'Underwriting Referral';
        quote.Parent_Quote__c = quote1.Id;
        insert quote; 
        
        Factor_Summary__c fac = new Factor_Summary__c();
        fac.Code__c = '1';
        fac.Quote__c = quote.Id;
        insert fac;
        
        Factor_Summary_Template__c facTem = new Factor_Summary_Template__c();
        facTem.Active__c = true;
        facTem.Code__c = '1';
        facTem.Sort_Order__c = 1;
        insert facTem;
        
        Quote_Option__c quoteOptionObj = new Quote_Option__c();
        quoteOptionObj.Quote__c = quote1.Id;
        quoteOptionObj.Option_Type__c = 'Fixed Limit';
        quoteOptionObj.Selected__c = true;
        insert quoteOptionObj;
        
        FactorSummaryController.FactorSummaryComparisonWrapper fact = new FactorSummaryController.FactorSummaryComparisonWrapper();
        fact.currentValue = 'Test';
        fact.priorValue ='Qwerty';
        fact.sortOrder = 22.0;
        fact.name = 'Bindas';
        
    }
    @isTest
    public static void getFactorSummarysTest(){
        Test.startTest();
        Quote quote =[SELECT id,Status from Quote where Parent_Quote__c !=null limit 1];
        FactorSummaryController.getFactorSummarys(quote.Id);
        Test.stopTest();
        system.assertEquals( 'In Progress', quote.Status); 
        //FactorSummaryController.FactorSummaryComparisonWrapper('Test','qwerty','abcd',21.0);
    }
    @isTest
    public static void getFactorSummarysTest1(){
        Test.startTest();
        Quote quote =[SELECT id,Parent_Quote__c,Status from Quote limit 1];
        Opportunity opp = [SELECT id,StageName,Parent_Opportunity__c from  Opportunity limit 1 ];
        
        quote.Parent_Quote__c = null;
        update quote;
        FactorSummaryController.getFactorSummarys(quote.Id);
        Test.stopTest();
        system.assertEquals( 'New', opp.StageName); 
        
    }
    
    @isTest
    public static void runTest(){
        
        Test.startTest();
        Quote quote =[SELECT id,Status from Quote where Parent_Quote__c = null AND Opportunity.Parent_Opportunity__c != null AND Name = 'New quote 2'];
        quote.Status = 'Bound';
        update quote;
        Quote_Option__c quoteOption = [SELECT id from Quote_Option__c where Quote__c =: quote.id];     
        quoteOption.Bound__c = true;
        update quoteOption;
        FactorSummaryController.getFactorSummarysQC(quoteOption.Id);
        Test.stopTest();
        
    }
    
}