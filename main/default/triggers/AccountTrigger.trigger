/**************************************************************************************************
 * Class Name: AccountLocationTrigger
 * Author: Binh Dang
 * Date: 17-May-2019
 * Description: Trigger on object Account
 **************************************************************************************************/
Trigger AccountTrigger on Account (before insert, after insert, before update, after update) {
    if(!CommonUtil.isTriggerBypass('AccountTrigger')){
        
        AccountTriggerBaseHandler baseHanderObj = new AccountTriggerBaseHandler();
        baseHanderObj.run(); 
        if( !AccountTriggerBaseHandler.isBypassed('AccountTriggerBaseHandler')){
            new AccountTriggerBaseHandler().runBaseHandler();  
        }
    }
}