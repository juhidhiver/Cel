/*************************************************
* Class Name: BrokerAccountTriggerHandler 
* Author: Long Ly
* Date: 2019 August 08
* Requirement/Project Description: Trigger to handle automation on Broker Account
*************************************************/
public class BrokerAccountTriggerHandler extends TriggerHandler {
    
    private List<Broker_Account__c> oldDataList;
    private List<Broker_Account__c> newDataList;
    private Map<Id, Broker_Account__c> newDataMap;
    private Map<Id, Broker_Account__c> oldDataMap;
    
     public BrokerAccountTriggerHandler () {
        this.oldDataList = (List<Broker_Account__c>) Trigger.old;
        this.newDataList = (List<Broker_Account__c>) Trigger.new;
        this.newDataMap = (Map<Id, Broker_Account__c>) Trigger.newMap;
        this.oldDataMap = (Map<Id, Broker_Account__c>) Trigger.oldMap;
    }
    
    public override void beforeInsert(){
       brokerAccountValidation(newDataList, null);      
    }

    public override void afterInsert(){
        //Update Primary Broker Name and Email when changing the 'Primary Broker' field
        updateQuotesWithPrimaryBrokerName(newDataList, null);  
        
        //Update AQ Quote which is Rated 
        updateQuoteStatusAQ(newDataList);
        
        //update quotes broker
        updateQuotesContactOnBrokerchange(newDataList);
    }

     public override void beforeUpdate(){
       brokerAccountValidation(newDataList, oldDataMap);
    }

    public override void afterUpdate(){
        //Update Primary Broker Name and Email when changing the 'Primary Broker' field
        updateQuotesWithPrimaryBrokerName(newDataList, oldDataMap); 
        
        //Update AQ Quote which is Rated 
        updateQuoteStatusAQ(newDataList);
    }
    
    public override void afterDelete(){
        //Update AQ Quote which is Rated 
        updateQuoteStatusAQ(oldDataList);
    }

    /*************************************************
    * Author: Hoang Bui
    * Date: 29-Oct-2019
    * Params: brokerAccounts, oldBrokerAccountsMap
    * Return: set<Id> of Opp
    * Description: Return the list of opp have primary Broker Account
    * Revision: 
    *************************************************/
    public static Set<Id> getPrimaryBrokerOpps(List<Broker_Account__c> newBrokerAccounts){
        Set<Id> oppIds = new Set<Id>();
        for(Broker_Account__c broker : newBrokerAccounts){
            oppIds.add(broker.Opportunity__c);

        }

        Set<Id> primaryBrokerOppSet = new Set<Id>();
        for(Broker_Account__c broker : [Select Id, Opportunity__c 
                                        From Broker_Account__c 
                                        Where IsPrimaryBroker__c =true and Opportunity__c in :oppIds]){
            
            primaryBrokerOppSet.add(broker.Opportunity__c);                                                                    
        }
        return primaryBrokerOppSet;
    }

    /*************************************************
    * Author: Long Ly
    * Date: 23-Aug-2019
    * Params: brokerAccounts, oldBrokerAccountsMap
    * Return: 
    * Description: brokerAccountValidation follow the task 3824
    * Revision: 
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
    /*---------------------------------------------------------------------
    * Author: Khanh TRAN
    * Date: 2019 Sept 30
    * Description: Update Broker Name and Broker Email when Primary Broker changes
    * ---------------------------------------------------------------------*/
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
        for(Broker_Account__c objBrokerAccount : [SELECT 
                                                    Id, Opportunity__c,
                                                    Broker_Contact__r.AccountId,
                                                    Broker_Contact__r.Email 
                                                  FROM Broker_Account__c WHERE Id IN :brokerAccountIds]) 
        {
            mapOppBrokerAcc.put(objBrokerAccount.Opportunity__c, objBrokerAccount);
        }
        List<Quote> listQuote = [SELECT Id, OpportunityId ,Broker__c, Broker_Email__c
                                 FROM Quote 
                                 WHERE OpportunityId IN : mapOppBrokerAcc.keySet()];
        
        System.debug('@@@mapOppBrokerAcc.keySet()@@@ '+mapOppBrokerAcc.keySet());
            
        //Starting - The Agency should be updated to the new Primary Broker Account - Prachi - 14Jan21
        List<Opportunity> oppUpdate = [Select Id, Agency__c From Opportunity Where Id IN :mapOppBrokerAcc.keySet()];
        for (Opportunity oppt : oppUpdate){ 
            oppt.Agency__c = mapOppBrokerAcc.get(oppt.Id).Broker_Contact__r.AccountId;
        }
        TriggerHandler.bypass('OpportunityTriggerHandler');
        update oppUpdate;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        //Ending

        for(Quote quote : listQuote) {            
            quote.Broker__c = mapOppBrokerAcc.get(quote.OpportunityId).Broker_Contact__c;
            quote.Broker_Email__c = mapOppBrokerAcc.get(quote.OpportunityId).Broker_Contact__r.Email;
        }
        update listQuote;
    }

    private static void updateQuoteStatusAQ(List<Broker_Account__c> brokerAccounts){
        Set<Id> oppIds = new Set<Id>();
        for(Broker_Account__c brokerAcc:brokerAccounts){
            oppIds.add(brokerAcc.Opportunity__c);
        }

        List<Quote> updateQuote = new List<Quote>();
        for(Quote quote:[SELECT Id, Status, OpportunityId, Product_Name__c FROM Quote WHERE OpportunityId IN:oppIds]){
            if(quote.status == 'Quoted' && quote.Product_Name__c == 'Professional Indemnity'){
                quote.status = 'Rated';
            }
            updateQuote.add(quote);
        }

        if(updateQuote.size()>0){
            update updateQuote;
        }
    }
    
    public static void updateQuotesContactOnBrokerchange(List<Broker_Account__c> newBrokerAccounts){
        Map<Id,Broker_Account__c> brokerAccountMap = new Map<Id,Broker_Account__c>();
        List<Account_Product__c> accProd = new List<Account_Product__c>();
        string AccountId;
        for(Broker_Account__c brokerAcc:newBrokerAccounts){
            brokerAccountMap.put(brokerAcc.Opportunity__c,brokerAcc);
        }
        
        List<Quote> updateQuote = new List<Quote>();
        
        try{
            for(Quote quote:[SELECT Id, Status, Broker__c,OpportunityId, Product_Name__c FROM Quote WHERE OpportunityId IN:brokerAccountMap.keySet()]){
                if(quote.Product_Name__c == 'Professional Indemnity'){
                    string brokerContact = brokerAccountMap.get(quote.OpportunityId).Broker_Contact__c;
                    if(string.isNotBlank(brokerContact)){
                        AccountId = [select Id,AccountId from contact where Id =:brokerContact].AccountId;
                    }
                    
                    if(string.isNotBlank(AccountId)){
                        accProd = [select Id,Product_Id__r.Name,Commission_percentage__c from Account_Product__c where Account_Id__c =:AccountId];
                    }
                    
                    if(quote.Broker__c == null){
                        quote.Broker__c = brokerAccountMap.get(quote.OpportunityId).Broker_Contact__c;
                    }
                    
                    if(!accProd.isEmpty()){
                        for(Account_Product__c acc: accProd){
                            if(acc.Product_Id__r.Name == quote.Product_Name__c){
                                if(acc.Commission_percentage__c != null){
                                    quote.Commission_percentage__c = acc.Commission_percentage__c;
                                }
                            }
                        }
                    }
                }
                updateQuote.add(quote);
            }
            
            if(updateQuote.size()>0){
                update updateQuote;
            }
        }catch(Exception ex){
            String errorMsg = CommonUtil.getExceptionMessage(ex);
            for (Broker_Account__c brokerAcc : (List<Broker_Account__c>) Trigger.new){
                brokerAcc.addError(errorMsg);
            }
        }
    }
}