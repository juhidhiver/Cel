/**************************************************************************************************
* Class Name: ContactTriggerHandler_Broker
* Author: 
* Date: 
* Description: Class to keep Broker related common methods
* Test Class : ContactTriggerHandlerTest
**************************************************************************************************/
public with sharing class ContactTriggerHandler_Broker extends TriggerHandler{
    private List<Contact> oldDataList;
    private List<Contact> newDataList; 
    private Map<Id, Contact> newDataMap;
    private Map<Id, Contact> oldDataMap; 
    
    public ContactTriggerHandler_Broker(List<Contact> newDataList, List<Contact> oldDataList, Map<Id, Contact> newDataMap, Map<Id, Contact> oldDataMap){
        this.oldDataList = oldDataList;
        this.newDataList = newDataList;
        this.newDataMap = newDataMap;
        this.oldDataMap = oldDataMap;
    }
    
    public override void beforeInsert()	{
        //generate external id (Azure)
        CommonUtil.generateExternalID('Azure_ID__c', newDataList);
    }

    public override void afterInsert(){
        //Update quote with broker's mail address
        CommonContactUtil.updateQuoteWithBrokerEmail(newDataMap);

        //#59035: AQ Auto Renewals function to update No Recipients on Custom Renewal Records
        updateNoRecipientOnAutoRenewals();
    }
    
    public override void beforeUpdate(){
        //generate external id (Azure)
        CommonUtil.generateExternalID('Azure_ID__c', newDataList);

        //#59035: AQ Auto Renewals function to update No Recipients on Custom Renewal Records
        updateNoRecipientOnAutoRenewals();
    }
    
    public override void afterUpdate(){
        //Check if contact email is changing
        CommonContactUtil.emailChangeContactHandler(newDataList, oldDataMap);

        //#59035: AQ Auto Renewals function to update No Recipients on Custom Renewal Records
        updateNoRecipientOnAutoRenewals();
    }

    public override void beforeDelete(){
        //#59035: AQ Auto Renewals function to update No Recipients on Custom Renewal Records
        updateNoRecipientOnAutoRenewals();
    }

    public override void afterUndelete(){
        //#59035: AQ Auto Renewals function to update No Recipients on Custom Renewal Records
        updateNoRecipientOnAutoRenewals();
    }

    //#59035: AQ Auto Renewals function to update No Recipients on Custom Renewal Records
    public static void updateNoRecipientOnAutoRenewals(){
        Set<Id> setOfAccWithRenewalContactAdded = new Set<Id>();
        Set<Id> setOfContWithRoleRemoved = new Set<Id>();
        Map<Id, List<Contact>> mapOfAccVsContWithRenewalRoleRemoved = new Map<Id, List<Contact>>();

        if(Trigger.isDelete){
            for(Contact objOldCon: (List<Contact>)Trigger.Old){
                setOfContWithRoleRemoved.add(objOldCon.Id);
                if(!mapOfAccVsContWithRenewalRoleRemoved.isEmpty() && mapOfAccVsContWithRenewalRoleRemoved.containsKey(objOldCon.AccountId)){
                    mapOfAccVsContWithRenewalRoleRemoved.get(objOldCon.AccountId).add(objOldCon);
                }
                else{
                    mapOfAccVsContWithRenewalRoleRemoved.put(objOldCon.AccountId, new List<Contact>{objOldCon});
                }
            }
        }
        else{
            for(Contact objNewCon: (List<Contact>)Trigger.New){
                if(Trigger.isInsert || Trigger.isUndelete){
                    if(objNewCon.Role__c == 'Renewals'){
                        setOfAccWithRenewalContactAdded.add(objNewCon.AccountId);
                    }
                }
                else if(Trigger.isUpdate){
                    Contact oldContact = (Contact)Trigger.oldMap.get(objNewCon.Id);
                    if(oldContact.Role__c != objNewCon.Role__c){
                        if(Trigger.isAfter && oldContact.Role__c != 'Renewals' && objNewCon.Role__c == 'Renewals'){
                            setOfAccWithRenewalContactAdded.add(objNewCon.AccountId);
                        }
                        else if(Trigger.isBefore && oldContact.Role__c == 'Renewals' && objNewCon.Role__c != 'Renewals'){
                            setOfContWithRoleRemoved.add(objNewCon.Id);
                            if(!mapOfAccVsContWithRenewalRoleRemoved.isEmpty() && mapOfAccVsContWithRenewalRoleRemoved.containsKey(objNewCon.AccountId)){
                                mapOfAccVsContWithRenewalRoleRemoved.get(objNewCon.AccountId).add(objNewCon);
                            }
                            else{
                                mapOfAccVsContWithRenewalRoleRemoved.put(objNewCon.AccountId, new List<Contact>{objNewCon});
                            }
                        }
                    }
                }
            }
        }

        Map<Id, List<Contact>> mapOfAccVsRemovedRenewalContact = new Map<Id, List<Contact>>();
        if(!mapOfAccVsContWithRenewalRoleRemoved.isEmpty()){
            List<Account> lstAccount = [SELECT Id, (SELECT Id FROM Contacts WHERE Role__c = 'Renewals' AND Id NOT IN: setOfContWithRoleRemoved)
                                        FROM Account
                                        WHERE Id IN: mapOfAccVsContWithRenewalRoleRemoved.keySet()];
            for(Account objAcc: lstAccount){
                if(objAcc.Contacts.isEmpty() && objAcc.Contacts.size() == 0){
                    if(mapOfAccVsContWithRenewalRoleRemoved.containsKey(objAcc.Id)){
                        mapOfAccVsRemovedRenewalContact.put(objAcc.Id, mapOfAccVsContWithRenewalRoleRemoved.get(objAcc.Id));
                    }
                }
            }
        }

        if(!mapOfAccVsRemovedRenewalContact.isEmpty() || !setOfAccWithRenewalContactAdded.isEmpty()){
            Set<Id> setOfAccountIdsToFetchAutoRenewals = new Set<Id>();
            if(!mapOfAccVsRemovedRenewalContact.isEmpty()){
                setOfAccountIdsToFetchAutoRenewals.addAll(mapOfAccVsRemovedRenewalContact.keySet());
            }
            if(!setOfAccWithRenewalContactAdded.isEmpty()){
                setOfAccountIdsToFetchAutoRenewals.addAll(setOfAccWithRenewalContactAdded);
            }
            if(!setOfAccountIdsToFetchAutoRenewals.isEmpty()){
                List<Renewal__c> lstOpenRenewals = [SELECT Id, No_Recipients__c, Broker__r.Broker_Contact__r.AccountId
                                                FROM Renewal__c
                                                WHERE Broker__r.Broker_Contact__r.AccountId IN: setOfAccountIdsToFetchAutoRenewals
                                                AND Status__c IN ('Suppressed', 'Ready to Send')];
                Set<Id> setOfAccountIdsToCompare = new Set<Id>();
                if(!lstOpenRenewals.isEmpty()){
                    for(Renewal__c objRen: lstOpenRenewals){
                        setOfAccountIdsToCompare.add(objRen.Broker__r.Broker_Contact__r.AccountId);
                    }

                    if(!mapOfAccVsRemovedRenewalContact.isEmpty()){
                        for(Id objAccId: mapOfAccVsRemovedRenewalContact.keySet()){
                            if(setOfAccountIdsToCompare.contains(objAccId)){
                                for(Contact objCon: mapOfAccVsRemovedRenewalContact.get(objAccId)){
                                    if(Trigger.isDelete){
                                        objCon.addError(Label.AQ_AutoRenewalsContactDeleteError);
                                    }
                                    else if(Trigger.isUpdate){
                                        objCon.addError(Label.AQ_AutoRenewalsContactUpdateError);
                                    }
                                }
                            }
                        }
                    }

                    List<Renewal__c> lstRenewalsToUpdate = new List<Renewal__c>();
                    if(!setOfAccWithRenewalContactAdded.isEmpty()){
                        for(Renewal__c objRen: lstOpenRenewals){
                            if(setOfAccWithRenewalContactAdded.contains(objRen.Broker__r.Broker_Contact__r.AccountId)
                                && objRen.No_Recipients__c == true){
                                    objRen.No_Recipients__c = false;
                                    lstRenewalsToUpdate.add(objRen);
                            }
                        }
                    }

                    if(!lstRenewalsToUpdate.isEmpty()){
                        update lstRenewalsToUpdate;
                    }
                }
            }
        }
    }
}