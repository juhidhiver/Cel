/**************************************************************************************************
 * Class Name: ProductOptionLineItemQueryUtil
 * Author: Vinay
 * Date: Dec 22nd, 2021
 * Description: Class to keep product option line item queries
 * Test Class : ProductOptionLineItemQueryUtilTest
 **************************************************************************************************/
public with sharing class ProductOptionLineItemQueryUtil {
    /*************************************************
    * Method Name: fetchPOLIByProdsAndOpps
    * Author: Vinay Vernekar
    * Date: 22nd Dec 2021
    * Params: opportunity ids and product ids
    * Return: list of product option line items
    * Exceptions:
    * Revision: 
    * Description: Fetch product option line items by opportunity ids and product ids
     *************************************************/
    public static List<Product_Option_Line_Item__c> fetchPOLIByProdsAndOpps(Set<Id> opportunityIds, Set<Id> productIds){
        return [Select Submission__c, Product__c, Product__r.Name From Product_Option_Line_Item__c Where Submission__c In :opportunityIds And Product__c In :productIds];
    }

    /*************************************************
    * Method Name: fetchPOLIByOpps
    * Author: Jai
    * Date: Jan 11 2022
    * Params: opportunity ids and fields to query
    * Return: list of product option line items
    * Exceptions:
    * Revision: 
    * Description: Fetch product option line items by opportunity ids and product ids
     *************************************************/
    public static List<Product_Option_Line_Item__c> fetchPOLIByOpps(Set<String> opportunityIds, String fields ){
        String queryStr = 'Select '+fields+' From Product_Option_Line_Item__c where Submission__c IN :opportunityIds';
        return (List<Product_Option_Line_Item__c>) database.query(queryStr);
    }

}