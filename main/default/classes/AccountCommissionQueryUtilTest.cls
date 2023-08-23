/**************************************************************************************************
* Class Name: AccountCommissionQueryUtilTest
* Author: JUHI 
* Date: 
* Description: Class to keep account commission test queries
**************************************************************************************************/
@isTest
public class AccountCommissionQueryUtilTest {
    
    public static testmethod void coverAccountCommissionQueryUtil(){
        Test.startTest();
        
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account chanAcc  =TestUtil.createAccount('Test Channel Account', recordTypeId, '01 Tran Duy Hung','Westminster',
                                                 'California','90000', 'United States');
        chanAcc.Azure_ID__c = '407a8180-7cf0-4c74-99d0-4c194723916e';
        insert chanAcc;
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
        insert product; 
        
         
        Account_Product__c accProd1 = new Account_Product__c();
        accProd1.Account_Id__c = chanAcc.Id;
        accProd1.Product_Id__c = product.id;
        insert accProd1;
        
        Account_Commission_Template__c ac = new Account_Commission_Template__c();
        ac.Wholesaler__c = 'Test Channel Account';
        ac.Cyber_Default__c = 20;
        insert ac;
        
        AccountCommissionQueryUtil.fetchAccountCommissionByAccounts();
        Test.stopTest();
    }
}