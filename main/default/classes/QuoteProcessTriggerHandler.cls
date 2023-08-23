/**
 * @File Name          : QuoteProcessTriggerHandler.cls
 * @Description        : 
 * @Author             : tuan.d.nguyen@capgemini.com
 * @Group              : 
 * @Last Modified By   : tuan.d.nguyen@capgemini.com
 * @Last Modified On   : 5/28/2020, 5:15:30 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    5/28/2020   tuan.d.nguyen@capgemini.com     Initial Version
**/
public with sharing class  QuoteProcessTriggerHandler extends TriggerHandler{
    private List<Quote_Process__c> oldDataList;
    private List<Quote_Process__c> newDataList;
    private Map<Id, Quote_Process__c> newDataMap;
    private Map<Id, Quote_Process__c> oldDataMap;

    public QuoteProcessTriggerHandler (){
        this.oldDataList = (List<Quote_Process__c>) Trigger.old;
        this.newDataList = (List<Quote_Process__c>) Trigger.new;
        this.newDataMap = (Map<Id, Quote_Process__c>) Trigger.newMap;
        this.oldDataMap = (Map<Id, Quote_Process__c>) Trigger.oldMap;
    }

    public override void beforeInsert() {

    }

    public override void beforeUpdate() {
       //Added to update Submission account if quote process account changes.
        updateSubmissions();
    }

    public override void afterInsert(){
       
        updateOpportunityQuoteProcessLink(null ,newDataList);
    }

    public override void afterUpdate() {
  
        updateOpportunityQuoteProcessLink(oldDataMap ,newDataList);
    }
       

    
//  * Description: 
// * 1. To update the Quote Process when account details change on Submission
// * Vinayesh
// ********************************************************************************/
private void updateSubmissions(){
    Set<String> oppIds = new Set<String>();
    for (Quote_Process__c qp : newDataList){
        if(qp.Submission__c != null)
            oppIds.add(qp.Submission__c);             
    }

     List<Opportunity> oppList = [Select AccountId From Opportunity
                                      Where Id In :oppIds];

     List<Opportunity> oppListToUpdate = new List<Opportunity>();
     for (Quote_Process__c qp : newDataList){
        for (Opportunity opp : oppList){
            if(qp.Account__c != opp.AccountId){
                opp.AccountId = qp.Account__c;
                oppListToUpdate.add(opp);
            }
        }              
    }

    if(oppListToUpdate.size() > 0){
        update oppListToUpdate;
    }
 }
    
   public static void updateOpportunityQuoteProcessLink(Map<Id, Quote_Process__c> oldDataMap, List<Quote_Process__c> newDataList) {
		Map<String,String> OppId_QpIdMap = new Map<String,String>();
       	for(Quote_Process__c item :newDataList) 
        {
			if(String.isNotBlank(item.Submission__c) && oldDataMap != null && oldDataMap.get(item.Id).Submission__c != item.Submission__c) {
                OppId_QpIdMap.put(item.Submission__c,item.Id); 
			}
        }
        if(OppId_QpIdMap.isEmpty()) return;
       
        List<Opportunity> oppList = [select Id, QP_Link__c from Opportunity where Id in: OppId_QpIdMap.keySet()];
        for(Opportunity item : oppList ){
           item.QP_Link__c = OppId_QpIdMap.get(item.Id);
        }
        if(!oppList.isEmpty()) update oppList;
        System.debug('@@@ Opportunity: ' + oppList);
   }
}