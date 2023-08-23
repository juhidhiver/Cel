/**************************************************************************************************
* Class Name: OpportunityQueryUtil
* Author: Vinay
* Date: Dec 7th, 2021
* Description: Class to keep opportunity queries
* Test Class : OpportunityQueryUtilTest
**************************************************************************************************/


public with sharing class OpportunityQueryUtil {
        /*************************************************
    * Method Name: fetchOpportunityByIds
    * Author: Vinay Vernekar
    * Date: 7th Dec 2021
    * Params: Set<id> opportunity ids
    * Return: list of opportunities
    * Exceptions:
    * Revision: 
    * Description: Fetch all opportunities
    *************************************************/
    public static List<Opportunity> fetchOpportunityByIds(Set<id> opportunityIds){
        return [Select Id, Agency__c, AccountId, QP_Link__c,Industry__c, Service_Classification__c, Submission_Status__c,
                Coverage_Product_Options__c, Product__r.Name, Product_Name__c,Transaction_Status__c,
                Total_Revenues__c,Innovisk_Entity_ID__c,Type,
                Account.SIC_Code__c, Main_Profession__c,
                Account.SIC_Code__r.SIC_Description__c, Parent_Opportunity__c,
                Account.SIC_Code__r.Crime_Eligibility_Status__c, 
                Account.SIC_Code__r.Cyber_Eligibility_Status__c, 
                Account.SIC_Code__r.D_O_Eligibility_Status__c, 
                Account.SIC_Code__r.EPL_Eligibility_Status__c, 
                Account.SIC_Code__r.Fiduciary_Eligibility_Status__c, 
                Account.SIC_Code__r.MPL_Eligibility_Status__c From Opportunity Where Id IN :opportunityIds];
    }
    
        /*************************************************
    * Method Name: fetchOpportunitiesByAccountAndStage
    * Author: Vinay Vernekar
    * Date: 7th Dec 2021
    * Params: Set<Id> accountIds, String stageName
    * Return: list of opportunities
    * Exceptions:
    * Revision: 
    * Description: Fetch all opportunities by account name and stage name
    *************************************************/
    public static List<Opportunity> fetchOpportunitiesByAccountAndStage(Set<Id> accountIds, String stageName){
        return [SELECT Id, AccountId, Product_Name__c,StageName FROM Opportunity WHERE AccountId IN :accountIds AND StageName =: stageName];
    }
    
        /*************************************************
    * Method Name: fetchSubmissionsWithRelatedQuotes
    * Author: 
    * Date: 
    * Params: set<Id> oppIds
    * Return: 
    * Exceptions:
    * Description: Get Submissions with nested child quotes.
    * Revision: 
    *************************************************/
    public static List<Opportunity> fetchSubmissionsWithRelatedQuotes (set<Id> oppIds){
        return [select id,Submission_Status__c,StageName,Loss_Reason__c,
                (select  Id,Status,Closed_Reason__c FROM Quotes ORDER BY LastModifiedDate DESC) from Opportunity where Id IN : oppIds];
    }
    
   /*************************************************
    * Method Name: fetchSubmissionsFromIds
    * Author: RINKU SAINI
    * Date: 3rd Jan 2022
    * Params: set<Id> oppIds
    * Return: Map of opportunity
    * Exceptions:
    * Description: 
    * Revision: 
    *************************************************/
    public static Map<Id,Opportunity> fetchSubmissionsFromIds (List<String> oppIds){
        return  New Map<Id,Opportunity>([SELECT Id, Product__r.Name, Product_Name__c  FROM Opportunity WHERE Id =: oppIds]);
    }
    
     /*************************************************
    * Method Name: fetchOpportunityWithBrokerById
    * Author: 
    * Date: 3rd Jan 2022
    * Params: String oppId
    * Return: Map of opportunity
    * Exceptions:
    * Description: 
    * Revision: 
    *************************************************/
    public static List<Opportunity> fetchOpportunityWithBrokerById (String oppId){
        return  [SELECT Id, 
                (SELECT Broker_Contact__c, Broker_Contact__r.AccountId 
                FROM Opportunity_Accounts1__r 
                WHERE IsPrimaryBroker__c = true LIMIT 1) 
                FROM Opportunity 
                WHERE Id =: oppId LIMIT 1];
    }

   /*************************************************
    * Method Name: fetchOpportunityByIdsSet
    * Author: RINKU SAINI
    * Date: 3rd Jan 2022
    * Params: Set<String> opportunity ids
    * Return: list of opportunities
    * Exceptions:
    * Revision: 
    * Description: Fetch all opportunities
    *************************************************/
    public static List<Opportunity> fetchOpportunityByIdsSet(Set<String> opportunityIds){
        return [SELECT Id,AccountId, Account.BillingStreet, Account.BillingCity, 
                  Account.BillingPostalCode,
                  Account.BillingState, Account.BillingStateCode,Account.BillingCountry,
                  Account.Billing_County__c,Account.BillingCountryCode,
                  Account.BillingLongitude, Account.BillingLatitude
                  FROM Opportunity WHERE Id IN :opportunityIds];
    }
    
   /*************************************************
    * Method Name: fetchSubmissionsFromIdswithProductOption
    * Author: RINKU SAINI
    * Date: 3rd Jan 2022
    * Params: set<Id> oppIds
    * Return: Map of opportunity
    * Exceptions:
    * Description: 
    * Revision: 
    *************************************************/
    public static Map<Id,Opportunity> fetchSubmissionsFromIdswithProductOption (Set<Id> oppIds){
        return  New Map<Id,Opportunity>([Select id,(Select id,Product__r.Name
                                                    from Product_Option_Line_Items__r where Clearance_Status__c = 'Cleared')
                                         from Opportunity where id in: oppIds]);
    }

      /*************************************************
    * Method Name: fetchOpportunityById
    * Author: 
    * Date: 3rd Jan 2022
    * Params: String oppId
    * Return: opportunity record
    * Exceptions:
    * Description: 
    * Revision: 
    *************************************************/
    public static List<Opportunity> fetchOpportunityById (String oppId){
        return [Select Id, StageName,Product__r.Name, Transaction_Status__c, Parent_Opportunity__c, Type from Opportunity where Id=:oppId];
    }

    /*************************************************
    * Method Name: fetchPCCOpportunityByIds
    * Author: Vinay Vernekar
    * Date: 19th Jan 2022
    * Params: Set<id> opportunity ids
    * Return: list of opportunities
    * Exceptions:
    * Revision: 
    * Description: Fetch PCC opportunities
    *************************************************/
    public static List<Opportunity> fetchPCCOpportunityByIds(Set<id> opportunityIds){
        return [SELECT Id,StageName,Type,No_of_Quotes__c from Opportunity where Id in: opportunityIds and Product_Name__c =: GlobalVariables.PROD_NAME_FOR_PCC];
    }
}