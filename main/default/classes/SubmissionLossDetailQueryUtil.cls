/**************************************************************************************************
 * Class Name: SubmissionLossDetailQueryUtil
 * Author: 
 * Date: 
 * Description: Utility class to hold all queries related to Submission Loss Detail
 * Test Class : 
 **************************************************************************************************/
public with sharing class SubmissionLossDetailQueryUtil {
    /*************************************************
    * Method Name: fetchByAccountLossAndOppStage
    * Author: Vinay Vernekar
    * Date: 13th Dec 2021
    * Params: Set<id> accountLossDetailIds, String stageName
    * Return: list of submission loss details
    * Exceptions:
    * Revision: 
    * Description: Fetch all submission loss detail records
     *************************************************/
    public static List<Submission_Loss_Detail__c> fetchByAccountLossAndOppStage(Set<id> accountLossDetailIds, String stageName){
        return [SELECT Id, Loss_Amount__c, Number_of_Losses__c,
                Product__c, Status__c, Year__c, Submission__c, Account_Loss_Detail__c,
                Account_Loss_Detail__r.Loss_Amount__c, Account_Loss_Detail__r.Number_of_Losses__c,
                Account_Loss_Detail__r.Product__c, Account_Loss_Detail__r.Status__c,
                Account_Loss_Detail__r.Year__c, Submission__r.StageName
            FROM Submission_Loss_Detail__c
            WHERE Account_Loss_Detail__c IN: accountLossDetailIds
            AND Submission__r.StageName =:stageName];
    }
}