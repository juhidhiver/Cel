/**************************************************************************************************
 * Class Name: BrokerAccountQueryUtilTest
 * Author: Vinay
 * Date: Dec 27th, 2021
 * Description: Test class for BrokerAccountQueryUtil
 **************************************************************************************************/
@isTest
public with sharing class BrokerAccountQueryUtilTest {
    static testmethod void test_BrokerAccountQueryUtil(){
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
		Account acc1  = TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster', 'California','90000', 'United States');
		acc1.IsMailingSameWithBillingAddress__c = true;
		acc1.Date_Started__c = Date.today().addYears(-2);
		insert acc1;

		// Create product and coverage
		Product2 prd = TestUtil.createProduct('Private Company Combo', Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Celerity').getRecordTypeId(), 'Celerity');
		prd.Expiration_Date__c = Date.today().addDays(200);
		prd.Effective_Date__c = Date.today().addDays(-1);
		insert prd;
		
		Opportunity opp = TestUtil.createOpportunity('Test opp', acc1.Id, prd.Id, Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId(), 'Celerity');
		opp.StageName = 'Qualified';
		opp.CloseDate = Date.today().addDays(30);
		opp.Effective_Date__c = Date.today().addDays(1);
		opp.Pricebook2Id = Test.getStandardPricebookId();
		opp.Coverage_Product_Options__c = 'D&O';
		insert opp;

		// Create contact
		Contact con = new Contact(Lastname = 'Huy broker',RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId());
		insert con;

		// Create broker
		Broker_Account__c broker =  TestUtil.createBrokerAccount(con.Id, opp.Id);
		insert broker;

        Test.startTest();
        BrokerAccountQueryUtil.fetchPrimaryBrokerAccounts(new Set<id>{con.id});
        BrokerAccountQueryUtil.fetchPrimaryBrokerAccountsByOpp(new Set<id>{opp.id});
        BrokerAccountQueryUtil.fetchBrokerAccountsByIds(new Set<id>{broker.id});
        // Added By RINKU SAINI 10th Jan 2022
        BrokerAccountQueryUtil.fetchPrimaryBrokerAccountsForOpp(opp.id);
        Test.stopTest();
    }
}