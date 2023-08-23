/**************************************************************************************************
* Class Name: AdditionalInterestTriggerBaseHandler
* Author: Binh Dang
* Date: 04-Dec-2018
* Description: Handler for AdditionalInterestTrigger
**************************************************************************************************/
public with sharing class AdditionalInterestTriggerBaseHandler extends TriggerHandler  {
    
    private List<Additional_Interests__c> oldDataList;
    private List<Additional_Interests__c> newDataList;
    private Map<Id, Additional_Interests__c> newDataMap;
    private Map<Id, Additional_Interests__c> oldDataMap;
    
    
    /*************************************************
* Method Name: run
* Author:
* Date: 
* Params: 
* Return: 
* Exceptions:
* Description: To filter records based on product name
* Revision: 
*************************************************/
    public void runBaseHandler(){
        Map<String, list<Additional_Interests__c>> newList_map = filter(Trigger.new);
        Map<String, list<Additional_Interests__c>> oldList_map = filter(Trigger.old);
        
        /* Logic for each record type */
        
        //prepare data for Celerity
        if(newList_map.containsKey(GlobalVariables.CELERITY) || oldList_map.containsKey(GlobalVariables.CELERITY) ){
            newDataList = newList_map.get(GlobalVariables.CELERITY); 
            oldDataList = oldList_map.get(GlobalVariables.CELERITY); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Additional_Interests__c>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{   
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Additional_Interests__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            }    
            new AdditionalInterestTriggerHandler_CEL(newDataList, oldDataList, newDataMap, oldDataMap).run();
        }
        //prepare data for Aqueous
        if(newList_map.containsKey(GlobalVariables.AQUEOUS) || oldList_map.containsKey(GlobalVariables.AQUEOUS)){
            newDataList = newList_map.get(GlobalVariables.AQUEOUS); 
            oldDataList = oldList_map.get(GlobalVariables.AQUEOUS); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Additional_Interests__c>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{       
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Additional_Interests__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            } 
            
            new AdditionalInterestTriggerHandler_AQ(newDataList, oldDataList, newDataMap, oldDataMap).run();
        }
    }
    
    /*************************************************
* Method Name: filter
* Author:
* Date: 
* Params: List<Additional_Interests__c>
* Return: Map<String, List<Additional_Interests__c>>
* Exceptions:
* Description: To filter records based on products
* Revision: 
*************************************************/
    public Map<String, List<Additional_Interests__c>> filter(List<Additional_Interests__c> dataList){  
        Set<id> quoteIds = new Set<id>();
        Map<id, Quote> quoteMap = new Map<id, Quote>();
        Map<String, List<Additional_Interests__c>> dataList_map= new Map<String, List<Additional_Interests__c>>();
        if(dataList == null){
            //return emplty map list has no records
            return dataList_map;
        }
        
        for(Additional_Interests__c interest : dataList){
            quoteIds.add(interest.Quote__c);
        }
        
        if(!quoteIds.isEmpty()){
            String fields = 'id, Product_Name__c';
            quoteMap = new Map<id, Quote>(QuoteQueryUtil.fetchQuotesForQuoteIds(quoteIds,fields));
        }
        
        for(Additional_Interests__c eachRecord : dataList ){             
            String productName = quoteMap.containsKey(eachRecord.Quote__c) ? quoteMap.get(eachRecord.Quote__c).Product_Name__c : '';
            //check if record is record type being handled
            if(String.isNotBlank(productName)){
                if(GlobalVariables.CEL_PRODUCTS.Contains(productName)){
                    if(dataList_map.containskey(GlobalVariables.CELERITY)){
                        dataList_map.get(GlobalVariables.CELERITY).add(eachRecord);
                    }
                    else{
                        dataList_map.put(GlobalVariables.CELERITY, new list<Additional_Interests__c>{eachRecord});
                    }                        
                }else if(GlobalVariables.AQ_PRODUCTS.Contains(productName)){
                    if(dataList_map.containskey(GlobalVariables.AQUEOUS)){
                        dataList_map.get(GlobalVariables.AQUEOUS).add(eachRecord);
                    }
                    else{
                        dataList_map.put(GlobalVariables.AQUEOUS, new list<Additional_Interests__c>{eachRecord});
                    } 
                }
            }
        }        
        return dataList_map;
    }      
}