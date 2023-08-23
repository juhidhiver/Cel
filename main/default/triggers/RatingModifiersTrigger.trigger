/**************************************************************************************************
 * Class Name: RatingModifiersTrigger
 * Author: Hoang Bui
 * Date: 23-Aug-2019
 * Description: Trigger on object Rating_Modifiers__c
 **************************************************************************************************/
trigger RatingModifiersTrigger on Rating_Modifiers__c (before insert, before update, after insert, after update, after delete) {
    if(!CommonUtil.isTriggerBypass('RatingModifiersTrigger')){
		//new RatingModifiersTriggerBaseHandler().run();
        RatingModifiersTriggerBaseHandler baseHanderObj = new RatingModifiersTriggerBaseHandler();
        baseHanderObj.run(); 
        if( !RatingModifiersTriggerBaseHandler.isBypassed('RatingModifiersTriggerBaseHandler')){
            new RatingModifiersTriggerBaseHandler().runBaseHandler();  
        }
	}
}