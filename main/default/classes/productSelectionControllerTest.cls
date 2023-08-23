/**
 * @description       : Test class to cover productSelectionController
 * @author            : Maeran Shaikh
 * @group             : 
 * @last modified on  : 11-10-2021
 * @last modified by  : Maeran Shaikh
**/

@isTest
public with sharing class productSelectionControllerTest {
    public static Product2 product;
    public static Product2 product1;
    // Create data
    @testSetup
    private static void testSetup() {
        product = TestUtil.createProduct('Private Company Combo');
        insert product;
        
        product1 = TestUtil.createProduct('D&O');
        product1.Parent_Product__c = product.Id;
        product1.IsComboProduct__c = true;
        insert product1;
    }


    @IsTest
    static void testMethod1(){
        List<Product_Selection__mdt> lstProdSelection = productSelectionController.getProductsForSelection();

        String oppId = productSelectionController.insertPlaceholderSubmission('D&O');
        System.assertEquals(false,String.isBlank(oppId));
        Datetime yesterday = Datetime.now().addMinutes(-15);
        Test.setCreatedDate(oppId, yesterday);
        String oppId2 = productSelectionController.deletePlaceholderOppsAndGetProdId('D&O');
        System.assertEquals(false,String.isBlank(oppId2));
    }
    
}