/*************************************************
* Author: Saumyak
* Date: 29-Oct-2020
* Description: Call synchronization when AccountTriggerHandler fired - Sync Account from SF to MW
*************************************************/
global class SyncAccountBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    global final Set<Id> accIds {get;set;}
    global final Map<Id,String> accMap {get;set;}
    global final String operation {get;set;}
    public static String Operation;
    global SyncAccountBatch(Map<Id, String> accMap) {
        this.operation = accMap.values()[0];
        this.accIds = accMap.keySet();
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Azure_ID__c,Name,BillingStreet,BillingCity,'+
            'BillingState,BillingStateCode,BillingPostalCode,BillingCountry,'+
            'BillingCountryCode,Billing_County__c, RecordType.DeveloperName '+
            'FROM Account WHERE Id IN:accIds'; 
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<Account> accList) {
        String orgName = Label.OrgName;
        
        String accRevSyncJson = '{ "Account":' + JSON.serialize(accList) +',"OrgName":' +JSON.serialize(orgName) +',"Operation":' +JSON.serialize(operation)+'}';
        System.debug('123 jsonString--'+accRevSyncJson);
        
        API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration('Account_Sync');
        if(apiSetting == null) return;
        
        try{
            HttpRequest req = Invsk_Callout.getHttpRequest(apiSetting);
            system.debug('123 Request--'+req);
            
            HttpResponse res = new HttpResponse();
            Http https = new Http();            
            req.setBody(accRevSyncJson); 
            res = https.send(req); 
            system.debug('AccountSync response--'+res); 
            if(res.getStatusCode() == 200){
                system.debug('123 Response--'+res); 
            }
            
            ApiUtil.logAPICall(req, res, 'AccountReverseSync_Callout', 'sendAccocuntDetails', apiSetting.HeaderParams__c , 'Outbound');
        }
        catch (Exception ex){
            System.debug(ex.getMessage());            
        }
        
    }
    public void finish(Database.BatchableContext info) {}    
    
}