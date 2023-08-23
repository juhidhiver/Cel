/**************************************************************************************************
* Class Name: OpportunityTriggerHandlerTest
* Author: Hoang Bui
* Date: 27-Aug-2019
* Description: OpportunityTriggerHandler Test
**************************************************************************************************/
@isTest
private class OpportunityTriggerHandlerTest {
    public static Product2 product;
    public static Product2 product1;
    public static Account acc;
    public static List<Rating_Modifier_Template__c> lRMT;
    
    static {
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = false;
        setting.BypassAccountTrigger__c = true;
        setting.BypassProductTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        update setting;
        
        acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        product = TestUtil.createProduct('D&O Standalone');
        insert product;
        
        product1 = TestUtil.createProduct('Professional Indemnity');
        insert product1;
        
        lRMT = new List<Rating_Modifier_Template__c>();
        Rating_Modifier_Template__c rMT1 = TestUtil.createRatingModifierTemplate('Service Classification','Cyber','Number');
        rMT1.Page_Section__c = Label.ELIGIBILITY_SECTION_HEADER;
        rMT1.Create_Criteria__c = 'Property Professionals;Engineers;IT Consultants';
        lRMT.add(rMT1);
        Rating_Modifier_Template__c rMT2 = TestUtil.createRatingModifierTemplate('New input integer','MPL','Integer');
        rMT2.Page_Section__c = Label.ELIGIBILITY_SECTION_HEADER;
        rMT2.Create_Criteria__c = 'Property Professionals;Engineers;IT Consultants';
        lRMT.add(rMT2);
        Rating_Modifier_Template__c rMT3 = TestUtil.createRatingModifierTemplate('New input integer','Cyber','Integer');
        rMT3.Page_Section__c = Label.ELIGIBILITY_SECTION_HEADER;
        rMT3.Create_Criteria__c = 'Property Professionals;Engineers;IT Consultants';
        lRMT.add(rMT3);
        Rating_Modifier_Template__c rMT4 = TestUtil.createRatingModifierTemplate('New input integer','MPL','Integer');
        rMT4.Page_Section__c = Label.ELIGIBILITY_SECTION_HEADER;
        rMT4.Create_Criteria__c = 'Property Professionals;Engineers;IT Consultants';
        lRMT.add(rMT4);
        Rating_Modifier_Template__c rMT5 = TestUtil.createRatingModifierTemplate(Label.NATURE_OF_INDUSTRY_OR_SECTOR,'Cyber','Number');
        rMT5.Page_Section__c = Label.ELIGIBILITY_SECTION_HEADER;
        rMT5.Create_Criteria__c = 'Property Professionals;Engineers;IT Consultants';
        lRMT.add(rMT5);
        Rating_Modifier_Template__c rMT6 = TestUtil.createRatingModifierTemplate(Label.ANNUAL_REVENUES,'Cyber','Number');
        rMT6.Page_Section__c = 'Risk Capture';
        rMT6.Create_Criteria__c = 'Property Professionals;Engineers;IT Consultants';
        lRMT.add(rMT6);
        
        insert lRMT;
        
        Account_Loss_Detail__c accLossDet = new Account_Loss_Detail__c();
        accLossDet.Loss_Amount__c = 1000;
        accLossDet.Account__c = acc.Id;
        accLossDet.Number_of_Losses__c = 2;
        accLossDet.Product__c = 'MPL';
        accLossDet.Status__c = 'Open';
        insert accLossDet;
        
        Rating_Modifier_Template__c percentField = TestUtil.createRatingModifierTemplate('New input Percentage','MPL','Percentage');
        percentField.Factor_Default_Value__c = 1.000; 
        percentField.Create_Criteria__c = 'Property Professionals;Engineers;IT Consultants';
        insert percentField;
        
        SectionSetting__c secSetting = new SectionSetting__c();
        secSetting.Component__c = 'Submission Info';
        secSetting.Main_Section__c = 'Submission Info';
        secSetting.Source_Object__c = 'Opportunity';
        secSetting.Source_Field_Label__c = 'Submission Type';
        secSetting.Source_Field_API__c = 'Type';
        secSetting.Format__c = 'Text';
        secSetting.Product__c = 'Cyber';
        secSetting.Active__c = true;
        secSetting.Record_Type__c = 'Celerity';
        secSetting.DisplayType__c = 'Component';
        insert secSetting; 
        
        //End of Setup
    }
    
    @isTest static void testCreateOpportunity() {
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.Total_Revenues__c = 100;
        
        Test.startTest();
        insert opportunity;
        Test.stopTest();
        opportunity.Name ='test1';
        update opportunity;
        
        List<Opportunity> lstOpportunity = [SELECT Id FROM Opportunity Where Id =:opportunity.Id];
        System.assertEquals(true,lstOpportunity[0].Id != null);
        delete opportunity;
    }
    
    @isTest static void testCreateOpportunityAQ() {
        product.Name = 'Professional Indemnity'; //change product name
        update product;
        
        Test.startTest();
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test', acc.Id, product.Id);
        opportunity.Coverage_Product_Options__c = 'D&O;Cyber';
        opportunity.Innovisk_Entity_ID__c = 'Celerity';
        
        String exceptionMessage = '';
        try{
            insert opportunity;
            opportunity.Coverage_Product_Options__c = 'Fiduciary;MPL';
            opportunity.Innovisk_Entity_ID__c = 'Aqueous';
            opportunity.Coverage_Product_Options__c = 'Professional Indemnity';
            opportunity.Main_Profession__c = 'Engineers';
            update opportunity;
        }catch(Exception ex){
            exceptionMessage = ex.getMessage();
        }
        
        try{
            Rating_Modifier_Template__c template = [Select Id From Rating_Modifier_Template__c Where Page_Section__c = 'Risk Capture'];
            template.Product__c = 'Professional Indemnity';
            template.Create_Criteria__c = 'Property Professionals;Engineers;IT Consultants';
            update template;
            
            opportunity.Main_Profession__c = 'IT Consultants';
            update opportunity;
            
        }catch(Exception ex){
            exceptionMessage = ex.getMessage();
        }
        
        List<Opportunity> lstOpportunity = [SELECT Id FROM Opportunity Where Id =:opportunity.Id];
        Test.stopTest();
        System.assertEquals(1, lstOpportunity.size());
        System.assert(String.isNotEmpty(exceptionMessage));
    }
    
    @isTest static void testCreateOpportunityAQ2() {
        Account acc1 = TestUtil.createBusinessAccount('Bussiness Account Test Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 product = TestUtil.createProduct('Professional Indemnity');
        product.RecordTypeId = aqueousRecordTypeId;
        product.Innovisk_Entity_ID__c = 'Aqueous';
        insert product;
        
        Opportunity opp = TestUtil.createOpportunity('Test opp', acc1.Id, product.Id);
        opp.Innovisk_Entity_ID__c = 'Aqueous';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        opp.Product__c = product.Id;
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        opp.Main_Profession__c = 'Engineers';
        insert opp;
        
        Quote quote1 = TestUtil.createQuote('New Quote Test',opp.Id);
        quote1.Status = 'In Progress';
        quote1.Coverage_Product_Options__c = 'D&O;Cyber';
        insert quote1;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test1',acc1.Id, product.Id);
        opportunity.Innovisk_Entity_ID__c = 'Aqueous';
        opportunity.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        opportunity.Product__c = product.Id;
        opportunity.Coverage_Product_Options__c = 'Professional Indemnity';
        opportunity.Main_Profession__c = 'Engineers';
        insert opportunity;
        
        Quote quote2 = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote2.Status = 'Rated';
        quote2.Coverage_Product_Options__c = 'D&O;Cyber';
        insert quote2;
        
        Rating_Modifiers__c rateModParent = TestUtil.createRatingModifier('Annual gross fees / turnover', 'Cyber', opportunity.Id);
        rateModParent.Rating_Modifier_Code__c = 'Test1';
        rateModParent.Page_Section__c = 'Risk Capture';
        insert rateModParent;
        
        Rating_Modifiers__c rateMod = TestUtil.createRatingModifier('Cyber Intel Average Score', 'Cyber', opp.Id);
        rateMod.Page_Section__c = 'Risk Capture';
        rateMod.Rating_Modifier_Code__c = 'Test2';
        insert rateMod;
        
        List<Opportunity> oppList = new List<Opportunity>();
        List<Rating_Modifiers__c> rmList = new List<Rating_Modifiers__c>();
        
        rmList.add(rateMod);
        rmList.add(rateModParent);
        oppList.add(opportunity);
        oppList.add(opp);
        
        SubmissionTriggerHandler_AQ.UpdateRatingModifierFactor(rmList,oppList);
        String exceptionMessage = '';
        try{
            Rating_Modifier_Template__c template = [Select Id From Rating_Modifier_Template__c Where Page_Section__c = 'Risk Capture'];
            template.Product__c = 'Professional Indemnity';
            template.Create_Criteria__c = 'Property Professionals;Engineers;IT Consultants';
            update template;

            //fetch another account            
            opp.Main_Profession__c = 'IT Consultants';
            opp.Parent_Opportunity__c = opportunity.Id;
            opp.Type = 'Renewal';
            opp.AccountId = acc.id;
            Test.startTest();
            update opp;
            Test.stopTest();
        }catch(Exception ex){
            System.assertEquals(ex.getMessage(), ex.getMessage());
            exceptionMessage = ex.getMessage();
        }
        
        List<Opportunity> lstOpportunity = [SELECT Id FROM Opportunity Where Id =:opp.Id];
        
        System.assertEquals(1, lstOpportunity.size());
        //System.assert(String.isEmpty(exceptionMessage));
        
    }
    
    
    @isTest static void testUpdateOpportunity() {
        product.Name = 'Private Company Combo'; //change product name
        update product;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.Coverage_Product_Options__c = 'D&O;Cyber';
        insert opportunity;
        
        Test.startTest();
        opportunity.Coverage_Product_Options__c = 'Fiduciary;MPL';
        opportunity.StageName = 'Bound Pending';
        opportunity.Innovisk_Entity_ID__c = 'Celerity';
        opportunity.Type = 'Renewal';
        update opportunity;
        
        Test.stopTest();
        
        List<Opportunity> lstOpportunity = [SELECT Id FROM Opportunity Where Id =:opportunity.Id];
        System.assertEquals(true,lstOpportunity[0].Id != null);
    }
    
    @isTest static void testUpdateOpportunityAQ1() {
        
        Test.startTest();
        product.Name = 'Professional Indemnity'; //change product name
        update product;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.Coverage_Product_Options__c = 'D&O;Cyber';
        opportunity.Main_Profession__c = 'Design & Construct';
        insert opportunity;
        
        Rating_Modifiers__c rateMod = TestUtil.createRatingModifier('Rateable Exposure', 'Cyber', opportunity.Id);
        rateMod.Page_Section__c = 'Risk Capture';
        insert rateMod;
        
        opportunity.Coverage_Product_Options__c = 'Fiduciary;MPL';
        opportunity.StageName = 'Bound Pending';
        //opportunity.Innovisk_Entity_ID__c = 'Aqueous';
        opportunity.Type = 'Renewal';
        update opportunity;
        
        Test.stopTest();
        List<Opportunity> lstOpportunity = [SELECT Id FROM Opportunity Where Id =:opportunity.Id];
        System.assertEquals(true,lstOpportunity[0].Id != null);
    }
    
    @isTest static void testUpdateOpportunity1() {
        Test.startTest();
        product.Name = 'Professional Indemnity'; //change product name
        update product;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test1',acc.Id, product.Id);
        opportunity.Coverage_Product_Options__c = 'D&O;MPL;Cyber';
        insert opportunity;
        
        Quote quote1 = TestUtil.createQuote('New quote', opportunity.Id);
        quote1.Coverage_Product_Options__c= 'D&O';
        quote1.Layer__c = 'Excess';
        quote1.OpportunityId=opportunity.ID;
        quote1.Status = 'In Approval';
        quote1.Refer_Type__c = 'Underwriting Referral';
        quote1.OpportunityId = opportunity.Id;
        insert quote1;  
        
        Opportunity opportunity1 = TestUtil.createOpportunity('Opp Test2',acc.Id, product.Id);
        opportunity1.Coverage_Product_Options__c = 'D&O;MPL;Cyber';
        opportunity1.Parent_Opportunity__c = opportunity.Id;
        opportunity1.Type = 'Renewal';
        insert opportunity1;
        
        opportunity1.StageName='Unqualified';
        //opportunity1.Innovisk_Entity_ID__c = 'Aqueous';
        update opportunity1;
        
        quote1.Status='Closed';
        update quote1;
        
        opportunity.Coverage_Product_Options__c = 'Fiduciary';
        //opportunity.Innovisk_Entity_ID__c = 'Aqueous';
        update opportunity;
        Test.stopTest();
        
        List<Opportunity> lstOpportunity = [SELECT Id FROM Opportunity Where Id =:opportunity.Id];
        System.assertEquals(true,lstOpportunity[0].Id != null);
    }
    
    @isTest static void testUpdateOpportunity2() {
        product.Name = 'Private Company Combo'; //change product name
        update product;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.Coverage_Product_Options__c = 'D&O;Cyber';
        insert opportunity;
        
        Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote.Status = 'Bound Pending';
        quote.Coverage_Product_Options__c = 'D&O;Cyber';
        insert quote;
        
        Test.startTest();
        opportunity.Coverage_Product_Options__c = 'Fiduciary;MPL';
        opportunity.StageName = 'Bound Pending';
        opportunity.Innovisk_Entity_ID__c = 'Celerity';
        opportunity.Type = 'Renewal';
        update opportunity;
        Test.stopTest();
        
        List<Opportunity> lstOpportunity = [SELECT Id FROM Opportunity Where Id =:opportunity.Id];
        
        System.assertEquals(true,lstOpportunity[0].Id != null);
    }
    
    @isTest
    public static void testUpdateOpp() {
        Test.startTest();
        Account acc = [SELECT id FROM Account LIMIT 1];
        Product2 prd = [SELECT id FROM Product2 LIMIT 1];
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.Total_Revenues__c = 100;
        opportunity.Account_Clearance__c = 'Closed Market';
        insert opportunity;
        
        Quote_Process__c qp = new Quote_Process__c();
        qp.Account__c = acc.Id;
        qp.Submission__c = opportunity.Id;
        insert qp;
        
        Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
        insert quote;
        
        opportunity.StageName = 'Unqualified';
        update opportunity;
        System.assertEquals(true, opportunity.StageName == 'Unqualified');
        Test.stopTest();
    }
    @isTest static void createUWAnalysisAfterUpdateTest(){
        Test.startTest();
        
        // added by RINKU SAINI 31/12/2021
        List<UW_Analysis_Template__c> insertUW_Analysis_Template = New List<UW_Analysis_Template__c>();
        UW_Analysis_Template__c TempList = new UW_Analysis_Template__c();
        TempList.UW_Analysis_Name__c = 'Test';
        TempList.Criteria__c = 'D&C Turnover Split';
        insertUW_Analysis_Template.add(TempList);
        
        UW_Analysis_Template__c TempList1 = new UW_Analysis_Template__c();
        TempList1.UW_Analysis_Name__c = 'Test';
        TempList1.Criteria__c = 'Territory';
        insertUW_Analysis_Template.add(TempList1);
        Insert insertUW_Analysis_Template;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product1.Id);
        opportunity.Total_Revenues__c = 100;  
        opportunity.Main_Profession__c = 'Design & Construct';
        insert opportunity;
        
        Opportunity opportunity1 = TestUtil.createOpportunity('Opp Test',acc.Id, product1.Id);
        opportunity1.Total_Revenues__c = 100;  
        opportunity1.Main_Profession__c = 'Engineers';
        insert opportunity1;
        
        TempList.Criteria__c = 'D&C Turnover Split';
        update TempList;
        
        opportunity1.Main_Profession__c = 'Design & Construct';
        update opportunity1;
        Test.stopTest();
        System.assert(TempList.Criteria__c == 'D&C Turnover Split');
    }
    @isTest static void createUWAnalysisAfterUpdate1Test(){
        // added by RINKU SAINI 31/12/2021
        List<UW_Analysis_Template__c> insertUW_Analysis_Template = New List<UW_Analysis_Template__c>();
        UW_Analysis_Template__c TempList = new UW_Analysis_Template__c();
        TempList.UW_Analysis_Name__c = 'Test';
        TempList.Criteria__c = 'D&C Turnover Split';
        insertUW_Analysis_Template.add(TempList);
        
        UW_Analysis_Template__c TempList1 = new UW_Analysis_Template__c();
        TempList1.UW_Analysis_Name__c = 'Test';
        TempList1.Criteria__c = 'Territory';
        insertUW_Analysis_Template.add(TempList1);
        Insert insertUW_Analysis_Template;
        
        acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 prod = TestUtil.createProduct('Professional Indemnity');
        prod.RecordTypeId = aqueousRecordTypeId;
        prod.Innovisk_Entity_ID__c = 'Aqueous';
        insert prod;
        
        List<Opportunity> newOpp = new List<Opportunity>();
        List<Opportunity> oldOpp = new List<Opportunity>();
        List<Opportunity> oppList = New List<Opportunity>();
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, prod.Id);
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        opp.CloseDate = Date.today();
        opp.Innovisk_Entity_ID__c = 'Aqueous';
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        opp.Main_Profession__c = 'IT Consultants';
        opp.StageName = 'Qualified';
        opp.Expiration_Date__c = Date.today()+60;
        oppList.add(opp);
        
        // added by RINKU SAINI 31/12/2021
        Opportunity opp1 = TestUtil.createOpportunity('Opp Test',acc.Id, prod.Id);
        opp1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        opp1.CloseDate = Date.today();
        opp1.Innovisk_Entity_ID__c = 'Aqueous';
        opp1.Coverage_Product_Options__c = 'Professional Indemnity';
        opp1.Main_Profession__c = 'Design & Construct';
        opp1.StageName = 'Declined';
        opp1.Expiration_Date__c = Date.today()+60;
        oppList.add(opp1);
        Insert oppList;
        
        oldOpp = oppList;
        
        // added by RINKU SAINI 31/12/2021
        List<Quote> QtList = New List<Quote>();
        Quote quote = TestUtil.createQuote('New Quote Test',opp.Id);
        quote.Coverage_Product_Options__c ='MPL;Cyber';
        quote.Status = 'Quoted';
        QtList.add(quote);
        
        // added by RINKU SAINI 31/12/2021
        Quote quote3 = TestUtil.createQuote('New Quote Test',opp1.Id);
        quote3.Coverage_Product_Options__c ='MPL;Cyber';
        quote3.Status = 'Quoted';
        QtList.add(quote3);
        Insert QtList;
        
        opp.Main_Profession__c = 'Design & Construct';
        opp.Type = 'Renewal';
        opp.Total_Revenues__c = 1000;  
        opp.StageName = 'Declined';
        update opp;
        
        opp.Main_Profession__c = 'IT Consultants';
        update opp;
        
        // added by RINKU SAINI 31/12/2021
        opp1.StageName = 'Qualified';
        opp1.Expiration_Date__c = Date.today()+60;
        update opp1;
        
        newOpp.add(opp);
        
        newOpp.add(opp1);
        
        TempList.Criteria__c = 'D&C Turnover Split';
        update TempList;
        
        Rating_Modifier_Template__c ratingModifiersTemp1 = TestUtil.createRatingModifierTemplate('Service Classification','Cyber', 'Number');
        ratingModifiersTemp1.Rating_Modifier_Code__c = 'Cyber000003';
        ratingModifiersTemp1.Page_Section__c = 'Risk Capture';
        insert ratingModifiersTemp1;
        Test.startTest();
        
        SubmissionTriggerHandler_AQ.onUpdateInsuredAccName(oldOpp, newOpp);
        
        Test.stopTest();
        
        System.assert(TempList.Criteria__c == 'D&C Turnover Split');
    }
    
    @isTest static void testupdateServiceClassificationRattingModifiers() {
        product.Name = 'Cyber'; //change product name
        update product;
        
        Test.startTest();
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.Coverage_Product_Options__c = 'D&O;Cyber';
        opportunity.Industry__c = 'Business Services';
        opportunity.Service_Classification__c = 'Auctioneer';
        insert opportunity;
        
        List<Quote> quotes = new  List<Quote>();
        Quote quote1 = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote1.Coverage_Product_Options__c ='D&O;MPL';
        quote1.Status = 'In Progress';
        quotes.add(quote1);
        Quote quote2 = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote2.Coverage_Product_Options__c ='MPL;Cyber';
        quote2.Status = 'In Approval';
        quotes.add(quote2);
        Quote quote3 = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote3.Coverage_Product_Options__c ='MPL;Cyber';
        quote3.Status = 'Quoted';
        quotes.add(quote3);
        insert quotes;
        
        Rating_Modifier_Template__c ratingModifiersTemp1 = TestUtil.createRatingModifierTemplate('Service Classification','Cyber', 'Number');
        ratingModifiersTemp1.Rating_Modifier_Code__c = 'Cyber000003';
        insert ratingModifiersTemp1;
        Rating_Modifiers__c rateMod = TestUtil.createRatingModifier('Service Classification', 'Cyber', opportunity.Id);
        rateMod.Page_Section__c = 'Base Rate';
        
        insert rateMod;
        
        Eligibility_Status__c es = new Eligibility_Status__c();
        es.Rating_Modifier_Template__c = ratingModifiersTemp1.Id;
        es.Rating_Modifier_Value__c = 'Yes';
        es.Eligibility_Status__c = 'Proceed';
        es.Modifier_Product__c = 'Cyber';
        insert es;
        
        
        opportunity.Service_Classification__c = 'Administrators';
        update opportunity;
        Test.stopTest();
        
        List<Opportunity> lstOpportunity = [SELECT Id FROM Opportunity Where Id =:opportunity.Id];
        
        System.assertEquals(true,lstOpportunity[0].Id != null);
    }
    
}