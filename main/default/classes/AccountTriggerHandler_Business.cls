/**************************************************************************************************
 * Class Name: AccountTriggerHandler_Business
 * Author: 
 * Date: 
 * Description: Class to keep Business related common methods
 * Test Class : AccountTriggerHandlerTest
 **************************************************************************************************/
public with sharing class AccountTriggerHandler_Business extends TriggerHandler{
    private List<Account> oldDataList;
    private List<Account> newDataList; 
    private Map<Id, Account> newDataMap;
    private Map<Id, Account> oldDataMap; 
    
    public AccountTriggerHandler_Business(List<Account> newDataList, List<Account> oldDataList, Map<Id, Account> newDataMap, Map<Id, Account> oldDataMap){
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

    //    CommonAccountUtil.onUpdateAccName(oldDataList,newDataList); // Added Mary


    }

	public override void afterInsert(){
        //add account location
        CommonAccountUtil.addLocation(newDataMap, null, 'Insert');
        //sync accounts
        CommonAccountUtil.syncAccounts(newDataMap);
        //calls a sanction search check on account Insert
        
        /******* New Lines for 56447 *****/
        
        
        List<Account> accList = new List<Account>();
        
        for(Account acc : newDataList){
            if(acc.IsSyncSanctionSearch__c==false){
              accList.add(acc);  
            }
        }
        
        if(accList.size()>0){
         CommonAccountUtil.validateSanctionCheckOnInsert(accList, false);
        }
       // CommonAccountUtil.validateSanctionCheckOnInsert(newDataList, false);
    }

	public override void afterUpdate(){
        //sync accounts
        CommonAccountUtil.accountsToSync(oldDataList, newDataList);
        //CommonAccountUtil.onUpdateAccName(oldDataList,newDataList); // Added Mary
        //calls a sanction search check on account Update
        CommonAccountUtil.validateSanctionCheckOnUpdate(oldDataList,newDataList);
        
        /***** for CD-167 ******/
        CommonAccountUtil.generatePolicyDocuments(oldDataList,newDataList);
        CommonAccountUtil.SanctionNotificationOnRequestingClearance(oldDataMap,newDataList);
        CommonAccountUtil.declineMainSubmission(newDataList,oldDataList);

       /**************************** Update Renewals related to Account *********************/
        CommonAccountUtil.updateRenewalRecord(newDataList,oldDataMap);

    }
}