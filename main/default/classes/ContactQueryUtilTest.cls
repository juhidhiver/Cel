/**************************************************************************************************
* Class Name: ContactQueryUtilTest
* Author: Vinay V
* Date: Dec 28, 2021
* Description: Test class for ContactQueryUtil
**************************************************************************************************/
@isTest
public with sharing class ContactQueryUtilTest {
    @TestSetup
    static void testSetup() {  
        //Create Account
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
        
        // Create contact
        Contact con = new Contact(
            Lastname = 'Test broker',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
        );
        insert con;
        
       
    }

    static testmethod void test_fetchContactFromBrokerAccount(){
        Contact con = [Select id from Contact limit 1];
        Test.startTest();
        ContactQueryUtil.fetchContactFromBrokerAccount(con.id);
        ContactQueryUtil.fetchContactWithBrokerLicenseById(con.id,'');
        Test.stopTest();
    }
}