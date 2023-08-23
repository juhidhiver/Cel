/**************************************************************************************************
* Class Name: RatingModifiersTriggerBaseHandler
* Author: 
* Date: 
* Description: Base class for rating modifiers trigger
* Test Class : RatingModifiersTriggerHandlerTest
**************************************************************************************************/
public with sharing class RatingModifiersTriggerBaseHandler extends TriggerHandler {
    private List<Rating_Modifiers__c> oldDataList;
    private List<Rating_Modifiers__c> newDataList; 
    private Map<Id, Rating_Modifiers__c> newDataMap;
    private Map<Id, Rating_Modifiers__c> oldDataMap;
    
    
    public void runBaseHandler(){        
        Map<String, list<Rating_Modifiers__c>> newList_map = filter(Trigger.new);
        Map<String, list<Rating_Modifiers__c>> oldList_map = filter(Trigger.old);
        
        //prepare data for Celerity
        if(newList_map.containsKey(GlobalVariables.CELERITY) || oldList_map.containsKey(GlobalVariables.CELERITY) ){
            newDataList = newList_map.get(GlobalVariables.CELERITY); 
            oldDataList = oldList_map.get(GlobalVariables.CELERITY); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Rating_Modifiers__c>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{ 
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Rating_Modifiers__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            }    
            new RatingModifiersTriggerHandler_CEL(newDataList, oldDataList, newDataMap, oldDataMap).run();
        }
        //prepare data for Aqueous
        if(newList_map.containsKey(GlobalVariables.AQUEOUS) || oldList_map.containsKey(GlobalVariables.AQUEOUS)){
            newDataList = newList_map.get(GlobalVariables.AQUEOUS); 
            oldDataList = oldList_map.get(GlobalVariables.AQUEOUS); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Rating_Modifiers__c>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{    
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Rating_Modifiers__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            } 
            new RatingModifiersTriggerHandler_AQ(newDataList, oldDataList, newDataMap, oldDataMap).run();
        }
        //prepare data for others
        if(newList_map.containsKey(GlobalVariables.OTHER)){
            newDataList = newList_map.get(GlobalVariables.OTHER); 
            oldDataList = newList_map.get(GlobalVariables.OTHER); 
            
            try{
                newDataMap = new Map<Id, Rating_Modifiers__c>(newDataList);				
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{                
                oldDataMap = new Map<Id, Rating_Modifiers__c>(oldDataList);
            }catch(Exception e){
                this.oldDataMap = null;
            } 
            new RatingModifiersTriggerHandler_Other(newDataList, oldDataList, newDataMap, oldDataMap).run();
        }
    }
    
    
    public Map<String, List<Rating_Modifiers__c>> filter(List<Rating_Modifiers__c> dataList){  
        Map<String, List<Rating_Modifiers__c>> dataList_map = new Map<String, List<Rating_Modifiers__c>>();
        if(dataList == null){
            return dataList_map;
        }
        for(Rating_Modifiers__c eachRecord : dataList){             
            if(GlobalVariables.CEL_PRODUCTS.Contains(eachRecord.Product__c)){
                if(dataList_map.containskey(GlobalVariables.CELERITY)){
                    dataList_map.get(GlobalVariables.CELERITY).add(eachRecord);
                }
                else{
                    dataList_map.put(GlobalVariables.CELERITY, new list<Rating_Modifiers__c>{eachRecord});
                }                        
            }else if(GlobalVariables.AQ_PRODUCTS.Contains(eachRecord.Product__c)){
                if(dataList_map.containskey(GlobalVariables.AQUEOUS)){
                    dataList_map.get(GlobalVariables.AQUEOUS).add(eachRecord);
                }
                else{
                    dataList_map.put(GlobalVariables.AQUEOUS, new list<Rating_Modifiers__c>{eachRecord});
                } 
            }
            else{
                if(dataList_map.containskey(GlobalVariables.OTHER)){
                    dataList_map.get(GlobalVariables.OTHER).add(eachRecord);
                }
                else{
                    dataList_map.put(GlobalVariables.OTHER, new list<Rating_Modifiers__c>{eachRecord});
                }                        
            }
        }        
        return dataList_map;
    }
}