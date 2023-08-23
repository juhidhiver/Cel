public class AccountProductTriggerBaseHandler  extends TriggerHandler {
    
    private List<Account_Product__c> oldDataList;
    private List<Account_Product__c> newDataList;
    private Map<Id, Account_Product__c> newDataMap;
    private Map<Id, Account_Product__c> oldDataMap;
    private static final String RT_NAME_CELERITY = GlobalVariables.RT_NAME_CELERITY;
    public  Map<Id,Product2> prodmap = new Map<Id,Product2>();
    
    public AccountProductTriggerBaseHandler (){  
        
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
      
        /* Logic for each record type-- */
        /*For Celerity */
        Map<String, list<Account_Product__c>> newList_map = filter(Trigger.new);
        Map<String, list<Account_Product__c>> oldList_map = filter(Trigger.old);
        system.debug('newList_map-->'+newList_map.size()); // Size 1
        newDataList = newList_map.get(GlobalVariables.CELERITY); 
        oldDataList = oldList_map.get(GlobalVariables.CELERITY);   
            try{
                if( newDataList != null && !newDataList.isEmpty()){
                    newDataMap = new Map<Id, Account_Product__c>(newDataList);	
                }
            }catch(Exception e){
                this.newDataMap = null;			
            }            
            try{    
                if( oldDataList != null &&  !oldDataList.isEmpty()){
                    oldDataMap = new Map<Id, Account_Product__c>(oldDataList);
                }
            }catch(Exception e){
                this.oldDataMap = null;
            }    
            //call Celerity AccountProduct Trigger related logic     
            new AccountProductTriggerHandler_Cel(newDataList, oldDataList, newDataMap, oldDataMap,prodmap).run();
    
    }  
    
     public Map<String, List<Account_Product__c>> filter(List<Account_Product__c> dataList){  
        Map<String, List<Account_Product__c>> dataList_map = new Map<String, List<Account_Product__c>>();
          if(dataList == null){
            return dataList_map;
          }
       
         List<Product2> prod = [Select Id,Name,Innovisk_Entity_Id__c from Product2 where Innovisk_Entity_Id__c =: 'Celerity'];
         for(Product2 p: prod){
             prodmap.put(p.id,p);
         }
       system.debug('data-->'+dataList);  
       List<Account_Product__c>  aplist = new  List<Account_Product__c>();
    for(Account_Product__c ap: dataList){
            if(!prodmap.isEmpty() && prodmap.containsKey(ap.Product_Id__c) &&
               (prodmap.get(ap.Product_Id__c).Name == 'Cyber Standalone' || 
               prodmap.get(ap.Product_Id__c).Name == 'MPL Standalone' ||
               prodmap.get(ap.Product_Id__c).Name == 'Private Company Combo')){
                      aplist.add(ap);
                      dataList_map.put(  prodmap.get(ap.Product_Id__c).Innovisk_Entity_Id__c , aplist );
           //system.debug('Product-->'+ap.Product_Id__c);
               }
        }  
      system.debug('dataList_map-->'+dataList_map);     
    return dataList_map;
    } 
    
   
}