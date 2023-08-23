/**************************************************************************************************
 * Class Name: ProductTrigger
 * Author: Hoang Bui
 * Date: 21-Aug-2019
 * Description: Trigger on object Product2
 **************************************************************************************************/

trigger ProductTrigger on Product2 (before insert, before update, after insert, after update, after delete) {
	if(!CommonUtil.isTriggerBypass('ProductTrigger')){
		
        ProductTriggerBaseHandler baseHanderObj = new ProductTriggerBaseHandler();
        baseHanderObj.run(); 
        if( !ProductTriggerBaseHandler.isBypassed('ProductTriggerBaseHandler')){
            new ProductTriggerBaseHandler().runBaseHandler();  
        }
    }
}