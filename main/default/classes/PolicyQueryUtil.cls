/**************************************************************************************************
 * Class Name: PolicyQueryUtil
 * Author: 
 * Date: Jan 3, 2021
 * Description: Class to keep policy queries
 * Test Class : PolicyQueryUtilTest
 **************************************************************************************************/
public with sharing class PolicyQueryUtil {
    
    /*************************************************
    * Method Name: fetchPolicyById
    * Author: 
    * Date: 6th Jan 2022
    * Params: String policyId
    * Return: List<Policy__c>
    * Exceptions:
    * Revision: 
    * Description: Fetch policy by Id
     *************************************************/
    public static List<Policy__c> fetchPolicyById(String policyId){
        return [SELECT Id, Account__c, Cancellation_Reason__c, Effective_Date__c, Expiration_Date__c, Master_Binder__c, 
                Layer__c, Policy_Number__c, Total_Premium__c, Product_Name__c, Cancellation_Date__c, RecordType.Name,
                Policy_Status__c, Pending_or_Prior_Proceedings_Date__c, NIPR_Results__c, Binding_License_Number__c 
                From Policy__c Where Id = :policyId];
    }

}