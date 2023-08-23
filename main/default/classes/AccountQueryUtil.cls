/**************************************************************************************************
 * Class Name: AccountQueryUtil
 * Author: Vinay Vernekar
 * Date: 30th Nov 2021
 * Description: Query util class for Account triggers.
 * Test Class : AccountQueryUtilTest
 **************************************************************************************************/
public with sharing class AccountQueryUtil{
    /*************************************************
    * Method Name: fetchAllLocations
    * Author: Vinay Vernekar
    * Date: 29th Nov 2021
    * Params: Set<String> streets, Set<String> cities, Set<String> states, Set<String> zipCodes, Set<String> countries
    * Return: list of locations
    * Exceptions:
    * Revision: 
    * Description: Fetch all locations by streets, cities, states, zip codes and countries
     *************************************************/
    public static List<Location__c> fetchAllLocations(Set<String> streets, Set<String> cities, Set<String> states, Set<String> zipCodes, Set<String> countries){
        return [Select Id, Name, Address__c, City__c, State_Province__c,
                Postal_Code__c, Country__c, County__c //Ly Long 06/21/2019
                From Location__c Where Address__c IN :streets
                And City__c IN :cities
                And State_Province__c IN :states
                And Postal_Code__c IN :zipCodes
                And Country__c IN :countries
                Limit 50000	];
    }
    /*************************************************
    * Method Name: fetchAccountLocations
    * Author: Vinay Vernekar
    * Date: 29th Nov 2021
    * Params: Set<Id> accountIds
    * Return: 
    * Exceptions:
    * Revision: 
    * Description: Fetch account locations by account ids
     *************************************************/
    public static List<Account_Location__c> fetchAccountLocations(Set<Id> accountIds){
        return [Select Id, Account__c, Location__c From Account_Location__c Where Account__c In: accountIds];
    }

     /*************************************************
    * Method Name: fetchQuotesForOppsAndStatus
    * Author:  
    * Date: 27 Dec 2021
    * Params: Set<String> oppIds
    * Return: list of quote
    * Exceptions:
    * Revision: 
    * Description: Fetch all quotes for opps which are not closed or rejected.
     *************************************************/
    public static List<Account> fetchAccountsById(Set<String> accIds){
        return [Select Id,Name,Current_Assets__c,BillingStateCode,Current_Liabilities__c,Total_Revenues__c,Total_Liabilities__c, BillingCountry,
                Total_Assets__c,Long_Term_Debt__c,Retained_Earnings__c,Net_Income__c from Account where Id in :accIds];
    }

     /*************************************************
    * Method Name: fetchQuotesForOppsAndStatus
    * Author:  
    * Date: 27 Dec 2021
    * Params: Set<String> oppIds
    * Return: list of quote
    * Exceptions:
    * Revision: 
    * Description: Fetch Account by Id
     *************************************************/
    public static List<Account> fetchAccountById(String accId){
        return [SELECT Id, BillingStateCode FROM Account WHERE Id =: accId];
    }

    /*************************************************
    * Method Name: fetchAccountWithContacts
    * Author:  
    * Date: 4th Jan 2022
    * Params: String accId
    * Return: list of account
    * Exceptions:
    * Revision: 
    * Description: Fetch Account with related contacts
     *************************************************/
    public static List<Account> fetchAccountWithContacts(String accId){
        return [SELECT Id, Name, BillingStreet,BillingCity, BillingState, BillingPostalCode,
                BillingCountryCode, Billing_County__c, FEIN__c,
                (SELECT Id, AccountId, Name, MailingStreet, MailingCity, MailingState, MailingPostalCode,
                MailingCountryCode, Mailing_County__c, Home_License_no__c FROM Contacts)
                FROM Account WHERE Id = :accId];
    }

     /*************************************************
    * Method Name: fetchAccountWithContacts
    * Author:  
    * Date: 4th Jan 2022
    * Params: String accId
    * Return: list of account
    * Exceptions:
    * Revision: 
    * Description: Fetch Account with related contact
     *************************************************/
    public static List<Account> fetchAccountWithSpecificContact(String accId, String contactId){
        return  [SELECT Id, Name, BillingStreet,BillingCity, BillingState, 
                BillingPostalCode, BillingCountryCode,Billing_County__c, FEIN__c,
                (SELECT Id, AccountId, Name, MailingStreet, MailingCity, MailingState,
                MailingPostalCode, MailingCountryCode, Mailing_County__c, Home_License_no__c 
                FROM Contacts WHERE Id =: contactId)
                FROM Account WHERE Id = :accId];
    }
    
     /*************************************************
    * Method Name: fetchAccountInfo
    * Author:  RINKU SAINI
    * Date: 11th Jan 2022
    * Params: Set Ids
    * Return: list of account
    * Exceptions:
    * Revision: 
    * Description: 
     *************************************************/
    public static Map<Id,Account> fetchAccountInfo(Set<Id> accountIds ){
        return  New Map<Id,Account>([Select Id,BillingStateCode from Account where Id IN : accountIds]);
    }
}