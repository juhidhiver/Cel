/**************************************************************************************************
* Class Name: QuoteTriggerBaseHandler
* Author: 
* Date: 
* Description: Handler for Quote Trigger
**************************************************************************************************/
public with sharing class QuoteTriggerBaseHandler extends TriggerHandler {
    
    private List<Quote> oldDataList;
    private List<Quote> newDataList;
    private Map<Id, Quote> newDataMap;
    private Map<Id, Quote> oldDataMap;
    private static Map<String, List<String>> oppComboProductsMap = new Map<String, List<String>>();
    private static final String RT_NAME_CELERITY = GlobalVariables.RT_NAME_CELERITY;
    private static final String RT_NAME_AQUEOUS = GlobalVariables.RT_NAME_AQUEOUS;
    
    public QuoteTriggerBaseHandler(){
        
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
        Map<String, list<Quote>> newList_mapByRecordType = filter(Trigger.new);
        Map<String, list<Quote>> oldList_mapByRecordType = filter(Trigger.old);
        /* Logic for each record type */
        
        //prepare data for Celerity record Type
        if(newList_mapByRecordType.containsKey(RT_NAME_CELERITY) || oldList_mapByRecordType.containsKey(RT_NAME_CELERITY) ){
            newDataList = newList_mapByRecordType.get(RT_NAME_CELERITY); 
            oldDataList = oldList_mapByRecordType.get(RT_NAME_CELERITY);
            
            boolean isPccQuote = false;
            for(Quote newQuote : newDataList){
                System.debug('newQuote.Product_Name__c---->'+newQuote.Product_Name__c);
                if(newQuote.Product_Name__c == System.label.Product_Name_for_PCC){
                    isPccQuote = true;
                }
            }
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Quote>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{ 
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Quote>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            }    
            //call Celerity Quote Trigger related logic        
            new QuoteTriggerHandler_CEL(newDataList, oldDataList, newDataMap, oldDataMap, isPccQuote).run();
            
        }
        //prepare data for Aqueous record Type
        if(newList_mapByRecordType.containsKey(RT_NAME_AQUEOUS) || oldList_mapByRecordType.containsKey(RT_NAME_AQUEOUS)){
            newDataList = newList_mapByRecordType.get(RT_NAME_AQUEOUS); 
            oldDataList = oldList_mapByRecordType.get(RT_NAME_AQUEOUS); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Quote>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{  
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Quote>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            } 
            //call Aqueous Quote Trigger related logic
            new QuoteTriggerHandler_AQ(newDataList, oldDataList, newDataMap, oldDataMap).run();
            
        }
        
    }
    
    /*************************************************
* Method Name: filter
* Author:
* Date: 
* Params: List<Quote>
* Return: Map<String, List<Quote>>
* Exceptions:
* Description: To filter records based on Record type
* Revision: 
*************************************************/
    public Map<String, List<Quote>> filter(List<Quote> dataList){  
        
        Map<String, List<Quote>> dataList_mapByRecordType= new Map<String, List<Quote>>();
        if(dataList == null){
            //return emplty map list has no records
            return dataList_mapByRecordType;
        }
        
        Map<ID,Schema.RecordTypeInfo> oppRecordTypeMap = Opportunity.sObjectType.getDescribe().getRecordTypeInfosById();
        
        //list of Record Types to be handled
        List<String> rt_Names = new List<String>{RT_NAME_CELERITY,RT_NAME_AQUEOUS};
        List<Quote> dataListWOclone = new List<Quote>();
        for(Quote qt : dataList) {
            if(!qt.isClone()) {
                dataListWOclone.add(qt);
            }
        }
        for(Quote eachRecord : dataListWOclone ){             
            String recordTypeName;
            System.debug('eachRecord.Product_Name__c'+eachRecord.Product_Name__c);
            if(eachRecord.Product_Name__c == 'Professional Indemnity'){
                recordTypeName = RT_NAME_AQUEOUS;
            }
            else if(eachRecord.Product_Name__c == 'MPL Standalone' || eachRecord.Product_Name__c == 'Cyber Standalone' || eachRecord.Product_Name__c == System.label.Product_Name_for_PCC){
                recordTypeName = RT_NAME_CELERITY;
            }
            //check if record is record type being handled
            if(rt_Names.Contains(recordTypeName)){
                if(dataList_mapByRecordType.containskey(recordTypeName)){
                    dataList_mapByRecordType.get(recordTypeName).add(eachRecord);
                }
                else{
                    dataList_mapByRecordType.put(recordTypeName, new List<Quote>{eachRecord});
                }                        
            }
            else{
                if(dataList_mapByRecordType.containskey('Other')){
                    dataList_mapByRecordType.get('Other').add(eachRecord);
                }
                else{
                    dataList_mapByRecordType.put('Other', new List<Quote>{eachRecord});
                }                        
            }
        }        
        return dataList_mapByRecordType;
    }
    
}