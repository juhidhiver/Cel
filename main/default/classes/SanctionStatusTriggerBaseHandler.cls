/**************************************************************************************************
* Class Name: SanctionStatusTriggerBaseHandler
* Author: 
* Date: 
* Description: Handler for SanctionStatus Trigger
**************************************************************************************************/
public class SanctionStatusTriggerBaseHandler extends TriggerHandler {
    
    private List<Sanction_Status__c> oldDataList;
    private List<Sanction_Status__c> newDataList;
    private Map<Id, Sanction_Status__c> newDataMap;
    private Map<Id, Sanction_Status__c> oldDataMap;
    private static final String RT_NAME_CELERITY = GlobalVariables.RT_NAME_CELERITY;
    private static final String RT_NAME_AQUEOUS = GlobalVariables.RT_NAME_AQUEOUS;
    
    public SanctionStatusTriggerBaseHandler(){
        
    }

    /*************************************************
    * Method Name: filter
    * Author:
    * Date: 
    * Params: List<Sanction_Status__c>
    * Return: Map<String, List<Sanction_Status__c>>
    * Exceptions:
    * Description: To filter records based on Record type
    * Revision: 
    *************************************************/
    public Map<String, List<Sanction_Status__c>> filter(List<Sanction_Status__c> dataList){  
            
        Map<String, List<Sanction_Status__c>> dataList_mapByRecordType= new Map<String, List<Sanction_Status__c>>();
        if(dataList == null){
            //return emplty map list has no records
            return dataList_mapByRecordType;
        }
        
        Map<ID,Schema.RecordTypeInfo> recordTypeMap = Sanction_Status__c.sObjectType.getDescribe().getRecordTypeInfosById();
        
        //list of Record Types to be handled
        List<String> rt_Names = new List<String>{RT_NAME_CELERITY,RT_NAME_AQUEOUS};
            
            for(Sanction_Status__c eachRecord : dataList ){             
                String recordTypeName = eachRecord.recordTypeID != null ? recordTypeMap.get(eachRecord.recordTypeID).getName() : null;
                //check if record is record type being handled
                if(String.isNotBlank(recordTypeName) && rt_Names.Contains(recordTypeName)){
                    if(dataList_mapByRecordType.containskey(recordTypeName)){
                        dataList_mapByRecordType.get(recordTypeName).add(eachRecord);
                    }
                    else{
                        dataList_mapByRecordType.put(recordTypeName, new List<Sanction_Status__c>{eachRecord});
                    }                        
                }
                else{
                    if(dataList_mapByRecordType.containskey('Other')){
                        dataList_mapByRecordType.get('Other').add(eachRecord);
                    }
                    else{
                        dataList_mapByRecordType.put('Other', new List<Sanction_Status__c>{eachRecord});
                    }                        
                }
            }        
        return dataList_mapByRecordType;
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
        Map<String, list<Sanction_Status__c>> newList_mapByRecordType = filter(Trigger.new);
        Map<String, list<Sanction_Status__c>> oldList_mapByRecordType = filter(Trigger.old);
        
        /* Logic for each record type */
        
        //prepare data for Celerity record Type
        if(newList_mapByRecordType.containsKey(RT_NAME_CELERITY) || oldList_mapByRecordType.containsKey(RT_NAME_CELERITY)){
            newDataList = newList_mapByRecordType.get(RT_NAME_CELERITY); 
            oldDataList = oldList_mapByRecordType.get(RT_NAME_CELERITY); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Sanction_Status__c>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{    
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Sanction_Status__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            }    
            //call Celerity Sanction_Status__c Trigger related logic        
            new SanctionStatusTriggerHandler_CEL(newDataList, oldDataList, newDataMap, oldDataMap).run();
            
        }
        //prepare data for Aqueous record Type
        if(newList_mapByRecordType.containsKey(RT_NAME_AQUEOUS) || oldList_mapByRecordType.containsKey(RT_NAME_AQUEOUS) ){
            newDataList = newList_mapByRecordType.get(RT_NAME_AQUEOUS); 
            oldDataList = oldList_mapByRecordType.get(RT_NAME_AQUEOUS); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Sanction_Status__c>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{   
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Sanction_Status__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            } 
            //call Aqueous Sanction_Status__c Trigger related logic
            new SanctionStatusTriggerHandler_AQ(newDataList, oldDataList, newDataMap, oldDataMap).run();
            
        }
    
    }

}