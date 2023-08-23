/**************************************************************************************************
* Class Name: cloneRecordsNewTest
* Author: Vinayesh
* Created date: 14-Jun-2021
* Description: Test Class for cloneRecordsNew class
**************************************************************************************************/
@isTest
public class cloneRecordsNewTest {
    
    @testSetup 
    static void createData(){
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        setting.BypassCoverageLineItemTrigger__c = true;
        setting.BypassAccountTrigger__c = true;
        update setting;
        
        Account acc1 = new Account();
        acc1.Name = 'Test account 2';
        acc1.BillingStreet = '11 Tran Duy Hung';
        acc1.BillingCity = 'Westminster';
        acc1.BillingState = 'California';
        acc1.BillingPostalCode = '90000';
        acc1.BillingCountry = 'United States';
        //acc1.Billing_County__c;
        acc1.IsMailingSameWithBillingAddress__c = true;
        acc1.Date_Started__c = Date.today().addYears(-2);
        insert acc1;
        
        Product2 product = TestUtil.createProduct('MPL');
        insert product;
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test11',acc1.Id, product.Id);
        insert opp;
        
        String rdPolicyId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId(); 
        Policy__c policy = new Policy__c();
        policy.Account__c = acc1.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);
        insert policy;
        
        Subjectivity_Template__c subjectivityTemplate = new Subjectivity_Template__c();
        subjectivityTemplate.Subjectivity_Name__c = 'Signed / Dated Proposal';
        subjectivityTemplate.Subjectivity_Text__c = 'Test';
        subjectivityTemplate.Profession_Criteria__c = 'Engineers';
        insert subjectivityTemplate;
        
        //Quote
        Quote quote = TestUtil.createQuote('New Quote Test',opp.Id);
        quote.Status = 'Quoted';
        quote.Layer__c = 'Primary';
        quote.OpportunityId = opp.Id;
        quote.ExpirationDate = date.today() + 365;
        quote.Effective_Date__c = date.today();
        quote.Endorsement_Type__c='New Business';
        quote.Policy__c = policy.Id;
        insert quote;
        
        
        UW_Analysis_Template__c TempList = new UW_Analysis_Template__c();
        TempList.UW_Analysis_Name__c = 'Test';
        TempList.Criteria__c = 'Engineers';
        TempList.UW_Analysis_Code__c ='Code';
        TempList.Rating_Factor__c= 5000;
        TempList.Sort_Order__c = 100;
        insert TempList;
        
        UW_Analysis__c uwList = new UW_Analysis__c();
        uwList.Amount__c = 1000;
        //uwList.Name = 'Test';
        uwList.UW_Analysis_Name__c = 'UW Test';
        uwList.Criteria__c = 'Territory';
        uwList.UW_Analysis_Code__c = 'T1';
        uwList.Rating_Factor__c = 1000;
        uwList.Sort_Order__c = 10;
        uwList.Submission__c = opp.Id;
        uwList.UW_Analysis_Template__c = TempList.Id;
        uwList.Sort_Order__c = 10;
        uwList.Notional_Income__c = 1000;
        insert uwList;
        
          UW_Analysis__c uwList1 = new UW_Analysis__c();
        uwList1.Amount__c = 1000;
        //uwList.Name = 'Test';
        uwList1.UW_Analysis_Name__c = 'UW Test1';
        uwList1.Criteria__c = 'Territory';
        uwList1.UW_Analysis_Code__c = 'T1';
        uwList1.Rating_Factor__c = 1000;
        uwList1.Sort_Order__c = 10;
        uwList1.Submission__c = opp.Id;
        uwList1.UW_Analysis_Template__c = TempList.Id;
        uwList1.Sort_Order__c = 10;
        uwList1.Notional_Income__c = 1000;
        insert uwList1;
        
        
        
        //Create Coverage
        Coverage__c cov = TestUtil.createCoverage('Test Coverage','D&O');
        insert cov;
        
        // Coverages Line Item
        CoveragesLineItem__c coverLi = new CoveragesLineItem__c();
        coverLi.Coverage__c  = cov.Id; 
        coverLi.Quote__c = quote.Id;
        coverLi.Coverage_Premium__c  = 'Text Premium'; 
        coverLi.Min_amt__c  = 1000;
        coverLi.Max_amt__c  = 5000;
        coverLi.Deductible_Frequency__c  = 'Daily';
        coverLi.Options_Value_Percent__c  = 5;
        insert coverLi;
        
        Subjectivity__c subj = new Subjectivity__c();
        subj.Subjectivity__c = 'Testing';
        subJ.Subjectivity_Status__c = 'Open';
        subJ.Subjectivity_Type__c = 'MPL';
        subJ.Quote__c = quote.Id;
        insert subJ;
        
        Rating_Modifiers__c rMod = new Rating_Modifiers__c();
        rMod.Opportunity__c = opp.Id;
        insert rMod;     
        
        Rating_Modifiers__c rMod2 = new Rating_Modifiers__c();
        rMod2.Opportunity__c = opp.Id;
        insert rMod2;    
        
        Rating_Modifier_Factor__c rm = new Rating_Modifier_Factor__c();
        rm.Factor_Default_Value__c = 123;
        rm.Factor_Max__c = 300;
        rm.Factor_Min__c = 100;
        rm.Factor_Value__c = 120;
        rm.Rating_Modifier__c = rMod.Id;
        rm.Quote__c = quote.Id;    
        insert rm;    
        
        Document_Revision__c documentRevision  = new Document_Revision__c(
            Name = 'QuoteProposal' + '_' + String.valueOf(Datetime.now()),
            Document_Azure_Id__c = '1',
            Document_Type__c = 'QuoteProposal',
            Quote_Id__c = quote.Id
            //Contract__c = lstQuote2[0].ContractId
        );
        insert documentRevision;
        
        String dtNow = String.valueOf(Datetime.now());
        Document_Revision__c newDoc = new Document_Revision__c(
            Name = 'PolicyForm' + '_' + dtNow,
            Document_Azure_Id__c = '3',
            Document_Type__c = 'PolicyForm',
            RecordTypeId = rdPolicyId
            //Contract__c = lstQuote2[0].ContractId
        ); 
        insert newDoc; 
        
        // Create contact
        Contact con = new Contact(
            Email = 'test@j.com',
            Lastname = 'Test broker',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
        );
        insert con;
        
        // Create broker
        Broker_Account__c broketAccount = new Broker_Account__c(
            Broker_Contact__c = con.Id,
            Opportunity__c = opp.Id,
            IsPrimaryBroker__c = true,
            Relationship_Type__c = 'Broker'
        );
        insert broketAccount;
        
        Transactions__c transactions = new Transactions__c();
        transactions.Policy__c=policy.Id;
        transactions.Submission__c=opp.Id;
        insert transactions;
        
        quote.Policy__c = policy.Id;
        quote.Status = 'Bound';
        update quote;
        
        Insurer_Layer_Limit__c insurerLayerLimit = new Insurer_Layer_Limit__c();
        insurerLayerLimit.Quote__c = quote.Id;
        insurerLayerLimit.Layer__c = 'Test';
        insurerLayerLimit.CurrencyIsoCode = 'GBP';
        insert insurerLayerLimit;
        
        Location__c  loc = new Location__c (Geolocation__latitude__s=40,Geolocation__longitude__s=73);
        insert loc;
        
        Quote_Location__c ql = new Quote_Location__c(Quote__c = quote.Id, Locations__c = loc.Id);
        insert ql;
        
        
        Quote_Process__c quoteProcess = new Quote_Process__c(Submission__c = opp.Id, Account__c = opp.AccountId, Status__c = 'Submission Info');
        insert quoteProcess;
        
        Account_Loss_Detail__c accountLoss = new Account_Loss_Detail__c();
        accountLoss.Account__c = acc1.Id;
        accountLoss.Product__c = 'Private Company Combo';
        accountLoss.Loss_Amount__c = 123;
        accountLoss.Status__c = 'Open';
        accountLoss.Year__c = '2020';
        accountLoss.Number_of_Losses__c = 23;
        insert accountLoss;
        
        Submission_Loss_Detail__c subLoss = new Submission_Loss_Detail__c();
        subLoss.Submission__c = opp.Id;
        subLoss.Loss_Amount__c = 22200;
        subLoss.Status__c = 'Open';
        subLoss.Year__c ='2019';
        subLoss.Number_of_Losses__c=2;
        subLoss.Account_Loss_Detail__c = accountLoss.Id;
        insert subLoss;
        
        Referral_Reason__c ref1=new Referral_Reason__c();
        ref1.Approver_Level__c='3';
        ref1.Approval_Level_Required__c='1';
        ref1.Approval_Rejected_Date__c= date.today()+365;
        ref1.Quote__c=quote.id;
        insert ref1;  
        
        Quote_Option__c qo= new Quote_Option__c();
        //qo.Azure_ID__c =quote.Azure_ID__c;
        qo.Actual_Premium_Final__c=10000;
        qo.Actual_Premium_Annual__c=30000;
        qo.Quote__c=quote.Id;
        insert qo;  
        
        Master_Binder__c masterbinder =new Master_Binder__c();
        masterbinder.Layer__c = 'Primary;Excess';
        insert masterbinder;
    }
    
    @isTest
    public static void testcoverageCancelProcess() {
        
        
        Test.startTest();
        Master_Binder__c masterbinder =new Master_Binder__c();
        masterbinder.Layer__c = 'Primary;Excess';
        insert masterbinder;
        
        List<String> quoteIdList = new List<String>();
         Map<String,String> parentQuoteIdToClonedQuoteIdMap =  new Map<String,String>();
        
        set<Id> quoteId = new set<Id>();
        Quote quote = [SELECT id,Name,Policy__c,Layer__c,ExpirationDate,Quote_Type__c,OpportunityId, Policy__r.Id, Parent_Quote__c FROM Quote where Layer__c = 'Primary' LIMIT 1];
        Quote quoteclone = [SELECT id,Policy__c,Name,Layer__c,ExpirationDate,Quote_Type__c,OpportunityId, Policy__r.Id, Parent_Quote__c FROM Quote LIMIT 1];
        quoteId.add(quote.Id);
        
        List<Quote> quoteListToClone = new List<Quote>();
        quoteListToClone.add(quote);
        quoteListToClone.add(quoteclone);
        Policy__c policy = [SELECT id FROM Policy__c LIMIT 1];
        Opportunity opp = [SELECT id,Transaction_Status__c FROM Opportunity LIMIT 1];
        Opportunity oppClone = [SELECT id,Competing_Insurer__c FROM Opportunity LIMIT 1];
        Account acc = [SELECT id FROM Account LIMIT 1];
        
     /*   cloneRecordsNew.ResultWrapper resultwrap = new cloneRecordsNew.ResultWrapper();
        resultwrap.oppId = opp.Id;
        resultwrap.cloneQuoteId = '';
        resultwrap.error = '';
        resultwrap.showAccounts = true;*/
        
        Insurer_Layer_Limit__c insurerLayerLimit = new Insurer_Layer_Limit__c();
        insurerLayerLimit.Quote__c = quote.Id;
        insurerLayerLimit.Layer__c = 'Test';
        insurerLayerLimit.CurrencyIsoCode = 'GBP';
        insert insurerLayerLimit;
        
        cloneRecordsNew.coverageCancelProcess(quoteId, quoteclone.Id, policy.Id);
        
        opp.Transaction_Status__c = 'Active';
        update opp;
        cloneRecordsNew.coverageCancelProcess(quoteId, quoteclone.Id, policy.Id);
        
        //  cloneRecordsNew.policyRenewal(policy.Id);
        quote.Layer__c='Excess';
        update quote;
        //  cloneRecordsNew.policyRenewal(policy.Id);
        //Quote
        Quote quote1 = TestUtil.createQuote('New Quote',oppClone.Id);
        quote1.Coverage_Product_Options__c ='Professional Indemnity'; 
        quote1.Status = 'Quoted';
        quote1.Layer__c = 'Primary';
        quote1.OpportunityId = opp.Id;
        quote1.ExpirationDate = date.today() + 365;
        quote1.Quote_Type__c = 'Insured Account Update';
        quote1.Policy__c = policy.Id;
        insert quote1;
        
        Transactions__c transactions = new Transactions__c();
        transactions.Policy__c=policy.Id;
        transactions.Submission__c=opp.Id;
        insert transactions;
        
        quote1.Status='Bound';
        update quote1;
        
      	 Account acc2 = new Account();
        acc2.Name = 'Test account 3';
        acc2.BillingStreet = '11 Tran Duy Hung';
        acc2.BillingCity = 'Westminster';
        acc2.BillingState = 'California';
        acc2.BillingPostalCode = '90000';
        acc2.BillingCountry = 'United States';
        //acc1.Billing_County__c;
        acc2.IsMailingSameWithBillingAddress__c = true;
        acc2.Date_Started__c = Date.today().addYears(-2);
        insert acc2;
        Product2 product1 = TestUtil.createProduct('MPL');
        insert product1;
        Opportunity opp1 = TestUtil.createOpportunity('Opp Test1',acc2.Id, product1.Id);
        insert opp1;
        
        //cloneRecordsNew.policyRenewal(policy.Id);
        //cloneRecords.createRenewalQuotes(oppClone.Id, policy.Id, quoteListToClone, masterbinder.Id, masterbinder.Id);
        // cloneRecordsNew.queryRenewalQuote(quoteId);
        //cloneRecordsNew.queryOpportunity(opp.Id);
        cloneRecordsNew.cloneOpportunityDetails(opp);
        cloneRecordsNew.cloneQuoteCancelCoverage(quoteListToClone);
        cloneRecordsNew.queryCoverageCancelQuote(quoteId);
        cloneRecordsNew.coverageCancelProcess(quoteId, quoteclone.Id, policy.Id);
        cloneRecordsNew.cloneCoverageListForQuotes(quoteIdList,parentQuoteIdToClonedQuoteIdMap);
        cloneRecordsNew.cloneQuoteRelatedRecords(quoteIdList,parentQuoteIdToClonedQuoteIdMap,opp.id);
    	cloneRecordsNew.cloneOppRelatedRecords(opp.Id, opp1);
	        
        test.stopTest();
        System.assertEquals('Active',opp.Transaction_Status__c);
        
    }
    
    @isTest
    public static void testclone() {
        Test.startTest();
        List<Quote> quotes = [SELECT id, Name, Quote_Type__c, OpportunityId,
                              Policy__r.Id, Parent_Quote__c, CreatedDate 
                              FROM Quote LIMIT 1];
        List<Policy__c> policyIds = [SELECT id FROM Policy__c LIMIT 1];
        
        Opportunity opp = [SELECT id FROM Opportunity LIMIT 1];
        Opportunity opp1 = opp;
        opp1.Service_to_Run__c='None';
        
        String quoteId = quotes[0].Id;
        String polId = policyIds[0].Id;
        NewEndorsementController.coverageCancelProcess(quoteId, quotes[0].CreatedDate.date(), 'effectDate', polId);
        cloneRecordsNew.cloneQuote(quotes);
        
        test.stopTest();
        System.assert(opp != null);
    }  
}