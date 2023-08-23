/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 07-12-2021
 * @last modified by  : Vinayesh
 * Modifications Log 
 * Ver   Date         Author     Modification
 * 1.0   07-08-2021   Vinayesh   Initial Version
**/
@isTest
public with sharing class ProductOptionLineItemTriggerHandlerTest {
    public static Product2 product;
    public static Product2 product1;
    public static Product2 product2;
    public static Product2 product3;
    public static Product2 product4;
    public static Account acc;
    public static Opportunity opp;
    public static List<Rating_Modifier_Template__c> lRMT;

    static {
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = false;
        setting.BypassAccountTrigger__c = true;
        setting.BypassProductTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        update setting;
        
        acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        product = TestUtil.createProduct('Private Company Combo');
        insert product;
        
        product1 = TestUtil.createProduct('D&O');
        product1.Parent_Product__c = product.Id;
        product1.IsComboProduct__c = true;
        insert product1;

        product2 = TestUtil.createProduct('EPL');
        product2.Parent_Product__c = product.Id;
        product2.IsComboProduct__c = true;
        insert product2;

        product3 = TestUtil.createProduct('Crime');
        product3.Parent_Product__c = product.Id;
        product3.IsComboProduct__c = true;
        insert product3;

        product4 = TestUtil.createProduct('Fiduciary');
        product4.Parent_Product__c = product.Id;
        product4.IsComboProduct__c = true;
        insert product4;
        
        lRMT = new List<Rating_Modifier_Template__c>();
        Rating_Modifier_Template__c rMT1 = TestUtil.createRatingModifierTemplate('Test Service Classification','D&O','Number');
        rMT1.Display_Format__c = 'Clearance';
        lRMT.add(rMT1);
        Rating_Modifier_Template__c rMT2 = TestUtil.createRatingModifierTemplate('New input integer','D&O','Integer');
        rMT2.Display_Format__c = 'Clearance';
        lRMT.add(rMT2);
        Rating_Modifier_Template__c rMT3 = TestUtil.createRatingModifierTemplate('New input integer','D&O','Integer');
        rMT3.Display_Format__c = 'Clearance';
        lRMT.add(rMT3);
        Rating_Modifier_Template__c rMT4 = TestUtil.createRatingModifierTemplate('New input integer','EPL','Integer');
        rMT4.Display_Format__c = 'Clearance';
        lRMT.add(rMT4);
        Rating_Modifier_Template__c rMT5 = TestUtil.createRatingModifierTemplate(Label.NATURE_OF_INDUSTRY_OR_SECTOR,'Crime','Number');
        rMT5.Display_Format__c = 'Clearance';
        lRMT.add(rMT5);
        Rating_Modifier_Template__c rMT6 = TestUtil.createRatingModifierTemplate(Label.ANNUAL_REVENUES,'Fiduciary','Number');
        rMT6.Display_Format__c = 'Clearance';
        lRMT.add(rMT6);
        
        insert lRMT;

        
        opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.Total_Revenues__c = 100;
        insert opp;

        Quote quote = TestUtil.createQuote('New Quote Test',opp.Id);
        quote.Coverage_Product_Options__c ='D&O;MPL';
        quote.Layer__c = 'Excess';
        quote.Is_Quote_Approved_AQ__c = 'Approved';
        quote.Pending_or_Prior_Proceedings_Date__c=date.today();
        insert quote;
    }

    @isTest static void testInsertProductOptionLineItem() {
        Product_Option_Line_Item__c newRec = new Product_Option_Line_Item__c();
        newRec.Product__c = product1.Id;
        newRec.Submission__c = opp.Id;
        newRec.Account__c = acc.Id;
        newRec.Clearance_Status__c = 'Cleared';
        newRec.Is_Selected__c = true;
        newRec.Clearance_Date__c = Datetime.now();
        insert newRec;

        List<Rating_Modifiers__c> rmList = [Select Id From Rating_Modifiers__c
                                             Where Name = 'Test Service Classification'];
        System.assertEquals(1, rmList.size());
        
    }

    @isTest static void testProductLineItemClearedToDecline() {
        Product_Option_Line_Item__c newRec = new Product_Option_Line_Item__c();
        newRec.Product__c = product1.Id;
        newRec.Submission__c = opp.Id;
        newRec.Account__c = acc.Id;
        newRec.Clearance_Status__c = 'Cleared';
        newRec.Is_Selected__c = true;
        newRec.Clearance_Date__c = Datetime.now();
        insert newRec;

        //update status to decline
        Test.startTest();
        newRec.Clearance_Status__c = 'Decline';
        update newRec;
        Test.stopTest();
    }

    @isTest static void testProductLineItemClearedToClosedMarket() {
        Product_Option_Line_Item__c newRec = new Product_Option_Line_Item__c();
        newRec.Product__c = product1.Id;
        newRec.Submission__c = opp.Id;
        newRec.Account__c = acc.Id;
        newRec.Clearance_Status__c = 'Cleared';
        newRec.Is_Selected__c = true;
        newRec.Clearance_Date__c = Datetime.now();
        insert newRec;

        //update status to decline
        Test.startTest();
        newRec.Clearance_Status__c = 'Closed Market';
        update newRec;
        Test.stopTest();
    }

    @isTest static void testDeleteProductOptionLineItem() {
        Product_Option_Line_Item__c newRec = new Product_Option_Line_Item__c();
        newRec.Product__c = product1.Id;
        newRec.Submission__c = opp.Id;
        newRec.Account__c = acc.Id;
        newRec.Clearance_Status__c = 'Cleared';
        newRec.Is_Selected__c = true;
        newRec.Clearance_Date__c = Datetime.now();
        insert newRec;

        List<Rating_Modifiers__c> rmList = [Select Id From Rating_Modifiers__c
                                             Where Name = 'Test Service Classification'];
        System.assertEquals(1, rmList.size());

        delete newRec;
        List<Rating_Modifiers__c> rmList1 = [Select Id From Rating_Modifiers__c
                                                Where Name = 'Test Service Classification'];
        System.assertEquals(0, rmList1.size());
    }
}