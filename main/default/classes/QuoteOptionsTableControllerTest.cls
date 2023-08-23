@isTest
public class QuoteOptionsTableControllerTest {

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
        
        Quote parentQuoteObj = TestUtil.createQuote('parentQuoteTest', opportunityObj.Id);
        parentQuoteObj.Status = 'In Progress';
        parentQuoteObj.Coverage_Product_Options__c = 'D&O';
        parentQuoteObj.Refer_Type__c = 'Underwriting Referral';
        parentQuoteObj.Rating_Status__c = 'Refer';
        parentQuoteObj.Last_Quote_Version__c = 'Version 1';
        parentQuoteObj.Policy__c = policyObj.id;
        parentQuoteObj.CloseDate__c = Date.today() + 120;
        parentQuoteObj.Effective_Date__c = system.today()+60;
        parentQuoteObj.ExpirationDate = system.today();
        parentQuoteObj.Quote_Type__c = 'New Business';
        parentQuoteObj.Actual_Premium__c = 3;
        parentQuoteObj.Broker_Netted_Down_Premium__c = 2;
        parentQuoteObj.Fee__c = 5;
        parentQuoteObj.Rate__c = 0.5;
        insert parentQuoteObj;  
        
        Quote quoteObj = TestUtil.createQuote('TestQuote', opportunityObj.Id);
        quoteObj.Status = 'In Progress';
        quoteObj.Parent_Quote__c = parentQuoteObj.Id;
        quoteObj.Coverage_Product_Options__c = 'D&O';
        quoteObj.Refer_Type__c = 'Underwriting Referral';
        quoteObj.Rating_Status__c = 'Refer';
        quoteObj.Last_Quote_Version__c = 'Version 1';
        quoteObj.Policy__c = policyObj.id;
        quoteObj.CloseDate__c = Date.today() + 120;
        quoteObj.Effective_Date__c = system.today()+60;
        quoteObj.ExpirationDate = system.today();
        quoteObj.Quote_Type__c = 'New Business';
        quoteObj.Rate__c = 0.5;
       // quoteObj.layer__c = 'Primary';
        insert quoteObj;  
        
        Quote quoteObj1 = TestUtil.createQuote('TestQuote1', opportunityObj.Id);
        quoteObj1.Status = 'In Progress';
        quoteObj1.Parent_Quote__c = parentQuoteObj.Id;
        quoteObj1.Coverage_Product_Options__c = 'D&O';
        quoteObj1.Refer_Type__c = 'Underwriting Referral';
        quoteObj1.Rating_Status__c = 'Refer';
        quoteObj1.Last_Quote_Version__c = 'Version 1';
        quoteObj1.Policy__c = policyObj.id;
        quoteObj1.CloseDate__c = Date.today() + 120;
        quoteObj1.Effective_Date__c = system.today()+60;
        quoteObj1.ExpirationDate = system.today();
        quoteObj1.Quote_Type__c = 'Full Amendment';
        quoteObj1.Rate__c = 0.5;
       // quoteObj.layer__c = 'Primary';
        insert quoteObj1;
        
        SectionSetting__c sectionSettingObj = new SectionSetting__c();
        sectionSettingObj.Component__c = 'Quote Console';
        sectionSettingObj.Order__c = 7;
        sectionSettingObj.Main_Section__c = 'Quote Options';
        sectionSettingObj.Sub_Section__c = 'Submission Status Sub';
        sectionSettingObj.Source_Object__c = 'Opportunity';
        sectionSettingObj.Source_Field_API__c = 'Amount';
        sectionSettingObj.Source_Field_Label__c = 'Amount';
        sectionSettingObj.Format__c = 'Number';
        sectionSettingObj.Active__c = true;
        sectionSettingObj.Record_Type__c = 'Aqueous';
        sectionSettingObj.Quote_Layer__c = quoteObj.layer__c;
        sectionSettingObj.Product__c = 'Professional Indemnity';
        insert sectionSettingObj;     
        
        Quote_Option__c quoteOptionObj = new Quote_Option__c();
        quoteOptionObj.Quote__c = quoteObj.Id;
        quoteOptionObj.Option_Type__c = 'Fixed Limit';
        quoteOptionObj.Selected__c = true;
        quoteOptionObj.Tax_Percent__c = 2;
        quoteOptionObj.Technical_Premium__c = 4;
        quoteOptionObj.Actual_Premium_Final__c = 7;
        quoteOptionObj.Broker_Netted_Down_Premium_Final__c = 6;
        quoteOptionObj.Fee_Final__c = 8;
        quoteOptionObj.Override_Actual_Premium_Percent__c = 9;
        quoteOptionObj.OverrideBrokerNettedDownPremiumPercent__c = 3;
        quoteOptionObj.Override_Fee_Percent__c = 2;
        quoteOptionObj.Actual_Premium_Annual__c = 1;
        quoteOptionObj.Broker_Netted_Down_Premium_Annual__c = 2;
        quoteOptionObj.Fee_Annual__c = 6;
        quoteOptionObj.Book_Premium__c = 1;
        quoteOptionObj.Minimum_Premium__c = 2;
        quoteOptionObj.Book_Premium_Annual__c = 2;
        quoteOptionObj.Minimum_Premium_Annual__c = 1;
        quoteOptionObj.Technical_Premium_Annual__c = 3;
        quoteOptionObj.Technical_Premium_Discretion__c = 2;
        quoteOptionObj.Final_Discretion__c = 1;
        quoteOptionObj.Price_Adequacy__c = 4;
        quoteOptionObj.Technical_Fee__c = 1;
        quoteOptionObj.IPT__c = 1;
        quoteOptionObj.Total_Cost_To_Client__c = 3;
        quoteOptionObj.Change_In_Actual_Premium__c = 1;
        quoteOptionObj.Change_In_Broker_Netted_Down_Premium__c = 3;
        quoteOptionObj.Change_In_Fee__c = 2;
        quoteOptionObj.Increased_Limit_Factor__c = 0.5;
        quoteOptionObj.Rate__c = 0.5;
        quoteOptionObj.Rate_Change__c = 0.5;
        insert quoteOptionObj;
        Quote_Option__c quoteOptionObj1 = new Quote_Option__c();
        quoteOptionObj1.Quote__c = quoteObj1.Id;
        quoteOptionObj1.Option_Type__c = 'Fixed Limit';
        quoteOptionObj1.Selected__c = true;
        quoteOptionObj1.Tax_Percent__c = 2;
        quoteOptionObj1.Technical_Premium__c = 4;
        quoteOptionObj1.Actual_Premium_Final__c = 7;
        quoteOptionObj1.Broker_Netted_Down_Premium_Final__c = 6;
        quoteOptionObj1.Fee_Final__c = 8;
        quoteOptionObj1.Override_Actual_Premium_Percent__c = 9;
        quoteOptionObj1.OverrideBrokerNettedDownPremiumPercent__c = 3;
        quoteOptionObj1.Override_Fee_Percent__c = 2;
        quoteOptionObj1.Actual_Premium_Annual__c = 1;
        quoteOptionObj1.Broker_Netted_Down_Premium_Annual__c = 2;
        quoteOptionObj1.Fee_Annual__c = 6;
        quoteOptionObj1.Book_Premium__c = 1;
        quoteOptionObj1.Minimum_Premium__c = 2;
        quoteOptionObj1.Book_Premium_Annual__c = 2;
        quoteOptionObj1.Minimum_Premium_Annual__c = 1;
        quoteOptionObj1.Technical_Premium_Annual__c = 3;
        quoteOptionObj1.Technical_Premium_Discretion__c = 2;
        quoteOptionObj1.Final_Discretion__c = 1;
        quoteOptionObj1.Price_Adequacy__c = 4;
        quoteOptionObj1.Technical_Fee__c = 1;
        quoteOptionObj1.IPT__c = 1;
        quoteOptionObj1.Total_Cost_To_Client__c = 3;
        quoteOptionObj1.Change_In_Actual_Premium__c = 1;
        quoteOptionObj1.Change_In_Broker_Netted_Down_Premium__c = 3;
        quoteOptionObj1.Change_In_Fee__c = 2;
        quoteOptionObj1.Increased_Limit_Factor__c = 0.5;
        quoteOptionObj1.Rate__c = 0.5;
        quoteOptionObj1.Rate_Change__c = 0.5;
        insert quoteOptionObj1;
         Quote_Option__c quoteOptionObj11 = new Quote_Option__c();
        quoteOptionObj11.Quote__c = quoteObj1.Id;
        quoteOptionObj11.Option_Type__c = 'Fixed Limit';
        quoteOptionObj11.Selected__c = true;
        quoteOptionObj11.Tax_Percent__c = 2;
        quoteOptionObj11.Technical_Premium__c = 4;
        quoteOptionObj11.Actual_Premium_Final__c = 7;
        quoteOptionObj11.Broker_Netted_Down_Premium_Final__c = 6;
        quoteOptionObj11.Fee_Final__c = 8;
        quoteOptionObj11.Override_Actual_Premium_Percent__c = 9;
        quoteOptionObj11.OverrideBrokerNettedDownPremiumPercent__c = 3;
        quoteOptionObj11.Override_Fee_Percent__c = 2;
        quoteOptionObj11.Actual_Premium_Annual__c = 1;
        quoteOptionObj11.Broker_Netted_Down_Premium_Annual__c = 2;
        quoteOptionObj11.Fee_Annual__c = 6;
        quoteOptionObj11.Book_Premium__c = 1;
        quoteOptionObj11.Minimum_Premium__c = 2;
        quoteOptionObj11.Book_Premium_Annual__c = 2;
        quoteOptionObj11.Minimum_Premium_Annual__c = 1;
        quoteOptionObj11.Technical_Premium_Annual__c = 3;
        quoteOptionObj11.Technical_Premium_Discretion__c = 2;
        quoteOptionObj11.Final_Discretion__c = 1;
        quoteOptionObj11.Price_Adequacy__c = 4;
        quoteOptionObj11.Technical_Fee__c = 1;
        quoteOptionObj11.IPT__c = 1;
        quoteOptionObj11.Total_Cost_To_Client__c = 3;
        quoteOptionObj11.Change_In_Actual_Premium__c = 1;
        quoteOptionObj11.Change_In_Broker_Netted_Down_Premium__c = 3;
        quoteOptionObj11.Change_In_Fee__c = 2;
        quoteOptionObj11.Increased_Limit_Factor__c = 0.5;
        quoteOptionObj11.Rate__c = 0.5;
        quoteOptionObj11.Rate_Change__c = 0.5;
        insert quoteOptionObj11;
    }
    
    @isTest
    static void runTest(){
        
        Test.startTest(); 
        Quote quoteObj = [Select Id, OpportunityId, layer__c, Effective_Date__c, ExpirationDate, Quote_Type__c,Rate__c,Parent_Quote__r.Rate__c from Quote where Name = 'TestQuote'];
        Quote_Option__c quoteOptions = [Select Id, Selected__c, Change_In_Fee__c,NonProrated_Actual_Premium__c, NonProRated_BNDP__c, Change_In_Broker_Netted_Down_Premium__c, 
                                        Change_In_Actual_Premium__c, Total_Cost_To_Client__c, IPT__c, Technical_Fee__c, Price_Adequacy__c, Final_Discretion__c, 
                                        Technical_Premium_Discretion__c, Technical_Premium_Annual__c, Minimum_Premium_Annual__c, Book_Premium_Annual__c, Minimum_Premium__c, 
                                        Book_Premium__c, Fee_Annual__c, Broker_Netted_Down_Premium_Annual__c, Actual_Premium_Annual__c, Override_Fee_Percent__c, 
                                        OverrideBrokerNettedDownPremiumPercent__c, Override_Actual_Premium_Percent__c, Fee_Final__c, Tax_Percent__c, Technical_Premium__c, 
                                        Actual_Premium_Final__c, Broker_Netted_Down_Premium_Final__c, Quote__r.Quote_Type__c, Quote__r.Parent_Quote__r.Actual_Premium__c, 
                                        Quote__r.Parent_Quote__r.Broker_Netted_Down_Premium__c, Quote__r.Parent_Quote__r.Fee__c , Quote__r.Parent_Quote__r.IPT_on_Broker_Netted_Down_Premium__c, 
                                        Quote__r.Parent_Quote__r.Total_Cost_To_Client__c, Change_in_IPT__c, Change_in_Total_Cost_to_Client__c,Increased_Limit_Factor__c,Rate__c,Rate_Change__c,Quote__r.Parent_Quote__r.Rate__c,
                                        Quote__r.Commission_percentage__c,Quote__r.MGA_Commission__c,Netted_Down_Commission_Percent__c,Netted_Down_Commission_Amount__c,Netted_Down_MGA_Commission_Percent__c,Netted_Down_MGA_Commission_Amount__c
                                        from Quote_Option__c where Quote__c =: quoteObj.Id];
        QuoteOptionsTableController.fetchQuoteOptions(quoteObj.Id);
        QuoteOptionsTableController.calculatePremiumFields(new List<Quote_Option__c>{quoteOptions}, 5, 2000000);
        QuoteOptionsTableController.saveQuoteOptions(new List<sObject>{quoteOptions}, quoteObj.Id, 1);
        QuoteOptionsTableController.deleteQuoteOptions(quoteOptions.Id);
        QuoteOptionsTableController obj = new QuoteOptionsTableController();
        Test.stopTest();
    }
    @isTest
    static void runTest1(){
        
        Test.startTest(); 
        Quote quoteObj = [Select Id, OpportunityId, layer__c, Effective_Date__c, ExpirationDate, Quote_Type__c,Rate__c,Parent_Quote__r.Rate__c from Quote where Name = 'TestQuote1'];
        List<Quote_Option__c> quoteOptions = [Select Id, Selected__c, Change_In_Fee__c,NonProrated_Actual_Premium__c, NonProRated_BNDP__c, Change_In_Broker_Netted_Down_Premium__c, 
                                        Change_In_Actual_Premium__c, Total_Cost_To_Client__c, IPT__c, Technical_Fee__c, Price_Adequacy__c, Final_Discretion__c, 
                                        Technical_Premium_Discretion__c, Technical_Premium_Annual__c, Minimum_Premium_Annual__c, Book_Premium_Annual__c, Minimum_Premium__c, 
                                        Book_Premium__c, Fee_Annual__c, Broker_Netted_Down_Premium_Annual__c, Actual_Premium_Annual__c, Override_Fee_Percent__c, 
                                        OverrideBrokerNettedDownPremiumPercent__c, Override_Actual_Premium_Percent__c, Fee_Final__c, Tax_Percent__c, Technical_Premium__c, 
                                        Actual_Premium_Final__c, Broker_Netted_Down_Premium_Final__c, Quote__r.Quote_Type__c, Quote__r.Parent_Quote__r.Actual_Premium__c, 
                                        Quote__r.Parent_Quote__r.Broker_Netted_Down_Premium__c, Quote__r.Parent_Quote__r.Fee__c , Quote__r.Parent_Quote__r.IPT_on_Broker_Netted_Down_Premium__c, 
                                        Quote__r.Parent_Quote__r.Total_Cost_To_Client__c, Change_in_IPT__c, Change_in_Total_Cost_to_Client__c,Increased_Limit_Factor__c,Rate__c,Rate_Change__c,Quote__r.Parent_Quote__r.Rate__c,
                                        Quote__r.Commission_percentage__c,Quote__r.MGA_Commission__c,Netted_Down_Commission_Percent__c,Netted_Down_Commission_Amount__c,Netted_Down_MGA_Commission_Percent__c,Netted_Down_MGA_Commission_Amount__c
                                        from Quote_Option__c where Quote__c =: quoteObj.Id];
        QuoteOptionsTableController.fetchQuoteOptions(quoteObj.Id);
        QuoteOptionsTableController.calculatePremiumFields(quoteOptions, 5, 2000000);
        QuoteOptionsTableController.saveQuoteOptions(quoteOptions, quoteObj.Id, 1);
        QuoteOptionsTableController.deleteQuoteOptions(quoteOptions[0].Id);
        QuoteOptionsTableController obj = new QuoteOptionsTableController();
        Test.stopTest();
    }
}