@isTest
private class strike_lookupControllerTest {

    @isTest static void test_getRecentRecords() {
        String jsonString = '{"searchField":"Name", "object": "Account", "filter": "Name = \'Test Account\'"}';

        Test.startTest();
        String responseString = strike_lookupController.getRecentRecords(jsonString);
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');

        System.assertEquals(true, response.get('isSuccess'));
    }

    @isTest static void test_getRecentRecords1() {
        String jsonString = '{"searchField":"Name", "object": "AccountError", "filter": "Name = \'Test Account\'"}';

        Test.startTest();
        String responseString = strike_lookupController.getRecentRecords(jsonString);
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');

        System.assertEquals(true, response.get('isSuccess'));
    }

    @isTest static void test_getRecordLabel() {
        Account a = new Account(Name='Test Account');
        insert a;

        String jsonString = '{"searchField":"Name", "object": "Account", "filter": "Name = \'Test Account\'"}';

        Test.startTest();
        String responseString = strike_lookupController.getRecordLabel(jsonString);
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        String objectLabel = String.valueOf(results.get('objectLabel'));

        System.assertEquals('Account', objectLabel);
    }

    @isTest static void test_getData() {
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());

        String jsonString = '{"searchTerm": "123"}';

        Test.startTest();
        String responseString = strike_lookupController.getRecords(jsonString);
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        List<Object> data =(List<Object>)results.get('data');

        System.assertEquals(true, !data.isEmpty());
    }

    @isTest static void test_responseData_error() {
        Test.startTest();
        strike_responseData responDtCtrl = new strike_responseData();
        responDtCtrl.addError('Test Error For strike_responseData class');
        Test.stopTest();

        System.assertEquals(false, responDtCtrl.isSuccess);
    }

    @isTest static void test_Strike_Utilities() {
        Test.startTest();
        
        Map<String, Object> objMaptest = new Map<String, Object>();
        objMaptest.put('test', 'Value Testttt');
        String jsonTest = '{\"putTimeCard\":{\"timecard\":{\"timeCardID\": \"\",\"employeeID\": \"\"}}}';
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(jsonTest);
        Map<String, Object> objMap = strike_utilities.convertObjectToMap(m.values()[0]);
        Test.stopTest();

        System.assertEquals(false, objMap.isEmpty());
    }
 
}