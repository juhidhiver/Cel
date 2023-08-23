/**************************************************************************************************
* Class Name: ProductOptionLineItemQueryUtilTest
* Author: RINKU SAINI
* Date: Dec 28th, 2021
* Description: 
**************************************************************************************************/
@isTest
public class ProductOptionLineItemQueryUtilTest {
    
    public static testmethod void coverProductOptionLineItemQueryUtil(){
        Test.startTest();
        
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        Product2 product = TestUtil.createProduct('Private Company Combo');
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
        
        ProductOptionLineItemQueryUtil.fetchPOLIByProdsAndOpps( New Set<Id>{opp.Id}, New Set<Id>{product.Id});
        Test.stopTest();
    }
}