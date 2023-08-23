/**************************************************************************************************
* Class Name: ContactTriggerBaseHandler
* Author: 
* Date: 
* Description: Base Handler for ContactTrigger
* Test Class: ContactTriggerHandlerTest
**************************************************************************************************/
public with sharing class ContactTriggerBaseHandler extends TriggerHandler {
    private List<Contact> oldDataList;
    private List<Contact> newDataList; 
    private Map<Id, Contact> newDataMap;
    private Map<Id, Contact> oldDataMap;
    
    
    public void runBaseHandler(){        
        Map<String, list<Contact>> newList_mapByRecordType = filter(Trigger.new);
        Map<String, list<Contact>> oldList_mapByRecordType = filter(Trigger.old);
        
        /* Logic for each record type */
        
        //prepare data for Broker record Type
        if(newList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_CONTACT_BROKER) || oldList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_CONTACT_BROKER)){
            newDataList = newList_mapByRecordType.get(GlobalVariables.RT_NAME_CONTACT_BROKER); 
            oldDataList = oldList_mapByRecordType.get(GlobalVariables.RT_NAME_CONTACT_BROKER); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Contact>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{   
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Contact>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            }    
            //call Broker Contact's Trigger relaetd logic        
            new ContactTriggerHandler_Broker(newDataList, oldDataList, newDataMap, oldDataMap).run();
        }
        //prepare data for Business record Type
        if(newList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_ACCOUNT_BUSINESS) || oldList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_ACCOUNT_BUSINESS)){
            newDataList = newList_mapByRecordType.get(GlobalVariables.RT_NAME_ACCOUNT_BUSINESS); 
            oldDataList = oldList_mapByRecordType.get(GlobalVariables.RT_NAME_ACCOUNT_BUSINESS); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Contact>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{  
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Contact>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            } 
            //call Business Contact's Trigger relaetd logic
            new ContactTriggerHandler_Business(newDataList, oldDataList, newDataMap, oldDataMap).run();
        } 
        //prepare data for other record types
        if(newList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_CONTACT_OTHER) || oldList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_CONTACT_OTHER)){
            newDataList = newList_mapByRecordType.get(GlobalVariables.RT_NAME_CONTACT_OTHER); 
            oldDataList = oldList_mapByRecordType.get(GlobalVariables.RT_NAME_CONTACT_OTHER); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Contact>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{   
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Contact>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            } 
            //call Other Contact' Trigger relaetd logic
            new ContactTriggerHandler_Other(newDataList, oldDataList, newDataMap, oldDataMap).run();
            
        }
    }
    
    
    public Map<String, List<Contact>> filter(List<Contact> dataList){  
        Map<String, List<Contact>> dataList_mapByBusiness = new Map<String, List<Contact>>();
        if(dataList == null){
            return dataList_mapByBusiness;
        }
        Map<ID,Schema.RecordTypeInfo> ContactRecordTypeMap = Contact.sObjectType.getDescribe().getRecordTypeInfosById();        
        List<String> rt_Names = new List<String>{GlobalVariables.RT_NAME_CONTACT_BUSINESS,GlobalVariables.RT_NAME_CONTACT_BROKER};
            for(Contact eachRecord : dataList ){             
                String recordTypeName = ContactRecordTypeMap.get(eachRecord.recordTypeID).getName();
                if(rt_Names.Contains(recordTypeName)){
                    if(dataList_mapByBusiness.containskey(recordTypeName)){
                        dataList_mapByBusiness.get(recordTypeName).add(eachRecord);
                    }
                    else{
                        dataList_mapByBusiness.put(recordTypeName, new list<Contact>{eachRecord});
                    }                        
                }
                else{
                    if(dataList_mapByBusiness.containskey(GlobalVariables.RT_NAME_CONTACT_OTHER)){
                        dataList_mapByBusiness.get(GlobalVariables.RT_NAME_CONTACT_OTHER).add(eachRecord);
                    }
                    else{
                        dataList_mapByBusiness.put(GlobalVariables.RT_NAME_CONTACT_OTHER, new list<Contact>{eachRecord});
                    }                        
                }
            }        
        return dataList_mapByBusiness;
    }   
}