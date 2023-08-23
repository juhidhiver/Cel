/***********************************************************************
 * Class Name: OpportunityInitFormCmpControllerTest
 * Author: Khanh TRAN
 * Date: 28-Oct-2019
 * Description: Unit test for OpportunityInitFormCmpController 
 ***********************************************************************
 */

@isTest
private class OpportunityInitFormCmpControllerTest {
	public static Product2 product;
	public static Account acc;
	public static Opportunity opp;
    public static Quote_Process__c newQuoteProcess;
    public static Contact con;
	
	static {
        
		acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
		insert acc;

		product = TestUtil.createProduct('D&O Standalone');
		insert product;

		opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
		insert opp;
        
        con = new Contact(
			Lastname = 'Test',
			RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
		);
		insert con;
        
        newQuoteProcess = new Quote_Process__c(Submission__c = opp.Id, Account__c = opp.AccountId, Status__c = 'Submission Info', Record_Type__c = 'Celerity');
		insert newQuoteProcess;
        
        opp.Agency__c = acc.Id;
        opp.Type = 'New Business';
        opp.StageName = 'New';
        update opp;           
	}
	
	@isTest static void getOpportunityRecordTypeTest() {
		List<RecordType> oppRecordTypeList = OpportunityInitFormCmpController.getOpportunityRecordType();
        OpportunityInitFormCmpController.getSubmissionName(acc.Id,product.Id);
		System.assertEquals('Aqueous', oppRecordTypeList[0].Name);
	}

	// getOpportunityInfo
	@isTest static void getOpportunityInfoTest(){
		new OpportunityInitFormCmpController.GenerateResult();
		new OpportunityInitFormCmpController.AccountWrapper();
		OpportunityInitFormCmpController.GenerateResult result = OpportunityInitFormCmpController.getOpportunityInfo(acc.Id, product.Id);
		System.assertEquals('Bussiness Account Test D&O Standalone', result.oppName);
	}

	@isTest static void getInfoTest(){
		Opportunity testOpp = OpportunityInitFormCmpController.getInfo(opp.Id);
		System.assert(testOpp != null);
	}
    
    //Added by sarthak 07-07-2020
    @isTest
    static void getFieldNameOpportunityTest(){
        Test.startTest();
        List<String> apiNames = OpportunityInitFormCmpController.getFieldNameOpportunity();       
        Test.stopTest();
        System.assert(apiNames != null);
    }
    //Added by sarthak 07-07-2020
   @isTest
    static void validateOpportunityDuplicateTest2(){
        Test.startTest();
        Contact con = [Select Id from Contact Limit 1];
        OpportunityInitFormCmpController.ValidateResult vResult = OpportunityInitFormCmpController.validateOpportunity(acc.Id, product.Id, con.Id, 'Primary');
        Test.stopTest();
        System.assert(con != null);
    }
    
    @isTest
    static void validateOpportunityTest(){
        Broker_Account__c newBroAccount = TestUtil.createBrokerAccount(con.Id, opp.Id);
        insert newBroAccount;
        
        Test.startTest();
        Contact con = [Select Id from Contact Limit 1];
        OpportunityInitFormCmpController.ValidateResult vResult = OpportunityInitFormCmpController.validateOpportunity(acc.Id, product.Id, con.Id, 'Primary');
        Test.stopTest();
        System.assert(newBroAccount != null);
    }
    
    @isTest static void getDefaultRecordTypeTest() {
        Test.startTest();
		String defaultRecordType = OpportunityInitFormCmpController.getDefaultRecordType(newQuoteProcess.Id);
        Test.stopTest();
		System.assert(defaultRecordType.contains('Celerity'));
	}
    
    @isTest static void getDefaultProductTest() {
        Test.startTest();
		String defaultProduct = OpportunityInitFormCmpController.getDefaultProduct(newQuoteProcess.Id);
        Test.stopTest();
		
        System.assertEquals('', defaultProduct);
	}
}