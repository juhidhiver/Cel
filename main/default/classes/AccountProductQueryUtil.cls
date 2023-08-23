/**************************************************************************************************
 * Class Name: AccountProductQueryUtil
 * Author: Vinay
 * Date: Dec 07, 2021
 * Description: Class to keep account product queries
 * Test Class : AccountProductQueryUtilTest
 **************************************************************************************************/
public with sharing class AccountProductQueryUtil {
    /*************************************************
    * Method Name: fetchAccountProductsByAccounts
    * Author: Vinay Vernekar
    * Date: 7th Dec 2021
    * Params: AccountId
    * Return: list of Account_Product__c
    * Exceptions:
    * Revision: 
    * Description: Fetch account products
     *************************************************/
    public static List<Account_Product__c> fetchAccountProductsByAccounts(Id AccountId){
        return [select Id,Product_Id__r.Name,Commission_percentage__c from Account_Product__c where Account_Id__c =:AccountId];
    }

    /*************************************************
    * Method Name: fetchAccountProductsByAccountAndProductName
    * Author: Vinay Vernekar
    * Date: 8th March 2022
    * Params: AccountId, ProductName
    * Return: list of Account_Product__c
    * Exceptions:
    * Revision: 
    * Description: Fetch account products
     *************************************************/
    public static List<Account_Product__c> fetchAccountProductsByAccountAndProductName(Id AccountId, String ProductName){
        return [select Id,Product_Id__r.Name, Commission_percentage__c from Account_Product__c where Account_Id__c =:AccountId AND Product_Id__r.Name =: ProductName];
    }
    
     /*************************************************
    * Method Name: fetchAccountProductsByAccountIds
    * Author: RINKU SAINI
    * Date: 3rd Jan 2022
    * Params: AccountIds
    * Return: list of Account_Product__c
    * Exceptions:
    * Revision: 
    * Description: Fetch account products
     *************************************************/
    public static List<Account_Product__c> fetchAccountProductsByAccountIds( List<String> AccountIds ){
        return [Select Id, Commission_percentage__c, Product_Id__c, Product_Id__r.Name, Account_Id__c
                                             From Account_Product__c 
                                             Where Account_Id__c =: AccountIds ];
    }
    
     /*************************************************
    * Method Name: fetchAccountProductsByAccountIds
    * Author: RINKU SAINI
    * Date: 3rd Jan 2022
    * Params: AccountIds
    * Return: list of Account_Product__c
    * Exceptions:
    * Revision: 
    * Description: Fetch account products
     *************************************************/
    public static List<Account_Product__c> getAllAcountProductsByIds( List<Account_Product__c> Ids ){
        return [Select Id, Commission_percentage__c, Product_Id__c, Product_Id__r.Name, Account_Id__c,Account_Id__r.Name
                                             From Account_Product__c 
                                             Where Id =: Ids ];
    }
}