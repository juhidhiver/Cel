/***************************************************
* Class Name: BindQuoteControllerTest
* Author: Giang Phan
* Date: 08-Nov-2019
* Description: Unit test for BindQuoteController
****************************************************/
@isTest
private class BindQuoteControllerTest {
    private static String responseBodyJson;
    @testSetup
    static void setup(){
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        setting.BypassCoverageLineItemTrigger__c = true;
        setting.BypassAccountTrigger__c = true;
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
        
        // Create opportunity
        Opportunity opp = new Opportunity();
        opp.Name = 'Test opp';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
        opp.Coverage_Product_Options__c = 'D&O';
        opp.AccountId = accPersonal.Id;
        opp.Pricebook2Id = Test.getStandardPricebookId();
        opp.Product__c = prd.Id;
        opp.Received_Date__c = Date.today();
        opp.CloseDate = Date.today().addDays(30);
        opp.Effective_Date__c = Date.today().addDays(1);
        opp.Type = 'New Business';
        opp.LeadSource = 'Email';
        opp.StageName = 'Qualified';
        insert opp;
        
        // Qualify Opportunity
        Opportunity opptUpdate = [Select Id, StageName From Opportunity where Id = :opp.Id];
        opptUpdate.StageName = 'Qualified';
        update opptUpdate;
        
        // create policy  
        Policy__c policy = new Policy__c();
        policy.Account__c = accPersonal.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);           
        insert policy;
        
        // Create quote
        Quote newQuote = new Quote(
            OpportunityId = opp.Id,
            Name = 'Test newQuote 1',
            Coverage_Product_Options__c = 'D&O',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert newQuote;
        
        Quote_Option__c quoteOption = new  Quote_Option__c();
        quoteOption.Quote__c=newQuote.Id;
        quoteOption.Selected__c=true;
        insert quoteOption;
        
        
        Referral_Reason__c ref1=new Referral_Reason__c();
        ref1.Approver_Level__c='1';
        ref1.Approval_Level_Required__c='1';
        ref1.Approval_Status__c='';
        ref1.Approval_Rejected_Date__c= date.today()+365;
        ref1.Quote_Option__c= quoteOption.Id;
        ref1.Quote__c=newQuote.id;
        ref1.Reason__c='Test';
        insert ref1; 
        
        //Create Another Quote
        Quote modQuote = new Quote(
            OpportunityId = opp.Id,
            Name = 'Test Mod Qoute',
            Coverage_Product_Options__c = 'D&O',
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'In Progress'
        );
        
        insert modQuote;
        
        Account acc3 = new Account();
        acc3.Name = 'Test account 3';
        acc3.BillingStreet = '106 Nguyen Van Troi';
        acc3.BillingCity = 'Westminster';
        acc3.BillingState = 'Alaska';
        acc3.BillingPostalCode = '90002';
        acc3.BillingCountry = 'United States';
        insert acc3;
        
        //AQ Setup
        
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
        
        Opportunity oppaq = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        oppaq.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        oppaq.AccountId=acc.Id;
        oppaq.StageName = 'Qualified'; 
        oppaq.Innovisk_Entity_ID__c = 'Aqueous';                            
        oppaq.Product__c = product.Id;
        oppaq.Submission_Status__c = 'Quoted';
        oppaq.Transaction_Status__c = 'Active';
        oppaq.Coverage_Product_Options__c = 'Professional Indemnity';
        insert oppaq;
        
        String rdPolicyId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId(); 
        Policy__c policyaq = new Policy__c();
        policyaq.Account__c = acc.Id; 
        policyaq.Expiration_Date__c = Date.today().addDays(100);
        insert policyaq;
        
        //Quote
        Quote quote = TestUtil.createQuote('New Quote Test',oppaq.Id);
        quote.Coverage_Product_Options__c ='Professional Indemnity'; 
        quote.Status = 'Quoted';
        quote.Layer__c = 'Primary';
        quote.OpportunityId = oppaq.Id;
        quote.Policy__c = policyaq.Id;
        quote.Endorsement_Effective_Date__c = date.parse('08/04/2021');
        // quote.Endorsement_Type__c='New Business' - date.parse('08/08/2021');
        insert quote;
        
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
            Opportunity__c = oppaq.Id,
            IsPrimaryBroker__c = true,
            Relationship_Type__c = 'Broker'
        );
        insert broketAccount;
        
        //Create Transaction
        Transactions__c transactions = new Transactions__c();
        transactions.Policy__c=policyaq.Id;
        transactions.Submission__c=oppaq.Id;
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
        rMod.Opportunity__c = oppaq.Id;
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
        
        API_Log__c apiLog = new API_Log__c();
        apiLog.Name = 'Test';
        apiLog.Business_Name__c = 'Celerity';
        apiLog.Status__c = 'Success';
        apilog.Functionality__c = 'Binding';
        insert apilog;
        
        /*  BindQuoteController.PaymentDetails paymentDetailsData = new BindQuoteController.PaymentDetails();
paymentDetailsData.Amount = '1000';
paymentDetailsData.CardHolderName = 'A Z';
paymentDetailsData.PaymentInstrumentType = '';
paymentDetailsData.ProcessorResponseText = '';
paymentDetailsData.TransactionID='';
paymentDetailsData.Timestamp=''; 

BindQuoteController.WritingCompany writingComp = new BindQuoteController.WritingCompany();
writingComp.City ='';
writingComp.Id ='';
writingComp.Name = 'A Z';
writingComp.State = '';
writingComp.Street ='';
writingComp.PostalCode ='';

BindQuoteController.policyInformationCelerity polInfoCel = new BindQuoteController.policyInformationCelerity();
polInfoCel.BillingType = '';
polInfoCel.BindingLicenseNumber= '';
polInfoCel.BindingLicenseOwner= 'A Z';
polInfoCel.BindingLicenseOwnerAddress= '';
polInfoCel.BindingLicenseOwnerName= '';
polInfoCel.BoundDateTime ='';
polInfoCel.IssueDate= '';
polInfoCel.PolicyId= '';
polInfoCel.PriorPolicyNumber = '';
polInfoCel.PolicyNumber= '';

BindQuoteController.IncomingBindResponseCelerity incomingBindResCel = new BindQuoteController.IncomingBindResponseCelerity();
incomingBindResCel.message = '';   
incomingBindResCel.status ='';
//incomingBindResCel.data='';

BindQuoteController.DataCelerity dataCel = new BindQuoteController.DataCelerity();
dataCel.quoteId = '';
dataCel.status = '';

BindQuoteController.policyInformation polInfo = new BindQuoteController.policyInformation();
polInfo.Id = '';
polInfo.BoundDateTime = '';
polInfo.WritingCompany = '';*/
    }
    
    public class BindQuoteControllerMockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBodyJson);
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest 
    static void testCheckSurplusLinesLicense(){
        Test.setMock(HttpCalloutMock.class, new bindQuoteMock());
        BindQuoteController.checkSurplusLinesLicense('');
        
        Account accPersonal = [SELECT Id FROM Account limit 1];
        accPersonal.BillingStateCode = 'AK';
        update accPersonal;
        
        Product2 prd = [SELECT Id FROM Product2 Where Name = 'MPL'][0];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId =: accPersonal.Id
                           AND Product__c =: prd.Id];        
        Quote newQuote = [SELECT Id,OpportunityId,Opportunity.RecordType.Name,Opportunity.Account.RecordType.Name FROM Quote WHERE OpportunityId =: opp.Id][0];
        
        TriggerSettings__c setting = new TriggerSettings__c();
        setting.BypassContactTrigger__c = true;
        insert setting;
        
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert accBroker;
        
        Contact contactBroker = TestUtil.createContact(accBroker.Id, 'Broker_Contact', 'New broker contact');
        insert contactBroker;
        
        Broker_Account__c brokerAcc = TestUtil.createBrokerAccount(contactBroker.Id, newQuote.OpportunityId);
        brokerAcc.IsPrimaryBroker__c = true;
        insert brokerAcc;
        
        Test.startTest();
        BindQuoteController.checkSurplusLinesLicense(newQuote.Id);
        
        Broker_License__c brokerLic = TestUtil.createBrokerLicense(contactBroker, '', '123');
        insert brokerLic;
        
        BindQuoteController.checkSurplusLinesLicense(newQuote.Id);
        
        brokerLic.License_State__c = 'AK';
        update brokerLic;
        
        Subjectivity__c subj = new Subjectivity__c();
        subj.Subjectivity__c = 'Testing';
        subJ.Subjectivity_Status__c = 'Open';
        subJ.Subjectivity_Type__c = 'MPL';
        subJ.Quote__c = newQuote.Id;
        subJ.RecordTypeId = Schema.SObjectType.Subjectivity__c.getRecordTypeInfosByName().get(GlobalVariables.RT_NAME_SUBJECTIVITY_CELERITY).getRecordTypeId();
        insert subJ;
        Rating_Modifiers__c rateMod = TestUtil.createRatingModifier('Cyber Intel Average Score', 'Cyber', opp.Id);
        insert rateMod;
        ResultResponse result = BindQuoteController.checkSurplusLinesLicense(newQuote.Id);
        BindQuoteController.getPreBindDetails(newQuote.Id);
        
        Rating_Modifiers__c rateMod1 = TestUtil.createRatingModifier('Proposal Form Date', 'Cyber', opp.Id);
        insert rateMod1;
        ResultResponse result1 = BindQuoteController.checkSurplusLinesLicense(newQuote.Id);
        BindQuoteController.getPreBindDetails(newQuote.Id);
        
        BindQuoteController.getPreBindDetails(null);
        /* BindQuoteController.ResponseWrapper res= new BindQuoteController.ResponseWrapper();
res.status='Success';
res.message='Success';
res.data='Success';

BindQuoteController.Data data= new BindQuoteController.Data();
data.status='Success';
data.quoteId=newQuote.Id;

BindQuoteController.IncomingBindResponseAQ req= new BindQuoteController.IncomingBindResponseAQ();
req.status='Success';
req.message='Success';*/
        
        Test.stopTest();
        
        System.assertEquals(true, result.isSuccess);
    }
    
    @isTest
    static void testCheckBoundPendingFromCallOutApi() {
        Test.startTest();
        Account accPersonal = [SELECT Id FROM Account limit 1];
        Product2 prd = [SELECT Id FROM Product2 Where Name = 'MPL'][0];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId =: accPersonal.Id
                           AND Product__c =: prd.Id];        
        Quote newQuote = [SELECT Id,OpportunityId,Opportunity.RecordType.Name,Opportunity.Account.RecordType.Name FROM Quote WHERE OpportunityId =: opp.Id][0];
        
        TriggerSettings__c setting = new TriggerSettings__c();
        setting.BypassContactTrigger__c = true;
        insert setting;
        
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert accBroker;
        
        Contact contactBroker = TestUtil.createContact(accBroker.Id, 'Broker_Contact', 'New broker contact');
        insert contactBroker;
        
        Broker_Account__c brokerAcc = TestUtil.createBrokerAccount(contactBroker.Id, newQuote.OpportunityId);
        brokerAcc.IsPrimaryBroker__c = true;
        insert brokerAcc;  
        
        //  Boolean checkBoundPending = BindQuoteController.checkBoundPendingFromCallOutApi(newQuote);
        Test.stopTest();
        
        //  System.assertEquals(false, checkBoundPending);
    }
    
    @isTest
    static void testBindQuoteFromAPI() {
        Exception expectedException;
        try{
            System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock()); 
            MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
            mock.body = '{"isValidOFAC":"True"}';
            mock.statusCode = 200;
            
            
            Test.setMock(HttpCalloutMock.class, mock);
            
            Account acc3 = [SELECT Id FROM Account limit 1];
            
            Product2 prd = [SELECT Id FROM Product2 Where Name = 'Private Company Combo'][0];
            Opportunity opp = [SELECT Id,RecordType.Name FROM Opportunity WHERE AccountId =: acc3.Id
                               AND Product__c =: prd.Id];
            opp.RecordType.Name = 'Celerity';
            update opp;    
            system.debug('==Opportunity==' + opp);
            
            Quote newQuote = [SELECT Id FROM Quote WHERE OpportunityId =: opp.Id];
            
            List<Quote> lstQuote = [SELECT Id,Azure_ID__c FROM Quote WHERE Id = :newQuote.Id];      
            
            // Create broker
            Broker_Account__c broker = [SELECT Id,Name FROM Broker_Account__c LIMIT 1];
            Additional_Interests__c addInt = new Additional_Interests__c(
                Additional_Interest_Account__c = acc3.Id,
                Quote__c = newQuote.Id,
                Relationship_Type__c = 'Additional Insured'
            );
            insert addInt;
            Test.startTest();
            
            //  BindQuoteController.checkBoundPendingFromCallOutApi(newQuote);
            Test.stopTest();
        } catch(Exception e){
            expectedException = e;
        }
        System.assertNotEquals(null, expectedException);
    }
    
    @isTest
    static void testGetInitData1() {
        Test.setMock(HttpCalloutMock.class, new bindQuoteMock());
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock()); 
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        mock.body = '{"isValidOFAC":"True"}';
        mock.statusCode = 200;
        responseBodyJson = '{"status":"Success","message":"Quote bound successfully.","data":{"quoteId":"34e5fb38-0e90-41c1-867a-e79e56d9bf02","status":"Bound","policyInformation":{"PolicyNumber":"5DA3FF0000683-00","PriorPolicyNumber":"","PolicyId":"4cab516e-c3ba-4500-b7bf-d40c8c51fb9b","BoundDateTime":"2022-09-06 13:14:13","IssueDate":"2022-09-06","BindingLicenseNumber":"dsdsds","BindingLicenseOwner":"Agency","BindingLicenseOwnerAddress":"102,Richard Have,Hoston TX 77082,USA","BindingLicenseOwnerName":"122121","PaymentDetails":{"TransactionID":"123","CardHolderName":"Test","ProcessorResponseText":"Test","Timestamp":"","Amount":"200","PaymentInstrumentType":"Test"},"BillingType":"","Documents":[{"Id":"","Type":"CelerityExcessQuote","GeneratedDate":""},{"Id":"29ea0b2b-4f68-420b-9dab-88a0c501a80a","Type":"PolicySchedulePrimary","GeneratedDate":"2021-03-31"}]}}}';
            
            //' {"status":"Success","message":"Quote bound successfully.","data":{"quoteId":"be6fd66a-04e3-47e6-bd18-d1fd646f2463","status":"Bound","policyInformation":{"PolicyNumber":"5DA3FF0000683-00","PriorPolicyNumber":"","PolicyId":"4cab516e-c3ba-4500-b7bf-d40c8c51fb9b","BoundDateTime":"2022-09-06 13:14:13","IssueDate":"2022-09-06","BindingLicenseNumber":"dsdsds","BindingLicenseOwner":"Agency","BindingLicenseOwnerAddress":"102,Richard Have,Hoston TX 77082,USA","BindingLicenseOwnerName":12212"","PaymentDetails":{"TransactionID":"","CardHolderName":"","ProcessorResponseText":"","Timestamp":"","Amount":"","PaymentInstrumentType":""},"BillingType":"","Documents":[{"Id":"","Type":"","GeneratedDate":""},{"Id":"a69d9f5f-4171-44af-8f57-c0a4fc2835e8","Type":"PolicySchedulePrimary","GeneratedDate":"2021-04-06"}],"WritingCompany":null}}}  ';
        
        Test.setMock(HttpCalloutMock.class, mock);
       
        Account accPersonal = [SELECT Id FROM Account limit 1];
        
        Product2 prd = [SELECT Id FROM Product2 Where Name = 'MPL'][0];
        prd.Pay_Plan__c = 'ACH';
        update prd;
        Policy__c pol2 = new Policy__c();
        pol2.Policy_Number__c = '123456';
        pol2.Effective_Date__c = Date.today()+5;
        pol2.Expiration_Date__c = Date.today() + 30;
        pol2.Policy_Status__c = 'Bound';
        insert pol2;
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId =: accPersonal.Id
                           AND Product__c =: prd.Id];
        
        //Create Transaction
        Transactions__c transactions = new Transactions__c();
        transactions.Policy__c=pol2.Id;
        transactions.Submission__c=opp.Id;
        insert transactions;
        
        
         Test.startTest();
        Quote newQuote = [SELECT Id,Azure_Id__c,Product_Name__c FROM Quote WHERE OpportunityId =: opp.Id][0];
        
        
        BindQuoteController.getInitData(newQuote.Id);
        BindQuoteController.bindQuoteAqueous(newQuote.Id, 'payPlan', true,'Primary');
        BindQuoteController.bindQuoteCelerity(newQuote.Id, 'payPlan', true);
        //BindQuoteController.bindQuoteWithBLInfo(newQuote.Id, 'payPlan', false,responseBodyJson);
        BindServiceHandler_CEL.bindQuoteCelerity(newQuote.Id, 'payPlan', true,true);
        BindServiceHandler_CEL.bindQuoteCelerity(null, 'payPlan', true,true);
        Test.stopTest();
        
        // System.assertEquals(true, initObj != null);
    }
    
    
    
    @isTest
    static void testGetInitData2() {
        
        responseBodyJson = '{"status":"Success","message":"Quote bound successfully.","data":{"quoteId":"34e5fb38-0e90-41c1-867a-e79e56d9bf02","status":"Bound","policyInformation":{"PolicyNumber":"P211PZ0000022","Id":"021023651478596","WritingCompany":null,"PriorPolicyNumber":"","PolicyId":"d7c17d36-6690-418b-ac09-42e646d82ba9","BoundDateTime":"2021-03-31","PaymentDetails":{"TransactionID":"","CardHolderName":"","ProcessorResponseText":"","Timestamp":"","Amount":"","PaymentInstrumentType":""},"BillingType":"","Documents":[{"Id":"","Type":"QuoteProposal","GeneratedDate":""},{"Id":"29ea0b2b-4f68-420b-9dab-88a0c501a80a","Type":"PolicyForm","GeneratedDate":"2021-03-31"}]}}}';
        /*BindQuoteControllerMockResponse mock = new BindQuoteControllerMockResponse();
Test.setMock(HttpCalloutMock.class, mock);*/
        Test.setMock(HttpCalloutMock.class, new bindQuoteMock());
        Test.startTest();
        
        Account accPersonal = [SELECT Id FROM Account limit 1];
        
        Product2 prd = [SELECT Id FROM Product2 Where Name = 'MPL'][0];
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId =: accPersonal.Id
                           AND Product__c =: prd.Id];
        
        
        Quote newQuote = [SELECT Id,Policy__c FROM Quote WHERE OpportunityId =: opp.Id][0];
        
        
        // START Added by RINKU SAINI 12th Jan 2022
        BindServiceHandler_AQ.IncomingBindResponseAQ bindResponse = (BindServiceHandler_AQ.IncomingBindResponseAQ) JSON.deserialize(responseBodyJson, BindServiceHandler_AQ.IncomingBindResponseAQ.class);
        bindResponse.status = 'Success';
        bindResponse.message = 'Quote bound successfully.';
        bindResponse.Data.quoteId = '';
        bindResponse.Data.status = '';
        bindResponse.Data.policyInformation.Id = '';
        bindResponse.Data.policyInformation.BoundDateTime = '';
        bindResponse.Data.policyInformation.WritingCompany = '';
        BindServiceHandler_AQ.WritingCompany obj = new BindServiceHandler_AQ.WritingCompany();
        obj.Id = '';
        obj.Name = '';
        obj.Street = '';
        obj.City = '';
        obj.PostalCode = '';
        obj.State = '';
        BindServiceHandler_AQ.Documents obj1 = new BindServiceHandler_AQ.Documents();
        obj1.GeneratedDate = '';
        // END Added by RINKU SAINI 12th Jan 2022
        
        BindQuoteController.bindQuoteAqueous(newQuote.Id, 'payPlan', false,'test');
        BindServiceHandler_AQ.bindQuoteAqueous(newQuote.Id, 'payPlan',false, '',false);
        Test.stopTest();
        // System.assertEquals(true, initObj != null);
    }
    
    // Added by RINKU SAINI 12th Jan 2022
    @isTest
    static void testGetInitData2NegativeTest() {
        
        Test.setMock(HttpCalloutMock.class, new bindQuoteMockNeagtiveTest());
        Test.startTest();
        Account accPersonal = [SELECT Id FROM Account limit 1];
        Product2 prd = [SELECT Id FROM Product2 Where Name = 'MPL'][0];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId =: accPersonal.Id AND Product__c =: prd.Id];
        Quote newQuote = [SELECT Id,Policy__c FROM Quote WHERE OpportunityId =: opp.Id][0]; 
        
        BindServiceHandler_Common.ResponseWrapper errorResponse = New BindServiceHandler_Common.ResponseWrapper();
        errorResponse.message = 'PreConditionNotMet';
        
        BindQuoteController.bindQuoteAqueous(newQuote.Id, 'payPlan', false,'test');
        BindServiceHandler_AQ.bindQuoteAqueous(newQuote.Id, 'payPlan',false, '',false);
        Test.stopTest();
        // System.assertEquals(true, initObj != null);
    }
    
    
    
    @isTest
    static void testGetInitDataAQ() {
        
        responseBodyJson = '{"status":"Success","message":"Quote bound successfully.","data":{"quoteId":"34e5fb38-0e90-41c1-867a-e79e56d9bf02","status":"Bound","policyInformation":{"PolicyNumber":"P211PZ0000022","Id":null,"WritingCompany":null,"PriorPolicyNumber":"","PolicyId":"d7c17d36-6690-418b-ac09-42e646d82ba9","BoundDateTime":"2021-03-31","PaymentDetails":{"TransactionID":"","CardHolderName":"","ProcessorResponseText":"","Timestamp":"","Amount":"","PaymentInstrumentType":""},"BillingType":"","Documents":[{"Id":"","Type":"","GeneratedDate":""},{"Id":"29ea0b2b-4f68-420b-9dab-88a0c501a80a","Type":"PolicySchedulePrimary","GeneratedDate":"2021-03-31"}]}}}';
        /*BindQuoteControllerMockResponse mock = new BindQuoteControllerMockResponse();
Test.setMock(HttpCalloutMock.class, mock);*/
        Test.setMock(HttpCalloutMock.class, new bindQuoteMock());
        
       
        BindServiceHandler_CEL.IncomingBindResponseCelerity bindResponse = (BindServiceHandler_CEL.IncomingBindResponseCelerity) JSON.deserialize(responseBodyJson, BindServiceHandler_CEL.IncomingBindResponseCelerity.class);
        Account acc = [SELECT Id FROM Account Where Name='Bussiness Accoun Aq' limit 1];
        
        Product2 prd = [SELECT Id FROM Product2 Where Name = 'Professional Indemnity'][0];
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId =: acc.Id
                           AND Product__c =: prd.Id];
        
        Quote newQuote = [SELECT Id,Policy__c FROM Quote WHERE OpportunityId =: opp.Id][0];
        
        Opportunity oppaq = TestUtil.createOpportunity('Opp Test',acc.Id, prd.Id);
        oppaq.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        oppaq.AccountId=acc.Id;
        oppaq.StageName = 'Qualified'; 
        oppaq.Innovisk_Entity_ID__c = 'Aqueous';                            
        oppaq.Product__c = prd.Id;
        oppaq.Submission_Status__c = 'Quoted';
        oppaq.Transaction_Status__c = 'Active';
        oppaq.Coverage_Product_Options__c = 'Professional Indemnity';
        insert oppaq;
        
        opp.Parent_Opportunity__c = oppaq.Id;
        update opp;
        
        //Create Transaction
        Transactions__c transactions = new Transactions__c();
        transactions.Policy__c=newQuote.Policy__c;
        transactions.Submission__c=oppaq.Id;
        insert transactions;
        
         Test.startTest();
        //  BindQuoteController.InitObject initObj = BindQuoteController.getInitData(newQuote.Id);
        BindQuoteController.bindQuoteAqueous(newQuote.Id, 'payPlan', false,'');
        BindQuoteController.bindQuoteQC(newQuote.Id, 'payPlan', false,'','');
        BindQuoteController.bindQuote(newQuote.Id, 'Test', false);
        BindQuoteController.bindQuoteFromEndorsement(newQuote.Id,Date.today(),'');
        newQuote.Status = 'Referred';
        update newQuote;
        ResultResponse result = BindQuoteController.bindQuote(newQuote.Id, 'Test', false);
        
        Test.stopTest();
        
        //  System.assertEquals(true, initObj != null);
    }
    
    @isTest
    static void testGetInitDataAQ2() {
        
        responseBodyJson = '{"status":"Success","message":"Quote bound successfully.","data":{"quoteId":"34e5fb38-0e90-41c1-867a-e79e56d9bf02","status":"Bound","policyInformation":{"PolicyNumber":"P211PZ0000022","Id":null,"WritingCompany":null,"PriorPolicyNumber":"","PolicyId":"d7c17d36-6690-418b-ac09-42e646d82ba9","BoundDateTime":"2021-03-31","PaymentDetails":{"TransactionID":"","CardHolderName":"","ProcessorResponseText":"","Timestamp":"","Amount":"","PaymentInstrumentType":""},"BillingType":"","Documents":[{"Id":"","Type":"","GeneratedDate":""},{"Id":"29ea0b2b-4f68-420b-9dab-88a0c501a80a","Type":"PolicySchedulePrimary","GeneratedDate":"2021-03-31"}]}}}';
        BindQuoteControllerMockResponse mock = new BindQuoteControllerMockResponse();
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        Account acc = [SELECT Id FROM Account Where Name='Bussiness Accoun Aq' limit 1];
        
        Product2 prd = [SELECT Id FROM Product2 Where Name = 'Professional Indemnity'][0];
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId =: acc.Id
                           AND Product__c =: prd.Id];
        
        Quote newQuote = [SELECT Id FROM Quote WHERE OpportunityId =: opp.Id][0];
        
        //  BindQuoteController.InitObject initObj = BindQuoteController.getInitData(newQuote.Id);
        BindQuoteController.bindQuoteAqueous(newQuote.Id, 'payPlan', false,'');
        BindQuoteController.bindQuoteQC(newQuote.Id, 'payPlan', false,'','');
        newQuote.Status = 'Referred';
        update newQuote;
        ResultResponse result = BindQuoteController.bindQuote(newQuote.Id, 'Test', false);
        
        Test.stopTest();
        //  System.assertEquals(true, initObj != null);
    }
    
    @isTest
    static void testInComingRequestOFAC(){
        Account acct = new Account();
        Contact cont = new Contact();
        test.startTest();
        //  BindQuoteController.InComingRequestOFAC inCommingOFAC = new BindQuoteController.InComingRequestOFAC();
        test.stopTest();
        //   System.Assert(inCommingOFAC !=null);
    }
    
    @isTest
    static void testInComingRequestOFAC01(){
        Test.startTest();
        // BindQuoteController.InComingRequestOFAC inCommingOFAC1 = new BindQuoteController.InComingRequestOFAC();
        Account accPersonal = [SELECT Id FROM Account limit 1];
        Contact cont = new Contact();
        cont.MailingStreet = 'MailingStreet';
        cont.MailingCity = 'MailingCity';
        cont.MailingState = 'MailingState';
        cont.MailingPostalCode = 'MailingPostalCode';
        cont.MailingCountryCode = 'MailingCountryCode';
        cont.Mailing_County__c = 'Mailing_County__c';
        cont.AccountId = accPersonal.Id;
        Test.stopTest();
        System.assert(accPersonal!=null);
    }
    @isTest
    static void testBindQuote(){                   
        TriggerSettings__c setting = new TriggerSettings__c();
        setting.BypassContactTrigger__c = true;
        insert setting;
        Quote newQuote = [SELECT Id,OpportunityId FROM Quote WHERE Name='Test newQuote 1'];
        
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert accBroker;               
        
        Contact contactBroker = TestUtil.createContact(accBroker.Id, 'Broker_Contact', 'New broker contact');
        insert contactBroker;
        
        Broker_Account__c brokerAcc = TestUtil.createBrokerAccount(contactBroker.Id, newQuote.OpportunityId);
        brokerAcc.IsPrimaryBroker__c = true;
        insert brokerAcc;               
        
        Broker_License__c brokerLicence = new Broker_License__c();
        brokerLicence.Broker__c = contactBroker.Id;
        brokerLicence.License_State__c = 'CA';
        insert brokerLicence;
        
        Location__c loc = TestUtil.createNewLocation('234, 1st Avenuet','New York', 'United States', '10593', 'California');
        loc.State_Code__c  = 'LA';
        insert loc;                            
        
        Quote_Location__c ql = TestUtil.createQuoteLocation(newQuote.Id,loc.Id,true);   
        insert ql;
        
        Invsk_Callout.AgencyLookup callAgen = new Invsk_Callout.AgencyLookup('651106324');
        Map<String,Invsk_Callout.AgencyLookup> mapAgency = new Map<String,Invsk_Callout.AgencyLookup>();
        mapAgency.put('agencyLookup',callAgen);
        mapAgency.put('Quotes',callAgen);
        String jsonString = JSON.serialize(mapAgency);
        
        Test.startTest();
        WebServiceNIPRTestMockImpl mock = new WebServiceNIPRTestMockImpl();
        mock.body = jsonString;
        Test.setMock(HttpCalloutMock.class, mock);
        ResultResponse result = BindQuoteController.bindQuote(newQuote.Id, 'Test', false);
        Test.stopTest();
        
        //System.assertEquals(true, result.isSuccess);
    }
    
    @isTest
    static void testBindQuoteIncomingCelerity() {
        
        responseBodyJson = '{"status":"Success","message":"Quote bound successfully.","data":{"quoteId":"34e5fb38-0e90-41c1-867a-e79e56d9bf02","status":"Bound","policyInformation":{"PolicyNumber":"P211PZ0000022","Id":null,"WritingCompany":null,"PriorPolicyNumber":"","PolicyId":"d7c17d36-6690-418b-ac09-42e646d82ba9","BoundDateTime":"2021-03-31","PaymentDetails":{"TransactionID":"","CardHolderName":"","ProcessorResponseText":"","Timestamp":"","Amount":"","PaymentInstrumentType":""},"BillingType":"","Documents":[{"Id":"","Type":"","GeneratedDate":""},{"Id":"29ea0b2b-4f68-420b-9dab-88a0c501a80a","Type":"PolicySchedulePrimary","GeneratedDate":"2021-03-31"}]}}}';
        BindQuoteControllerMockResponse mock = new BindQuoteControllerMockResponse();
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        Account accPersonal = [SELECT Id FROM Account limit 1];
        
        Product2 prd = [SELECT Id FROM Product2 Where Name = 'MPL'][0];
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId =: accPersonal.Id
                           AND Product__c =: prd.Id];
        
        Quote newQuote = [SELECT Id FROM Quote WHERE OpportunityId =: opp.Id][0];
        // START Added by RINKU SAINI 12th Jan 2022
        BindServiceHandler_CEL.IncomingBindResponseCelerity bindResponse = (BindServiceHandler_CEL.IncomingBindResponseCelerity) JSON.deserialize(responseBodyJson, BindServiceHandler_CEL.IncomingBindResponseCelerity.class);
        bindResponse.status = 'Success';
        bindResponse.message = 'Quote bound successfully.';
        bindResponse.Data.quoteId = '';
        bindResponse.Data.status = '';
        bindResponse.Data.policyInformation.PolicyNumber = '';
        bindResponse.Data.policyInformation.PriorPolicyNumber = '';
        bindResponse.Data.policyInformation.PolicyId = '';
        bindResponse.Data.policyInformation.BoundDateTime = '';
        bindResponse.Data.policyInformation.IssueDate = '';
        bindResponse.Data.policyInformation.BindingLicenseNumber = 'dsdsda';
        bindResponse.Data.policyInformation.BindingLicenseOwner = '12345';
        bindResponse.Data.policyInformation.BindingLicenseOwnerAddress = 'Pooja New Company, G-24, GOKULDAM SHOPPING CENTRE,, Mumbai,';
        bindResponse.Data.policyInformation.BindingLicenseOwnerName = 'test1334';
        bindResponse.Data.policyInformation.BillingType = 'Agency';
        bindResponse.Data.policyInformation.IsSignaturePackUploaded = true;	
        
        BindServiceHandler_CEL.PaymentDetails obj2 = new BindServiceHandler_CEL.PaymentDetails();
        obj2.TransactionID = '';
        obj2.CardHolderName = '';
        obj2.ProcessorResponseText = '';
        obj2.Timestamp = '';
        obj2.Amount = '';
        obj2.PaymentInstrumentType = '';
        bindResponse.Data.policyInformation.PaymentDetails = obj2;
        
        BindServiceHandler_CEL.WritingCompany obj = new BindServiceHandler_CEL.WritingCompany();
        obj.Id = '';
        obj.Name = '';
        obj.Street = '';
        obj.City = '';
        obj.PostalCode = '';
        obj.State = '';
        BindServiceHandler_CEL.Documents obj3 = new BindServiceHandler_CEL.Documents();
        obj3.GeneratedDate = '';
        bindResponse.Data.policyInformation.WritingCompany = obj;
        
        
        BindServiceHandler_AQ.Documents obj1 = new BindServiceHandler_AQ.Documents();
        obj1.GeneratedDate = '';
        // END Added by RINKU SAINI 12th Jan 2022       
        
        // BindQuoteController.InitObject initObj = BindQuoteController.getInitData(newQuote.Id);
        BindQuoteController.bindQuoteIncoming(newQuote.Id, 'payPlan', false);
        //BindQuoteController.bindQuoteQC(newQuote.Id, 'payPlan', false,'');
        //vivek
        
        Test.stopTest();
        
        //System.assertEquals(true, initObj != null);
    }
    
    @isTest
    static void testBindQuoteWithinfo() {
        responseBodyJson = '{"status":"Success","message":"Quote bound successfully.","data":{"quoteId":"34e5fb38-0e90-41c1-867a-e79e56d9bf02","status":"Bound","policyInformation":{"PolicyNumber":"P211PZ0000022","Id":null,"WritingCompany":null,"PriorPolicyNumber":"","PolicyId":"d7c17d36-6690-418b-ac09-42e646d82ba9","BoundDateTime":"2021-03-31","PaymentDetails":{"TransactionID":"","CardHolderName":"","ProcessorResponseText":"","Timestamp":"","Amount":"","PaymentInstrumentType":""},"BillingType":"","bindingLicenseOwnerName":"Oooo","bindingLicenseOwner":"Producer","bindingLicenseOwnerAddress":"4375 N Perris Blvd, Perris, CA 92571, USA","bindingLicenseNumber":"8237832","Documents":[{"Id":"","Type":"Binder","GeneratedDate":""},{"Id":"29ea0b2b-4f68-420b-9dab-88a0c501a80a","Type":"SOA","GeneratedDate":"2021-03-31"}]}}}';
        BindQuoteControllerMockResponse mock = new BindQuoteControllerMockResponse();
        Test.setMock(HttpCalloutMock.class, mock);
                
        Account accPersonal = [SELECT Id FROM Account limit 1];
        
        Product2 prd = [SELECT Id FROM Product2 Where Name = 'MPL'][0];
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId =: accPersonal.Id
                           AND Product__c =: prd.Id];
        
        Quote newQuote = [SELECT Id FROM Quote WHERE OpportunityId =: opp.Id][0];
        
        Test.startTest();
        // BindQuoteController.InitObject initObj = BindQuoteController.getInitData(newQuote.Id);
        //BindQuoteController.bindQuote(newQuote.Id, 'payPlan', false); 
        //BindQuoteController.bindQuoteQC(newQuote.Id, 'payPlan', false,'');
        //BindQuoteController.bindQuoteWithBLInfo(newQuote.Id, 'payPlan', false, '{"oppRecordType": "Celerity","productName":"Cyber Standalone":"Agency","id":"a082500000IxAI5AAN","blOwnerName":"Test User","blNo":"1407112","liceseState":"TX","NPNStatus":"Pass","blOwnerAddress":"Test User, 15687 Thistle Court, New York, New York, 40000","bindingLicenseOwnerName":"Oooo","bindingLicenseOwner":"Producer","bindingLicenseOwnerAddress":"4375 N Perris Blvd, Perris, CA 92571, USA","bindingLicenseNumber":"8237832"}');
        BindQuoteController.bindQuoteWithBLInfo(newQuote.Id, 'payPlan', false,responseBodyJson);
        Test.stopTest();
    }
    @isTest
    static void testBindQuoteCelerity() {
        
        responseBodyJson = '{"status":"Success","message":"Quote bound successfully.","data":{"quoteId":"34e5fb38-0e90-41c1-867a-e79e56d9bf02","status":"Bound","policyInformation":{"PolicyNumber":"5DA3FF0000683-00","PriorPolicyNumber":"","PolicyId":"4cab516e-c3ba-4500-b7bf-d40c8c51fb9b","BoundDateTime":"2022-09-06 13:14:13","IssueDate":"2022-09-06","BindingLicenseNumber":"dsdsds","BindingLicenseOwner":"Agency","BindingLicenseOwnerAddress":"102,Richard Have,Hoston TX 77082,USA","BindingLicenseOwnerName":12212"","PaymentDetails":{"TransactionID":"","CardHolderName":"","ProcessorResponseText":"","Timestamp":"","Amount":"","PaymentInstrumentType":""},"BillingType":"","Documents":[{"Id":"","Type":"","GeneratedDate":""},{"Id":"29ea0b2b-4f68-420b-9dab-88a0c501a80a","Type":"PolicySchedulePrimary","GeneratedDate":"2021-03-31"}]}}}';
        BindQuoteControllerMockResponse mock = new BindQuoteControllerMockResponse();
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        Account accPersonal = [SELECT Id FROM Account limit 1];
        
        Product2 prd = [SELECT Id FROM Product2 Where Name = 'MPL'][0];
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId =: accPersonal.Id
                           AND Product__c =: prd.Id];
        
        Quote newQuote = [SELECT Id FROM Quote WHERE OpportunityId =: opp.Id][0];
        
        // BindQuoteController.InitObject initObj = BindQuoteController.getInitData(newQuote.Id);
        BindQuoteController.bindQuote(newQuote.Id, 'payPlan', false);
        BindQuoteController.bindQuoteQC(newQuote.Id, 'payPlan', false,'',responseBodyJson);
        Test.stopTest();
        
        // System.assertEquals(true, initObj != null);
    }
    
    @isTest
    static void testBindQuoteCelerityCancellation() {
        
        responseBodyJson = '{"status":"Success","message":"Quote bound successfully.","data":{"quoteId":"34e5fb38-0e90-41c1-867a-e79e56d9bf02","status":"Bound","policyInformation":{"PolicyNumber":"P211PZ0000022","Id":null,"WritingCompany":null,"PriorPolicyNumber":"","PolicyId":"d7c17d36-6690-418b-ac09-42e646d82ba9","BoundDateTime":"2021-03-31","PaymentDetails":{"TransactionID":"","CardHolderName":"","ProcessorResponseText":"","Timestamp":"","Amount":"","PaymentInstrumentType":""},"BillingType":"","Documents":[{"Id":"","Type":"","GeneratedDate":""},{"Id":"29ea0b2b-4f68-420b-9dab-88a0c501a80a","Type":"PolicySchedulePrimary","GeneratedDate":"2021-03-31"}]}}}';
        BindQuoteControllerMockResponse mock = new BindQuoteControllerMockResponse();
        Test.setMock(HttpCalloutMock.class, mock);
        
        Account accPersonal = [SELECT Id FROM Account limit 1];
        
        Product2 prd = [SELECT Id FROM Product2 Where Name = 'MPL'][0];
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId =: accPersonal.Id
                           AND Product__c =: prd.Id];
        
        Quote newQuote = [SELECT Id FROM Quote WHERE OpportunityId =: opp.Id][0];
        newQuote.Quote_Type__c = 'Midterm Cancellation';
        update newQuote;
        
        Test.startTest(); 
        
        //  BindQuoteController.InitObject initObj = BindQuoteController.getInitData(newQuote.Id);
        BindQuoteController.bindQuote(newQuote.Id, 'payPlan', false);
        //BindQuoteController.bindQuoteQC(newQuote.Id, 'payPlan', false,'');
        
        Test.stopTest();
        
        // System.assertEquals(true, initObj != null);
    }
    
    @isTest
    static void testBindQuoteExcep(){
        TriggerSettings__c setting = new TriggerSettings__c();
        setting.BypassContactTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        insert setting;
        
        Quote newQuote = [SELECT Id,OpportunityId,Policy__c FROM Quote WHERE Name='Test newQuote 1'];
        
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert accBroker;               
        
        Contact contactBroker = TestUtil.createContact(accBroker.Id, 'Broker_Contact', 'New broker contact');
        insert contactBroker;
        
        Broker_Account__c brokerAcc = TestUtil.createBrokerAccount(contactBroker.Id, newQuote.OpportunityId);
        brokerAcc.IsPrimaryBroker__c = true;
        insert brokerAcc;               
        
        Broker_License__c brokerLicence = new Broker_License__c();
        brokerLicence.Broker__c = contactBroker.Id;
        brokerLicence.License_State__c = 'CA';
        insert brokerLicence;
        
        Location__c loc = TestUtil.createNewLocation('234, 1st Avenuet','New York', 'United States', '10593', 'California');
        loc.State_Code__c  = 'LA';
        insert loc;                            
        
        Quote_Location__c ql = TestUtil.createQuoteLocation(newQuote.Id,loc.Id,true);   
        insert ql;
        
        
        BindQuoteController.bindQuote('', 'Test', false);
        
        Policy__c policy = [SELECT id,Name FROM Policy__c LIMIT 1];
        newQuote.Policy__c =  policy.Id;
        update newQuote;
        Test.startTest();
        ResultResponse result = BindQuoteController.bindQuote(newQuote.Id, 'TestPolicy', false);
        test.stopTest();
        System.assert(newQuote.Policy__c == policy.Id);
    }
    
    @isTest
    public static void testBindQuoteForEndorsement() {
        TriggerSettings__c setting = new TriggerSettings__c();
        setting.BypassQuoteTrigger__c = true;
        setting.BypassPolicyTrigger__c = true;
        insert setting;
        
        Quote newQuote = [SELECT Id,OpportunityId FROM Quote WHERE Name='Test newQuote 1'];
        
        Policy__c policy = [SELECT id,Name FROM Policy__c LIMIT 1];
        newQuote.Policy__c =  policy.Id;
        newQuote.Quote_Type__c = 'Extension';
        update newQuote;
        
        Test.startTest();
        
        BindQuoteController.bindQuoteForEndorsement(newQuote.Id,Date.today().addMonths(2),'Non-Payment');
        
        newQuote.Quote_Type__c = 'Midterm Cancellation';
        update newQuote;
        BindQuoteController.bindQuoteForEndorsement(newQuote.Id,Date.today().addMonths(3),'Underwriting Reasons');
        
        newQuote.Quote_Type__c = 'Flat Cancellation';
        update newQuote;
        BindQuoteController.bindQuoteForEndorsement(newQuote.Id,Date.today().addMonths(4),'Insured Request');
        
        /*newQuote.Quote_Type__c = 'Flat Cancellation (Ab - Initio)';
update newQuote;
BindQuoteController.bindQuoteForEndorsement(newQuote.Id,Date.today().addMonths(4),'Insured Request');*/
        
        newQuote.Quote_Type__c = 'Reinstatement';
        update newQuote;
        
        
        policy.Policy_Status__c = 'Cancelled';
        update policy;
        String msgError = BindQuoteController.bindQuoteForEndorsement(newQuote.Id,Date.today().addMonths(4),'Insured Request');
        
        Test.stopTest();
        
        System.assertEquals('', msgError);
    }
    @isTest
    public static void testBindQuoteForEndorsement2() {
        String msgError = BindQuoteController.bindQuoteForEndorsement('',Date.today().addMonths(2),'');
        BindQuoteController.bindQuoteQC('','payPlan', true,'Primary','');
        System.assert(msgError != null);
    }
    
    
    public class WebServiceNIPRTestMockImpl implements HttpCalloutMock {
        public String body          {get; set;}
        public Integer statusCode   {get; set;} 
        public HTTPResponse respond(HTTPRequest req) {
            
            /*HttpResponse res = new HttpResponse();
res.setHeader('Content-Type', 'application/json');
res.setBody(body);
res.setStatusCode(200);
return res;*/
            HttpResponse res = new HttpResponse();
            Map<String, Object> reqMap = (Map<String, Object>) JSON.deserializeUntyped(body);
            if(reqMap.containsKey('agencyLookup')) { 
                Map<String, Object>  feinMap = (Map<String, Object>) reqMap.get('agencyLookup');
                if(feinMap.containsKey('fein')) {
                    String fein = String.valueOf(feinMap.get('fein'));
                    System.debug('BBBBBBBBBBB ' + fein);
                    switch on fein {
                        when '651106324' {
                            String resBody = '{"isValidAgencyFEIN": true,"npn": "8904483","isStop":false}';
                            //res = createResponse(200, resBody);
                            
                            res.setHeader('Content-Type', 'application/json');
                            res.setStatusCode(200);
                            res.setBody(resBody);
                        }
                        when '' {
                            String resBody = '{"Message": "400 - there is no input data for NIPR to call "}';
                            //res = createResponse(400, resBody);
                            res.setHeader('Content-Type', 'application/json');
                            res.setStatusCode(400);
                            res.setBody(resBody);
                        }
                        when else {
                            String resBody = '{"error": {"code": "NoResponse","message": "Server is unavailable" }}';
                            //res = createResponse(415, resBody);
                            res.setHeader('Content-Type', 'application/json');
                            res.setStatusCode(415);
                            res.setBody(resBody);
                        }
                    }
                }
                
            }
            
            
            return res;    
        }
    }
    
    @isTest
    static void testfetchMReAppointmentDetails(){
        
        Id recordTypeAccBroker = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Account accBroker = new Account(
            Name='Account_Broker_Test_01', 
            RecordTypeId = recordTypeAccBroker, 
            BillingStreet = '5305, Monroe Street',
            BillingCity = 'Toledo', 
            BillingState = 'Ohio',
            BillingPostalCode = '43623', 
            BillingCountry = 'United States',
            MRe_Admittance__c = 'Not Started',
            FEIN__c = 12345
        );
        insert accBroker;
        
        Id recordTypeConBroker = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Contact contactBroker1 = new Contact(
            FirstName = 'Test',
            LastName = 'Broker_Contact_1',
            RecordTypeId =recordTypeConBroker ,
            Azure_Id__c = '1234',
            Email = 'test1@broker.com',
            AccountId = accBroker.Id
        );
        insert contactBroker1;
        
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
        
        // Create opportunity
        Opportunity opp = new Opportunity();
        opp.Name = 'Test opp';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
        opp.Coverage_Product_Options__c = 'D&O';
        opp.AccountId = accPersonal.Id;
        opp.Pricebook2Id = Test.getStandardPricebookId();
        opp.Product__c = prd.Id;
        opp.Received_Date__c = Date.today();
        opp.CloseDate = Date.today().addDays(30);
        opp.Effective_Date__c = Date.today().addDays(1);
        opp.Type = 'New Business';
        opp.LeadSource = 'Email';
        opp.StageName = 'Qualified';
        insert opp;
        
        // Create broker
        Broker_Account__c broketAccount = new Broker_Account__c(
            Broker_Contact__c = contactBroker1.Id,
            Opportunity__c = opp.Id,
            IsPrimaryBroker__c = true,
            Relationship_Type__c = 'Broker'
        );
        insert broketAccount;
        
        Id recordTypeBrokerLicence = [SELECT Id FROM RecordType WHERE DeveloperName = 'MRe_Appointment' AND sObjectType = 'Broker_License__c'].Id;
        //Id recordTypeBrokerLicence = Schema.SObjectType.Broker_License__c.getRecordTypeInfosByDeveloperName().get('MRe_Appointment').getRecordTypeId();
        Broker_License__c brokerLicence = TestUtil.createBrokerLicense(contactBroker1, '', '123');
        brokerLicence.License_Number__c = 'LICTEST';
        brokerLicence.License_State__c = 'CA';
        brokerLicence.MRe_Appointment_Status__c = 'Not Started';
        brokerLicence.License_Type__c = 'Admitted Lines';
        brokerLicence.RecordTypeId = recordTypeBrokerLicence;
        insert brokerLicence;
        
        Id recordTypeAgencyLicence = [SELECT Id FROM RecordType WHERE DeveloperName = 'MRe_Appointment' AND sObjectType = 'Agency_License__c'].Id;
        //Id recordTypeAgencyLicence = Schema.SObjectType.Agency_License__c.getRecordTypeInfosByDeveloperName().get('MRe_Appointment').getRecordTypeId();
        Agency_License__c agencyLicence = new Agency_License__c();
        agencyLicence.Agency__c = accBroker.Id;
        agencyLicence.License_Number__c = brokerLicence.License_Number__c;
        agencyLicence.License_State__c = brokerLicence.License_State__c;
        agencyLicence.License_Type__c = 'Admitted Lines';
        agencyLicence.MRe_Appointment_Status__c = 'Not Started';
        agencyLicence.RecordTypeId = recordTypeAgencyLicence;
        insert agencyLicence;
        
      
        
        String insuredState = 'AL';
        String quoteId = '';
        String oppId = opp.Id;
        
        test.startTest();
        BindQuoteController.fetchMReAppointmentDetails(quoteId, oppId, insuredState);
        BindService.fetchMReAppointmentDetails(quoteId, oppId, insuredState);
        test.stopTest();
        
    }
    
    public static testmethod void covergetHttpRequest(){
        Test.startTest();
        API_Configuration__mdt apiSettings = [SELECT id,Base_Url__c,Endpoint__c,HeaderParams__c,Method__c 
                                              FROM API_Configuration__mdt LIMIT 1];
        apiSettings.Base_Url__c = 'https://dev.api.innovisk.com';
        apiSettings.Endpoint__c = 'quoteAzureId/sfdc/v1/ofac';
        //BindQuoteController.getHttpRequest(apiSettings,'335252871d624d01b2fdf6e379d2fdfe','Bind_Quote_V2');
        Contact con = [Select Id,Name,MailingStreet,MailingCity,MailingState,MailingPostalCode,MailingCountryCode,Mailing_County__c,AccountId,Home_License_no__c from Contact LIMIT 1];
        Account acc = [Select Id,Name,BillingStreet,BillingCity,BillingState,BillingPostalCode,BillingCountryCode,Billing_County__c,FEIN__c from account limit 1];
        // START Added by RINKU SAINI 12th Jan 2022
        BindServiceHandler_Common.InComingRequestOFAC obj = new BindServiceHandler_Common.InComingRequestOFAC();
        BindServiceHandler_Common.InComingRequestOFAC obj1 = new BindServiceHandler_Common.InComingRequestOFAC(con);
        BindServiceHandler_Common.InComingRequestOFAC obj2 = new BindServiceHandler_Common.InComingRequestOFAC(acc);
        BindServiceHandler_Common.ResponseWrapper obj3 = new BindServiceHandler_Common.ResponseWrapper();
        obj3.status = '';
        obj3.data = '';
        // END Added by RINKU SAINI 12th Jan 2022
        Test.stopTest();
    }
    
    // Added by RINKU SAINI 11th Jan 2022
    public class bindQuoteMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"Success","message":"Quote bound successfully.","data":{"quoteId":"34e5fb38-0e90-41c1-867a-e79e56d9bf02","status":"Bound","policyInformation":{"PolicyNumber":"5DA3FF0000683-00","PriorPolicyNumber":"","PolicyId":"4cab516e-c3ba-4500-b7bf-d40c8c51fb9b","BoundDateTime":"2021-09-06 13:14:13","IssueDate":"2022-09-06","BindingLicenseNumber":"dsdsd","BindingLicenseOwner":"Agency","BindingLicenseOwnerAddress":"102,Richard Have,Hoston TX 77082,USA","BindingLicenseOwnerName":"12121","PaymentDetails":{"TransactionID":"123","CardHolderName":"Test","ProcessorResponseText":"Test","Timestamp":"","Amount":"200","PaymentInstrumentType":"Test"},"BillingType":"","Documents":[{"Id":"","Type":"CelerityExcessQuote","GeneratedDate":""},{"Id":"29ea0b2b-4f68-420b-9dab-88a0c501a80a","Type":"PolicySchedulePrimary","GeneratedDate":"2021-03-31"}]}}}');
            res.setStatusCode(200);
            system.debug('res--->'+res);
            return res;
        }
    }
    
    // Added by RINKU SAINI 12th Jan 2022
    public class bindQuoteMockNeagtiveTest implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"Success","message":"Quote bound successfully.","data":{"quoteId":"34e5fb38-0e90-41c1-867a-e79e56d9bf02","status":"Bound","policyInformation":{"PolicyNumber":"5DA3FF0000683-00","PriorPolicyNumber":"","PolicyId":"4cab516e-c3ba-4500-b7bf-d40c8c51fb9b","BoundDateTime":"2022-09-06 13:14:13","IssueDate":"2022-09-06","BindingLicenseNumber":"dsdsds","BindingLicenseOwner":"Agency","BindingLicenseOwnerAddress":"102,Richard Have,Hoston TX 77082,USA","BindingLicenseOwnerName":"12212","PaymentDetails":{"TransactionID":"123","CardHolderName":"Test","ProcessorResponseText":"Test","Timestamp":"","Amount":"200","PaymentInstrumentType":"Test"},"BillingType":"","Documents":[{"Id":"","Type":"CelerityExcessQuote","GeneratedDate":""},{"Id":"29ea0b2b-4f68-420b-9dab-88a0c501a80a","Type":"PolicySchedulePrimary","GeneratedDate":"2021-03-31"}]}}}');
            res.setStatusCode(500);
            return res;
        }
    }
    
}