/**************************************************************************************************
 * Class Name: BrokerAccountTriggerHandler_AQ
 * Author: 
 * Date: 
 * Description: Class to keep method related to AQ
 * Test Class : BrokerAccountTriggerHandlerTest
 **************************************************************************************************/
public with sharing class BrokerAccountTriggerHandler_AQ extends TriggerHandler{
    private List<Broker_Account__c> oldDataList;
    private List<Broker_Account__c> newDataList; 
    private Map<Id, Broker_Account__c> newDataMap;
    private Map<Id, Broker_Account__c> oldDataMap; 
    
    public BrokerAccountTriggerHandler_AQ(List<Broker_Account__c> newDataList, List<Broker_Account__c> oldDataList, Map<Id, Broker_Account__c> newDataMap, Map<Id, Broker_Account__c> oldDataMap){
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
        //CommonBrokerAccountUtil.updateQuotesWithPrimaryBrokerName(newDataList, null);
        updateQuotesWithPrimaryBrokerName(newDataList, null);  //added local function to add code for contact change for #55120
                
        //Update AQ Quote which is Rated 
        updateQuoteStatusAQ(newDataList);

        //Update quote broker and commission percentage
        updateQuotesContactOnBrokerchange(newDataList);

        //Update commission percentage for Aqueous
        updateCommissionPercentage(newDataList);
    }

	public override void afterUpdate(){
        //Update commission percentage for Aqueous
        updateCommissionPercentage(newDataList);

        //Update Primary Broker Name and Email when changing the 'Primary Broker' field
        //CommonBrokerAccountUtil.updateQuotesWithPrimaryBrokerName(newDataList, oldDataMap); 
        updateQuotesWithPrimaryBrokerName(newDataList, oldDataMap); //added local function to add code for contact change for #55120
                
        //Update AQ Quote which is Rated 
        updateQuoteStatusAQ(newDataList);
    }

	public override void afterDelete(){
        //Update AQ Quote which is Rated 
        updateQuoteStatusAQ(oldDataList);
    }

    /*************************************************
    * Method Name: updateCommissionPercentage
    * Author:
    * Date: 
    * Params: List<Broker_Account__c>, Map<id, Broker_Account__c>
    * Return: 
    * Exceptions:
    * Description: Update commission percentage from account product to quote
    * Revision: 
    * Can be done with flows: Yes
     *************************************************/
    public static void updateCommissionPercentage(List<Broker_Account__c> newBrokerAccounts){
        Set<Id> primaryBrokerAccountIds = new Set<Id>();
        for(Broker_Account__c brokerAcc : newBrokerAccounts){
            if(brokerAcc.IsPrimaryBroker__c){
                primaryBrokerAccountIds.add(brokerAcc.Id);
            }
        }
        if(!primaryBrokerAccountIds.isEmpty()){
            Map<String, String> oppAccMap = new Map<String, String>();
            Set<Id> accountIds = new Set<Id>();
            Set<Id> opportunityIds = new Set<Id>();
            List<Broker_Account__c> brokerAccounts = BrokerAccountQueryUtil.fetchBrokerAccountsByIds(primaryBrokerAccountIds);
            for(Broker_Account__c brokerAcc : brokerAccounts){
                accountIds.add(brokerAcc.Broker_Contact__r.AccountId);
                opportunityIds.add(brokerAcc.Opportunity__c);
            }

            List<Account_Product__c> accProds = AccountProductQueryUtil.fetchAccountProductsByAccountIds(new List<Id>(accountIds));
            Map<String, List<Account_Product__c>> accAccProd = new Map<String, List<Account_Product__c>>();
            for(Account_Product__c accProd : accProds){
                if(!accAccProd.containsKey(accProd.Account_Id__c))
                    accAccProd.put(accProd.Account_Id__c, new List<Account_Product__c>{accProd});
                else
                    accAccProd.get(accProd.Account_Id__c).add(accProd);
            }

            Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([Select AccountId,Product_Name__c, (SELECT ID,OpportunityId,Opportunity.Product_Name__c,Opportunity.AccountId From Quotes WHERE Status not in ('Bound','Closed','Rejected','Correction','Cancelled')) from Opportunity where Id in: opportunityIds]);
            List<Quote> quotes = new List<Quote>();
            for(Broker_Account__c brokerAcc : brokerAccounts){
                if(!opportunityMap.isEmpty() && opportunityMap.containsKey(brokerAcc.Opportunity__c) && accAccProd.containsKey(brokerAcc.Broker_Contact__r.AccountId)){
                    for(Account_Product__c accProd : accAccProd.get(brokerAcc.Broker_Contact__r.AccountId)){
                        if(accProd.Product_Id__r.Name == opportunityMap.get(brokerAcc.Opportunity__c).Product_Name__c
                        && opportunityMap.get(brokerAcc.Opportunity__c).Quotes != null && opportunityMap.get(brokerAcc.Opportunity__c).Quotes.size() > 0){
                            for(Quote quoteObj : opportunityMap.get(brokerAcc.Opportunity__c).Quotes){
                                quoteObj.Commission_percentage__c = accProd.Commission_percentage__c;
                                quoteObj.Status = 'In Progress';
                                quotes.add(quoteObj);
                            }
                        }
                    }
                }
            }

            if(!quotes.isEmpty())
                update quotes;
        }
    }

    /*************************************************
    * Method Name: updateQuoteStatusAQ
    * Author:
    * Date: 
    * Params: List<Broker_Account__c> brokerAccounts
    * Return: 
    * Exceptions:
    * Description: Update status of quote to rated
    * Revision: 
    * Can be done with flows: Yes
     *************************************************/
    public static void updateQuoteStatusAQ(List<Broker_Account__c> brokerAccounts){
        Set<Id> oppIds = new Set<Id>();
        for(Broker_Account__c brokerAcc:brokerAccounts){
            oppIds.add(brokerAcc.Opportunity__c);
        }

        List<Quote> updateQuote = new List<Quote>();
        if(Trigger.isDelete){
            for(Quote quote: QuoteQueryUtil.fetchOpenQuotesAQ(oppIds)){
                if(quote.Status != 'In Progress'){
                    quote.status = 'In Progress';
                    updateQuote.add(quote);
                }
            }
        }
        else{
            for(Quote quote: QuoteQueryUtil.fetchPIQuotedQuotes(oppIds)){
                quote.status = 'Rated';
                updateQuote.add(quote);
            }
        }

        if(updateQuote.size() > 0){
            update updateQuote;
        }
    }

    /*************************************************
    * Method Name: updateQuotesContactOnBrokerchange
    * Author:
    * Date: 
    * Params: List<Broker_Account__c> newBrokerAccounts
    * Return: 
    * Exceptions:
    * Description: Update quote broker and commission percentage
    * Revision: 
    * Can be done with flows: Yes
     *************************************************/
    public static void updateQuotesContactOnBrokerchange(List<Broker_Account__c> newBrokerAccounts){
        Map<Id,Broker_Account__c> brokerAccountMap = new Map<Id,Broker_Account__c>();
        List<Account_Product__c> accProd = new List<Account_Product__c>();
        string AccountId;
        for(Broker_Account__c brokerAcc:newBrokerAccounts){
            brokerAccountMap.put(brokerAcc.Opportunity__c,brokerAcc);
        }

        List<Quote> updateQuote = new List<Quote>();
        
        try{
            for(Quote quote: QuoteQueryUtil.fetchQuotesByOpportunties(brokerAccountMap.keySet())){
                if(quote.Product_Name__c == GlobalVariables.PROD_NAME_FOR_PI){
                    string brokerContact = brokerAccountMap.get(quote.OpportunityId).Broker_Contact__c;
                    if(string.isNotBlank(brokerContact)){
                        AccountId = ContactQueryUtil.fetchContactFromBrokerAccount(brokerContact).AccountId;
                    }
                    
                    if(string.isNotBlank(AccountId)){
                        accProd = AccountProductQueryUtil.fetchAccountProductsByAccounts(AccountId);
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
            /*if(Test.isRunningTest())
                throw new DMLException();*/
        }catch(Exception ex){
            String errorMsg = CommonUtil.getExceptionMessage(ex);
            for (Broker_Account__c brokerAcc : (List<Broker_Account__c>) Trigger.new){
                brokerAcc.addError(errorMsg);
            }
        }
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
            else if(item.IsPrimaryBroker__c && ( !oldBrokerAccountsMap.get(item.Id).IsPrimaryBroker__c ||
                    item.Broker_Contact__c != oldBrokerAccountsMap.get(item.Id).Broker_Contact__c ) )
            {
                brokerAccountIds.add(item.Id);
            }
            
        }
        if(brokerAccountIds.isEmpty()) return;
       
        Map<Id, Broker_Account__c> mapOppBrokerAcc = new Map<Id, Broker_Account__c>();
        for(Broker_Account__c objBrokerAccount : BrokerAccountQueryUtil.fetchBrokerAccountsByIds(brokerAccountIds)) 
        {
            mapOppBrokerAcc.put(objBrokerAccount.Opportunity__c, objBrokerAccount);
        }
        //List<Quote> listQuote = QuoteQueryUtil.fetchQuotesByOpportunties(mapOppBrokerAcc.keySet());
        List<Quote> listQuote = [SELECT Id, Status, OpportunityId ,AccountId, Name ,Broker__c,Product_Name__c, Broker_Email__c FROM Quote WHERE OpportunityId IN : mapOppBrokerAcc.keySet() AND Status NOT IN ('Bound','Closed','Rejected','Correction','Cancelled')];
        
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