@isTest
public class submissionConsoleMReLwcController_Test {@testSetup
    public static void setup() {
        Account acc1 = new Account();
        acc1.Name = 'Test account 2';
        acc1.BillingStreet = '11 Tran Duy Hung';
        acc1.BillingCity = 'Westminster';
        acc1.BillingState = 'California';
        acc1.BillingPostalCode = '90000';
        acc1.BillingCountry = 'United States';
        //acc1.Billing_County__c;
        acc1.IsMailingSameWithBillingAddress__c = true;
        acc1.Date_Started__c = Date.today().addYears(-2);
        insert acc1;
        
        Product2 product = TestUtil.createProduct('MPL');
        insert product;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp_Test_1',acc1.Id, product.Id);
        insert opportunity;
        
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

        //List<Contact> brokerConList = new List<Contact>();
        Id recordTypeConBroker = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Contact contactBroker1 = new Contact(
            FirstName = 'Test',
			LastName = 'Broker_Contact_1',
			RecordTypeId =recordTypeConBroker ,
            Azure_Id__c = '1234',
            Email = 'test1@broker.com',
			AccountId = accBroker.Id
        );
		//brokerConList.add(contactBroker1);
        insert contactBroker1;
        
        Id recordTypeBrokerLicence = Schema.SObjectType.Broker_License__c.getRecordTypeInfosByDeveloperName().get('MRe_Appointment').getRecordTypeId();
        Broker_License__c brokerLicence = TestUtil.createBrokerLicense(contactBroker1, '', '123');
        brokerLicence.License_Number__c = 'LICTEST';
        brokerLicence.License_State__c = 'CA';
        brokerLicence.MRe_Appointment_Status__c = 'Not Started';
        brokerLicence.License_Type__c = 'Admitted Lines';
        brokerLicence.RecordTypeId = recordTypeBrokerLicence;
        insert brokerLicence;
        
        Id recordTypeAgencyLicence = Schema.SObjectType.Agency_License__c.getRecordTypeInfosByDeveloperName().get('MRe_Appointment').getRecordTypeId();
        Agency_License__c agencyLicence = new Agency_License__c();
        agencyLicence.Agency__c = accBroker.Id;
        agencyLicence.License_Number__c = brokerLicence.License_Number__c;
        agencyLicence.License_State__c = brokerLicence.License_State__c;
        agencyLicence.License_Type__c = 'Admitted Lines';
        agencyLicence.MRe_Appointment_Status__c = 'Not Started';
        agencyLicence.RecordTypeId = recordTypeAgencyLicence;
        insert agencyLicence;
    }
    public static testMethod void fetchLicenceInfo_Test(){
        String brokerContactId = [SELECT Id FROM Contact WHERE LastName = 'Broker_Contact_1' LIMIT 1].Id;
        String insuredState = 'CA';
        Test.startTest();
        submissionConsoleMReLwcController.fetchMReAppointmentConfigs();
        submissionConsoleMReLwcController.wrLicense wr = submissionConsoleMReLwcController.fetchLicenceInfo(brokerContactId, insuredState);
        Test.stopTest();
        System.assertEquals(insuredState,wr.brokerLicense.License_State__c);
    }
    public static testMethod void handleMReProcess_Test(){
        Agency_License__c agencyLicence = [SELECT Agency__c FROM Agency_License__c LIMIT 1];
        Broker_License__c brokerLicence = [SELECT Broker__c FROM Broker_License__c LIMIT 1];
        String agencyLicenseId = agencyLicence.Id;
        String brokerLicenseId = brokerLicence.Id;
        String brokerId = brokerLicence.Broker__c;
        String agencyId = agencyLicence.Agency__c;
        String OppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Test.startTest();
        submissionConsoleMReLwcController.handleMReProcess(OppId, 'CA',agencyId, brokerId,agencyLicenseId,brokerLicenseId);
        submissionConsoleMReLwcController.handleMReProcess(OppId, 'CA',agencyId, brokerId,'','');
        //submissionConsoleMReLwcController.handleMReProcess('OppId', 'brokerContactId');
        Test.stopTest();
        Agency_License__c agencyLicenceTest = [SELECT MRe_Appointment_Status__c FROM Agency_License__c WHERE Id =: agencyLicenseId LIMIT 1];
        System.assertEquals('In Progress',agencyLicenceTest.MRe_Appointment_Status__c);
    }
}