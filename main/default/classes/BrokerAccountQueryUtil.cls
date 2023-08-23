/**************************************************************************************************
 * Class Name: BrokerAccountQueryUtil
 * Author: Vinay
 * Date: Dec 4th, 2021
 * Description: Class to keep Broker account queries
 * Test Class : 
 **************************************************************************************************/
public with sharing class BrokerAccountQueryUtil {
    /*************************************************
    * Method Name: fetchPrimaryBrokerAccounts
    * Author: Vinay Vernekar
    * Date: 4th Dec 2021
    * Params: Set<id> contactIds
    * Return: list of broker accounts
    * Exceptions:
    * Revision: 
    * Description: Fetch all primary broker accounts
     *************************************************/
    public static List<Broker_Account__c> fetchPrimaryBrokerAccounts(Set<id> contactIds){
        return [SELECT Id, Opportunity__c, Broker_Contact__r.AccountId, Broker_Contact__r.Email  FROM Broker_Account__c WHERE IsPrimaryBroker__c = true  AND Broker_Contact__c IN :contactIds];
    }
    /*************************************************
    * Method Name: fetchPrimaryBrokerAccountsByOpp
    * Author: Vinay Vernekar
    * Date: 7th Dec 2021
    * Params: Set<id> opportuntyIds
    * Return: list of broker accounts
    * Exceptions:
    * Revision: 
    * Description: Fetch all primary broker accounts
     *************************************************/
    public static List<Broker_Account__c> fetchPrimaryBrokerAccountsByOpp(Set<id> opportuntyIds){
        return [Select Id, Opportunity__c From Broker_Account__c Where IsPrimaryBroker__c =true and Opportunity__c in :opportuntyIds];
    }
    /*************************************************
    * Method Name: fetchBrokerAccountsByIds
    * Author: Vinay Vernekar
    * Date: 7th Dec 2021
    * Params: Set<id> brokerAccountIds
    * Return: list of broker accounts
    * Exceptions:
    * Revision: 
    * Description: Fetch all primary broker accounts
     *************************************************/
    public static List<Broker_Account__c> fetchBrokerAccountsByIds(Set<id> brokerAccountIds){
        return [SELECT Id, Opportunity__c,Broker_Contact__r.AccountId,Broker_Contact__r.Email FROM Broker_Account__c WHERE Id IN :brokerAccountIds];
    }

    /*************************************************
    * Method Name: fetchPrimaryBrokerAccountsForOpp
    * Author: 
    * Date: 4th Jan 2022
    * Params: Set<id> opportuntyIds
    * Return: list of broker accounts
    * Exceptions:
    * Revision: 
    * Description: Fetch all primary broker accounts
     *************************************************/
    public static List<Broker_Account__c> fetchPrimaryBrokerAccountsForOpp(String opportunityId){
        return [SELECT Id,IsPrimaryBroker__c,Broker_Contact__c, Broker_Contact__r.AccountId, Broker_Contact__r.Name
                FROM Broker_Account__c 
                WHERE Opportunity__c =: opportunityId
                AND IsPrimaryBroker__c = true];
    }
}