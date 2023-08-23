/**************************************************************************************************
* Class Name: SubjectivityTriggerBaseHandler
* Author: Vivek Raturi
* Date: 
* Description: 
**************************************************************************************************/
public  with sharing class SubjectivityTriggerBaseHandler extends TriggerHandler{
    
    private List<Subjectivity__c> oldDataList;
    private List<Subjectivity__c> newDataList;
    private Map<Id, Subjectivity__c> newDataMap;
    private Map<Id, Subjectivity__c> oldDataMap;
    
    
    /*************************************************
* Method Name: run
* Author: Vivek Raturi
* Date: 
* Params: 
* Return: 
* Exceptions:
* Description: To filter records based on Record type and RT specific handler
* Revision: 
*************************************************/
    public void runBaseHandler(){
        Map<String, list<Subjectivity__c>> newList_mapByRecordType = filter(Trigger.new);
        Map<String, list<Subjectivity__c>> oldList_mapByRecordType = filter(Trigger.old);
        
        /* Logic for each record type */
        
        //prepare data for Celerity Subjectivity record Type
        if( newList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_SUBJECTIVITY_CELERITY) || oldList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_SUBJECTIVITY_CELERITY)){
            newDataList = newList_mapByRecordType.get(GlobalVariables.RT_NAME_SUBJECTIVITY_CELERITY); 
            oldDataList = oldList_mapByRecordType.get(GlobalVariables.RT_NAME_SUBJECTIVITY_CELERITY); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Subjectivity__c>(newDataList);
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{    
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Subjectivity__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            }    
            //call Celerity Subjectivity Trigger relaetd logic        
            new SubjectivityTriggerHandler_CEL(newDataList, oldDataList, newDataMap, oldDataMap).run();
            
        }
        
        //prepare data for Aqueous Subjectivity record Type
        if(newList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_SUBJECTIVITY_AQUEOUS) || oldList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_SUBJECTIVITY_AQUEOUS)){
            newDataList = newList_mapByRecordType.get(GlobalVariables.RT_NAME_SUBJECTIVITY_AQUEOUS); 
            oldDataList = oldList_mapByRecordType.get(GlobalVariables.RT_NAME_SUBJECTIVITY_AQUEOUS); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Subjectivity__c>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{  
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Subjectivity__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            }    
            //call Aqueous Subjectivity Trigger relaetd logic        
            new SubjectivityTriggerHandler_AQ(newDataList, oldDataList, newDataMap, oldDataMap).run();
            
        }
    }
    
    /*************************************************
* Method Name: filter
* Author: Vivek Raturi
* Date: 
* Params: List<Subjectivity__c>
* Return: Map<String, List<Subjectivity__c>>
* Exceptions:
* Description: To filter records based on Record type
* Revision: 
*************************************************/
    public Map<String, List<Subjectivity__c>> filter(List<Subjectivity__c> dataList){  
        
        Map<String, List<Subjectivity__c>> dataList_mapByRecordType= new Map<String, List<Subjectivity__c>>();
        if(dataList == null){
            //return emplty map list has no records
            return dataList_mapByRecordType;
        }
        
        Map<ID,Schema.RecordTypeInfo> recordTypeMap = Subjectivity__c.sObjectType.getDescribe().getRecordTypeInfosById();
        
        //list of Record Types to be handled
        List<String> rt_Names = new List<String>{GlobalVariables.RT_NAME_SUBJECTIVITY_CELERITY,GlobalVariables.RT_NAME_SUBJECTIVITY_AQUEOUS};
            
            for(Subjectivity__c eachRecord : dataList ){             
                String recordTypeName = recordTypeMap.get(eachRecord.recordTypeId).getName();
                //check if record is record type being handled
                if(rt_Names.Contains(recordTypeName)){
                    if(dataList_mapByRecordType.containskey(recordTypeName)){
                        dataList_mapByRecordType.get(recordTypeName).add(eachRecord);
                    }
                    else{
                        dataList_mapByRecordType.put(recordTypeName, new list<Subjectivity__c>{eachRecord});
                    }                        
                }
                else{
                    if(dataList_mapByRecordType.containskey('Other')){
                        dataList_mapByRecordType.get('Other').add(eachRecord);
                    }
                    else{
                        dataList_mapByRecordType.put('Other', new list<Subjectivity__c>{eachRecord});
                    }                        
                }
            }        
        return dataList_mapByRecordType;
    }       
}