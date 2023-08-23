@isTest
private class RequestObjectTest {
    static testMethod void testRequestObject() {
    	String endpoint = '';
    	String method = '';
    	Map<String, String> headers = new Map<String, String>();
    	String body = '';
    	Integer timeout = 1;

    	Test.startTest();
    		RequestObject reqObj = new RequestObject();
    		reqObj.endpoint = endpoint;
    		reqObj.method = method;
    		reqObj.headers = headers;
    		reqObj.body = body;
    		reqObj.timeout = timeout;
    		reqObj.getHttpRequest();
    	Test.stopTest();
    }
}