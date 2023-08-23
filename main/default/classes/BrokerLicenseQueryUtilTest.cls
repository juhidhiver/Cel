/**************************************************************************************************
* Class Name: BrokerLicenseQueryUtilTest
* Author: RINKU SAINI
* Date: Jan 10th, 2022
* Description: 
**************************************************************************************************/
@isTest
public class BrokerLicenseQueryUtilTest {
    
    public static testmethod void coverBrokerLicenseQueryUtil(){
        Test.startTest();
        
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert accBroker;
        
        Contact contactBroker = TestUtil.createContact(accBroker.Id, 'Broker_Contact', 'New broker contact');
        insert contactBroker;
        
        Broker_License__c brokerLic = TestUtil.createBrokerLicense(contactBroker, '', '123');
        insert brokerLic;
        
        BrokerLicenseQueryUtil.fetchLicencesForBroker(contactBroker.Id);
        
        Test.stopTest();
    }
}