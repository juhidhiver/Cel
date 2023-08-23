@isTest
public class QuoteOptionTriggerHandlerTest {
    
    @testSetup
    public static void testSetup(){
        
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
        
        List<Quote_Option__c> lstQuoteOptions = new List<Quote_Option__c>();
        Quote_Option__c objQO1 = new Quote_Option__c();
        objQO1.Quote__c = quoteObj.Id;
        objQO1.Bound__c = true;
        objQO1.Tax_Percent__c = 10;
        lstQuoteOptions.add(objQO1);
        Quote_Option__c objQO2 = new Quote_Option__c();
        objQO2.Quote__c = quoteObj.Id;
        objQO2.Bound__c = false;
        objQO2.Netted_Down_Commission_Percent__c = 20;
        objQO2.Tax_Percent__c = 20;
        lstQuoteOptions.add(objQO2);        
        Quote_Option__c objQO3 = new Quote_Option__c();
        objQO3.Quote__c = quoteObj.Id;
        objQO3.Bound__c = false;
        objQO3.Tax_Percent__c = 30;
        lstQuoteOptions.add(objQO3);
        insert lstQuoteOptions;       
                
    }
    
    @isTest
    public static void runTest(){
        
        Quote_Option__c objQO1 = [SELECT Id, Bound__c FROM Quote_Option__c WHERE Tax_Percent__c = 10];
        System.assertEquals(true, objQO1.Bound__c);
        Quote_Option__c objQO2 = [SELECT Id, Bound__c, Netted_Down_Commission_Percent__c FROM Quote_Option__c WHERE Tax_Percent__c = 20];
        System.assertEquals(false, objQO2.Bound__c);
        
        Quote quoteObj = [Select Id,Status From Quote Where Name = 'TestQuote'];
        
        Test.startTest();
        objQO2.Bound__c = true;
        objQO2.Netted_Down_Commission_Percent__c = 30;
        update objQO2; 
        quoteObj.Status = 'Bound';
        Update quoteObj;
        Test.stopTest();
        
        Quote_Option__c objQO3 = [SELECT Id,Quote__c, Bound__c,Rate__c,Rate_Change__c,Netted_Down_Commission_Amount__c,Netted_Down_Commission_Percent__c,Netted_Down_MGA_Commission_Percent__c,Netted_Down_MGA_Commission_Amount__c FROM Quote_Option__c WHERE Tax_Percent__c = 10];
        
        
        Factor_Summary__c factSumm2 = new Factor_Summary__c();
        factSumm2.Code__c = 'Netted Down Premium Broker Commission Sum';
        factSumm2.Quote__c = objQO3.Quote__c;
        factSumm2.Quote_Option__c = objQO3.Id;
        insert factSumm2;
        
        Factor_Summary__c factSumm1 = new Factor_Summary__c();
        factSumm1.Code__c = 'Netted Down Premium MGA Commission Percent';
        factSumm1.Quote__c = objQO3.Quote__c;
        factSumm1.Quote_Option__c = objQO3.Id;
        insert factSumm1;
        
        Factor_Summary__c factSumm3 = new Factor_Summary__c();
        factSumm3.Code__c = 'Netted Down Premium MGA Commission Sum';
        factSumm3.Quote__c = objQO3.Quote__c;
        factSumm3.Quote_Option__c = objQO3.Id;
        insert factSumm3;
        
        Factor_Summary__c factSumm4 = new Factor_Summary__c();
        factSumm4.Code__c = 'Rate';
        factSumm4.Quote__c = objQO3.Quote__c;
        factSumm4.Quote_Option__c = objQO3.Id;
        insert factSumm4;
        
        Factor_Summary__c factSumm5 = new Factor_Summary__c();
        factSumm5.Code__c = 'Rate Change';
        factSumm5.Quote__c = objQO3.Quote__c;
        factSumm5.Quote_Option__c = objQO3.Id;
        insert factSumm5;
        
        System.assertEquals(false, objQO3.Bound__c);           
        Quote_Option__c objQO4 = [SELECT Id, Bound__c, Quote__c, Netted_Down_Commission_Percent__c FROM Quote_Option__c WHERE Tax_Percent__c = 20];
        Factor_Summary__c factSumm = new Factor_Summary__c();
        factSumm.Code__c = 'Netted Down Premium Broker Commission Percent';
        factSumm.Quote__c = objQO4.Quote__c;
        factSumm.Quote_Option__c = objQO4.Id;
        insert factSumm;
        System.assertEquals(true, objQO4.Bound__c);
        Map<String,Quote_Option__c> quotOption = new Map<String,Quote_Option__c>();
        quotOption.put(objQO4.id,objQO4);
        quotOption.put(objQO2.id,objQO2);
        quotOption.put(objQO3.id,objQO3);
        QuoteOptionTriggerHandler.populateFactorSummary(quotOption);
    }

}