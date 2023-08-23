/**************************************************************************************************
* Class Name: AgencyLicenseTriggerBaseHandler
* Author: 
* Date: 
* Description: 
**************************************************************************************************/
public  with sharing class AgencyLicenseTriggerBaseHandler extends TriggerHandler  {
    
    private List<Agency_License__c> oldDataList;
    private List<Agency_License__c> newDataList;
    private Map<Id, Agency_License__c> newDataMap;
    private Map<Id, Agency_License__c> oldDataMap;
    
    
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
        Map<String, list<Agency_License__c>> newList_mapByRecordType = filter(Trigger.new);
        Map<String, list<Agency_License__c>> oldList_mapByRecordType = filter(Trigger.old);
        
        /* Logic for each record type */
        
        //prepare data for General record Type
        if(newList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_BROKER_LICENSE_GENERAL) || oldList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_BROKER_LICENSE_GENERAL)){
            newDataList = newList_mapByRecordType.get(GlobalVariables.RT_NAME_BROKER_LICENSE_GENERAL); 
            oldDataList = oldList_mapByRecordType.get(GlobalVariables.RT_NAME_BROKER_LICENSE_GENERAL); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Agency_License__c>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{ 
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Agency_License__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            }    
            //call General AgencyLicense Trigger relaetd logic        
            new AgencyLicenseTriggerHandler_GEN(newDataList, oldDataList, newDataMap, oldDataMap).run();
            
        }
        //prepare data for MRe Appointment record Type
        if(newList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_BROKER_LICENSE_MRE) || oldList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_BROKER_LICENSE_MRE)){
            newDataList = newList_mapByRecordType.get(GlobalVariables.RT_NAME_BROKER_LICENSE_MRE); 
            oldDataList = oldList_mapByRecordType.get(GlobalVariables.RT_NAME_BROKER_LICENSE_MRE); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Agency_License__c>(newDataList);
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{  
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Agency_License__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            } 
            //call MRe Appointment AgencyLicense Trigger relaetd logic
            new AgencyLicenseTriggerHandler_MRE(newDataList, oldDataList, newDataMap, oldDataMap).run();
            
        }
        
    }
    
    /*************************************************
* Method Name: filter
* Author:
* Date: 
* Params: List<Agency_License__c>
* Return: Map<String, List<Agency_License__c>>
* Exceptions:
* Description: To filter records based on Record type
* Revision: 
*************************************************/
    public Map<String, List<Agency_License__c>> filter(List<Agency_License__c> dataList){  
        
        Map<String, List<Agency_License__c>> dataList_mapByRecordType= new Map<String, List<Agency_License__c>>();
        if(dataList == null){
            //return emplty map list has no records
            return dataList_mapByRecordType;
        }
        
        Map<ID,Schema.RecordTypeInfo> recordTypeMap = Agency_License__c.sObjectType.getDescribe().getRecordTypeInfosById();
        
        //list of Record Types to be handled
        List<String> rt_Names = new List<String>{GlobalVariables.RT_NAME_BROKER_LICENSE_GENERAL, GlobalVariables.RT_NAME_BROKER_LICENSE_MRE};
            
            for(Agency_License__c eachRecord : dataList ){             
                String recordTypeName = recordTypeMap.get(eachRecord.recordTypeID).getName();
                //check if record is record type being handled
                if(rt_Names.Contains(recordTypeName)){
                    if(dataList_mapByRecordType.containskey(recordTypeName)){
                        dataList_mapByRecordType.get(recordTypeName).add(eachRecord);
                    }
                    else{
                        dataList_mapByRecordType.put(recordTypeName, new list<Agency_License__c>{eachRecord});
                    }                        
                }
            }        
        return dataList_mapByRecordType;
    }       
}