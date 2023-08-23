@isTest
private class QuoteLocationAssetTreeViewControllerTest {
    @testSetup static void setup() {
    	TriggerSettings__c setting = new TriggerSettings__c();
		insert setting;

		// Create product and coverage
		Product2 prd = new Product2(
			Name = 'Private Company Combo',
			//RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Celerity').getRecordTypeId(),
			Innovisk_Entity_ID__c = 'Celerity',
			Package_Indicator__c = true,
			IsActive = true,
			Expiration_Date__c = Date.today().addDays(200),
			Effective_Date__c = Date.today().addDays(-1)
		);
		insert prd;

		// Create Account
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

		// Create quote
		Quote quote = new Quote(
			OpportunityId = opp.Id,
			Name = 'Test quote 1',
			Coverage_Product_Options__c = 'D&O',
			Pricebook2Id = Test.getStandardPricebookId()
		);
		insert quote;
    }

    static testMethod void testInitData() {
        Test.startTest();

		// Create new Quote
		//TestUtil.createQuoteOnOpportunity();

		Product2 product = [Select Id From Product2 where Name = 'Private Company Combo' limit 1];
		Quote newQuote = [Select Id,Azure_Id__c,OpportunityId From Quote Where Opportunity.Product__c =: product.Id limit 1];

		// Create Quote Location
		List<Location__c> newLocations = new List<Location__c>();
		newLocations.add(TestUtil.createNewLocation('131, 1st Avenue Test','New York', 'United States', '10093', 'New York'));
		insert newLocations;

		Quote_Location__c newQuoteLoc = TestUtil.createQuoteLocation(newQuote.Id, newLocations[0].Id, true);
		insert newQuoteLoc;

		QuoteLocationAssetTreeViewController.initData(newQuote.Id);

		Test.stopTest();

		System.assertEquals(true, String.isNotBlank(newQuote.Id));
    }
}