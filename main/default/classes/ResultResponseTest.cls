@isTest
private class ResultResponseTest {
    static testMethod void testMethod1() {
    	Boolean isSuccess = false;
    	List<String> errors = new List<String>();
    	String data = '';

        Test.startTest();
        	ResultResponse rr = new ResultResponse();
        	rr.isSuccess = false;
        	rr.data = '';
        Test.stopTest();
        System.assertEquals(rr.isSuccess, false);
    }
}