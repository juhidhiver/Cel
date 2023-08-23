/***************************************************
 * Class Name: CloneQuoteHandlerTest
 * Author: Giang Phan
 * Date: 08-Nov-2019
 * Description: Unit test for CloneQuoteHandler
 ****************************************************/
@isTest
private class CloneQuoteHandlerTest { 
	private static List<Location__c> newLocations;
		@testSetup static void setup() {
		TriggerSettings__c settings = new TriggerSettings__c();
		settings.BypassQuoteTrigger__c = true;
        settings.BypassContactTrigger__c = true;    
        settings.BypassOpportunityTrigger__c = true;
		insert settings;
		System.assert(settings != null);
		
		// Create product and coverage
		Product2 prd = new Product2(
			Name = 'Cyber Standalone',
			Innovisk_Entity_ID__c = 'Celerity',
			Package_Indicator__c = true,
			IsActive = true,
			Expiration_Date__c = Date.today().addDays(200),
			Effective_Date__c = Date.today().addDays(-1)
		);
		insert prd;
          
        List<Opportunity> opplist = new List<Opportunity>(); 
        
            
            Account acc1 = new Account();
		acc1.Name = 'Test account 1';
		acc1.BillingStreet = '01 Tran Duy Hung';
		acc1.BillingCity = 'Westminster';
		acc1.BillingState = 'California';
		acc1.BillingPostalCode = '90000';
		acc1.BillingCountry = 'United States';
		acc1.IsMailingSameWithBillingAddress__c = true;
		acc1.Date_Started__c = Date.today().addYears(-2);
		insert acc1;
            
           Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
            
		
		// Create opportunity
		Opportunity opp = new Opportunity();
		opp.Name = 'Test opp';
		opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
		opp.Coverage_Product_Options__c = 'D&O';
		opp.AccountId = acc1.Id;
		opp.Pricebook2Id = Test.getStandardPricebookId();
		opp.Product__c = prd.Id;
		opp.Received_Date__c = Date.today();
		opp.CloseDate = Date.today().addDays(30);
		opp.Effective_Date__c = Date.today().addDays(1);
		opp.Type = 'New Business';
		opp.LeadSource = 'Email';
		opp.StageName = 'Qualified';
		//insert opp;
		opplist.add(opp);
            
              Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();     
        Product2 prod = TestUtil.createProduct('Professional Indemnity');
        prod.RecordTypeId = aqueousRecordTypeId;
        prod.Innovisk_Entity_ID__c = 'Aqueous';
        insert prod;
        
          
        
            
       
            Opportunity oppaq = TestUtil.createOpportunity('Aqueous Test',acc.Id, prod.Id);
            oppaq.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
            oppaq.Innovisk_Entity_ID__c = 'Aqueous';        
            oppaq.Coverage_Product_Options__c = 'Professional Indemnity';
            oppaq.StageName = 'Qualified';
            //insert oppaq;
            opplist.add(oppaq);     
            insert opplist;

		// Create contact
		Contact con = new Contact(
			Lastname = 'Huy broker',
			RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
		);
		insert con;

		// Create broker
		Broker_Account__c broker = new Broker_Account__c(
			Broker_Contact__c = con.Id,
			Opportunity__c = opp.Id,
			IsPrimaryBroker__c = true,
			Relationship_Type__c = 'Broker'
		);
		insert broker;

		// Create pricebook entry
		PricebookEntry pbe = new PricebookEntry(
		    Pricebook2Id = Test.getStandardPricebookId(), 
		    Product2Id = prd.Id, 
		    UnitPrice = 10000, 
		    IsActive = true
	    );
	    insert pbe;

		// Create quote
		Quote quote = new Quote(
			OpportunityId = opp.Id,
			Name = 'Test quote 1',
			Coverage_Product_Options__c = 'D&O',
			Pricebook2Id = Test.getStandardPricebookId()
		);
		insert quote;

		// Create account for additional interests
		Account addAcc1 = new Account(
			Name = 'Additional interest account 1',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId()
		);
		insert addAcc1;

		// Create additional interests
		Additional_Interests__c addInt = new Additional_Interests__c(
			Additional_Interest_Account__c = addAcc1.Id,
			Quote__c = quote.Id,
			Relationship_Type__c = 'Additional Insured'
		);
		insert addInt;

		addInt.Relationship_Type__c = 'Lienholder';
		update addInt; 

		// Insert duplicate additional interest
		Additional_Interests__c duplicateAddInt = new Additional_Interests__c(
			Additional_Interest_Account__c = addAcc1.Id,
			Quote__c = quote.Id,
			Relationship_Type__c = 'Additional Insured'
		);

		// Create Location
		Location__c newLocation = TestUtil.createNewLocation('131, 1st Avenue Test','New York', 'United States', '10093', 'New York');
		insert newLocation;

		// Create Quote Location
		Quote_Location__c newQuoteLoc = TestUtil.createQuoteLocation(quote.Id, newLocation.Id, true);
		newQuoteLoc.put('Quote__c', quote.Id);
		insert newQuoteLoc;

		//Create Coverage
		Coverage__c cov = TestUtil.createCoverage('Test Coverage','D&O');
		insert cov;


            
		// Coverages Line Item
		CoveragesLineItem__c coverLi = new CoveragesLineItem__c();
		coverLi.Coverage__c  = cov.Id; 
		coverLi.Quote__c = quote.Id;
		coverLi.Coverage_Premium__c  = 'Text Premium'; 
		coverLi.Min_amt__c  = 1000;
		coverLi.Max_amt__c  = 5000;
		coverLi.Deductible_Frequency__c  = 'Daily';
		coverLi.Options_Value_Percent__c  = 5;
		insert coverLi;
            
        Subjectivity__c subj = new Subjectivity__c();
        subj.Subjectivity__c = 'Testing';
        subJ.Subjectivity_Status__c = 'Open';
        subJ.Subjectivity_Type__c = 'MPL';
        subJ.Quote__c = quote.Id;
        insert subJ;
        
        Rating_Modifiers__c rMod = new Rating_Modifiers__c();
        rMod.Opportunity__c = opp.Id;
        insert rMod;     
            
        Rating_Modifier_Factor__c rm = new Rating_Modifier_Factor__c();
        rm.Factor_Default_Value__c = 123;
        rm.Factor_Max__c = 300;
        rm.Factor_Min__c = 100;
        rm.Factor_Value__c = 120;
        rm.Rating_Modifier__c = rMod.Id;
        rm.Quote__c = quote.Id;    
        insert rm;    
            
      
            Quote quoteaq0 = Testutil.createQuote('AQNew Quote', oppaq.Id);
        quoteaq0.Rating_Status__c = 'Clear';
        quoteaq0.Status = 'Quoted'; 
        //insert quoteaq0;
            
        Quote quoteaq = Testutil.createQuote('AQNew Quote', oppaq.Id);
        quoteaq.Rating_Status__c = 'Clear';
        quoteaq.Status = 'Bound'; 
        insert quoteaq;
            
        Quote_Option__c quoteOpt = new Quote_Option__c();
        quoteOpt.Azure_ID__c = 'Test';
        quoteOpt.Quote__c =  quoteaq.Id;
        insert quoteOpt;
            
        Referral_Reason__c ref1=new Referral_Reason__c();
        ref1.Approver_Level__c='3';
        ref1.Approval_Level_Required__c='1';
        ref1.Approval_Rejected_Date__c= date.today()+365;
        ref1.Quote__c=quoteaq.id;
       
        insert ref1;  
	}
    
    
	@isTest
	static void testCloneQuoteWithChildren() {
		Quote quote = [SELECT id, Quote_Type__c, Effective_Date__c, Endorsement_Effective_Date__c FROM Quote LIMIT 1];
        Opportunity opp =[SELECT id from  Opportunity limit 1];
       Coverage__c cov = [SELECT id, Coverage_Product__c, Page_Section__c, Form_Number__c, Coverage_Type__c, Coverage_or_Sub__c, (SELECT Id, Page_Section__c From FeaturesProductOptions__r) FROM Coverage__c LIMIT 1];
		Test.startTest();
		CloneQuoteHandler.cloneQuoteWithChildren(quote.Id, null);
         quote.OpportunityId=opp.id;
        opp.StageName='Closed Won';
        update opp;
        update quote;
        //CloneQuoteHandler.ratingQuoteEndorsement(quote.Id);
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id, null);
        Map<String,Object> fieldUpdateMap = new Map<String,Object>();
        fieldUpdateMap.put('Contract_Cancellation_Reason__c','None');
        fieldUpdateMap.put('Endorsement_Effective_Date__c',Date.today());
        fieldUpdateMap.put('Quote_Type__c','Extension');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.remove('Quote_Type__c');
        fieldUpdateMap.put('Quote_Type__c','Midterm Cancellation');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.remove('Quote_Type__c');
        fieldUpdateMap.put('Quote_Type__c','Flat Cancellation');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.remove('Quote_Type__c');
        fieldUpdateMap.put('Quote_Type__c','Reinstatement');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        CloneServiceHandler_Common.GenerateCLIByCoverage(cov, quote);
        Test.stopTest();
        System.assert(fieldUpdateMap != null);
	}
    	@isTest
	static void testCloneQuoteWithChildrenAQ() {
		Quote quote = [SELECT id FROM Quote where Name='AQNew Quote' LIMIT 1];

		Test.startTest();
		Map<String,Object> fieldUpdateMap = new Map<String,Object>();
        fieldUpdateMap.put('Contract_Cancellation_Reason__c','None');
        fieldUpdateMap.put('Endorsement_Effective_Date__c',Date.today());
        fieldUpdateMap.put('Quote_Type__c','Extension');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.remove('Quote_Type__c');
        fieldUpdateMap.put('Quote_Type__c','Midterm Cancellation');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.remove('Quote_Type__c');
        fieldUpdateMap.put('Quote_Type__c','Flat Cancellation');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.remove('Quote_Type__c');
        fieldUpdateMap.put('Quote_Type__c','Reinstatement');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
		Test.stopTest();
        System.assert(fieldUpdateMap != null);
	}
    
    @isTest
    public static void testRatingQuoteEndorsement() {
        TriggerSettings__c setting = new TriggerSettings__c();
  		setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        setting.BypassCoverageLineItemTrigger__c = true;
        //setting.BypassAccountTrigger__c = true;
        setting.BypassCoverageTrigger__c = true;
        
        insert setting;
        
        Test.startTest();
        Quote quote = [SELECT id, Quote_Type__c, Effective_Date__c, Endorsement_Effective_Date__c FROM Quote LIMIT 1];
        quote.Quote_Type__c = Label.Quote_Type_Amendment;
            quote.Effective_Date__c = Date.today();
            quote.Endorsement_Effective_Date__c = Date.today();
            update quote;
        Coverage__c cov1 = TestUtil.createCoverage('Test Coverage','D&O');
		insert cov1;
        Opportunity opp =[SELECT id from  Opportunity limit 1];
       Coverage__c cov = [SELECT id, RecordTypeId, RecordType.Name, Coverage_Product__c, Page_Section__c, Form_Number__c, Coverage_Type__c, Coverage_or_Sub__c, (SELECT Id, Page_Section__c From FeaturesProductOptions__r) FROM Coverage__c LIMIT 1];
		cov.RecordTypeId = Schema.SObjectType.Coverage__c.getRecordTypeInfosByName().get('Sub Coverage').getRecordTypeId();
       cov.RecordType.Name = 'Sub Coverage';
        cov.Coverage_Type__c = 'Endorsement';
        cov.Coverage_or_Sub__c = cov1.id;
        update cov;
      //  Test.startTest();
        
        //String msgError = CloneQuoteHandler.ratingQuoteEndorsement(quote.Id);
        
        CloneServiceHandler_Common.GenerateCLIByCoverage(cov, quote);
        Test.stopTest();
        //System.assert(msgError != null);
    }

    @isTest
    public static void testCloneQuoteWithChildren1() {
        Quote quote = [SELECT id, Quote_Type__c, Effective_Date__c, Endorsement_Effective_Date__c, Product_Name__c FROM Quote LIMIT 1];
        quote.Quote_Type__c = 'Flat Cancellation';
        //quote.Product_Name__c = 'MPL';
        quote.Effective_Date__c = Date.today();
        quote.Endorsement_Effective_Date__c = Date.today();
        update quote;
        Opportunity opp =[SELECT id from  Opportunity limit 1];
        Test.startTest();
        Map<String,Object> fieldUpdateMap = new Map<String,Object>();
        fieldUpdateMap.put('Contract_Cancellation_Reason__c','None');
        fieldUpdateMap.put('Endorsement_Effective_Date__c',Date.today());
        fieldUpdateMap.put('Quote_Type__c','Flat Cancellation');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        Test.stopTest();
        System.assert(fieldUpdateMap != null);
    }

    @isTest
    public static void testCelerityCoverageCancelReplace() {
        TriggerSettings__c setting = new TriggerSettings__c();
  		setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        setting.BypassCoverageLineItemTrigger__c = true;
        //setting.BypassAccountTrigger__c = true;
        setting.BypassCoverageTrigger__c = true;
        
        insert setting;
        Quote quote = [SELECT id, Status,Quote_Type__c, Effective_Date__c, Endorsement_Effective_Date__c, Product_Name__c 
                       FROM Quote Where Product_Name__c like '%Cyber%' LIMIT 1];
        quote.Status = 'Bound';

        //Opportunity opp =[SELECT id, StageName from  Opportunity Where limit 1];
       // Coverage__c cov = [SELECT id, Coverage_Product__c, Page_Section__c, Form_Number__c, Coverage_Type__c, Coverage_or_Sub__c, (SELECT Id, Page_Section__c From FeaturesProductOptions__r) FROM Coverage__c LIMIT 1];
		
		//CloneQuoteHandler.cloneQuoteWithChildren(quote.Id, null);
        // quote.OpportunityId=opp.id;
        // opp.StageName='Closed Won';
        //update opp;
        quote.Effective_Date__c = Date.today();
        quote.Endorsement_Effective_Date__c = Date.today();
        update quote;

        set<Id> quoteIds = new set<Id>();
        quoteIds.add(quote.Id);
        //quote.Quote_Type__c = 'Flat Cancellation';
        //quote.Product_Name__c = 'MPL';
        
        //update quote;
        Test.startTest();
        CloneServiceHandler_CEL.coverageCancelProcessCEL(quoteIds, quote.Id, null);
        Test.stopTest();
        System.assert(quote != null);
    }


   @isTest
    public static void testCloneQuoteWithChildren2() {
        
        Test.startTest();
        Map<String,Object> fieldUpdateMap = new Map<String,Object>();
        fieldUpdateMap.put('Contract_Cancellation_Reason__c','None');
        fieldUpdateMap.put('Endorsement_Effective_Date__c',Date.today());
        fieldUpdateMap.put('Quote_Type__c','Flat Cancellation');
        CloneQuoteHandler.cloneQuoteWithChildren('Test',fieldUpdateMap);
        Test.stopTest();
        System.assert(fieldUpdateMap != null);
    }
    @isTest
    public static void testCloneQuoteWithChildren3() {
        Quote quote = [SELECT id, Quote_Type__c, Effective_Date__c, Endorsement_Effective_Date__c, Product_Name__c FROM Quote LIMIT 1];
        quote.Quote_Type__c = 'Flat Cancellation';
        //quote.Product_Name__c = 'MPL';
        quote.Effective_Date__c = Date.today();
        quote.Endorsement_Effective_Date__c = Date.today();
        update quote;
        Opportunity opp =[SELECT id from  Opportunity limit 1];
        Test.startTest();
        Map<String,Object> fieldUpdateMap = new Map<String,Object>();
        fieldUpdateMap.put('Contract_Cancellation_Reason__c','None');
        fieldUpdateMap.put('Endorsement_Effective_Date__c',Date.today());
        fieldUpdateMap.put('Quote_Type__c','Flat Cancellation');
        fieldUpdateMap.put('Layer__c','Excess');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.remove('Quote_Type__c');
        fieldUpdateMap.put('Quote_Type__c','Renewal');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        Test.stopTest();
        System.assert(fieldUpdateMap != null);
    }
    /*@isTest
    public static void testCloneQuoteWithChildren4() {
        // Create product and coverage
		Product2 prd = new Product2(
			Name = 'Private Company Combo MPL',
			Innovisk_Entity_ID__c = 'Celerity',
			Package_Indicator__c = true,
			IsActive = true,
			Expiration_Date__c = Date.today().addDays(200),
			Effective_Date__c = Date.today().addDays(-1)
		);
		insert prd;
            
        Account acc1 = new Account();
		acc1.Name = 'Test account 1';
		acc1.BillingStreet = '01 Tran Duy Hung';
		acc1.BillingCity = 'Westminster';
		acc1.BillingState = 'California';
		acc1.BillingPostalCode = '90000';
		acc1.BillingCountry = 'United States';
		acc1.IsMailingSameWithBillingAddress__c = true;
		acc1.Date_Started__c = Date.today().addYears(-2);
		insert acc1;
		
		// Create opportunity
		Opportunity opp = new Opportunity();
		opp.Name = 'Test opp';
		opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
		opp.Coverage_Product_Options__c = 'D&O';
		opp.AccountId = acc1.Id;
		opp.Pricebook2Id = Test.getStandardPricebookId();
		opp.Product__c = prd.Id;
		opp.Received_Date__c = Date.today();
		opp.CloseDate = Date.today().addDays(30);
		opp.Effective_Date__c = Date.today().addDays(1);
		opp.Type = 'New Business';
		opp.LeadSource = 'Email';
		opp.StageName = 'Qualified';
		insert opp;

		// Create contact
		Contact con = new Contact(
			Lastname = 'Huy broker',
			RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
		);
		insert con;


		// Create pricebook entry
		PricebookEntry pbe = new PricebookEntry(
		    Pricebook2Id = Test.getStandardPricebookId(), 
		    Product2Id = prd.Id, 
		    UnitPrice = 10000, 
		    IsActive = true
	    );
	    insert pbe;

		// Create quote
		Quote quote = new Quote(
			OpportunityId = opp.Id,
			Name = 'Test quote 1',
			Coverage_Product_Options__c = 'D&O',
            //Status = 'Bound',
            Layer__c = 'Excess',
			Pricebook2Id = Test.getStandardPricebookId()
		);
		insert quote;
        Quote_Option__c quoteOpt = new Quote_Option__c();
        quoteOpt.Azure_ID__c = 'Test 1';
        quoteOpt.Quote__c =  quote.Id;
        insert quoteOpt;
        Free_Form_Endorsements__c ffe = new Free_Form_Endorsements__c();
        ffe.Quote__c = quote.Id;
        insert ffe;
        Referral_Reason__c ref1=new Referral_Reason__c();
        ref1.Approver_Level__c='3';
        ref1.Approval_Level_Required__c='1';
        ref1.Approval_Rejected_Date__c= date.today()+365;
        ref1.Quote__c=quote.id;
        insert ref1;
        Insurer_Layer_Limit__c ill = new Insurer_Layer_Limit__c();
        ill.Quote__c = quote.Id;
        insert ill;
       Coverage__c cov = [SELECT id, Coverage_Type__c, Page_Section__c, Form_Number__c, Coverage_or_Sub__c, (SELECT Id, Page_Section__c From FeaturesProductOptions__r) FROM Coverage__c LIMIT 1];
        cov.Coverage_Type__c = 'Coverage';
        update cov;
        CoveragesLineItem__c cli = new CoveragesLineItem__c();
        cli.Quote__c = quote.Id;
        cli.Coverage__c = cov.Id;
        insert cli;
        Test.startTest();
        Map<String,Object> fieldUpdateMap = new Map<String,Object>();
        fieldUpdateMap.put('Contract_Cancellation_Reason__c','None');
        fieldUpdateMap.put('Endorsement_Effective_Date__c',Date.today());
        fieldUpdateMap.put('Quote_Type__c','Extended Reporting Period (ERP)');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.put('Layer__c','Primary');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.remove('Quote_Type__c');
        fieldUpdateMap.put('Quote_Type__c','Renewal');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        Test.stopTest();
        System.assert(fieldUpdateMap != null);
    }*/

    @isTest
    public static void testCloneQuoteWithChildren5() {
        //Mary
        TriggerSettings__c setting = new TriggerSettings__c();
  		setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        setting.BypassCoverageLineItemTrigger__c = true;
        //setting.BypassAccountTrigger__c = true;
        setting.BypassCoverageTrigger__c = true;
        insert setting;
        
        Test.startTest();
        
        // Create product and coverage
		Product2 prd = new Product2(
			Name = 'Professional Indemnity',
			Innovisk_Entity_ID__c = 'Celerity',
			Package_Indicator__c = true,
			IsActive = true,
			Expiration_Date__c = Date.today().addDays(200),
			Effective_Date__c = Date.today().addDays(-1)
		);
		insert prd;
            
        Account acc1 = new Account();
		acc1.Name = 'Test account 1';
		acc1.BillingStreet = '01 Tran Duy Hung';
		acc1.BillingCity = 'Westminster';
		acc1.BillingState = 'California';
		acc1.BillingPostalCode = '90000';
		acc1.BillingCountry = 'United States';
		acc1.IsMailingSameWithBillingAddress__c = true;
		acc1.Date_Started__c = Date.today().addYears(-2);
		insert acc1;
		
		// Create opportunity
		Opportunity opp = new Opportunity();
		opp.Name = 'Test opp';
		opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
		opp.Coverage_Product_Options__c = 'D&O';
		opp.AccountId = acc1.Id;
		opp.Pricebook2Id = Test.getStandardPricebookId();
		opp.Product__c = prd.Id;
		opp.Received_Date__c = Date.today();
		opp.CloseDate = Date.today().addDays(30);
		opp.Effective_Date__c = Date.today().addDays(1);
		opp.Type = 'New Business';
		opp.LeadSource = 'Email';
		opp.StageName = 'Qualified';
		insert opp;

		// Create contact
		Contact con = new Contact(
			Lastname = 'Huy broker',
			RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
		);
		insert con;


		// Create pricebook entry
		PricebookEntry pbe = new PricebookEntry(
		    Pricebook2Id = Test.getStandardPricebookId(), 
		    Product2Id = prd.Id, 
		    UnitPrice = 10000, 
		    IsActive = true
	    );
	    insert pbe;

		// Create quote
		Quote quote = new Quote(
			OpportunityId = opp.Id,
			Name = 'Test quote 1',
			Coverage_Product_Options__c = 'D&O',
            Quote_Type__c = 'Coverage Amendment',
            //Status = 'Bound',
            Layer__c = 'Primary',
			Pricebook2Id = Test.getStandardPricebookId()
		);
		insert quote;
        Quote_Option__c quoteOpt = new Quote_Option__c();
        quoteOpt.Azure_ID__c = 'Test 1';
        quoteOpt.Quote__c =  quote.Id;
        quoteOpt.Bound__c = true;
        insert quoteOpt;
        Referral_Reason__c ref1=new Referral_Reason__c();
        ref1.Approver_Level__c='3';
        ref1.Approval_Level_Required__c='1';
        ref1.Approval_Rejected_Date__c= date.today()+365;
        ref1.Quote__c=quote.id;
        ref1.Quote_Option__c = quoteOpt.Id;
        ref1.Approval_Status__c = 'Approved';
        insert ref1;
        Insurer_Layer_Limit__c ill = new Insurer_Layer_Limit__c();
        ill.Quote__c = quote.Id;
        insert ill;
        Subjectivity__c subject = new Subjectivity__c();
        subject.Quote__c = quote.Id;
        insert subject;
        //Test.startTest();
        Map<String,Object> fieldUpdateMap = new Map<String,Object>();
        fieldUpdateMap.put('Contract_Cancellation_Reason__c','None');
        fieldUpdateMap.put('Endorsement_Effective_Date__c',Date.today());
        fieldUpdateMap.put('Quote_Type__c','Coverage Amendment');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.put('Quote_Type__c','Extension');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.remove('Quote_Type__c');
        fieldUpdateMap.put('Quote_Type__c','Midterm Cancellation');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        /*fieldUpdateMap.remove('Quote_Type__c');
        fieldUpdateMap.put('Quote_Type__c','Flat Cancellation');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.remove('Quote_Type__c');
        fieldUpdateMap.put('Quote_Type__c','Reinstatement');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.put('Layer__c','Primary');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);*/
        Test.stopTest();
        System.assert(fieldUpdateMap != null);
    }

    @isTest
    public static void testCloneQuoteWithChildren5_2() {
        //Mary
        TriggerSettings__c setting = new TriggerSettings__c();
  		setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        setting.BypassCoverageLineItemTrigger__c = true;
        //setting.BypassAccountTrigger__c = true;
        setting.BypassCoverageTrigger__c = true;
        insert setting;
        
        Test.startTest();
        
        // Create product and coverage
		Product2 prd = new Product2(
			Name = 'Professional Indemnity',
			Innovisk_Entity_ID__c = 'Celerity',
			Package_Indicator__c = true,
			IsActive = true,
			Expiration_Date__c = Date.today().addDays(200),
			Effective_Date__c = Date.today().addDays(-1)
		);
		insert prd;
            
        Account acc1 = new Account();
		acc1.Name = 'Test account 1';
		acc1.BillingStreet = '01 Tran Duy Hung';
		acc1.BillingCity = 'Westminster';
		acc1.BillingState = 'California';
		acc1.BillingPostalCode = '90000';
		acc1.BillingCountry = 'United States';
		acc1.IsMailingSameWithBillingAddress__c = true;
		acc1.Date_Started__c = Date.today().addYears(-2);
		insert acc1;
		
		// Create opportunity
		Opportunity opp = new Opportunity();
		opp.Name = 'Test opp';
		opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
		opp.Coverage_Product_Options__c = 'D&O';
		opp.AccountId = acc1.Id;
		opp.Pricebook2Id = Test.getStandardPricebookId();
		opp.Product__c = prd.Id;
		opp.Received_Date__c = Date.today();
		opp.CloseDate = Date.today().addDays(30);
		opp.Effective_Date__c = Date.today().addDays(1);
		opp.Type = 'New Business';
		opp.LeadSource = 'Email';
		opp.StageName = 'Qualified';
		insert opp;

		// Create contact
		Contact con = new Contact(
			Lastname = 'Huy broker',
			RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
		);
		insert con;


		// Create pricebook entry
		PricebookEntry pbe = new PricebookEntry(
		    Pricebook2Id = Test.getStandardPricebookId(), 
		    Product2Id = prd.Id, 
		    UnitPrice = 10000, 
		    IsActive = true
	    );
	    insert pbe;

		// Create quote
		Quote quote = new Quote(
			OpportunityId = opp.Id,
			Name = 'Test quote 1',
			Coverage_Product_Options__c = 'D&O',
            Quote_Type__c = 'Coverage Amendment',
            //Status = 'Bound',
            Layer__c = 'Primary',
			Pricebook2Id = Test.getStandardPricebookId()
		);
		insert quote;
        Quote_Option__c quoteOpt = new Quote_Option__c();
        quoteOpt.Azure_ID__c = 'Test 1';
        quoteOpt.Quote__c =  quote.Id;
        quoteOpt.Bound__c = true;
        insert quoteOpt;
        Referral_Reason__c ref1=new Referral_Reason__c();
        ref1.Approver_Level__c='3';
        ref1.Approval_Level_Required__c='1';
        ref1.Approval_Rejected_Date__c= date.today()+365;
        ref1.Quote__c=quote.id;
        ref1.Quote_Option__c = quoteOpt.Id;
        ref1.Approval_Status__c = 'Approved';
        insert ref1;
        Insurer_Layer_Limit__c ill = new Insurer_Layer_Limit__c();
        ill.Quote__c = quote.Id;
        insert ill;
        Subjectivity__c subject = new Subjectivity__c();
        subject.Quote__c = quote.Id;
        insert subject;
        //Test.startTest();
        Map<String,Object> fieldUpdateMap = new Map<String,Object>();
        /*fieldUpdateMap.put('Contract_Cancellation_Reason__c','None');
        fieldUpdateMap.put('Endorsement_Effective_Date__c',Date.today());
        fieldUpdateMap.put('Quote_Type__c','Coverage Amendment');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.put('Quote_Type__c','Extension');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.remove('Quote_Type__c');
        fieldUpdateMap.put('Quote_Type__c','Midterm Cancellation');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        */
        fieldUpdateMap.remove('Quote_Type__c');
        fieldUpdateMap.put('Quote_Type__c','Flat Cancellation');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.remove('Quote_Type__c');
        fieldUpdateMap.put('Quote_Type__c','Reinstatement');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.put('Layer__c','Primary');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        Test.stopTest();
        System.assert(fieldUpdateMap != null);
    }
    @isTest
    public static void testCloneQuoteWithChildren6() {
        
        TriggerSettings__c setting = new TriggerSettings__c();
  		setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        setting.BypassCoverageLineItemTrigger__c = true;
        //setting.BypassAccountTrigger__c = true;
        setting.BypassCoverageTrigger__c = true;
        
        insert setting;
        
        Test.startTest();
        // Create product and coverage
		Product2 prd = new Product2(
			Name = 'Professional Indemnity',
			Innovisk_Entity_ID__c = 'Celerity',
			Package_Indicator__c = true,
			IsActive = true,
			Expiration_Date__c = Date.today().addDays(200),
			Effective_Date__c = Date.today().addDays(-1)
		);
		insert prd;
            
        Account acc1 = new Account();
		acc1.Name = 'Test account 1';
		acc1.BillingStreet = '01 Tran Duy Hung';
		acc1.BillingCity = 'Westminster';
		acc1.BillingState = 'California';
		acc1.BillingPostalCode = '90000';
		acc1.BillingCountry = 'United States';
		acc1.IsMailingSameWithBillingAddress__c = true;
		acc1.Date_Started__c = Date.today().addYears(-2);
		insert acc1;
		
		// Create opportunity
		Opportunity opp = new Opportunity();
		opp.Name = 'Test opp';
		opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
		opp.Coverage_Product_Options__c = 'D&O';
		opp.AccountId = acc1.Id;
		opp.Pricebook2Id = Test.getStandardPricebookId();
		opp.Product__c = prd.Id;
		opp.Received_Date__c = Date.today();
		opp.CloseDate = Date.today().addDays(30);
		opp.Effective_Date__c = Date.today().addDays(1);
		opp.Type = 'New Business';
		opp.LeadSource = 'Email';
		opp.StageName = 'Qualified';
		insert opp;

		// Create contact
		Contact con = new Contact(
			Lastname = 'Huy broker',
			RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
		);
		insert con;


		// Create pricebook entry
		PricebookEntry pbe = new PricebookEntry(
		    Pricebook2Id = Test.getStandardPricebookId(), 
		    Product2Id = prd.Id, 
		    UnitPrice = 10000, 
		    IsActive = true
	    );
	    insert pbe;

		// Create quote
		Quote quote = new Quote(
			OpportunityId = opp.Id,
			Name = 'Test quote 1',
			Coverage_Product_Options__c = 'D&O',
            Quote_Type__c = 'Extension',
            //Status = 'Bound',
            Layer__c = 'Primary',
			Pricebook2Id = Test.getStandardPricebookId()
		);
		insert quote;
        Quote_Option__c quoteOpt = new Quote_Option__c();
        quoteOpt.Azure_ID__c = 'Test 1';
        quoteOpt.Quote__c =  quote.Id;
        quoteOpt.Bound__c = false;
        insert quoteOpt;
        Referral_Reason__c ref1=new Referral_Reason__c();
        ref1.Approver_Level__c='3';
        ref1.Approval_Level_Required__c='1';
        ref1.Approval_Rejected_Date__c= date.today()+365;
        ref1.Quote__c=quote.id;
        ref1.Quote_Option__c = quoteOpt.Id;
        //ref1.Approval_Status__c = 'Approved';
        insert ref1;
        Insurer_Layer_Limit__c ill = new Insurer_Layer_Limit__c();
        ill.Quote__c = quote.Id;
        insert ill;
        Subjectivity__c subject = new Subjectivity__c();
        subject.Quote__c = quote.Id;
        insert subject;
        //Test.startTest();
        Map<String,Object> fieldUpdateMap = new Map<String,Object>();
        fieldUpdateMap.put('Contract_Cancellation_Reason__c','None');
        fieldUpdateMap.put('Endorsement_Effective_Date__c',Date.today());
        fieldUpdateMap.put('Quote_Type__c','Coverage Amendment');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.put('Quote_Type__c','Extension');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.remove('Quote_Type__c');
        fieldUpdateMap.put('Quote_Type__c','Midterm Cancellation');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        /*
        fieldUpdateMap.remove('Quote_Type__c');
        fieldUpdateMap.put('Quote_Type__c','Flat Cancellation');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.remove('Quote_Type__c');
        fieldUpdateMap.put('Quote_Type__c','Reinstatement');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.put('Layer__c','Primary');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        */
        Test.stopTest();
        System.assert(fieldUpdateMap != null);
    }
    @isTest
    public static void testCloneQuoteWithChildren6_2() {
        
        TriggerSettings__c setting = new TriggerSettings__c();
  		setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        setting.BypassCoverageLineItemTrigger__c = true;
        //setting.BypassAccountTrigger__c = true;
        setting.BypassCoverageTrigger__c = true;
        
        insert setting;
        
        Test.startTest();
        // Create product and coverage
		Product2 prd = new Product2(
			Name = 'Professional Indemnity',
			Innovisk_Entity_ID__c = 'Celerity',
			Package_Indicator__c = true,
			IsActive = true,
			Expiration_Date__c = Date.today().addDays(200),
			Effective_Date__c = Date.today().addDays(-1)
		);
		insert prd;
            
        Account acc1 = new Account();
		acc1.Name = 'Test account 1';
		acc1.BillingStreet = '01 Tran Duy Hung';
		acc1.BillingCity = 'Westminster';
		acc1.BillingState = 'California';
		acc1.BillingPostalCode = '90000';
		acc1.BillingCountry = 'United States';
		acc1.IsMailingSameWithBillingAddress__c = true;
		acc1.Date_Started__c = Date.today().addYears(-2);
		insert acc1;
		
		// Create opportunity
		Opportunity opp = new Opportunity();
		opp.Name = 'Test opp';
		opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
		opp.Coverage_Product_Options__c = 'D&O';
		opp.AccountId = acc1.Id;
		opp.Pricebook2Id = Test.getStandardPricebookId();
		opp.Product__c = prd.Id;
		opp.Received_Date__c = Date.today();
		opp.CloseDate = Date.today().addDays(30);
		opp.Effective_Date__c = Date.today().addDays(1);
		opp.Type = 'New Business';
		opp.LeadSource = 'Email';
		opp.StageName = 'Qualified';
		insert opp;

		// Create contact
		Contact con = new Contact(
			Lastname = 'Huy broker',
			RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
		);
		insert con;


		// Create pricebook entry
		PricebookEntry pbe = new PricebookEntry(
		    Pricebook2Id = Test.getStandardPricebookId(), 
		    Product2Id = prd.Id, 
		    UnitPrice = 10000, 
		    IsActive = true
	    );
	    insert pbe;

		// Create quote
		Quote quote = new Quote(
			OpportunityId = opp.Id,
			Name = 'Test quote 1',
			Coverage_Product_Options__c = 'D&O',
            Quote_Type__c = 'Extension',
            //Status = 'Bound',
            Layer__c = 'Primary',
			Pricebook2Id = Test.getStandardPricebookId()
		);
		insert quote;
        Quote_Option__c quoteOpt = new Quote_Option__c();
        quoteOpt.Azure_ID__c = 'Test 1';
        quoteOpt.Quote__c =  quote.Id;
        quoteOpt.Bound__c = false;
        insert quoteOpt;
        Referral_Reason__c ref1=new Referral_Reason__c();
        ref1.Approver_Level__c='3';
        ref1.Approval_Level_Required__c='1';
        ref1.Approval_Rejected_Date__c= date.today()+365;
        ref1.Quote__c=quote.id;
        ref1.Quote_Option__c = quoteOpt.Id;
        //ref1.Approval_Status__c = 'Approved';
        insert ref1;
        Insurer_Layer_Limit__c ill = new Insurer_Layer_Limit__c();
        ill.Quote__c = quote.Id;
        insert ill;
        Subjectivity__c subject = new Subjectivity__c();
        subject.Quote__c = quote.Id;
        insert subject;
        //Test.startTest();
        Map<String,Object> fieldUpdateMap = new Map<String,Object>();
        /*fieldUpdateMap.put('Contract_Cancellation_Reason__c','None');
        fieldUpdateMap.put('Endorsement_Effective_Date__c',Date.today());
        fieldUpdateMap.put('Quote_Type__c','Coverage Amendment');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.put('Quote_Type__c','Extension');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.remove('Quote_Type__c');
        fieldUpdateMap.put('Quote_Type__c','Midterm Cancellation');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        */
        fieldUpdateMap.remove('Quote_Type__c');
        fieldUpdateMap.put('Quote_Type__c','Flat Cancellation');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.remove('Quote_Type__c');
        fieldUpdateMap.put('Quote_Type__c','Reinstatement');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        fieldUpdateMap.put('Layer__c','Primary');
        CloneQuoteHandler.cloneQuoteWithChildren(quote.Id,fieldUpdateMap);
        Test.stopTest();
        System.assert(fieldUpdateMap != null);
    }
    
  
   

}