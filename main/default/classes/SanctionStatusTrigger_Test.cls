@isTest
public class SanctionStatusTrigger_Test {

    @isTest
     static void testmethod1() {
         Account acc = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
         acc.BillingStreet = acc.ShippingStreet;
         acc.BillingCity = acc.ShippingCity;
         acc.BillingState = acc.ShippingState;
         acc.BillingPostalCode = acc.ShippingPostalCode;
         acc.BillingCountry = acc.ShippingCountry;
         insert acc;
         
         Account acc1 = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
         acc1.BillingStreet = acc.ShippingStreet;
         acc1.BillingCity = acc.ShippingCity;
         acc1.BillingState = acc.ShippingState;
         acc1.BillingPostalCode = acc.ShippingPostalCode;
         acc1.BillingCountry = acc.ShippingCountry;
         insert acc1;
         
         
         Sanction_Status__c sancstatus = new Sanction_Status__c();
         sancstatus.Account__c = acc.Id; 
         sancstatus.Review_Requested__c = true;
         sancstatus.Sanction_Status__c = 'Potential Match';
         sancstatus.RecordTypeId = Schema.SObjectType.Sanction_Status__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
         
         insert sancstatus;
         
         Sanction_Status__c sancstatus1 = new Sanction_Status__c();
         sancstatus1.Account__c = acc.Id; 
         sancstatus1.Review_Requested__c = true;
         sancstatus1.RecordTypeId = Schema.SObjectType.Sanction_Status__c.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
         
         upsert sancstatus1;
         
         sancstatus1.Review_Requested__c = false;
         update sancstatus1;

         //sancstatus.Account__c = acc1.Id;
         sancstatus.Sanction_Status__c = 'Failed';
       	 update sancstatus;
     }
         
}