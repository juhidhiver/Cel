@isTest
private class ResponseObjectTest {
    
    @isTest(SeeAllData='true')
    static void testResponseObject() {
        String body = '';
    	String status = '';
    	Integer statusCode = 0;
    	List<String> errors = new List<String>();

    	Test.startTest();
    		ResponseObject responObj = new ResponseObject();
    		responObj.body = body;
    		responObj.status = status;
    		responObj.statusCode = 200;
    		responObj.errors = new List<String>();
    	Test.stopTest();
    }

    @isTest(SeeAllData='true')
    static void testMethod2(){
        
        String body = '';
        String status = '';
        Integer statusCode = 200;
        List<String> errors = new List<String>();
        
        Test.startTest();
            HttpResponse res = new HttpResponse();
            res.setBody('{"message":"OK"}');
            
            ResponseObject responObj = new ResponseObject(res);
            responObj.body = res.getBody();
            responObj.status = res.getStatus();
            responObj.statusCode = res.getStatusCode();

            Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            responObj.errors = new List<String>();
            
        Test.stopTest();

        
    }
}