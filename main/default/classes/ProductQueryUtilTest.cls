/**************************************************************************************************
 * Class Name: ProductQueryUtilTest
 * Author: RINKU SAINI
 * Date: Dec 28th, 2021
 * Description: 
 **************************************************************************************************/

@isTest
public class ProductQueryUtilTest {
    
    public static testmethod void coverProductQueryUtil(){
        Test.startTest();
        
        // Create product and coverage
        Product2 prd = TestUtil.createProduct('Private Company Combo', Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Celerity').getRecordTypeId(),
                                              'Celerity');
        prd.Expiration_Date__c = Date.today().addDays(200);
        prd.Effective_Date__c = Date.today().addDays(-1);
        insert prd;
        
        ProductQueryUtil.fetchProductsByIds( New Set<Id>{prd.Id});
        ProductQueryUtil.getProductsForAccountProductCreation();
        Test.stopTest();
    }
}