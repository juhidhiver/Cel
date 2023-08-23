/**************************************************************************************************
 * Class Name: ProductTriggerHandler_AQ
 * Author: 
 * Date: 
 * Description: Class to keep AQ related  common methods
 * Test Class : ProductTriggerHandlerTest
 **************************************************************************************************/
public with sharing class ProductTriggerHandler_AQ extends TriggerHandler {


    private List<Product2> oldDataList;
    private List<Product2> newDataList; 
    private Map<Id, Product2> newDataMap;
    private Map<Id, Product2> oldDataMap; 

    public ProductTriggerHandler_AQ(  List<Product2> newDataList, 
                                                List<Product2> oldDataList, 
                                                Map<Id, Product2> newDataMap, 
                                                Map<Id, Product2> oldDataMap){
        this.oldDataList = oldDataList;
        this.newDataList = newDataList;
        this.newDataMap = newDataMap;
        this.oldDataMap = oldDataMap;
    } 

    public override void afterInsert(){
        //add product name to object's picklist field 
        CommonProductUtil.addProductNameToObject('Rating_Modifier_Template__c.Modifier_Product__c',newDataList);
        CommonProductUtil.addProductNameToObject('Rating_Modifiers__c.Product__c',newDataList);
        CommonProductUtil.addProductNameToObject('Coverage__c.Coverage_Product__c',newDataList);
        CommonProductUtil.addProductNameToObject('CoveragesLineItem__c.Coverage_Product__c',newDataList);
        CommonProductUtil.addProductNameToObject('Endorsement_Line_Item__c.Coverage_Product__c',newDataList);
        CommonProductUtil.addProductNameToObject('Eligibility_Status__c.Modifier_Product__c',newDataList);
       
    }

    public override void afterUpdate() {
        //update product name in object's picklist field 
        CommonProductUtil.updateProductNameFromObject('Modifier_Product',oldDataMap, newDataMap);
    }

    public override void afterDelete() {
        //remove product name from object's picklist field 
        CommonProductUtil.removeProductNameFromObject('Rating_Modifier_Template__c.Modifier_Product__c',oldDataList);
        CommonProductUtil.removeProductNameFromObject('Rating_Modifiers__c.Product__c',oldDataList);
        CommonProductUtil.removeProductNameFromObject('Coverage__c.Coverage_Product__c', oldDataList);
        CommonProductUtil.removeProductNameFromObject('CoveragesLineItem__c.Coverage_Product__c', oldDataList);
        CommonProductUtil.removeProductNameFromObject('Endorsement_Line_Item__c.Coverage_Product__c', oldDataList);
        CommonProductUtil.removeProductNameFromObject('Eligibility_Status__c.Modifier_Product__c', oldDataList);
    }
}