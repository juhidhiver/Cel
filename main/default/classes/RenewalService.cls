public with sharing class RenewalService {
    @AuraEnabled
    public static List<Renewal__c> fetchRenewalRecords(String renewalRecordTypeId){
        return RenewalServiceHandler_Common.fetchRenewalRecords(renewalRecordTypeId);
    }

    @AuraEnabled
    public static RenewalServiceHandler_Common.TabItem getListSectionSetting(String productName){
        return RenewalServiceHandler_Common.getListSectionSetting(productName);
    }

    
    @AuraEnabled(cacheable=true)
    public static RenewalServiceHandler_Common.AutoRenewalWrapper getRenewalWrappInfo (){
        return RenewalServiceHandler_Common.getRenewalWrappInfo();
    }

    @AuraEnabled
    public static  List<Renewal__c> fetchFilteredRenewalRecords (String filterWrapper,String renewalRecordTypeId){
     return  RenewalServiceHandler_Common.fetchFilteredRecords(filterWrapper,renewalRecordTypeId);
    }
 	// Vivek Raturi on 15-07-2022 For 'suppresed' and 'ready to Send' buttons.
    @AuraEnabled
    public static void updateRenewalRecords (List<String> RenewalIds , String RenewalStatus){
       RenewalServiceHandler_Common.updateRenewalRecords(RenewalIds,RenewalStatus);
    }

    @AuraEnabled
    public static void sendTestEmail (String renewalId){

        RenewalServiceHandler_Common.sendEmail(renewalId,true);
  
    }
    @AuraEnabled
    public static void manualEmailSend (String renewalId){
        RenewalServiceHandler_Common.sendEmail(renewalId,false);
    }
    @AuraEnabled
    public static List<String> getListOfBrokerContacts(String renewalId){
     
        return  RenewalServiceHandler_Common.getBrokersContacts(renewalId);

    }

    @AuraEnabled
    public static List<Contact> fetchContactsofRenewal(String renewalId){

      return RenewalServiceHandler_Common.fetchContactsofRenewal(renewalId);
  
    }
    
    @AuraEnabled
    public static void updateRoleOnContact(List<Id> removeRoleonContact, List<Id> addRoleonContact, String renewalId){
        RenewalServiceHandler_Common.updateRoleOnContact(removeRoleonContact,addRoleonContact, renewalId);
    }




}