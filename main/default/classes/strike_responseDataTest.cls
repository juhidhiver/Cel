@isTest
private class strike_responseDataTest {
    static testMethod void testMethod1() {
        Boolean isSuccess = false;
        Map<String, Object> results = new Map<String, Object>();
        String errMsg = '';

        Test.startTest();
        	strike_responseData rponse = new strike_responseData();
        	rponse.isSuccess = true;
        	rponse.results = new Map<String, Object>();
        	rponse.addError(errMsg);
        	rponse.getJsonString();
        Test.stopTest();
        System.assert(true);
    }
}