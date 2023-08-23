/**************************************************************************************************
* Class Name: AccountProductQueryUtilTest
* Author: Rinku Saini
* Date: 3rd Dec 2022
* Description: Class to keep account product queries
**************************************************************************************************/
@isTest
public class AccountProductQueryUtilTest {
    
    public static testmethod void coverAccountProductQueryUtil(){
        List<Account_Product__c> acp = new List<Account_Product__c>();
        Test.startTest();
        
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account chanAcc  =TestUtil.createAccount('Test Channel Account', recordTypeId, '01 Tran Duy Hung','Westminster',
                                                 'California','90000', 'United States');
        chanAcc.Azure_ID__c = '407a8180-7cf0-4c74-99d0-4c194723916e';
        insert chanAcc;
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
        insert product; 
        
        Product2 product2 = TestUtil.createProduct('Cyber Standalone');
        insert product2; 
        
        Account_Product__c accProd1 = new Account_Product__c();
        accProd1.Account_Id__c = chanAcc.Id;
        accProd1.Product_Id__c = product2.id;
        insert accProd1;
        acp.add(accProd1);
        
        AccountProductQueryUtil.fetchAccountProductsByAccounts(chanAcc.Id);
        AccountProductQueryUtil.fetchAccountProductsByAccountIds( New List<String>{chanAcc.Id});
        AccountProductQueryUtil.fetchAccountProductsByAccountAndProductName(chanAcc.Id,product2.Name);
        AccountProductQueryUtil.getAllAcountProductsByIds(acp);
       // AccountProductQueryUtil.getAllAcountProductsByIds(acp);
        
        Test.stopTest();
    }
}