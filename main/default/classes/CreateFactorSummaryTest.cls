/**************************************************************************************************
* Class Name: CreateFactorSummary
* Author: Namana K G
* Created date: 05-May-2021
* Description: CreateFactorSummaryTest Class
**************************************************************************************************/
@isTest
public class CreateFactorSummaryTest {
    @testSetup
    public static void setupData() {
        Product2 product = TestUtil.createProduct('D&O');
        insert product;
        
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        insert opportunity;
        
        Subjectivity_Template__c  subjectivityTemplate = new Subjectivity_Template__c();
        subjectivityTemplate.Subjectivity_Name__c = 'Signed / Dated Proposal';
        subjectivityTemplate.Subjectivity_Text__c  = 'Test';
        subjectivityTemplate.Profession_Criteria__c = 'Engineers';
        insert subjectivityTemplate;
        
        Quote quote = TestUtil.createQuote('Quote Test',opportunity.Id);
        quote.Azure_ID__c = 'Test Az 1';
        upsert quote;
        
        Quote ratedQuote = TestUtil.createQuote('Rated Quote Test',opportunity.Id);
        //ratedQuote.Status = 'Rated';
        ratedQuote.Status = 'IN PROGRESS';
        ratedQuote.Azure_ID__c = 'Test Az 2';
        insert ratedQuote;
        
        Coverage__c cov = Testutil.createCoverage('Coverage 1', 'D&O');
        insert cov;
        
        Coverage_Limits_Deductibles__c covLD = TestUtil.creatLimitsDeductibles('test LD', cov.id);
        insert covLD;
        
        CoveragesLineItem__c covLineItem = testUtil.createCoverageLineItem(ratedQuote.id, covLD.id, cov.Id, 'Picklist');
        covLineItem.Azure_ID__c = '61b1c13d-24a5-4181-8ccc-d3929c1b4edd';
        covLineItem.Coverage_Product__c = 'D&O';
        insert covLineItem;
        
        Rating_Modifiers__c rateMod = TestUtil.createRatingModifier('Test Rat Modifier', 'MPL', opportunity.id);
        rateMod.Azure_ID__c = 'Test ID Azure';
        rateMod.Rating_Modifier_Code__c = 'Cyber000156';
        insert rateMod;
        
        Rating_Modifier_Factor__c rm = new Rating_Modifier_Factor__c();
        rm.Factor_Default_Value__c = 123;
        rm.Factor_Max__c = 300;
        rm.Factor_Min__c = 100;
        rm.Factor_Value__c = 120;
        rm.Rating_Modifier__c = rateMod.Id;
        rm.Quote__c = quote.Id;    
        insert rm; 
        
        Factor_Summary__c fac = new Factor_Summary__c();
        fac.Code__c = '1';
        fac.Quote__c = quote.Id;
        insert fac;
        
        
    }  
    
    @isTest
    public static void createNewFactorSummaryTest () {
        Quote quote = [SELECT Id FROM Quote limit 1];
        List<Factor_Summary__c> fsList = new List<Factor_Summary__c>();
        List<Factor_Summary__c> fsListQC = new List<Factor_Summary__c>();
        Map<String, List<Factor_Summary__c>> mapOfOptionIdVsListOfFactorSummary = new Map<String, List<Factor_Summary__c>>();
        
        Quote_Option__c quoteOption = new Quote_Option__c();
        quoteOption.Actual_Premium__c = 181;
        quoteOption.Quote__c = quote.Id;
        insert quoteOption;
            
        Factor_Summary__c fac = new Factor_Summary__c();
        fac.Code__c = 'Rate';
        fac.Quote__c = quote.Id;
        fsList.add(fac);
        
        Factor_Summary__c facQC = new Factor_Summary__c();
        facQC.Code__c = 'Rate';
        facQC.Quote__c = quote.Id;
        fsListQC.add(facQC);
        mapOfOptionIdVsListOfFactorSummary.put(quoteOption.Id, fsListQC);
        
        test.startTest();
        CreateFactorSummary.createNewFactorSummary(fsList, quote.Id); 
        CreateFactorSummary.createNewFactorSummaryQC(mapOfOptionIdVsListOfFactorSummary);  
        CreateFactorSummary.createNewFactorSummary(fsList, ''); 
        test.stopTest();
        system.assert(fsList != null);
        
    }
}