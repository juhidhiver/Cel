/**************************************************************************************************
* Class Name: FreeFormEndorsementTriggerBaseHandler
* Author: 
* Date: 
* Description: Handler for FreeFormEndorsementTrigger
**************************************************************************************************/

public with sharing class FreeFormEndorsementTriggerBaseHandler extends TriggerHandler {
    
    private List<Free_Form_Endorsements__c> oldDataList;
    private List<Free_Form_Endorsements__c> newDataList;
    private Map<Id, Free_Form_Endorsements__c> newDataMap;
    private Map<Id, Free_Form_Endorsements__c> oldDataMap;
    private Map<Id,Quote> quoteMap;
    
    
    /*************************************************
* Method Name: run
* Author:
* Date: 
* Params: 
* Return: 
* Exceptions:
* Description: To filter records based on Record type and run Record Type specific handler
* Revision: 
*************************************************/
    
    public void runBaseHandler(){
        newDataList = trigger.new;
        oldDataList = trigger.old != null ? trigger.old : new List<Free_Form_Endorsements__c>() ;
        newDataMap = (Map<Id, Free_Form_Endorsements__c>)trigger.newmap;
        oldDataMap = (Map<Id, Free_Form_Endorsements__c>)trigger.oldmap;
        
        //prepare parent record map
        List<Free_Form_Endorsements__c> dataList = Trigger.isDelete == true ? oldDataList : newDataList;
        quoteMap = processFFERecords(dataList);
        
        Map<String, list<Free_Form_Endorsements__c>> newList_mapByRecordType = filter(Trigger.new, quoteMap);
        Map<String, list<Free_Form_Endorsements__c>> oldList_mapByRecordType = filter(Trigger.old, quoteMap);
        
        
        //prepare data for MRe Appointment record Type
        if(newList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_AQUEOUS) || oldList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_AQUEOUS)){
            newDataList = newList_mapByRecordType.get(GlobalVariables.RT_NAME_AQUEOUS); 
            oldDataList = oldList_mapByRecordType.get(GlobalVariables.RT_NAME_AQUEOUS); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Free_Form_Endorsements__c>(newDataList);
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{   
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Free_Form_Endorsements__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            } 
            //call MRe Appointment AgencyLicense Trigger relaetd logic
            new FreeFormEndorsementTriggerHandler_AQ(newDataList, oldDataList, newDataMap, oldDataMap).run();  
        }
        
        
    }    
    
    /*************************************************
* Method Name: filter
* Author:
* Date: 
* Params: List<Free_Form_Endorsements__c>
* Return: Map<String, List<Free_Form_Endorsements__c>>
* Exceptions:
* Description: To filter records based on Record type
* Revision: 
*************************************************/
    public Map<String, List<Free_Form_Endorsements__c>> filter(List<Free_Form_Endorsements__c> dataList, Map<Id,Quote> quoteMap){  
        
        Map<String, List<Free_Form_Endorsements__c>> dataList_mapByRecordType = new Map<String, List<Free_Form_Endorsements__c>>();
        if(dataList == null){
            //return emplty map list has no records
            return dataList_mapByRecordType;
        }
        
        /***Map<ID,Schema.RecordTypeInfo> recordTypeMap = Agency_License__c.sObjectType.getDescribe().getRecordTypeInfosById();***/
        
        //list of Record Types to be handled
        List<String> rt_Names = new List<String>{GlobalVariables.RT_NAME_CELERITY, GlobalVariables.RT_NAME_AQUEOUS};
            
            for(Free_Form_Endorsements__c eachRecord : dataList ){             
                /***String recordTypeName = recordTypeMap.get(eachRecord.recordTypeID).getName();***/
                String recordTypeName = quoteMap.get(eachRecord.Quote__c).Opportunity.RecordType.Name;
                
                //check if record is record type being handled
                if(rt_Names.Contains(recordTypeName)){
                    if(dataList_mapByRecordType.containskey(recordTypeName)){
                        dataList_mapByRecordType.get(recordTypeName).add(eachRecord);
                    }
                    else{
                        dataList_mapByRecordType.put(recordTypeName, new list<Free_Form_Endorsements__c>{eachRecord});
                    }                        
                }
                else{
                    if(dataList_mapByRecordType.containskey('Other')){
                        dataList_mapByRecordType.get('Other').add(eachRecord);
                    }
                    else{
                        dataList_mapByRecordType.put('Other', new list<Free_Form_Endorsements__c>{eachRecord});
                    }                        
                }
            }        
        return dataList_mapByRecordType;
    }  
    
    /*************************************************
* Method Name: processFFERecords
* Author:
* Date: 
* Params: List<Free_Form_Endorsements__c>
* Return: Map<String, List<Quote>>
* Exceptions:
* Description: To filter records based on Record type
* Revision: 
*************************************************/
    public static map<Id,Quote> processFFERecords( list<Free_Form_Endorsements__c> dataList ){
        
        //prepare quote ids set
        set<Id> parentIds =  new set<Id>();
        for( Free_Form_Endorsements__c eachRecord : dataList ){
            parentIds.add( eachRecord.Quote__c);
        }
        
        //return map with record type info
        String queryFields = 'Id, OpportunityId, Opportunity.RecordTypeId, Opportunity.RecordType.Name';
        return new map<Id,Quote>( QuoteQueryUtil.fetchQuotesForQuoteIds( parentIds, queryFields ) );
    }
    
    
}