@isTest
private class CustomLookupCmpControllerTest {


	@testSetup static void setup() {
		Account acc1 = new Account();
        acc1.Name = 'Test Account';
        acc1.BillingStreet = '11 Tran Duy Hung';
		acc1.BillingCity = 'Westminster';
		acc1.BillingState = 'California';
		acc1.BillingPostalCode = '90000';
		acc1.BillingCountry = 'United States';
        //acc1.Billing_County__c;
		acc1.IsMailingSameWithBillingAddress__c = true;
		acc1.Date_Started__c = Date.today().addYears(-2);
		insert acc1;
		
	}

	@isTest static void test_getRecentRecordsAccount() {
		
        
		String jsonBody =
				'{"limit":"5","object":"Account","order":"Name","searchField":"Name","subtitleField":"Industry"}';
		String jsonString = '{"searchField":"Name", "object": "Account", "filter": "Name = \'Test Account\'","searchTerm": "Test"}';

		Test.startTest();
		String responseString = CustomLookupCmpController.getRecentRecords(jsonString);
		Test.stopTest();

		Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
		Map<string, Object> results = (Map<String, Object>)response.get('results');

		System.assertEquals(true, response.get('isSuccess'));
	}


	@isTest static void test_getRecentRecordsOPP() {

		String jsonBody =
				'{"limit":"5","object":"Account","order":"Name","searchField":"Name","subtitleField":"Industry"}';
		String jsonString = '{"searchField":"Name", "object": "Opportunity", "filter": "Name = \'Test Opp\'"}';

		Test.startTest();
		String responseString = CustomLookupCmpController.getRecentRecords(jsonString);
		Test.stopTest();

		Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
		Map<string, Object> results = (Map<String, Object>)response.get('results');

		System.assertEquals(true, response.get('isSuccess'));
	}

	@isTest static void test_getRecordLabel() {
		/*Account a = new Account(Name = 'Test Account');
		insert a; */

		String jsonString = '{"searchField":"Name", "object": "Account", "filter": "Name = \'Test Account\'"}';

		Test.startTest();
		String responseString = CustomLookupCmpController.getRecordLabel(jsonString);
		Test.stopTest();

		Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
		Map<string, Object> results = (Map<String, Object>)response.get('results');
		String objectLabel = String.valueOf(results.get('objectLabel'));

		System.assertEquals('Account', objectLabel);
	}

	@isTest static void testGetNewObjIdFromToast() {
		String s = CustomLookupCmpController.getNewObjIdFromToast('Account', '');
		System.assertEquals(s == null, true);

	}
	@isTest static void failGetRecords() {
		String result  = CustomLookupCmpController.getRecords(null);
		Map<String,Object> resultMap =(Map<String,Object> )JSON.deserializeUntyped(result);
		System.assertEquals(false, (Boolean)resultMap.get('isSuccess'));
	}

	@isTest static void testGetObjLabel() {
		String sLabel = CustomLookupCmpController.getObjLabel('Account');
		System.assertEquals('Account', sLabel);

	}

/*
	@isTest static void test_getData() {
		Account a = new Account(Name = 'Test Account');
		insert a;

		String jsonString =
				'{"searchField":"Name", "object": "Account", "filter": "Name = \'Test Account\'", "order": "Name", "limit": "5", "searchTerm": "Test"}';

		Test.startTest();
		String responseString = CustomLookupCmpController.getRecords(jsonString);
		Test.stopTest();

		Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
		Map<string, Object> results = (Map<String, Object>)response.get('results');
		List<Object> data = (List<Object>)results.get('data');

		System.assertEquals(0, data.size());

		Map<String, Object> record = (Map<String, Object>)data.get(0);

		System.assertEquals(a.Id, record.get('value'));
	}

	@isTest static void test_getData_subtitleField() {
		Account a = new Account(Name = 'Test Account');
		insert a;

		String jsonString =
				'{"searchField":"Name", "subtitleField": "Name", "object": "Account", "filter": "Name = \'Test Account\'", "searchTerm": "Test"}';

		Test.startTest();
		String responseString = CustomLookupCmpController.getRecords(jsonString);
		Test.stopTest();

		Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
		Map<string, Object> results = (Map<String, Object>)response.get('results');
		List<Object> data = (List<Object>)results.get('data');

		System.assertEquals(1, data.size());
	}

*/

	@isTest static void test_getData_reference() {
		Account a = new Account(Name = 'Test Account');
		insert a;

		Contact c = new Contact(
				LastName = 'Contact',
				FirstName = 'Test',
				AccountId = a.Id);
		insert c;

		String jsonString =
				//'{"searchField":"FirstName", "subtitleField": "Account.Name", "object": "Contact", "filter": "Name = \'Test Contact\'", "searchTerm": "Test"}';
				'{"searchField":"Name", "object": "Account","order":"Name", "filter": "Name = \'Test Account\'", "searchTerm": "Test"}';
		Test.startTest();
        Id [] fixedSearchResults= new Id[1];
       	fixedSearchResults[0] = a.Id;
        Test.setFixedSearchResults(fixedSearchResults);
		String responseString = CustomLookupCmpController.getRecords(jsonString);
		Test.stopTest();

		Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
		Map<string, Object> results = (Map<String, Object>)response.get('results');
		List<Object> data = (List<Object>)results.get('data');

		System.assertEquals(1, data.size());

		Map<String, Object> record = (Map<String, Object>)data.get(0);

		System.assertEquals(a.Id, record.get('value'));
	}
    
    @isTest static void test_getData_reference2() {
		Account acc1 = [SELECT id,Name FROM Account LIMIT 1];
        Product2 product = TestUtil.createProduct('MPL');
		insert product;

        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc1.Id, product.Id);
        insert opportunity;
		String jsonString = '{"searchField":"Name","order":"Name","limit":"1", "subtitleField": "Account.Name", "object": "Opportunity", "filter": "Name = \'Test Account\'", "searchTerm": "Test"}';
		Test.startTest();
		String responseString = CustomLookupCmpController.getRecords(jsonString);
		Test.stopTest();

		Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
		Map<string, Object> results = (Map<String, Object>)response.get('results');
		List<Object> data = (List<Object>)results.get('data');

		System.assertEquals(0, data.size());

		System.assertEquals('Test', results.get('searchTerm'));
	}
    
    @isTest static void test_getData_reference3() {
		Account a = new Account(Name = 'Test Account');
		insert a;

		Contact c = new Contact(
				LastName = 'Contact',
				FirstName = 'Test',
            	Department = 'Test Department',
				AccountId = a.Id);
		insert c;

		String jsonString =
				//'{"searchField":"FirstName", "subtitleField": "Account.Name", "object": "Contact", "filter": "Name = \'Test Contact\'", "searchTerm": "Test"}';
				'{"searchField":"Department", "order":"Department", "subtitleField": "Account.Name", "object": "Contact", "filter": "Department = \'Test Department\'", "searchTerm": "Test"}';
		Test.startTest();
		String responseString = CustomLookupCmpController.getRecords(jsonString);
		Test.stopTest();

		Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
		Map<string, Object> results = (Map<String, Object>)response.get('results');
		List<Object> data = (List<Object>)results.get('data');

		System.assertEquals(1, data.size());

		Map<String, Object> record = (Map<String, Object>)data.get(0);

		System.assertEquals(c.Id, record.get('value'));
	}
}