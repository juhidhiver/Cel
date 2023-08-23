/**************************************************************************************************
* Class Name: QuoteProcessTriggerBaseHandler
* Author: 
* Date: 
* Description: Base Handler for QuoteProcessTrigger
* Test Class: QuoteProcessTriggerHandlerTest
**************************************************************************************************/
public with sharing class QuoteProcessTriggerBaseHandler extends TriggerHandler {
    private List<Quote_Process__c> oldDataList;
    private List<Quote_Process__c> newDataList; 
    private Map<Id, Quote_Process__c> newDataMap;
    private Map<Id, Quote_Process__c> oldDataMap;
    
    
    public void runBaseHandler(){        
        Map<String, list<Quote_Process__c>> newList_map = filter(Trigger.new);
        Map<String, list<Quote_Process__c>> oldList_map = filter(Trigger.old);
        
        //prepare data for Celerity
        if(newList_map.containsKey(GlobalVariables.CELERITY) || oldList_map.containsKey(GlobalVariables.CELERITY)){
            newDataList = newList_map.get(GlobalVariables.CELERITY); 
            oldDataList = oldList_map.get(GlobalVariables.CELERITY); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Quote_Process__c>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{   
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Quote_Process__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            }    
            new QuoteProcessTriggerHandler_CEL(newDataList, oldDataList, newDataMap, oldDataMap).run();
        }
        //prepare data for Aqueous
        if(newList_map.containsKey(GlobalVariables.AQUEOUS) || oldList_map.containsKey(GlobalVariables.AQUEOUS) ){
            newDataList = newList_map.get(GlobalVariables.AQUEOUS); 
            oldDataList = oldList_map.get(GlobalVariables.AQUEOUS); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Quote_Process__c>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{   
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Quote_Process__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            } 
            
            new QuoteProcessTriggerHandler_AQ(newDataList, oldDataList, newDataMap, oldDataMap).run();
        }
        //prepare data for other
        if(newList_map.containsKey(GlobalVariables.OTHER) ){
            newDataList = newList_map.get(GlobalVariables.OTHER); 
            oldDataList = oldList_map.get(GlobalVariables.OTHER); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Quote_Process__c>(newDataList);
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{  
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Quote_Process__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            } 
            new QuoteProcessTriggerHandler_Other(newDataList, oldDataList, newDataMap, oldDataMap).run();
        }
    }
    
    
    public Map<String, List<Quote_Process__c>> filter(List<Quote_Process__c> dataList){  
        Map<String, List<Quote_Process__c>> dataList_map = new Map<String, List<Quote_Process__c>>();
        if(dataList == null){
            return dataList_map;
        }
        Set<Id> submissionIds = new Set<Id>();
        for(Quote_Process__c eachRecord : dataList ){ 
            if(eachRecord.Submission__c != null)
                submissionIds.add(eachRecord.Submission__c);
        }
        Map<id, Opportunity> opportunityMap = new Map<id, Opportunity>();
        if(!submissionIds.isEmpty()){
            opportunityMap = new Map<id, Opportunity>(OpportunityQueryUtil.fetchOpportunityByIds(submissionIds));
        }
        for(Quote_Process__c eachRecord : dataList ){             
            String productName = eachRecord.Submission__c != null && opportunityMap.containsKey(eachRecord.Submission__c) ? opportunityMap.get(eachRecord.Submission__c).Product__r.Name : '' ;
            if(GlobalVariables.CEL_PRODUCTS.Contains(productName)){
                if(dataList_map.containskey(GlobalVariables.CELERITY)){
                    dataList_map.get(GlobalVariables.CELERITY).add(eachRecord);
                }
                else{
                    dataList_map.put(GlobalVariables.CELERITY, new list<Quote_Process__c>{eachRecord});
                }                        
            }else if(GlobalVariables.AQ_PRODUCTS.Contains(productName)){
                if(dataList_map.containskey(GlobalVariables.AQUEOUS)){
                    dataList_map.get(GlobalVariables.AQUEOUS).add(eachRecord);
                }
                else{
                    dataList_map.put(GlobalVariables.AQUEOUS, new list<Quote_Process__c>{eachRecord});
                } 
            }
            else{
                if(dataList_map.containskey(GlobalVariables.OTHER)){
                    dataList_map.get(GlobalVariables.OTHER).add(eachRecord);
                }
                else{
                    dataList_map.put(GlobalVariables.OTHER, new list<Quote_Process__c>{eachRecord});
                }                        
            }
        }        
        return dataList_map;
    }  
}