/*************************************************
* Class Name: BrokerAccountTriggerHandler 
* Author: Long Ly
* Date: 2019 August 08
* Requirement/Project Description: Trigger to handle automation on Broker Account
*************************************************/
trigger BrokerAccountTrigger on Broker_Account__c (before insert, after insert,before update, after Update, before delete, after delete) {
    
    if( !BrokerAccountTriggerBaseHandler.isBypassed('BrokerAccountTriggerBaseHandler')){
        new BrokerAccountTriggerBaseHandler().runBaseHandler();  
    }
}