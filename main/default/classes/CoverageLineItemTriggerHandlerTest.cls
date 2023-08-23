/**************************************************************************************************
* Class Name: CoverageLineItemTriggerHandlerTest
* Author: Hoang Bui
* Date: 28-Oct-2019
* Description: CoverageLineItemTriggerHandlerTest Test
**************************************************************************************************/
@isTest
private class CoverageLineItemTriggerHandlerTest {
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
        
        
        List<Coverage__c> insertCoverageList = New List<Coverage__c>();
        
        //Create coverage for Cyber
        Coverage__c cov3 = TestUtil.createCoverage('Cyber Coverage', 'Cyber');
        insertCoverageList.add(cov3);
        system.debug('-->cov3-->'+cov3);
        
        //Create coverage
        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'D&O');
        insertCoverageList.add(cov);
        
        //Create coverage
        Coverage__c cov1 = TestUtil.createCoverage('Coverage test', 'MPL');
        cov1.Additional_Requirements__c = 'Rating Required';
        insertCoverageList.add(cov1);
        
         //Create coverage
        Coverage__c cov2 = TestUtil.createCoverage('Coverage test', 'MPL');
        insertCoverageList.add(cov2);
        
        
        
        Insert insertCoverageList;
        
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
        
         // Coverages Line Item   added by RINKU SAINI 27-Dec-2021
        CoveragesLineItem__c coverLi4 = new CoveragesLineItem__c();
        coverLi4.Coverage__c  = cov2.Id; 
        coverLi4.Quote__c = quote.Id;
        coverLi4.Limits_Deductibles__c = ded.Id;
        coverLi4.Coverage_Premium__c  = 'Text Premium'; 
        coverLi4.Min_amt__c  = 1000;
        coverLi4.Max_amt__c  = 5000;
        coverLi4.Deductible_Frequency__c  = 'Daily';
        coverLi4.Options_Value_Percent__c  = 5;
        coverLi4.RecordTypeId = Schema.SObjectType.CoveragesLineItem__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        coverageList.add(coverLi4);
        
        CoveragesLineItem__c coverLi5 = new CoveragesLineItem__c();
        coverLi5.Coverage__c  = cov3.Id; 
        coverLi5.Quote__c = quote.Id;
        coverLi5.Limits_Deductibles__c = ded.Id;
        coverLi5.Coverage_Premium__c  = 'Text Premium'; 
        coverLi5.Min_amt__c  = 1000;
        coverLi5.Max_amt__c  = 5000;
        coverLi5.Deductible_Frequency__c  = 'Daily';
        coverLi5.Options_Value_Percent__c  = 5;
        coverLi5.RecordTypeId = Schema.SObjectType.CoveragesLineItem__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        coverageList.add(coverLi5);
        
        Insert coverageList;
        
        ded.LmtDedCode__c = coverLi.Limits_Deductibles__c;
        update ded;
        
        cov1.Coverage_Code__c = coverLi.Coverage__c;
        update cov1;      
    }
    
    @isTest static void testUpdateCoveragesLineItem() {
        
        Boolean result = CommonUtil.isTriggerBypass('CoverageLineItemTrigger');
        System.assertEquals(false, result);
        
        
        List<CoveragesLineItem__c> covLineItems = new List<CoveragesLineItem__c>();
        // Integer index = 0;
         Test.startTest();
        for (CoveragesLineItem__c covItem: [Select Id,Coverage_Premium__c,Quote__c from CoveragesLineItem__c]){
            covItem.Coverage_Premium__c = 'New Update Name';
            covItem.Option_Value_Default__c = 'It is new Option_Value_Default__c'; //Khanh added 18-Sep-20
            //index ++;
            covLineItems.add(covItem);
        }
         for (CoveragesLineItem__c covItem: [Select Id,Coverage_Premium__c,Quote__c from CoveragesLineItem__c where                    
                                             CoverageLineItemType__c  =:'Main Coverage']){
            covItem.Coverage_Premium__c = 'New Update Name2';
            covLineItems.add(covItem);
             system.debug('covItem-->'+covItem);                                        
        }
        
        update covLineItems;
        CoverageLineItemTriggerHandler_CEL.filterEndorsement(covLineItems);
        
        Test.stopTest();
        
        system.debug('covLineItems='+covLineItems);
        System.assertEquals(false,covLineItems.isEmpty());
    }
    
    @isTest static void testUpdateCoveragesLineItem1() {
        
       
        Boolean result = CommonUtil.isTriggerBypass('CoverageLineItemTrigger');
        System.assertEquals(false, result);
         Test.startTest();
        Coverage__c cov1 = TestUtil.createCoverage('Miscellaneous Professional Liability', 'MPL');
        insert cov1;
        
        List<CoveragesLineItem__c> covLineItems = new List<CoveragesLineItem__c>();
        
        CoveragesLineItem__c covItem =  [Select Id,Coverage_Premium__c from CoveragesLineItem__c limit 1];
        covItem.Coverage_Premium__c = '1000';
        covItem.Option_Value_Default__c = 'It is new Option_Value_Default__c'; 
        covItem.Coverage__c  = cov1.Id;
        covLineItems.add(covItem);
        
        List<CoveragesLineItem__c> covItemdeleteList =  [Select Id,Coverage_Premium__c from CoveragesLineItem__c where Rating__c =: true ];
        
        
        update covLineItems;
        delete covItemdeleteList;
        Test.stopTest();
        
        system.debug('covLineItems='+covLineItems);
        System.assertEquals(false,covLineItems.isEmpty());
    }       
    
}