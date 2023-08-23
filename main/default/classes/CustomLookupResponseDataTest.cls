@isTest
private class CustomLookupResponseDataTest {
    static testMethod void testCustomLookupResponseData() {
    	Boolean isSuccess = true;
    	Map<String, Object> results = new Map<String, Object>();
    	String errMsg = '';

        Test.startTest();
        CustomLookupResponseData customLookup = new CustomLookupResponseData();
        customLookup.isSuccess = true;
        customLookup.results = new Map<String, Object>();
        customLookup.addError(errMsg);
        customLookup.getJsonString();
        Test.stopTest();
    }
}