trigger AgencyLicenseTrigger on Agency_License__c (after insert, after update) {
    if(!CommonUtil.isTriggerBypass('AgencyLicenseTrigger')){
       
      AgencyLicenseTriggerBaseHandler baseHanderObj = new AgencyLicenseTriggerBaseHandler();
        baseHanderObj.run(); 
        if( !AgencyLicenseTriggerBaseHandler.isBypassed('AgencyLicenseTriggerBaseHandler')){
            new AgencyLicenseTriggerBaseHandler().runBaseHandler();  
        }
    }
}