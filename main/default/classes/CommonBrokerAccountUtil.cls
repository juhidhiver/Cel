public with sharing class CommonBrokerAccountUtil {
    /*************************************************
    * Method Name: brokerAccountValidation
    * Author: Long Ly
    * Date: 23-Aug-2019
    * Params: brokerAccounts, oldBrokerAccountsMap
    * Return: 
    * Description: brokerAccountValidation follow the task 3824
    * Revision: 
    * Can be done with flows: Yes
    *************************************************/
    public static void brokerAccountValidation(List<Broker_Account__c> brokerAccounts, Map<Id, Broker_Account__c> oldBrokerAccountsMap){
        system.debug('@@@ -------------------- BrokerAccountTriggerHandler.brokerAccountValidation --------------------');
        
        /* 1. Find all other Opportunties for that Business Account and check if any of the open Opportunites 
        (i.e. Not Closed Lost or Declined) are assigned to a different Primary Broker than the one attempting 
        to be added to the current Opportunity. If No there is no conflict, allow Broker Account to be saved , 
        if Yes go  to #2 */
        Map<String, Broker_Account__c> mapBrokerbyOpptAccountNew = new Map<String, Broker_Account__c>();
        //Set<Id> opportunityIds = new Set<Id>();
       // Set<Id> contactIds = new Set<Id>();
        Set<Id> primaryBrokerOppSet = getPrimaryBrokerOpps(brokerAccounts);
        //system.debug('brokerAccounts='+brokerAccounts);
        for(Broker_Account__c broker : brokerAccounts) {
            //Check if the exist primary in the same Oppt first
            if(broker.IsPrimaryBroker__c){
                if(
                    ((oldBrokerAccountsMap !=null && !oldBrokerAccountsMap.get(broker.Id).IsPrimaryBroker__c) // is edit
                    || oldBrokerAccountsMap == null)  // insert new
                    && primaryBrokerOppSet != null && primaryBrokerOppSet.contains(broker.Opportunity__c)){ //check if it exist primary
                    broker.addError(Label.PRIMARY_BROCKER_ACCOUNT_DUPLICATE_SAME_OPPT_MSG);
                    continue;
                } 
            }
            if (broker.Broker_Block_Override__c == true || oldBrokerAccountsMap != null){ //check bypass or edit
                //When Underwriter checks the box Broker Block Override, the Blocking algorithm should ignore the block and allow the Broker to be saved to the related Opportunity.                      
                continue;
            } 

            // check if exist
            //system.debug('broker.Broker_Contact__c='+broker.Broker_Contact__c);
            String key = String.valueOf(broker.Opportunity__c) + String.valueOf(broker.Broker_Contact__c);
            if(mapBrokerbyOpptAccountNew.containsKey(key)){
                broker.addError(Label.BROCKER_ACCOUNT_DUPLICATE_SAME_OPPT_MSG);
                continue;
            }else{
                mapBrokerbyOpptAccountNew.put(key, broker);
            }
        }
    }
    /*************************************************
    * Method Name: updateQuotesWithPrimaryBrokerName
    * Author: Hoang Bui
    * Date: 29-Oct-2019
    * Params: brokerAccounts, oldBrokerAccountsMap
    * Return: set<Id> of Opp
    * Exceptions:
    * Description: Return the list of opp have primary Broker Account
    * Revision: 
    * Can be done with flows: Yes
     *************************************************/
    public static Set<Id> getPrimaryBrokerOpps(List<Broker_Account__c> newBrokerAccounts){
        Set<Id> oppIds = new Set<Id>();
        for(Broker_Account__c broker : newBrokerAccounts){
            oppIds.add(broker.Opportunity__c);

        }

        Set<Id> primaryBrokerOppSet = new Set<Id>();
        for(Broker_Account__c broker : BrokerAccountQueryUtil.fetchPrimaryBrokerAccountsByOpp(oppIds)){
            primaryBrokerOppSet.add(broker.Opportunity__c);                                                                    
        }
        return primaryBrokerOppSet;
    }
    /*************************************************
    * Method Name: updateQuotesWithPrimaryBrokerName
    * Author:Khanh TRAN
    * Date: 2019 Sept 30
    * Params: List<Broker_Account__c> newBrokerAccounts
    * Return: 
    * Exceptions:
    * Description: Update Broker Name and Broker Email when Primary Broker changes
    * Revision: 
    * Can be done with flows: Yes
     *************************************************/
    public static void updateQuotesWithPrimaryBrokerName(
        List<Broker_Account__c> newBrokerAccounts, Map<Id, Broker_Account__c> oldBrokerAccountsMap){
        Set<Id> brokerAccountIds = new Set<Id>();
        for(Broker_Account__c item : newBrokerAccounts){
            System.debug('###newBrokerAccounts###'+newBrokerAccounts);
            if(item.IsPrimaryBroker__c && oldBrokerAccountsMap == null) 
                brokerAccountIds.add(item.Id);
            else if(item.IsPrimaryBroker__c && !oldBrokerAccountsMap.get(item.Id).IsPrimaryBroker__c) 
                brokerAccountIds.add(item.Id);
            
        }
        if(brokerAccountIds.isEmpty()) return;
       
        Map<Id, Broker_Account__c> mapOppBrokerAcc = new Map<Id, Broker_Account__c>();
        for(Broker_Account__c objBrokerAccount : BrokerAccountQueryUtil.fetchBrokerAccountsByIds(brokerAccountIds)) 
        {
            mapOppBrokerAcc.put(objBrokerAccount.Opportunity__c, objBrokerAccount);
        }
        List<Quote> listQuote = QuoteQueryUtil.fetchQuotesByOpportunties(mapOppBrokerAcc.keySet());
        
        System.debug('@@@mapOppBrokerAcc.keySet()@@@ '+mapOppBrokerAcc.keySet());
            
        //Starting - The Agency should be updated to the new Primary Broker Account - Prachi - 14Jan21
        List<Opportunity> oppUpdate = OpportunityQueryUtil.fetchOpportunityByIds(mapOppBrokerAcc.keySet());
        for (Opportunity oppt : oppUpdate){ 
            oppt.Agency__c = mapOppBrokerAcc.get(oppt.Id).Broker_Contact__r.AccountId;
        }
        TriggerHandler.bypass('SubmissionTriggerBaseHandler');
        update oppUpdate;
        TriggerHandler.clearBypass('SubmissionTriggerBaseHandler');
        //Ending

        for(Quote quote : listQuote) {            
            quote.Broker__c = mapOppBrokerAcc.get(quote.OpportunityId).Broker_Contact__c;
            quote.Broker_Email__c = mapOppBrokerAcc.get(quote.OpportunityId).Broker_Contact__r.Email;
        }
        update listQuote;
    }    
}