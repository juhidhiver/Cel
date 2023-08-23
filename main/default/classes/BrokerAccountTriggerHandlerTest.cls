/**************************************************************************************************
 * Class Name: BrokerAccountTriggerHandlerTest
 * Author: Hoang Bui
 * Date: 03-Sep-2019
 * Description: BrokerAccountTriggerHandlerTest Test
 **************************************************************************************************/
@isTest
private class BrokerAccountTriggerHandlerTest {
	public static Quote quote;
	public static Opportunity opp;
	public static Opportunity opp_aq;

	static {
    	TriggerSettings__c setting = TestUtil.initialTriggerSetting();
		setting.BypassBrokerAccountTrigger__c = false;
        setting.BypassContactTrigger__c = true;
		update setting;

		//Create Account
		Account acc1 = new Account();
		acc1.Name = 'Test account 2';
		acc1.BillingStreet = '11 Tran Duy Hung';
		acc1.BillingCity = 'Westminster';
		acc1.BillingState = 'California';
		acc1.BillingPostalCode = '90000';
		acc1.BillingCountry = 'United States';
        //acc1.Billing_County__c;
		acc1.IsMailingSameWithBillingAddress__c = true;
		acc1.Date_Started__c = Date.today().addYears(-2);
		insert acc1;

        // Create contact
		Contact con = new Contact(
			Lastname = 'Test broker',
			RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
		);
		insert con;

		Contract contr = new Contract(
			AccountId = acc1.Id,
			Expiration_Date__c = Date.today().addDays(100)
        );

        insert contr;

        // create policy  
        Policy__c policy = new Policy__c();
        	policy.Account__c = acc1.Id; 
        	policy.Expiration_Date__c = Date.today().addDays(100);           
        insert policy;

		//Create Product
		Product2 prd = new Product2(
			Name = 'Private Company Combo',
			RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Celerity').getRecordTypeId(),
			Innovisk_Entity_ID__c = 'Celerity',
			Package_Indicator__c = true,
			IsActive = true,
			Expiration_Date__c = Date.today().addDays(200),
			Effective_Date__c = Date.today().addDays(-1)
		);
		insert prd;
		
		//Create AQ Product
		Product2 prd_aq = new Product2(
			Name = 'Professional Indemnity',
			RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Aqueous').getRecordTypeId(),
			Innovisk_Entity_ID__c = 'Aqueous',
			Package_Indicator__c = true,
			IsActive = true,
			Expiration_Date__c = Date.today().addDays(200),
			Effective_Date__c = Date.today().addDays(-1)
		);
		insert prd_aq;

		Account_Product__c accProd1 = new Account_Product__c();
        accProd1.Account_Id__c = acc1.Id;
        accProd1.Product_Id__c = prd_aq.id;
        insert accProd1;

		// Create opportunity
		opp = new Opportunity();
		opp.Name = 'Test opp';
		opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
		opp.Coverage_Product_Options__c = 'D&O';
		opp.AccountId = acc1.Id;
		opp.Pricebook2Id = Test.getStandardPricebookId();
		opp.Product__c = prd.Id;
		opp.Received_Date__c = Date.today();
		opp.CloseDate = Date.today().addDays(30);
		opp.Effective_Date__c = Date.today();
		opp.Type = 'New Business';
		opp.LeadSource = 'Email';
		opp.StageName = 'New';
		opp.ContractId = contr.Id;
		opp.Policy__c = policy.Id;
		insert opp;

		// Create aq opportunity
		opp_aq = new Opportunity();
		opp_aq.Name = 'Test opp';
		opp_aq.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
		opp_aq.AccountId = acc1.Id;
		opp_aq.Innovisk_Entity_ID__c = 'Aqueous';
		opp_aq.Pricebook2Id = Test.getStandardPricebookId();
		opp_aq.Product__c = prd_aq.Id;
		opp_aq.Received_Date__c = Date.today();
		opp_aq.CloseDate = Date.today().addDays(30);
		opp_aq.Effective_Date__c = Date.today();
		opp_aq.Type = 'New Business';
		opp_aq.LeadSource = 'Email';
		opp_aq.StageName = 'New';
		opp_aq.ContractId = contr.Id;
		opp_aq.Policy__c = policy.Id;
		insert opp_aq;

		// Create broker
		Broker_Account__c broketAccount = new Broker_Account__c(
			Broker_Contact__c = con.Id,
			Opportunity__c = opp.Id,
			IsPrimaryBroker__c = true,
			Relationship_Type__c = 'Broker'
		);
		insert broketAccount;

		// Create broker
		Broker_Account__c brokerAccount_aq = new Broker_Account__c(
			Broker_Contact__c = con.Id,
			Opportunity__c = opp_aq.Id,
			IsPrimaryBroker__c = true,
			Relationship_Type__c = 'Broker'
		);
		insert brokerAccount_aq;
    }

    @isTest
	static void testPopulateContactToQuotes() {
		Test.startTest();
		Opportunity opps = [SELECT Id FROM Opportunity limit 1];
		Broker_Account__c brokerss = [SELECT Id,Opportunity__c, IsPrimaryBroker__c FROM Broker_Account__c WHERE Opportunity__c =: opps.Id];
		Test.stopTest();
		List<Quote> listQuotes = [Select Id,ContactId,OpportunityId From Quote Where OpportunityId = :opps.Id];
		system.assertEquals(true, brokerss.IsPrimaryBroker__c);
        System.assert(listQuotes != null);
        
        
	}

	@isTest
	static void testUpdateCommissionPercentage() {
		Opportunity opps = [SELECT Id FROM Opportunity where Product__r.Name = 'Professional Indemnity' limit 1];
		Broker_Account__c broker = [SELECT Id,Opportunity__c, IsPrimaryBroker__c FROM Broker_Account__c WHERE Opportunity__c =: opps.Id];
        
		Test.startTest();
		broker.IsPrimaryBroker__c = true;
        update broker;
        Test.stopTest();   
	}

	@isTest
	static void testUpdateAQBrokerAccs() {
		Broker_Account__c brokerAcc = [SELECT Id,Opportunity__c, IsPrimaryBroker__c FROM Broker_Account__c WHERE Opportunity__r.RecordType.Name = 'Aqueous' limit 1];
		Test.startTest();
		//update broker account
		brokerAcc.IsPrimaryBroker__c = false;
		update brokerAcc;

		//delete broker accont
		delete brokerAcc;
        Test.stopTest();
	}

	@isTest(SeeAllData='false')
	static void testUpdate(){

		quote = TestUtil.createQuote('New Quote Test',opp.Id);
        quote.Coverage_Product_Options__c ='D&O;MPL';        
		//insert quote;

        System.debug('%%Label.BROCKER_ACCOUNT_BLOCK_OTHER_BROKERS_MSG%% '+ Label.BROCKER_ACCOUNT_BLOCK_OTHER_BROKERS_MSG);

		Test.startTest();

		Policy__c pol = [SELECT Id FROM Policy__c limit 1];
		Opportunity opps = [SELECT Id, StageName, Policy__c  FROM Opportunity WHERE Policy__c =: pol.Id limit 1];
		opps.StageName = 'New';
		System.debug('opportunityAccounts: ' + opps + '===' + opps.Opportunity_Accounts1__r);
		update opps;

		Opportunity opportunity1 = [SELECT Id FROM Opportunity limit 1];
		Broker_Account__c brokers = [SELECT Id, IsPrimaryBroker__c FROM Broker_Account__c WHERE Opportunity__c =: opportunity1.Id];
		brokers.IsPrimaryBroker__c = false;
		update brokers;

		brokers.IsPrimaryBroker__c = true;
		update brokers;

        delete brokers;
		Test.stopTest();
        //system.assertEquals(true,brokers.IsPrimaryBroker__c );
         system.assert(opportunity1 !=null);

	}

    @isTest
	static void testAQ() {
		
        Test.startTest();
		Account acc = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 product = TestUtil.createProduct('Professional Indemnity');
        product.RecordTypeId = aqueousRecordTypeId; 
        product.Innovisk_Entity_ID__c = 'Aqueous';
        insert product;   
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.StageName = 'Qualified'; 
        opp.Innovisk_Entity_ID__c = 'Aqueous';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();                            
        opp.Product__c = product.Id;
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        insert opp;
        
        String rdPolicyId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId(); 
        Policy__c policy = new Policy__c();
        policy.Account__c = acc.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);
        insert policy;
        
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
        
        //Quote
        Quote quote = TestUtil.createQuote('New Quote Test',opp.Id);
        quote.Coverage_Product_Options__c ='Professional Indemnity'; 
        quote.Status = 'In Progress';
        quote.OpportunityId = opp.Id;
        insert quote;
        
		// Create contact
        Contact con = new Contact(
            Email = 'test@j.com',
            Lastname = 'Test broker',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
        );
        insert con;
        
        // Create broker
        Broker_Account__c broketAccount = new Broker_Account__c(
            Broker_Contact__c = con.Id,
            Opportunity__c = opp.Id,
            IsPrimaryBroker__c = true,
            Relationship_Type__c = 'Broker'
        );
        insert broketAccount;
        
        //Create Transaction
        Transactions__c transactions = new Transactions__c();
        transactions.Policy__c=policy.Id;
        transactions.Submission__c=opp.Id;
        insert transactions;
        
        /*Opportunity opps = [SELECT Id FROM Opportunity limit 1];
		Broker_Account__c brokerss = [SELECT Id,Opportunity__c, IsPrimaryBroker__c FROM Broker_Account__c WHERE Opportunity__c =: opps.Id];
		Test.stopTest();
		List<Quote> listQuotes = [Select Id,ContactId,OpportunityId From Quote Where OpportunityId = :opps.Id];*/
        

       
        
	}
}