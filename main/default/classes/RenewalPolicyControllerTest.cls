@isTest
public class RenewalPolicyControllerTest {
@testsetup static void testSetup(){
       TriggerSettings__c setting = TestUtil.initialTriggerSetting();
       setting.BypassQuoteTrigger__c = true;
       update setting;
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
		insert acc;
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
		insert product; 
        Policy__c pol = new Policy__c();
    	pol.Policy_Number__c = '12345';
    	pol.Effective_Date__c = Date.today()+5;
    	pol.Expiration_Date__c = Date.today() + 30;
    	pol.Policy_Status__c = 'Bound';
    	insert pol;
    
    	Policy__c pol2 = new Policy__c();
    	pol2.Policy_Number__c = '123456';
    	pol2.Effective_Date__c = Date.today()+5;
    	pol2.Expiration_Date__c = Date.today() + 30;
    	pol2.Policy_Status__c = 'Bound';
    	insert pol2;
    
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
    	opp.Name = 'Test Opportunity';
        opp.CloseDate = Date.today()+10;
        opp.StageName = 'New';
    	opp.Effective_Date__c = Date.today();
    	opp.Expiration_Date__c = Date.today()+10;
        opp.Received_Date__c=Date.today()-120;
         opp.Prior_Policy__c=pol.id;
         opp.Policy__c=pol2.Id;
         opp.Azure_ID__c= 'Test Id';
         opp.Probability= 0.5;
        insert opp;
        
        
        Opportunity opp2 = TestUtil.createOpportunity('Opp Test2',acc.Id, product.Id);
        opp2.CloseDate = Date.today();
        opp2.StageName = 'Closed Won';
    	opp2.Expiration_Date__c = Date.today()+60;
        insert opp2;
        
  
    
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'In Progress';
        quote1.Coverage_Product_Options__c = 'D&O';
     	quote1.Refer_Type__c = 'Underwriting Referral';
    	quote1.Policy__c = pol.Id;
        insert quote1;  

		Quote quote2 = Testutil.createQuote('New Quote 2', opp.Id);
        quote2.Status = 'Bound Pending';
        quote2.Coverage_Product_Options__c = 'D&O';
        quote2.Refer_Type__c = 'Underwriting Referral';
    	quote2.Policy__c = pol2.Id;
        insert quote2;  
	
    	Contact con = new Contact(
			Lastname = 'Test broker',
			RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
		);
		insert con;
    
    		Broker_Account__c brokerAccount = new Broker_Account__c(
			Broker_Contact__c = con.Id,
			Opportunity__c = opp.Id,
			IsPrimaryBroker__c = true,
			Relationship_Type__c = 'Broker'
		);
		insert brokerAccount;

	}
    @isTest
    static void cloneOpportunityRenewalTest(){
        Test.startTest();
        Opportunity opp = [Select Id, Name, Expiration_Date__c, Type, Received_Date__c, CloseDate, Effective_Date__c, Prior_Policy__c, Policy__c, Azure_ID__c, Probability from Opportunity Limit 1]; 
        opp.Name = 'Bussiness Account Test';
        update opp;
        List<sObject> lstOfOpps = new List<sObject>{opp};
        
       RenewalPolicyController.ResponseResult result = RenewalPolicyController.cloneOpportunityRenewal(lstOfOpps);
        
        Test.stoptest();
        System.assert(result.isSuccess == true);
    }
    
    @isTest
    static void generateOpportunityTest(){
        Test.startTest();
        Opportunity opp = [Select Id, Name, Expiration_Date__c, Type, Received_Date__c, CloseDate, Effective_Date__c, Prior_Policy__c, Policy__c, Azure_ID__c, Probability from Opportunity Limit 1];
        Opportunity generatedOpp = RenewalPolicyController.generateOpportunity(opp);
         System.assertEquals( 'Qualified',generatedOpp.StageName);
        Test.stoptest();
    }
    @isTest
    static void generateQuoteMapTest(){
        Test.startTest();
        List<Quote> lstOfQuotes = [Select Id, OpportunityId from Quote];
        Map<String, Quote> quoteMap = RenewalPolicyController.generateQuoteMap(lstOfQuotes);
         System.assertEquals( true, quoteMap != null);
        Test.stopTest();
    }
    @isTest
    static void getQuoteBusinessQueryTest(){
        Test.startTest();
        List<Id> quoteIds = new List<Id>();
        for(Quote q :[Select Id from Quote]){
            quoteIds.add(q.Id);
        }
     List<Quote> quotes = RenewalPolicyController.getQuoteBusinessQuery(quoteIds);
         System.assert( quotes != null);
        Test.stopTest();
    }
     @isTest
    static void getBrokerAccountsTest(){
        Test.startTest();
        List<Id> quoteIds = new List<Id>();
        for(Quote q :[Select Id from Quote]){
            quoteIds.add(q.Id);
        }
       List<Broker_Account__c> brokerAccounts = RenewalPolicyController.getBrokerAccounts(quoteIds);
        System.assert( brokerAccounts != null);
        Test.stopTest();
    }
    @isTest
    static void renewalControllerTest(){
        Test.startTest();
        Policy__c pol = [Select Id from Policy__c Limit 1];
       RenewalPolicyController.ResponseResult result = RenewalPolicyController.renewalController(pol.Id);
        System.assertEquals('Renewal is not created.', result.msgError);
        Test.stopTest();
    }
     @isTest
    static void renewalControllerBlankPolicyTest(){
        Test.startTest();
        Policy__c pol = [Select Id from Policy__c Limit 1];
       RenewalPolicyController.ResponseResult result = RenewalPolicyController.renewalController('');
         System.assert(result.isSuccess == false);
        Test.stopTest();
    }
     @isTest
    static void renewalControllerQuoteBPTest(){
        Test.startTest();
        Policy__c pol = [Select Id from Policy__c where Policy_Number__c = '123456'];
       RenewalPolicyController.ResponseResult result = RenewalPolicyController.renewalController(pol.Id);
        System.assert(result.isSuccess == false);
        Test.stopTest();
    }
    
     @isTest
    static void generateNewBrokerAccountTest(){
        Test.startTest();
        List<Broker_Account__c> brokerList = [Select id, Opportunity__c from Broker_Account__c Limit 1];
        List<Opportunity> lstOfOpps = [Select Id from Opportunity];
        Map<id, Opportunity> oppMap = new Map<id, Opportunity>(lstOfOpps);
       List<Broker_Account__c> brokerAccounts = RenewalPolicyController.generateNewBrokerAccount(brokerList, oppMap);
       System.assert(brokerAccounts != null);
        Test.stopTest();
    }
}