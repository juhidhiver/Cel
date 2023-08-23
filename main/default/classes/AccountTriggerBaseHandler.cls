/**************************************************************************************************
* Class Name: AccountTriggerBaseHandler
* Author: 
* Date: 
* Description: Base Handler for AccountTrigger
**************************************************************************************************/
public class AccountTriggerBaseHandler extends TriggerHandler {
    private List<Account> oldDataList;
    private List<Account> newDataList; 
    private Map<Id, Account> newDataMap;
    private Map<Id, Account> oldDataMap;
    
    
    public void runBaseHandler(){        
        Map<String, list<Account>> newList_mapByRecordType = filter(Trigger.new);
        Map<String, list<Account>> oldList_mapByRecordType = filter(Trigger.old);
        
        /* Logic for each record type */
        
        //prepare data for Broker record Type
        if(newList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_ACCOUNT_BROKER) || oldList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_ACCOUNT_BROKER)){
            newDataList = newList_mapByRecordType.get(GlobalVariables.RT_NAME_ACCOUNT_BROKER); 
            oldDataList = oldList_mapByRecordType.get(GlobalVariables.RT_NAME_ACCOUNT_BROKER); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Account>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{   
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Account>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            }    
            //call Broker Account's Trigger relaetd logic        
            new AccountTriggerHandler_Broker(newDataList, oldDataList, newDataMap, oldDataMap).run();
        }
        //prepare data for Business record Type
        if(newList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_ACCOUNT_BUSINESS) || oldList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_ACCOUNT_BUSINESS)){
            newDataList = newList_mapByRecordType.get(GlobalVariables.RT_NAME_ACCOUNT_BUSINESS); 
            oldDataList = oldList_mapByRecordType.get(GlobalVariables.RT_NAME_ACCOUNT_BUSINESS); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Account>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{   
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Account>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            } 
            //call Business Account's Trigger relaetd logic
            new AccountTriggerHandler_Business(newDataList, oldDataList, newDataMap, oldDataMap).run();
        } 
        //prepare data for other record types
        if(newList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_ACCOUNT_OTHER) || oldList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_ACCOUNT_OTHER)){
            newDataList = newList_mapByRecordType.get(GlobalVariables.RT_NAME_ACCOUNT_OTHER); 
            oldDataList = oldList_mapByRecordType.get(GlobalVariables.RT_NAME_ACCOUNT_OTHER); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Account>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{  
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Account>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            } 
            //call Other Account' Trigger relaetd logic
            new AccountTriggerHandler_Other(newDataList, oldDataList, newDataMap, oldDataMap).run();
            
        }
    }
    
    
    public Map<String, List<Account>> filter(List<Account> dataList){  
        Map<String, List<Account>> dataList_mapByBusiness = new Map<String, List<Account>>();
        if(dataList == null){
            return dataList_mapByBusiness;
        }
        Map<ID,Schema.RecordTypeInfo> AccountRecordTypeMap = Account.sObjectType.getDescribe().getRecordTypeInfosById();        
        List<String> rt_Names = new List<String>{GlobalVariables.RT_NAME_ACCOUNT_BUSINESS,GlobalVariables.RT_NAME_ACCOUNT_BROKER};
            for(Account eachRecord : dataList ){             
                String recordTypeName = AccountRecordTypeMap.get(eachRecord.recordTypeID).getName();
                if(rt_Names.Contains(recordTypeName)){
                    if(dataList_mapByBusiness.containskey(recordTypeName)){
                        dataList_mapByBusiness.get(recordTypeName).add(eachRecord);
                    }
                    else{
                        dataList_mapByBusiness.put(recordTypeName, new list<Account>{eachRecord});
                    }                        
                }
                else{
                    if(dataList_mapByBusiness.containskey(GlobalVariables.RT_NAME_ACCOUNT_OTHER)){
                        dataList_mapByBusiness.get(GlobalVariables.RT_NAME_ACCOUNT_OTHER).add(eachRecord);
                    }
                    else{
                        dataList_mapByBusiness.put(GlobalVariables.RT_NAME_ACCOUNT_OTHER, new list<Account>{eachRecord});
                    }                        
                }
            }        
        return dataList_mapByBusiness;
    }    
}