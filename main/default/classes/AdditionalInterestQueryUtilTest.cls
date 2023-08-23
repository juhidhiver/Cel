/**************************************************************************************************
* Class Name: AdditionalInterestQueryUtilTest
* Author:  RINKU SAINI
* Date: 28th Dec 2021
* Description: 
**************************************************************************************************/
@isTest
public class AdditionalInterestQueryUtilTest {
    
    public static testmethod void fetchAdditionalInterests(){
        Test.startTest();
        
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account acc1  = TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster',
                                               'California','90000', 'United States');
        acc1.IsMailingSameWithBillingAddress__c = true;
        acc1.Date_Started__c = Date.today().addYears(-2);
        insert acc1;
        
        // Create product and coverage
        Product2 prd = TestUtil.createProduct('Private Company Combo', Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Celerity').getRecordTypeId(),
                                              'Celerity');
        prd.Expiration_Date__c = Date.today().addDays(200);
        prd.Effective_Date__c = Date.today().addDays(-1);
        insert prd;
        
        Opportunity opp = TestUtil.createOpportunity('Test opp', acc1.Id, prd.Id, 
                                                     Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId(), 'Celerity');
        opp.StageName = 'Qualified';
        opp.CloseDate = Date.today().addDays(30);
        opp.Effective_Date__c = Date.today().addDays(1);
        opp.Pricebook2Id = Test.getStandardPricebookId();
        opp.Coverage_Product_Options__c = 'D&O';
        insert opp;
        
        // Create quote
        Quote quote = TestUtil.createQuote('Test quote 1',opp.Id);
        quote.Coverage_Product_Options__c = 'D&O';
        quote.Pricebook2Id = Test.getStandardPricebookId();
        insert quote;
        
        AdditionalInterestQueryUtil.fetchAdditionalInterestsByQuote( New Set<Id>{quote.Id});
        Test.stopTest();
    }
}