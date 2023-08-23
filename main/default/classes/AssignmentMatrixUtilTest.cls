/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 07-25-2022
 * @last modified by  : Vinayesh
**/
@isTest
public class AssignmentMatrixUtilTest {
    @testSetup static void setup() {
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassQuoteTrigger__c = false;
        update setting;
        GlobalStaticVar.byPassRenewalTrigger = true;
        
        String RecordTypeId = Schema.SObjectType.Renewal__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Contact con = new Contact(
            Email = 'test@j.com',
            Lastname = 'Test broker',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
        );
        insert con;
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = 'England';
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        Account accaq = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        accaq.BillingStreet = acc.ShippingStreet;
        accaq.BillingCity = acc.ShippingCity;
        accaq.BillingState = 'England';
        accaq.BillingPostalCode = acc.ShippingPostalCode;
        accaq.BillingCountry = acc.ShippingCountry;
        insert accaq;
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 productaq = TestUtil.createProduct('Professional Indemnity');
        productaq.RecordTypeId = aqueousRecordTypeId; 
        productaq.Innovisk_Entity_ID__c = 'Aqueous';
        insert productaq; 
        Opportunity oppaq = TestUtil.createOpportunity('Opp Test',accaq.Id, productaq.Id);
        oppaq.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        oppaq.AccountId = accaq.Id;
        oppaq.StageName = 'Qualified'; 
        oppaq.Innovisk_Entity_ID__c = 'Aqueous';                            
        oppaq.Product__c = productaq.Id;
        oppaq.Submission_Status__c = 'Quoted';
        oppaq.Transaction_Status__c = 'Active';
        oppaq.Coverage_Product_Options__c = 'Professional Indemnity';
        oppaq.Tax_Country__c = 'United Kingdom';
        oppaq.Main_Profession__c = 'Accountants';
        insert oppaq;


        Quote quote1 = TestUtil.createQuote('New quote', oppaq.Id);
        quote1.Layer__c = 'Primary';
        quote1.Coverage_Product_Options__c = 'Professional Indemnity';
        quote1.Status = 'Bound';
        insert quote1; 

        String rdPolicyId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId(); 
        Policy__c policy = new Policy__c();
        policy.Account__c = accaq.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);
        insert policy;

        quote1.Policy__c=policy.Id;
        update quote1;  
        
        Broker_Account__c brokerAccount = new Broker_Account__c(
            Broker_Contact__c = con.Id,
            Opportunity__c = oppaq.Id,
            IsPrimaryBroker__c = true,
            Relationship_Type__c = 'Broker'
        );
        insert brokerAccount;
        
        Document_Template__c document = new Document_Template__c();
        document.Document_Name__c = 'Accountants Proposal Form & a Tax Scheme Questionnaire';
        insert document;
        
        Assignment_Matrix__c am = new Assignment_Matrix__c();
        am.Document_Template__c = document.id ;
        am.Assignment_Object_Type__c = 'Document';
		am.IsActive__c = true ;
       // am.Assignment_Object_Type__c = 'Document_Template__c' ;
        am.Unique_Identifier__c = 'DOC-0002_1';
       // am.CurrencyIsoCode = 'USD';
       	am.Product__c = 'Professional Indemnity';
        am.Lookup_Field_API_Name__c = 'Document_Template__c';
        insert am;
        
        Assignment_Matrix_Rule__c amr = new Assignment_Matrix_Rule__c();
        amr.Assignment_Matrix__c = am.Id;
        amr.Field_Type__c = 'Text';
        amr.IsActive__c = true ; 
        amr.Rule_Type__c = 'Field Query';
        amr.Field_API_Name__c = 'Main_Profession__c';
        amr.Value__c = 'Accountants';
        amr.Operator__c = 'in';
        amr.Object_API_Name__c = 'Renewal__c';
        amr.Includes_Group_Number__c = 1;
        insert amr;

        Assignment_Matrix_Rule__c amr1 = new Assignment_Matrix_Rule__c();
        amr1.Assignment_Matrix__c = am.Id;
        amr1.Field_Type__c = 'Number';
        amr1.IsActive__c = true ; 
        amr1.Rule_Type__c = 'Field Query';
        amr1.Field_API_Name__c = 'Claims_Number__c';
        amr1.Value__c = '0';
        amr1.Operator__c = 'greater than equals';
        amr1.Object_API_Name__c = 'Renewal__c';
        amr1.Includes_Group_Number__c = 1;
        insert amr1;

        Assignment_Matrix_Rule__c amr2 = new Assignment_Matrix_Rule__c();
        amr2.Assignment_Matrix__c = am.Id;
        amr2.Field_Type__c = 'Number';
        amr2.IsActive__c = true ; 
        amr2.Rule_Type__c = 'Key Value Query';
        amr2.Field_API_Name__c = 'Main_Profession__c;Claims_Number__c';
        amr2.Value__c = 'Accountants;0';
        amr2.Operator__c = 'greater than equals';
        amr2.Object_API_Name__c = 'Renewal__c';
        amr2.Includes_Group_Number__c = 1;
        insert amr2;
        
        Renewal__c rn = new Renewal__c(
        Broker__c = brokerAccount.id,
       	Documents_Required__c = document.Document_Name__c,
        recordtypeId = RecordTypeId,
        Latest_Bound_Quote__c = quote1.Id,
        Claims_Number__c = 1);
        insert rn;
    }
    // public testmethod static void  testMethod1(){
    //     String RecordTypeId = Schema.SObjectType.Renewal__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
    //       Renewal__c renewal = [Select Id, Broker__c From Renewal__c limit 1];
    //     //RenewalService.fetchRenewalRecords(RecordTypeId);
    //     //RenewalService.getListSectionSetting('Professional Indemnity');
    //     test.startTest();
    //     list<Renewal__c> renewalList = [Select id, Policy__c from Renewal__c where id =: renewal.Id];
    //     RenewalTriggerHandler.UpdateRenewalDocuments(renewalList);
    //     test.stopTest();
    // }

    public testmethod static void  testMethod1(){
        String RecordTypeId = Schema.SObjectType.Renewal__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
          Renewal__c renewal = [Select Id, Broker__c From Renewal__c limit 1];
        //RenewalService.fetchRenewalRecords(RecordTypeId);
        //RenewalService.getListSectionSetting('Professional Indemnity');
        test.startTest();
        list<Renewal__c> renewalList = [Select id, Policy__c from Renewal__c where id =: renewal.Id];
        //RenewalTriggerHandler.UpdateRenewalDocuments(renewalList);
        AssignmentMatrixUtil.GetDocumentsData(renewal.Id, 'Professional Indemnity');
        test.stopTest();
    }
}