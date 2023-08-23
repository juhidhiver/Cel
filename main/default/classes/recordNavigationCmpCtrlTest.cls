@isTest
public class recordNavigationCmpCtrlTest {

    @testSetup
    static void testSetup(){
        
        TriggerSettings__c triggerSettingsObj = new TriggerSettings__c();
        triggerSettingsObj.BypassQuoteTrigger__c = true;
        insert triggerSettingsObj;
        
        Account accountObj = TestUtil.createBusinessAccount('Test Bussiness Account', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert accountObj;
        
        Product2 productObj = TestUtil.createProduct('D&O Standalone');
        insert productObj; 
        
        Opportunity opportunityObj = TestUtil.createOpportunity('Test Opportunity',accountObj.Id, productObj.Id);
        opportunityObj.CloseDate = Date.today();
        opportunityObj.StageName = 'Closed Won';
        opportunityObj.Expiration_Date__c = Date.today()+60;
        insert opportunityObj;
        
        Policy__c policyObj = new Policy__c();
        policyObj.Policy_Number__c = '12345';
        policyObj.Effective_Date__c = Date.today()+5;
        policyObj.Expiration_Date__c = Date.today() + 30;
        policyObj.Policy_Status__c = 'Bound';
        insert policyObj;
        
        Quote quoteObj = TestUtil.createQuote('TestQuote', opportunityObj.Id);
        quoteObj.Status = 'In Progress';
        quoteObj.Coverage_Product_Options__c = 'D&O';
        quoteObj.Refer_Type__c = 'Underwriting Referral';
        quoteObj.Rating_Status__c = 'Refer';
        quoteObj.Last_Quote_Version__c = 'Version 1';
        quoteObj.Policy__c = policyObj.id;
        quoteObj.CloseDate__c = Date.today() + 120;
        insert quoteObj;  
        
    }
    
    @isTest
    static void runTest(){
        
        Test.startTest();
        Quote quoteObj = [Select Id, OpportunityId, layer__c from Quote where Name = 'TestQuote'];
        recordNavigationCmpCtrl.fetchDetails(quoteObj.Id);
        Test.stopTest();
    }
}