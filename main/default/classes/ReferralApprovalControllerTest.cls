@isTest
public class ReferralApprovalControllerTest {
 @testsetup static void testSetup(){
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
		insert acc;
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
		insert product; 

        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Prospect';
        insert opp;
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'Rated';
        quote1.Coverage_Product_Options__c = 'D&O';
     	quote1.Refer_Type__c = 'Underwriting Referral';
        insert quote1;     
    }
    @isTest
    static void submitSubmissionToApprovalProcessTest(){
        Test.startTest();
        Quote q = [Select Id , Refer_Type__c from Quote Limit 1];
      	User lstUser =[select id,userName from user Limit 1];
        ReferralApprovalController.submitSubmissionToApprovalProcess(q.id, lstUser.Id, 'comment', q.Refer_Type__c);
        Test.stopTest();
        system.assertEquals('Underwriting Referral', q.Refer_Type__c);
    }
     @isTest
    static void submitSubmissionToApprovalProcessNoQuoteIdTest(){
        Test.startTest();
        Quote q = [Select Id , Refer_Type__c from Quote Limit 1];
        ReferralApprovalController.submitSubmissionToApprovalProcess('','', 'comment', q.Refer_Type__c);
        Test.stopTest();
        system.assertEquals('Underwriting Referral', q.Refer_Type__c);
    }
     @isTest
    static void submitSubmissionToApprovalProcessExceptionTest(){
        Test.startTest();
        Quote q = [Select Id , Refer_Type__c from Quote Limit 1];
        ReferralApprovalController.submitSubmissionToApprovalProcess(q.id, UserInfo.getUserId(), 'comment', 'Test Val');
        Test.stopTest();
        system.assertEquals('Underwriting Referral', q.Refer_Type__c);
    }
}