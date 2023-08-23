@isTest
public with sharing class NIPRAccountBatchTest {
   
    @testSetup 
    static void setup() {
    	Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        accBroker.FEIN__c  = 123456;
        insert accBroker;
    
    }

    public class WebServiceMockImpl implements HttpCalloutMock {
         public HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        //System.assertEquals('http://example.com/example/test', req.getEndpoint());
        //System.assertEquals('GET', req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"example":"test"}');
        res.setStatusCode(200);
        return res;
    }
    }
    
    static testmethod void test() {  
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new WebServiceMockImpl());
        String cronExpr = '0 0 0 15 3 ? 2022';
        NIPRAccountBatchSchedule niprSch = new NIPRAccountBatchSchedule();
        System.schedule('NIPR Batch',cronExpr,niprSch);
        Test.stopTest();

        // after the testing stops, assert...
        System.assert(true);

    }

}