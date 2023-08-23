@isTest
public class REST_Invsk_BrokerTest {
    	public static Quote quote;
	public static Opportunity opp;
@testSetup static void setup() {
   
		//Create Account
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

        // Create contact
		Contact con = new Contact(
			Lastname = 'Test broker',
			RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
		);
		insert con;
    

		Contract contr = new Contract(
			AccountId = acc1.Id,
			Expiration_Date__c = Date.today().addDays(100)
        );

        insert contr;

        // create policy  
        Policy__c policy = new Policy__c();
        	policy.Account__c = acc1.Id; 
        	policy.Expiration_Date__c = Date.today().addDays(100);           
        insert policy;

		//Create Product
		Product2 prd = new Product2(
			Name = 'Private Company Combo',
			RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Celerity').getRecordTypeId(),
			Innovisk_Entity_ID__c = 'Celerity',
			Package_Indicator__c = true,
			IsActive = true,
			Expiration_Date__c = Date.today().addDays(200),
			Effective_Date__c = Date.today().addDays(-1)
		);
		insert prd;

		// Create opportunity
		Opportunity opp = new Opportunity();
		opp.Name = 'Test opp';
		opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
		opp.Coverage_Product_Options__c = 'MPL';
		opp.AccountId = acc1.Id;
		opp.Pricebook2Id = Test.getStandardPricebookId();
		opp.Product__c = prd.Id;
		opp.Received_Date__c = Date.today();
		opp.CloseDate = Date.today().addDays(30);
		opp.Effective_Date__c = Date.today();
		opp.Type = 'New Business';
		opp.LeadSource = 'Email';
		opp.StageName = 'New';
		opp.ContractId = contr.Id;
		opp.Policy__c = policy.Id;
		insert opp;

		// Create broker
		Broker_Account__c broketAccount = new Broker_Account__c(
			Broker_Contact__c = con.Id,
			Opportunity__c = opp.Id,
			IsPrimaryBroker__c = true,
			Relationship_Type__c = 'Broker'
		);
		insert broketAccount;
     
    

    	Broker_License__c licensetest = new Broker_License__c();
        licensetest.Broker__c = con.Id;
        licensetest.License_Number__c = '1234';
        licensetest.License_State__c =  'NY';
        licensetest.License_Type__c = 'Surplus Lines';
        insert licensetest;
        
        Quote quote = TestUtil.createQuote('New quote 1', opp.Id);
       quote.Status = 'In Progress';
       quote.Coverage_Product_Options__c = 'MPL';
        quote.Quote_Type__c = 'New Business';
     	quote.Refer_Type__c = 'Underwriting Referral';
      
        insert quote; 
    
		Coverage__c cov1 = TestUtil.createCoverage('Coverage test', 'MPL');
		insert cov1;

        //create limit deductables
		Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov1.Id);
        insert ded;
        
         // Coverages Line Item
        CoveragesLineItem__c coverLi = new CoveragesLineItem__c();
        coverLi.Coverage__c  = cov1.Id; 
        coverLi.Quote__c = quote.Id;
        coverLi.Limits_Deductibles__c = ded.Id;
        coverLi.Coverage_Premium__c  = 'Text Premium'; 
        coverLi.Min_amt__c  = 1000;
        coverLi.Max_amt__c  = 5000;
        coverLi.Deductible_Frequency__c  = 'Daily';
        coverLi.Options_Value_Percent__c  = 5;
        insert coverLi;
      
        ded.LmtDedCode__c = coverLi.Limits_Deductibles__c;
        update ded;
        
        cov1.Coverage_Code__c = coverLi.Coverage__c;
        update cov1;
    
        REST_Invsk_Broker.WrapperObject Rest = new  REST_Invsk_Broker.WrapperObject();
        Rest.BrokerContactId= '12';
		Rest.BrokerContactName='TestBroker';
		Rest.BrokerAccountName='TestAccount';
		Rest.BrokerPhone='1234567890';		
        Rest.AppointedFlag= true;  
        Rest.FEINNumber='123';   
				/*Test.startTest();
		TriggerSettings__c setting = new TriggerSettings__c();
		setting.BypassOpportunityTrigger__c = false;
		setting.BypassQuoteLineItemTrigger__c = false;
		insert setting;

		// Create new Quote
		TestUtil.createQuoteOnOpportunity();
		//Long - 05/03/2020 - remove the compound field in SOQL to apply the encryption
		//Contact conBusiness = [Select Id, Email From Contact Where Name = 'Contact_Broker_Test_01' limit 1];
		Contact conBusiness = [Select Id, Email From Contact Where LastName = 'New broker contact' limit 1];
		//End
		conBusiness.Email = 'binh@yahoo.com';
		update conBusiness;
		
		Broker_Account__c broker = [Select Id From Broker_Account__c limit 1];

		Test.stopTest();

		System.assertEquals(true, String.isNotBlank(broker.Id));*/
	}

	@isTest
	static void testAddPostMethod_NullQuote() {
		Test.startTest();
		
		REST_Invsk_Broker.CommingRequest incomingReq = new REST_Invsk_Broker.CommingRequest();
		incomingReq.OpportunityId = '';
		incomingReq.ContactId = '';
		String myJSON = JSON.serialize(incomingReq);

		// Clone success
		RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();

        request.requestUri = '/services/apexrest/Invsk_Broker';
        request.httpMethod = 'POST';
		request.requestBody = Blob.valueof(myJSON);
		request.addHeader('Content-Type', 'application/json'); 

		RestContext.request = request;
		RestContext.response = res;
    
        REST_Invsk_Broker.doPost();
      
		Test.stopTest();

		System.assert(RestContext.response.statusCode==200);
	}

	@isTest
	static void testAddPostMethod_CreateBroker() {
		Test.startTest();
		//Long - 05/03/2020 - remove the compound field in SOQL to apply the encryption
		//Contact con = [Select Id, Azure_Id__c From Contact Where Name = 'Contact_Broker_Test_01' limit 1];
		Contact con = [Select Id, Azure_Id__c From Contact limit 1];
		//End
		Product2 product = [Select Id From Product2 limit 1];
		Quote newQuote = [Select Id,Azure_Id__c,Opportunity.Azure_ID__c From Quote Where Opportunity.Product__c =: product.Id limit 1];
		Broker_Account__c broker = [Select Id, IsPrimaryBroker__c From Broker_Account__c limit 1];
	
		RestRequest request = new RestRequest();
		request.requestUri = '/services/apexrest/Invsk_Broker';
		request.httpMethod = 'POST';
		request.requestBody =  Blob.valueOf(
								 '{"OpportunityId" : "' + newQuote.Opportunity.Azure_ID__c + ',"ContactId" : "' + broker+'"}');
		RestResponse response  = new RestResponse();

		// Finally, assign the request to RestContext if used
		RestContext.request = request;
		RestContext.response = response; 
		
        REST_Invsk_Broker.doPost();
        Test.stopTest();
	
	}
    @isTest
	static void testAddPostMethod_CreateBroker1() {
		Test.startTest();
       Account acc1 = [select id from Account limit 1];
        Product2 prd = [select id from Product2 limit 1 ];
        Contact con = [select id,Azure_ID__c from contact limit 1];
        
        Opportunity opp1 = TestUtil.createOpportunity('Test opp1', acc1.Id, prd.Id, 
					Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId(), 'Celerity');
		opp1.CloseDate = Date.today().addDays(30);
		opp1.Effective_Date__c = Date.today().addDays(1);
		opp1.Pricebook2Id = Test.getStandardPricebookId();
		opp1.Coverage_Product_Options__c = 'D&O';
		insert opp1;
        
        Broker_Account__c broker =  TestUtil.createBrokerAccount(con.Id, opp1.Id);
        broker.IsPrimaryBroker__c = true;
		insert broker;
     
        opp1.Azure_ID__c = '1234abcd';
        update opp1;
        
        REST_Invsk_Broker.CommingRequest incomingReq = new REST_Invsk_Broker.CommingRequest();
		incomingReq.OpportunityId = opp1.Azure_ID__c;
		incomingReq.ContactId = con.Azure_ID__c;
		//String myJSON = JSON.serialize(incomingReq);
        
		
        RestRequest request = new RestRequest();
		request.requestUri = '/services/apexrest/Invsk_Broker';
		request.httpMethod = 'POST';
		request.requestBody = Blob.valueOf(JSON.serialize(incomingReq));
      
		RestResponse response  = new RestResponse();

		// Finally, assign the request to RestContext if used
		RestContext.request = request;
		RestContext.response = response; 
		
        REST_Invsk_Broker.doPost();
        Test.stopTest();
	
	}

	@isTest
	static void testGetDetail_NotExistOpp() {
		Test.startTest();
			
		//Contact conBusiness = [Select Id, Email From Contact Where Name = 'Contact_Broker_Test_01' limit 1];
	
		String myJSON = '{"brokerEmail" : ""}';

		// Clone success
		RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();

        request.requestUri = '/services/apexrest/Invsk_Broker';
        request.httpMethod = 'GET';
		request.requestBody = Blob.valueof(myJSON);
		request.addHeader('Content-Type', 'application/json');
		request.params.put('brokerEmail', '');

		RestContext.request = request;
		RestContext.response = res;
        REST_Invsk_Broker.doGet();
      
		Test.stopTest();

		System.assert(RestContext.response.statusCode==200);
	}

	@isTest
	static void testGetDetail_InvalidEmail() {
		Test.startTest();
        Contact con = [Select Id,Name,Email,Account.Name From Contact limit 1];
        
        
		String myJSON = '{"brokerEmail" : ""}';
       // Clone success
		RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();

        request.requestUri = '/services/apexrest/Invsk_Broker';
        request.httpMethod = 'GET';
		request.requestBody = Blob.valueof(myJSON);
		request.addHeader('Content-Type', 'application/json');
		request.params.put('brokerEmail', 'abc.com');
       
		//request.params.put('brokerEmail', con.Email);

	

		RestContext.request = request;
		RestContext.response = res;
        REST_Invsk_Broker.doGet();
      
		Test.stopTest();

		System.assert(RestContext.response.statusCode==200);
	}
   
	@isTest
	static void testGetDetail_NotExistEmail() {
		Test.startTest();
			
		String myJSON = '{"brokerEmail" : ""}';

		// Clone success
		RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();

        request.requestUri = '/services/apexrest/Invsk_Broker';
        request.httpMethod = 'GET';
		request.requestBody = Blob.valueof(myJSON);
		request.addHeader('Content-Type', 'application/json');
		request.params.put('brokerEmail', 'abc@yahoo.com');

		RestContext.request = request;
		RestContext.response = res;
        REST_Invsk_Broker.doGet();
      
		Test.stopTest();

		System.assert(RestContext.response.statusCode==200);
	}
    @isTest
	static void testGetDetail_ExistEmail() {
		Test.startTest();
			Contact con = [Select Id,Name,Email,Account.Name From Contact limit 1];
        con.Email = 'abc@gmail.com';
        update con;
        //Broker_Account__c broketAccount =[Select id from Broker_Account__c limit 1 ];
        //broketAccount.Broker_Contact__c = con.id;
        //update 
		String myJSON = '{"brokerEmail" : "' + con.Email + '"}';

		// Clone success
		RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();

        request.requestUri = '/services/apexrest/Invsk_Broker';
        request.httpMethod = 'GET';
		request.requestBody = Blob.valueof(myJSON);
		request.addHeader('Content-Type', 'application/json');
		request.params.put('brokerEmail', con.Email);

		RestContext.request = request;
		RestContext.response = res;
        REST_Invsk_Broker.doGet();
      
		Test.stopTest();

		System.assert(RestContext.response.statusCode==200);
	}
}