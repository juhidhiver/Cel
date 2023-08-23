/**************************************************************************************************
 * Class Name: ReferralReasonQueryUtil
 * Author: 
 * Date: Jan 3, 2021
 * Description: Class to keep Referral Reason queries
 * Test Class : ReferralReasonQueryUtilTest
 **************************************************************************************************/
public with sharing class ReferralReasonQueryUtil {
    /*************************************************
    * Method Name: fetchRefReasonsByQuoteId
    * Author: 
    * Date: 22 Dec 2021
    * Params: Id quoteId
    * Return: List<Referral_Reason__c> 
    * Exceptions:
    * Revision: 
    * Description: Fetch Referral Reasons
     *************************************************/
    public static List<Referral_Reason__c> fetchRefReasonsByQuoteId(Id quoteId){
        return [SELECT Id,Name,Approval_Level_Required__c,Approval_Status__c,
                Approval_Rejected_Date__c,Approver_Level__c,Approved_By__c,Option_Id__c,
                Entity_Path__c,Reason__c,Reason_Type__c,Status__c,Approved_By__r.Name,
                Quote_Option__c,Quote_Option__r.Selected__c,Option_Type__c,Option_Limit__c 
                From Referral_Reason__c                                                               
                Where Quote__c=:quoteId];
    }

}