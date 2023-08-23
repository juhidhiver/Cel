/**************************************************************************************************
 * Class Name: ProductOptionLineItemTriggerHandler_CEL
 * Author: 
 * Date: 16th Dec 2021
 * Description: Class to keep product option line item related common methods
 * Test Class : ProductOptionLineItemTriggerHandlerTest
 **************************************************************************************************/
public with sharing class ProductOptionLineItemTriggerHandler_CEL  extends TriggerHandler{
    private List<Product_Option_Line_Item__c> oldDataList;
    private List<Product_Option_Line_Item__c> newDataList; 
    private Map<Id, Product_Option_Line_Item__c> newDataMap;
    private Map<Id, Product_Option_Line_Item__c> oldDataMap; 
    
    public ProductOptionLineItemTriggerHandler_CEL(List<Product_Option_Line_Item__c> newDataList, List<Product_Option_Line_Item__c> oldDataList, Map<Id, Product_Option_Line_Item__c> newDataMap, Map<Id, Product_Option_Line_Item__c> oldDataMap){
        this.oldDataList = oldDataList;
        this.newDataList = newDataList;
        this.newDataMap = newDataMap;
        this.oldDataMap = oldDataMap;
    }

	public override void beforeInsert()	{
        //existing poli validation
        CommonProductOptionLineItemUtil.existingPOLIValidation(newDataList);
    }

    public override void beforeUpdate(){
        
    }

	public override void afterInsert(){
        //List<Product_Option_Line_Item__c> currPoli = this.newDataList[0];
        //Maybe dont need validate for new. Just add for selected.
        CommonProductOptionLineItemUtil.RatingModifiersValidate(newDataList, oldDataMap);
        //update rating modifiers for opportunity/submission
        CommonProductOptionLineItemUtil.updateRatingModifiersForOpps(newDataList);
    }

	public override void afterUpdate(){
        //List<Product_Option_Line_Item__c> currPoli = this.newDataList[0];
        //Maybe dont need validate for new. Just add for selected.
        CommonProductOptionLineItemUtil.RatingModifiersValidate(newDataList, oldDataMap);
        //update rating modifiers for opportunity/submission
        CommonProductOptionLineItemUtil.updateRatingModifiersForOpps(newDataList);
    }

	public override void afterDelete(){
        //delete related rating modifiers
        CommonProductOptionLineItemUtil.deleteRatingModifiers(oldDataList);
    }
}