@isTest
public class AdditionalInsuredTrigger_Test {
	@isTest
    static void testmethodAccount() {
        Account acc = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        Account acc1 = TestUtil.createBusinessAccount('Bussiness Accoun Aq1', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc1.BillingStreet = acc.ShippingStreet;
        acc1.BillingCity = acc.ShippingCity;
        acc1.BillingState = acc.ShippingState;
        acc1.BillingPostalCode = acc.ShippingPostalCode;
        acc1.BillingCountry = acc.ShippingCountry;
        insert acc1;
        
        Product2 product = TestUtil.createProduct('D&O');
        insert product;   
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        opportunity.Coverage_Product_Options__c = 'D&O;MPL';
        insert opportunity;
        
        Additional_Insured__c additionalInsuredAcc = new Additional_Insured__c();
        additionalInsuredAcc.Submission__c = opportunity.Id;
        additionalInsuredAcc.Additional_Insured_Account__c = acc.Id;
        insert additionalInsuredAcc;
        
        
        
        
        
        //additionalInsuredAcc.Additional_Insured_Account__c = acc1.Id;
       // update additionalInsuredAcc;
        
       
    }
}