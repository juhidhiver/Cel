/**************************************************************************************************
* Class Name: BrokerAccountTriggerBaseHandler
* Author: 
* Date: 
* Description: Base class for broker account trigger
* Test Class : BrokerAccountTriggerHandlerTest
**************************************************************************************************/
public with sharing class BrokerAccountTriggerBaseHandler extends TriggerHandler {
    private List<Broker_Account__c> oldDataList;
    private List<Broker_Account__c> newDataList; 
    private Map<Id, Broker_Account__c> newDataMap;
    private Map<Id, Broker_Account__c> oldDataMap;
    
    
    public void runBaseHandler(){        
        Map<String, list<Broker_Account__c>> newList_map = filter(Trigger.new);
        Map<String, list<Broker_Account__c>> oldList_map = filter(Trigger.old);
        
        //prepare data for Celerity
        if(newList_map.containsKey(GlobalVariables.CELERITY) || oldList_map.containsKey(GlobalVariables.CELERITY)){
            newDataList = newList_map.get(GlobalVariables.CELERITY); 
            oldDataList = oldList_map.get(GlobalVariables.CELERITY); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Broker_Account__c>(newDataList);
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{   
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Broker_Account__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            }         
            new BrokerAccountTriggerHandler_CEL(newDataList, oldDataList, newDataMap, oldDataMap).run();
        }
        //prepare data for Aqueous
        if(newList_map.containsKey(GlobalVariables.AQUEOUS) || oldList_map.containsKey(GlobalVariables.AQUEOUS)){
            newDataList = newList_map.get(GlobalVariables.AQUEOUS); 
            oldDataList = oldList_map.get(GlobalVariables.AQUEOUS); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Broker_Account__c>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{  
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Broker_Account__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            } 
            new BrokerAccountTriggerHandler_AQ(newDataList, oldDataList, newDataMap, oldDataMap).run();
        }
        //prepare data for other
        if(newList_map.containsKey(GlobalVariables.OTHER)){
            newDataList = newList_map.get(GlobalVariables.OTHER); 
            oldDataList = oldList_map.get(GlobalVariables.OTHER); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Broker_Account__c>(newDataList);
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{  
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Broker_Account__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            } 
            new BrokerAccountTriggerHandler_Other(newDataList, oldDataList, newDataMap, oldDataMap).run();
        }
    }
    
    
    public Map<String, List<Broker_Account__c>> filter(List<Broker_Account__c> dataList){  
        Map<String, List<Broker_Account__c>> dataList_map = new Map<String, List<Broker_Account__c>>();
        if(dataList == null){
            return dataList_map;
        }
        
        Set<Id> submissionIds = new Set<id>();
        Map<id, Opportunity> oppotunityMap = new Map<id, Opportunity>();
        for(Broker_Account__c ba : dataList){
            submissionIds.add(ba.Opportunity__c);
        }
        
        if(!submissionIds.isEmpty()){
            oppotunityMap = new Map<id, Opportunity>([SELECT id,Product_Name__c from Opportunity where id in: submissionIds]);
        }
        if(!oppotunityMap.isEmpty()){
            system.debug('oppotunityMap:' + oppotunityMap);
        for(Broker_Account__c eachRecord : dataList){          
            String productName = oppotunityMap.get(eachRecord.Opportunity__c).Product_Name__c;   
            if(GlobalVariables.CEL_PRODUCTS.Contains(productName)){
                if(dataList_map.containskey(GlobalVariables.CELERITY)){
                    dataList_map.get(GlobalVariables.CELERITY).add(eachRecord);
                }
                else{
                    dataList_map.put(GlobalVariables.CELERITY, new list<Broker_Account__c>{eachRecord});
                }                        
            }else if(GlobalVariables.AQ_PRODUCTS.Contains(productName)){
                if(dataList_map.containskey(GlobalVariables.AQUEOUS)){
                    dataList_map.get(GlobalVariables.AQUEOUS).add(eachRecord);
                }
                else{
                    dataList_map.put(GlobalVariables.AQUEOUS, new list<Broker_Account__c>{eachRecord});
                } 
            }
            else{
                if(dataList_map.containskey(GlobalVariables.OTHER)){
                    dataList_map.get(GlobalVariables.OTHER).add(eachRecord);
                }
                else{
                    dataList_map.put(GlobalVariables.OTHER, new list<Broker_Account__c>{eachRecord});
                }                        
            }
        }        
        }
             
        return dataList_map;
    }
}