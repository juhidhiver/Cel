/**************************************************************************************************
 * Class Name: AccountLossDetailQueryUtil
 * Author: 
 * Date: 27th Dec 2021
 * Description: Query util class for Account Loss Object.
 **************************************************************************************************/
public with sharing class AccountLossDetailQueryUtil{
     /*************************************************
    * Method Name: fetchAccountLossDetailssByAccountId
    * Author:  
    * Date: 27 Dec 2021
    * Params: Set<String> accIds
    * Return: list of Account_Loss_Detail__c
    * Exceptions:
    * Revision: 
    * Description: Get account loss details for accounts
     *************************************************/
    public static List<Account_Loss_Detail__c> fetchAccountLossDetailsByAccountId(Set<Id> accountIds){
        return [SELECT Id, Name, Account__c, Loss_Amount__c,
                Number_of_Losses__c, OwnerId,Product__c, Status__c, Year__c
                FROM Account_Loss_Detail__c WHERE Account__c IN :accountIds];
    }
}