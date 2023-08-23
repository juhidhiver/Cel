/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 07-01-2021
 * @last modified by  : Vinayesh
 * Modifications Log 
 * Ver   Date         Author     Modification
 * 1.0   06-24-2021   Vinayesh   Initial Version
**/
trigger ProductOptionLineItemTrigger on Product_Option_Line_Item__c(before insert, before update, before delete,
                                                                      after insert, after update, after delete) {
    //Need to add trigger bypass code here.
    new ProductOptionLineItemTriggerBaseHandler().run(); 
        ProductOptionLineItemTriggerBaseHandler baseHanderObj = new ProductOptionLineItemTriggerBaseHandler();
        baseHanderObj.run(); 
        if( !ProductOptionLineItemTriggerBaseHandler.isBypassed('ProductOptionLineItemTriggerBaseHandler')){
            new ProductOptionLineItemTriggerBaseHandler().runBaseHandler();  
        }                                                                         
}