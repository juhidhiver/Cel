/**************************************************************************************************
 * Class Name: NIPRAccountBatch
 * Author: Giang PHAN
 * Date: 14-Nov-2019
 * Description: Batch Program to Callouts FEIN fields on Account object.
 **************************************************************************************************/
global class NIPRAccountBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        Id recordTypeBrokerAgency = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        String query = 'SELECT Id, FEIN__c FROM Account WHERE RecordTypeId =: recordTypeBrokerAgency';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, list<Account> accountList) {
        Invsk_Callout.NIPRResponse resNIPR = new Invsk_Callout.NIPRResponse();
        API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration('NIPR_API');
        if(apiSetting == null) return ;

        HttpRequest req = Invsk_Callout.getHttpRequest(apiSetting);
        Http https = new Http();
        HttpResponse res = new HttpResponse();

        for(Account account : accountList){
            if(account.FEIN__c != null) {
                Map<String, Invsk_Callout.AgencyLookup> mapsAgencylookup = new Map<String, Invsk_Callout.AgencyLookup>();
                    mapsAgencylookup.put('agencyLookup', new Invsk_Callout.AgencyLookup(String.valueOf(account.FEIN__c)));
                    req.setBody(JSON.serialize(mapsAgencylookup));
                    res = https.send(req);
                    if(res.getStatusCode() == 200) 
                        account.NIPR_Feinn_flag__c = Invsk_Callout.isValidNIPR(res.getBody()) ? true : false;
            }
        }
        update accountList;
    }

    global void finish(Database.BatchableContext BC) {

    }
}