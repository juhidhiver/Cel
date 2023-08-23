/***********************************************************************
 * Class Name: BrokerLicenseTriggerHandlerTest
 * Author: Khanh TRAN
 * Date: 07-Nov-2019
 * Description: BrokerLicenseTriggerHandler Test
 ***********************************************************************
 */
@isTest
public class BrokerLicenseTriggerHandlerTest {
    
   public static testmethod void testMethod1() {
        Test.startTest();
        
        
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Broker_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert accBroker;              	
        
        Contact contactBroker = TestUtil.createContact(accBroker.Id, 'Broker_Contact', 'New broker contact');
        insert contactBroker;
        
        
        Broker_License__c brokerLicence = new Broker_License__c();
        brokerLicence.Broker__c = contactBroker.Id;
        brokerLicence.License_State__c = 'LA';
        insert brokerLicence;
        
        brokerLicence.License_State__c = 'MN';
        update brokerLicence;
        
       // added by RINKU SAINI 23-Dec-2021
        Broker_License__c brokerLicence1 = new Broker_License__c();
        brokerLicence1.Broker__c = contactBroker.Id;
        brokerLicence1.License_State__c = 'LA';
        brokerLicence1.RecordTypeId = Schema.SObjectType.Broker_License__c.getRecordTypeInfosByName().get('MRe Appointment').getRecordTypeId();
        insert brokerLicence1;
        
        brokerLicence1.License_State__c = 'MN';
        update brokerLicence1;
        
        Test.stopTest();
    }
   
}