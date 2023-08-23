/*************************************************
* Class Name: Invsk_Callout
* Author: 
* Created: 
* Description: Contains callouts to external services
* Revision: 
*/
public with sharing class Invsk_Callout {
    /*************************************************
    * Method Name: getNIPR
    * Author: 
    * Description : NIPR API request FEIN for Account Business
    * Date: 
    * Params: String fein
    *************************************************/
    public static String getNIPR(String fein)
    {
        try{
            API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration('NIPR_API');
            if(apiSetting == null) return null;

            String baseUri = apiSetting.Base_Url__c + apiSetting.Endpoint__c;

            Http https = new Http();
            HttpRequest req = getHttpRequest(apiSetting);

            Map<String, AgencyLookup> mapsAgencylookup = new Map<String, AgencyLookup>();
            mapsAgencylookup.put('agencyLookup', new AgencyLookup(fein));
            req.setBody(JSON.serialize(mapsAgencylookup));
            HttpResponse res = new HttpResponse();
            res = https.send(req);

            if (res.getStatusCode() == 200) {
                // log API Call
                ApiUtil.logAPICall(req,res,'NIPR Callout','Invsk_Callout.getNIPR', apiSetting.HeaderParams__c, 'Outbound');
                return res.getBody();
            }

            String errMsg = '';
            Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if (resultMap.containsKey('error')) {
                Map<String, Object> errorMap = (Map<String, Object>) resultMap.get('error');
                errMsg = (String) errorMap.get('message');
            } else if (resultMap.containsKey('Message')) {
                errMsg = (String) resultMap.get('Message');
            }

            // log API Call
            ApiUtil.logAPICall(req,res,'NIPR Callout','Invsk_Callout.getNIPR', apiSetting.HeaderParams__c, 'Outbound');
            return errMsg;
        } catch(Exception ex) {  
            system.debug('ex:' + ex.getStackTraceString() + ' line:' + ex.getLineNumber());    
            return null;
        }
    }

    //For Account Trigger  and Broker_License__c Trigger
    @future(callout=true)
    public static void getNIPRCallOut(List<Id> listId)
    {     
        NIPRResponse resNIPR = new NIPRResponse();
        API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration('NIPR_API');
        if(apiSetting == null) return ;

        HttpRequest req = getHttpRequest(apiSetting);
        Http https = new Http();
        HttpResponse res = new HttpResponse();
        try {
            if( listId[0].getSObjectType().getDescribe().getName() == 'Broker_License__c') //Account
            {
                List<Broker_License__c> updatedBrokerLicenses = new List<Broker_License__c>();
                for(Broker_License__c brokerLC : [SELECT Id,License_Number__c, License_State__c,License_Type__c, NPN__c 
                                                    FROM Broker_License__c WHERE Id IN :listId ]) 
                {
                    if(String.isNotBlank(brokerLC.License_Number__c) && String.isNotBlank(brokerLC.License_State__c)) 
                    {
                        Map<String, LicenseLookup> mapsLicenselookup = new Map<String, LicenseLookup>();
                        mapsLicenselookup.put('licenseLookup', new LicenseLookup(brokerLC.License_Number__c,brokerLC.License_State__c,'1'));
                        req.setBody(JSON.serialize(mapsLicenselookup));
                        
                        res = https.send(req);   
                 
                        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    
                        if(resultMap.containsKey('isValidBrokerLicense') && (Boolean)resultMap.get('isValidBrokerLicense'))
                        {
                            String numberNPN = (String)resultMap.get('npn');      
                            system.debug('numberNPN@@@@@@@' + numberNPN);                     
                            if(String.isNotBlank(numberNPN)) {
                                brokerLC.NPN__c = numberNPN;
                                brokerLC.NIPR_License_flag__c = true;
                                updatedBrokerLicenses.add(brokerLC);
                            }
                        }
                        
                    }
                    //update broker license
                    if(!updatedBrokerLicenses.isEmpty()) upsert updatedBrokerLicenses;
                }
            } else if(listId[0].getSObjectType().getDescribe().getName() == 'Agency_License__c'){
                List<Agency_License__c> updatedAgencyLicenses = new List<Agency_License__c>();
                List<Agency_License__c> agencyLCList = [SELECT Id,License_Number__c, License_State__c,License_Type__c, NPN__c, NIPR_License_Status__c 
                                                        FROM Agency_License__c WHERE Id =:listId ORDER By LastModifiedDate DESC];
                system.debug('AGENCY LIST' + agencyLCList);                                        
                if(agencyLCList.isEmpty())  return;
                for(Agency_License__c agencyLic : agencyLCList)
                {
                    if(String.isNotBlank(agencyLic.License_Number__c) && String.isNotBlank(agencyLic.License_State__c)) 
                    {
                        Map<String, LicenseLookup> mapsLicenselookup = new Map<String, LicenseLookup>();
                        mapsLicenselookup.put('licenseLookup', new LicenseLookup(agencyLic.License_Number__c,agencyLic.License_State__c, '2'));   
                        req.setBody(JSON.serialize(mapsLicenselookup));
                      system.debug('else res  --'+req);
                        res = https.send(req);
                        system.debug('else res'+res);
                        if (res.getStatusCode() == 200) 
                        {
                            Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                            if(isValidNIPR(res.getBody())){
                                agencyLic.NIPR_License_Status__c = 'Pass';
                                agencyLic.NPN__c = (String)resultMap.get('npn');
                            }else {
                                agencyLic.NIPR_License_Status__c = 'Fail';
                            }
                            
                            
                            updatedAgencyLicenses.add(agencyLic);
                            
                            break;
                        }
                    }
                  }
                  if(!updatedAgencyLicenses.isEmpty()) upsert updatedAgencyLicenses;
            }
             // log API Call
             ApiUtil.logAPICall(req,res,'NIPR Callout','Invsk_Callout.getNIPRCallOut', apiSetting.HeaderParams__c, 'Outbound');
        }catch(Exception ex) {  
             ApiUtil.logAPICall(req,res,'NIPR Callout','Invsk_Callout.getNIPRCallOut', apiSetting.HeaderParams__c, 'Outbound');   
        }
        return ;
    }


    /*************************************************
    * Author: Giang Phan
    * Date: 
    * Params: Quote Id
    * Description: Check NIPR FEIN Account & Broker License for Binding Quote Process
    * Revision: 
    *************************************************/
    public static NIPRResponse getNIPRCallOut(Quote q, List<API_Log__c> apiLogList)
    {     
        NIPRResponse resNIPR = new NIPRResponse();
        List<Broker_Account__c> brokeracc = [SELECT Id, Broker_Contact__c, Broker_Contact__r.AccountId 
                                                FROM Broker_Account__c 
                                                WHERE Opportunity__c =: q.OpportunityId 
                                                AND IsPrimaryBroker__c = true LIMIT 1];

        String stateCode = q.Opportunity.Account.BillingStateCode;
        if(brokeracc.isEmpty())
        {
            resNIPR.msgError = 'There is no Broker Agency.';
            resNIPR.isStop = true;
            return resNIPR;
        }
        // check sate code null
        if(String.isBlank(stateCode)){
            resNIPR.isStop = true;
            return resNIPR;
        }

        checkNIPRCallOut(brokeracc[0].Broker_Contact__c, resNIPR, apiLogList, stateCode);
        if(resNIPR.isStop){
            //insert apiLogs;
            return resNIPR;
        }
        //End check Broker License NIPR

        //insert apiLogs;
        return resNIPR;
    }

    /*************************************************
    * Author: Giang Phan
    * Date: 
    * Params: Quote Id
    * Description: Callout NIPR FEIN Account & Broker License for Binding Quote Process
    * Revision: 
    *************************************************/
    public static void checkNIPRCallOut(Id objId, NIPRResponse niprRes, List<API_Log__c> apiLogList,String stateCode)
    {  

        API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration('NIPR_API');
        if(apiSetting == null){
            niprRes.msgError = 'There is no Configuration for NIPR Call out.';
            niprRes.isStop = true;
            return ;
        }
        HttpRequest req = getHttpRequest(apiSetting);
        Http https = new Http();
        HttpResponse res = new HttpResponse();
        String currentSObjName = objId.getSObjectType().getDescribe().getName();
        system.debug('OBJECT NAME: ' + currentSObjName);
        try{
            if(currentSObjName=='Contact')
            {
                niprRes.isStop = true;
                List<Id> listBrokerLC = new List<Id>();
                List<Broker_License__c> brokerLCList = [SELECT Id,License_Number__c, License_State__c,License_Type__c, NPN__c
                                                        FROM Broker_License__c WHERE Broker__c =:objId AND License_State__c =: stateCode ORDER By LastModifiedDate DESC];
                                                        
                if(brokerLCList.isEmpty()){
                    niprRes.msgError = Label.Error_NoSurplusLinesLicense;
                    niprRes.isStop = true;
                    return;
                }   

                system.debug('@@@@@brokerLCList' + brokerLCList);
                for(Broker_License__c brokerLic : brokerLCList)
                {
                    if(String.isNotBlank(brokerLic.License_Number__c) && String.isNotBlank(brokerLic.License_State__c)) 
                    {
                        Map<String, LicenseLookup> mapsLicenselookup = new Map<String, LicenseLookup>();
                        mapsLicenselookup.put('licenseLookup', new LicenseLookup(brokerLic.License_Number__c,brokerLic.License_State__c, '1'));   
                        req.setBody(JSON.serialize(mapsLicenselookup));
                        res = https.send(req);
                        system.debug('res -- '+res);
                        if (res.getStatusCode() == 200 && isValidNIPR(res.getBody())) 
                        {
                            Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                            brokerLic.NIPR_License_flag__c = true;
                            brokerLic.NPN__c = (String)resultMap.get('npn'); 
                            
                            niprRes.brokerLicenseUpdate = brokerLic;
                            niprRes.isStop = false;
                            niprRes.licenseNumber = brokerLic.License_Number__c;
                            break;
                        }
                    }
                    //invalid license
                    niprRes.msgError = ('No valid Broker License exists');
                    niprRes.isStop = true;
                }
            }

            // log API Call
            apiLogList.add(ApiUtil.createLogAPICall(req, res, 'NIPR Callout', 
                                                    'Invsk_Callout.checkNIPRCallOut', 
                                                    apiSetting.HeaderParams__c, 'Outbound'));
       }catch(Exception ex) {  
            system.debug('@@@@APILOG33333');
            apiLogList.add(ApiUtil.createLogAPICall(req, res, 'NIPR Callout', 
                                                    'Invsk_Callout.checkNIPRCallOut', 
                                                    apiSetting.HeaderParams__c, 'Outbound'));   
       }
    
    }

    /*************************************************
    * Author: Giang Phan
    * Date: 06-Aug-2020
    * Params: Quote Id
    * Description: Check NIPR Agency Broker for Binding Quote Process
    * Revision: 
    *************************************************/
    public static NIPRResponseAgency getNIPRCallOutAgency(Quote q, List<API_Log__c> apiLogList)
    {     
        system.debug('niprcallout agency');
        NIPRResponseAgency resNIPRAgency = new NIPRResponseAgency();
        List<Broker_Account__c> brokeracc = [SELECT Id, Broker_Contact__c, Broker_Contact__r.AccountId 
                                                FROM Broker_Account__c 
                                                WHERE Opportunity__c =: q.OpportunityId 
                                                AND IsPrimaryBroker__c = true LIMIT 1];

        List<Agency_License__c> agencyAcc = new List<Agency_License__c>();

        String stateCode = q.Opportunity.Account.BillingStateCode;
        // check sate code null
        if(String.isBlank(stateCode)){
            resNIPRAgency.isStop = true;
            return resNIPRAgency;
        }

        if(brokeracc.isEmpty()){
            resNIPRAgency.msgError = 'There is no Broker.';
            resNIPRAgency.isStop = true;
            return resNIPRAgency;
        } else if(brokeracc[0].Broker_Contact__c == null){
            resNIPRAgency.msgError = 'There is no Broker Contact.';
            resNIPRAgency.isStop = true;
            return resNIPRAgency;
            
        } else if(brokeracc[0].Broker_Contact__r.AccountId == null){
            resNIPRAgency.msgError = 'There is no Agency.';
            resNIPRAgency.isStop = true;
            return resNIPRAgency;
        } else {
            agencyAcc= [SELECT Id FROM Agency_License__c WHERE Agency__c =: brokeracc[0].Broker_Contact__r.AccountId
                       AND License_State__c =: stateCode];
            if(agencyAcc.isEmpty())
            {
                resNIPRAgency.msgError = 'There is no Agency License.';
                resNIPRAgency.isStop = true;
                return resNIPRAgency;
            }
        }
        
        
        //Check Agency License NIPR
        checkNIPRCallOutAgency(agencyAcc[0].Id, resNIPRAgency, apiLogList, stateCode);
        if(resNIPRAgency.isStop){
            //insert apiLogs;
            return resNIPRAgency;
        }
        //End Check Agency License NIPR

        //insert apiLogs;
               system.debug('niprcallout agency return'+resNIPRAgency);

        return resNIPRAgency;
    }

    /*************************************************
    * Author: Giang Phan
    * Date: 06-Aug-2020
    * Params: Object Id, NIPRResponse, API Log
    * Description: Callout NIPR Agency Broker for Binding Quote Process
    * Revision: 
    *************************************************/
    public static void checkNIPRCallOutAgency(Id objId, NIPRResponseAgency niprRes, List<API_Log__c> apiLogList,String stateCode)
    {  
        system.debug('This is DEBUG AGENCY');
        API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration('NIPR_API');
        if(apiSetting == null){
            niprRes.msgError = 'There is no Configuration for NIPR Call out.';
            niprRes.isStop = true;
            return ;
        }
        HttpRequest req = getHttpRequest(apiSetting);
        Http https = new Http();
        HttpResponse res = new HttpResponse();
        String currentSObjName = objId.getSObjectType().getDescribe().getName();
        system.debug('OBJECT NAME: ' + currentSObjName);
        try{
            if(currentSObjName=='Agency_License__c') //Agency_License__c
            { 
                niprRes.isStop = true;
                List<Id> listAgencyLC = new List<Id>();
                List<Agency_License__c> agencyLCList = [SELECT Id,License_Number__c, License_State__c,License_Type__c, NPN__c
                                                        FROM Agency_License__c WHERE Id =:objId AND License_State__c =: stateCode ORDER By LastModifiedDate DESC];
                system.debug('AGENCY LIST' + agencyLCList);                                        
                if(agencyLCList.isEmpty()){
                    return;
                }
                
                for(Agency_License__c agencyLic : agencyLCList)
                {
                    if(String.isNotBlank(agencyLic.License_Number__c) && String.isNotBlank(agencyLic.License_State__c)) 
                    {
                        Map<String, LicenseLookup> mapsLicenselookup = new Map<String, LicenseLookup>();
                        mapsLicenselookup.put('licenseLookup', new LicenseLookup(agencyLic.License_Number__c,agencyLic.License_State__c, '2'));   
                        req.setBody(JSON.serialize(mapsLicenselookup));
                        res = https.send(req);
                        if (res.getStatusCode() == 200 && isValidNIPR(res.getBody())) 
                        {
                            Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                            agencyLic.NIPR_License_Status__c = 'Pass';
                            agencyLic.NPN__c = (String)resultMap.get('npn'); 
                            
                            niprRes.agencyLicenseUpdate = agencyLic;
                            niprRes.isStop = false;
                            niprRes.licenseNumber = agencyLic.License_Number__c;
                            break;
                        }
                    }
                    //invalid license
                        niprRes.msgError = ('No valid Agency License exists');
                        niprRes.isStop = true;
                }
            }
            // log API Call
            apiLogList.add(ApiUtil.createLogAPICall(req, res, 'NIPR Callout', 
                                                    'Invsk_Callout.checkNIPRCallOut', 
                                                    apiSetting.HeaderParams__c, 'Outbound'));
       }catch(Exception ex) {
            system.debug('@@@@APILOG333334444');
            apiLogList.add(ApiUtil.createLogAPICall(req, res, 'NIPR Callout', 
                                                    'Invsk_Callout.checkNIPRCallOut', 
                                                    apiSetting.HeaderParams__c, 'Outbound')); 
       }
    
    }

    
    public static boolean isValidNIPR(String response) {
        try {
            Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(response);
            if(resultMap.containsKey('isValidAgencyFEIN')) {
                boolean isSuccess = (boolean)resultMap.get('isValidAgencyFEIN');
                return isSuccess;
            }

            if(resultMap.containsKey('isValidBrokerLicense')) {
                boolean isSuccess = (boolean)resultMap.get('isValidBrokerLicense');
                return isSuccess;
            }
        } catch(Exception ex) {
            return false;
        }

        return false;
    }


    public class NIPRResponse {
        public String msgError  {get; set;} 
        public Boolean isStop   {get; set;} 
        public String numberNPN {get; set;}
        public String state     {get;set;}
        public String licenseNumber {get;set;}
        public Broker_License__c brokerLicenseUpdate {get; set;}
        public Account accountUpdate {get; set;}
        public NIPRResponse(){
            msgError = '';
            isStop = false;
            numberNPN = '';
            state = '';
            licenseNumber = '';
            brokerLicenseUpdate = null;
            accountUpdate = null;
        }
    }

    public class NIPRResponseAgency {
        public String msgError  {get; set;} 
        public Boolean isStop   {get; set;} 
        public String numberNPN {get; set;}
        public String state     {get;set;}
        public String licenseNumber {get;set;}
        public Agency_License__c agencyLicenseUpdate {get; set;}
        public NIPRResponseAgency(){
            msgError = '';
            isStop = false;
            numberNPN = '';
            state = '';
            licenseNumber = '';
            agencyLicenseUpdate = null;
        }
    }

    public class AgencyLookup {
        public String fein {get;set;}
        public AgencyLookup(){
            this.fein = '';
        }
        public AgencyLookup(String fein){
            this.fein = fein;
        }
    }

    public class LicenseLookup {        
        public String licenseId {get;set;}
        public String producertype {get;set;}
        public  String state {get;set;}
        
        public LicenseLookup(String licenseId, String state, String producertype){
            this.licenseId = licenseId;
            this.state = state;
            this.producertype = producertype;
        }
    }
    //END NIPR API

    //////////////////////////////////////RATE/////////////////////////////////////////////
    public static Quote getRatedQuote(Quote updatedQuote) {
        API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration('Rate_Quote');
        if(apiSetting == null) return updatedQuote;

        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        try {
            req = getHttpRequest(apiSetting, updatedQuote);
            Http h = new Http();
            res = h.send(req);
            system.debug('req='+req);
            system.debug('getStatusCode='+res.getStatusCode());
            if (res.getStatusCode() == 200) {
                updatedQuote.Status = 'Rated';
                updatedQuote.Declined_Reason__c = null;
            //////////........Add more action here.............//////////////////////

            } else {
                String errMsg = '';
                Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                if (resultMap.containsKey('error')) {
                    Map<String, Object> errorMap = (Map<String, Object>) resultMap.get('error');
                    errMsg = (String) errorMap.get('message');
                }else if (resultMap.containsKey('message')) errMsg = (String) resultMap.get('message');
                
                updatedQuote.Status = 'In Progress';
                updatedQuote.Rating_Status__c = 'System Error';
                updatedQuote.Declined_Reason__c = errMsg;
            }

            // log API Call
            ApiUtil.logAPICall(req,res,'RatingAPI Callout','REST_Rating.getRatedQuote', apiSetting.HeaderParams__c, 'Outbound');        
            return updatedQuote;

        } catch (Exception ex) {
            updatedQuote.Status = 'In Progress';
            updatedQuote.Rating_Status__c = 'System Error';
            updatedQuote.Declined_Reason__c = CommonUtil.getExceptionMessage(ex);
            // log API Call
            ApiUtil.logAPICall(req,res,'RatingAPI Callout','REST_Rating.getRatedQuote', apiSetting.HeaderParams__c, 'Outbound');            
            return updatedQuote;
        }
    }

    /*************************************************
    * Method Name: checkBoundPending
    * Author: 
    * Description : Call out to update status Bound for Quote
    * Date: 07-Nov-2019
    * Params: Quote currentQuote
    * Return: Bool isBoundPending
    * Exceptions:
    * Revision: 
    **************************************************/
    public static Boolean checkBoundPending(Quote currentQuote, 
                                            List<BindServiceHandler_Common.InComingRequestOFAC> listInComingRequestOFAC,
                                            Map<String, Account> mapUpdateAccount) 
    {
        Boolean isBoundPending = false;
     
        List<Account> accountUpdates = new List<Account>();// List of Account Update
        List<Task> newTasks = new List<Task>();// List of Task Insert
        List<Id> userGroupOFACs = CommonUtil.getUserIdInGroupByGroupName('OFAC Group');// Get Users for Group OFAC
        List<API_Log__c> apiLogList = new List<API_Log__c>();
        Set<String> duplicateIdAcc = new Set<String>();
        
        API_Configuration__mdt apiSettingOFAC = CommonUtil.getAPIconfiguration('API_OFAC');// Get API OFAC Custom Metadata
        HttpRequest reqOFAC = getHttpRequest(apiSettingOFAC, currentQuote);

        for (BindServiceHandler_Common.InComingRequestOFAC inComingRequestOFAC : listInComingRequestOFAC) {
            String bodyRequest = null;            
            if(inComingRequestOFAC.isAccount) {
                // For Account
                bodyRequest = '{' +  '"Name":"' + inComingRequestOFAC.name + 
                            '","Address1":"'    + inComingRequestOFAC.street + 
                            '","City":"'        + inComingRequestOFAC.city + 
                            '","State":"'       + inComingRequestOFAC.state + 
                            '","postalCode":"'  + inComingRequestOFAC.postalCode + 
                            '","Country":"'     + inComingRequestOFAC.countryCode + 
                            '","county":"'      + inComingRequestOFAC.county +
                            '","FEINNumber":"'  + inComingRequestOFAC.FEINNumber +
                    '"}';
            }else {
                // // For Contact
                bodyRequest = '{' +  '"Name":"'         + inComingRequestOFAC.name + 
                                    '","Address1":"'    + inComingRequestOFAC.street + 
                                    '","City":"'        + inComingRequestOFAC.city + 
                                    '","State":"'       + inComingRequestOFAC.state + 
                                    '","postalCode":"'  + inComingRequestOFAC.postalCode + 
                                    '","Country":"'     + inComingRequestOFAC.countryCode + 
                                    '","county":"'      + inComingRequestOFAC.county +
                                    '","LicenseId":"'   + inComingRequestOFAC.LicenseId +
                            '"}';                
            }            
          
            reqOFAC.setBody(bodyRequest);
            HttpResponse resOFAC = new HttpResponse();
            Http httpOFAC = new Http();
            try{                
                resOFAC = httpOFAC.send(reqOFAC); 
                
                if (resOFAC.getStatusCode() == 200) {
                    Map<String, Object> resOFACBody = (Map<String, Object>) JSON.deserializeUntyped(resOFAC.getBody());
                    
                    String strValidOFAC = (String) resOFACBody.get('isValidOFAC');
                    Boolean validOFACFlg = Boolean.valueOf(strValidOFAC); 
                   
                    // validOFACFlg is true then update Account and create a new Task
                    if(validOFACFlg) {//Lock
                        isBoundPending = true;
                        // update Account
                        if(mapUpdateAccount.get(inComingRequestOFAC.accountId) != null) {
                            Account acc = mapUpdateAccount.get(inComingRequestOFAC.accountId);
                            if(!duplicateIdAcc.contains(inComingRequestOFAC.accountId)) {
                                accountUpdates.add(acc);
                                duplicateIdAcc.add(inComingRequestOFAC.accountId);
                            }
                            // Create new Task
                            //system.debug('userGroupOFACs:' + userGroupOFACs);
                            for(Id userId : userGroupOFACs) {
                                Task newTask = new Task(
                                    Subject = 'Review Sanctions for ' + inComingRequestOFAC.Name,
                                    ActivityDate = Date.today().addDays(1),
                                    WhatId = currentQuote.Id,
                                    OwnerId = userId,
                                    Description = 'This task for ' + inComingRequestOFAC.Name + ' (' + inComingRequestOFAC.accountId + ')'
                                );
                                newTasks.add(newTask);
                            }
                        }                    
                    }
                }

                apiLogList.add(ApiUtil.createLogAPICall(reqOFAC, resOFAC, 'OFACAPI Callout', 'BindQuoteController.checkBoundPendingFromOFACApi', 
                                    apiSettingOFAC.HeaderParams__c, 'Outbound'));
            } catch(Exception ex){
                system.debug('exception:' + ex.getLineNumber() + ' ex:' + ex.getMessage());
                ApiUtil.logAPICall(reqOFAC, resOFAC, 'OFACAPI Callout', 'BindQuoteController.checkBoundPendingFromOFACApi', 
                                    apiSettingOFAC.HeaderParams__c, 'Outbound');
                return false;
            }
        }

        //If all of the OFAC Flag is False => Set the Quote Status 
        //to Bound & Sanction Status on the Account should be False
        if(!isBoundPending) {
            for(Account acc : mapUpdateAccount.values()) {
                 accountUpdates.add(acc);
            }
        }  

        //Check NIPR Logic 
        //NIPR fails  - STOP the Bind process and display an error message "Broker does not have license for Insured State".
        // Update the NIPR_Status__c field on the Quote to "Broker does not have license for Insured State"  Return to Quote view page
        // if(getNIPRCallOut(currentQuote)) {
        //  currentQuote.NIPR_Status__c ='Valid State License';
        // }else{
        //  String NIPRerrorMsg = 'Broker does not have license for Insured State';
        //  currentQuote.NIPR_Status__c= NIPRerrorMsg;
        //  currentQuote.addError(NIPRerrorMsg);
        // }
        // update currentQuote;      
        //end      
        if(!accountUpdates.isEmpty())   update accountUpdates;
        if(!newTasks.isEmpty())         insert newTasks;
        if(!apiLogList.isEmpty())       insert apiLogList;     
        return isBoundPending;
    }

 ///////////////////////////////////////////////////////////
    public static HttpRequest getHttpRequest(API_Configuration__mdt apiSetting, SObject obj) {
        String baseUri = apiSetting.Base_Url__c + apiSetting.Endpoint__c;

        Map<String, String> headerParamMap = new Map<String, String>();
        for (String headerParam : apiSetting.HeaderParams__c.split(';')) {
            List<String> headerKeyValue = headerParam.split(':');
            headerParamMap.put(headerKeyValue[0], headerKeyValue[1]);
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUri);
        req.setMethod(apiSetting.Method__c);
        req.setTimeout(Integer.valueOf(Label.ApiTimeOut));

        String strBody =  ApiUtil.getRatingJsonString((ID)obj.get('Id'));
      
        req.setBody(strBody);
        for (String headerParamKey : headerParamMap.keySet()) {
            req.setHeader(headerParamKey, headerParamMap.get(headerParamKey));
        }

        return req;
    }

    public static HttpRequest getHttpRequest(API_Configuration__mdt apiSetting) {
        String baseUri = apiSetting.Base_Url__c + apiSetting.Endpoint__c;

        Map<String, String> headerParamMap = new Map<String, String>();
        for (String headerParam : apiSetting.HeaderParams__c.split(';')) {
            List<String> headerKeyValue = headerParam.split(':');
            headerParamMap.put(headerKeyValue[0], headerKeyValue[1]);
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUri);
        req.setMethod(apiSetting.Method__c);
        req.setTimeout(Integer.valueOf(Label.ApiTimeOut));

        for (String headerParamKey : headerParamMap.keySet()) {
            req.setHeader(headerParamKey, headerParamMap.get(headerParamKey));
        }

        return req;
    }
    
    public static RequestObject getRequestObject(API_Configuration__mdt apiSetting, String body) {
        RequestObject result = new RequestObject();
        try {
            if (apiSetting == null) 
                return null;

            String baseUri = apiSetting.Base_Url__c + apiSetting.Endpoint__c;

            Map<String, String> headers = new Map<String, String>();
            List<String> headerParams = new List<String>();

            // if API has header
            if (String.isNotBlank(apiSetting.HeaderParams__c)) {
                headerParams = apiSetting.HeaderParams__c.split(';');
            }

            for (String item : headerParams) {
                List<String> headerKeyValue = item.split(':');
                headers.put(headerKeyValue[0], headerKeyValue[1]);
            }

            result.endpoint = baseUri;
            result.headers = headers;
            result.method = apiSetting.Method__c;
            result.timeout = Integer.valueOf(Label.ApiTimeOut);
            result.body = body;
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            result = null;
        }
        
        return result;
    }

    public static ResponseObject getRatingRequest(Quote obj) {
        ResponseObject result = new ResponseObject();

        String api = 'Rate_Quote';
        String body = '';
        try {
            body =  ApiUtil.getRatingJson((ID)obj.get('Id'));
system.debug('body--'+body);
            API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration(api);
            
            RequestObject reqObj = getRequestObject(apiSetting, body);
            if (reqObj == null) {
                System.debug('failed');
                return null;
            }

            HttpRequest req = reqObj.getHttpRequest();
            HttpResponse res = new HttpResponse();
            system.debug('req----'+req.getBody());
            Http h = new Http();
            res = h.send(req);
            // mock response
            //res = RatingResponse.generateRatingResponse(req.getBody());
            // mock response
            system.debug('rating responsev '+res);
            result = new ResponseObject(res);             
            String headers = JSON.serialize(reqObj.headers);

            ApiUtil.logAPICall(req,res,'RatingAPI Callout','getRatingRequest', headers, 'Outbound'); 
            System.debug('res'+res);
        } catch (Exception ex) {
            System.debug(ex.getMessage() + ' - ' + ex.getLineNumber() + ' - ' + ex.getStackTraceString());
            result = null;
        }

        return result;
    }

}