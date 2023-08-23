/**************************************************************************************************
* Class Name: CoverageLineItemQueryUtilTest
* Author: RINKU SAINI
* Date: Dec 24, 2021
* Description: 
**************************************************************************************************/
@isTest
public class CoverageLineItemQueryUtilTest {
    
    public static Product2 product;
    public static Account acc;
    
    static {
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassQuoteTrigger__c = true;
        setting.BypassCoverageLineItemTrigger__c = false;
        setting.BypassContactTrigger__c = true;
        update setting;
        
        //acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        //insert acc;
        
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Account acc = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert acc;
        
        // Create Contact Broker
        Id recordTypeContactAgency = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Contact contactBroker = TestUtil.createContact(acc.Id, 'Broker_Contact', 'New broker contact');
        contactBroker.RecordTypeId = recordTypeContactAgency;
        insert contactBroker;
        
        
        product = TestUtil.createProduct('MPL Standalone');
        insert product;
        
        Opportunity oppt = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        insert oppt;
        
        // Add Broker to Opportunity
        Broker_Account__c newBroAccount = TestUtil.createBrokerAccount(contactBroker.Id, oppt.Id);
        insert newBroAccount;
        
        // Qualify Opportunity
        oppt.StageName = 'Qualified';
        update oppt;
        
        //Create coverage
        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'D&O');
        insert cov;
        
        //Create coverage
        Coverage__c cov1 = TestUtil.createCoverage('Coverage test', 'MPL');
        insert cov1;
        
        
        //create limit deductables
        Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
        ded.LmtDedCode__c = 'CelerityExcessLimit';
        insert ded;
        
        
        
        Quote quote = TestUtil.createQuote('New Quote Test',oppt.Id);
        quote.Coverage_Product_Options__c ='MPL';
        quote.Status = 'In Progress';
        quote.Quote_Type__c = 'New Business';
        quote.Refer_Type__c = 'Underwriting Referral';
        quote.Azure_ID__c = 'Testing-Quote';
        insert quote;
        
        //added by RINKU SAINI 24-Dec-2021
        Quote quote1 = TestUtil.createQuote('New Quote Test',oppt.Id);
        quote1.Coverage_Product_Options__c ='MPL';
        quote1.Status = 'In Progress';
        quote1.Quote_Type__c = 'New Business';
        quote1.Refer_Type__c = 'Underwriting Referral';
        quote1.Azure_ID__c = 'Testing-Quote123';
        insert quote1;
        
         //added by RINKU SAINI 24-Dec-2021
        List<CoveragesLineItem__c> coverageList = New List<CoveragesLineItem__c>();
        // Coverages Line Item
        CoveragesLineItem__c coverLi = new CoveragesLineItem__c();
        coverLi.Coverage__c  = cov1.Id; 
        coverLi.Quote__c = quote.Id;
        coverLi.Limits_Deductibles__c = ded.Id;
        coverLi.Coverage_Premium__c  = 'Text Premium'; 
        coverLi.Min_amt__c  = 1000;
        coverLi.Max_amt__c  = 5000;
        coverLi.Deductible_Frequency__c  = 'Daily';
        coverLi.Options_Value_Percent__c  = 5;
        coverageList.add(coverLi);
        
        // Coverages Line Item  added by RINKU SAINI 24-Dec-2021
        CoveragesLineItem__c coverLi2 = new CoveragesLineItem__c();
        coverLi2.Coverage__c  = cov1.Id; 
        coverLi2.Quote__c = quote.Id;
        coverLi2.Limits_Deductibles__c = ded.Id;
        coverLi2.Coverage_Premium__c  = 'Text Premium'; 
        coverLi2.Min_amt__c  = 1000;
        coverLi2.Max_amt__c  = 5000;
        coverLi2.Deductible_Frequency__c  = 'Daily';
        coverLi2.Options_Value_Percent__c  = 5;
        coverageList.add(coverLi2);
        
        // Coverages Line Item
        CoveragesLineItem__c coverLi1 = new CoveragesLineItem__c();
        coverLi1.Coverage__c  = cov1.Id; 
        coverLi1.Quote__c = quote.Id;
        coverLi1.Limits_Deductibles__c = ded.Id;
        coverLi1.Coverage_Premium__c  = 'Text Premium'; 
        coverLi1.Min_amt__c  = 1000;
        coverLi1.Max_amt__c  = 5000;
        coverLi1.Deductible_Frequency__c  = 'Daily';
        coverLi1.Options_Value_Percent__c  = 5;
        coverLi1.RecordTypeId = Schema.SObjectType.CoveragesLineItem__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        coverageList.add(coverLi1);
        
        // Coverages Line Item   added by RINKU SAINI 24-Dec-2021
        CoveragesLineItem__c coverLi3 = new CoveragesLineItem__c();
        coverLi3.Coverage__c  = cov1.Id; 
        coverLi3.Quote__c = quote.Id;
        coverLi3.Limits_Deductibles__c = ded.Id;
        coverLi3.Coverage_Premium__c  = 'Text Premium'; 
        coverLi3.Min_amt__c  = 1000;
        coverLi3.Max_amt__c  = 5000;
        coverLi3.Deductible_Frequency__c  = 'Daily';
        coverLi3.Options_Value_Percent__c  = 5;
        coverLi3.RecordTypeId = Schema.SObjectType.CoveragesLineItem__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        coverageList.add(coverLi3);
        
        Insert coverageList;
        
        ded.LmtDedCode__c = coverLi.Limits_Deductibles__c;
        update ded;
        
        cov1.Coverage_Code__c = coverLi.Coverage__c;
        update cov1;
        
    }
   
    @isTest static void testUpdateCoveragesLineItem1() {
        
        
        Boolean result = CommonUtil.isTriggerBypass('CoverageLineItemTrigger');
        System.assertEquals(false, result);
        Coverage__c cov1 = TestUtil.createCoverage('Miscellaneous Professional Liability', 'MPL');
        insert cov1;
        
        List<CoveragesLineItem__c> covLineItems = new List<CoveragesLineItem__c>();
        
        CoveragesLineItem__c covItem =  [Select Id,Coverage_Premium__c from CoveragesLineItem__c limit 1];
        covItem.Coverage_Premium__c = '1000';
        covItem.Option_Value_Default__c = 'It is new Option_Value_Default__c'; 
        covItem.Coverage__c  = cov1.Id;
        covLineItems.add(covItem);
        
        Test.startTest();
        update covLineItems;
        // added by Rinku Saini 3rd Jan 2022
        Set<Id> quoteIds = New Set<Id>();
        for( Quote qt : [Select Id from Quote ]){
            quoteIds.add(qt.Id);
        }
        CoverageLineItemQueryUtil.fetchCLIsByProductNamesAndQuotes('',null);
        CoverageLineItemQueryUtil.fetchCLIsByCoverageTypeAndQuotes(quoteIds);
        Test.stopTest();
        
        system.debug('covLineItems='+covLineItems);
        System.assertEquals(false,covLineItems.isEmpty());
    }       
    
}