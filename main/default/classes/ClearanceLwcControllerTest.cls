/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 08-03-2021
 * @last modified by  : Vinayesh
**/
@isTest
public with sharing class ClearanceLwcControllerTest {
    public static Product2 product;
    public static Account acc;
    public static Opportunity opp;
    public static Quote_Process__c qp;

    static {
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = false;
        setting.BypassAccountTrigger__c = true;
        setting.BypassProductTrigger__c = true;
        update setting;
        
        acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        product = TestUtil.createProduct('Private Company Combo');
        insert product;
        
        opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.Total_Revenues__c = 100;
        insert opp;

         
        qp = new Quote_Process__c();
        qp.Account__c = acc.Id;
        qp.Submission__c = opp.Id;
        qp.Product__c = product.Name;
        insert qp;
    }

    @isTest static void testGetSubmissionData() {
        test.startTest();

        ClearanceLwcController.getProductId(qp.Id);
        ClearanceLwcController.getAccountId(qp.Id);

        ClearanceLwcController.getProductId(opp.Id);
        ClearanceLwcController.getAccountId(opp.Id);
        ClearanceLwcController.getSubmissionId(opp.Id);

        String oppId = ClearanceLwcController.getSubmissionId(qp.Id);

        test.stopTest();   
        
        System.assertEquals(opp.Id, oppId);
    }
}