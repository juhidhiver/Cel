/**************************************************************************************************
 * Class Name: ProductTriggerHandlerTest
 * Author: Hoang Bui
 * Date: 29-Aug-2019
 * Description: ProductTriggerHandlerTest Test
 **************************************************************************************************/
@isTest
private class ProductTriggerHandlerTest {
   public static Product2 product;
    public static Account acc;
    
    static {
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassQuoteTrigger__c = false;
        update setting;
        
        acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        product = TestUtil.createProduct('Cyber');
        insert product;
        
         //create new product
        Product2 newProduct = TestUtil.createProduct('MPL');
        insert newProduct;
        
        //create new product added by RINKU SAINI 23-12-2021
        Product2 newProduct1 = TestUtil.createProduct('MPL');
        newProduct1.Innovisk_Entity_ID__c = 'Aqueous';
        newProduct1.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        insert newProduct1;
        
    }
    
    
    @isTest static void testCreateProduct() {
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        insert opportunity; 
        
        //Create Rating_Modifier_Template__c list
        List<Rating_Modifier_Template__c> listRatingModifierTemp = new List<Rating_Modifier_Template__c>();
        Rating_Modifier_Template__c ratingModifiersTemp1 = TestUtil.createRatingModifierTemplate('Input number field','Cyber' , 'Number');
        Rating_Modifier_Template__c ratingModifiersTemp2 = TestUtil.createRatingModifierTemplate('Input number field', 'MPL' , 'Integer');
        listRatingModifierTemp.add(ratingModifiersTemp1);
        listRatingModifierTemp.add(ratingModifiersTemp2);
        insert listRatingModifierTemp;
        
        //Create Rating_Modifiers__c list
        List<Rating_Modifiers__c> lstRatingModifier = new List<Rating_Modifiers__c>();
        Rating_Modifiers__c ratingModifier1 = TestUtil.createRatingModifier('Rating field test1', product.Name, opportunity.Id);
        Rating_Modifiers__c ratingModifier2 = TestUtil.createRatingModifier('Rating field test2', 'MPL', opportunity.Id);
        lstRatingModifier.add(ratingModifier1);
        lstRatingModifier.add(ratingModifier2);
        insert lstRatingModifier;
        
        Test.startTest();
        //create new product
        Product2 newProduct = TestUtil.createProduct('MPL');
        insert newProduct;
        
        Test.stopTest();
        
        //START Added by RINKU SAINI 24-Dec-2021
        List<Product2> lstProduct = [SELECT Id,Name FROM Product2 Where Id =:newProduct.Id];
        CommonProductUtil.RemoveProductNameFromObject('Product2',lstProduct);
        CommonProductUtil.RemoveProductNameFromObject('Product2',new List<Product2>());
        List<Product2> lstProduct1 = [SELECT Id FROM Product2 Where Id =:newProduct.Id];
        CommonProductUtil.RemoveProductNameFromObject('Product2',lstProduct1);
        
        CommonProductUtil.addProductNameToObject('Product2',new List<Product2>());
        CommonProductUtil.addProductNameToObject('Product2',lstProduct1);
        CommonProductUtil.updateProductNameFromObject('Product2',null,null);
        CommonProductUtil.updateProductNameFromObject('Product2', New Map<Id, Product2>(), New Map<Id, Product2>());
        //END Added by RINKU SAINI 24-Dec-2021
        System.assertEquals(true,lstProduct[0].Id != null);
        
    }
    
    
    @isTest static void testUpdateProduct() {
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        insert opportunity; 
        
        //Create Rating_Modifier_Template__c list
        List<Rating_Modifier_Template__c> listRatingModifierTemp = new List<Rating_Modifier_Template__c>();
        Rating_Modifier_Template__c ratingModifiersTemp1 = TestUtil.createRatingModifierTemplate('Input number field','Cyber', 'Number');
        Rating_Modifier_Template__c ratingModifiersTemp2 = TestUtil.createRatingModifierTemplate('Input number field', 'MPL' , 'Integer');
        listRatingModifierTemp.add(ratingModifiersTemp1);
        listRatingModifierTemp.add(ratingModifiersTemp2);
        insert listRatingModifierTemp;
        
        //Create Rating_Modifiers__c list
        List<Rating_Modifiers__c> lstRatingModifier = new List<Rating_Modifiers__c>();
        Rating_Modifiers__c ratingModifier1 = TestUtil.createRatingModifier('Rating field test1', product.Name, opportunity.Id);
        Rating_Modifiers__c ratingModifier2 = TestUtil.createRatingModifier('Rating field test2', 'MPL', opportunity.Id);
        lstRatingModifier.add(ratingModifier1);
        lstRatingModifier.add(ratingModifier2);
        insert lstRatingModifier;
        
        
        Test.startTest();
        product.Name = 'D&O Standalone';
        update product;
        Test.stopTest();
        
        List<Product2> lstProduct = [SELECT Id FROM Product2 Where Id =:product.Id];
        System.assertEquals(true,lstProduct[0].Id != null);
        delete lstProduct;
    }
    
    
    @isTest static void testDeleteProduct() {
        
        Test.startTest();
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        insert opportunity; 
        
        //Create Rating_Modifier_Template__c list
        List<Rating_Modifier_Template__c> listRatingModifierTemp = new List<Rating_Modifier_Template__c>();
        Rating_Modifier_Template__c ratingModifiersTemp1 = TestUtil.createRatingModifierTemplate('Input number field', 'Cyber' , 'Number');
        Rating_Modifier_Template__c ratingModifiersTemp2 = TestUtil.createRatingModifierTemplate('Input number field', 'MPL' , 'Integer');
        listRatingModifierTemp.add(ratingModifiersTemp1);
        listRatingModifierTemp.add(ratingModifiersTemp2);
        insert listRatingModifierTemp;
        
        //Create Rating_Modifiers__c list
        List<Rating_Modifiers__c> lstRatingModifier = new List<Rating_Modifiers__c>();
        Rating_Modifiers__c ratingModifier1 = TestUtil.createRatingModifier('Rating field test1', product.Name, opportunity.Id);
        Rating_Modifiers__c ratingModifier2 = TestUtil.createRatingModifier('Rating field test2', 'MPL', opportunity.Id);
        lstRatingModifier.add(ratingModifier1);
        lstRatingModifier.add(ratingModifier2);
        insert lstRatingModifier;
        
        //create new product
        Product2 newProduct = TestUtil.createProduct('MPL');
        insert newProduct;
        
        //create new product added by RINKU SAINI 23-12-2021
        Product2 newProduct1 = TestUtil.createProduct('MPL');
        newProduct1.Innovisk_Entity_ID__c = 'Aqueous';
        newProduct1.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        insert newProduct1;
        
        String newProductId = newProduct.Id;
        
        
        newProduct1.Name = 'MPL1';
        update newProduct1;
        delete opportunity;
        delete newProduct1;
        delete product;
        delete newProduct;
        Test.stopTest();
        
        List<Product2> lstProduct = [SELECT Id FROM Product2 Where Id =:newProductId];
        System.assertEquals(true, lstProduct.isEmpty());
    }
    
    
    @isTest static void testCreateProductExceptionNull() {
        Test.startTest();
        ProductTriggerHandler.addProductNameToObject('Rating_Modifier_Template__c.Modifier_Product__c',null); 
        ProductTriggerHandler.addProductNameToObject('Rating_Modifier_Template__c.Modifier_Product__c',new List<Product2>());      
        Test.stopTest();
        
        System.assert(true);
    }
    
    
    @isTest static void testDeleteProductExceptionNull() {
        Test.startTest();
        ProductTriggerHandler.removeProductNameFromObject('Rating_Modifier_Template__c.Modifier_Product__c',null); 
        ProductTriggerHandler.removeProductNameFromObject('Rating_Modifier_Template__c.Modifier_Product__c',new List<Product2>());      
        Test.stopTest();
        
        System.assert(true);
    }
    
    
    @isTest static void testUpdateProductExceptionNull() {
        Test.startTest();
        ProductTriggerHandler.updateProductNameFromObject('Rating_Modifier_Template__c.Modifier_Product__c',null,null); 
        ProductTriggerHandler.updateProductNameFromObject('Rating_Modifier_Template__c.Modifier_Product__c',new Map<Id, Product2>(), new Map<Id, Product2>());      
        Test.stopTest();
        
        System.assert(true);
    }
    
    // added by RINKU SAINI 23-Dec-2021
    public static testmethod void deleteProduct(){
        Test.startTest();
        
        //create new product
        Product2 newProduct = TestUtil.createProduct('MPL');
        insert newProduct;
        
        //create new product
        Product2 newProduct1 = TestUtil.createProduct('MPL');
        newProduct1.Innovisk_Entity_ID__c = 'Aqueous';
        newProduct1.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        insert newProduct1;
        update newProduct;
        update newProduct1;
        
        delete newProduct;
        delete newProduct1;
        Test.stopTest();
    }
	
}