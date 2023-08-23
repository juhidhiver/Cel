@isTest
public class AccountLossDetailTriggerHandlerTest {
    
    @testSetup static void setup(){
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
        insert product; 
        
        // added by RINKU SAINI 28/12/2021
        List<Opportunity> oppList = New List<Opportunity>();
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Qualified';
        opp.AccountId=acc.Id;
        oppList.add(opp);
        
        // added by RINKU SAINI 28/12/2021
        Opportunity opp1 = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp1.CloseDate = Date.today();
        opp1.StageName = 'Qualified';
        opp1.AccountId=acc.Id;
        oppList.add(opp1);
        Insert oppList;
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'In Progress';
        quote1.Coverage_Product_Options__c = 'D&O';
        quote1.Refer_Type__c = 'Underwriting Referral';
        insert quote1;  
        
        Account_Loss_Detail__c accountLoss = new Account_Loss_Detail__c();
        accountLoss.Account__c = acc.Id;
        accountLoss.Product__c = 'Cyber';
        accountLoss.Loss_Amount__c = 123;
        accountLoss.Status__c = 'Open';
        accountLoss.Year__c = '2020';
        accountLoss.Number_of_Losses__c = 23;
        insert accountLoss;
        
    }
    
    @isTest
    static void TestMethod1(){
        Test.startTest();
        Account acc1 = [Select Id,Name from Account where Name ='Bussiness Account Test' limit 1];
        
        Account_Loss_Detail__c aloss1 = [Select Id,Loss_Amount__c,Account__c,Number_of_Losses__c,Product__c,Status__c,Year__c from Account_Loss_Detail__c limit 1];
        aloss1.Loss_Amount__c=2222;
        aloss1.Account__c=acc1.Id;
        update aloss1;
        
        Map<Id, Account_Loss_Detail__c> mloss = new Map<Id, Account_Loss_Detail__c>();
        mloss.put(aloss1.Id,aloss1);
        
        
        AccountLossDetailTriggerHandler.createSubmissionLossDetails(mloss);
        
        System.assertEquals(acc1.Id, aloss1.Account__c);
        Test.stopTest();
    }
}