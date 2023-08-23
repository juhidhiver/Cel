@isTest
public class QuoteProcessTriggerHandlerTest {
    
    @testsetup static void testSetup(){
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
        insert product; 
        
        Product2 Cyber_prod = TestUtil.createProduct('Cyber');
        insert Cyber_prod;
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Prospect';
        insert opp;
        
        Opportunity opp3 = TestUtil.createOpportunity('Opp Test',acc.Id, Cyber_prod.Id);
        opp3.CloseDate = Date.today();
        opp3.StageName = 'Prospect';
        insert opp3;
        
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
        
        Quote_Process__c quoteProcess = new Quote_Process__c();
        quoteProcess.Account__c = acc.Id;
        quoteProcess.Submission__c = opp.Id;
        quoteProcess.Name = 'Test Quote Process';
        insert quoteProcess;  
        
        Quote_Process__c quoteProcess2 = new Quote_Process__c();
        quoteProcess2.Account__c = acc.Id;
        quoteProcess2.Submission__c = opp3.Id;
        quoteProcess2.Name = 'Test Quote Process';
        insert quoteProcess2;  
        
        //Inserting Another Opportunity
        Account acc2 = TestUtil.createBusinessAccount('Test Business Account', 'Business', '123 Main Street', 'Test City', 'New York', '11354', 'United States');
        insert acc2;
        
        Product2 Prod = TestUtil.createProduct('test Prod');
        insert Prod;
        
        Opportunity opp2 = TestUtil.createOpportunity('Test Opp',acc2.Id, Prod.Id);
        opp2.CloseDate = Date.today();
        opp2.StageName = 'Prospect';
        insert opp2;
        
        Quote quote3 = TestUtil.createQuote('New quote 3', opp2.Id);
        quote3.Status = 'In Progress';
        quote3.Coverage_Product_Options__c = 'D&O';
        quote3.Refer_Type__c = 'Underwriting Referral';
        insert quote3;  
        
    }
    @isTest
    static void updateQuoteProcessTestforBeforeUpdate(){
        Test.startTest(); 
        
        //added by RINKU SAINI 4th Dec 2022
        Account acc2 = TestUtil.createBusinessAccount('Test Business Account', 'Business', '123 Main Street', 'Test City', 'New York', '11354', 'United States');
        insert acc2;
        //added by RINKU SAINI 4th Dec 2022
        Product2 Prod = TestUtil.createProduct('test Prod');
        insert Prod;
        //added by RINKU SAINI 4th Dec 2022
        Opportunity opp3 = TestUtil.createOpportunity('Test Opp',acc2.Id, Prod.Id);
        opp3.CloseDate = Date.today();
        opp3.StageName = 'Prospect';
        insert opp3;
        
        Quote_Process__c quoteProc = [Select Id from Quote_Process__c Limit 1];
        quoteProc.Name = 'Update Quote Process Name'; 
        //added by RINKU SAINI 4th Dec 2022
        quoteProc.Submission__c = opp3.Id;
        
        update quoteProc;
        System.assert(True);
        Test.stopTest();
    }
    
    @isTest
    static void updateQuoteProcessTestforBeforeUpdate_CEL(){
        Test.startTest();       
        Quote_Process__c quoteProc = [Select Id from Quote_Process__c where Submission__r.Product__r.Name = 'Cyber' Limit 1];
        quoteProc.Name = 'Update Quote Process Name'; 
        update quoteProc;
        Test.stopTest();
    }
    
    @isTest
    static void updateQuoteProcessSubmission(){    
        Quote_Process__c quoteProc = [Select Id,Submission__c from Quote_Process__c Limit 1];
        List<Opportunity> submissions = [Select Id from Opportunity where Id !=: quoteProc.Submission__c];
        if(!submissions.isEmpty()){
            Test.startTest();
            quoteProc.Submission__c = submissions[0].Id; 
            update quoteProc;
            Test.stopTest();
        }
    }
    
    static void updateQuoteProcessTestforAfterUpdate(){
        Test.startTest();       
        Quote_Process__c quoteProc = [Select Id from Quote_Process__c Limit 1];
        Account acc = [Select Id from Account where Name = 'Test Business Account'];
        Opportunity opp = [Select Id, AccountId from Opportunity where AccountId=:acc.Id];
        quoteProc.Name = 'Update Quote Process Name'; 
        quoteProc.Account__c = acc.Id;
        quoteProc.Submission__c = opp.Id;
        update quoteProc;
        System.assert(True);
        Test.stopTest();
    }
}