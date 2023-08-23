/**************************************************************************************************
* Class Name: BrokerLicenseTriggerBaseHandler
* Author: 
* Date: 
* Description: 
**************************************************************************************************/
public  with sharing class BrokerLicenseTriggerBaseHandler extends TriggerHandler {
    
    private List<Broker_License__c> oldDataList;
    private List<Broker_License__c> newDataList;
    private Map<Id, Broker_License__c> newDataMap;
    private Map<Id, Broker_License__c> oldDataMap;
    
    
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
        Map<String, list<Broker_License__c>> newList_mapByRecordType = filter(Trigger.new);
        Map<String, list<Broker_License__c>> oldList_mapByRecordType = filter(Trigger.old);
        
        /* Logic for each record type */
        
        //prepare data for General record Type
        if(newList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_BROKER_LICENSE_GENERAL) || oldList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_BROKER_LICENSE_GENERAL)){
            newDataList = newList_mapByRecordType.get(GlobalVariables.RT_NAME_BROKER_LICENSE_GENERAL); 
            oldDataList = oldList_mapByRecordType.get(GlobalVariables.RT_NAME_BROKER_LICENSE_GENERAL); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Broker_License__c>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{  
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Broker_License__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            }    
            //call General BrokerLicense Trigger relaetd logic        
            new BrokerLicenseTriggerHandler_General(newDataList, oldDataList, newDataMap, oldDataMap).run();
            
        }
        //prepare data for MRe Appointment record Type
        if(newList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_BROKER_LICENSE_MRE) || oldList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_BROKER_LICENSE_MRE)){
            newDataList = newList_mapByRecordType.get(GlobalVariables.RT_NAME_BROKER_LICENSE_MRE); 
            oldDataList = oldList_mapByRecordType.get(GlobalVariables.RT_NAME_BROKER_LICENSE_MRE); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Broker_License__c>(newDataList);
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{    
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Broker_License__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            } 
            //call MRe Appointment BrokerLicense Trigger relaetd logic
            new BrokerLicenseTriggerHandler_MRE(newDataList, oldDataList, newDataMap, oldDataMap).run();
        }
    }
    
    /*************************************************
* Method Name: filter
* Author:
* Date: 
* Params: List<Broker_License__c>
* Return: Map<String, List<Broker_License__c>>
* Exceptions:
* Description: To filter records based on Record type
* Revision: 
*************************************************/
    public Map<String, List<Broker_License__c>> filter(List<Broker_License__c> dataList){  
        
        Map<String, List<Broker_License__c>> dataList_mapByRecordType= new Map<String, List<Broker_License__c>>();
        if(dataList == null){
            //return emplty map list has no records
            return dataList_mapByRecordType;
        }
        
        Map<ID,Schema.RecordTypeInfo> AgencyLicenseRecordTypeMap = Broker_License__c.sObjectType.getDescribe().getRecordTypeInfosById();
        
        //list of Record Types to be handled
        List<String> rt_Names = new List<String>{GlobalVariables.RT_NAME_BROKER_LICENSE_MRE, GlobalVariables.RT_NAME_BROKER_LICENSE_GENERAL};
            
            for(Broker_License__c eachRecord : dataList ){             
                String recordTypeName = AgencyLicenseRecordTypeMap.get(eachRecord.recordTypeID).getName();
                //check if record is record type being handled
                if(rt_Names.Contains(recordTypeName)){
                    if(dataList_mapByRecordType.containskey(recordTypeName)){
                        dataList_mapByRecordType.get(recordTypeName).add(eachRecord);
                    }
                    else{
                        dataList_mapByRecordType.put(recordTypeName, new list<Broker_License__c>{eachRecord});
                    }                        
                }
            }        
        return dataList_mapByRecordType;
    }       
}