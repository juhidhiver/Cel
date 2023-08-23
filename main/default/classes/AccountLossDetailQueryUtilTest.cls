/**************************************************************************************************
* Class Name: AccountLossDetailQueryUtilTest
* Author:  RINKU SAINI
* Date: 30th Dec 2021
* Description: 
**************************************************************************************************/

@isTest
public class AccountLossDetailQueryUtilTest {
    
    public static testmethod void coverFetchAccountLossDetailsByAccountId(){
        Test.startTest();
        
        Account accPersonal = new Account();
        accPersonal.Name = 'Test account 1';
        accPersonal.BillingStreet = '123 Main Street';
        accPersonal.BillingCity = 'Anycity';
        accPersonal.BillingState = 'England';
        accPersonal.BillingPostalCode = '11354';
        accPersonal.BillingCountry = 'United Kingdom';
        accPersonal.IsMailingSameWithBillingAddress__c = true;
        accPersonal.Date_Started__c = Date.today().addYears(-2);
        insert accPersonal;
        
        Account_Loss_Detail__c accountLoss = new Account_Loss_Detail__c();
        accountLoss.Account__c = accPersonal.Id;
        //accountLoss.Product__c = 'Cyber';
        accountLoss.Loss_Amount__c = 123;
        accountLoss.Status__c = 'Open';
        accountLoss.Year__c = '2020';
        accountLoss.Number_of_Losses__c = 23;
        insert accountLoss;
        
        AccountLossDetailQueryUtil.fetchAccountLossDetailsByAccountId( New Set<Id>{accPersonal.Id});
        
        Test.stopTest();
    }
}