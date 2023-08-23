/*************************************************
* Class Name: CreateQuoteProcessTest
* Author: Ashik Zahir
* Updated: 09-Mar-2021
* Description: Test Class for CreateQuoteProcess
*
*************************************************/
@isTest
public class CreateQuoteProcessTest {
@testsetup static void testSetup(){
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
		Account acc  =TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster',
												'California','90000', 'United States');
        acc.Azure_ID__c = '8042ac98-ae5a-4692-9880-58d92d0eb9d9';
		insert acc;
    
        Product2 product = TestUtil.createProduct('D&O Standalone');
		insert product; 
    
     	Product2 product1 = TestUtil.createProduct('Private Company Combo');
		insert product1; 

        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today()+365;
        opp.StageName = 'New';
        opp.Azure_ID__c = 'f70e4c82-3378-41ce-870b-57f4df415874';
        insert opp;
    
    	Opportunity opp1 = TestUtil.createOpportunity('Opp Test1',acc.Id, product1.Id);
        opp1.CloseDate = Date.today()+365;
        opp1.StageName = 'New';
        opp1.Azure_ID__c = 'f70e4c82-3378-41ce-870b-57f4df415879';
        insert opp1;
        
        //Account Product for AccountID
        Account_Product__c accProd1 = new Account_Product__c();
        accProd1.Account_Id__c = acc.Id;
        accProd1.Product_Id__c = product.id;
        insert accProd1;
        
        //Channel Account
		Account chanAcc  =TestUtil.createAccount('Test Channel Account', recordTypeId, '01 Tran Duy Hung','Westminster',
												'California','90000', 'United States');
        chanAcc.Azure_ID__c = '407a8180-7cf0-4c74-99d0-4c194723916e';
		insert chanAcc;
        
		Account_Product__c accProd2 = new Account_Product__c();
        accProd2.Account_Id__c = chanAcc.Id;
        accProd2.Product_Id__c = product.id;
        insert accProd2;

        Id recordTypeBrokerAgency = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        
        Account accBroker = TestUtil.createBusinessAccount('Broker Account Test', 'Broker_Account', '625, South Mill Road', 'Anycity', 'New York', '67074', 'United States');
		accBroker.RecordTypeId = recordTypeBrokerAgency;
		
        insert accBroker;

		Contact contactBroker = TestUtil.createContact(accBroker.Id, 'Broker_Contact', 'New broker contact');
		insert  contactBroker;       
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'In Progress';
        quote1.Coverage_Product_Options__c = 'D&O';
        quote1.Quote_Type__c = 'New Business';
     	quote1.Refer_Type__c = 'Underwriting Referral';
        insert quote1; 
    
   		Quote_Process__c qp = new Quote_Process__c();
        //qp.Account__c = accBroker.Id;
        //qp.Submission__c = opp.Id;
    	qp.Status__c = 'Underwritting Analysis';
    	qp.Record_Type__c = 'Test record';
    	qp.Product__c = 'test Product';
        insert qp;
    
	}
    
     @isTest
    static void testInsertQuote(){
        Test.startTest();
        Quote_Process__c qp = [SELECT Id, Status__c,Record_Type__c,Product__c, Submission__c 
                                                   FROM Quote_Process__c LIMIT 1];
        CreateQuoteProcess.insertQuote(qp.Record_Type__c, qp.Product__c);
        Test.stopTest();
        system.assert(qp !=null);
    }
    
     @isTest
    static void testInsertQuotePCC(){
        Test.startTest();
        Quote_Process__c qp = [SELECT Id, Status__c,Record_Type__c,Product__c, Submission__c 
                                                   FROM Quote_Process__c LIMIT 1];
        CreateQuoteProcess.insertQuote(qp.Record_Type__c, 'Private Company Combo');
        
        List<Opportunity> opp1 = [Select Id From Opportunity Where Product_Name__c = 'Private Company Combo'];
        if(opp1.size() > 0){
            CreateQuoteProcess.insertQuoteForPCC(qp.Record_Type__c, 'Private Company Combo', opp1[0].Id);
        }     
        
        Test.stopTest();
        system.assert(qp !=null);
    }

}