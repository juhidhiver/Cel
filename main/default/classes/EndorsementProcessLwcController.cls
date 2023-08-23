/**
 * @File Name          : EndorsementProcessLwcController.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 6/1/2020, 3:28:58 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/1/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public with sharing class EndorsementProcessLwcController {
    //public static final String ENDORSEMENT_PROCESS_OBJ = 'Endorsement_Process__c';
    //public static final String OPPORTUNITY_OBJ = 'Opportunity';
    /* long ly 01/06/2020 - delete
    @AuraEnabled(cacheable=true)
    public static Endorsement_Process__c getSingleEndorsementProcess() {
        return [SELECT Id, Account__c, Submission__c, Policy__c, Status__c FROM Endorsement_Process__c WITH SECURITY_ENFORCED LIMIT 1];
    }

    @AuraEnabled(cacheable=true)
    public static Endorsement_Process__c getRecordEndorsement(Id recordId) {
        String sObjNames = recordId.getSObjectType().getDescribe().getName();
        if(sObjNames == ENDORSEMENT_PROCESS_OBJ) {
            return [SELECT Id, Account__c, Submission__c, Policy__c, Status__c FROM Endorsement_Process__c WHERE Id = :recordId];
        }
        if(sObjNames == OPPORTUNITY_OBJ) {
            List<Opportunity> listOpp = [SELECT Id,(SELECT Id, Account__c, Submission__c, Policy__c, Status__c FROM Endorsement_Process__r LIMIT 1) FROM Opportunity WHERE Id = :recordId];
            return listOpp[0].Endorsement_Process__r[0];
        }
        return null;
    }*/

    //Lightning Web Components get List Policies
    @AuraEnabled(cacheable=true)
    public static List<ItemWrapper> getPolicyList(String searchKeyPol) {
        String strKeyPol = searchKeyPol + '%';
            List<ItemWrapper> resultList = new List<ItemWrapper>();
            for (Policy__c pol : [SELECT Id, Name, Policy_Status__c, Policy_Number__c, Effective_Date__c, Expiration_Date__c, Total_Premium__c
                                    /*(SELECT Id FROM Endorsement_Process__r LIMIT 1)*/ FROM Policy__c WHERE Policy_Number__c LIKE: strKeyPol])
            {
                //List<Endorsement_Process__c> lstQp = pol.Endorsement_Process__r;
                ItemWrapper item = new ItemWrapper();
                item.Id = pol.Id;
                //item.QpId = lstQp.isEmpty() ? '' : lstQp[0].Id;
                item.Name = pol.Name;
                item.Policy_Status = pol.Policy_Status__c;
                item.Policy_Number = pol.Policy_Number__c;
                item.Total_Premium = pol.Total_Premium__c;
                item.Effective_Date = pol.Effective_Date__c;
                item.Expiration_Date = pol.Expiration_Date__c;
                resultList.add(item);
            }
            return resultList;
        }    

    public class ItemWrapper{
		@AuraEnabled public String Id {get; set;}
		@AuraEnabled public String QpId {get; set;}
		@AuraEnabled public String Name {get; set;}
        @AuraEnabled public String Policy_Status {get; set;}
        @AuraEnabled public String Policy_Number {get; set;}
		@AuraEnabled public Decimal Total_Premium {get; set;}
		@AuraEnabled public Datetime Effective_Date {get; set;}
		@AuraEnabled public Datetime Expiration_Date {get; set;}
        public ItemWrapper() {
            Id = '';
			QpId = '';
            Policy_Status = '';
            Policy_Number = '';
			Total_Premium = 0;
			Effective_Date = null;
			Expiration_Date = null;
        }
    }
}