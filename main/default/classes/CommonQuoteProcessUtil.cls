/**************************************************************************************************
 * Class Name: CommonQuoteProcessUtil
 * Author: 
 * Date: 
 * Description: Utility class for Quote Process
 * Test Class : QuoteProcessTriggerHandlerTest
 **************************************************************************************************/
public with sharing class CommonQuoteProcessUtil {
    /*************************************************
    * Method Name: updateSubmissions
    * Author: Vinayesh
    * Date: 
    * Params: List<Quote_Process__c> newDataList
    * Return: 
    * Exceptions:
    * Revision: 
    * Description: To update the Quote Process when account details change on Submission
    * Can be replaced with flow: Yes
     *************************************************/
    public static void updateSubmissions(List<Quote_Process__c> newDataList){
        Set<Id> oppIds = new Set<Id>();
        for (Quote_Process__c qp : newDataList){
            if(qp.Submission__c != null)
                oppIds.add(qp.Submission__c);             
        }

        List<Opportunity> oppList = OpportunityQueryUtil.fetchOpportunityByIds(oppIds);

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

    /*************************************************
    * Method Name: updateOpportunityQuoteProcessLink
    * Author: 
    * Date: 
    * Params: Map<Id, Quote_Process__c> oldDataMap, List<Quote_Process__c> newDataList
    * Return: 
    * Exceptions:
    * Revision: 
    * Description: Update QP Link on related opportunity
    * Can be replaced with flow: Yes
     *************************************************/
    public static void updateOpportunityQuoteProcessLink(Map<Id, Quote_Process__c> oldDataMap, List<Quote_Process__c> newDataList) {
        Map<Id,String> OppId_QpIdMap = new Map<Id,String>();
        for(Quote_Process__c item :newDataList) 
        {
            if(String.isNotBlank(item.Submission__c)){
                if(oldDataMap != null){
                    if(oldDataMap.get(item.Id).Submission__c != item.Submission__c) {
                        OppId_QpIdMap.put(item.Submission__c,item.Id); 
                    }
                }else{
                    OppId_QpIdMap.put(item.Submission__c,item.Id); 
                }
            }
        }
        if(OppId_QpIdMap.isEmpty()) return;
       
        List<Opportunity> oppList = new List<Opportunity>(); //OpportunityQueryUtil.fetchOpportunityByIds(OppId_QpIdMap.keySet());
        for(Id oppId : OppId_QpIdMap.keySet()){
            Opportunity opp  = new Opportunity(id = oppId);
            opp.QP_Link__c = OppId_QpIdMap.get(oppId);
            oppList.add(opp);
        }
        if(!oppList.isEmpty()) update oppList;
        System.debug('@@@ Opportunity: ' + oppList);
    }
}