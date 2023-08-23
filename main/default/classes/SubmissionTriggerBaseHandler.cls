/**************************************************************************************************
* Class Name: SubmissionTriggerBaseHandler
* Author: 
* Date: 
* Description: Handler for Submission Trigger
**************************************************************************************************/
public with sharing class SubmissionTriggerBaseHandler extends TriggerHandler {
    
    private List<Opportunity> oldDataList;
    private List<Opportunity> newDataList;
    private Map<Id, Opportunity> newDataMap;
    private Map<Id, Opportunity> oldDataMap;
    private static final String RT_NAME_CELERITY = GlobalVariables.RT_NAME_CELERITY;
    private static final String RT_NAME_AQUEOUS = GlobalVariables.RT_NAME_AQUEOUS;
    
    public SubmissionTriggerBaseHandler (){  
        
    }
    
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
        Map<String, list<Opportunity>> newList_mapByRecordType = filter(Trigger.new);
        Map<String, list<Opportunity>> oldList_mapByRecordType = filter(Trigger.old);
        
        /* Logic for each record type */
        
        //prepare data for Celerity record Type
        if(newList_mapByRecordType.containsKey(RT_NAME_CELERITY) || oldList_mapByRecordType.containsKey(RT_NAME_CELERITY)){
            newDataList = newList_mapByRecordType.get(RT_NAME_CELERITY); 
            oldDataList = oldList_mapByRecordType.get(RT_NAME_CELERITY); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Opportunity>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{    
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Opportunity>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            }    
            //call Celerity Opportunity Trigger related logic        
            new SubmissionTriggerHandler_CEL(newDataList, oldDataList, newDataMap, oldDataMap).run();
            
        }
        //prepare data for Aqueous record Type
        if(newList_mapByRecordType.containsKey(RT_NAME_AQUEOUS) || oldList_mapByRecordType.containsKey(RT_NAME_AQUEOUS) ){
            newDataList = newList_mapByRecordType.get(RT_NAME_AQUEOUS); 
            oldDataList = oldList_mapByRecordType.get(RT_NAME_AQUEOUS); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Opportunity>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{   
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Opportunity>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            } 
            //call Aqueous Opportunity Trigger related logic
            new SubmissionTriggerHandler_AQ(newDataList, oldDataList, newDataMap, oldDataMap).run();
            
        }
        
    }
    
    /*************************************************
* Method Name: filter
* Author:
* Date: 
* Params: List<Opportunity>
* Return: Map<String, List<Opportunity>>
* Exceptions:
* Description: To filter records based on Record type
* Revision: 
*************************************************/
    public Map<String, List<Opportunity>> filter(List<Opportunity> dataList){  
        
        Map<String, List<Opportunity>> dataList_mapByRecordType= new Map<String, List<Opportunity>>();
        if(dataList == null){
            //return emplty map list has no records
            return dataList_mapByRecordType;
        }
        
        Map<ID,Schema.RecordTypeInfo> oppRecordTypeMap = Opportunity.sObjectType.getDescribe().getRecordTypeInfosById();
        
        //list of Record Types to be handled
        List<String> rt_Names = new List<String>{RT_NAME_CELERITY,RT_NAME_AQUEOUS};
            
            for(Opportunity eachRecord : dataList ){             
                String recordTypeName = oppRecordTypeMap.get(eachRecord.recordTypeID).getName();
                //check if record is record type being handled
                if(rt_Names.Contains(recordTypeName)){
                    if(dataList_mapByRecordType.containskey(recordTypeName)){
                        dataList_mapByRecordType.get(recordTypeName).add(eachRecord);
                    }
                    else{
                        dataList_mapByRecordType.put(recordTypeName, new List<Opportunity>{eachRecord});
                    }                        
                }
                else{
                    if(dataList_mapByRecordType.containskey('Other')){
                        dataList_mapByRecordType.get('Other').add(eachRecord);
                    }
                    else{
                        dataList_mapByRecordType.put('Other', new List<Opportunity>{eachRecord});
                    }                        
                }
            }        
        return dataList_mapByRecordType;
    }       
}