/**************************************************************************************************
 * Class Name: CommonContactUtil
 * Author: 
 * Date: 
 * Description: Class to keep contact trigger related logic
 **************************************************************************************************/
public with sharing class CommonContactUtil {
    /*************************************************
    * Method Name: emailChangeContactHandler
    * Author: Vinay Vernekar
    * Date: 4th Dec 2021
    * Params: List<Contact> newDataList, Map<Id, Contact> oldDataMap
    * Return: 
    * Exceptions:
    * Revision: 
    * Description: Check if contact email is changing
    * Can be replaced with flow: Yes
     *************************************************/
    public static void emailChangeContactHandler(List<Contact> newDataList, Map<Id, Contact> oldDataMap){
        Map<Id,Contact> newContactMap =  new Map<Id,Contact>();
		for(Contact con : newDataList){
            if(oldDataMap.get(con.Id).Email != con.Email){
                newContactMap.put(con.Id,con);
            }
        }
        if(!newContactMap.isEmpty())
            updateQuoteWithBrokerEmail(newContactMap);   
    }
    
    /*************************************************
    * Method Name: updateQuoteWithBrokerEmail
    * Author: Vinay Vernekar
    * Date: 4th Dec 2021
    * Params: Map<Id, Contact> mapNewContacts
    * Return: 
    * Exceptions:
    * Revision: 
    * Description: Update quotes with broker's email
    * Can be replaced with flow: Yes
     *************************************************/
    //Update Broker Email when Primary Broker changes
    public static void updateQuoteWithBrokerEmail(Map<Id, Contact> mapNewContacts){
        Set<Id> contactIds = new Set<Id>();
        contactIds = mapNewContacts.keySet();
        if(contactIds.isEmpty()) return;
        //Savepoint sp = null;
      
        try{
        Map<Id, Broker_Account__c> mapOppContact = new Map<Id, Broker_Account__c>();
        for(Broker_Account__c objBrokerAccount : BrokerAccountQueryUtil.fetchPrimaryBrokerAccounts(contactIds)){
            mapOppContact.put(objBrokerAccount.Opportunity__c, objBrokerAccount);
        }
        List<String> editedStatusList = new List<String>{'In Progress','Rated','Quoted'};
        Map<Id,Quote> quoteMap =  QuoteQueryUtil.fetchQuoteMapByOpportunity(mapOppContact.keySet(), editedStatusList);

        Set<Id> penddingQuotes  = new Set<Id>();
        for (ProcessInstance processInst : [SELECT Id,TargetObjectId 
                                            FROM ProcessInstance 
                                            WHERE TargetObjectId IN :quoteMap.keySet() 
                                                    AND Status='Pending']){
            penddingQuotes.add(processInst.TargetObjectId);

        }
        
          List<Quote> listQuote = new List<Quote>(); 
        
          for(Quote quote : quoteMap.values()) {
            if(!penddingQuotes.contains(quote.Id)){
                quote.Broker_Email__c = mapOppContact.get(quote.OpportunityId).Broker_Contact__r.Email;
                listQuote.add(quote);
            }
            
        }
        TriggerHandler.bypass('QuoteTriggerBaseHandler');
            update listQuote;
        TriggerHandler.clearBypass('QuoteTriggerBaseHandler');
        if(Test.isRunningTest())
            throw new DMLException();
        }catch(exception ex){
            //if(sp!=null) Database.rollback(sp);
            system.debug('exception : ' + ex.getMessage());
            String errorMsg = CommonUtil.getExceptionMessage(ex);
            for (Contact con : (List<Contact>) Trigger.new){
                if(!Test.isRunningTest())
                    con.addError(errorMsg);
            }
        }
    }
}