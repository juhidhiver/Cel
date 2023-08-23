/**************************************************************************************************
* Class Name: ReferralReasonQueryUtilTest
* Author: RINKU SAINI
* Date: Jan 10th, 2022
* Description: Class to keep Referral Reason queries
**************************************************************************************************/
@isTest
public class ReferralReasonQueryUtilTest {
    
    public static testmethod void coverReferralReasonQueryUtil(){
        Test.startTest();
        
        // create broker account        
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert accBroker;              	
        
        // create product
        Product2 product = TestUtil.createProduct('Test Product');
        insert product;
        
        // create opportunity        
        Opportunity opp = TestUtil.createOpportunity('Test Opportunity', accBroker.Id, product.Id);
        opp.StageName = 'Qualified';
        insert opp;
        
        // create Quote
        Quote q = TestUtil.createQuote('Test Quote', opp.Id);
        q.Rating_Status__c = 'Refer';
        q.Status = 'Rated';
        insert q;
        
        
        Referral_Reason__c ref1=new Referral_Reason__c();
        ref1.Approval_Level_Required__c='1';
        ref1.Approval_Status__c='Approved';
        ref1.Approval_Rejected_Date__c= date.today()+365;
        ref1.Quote__c=q.id;
        Insert ref1;
        ReferralReasonQueryUtil.fetchRefReasonsByQuoteId(q.Id);
        
        Test.stopTest();
    }
}