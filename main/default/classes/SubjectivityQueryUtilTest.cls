/**************************************************************************************************
* Class Name: SubjectivityQueryUtilTest
* Author: RINKU SAINI
* Date: Dec 24, 2021
* Description: 
**************************************************************************************************/
@isTest
public class SubjectivityQueryUtilTest {
    
    public static testmethod void coverfetchSubjectivities(){
        Test.startTest();
        
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
        
        
        Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote.Coverage_Product_Options__c ='D&O;MPL';       
        insert quote;
        
        Subjectivity__c subj = new Subjectivity__c();
        subj.Subjectivity__c = 'Testing';
        subJ.Subjectivity_Status__c = 'Open';
        subJ.Subjectivity_Type__c = 'MPL';
        subJ.Quote__c = quote.Id;
        subJ.RecordTypeId = Schema.SObjectType.Subjectivity__c.getRecordTypeInfosByName().get(GlobalVariables.RT_NAME_SUBJECTIVITY_CELERITY).getRecordTypeId();
        insert subJ;
        
        SubjectivityQueryUtil.fetchSubjectivitiesForSubjectivityIds( New Set<id>{subJ.Id},'Id');
        SubjectivityQueryUtil.fetchSubjectivitiesForQuote(quote.Id);
        Test.stopTest();
    }
}