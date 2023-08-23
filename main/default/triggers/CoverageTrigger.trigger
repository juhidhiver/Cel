/****************************************************
 * Class Name: CoverageTrigger
 * Author: Quang Pham
 * Date: 04-Oct-2019
 * Description: Trigger on object Coverage__c
 ***************************************************/
trigger CoverageTrigger on Coverage__c (before insert, before update) {
	if(!CommonUtil.isTriggerBypass('CoverageTrigger')){
		if(trigger.isBefore){
			CommonUtil.generateExternalID('Azure_ID__c', Trigger.new);
		}
	}
}