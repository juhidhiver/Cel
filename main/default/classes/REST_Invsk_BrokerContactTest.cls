/*************************************************
* Class Name: REST_Invsk_BrokerContactTest 
* Author: Namana K g
* Date: 4/02/2021
* Requirement/Project Name: 
* Requirement/Project Description: 
*************************************************/

@isTest (SeeAllData = false)
private class REST_Invsk_BrokerContactTest{
	@testSetup static void setup() {
   
    Test.startTest();
        // Create Custom Setting
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassBrokerAccountTrigger__c = false;
      
        setting.BypassAccountTrigger__c = false;
        update setting;

		// Create Accounts
        List<Account> accountInserts = new List<Account>();

        // Account Broker 1
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        system.debug('hee'+brokerRtId);
        Account accBroker1 = TestUtil.createAccount('Account_Broker_Test_01', brokerRtId, '5305, Monroe Street',
                                                    'Toledo', 'Ohio','43623', 'United States');
		accBroker1.put('FEIN__c', 12345);
        insert accBroker1;
        
        // Account Broker 2
        Account accBroker2 = TestUtil.createAccount('Account_Broker_Test_02', brokerRtId, 
		        									'625, South Mill Road', 
		                                            'Leon', 'Kansas','67074', 'United States');
        accBroker2.put('Channel_Indicator__c', true);
          insert accBroker2;
        // Account Anonymous Portal
        Account accBrokerAnonymous = TestUtil.createAccount('Anonymous Portal Broker', brokerRtId, 
		        									'625, South Mill Road', 
		                                            'Leon', 'Kansas','67074', 'United States');
        accBrokerAnonymous.put('FEIN__c', 12345);


        insert accBrokerAnonymous;

        // Create Contact Broker
      
        
		 Id recordTypeContactAgency = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        system.debug('hhh'+recordTypeContactAgency );
        Contact contactBroker = new Contact(
			LastName = 'Contact_Broker_Test_01',
			RecordTypeId =recordTypeContactAgency ,
            Azure_Id__c = '1234',
			AccountId = accBroker1.Id);
		insert contactBroker;
      
      //Contact contactBroker = TestUtil.createContact( accBroker1.Id,'Broker_Contact', 'New broker contact');
          // Contact contactBroker = TestUtil.createContact('Contact_Broker_Test_01', brokerConRtId, accBroker1.Id);                                  
        										
        //insert contactBroker;

        // Create Product
        Id productRtId = Schema.SObjectType.Product2.getRecordTypeInfosByName().
        									get('Celerity').getRecordTypeId();
        Product2 equipmentProduct = TestUtil.createProduct('Mpl Standalone');
        insert equipmentProduct;

        Account_Product__c accProduct = new Account_Product__c();
        accProduct.Product_Id__c = equipmentProduct.Id;
        accProduct.Account_Id__c = accBroker1.Id;
        insert accProduct;
        
       Broker_License__c licensetest = new Broker_License__c();
        licensetest.Broker__c = contactBroker.Id;
        licensetest.License_Number__c = '1234';
        licensetest.License_State__c =  'NY';
        licensetest.License_Type__c = 'Surplus Lines';
        insert licensetest;
            
        
        Test.stopTest();
	           

	
        }
    @isTest
	static void testCreateContactAnonymousPortal() {
		Test.startTest();
		//Long - 05/03/2020 - remove the order by in SOQL to apply the encryption
		/*List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Anonymous Portal Broker')
									Order By Name ASC];*/
		List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Anonymous Portal Broker')];
		//End

		REST_Invsk_BrokerContact.AddressInfo address = new REST_Invsk_BrokerContact.AddressInfo();
		address.addressLine1 = 'Billing Street Test 11';
		address.city = 'HCM';
		address.state = 'WA';
		address.postalCode = '70001';
		address.country = 'US';
        address.county = 'US';
        
        REST_Invsk_BrokerContact.BrokerLicenses brokerlicense = new REST_Invsk_BrokerContact.BrokerLicenses();
        brokerlicense.licenseNumber = '65616';
        brokerlicense.licenseState = 'NY';
        brokerlicense.licenseType = 'Surplus Lines';
        brokerlicense.brokerLicOperation = 'Create';
        brokerlicense.licenseEntity = 'Individual';
        
        
        List<REST_Invsk_BrokerContact.BrokerLicenses> broLicen = new List<REST_Invsk_BrokerContact.BrokerLicenses>();
        broLicen.add(brokerlicense);       


		Account accBrokerAnonymous = [SELECT Id, Name FROM Account WHERE Name = 'Anonymous Portal Broker' LIMIT 1];
		//Long - 05/03/2020 - remove the compound field in SOQL to apply the encryption
		//Contact contactBroker = [SELECT Id FROM Contact WHERE Name = 'Contact_Broker_Test_01' LIMIT 1];
		Contact contactBroker = [SELECT Id FROM Contact WHERE LastName = 'Contact_Broker_Test_01' LIMIT 1];
		//End
		contactBroker.LastName = 'Anonymous Portal Broker';
		contactBroker.Email = 'newapi5@capgemini.com';
       
		contactBroker.AccountId = accBrokerAnonymous.Id;
        contactBroker.Azure_ID__c = '1234';
		update contactBroker;

		REST_Invsk_BrokerContact.CommingRequest incomingReq = new REST_Invsk_BrokerContact.CommingRequest();
		incomingReq.firstName = 'New';
		incomingReq.lastName = 'API 5';		
		incomingReq.emailAddress = 'newapi5@capgemini.com';
		incomingReq.phoneNo = '0978798798915';
		incomingReq.operation = 'Create';
		incomingReq.FEIN = String.valueOf(accList[0].FEIN__c);
		incomingReq.channelID = accList[0].Azure_Id__c;
        incomingReq.contactAzureId = accList[0].Azure_Id__c;
		incomingReq.address = address;
        incomingReq.appointedFlag = true;
        incomingReq.voucherCode = '865';
        incomingReq.licenses = broLicen;

		// Clone success
		RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();

        request.requestURI = '/services/apexrest/Invsk_BrokerContact';
        request.httpMethod = 'POST';
		request.addHeader('Content-Type', 'application/json'); 
		request.requestBody = Blob.valueOf(JSON.serialize(incomingReq));

		RestContext.request = request;
		RestContext.response = res;


        REST_Invsk_BrokerContact.doPost();

		Test.stopTest();

		System.assert(RestContext.response.statusCode==200);
	}

	@isTest
	static void testCreateContact() {
		Test.startTest();
		//Long - 05/03/2020 - remove the order by in SOQL to apply the encryption
		/*
		List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Account_Broker_Test_01', 'Account_Broker_Test_02')
									Order By Name ASC];
		
		*/
        Contact con = [Select Id,Azure_Id__c From Contact Where LastName = 'Contact_Broker_Test_01' Limit 1];
		List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Account_Broker_Test_01', 'Account_Broker_Test_02')];
		//End
		REST_Invsk_BrokerContact.AddressInfo address = new REST_Invsk_BrokerContact.AddressInfo();
		address.addressLine1 = 'Billing Street Test 11';
		address.city = 'HCM';
		address.state = 'WA';
		address.postalCode = '70001';
		address.country = 'US';
        
        Broker_License__c li = new Broker_License__c();
        li.Broker__c = con.Id;
        li.License_Number__c = '65616';
        li.License_Type__c = 'Surplus Lines';
        li.License_State__c = 'NY';
        li.License_Entity__c = 'Individual';
        insert li;
        
        REST_Invsk_BrokerContact.BrokerLicenses brokerlicense = new REST_Invsk_BrokerContact.BrokerLicenses();
        brokerlicense.licenseNumber = '65616';
        brokerlicense.licenseState = 'NY';
        brokerlicense.licenseType = 'Limited Lines';
        brokerlicense.brokerLicOperation = 'Delete';
        brokerlicense.licenseEntity = 'Individual';
        
       List<REST_Invsk_BrokerContact.BrokerLicenses> broLicen = new List<REST_Invsk_BrokerContact.BrokerLicenses>();
        broLicen.add(brokerlicense);

		REST_Invsk_BrokerContact.CommingRequest incomingReq = new REST_Invsk_BrokerContact.CommingRequest();
		incomingReq.firstName = 'Test';
		incomingReq.lastName = 'Contact 1';
		incomingReq.emailAddress = 'testcontact1@capgemini.com';
		incomingReq.phoneNo = '1234567876';
		incomingReq.operation = 'Create';
		incomingReq.FEIN = String.valueOf(accList[0].FEIN__c);
		incomingReq.channelID = accList[1].Azure_Id__c;
        incomingReq.appointedFlag = true;
        incomingReq.voucherCode = '865';
		incomingReq.address = address;  
        incomingReq.licenses = broLicen;
      
		// Clone success
		RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();

        request.requestUri = '/services/apexrest/Invsk_BrokerContact';
        request.httpMethod = 'POST';
		request.addHeader('Content-Type', 'application/json'); 
		request.requestBody = Blob.valueOf(JSON.serialize(incomingReq));

		RestContext.request = request;
		RestContext.response = res;


        REST_Invsk_BrokerContact.doPost();

		Test.stopTest();

		System.assert(RestContext.response.statusCode==200);
	}

	@isTest
	static void testCreateContactErrorLastName() {
		Test.startTest();
		//Long - 05/03/2020 - remove the order by in SOQL to apply the encryption
		/*List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Account_Broker_Test_01', 'Account_Broker_Test_02')
									Order By Name ASC];*/
		List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Account_Broker_Test_01', 'Account_Broker_Test_02')];
		//End

		REST_Invsk_BrokerContact.AddressInfo address = new REST_Invsk_BrokerContact.AddressInfo();
		address.addressLine1 = 'Billing Street Test 11';
		address.city = 'HCM';
		address.state = 'WA';
		address.postalCode = '70001';
		address.country = 'US';
        
        REST_Invsk_BrokerContact.BrokerLicenses brokerlicense = new REST_Invsk_BrokerContact.BrokerLicenses();
        brokerlicense.licenseNumber = '65616';
        brokerlicense.licenseState = 'NY';
        brokerlicense.licenseType = 'Limited Lines';
        brokerlicense.brokerLicOperation = 'Create';
        brokerlicense.licenseEntity = 'Individual';
        
        List<REST_Invsk_BrokerContact.BrokerLicenses> broLicen = new List<REST_Invsk_BrokerContact.BrokerLicenses>();
        broLicen.add(brokerlicense);

		REST_Invsk_BrokerContact.CommingRequest incomingReq = new REST_Invsk_BrokerContact.CommingRequest();
		incomingReq.firstName = 'Test';
		incomingReq.lastName = '';
		incomingReq.emailAddress = 'testcontact1@capgemini.com';
		incomingReq.phoneNo = '09787987911';
		incomingReq.operation = 'Create';
		incomingReq.FEIN = String.valueOf(accList[0].FEIN__c);
		incomingReq.channelID = accList[1].Azure_Id__c;
		incomingReq.address = address;
        incomingReq.appointedFlag = true;
        incomingReq.voucherCode = '865';
        incomingReq.licenses = broLicen;

		RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();

        request.requestUri = '/services/apexrest/Invsk_BrokerContact/*';
        request.httpMethod = 'POST';
		request.addHeader('Content-Type', 'application/json'); 
		request.requestBody = Blob.valueOf(JSON.serialize(incomingReq));

		RestContext.request = request;
		RestContext.response = res;


        REST_Invsk_BrokerContact.doPost();

		Test.stopTest();

		System.assert(RestContext.response.statusCode==200);
	}

	@isTest
	static void testCreateContactErrorFEIN() {
		Test.startTest();
		//Long - 05/03/2020 - remove the order by in SOQL to apply the encryption
		/*List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Account_Broker_Test_01', 'Account_Broker_Test_02')
									Order By Name ASC];*/
		List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Account_Broker_Test_01', 'Account_Broker_Test_02')];
		//End
		REST_Invsk_BrokerContact.AddressInfo address = new REST_Invsk_BrokerContact.AddressInfo();
		address.addressLine1 = 'Billing Street Test 11';
		address.city = 'HCM';
		address.state = 'WA';
		address.postalCode = '70001';
		address.country = 'US';
        
        REST_Invsk_BrokerContact.BrokerLicenses brokerlicense = new REST_Invsk_BrokerContact.BrokerLicenses();
        brokerlicense.licenseNumber = '65616';
        brokerlicense.licenseState = 'NY';
        brokerlicense.licenseType = 'Limited Lines';
        brokerlicense.brokerLicOperation = 'Create';
        brokerlicense.licenseEntity = 'Individual';
        
        List<REST_Invsk_BrokerContact.BrokerLicenses> broLicen = new List<REST_Invsk_BrokerContact.BrokerLicenses>();
        broLicen.add(brokerlicense);

		REST_Invsk_BrokerContact.CommingRequest incomingReq = new REST_Invsk_BrokerContact.CommingRequest();
		incomingReq.firstName = 'Test';
		incomingReq.lastName = 'Contact 1';
		incomingReq.emailAddress = 'testcontact1@capgemini.com';
		incomingReq.phoneNo = '09787987911';
		incomingReq.operation = 'Create';
		incomingReq.FEIN = '';
        incomingReq.appointedFlag = true;
        incomingReq.voucherCode = '865';
		incomingReq.channelID = accList[1].Azure_Id__c;
		incomingReq.address = address;
        incomingReq.licenses = broLicen;

		RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();

        request.requestUri = '/services/apexrest/Invsk_BrokerContact';
        request.httpMethod = 'POST';
		request.addHeader('Content-Type', 'application/json'); 
		request.requestBody = Blob.valueOf(JSON.serialize(incomingReq));

		RestContext.request = request;
		RestContext.response = res;


        REST_Invsk_BrokerContact.doPost();

		Test.stopTest();

		System.assert(RestContext.response.statusCode==200);
	}

	@isTest
	static void testCreateContactErrorFormatFEIN() {
		Test.startTest();
		//Long - 05/03/2020 - remove the order by in SOQL to apply the encryption
		/*List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Account_Broker_Test_01', 'Account_Broker_Test_02')
									Order By Name ASC];*/
		List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Account_Broker_Test_01', 'Account_Broker_Test_02')];
        

		//End
		REST_Invsk_BrokerContact.AddressInfo address = new REST_Invsk_BrokerContact.AddressInfo();
		address.addressLine1 = 'Billing Street Test 11';
		address.city = 'HCM';
		address.state = 'WA';
		address.postalCode = '70001';
		address.country = 'US';
        
        REST_Invsk_BrokerContact.BrokerLicenses brokerlicense = new REST_Invsk_BrokerContact.BrokerLicenses();
        brokerlicense.licenseNumber = '65616';
        brokerlicense.licenseState = 'NY';
        brokerlicense.licenseType = 'Limited Lines';
        brokerlicense.brokerLicOperation = 'Create';
        brokerlicense.licenseEntity = 'Individual';
        
        List<REST_Invsk_BrokerContact.BrokerLicenses> broLicen = new List<REST_Invsk_BrokerContact.BrokerLicenses>();
        broLicen.add(brokerlicense);

		REST_Invsk_BrokerContact.CommingRequest incomingReq = new REST_Invsk_BrokerContact.CommingRequest();
		incomingReq.firstName = 'Test';
		incomingReq.lastName = 'Contact 1';
		incomingReq.emailAddress = 'testcontact1@capgemini.com';
		incomingReq.phoneNo = '09787987911';
		incomingReq.operation = 'Create';
		incomingReq.FEIN = '123abc';
		incomingReq.channelID = accList[1].Azure_Id__c;
		incomingReq.address = address;
        incomingReq.appointedFlag = true;
        incomingReq.voucherCode = '865';
        incomingReq.licenses = broLicen;
		RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();

        request.requestUri = '/services/apexrest/Invsk_BrokerContact';
        request.httpMethod = 'POST';
		request.addHeader('Content-Type', 'application/json'); 
		request.requestBody = Blob.valueOf(JSON.serialize(incomingReq));

		RestContext.request = request;
		RestContext.response = res;


        REST_Invsk_BrokerContact.doPost();

		Test.stopTest();

		System.assert(RestContext.response.statusCode==200);
	}
    
	@isTest
	static void testUpdateContactFEIN() {
		Test.startTest();
		List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Account_Broker_Test_01', 'Account_Broker_Test_02')];
        Contact con = [Select Id,Azure_Id__c From Contact Where LastName = 'Contact_Broker_Test_01' Limit 1];
        system.debug('azure'+con.Azure_Id__c);
		//End
		REST_Invsk_BrokerContact.AddressInfo address = new REST_Invsk_BrokerContact.AddressInfo();
		address.addressLine1 = 'Billing Street Test 11';
		address.city = 'HCM';
		address.state = 'WA';
		address.postalCode = '70001';
		address.country = 'US';
        
        REST_Invsk_BrokerContact.BrokerLicenses brokerlicense = new REST_Invsk_BrokerContact.BrokerLicenses();
        brokerlicense.licenseNumber = '65616';
        brokerlicense.licenseState = 'NY';
        brokerlicense.licenseType = 'Limited Lines';
        brokerlicense.brokerLicOperation = 'Create';
        brokerlicense.licenseEntity = 'Individual';
        
        List<REST_Invsk_BrokerContact.BrokerLicenses> broLicen = new List<REST_Invsk_BrokerContact.BrokerLicenses>();
        broLicen.add(brokerlicense);

		REST_Invsk_BrokerContact.CommingRequest incomingReq = new REST_Invsk_BrokerContact.CommingRequest();
		incomingReq.firstName = 'Test';
		incomingReq.lastName = 'Contact 1';
		incomingReq.emailAddress = 'testcontact1@capgemini.com';
		incomingReq.phoneNo = '09787987911';
		incomingReq.operation = 'Update';
		incomingReq.FEIN = '123abc';
        incomingReq.contactAzureId = con.Azure_ID__c;
		incomingReq.channelID = accList[1].Azure_Id__c;
		incomingReq.address = address;
        incomingReq.appointedFlag = true;
        incomingReq.voucherCode = '865';
        incomingReq.licenses = broLicen;
		RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();

        request.requestUri = '/services/apexrest/Invsk_BrokerContact';
        request.httpMethod = 'POST';
		request.addHeader('Content-Type', 'application/json'); 
		request.requestBody = Blob.valueOf(JSON.serialize(incomingReq));

		RestContext.request = request;
		RestContext.response = res;


        REST_Invsk_BrokerContact.doPost();

		Test.stopTest();

		System.assert(RestContext.response.statusCode==200);
	}


	@isTest
	static void testCreateContactErrorNotExistFEIN() {
		Test.startTest();
		//Long - 05/03/2020 - remove the order by in SOQL to apply the encryption
		/*List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Account_Broker_Test_01', 'Account_Broker_Test_02')
									Order By Name ASC];*/
		List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Account_Broker_Test_01', 'Account_Broker_Test_02')];
		//End
		REST_Invsk_BrokerContact.AddressInfo address = new REST_Invsk_BrokerContact.AddressInfo();
		address.addressLine1 = 'Billing Street Test 11';
		address.city = 'HCM';
		address.state = 'WA';
		address.postalCode = '70001';
		address.country = 'US';
        
        REST_Invsk_BrokerContact.BrokerLicenses brokerlicense = new REST_Invsk_BrokerContact.BrokerLicenses();
        brokerlicense.licenseNumber = '65616';
        brokerlicense.licenseState = 'NY';
        brokerlicense.licenseType = 'Limited Lines';
        brokerlicense.brokerLicOperation = 'Create';
        brokerlicense.licenseEntity = 'Individual';
        
        List<REST_Invsk_BrokerContact.BrokerLicenses> broLicen = new List<REST_Invsk_BrokerContact.BrokerLicenses>();
        broLicen.add(brokerlicense);

		REST_Invsk_BrokerContact.CommingRequest incomingReq = new REST_Invsk_BrokerContact.CommingRequest();
		incomingReq.firstName = 'Test';
		incomingReq.lastName = 'Contact 1';
		incomingReq.emailAddress = 'testcontact1@capgemini.com';
		incomingReq.phoneNo = '09787987911';
		incomingReq.operation = 'Create';
		incomingReq.FEIN = '1233333';
		incomingReq.channelID = accList[1].Azure_Id__c;
		incomingReq.address = address;
        incomingReq.licenses = broLicen;
        incomingReq.appointedFlag = true;
        incomingReq.voucherCode = '865';
        
		RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();

        request.requestUri = '/services/apexrest/Invsk_BrokerContact';
        request.httpMethod = 'POST';
		request.addHeader('Content-Type', 'application/json'); 
		request.requestBody = Blob.valueOf(JSON.serialize(incomingReq));

		RestContext.request = request;
		RestContext.response = res;


        REST_Invsk_BrokerContact.doPost();

		Test.stopTest();

		System.assert(RestContext.response.statusCode==200);
	}

	@isTest
	static void testMethod1() {
		Test.startTest();
		//Long - 05/03/2020 - remove the compound field in SOQL to apply the encryption
		//Contact con = [Select Id,Azure_Id__c From Contact Where Name = 'Contact_Broker_Test_01' Limit 1];
		Contact con = [Select Id,Azure_Id__c From Contact Where LastName = 'Contact_Broker_Test_01' Limit 1];
		//End
		
		List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Account_Broker_Test_01', 'Account_Broker_Test_02')];
		
		REST_Invsk_BrokerContact.AddressInfo address = new REST_Invsk_BrokerContact.AddressInfo();
		address.addressLine1 = 'Billing Street Test 11';
		address.city = 'HCM';
		address.state = 'WA';
		address.postalCode = '70001';
		address.country = 'US';
        
        REST_Invsk_BrokerContact.BrokerLicenses brokerlicense = new REST_Invsk_BrokerContact.BrokerLicenses();
        brokerlicense.licenseNumber = '65616';
        brokerlicense.licenseState = 'NY';
        brokerlicense.licenseType = 'Limited Lines';
        brokerlicense.brokerLicOperation = 'Create';
        brokerlicense.licenseEntity = 'Individual';
        
        List<REST_Invsk_BrokerContact.BrokerLicenses> broLicen = new List<REST_Invsk_BrokerContact.BrokerLicenses>();
        broLicen.add(brokerlicense);

		REST_Invsk_BrokerContact.CommingRequest incomingReq = new REST_Invsk_BrokerContact.CommingRequest();
		incomingReq.firstName = 'Test';
		incomingReq.lastName = 'Contact update 1';
		incomingReq.emailAddress = 'updatecontact1@capgemini.com';
		incomingReq.phoneNo = '09787987912';
		incomingReq.operation = 'Update';
		incomingReq.contactAzureId = accList[0].Id;
		incomingReq.address = address;        
        incomingReq.licenses = broLicen;
        incomingReq.appointedFlag = true;
        incomingReq.voucherCode = '865';
        
        
		RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();

        request.requestUri = '/services/apexrest/Invsk_BrokerContact';
        request.httpMethod = 'POST';
		request.addHeader('Content-Type', 'application/json'); 
		request.requestBody = Blob.valueOf(JSON.serialize(incomingReq));

		RestContext.request = request;
		RestContext.response = res;

        REST_Invsk_BrokerContact.doPost();

		Test.stopTest();

		System.assert(RestContext.response.statusCode==200);
	}

	@isTest
	static void testUpdateContactError() {
		Test.startTest();
		//Contact con = [Select Id,Azure_Id__c From Contact Where Name = 'Contact_Broker_Test_01' Limit 1];
		//Long - 05/03/2020 - remove the order by in SOQL to apply the encryption
		/*List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Account_Broker_Test_01', 'Account_Broker_Test_02')
									Order By Name ASC];*/
		List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account];
									//Where Name IN ('Account_Broker_Test_01', 'Account_Broker_Test_02')];
		//End
		
		REST_Invsk_BrokerContact.AddressInfo address = new REST_Invsk_BrokerContact.AddressInfo();
		address.addressLine1 = 'Billing Street Test 11';
		address.city = 'HCM';
		address.state = 'WA';
		address.postalCode = '70001';
		address.country = 'US';
        
        REST_Invsk_BrokerContact.BrokerLicenses brokerlicense = new REST_Invsk_BrokerContact.BrokerLicenses();
        brokerlicense.licenseNumber = '';
        brokerlicense.licenseState = '';
        brokerlicense.licenseType = 'Limited Lines';
        brokerlicense.brokerLicOperation = 'Delete';
        brokerlicense.licenseEntity = 'Individual';
        
        List<REST_Invsk_BrokerContact.BrokerLicenses> broLicen = new List<REST_Invsk_BrokerContact.BrokerLicenses>();
        broLicen.add(brokerlicense);

		REST_Invsk_BrokerContact.CommingRequest incomingReq = new REST_Invsk_BrokerContact.CommingRequest();
		incomingReq.firstName = 'Test';
		incomingReq.lastName = 'Contact update 1';
		incomingReq.emailAddress = 'updatecontact1@capgemini.com';
		incomingReq.phoneNo = '09787987912';
		incomingReq.operation = 'test';
		incomingReq.contactAzureId = 'Azure not exist';
		incomingReq.address = address;
        incomingReq.licenses = broLicen;
		RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();

        request.requestUri = '/services/apexrest/Invsk_BrokerContact';
        request.httpMethod = 'POST';
		request.addHeader('Content-Type', 'application/json'); 
		request.requestBody = Blob.valueOf(JSON.serialize('incomingReq'));//bad value

		RestContext.request = request;
		RestContext.response = res;

        REST_Invsk_BrokerContact.doPost();

		Test.stopTest();

		System.assert(true, RestContext.response.statusCode!=null);
	}
    
    @isTest
	static void testUpdateContact() {
        Contact con = [Select Id,Azure_Id__c From Contact Where LastName = 'Contact_Broker_Test_01' Limit 1];
		List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account];
									//Where Name IN ('Account_Broker_Test_01', 'Account_Broker_Test_02')];
        for(Account acc: accList){
            acc.FEIN__c = 99999.0;
        }
        update accList;
		Test.startTest();
		
        
		REST_Invsk_BrokerContact.AddressInfo address = new REST_Invsk_BrokerContact.AddressInfo();
		address.addressLine1 = 'Billing Street Test 11';
		address.city = 'HCM';
		address.state = 'WA';
		address.postalCode = '70001';
		address.country = 'US';
        
        REST_Invsk_BrokerContact.BrokerLicenses brokerlicense = new REST_Invsk_BrokerContact.BrokerLicenses();
        brokerlicense.licenseNumber = '65616';
        brokerlicense.licenseState = 'NY15241f';
        brokerlicense.licenseType = 'Limited Lines';
        brokerlicense.brokerLicOperation = 'Create';
        brokerlicense.licenseEntity = 'Individual';
        
       List<REST_Invsk_BrokerContact.BrokerLicenses> broLicen = new List<REST_Invsk_BrokerContact.BrokerLicenses>();
        broLicen.add(brokerlicense);

		REST_Invsk_BrokerContact.CommingRequest incomingReq = new REST_Invsk_BrokerContact.CommingRequest();
		incomingReq.firstName = 'Test';
		incomingReq.lastName = 'Contact 1';
		incomingReq.emailAddress = 'testcontact1@capgemini.com';
		incomingReq.phoneNo = '09787987911';
		incomingReq.operation = 'Update';
		//incomingReq.FEIN = String.valueOf(accList[0].FEIN__c);
		incomingReq.FEIN = String.valueOf(1233);
		incomingReq.channelID = accList[1].Azure_Id__c;
        incomingReq.contactAzureId = con.Azure_ID__c;
        incomingReq.appointedFlag = true;
        incomingReq.voucherCode = '865';
		incomingReq.address = address;  
        incomingReq.licenses = broLicen;
      
		// Clone success
		RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();

        request.requestUri = '/services/apexrest/Invsk_BrokerContact';
        request.httpMethod = 'POST';
		request.addHeader('Content-Type', 'application/json'); 
		request.requestBody = Blob.valueOf(JSON.serialize(incomingReq));

		RestContext.request = request;
		RestContext.response = res;


        REST_Invsk_BrokerContact.doPost();

		Test.stopTest();

		System.assert(RestContext.response.statusCode==200);
	}
    
    	@isTest
	static void testCreateContact3() {
		Test.startTest();
		//Long - 05/03/2020 - remove the order by in SOQL to apply the encryption
		/*
		List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Account_Broker_Test_01', 'Account_Broker_Test_02')
									Order By Name ASC];
		
		*/
		List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Account_Broker_Test_01', 'Account_Broker_Test_02')];
		//End
		REST_Invsk_BrokerContact.AddressInfo address = new REST_Invsk_BrokerContact.AddressInfo();
		address.addressLine1 = 'Billing Street Test 11';
		address.city = 'HCM';
		address.state = 'WA';
		address.postalCode = '70001';
		address.country = 'US';
        
        REST_Invsk_BrokerContact.BrokerLicenses brokerlicense = new REST_Invsk_BrokerContact.BrokerLicenses();
        brokerlicense.licenseNumber = '';
        brokerlicense.licenseState = '';
        brokerlicense.licenseType = 'Limited Lines';
        brokerlicense.brokerLicOperation = 'Create';
        brokerlicense.licenseEntity = 'Individual';
        
       List<REST_Invsk_BrokerContact.BrokerLicenses> broLicen = new List<REST_Invsk_BrokerContact.BrokerLicenses>();
        broLicen.add(brokerlicense);

		REST_Invsk_BrokerContact.CommingRequest incomingReq = new REST_Invsk_BrokerContact.CommingRequest();
		incomingReq.firstName = 'Test';
		incomingReq.lastName = 'Contact 1';
		incomingReq.emailAddress = 'testcontact1@capgemini.com';
		incomingReq.phoneNo = '09787987911';
		incomingReq.operation = 'Create';
		incomingReq.FEIN = String.valueOf(accList[0].FEIN__c);
		incomingReq.channelID = accList[1].Azure_Id__c;
        incomingReq.appointedFlag = true;
        incomingReq.voucherCode = '865';
		incomingReq.address = address;  
        incomingReq.licenses = broLicen;
      
		// Clone success
		RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();

        request.requestUri = '/services/apexrest/Invsk_BrokerContact';
        request.httpMethod = 'POST';
		request.addHeader('Content-Type', 'application/json'); 
		request.requestBody = Blob.valueOf(JSON.serialize(incomingReq));

		RestContext.request = request;
		RestContext.response = res;


        REST_Invsk_BrokerContact.doPost();

		Test.stopTest();

		System.assert(RestContext.response.statusCode==200);
	} 
    
    	@isTest
	static void testCreateContactAnonymousPortalex() {
		Test.startTest();
		//Long - 05/03/2020 - remove the order by in SOQL to apply the encryption
		/*List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Anonymous Portal Broker')
									Order By Name ASC];*/
		List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Anonymous Portal Broker')];
		//End

		REST_Invsk_BrokerContact.AddressInfo address = new REST_Invsk_BrokerContact.AddressInfo();
		address.addressLine1 = 'Billing Street Test 11';
		address.city = 'HCM';
		address.state = 'WA';
		address.postalCode = '70001';
		address.country = 'US';
        address.county = 'US';
        
        REST_Invsk_BrokerContact.BrokerLicenses brokerlicense = new REST_Invsk_BrokerContact.BrokerLicenses();
        brokerlicense.licenseNumber = '65616';
        brokerlicense.licenseState = 'NY';
        brokerlicense.licenseType = 'Limited Lines';
        brokerlicense.brokerLicOperation = 'Create';
        brokerlicense.licenseEntity = 'Individual';
        
        List<REST_Invsk_BrokerContact.BrokerLicenses> broLicen = new List<REST_Invsk_BrokerContact.BrokerLicenses>();
        broLicen.add(brokerlicense);       


		Account accBrokerAnonymous = [SELECT Id, Name FROM Account WHERE Name = 'Anonymous Portal Broker' LIMIT 1];
		//Long - 05/03/2020 - remove the compound field in SOQL to apply the encryption
		//Contact contactBroker = [SELECT Id FROM Contact WHERE Name = 'Contact_Broker_Test_01' LIMIT 1];
		Contact contactBroker = [SELECT Id FROM Contact WHERE LastName = 'Contact_Broker_Test_01' LIMIT 1];
		//End
		contactBroker.LastName = 'Anonymous Portal Broker';
		contactBroker.Email = 'newapi5@capgemini.com';
       
		contactBroker.AccountId = accBrokerAnonymous.Id;
		update contactBroker;

		REST_Invsk_BrokerContact.CommingRequest incomingReq = new REST_Invsk_BrokerContact.CommingRequest();
		incomingReq.firstName = 'New';
		incomingReq.lastName = 'API 5';		
		incomingReq.emailAddress = 'newapi5@capgemini.com';
		incomingReq.phoneNo = '0978798798915';
		incomingReq.operation = 'Create';
		incomingReq.FEIN = String.valueOf(accList[0].FEIN__c);
		incomingReq.channelID = accList[0].Azure_Id__c;
        incomingReq.contactAzureId = accList[0].Azure_Id__c;
		incomingReq.address = address;
        incomingReq.appointedFlag = true;
        incomingReq.voucherCode = '865';
        incomingReq.licenses = broLicen;

		// Clone success
		RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();

        request.requestURI = '/services/apexrest/Invsk_BrokerContact/*';
        request.httpMethod = 'POST';
		request.addHeader('Content-Type', 'application/json'); 
		request.requestBody = Blob.valueOf(JSON.serialize(incomingReq));

		RestContext.request = request;
		RestContext.response = res;


        REST_Invsk_BrokerContact.doPost();

		Test.stopTest();

		System.assert(RestContext.response.statusCode==200);
	}
    
        @isTest
	static void testUpdateContactex1() {
		Test.startTest();
		//Long - 05/03/2020 - remove the order by in SOQL to apply the encryption
		/*
		List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Account_Broker_Test_01', 'Account_Broker_Test_02')
									Order By Name ASC];
		
		*/
        Contact con = [Select Id,Azure_Id__c From Contact Where LastName = 'Contact_Broker_Test_01' Limit 1];
        con.LastName = 'Anonymous Portal Broker';
        update con;
		List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Account_Broker_Test_01', 'Account_Broker_Test_02')];
		//End
		REST_Invsk_BrokerContact.AddressInfo address = new REST_Invsk_BrokerContact.AddressInfo();
		address.addressLine1 = 'Billing Street Test 11';
		address.city = 'HCM';
		address.state = 'WA';
		address.postalCode = '70001';
		address.country = 'US';
        
        REST_Invsk_BrokerContact.BrokerLicenses brokerlicense = new REST_Invsk_BrokerContact.BrokerLicenses();
        brokerlicense.licenseNumber = '';
        brokerlicense.licenseState = '';
        brokerlicense.licenseType = 'Limited Lines';
        brokerlicense.brokerLicOperation = 'Create';
        brokerlicense.licenseEntity = 'Individual';
        
       List<REST_Invsk_BrokerContact.BrokerLicenses> broLicen = new List<REST_Invsk_BrokerContact.BrokerLicenses>();
        broLicen.add(brokerlicense);

		REST_Invsk_BrokerContact.CommingRequest incomingReq = new REST_Invsk_BrokerContact.CommingRequest();
		incomingReq.firstName = 'Test';
		incomingReq.lastName = 'Contact 1';
		incomingReq.emailAddress = 'testcontact1@capgemini.com';
		incomingReq.phoneNo = '09787987911';
		incomingReq.operation = 'Update';
		incomingReq.FEIN = '';
		incomingReq.channelID = accList[1].Azure_Id__c;
        incomingReq.contactAzureId = con.Azure_ID__c;
        incomingReq.appointedFlag = true;
        incomingReq.voucherCode = '865';
		incomingReq.address = address;  
        incomingReq.licenses = broLicen;
      
		// Clone success
		RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();

        request.requestUri = '/services/apexrest/Invsk_BrokerContact';
        request.httpMethod = 'POST';
		request.addHeader('Content-Type', 'application/json'); 
		request.requestBody = Blob.valueOf(JSON.serialize(incomingReq));

		RestContext.request = request;
		RestContext.response = res;


        REST_Invsk_BrokerContact.doPost();

		Test.stopTest();

		System.assert(RestContext.response.statusCode==200);
	}
    

    @isTest static void testbrokerLicenseException() {
		
		Test.startTest();
		
        Contact con = [Select Id,Azure_Id__c From Contact Where LastName = 'Contact_Broker_Test_01' Limit 1];
		List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Account_Broker_Test_01', 'Account_Broker_Test_02')];
		//End
		REST_Invsk_BrokerContact.AddressInfo address = new REST_Invsk_BrokerContact.AddressInfo();
		address.addressLine1 = 'Billing Street Test 11';
		address.city = 'HCM';
		address.state = 'WA';
		address.postalCode = '70001';
		address.country = 'US';
        
        REST_Invsk_BrokerContact.BrokerLicenses brokerlicense = new REST_Invsk_BrokerContact.BrokerLicenses();
        brokerlicense.licenseNumber = '65616';
        brokerlicense.licenseState = 'NYtest';
        brokerlicense.licenseType = 'Limited Lines';
        brokerlicense.brokerLicOperation = 'Create';
        brokerlicense.licenseEntity = 'Individual';
        
        REST_Invsk_BrokerContact.BrokerLicenses brokerlicense2 = new REST_Invsk_BrokerContact.BrokerLicenses();
        brokerlicense2.licenseNumber = '';
        brokerlicense2.licenseState = 'Cal';
        brokerlicense2.licenseType = 'Limited Lines';
        brokerlicense2.brokerLicOperation = 'Update';
        brokerlicense2.licenseEntity = 'Individual';
        
       List<REST_Invsk_BrokerContact.BrokerLicenses> broLicen = new List<REST_Invsk_BrokerContact.BrokerLicenses>();
        broLicen.add(brokerlicense);
        broLicen.add(brokerlicense2);

		REST_Invsk_BrokerContact.CommingRequest incomingReq = new REST_Invsk_BrokerContact.CommingRequest();
		incomingReq.firstName = 'Test';
		incomingReq.lastName = 'Contact 1';
		incomingReq.emailAddress = 'testcontact1@capgemini.com';
		incomingReq.phoneNo = '9787987911';
		incomingReq.operation = 'Update';
		incomingReq.FEIN = String.valueOf(accList[0].FEIN__c);
		incomingReq.channelID = accList[1].Azure_Id__c;
        incomingReq.contactAzureId = con.Azure_ID__c;
        incomingReq.appointedFlag = true;
        incomingReq.voucherCode = '865';
		incomingReq.address = address;  
        incomingReq.licenses = broLicen;
      
		// Clone success
		RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();

        request.requestUri = '/services/apexrest/Invsk_BrokerContact';
        request.httpMethod = 'POST';
		request.addHeader('Content-Type', 'application/json'); 
		request.requestBody = Blob.valueOf(JSON.serialize(incomingReq));

		RestContext.request = request;
		RestContext.response = res;


        REST_Invsk_BrokerContact.doPost();

		Test.stopTest();

		System.assert(RestContext.response.statusCode==200);

        }
     @isTest static void testbrokerLicenseBlankException() {
		
		Test.startTest();
		
        Contact con = [Select Id,Azure_Id__c From Contact Where LastName = 'Contact_Broker_Test_01' Limit 1];
		List<Account> accList = [Select Id,FEIN__c, Azure_Id__c From Account 
									Where Name IN ('Account_Broker_Test_01', 'Account_Broker_Test_02')];
		//End
		REST_Invsk_BrokerContact.AddressInfo address = new REST_Invsk_BrokerContact.AddressInfo();
		address.addressLine1 = 'Billing Street Test 11';
		address.city = 'HCM';
		address.state = 'WA';
		address.postalCode = '70001';
		address.country = 'US';
        
        REST_Invsk_BrokerContact.BrokerLicenses brokerlicense = new REST_Invsk_BrokerContact.BrokerLicenses();
        brokerlicense.licenseNumber = '';
        brokerlicense.licenseState = '';
        brokerlicense.licenseType = 'Limited Lines';
        brokerlicense.brokerLicOperation = '';
        brokerlicense.licenseEntity = 'Individual';
        
       List<REST_Invsk_BrokerContact.BrokerLicenses> broLicen = new List<REST_Invsk_BrokerContact.BrokerLicenses>();
        broLicen.add(brokerlicense);

		REST_Invsk_BrokerContact.CommingRequest incomingReq = new REST_Invsk_BrokerContact.CommingRequest();
		incomingReq.firstName = 'Test';
		incomingReq.lastName = 'Contact 1';
		incomingReq.emailAddress = 'testcontact1@capgemini.com';
		incomingReq.phoneNo = '09787987911';
		incomingReq.operation = 'Update';
		incomingReq.FEIN = String.valueOf(accList[0].FEIN__c);
		incomingReq.channelID = accList[1].Azure_Id__c;
        incomingReq.contactAzureId = con.Azure_ID__c;
        incomingReq.appointedFlag = true;
        incomingReq.voucherCode = '865';
		incomingReq.address = address;  
        incomingReq.licenses = broLicen;
      
		// Clone success
		RestRequest request = new RestRequest();
		RestResponse res = new RestResponse();

        request.requestUri = '/services/apexrest/Invsk_BrokerContact';
        request.httpMethod = 'POST';
		request.addHeader('Content-Type', 'application/json'); 
		request.requestBody = Blob.valueOf(JSON.serialize(incomingReq));

		RestContext.request = request;
		RestContext.response = res;


        REST_Invsk_BrokerContact.doPost();

		Test.stopTest();

		System.assert(RestContext.response.statusCode==200);

        }
}