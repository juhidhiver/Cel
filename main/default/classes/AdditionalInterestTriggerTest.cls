/**************************************************************************************************
* Class Name: AdditionalInterestTriggerTest
* Author: Giang Phan
* Date: 08-Nov-2019
* Description: Unit test for AdditionalInterestTrigger
**************************************************************************************************/
@isTest private class AdditionalInterestTriggerTest {
    @testSetup static void setup() {
        // added by RINKU SAINI 29/12/2021
        Account addAcc1 = new Account(
            Name = 'Additional interest account 1',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId()
        );
        insert addAcc1;
        // Create product and coverage
        Product2 prd = TestUtil.createProduct('Private Company Combo', Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Celerity').getRecordTypeId(),
                                              'Celerity');
        prd.Expiration_Date__c = Date.today().addDays(200);
        prd.Effective_Date__c = Date.today().addDays(-1);
        insert prd;
        
        // Create product and coverage added by RINKU SAINI 28/12/2021
        Product2 prd1 = TestUtil.createProduct('Professional Indemnity', Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Aqueous').getRecordTypeId(),
                                               'Aqueous');
        prd1.Expiration_Date__c = Date.today().addDays(200);
        prd1.Effective_Date__c = Date.today().addDays(-1);
        insert prd1;
        
        // By pass trigger ti insert quote
        TriggerSettings__c settings = new TriggerSettings__c();
        settings.BypassQuoteTrigger__c = true;
        insert settings;
        System.assert(settings != null);
    }
    
    @isTest static void testCase1() {
        
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account acc1  = TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster',
                                               'California','90000', 'United States');
        acc1.IsMailingSameWithBillingAddress__c = true;
        acc1.Date_Started__c = Date.today().addYears(-2);
        insert acc1;
        
        // added by RINKU SAINI 28/12/2021
        Account acc2  = TestUtil.createAccount('AQ Bussiness Account Test', recordTypeId, '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc2.IsMailingSameWithBillingAddress__c = true;
        acc2.Date_Started__c = Date.today().addYears(-2);
        insert acc2;
        
        Product2 prd = [Select Id From Product2 Where Name = 'Private Company Combo'][0];
        // added by RINKU SAINI 28/12/2021                                                                             
        Product2 prd1 = [Select Id,Name From Product2 Where Name = 'Professional Indemnity'][0];
        
        Opportunity opp = TestUtil.createOpportunity('Test opp', acc1.Id, prd.Id, 
                                                     Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId(), 'Celerity');
        opp.StageName = 'Qualified';
        opp.CloseDate = Date.today().addDays(30);
        opp.Effective_Date__c = Date.today().addDays(1);
        opp.Pricebook2Id = Test.getStandardPricebookId();
        opp.Coverage_Product_Options__c = 'D&O';
        insert opp;
        
        // added by RINKU SAINI 28/12/2021                                                                              
        Opportunity opp1 = TestUtil.createOpportunity('Test opp', acc2.Id, prd1.Id, 
                                                      Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId(), 'Aqueous');
        opp1.StageName = 'Qualified';
        opp1.CloseDate = Date.today().addDays(30);
        opp1.Effective_Date__c = Date.today().addDays(1);
        opp1.Pricebook2Id = Test.getStandardPricebookId();
        opp1.Coverage_Product_Options__c = 'Expired';
        insert opp1;
        
        // Create contact
        Contact con = new Contact(
            Lastname = 'Huy broker',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
        );
        insert con;
        
        // Create broker
        Broker_Account__c broker =  TestUtil.createBrokerAccount(con.Id, opp.Id);
        insert broker;
        
        // Create pricebook entry
        PricebookEntry pbe = TestUtil.createPricebookEntry(Test.getStandardPricebookId(), prd.Id);
        insert pbe;
        
        // Create quote
        Quote quote = TestUtil.createQuote('Test quote 1',opp.Id);
        quote.Coverage_Product_Options__c = 'D&O';
        quote.Pricebook2Id = Test.getStandardPricebookId();
        insert quote;
        
        // Create quote  added by RINKU SAINI 28/12/2021
        Quote quote1 = TestUtil.createQuote('Test quote 2',opp1.Id);
        quote1.Coverage_Product_Options__c = 'Expired';
        quote1.Pricebook2Id = Test.getStandardPricebookId();
        insert quote1;
        
        // Create account for additional interests
        Account addAcc1 = new Account(
            Name = 'Additional interest account 1',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId()
        );
        insert addAcc1;
        
        // Create additional interests
        Additional_Interests__c addInt = TestUtil.createAdditionalInterests(addAcc1.Id, quote.Id, 'Additional Insured');
        insert addInt;
        
        // Create additional interests  added by RINKU SAINI 28/12/2021
        Additional_Interests__c addInt1 = TestUtil.createAdditionalInterests(addAcc1.Id, quote1.Id, 'Additional Insured');
        insert addInt1;
        
        addInt.Relationship_Type__c = 'Lienholder';
        update addInt; 
        
        addInt1.Relationship_Type__c = 'Lienholder';
        update addInt1;
        
        // Insert duplicate additional interest
        Additional_Interests__c duplicateAddInt = TestUtil.createAdditionalInterests(addAcc1.Id, quote.Id, 'Additional Insured');
        Database.insert(duplicateAddInt, false);
        
        // Duplicate additional interest when bulk insert
        List<Additional_Interests__c> duplicateAddInts = new List<Additional_Interests__c>();
        for (Integer i=0; i<=1; i++) {
            Additional_Interests__c dupAddInt = TestUtil.createAdditionalInterests(addAcc1.Id, quote.Id, 'Additional Insured');
            duplicateAddInts.add(dupAddInt);
        }
        Database.insert(duplicateAddInts, false);
        
        system.debug([Select id from Additional_Interests__c where id =: addInt1.Id]);
        System.assert(acc1 != null);
        delete addInt;
        delete addInt1;
        system.debug([Select id from Additional_Interests__c where id =: addInt1.Id]);
    }
    
    @isTest 
    static void testDeleteValidationWhenQuoteLock() {
        
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account acc1  = TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster',
                                               'California','90000', 'United States');
        acc1.IsMailingSameWithBillingAddress__c = true;
        acc1.Date_Started__c = Date.today().addYears(-2);
        insert acc1;
        
        Product2 prd = [Select Id From Product2 Where Name = 'Private Company Combo'][0];
        
        // Create opportunity
        Opportunity opp = TestUtil.createOpportunity('Test opp', acc1.Id, prd.Id, 
                                                     Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId(), 'Celerity');
        opp.CloseDate = Date.today().addDays(30);
        opp.Effective_Date__c = Date.today().addDays(1);
        opp.Pricebook2Id = Test.getStandardPricebookId();
        opp.Coverage_Product_Options__c = 'D&O';
        insert opp;
        
        // Create contact
        Contact con = new Contact(
            Lastname = 'Huy broker',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
        );
        insert con;
        
        // Create broker
        Broker_Account__c broker =  TestUtil.createBrokerAccount(con.Id, opp.Id);
        insert broker;
        
        // After insert broker, opp stage will change to 'Prospect'
        // The we update opp stage again to 'Qualified' to create quote
        opp.StageName = 'Qualified';
        update opp;
        
        // Create pricebook entry
        PricebookEntry pbe = TestUtil.createPricebookEntry(Test.getStandardPricebookId(), prd.Id);
        insert pbe;
        
        // Create quote
        Quote quote = TestUtil.createQuote('Test quote 1',opp.Id);
        quote.Coverage_Product_Options__c = 'D&O';
        quote.Pricebook2Id = Test.getStandardPricebookId();
        insert quote;	
        
        // Create account for additional interests
        Account addAcc1 = new Account(
            Name = 'Additional interest account 1',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId()
        );
        insert addAcc1;	
        
        // Create additional interests
        Additional_Interests__c addInt = TestUtil.createAdditionalInterests(addAcc1.Id, quote.Id, 'Additional Insured');
        insert addInt;
        
        delete addInt;
        
    }
    
    @isTest 
    static void testUpdate() {
        
        List<Account> lstAcc = new List<Account>();
        
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account acc1  = TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster',
                                               'California','90000', 'United States');
        acc1.IsMailingSameWithBillingAddress__c = true;
        acc1.Date_Started__c = Date.today().addYears(-2);
        lstAcc.add(acc1);
        
        // Create account for additional interests
        
        Account addAcc1 = new Account(
            Name = 'Additional interest account 1',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId()
        );
        Account addAcc2 = new Account(
            Name = 'Additional interest account 2',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId()
        );
        // commented by RINKU SAINI 29/12/2021
        //lstAcc.Add(addAcc1);	
        //lstAcc.Add(addAcc2);	
        insert lstAcc;
        
        Product2 prd = [Select Id From Product2 Where Name = 'Private Company Combo'][0];
        
        // Create opportunity
        Opportunity opp = TestUtil.createOpportunity('Test opp', acc1.Id, prd.Id, 
                                                     Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId(), 'Celerity');
        opp.CloseDate = Date.today().addDays(30);
        opp.Effective_Date__c = Date.today().addDays(1);
        opp.Pricebook2Id = Test.getStandardPricebookId();
        opp.Coverage_Product_Options__c = 'D&O';
        insert opp;
        
        // Create contact
        Contact con = new Contact(
            Lastname = 'Huy broker',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
        );
        insert con;
        
        // Create broker
        Broker_Account__c broker =  TestUtil.createBrokerAccount(con.Id, opp.Id);
        insert broker;
        
        // After insert broker, opp stage will change to 'Prospect'
        // The we update opp stage again to 'Qualified' to create quote
        opp.StageName = 'Qualified';
        update opp;
        
        // Create pricebook entry
        PricebookEntry pbe = TestUtil.createPricebookEntry(Test.getStandardPricebookId(), prd.Id);
        insert pbe;
        
        // Create quote
        Quote quote = TestUtil.createQuote('Test quote 1',opp.Id);
        quote.Coverage_Product_Options__c = 'D&O';
        quote.Pricebook2Id = Test.getStandardPricebookId();
        insert quote;
        
        
        
        // Create additional interests
        Additional_Interests__c addInt = TestUtil.createAdditionalInterests(lstAcc[0].Id,
                                                                            quote.Id, 'Lienholder');
        addInt.Old_Additional_Interest_Account__c = '123456';
        insert addInt;
        
        addInt.Additional_Interest_Account__c = [Select Id from Account where Name =: 'Additional interest account 1'].Id;
        addInt.Old_Additional_Interest_Account__c = '';
        update addInt;	
    }
    
    @isTest 
    static void testErrorcreateCoverageLineItem() {				
        Database.SaveResult[] srList = new Database.SaveResult[1];
        
        Database.SaveResult blankResult = (Database.SaveResult)
            JSON.deserialize('{"success":false,"errors":[{"message":"You cannot do this...","statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}', Database.SaveResult.class);		
        srList[0] = blankResult; 
        List<CoveragesLineItem__c> cvgl = new List<CoveragesLineItem__c>();    
    }
}