/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 08-05-2022
 * @last modified by  : Vinayesh
**/
@isTest
public with sharing class EndorsementTabLwcControllerTest {
    private static Opportunity submission;
    private static Opportunity submission1;
    private static Quote quote;
    private static Quote quote1;
    private static Coverage__c cov;
    private static Coverage__c cov1;
    private static List<UpdateObject> listUpdateObject;
    private static CoveragesLineItem__c cli;
    private static CoveragesLineItem__c cli1;
    public static Coverage_Limits_Deductibles__c ded;
    public static Coverage_Limits_Deductibles__c ded1;
    public static Product2 product;
    public static Account acc;
    static {
        GlobalStaticVar.byPassQuoteTrigger = true;
        // Create account
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account acc1  = TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster',
                                               'California','90000', 'United States');
        acc1.IsMailingSameWithBillingAddress__c = true;
        acc1.Date_Started__c = Date.today().addYears(-2);
        insert acc1;
        
        // Create product and coverage
        Product2 prd = new Product2(
            Name = 'MPL Standalone',
            Innovisk_Entity_ID__c = 'Celerity',
            Package_Indicator__c = true,
            IsActive = true,
            Expiration_Date__c = Date.today().addDays(200),
            Effective_Date__c = Date.today().addDays(-1)
        );
        insert prd;
        // Create opportunity
        submission = TestUtil.createOpportunity('Test opp', acc1.Id, prd.Id, Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId(), 'Celerity');
        submission.StageName = 'Qualified';
        submission.Coverage_Product_Options__c = '';
        insert submission;
        
        submission1 = TestUtil.createOpportunity('New Submission', acc1.Id, prd.Id, Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId(), 'Celerity');
        submission1.StageName = 'Qualified';
        submission1.Coverage_Product_Options__c = '';
        insert submission1;
        
        quote = TestUtil.createQuote('New Quote Test',submission.Id);
        quote.Coverage_Product_Options__c ='Cyber';        
        insert quote;
        
        quote1 = TestUtil.createQuote('New Quote Test',submission1.Id);
        quote1.Coverage_Product_Options__c ='Cyber';        
        insert quote1;
        
        cov = TestUtil.createCoverage('Coverage test', 'Cyber');
        cov.Endorsement_Categories__c = 'Test Category';
        cov.Endorsement_Tags__c = 'Business Services - Administrators';
        cov.Coverage_Type__c = 'Endorsement';
        cov.Coverage_Product__c = 'MPL';
        cov.Additional_Requirements__c = 'Schedule';
        insert cov;
        
        cov1 = TestUtil.createCoverage('MPL Manuscript Template', 'Cyber');
        cov1.Endorsement_Categories__c = 'Test Category';
        cov1.Endorsement_Tags__c = 'Business Services - Administrators';
        cov1.Coverage_Type__c = 'Endorsement';
        cov1.Coverage_Product__c = 'MPL';
        cov1.Additional_Requirements__c = 'Load by Default';
        cov1.RecordTypeId = Schema.SObjectType.Coverage__c.getRecordTypeInfosByName().get('Main Coverage').getRecordTypeId();
        insert cov1;
        
        
        //create limit deductables
        ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
        ded.Limit_Deductible_Type__c = 'Endorsement';
        insert ded;
        
        ded1 = TestUtil.creatLimitsDeductibles('Deductible test', cov1.Id);
        ded1.Limit_Deductible_Type__c = 'Endorsement';
        insert ded1;
        
        GlobalStaticVar.byPassCoverageLineItemTrigger = true;
        cli = new CoveragesLineItem__c();
        cli.Quote__c = quote.Id;
        cli.Coverage_Product__c = cov.Coverage_Product__c;
        cli.Coverage__c = cov.Id;
        cli.Limits_Deductibles__c = ded.Id;
        cli.Option_Value_Default__c = 'Coverage';
        insert cli;
        
        cli1 = new CoveragesLineItem__c();
        cli1.Quote__c = quote1.Id;
        cli1.Coverage_Product__c = cov1.Coverage_Product__c;
        cli1.Coverage__c = cov1.Id;
        cli1.Option_Value_Default__c = 'Coverage';
        insert cli1;
        
        //list update object
        listUpdateObject = new List<UpdateObject>();
        UpdateObject updateObj = new UpdateObject();
        updateObj.id = cli.Id;
        updateObj.value = 'Test';
        listUpdateObject.add(updateObj);
        
    }
    
    @isTest static void testGetCategoryOptions() {
        List<String> listCategories = new List<String>();
        Test.startTest();
        listCategories = EndorsementTabLwcController.getCategoryOptions(quote.Id);
        Test.stopTest();
        System.assertEquals(true, listCategories.size() > 0);
    }
    
    @isTest static void testSearchCoverage() {
        List<String> listCategories = new List<String>();
        List<Coverage__c> listCov = new List<Coverage__c>();
        listCov = EndorsementTabLwcController.searchCoverage('test', listCategories, quote.Id);
        listCategories.add('Business Services - Administrators');
        
        List<Coverage__c> existedCov = new List<Coverage__c>();
        existedCov.add(cov1);
        Test.startTest();
        GlobalStaticVar.byPassQuoteTrigger = true;
        listCov = EndorsementTabLwcController.searchCoverage('test', listCategories, quote.Id);
        quote.Layer__c='Excess';
        update quote;
         listCov = EndorsementTabLwcController.searchCoverage('test', listCategories, quote.Id);
        
        cov.Link_Document__c='';
        update cov;
        listCov = EndorsementTabLwcController.searchCoverage('test', listCategories, quote.Id);
        Test.stopTest();
        System.assertEquals(false, listCov.size() > 0);
    }
    
    @isTest static void testInsertEndorsementCLI() {
        ResultResponse result;
        Test.startTest();
        result = EndorsementTabLwcController.insertEndorsementCLI(String.valueOf(quote.Id), String.valueOf(cov.Id));
        Test.stopTest();
        System.assertEquals(true, result.isSuccess);
    }
    
    @isTest static void testGetEndorsementCLI() {
        String result = '';
        Test.startTest();
        result = String.valueOf(EndorsementTabLwcController.getEndorsementCLI(String.valueOf(quote.Id), String.valueOf(cov.Id)));
       Test.stopTest();
        System.assertEquals(true, result != '');
    }
    
    @isTest static void testSaveUpdatedCLI() {
        Test.startTest();
        ResultResponse result = new ResultResponse();
        CoveragesLineItem__c cli = [Select Id, Coverage__r.Id, Coverage__r.Name,IsSelected__c,
                                    Form_Number__c, Rating__c, Notes__c, Coverage__r.Link_Document__c, Coverage_Effective_Date__c,Is_Modified__c
                                    From CoveragesLineItem__c Limit 1];
        
        Map<Id, Coverage__c> mapCLItoCoverage = new Map<Id, Coverage__c>([SELECT Id, Name, Additional_Requirements__c,
                                                                          (SELECT Id, Name FROM FeaturesProductOptions__r) 
                                                                          FROM Coverage__c ]);
        EndorsementTabLwcController.Endorsement endor = new EndorsementTabLwcController.Endorsement(cli, mapCLItoCoverage);
        EndorsementTabLwcController.Endorsement endorseId= new EndorsementTabLwcController.Endorsement();
        endorseId.rating=true;
        result = EndorsementTabLwcController.saveUpdatedCLI(JSON.serialize(listUpdateObject), endorseId, quote1.Id);
        
        EndorsementTabLwcController.deleteEndorsementCLI(quote1.Id, cli1.Id);
        Test.stopTest();
        System.assertEquals(true, result!=null);
    }
    
    @isTest static void testGetSelectedCoverages() {
        List<Coverage__c> coverages = [SELECT Id, Name FROM Coverage__c];       
        List<String> listCoverage = new List<String>();
        Test.startTest();
        listCoverage = EndorsementTabLwcController.getSelectedCoverages(String.valueOf(quote.Id), coverages);
        Test.stopTest();
        System.assertEquals(true, listCoverage.size() > 0);
    }
    
    
    
    @isTest static void testAddNewRow() {
        EndorsementTabLwcController.EndorsementTable table = new EndorsementTabLwcController.EndorsementTable();
        Test.startTest();
        table = EndorsementTabLwcController.addNewRow(String.valueOf(quote.Id), String.valueOf(cov.Id));
              quote.Quote_Type__c='Amendment';
        update quote;
        table = EndorsementTabLwcController.addNewRow(String.valueOf(quote.Id), String.valueOf(cov.Id));
        Test.stopTest();
        System.assertEquals(true, table.data.size() > 0);
    }
    
    @isTest static void testDeleteRow() {
        List<String> listId = new List<String>();
        listId.add(String.valueOf(cli.Id));
        String result = '';
        Test.startTest();
        result = EndorsementTabLwcController.deleteRow(listId);
        Test.stopTest();
        System.assertEquals('success', result);
    }
    
    @isTest static void testAddEndorsementCLI() {
        Test.startTest();
        List<String> listCategories = new List<String>();
        List<Coverage__c> coverages = new List<Coverage__c>();
        coverages.add(cov1);
        
        ResultResponse result = EndorsementTabLwcController.addEndorsementCLI(String.valueOf(quote1.Id), coverages, listCategories);
         result = EndorsementTabLwcController.addEndorsementCLI(String.valueOf(quote1.Id), null, listCategories);
       
        cli1.Coverage__c=cov1.Id;
        update cli1;
          result = EndorsementTabLwcController.addEndorsementCLI(String.valueOf(quote1.Id), null, listCategories);
        quote1.Quote_Type__c='Amendment';
        quote1.Layer__c='Excess';
        update quote1;
        EndorsementTabLwcController.getSelectedEndorsement(String.valueOf(quote1.Id));
      
      
           EndorsementTabLwcController.getSelectedEndorsement(String.valueOf(quote1.Id));
        Test.stopTest();
        System.assertEquals(true, result!=NULL);
    }
    
    @isTest static void testSaveEndorsementCLI() {
        EndorsementTabLwcController.Endorsement endors = new EndorsementTabLwcController.Endorsement();
        endors.id = cli.Coverage__c;
        endors.cli = cli.Id;
        endors.note = 'test note';
        List<EndorsementTabLwcController.Endorsement> listEndorsement = new List<EndorsementTabLwcController.Endorsement>();
        listEndorsement.add(endors);
        ResultResponse result;
        Test.startTest();
        result = EndorsementTabLwcController.saveEndorsement(listEndorsement);
         result = EndorsementTabLwcController.saveEndorsement(null);
        Test.stopTest();
        System.assertEquals(true, result!=null);
    }
    
    @isTest static void testRemoveCLIByTag() {
        CoveragesLineItem__c cli = [Select Id, Coverage__r.Id, Coverage__r.Name,
                                    Coverage__r.Endorsement_Tags__c
                                    From CoveragesLineItem__c Limit 1];
        List<String> tags = new List<String>();
        tags.add('Business Services - Administrators');
        List<CoveragesLineItem__c> items = new List<CoveragesLineItem__c>();
        items.add(cli);
        Test.startTest();
        List<CoveragesLineItem__c> clis = EndorsementTabLwcController.removeCLIByTag(items, tags);
        Test.stopTest();
        System.assertEquals(true, clis.size() > 0);
    }
    
    @isTest static void testCheckIsShowed() {
        List<CoveragesLineItem__c> clis = [Select Id, Coverage__r.Id, Coverage__r.Name, Option_Value_Default__c,
                                           Coverage__r.Endorsement_Tags__c
                                           From CoveragesLineItem__c Limit 1];
        Map<String, List<CoveragesLineItem__c>> mapMainCLI = new Map<String, List<CoveragesLineItem__c>>();
        mapMainCLI.put(clis[0].Coverage__r.Id, clis);
        Test.startTest();
        Boolean isShowed = EndorsementTabLwcController.checkIsShowed(clis[0].Coverage__r.Id, mapMainCLI);
        Test.stopTest();
        System.assertEquals(true, isShowed);
    }
    
    
    public class UpdateObject {
        public String id {get;set;}
        public String value {get;set;}
        public UpdateObject() {
            this.id = '';
            this.value = '';
        }
    }
    
    @isTest static void testAQ(){
        
      TriggerSettings__c setting = new TriggerSettings__c();
  		setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        setting.BypassCoverageLineItemTrigger__c = true;
        //setting.BypassAccountTrigger__c = true;
        setting.BypassCoverageTrigger__c = true;
        
        insert setting;
        
        Test.startTest();
        acc = TestUtil.createBusinessAccount('AQ Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
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
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, prod.Id);
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        opp.CloseDate = Date.today();
        opp.Innovisk_Entity_ID__c = 'Aqueous';        
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        
        opp.StageName = 'Qualified';
        opp.Expiration_Date__c = Date.today()+60;
        insert opp;
       // Test.startTest();
        Quote quote1 = TestUtil.createQuote('New quote', opp.Id);
        quote1.Layer__c = 'Primary';
        quote1.Status = 'In Progress';
        quote1.Refer_Type__c = 'Underwriting Referral';
        quote1.Coverage_Product_Options__c = 'Professional Indemnity';
        //quote1.Is_Quote_Approved_AQ__c = 'Approved';
        insert quote1;
        
        Quote quote = [select Id,Is_Quote_Approved_AQ__c from Quote where Id=:quote1.Id];    
        system.debug('value: '+quote); 
        quote1.Status = 'Quoted';
        quote1.Effective_Date__c = date.today() + 24;
        update quote1;
        List<String> listCategories = new List<String>();
        listCategories.add('Business Services - Administrators');
        List<Coverage__c> listCov = new List<Coverage__c>();
        Coverage__c coverage = TestUtil.createCoverage('Coverage test', 'Professional Indemnity');
        insert coverage;
        listCov.add(coverage);
        List<Coverage__c> existedCov = new List<Coverage__c>();
        existedCov.add(cov1);
        
        //Create coverage
        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'Professional Indemnity');
        insert cov;            
        cov.Additional_Requirements__c='Part-Fixed';
        update cov;
        //create limit deductables
        Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
        //ded.LmtDedCode__c = 'CelerityExcessLimit';
        insert ded;
        
        // Coverages Line Item
        CoveragesLineItem__c coverLi = new CoveragesLineItem__c();
        coverLi.Coverage__c  = cov1.Id; 
        coverLi.Quote__c = quote1.Id;
        coverLi.Limits_Deductibles__c = ded.Id;
        coverLi.Coverage_Premium__c  = 'Text Premium'; 
        coverLi.Min_amt__c  = 1000;
        coverLi.Max_amt__c  = 5000;
        coverLi.Deductible_Frequency__c  = 'Daily';
        coverLi.Options_Value_Percent__c  = 5;
        coverLi.Coverage_Product__c='Excess';
        insert coverLi;
        coverLi.Coverage_Type__c='Endorsement';
        update coverLi;
        ded.LmtDedCode__c = coverLi.Limits_Deductibles__c;
        update ded;
        
        cov1.Coverage_Code__c = coverLi.Coverage__c;
        update cov1;
        ResultResponse result;
        //EndorsementTabLwcController.getSelectedEndorsement(quote1.Id);
        listCov = EndorsementTabLwcController.searchCoverage('test', listCategories, quote1.Id);
        result = EndorsementTabLwcController.addEndorsementCLI(String.valueOf(quote1.Id), listCov, listCategories);
        Test.stopTest();
        System.assertEquals(false, listCov.size() > 0);
        
    } 
}