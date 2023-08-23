/**************************************************************************************************
 * Class Name: AccountProductTriggerHandlerTest
 * Author: JUHI DHIVER
 * Date: 20-JUL-2022
 * Description: AccountProductTriggerHandlerTest Test
 **************************************************************************************************/
@isTest
private class AccountProductTriggerHandlerTest {
	public static Quote quote;
	public static Opportunity opp;
	public static Opportunity opp_aq;

	static {
    	TriggerSettings__c setting = TestUtil.initialTriggerSetting();
		setting.BypassAccountProductTrigger__c = false;
		update setting;

		//Create Account
		Account acc1 = new Account();
		acc1.Name = 'New_J_Account_123';
		acc1.BillingStreet = '11 Tran Duy Hung';
		acc1.BillingCity = 'Westminster';
		acc1.BillingState = 'California';
		acc1.BillingPostalCode = '90000';
		acc1.BillingCountry = 'United States';
		acc1.IsMailingSameWithBillingAddress__c = true;
		acc1.Date_Started__c = Date.today().addYears(-2);
		insert acc1;

        // Create contact
		Contact con = new Contact(
			Lastname = 'Test broker',
			RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
		);
		insert con;
        
        //Setip Account Commision Table
	    Account_Commission_Template__c ac = new Account_Commission_Template__c();
        ac.Wholesaler__c = 'New_J_Account_123';
        ac.Cyber_Default__c = 20;
        insert ac;

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
		
		Account_Product__c accProd1 = new Account_Product__c();
        accProd1.Account_Id__c = acc1.Id;
        accProd1.Product_Id__c = prd.id;
        insert accProd1;
		
    }

 
	@isTest
	static void testUpdateCommissionPercentage() {
        Test.startTest();
		Account acc = [SELECT Id FROM Account limit 1];
        Account_Commission_Template__c act = [Select id, Wholesaler__c,Cyber_Default__c from Account_Commission_Template__c limit 1];
		Account_Product__c ap = [SELECT Id,Commission_percentage__c, Product_Id__c, Product_Id__r.Name, Account_Id__c,Account_Id__r.Name
                                             From Account_Product__c WHERE Account_Id__c =: acc.Id limit 1];
        update ap;
        Test.stopTest();   
	}

	
}