@isTest
public class customSingleRelListCtrlTest {
    
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
        quoteObj.Effective_Date__c = system.today()+60;
        quoteObj.ExpirationDate = system.today();
        quoteObj.Quote_Type__c = 'New Business';
        insert quoteObj;  
        
        Document_Revision__c documentRevisionObj = new Document_Revision__c();
        documentRevisionObj.Name = 'Test Revision';
        insert documentRevisionObj;
    }
    
    @isTest
    static void runTest(){
        
        Test.startTest();
        Quote quoteObj = [Select Id,OpportunityId from Quote where Name = 'TestQuote'];
        String fieldConfigDetails = '"label":"","apiName":"QuoteNumber","isHyperlink":"true","":"navigateToRecord":"true";;"label":"Quote Name","apiName":"Name","isHyperlink":"true","":"navigateToRecord":"true";;"label":"Status","apiName":"Status","isHyperlink":"false","":"navigateToRecord":"";;"label":"Layer","apiName":"Layer__c","isHyperlink":"false","":"navigateToRecord":""';
        String relationshipFieldName = 'OpportunityId';
        Document_Revision__c documentRevisionObj = [Select Id from Document_Revision__c where Name = 'Test Revision'];
        customSingleRelListCtrl.getDocRevisionRecord(documentRevisionObj.Id);
        customSingleRelListCtrl.fetchRecords(quoteObj.OpportunityId, 'Quote', fieldConfigDetails, relationshipFieldName, null);
        Test.stopTest();
    }
    
    @isTest
    static void runTest1(){
        
        Test.startTest();
        Quote quoteObj = [Select Id,OpportunityId from Quote where Name = 'TestQuote'];
        String fieldConfigDetails = '"label":"","apiName":"QuoteNumber","isHyperlink":"true","":"navigateToRecord":"true";;"label":"Quote Name","apiName":"Name","isHyperlink":"true","":"navigateToRecord":"true";;"label":"Status","apiName":"Status","isHyperlink":"false","":"navigateToRecord":"";;"label":"Layer","apiName":"Layer__c","isHyperlink":"false","":"navigateToRecord":""';
        String soqlAdditionalWhereCondition = ' AND Layer__c = \'Primary\'';
        String relationshipFieldName = 'OpportunityId';
        customSingleRelListCtrl.fetchRecords(quoteObj.OpportunityId, 'Quote', fieldConfigDetails, relationshipFieldName, soqlAdditionalWhereCondition);
        Test.stopTest();
        
    }
}