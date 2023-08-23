/**
 * @description       : 
 * @author            : Maeran Shaikh
 * @group             : 
 * @last modified on  : 11-12-2021
 * @last modified by  : Maeran Shaikh
**/
@isTest
private class REST_Invsk_GetBrokerProfileTest {
	
    public static Product2 product;
    public static Account acc;
	private static REST_Invsk_GetBrokerProfile.AddressInfo address;
    @TestSetup
    static void setupData(){
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
         contactBroker.Home_License_no__c = '1235';
        contactBroker.NIPR_License_flag__c = false;
        contactBroker.Phone = '1234567890';
        contactBroker.Azure_ID__c = contactBroker.Id;
        contactBroker.Type__c ='Producer';
        contactBroker.Appointed_Flag__c = false;
        update contactBroker;
    
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
           
       acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        product = TestUtil.createProduct('D&O Standalone');
        insert product;
        
         Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.Total_Revenues__c = 100;
        insert opp;
        
        Broker_Account__c newBroAccount = TestUtil.createBrokerAccount(contactBroker.Id, opp.Id);
        insert newBroAccount;

        REST_Invsk_GetBrokerProfile.ContactDetailWrapper contactWrap = new REST_Invsk_GetBrokerProfile.ContactDetailWrapper();
        contactWrap.homeLicense =contactBroker.Home_License_no__c + '';
        contactWrap.NIPRLicenseFlag =contactBroker.NIPR_License_flag__c + '';
        contactWrap.type =contactBroker.Type__c + '';
        contactWrap.contactAccountName = contactBroker.Name + '';
        contactWrap.contactId = contactBroker.Azure_ID__c + '';
        contactWrap.contactName = contactBroker.Name + '';
        contactWrap.phone = contactBroker.Phone + '';
        contactWrap.appointedFlag = contactBroker.Appointed_Flag__c + '';

        REST_Invsk_GetBrokerProfile.AddressInfo billingAddress = new REST_Invsk_GetBrokerProfile.AddressInfo();
        billingAddress.addressLine1 = accBroker1.BillingStreet;
        billingAddress.city = accBroker1.BillingCity;
        billingAddress.state = accBroker1.BillingStateCode;
        billingAddress.postalCode = accBroker1.BillingPostalCode;
        billingAddress.country = accBroker1.BillingCountryCode;

        REST_Invsk_GetBrokerProfile.AccountDetailWrapper accountDetail = new REST_Invsk_GetBrokerProfile.AccountDetailWrapper();
        accountDetail.accountName = contactBroker.Account.Name + '';
        accountDetail.fEINNumber = contactBroker.Account.FEIN__c + '';
     //   accountDetail.taxCode = contactBroker.Account.Tax_Code__c + '';
        accountDetail.description = contactBroker.Account.Description + '';
        accountDetail.website = contactBroker.Account.Website + '';
        accountDetail.phone = contactBroker.Account.Phone + '';           

        REST_Invsk_GetBrokerProfile.AddressInfo shippingAddrInfo = new REST_Invsk_GetBrokerProfile.AddressInfo();
        shippingAddrInfo.addressLine1 = accBroker1.BillingStreet;
        shippingAddrInfo.city = accBroker1.BillingCity;
        shippingAddrInfo.state = accBroker1.BillingStateCode;
        shippingAddrInfo.postalCode = accBroker1.BillingPostalCode;
        shippingAddrInfo.country = accBroker1.BillingCountryCode;

        // Id productRtId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Vindati').getRecordTypeId();
        // Product2 equipmentProduct = TestUtil.createProduct('Equipment', productRtId);
        // insert equipmentProduct;



}
    static TestMethod void testdoGet() {
        String jsontest = '{"status":"Failed","isSuccess":false,"errors":["List index out of bounds: 041"],"commission":null,"brokerContactDetails":null,"brokerAccountDetails":null}';
        Contact testContact = [Select Id,AccountId,Account.Azure_ID__c, Account.Name, Account.FEIN__c,Account.Description,//Account.Tax_Code__c,
                               Account.Phone,Account.Website,
                                            Account.BillingStateCode,Account.BillingCity,Account.BillingCountry,Account.BillingCountryCode,Account.BillingPostalCode,
                                            Account.BillingState,Account.BillingStreet,Account.Billing_County__c,
                                            Name, Email, Phone,Appointed_Flag__c, Azure_Id__c,NIPR_License_flag__c,Home_License_no__c,Type__c,
                                            MailingCity,MailingState,MailingStreet,MailingPostalCode,   MailingCountry, Mailing_County__c 
                                            From Contact LIMIT 1];
        System.debug('@@@ testContact ' +testContact);
        Product2 testPro = [Select  Id FROM Product2 LIMIT 1];
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_BrokerAgencyAccount';
        request.httpMethod = 'GET';
        request.params.put('brokerID',testContact.Id);
        request.params.put('productID', testPro.Id);
        request.requestBody = Blob.valueOf(jsontest);
        RestResponse response = new RestResponse();
        
        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        REST_Invsk_GetBrokerProfile.doGet();
        Test.stopTest();
        
        System.assertEquals(400, RestContext.response.statusCode);
    }
}