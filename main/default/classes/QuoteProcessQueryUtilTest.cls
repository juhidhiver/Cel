/**************************************************************************************************
* Class Name: QuoteProcessQueryUtilTest
* Author: RINKU SAINI
* Date: Dec 30th, 2021
* Description: 
**************************************************************************************************/

@isTest
public class QuoteProcessQueryUtilTest {
    
    public static testmethod void coverQuoteProcessQueryUtil(){
        Test.startTest();
        
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert accBroker;
        
        Product2 product = TestUtil.createProduct('MPL Standalone');
        insert product;
        
        // create opportunity        
        Opportunity opp = TestUtil.createOpportunity('Test Opportunity', accBroker.Id, product.Id);
        opp.StageName = 'Qualified';
        insert opp;
        
        Quote_Process__c qp = new Quote_Process__c();
        qp.Account__c = accBroker.Id;
        qp.Submission__c = opp.Id;
        insert qp;
        
        QuoteProcessQueryUtil.fetchQPForSubmissions( New Set<Id>{opp.Id});
        Test.stopTest();
    }
}