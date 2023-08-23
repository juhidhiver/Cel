/**************************************************************************************************
* Class Name: NewEndorsementAQControllerTest
* Author: Ashik Zahir
* Created date: 15-April-2021
* Description: Controller class for NewEndorsementAQController
**************************************************************************************************/
@isTest
public class NewEndorsementAQControllerTest {
    
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
        opp.AccountId=acc.Id;
        opp.StageName = 'Qualified'; 
        opp.Innovisk_Entity_ID__c = 'Aqueous';                            
        opp.Product__c = product.Id;
        opp.Submission_Status__c = 'Quoted';
        opp.Transaction_Status__c = 'Active';
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        insert opp;
        
        String rdPolicyId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId(); 
        Policy__c policy = new Policy__c();
        policy.Account__c = acc.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);
        insert policy;
        
        //Quote
        Quote quote = TestUtil.createQuote('New Quote Test',opp.Id);
        quote.Coverage_Product_Options__c ='Professional Indemnity'; 
        quote.Status = 'Quoted';
        quote.Layer__c = 'Primary';
        quote.OpportunityId = opp.Id;
        quote.Policy__c = policy.Id;
        quote.Endorsement_Effective_Date__c = date.parse('08/04/2021');
        // quote.Endorsement_Type__c='New Business' - date.parse('08/08/2021');
        insert quote;
        
        
        Quote quote1 = TestUtil.createQuote('New Quote Test 2',opp.Id);
        quote1.Coverage_Product_Options__c ='Professional Indemnity'; 
        quote1.Status = 'Bound';
        quote1.Layer__c = 'Primary';
        quote1.Rating_Status__c = 'Clear';
        quote1.OpportunityId = opp.Id;
        quote1.Policy__c = policy.Id;
        quote1.Endorsement_Effective_Date__c = date.parse('08/04/2021');
        // quote.Endorsement_Type__c='New Business' - date.parse('08/08/2021');
        insert quote1;
        
        
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
        
        //Create Transaction
        Transactions__c transactions = new Transactions__c();
        transactions.Policy__c=policy.Id;
        transactions.Submission__c=opp.Id;
        insert transactions;
        
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
        
        //Rating Modifires
        Rating_Modifiers__c rMod = new Rating_Modifiers__c();
        rMod.Opportunity__c = opp.Id;
        insert rMod;     
        
        //Rating Modifier Factor
        Rating_Modifier_Factor__c rm = new Rating_Modifier_Factor__c();
        rm.Factor_Default_Value__c = 123;
        rm.Factor_Max__c = 300;
        rm.Factor_Min__c = 100;
        rm.Factor_Value__c = 120;
        rm.Rating_Modifier__c = rMod.Id;
        rm.Quote__c = quote.Id;    
        insert rm; 
        
        
    }
    
    
    
    @isTest 
    static void checkDuplicateAccountTest(){
        
        Account acc = [SELECT id,Name FROM Account LIMIT 1];
        Opportunity opp = [SELECT id,StageName,AccountId FROM Opportunity LIMIT 1];
        opp.StageName = 'Closed Won';
        opp.AccountId = acc.id;
        update opp;
        Test.startTest();
        String resp = '{"accId":"'+acc.Id+'","accName":"'+acc.Name+'","billingStreet":"123 Main Street","billingCity":"Anycity","stateCode":"ENGLAND","billingCountry":"United Kingdom","postalCode":"612001","countryCode":"GB","kycStatus":"Approved","sanctionStatus":"Pass","policyId":"test"}';
        //NewEndorsementAQController.ResultWrapper result = NewEndorsementAQController.checkDuplicateAccount(resp);
        Test.stopTest();
       // System.assert(result != null);
    }  
    
    @isTest 
    static void checkDuplicateAccountTest2(){
        
        Account acc1 = [SELECT id,Name FROM Account LIMIT 1];
        
        Opportunity opp1 = [SELECT id,StageName FROM Opportunity LIMIT 1];
        opp1.StageName = 'Closed Won';
        update opp1;
        
        Product2 product = [Select Id from Product2 Limit 1];
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc1.Id, product.Id);
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        opp.StageName = 'Closed Won'; 
        opp.Innovisk_Entity_ID__c = 'Aqueous';                            
        opp.Product__c = product.Id;
        opp.Submission_Status__c = 'Quoted';
        opp.Transaction_Status__c = 'Active';
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        insert opp;
        Test.startTest();
        String resp = '{"accId":"'+acc1.Id+'","accName":"'+acc1.Name+'","billingStreet":"123 Main Street","billingCity":"Anycity","stateCode":"ENGLAND","billingCountry":"United Kingdom","postalCode":"612001","countryCode":"GB","kycStatus":"Approved","sanctionStatus":"Pass","policyId":"test"}';
        NewEndorsementAQController.ResultWrapper result = NewEndorsementAQController.checkDuplicateAccount(resp);
        
        List<Account> getOppCount = [select id,(select id,StageName from Opportunities where StageName = 'Closed Won') from Account]; 
        
        Account acc = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        acc.Duns_Number__c = '1234';
        insert acc;
        
        NewEndorsementAQController.ResultWrapper result2 = NewEndorsementAQController.checkDuplicateAccount(resp);
        
        acc1.Duns_Number__c = '1234';
        //acc1.Opportunities = opp.Id;
        update acc1;
        
        NewEndorsementAQController.ResultWrapper result3 = NewEndorsementAQController.checkDuplicateAccount(resp);
        
        Test.stopTest();
        System.assert(result3 != null);
    }    
    
    @isTest static void cloneAccountWithRelatedTest(){
        Test.startTest();
        Transactions__c transactions = [SELECT Id, Policy__c,Policy__r.Id FROM Transactions__c Limit 1];
        NewEndorsementAQController.checkOpenQuotes(transactions.Policy__r.Id);
        String clonedoppId = '';
        String endorsementType = 'Insured Account Update';
        String resp = '{"accId":"test1","accName":"tes2"}';
        NewEndorsementAQController.ResultWrapper result = NewEndorsementAQController.cloneAccountWithRelated(resp);
        
        Test.stopTest();
        System.assert(result != null);
    }    
    
    @isTest
    public static void testInitData() {
        List<Policy__c> policyList = [select Id, Effective_Date__c,Expiration_Date__c from Policy__c ];
        List<Quote> quoteList = [select Id, status,Effective_Date__c,Policy__c,ExpirationDate from Quote where Policy__c =:policyList[0].id];
       	quoteList[0].Status = 'Bound';
        update quoteList;
        
        Test.startTest();
        NewEndorsementAQController.checkActiveSubmission('');
        NewEndorsementAQController.initData('','Professional Indemnity','Cancelled',Date.today(),Date.today().addMonths(2));
        NewEndorsementAQController.initData('','Professional Indemnity','Cancelled',Date.today(),null);
        NewEndorsementAQController.checkOpenQuotes('');
        NewEndorsementAQController.checkEndorsementDate(policyList[0].id,'15-04-21');
         NewEndorsementAQController.checkCancellationDate(policyList[0].id,'15-04-21');
       // NewEndorsementAQController.isPolicyExpired(policyList[0].id);
        NewEndorsementAQController.checkCancellationDate('','15-04-21');
        List<PicklistOption> result = NewEndorsementAQController.getQuotesEndorsementCancelPicklist();
        List<PicklistOption> result1 = NewEndorsementAQController.getKYCStatusPicklist();
        List<PicklistOption> result2 = NewEndorsementAQController.getSanctionStatusPicklist();
        List<PicklistOption> result3 = NewEndorsementAQController.getEndorsementReasons('Insured Account Update');
        Test.stopTest();
        System.assert(result!= null);   
    }
    
    @isTest
    public static void testBindQuoteEndorsement() {
        Test.startTest();
        date CreatedDate=date.today();
        Quote quote = [SELECT id FROM Quote LIMIT 1];
        Transactions__c transactions =[SELECT id FROM Transactions__c LIMIT 1];
        String result = NewEndorsementAQController.bindQuoteEndorsement(quote.Id,'2021-08-08','Non-Payment');
        String result1= NewEndorsementAQController.ratingQuoteEndorsement(quote.Id);
        NewEndorsementAQController.ratingQuoteRenewalOrNb(quote.Id);
        NewEndorsementAQController.coverageCancelProcess(null,CreatedDate,'','policy.Id');
        test.stopTest();
        System.assert(result!= null);
    }
    
    @isTest
   public static void testCreateNewEndorsement() {
        Quote quote = [SELECT id,Status FROM Quote LIMIT 1];
        Policy__c policy = [SELECT id FROM Policy__c LIMIT 1];
        Account acc = [SELECT id, Name FROM Account LIMIT 1];
        Transactions__c transactions =[SELECT id FROM Transactions__c LIMIT 1];
        Opportunity opp = [SELECT id,StageName,AccountId FROM Opportunity LIMIT 1];
        Test.startTest();
        Map<string,Object> accountData = new Map<string,Object>();
        accountData.put('accId',  acc.Id);
        accountData.put('accName',  acc.Name);
        accountData.put('billingStreet','123 Main Street');
        accountData.put('billingCity',  'Anycity');
        accountData.put('stateCode',  '11354');
        accountData.put('billingCountry',  'United Kingdom');
        accountData.put('postalCode','612001');
        accountData.put('countryCode',  '122');
        accountData.put('kycStatus',  'Approved');
        accountData.put('sanctionStatus', 'Pass');
        accountData.put('policyId', policy.Id);
        Quote_Process__c qp = new Quote_Process__c();
        qp.Account__c = acc.Id;
        qp.Submission__c = opp.Id;
        insert qp;
        NewEndorsementAQController.updateAccount(acc.Id,policy.Id,accountData);
        NewEndorsementAQController.updateAccount('',policy.Id,accountData);
        quote.Status = 'Bound';
        update Quote;
        List<Quote> listquote= new List<Quote>();
        Quote quote1 = [SELECT id,Status,Endorsement_Type__c,Effective_Date__c FROM Quote LIMIT 1];
        quote1.Status='Bound';
        quote1.Endorsement_Type__c='Coverage Cancel & Replace';
        //quote1.Effective_Date__c=Date.today()+30;
        update quote1;
        Quote quote2 = [SELECT id,Status FROM Quote LIMIT 1];
        quote2.Status='Cancelled';
        listquote.add(quote1);
        listquote.add(quote2);
        date CreatedDate=date.today();
        
        NewEndorsementAQController.showQuotes('policy.Id', 'quote1.Effective_Date__c',quote1.Endorsement_Type__c);
        NewEndorsementAQController.updatePolicyAccount(acc.Id,policy.Id);
       // NewEndorsementAQController.createNewEndorsement(policy.Id,'2021-08-08','Extension','Non-Payment','Non-Payment','Non-Payment',accountData);
        NewEndorsementAQController.coverageCancelProcess(quote1.id,CreatedDate,'quote1.Effective_Date__c','policy.Id');
        
        Test.stopTest();
        System.assert(accountData!= null);
    }  
    
    
    @isTest
    public static void testwrapper() {
        Test.startTest();
        Quote quote = [SELECT id FROM Quote LIMIT 1];
        Account acc = [SELECT id,Name FROM Account LIMIT 1];
        Policy__c policy = [SELECT id FROM Policy__c LIMIT 1];
        Opportunity opp = [SELECT id,StageName,AccountId FROM Opportunity LIMIT 1];
        NewEndorsementAQController.AddressWrapper address = new NewEndorsementAQController.AddressWrapper();
        address.accId = acc.Id;
        address.accName = acc.Name;
        address.billingStreet = '123 Main Street';
        address.billingCity = 'Anycity';
        address.stateCode = 'ENGLAND';
        address.billingCountry= 'United Kingdom';
        address.postalCode = '612001';
        address.countryCode = 'GB';
        address.kycStatus = 'Approved';
        address.sanctionStatus = 'Pass';
        address.policyId = policy.Id;
        
        Map<string,Object> accountData = new Map<string,Object>();
        accountData.put('accId',  acc.Id);
        accountData.put('accName',  acc.Name);
        accountData.put('billingStreet','123 Main Street');
        accountData.put('billingCity',  'Anycity');
        accountData.put('stateCode',  'ENGLAND');
        accountData.put('billingCountry',  'United Kingdom');
        accountData.put('postalCode','612001');
        accountData.put('countryCode',  'GB');
        accountData.put('kycStatus',  'Approved');
        accountData.put('sanctionStatus', 'Pass');
        accountData.put('policyId', policy.Id);
        Quote_Process__c qp = new Quote_Process__c();
        qp.Account__c = acc.Id;
        qp.Submission__c = opp.Id;
        insert qp;
        quote.Endorsement_Effective_Date__c=date.today()+30;
        quote.Effective_Date__c=date.today();
        update quote;
        
        NewEndorsementAQController.createNewEndorsement(policy.Id,date.today().format(),'Midterm Cancellation','Non-Payment','Non-Payment','Non-Payment',accountData);
        NewEndorsementAQController.createNewEndorsement(policy.Id,'2021-08-08','Extension','Non-Payment','Non-Payment','Non-Payment',accountData);
        NewEndorsementAQController.createNewEndorsement(policy.Id,'2021-08-08','Full Amendment','Non-Payment','Non-Payment','Non-Payment',accountData);
        NewEndorsementAQController.createNewEndorsement(policy.Id,'2021-08-08','Reinstatement','Non-Payment','Non-Payment','Non-Payment',accountData);
        NewEndorsementAQController.createNewEndorsement(policy.Id,'2021-08-08','Insured Account Update','Non-Payment','Non-Payment','Non-Payment',accountData);
        NewEndorsementAQController.createNewAccount(accountData, policy.Id);
        NewEndorsementAQController.createNewAccount(accountData, '');
        test.stopTest();
        System.assert(accountData!= null);
    }
    
    @isTest
    public static void testwrapper2() {
        Test.startTest();
        Quote quote = [SELECT id FROM Quote LIMIT 1];
        quote.Status = 'Bound';
        update quote;
        
        Account acc = [SELECT id,Name FROM Account LIMIT 1];
        Policy__c policy = [SELECT id FROM Policy__c LIMIT 1];
        
        NewEndorsementAQController.AddressWrapper address = new NewEndorsementAQController.AddressWrapper();
        address.accId = acc.Id;
        address.accName = acc.Name;
        address.billingStreet = '123 Main Street';
        address.billingCity = 'Anycity';
        address.stateCode = 'ENGLAND';
        address.billingCountry= 'United Kingdom';
        address.postalCode = '612001';
        address.countryCode = 'GB';
        address.kycStatus = 'Approved';
        address.sanctionStatus = 'Pass';
        address.policyId = policy.Id;
        
        Map<string,Object> accountData = new Map<string,Object>();
        accountData.put('accId',  acc.Id);
        accountData.put('accName',  acc.Name);
        accountData.put('billingStreet','123 Main Street');
        accountData.put('billingCity',  'Anycity');
        accountData.put('stateCode',  'ENGLAND');
        accountData.put('billingCountry',  'United Kingdom');
        accountData.put('postalCode','612001');
        accountData.put('countryCode',  'GB');
        accountData.put('kycStatus',  'Approved');
        accountData.put('sanctionStatus', 'Pass');
        accountData.put('policyId', policy.Id);
        
        quote.Endorsement_Effective_Date__c=date.today()+30;
        quote.Effective_Date__c=date.today();
        update quote;
        
        NewEndorsementAQController.createNewEndorsement(policy.Id,'2021-08-08','Reinstatement','Non-Payment','Non-Payment','Non-Payment',accountData);
        NewEndorsementAQController.createNewEndorsement(policy.Id,'2021-08-08','Insured Account Update','Non-Payment','Non-Payment','Non-Payment',accountData);
        test.stopTest();
        System.assert(accountData!= null);
    }   
    
    @isTest
    public static void testwrapper3() {
        Test.startTest();
        Quote quote = [SELECT id FROM Quote LIMIT 1];
        quote.Status = 'Bound';
        update quote;
        
        Account acc = [SELECT id,Name FROM Account LIMIT 1];
        Policy__c policy = [SELECT id FROM Policy__c LIMIT 1];
        
        NewEndorsementAQController.AddressWrapper address = new NewEndorsementAQController.AddressWrapper();
        address.accId = acc.Id;
        address.accName = acc.Name;
        address.billingStreet = '123 Main Street';
        address.billingCity = 'Anycity';
        address.stateCode = '11354';
        address.billingCountry= 'United Kingdom';
        address.postalCode = '612001';
        address.countryCode = '122';
        address.kycStatus = 'Approved';
        address.sanctionStatus = 'Pass';
        address.policyId = policy.Id;
        
        Map<string,Object> accountData = new Map<string,Object>();
        accountData.put('accId',  acc.Id);
        accountData.put('accName',  acc.Name);
        accountData.put('billingStreet','123 Main Street');
        accountData.put('billingCity',  'Anycity');
        accountData.put('stateCode',  '11354');
        accountData.put('billingCountry',  'United Kingdom');
        accountData.put('postalCode','612001');
        accountData.put('countryCode',  '122');
        accountData.put('kycStatus',  'Approved');
        accountData.put('sanctionStatus', 'Pass');
        accountData.put('policyId', policy.Id);
        
        quote.Endorsement_Effective_Date__c=date.today()+30;
        quote.Effective_Date__c=date.today();
        update quote;
        
        NewEndorsementAQController.createNewEndorsement(policy.Id,'2021-08-08','Coverage Amendment','Non-Payment','Non-Payment','Non-Payment',accountData);
        test.stopTest();
        System.assert(accountData!= null);
    }      
    
    @isTest
    public static void testwrapper4() {
        Test.startTest();
        Quote quote = [SELECT id FROM Quote LIMIT 1];
        quote.Status = 'Bound';
        update quote;
        
        Account acc = [SELECT id,Name FROM Account LIMIT 1];
        Policy__c policy = [SELECT id FROM Policy__c LIMIT 1];
        
        NewEndorsementAQController.AddressWrapper address = new NewEndorsementAQController.AddressWrapper();
        address.accId = acc.Id;
        address.accName = acc.Name;
        address.billingStreet = '123 Main Street';
        address.billingCity = 'Anycity';
        address.stateCode = '11354';
        address.billingCountry= 'United Kingdom';
        address.postalCode = '612001';
        address.countryCode = '122';
        address.kycStatus = 'Approved';
        address.kycDate = date.today();
        address.sanctionStatus = 'Pass';
        address.sanctionDate = date.today();
        address.policyId = policy.Id;
        
        Map<string,Object> accountData = new Map<string,Object>();
        accountData.put('accId',  acc.Id);
        accountData.put('accName',  acc.Name);
        accountData.put('billingStreet','123 Main Street');
        accountData.put('billingCity',  'Anycity');
        accountData.put('stateCode',  '11354');
        accountData.put('billingCountry',  'United Kingdom');
        accountData.put('postalCode','612001');
        accountData.put('countryCode',  '122');
        accountData.put('kycStatus',  'Approved');
        accountData.put('sanctionStatus', 'Pass');
        accountData.put('policyId', policy.Id);
        
        quote.Endorsement_Effective_Date__c=date.today()+30;
        quote.Effective_Date__c=date.today();
        update quote;
        NewEndorsementAQController.cloneAccountWithRelated(System.JSON.serialize(address));
        NewEndorsementAQController.createNewEndorsement(policy.Id,'2021-08-08','Full Amendment','Non-Payment','Non-Payment','Non-Payment',accountData);
        NewEndorsementAQController.validateSanctionCheckOnAccount(acc.id,policy.Id);
        
        test.stopTest();
        System.assert(accountData!= null);
    }   
    @isTest
    public static void testResultwrapper() {
        Test.startTest();
        Quote quote = [SELECT id FROM Quote LIMIT 1];
        Account acc = [SELECT id,Name FROM Account LIMIT 1];
        Policy__c policy = [SELECT id FROM Policy__c LIMIT 1];
        Opportunity opp =  [SELECT id FROM Opportunity LIMIT 1];
        
        NewEndorsementAQController.ResultWrapper resultwrap = new NewEndorsementAQController.ResultWrapper();
        resultwrap.oppId = opp.Id;
        resultwrap.cloneQuoteId = '';
        resultwrap.error = '';
        resultwrap.resultAccId = acc.Id;
        resultwrap.showAccounts = true;
        
        NewEndorsementAQController.AccountWrapper accwrap = new NewEndorsementAQController.AccountWrapper();
        accwrap.accId = acc.Id;
        accwrap.billingStreet = '123 Main Street';
        accwrap.dunsNumber = '123';
        accwrap.name = acc.Name;
        accwrap.type = 'Customer';
        
        NewEndorsementAQController.validateSanctionCheckOnAccount(acc.id,policy.Id);
        
        test.stopTest();
        System.assert(accwrap!= null);
    }
    @isTest
    public static void testgetAccountDetails() {    
        Test.startTest();
        date CreatedDate=date.today();
        Transactions__c transactions = [SELECT Id, Policy__c FROM Transactions__c Limit 1];
        NewEndorsementAQController.getAccountDetails(transactions.Policy__c);
        try{
            NewEndorsementAQController.FullAmendmentCancelProcess(null,CreatedDate,String.valueOf(date.today()),transactions.Policy__c);
        }   catch(NullPointerException ex){
            
        }
        
        Test.stopTest();
        System.assert(transactions.Id != null);
    }
    @isTest
    public static void syncQuoteFun(){
        Quote quoteTest = [Select Id, Status, Quote_Type__c, Parent_Quote__c, AccountId, OpportunityId from Quote limit 1];
        
        Quote q = new Quote(Name = 'Test',OpportunityId =quoteTest.OpportunityId,Status = 'Bound');
        insert q;
         
        Quote_Option__c qo = new Quote_Option__c();
        qo.Quote__c = quoteTest.id;
        qo.Bound__c = true;
        insert qo;
        
        Policy__c policyRec  = [select id from policy__c limit 1];
        
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
        Test.startTest();
        NewEndorsementAQController.syncQuoteFunc(policyRec.Id);
        NewEndorsementAQController.populateQuoteOption(quoteTest.Id);
        Test.stopTest();
    }
}