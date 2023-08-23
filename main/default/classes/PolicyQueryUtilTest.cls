/**************************************************************************************************
* Class Name: PolicyQueryUtilTest
* Author: RINKU SAINI
* Date: Jan 10, 2022
* Description: 
**************************************************************************************************/
@isTest
public class PolicyQueryUtilTest {
    
    public static testmethod void coverPolicyQueryUtil(){
        Test.startTest();
        
        Account accPersonal = new Account();
        accPersonal.Name = 'Test account 1';
        accPersonal.BillingStreet = '01 Tran Duy Hung';
        accPersonal.BillingCity = 'Westminster';
        accPersonal.BillingState = 'California';
        accPersonal.BillingPostalCode = '90000';
        accPersonal.BillingCountry = 'United States';
        accPersonal.IsMailingSameWithBillingAddress__c = true;
        accPersonal.Date_Started__c = Date.today().addYears(-2);
        insert accPersonal;
        
        
        // create policy  
        Policy__c policy = new Policy__c();
        policy.Account__c = accPersonal.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);           
        insert policy;
        PolicyQueryUtil.fetchPolicyById(policy.Id);
        
        Test.stopTest();
    }
}