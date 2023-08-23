public with sharing class SanctionSearchAPICallout {
    public SanctionSearchAPICallout() {

    }

    @future(callout = true)
    public static void callAccountSanctionV2API_async(Set<Id> accountIds) {
        if(!accountIds.isEmpty()){
            List<Sanction_Status__c> lstUpdatedSanctions = callAccountSanctionV2API(accountIds);
        }
    }

    public static List<Sanction_Status__c> callAccountSanctionV2API(Set<Id> accountIds) {
        if(UserInfo.getUserRoleId() == null){
            return null;
        }
        User loggedInUser =[SELECT Id, Name, Email, Profile.Name, UserRole.Name FROM User where Id =: UserInfo.getUserId()];
        String runningUserRoleName = loggedInUser.UserRole.Name;
        String lobSanctionId;
        String appName;
        if(runningUserRoleName != null && runningUserRoleName.contains('Aqueous')){
            lobSanctionId = Label.LOBID_AQPI;
            appName = 'Aqueous PI';
        }
        else if(runningUserRoleName != null && runningUserRoleName.contains('Celerity')){
            lobSanctionId = Label.LOBID_CEL;
            appName = 'Celerity';
        }

        List<API_Log__c> APIlist = new List<API_Log__c>();
        SanctionSearchAPICallout.sanctionV2APIres sanctionres = new SanctionSearchAPICallout.sanctionV2APIres();
        SanctionSearchAPICallout.requestbodyformat sanctionRequest =  new SanctionSearchAPICallout.requestbodyformat();
        List<Sanction_Status__c> listSanctionSearchtoUpdate = new List<Sanction_Status__c>();
        try {
            List<Account> accounts = [
                SELECT
                	BillingAddress,BillingCountry,
                    Name, BillingStreet, Billingcity, BillingState, Billingpostalcode,
                    BillingCountrycode, RecordTypeId
                FROM Account
                WHERE Id IN :accountIds
            ];
            List<Account> accountsToUpdate = new List<Account>();
            for(Account account : accounts){
                sanctionRequest = SanctionSearchAPICallout.createSanctionRequestAccountBody(sanctionRequest, account, lobSanctionId);
                System.debug('sanctionRequest'+sanctionRequest);
                sanctionres =SanctionSearchAPICallout.AccountAPICallout(JSON.serialize(sanctionRequest),appName,account.Id);
                System.debug('sanctionres'+sanctionres);
                //accountsToUpdate.add(SanctionSearchAPICallout.updateAccountSanction(sanctionres,null, account.Id));
                listSanctionSearchtoUpdate.add(SanctionSearchAPICallout.updateAccountSanction(sanctionres,null, account.Id, appName));
                APIlist.addAll(sanctionres.resapiList);
            }
            //update accountsToUpdate;
            System.debug('listSanctionSearchtoUpdate--->'+listSanctionSearchtoUpdate);
            upsert listSanctionSearchtoUpdate;
            if(APIlist.size()>0){
            	insert APIlist;
            }
            return listSanctionSearchtoUpdate;
        }
        catch(Exception ex){
            sanctionres.reserror = CommonUtil.getExceptionMessage(ex);
            if(APIlist.size()>0){
            	insert APIlist;
            }
            return listSanctionSearchtoUpdate;
        } 
    }

    public static SanctionSearchAPICallout.requestbodyformat createSanctionRequestAccountBody(SanctionSearchAPICallout.requestbodyformat sanctionRequest, Account objAccount, String lobSanctionId){
        
        sanctionRequest.searchTerm = objAccount.Name;
            sanctionRequest.searchType='entity';
            sanctionRequest.countryOfBirth = objAccount.BillingCountry;

        String add='';
        /*if (String.isNotBlank(objAccount.BillingStreet)){
            add = add + objAccount.BillingStreet + ' ';
        } 
        if (String.isNotBlank(objAccount.BillingCity)){
            add = add + objAccount.BillingCity+' ';
        } 
        if (String.isNotBlank(objAccount.BillingState)){
            add = add +objAccount.BillingState +' ';
        }
        if(String.isNotBlank(objAccount.BillingPostalCode)){
            add = add + objAccount.BillingPostalCode +' ';
        }*/
        if(String.isNotBlank(objAccount.BillingCountry)){
            add = add + objAccount.BillingCountry;
        }
        system.debug('Adddddd'+add);
        sanctionRequest.address= add;
 	//sanctionRequest.address=  subp.Account__r.BillingStreet  +' '+ subp.Account__r.BillingCity+' '+subp.Account__r.BillingState+' '+ subp.Account__r.BillingPostalCode+' '+subp.Account__r.BillingCountry;
        // sanctionRequest.billingAdd.street = subp.Account__r.BillingStreet;
        if(lobSanctionId != null){
            sanctionRequest.lobid = lobSanctionId;
        }
        // sanctionRequest.searchLists = null;  
        return sanctionRequest;
    }

    public static sanctionV2APIres AccountAPICallout(String requestBody,String Appli,String fromid){
        API_Configuration__mdt apiSettingV2 = CommonUtil.getAPIconfiguration('SanctionV2');
        sanctionV2APIres returnres = new sanctionV2APIres();
        list<API_Log__c> apiList = new list<API_Log__c>();
        
        HttpRequest req = getHttpRequest(apiSettingV2); 
        System.debug(requestBody);
        req.setBody(requestBody);
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        
        try{                
            res = http.send(req);    
            
            API_Log__c apiData = ApiUtil.createLogAPICall(req,res,'SanctionSearchAPICallout','Sanction callout', 
                                                          apiSettingV2.HeaderParams__c, 'Outbound');
            if(apiData != null){                    
                apiData.sObject_Id__c = fromid;
                apiData.Functionality__c = 'SanctionAPICheck';
                apiData.Business_Name__c = Appli;    
                apiList.add(apiData);
                //insert apiData;
            }
            System.debug('apiData==>'+apiData);
            
            
            if (res.getStatusCode() == 200) {   
                returnres.resstatus = true;
                returnres.reserror = null;
                returnres.resbody = res.getBody();
                returnres.resapiList = apiList;
                system.debug('SanctionResponse'+res.getBody());
                return returnres;
            }else{
                returnres.resstatus = false;
                returnres.reserror = 'callout fail with status :'+res.getStatusCode();
                system.debug('SanctionResponse--->'+res.getBody());
                returnres.resbody = null;
                returnres.resapiList = apiList;
                return returnres;
            }
            
        } catch(Exception ex){
            system.debug('exception:' + ex.getLineNumber() + ' ex:' + ex.getMessage());
            returnres.resstatus = false;
            returnres.reserror = 'exception:' + ex.getLineNumber() + ' ex:' + ex.getMessage();
            returnres.resbody = null;
            returnres.resapiList = apiList;
            return returnres;
        }        
    }

    public static  Sanction_Status__c updateAccountSanction(SanctionSearchAPICallout.sanctionV2APIres sanctionres, Id submissionId, Id accountId, String appName){
        if (accountId == null) {
            accountId = [select id, AccountId from Opportunity where id =: submissionId].AccountId;
        }
        Id recordTypeId;
        if(appName == 'Aqueous PI'){
            recordTypeId =Schema.SObjectType.Sanction_Status__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        }
        else if(appName == 'Celerity'){
            recordTypeId =Schema.SObjectType.Sanction_Status__c.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
        }
        List<Sanction_Status__c> listSanctionStatus = [Select Id, Account__c,Sanction_Status__c,Sanction_Date__c, searchId__c  from Sanction_Status__c where Account__c =: accountId and RecordTypeId =: recordTypeId and Sanction_Status__c NOT IN ('Cleared','Pass')];
        system.debug('AccountId'+ accountId);
        system.debug('sanctionres.resstatus'+ sanctionres.resstatus);
        system.debug('sanctionres.resstatus'+ sanctionres.reserror);
        system.debug('');
        String sanctionStatusId;
        if(listSanctionStatus != null && !listSanctionStatus.isEmpty()){
            sanctionStatusId = listSanctionStatus[0].Id;
        }
        Account acc = new Account(Id=accountId);
        Sanction_Status__c objSanctionStatus = new Sanction_Status__c();
        if(String.isNotBlank(sanctionStatusId)){
            //objSanctionStatus.Id = sanctionStatusId;
            objSanctionStatus = listSanctionStatus[0];
        }
        else{
            objSanctionStatus.Account__c = accountId;
        }
        if(sanctionres.resstatus ==true  && sanctionres.reserror == null){
            system.debug('In true check');
            SanctionSearchAPICallout.responsebodyformat sanctionResponse = (SanctionSearchAPICallout.responsebodyformat)JSON.deserialize(sanctionres.resbody, SanctionSearchAPICallout.responsebodyformat.class);
            system.debug('Sanction Response@@@@'+sanctionResponse);	
            String ragStatus = sanctionResponse.rag;  
            String searchId = sanctionResponse.searchId;
            Boolean containsClient = sanctionResponse.containsClient;
            
            if(ragStatus == 'Amber' || ragStatus =='Red'){
                if(containsClient == null){
                    if(appName == 'Aqueous PI'){
                        acc.AQ_Sanction_Status__c = 'Potential Match';
                    }
                    else if(appName == 'Celerity'){
                        acc.CEL_Sanction_Status__c = 'Potential Match';
                    }
                    objSanctionStatus.Sanction_Status__c = 'Potential Match';
                }
                else if(containsClient == true){
                    if(appName == 'Aqueous PI'){
                        acc.AQ_Sanction_Status__c = 'Failed';
                    }
                    else if(appName == 'Celerity'){
                        acc.CEL_Sanction_Status__c = 'Failed';
                    }
                    objSanctionStatus.Sanction_Status__c = 'Failed';
                }
                else if(containsClient == false){
                    if(appName == 'Aqueous PI'){
                        acc.AQ_Sanction_Status__c = 'Cleared';
                    }
                    else if(appName == 'Celerity'){
                        acc.CEL_Sanction_Status__c = 'Cleared';
                    }
                    objSanctionStatus.Sanction_Status__c = 'Cleared';
                }
                
            }
            if(ragStatus == 'Green'){
                if(appName == 'Aqueous PI'){
                    acc.AQ_Sanction_Status__c = 'Pass';
                }
                else if(appName == 'Celerity'){
                    acc.CEL_Sanction_Status__c = 'Pass';
                }
                objSanctionStatus.Sanction_Status__c = 'Pass';
            }
            acc.Sanction_Date__c = system.today();
            acc.searchId__c = searchId;
            objSanctionStatus.Sanction_Date__c = system.today();
            objSanctionStatus.searchId__c = searchId;
            system.debug('AccountInfo'+acc.Sanction_Status__c);
        }
        return objSanctionStatus;
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
        System.debug('header = '+headerParamMap);
        for (String headerParamKey : headerParamMap.keySet()) {
            req.setHeader(headerParamKey, headerParamMap.get(headerParamKey));
        }
        
        return req;
    }


    public class sanctionV2APIres{
        @AuraEnabled  Public Boolean resstatus;
        @AuraEnabled  Public String reserror;
        @AuraEnabled  Public String resbody;
        @AuraEnabled  public List<Account> sacAcc;
        @AuraEnabled  Public list<API_Log__c> resapiList;
    }
    
    public class requestbodyformat{
        Public String searchTerm;
        Public String searchType;
        Public String lobid;
        Public String address;
        Public String dob;
        Public String countryOfBirth;
        Public String nationality;
        Public list<string> searchLists;
        Public Boolean containsClient;
    }
    
    public class responsebodyformat{
        Public String searchTerm;
        Public String searchType;
        Public String address;
        Public String dob;
        Public String countryOfBirth;
        Public String nationality;
        Public String rag;
        Public Boolean containsClient;
        Public String searchId;
    }
    
}