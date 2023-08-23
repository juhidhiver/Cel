@isTest
public class ClaimDetailsSectionControllerTest {
    //public static Account acc;
    @testSetup
    public static void setup(){
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = 'England';
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        Contact con = new Contact(
            Lastname = 'Test broker',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
        );
        insert con;
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 productaq = TestUtil.createProduct('Professional Indemnity');
        productaq.RecordTypeId = aqueousRecordTypeId; 
        productaq.Innovisk_Entity_ID__c = 'Aqueous';
        insert productaq; 
        
        Opportunity oppaq = TestUtil.createOpportunity('Opp Test',acc.Id, productaq.Id);
        oppaq.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        oppaq.AccountId = acc.Id;
        oppaq.StageName = 'Qualified'; 
        oppaq.Innovisk_Entity_ID__c = 'Aqueous';                            
        oppaq.Product__c = productaq.Id;
        oppaq.Submission_Status__c = 'Quoted';
        oppaq.Transaction_Status__c = 'Active';
        oppaq.Coverage_Product_Options__c = 'Professional Indemnity';
        oppaq.Tax_Country__c = 'United Kingdom';
        insert oppaq;
        
        Broker_Account__c broketAccount = new Broker_Account__c(
            Broker_Contact__c = con.Id,
            Opportunity__c = oppaq.Id,
            IsPrimaryBroker__c = true,
            Relationship_Type__c = 'Broker'
        );
        insert broketAccount;
        
        Policy__c policy = new Policy__c();
        policy.Account__c = acc.Id;
        policy.Product_Name__c = 'Professional Indemnity';
        policy.Expiration_Date__c = Date.today().addDays(100);
        policy.Total_Premium__c = 2000;
        policy.Initial_Premium__c = null;
        insert policy;
        
        Claim_Data__c cd = new Claim_Data__c();
        cd.Account__c = acc.id;
        cd.Policy__c  = policy.id;
        cd.Claim_status__c = 'Test Status';
        cd.Indemnity_Paid__c = 10000.7;
        cd.Fees_Paid__c = 2000.66;
        cd.Fees_Reserve__c = 3000.24;
        cd.Indemnity_Reserve__c = 4000.11;
        cd.TPA_Fees__c = 1223.11;
        insert cd;
        
    }
    @isTest
    public static void testMethod1(){
        Claim_Data__c cd = [Select Id From Claim_Data__c];
        Opportunity opp = [Select Id from Opportunity];
        
        test.startTest();
        ClaimDetailsSectionController.getSubmissionRelatedToAccount(opp.Id);
        test.stopTest();
        
        
    }
}