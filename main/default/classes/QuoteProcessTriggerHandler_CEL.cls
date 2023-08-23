/**************************************************************************************************
 * Class Name: QuoteProcessTriggerHandler_CEL
 * Author: 
 * Date: 
 * Description: Class to keep method related to Celerity
 * Test Class : QuoteProcessTriggerHandlerTest
 **************************************************************************************************/
public with sharing class QuoteProcessTriggerHandler_CEL extends TriggerHandler {
    private List<Quote_Process__c> oldDataList;
    private List<Quote_Process__c> newDataList; 
    private Map<Id, Quote_Process__c> newDataMap;
    private Map<Id, Quote_Process__c> oldDataMap; 
    
    public QuoteProcessTriggerHandler_CEL(List<Quote_Process__c> newDataList, List<Quote_Process__c> oldDataList, Map<Id, Quote_Process__c> newDataMap, Map<Id, Quote_Process__c> oldDataMap){
        this.oldDataList = oldDataList;
        this.newDataList = newDataList;
        this.newDataMap = newDataMap;
        this.oldDataMap = oldDataMap;
    } 

	public override void beforeInsert()	{

    }

    public override void beforeUpdate(){
        //update account on submissions as per quote process's account
        CommonQuoteProcessUtil.updateSubmissions(newDataList);
    }

	public override void afterInsert(){
        //update quote process link
        CommonQuoteProcessUtil.updateOpportunityQuoteProcessLink(oldDataMap ,newDataList);
    }

	public override void afterUpdate(){
        //update quote process link
        CommonQuoteProcessUtil.updateOpportunityQuoteProcessLink(oldDataMap ,newDataList);
    }
}