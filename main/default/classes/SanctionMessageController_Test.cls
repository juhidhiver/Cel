@isTest
public class SanctionMessageController_Test {
    
    @isTest
    static void testmethodAccount() {
        Account acc = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        Sanction_Status__c sancstatus = new Sanction_Status__c();
        sancstatus.Sanction_Status__c = 'Failed';
        sancstatus.SearchId__c = '2442244';
        sancstatus.Account__c = acc.Id; 
        sancstatus.Review_Requested__c = true;
        sancstatus.RecordTypeId = Schema.SObjectType.Sanction_Status__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        
        insert sancstatus;
        
        Product2 product = TestUtil.createProduct('D&O');
        insert product;   
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        opportunity.Coverage_Product_Options__c = 'D&O;MPL';
        insert opportunity;
        
        Test.startTest();
            SanctionMessageController.checkSanctionStatus(acc.id);
            SanctionMessageController.checkUWSanctionStatus(opportunity.id);
        Test.stopTest();
    }
    
    @isTest
    static void testmethodOpportunity1() {
        Account acc = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        acc.AQ_Sanction_Status__c = 'Failed';
        acc.SearchId__c = '2344556';
        insert acc;
        
        Product2 product = TestUtil.createProduct('D&O');
        insert product;   
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        opportunity.Coverage_Product_Options__c = 'D&O;MPL';
        insert opportunity;
        
        Quote_Process__c qp = new Quote_Process__c();
        qp.Account__c = acc.Id;
        qp.Submission__c = opportunity.Id;
        insert qp;
        
        Test.startTest();
            SanctionMessageController.checkSanctionStatus(opportunity.id);
            SanctionMessageController.checkUWSanctionStatus(qp.id);
        Test.stopTest();
    }
    
    
}