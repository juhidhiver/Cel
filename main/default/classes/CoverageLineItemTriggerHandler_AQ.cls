/**************************************************************************************************
 * Class Name: CoverageLineItemTriggerHandler_AQ
 * Author: 
 * Date: 
 * Description: Class to keep Celerity related  common methods
 * Test Class : CoverageLineItemTriggerTest
 **************************************************************************************************/
public class CoverageLineItemTriggerHandler_AQ extends TriggerHandler {

    private List<CoveragesLineItem__c> oldDataList;
    private List<CoveragesLineItem__c> newDataList; 
    private Map<Id, CoveragesLineItem__c> newDataMap;
    private Map<Id, CoveragesLineItem__c> oldDataMap; 

    Map<Id, Quote> updateQuoteMap = new Map<Id, Quote>();
    
    public CoverageLineItemTriggerHandler_AQ(List<CoveragesLineItem__c> newDataList, List<CoveragesLineItem__c> oldDataList, 
                                         Map<Id, CoveragesLineItem__c> newDataMap, Map<Id, CoveragesLineItem__c> oldDataMap){
                                             this.oldDataList = oldDataList;
                                             this.newDataList = newDataList;
                                             this.newDataMap = newDataMap;
                                             this.oldDataMap = oldDataMap;
                                         } 

	public override void beforeInsert()	{
        // Generate Azure Id before insert of CLI
		CommonUtil.generateExternalID('Azure_ID__c', newDataList);
	}

    public override void beforeUpdate(){
        // Generate Azure Id before update of CLI
		CommonUtil.generateExternalID('Azure_ID__c', newDataList);
    }

	
	public override void afterInsert(){
        //update Quote ExcessLimit
        map<Id,Quote> updateExcessLimitMap = CommonCoverageLineItemUtil.updateExcessLimit(this.newDataMap);
        updateQuoteMap.putAll(updateExcessLimitMap);


        //update quote status
        map<Id,Quote> updateStatusMap = CommonCoverageLineItemUtil.updateQuoteStatus(this.newDataList,null);
        updateQuoteMap.putAll(updateStatusMap);

        if(updateQuoteMap.Values().size() > 0){
            update updateQuoteMap.Values(); 
        } 
    }

	
	public override void afterUpdate(){
        //update quote status
        map<Id,Quote> updateStatusMap = CommonCoverageLineItemUtil.updateQuoteStatus(this.newDataList,this.oldDataMap);
        updateQuoteMap.putAll(updateStatusMap);

        //update Quote ExcessLimit
        map<Id,Quote> updateExcessLimitMap = CommonCoverageLineItemUtil.updateExcessLimit(this.newDataMap);
        updateQuoteMap.putAll(updateExcessLimitMap);


        if(updateQuoteMap.Values().size() > 0){
            update updateQuoteMap.Values();
        }
        
        //update CLI Option_Value_Default__c
        CommonCoverageLineItemUtil.handleUpdateSyncLimitDeductible(this.oldDataMap, this.newDataMap);
    }

    
    public override void afterdelete(){
        //update quote status
        map<Id,Quote> updateStatusMap = CommonCoverageLineItemUtil.updateQuoteStatus(oldDataList,null);

        /* should it updated?
        
        */
    }
}