@isTest
public class QuoteProcessLWCControllerTest {
	@testSetup
    public static void setup() {
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert accBroker;              	
        
        // create product
        Product2 product = TestUtil.createProduct('Standalone Product');
		insert product;
        
        //Create Policy
        Policy__c policy = new Policy__c();
        policy.Account__c = accBroker.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);
        policy.Policy_Number__c = 'TESTPOL';
        insert policy;
        
		// create opportunity        
        Opportunity opp = TestUtil.createOpportunity('Test Opportunity', accBroker.Id, product.Id);
        opp.StageName = 'Qualified';
        opp.Policy__c = policy.Id;
        insert opp;
        
        Quote_Process__c qp = new Quote_Process__c();
        qp.Account__c = accBroker.Id;
        qp.Submission__c = opp.Id;
        insert qp;
        
        /*Quote_Process__c qp1 = new Quote_Process__c();
        qp1.Status__c = 'Submission Info';
       	insert qp1;*/
    }
    
    @isTest
    public static void testFletchData() {
        List<QuoteProcessLWCController.ItemWrapper> resultLst = QuoteProcessLWCController.fletchData(1,2,false);
        System.assertEquals(new List<QuoteProcessLWCController.ItemWrapper>(),resultLst);
        List<QuoteProcessLWCController.ItemWrapper> resultOppLst = QuoteProcessLWCController.fletchData(1,1,true);
        System.assertEquals(true,resultOppLst.size() > 0);
    }
    
    @isTest
    public static void testCreateQuoteProcess() {
        QuoteProcessLWCController.createQuoteProcess('Celerity','MPL');
        Quote_Process__c qp = [SELECT Id, Status__c,Account__c,Submission__c 
                               FROM Quote_Process__c LIMIT 1];
        qp.Status__c = 'Submission Info';
        qp.Account__c = null;
        qp.Submission__c = null;
        update qp;
        QuoteProcessLWCController.createQuoteProcess('Celerity','MPL');
    }
    
    @isTest
    public static void testAddAccount() {
        Quote_Process__c qp = [SELECT Id, Status__c,Account__c,Submission__c 
                               FROM Quote_Process__c LIMIT 1];
        String result = QuoteProcessLWCController.addAccount(qp.Id,qp.Account__c);
        System.assertEquals(null,result);
        qp.Submission__c = null;
        update qp;
        String resultObj = QuoteProcessLWCController.addAccount(qp.Id,qp.Account__c);
        System.assertEquals(String.valueOf(qp.Id),resultObj);
    }
    
    @isTest
    public static void testGetOpportunityList() {
        List<QuoteProcessLWCController.ItemWrapper> resultOppLst = QuoteProcessLWCController.getOpportunityList();
        System.assertEquals(true,resultOppLst.size() > 0);
    }
    
    @isTest
    public static void testFetchOpportunity() {
        List<QuoteProcessLWCController.ItemWrapper> resultOppLst = QuoteProcessLWCController.fetchOpportunity('Test','Opportunity','',1);
        System.assertEquals(true,resultOppLst.size() > 0);
        List<QuoteProcessLWCController.ItemWrapper> resultAccLst = QuoteProcessLWCController.fetchOpportunity('','Account','',1);
        System.assertEquals(true,resultAccLst.size() > 0);
        Account acc = [SELECT id,Name FROM Account LIMIT 1];
        List<QuoteProcessLWCController.ItemWrapper> resultAccValLst = QuoteProcessLWCController.fetchOpportunity('','Account',String.valueOf(acc.Id),1);
        System.assertEquals(true,resultAccValLst.size() > 0);
    }
    
    @isTest
    public static void testGetPolicyList() {
        List<QuoteProcessLWCController.ItemWrapper1> result = QuoteProcessLWCController.getPolicyList('TEST');
        System.assertEquals(true,result.size() > 0);
    }
    @isTest 
    public static void insertQuote2Test(){
      
        QuoteProcessLWCController.createQuoteProcess('Celerity','MPL');
        Quote_Process__c qp = [SELECT Id, Status__c,Account__c,Submission__c 
                               FROM Quote_Process__c LIMIT 1];
        qp.Status__c = 'Submission Info';
        qp.Account__c = null;
        qp.Submission__c = null;
        update qp;
        QuoteProcessLWCController.createQuoteProcess('Celerity','MPL');
         QuoteProcessLWCController.insertQuote2('Celerity','MPL');
    }
     @isTest 
    public static void getRecordTypeObjectTest(){
        QuoteProcessLWCController.getRecordTypeObject('Quote');
         QuoteProcessLWCController.getRecordTypeObject('Opportunity');
        QuoteProcessLWCController.mapRecordTypeWithProductName();
    }
    
}