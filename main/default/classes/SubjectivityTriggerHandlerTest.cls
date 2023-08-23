/**************************************************************************************************
* Class Name: SubjectivityTriggerTest
* Author: Sarthak Roy
* Created date: 18-Dec-2020
* Description: Test Trigger for Subjectivity__c Object
* Modified By: Ashik Zahir
* Modifiied date: 15-Feb-2021
**************************************************************************************************/
@isTest
public class SubjectivityTriggerHandlerTest {
   @testSetup 
    static void createData(){
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        Product2 product = TestUtil.createProduct('D&O');
        insert product;   
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        opportunity.Coverage_Product_Options__c = 'D&O;MPL';
        insert opportunity;
        
        //Create coverage
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
        
        // By pass trigger to insert quote
        TriggerSettings__c settings = new TriggerSettings__c();
		settings.BypassQuoteTrigger__c = true;
		insert settings;
		System.assert(settings != null);
        
        Subjectivity_Template__c subjectivityTemplate = new Subjectivity_Template__c();
		subjectivityTemplate.Subjectivity_Name__c = 'Signed / Dated Proposal';
		subjectivityTemplate.Subjectivity_Text__c = 'Test';
		subjectivityTemplate.Profession_Criteria__c = 'Engineers';
		insert subjectivityTemplate;
        
        Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote.Coverage_Product_Options__c ='D&O;MPL'; 
        quote.Status = 'Quoted';
        insert quote;
        
        quote.Status = 'Rated';
       // update quote;
        
        // added By RINKU SAINI 27/12/2021
        List<Subjectivity__c> subList = New List<Subjectivity__c>();
        // added by RINKU SAINI 24-Dec-2021
        Subjectivity__c subj = new Subjectivity__c();
        subj.Subjectivity__c = 'Testing';
        subJ.Subjectivity_Status__c = 'Open';
        subJ.Subjectivity_Type__c = 'MPL';
        subJ.Quote__c = quote.Id;
        subJ.RecordTypeId = Schema.SObjectType.Subjectivity__c.getRecordTypeInfosByName().get(GlobalVariables.RT_NAME_SUBJECTIVITY_CELERITY).getRecordTypeId();
        subList.add(subJ);
        
        Subjectivity__c subj1 = new Subjectivity__c();
        subj1.Subjectivity__c = 'Testing';
        subj1.Subjectivity_Status__c = 'Open';
        subj1.Subjectivity_Type__c = 'MPL';
        subj1.Quote__c = quote.Id;
        subj1.RecordTypeId = Schema.SObjectType.Subjectivity__c.getRecordTypeInfosByName().get(GlobalVariables.RT_NAME_SUBJECTIVITY_AQUEOUS).getRecordTypeId();
        subList.add(subj1);
        
        Subjectivity__c subj2 = new Subjectivity__c();
        subj2.Subjectivity__c = 'Testing';
        subj2.Subjectivity_Status__c = 'Open';
        subj2.Subjectivity_Type__c = 'MPL';
        subj2.Quote__c = quote.Id;
        subj2.RecordTypeId = Schema.SObjectType.Subjectivity__c.getRecordTypeInfosByName().get(GlobalVariables.RT_NAME_SUBJECTIVITY_AQUEOUS).getRecordTypeId();
        subj2.Cleared__c = true;
        subList.add(subj2);
        Insert subList;
        
        update subj1;
    }
    
    @isTest
    static void testSubjectivity(){
        Test.startTest();
        Id quoteId = [Select Id from Quote Limit 1].Id;
        Subjectivity__c sub = new Subjectivity__c();
        sub.Quote__c = quoteId;
        sub.RecordTypeId = Schema.SObjectType.Subjectivity__c.getRecordTypeInfosByName().get(GlobalVariables.RT_NAME_SUBJECTIVITY_CELERITY).getRecordTypeId();
        insert sub;
        
        sub.Subjectivity_Status__c = 'Completed';
        update sub;
        
        delete sub;
        System.assertEquals(3, [Select id from Subjectivity__c Where Quote__c = :quoteId].size()); 
        List<Subjectivity__c> subList = [Select id from Subjectivity__c];
        delete subList;
        Test.stopTest();
    }
}