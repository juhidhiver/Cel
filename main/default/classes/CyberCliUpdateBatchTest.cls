/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 07-01-2022
 * @last modified by  : Vinayesh
**/
@isTest
public class CyberCliUpdateBatchTest {	
    @testSetup
    public static void testSetup() {
        
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        Product2 product = TestUtil.createProduct('Cyber Standalone');
        product.IsActive = true;
        insert product; 
        
        List<Coverage__c> insertCoverageList1 = New List<Coverage__c>();

        Coverage__c cov9 = TestUtil.createCoverage('DataBreachLiability', 'Cyber');
        cov9.Coverage_Code__c = 'DataBreachLiability';
        insertCoverageList1.add(cov9);

        Coverage__c cov10 = TestUtil.createCoverage('CyberCrime', 'Cyber');
        cov10.Coverage_Code__c = 'CyberCrime';
        insertCoverageList1.add(cov10);

        Coverage__c cov11 = TestUtil.createCoverage('BIandExtraExpenses', 'Cyber');
        cov11.Coverage_Code__c = 'BIandExtraExpenses';
        insertCoverageList1.add(cov11);

        insert insertCoverageList1;

        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.Name = 'Test Opportunity';
        opp.CloseDate = Date.today()+10;
        opp.StageName = 'Qualified';
        opp.Effective_Date__c = Date.today();
        opp.Expiration_Date__c = Date.today()+120;
        opp.Azure_ID__c= 'Test Id';
        opp.Probability= 0.5;
        insert opp; 

        Quote quote = TestUtil.createQuote('Quote Test',opp.Id);
        quote.Azure_ID__c = 'Test Az 1';
        insert quote;

        CyberCoveragesTemp__c covPremiumData = new CyberCoveragesTemp__c();
        covPremiumData.QuoteId__c = 'Test Az 1';
        covPremiumData.ReferenceId__c = quote.Id;
        covPremiumData.RegDefenceAndPenaltiesQP__c = 10.546;
        covPremiumData.SocialEngineeringQP__c = 10.546;
        covPremiumData.CyberCrimeNP__c = 10.546;
        covPremiumData.DataBreachLiabilityNP__c = 10.546;
        covPremiumData.FundsTransferNP__c = 10.546;
        covPremiumData.BIandExtraExpensesQP__c = 10.546;
        covPremiumData.InsuredSystemFailureNP__c = 10.546;
        covPremiumData.InvoiceManipulationNP__c = 10.546;
        covPremiumData.InvoiceManipulationQP__c = 10.546;
        covPremiumData.PCIFinesAndAssessmentNP__c = 10.546;
        covPremiumData.CyberCrimeQP__c = 10.546;
        covPremiumData.InsuredSystemFailureQP__c = 10.546;
        covPremiumData.FundsTransferQP__c = 10.546;
        covPremiumData.OutsourceSystemFailureNP__c = 10.546;
        covPremiumData.RegDefenceAndPenaltiesNP__c = 10.546;
        covPremiumData.TelecomFraudQP__c = 10.546;
        covPremiumData.OutsourceSecurityFailureQP__c = 10.546;
        covPremiumData.OutsourceSecurityFailureNP__c = 10.546;
        covPremiumData.PCIFinesAndAssessmentQP__c = 10.546;
        covPremiumData.OutsourceSystemFailureQP__c = 10.546;
        covPremiumData.SocialEngineeringNP__c = 10.546;
        covPremiumData.TelecomFraudNP__c = 10.546;
        covPremiumData.BIandExtraExpensesNP__c = 10.546;
        covPremiumData.DataBreachLiabilityQP__c = 10.546;

        insert covPremiumData;

        List<Coverage__c> insertCoverageList = New List<Coverage__c>();
        //Create coverage
        Coverage__c cov = TestUtil.createCoverage('RegDefenceAndPenalties', 'Cyber');
        cov.Coverage_Code__c = 'RegDefenceAndPenalties';
        insertCoverageList.add(cov);
        
        Coverage__c cov1 = TestUtil.createCoverage('PCIFinesAndAssessment', 'Cyber');
        cov1.Coverage_Code__c = 'PCIFinesAndAssessment';
        insertCoverageList.add(cov1);

        Coverage__c cov2 = TestUtil.createCoverage('SocialEngineering', 'Cyber');
        cov2.Coverage_Code__c = 'SocialEngineering';
        insertCoverageList.add(cov2);

        Coverage__c cov3 = TestUtil.createCoverage('FundsTransfer', 'Cyber');
        cov3.Coverage_Code__c = 'FundsTransfer';
        insertCoverageList.add(cov3);

        Coverage__c cov4 = TestUtil.createCoverage('InvoiceManipulation', 'Cyber');
        cov4.Coverage_Code__c = 'InvoiceManipulation';
        insertCoverageList.add(cov4);

        Coverage__c cov5 = TestUtil.createCoverage('TelecomFraud', 'Cyber');
        cov5.Coverage_Code__c = 'TelecomFraud';
        insertCoverageList.add(cov5);

        Coverage__c cov6 = TestUtil.createCoverage('OutsourceSecurityFailure', 'Cyber');
        cov6.Coverage_Code__c = 'OutsourceSecurityFailure';
        insertCoverageList.add(cov6);

        Coverage__c cov7 = TestUtil.createCoverage('InsuredSystemFailure', 'Cyber');
        cov7.Coverage_Code__c = 'InsuredSystemFailure';
        insertCoverageList.add(cov7);

        Coverage__c cov8 = TestUtil.createCoverage('OutsourceSystemFailure', 'Cyber');
        cov8.Coverage_Code__c = 'OutsourceSystemFailure';
        insertCoverageList.add(cov8);



        insert insertCoverageList;    
    }
    @isTest static void cyberUpdateTest() {
        Coverage__c cov8 = TestUtil.createCoverage('TestCov', 'Cyber');
        cov8.Coverage_Code__c = 'teSTJSDKNFKSD';
        insert cov8;
        Quote quote1 = [Select Id From Quote];
        GlobalStaticVar.byPassCoverageLineItemTrigger = true;
        GlobalStaticVar.byPassQuoteTrigger = true;
        CoveragesLineItem__c cli1 = new CoveragesLineItem__c();
        cli1.Quote__c = quote1.Id;
        cli1.Coverage_Product__c = cov8.Coverage_Product__c;
        cli1.Coverage__c = cov8.Id;
        cli1.Option_Value_Default__c = 'Coverage';
        insert cli1;

        Test.startTest();
        CyberCliUpdateBatch cb = new CyberCliUpdateBatch();
        Id batchId = Database.executeBatch(cb, 10);
        Test.stopTest();
        //System.assertEquals(1, [select count() from Opportunity where Renewed__c = true]);
    }

    @isTest static void cliIsSelectedUpdateTest() {
        GlobalStaticVar.byPassQuoteTrigger = true;

        Opportunity opp = [Select Id from Opportunity limit 1];
        Quote qt = [Select Id from Quote limit 1];
        qt.Quote_Type__c = 'Renewal';
        update qt;
        Quote quote = TestUtil.createQuote('Quote Test1',opp.Id);
        quote.Azure_ID__c = 'Test Az 2';
        quote.Quote_Type__c = 'Amendment';
        insert quote;

        Coverage__c cov8 = TestUtil.createCoverage('TestCov', 'Cyber');
        cov8.Coverage_Code__c = 'OFAC';
        insert cov8;
        GlobalStaticVar.byPassCoverageLineItemTrigger = true;
        GlobalStaticVar.byPassQuoteTrigger = true;
        CoveragesLineItem__c cli1 = new CoveragesLineItem__c();
        cli1.Quote__c = quote.Id;
        cli1.Coverage_Product__c = cov8.Coverage_Product__c;
        cli1.Coverage__c = cov8.Id;
        cli1.Option_Value_Default__c = 'Coverage';
        insert cli1;

        Test.startTest();
        UpdateCliSelectedFieldBatch cb = new UpdateCliSelectedFieldBatch();
        Id batchId = Database.executeBatch(cb, 5);
        Test.stopTest();
        // Test.startTest();
        // UpdateCliSelectedFieldBatch cb = new UpdateCliSelectedFieldBatch();
        // Id batchId = Database.executeBatch(cb, 5);
        // Test.stopTest();
        //System.assertEquals(1, [select count() from Opportunity where Renewed__c = true]);
    }

    @isTest static void overallRatingFactorTest() {

         
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test1', 'Business', '1231 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;

        Product2 product1 = TestUtil.createProduct('Private Company Combo');
        insert product1;
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product1.Id);
        opp.Name = 'Test Opportunity1';
        opp.CloseDate = Date.today()+10;
        opp.StageName = 'Qualified';
        opp.Effective_Date__c = Date.today();
        opp.Expiration_Date__c = Date.today()+120;
        opp.Azure_ID__c= 'Test Id1';
        opp.Probability= 0.5;
        insert opp;

        Quote quote = TestUtil.createQuote('Quote Test',opp.Id);
        quote.Azure_ID__c = 'Test Az 2';
        quote.Status = 'Rated';
        insert quote;

        Test.startTest();
        OverallRatingFactorUpdateBatch cb = new OverallRatingFactorUpdateBatch();
        Id batchId = Database.executeBatch(cb, 3);
        Test.stopTest();
        //System.assertEquals(1, [select count() from Opportunity where Renewed__c = true]);
    }
}