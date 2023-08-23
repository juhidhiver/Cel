@isTest
public with sharing class Invsk_CalloutTest {
    private static String QuoteHomeID = 'quoteHome_111';
    private static Opportunity opp;
    private static Quote quote;
    private static Account acc;
    private static Broker_License__c brokerLicence;
    
    @testSetup static void setup() {
         
        TriggerSettings__c setting = new TriggerSettings__c();
        setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        //setting.BypassQuoteDwellingHomeTrigger__c = true;
        setting.BypassLocationTrigger__c = true;
        setting.BypassContactTrigger__c = true;   
        insert setting;
        
        
        // Create Accounts
        List<Account> accountInserts = new List<Account>();
        
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account acc1 = TestUtil.createAccount('Test account 1', recordTypeId, 'Test account 1', 'Westminster',
                                              'California', 'California',  'United States');
        acc1.IsMailingSameWithBillingAddress__c = true;
        acc1.Date_Started__c = Date.today().addYears(-2);
        acc1.FEIN__c = 651106324;
        insert acc1;
        
        // Create product
        Product2 prd = TestUtil.createProduct('Private Company Combo');
        prd.Expiration_Date__c = Date.today().addDays(200);
        prd.Effective_Date__c = Date.today().addDays(-1);
        insert prd;
        
        acc1 = [SELECT Id FROM Account WHERE Id = :acc1.Id LIMIt 1];
        
        // Create opportunity
        Opportunity opp = TestUtil.createOpportunity('Test opp', acc1.Id, prd.Id);
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
        opp.Pricebook2Id = Test.getStandardPricebookId();
        opp.Coverage_Product_Options__c = 'D&O';
        opp.StageName = 'Qualified';
        opp.CloseDate = Date.today().addDays(30);
        opp.Effective_Date__c = Date.today().addDays(1);
        insert opp;
        
        // Create quote
        Quote newQuote = TestUtil.createQuote('Test newQuote 1', opp.Id);
        newQuote.Coverage_Product_Options__c = 'D&O';
        newQuote.Pricebook2Id = Test.getStandardPricebookId();
        insert newQuote;
        
        // Create Location
        Location__c newLocation = TestUtil.createNewLocation('131, 1st Avenue Test','New York', 'United States', '10093', 'New York');
        newLocation.State_Code__c = 'CA';
        insert newLocation;

        // Create Quote Location
        Quote_Location__c newQuoteLoc = TestUtil.createQuoteLocation(newQuote.Id, newLocation.Id, true);
        insert newQuoteLoc;
        
        Account acc3 = TestUtil.createAccount('Test account 3', recordTypeId, '106 Nguyen Van Troi', 'Westminster',
                                              'Alaska', '90002', 'United States');
        insert acc3;
        
        
        Invsk_Callout.NIPRResponse nIPRResponse = new Invsk_Callout.NIPRResponse();
        Invsk_Callout.AgencyLookup agencyLookup =  new Invsk_Callout.AgencyLookup();
        Invsk_Callout.LicenseLookup lclk =  new Invsk_Callout.LicenseLookup('123', 'new','1');    
        API_Configuration__mdt apiSetting =  new API_Configuration__mdt();
        
        
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        accBroker.FEIN__c = 651106324;
        insert accBroker;               
        
        Contact contactBroker = TestUtil.createContact(accBroker.Id, 'Broker_Contact', 'New broker contact');
        insert contactBroker;
        
        Broker_Account__c brokerAcc = TestUtil.createBrokerAccount(contactBroker.Id, newQuote.OpportunityId);
        brokerAcc.IsPrimaryBroker__c = true;
        insert brokerAcc;               
        
        Broker_License__c brokerLicence = TestUtil.createBrokerLicense(contactBroker, '', '123');
        brokerLicence.License_Number__c = 'LICTEST';
        brokerLicence.License_State__c = 'CA';   
        insert brokerLicence;
        
        Agency_License__c agency = new Agency_License__c();
        agency.Agency__c = accBroker.Id;
        agency.License_Number__c = brokerLicence.License_Number__c;
        agency.License_State__c = brokerLicence.License_State__c;
        insert agency;

    }
    
	
     public class WebServiceNIPR_InvskMockImpl implements HttpCalloutMock {
         public HTTPResponse respond(HTTPRequest req) {
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
       //res.setBody('{"isValidBrokerLicense":true,"npn":"20"}');
       res.setBody('{"isValidBrokerLicense":true,"npn":"20","isValidOFAC":"true","isValidAgencyFEIN":true}');
        res.setStatusCode(200);
        return res;
    	}
    }

    
    // NIPR API Test - successful request
    @isTest static void testGetNIPR(){
        // Associate the callout with a mock response
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        String result = Invsk_Callout.getNIPR(String.valueOf('651106324'));
        Test.stopTest();
        String expected = '{"isValidAgencyFEIN": true,"npn": "8904483"}';
        System.assertEquals(expected, result);
    }
    
    // NIPR API Failed Test - wrong request (empty fein)
    @isTest
    static void testGetNIPRFail(){
        // Set mock callout class
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        String body = '';
        String result = Invsk_Callout.getNIPR(body);
        Test.stopTest();
        System.assert(result.contains('400'));  
    }
    
    
    // NIPR API Failed Test - inccorect syntax (Server is unavailable)
    @isTest
    static void testGetNIPRFail2(){
        // Set mock callout class
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        String body = String.valueOf('Server is unavailable');
        String result = Invsk_Callout.getNIPR(body);
        Test.stopTest();
        System.assert(result.contains('unavailable'));  
    }
    
    // Sucessful getNIPRCallOut test
    @isTest static void testGetNIPRCallOutLB(){
        List<Id> lBLId = new List<Id>();
        Broker_License__c bL = [SELECT Id FROM Broker_License__c LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test account 1' LIMIt 1];
        lBLId.add(bL.Id); 
        lBLId.add(acc.Id);
        
        // Set mock callout class
        WebServiceNIPR_InvskMockImpl mock = new WebServiceNIPR_InvskMockImpl();
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Invsk_Callout.getNIPRCallOut(lBLId);
        Test.stopTest();
        System.assert(true);
        
    }
    
    @isTest
    public static void testGetNIPRCalloutAcc() {
        List<Id> lBLId = new List<Id>();
        
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test account 1' LIMIt 1];
        Broker_License__c bL = [SELECT Id FROM Broker_License__c LIMIT 1];
        
        lBLId.add(acc.Id);
        lBLId.add(bL.Id); 
        
        // Set mock callout class
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Invsk_Callout.getNIPRCallOut(lBLId);
        Test.stopTest();
        System.assert(true);
    }    
    
    @isTest static void testGetNIPRCallOutLB1(){
        List<Id> lBLId = new List<Id>();
        Broker_License__c bL = [SELECT Id FROM Broker_License__c LIMIT 1];
        lBLId.add(bL.Id);
        Quote q = new Quote();
        List<API_Log__c> apiLogList = new List<API_Log__c>();
        // Set mock callout class
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        mock.statusCode = 200;
        mock.body = '{"isValidBrokerLicense": true, "npn" : "123"}';
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Invsk_Callout.getNIPRCallOut(q,apiLogList);
        Test.stopTest();
        System.assert(true);
        
    }
    
   
    @isTest static void testGetNIPRCallOutStateBlank(){
        Quote quote = [SELECT Id, OpportunityId, Opportunity.Account.BillingStateCode FROM Quote LIMIT 1];
        quote.Opportunity.Account.BillingStateCode = ' ';
        update quote;
        List<API_Log__c> apiLogList = new List<API_Log__c>();
        // Set mock callout class
        WebServiceNIPR_InvskMockImpl mock = new WebServiceNIPR_InvskMockImpl();
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Invsk_Callout.getNIPRCallOut(quote,apiLogList);
        Test.stopTest();
        System.assert(true);
        
    } 
    
    
    @isTest static void testGetNIPRCallOut1(){
        Quote quote = [SELECT Id, OpportunityId, Opportunity.Account.BillingStateCode FROM Quote LIMIT 1];
        List<API_Log__c> apiLogList = new List<API_Log__c>();
        // Set mock callout class
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        mock.statusCode = 400;
        mock.body = '{"agencyLookup": {"fein": "391820226"}}';
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Invsk_Callout.getNIPRCallOut(quote,apiLogList);
        Test.stopTest();
        System.assert(true);
        
    }
    
    @isTest static void testGetNIPRCallOut2(){
        Quote quote = [SELECT Id, OpportunityId, Opportunity.Account.BillingStateCode FROM Quote LIMIT 1];
        List<API_Log__c> apiLogList = new List<API_Log__c>();
        // Set mock callout class
        WebServiceNIPR_InvskMockImpl mock = new WebServiceNIPR_InvskMockImpl();
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Invsk_Callout.getNIPRCallOut(quote,apiLogList);
        Test.stopTest();
        System.assert(true);
        
    }
    
    
    @isTest static void testGetRatedQuote(){
        // Set mock callout class
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        mock.statusCode = 200;
        mock.body = '{"agencyLookup": {"fein": "391820226"}}';
        Test.setMock(HttpCalloutMock.class, mock);
        
        List<Broker_License__c> newDataList = new List<Broker_License__c>();
        quote = new Quote(); 
        
        Test.startTest();
        Invsk_Callout.getRatedQuote(quote);
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest static void testGetRatedQuote1(){
        
        
        // Set mock callout class
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        mock.statusCode = 400;
        mock.body = '{"agencyLookup": {"fein": "391820226"}}';
        Test.setMock(HttpCalloutMock.class, mock);
        
        List<Broker_License__c> newDataList = new List<Broker_License__c>();
        
        quote = new Quote(); 
        
        Test.startTest();
        Invsk_Callout.getRatedQuote(quote);
        Test.stopTest();
        System.assert(true);
        
    }
    
    @isTest static void testGetRequestObject(){
        // getRequestObject(API_Configuration__mdt apiSetting, String body) {    
        API_Configuration__mdt apiSetting =  new API_Configuration__mdt();
        String body;
        Test.startTest();
        Invsk_Callout.getRequestObject(apiSetting, body);
        Test.stopTest();
        System.assert(true);
    }
    
    
    @isTest static void testGetRatingRequest(){
        
        // Set mock callout class
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        mock.statusCode = 200;
        mock.body = '{"agencyLookup": {"fein": "391820226"}}';
        Test.setMock(HttpCalloutMock.class, mock);
       
        Test.startTest();
        Invsk_Callout.getRatingRequest(new Quote());
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest static void testCheckBoundPending(){
        List<Account> accountAlls = new List<Account>();
        Account a = [SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode,
                     BillingCountryCode, Billing_County__c, FEIN__c FROM Account LIMIT 1];
        accountAlls.add(a);
        Contact c = [SELECT Id, Name, MailingStreet, MailingCity, MailingState, MailingPostalCode,
                     MailingCountryCode, Mailing_County__c, AccountId, Home_License_no__c FROM Contact LIMIT 1];
        Map<String, Account> mapUpdateAccount = new  Map<String, Account>();
        
        List<BindServiceHandler_Common.InComingRequestOFAC> listInComingRequestOFAC = new List<BindServiceHandler_Common.InComingRequestOFAC>();
        for(Account acc : accountAlls) {
            BindServiceHandler_Common.InComingRequestOFAC inComingRequestOFAC = new BindServiceHandler_Common.InComingRequestOFAC(acc);
            listInComingRequestOFAC.add(inComingRequestOFAC);
            mapUpdateAccount.put(acc.Id,acc);
        }
        BindServiceHandler_Common.InComingRequestOFAC inComingRequestOFACContact = new BindServiceHandler_Common.InComingRequestOFAC(c);
        listInComingRequestOFAC.add(inComingRequestOFACContact);
        
        // Set mock callout class
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        mock.statusCode = 200;
        mock.body = '{"isValidOFAC":"true"}';
       
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        Invsk_Callout.checkBoundPending(new Quote(), listInComingRequestOFAC, mapUpdateAccount);
        Test.stopTest(); 
        System.assert(true);
    } 
     
    
    @isTest
    public static void testGetNIPRCallOutAgency() {
        Quote quote = [SELECT Id, OpportunityId, Opportunity.Account.BillingStateCode FROM Quote LIMIT 1];
        List<API_Log__c> apiLogList = new List<API_Log__c>();
        // Set mock callout class
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        mock.statusCode = 400;
        mock.body = '{"agencyLookup": {"fein": "391820226"}}';
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Invsk_Callout.getNIPRCallOutAgency(quote,apiLogList);
        Test.stopTest();
        System.assert(true);
    }    

    @isTest
    public static void testCheckNIPRCallOutAgency() {
        Quote quote = [SELECT Id, OpportunityId, Opportunity.Account.BillingStateCode FROM Quote LIMIT 1];
        Invsk_Callout.NIPRResponseAgency resNIPRAgency = new Invsk_Callout.NIPRResponseAgency();
        List<Broker_Account__c> brokeracc = [SELECT Id, Broker_Contact__c, Broker_Contact__r.AccountId 
                                                FROM Broker_Account__c 
                                                WHERE Opportunity__c =: quote.OpportunityId 
                                                AND IsPrimaryBroker__c = true LIMIT 1];
        String stateCode = quote.Opportunity.Account.BillingStateCode;
        List<Agency_License__c> agencyAcc = new List<Agency_License__c>();
        agencyAcc= [SELECT Id FROM Agency_License__c WHERE Agency__c =: brokeracc[0].Broker_Contact__r.AccountId];
        List<API_Log__c> apiLogList = new List<API_Log__c>();
        // Set mock callout class
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        // mock.statusCode = 400;
        // mock.body = '{"agencyLookup": {"fein": "391820226"}}';
        mock.statusCode = 200;
        mock.body = '{"isValidBrokerLicense":true,"npn":"20","isValidOFAC":"true","isValidAgencyFEIN":true}';
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Invsk_Callout.checkNIPRCallOutAgency(agencyAcc[0].Id, resNIPRAgency, apiLogList, stateCode);
        Test.stopTest();
        System.assert(true);
    }    
    @isTest static void testCheckBoundPending2(){
        List<Account> accountAlls = new List<Account>();
        Account a = [SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode,
                     BillingCountryCode, Billing_County__c, FEIN__c FROM Account LIMIT 1];
        accountAlls.add(a);
        Contact c = [SELECT Id, Name, MailingStreet, MailingCity, MailingState, MailingPostalCode,
                     MailingCountryCode, Mailing_County__c, AccountId, Home_License_no__c FROM Contact LIMIT 1];
        Map<String, Account> mapUpdateAccount = new  Map<String, Account>();
        
        List<BindServiceHandler_Common.InComingRequestOFAC> listInComingRequestOFAC = new List<BindServiceHandler_Common.InComingRequestOFAC>();
        for(Account acc : accountAlls) {
            BindServiceHandler_Common.InComingRequestOFAC inComingRequestOFAC = new BindServiceHandler_Common.InComingRequestOFAC(acc);
            listInComingRequestOFAC.add(inComingRequestOFAC);
            mapUpdateAccount.put(acc.Id,acc);
        }
        BindServiceHandler_Common.InComingRequestOFAC inComingRequestOFACContact = new BindServiceHandler_Common.InComingRequestOFAC(c);
        listInComingRequestOFAC.add(inComingRequestOFACContact);
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
        Group grp = new Group();
        grp.name = 'OFAC Group';
        grp.Type = 'Regular'; 
        Insert grp;
        
        //Create Group Member
        GroupMember grpMem1 = new GroupMember();
        grpMem1.UserOrGroupId = UserInfo.getUserId();
        grpMem1.GroupId = grp.Id;
        Insert grpMem1;
        
        //Create Sub group
        Group subGrp  = new Group();
        subGrp.name = 'Test Group2';
        subGrp.Type = 'Regular'; 
        Insert subGrp;
        }
        // Set mock callout class
        WebServiceNIPR_InvskMockImpl mock = new WebServiceNIPR_InvskMockImpl();
       
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        Invsk_Callout.checkBoundPending(new Quote(), listInComingRequestOFAC, mapUpdateAccount);
        Test.stopTest(); 
        System.assert(true);
    }
     @isTest static void testGetNIPRCallOutAgencyEmptyBrokerAccount(){
         
        Quote quote = [SELECT Id, OpportunityId, Opportunity.Account.BillingStateCode FROM Quote LIMIT 1];
        Invsk_Callout.NIPRResponseAgency resNIPRAgency = new Invsk_Callout.NIPRResponseAgency();
        List<Broker_Account__c> brokeracc = [SELECT Id, Broker_Contact__c, Broker_Contact__r.AccountId 
                                                FROM Broker_Account__c 
                                                WHERE Opportunity__c =: quote.OpportunityId 
                                                AND IsPrimaryBroker__c = true LIMIT 1];
         delete brokeracc;
       // quote.Opportunity.Account.BillingStateCode='';
      /*  List<Agency_License__c> agencyAcc = new List<Agency_License__c>();
        agencyAcc= [SELECT Id FROM Agency_License__c WHERE Agency__c =: brokeracc[0].Broker_Contact__r.AccountId]; */
        List<API_Log__c> apiLogList = new List<API_Log__c>();
        // Set mock callout class
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        mock.statusCode = 400;
        mock.body = '{"agencyLookup": {"fein": "391820226"}}';
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Invsk_Callout.getNIPRCallOutAgency(quote,apiLogList);
        Test.stopTest();
        System.assert(true);
    }
@isTest static void testGetNIPRCallOutAgencyEmptyState(){
         
        Quote quote = [SELECT Id, OpportunityId, Opportunity.Account.BillingStateCode FROM Quote LIMIT 1];
        Invsk_Callout.NIPRResponseAgency resNIPRAgency = new Invsk_Callout.NIPRResponseAgency();
        List<Broker_Account__c> brokeracc = [SELECT Id, Broker_Contact__c, Broker_Contact__r.AccountId 
                                                FROM Broker_Account__c 
                                                WHERE Opportunity__c =: quote.OpportunityId 
                                                AND IsPrimaryBroker__c = true LIMIT 1];
      //  brokeracc[0].Broker_Contact__c ='';
        quote.Opportunity.Account.BillingStateCode='';
      
        List<API_Log__c> apiLogList = new List<API_Log__c>();
        // Set mock callout class
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        mock.statusCode = 400;
        mock.body = '{"agencyLookup": {"fein": "391820226"}}';
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Invsk_Callout.getNIPRCallOutAgency(quote,apiLogList);
        Test.stopTest();
        System.assert(true);
    }
    
}