/*************************************************
* Class Name: BrokerLicenseTrigger 
* Author: Binh Dang
* Date: 2019 November 1
* Requirement/Project Description: Trigger to handle automation on Broker License
*************************************************/
trigger BrokerLicenseTrigger on Broker_License__c (before insert, after insert,before update, after Update, after delete) {
    if(!CommonUtil.isTriggerBypass('BrokerLicenseTrigger')){
     
      BrokerLicenseTriggerBaseHandler baseHanderObj = new BrokerLicenseTriggerBaseHandler();
        baseHanderObj.run(); 
        if( !BrokerLicenseTriggerBaseHandler.isBypassed('BrokerLicenseTriggerBaseHandler')){
            new BrokerLicenseTriggerBaseHandler().runBaseHandler();  
        }
    }
}