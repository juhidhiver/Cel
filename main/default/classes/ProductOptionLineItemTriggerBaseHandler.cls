/**************************************************************************************************
* Class Name: ProductOptionLineItemTriggerBaseHandler
* Author: Vinay 
* Date: 16th Dec 2021
* Description: Base class for product option line item trigger
* Test Class : ProductOptionLineItemTriggerHandlerTest
**************************************************************************************************/
public with sharing class ProductOptionLineItemTriggerBaseHandler extends TriggerHandler {
    private List<Product_Option_Line_Item__c> oldDataList;
    private List<Product_Option_Line_Item__c> newDataList; 
    private Map<Id, Product_Option_Line_Item__c> newDataMap;
    private Map<Id, Product_Option_Line_Item__c> oldDataMap;
    
    
    public void runBaseHandler(){
        this.newDataList = Trigger.new;
        this.oldDataList = Trigger.old;
        
        try{
            if( this.newDataList != null && !this.newDataList.isEmpty()){
                newDataMap = new Map<Id, Product_Option_Line_Item__c>(this.newDataList);
            }
        }catch(Exception e){
            this.newDataMap = null;			
        }          
        
        try{  
            if( this.oldDataList != null &&  !this.oldDataList.isEmpty()){
                oldDataMap = new Map<Id, Product_Option_Line_Item__c>(this.oldDataList);
            }
        }catch(Exception e){
            this.oldDataMap = null;
        }    
        new ProductOptionLineItemTriggerHandler_CEL(newDataList, oldDataList, newDataMap, oldDataMap).run();
    }
}