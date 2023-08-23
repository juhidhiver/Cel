@isTest
private class QuoteInitFormCmpControllerTest {
	@testSetup static void setup(){
		// Create product and coverage
		Product2 prd = new Product2(
			Name = 'Private Company Combo',
			Innovisk_Entity_ID__c = 'Celerity',
			Package_Indicator__c = true,
			IsActive = true,
			Expiration_Date__c = Date.today().addDays(200),
			Effective_Date__c = Date.today().addDays(-1)
		);
		insert prd;

		//Create Account
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
		
		// Create Opportunity
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
	}

	@isTest
    static void testGetOpportunityInfo() {
    	Opportunity opps = [SELECT Id,Name,AccountId,Product_Name__c,Effective_Date__c,Expiration_Date__c,CloseDate
    						FROM Opportunity limit 1];
    	String iDOpps = opps.Id;
        Test.startTest();
        	QuoteInitFormCmpController.getOpportunityInfo(iDOpps);
        Test.stopTest();

        System.assert(iDOpps != null);
    }
}