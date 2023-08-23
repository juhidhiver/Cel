/**************************************************************************************************
 * Class Name: AgencyLicenseTriggerHandler_GEN
 * Author: 
 * Date: 
 * Description: to handle General RT functions
 **************************************************************************************************/
public class AgencyLicenseTriggerHandler_GEN extends TriggerHandler{
    private List<Agency_License__c> oldDataList;
	private List<Agency_License__c> newDataList;
	private Map<Id, Agency_License__c> newDataMap;
	private Map<Id, Agency_License__c> oldDataMap;
    
    public AgencyLicenseTriggerHandler_GEN(List<Agency_License__c> newDataList, List<Agency_License__c> oldDataList, 
                                           Map<Id, Agency_License__c> newDataMap, Map<Id, Agency_License__c> oldDataMap){
                                               this.oldDataList = oldDataList;
                                               this.newDataList = newDataList;
                                               this.newDataMap = newDataMap;
                                               this.oldDataMap = oldDataMap;
                                           }

	public override void afterInsert(){
        //call NIPR Callout
        CommonAgencyLicenseUtil.updateNIPRAgencyLCByCallOut(newDataList, oldDataMap);
	}

	public override void afterUpdate(){
        //call NIPR Callout
        CommonAgencyLicenseUtil.updateNIPRAgencyLCByCallOut(newDataList, oldDataMap);
	}

}