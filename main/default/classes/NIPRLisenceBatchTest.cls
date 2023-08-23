@isTest
public class NIPRLisenceBatchTest {
	
    
    public class WebServiceNIPRMockImpl implements HttpCalloutMock {
         public HTTPResponse respond(HTTPRequest req) {
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"isValidBrokerLicense":true,"npn":"20"}');
        res.setStatusCode(200);
        return res;
    	}
    }
    
    @isTest
    public static void testBatchSchedule() {
        TriggerSettings__c setting = new TriggerSettings__c();
          
          setting.BypassContactTrigger__c = true;
          insert setting;
        
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
             Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
             insert accBroker;               
    
             Contact contactBroker = TestUtil.createContact(accBroker.Id, 'Broker_Contact', 'New broker contact');
             insert contactBroker;
       
        
          Broker_License__c brokerLicence = TestUtil.createBrokerLicense(contactBroker, '', '123');
        	 brokerLicence.License_Number__c = 'OB13129';
        	 brokerLicence.License_State__c = 'CA';
             insert brokerLicence;
        
                  
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new WebServiceNIPRMockImpl());
        String cronExpr = '0 0 0 15 3 ? 2022';
        NIPRLisenceBatchScheduleble niprSch = new NIPRLisenceBatchScheduleble();
        System.schedule('NIPR Batch',cronExpr,niprSch);
        Test.stopTest();
    }
}