/**************************************************************************************************
 * Class Name: ContactTriggerHandler
 * Author:Quan Tran 
 * Date: 19-August-2019
 * Description: Handler for ContactTrigger
 **************************************************************************************************/
public with sharing class ContactTriggerHandler extends TriggerHandler{
    private List<Contact> oldDataList;
	private List<Contact> newDataList;
	private Map<Id, Contact> newDataMap;
	private Map<Id, Contact> oldDataMap;
	
    public ContactTriggerHandler (){  
		//prevent recurison
		//this.setMaxLoopCount(2);

		this.oldDataList = (List<Contact>) Trigger.old;
		this.newDataList = (List<Contact>) Trigger.new;
		this.newDataMap = (Map<Id, Contact>) Trigger.newMap;
		this.oldDataMap = (Map<Id, Contact>) Trigger.oldMap;
    }

	public override void beforeInsert()	{
		CommonUtil.generateExternalID('Azure_ID__c', newDataList);		
	}

	public override void beforeUpdate() {
		CommonUtil.generateExternalID('Azure_ID__c', newDataList);	
    }

	public override void afterInsert(){
		updateQuoteWithBrokerEmail(newDataMap);
	}

	public override void afterUpdate() {     
        Map<Id,Contact> newContactMap =  new Map<Id,Contact>();
		for(Contact con : newDataList){
            if(oldDataMap.get(con.Id).Email != con.Email){
                newContactMap.put(con.Id,con);
            }
        }   
        updateQuoteWithBrokerEmail(newContactMap);
    }
	
    //Update Broker Email when Primary Broker changes
    private static void updateQuoteWithBrokerEmail(Map<Id, Contact> mapNewContacts){
        Set<Id> contactIds = new Set<Id>();
        contactIds = mapNewContacts.keySet();
        if(contactIds.isEmpty()) return;

        Map<Id, Broker_Account__c> mapOppContact = new Map<Id, Broker_Account__c>();
        for(Broker_Account__c objBrokerAccount : [SELECT Id, Opportunity__c, Broker_Contact__r.AccountId, Broker_Contact__r.Email 
                                                  FROM Broker_Account__c WHERE IsPrimaryBroker__c = true 
                                                  AND Broker_Contact__c IN :contactIds])
        {
            mapOppContact.put(objBrokerAccount.Opportunity__c, objBrokerAccount);
        }
        List<String> editedStatusList = new List<String>{'In Progress','Rated','Quoted'};
        Map<Id,Quote> quoteMap = new Map<Id, Quote>([SELECT Id, OpportunityId ,Broker__c, Broker_Email__c
                                                    FROM Quote 
                                                    WHERE OpportunityId IN : mapOppContact.keySet()
                                                        AND Status IN :editedStatusList]);
                                                       
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
        TriggerHandler.bypass('QuoteTriggerHandler');
            update listQuote;
        TriggerHandler.clearBypass('QuoteTriggerHandler');
    }
}