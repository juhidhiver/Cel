/**************************************************************************************************
 * Class Name: ProductTriggerBaseHandler
 * Author: 
 * Date: 
 * Description: Handler for ProductTrigger
 * TestClass : ProductTriggerHandlerTest
 **************************************************************************************************/
public  with sharing class ProductTriggerBaseHandler extends TriggerHandler  {

    private List<Product2> oldDataList;
	private List<Product2> newDataList;
	private Map<Id, Product2> newDataMap;
	private Map<Id, Product2> oldDataMap;
	

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
        Map<String, list<Product2>> newList_mapByRecordType = filter(Trigger.new);
        Map<String, list<Product2>> oldList_mapByRecordType = filter(Trigger.old);

        /* Logic for each record type */
        
        //prepare data for Celerity record Type
        if(newList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_CELERITY) || oldList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_CELERITY) ){
            newDataList = newList_mapByRecordType.get(GlobalVariables.RT_NAME_CELERITY); 
            oldDataList = oldList_mapByRecordType.get(GlobalVariables.RT_NAME_CELERITY); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Product2>(newDataList);	
                }			
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{ 
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Product2>(oldDataList);	
                }  
            }catch(Exception e){
                this.oldDataMap = null;
            }    
            //call Celerity relaetd logic     
             
            new ProductTriggerHandler_CEL(newDataList, oldDataList, newDataMap, oldDataMap).run();
            
        }
        //prepare data for Aqueous record Type
        if(newList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_AQUEOUS) ||  oldList_mapByRecordType.containsKey(GlobalVariables.RT_NAME_AQUEOUS)){
            newDataList = newList_mapByRecordType.get(GlobalVariables.RT_NAME_AQUEOUS); 
            oldDataList = oldList_mapByRecordType.get(GlobalVariables.RT_NAME_AQUEOUS); 
            
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                newDataMap = new Map<Id, Product2>(newDataList);
            }				
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{                
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Product2>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            } 
            //call Aqueous relaetd logic
            new ProductTriggerHandler_AQ(newDataList, oldDataList, newDataMap, oldDataMap).run();
            
        }

    }

    /*************************************************
    * Method Name: filter
    * Author:
    * Date: 
    * Params: List<Product2>
    * Return: Map<String, List<Product2>>
    * Exceptions:
    * Description: To filter records based on Record type
    * Revision: 
     *************************************************/
    public Map<String, List<Product2>> filter(List<Product2> dataList){  
        
        Map<String, List<Product2>> dataList_mapByRecordType= new Map<String, List<Product2>>();
        if(dataList == null){
            //return emplty map list has no records
            return dataList_mapByRecordType;
        }

        Map<ID,Schema.RecordTypeInfo> recordTypeMap = Product2.sObjectType.getDescribe().getRecordTypeInfosById();
        
        //list of Record Types to be handled
        List<String> rt_Names = new List<String>{GlobalVariables.RT_NAME_CELERITY,GlobalVariables.RT_NAME_AQUEOUS};
            
        for(Product2 eachRecord : dataList ){             
            String recordTypeName = recordTypeMap.get(eachRecord.recordTypeID).getName();
            //check if record is record type being handled
            if(rt_Names.Contains(recordTypeName)){
                if(dataList_mapByRecordType.containskey(recordTypeName)){
                    dataList_mapByRecordType.get(recordTypeName).add(eachRecord);
                }
                else{
                    dataList_mapByRecordType.put(recordTypeName, new list<Product2>{eachRecord});
                }                        
            }
            else{
                if(dataList_mapByRecordType.containskey('Other')){
                    dataList_mapByRecordType.get('Other').add(eachRecord);
                }
                else{
                    dataList_mapByRecordType.put('Other', new list<Product2>{eachRecord});
                }                        
            }
        }        
        return dataList_mapByRecordType;
    }       
}