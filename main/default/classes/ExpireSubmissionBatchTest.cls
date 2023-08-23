@isTest
public class ExpireSubmissionBatchTest {
    @testSetup
    public static void testSetup() {
        
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        setting.BypassPolicyTrigger__c = true;       
        setting.BypassRatingModifiersTrigger__c = true;
        setting.BypassAccountLossDetailTrigger__c = true;
        update setting;
        
        // Create Accounts
        List<Account> accountInserts = new List<Account>();
        
        Account accPersonal = new Account();
        accPersonal.Name = 'Test account 1';
        accPersonal.BillingStreet = '01 Tran Duy Hung';
        accPersonal.BillingCity = 'Westminster';
        accPersonal.BillingState = 'California';
        accPersonal.BillingPostalCode = '90000';
        accPersonal.BillingCountry = 'United States';
        accPersonal.IsMailingSameWithBillingAddress__c = true;
        accPersonal.Date_Started__c = Date.today().addYears(-2);
        insert accPersonal;
        
        // Create product
        Product2 prd = new Product2(
            Name = 'MPL',
            Innovisk_Entity_ID__c = 'Celerity',
            Package_Indicator__c = true,
            IsActive = true,
            Expiration_Date__c = Date.today().addDays(200),
            Effective_Date__c = Date.today().addDays(-1),
            Pay_Plan__c = 'ACH'
        );
        insert prd;
        
        accPersonal = [SELECT Id FROM Account WHERE Id = :accPersonal.Id LIMIt 1];
        
        List<sObject> ls = Test.loadData(Opportunity.sObjectType,'testOpportunity'); 
        
        Opportunity opptemp = (Opportunity)ls[0]; 
        
        System.assert(ls.size() == 1); 
        DateTime cDate = opptemp.CreatedDate; 
        
        
        opptemp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
        opptemp.Coverage_Product_Options__c = 'D&O';
        opptemp.AccountId = accPersonal.Id;
        opptemp.Pricebook2Id = Test.getStandardPricebookId();
        //opptemp.Product__c = prd.Id;
        opptemp.Received_Date__c = Date.today();
        opptemp.CloseDate = Date.today().addDays(30);
        opptemp.Effective_Date__c = Date.today().addDays(1);
        opptemp.Type = 'New Business';
        opptemp.LeadSource = 'Email';
        opptemp.StageName = 'Qualified';
        
        
        // Create quote
        Quote newQuote = new Quote(
            OpportunityId = opptemp.Id,
            Name = 'Test newQuote 1',
            Coverage_Product_Options__c = 'D&O',
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Rated'
        );
        insert newQuote;
        
        //Create Another Quote
        Quote modQuote = new Quote(
            OpportunityId = opptemp.Id,
            Name = 'Test Mod Qoute',
            Coverage_Product_Options__c = 'D&O',
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'In Progress'
        );        
        insert modQuote;
        
        Document_Revision__c documentRevision  = new Document_Revision__c(
            Name = 'QuoteProposal' + '_' + String.valueOf(Datetime.now()),
            Document_Azure_Id__c = '1',
            Document_Type__c = 'QuoteProposal',
            Quote_Id__c = newQuote.Id
        );
        insert documentRevision;
        
        Account_Loss_Detail__c accountLoss = new Account_Loss_Detail__c();
        accountLoss.Account__c = accPersonal.Id;
        accountLoss.Product__c = 'Cyber';
        accountLoss.Loss_Amount__c = 123;
        accountLoss.Status__c = 'Open';
        accountLoss.Year__c = '2020';
        accountLoss.Number_of_Losses__c = 23;
        insert accountLoss;
        
        UW_Analysis_Template__c TempList = new UW_Analysis_Template__c();
        TempList.UW_Analysis_Name__c = 'Test';
        TempList.Criteria__c = 'Engineers';
        TempList.UW_Analysis_Code__c ='Code';
        TempList.Rating_Factor__c= 5000;
        TempList.Sort_Order__c = 100;       
        insert TempList;
        
        UW_Analysis__c uwList = new UW_Analysis__c();
        uwList.Amount__c = 1000;
        uwList.UW_Analysis_Name__c = 'UW Test';
        uwList.Criteria__c = 'Territory';
        uwList.UW_Analysis_Code__c = 'T1';
        uwList.Rating_Factor__c = 1000;
        uwList.Sort_Order__c = 10;
        uwList.Submission__c = opptemp.Id;
        uwList.UW_Analysis_Template__c = TempList.Id;
        uwList.Sort_Order__c = 10;
        uwList.Notional_Income__c = 1000;
        insert uwList;
        
    }
    @isTest static void test() {
        Test.startTest();        
        ExpireSubmissionBatch expireSubmission = new ExpireSubmissionBatch();
        Id batchId = Database.executeBatch(expireSubmission, 2);
        Test.stopTest();
        System.assertEquals('New', [select id,stageName  from Opportunity Limit 1].stageName);
        
    }
    
    @isTest static void test2() {
        Opportunity opp = [Select id from Opportunity limit 1];
        update opp;
        Test.startTest();        
        ExpireSubmissionBatch expireSubmission = new ExpireSubmissionBatch();
        Id batchId = Database.executeBatch(expireSubmission, 2);
        Test.stopTest();
        System.assertEquals('New', [select id,stageName  from Opportunity Limit 1].stageName);
        
    }
    
    @isTest static void test3() {
        Opportunity opp = [Select id from Opportunity limit 1];
        Quote newQuote = [Select id from Quote limit 1];
        
        Rating_Modifiers__c rMod = new Rating_Modifiers__c();
        rMod.Opportunity__c = opp.Id;
        insert rMod;   
        
        Rating_Modifier_Factor__c rm = new Rating_Modifier_Factor__c();
        rm.Factor_Default_Value__c = 123;
        rm.Factor_Max__c = 300;
        rm.Factor_Min__c = 100;
        rm.Factor_Value__c = 120;
        rm.Rating_Modifier__c = rMod.Id;
        rm.Quote__c = newQuote.Id;    
        insert rm;
        Test.startTest();        
        ExpireSubmissionBatch expireSubmission = new ExpireSubmissionBatch();
        Id batchId = Database.executeBatch(expireSubmission, 2);
        Test.stopTest();
        //System.assertEquals('Closed Lost', [select id,stageName  from Opportunity Limit 1].stageName);
        System.assertEquals('New', [select id,stageName  from Opportunity Limit 1].stageName);
    }
    
    @isTest static void test4() {
        Opportunity opp = [Select id from Opportunity limit 1];
        Quote newQuote = [Select id from Quote limit 1];
        Account_Loss_Detail__c accountLoss = [Select id from Account_Loss_Detail__c limit 1];
        
        Rating_Modifiers__c rMod = new Rating_Modifiers__c();
        rMod.Opportunity__c = opp.Id;
        insert rMod;   
        
        Rating_Modifier_Factor__c rm = new Rating_Modifier_Factor__c();
        rm.Factor_Default_Value__c = 123;
        rm.Factor_Max__c = 300;
        rm.Factor_Min__c = 100;
        rm.Factor_Value__c = 120;
        rm.Rating_Modifier__c = rMod.Id;
        rm.Quote__c = newQuote.Id;    
        insert rm; 
        
        Submission_Loss_Detail__c subLoss = new Submission_Loss_Detail__c();
        subLoss.Submission__c = opp.Id;
        subLoss.Loss_Amount__c = 22200;
        subLoss.Status__c = 'Open';
        subLoss.Year__c ='2019';
        subLoss.Number_of_Losses__c=2;
        subLoss.Account_Loss_Detail__c = accountLoss.Id;
        insert subLoss;
        
        Test.startTest();        
        ExpireSubmissionBatch expireSubmission = new ExpireSubmissionBatch();
        Id batchId = Database.executeBatch(expireSubmission, 2);
        Test.stopTest();
        System.assertEquals('New', [select id,stageName  from Opportunity Limit 1].stageName);
        
    }
}