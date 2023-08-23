@isTest
public class SanctionSearchUpdateController_Test {
    
    @isTest
    static void testmethod1() {
        Account acc = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        List<ID> accids = new List<ID>();
        accids.add(acc.id);
        
        
        Set<ID> setAcc = new Set<ID>();
        setAcc.add(acc.id);
        
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        mock.body = '{"isSuccess":"True"}';
        mock.statusCode = 200;
        
        Test.setMock(HttpCalloutMock.class, mock);
        SanctionSearchUpdateController ssuc = new SanctionSearchUpdateController();
        Test.startTest();
        	SanctionSearchUpdateController.declineFailedSanctioncallout(accids);
        	SanctionSearchAPICallout.callAccountSanctionV2API_async(setAcc);
        Test.stopTest();
    }
    
    @isTest
    static void testmethod2() {
        Account acc = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        List<ID> accids = new List<ID>();
        accids.add(acc.id);
        
        SanctionSearchAPICalloutMockResponse mock = new SanctionSearchAPICalloutMockResponse();
        Test.setMock(HttpCalloutMock.class, mock);
        
        Set<ID> setAcc = new Set<ID>();
        setAcc.add(acc.id);
        
        Test.startTest();
        	SanctionSearchAPICallout.callAccountSanctionV2API_async(setAcc);
        	SanctionSearchUpdateController.declineFailedSanctioncallout(accids);
        Test.stopTest();
    }
    
    @isTest
    static void testmethod3() {
        Account acc = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        acc.AQ_Sanction_Status__c = 'Cleared';
        insert acc;
        
        List<ID> accids = new List<ID>();
        accids.add(acc.id);
        
        SanctionSearchAPICalloutMockResponse1 mock = new SanctionSearchAPICalloutMockResponse1();
        Test.setMock(HttpCalloutMock.class, mock);
        
        Set<ID> setAcc = new Set<ID>();
        setAcc.add(acc.id);
        
        Test.startTest();
        	SanctionSearchAPICallout.callAccountSanctionV2API_async(setAcc);
        	SanctionSearchUpdateController.declineFailedSanctioncallout(accids);
        Test.stopTest();
    }

	@isTest
    static void testmethod4() {
        Account acc = new Account();
        //String recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        //acc.RecordTypeID=recordTypeId;
        acc.Name='Test FName';
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        SanctionSearchAPICalloutMockResponse2 mock = new SanctionSearchAPICalloutMockResponse2();
       
        Test.setMock(HttpCalloutMock.class, mock);
        
        Set<ID> accids = new Set<ID>();
        accids.add(acc.id);
        
        Test.startTest();
        	SanctionSearchAPICallout.callAccountSanctionV2API_async(accids);
        Test.stopTest();
    }
    
    public class SanctionSearchAPICalloutMockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{ "searchTerm": "", "searchType": "", "address": "", "dob": "", "countryOfBirth": "", "nationality": "", "rag": "Red", "containsClient": null, "searchId": "33344455" }');
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class SanctionSearchAPICalloutMockResponse1 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{ "searchTerm": "", "searchType": "", "address": "", "dob": "", "countryOfBirth": "", "nationality": "", "rag": "Red", "containsClient": true, "searchId": "33344455" }');
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class SanctionSearchAPICalloutMockResponse2 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{ "searchTerm": "", "searchType": "", "address": "", "dob": "", "countryOfBirth": "", "nationality": "", "rag": "Green", "containsClient": true, "searchId": "33344455" }');
            res.setStatusCode(200);
            return res;
        }
    }
    
}