/**************************************************************************************************
 * Class Name: ProductQueryUtil
 * Author: Vinay
 * Date: Dec 22nd, 2021
 * Description: Class to keep product queries
 * Test Class :  ProductQueryUtilTest
 **************************************************************************************************/
public with sharing class ProductQueryUtil {
    /*************************************************
    * Method Name: fetchProductsByIds
    * Author: Vinay Vernekar
    * Date: 7th Dec 2021
    * Params: Set<id> productIds
    * Return: list of products
    * Exceptions:
    * Revision: 
    * Description: Fetch products by ids
     *************************************************/
    public static List<Product2> fetchProductsByIds(Set<id> productIds){
        return [Select Name From Product2 Where Id in: productIds];
    }


    /*************************************************
    * Method Name: getProductsForAccountProductCreation
    * Author: Maeran Shaikh
    * Date: 1th Feb 2022
    * Params: 
    * Return: list of products
    * Exceptions:
    * Revision: 
    * Description: will fetch all Active Celerity products which are not child 
     *************************************************/
    public static List<Product2> getProductsForAccountProductCreation(){
        return [Select Id, Name, RecordType.Id, RecordType.Name,Carrier_Commission__c From Product2 WHERE
        IsActive = true AND RecordType.Name =:GlobalVariables.CELERITY and IsComboProduct__c = false];
    }
}