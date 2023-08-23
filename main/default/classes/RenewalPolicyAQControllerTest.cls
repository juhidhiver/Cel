/**************************************************************************************************
* Class Name: RenewalPolicyAQControllerTest
* Author: Ashik Zahir
* Created date: May 5th 2021
* Description: Controller class for RenewalPolicyAQController
**************************************************************************************************/
@isTest
public class RenewalPolicyAQControllerTest {

    @testSetup 
    static void createData(){
    	TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        setting.BypassCoverageLineItemTrigger__c = true;
        setting.BypassAccountTrigger__c = true;
        update setting;
        
        Account acc = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
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
        
        String rdPolicyId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId(); 
        Policy__c policy = new Policy__c();
        policy.Account__c = acc.Id; 
        policy.Expiration_Date__c = Date.today().addDays(10);
        policy.Policy_Number__c = '12345';
        policy.Effective_Date__c = Date.today()+5;
        policy.Policy_Status__c = 'Bound';
        policy.Renewal_Completed__c = false;
        policy.Policy_Status__c = 'Active'; 
        insert policy;
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        opp.StageName = 'Qualified'; 
        opp.CloseDate = Date.today()+10;
        opp.Innovisk_Entity_ID__c = 'Aqueous';                            
        opp.Product__c = product.Id;
        opp.Effective_Date__c = Date.today();
    	opp.Expiration_Date__c = Date.today()+10;
        opp.Received_Date__c=Date.today()-120;
        opp.Submission_Status__c = 'Quoted';
        opp.Transaction_Status__c = 'Active';
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        opp.Azure_ID__c= 'Test Id';
        opp.Policy__c=policy.Id;
        opp.Probability= 0.5;
        
		insert opp;

        //Quote
        Quote quote = TestUtil.createQuote('New Quote Test',opp.Id);
        quote.Coverage_Product_Options__c ='Professional Indemnity'; 
        quote.Status = 'Bound';
        quote.Layer__c = 'Primary';
        quote.OpportunityId = opp.Id;
        quote.Policy__c = policy.Id;
        quote.Endorsement_Effective_Date__c = System.today() + 5;
       // quote.Endorsement_Type__c='New Business' - date.parse('08/08/2021');
        insert quote;
        
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
        
        List<Master_Binder__c> lofmasterbind = new List<Master_Binder__c>();
        Master_Binder__c masterbinder =new Master_Binder__c();
        masterbinder.Layer__c = 'Primary;Excess';
        masterbinder.Name = 'Master AZ';
        masterbinder.Expiry_Date__c = Date.today()+365;
        masterbinder.Inception_Date__c = Date.today();
        masterbinder.MGA_Commission__c = 15;
        masterbinder.Coverholder_Name__c = 'AZ masterBinder Holder';
        masterbinder.Coverholder_Pin__c = 'AZ masterBinder Pin';
        masterbinder.Country__c = 'United Kingdom';
        insert masterbinder;
        lofmasterbind.add(masterbinder);
        
        quote.Master_Binder__c =  masterBinder.Id;
        update quote;
        
        Master_Binder__c masterbinder2 =new Master_Binder__c();
        //masterbinder2.Layer__c = 'Primary;Excess';
        masterbinder2.Name = 'Master AZ 2';
        masterbinder2.Expiry_Date__c = Date.today()+365;
        masterbinder2.Inception_Date__c = Date.today();
        masterbinder2.MGA_Commission__c = 15;
        masterbinder2.Coverholder_Name__c = 'AZ masterBinder Holder';
        masterbinder2.Coverholder_Pin__c = 'AZ masterBinder Pin';
        
        lofmasterbind.add(masterbinder2);
    }
    
    @isTest
    static void renewalControllerTest(){
        Test.startTest();
        
        Policy__c pol = [Select Id from Policy__c Limit 1];
        Opportunity opp = [Select Id, Name, Expiration_Date__c, Type, Received_Date__c, CloseDate, Effective_Date__c, Prior_Policy__c, Policy__c, Azure_ID__c, Probability from Opportunity Limit 1];
        List<Quote> lstOfQuotes = [Select Id, OpportunityId from Quote];
        Master_Binder__c masterbinder = [Select Id,Name,Expiry_Date__c,Inception_Date__c,MGA_Commission__c,Layer__c,Coverholder_Name__c,Coverholder_Pin__c, Country__c from Master_Binder__c  where Name = 'Master AZ' Limit 1];
      
        RenewalPolicyAQController.ResultWrapper result = RenewalPolicyAQController.renewalController(pol.Id);
        RenewalPolicyAQController.getMasterBinders(pol.Id);
        RenewalPolicyAQController.createRenewalQuote(opp.Id, pol.Id, lstOfQuotes, masterbinder.Id, masterbinder.Id);
        RenewalPolicyAQController.deleteClonedOpp(opp.Id);
        
        Test.stopTest();
        System.assert( result != null);
    }
    
    @isTest
    static void testrenewalControllerExpirydate(){
        Test.startTest();
        Policy__c pol = [Select Id,Expiration_Date__c,Renewal_Completed__c,Policy_Status__c from Policy__c Limit 1];
        
        pol.Expiration_Date__c = Date.today().addDays(-10);
        update pol;
        RenewalPolicyAQController.ResultWrapper result1 = RenewalPolicyAQController.renewalController(pol.Id);

        Test.stopTest();
        System.assert( result1 != null);
    }
    
    @isTest
    static void testrenewalControllerrenewalComplete(){
        Test.startTest();
        Policy__c pol = [Select Id,Expiration_Date__c,Renewal_Completed__c,Policy_Status__c from Policy__c Limit 1];

        pol.Renewal_Completed__c = true;
        update pol;
        RenewalPolicyAQController.ResultWrapper result2 = RenewalPolicyAQController.renewalController(pol.Id);

        Test.stopTest();
        System.assert( result2 != null);
    }
    
    @isTest
    static void testrenewalControllerstatus(){
        Test.startTest();
        
        Policy__c pol = [Select Id,Expiration_Date__c,Renewal_Completed__c,Policy_Status__c from Policy__c Limit 1];

        pol.Policy_Status__c = 'Cancelled';
        update pol; 
        RenewalPolicyAQController.ResultWrapper result2 = RenewalPolicyAQController.renewalController(pol.Id);

        Test.stopTest();
        System.assert( result2 != null);
    }
    
    @isTest
    static void testrenewalControllersubmission(){
        Test.startTest();
        Opportunity opp = [Select Id, Name, Expiration_Date__c, Type, Received_Date__c, CloseDate, Effective_Date__c, Prior_Policy__c, Policy__c, Azure_ID__c, Probability from Opportunity Limit 1];
		opp.Transaction_Status__c = 'Inactive';
        update opp;
        
        Policy__c pol = [Select Id,Expiration_Date__c,Renewal_Completed__c,Policy_Status__c from Policy__c Limit 1];

        RenewalPolicyAQController.ResultWrapper result2 = RenewalPolicyAQController.renewalController(pol.Id);

        Test.stopTest();
        System.assert( result2 != null);
    }
    
    @isTest
    static void testrenewalControllerExpiryDate2(){
        Test.startTest();
        Policy__c pol = [Select Id,Expiration_Date__c,Renewal_Completed__c,Policy_Status__c from Policy__c Limit 1];
        
        pol.Expiration_Date__c = Date.today().addDays(100);
        update pol;

        RenewalPolicyAQController.ResultWrapper result2 = RenewalPolicyAQController.renewalController(pol.Id);

        Test.stopTest();
        System.assert( result2 != null);
    }
    @isTest
    static void renewalControllerTestException(){
        Test.startTest();
        //Policy__c pol = [Select Id from Policy__c Limit 1];
        Opportunity opp = [Select Id, Name, Expiration_Date__c, Type, Received_Date__c, CloseDate, Effective_Date__c, Prior_Policy__c, Policy__c, Azure_ID__c, Probability from Opportunity Limit 1];
        List<Quote> lstOfQuotes = [Select Id, OpportunityId from Quote];
        
        List<String> listQuoteId = new List<String>{lstOfQuotes[0].Id};
        RenewalPolicyAQController.ratingQuoteRenewal(listQuoteId);
        RenewalPolicyAQController.ResultWrapper result = RenewalPolicyAQController.renewalController(opp.Id);
        //RenewalPolicyAQController.createRenewalQuote('', '', lstOfQuotes,'', '');
        RenewalPolicyAQController.ResultWrapper result2 = RenewalPolicyAQController.getMasterBinders('');
        Test.stopTest();
        System.assert(result !=null );
    }
}