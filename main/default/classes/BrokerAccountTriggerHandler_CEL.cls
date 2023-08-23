/**************************************************************************************************
 * Class Name: BrokerAccountTriggerHandler_CEL
 * Author: 
 * Date: 
 * Description: Class to keep method related to Celerity
 * Test Class : BrokerAccountTriggerHandlerTest
 **************************************************************************************************/
public with sharing class BrokerAccountTriggerHandler_CEL extends TriggerHandler{
    private List<Broker_Account__c> oldDataList;
    private List<Broker_Account__c> newDataList; 
    private Map<Id, Broker_Account__c> newDataMap;
    private Map<Id, Broker_Account__c> oldDataMap; 
    
    public BrokerAccountTriggerHandler_CEL(List<Broker_Account__c> newDataList, List<Broker_Account__c> oldDataList, Map<Id, Broker_Account__c> newDataMap, Map<Id, Broker_Account__c> oldDataMap){
        this.oldDataList = oldDataList;
        this.newDataList = newDataList;
        this.newDataMap = newDataMap;
        this.oldDataMap = oldDataMap;
    } 

	public override void beforeInsert()	{
        //validation for broker account
        CommonBrokerAccountUtil.brokerAccountValidation(newDataList, oldDataMap);
    }

    public override void beforeUpdate(){
        //validation for broker account
        CommonBrokerAccountUtil.brokerAccountValidation(newDataList, oldDataMap);
    }

	public override void afterInsert(){
        //Update Primary Broker Name and Email when changing the 'Primary Broker' field
        CommonBrokerAccountUtil.updateQuotesWithPrimaryBrokerName(newDataList, null);  

    }

	public override void afterUpdate(){
        //Update Primary Broker Name and Email when changing the 'Primary Broker' field
        CommonBrokerAccountUtil.updateQuotesWithPrimaryBrokerName(newDataList, oldDataMap); 
    }

    public override void beforeDelete(){
        //prevent deleting broker account if Opportunity type is Full Amedment or Stage is Closed Won, Closed Lost or Declient or No of quotes are greater than 0
        PCC_preventDeletion(oldDataList); 
    }

    /*************************************************
    * Method Name: preventDeletion
    * Author: Vinay Vernekar
    * Date: 01/18/2022
    * Params: List of Broker Accounts
    * Return: prevent deleting broker account if Opportunity type is Full Amedment or Stage is Closed Won, Closed Lost or Declient or No of quotes are greater than 0
    * Description: get Opportunity field Map
    * Revision: 
    *************************************************/
    public void PCC_preventDeletion(List<Broker_Account__c> oldList){
        Set<id> submissionIds = new Set<id>();
        for(Broker_Account__c brokerAccount : oldList){
            submissionIds.add(brokerAccount.Opportunity__c);
        }
        if(!submissionIds.isEmpty()){
            Map<Id, Opportunity> opportunityMap = new Map<id, Opportunity>(OpportunityQueryUtil.fetchPCCOpportunityByIds(submissionIds));
            for(Broker_Account__c brokerAccount : oldList){
                if(opportunityMap.containsKey(brokerAccount.Opportunity__c)){
                    Opportunity opp = opportunityMap.get(brokerAccount.Opportunity__c);
                    if(opp.Type == 'Full Amendment')
                        brokerAccount.addError('You cannot delete full amendment submission.');
                    if(opp.StageName == 'Closed Won' || opp.StageName == 'Closed Lost' || opp.StageName == 'Declined' || opp.No_of_Quotes__c > 0)
                        brokerAccount.addError('You cannot delete locked submission.');
                }
            }
        }
    }
}