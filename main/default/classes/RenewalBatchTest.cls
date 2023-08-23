/*************************************************
* Class Name: RenewalBatchTest 
* Author: Priyanka Fulwani
* Date: 24-12-2020
* Requirement/Project Name: 
* Requirement/Project Description: 
** Revision: 
*************************************************/

@isTest
public class RenewalBatchTest {	
    @testSetup
    public static void testSetup() {
        
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
        product.IsActive = true;
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
        opp.StageName = 'Closed Won';
        opp.Effective_Date__c = Date.today();
        opp.Expiration_Date__c = Date.today()+120;
        opp.Received_Date__c=Date.today()-120;
        opp.Prior_Policy__c=pol.id;
        opp.Policy__c=pol2.Id;
        opp.Azure_ID__c= 'Test Id';
        opp.Probability= 0.5;
        insert opp; 
        
        
    }
    @isTest static void test() {
        Test.startTest();
        RenewalBatch rb = new RenewalBatch();
        Id batchId = Database.executeBatch(rb, 1);
        Test.stopTest();
        System.assertEquals(1, [select count() from Opportunity where Renewed__c = true]);
    }
}