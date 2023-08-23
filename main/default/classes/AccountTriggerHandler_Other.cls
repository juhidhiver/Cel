/**************************************************************************************************
 * Class Name: AccountTriggerHandler_Other
 * Author: 
 * Date: 
 * Description: Class to keep method related to record types except Broker and Business
 * Test Class : AccountTriggerHandlerTest
 **************************************************************************************************/
public with sharing class AccountTriggerHandler_Other extends TriggerHandler{
    private List<Account> oldDataList;
    private List<Account> newDataList; 
    private Map<Id, Account> newDataMap;
    private Map<Id, Account> oldDataMap; 
    
    public AccountTriggerHandler_Other(List<Account> newDataList, List<Account> oldDataList, Map<Id, Account> newDataMap, Map<Id, Account> oldDataMap){
        this.oldDataList = oldDataList;
        this.newDataList = newDataList;
        this.newDataMap = newDataMap;
        this.oldDataMap = oldDataMap;
    } 

	public override void beforeInsert()	{
        //generate azure external id
        CommonUtil.generateExternalID('Azure_ID__c', newDataList);
        //copy billing address to mailing address
        CommonAccountUtil.copyBillingAddressToMailingAddress(newDataList); 
        //populate KYC Sanction Date
        CommonAccountUtil.insertKYCSanctionDate(newDataList);
	}

    public override void beforeUpdate(){
        //generate azure external id
        CommonUtil.generateExternalID('Azure_ID__c', newDataList);
        //copy billing address to mailing address
        CommonAccountUtil.copyBillingAddressToMailingAddress(newDataList); 
        //populate KYC Sanction Date
        CommonAccountUtil.updateKYCSanctionDate(oldDataList, newDataList); 
    }

	public override void afterInsert(){
        //add account location
        CommonAccountUtil.addLocation(newDataMap, null, 'Insert');
        //sync accounts
        CommonAccountUtil.syncAccounts(newDataMap);
    }

	public override void afterUpdate(){
        //sync accounts
        CommonAccountUtil.accountsToSync(oldDataList, newDataList);
    }
}