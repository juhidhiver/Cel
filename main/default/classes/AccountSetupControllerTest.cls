@isTest
public with sharing class AccountSetupControllerTest {
    static testMethod void checkCountryCodepicklist() {
        sObject account = new Account();
        List <List<String>> allOpts = AccountSetupController.getselectOptions(account, 'Country_Code__c');
        System.assert(allOpts.size()>0,'Failed because: Account.Country_Code__c is not having values: ');
    }
}