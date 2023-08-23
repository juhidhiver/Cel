/**************************************************************************************************
 * Class Name: ContactTriggerHandlerTest
 * Author: Hoang Bui
 * Date: 21-Oct-2019
 * Description: ContactTriggerHandlerTest Test
 **************************************************************************************************/
@isTest
private class ContactTriggerHandlerTest {
   @testSetup static void setup(){
    	TriggerSettings__c setting = TestUtil.initialTriggerSetting();
		setting.BypassContactTrigger__c = false;
        setting.BypassOpportunityTrigger__c = true;
        setting.BypassAccountTrigger__c = true;
        setting.BypassProductTrigger__c = true;
        setting.BypassQuoteTrigger__c  = true;
        update setting;
       
        
       /*
        
       System.debug('Renewal'+ rn);
       
        con.LastName = 'Test2 Broker';
        update con;
       
        Contact con3 = new Contact(
            Lastname = 'Test broker3',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
        );
        insert con3;
        con3.Role__c = 'Renewals';
        update con3;
        con3.Role__c = '';
       	update con3;*/

    }

    @isTest
	static void testCreateAndUpdateAccountContact() {
        Id recordTypeBrokerAgency = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Id recordTypeContactAgency = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        List<String> contactIds = new List<String>();
		Account accBroker = TestUtil.createBusinessAccount('Broker Account Test', 'Broker_Account', '625, South Mill Road', 'Anycity', 'New York', '67074', 'United States');
		accBroker.RecordTypeId = recordTypeBrokerAgency;
		
        insert accBroker;
        
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
		opp.Coverage_Product_Options__c = 'D&O';
		opp.AccountId = accBroker.Id;
		opp.Pricebook2Id = Test.getStandardPricebookId();
		opp.Product__c = prd.Id;
		opp.Received_Date__c = Date.today();
		opp.CloseDate = Date.today().addDays(30);
		opp.Effective_Date__c = Date.today();
		opp.Type = 'New Business';
		opp.LeadSource = 'Email';
		opp.StageName = 'New';
		insert opp;

        // Create Contact Broker
        Contact contactBroker = TestUtil.createContact(accBroker.Id, 'Broker_Contact', 'New broker contact');
		contactBroker.RecordTypeId = recordTypeContactAgency;
		contactBroker.Home_License_no__c ='123456';
        contactBroker.Email = 'Test@test.com';
		Test.startTest();
		insert contactBroker;
               
        
         // Create broker
		Broker_Account__c brokerAccount = new Broker_Account__c(
			Broker_Contact__c = contactBroker.Id,
			Opportunity__c = opp.Id,
			IsPrimaryBroker__c = true,
			Relationship_Type__c = 'Broker'
		);
		insert brokerAccount;

		contactBroker.LastName = 'New update Name';
		contactBroker.Home_License_no__c ='0123456';
        contactBroker.Email = 'Test2@test.com';
		update contactBroker;
		Test.stopTest();
        
       

		List<Contact> contacts = [Select Id From Contact];
		system.assertEquals(false, contacts.isEmpty());
	}

	@isTest
	static void testCreateUpdateBusinessContact() {
        Id recordTypeBrokerAgency = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Id recordTypeContactAgency = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        List<String> contactIds = new List<String>();
		Account accBroker = TestUtil.createBusinessAccount('Broker Account Test', 'Broker_Account', '625, South Mill Road', 'Anycity', 'New York', '67074', 'United States');
		accBroker.RecordTypeId = recordTypeBrokerAgency;
        insert accBroker;

        // Create Contact Broker
        Contact contactBroker = TestUtil.createContact(accBroker.Id, 'Broker_Contact', 'New broker contact');
		contactBroker.RecordTypeId = recordTypeContactAgency;
		contactBroker.Home_License_no__c ='123456';
        contactBroker.Email = 'Test@test.com';

		Test.startTest();
		insert contactBroker;

		contactBroker.Email = 'test@test2.com';
		update contactBroker;
		Test.stopTest();
	}	

	@isTest
	static void testCreateUpdateOtherContact() {
        Id recordTypeBrokerAgency = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Id recordTypeContactAgency = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Attorney').getRecordTypeId();
        List<String> contactIds = new List<String>();
		Account accBroker = TestUtil.createBusinessAccount('Broker Account Test', 'Broker_Account', '625, South Mill Road', 'Anycity', 'New York', '67074', 'United States');
		accBroker.RecordTypeId = recordTypeBrokerAgency;
        insert accBroker;

        // Create Contact Broker
        Contact contactBroker = TestUtil.createContact(accBroker.Id, 'Broker_Contact', 'New broker contact');
		contactBroker.RecordTypeId = recordTypeContactAgency;
		contactBroker.Home_License_no__c ='123456';
        contactBroker.Email = 'Test@test.com';

		Test.startTest();
		insert contactBroker;

		contactBroker.Email = 'test@test2.com';
		update contactBroker;
		Test.stopTest();
	}
    
   @istest 
    public static void updateNoRecipientOnAutoRenewalsTest()
    {
   		list<Contact> conList = new list<Contact>();
        List<Policy__c> policyList = new List<Policy__c>();
        List<Quote> quoteList = new List<Quote>();
       
        Id recordTypeIdBrokerAcc = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Account brokeracc  =TestUtil.createAccount('Test account 1', recordTypeIdBrokerAcc, '01 Tran Duy Hung','Westminster',
                                             'California','90000', 'United States');
         insert brokeracc;
        
        Id recordTypeIdBusiness = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account businessacc  =TestUtil.createAccount('Test account business', recordTypeIdBusiness, '01 Tran Duy Hung','Westminster',
                                             'California','90000', 'United States');
         insert businessacc;
        
        // Create contact 
        Contact con = new Contact();
        con.Lastname = 'Test broker';
        con.Role__c = 'Renewals';
        con.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        con.AccountId = brokeracc.id;
        conList.add(con);
        
        Contact con1 = new Contact();
        con1.Lastname = 'Test broker1';
        con1.Role__c = 'Renewals';
        con1.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        con1.AccountId = brokeracc.id;
        conList.add(con1);
        
         Contact norenewalContact = new Contact();
        norenewalContact.Lastname = 'Test broker2';
        norenewalContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        norenewalContact.AccountId = brokeracc.id;
        conList.add(norenewalContact);
        insert conList;
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 productaq = TestUtil.createProduct('Professional Indemnity');
       productaq.RecordTypeId = aqueousRecordTypeId; 
      productaq.Innovisk_Entity_ID__c = 'Aqueous';
       
        insert productaq; 
        
        Opportunity oppaq = TestUtil.createOpportunity('Opp Test',brokeracc.Id, productaq.Id);
        oppaq.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        oppaq.AccountId = brokeracc.Id;
        oppaq.StageName = 'Qualified'; 
        oppaq.Innovisk_Entity_ID__c = 'Aqueous';                            
        oppaq.Product__c = productaq.Id;
        oppaq.Submission_Status__c = 'Quoted';
        oppaq.Transaction_Status__c = 'Active';
        oppaq.Coverage_Product_Options__c = 'Professional Indemnity';
        oppaq.Tax_Country__c = 'United Kingdom';
        insert oppaq;
        
        // Create broker
        Broker_Account__c brokersAccount = new Broker_Account__c(
            Broker_Contact__c = con1.Id,
            Opportunity__c = oppaq.Id,
            IsPrimaryBroker__c = true,
            Relationship_Type__c = 'Broker',
          Bypass_New_Broker_Validation__c = true
        );
        insert brokersAccount;
         
        Policy__c policy = new Policy__c();
        policy.Account__c = brokeracc.Id;
        policy.Product_Name__c = 'Professional Indemnity';
        policy.Expiration_Date__c = Date.today().addmonths(3);
        policy.Total_Premium__c = 2000;
        policy.Initial_Premium__c = null;
        policy.Policy_Status__c = 'Bound';        	
        policyList.add(policy);
        
        Policy__c policy1 = new Policy__c();
        policy1.Account__c = brokeracc.Id;
        policy1.Product_Name__c = 'Professional Indemnity';
        policy1.Expiration_Date__c = Date.today().addmonths(3);
        policy1.Total_Premium__c = 2000;
        policy1.Initial_Premium__c = null;
        policy1.Policy_Status__c = 'Bound';
        policyList.add(policy1);
        insert policyList;
        
        
        Quote quote = TestUtil.createQuote('Quote Test',oppaq.Id);
        quote.Azure_ID__c = 'Test Az 1';
        quote.Policy__c = policy.Id;
        quote.Status = 'Bound';
        quote.Layer__c = 'Primary';
        quote.OpportunityId = oppaq.Id;
        quoteList.add(quote);
        
        Quote quote1 = TestUtil.createQuote('Quote Test1',oppaq.Id);
        quote1.Azure_ID__c = 'Testaz2';
        quote1.Policy__c = policy1.Id;
        quote1.Status = 'Bound';
        quote1.Layer__c = 'Primary';
        quote.OpportunityId = oppaq.Id;
        quoteList.add(quote1);
        insert quoteList;
   
        String RecordTypeIdREN = Schema.SObjectType.Renewal__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Renewal__c rn = new Renewal__c(
        Broker__c = brokersAccount.id,
        Policy__c = policy.Id,
        recordtypeId = RecordTypeIdREN,
        Status__c = 'Suppressed',
        No_Recipients__c = true ,
        Documents_Required__c = 'Miscellaneous Proposal Form');
    	insert rn;

       
       	//Contact c = [Select Id, Role__c from Contact where lastname = 'Test broker2' limit 1 ];
     	norenewalContact.Role__c = 'Renewals';
        update norenewalContact;
        norenewalContact.Role__c= '';
        update norenewalContact;
        norenewalContact.Role__c = 'Renewals';
        update norenewalContact;
        
        Test.startTest();
       	delete norenewalContact; 
       	test.stopTest();
      
    }
    
    
}