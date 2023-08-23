public with sharing class SanctionSearchUpdateController {
    public SanctionSearchUpdateController() {

    }

    @InvocableMethod(label='Sanction Service Update Callout')
    public static void declineFailedSanctioncallout(List<Id> AccountId){
        String Appli = '';
        system.debug('AccountId ::'+AccountId);
        SanctionSearchAPICallout.requestbodyformat sanctionRequest =  new SanctionSearchAPICallout.requestbodyformat();
        SanctionSearchAPICallout.sanctionV2APIres sanctionres = new SanctionSearchAPICallout.sanctionV2APIres();

        try{
            List<Account> acc = [select id,Name,BillingAddress,BillingStreet,BillingCity,BillingState,
                                 BillingPostalCode,BillingCountry,RecordTypeId,AQ_Sanction_Status__c,Cel_Sanction_Status__c from 
                                 Account where Id IN:AccountId];
            
            if(acc.size()>0)
            {
                if(String.isNotBlank( acc[0].AQ_Sanction_Status__c)){
                 sanctionRequest = SanctionSearchUpdateController.createSanctionRequestBody(sanctionRequest, acc[0],acc[0].AQ_Sanction_Status__c); 
                    Appli = 'Aqueous PI';
                }else{
                  sanctionRequest = SanctionSearchUpdateController.createSanctionRequestBody(sanctionRequest, acc[0],acc[0].Cel_Sanction_Status__c); 
                    Appli = 'Celerity PI';
                }
            System.debug('sanctionRequest---->'+sanctionRequest);
            SanctionSearchUpdateController.AccountAPICallout(JSON.serialize(sanctionRequest),Appli,acc[0].Id);
            }
        }
        catch(Exception ex){
          CommonUtil.getExceptionMessage(ex);
        }  
    }
    
    @Future(callout=true)
    Public static void AccountAPICallout(String requestBody,String Appli,String fromid){
        
        API_Configuration__mdt apiSettingV2 = CommonUtil.getAPIconfiguration('SanctionV2_Update');
         
        SanctionSearchAPICallout.sanctionV2APIres returnres = new SanctionSearchAPICallout.sanctionV2APIres();
        list<API_Log__c> apiList = new list<API_Log__c>();
        System.debug('returnres'+returnres);
        HttpRequest req = SanctionSearchAPICallout.getHttpRequest(apiSettingV2); 
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
                insert apiData;
            }
            System.debug('apiData==>'+apiData);
            
            
            if (res.getStatusCode() == 200) {   
                returnres.resstatus = true;
                returnres.reserror = null;
                returnres.resbody = res.getBody();
                returnres.resapiList = apiList;
                system.debug('SanctionResponse-->'+res.getBody());
             //   return returnres;
            }else{
                returnres.resstatus = false;
                returnres.reserror = 'callout fail with status :'+res.getStatusCode();
                system.debug('SanctionResponse Status Code--->'+res.getStatusCode()+'****'+res.getStatus());
                system.debug('SanctionResponse--->'+res.getBody());
                returnres.resbody = null;
                returnres.resapiList = apiList;
              //  return returnres;
            }
            
        } catch(Exception ex){
            system.debug('exception:' + ex.getLineNumber() + ' ex:' + ex.getMessage());
            returnres.resstatus = false;
            returnres.reserror = 'exception:' + ex.getLineNumber() + ' ex:' + ex.getMessage();
            returnres.resbody = null;
            returnres.resapiList = apiList;
          //  return returnres;
        }        
    }
    
    public static SanctionSearchAPICallout.requestbodyformat 
        createSanctionRequestBody(SanctionSearchAPICallout.requestbodyformat sanctionRequest, Account acc, String options){
        system.debug('acc.RecordTypeId ::'+acc.RecordTypeId);
        system.debug('Schema.SObjectType.Account.getRecordTypeInfosById().get(acc.RecordTypeId).getDeveloperName() ::' +Schema.SObjectType.Account.getRecordTypeInfosById().get(acc.RecordTypeId).getDeveloperName());
        if(Schema.SObjectType.Account.getRecordTypeInfosById().get(acc.RecordTypeId).getDeveloperName() == 'Business'){
            sanctionRequest.searchTerm = acc.Name;
            sanctionRequest.searchType='entity';
            sanctionRequest.countryOfBirth = acc.BillingCountry;
            
        }else if(Schema.SObjectType.Account.getRecordTypeInfosById().get(acc.RecordTypeId).getDeveloperName() == 'PersonAccount'){
            sanctionRequest.searchType='individual';
            sanctionRequest.searchTerm = acc.Name;
            if(acc.Name.containsWhitespace()){
                sanctionRequest.searchTerm = acc.Name;
            }else{
                sanctionRequest.searchTerm = acc.Name +' ';
            }
        }
        String add='';
        /*if (String.isNotBlank(acc.BillingStreet)){
            add = add + acc.BillingStreet + ' ';
        } if (String.isNotBlank(acc.BillingCity)){
            add = add + acc.BillingCity+' ';
        } if (String.isNotBlank(acc.BillingState)){
            add = add +acc.BillingState +' ';
        }if(String.isNotBlank(acc.BillingPostalCode)){
            add = add + acc.BillingPostalCode +' ';
        }*/
        if(String.isNotBlank(acc.BillingCountry)){
            add = add + acc.BillingCountry;
        }
        sanctionRequest.address= add;
        
        
        sanctionRequest.lobid = '3F761456B4AA47C68C4F9041DB8B3311';		
            if(options == 'Cleared'){
              sanctionRequest.containsClient = false;  
            }else{
              sanctionRequest.containsClient = true; 
            }
        return sanctionRequest;
    }
}