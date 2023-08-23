@isTest
public with sharing class REST_Invsk_PolicyTest {

	private static Opportunity newOppt;
	private static Quote newQuote;
	//private static Equipment__c equipment;
	private static Location__c loc;
	private static Account accBusiness;
	private static Contact contactBroker;
	 @testsetup static void testSetup() {
		// Create Custom Setting
		TriggerSettings__c setting = TestUtil.initialTriggerSetting();
		setting.BypassQuoteTrigger__c = false;
		setting.BypassQuoteLineItemTrigger__c = false;
		setting.BypassOpportunityTrigger__c = false;
		setting.BypassBrokerAccountTrigger__c = false;
		//setting.BypassQuoteEquipmentTrigger__c = false;
		setting.BypassAccountTrigger__c = false;
		update setting;

		// Create Accounts
		List<Account> accountInserts = new List<Account>();
		        
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
		Account accBusiness  =TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster',
												'California','90000', 'United States');
         accBusiness.Azure_ID__c = '8042ac98-ae5a-4692-9880-58d92d0eb9d9';
		insert accBusiness;
        system.debug('accBusiness Id'+accBusiness.Id);
        
         Id recordTypeBrokerAgency = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        
        Account accBroker = TestUtil.createBusinessAccount('Broker Account Test', 'Broker_Account', '625, South Mill Road', 'Anycity', 'New York', '67074', 'United States');
		accBroker.RecordTypeId = recordTypeBrokerAgency;
		
        insert accBroker;

		Contact contactBroker = TestUtil.createContact(accBroker.Id, 'Broker_Contact', 'New broker contact');
		insert  contactBroker;   

		/*// Create Contact Broker
		Id brokerConRtId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
		//contactBroker = TestUtil.createContact('Contact_Broker_Test_01', brokerConRtId, accBorker.Id);
		Contact contactBroker = TestUtil.createContact(accBusiness.Id, 'Broker_Contact', 'New broker contact');
		insert contactBroker;*/

		// Create Product
		/*Id productRtId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Vindati').getRecordTypeId();
		Product2 equipmentProduct = TestUtil.createProduct('Equipment', productRtId, 'Vindati');
		equipmentProduct.Pay_Plan__c = '2 Pay Plan;4 Pay Plan;6 Pay Plan';
		insert equipmentProduct;*/
        
         Product2 product = TestUtil.createProduct('D&O Standalone');
		insert product; 

		Id pricebook2Id = Test.getStandardPricebookId();
		PricebookEntry pricebookEntryEquipment =  TestUtil.createPricebookEntry(pricebook2Id, product.Id);
		insert pricebookEntryEquipment;

		// Create Opportunity
		/*Id opptRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Vindati').getRecordTypeId();
		newOppt = TestUtil.createOpportunity('Opportunity Test', accBusiness.Id, 
                                        product.Id, opptRtId, product.Innovisk_Entity_ID__c);
		insert newOppt;*/
        
        Opportunity newOppt = TestUtil.createOpportunity('Opp Test',accBusiness.Id, product.Id);
        newOppt.CloseDate = Date.today()+365;
        newOppt.StageName = 'New';
        newOppt.Azure_ID__c = 'f70e4c82-3378-41ce-870b-57f4df415874';
        insert newOppt;

		// Add Broker to Opportunity
		Broker_Account__c newBroAccount = TestUtil.createBrokerAccount(contactBroker.Id, newOppt.Id);
		insert newBroAccount;

		// Qualify Opportunity
		Opportunity opptUpdate = [Select Id, StageName From Opportunity where Id=: newOppt.Id];
		opptUpdate.StageName = 'Qualified';
		update opptUpdate;

		newQuote = TestUtil.createQuote('test',newOppt.Id);
		newQuote.Status = 'Quoted';
		insert newQuote; 
         
          // create policy  
        Policy__c policy = new Policy__c();
        	policy.Account__c = accBusiness.Id;
        	policy.Product_Name__c = 'MPL';
        	policy.Expiration_Date__c = Date.today().addDays(100);
        	policy.Total_Premium__c = 2000;
        	policy.Initial_Premium__c = null;
        insert policy;



		List<Quote> lstQuote = [SELECT Id,Azure_ID__c FROM Quote WHERE Id = :newQuote.Id];
		//BindQuoteController.bindQuoteFromAPI(lstQuote[0].Azure_ID__c);

		       
        Account_Product__c accProduct = new Account_Product__c();
        accProduct.Account_Id__c = accBusiness.Id;
        accProduct.Product_Id__c = product.id;
        insert accProduct;

		List<Quote> lstQuote2 = [SELECT Id,Azure_ID__c,ContractId FROM Quote WHERE Id = :newQuote.Id];
		Document_Revision__c documentRevision  = new Document_Revision__c(
        	Name = 'QuoteProposal' + '_' + String.valueOf(Datetime.now()),
        	Document_Azure_Id__c = '1',
        	Document_Type__c = 'QuoteProposal',
        	Quote_Id__c = newQuote.Id
        	//Contract__c = lstQuote2[0].ContractId
        );
        insert documentRevision;         

       String rdPolicyId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId(); 
       String dtNow = String.valueOf(Datetime.now());
       Document_Revision__c newDoc = new Document_Revision__c(
            Name = 'PolicyForm' + '_' + dtNow,
            Document_Azure_Id__c = '3',
            Document_Type__c = 'PolicyForm',
            RecordTypeId = rdPolicyId
            //Contract__c = lstQuote2[0].ContractId
        ); 
        insert newDoc;         
	}

   
    @isTest
    public static void testGetEquipmentValidParam() {
        
       // accBusiness = [SELECT Id,Azure_Id__c FROM Account Where Id = :accBusiness.Id];
       
        //contactBroker = [SELECT Id,Azure_Id__c FROM Contact Where Id = :contactBroker.Id];
        system.debug('accBusiness'+ accBusiness);
        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Policies/';
        request.httpMethod = 'POST';
        //request.headers.put('Channel-Key', accBusiness.Azure_Id__c);
        //request.headers.put('Broker-Key', contactBroker.Azure_Id__c);
        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        REST_Invsk_Policy.getPolicies();
        Test.stopTest();
        
        System.assertEquals(200, RestContext.response.statusCode);
    }
	
    @isTest
    public static void testEmptyAccountPolicy() {
        	
        //accBusiness = [SELECT Id FROM Account Where Id = :accBusiness.Id];
        system.debug('accBusiness'+accBusiness);
        //contactBroker = [SELECT Id,Azure_Id__c FROM Contact Where Id = :contactBroker.Id];
        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Policies/';
        request.httpMethod = 'POST';
        //request.headers.put('Channel-Key', accBusiness.Azure_Id__c);
        //request.headers.put('Broker-Key', contactBroker.Azure_Id__c);

        REST_Invsk_Policy.IncomingRequest inComingRequest = new REST_Invsk_Policy.IncomingRequest();
        inComingRequest.AccountId = '';
        inComingRequest.PolicyAzureId = '';
        request.requestBody = Blob.valueOf(JSON.serialize(inComingRequest));    

        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        REST_Invsk_Policy.getPolicies();
        Test.stopTest();
        
        System.assertEquals(200, RestContext.response.statusCode);
    } 
    @isTest
    public static void testEndorsementSummary1() {
        //accBusiness = [SELECT Id,Azure_Id__c FROM Account Where Id = :accBusiness.Id];
        //contactBroker = [SELECT Id,Azure_Id__c FROM Contact Where Id = :contactBroker.Id];

        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Policies/';
        request.httpMethod = 'POST';
       // request.headers.put('Channel-Key', accBusiness.Azure_Id__c);
        //request.headers.put('Broker-Key', contactBroker.Azure_Id__c);
        request.requestBody = Blob.valueOf('{ "AccountId":"", "PolicyAzureId":"" }');

        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;      

        Test.startTest();
        REST_Invsk_Policy.getPolicies();
        Test.stopTest();
        
        System.assertEquals(200, RestContext.response.statusCode);  
    }   
	
    @isTest
    public static void testGetEquipmentBrokerInvalid() {
        
       // accBusiness = [SELECT Id FROM Account Where Id = :accBusiness.Id];
       // contactBroker = [SELECT Id,Azure_Id__c FROM Contact Where Id = :contactBroker.Id];
        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Policies/';
        request.httpMethod = 'POST';
       // request.headers.put('Channel-Key', accBusiness.Azure_Id__c);
        request.headers.put('Broker-Key', 'test-123');
        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        REST_Invsk_Policy.getPolicies();
        Test.stopTest();
        
        System.assertEquals(200, RestContext.response.statusCode);
    }
     @isTest
    public static void testGetEquipmentChannelInvalid() {
        
        //accBusiness = [SELECT Id,Azure_Id__c FROM Account Where Id = :accBusiness.Id];
        //contactBroker = [SELECT Id,Azure_Id__c FROM Contact Where Id = :contactBroker.Id];
        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Policies/';
        request.httpMethod = 'POST';
        request.headers.put('Channel-Key', 'test111');
        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        REST_Invsk_Policy.getPolicies();
        Test.stopTest();
        
        System.assertEquals(200, RestContext.response.statusCode);
    }

   
    @isTest
    public static void testGetEquipmentNoBroker() {
        
        //accBusiness = [SELECT Id,Azure_Id__c FROM Account Where Id = :accBusiness.Id];
        //contactBroker = [SELECT Id,Azure_Id__c FROM Contact Where Id = :contactBroker.Id];
        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Policies/';
        request.httpMethod = 'POST';
       // request.headers.put('Channel-Key', accBusiness.Azure_Id__c);
        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        REST_Invsk_Policy.getPolicies();
        Test.stopTest();
        
        System.assertEquals(200, RestContext.response.statusCode);
    }
    @isTest
    public static void testGetEquipmentNoChannel() {
        
        //accBusiness = [SELECT Id,Azure_Id__c FROM Account Where Id = :accBusiness.Id];
       // system.debug('accBusiness------------------'+accBusiness);
        //contactBroker = [SELECT Id,Azure_Id__c FROM Contact Where Id = :contactBroker.Id];
        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Policies/';
        request.httpMethod = 'POST';
       // request.headers.put('Broker-Key', contactBroker.Azure_Id__c);
        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        REST_Invsk_Policy.getPolicies();
        Test.stopTest();
        
        System.assertEquals(200, RestContext.response.statusCode);
    }
	
    @isTest
    public static void testCreateDocumentRevisionMap() {
        List<Document_Revision__c> doc = [SELECT Name,Document_Type__c FROM Document_Revision__c];  
        system.assert(doc != null);
    }
    
    @isTest
    public static void testsetEndorsementQuoteWrapper() {
         Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
		Account acc  =TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster',
												'California','90000', 'United States');
       // acc.Azure_ID__c = '8042ac98-ae5a-4692-9880-58d92d0eb9d9';
		insert acc;
    
        Product2 product = TestUtil.createProduct('D&O Standalone');
		insert product; 

        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today()+365;
        opp.StageName = 'New';
       // opp.Azure_ID__c = 'f70e4c82-3378-41ce-870b-57f4df415874';
        insert opp;
       
        Quote newQuote1 = TestUtil.createQuote('test',opp.Id);
        newQuote1.Status = 'Quoted';
        //newQuote1.ContractId = newContract.Id;        
        newQuote1.Quote_Type__c = 'Amendment';
        newQuote1.Status = 'Bound';  
        insert newQuote1;
        Test.startTest();
       
        REST_Invsk_Policy.EndorsementQuoteWrapper  wrap=new REST_Invsk_Policy.EndorsementQuoteWrapper();
        // wrap.Id = newQuote1.Id;
         REST_Invsk_Policy.setEndorsementQuoteWrapper(newQuote1); 
        Test.stopTest();
          
        
    }
    
     @isTest
    public static void testcreatePolicyWrap() {
         Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
		Account acc  =TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster',
												'California','90000', 'United States');
  insert acc;
    
        Product2 product = TestUtil.createProduct('D&O Standalone');
		insert product; 

        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today()+365;
        opp.StageName = 'New';
        insert opp;
       
        Quote newQuote1 = TestUtil.createQuote('test',opp.Id);
        newQuote1.Status = 'Quoted';
        newQuote1.Quote_Type__c = 'Amendment';
        newQuote1.Status = 'Bound';  
        insert newQuote1;
        Test.startTest();
        Map<Id, List<Document_Revision__c>> docRevMap = new Map<Id, List<Document_Revision__c>>();
        List<Document_Revision__c> doc = [SELECT Name,Document_Type__c,Document_Azure_Id__c,Policy__c
        	FROM Document_Revision__c];
       // REST_Invsk_Policy.getPolicies();
         REST_Invsk_Policy.createPolicyWrap(newQuote1,docRevMap); 
        Test.stopTest();
          
        
    }
     @isTest
    public static void testWrapcreateDocumentRevisionMap() {
         Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
		Account acc  =TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster',
												'California','90000', 'United States');
        insert acc;
        Set<Id> policyIds = new Set<Id>();
        Policy__c policy = new Policy__c();
        	policy.Account__c = acc.Id;
        	policy.Product_Name__c = 'MPL';
        	policy.Expiration_Date__c = Date.today().addDays(100);
        	policy.Total_Premium__c = 2000;
        	policy.Initial_Premium__c = null;
        insert policy;
        policyIds.add(policy.Id);
        Test.startTest();
       //REST_Invsk_Policy.getPolicies();
         REST_Invsk_Policy.createDocumentRevisionMap(policyIds); 
        Test.stopTest();
          
        
    }
       @isTest
    public static void testsample() {
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Policies/';
        request.httpMethod = 'POST';
        request.headers.put('Channel-Key', '407a8180-7cf0-4c74-99d0-4c194723916e');
        request.headers.put('Channel-Key', '407a8180-7cf0-4c74-99d0-4c194723916e');
        request.headers.put('Broker-Key', '407a8180-7cf0-4c74-99d0-4c194723916e');
        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
  Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account chanAcc  =TestUtil.createAccount('Test Channel Account', recordTypeId, '01 Tran Duy Hung','Westminster',
												'California','90000', 'United States');
        chanAcc.Azure_ID__c = '407a8180-7cf0-4c74-99d0-4c194723916e';
		insert chanAcc;
        Product2 prod =[Select id from Product2 where name='D&O Standalone'];
     	Opportunity opportunity1 = [SELECT Id FROM Opportunity limit 1];
		Broker_Account__c brokers = [SELECT Id, IsPrimaryBroker__c,Broker_Contact__c FROM Broker_Account__c WHERE Opportunity__c =: opportunity1.Id];
       
        contact con =[select id,LastName from contact where Lastname=:'New broker contact'];
        
        con.Azure_Id__c='407a8180-7cf0-4c74-99d0-4c194723916e';
        update con;
        Account_Product__c accProd1 = new Account_Product__c();
        accProd1.Account_Id__c = chanAcc.Id;
        accProd1.Product_Id__c = prod.id;
        insert accProd1;
        Test.startTest();
        REST_Invsk_Policy.getPolicies();
        Test.stopTest();
        
    }
      @isTest
    static void postMethodTest(){
        Test.startTest();
                
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account chanAcc  =TestUtil.createAccount('Test Channel Account', recordTypeId, '01 Tran Duy Hung','Westminster',
												'California','90000', 'United States');
        chanAcc.Azure_ID__c = '407a8180-7cf0-4c74-99d0-4c194723916e';
		insert chanAcc;
         Product2 prod =[Select id from Product2 where name='D&O Standalone'];
       Opportunity opportunity1 = [SELECT Id FROM Opportunity limit 1];
		Broker_Account__c brokers = [SELECT Id, IsPrimaryBroker__c,Broker_Contact__c FROM Broker_Account__c WHERE Opportunity__c =: opportunity1.Id];
        
      contact con =[select id,LastName from contact where Lastname=:'New broker contact'];
        
        con.Azure_Id__c='407a8180-7cf0-4c74-99d0-4c194723916e';
        update con;
        Account_Product__c accProd1 = new Account_Product__c();
        accProd1.Account_Id__c = chanAcc.Id;
        accProd1.Product_Id__c = prod.id;
        insert accProd1;
         
        Set<Id> policyIds = new Set<Id>();        
         List<Quote> quoteEndorsementList = new List<Quote>();
        Policy__c policy = new Policy__c();
        policy.Account__c = chanAcc.Id;
        policy.Product_Name__c = 'MPL';
        policy.Expiration_Date__c = Date.today().addDays(100);
        policy.Total_Premium__c = 2000;
        policy.Initial_Premium__c = null;
        policy.Azure_ID__c='407a8180-7cf0-4c74-99d0-4c194723916e';
        insert policy;
        policyIds.add(policy.Id);
        
        Quote newQuote1 = TestUtil.createQuote('test',opportunity1.Id);
        newQuote1.Status = 'Quoted';
        newQuote1.Quote_Type__c = 'Amendment';
        newQuote1.Status = 'Bound';  
        insert newQuote1;
        
        quoteEndorsementList.add(newQuote1);
        
        REST_Invsk_Policy.IncomingRequest incomingRequest = new REST_Invsk_Policy.IncomingRequest();
        incomingRequest.PolicyAzureId = [Select Id,Name,Azure_Id__c from Policy__c Limit 1].Azure_Id__c;
      //  incomingRequest.accountId = [Select Id, Name,Azure_Id__c from Account where Name = 'Test account 1'].Azure_Id__c;
        
        
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Policies/';
        request.httpMethod = 'POST';
        request.headers.put('Channel-Key', '407a8180-7cf0-4c74-99d0-4c194723916e');
        request.headers.put('Channel-Key', '407a8180-7cf0-4c74-99d0-4c194723916e');
        request.headers.put('Broker-Key', '407a8180-7cf0-4c74-99d0-4c194723916e');
       
        request.requestBody = Blob.valueOf(JSON.serialize(incomingRequest));
        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
        
        REST_Invsk_Policy.getPolicies();
       
        System.assertEquals(200, RestContext.response.statusCode);
        Test.stopTest();
    }
          @isTest
    static void postMethodTest1(){
        Test.startTest();
                
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account chanAcc  =TestUtil.createAccount('Test Channel Account', recordTypeId, '01 Tran Duy Hung','Westminster',
												'California','90000', 'United States');
        chanAcc.Azure_ID__c = '407a8180-7cf0-4c74-99d0-4c194723916e';
		insert chanAcc;
         Product2 prod =[Select id from Product2 where name='D&O Standalone'];
       Opportunity opportunity1 = [SELECT Id FROM Opportunity limit 1];
		Broker_Account__c brokers = [SELECT Id, IsPrimaryBroker__c,Broker_Contact__c FROM Broker_Account__c WHERE Opportunity__c =: opportunity1.Id];
        
      contact con =[select id,LastName from contact where Lastname=:'New broker contact'];
        
        con.Azure_Id__c='407a8180-7cf0-4c74-99d0-4c194723916e';
        update con;
        Account_Product__c accProd1 = new Account_Product__c();
        accProd1.Account_Id__c = chanAcc.Id;
        accProd1.Product_Id__c = prod.id;
        insert accProd1;
         
        Set<Id> policyIds = new Set<Id>();        
         List<Quote> quoteEndorsementList = new List<Quote>();
        Policy__c policy = new Policy__c();
        policy.Account__c = chanAcc.Id;
        policy.Product_Name__c = 'MPL';
        policy.Expiration_Date__c = Date.today().addDays(100);
        policy.Total_Premium__c = 2000;
        policy.Initial_Premium__c = null;
        insert policy;
        policyIds.add(policy.Id);
        
        Quote newQuote1 = TestUtil.createQuote('test',opportunity1.Id);
        newQuote1.Status = 'Quoted';
        newQuote1.Quote_Type__c = 'Amendment';
        newQuote1.Status = 'Bound';  
        newQuote1.Azure_ID__c = '407a8180-7cf0-4c74-99d0-4c194723916e';
        insert newQuote1;
        
        quoteEndorsementList.add(newQuote1);
        
        REST_Invsk_Policy.IncomingRequest incomingRequest = new REST_Invsk_Policy.IncomingRequest();
       // incomingRequest.PolicyAzureId = [Select Id,Name,Azure_Id__c from Policy__c Limit 1].Azure_Id__c;
        incomingRequest.accountId = [Select Id, Name,Azure_Id__c from Account where Name = 'Test account 1'].Azure_Id__c;
        
        
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Policies/';
        request.httpMethod = 'POST';
        request.headers.put('Channel-Key', '407a8180-7cf0-4c74-99d0-4c194723916e');
        request.headers.put('Channel-Key', '407a8180-7cf0-4c74-99d0-4c194723916e');
        request.headers.put('Broker-Key', '407a8180-7cf0-4c74-99d0-4c194723916e');
       
        request.requestBody = Blob.valueOf(JSON.serialize(incomingRequest));
        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
        
        REST_Invsk_Policy.getPolicies();
       
        System.assertEquals(200, RestContext.response.statusCode);
        Test.stopTest();
    }
              @isTest
    static void postMethodTest2(){
        Test.startTest();
                
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account chanAcc  =TestUtil.createAccount('Test Channel Account', recordTypeId, '01 Tran Duy Hung','Westminster',
												'California','90000', 'United States');
        chanAcc.Azure_ID__c = '407a8180-7cf0-4c74-99d0-4c194723916e';
		insert chanAcc;
         Product2 prod =[Select id from Product2 where name='D&O Standalone'];
       Opportunity opportunity1 = [SELECT Id FROM Opportunity limit 1];
		Broker_Account__c brokers = [SELECT Id, IsPrimaryBroker__c,Broker_Contact__c FROM Broker_Account__c WHERE Opportunity__c =: opportunity1.Id];
        
      contact con =[select id,LastName from contact where Lastname=:'New broker contact'];
        
        con.Azure_Id__c='407a8180-7cf0-4c74-99d0-4c194723916e';
        update con;
        Account_Product__c accProd1 = new Account_Product__c();
        accProd1.Account_Id__c = chanAcc.Id;
        accProd1.Product_Id__c = prod.id;
        insert accProd1;
         
        Set<Id> policyIds = new Set<Id>();        
         List<Quote> quoteEndorsementList = new List<Quote>();
        Policy__c policy = new Policy__c();
        policy.Account__c = chanAcc.Id;
        policy.Product_Name__c = 'MPL';
        policy.Expiration_Date__c = Date.today().addDays(100);
        policy.Total_Premium__c = 2000;
        policy.Initial_Premium__c = null;
        insert policy;
        policyIds.add(policy.Id);
        
        Quote newQuote1 = TestUtil.createQuote('test',opportunity1.Id);
        newQuote1.Status = 'Quoted';
        newQuote1.Quote_Type__c = 'Amendment';
        newQuote1.Status = 'Bound';  
        newQuote1.Policy__c = policy.Id;
        insert newQuote1;
        
        quoteEndorsementList.add(newQuote1);
        
        REST_Invsk_Policy.IncomingRequest incomingRequest = new REST_Invsk_Policy.IncomingRequest();
       // incomingRequest.PolicyAzureId = [Select Id,Name,Azure_Id__c from Policy__c Limit 1].Azure_Id__c;
      //  incomingRequest.accountId = [Select Id, Name,Azure_Id__c from Account where Name = 'Test account 1'].Azure_Id__c;
        
        
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_Policies/';
        request.httpMethod = 'POST';
        request.headers.put('Channel-Key', '407a8180-7cf0-4c74-99d0-4c194723916e');
        request.headers.put('Channel-Key', '407a8180-7cf0-4c74-99d0-4c194723916e');
        request.headers.put('Broker-Key', '407a8180-7cf0-4c74-99d0-4c194723916e');
       
        request.requestBody = Blob.valueOf(JSON.serialize(incomingRequest));
        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
        
        REST_Invsk_Policy.getPolicies();
       
        System.assertEquals(200, RestContext.response.statusCode);
        Test.stopTest();
    }
}