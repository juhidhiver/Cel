/**************************************************************************************************
 * Class Name: AddLocationControllerTest
 * Author: Giang Phan
 * Date: 08-Nov-2019
 * Description: Unit test for AddLocationController
 **************************************************************************************************/
@isTest
private class AddLocationControllerTest{
	
	private static List<Location__c> newLocations;

	static {                                     
		// Create account	
		Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
		Account acc1  = TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster',
												'California','90000', 'United States');
		acc1.IsMailingSameWithBillingAddress__c = true;
		acc1.Date_Started__c = Date.today().addYears(-2);
		insert acc1;

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
		
		// Create opportunity
		Opportunity opp = TestUtil.createOpportunity('Test opp', acc1.Id, prd.Id, 
					Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId(), 'Celerity');
		opp.StageName = 'Qualified';
		opp.CloseDate = Date.today().addDays(30);
		opp.Effective_Date__c = Date.today().addDays(1);
		opp.Pricebook2Id = Test.getStandardPricebookId();
		opp.Coverage_Product_Options__c = 'D&O';
		insert opp;

		// Create quote
		Quote quote = TestUtil.createQuote('Test quote 1', opp.Id);
		quote.Coverage_Product_Options__c = 'D&O';
		quote.Pricebook2Id = Test.getStandardPricebookId();
		insert quote;

		// Create Quote Location
		newLocations = new List<Location__c>();
		newLocations.add(TestUtil.createNewLocation('131, 1st Avenue Test','New York', 'United States', '10093', 'New York'));
		newLocations.add(TestUtil.createNewLocation('234, 1st Avenue','New York', 'United States', '10593', 'New York'));
		newLocations.add(TestUtil.createNewLocation('586, 1st Avenue','Los Angeles', 'United States', '17593', 'Los Angeles'));
		newLocations[0].County__c = 'County1';
        newLocations[1].County__c = 'County2';
        newLocations[2].County__c = 'County3';
        
		insert newLocations;

	}

	static TestMethod void testAddNewLocation() {
		
		Quote newQuote = [Select Id From Quote limit 1];
		Test.startTest();
		AddLocationController.getCountryPickList();
		AddLocationController.getUsageTypePickList();
		AddLocationController.addNewLocation(newLocations[0], String.valueOf(newQuote.Id), 'Quote_Location__c','Quote__c', 'Locations__c', 'Farm', false);
		Test.stopTest();

		System.assertEquals(true, String.isNotBlank(newLocations[0].Id));
	}

	static TestMethod void testSearchLocation() {
		Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
		Test.startTest();
		AddLocationController.LocationResponse locationResponse = AddLocationController.searchLocation('131');
		AddLocationController.searchPlace(locationResponse.predictions[0].place_id);
		Test.stopTest();
		System.assertEquals(true, locationResponse != null);		
	}

	static TestMethod void testNULLSearchLocation(){
		Test.startTest();
		AddLocationController.LocationResponse locationResponse = AddLocationController.searchLocation('');
		Test.stopTest();
		System.assertEquals(true, locationResponse == null);
	}

	static TestMethod void testNULLSearchPlace(){
		String placeId = '';
		Test.startTest();
		AddLocationController.searchPlace(placeId);
		Test.stopTest();
		System.assertEquals(true, placeId != null);
	}
}