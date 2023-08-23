/**************************************************************************************************
 * Class Name: NIPRController
 * Author:
 * Date:
 * Description:
 * Revision: 
 **************************************************************************************************/
global with sharing class NIPRController {
    @AuraEnabled
    global static String niprAPI(String fein){
        return Invsk_Callout.getNIPR(fein);
    }
    /*
    @AuraEnabled
    global static String niprAPIAcct(String accountId){
        Account acct = [SELECT FEIN__c FROM Account WHERE Id =: accountId LIMIT 1];
        return Invsk_Callout.getNIPR(acct.FEIN__c);
    }
	*/
}