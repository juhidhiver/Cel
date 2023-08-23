/**************************************************************************************************
* Class Name: cloneRecordsTest
* Author: Ashik Zahir
* Created date: 15-April-2021
* Description: Test Class for cloneRecords class
**************************************************************************************************/
@isTest
public class cloneRecordsTest {
    
    @testSetup 
    static void createData(){
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        setting.BypassCoverageLineItemTrigger__c = true;
        setting.BypassAccountTrigger__c = true;
        update setting;
        
        Account acc = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 product = TestUtil.createProduct('Professional Indemnity');
        product.RecordTypeId = aqueousRecordTypeId; 
        product.Innovisk_Entity_ID__c = 'Aqueous';
        insert product;        
        
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        opp.StageName = 'Qualified'; 
        opp.Innovisk_Entity_ID__c = 'Aqueous';                            
        opp.Product__c = product.Id;
        opp.Submission_Status__c = 'Quoted';
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        opp.Transaction_Status__c = 'Active';
        insert opp;
        
        Opportunity oppClone = TestUtil.createOpportunity('Opp Test clone',acc.Id, product.Id);
        oppClone.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        oppClone.StageName = 'Qualified'; 
        oppClone.Innovisk_Entity_ID__c = 'Aqueous'; 
        oppClone.Competing_Insurer__c = 'test6';
        oppClone.Product__c = product.Id;
        oppClone.Submission_Status__c = 'Quoted';
        oppClone.Coverage_Product_Options__c = 'Professional Indemnity';
        insert oppClone;
        
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
        
        String rdPolicyId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId(); 
        Policy__c policy = new Policy__c();
        policy.Account__c = acc.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);
        insert policy;
        
        Policy__c policy2 = new Policy__c();
        policy2.Account__c = acc.Id; 
        policy2.Expiration_Date__c = Date.today().addDays(100);
        insert policy2;
        
        Master_Binder__c masterbinder1 =new Master_Binder__c();
        masterbinder1.Layer__c = 'Primary;Excess';
        insert masterbinder1;
        
        //Quote
        Quote quote = TestUtil.createQuote('New Quote Test',opp.Id);
        quote.Coverage_Product_Options__c ='Professional Indemnity'; 
        quote.Status = 'Quoted';
        quote.Master_Binder__c = masterbinder1.Id;
        quote.Layer__c = 'Primary';
        quote.OpportunityId = opp.Id;
        quote.ExpirationDate = date.today() + 365;
        quote.Effective_Date__c = date.today();
        // quote.Endorsement_Type__c='New Business';
        quote.Quote_Type__c = 'Insured Account Update';
        quote.Policy__c = policy.Id;
        insert quote;
        
        Quote quoteclone = TestUtil.createQuote('New Quote Test 2',opp.Id);
        quoteclone.Coverage_Product_Options__c ='Professional Indemnity'; 
        quoteclone.Status = 'Quoted';
        quoteclone.Layer__c = 'Excess';
        quoteclone.OpportunityId = opp.Id;
        quoteclone.ExpirationDate = date.today() + 365;
        quoteclone.Quote_Type__c = 'Insured Account Update';
        quoteclone.Policy__c = policy2.Id;
        quoteclone.Parent_Quote__c = quote.Id;
        insert quoteclone;
        
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
        subJ.RecordTypeId = Schema.SObjectType.Subjectivity__c.getRecordTypeInfosByName().get(GlobalVariables.RT_NAME_SUBJECTIVITY_CELERITY).getRecordTypeId();
        insert subJ;
        
        Rating_Modifiers__c rMod = new Rating_Modifiers__c();
        rMod.Opportunity__c = opp.Id;
        insert rMod;     
        
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
        
        Transactions__c transactions2 = new Transactions__c();
        transactions2.Policy__c=policy2.Id;
        transactions2.Submission__c=opp.Id;
        insert transactions2;
        
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
        accountLoss.Account__c = acc.Id;
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
        qo.Option_Type__c='Fixed Limit';
        qo.Actual_Premium_Final__c=10000;
        qo.Actual_Premium_Annual__c=30000;
        qo.Quote__c=quote.Id;
        qo.Bound__c = true;
        insert qo;  
        
        Master_Binder__c masterbinder =new Master_Binder__c();
        masterbinder.Layer__c = 'Primary;Excess';
        insert masterbinder;
        
        /*Free_Form_Endorsements__c freeForm=new Free_Form_Endorsements__c();
freeForm.Quote__c=quote.id;
freeForm.Coverage_Effective_Date__c=Date.today().addDays(30);
freeForm.Form_Number__c='12345';
freeForm.Endorsement_Name__c='New Endorsement';
freeForm.Endorsement_Wording__c= 'NewEndorsement' ;
insert freeForm;*/
    }
    
    @isTest
    public static void testfullAmendment() {
        
        Master_Binder__c masterbinder =new Master_Binder__c();
        masterbinder.Layer__c = 'Primary;Excess';
        insert masterbinder;
        
        set<Id> quoteId = new set<Id>();
        Quote quote = [SELECT id,Name,Policy__c,Layer__c,ExpirationDate,Quote_Type__c,OpportunityId, Policy__r.Id, Parent_Quote__c FROM Quote where Layer__c = 'Primary' LIMIT 1];
        Quote quoteclone = [SELECT id,Policy__c,Name,Layer__c,ExpirationDate,Quote_Type__c,OpportunityId, Policy__r.Id, Parent_Quote__c FROM Quote where Layer__c = 'Excess'  LIMIT 1];
        quoteId.add(quote.Id);
        
        List<Quote> quoteListToClone = new List<Quote>();
        quoteListToClone.add(quote);
        quoteListToClone.add(quoteclone);
        Policy__c policy = [SELECT id FROM Policy__c LIMIT 1];
        Opportunity opp = [SELECT id,Transaction_Status__c FROM Opportunity LIMIT 1];
        Opportunity oppClone = [SELECT id,Competing_Insurer__c FROM Opportunity where Competing_Insurer__c = 'test6' LIMIT 1];
        Account acc = [SELECT id FROM Account LIMIT 1];
        
        Insurer_Layer_Limit__c insurerLayerLimit = new Insurer_Layer_Limit__c();
        insurerLayerLimit.Quote__c = quote.Id;
        insurerLayerLimit.Layer__c = 'Test';
        insurerLayerLimit.CurrencyIsoCode = 'GBP';
        insert insurerLayerLimit;
        
        /*Free_Form_Endorsements__c freeForm=new Free_Form_Endorsements__c();
freeForm.Quote__c=quote.id;
freeForm.Coverage_Effective_Date__c=Date.today().addDays(30);
freeForm.Form_Number__c='12345';
freeForm.Endorsement_Name__c='New Endorsement';
freeForm.Endorsement_Wording__c= 'NewEndorsement' ;
insert freeForm;*/
        Date todaysDate = System.today();
        String todaysDateStr = String.valueOf(todaysDate);
        //cloneRecords.fullAmendment(policy.Id, 'Insured Account Update',todaysDateStr,'','test');
        
        opp.Transaction_Status__c = 'Active';
        update opp;
        cloneRecords.fullAmendment(policy.Id, 'Insured Account Update',todaysDateStr,'','test');
        //cloneRecords.policyRenewal(policy.Id);
        quote.Layer__c='Excess';
        update quote;
        //cloneRecords.policyRenewal(policy.Id);
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
        
        cloneRecords.policyRenewal(policy.Id);
        //cloneRecords.createRenewalQuotes(oppClone.Id, policy.Id, quoteListToClone, masterbinder.Id, masterbinder.Id);
        cloneRecords.queryRenewalQuote(quoteId);
        cloneRecords.queryOpportunity(opp.Id);
        cloneRecords.cloneOpportunityDetails(opp);
        cloneRecords.cloneQuoteCancelCoverage(quoteListToClone);
        cloneRecords.queryCoverageCancelQuote(quoteId);
        Test.startTest();
        cloneRecords.coverageCancelProcess(quoteId, quoteclone.Id, policy.Id);
        
        test.stopTest();
        System.assertEquals('Active',opp.Transaction_Status__c);
    }
    
    @isTest
    public static void testclone() {
        Test.startTest();
        List<Quote> quotes = [SELECT id, Name, Quote_Type__c, OpportunityId, Policy__r.Id, Parent_Quote__c FROM Quote LIMIT 1];
        List<Policy__c> policyIds = [SELECT id FROM Policy__c LIMIT 1];
        Quote_Option__c quoteOption=[Select id,Option_Type__c From Quote_Option__c Limit 1];
        
        Opportunity opp = [SELECT id FROM Opportunity LIMIT 1];
        Opportunity opp1 = opp;
        opp1.Service_to_Run__c='None';
        cloneRecords.cloneQuote(quotes);
        cloneRecords.createQuoteOptions(2,quotes[0].id,quoteOption.Option_Type__c);
        test.stopTest();
        System.assert(opp != null);
    }  
    
    @isTest public static void cloneQuoteRenewalRelatedRecordsTest(){
        List<Quote> quotes = [SELECT id, Name, Quote_Type__c, OpportunityId, Policy__r.Id, Parent_Quote__c FROM Quote LIMIT 1];
        List<String> quoteIdList = new List<String>();
        Map<String,String> parentQuoteIdToClonedQuoteIdMap = new Map<String,String>();
        quoteIdList.add(quotes[0].id);
        
        Quote newQuote = quotes[0].clone(false,false,false,false);
        insert newQuote;
        
        parentQuoteIdToClonedQuoteIdMap.put(quotes[0].id, newQuote.id);
        
        Opportunity opp = [SELECT id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        cloneRecords.cloneQuoteRenewalRelatedRecords(quoteIdList, parentQuoteIdToClonedQuoteIdMap, opp.Id);
        Test.stopTest();
    }
    
    @isTest public static void createRenewalQuotesTest(){
        Opportunity opp = [SELECT id FROM Opportunity Where Name = 'Opp Test clone' LIMIT 1];
        Policy__c policy = [SELECT id FROM Policy__c LIMIT 1];
        List<Quote> quoteListToClone = [SELECT id, Name,Effective_Date__c,ExpirationDate, Layer__c,Quote_Type__c, OpportunityId, Policy__r.Id, Parent_Quote__c FROM Quote LIMIT 1];
        Master_Binder__c masterbinder = [SELECT id FROM Master_Binder__c Limit 1];
        RenewalPolicyAQController.ResultWrapper wrapper = new RenewalPolicyAQController.ResultWrapper();
        
        wrapper = cloneRecords.createRenewalQuotes(opp.Id, policy.Id, quoteListToClone, masterbinder.Id, masterbinder.Id);
        
    }
    @isTest public static void exceptionTest(){
        List<Quote> quoteListToClone = [SELECT id, Name,Effective_Date__c,ExpirationDate, Layer__c,Quote_Type__c, OpportunityId, Policy__r.Id, Parent_Quote__c FROM Quote LIMIT 1];
        RenewalPolicyAQController.ResultWrapper wrapper = new RenewalPolicyAQController.ResultWrapper();
        wrapper = cloneRecords.createRenewalQuotes('', '', quoteListToClone, '', '');
        
        cloneRecords.fullAmendment('', '','','','');
        cloneRecords.policyRenewal('');
        
    }
    @isTest
    public static void testPolicyRenewal() {
        
        
        set<Id> quoteId = new set<Id>();
        Quote quote = [SELECT id,Name,Policy__c,Layer__c,ExpirationDate,Quote_Type__c,OpportunityId, Policy__r.Id, Parent_Quote__c,Effective_Date__c FROM Quote where Layer__c = 'Primary' LIMIT 1];
        quote.Effective_Date__c=date.today()+1;
        quote.ExpirationDate=date.today()+365;
        quote.status = 'Bound';
        update quote;
        Quote quoteclone = [SELECT id,Policy__c,Name,Layer__c,ExpirationDate,Quote_Type__c,OpportunityId, Policy__r.Id, Parent_Quote__c,Effective_Date__c FROM Quote where Layer__c = 'Excess'  LIMIT 1];
        quoteclone.Effective_Date__c=date.today()+1;
        quoteclone.ExpirationDate=date.today()+365;
        quoteclone.status = 'Quoted';
        update quoteclone;
        
        // Added by Rinku Saini For CD-118
        Quote_Option__c qo= new Quote_Option__c();
        //qo.Azure_ID__c =quote.Azure_ID__c;
        qo.Option_Type__c='Fixed Limit';
        qo.Actual_Premium_Final__c=10000;
        qo.Actual_Premium_Annual__c=30000;
        qo.Quote__c=quoteclone.Id;
        qo.Bound__c = false;
        insert qo; 
        
        // Added by Rinku Saini For CD-118
        Referral_Reason__c ref1=new Referral_Reason__c();
        ref1.Approver_Level__c='3';
        ref1.Approval_Level_Required__c='1';
        ref1.Approval_Rejected_Date__c= date.today()+365;
        ref1.Quote__c=quoteclone.id;
        ref1.Quote_Option__c = qo.Id;
        ref1.Approval_Status__c = 'Rejected';
        insert ref1; 
        
        
        quoteId.add(quote.Id);
        quoteId.add(quoteclone.Id);
        //List<Quote> quoteListToClone = new List<Quote>();
        //quoteListToClone.add(quote.id);
        //quoteListToClone.add(quoteclone.id);
        Policy__c policy = [SELECT id FROM Policy__c LIMIT 1];
        Test.startTest();
        cloneRecords.policyRenewal(policy.id);
        CloneServiceHandler_Common.cloneQuote( New List<Quote>());
        CloneServiceHandler_Common.cloneQuoteWithChildren('',null);// Added by Rinku Saini For CD-118
        QuoteCompareItemWrapper.cloneExcessQuoteHandler(quoteclone.Id,'Excess');// Added by Rinku Saini For CD-118
        QuoteCompareItemWrapper.cloneExcessQuoteHandler(quote.Id,'Excess');// Added by Rinku Saini For CD-118
        test.stopTest();
    }
    
    // Added by Rinku Saini For CD-118
    @isTest
    public static void testPolicyRenewal1() {
        
        
        set<Id> quoteId = new set<Id>();
        Quote quote = [SELECT id,Name,Policy__c,Layer__c,ExpirationDate,Quote_Type__c,OpportunityId, Policy__r.Id, Parent_Quote__c,Effective_Date__c FROM Quote where Layer__c = 'Primary' LIMIT 1];
        quote.Effective_Date__c=date.today()+1;
        quote.ExpirationDate=date.today()+365;
        quote.status = 'Bound';
        update quote;
        Quote quoteclone = [SELECT id,Policy__c,Name,Layer__c,ExpirationDate,Quote_Type__c,OpportunityId, Policy__r.Id, Parent_Quote__c,Effective_Date__c FROM Quote where Layer__c = 'Excess'  LIMIT 1];
        quoteclone.Effective_Date__c=date.today()+1;
        quoteclone.ExpirationDate=date.today()+365;
        quoteclone.status = 'Bound';
        quoteclone.Quote_Type__c = 'New Business';
        update quoteclone;
        
        Quote_Option__c qo= new Quote_Option__c();
        //qo.Azure_ID__c =quote.Azure_ID__c;
        qo.Option_Type__c='Fixed Limit';
        qo.Actual_Premium_Final__c=10000;
        qo.Actual_Premium_Annual__c=30000;
        qo.Quote__c=quoteclone.Id;
        qo.Bound__c = true;
        insert qo; 
        
        Referral_Reason__c ref1=new Referral_Reason__c();
        ref1.Approver_Level__c='3';
        ref1.Approval_Level_Required__c='1';
        ref1.Approval_Rejected_Date__c= date.today()+365;
        ref1.Quote__c=quoteclone.id;
        ref1.Quote_Option__c = qo.Id;
        ref1.Approval_Status__c = 'Approved';
        insert ref1; 
        
        
        quoteId.add(quote.Id);
        quoteId.add(quoteclone.Id);
        //List<Quote> quoteListToClone = new List<Quote>();
        //quoteListToClone.add(quote.id);
        //quoteListToClone.add(quoteclone.id);
        Policy__c policy = [SELECT id FROM Policy__c LIMIT 1];
        Test.startTest();
        cloneRecords.policyRenewal(policy.id);
        CloneServiceHandler_Common.cloneQuote( New List<Quote>());
        CloneServiceHandler_Common.cloneQuoteWithChildren('',null);
        QuoteCompareItemWrapper.cloneExcessQuoteHandler(quoteclone.Id,'Excess');
        QuoteCompareItemWrapper.cloneExcessQuoteHandler(quote.Id,'Excess');
        test.stopTest();
    }
    
    
    // Added by Rinku Saini For CD-118
    public static testmethod void coverCloneService(){
        Test.startTest();
        
        
        Account acc = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        // Create product
        Product2 PCCprd = TestUtil.createProduct('Private Company Combo');
        PCCprd.Expiration_Date__c = Date.today().addDays(200);
        PCCprd.Effective_Date__c = Date.today().addDays(-1);
        PCCprd.Innovisk_Entity_ID__c = 'Celerity'; 
        insert PCCprd;
        
        Opportunity PCCopp = TestUtil.createOpportunity('Opp Test',acc.Id, PCCprd.Id);
        PCCopp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
        PCCopp.StageName = 'Qualified'; 
        PCCopp.Innovisk_Entity_ID__c = 'Celerity';                            
        PCCopp.Product__c = PCCprd.Id;
        // PCCopp.Submission_Status__c = 'Quoted';
        PCCopp.Coverage_Product_Options__c = 'D&O';
        PCCopp.Transaction_Status__c = 'Active';
        insert PCCopp;
        
        Policy__c policy = new Policy__c();
        policy.Account__c = acc.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);
        insert policy;
        
        //Quote
        Quote quote = TestUtil.createQuote('New Quote Test',PCCopp.Id);
        quote.Coverage_Product_Options__c ='Professional Indemnity'; 
        quote.Status = 'Quoted';
        quote.Layer__c = 'Primary';
        quote.OpportunityId = PCCopp.Id;
        quote.ExpirationDate = date.today() + 365;
        quote.Effective_Date__c = date.today();
        // quote.Endorsement_Type__c='New Business';
        quote.Quote_Type__c = 'Insured Account Update';
        quote.Policy__c = policy.Id;
        insert quote;
        
        Referral_Reason__c ref1=new Referral_Reason__c();
        ref1.Approver_Level__c='3';
        ref1.Approval_Level_Required__c='1';
        ref1.Approval_Rejected_Date__c= date.today()+365;
        ref1.Quote__c=quote.id;
        insert ref1; 
        
        Quote_Option__c qo= new Quote_Option__c();
        //qo.Azure_ID__c =quote.Azure_ID__c;
        qo.Option_Type__c='Fixed Limit';
        qo.Actual_Premium_Final__c=10000;
        qo.Actual_Premium_Annual__c=30000;
        qo.Quote__c=quote.Id;
        qo.Bound__c = true;
        insert qo; 
        
        // Create account for additional interests
        Account addAcc1 = new Account(
            Name = 'Additional interest account 1',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId()
        );
        insert addAcc1;
        
        //Create Coverage
        Coverage__c cov = TestUtil.createCoverage('Test Coverage','D&O');
        cov.Coverage_Type__c = 'Endorsement';
        cov.Additional_Requirements__c = 'Load by Default';
        cov.Coverage_Product__c = 'Excess';
        insert cov;
        
        //create limit deductables
        Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
        insert ded;
        
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
        
        Free_Form_Endorsements__c freeForm=new Free_Form_Endorsements__c();
        freeForm.Quote__c=quote.id;
        freeForm.Coverage_Effective_Date__c=Date.today().addDays(30);
        freeForm.Form_Number__c='12345';
        freeForm.Endorsement_Name__c='New Endorsement';
        freeForm.Endorsement_Wording__c= 'NewEndorsement' ;
        insert freeForm;
        
        QuoteCompareItemWrapper.cloneExcessQuoteHandler(quote.Id,'Excess');
        
        Map<string,Object> accountData = new Map<string,Object>();
        accountData.put('accId',  acc.Id);
        accountData.put('accName',  acc.Name);
        accountData.put('billingStreet','123 Main Street');
        accountData.put('billingCity',  'Anycity');
        accountData.put('stateCode',  '11354');
        accountData.put('billingCountry',  'United States');
        accountData.put('postalCode','612001');
        accountData.put('countryCode',  '122');
        accountData.put('kycStatus',  'Approved');
        accountData.put('sanctionStatus', 'Pass');
        accountData.put('policyId', policy.Id);
        quote.Status = 'Bound';
        update quote;
        
        NewEndorsementAQController.createNewEndorsement(policy.Id,'2022-10-20','Flat Cancellation','Non-Payment','Non-Payment','Non-Payment',accountData);
        NewEndorsementAQController.createNewEndorsement(policy.Id,'2022-10-20','Reinstatement','Non-Payment','Non-Payment','Non-Payment',accountData);
        Test.stopTest();
    }
    
    // Added by Rinku Saini For CD-118
    public static testmethod void coverCloneService1(){
        Test.startTest();
        
        // Create product and coverage
        Product2 prd = new Product2(
            Name = 'Private Company Combo',
            Innovisk_Entity_ID__c = 'Celerity',
            Package_Indicator__c = true,
            IsActive = true,
            Expiration_Date__c = Date.today().addDays(200),
            Effective_Date__c = Date.today().addDays(-1)
        );
        insert prd;
        
        Account acc1 = new Account();
        acc1.Name = 'Test account 1';
        acc1.BillingStreet = '01 Tran Duy Hung';
        acc1.BillingCity = 'Westminster';
        acc1.BillingState = 'California';
        acc1.BillingPostalCode = '90000';
        acc1.BillingCountry = 'United States';
        acc1.IsMailingSameWithBillingAddress__c = true;
        acc1.Date_Started__c = Date.today().addYears(-2);
        insert acc1;
        
        // Create opportunity
        Opportunity opp = new Opportunity();
        opp.Name = 'Test opp';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
        opp.Coverage_Product_Options__c = 'D&O';
        opp.AccountId = acc1.Id;
        opp.Pricebook2Id = Test.getStandardPricebookId();
        opp.Product__c = prd.Id;
        opp.Received_Date__c = Date.today();
        opp.CloseDate = Date.today().addDays(30);
        opp.Effective_Date__c = Date.today().addDays(1);
        opp.Type = 'New Business';
        opp.LeadSource = 'Email';
        opp.StageName = 'Qualified';
        insert opp;
        
        // Create contact
        Contact con = new Contact(
            Lastname = 'Huy broker',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
        );
        insert con;
        
        // Create broker
        Broker_Account__c broker = new Broker_Account__c(
            Broker_Contact__c = con.Id,
            Opportunity__c = opp.Id,
            IsPrimaryBroker__c = true,
            Relationship_Type__c = 'Broker'
        );
        insert broker;
        
        // Create pricebook entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(), 
            Product2Id = prd.Id, 
            UnitPrice = 10000, 
            IsActive = true
        );
        insert pbe;
        
        // Create quote
        Quote quote = new Quote(
            OpportunityId = opp.Id,
            Name = 'Test quote 1',
            Coverage_Product_Options__c = 'D&O',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert quote;
        
        Quote_Option__c qo= new Quote_Option__c();
        //qo.Azure_ID__c =quote.Azure_ID__c;
        qo.Option_Type__c='Fixed Limit';
        qo.Actual_Premium_Final__c=10000;
        qo.Actual_Premium_Annual__c=30000;
        qo.Quote__c=quote.Id;
        qo.Bound__c = true;
        insert qo; 
        
        // Create account for additional interests
        Account addAcc1 = new Account(
            Name = 'Additional interest account 1',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId()
        );
        insert addAcc1;
        
        // Create additional interests
        Additional_Interests__c addInt = new Additional_Interests__c(
            Additional_Interest_Account__c = addAcc1.Id,
            Quote__c = quote.Id,
            Relationship_Type__c = 'Additional Insured'
        );
        insert addInt;
        
        QuoteCompareItemWrapper.cloneExcessQuoteHandler(quote.Id,'Excess');
        
        Test.stopTest();
    }
    
    // Added by Rinku Saini For CD-118
    public static testmethod void coverCloneService2(){
        Test.startTest();
        
        // Create product and coverage
        Product2 prd = new Product2(
            Name = 'MPL',
            Innovisk_Entity_ID__c = 'Celerity',
            Package_Indicator__c = true,
            IsActive = true,
            Expiration_Date__c = Date.today().addDays(200),
            Effective_Date__c = Date.today().addDays(-1)
        );
        insert prd;
        
        Account acc1 = new Account();
        acc1.Name = 'Test account 1';
        acc1.BillingStreet = '01 Tran Duy Hung';
        acc1.BillingCity = 'Westminster';
        acc1.BillingState = 'California';
        acc1.BillingPostalCode = '90000';
        acc1.BillingCountry = 'United States';
        acc1.IsMailingSameWithBillingAddress__c = true;
        acc1.Date_Started__c = Date.today().addYears(-2);
        insert acc1;
        
        // Create opportunity
        Opportunity opp = new Opportunity();
        opp.Name = 'Test opp';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
        opp.Coverage_Product_Options__c = 'D&O';
        opp.AccountId = acc1.Id;
        opp.Pricebook2Id = Test.getStandardPricebookId();
        opp.Product__c = prd.Id;
        opp.Received_Date__c = Date.today();
        opp.CloseDate = Date.today().addDays(30);
        opp.Effective_Date__c = Date.today().addDays(1);
        opp.Type = 'New Business';
        opp.LeadSource = 'Email';
        opp.StageName = 'Qualified';
        insert opp;
        
        // Create contact
        Contact con = new Contact(
            Lastname = 'Huy broker',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
        );
        insert con;
        
        // Create broker
        Broker_Account__c broker = new Broker_Account__c(
            Broker_Contact__c = con.Id,
            Opportunity__c = opp.Id,
            IsPrimaryBroker__c = true,
            Relationship_Type__c = 'Broker'
        );
        insert broker;
        
        // Create pricebook entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(), 
            Product2Id = prd.Id, 
            UnitPrice = 10000, 
            IsActive = true
        );
        insert pbe;
        
        // Create quote
        Quote quote = new Quote(
            OpportunityId = opp.Id,
            Name = 'Test quote 1',
            Coverage_Product_Options__c = 'D&O',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert quote;
        
        Quote_Option__c qo= new Quote_Option__c();
        //qo.Azure_ID__c =quote.Azure_ID__c;
        qo.Option_Type__c='Fixed Limit';
        qo.Actual_Premium_Final__c=10000;
        qo.Actual_Premium_Annual__c=30000;
        qo.Quote__c=quote.Id;
        qo.Bound__c = true;
        insert qo; 
        
        // Create account for additional interests
        Account addAcc1 = new Account(
            Name = 'Additional interest account 1',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId()
        );
        insert addAcc1;
        
        // Create additional interests
        Additional_Interests__c addInt = new Additional_Interests__c(
            Additional_Interest_Account__c = addAcc1.Id,
            Quote__c = quote.Id,
            Relationship_Type__c = 'Additional Insured'
        );
        insert addInt;
        
        QuoteCompareItemWrapper.cloneExcessQuoteHandler(quote.Id,'Excess');
        
        Test.stopTest();
    }
}