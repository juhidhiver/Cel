/**
* @description       : 
* @author            : Vinayesh
* @group             : 
* @last modified on  : 08-17-2021
* @last modified by  : Vinayesh
**/
@isTest
public with sharing class ClearanceAccordianControllerTest {
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
        Rating_Modifier_Template__c rMT2 = TestUtil.createRatingModifierTemplate('New input integer','D&O','Percentage');
        rMT2.Display_Format__c = 'Clearance';
        lRMT.add(rMT2);
        Rating_Modifier_Template__c rMT3 = TestUtil.createRatingModifierTemplate('New input integer','D&O','Radio Button');
        rMT3.Display_Format__c = 'Clearance';
        lRMT.add(rMT3);
        lRMT = new List<Rating_Modifier_Template__c>();
        Rating_Modifier_Template__c rMT7 = TestUtil.createRatingModifierTemplate('Test Service Classification','D&O','Text');
        rMT7.Display_Format__c = 'Clearance';
        lRMT.add(rMT7);
        Rating_Modifier_Template__c rMT8 = TestUtil.createRatingModifierTemplate('New input integer','D&O','Picklist');
        rMT8.Display_Format__c = 'Clearance';
        lRMT.add(rMT8);
        
        Rating_Modifier_Template__c rMT9 = TestUtil.createRatingModifierTemplate('New input integer','D&O','Date');
        rMT9.Display_Format__c = 'Clearance';
        lRMT.add(rMT9);
        Rating_Modifier_Template__c rMT4 = TestUtil.createRatingModifierTemplate('New input integer','EPL','Integer');
        rMT4.Display_Format__c = 'Clearance';
        lRMT.add(rMT4);
        Rating_Modifier_Template__c rMT5 = TestUtil.createRatingModifierTemplate('Nature of Industry','Crime','Number');
        rMT5.Display_Format__c = 'Clearance';
        lRMT.add(rMT5);
        Rating_Modifier_Template__c rMT6 = TestUtil.createRatingModifierTemplate('Annual Revenues','Fiduciary','Number');
        rMT6.Display_Format__c = 'Clearance';
        lRMT.add(rMT6);
        
        Rating_Modifier_Template__c rMT10 = TestUtil.createRatingModifierTemplate('New input integer','D&O','Picklist');
        rMT10.Display_Format__c = 'Primary Modifiers';
        rMT10.Picklist_Values__c = 'Test 1;Test 2;Test 3;Test 4';
        lRMT.add(rMT10);
        
        Rating_Modifier_Template__c rMT11 = TestUtil.createRatingModifierTemplate('Notes','D&O','Number');
        rMT11.Display_Format__c = 'Clearance';
        lRMT.add(rMT11);
        
        Rating_Modifier_Template__c rMT12 = TestUtil.createRatingModifierTemplate('Notes','D&O','Currency');
        rMT12.Display_Format__c = 'Clearance';
        lRMT.add(rMT12);
        
        Rating_Modifier_Template__c rMT13 = TestUtil.createRatingModifierTemplate('Notes','D&O','Percentage');
        rMT13.Display_Format__c = 'Clearance';
        lRMT.add(rMT13);
        
        Rating_Modifier_Template__c rMT14 = TestUtil.createRatingModifierTemplate('Notes','D&O','Integer');
        rMT14.Display_Format__c = 'Clearance';
        lRMT.add(rMT14);
        
        Rating_Modifier_Template__c rMT15 = TestUtil.createRatingModifierTemplate('Notes','D&O','Radio Button');
        rMT15.Display_Format__c = 'Clearance';
        rMT15.Picklist_Values__c = 'Test 1;Test 2;Test 3;Test 4';
        lRMT.add(rMT15);
        
        Rating_Modifier_Template__c rMT16 = TestUtil.createRatingModifierTemplate('Notes','D&O','Text Area');
        rMT16.Display_Format__c = 'Clearance';
        rMT16.Sub_Section__c = 'TEST';
        lRMT.add(rMT16);
        
        insert lRMT;
        
        
        opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.Total_Revenues__c = 100;
        insert opp;
    }
    
    
    @isTest static void testGetData() {
        
        Product_Option_Line_Item__c newRec = new Product_Option_Line_Item__c();
        newRec.Product__c = product1.Id;
        newRec.Submission__c = opp.Id;
        newRec.Account__c = acc.Id;
        newRec.Clearance_Status__c = 'Cleared';
        newRec.Is_Selected__c = true;
        newRec.Clearance_Date__c = Datetime.now();
        insert newRec;
        
        ClearanceAccordianController.ClearanceWrapper objWrapper = ClearanceAccordianController.getRatingModifiersrecords(opp.Id);
        System.assertEquals(1, objWrapper.productWrapperList.size()); 
        
    }
    
    @isTest static void testAddData() {
        
        Product_Option_Line_Item__c newRec = new Product_Option_Line_Item__c();
        newRec.Product__c = product1.Id;
        newRec.Submission__c = opp.Id;
        newRec.Account__c = acc.Id;
        newRec.Clearance_Status__c = 'Cleared';
        newRec.Is_Selected__c = true;
        newRec.Clearance_Date__c = Datetime.now();
        insert newRec;
        
        ClearanceAccordianController.addRatingModifier(opp.Id);
        ClearanceAccordianController.ClearanceWrapper objWrapper = ClearanceAccordianController.getRatingModifiersrecords(opp.Id);
        //objWrapper.eligibilityStatusWrapper = new Map<String,List<Eligibility_Status__c>>();
        String clearanceWrapperJson = Json.serialize(objWrapper.productWrapperList);
        test.startTest();
        
        ClearanceAccordianController.saveClearanceData(clearanceWrapperJson, opp.Id);
        
        test.stopTest();
        
        System.assertEquals(1, objWrapper.productWrapperList.size());
    }
    
    // Added by RINKU SAINI 20 jan 2022
    public testmethod static void coverClearanceAccordian(){
        Test.startTest();
        
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        Product2 product = TestUtil.createProduct('MPL');
        insert product;
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.Total_Revenues__c = 100;
        insert opp;
        
        Product_Option_Line_Item__c newRec = new Product_Option_Line_Item__c();
        newRec.Product__c = product.Id;
        newRec.Submission__c = opp.Id;
        newRec.Account__c = acc.Id;
        newRec.Clearance_Status__c = 'Cleared';
        newRec.Is_Selected__c = true;
        newRec.Clearance_Date__c = Datetime.now();
        insert newRec;
        
        Rating_Modifier_Template__c rMT1 = New Rating_Modifier_Template__c();
        rMT1.Name = 'Test Service Classification';
        rMT1.Display_Format__c = 'Primary Modifiers';
        rMT1.Product__c = 'MPL';
        insert rMT1;
        
        ClearanceAccordianController.addRatingModifier(opp.Id);
        
        Test.stopTest();
    }
}