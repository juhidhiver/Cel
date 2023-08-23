/**************************************************************************************************
 * Class Name: AccountCommissionQueryUtil
 * Author: Juhi
 * Date: Jul 20,2022
 * Description: Class to keep account commissiom template queries
 * Test Class : AccountCommissionQueryUtilTest
 **************************************************************************************************/
public without sharing class AccountCommissionQueryUtil {
    
      public static List<Account_Commission_Template__c> fetchAccountCommissionByAccounts(){
        return [Select id,Wholesaler__c, Cyber_Default__c from Account_Commission_Template__c];
    }

}