/**************************************************************************************************
 * Class Name: UpdateLicenseInfoOnPolicy
 * Author: Jai Singh
 * Date: 22-12-2021 
 * Description: Update broker details.
 **************************************************************************************************/
public with sharing class UpdateLicenseInfoOnPolicy {
    public UpdateLicenseInfoOnPolicy() {

    }

    /*************************************************
    * Method Name: getBrokerDetail
    * Author: Jai Singh
    * Date: 22-12-2021
    * Params: 
    * Return: 
    * Exceptions:
    * Description: Returning Data of Policy,Opportunity,Quote,Broker Account, Agency License and Broker License USing Wrapper Class.
    * Revision: 
     *************************************************/
    @AuraEnabled
    public static LicenseInfoWrapper getBrokerDetail(String recId ) {
        LicenseInfoWrapper liwObj = new LicenseInfoWrapper();
        system.debug(recId);
        Id recordId = recId;
        Id opportunityId = null;

        if( recordId.getSObjectType() == Schema.Quote.SObjectType ){
            Set<Id> qIdSet = new set<Id> {recId};
            list<Quote> qList = QuoteQueryUtil.fetchQuotesForQuoteIds(qIdSet, 'OpportunityId, Product_Name__c' );
            if( !qList.isEmpty()  ){
                liwObj.q = qList[0];
                opportunityId = qList[0].OpportunityId;
            }
        }else if( recordId.getSObjectType() == Schema.Policy__c.SObjectType ){
            Policy__c p = [Select Id, Product_Name__c,(Select Id from Submissions__r limit 1) from Policy__c where Id = :recordId ];
            liwObj.p = p;
            if( p.Submissions__r.size() > 0 ){
                opportunityId = p.Submissions__r[0].Id;
            }
        }
        if( opportunityId != null  ){
            
            list<Opportunity> oppList = [Select Id, AccountId, Account.BillingState, Account.BillingStateCode,RecordType.Name,
                                        ( Select Id, Broker_Contact__c, Broker_Contact__r.AccountId from Opportunity_Accounts1__r where IsPrimaryBroker__c = true )
                                        FROM Opportunity 
                                        WHERE
                                        Id = :opportunityId
                                        ];
            if( !oppList.isEmpty() && oppList[0].Opportunity_Accounts1__r.size() > 0 ){
                liwObj.opp = oppList[0];
                liwObj.ba = oppList[0].Opportunity_Accounts1__r[0];
                if( oppList[0].Opportunity_Accounts1__r[0].Broker_Contact__r.AccountId != null ){
                    list<Agency_License__c> alList = [ Select Id, Agency__c,Agency__r.Name, License_Number__c, License_State__c, License_Type__c, NIPR_License_Status__c, RecordType.Name, NPN__c,
                                                        Agency__r.BillingStreet, Agency__r.BillingCity, Agency__r.BillingState, Agency__r.BillingPostalCode
                                                        FROM Agency_License__c
                                                        where Agency__c =: oppList[0].Opportunity_Accounts1__r[0].Broker_Contact__r.AccountId AND
                                                        License_State__c = :oppList[0].Account.BillingStateCode
                                                    ];
                    liwObj.alList = alList;
                }
                list<Broker_License__c> blList = [ Select Id, Broker__c,Broker__r.Name, License_Number__c, License_State__c, License_Type__c, RecordType.Name, NPN__c, 
                                                Broker__r.Account.Name, Broker__r.Account.BillingStreet, Broker__r.Account.BillingCity, Broker__r.Account.BillingState, Broker__r.Account.BillingPostalCode
                                                FROM Broker_License__c
                                                where Broker__c =: oppList[0].Opportunity_Accounts1__r[0].Broker_Contact__c AND
                                                License_State__c = :oppList[0].Account.BillingStateCode
                                                ];
                liwObj.blList = blList;
                 
            }
        }
        system.debug(liwObj);
        return liwObj;

    }

    /*************************************************
    * Method Name: updatePolicyBLInfo
    * Author: Jai Singh
    * Date: 
    * Params: 
    * Return: 
    * Exceptions:
    * Description: Update Policy.
    * Revision: 
     *************************************************/
    @AuraEnabled
    public static void updatePolicyBLInfo(Id policyId, String blInfo){
        system.debug(blInfo);
        if(String.isNotBlank(blInfo)){
        BindingLicenseInfo blObj = (BindingLicenseInfo)JSON.deserialize(blInfo, BindingLicenseInfo.class );
        
        TriggerHandler.bypass('PolicyTriggerBaseHandler');       
        
        update new Policy__c(
            Id = policyId,
            Binding_License_Number__c = blObj.bindingLicenseNumber,
            Binding_License_Owner__c = blObj.bindingLicenseOwner,
            Binding_License_Owner_Address__c = blObj.bindingLicenseOwnerAddress ,
            Binding_License_Owner_Name__c = blObj.bindingLicenseOwnerName
            //Is_Signature_Pack_Uploaded__c = blObj.IsSignaturePackUploaded
        );   
        TriggerHandler.clearBypass('PolicyTriggerBaseHandler');
        }
    }

   public class LicenseInfoWrapper{
        @AuraEnabled
        public Opportunity opp;
        @AuraEnabled
        public Quote q;
        @AuraEnabled
        public Policy__c p;
        @AuraEnabled
        public Broker_Account__c ba;
        @AuraEnabled
        public list<Agency_License__c> alList ;
        @AuraEnabled
        public list<Broker_License__c> blList;

    }

    public class BindingLicenseInfo{
        @AuraEnabled
        public string bindingLicenseOwner;
        @AuraEnabled
        public string bindingLicenseOwnerName;                
        @AuraEnabled
        public string bindingLicenseNumber;
        @AuraEnabled
        public string bindingLicenseOwnerAddress;
        @AuraEnabled
        public Boolean IsSignaturePackUploaded;
        @AuraEnabled
        public string productName;
        @AuraEnabled
        public string oppRecordType;


    }
}