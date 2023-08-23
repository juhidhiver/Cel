/**************************************************************************************************
 * Class Name: AccountTriggerHandler_Broker
 * Author: 
 * Date: 
 * Description: Class to keep Broker related common methods
 * Test Class : AccountTriggerHandlerTest
 **************************************************************************************************/
public with sharing class AccountTriggerHandler_Broker extends TriggerHandler{
    private List<Account> oldDataList;
    private List<Account> newDataList; 
    private Map<Id, Account> newDataMap;
    private Map<Id, Account> oldDataMap; 
    
    public AccountTriggerHandler_Broker(List<Account> newDataList, List<Account> oldDataList, Map<Id, Account> newDataMap, Map<Id, Account> oldDataMap){
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
        //check appointed by AQ
        checkAppointedbyAQ(newDataList, oldDataMap);
    }

    public override void beforeUpdate(){
         //generate azure external id
         CommonUtil.generateExternalID('Azure_ID__c', newDataList);
         //copy billing address to mailing address
         CommonAccountUtil.copyBillingAddressToMailingAddress(newDataList);
         //populate KYC Sanction Date
         CommonAccountUtil.updateKYCSanctionDate(oldDataList, newDataList);  
        //check appointed by AQ
        checkAppointedbyAQ(newDataList, oldDataMap);
    }

	public override void afterInsert(){
        //add account location
        CommonAccountUtil.addLocation(newDataMap, null, 'Insert');
        //sync accounts
        CommonAccountUtil.syncAccounts(newDataMap);
        //create broker account product
        createBrokerAccountProduct(newDataList);
    }

	public override void afterUpdate(){
        //sync accounts
        CommonAccountUtil.accountsToSync(oldDataList, newDataList);
    }

    /*************************************************
    * Method Name: checkAppointedbyAQ
    * Author: 
    * Date: 
    * Params: List<Account> newBrokerAccounts,  Map<Id, Account> oldAccsMap 
    * Return: 
    * Description: Check "Pending By Aqueous" checkbox if logged in user's profile is "Aqueous Underwriter"
     *************************************************/
    private static void checkAppointedbyAQ(List<Account> newDataList,  Map<Id, Account> oldDataMap){
        Id profileId = userinfo.getProfileId();       
        String profileName = [Select Id, Name from Profile where Id =: profileId].Name;          
        for(Account acc : newDataList){
            if(Trigger.isInsert){
                if(profileName == 'Aqueous Underwriter'){
                    acc.Pending_By_Aqueous__c = true;
                }
            }else{
                if(acc.Appointed__c == true && oldDataMap.get(acc.Id).Appointed__c != true && oldDataMap.get(acc.Id).Pending_By_Aqueous__c == true){
                       acc.Pending_By_Aqueous__c = false;
                 }
            } 
        }
    }

    /*************************************************
    * Method Name: createBrokerAccountProduct
    * Author: 
    * Date: 
    * Params: List<Account> brokerAccounts 
    * Return: 
    * Description: Insert celerity products for broker accounts
     *************************************************/
    public static void createBrokerAccountProduct(List<Account> newDataList){
        List<Account_Product__c> accountPrdList = new List<Account_Product__c>();
        
        List<Product2> prdList= [Select Id, Name, RecordType.Id, RecordType.Name,Carrier_Commission__c From Product2 WHERE
                                 IsActive = true AND RecordType.Name IN ('Celerity', 'Aqueous') and IsComboProduct__c = false];
        for(Account brokerAcc : newDataList)
        {
            for(Product2 prd : prdList){
                Account_Product__c accPrd = new Account_Product__c();
                accPrd.Account_Id__c = brokerAcc.Id;
                accPrd.Product_Id__c = prd.Id;
                accPrd.Commission_percentage__c = prd.Carrier_Commission__c; // Added by Maeran for US:54367 earlier defaulted to 15
                system.debug('accPrd--'+accPrd);
                accountPrdList.add(accPrd);
            }
        }
        if(!accountPrdList.isEmpty())
            insert accountPrdList;
    }
}