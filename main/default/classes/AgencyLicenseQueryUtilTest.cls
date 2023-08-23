/**************************************************************************************************
* Class Name: AgencyLicenseQueryUtil
* Author: RINKU SAINI
* Date: Jan 10th, 2022
* Description: 
**************************************************************************************************/
@isTest
public class AgencyLicenseQueryUtilTest {
    
    public static testmethod void coverAgencyLicenseQueryUtil(){
        Test.startTest();
        
        Id recordTypeAccBroker = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Account accBroker = new Account(
            Name='Account_Broker_Test_01', 
            RecordTypeId = recordTypeAccBroker, 
            BillingStreet = '5305, Monroe Street',
            BillingCity = 'Toledo', 
            BillingState = 'Ohio',
            BillingPostalCode = '43623', 
            BillingCountry = 'United States',
            MRe_Admittance__c = 'Not Started',
            FEIN__c = 12345
        );
        insert accBroker;
        
        Id recordTypeConBroker = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Contact contactBroker1 = new Contact(
            FirstName = 'Test',
            LastName = 'Broker_Contact_1',
            RecordTypeId =recordTypeConBroker ,
            Azure_Id__c = '1234',
            Email = 'test1@broker.com',
            AccountId = accBroker.Id
        );
        insert contactBroker1;
        
        Id recordTypeBrokerLicence = [SELECT Id FROM RecordType WHERE DeveloperName = 'MRe_Appointment' AND sObjectType = 'Broker_License__c'].Id;
        Broker_License__c brokerLicence = TestUtil.createBrokerLicense(contactBroker1, '', '123');
        brokerLicence.License_Number__c = 'LICTEST';
        brokerLicence.License_State__c = 'CA';
        brokerLicence.MRe_Appointment_Status__c = 'Not Started';
        brokerLicence.License_Type__c = 'Admitted Lines';
        brokerLicence.RecordTypeId = recordTypeBrokerLicence;
        insert brokerLicence;
        
        Id recordTypeAgencyLicence = [SELECT Id FROM RecordType WHERE DeveloperName = 'MRe_Appointment' AND sObjectType = 'Agency_License__c'].Id;
        Agency_License__c agencyLicence = new Agency_License__c();
        agencyLicence.Agency__c = accBroker.Id;
        agencyLicence.License_Number__c = brokerLicence.License_Number__c;
        agencyLicence.License_State__c = brokerLicence.License_State__c;
        agencyLicence.License_Type__c = 'Admitted Lines';
        agencyLicence.MRe_Appointment_Status__c = 'Not Started';
        agencyLicence.RecordTypeId = recordTypeAgencyLicence;
        agencyLicence.Agency__c = accBroker.Id;
        insert agencyLicence;
        
        AgencyLicenseQueryUtil.fetchLicenseByAgencyId(accBroker.Id,brokerLicence.License_State__c);
        
        Test.stopTest();
    }
}