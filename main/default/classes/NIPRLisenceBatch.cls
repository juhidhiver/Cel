/**************************************************************************************************
 * Class Name: NIPRLisenceBatch
 * Author: Giang PHAN
 * Date: 14-Nov-2019
 * Description: Batch Program to Callouts LicenseNumber.
 **************************************************************************************************/
global class NIPRLisenceBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, License_Number__c, License_State__c,License_Type__c, NPN__c FROM Broker_License__c';
        return Database.getQueryLocator(strQuery);
    }

    global void execute(Database.BatchableContext BC, list<Broker_License__c> listBrokerLCId) {
        Invsk_Callout.NIPRResponse resNIPR = new Invsk_Callout.NIPRResponse();
        API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration('NIPR_API');
        if(apiSetting == null) return ;

        List<Broker_License__c> updatedBrokerLicenses = new List<Broker_License__c>();

        for(Broker_License__c brokerLC : listBrokerLCId){

            if(String.isNotBlank(brokerLC.License_Number__c) && String.isNotBlank(brokerLC.License_State__c)){
                Map<String, Invsk_Callout.LicenseLookup> mapsLicenselookup = new Map<String, Invsk_Callout.LicenseLookup>();
                mapsLicenselookup.put('licenseLookup', new Invsk_Callout.LicenseLookup(brokerLC.License_Number__c,brokerLC.License_State__c)); 
                
                Http httpVar = new Http();  
                HttpRequest req = Invsk_Callout.getHttpRequest(apiSetting);
                HttpResponse res = new HttpResponse();
                
                //Send Resquest Callouts
                req.setBody(JSON.serialize(mapsLicenselookup));                            
                res = httpVar.send(req);
                
                //Response Callouts 
                Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    
                if(resultMap.containsKey('isValidBrokerLicense') && (Boolean)resultMap.get('isValidBrokerLicense')){
                    String numberNPN = (String)resultMap.get('npn');                          
                    if(String.isNotBlank(numberNPN)) {
                        brokerLC.NPN__c = numberNPN;
                        brokerLC.NIPR_License_flag__c = true;
                        updatedBrokerLicenses.add(brokerLC); 
                        }
                    }                       
                }
                //Update Broker License NPN
                if(!updatedBrokerLicenses.isEmpty()) upsert updatedBrokerLicenses;
            }
    }

    global void finish(Database.BatchableContext BC) {
        
    }
}