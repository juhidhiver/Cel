/**************************************************************************************************
* Class Name: CoverageLineItemTriggerBaseHandler
* Author: 
* Date: 
* Description: Handler for CoverageLineItemTrigger
**************************************************************************************************/
public  with sharing class CoverageLineItemTriggerBaseHandler extends TriggerHandler {
    
    private List<CoveragesLineItem__c> oldDataList;
    private List<CoveragesLineItem__c> newDataList;
    private Map<Id, CoveragesLineItem__c> newDataMap;
    private Map<Id, CoveragesLineItem__c> oldDataMap;
    
    
    /*************************************************
* Method Name: run
* Author:
* Date: 
* Params: 
* Return: 
* Exceptions:
* Description: To filter records based on Record type and RT specific handler
* Revision: 
*************************************************/
    public void runBaseHandler(){
        Map<String, list<CoveragesLineItem__c>> newList_mapByRecordType = filter(Trigger.new);
        Map<String, list<CoveragesLineItem__c>> oldList_mapByRecordType = filter(Trigger.old);
        
        /* Logic for each record type */
        
        //prepare data for Celerity record Type
        if(newList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_CELERITY) || oldList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_CELERITY)){
            newDataList = newList_mapByRecordType.get(GlobalVariables.RT_NAME_CELERITY); 
            oldDataList = oldList_mapByRecordType.get(GlobalVariables.RT_NAME_CELERITY); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, CoveragesLineItem__c>(newDataList);
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{    
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, CoveragesLineItem__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            }    
            //call Aqueous Trigger relaetd logic        
            new CoverageLineItemTriggerHandler_CEL(newDataList, oldDataList, newDataMap, oldDataMap).run();
            
        }
        //prepare data for Aqueous record Type
        if(newList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_AQUEOUS) || oldList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_AQUEOUS)){
            newDataList = newList_mapByRecordType.get(GlobalVariables.RT_NAME_AQUEOUS); 
            oldDataList = oldList_mapByRecordType.get(GlobalVariables.RT_NAME_AQUEOUS); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, CoveragesLineItem__c>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{    
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, CoveragesLineItem__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            } 
            //call Aqueous Trigger relaetd logic
            new CoverageLineItemTriggerHandler_AQ(newDataList, oldDataList, newDataMap, oldDataMap).run();
            
        }
        
    }
    
    /*************************************************
* Method Name: filter
* Author:
* Date: 
* Params: List<CoveragesLineItem__c>
* Return: Map<String, List<CoveragesLineItem__c>>
* Exceptions:
* Description: To filter records based on Record type
* Revision: 
*************************************************/
    public Map<String, List<CoveragesLineItem__c>> filter(List<CoveragesLineItem__c> dataList){  
        
        Map<String, List<CoveragesLineItem__c>> dataList_mapByRecordType= new Map<String, List<CoveragesLineItem__c>>();
        if(dataList == null){
            //return emplty map list has no records
            return dataList_mapByRecordType;
        }
        
        Map<ID,Schema.RecordTypeInfo> recordTypeMap = CoveragesLineItem__c.sObjectType.getDescribe().getRecordTypeInfosById();
        
        //list of Record Types to be handled
        List<String> rt_Names = new List<String>{GlobalVariables.RT_NAME_CELERITY,GlobalVariables.RT_NAME_AQUEOUS};
            
            for(CoveragesLineItem__c eachRecord : dataList ){   
                String recordTypeName = '';
                if(eachRecord.recordTypeID != null){
                    recordTypeName = recordTypeMap.get(eachRecord.recordTypeID).getName();
                }          
                
                //check if record is record type being handled
                if(rt_Names.Contains(recordTypeName)){
                    if(dataList_mapByRecordType.containskey(recordTypeName)){
                        dataList_mapByRecordType.get(recordTypeName).add(eachRecord);
                    }
                    else{
                        dataList_mapByRecordType.put(recordTypeName, new list<CoveragesLineItem__c>{eachRecord});
                    }                        
                }
                else{
                    if(dataList_mapByRecordType.containskey('Other')){
                        dataList_mapByRecordType.get('Other').add(eachRecord);
                    }
                    else{
                        dataList_mapByRecordType.put('Other', new list<CoveragesLineItem__c>{eachRecord});
                    }                        
                }
            }        
        return dataList_mapByRecordType;
    }       
    
}