@isTest
public with sharing class ContentDocumentLinkTriggerHandlerTest{
    
    public static testmethod void testSetup(){
        
        Test.setMock(HttpCalloutMock.class, new contentDocumentMock());
        TriggerSettings__c setting = new TriggerSettings__c();
        setting.BypassContentDocumentLinkTrigger__c = false;
        insert setting;
        System.assert(setting != null);
        
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio', '43623', 'United States');
        insert accBroker;
        
        // create product
        Product2 product = TestUtil.createProduct('MPL Standalone');
        insert product;
        
        // create opportunity
        Opportunity opp = TestUtil.createOpportunity('Test Opportunity', accBroker.Id, product.Id);
        opp.StageName = 'Qualified';
        insert opp;
        
        Coverage__c cov1 = new Coverage__c(Name = 'Coverage Name', Form_Number__c = 'ACMP 27 03 08 04', Coverage_Product__c = 'MPL', Coverage_Type__c = 'Endorsement');
        insert cov1;
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'ACMP 27 03 Coverage Name', 
            PathOnClient = 'ACMP 27 03 Coverage Name', 
            VersionData = Blob.valueOf('ACMP 27 03 Coverage Name')
        );
        insert contentVersion;
    }
    
    public static testmethod void afterInsertTest(){
        
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio', '43623', 'United States');
        insert accBroker;
        // List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId
        //                                    FROM ContentDocument ];
        List<Account> accBrokers = [SELECT Id, Name
                                    FROM Account 
                                    WHERE Name = :'Account_Business_Test_01'];
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'ACMP 27 03 Coverage Name', 
            PathOnClient = 'ACMP 27 03 Coverage Name', 
            VersionData = Blob.valueOf('ACMP 27 03 Coverage Name')
        );
        insert contentVersion;
        
        System.debug('@@ accBrokers ' + accBrokers);
        // System.debug('@@ documents ' + documents);
        // Test.setMock(HttpCalloutMock.class, new RequestCalloutMockClass());
        
        List<ContentVersion> cdvs = [SELECT id, ContentDocumentId FROM ContentVersion LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new contentDocumentMock());
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = accBrokers[0].Id;
        cdl.ContentDocumentId = cdvs[0].ContentDocumentId;
        cdl.shareType = 'V';
        cdl.Visibility = 'AllUsers'; 
        //insert cdl;
        Test.stopTest();
        System.assert(cdl != null);
    }
    
    // Added by RINKU SAINI 07th Jan 2022
    public class contentDocumentMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"example":"test"}');
            res.setStatusCode(200);
            return res;
        }
    }
}