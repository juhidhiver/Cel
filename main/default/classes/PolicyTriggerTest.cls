@isTest
public class PolicyTriggerTest {
	@testSetup
    public static void setup() {
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
		setting.BypassBrokerAccountTrigger__c = false;
        setting.BypassContactTrigger__c = true;
		update setting;

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
        
        Product2 product = TestUtil.createProduct('MPL Standalone');
		insert product; 
           
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc1.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Prospect';
        insert opp;
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'Bound';
        quote1.Rating_Status__c = 'Clear';
        quote1.Quote_Type__c = 'New Business';
     
        insert quote1; 

    }
    
    @isTest
    public static void testMethod1() {
        Account acc1 = [SELECT id FROM Account LIMIT 1];
         
        Policy_Incremental_Setting__c pInSet = new Policy_Incremental_Setting__c();
        pInSet.Name = 'Test PIS';
        pInSet.Product_Name__c = 'MPL';
        pInSet.Policy_Format__c = '5DA3PL{0}';
        pInSet.Start_Number__c = '0000050';
        pInSet.End_Number__c = '0000998';
        pInSet.Active__c = true;
        pInSet.Suffix__c = '00';
        pInSet.Spacing__c = '-';
        insert pInSet;
        
        // create policy  
        Policy__c policy = new Policy__c();
        	policy.Account__c = acc1.Id;
        	policy.Product_Name__c = 'MPL';
        	policy.Expiration_Date__c = Date.today().addDays(100);
        	policy.Total_Premium__c = 2000;
        	policy.Initial_Premium__c = null;
        insert policy;
        
        // rinku saini
        // create policy  
        Policy__c policy1 = new Policy__c();
        policy1.Account__c = acc1.Id;
        policy1.Product_Name__c = 'MPL';
        policy1.Expiration_Date__c = Date.today().addDays(100);
        policy1.Total_Premium__c = 2000;
        policy1.Initial_Premium__c = null;
        policy1.RecordTypeId = Schema.SObjectType.Policy__c.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
        insert policy1;
        update policy1;
        
        System.assert(policy.Policy_Number__c == null);
    }
    
    @isTest
    public static void testMethod2() {
        Account acc1 = [SELECT id FROM Account LIMIT 1];
         
        Policy_Incremental_Setting__c pInSet2 = new Policy_Incremental_Setting__c();
        pInSet2.Name = 'Cyber Standalone';
        pInSet2.Product_Name__c = 'Cyber Standalone';
        pInSet2.Policy_Format__c = '5DA3PL{0}';
        pInSet2.Start_Number__c = '0000050';
        pInSet2.End_Number__c = '0000998';
        pInSet2.Active__c = true;
        pInSet2.Suffix__c = '00';
        pInSet2.Spacing__c = '-';
        insert pInSet2;
        
        Policy_Incremental_Setting__c pInSet = new Policy_Incremental_Setting__c();
        pInSet.Name = 'Excess';
        pInSet.Product_Name__c = 'Excess';
        pInSet.Policy_Format__c = '5DA3FF{0}';
        pInSet.Start_Number__c = '0000050';
        pInSet.End_Number__c = '0000998';
        pInSet.Active__c = true;
        pInSet.Suffix__c = '00';
        pInSet.Spacing__c = '-';
        insert pInSet;
        update pInSet;
        Policy__c policy1 = new Policy__c();
        policy1.Account__c = acc1.Id;
        policy1.Product_Name__c = 'Cyber Standalone';
        policy1.Expiration_Date__c = Date.today().addDays(90);
        policy1.Total_Premium__c = 3200;
        policy1.Layer__c = 'Excess';
        insert policy1;
        
        update policy1;
        
        Policy__c policy2 = new Policy__c();
        policy2.Account__c = acc1.Id;
        policy2.Product_Name__c = 'Cyber Standalone';
        policy2.Expiration_Date__c = Date.today().addDays(90);
        policy2.Total_Premium__c = 3200;
        policy2.Layer__c = 'Excess';
        policy2.Policy_Number__c = '5DA3FF0000039-00';
        insert policy2;
        System.assert(policy2.Policy_Number__c != null);
    }
    
    @isTest
    public static void testMethod3() {
        Account acc1 = [SELECT id FROM Account LIMIT 1];
         
        Policy_Incremental_Setting__c pInSet = new Policy_Incremental_Setting__c();
        pInSet.Name = 'Test PIS';
        pInSet.Product_Name__c = 'MPL';
        pInSet.Policy_Format__c = '5DA3PL{0}';
        pInSet.Start_Number__c = '0000050';
        pInSet.End_Number__c = '0000998';
        pInSet.Active__c = true;
        pInSet.Suffix__c = '00';
        pInSet.Spacing__c = '-';
        insert pInSet;
        
        // create policy  
        Policy__c policy = new Policy__c();
        	policy.Account__c = acc1.Id;
        	policy.Policy_Number__c = '5DA3PL27-00';
        	policy.Product_Name__c = 'MPL';
        	policy.Expiration_Date__c = Date.today().addDays(100);
        	policy.Total_Premium__c = 2000;
        	policy.Initial_Premium__c = null;
        insert policy;
        
        Quote q = [Select Id From Quote];
        q.Policy__c = policy.Id;
        update q;
        
        policy.Binding_License_Number__c = '1234';
        update policy;
        
        System.assert(policy.Policy_Number__c != null);
        
    }
}