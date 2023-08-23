/*************************************************
* Class Name: REST_Invsk_BrokerContact 
* Author: 
* Date: 
* Requirement/Project Name: 
* Requirement/Project Description: 
** Revision: Quan Tran / 19 April 2019
*************************************************/

@RestResource(urlMapping='/Invsk_BrokerContact/*')
global with sharing class REST_Invsk_BrokerContact  {
    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        ResponseCreateObject responseStatus = new ResponseCreateObject();
        
        try {
            String requestString = req.requestBody.toString();
            CommingRequest request = (CommingRequest)JSON.deserialize(requestString, CommingRequest.class);
            system.debug('###request####' + request);
            
            if(request.operation == 'Create') {
                createContact(request);
            }
            else if(request.operation == 'Update') {
                updateContact(request);
            }
        } catch(Exception ex) {
            system.debug('@@@ ' + ex.getMessage() + ', location: ' + ex.getStackTraceString());
            
            responseStatus.status = 'Failed';
            responseStatus.isSuccess = false;
            responseStatus.errors.add(CommonUtil.getExceptionMessage(ex));
            RestContext.response.statusCode = 200;
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
            ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_BrokerContact', 'REST_Invsk_BrokerContact.doPost');
        }
    }
    
    private static void createContact(CommingRequest request) {
        RestRequest req = RestContext.request;
        ResponseCreateObject responseStatus = new ResponseCreateObject();
        
        if(String.isBlank(request.lastName)) {
            responseStatus.status = 'Failed';
            responseStatus.isSuccess = false;
            responseStatus.errors.add('Missing Last Name');
            
            RestContext.response.statusCode = 200;
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
            ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_BrokerContact', 'REST_Invsk_BrokerContact.createContact');
            
            return;
        }
        
        if(String.isBlank(request.FEIN)) {
            responseStatus.status = 'Failed';
            responseStatus.isSuccess = false;
            responseStatus.errors.add('Missing FEIN Number');
            
            RestContext.response.statusCode = 200;
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
            ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_BrokerContact', 'REST_Invsk_BrokerContact.createContact');
            
            return;
        }
        
        Decimal feinDec = null;
        try{
            feinDec = Decimal.valueOf(request.FEIN);
        } catch(Exception ex){
            responseStatus.status = 'Failed';
            responseStatus.isSuccess = false;
            responseStatus.errors.add('The FEIN Number does not format number');
            
            RestContext.response.statusCode = 200;
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
            ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_BrokerContact', 'REST_Invsk_BrokerContact.createContact');
            
            return;
        }
        
        // 2019/04/19 Quan Tran modified start
        Id rdAccBrokerId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Account').getRecordTypeId();
        List<Account> accBrokers = [Select Id,Name From Account Where FEIN__c =: feinDec And RecordTypeId =: rdAccBrokerId];
        // validate FEIN (Federal Employer Identification Number)            
        String azureId = '';
        
        if(accBrokers.isEmpty()) {
            responseStatus.status = 'Failed';
            responseStatus.isSuccess = false;
            responseStatus.errors.add('No Broker Agency found with this FEIN Number');
            
            RestContext.response.statusCode = 200;
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
            ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_BrokerContact', 'REST_Invsk_BrokerContact.createContact');
            return;
        } 
        
        if(request.licenses != null && !request.licenses.isEmpty()){
            //To check licenses fields not empty 
            for(BrokerLicenses brLic : request.licenses){
                if(String.isBlank(brLic.licenseState) || String.isBlank(brLic.licenseNumber) || String.isBlank(brLic.licenseType) || String.isBlank(brLic.brokerLicOperation)
                  || String.isBlank(brLic.licenseEntity)
                  ){
                    responseStatus.status = 'Failed';
                    responseStatus.isSuccess = false;
                    responseStatus.errors.add('Invalid license request');
                    RestContext.response.statusCode = 200;
                    RestContext.response.addHeader('Content-Type', 'application/json');
                    RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
                    ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_BrokerContact', 'REST_Invsk_BrokerContact.createContact');
                    return;
                }
            }
        } 
        
        List<Contact> contactAnonymous = [SELECT Id, Azure_ID__c, AccountId, Name, Account.Name  
                                          FROM Contact 
                                          WHERE Email = :request.emailAddress limit 1];
        
        if(!contactAnonymous.isEmpty()) {       
            if(contactAnonymous[0].Account.Name == 'Anonymous Portal Broker'){   
                if (accBrokers[0].Name != 'Anonymous Portal Broker') 
                {
                    
                    contactAnonymous[0].AccountId = accBrokers[0].Id;
                    if(String.isNotBlank(request.contactAzureId)){
                        contactAnonymous[0].Azure_ID__c =  request.contactAzureId;
                    }
                    //24/04/2019 long.ly check null
                    if(String.isNotBlank(request.firstName)) {
                        contactAnonymous[0].FirstName = request.firstName;
                    }
                    if(String.isNotBlank(request.lastName)) {
                        contactAnonymous[0].LastName = request.lastName;
                    }
                    if(String.isNotBlank(request.emailAddress)) {
                        contactAnonymous[0].Email = request.emailAddress;
                    }
                    if(String.isNotBlank(request.phoneNo)) {
                        contactAnonymous[0].Phone = request.phoneNo;
                    }    
                    if(request.AppointedFlag != null) {
                        contactAnonymous[0].Appointed_Flag__c = request.AppointedFlag;
                    }
                    //22794
                    if(request.voucherCode != null) {
                        contactAnonymous[0].Voucher_Code__c = request.voucherCode;
                    }
                    
                    //START 19656 7/13/2020 Calling create/update method
                    if(!request.licenses.isEmpty()){
                        try{
                            brokerLicenseDML(request,contactAnonymous);
                        }catch(Exception ex) {
                            system.debug('@@@ ' + ex.getMessage() + ', invalid : ' + ex.getStackTraceString());
                            responseStatus.status = 'Failed';
                            responseStatus.isSuccess = false;
                            responseStatus.errors.clear();
                            responseStatus.errors.add('Incorrect license fields');
                            RestContext.response.statusCode = 200;
                            RestContext.response.addHeader('Content-Type', 'application/json');
                            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
                            ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_BrokerContact', 'REST_Invsk_BrokerContact.createContact');
                            return;
                        }
                    }
                    //END
                    
                    if(request.address != null) {
                        if(String.isNotBlank(request.address.addressLine1)) {
                            contactAnonymous[0].MailingStreet = request.address.addressLine1;
                        }
                        if(String.isNotBlank(request.address.city)) {
                            contactAnonymous[0].MailingCity = request.address.city;
                        }
                        if(String.isNotBlank(request.address.state)) {
                            contactAnonymous[0].MailingStateCode = request.address.state;
                        }
                        if(String.isNotBlank(request.address.postalCode)) {
                            contactAnonymous[0].MailingPostalCode = request.address.postalCode;
                        }
                        if(String.isNotBlank(request.address.country)) {
                            contactAnonymous[0].MailingCountryCode = request.address.country;
                        }
                        // Quan Tran on 6/20/2019                    
                        if(String.isNotBlank(request.address.county)) {
                            contactAnonymous[0].Mailing_County__c = request.address.county;
                        }                    
                        // end
                    }                   
                    update contactAnonymous;
                    azureId = contactAnonymous[0].Azure_ID__c;
                }
            }                     
        }
        
        else {         
            Id rdConBroker = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Broker_Contact').getRecordTypeId();
            Contact newContact = new Contact(
                FirstName = request.firstName,
                LastName = request.lastName,
                Email = request.emailAddress,
                Phone = request.phoneNo,
                AccountId = accBrokers[0].Id,
                Azure_Id__c = request.contactAzureId,
                RecordTypeId = rdConBroker,
                Appointed_Flag__c = request.AppointedFlag,
                Voucher_Code__c = request.voucherCode
            );
            
            if(request.address != null){
                newContact.MailingStreet = request.address.addressLine1;
                newContact.MailingCity = request.address.city;
                newContact.MailingStateCode = request.address.state; 
                newContact.MailingPostalCode = request.address.postalCode;
                newContact.MailingCountryCode = request.address.country;
                newContact.Mailing_County__c = request.address.county; // Quan Tran on 6/20/2019
            }  
            system.debug('newContact'+newContact);
            insert newContact;
            
            List<Contact> conAzure = [Select Id, Azure_ID__c From Contact Where Id =: newContact.Id];
            azureId = conAzure[0].Azure_ID__c; 
            
            //START 19656 7/13/2020 Calling create/update method
            if(request.licenses != null && !request.licenses.isEmpty()){
                try{
                    brokerLicenseDML(request,conAzure);
                }catch(Exception ex) {
                    system.debug('@@@ ' + ex.getMessage() + ', invalid : ' + ex.getStackTraceString());
                    responseStatus.status = 'Failed';
                    responseStatus.isSuccess = false;
                    responseStatus.errors.clear();
                    responseStatus.errors.add('Incorrect license fields');
                    RestContext.response.statusCode = 200;
                    RestContext.response.addHeader('Content-Type', 'application/json');
                    RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
                    ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_BrokerContact', 'REST_Invsk_BrokerContact.createContact');
                    return;
                }
            }
            //END 
        }
        
        Set<String> prodIdOnAccBrokers = new Set<String>();
        for(Account_Product__c ap : [Select Id,Account_Id__c,Product_Id__c
                                     From Account_Product__c 
                                     Where Account_Id__c =: accBrokers[0].Id]) {
                                         prodIdOnAccBrokers.add(ap.Product_Id__c);
                                     }
        
        Set<String> accoutChannels = new Set<String>();
        for(Account acc : [SELECT Id FROM Account Where Azure_Id__c =: request.channelID And Channel_Indicator__c = true]) {
            accoutChannels.add(acc.Id);
        }
        
        List<Account_Product__c> newAccPros = new List<Account_Product__c>();
        
        if(!accoutChannels.isEmpty() && !accoutChannels.contains(accBrokers[0].Id)) {
            for(Account_Product__c ap : [Select Id,Account_Id__c,Product_Id__c
                                         From Account_Product__c 
                                         Where Account_Id__c In: accoutChannels]){
                                             // If Products on Account Broker do not contain Products on Account Channel then create new Account Product
                                             if(!prodIdOnAccBrokers.contains(ap.Product_Id__c)) {
                                                 Account_Product__c accProClone = ap.clone(false, false, false, false);
                                                 accProClone.Account_Id__c = accBrokers[0].Id;
                                                 newAccPros.add(accProClone);
                                             }
                                             
                                         }
        }
        System.debug('###newAccPros===' + newAccPros);
        
        if(!newAccPros.isEmpty()) {
            insert newAccPros;
        }
        
        responseStatus.status = 'Success';
        responseStatus.isSuccess = true;
        responseStatus.errors.clear();
        //commented by Siva
        
        responseStatus.brokerContactId = azureId;
        
        RestContext.response.statusCode = 200;
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
        ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_BrokerContact', 'REST_Invsk_BrokerContact.createContact');
    }
    
    private static void updateContact(CommingRequest request) {
        RestRequest req = RestContext.request;
        ResponseUpdateObject responseStatus = new ResponseUpdateObject();
        
        List<Contact> contactUpdates = [Select Id, FirstName, LastName,Account.Name, Phone, Email,Azure_ID__c ,Voucher_Code__c
                                        From Contact Where Azure_ID__c =: request.contactAzureId];
        
        if(contactUpdates.isEmpty()) {
            responseStatus.status = 'Failed';
            responseStatus.isSuccess = false;
            responseStatus.errors.add('No Contact found with this Contact Azure Id.');
            
            RestContext.response.statusCode = 200;
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
            ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_BrokerContact', 'REST_Invsk_BrokerContact.updateContact');
            return;
        }
        
        //START FEIN Update
        if(String.isBlank(request.FEIN)) {
            responseStatus.status = 'Failed';
            responseStatus.isSuccess = false;
            responseStatus.errors.add('Missing FEIN Number');
            
            RestContext.response.statusCode = 200;
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
            ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_BrokerContact', 'REST_Invsk_BrokerContact.createContact');
            
            return;
        }
        
        Decimal feinDec = null;
        try{
            feinDec = Decimal.valueOf(request.FEIN);
        } catch(Exception ex){
            responseStatus.status = 'Failed';
            responseStatus.isSuccess = false;
            responseStatus.errors.add('The FEIN Number does not format number');
            
            RestContext.response.statusCode = 200;
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
            ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_BrokerContact', 'REST_Invsk_BrokerContact.createContact');
            
            return;
        }
        
        Id rdAccBrokerId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Account').getRecordTypeId();
        List<Account> accBrokers = [Select Id,Name From Account Where FEIN__c =: feinDec And RecordTypeId =: rdAccBrokerId];
        
        if(accBrokers.isEmpty()) {
            responseStatus.status = 'Failed';
            responseStatus.isSuccess = false;
            responseStatus.errors.add('No Broker Agency found with this FEIN Number');
            
            RestContext.response.statusCode = 200;
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
            ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_BrokerContact', 'REST_Invsk_BrokerContact.createContact');
            return;
        } 
        //END
        
        Contact conUpdate = contactUpdates[0];
        Boolean isUpdate = false;
        
        //START FEIN Update
        if(conUpdate.Account.Name == 'Anonymous Portal Broker'){
            if (accBrokers[0].Name != 'Anonymous Portal Broker'){
                conUpdate.AccountId = accBrokers[0].Id;
                isUpdate = true;
            }
        }   
        //END
        
        if(String.isNotBlank(request.phoneNo)) {
            conUpdate.Phone = request.phoneNo;
            isUpdate = true;
        }
        
        if(String.isNotBlank(request.newcontactAzureId)) {
            conUpdate.Azure_ID__c = request.newcontactAzureId;
            isUpdate = true;
        }
        if(String.isNotBlank(request.voucherCode)) {
            conUpdate.Voucher_Code__c = request.voucherCode;
            isUpdate = true;
        }
        
        
        if(request.address != null) {
            conUpdate.MailingStreet = request.address.addressLine1;
            conUpdate.MailingCity = request.address.city;
            conUpdate.MailingStateCode = request.address.state;
            conUpdate.MailingPostalCode = request.address.postalCode;
            conUpdate.MailingCountryCode = request.address.country;
            conUpdate.Mailing_County__c = request.address.county; // Quan Tran on 6/21/2019
            isUpdate = true;
        }
        // 2019/03/30 Vin Hua added end
        
        if(isUpdate) {
            update conUpdate;
        }
        
        //START 19656 7/13/2020 
        if(!request.licenses.isEmpty()){
            //To check licenses fields not empty 
            for(BrokerLicenses brLic : request.licenses){
                if(String.isBlank(brLic.licenseState) || String.isBlank(brLic.licenseNumber) 
                   || String.isBlank(brLic.licenseType) || String.isBlank(brLic.brokerLicOperation) || String.isBlank(brLic.licenseEntity)){
                    responseStatus.status = 'Failed';
                    responseStatus.isSuccess = false;
                    responseStatus.errors.add('Invalid license request');
                    RestContext.response.statusCode = 200;
                    RestContext.response.addHeader('Content-Type', 'application/json');
                    RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
                    ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_BrokerContact', 'REST_Invsk_BrokerContact.updateContact');
                    return;
                }
            }
             // Calling create/update method
            try{
                brokerLicenseDML(request,contactUpdates);
            }catch(Exception ex) {
                system.debug('@@@ ' + ex.getMessage() + ', invalid : ' + ex.getStackTraceString());
                responseStatus.status = 'Failed';
                responseStatus.isSuccess = false;
                responseStatus.errors.clear();
                responseStatus.errors.add('Incorrect license fields');
                RestContext.response.statusCode = 200;
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
                ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_BrokerContact', 'REST_Invsk_BrokerContact.updateContact');
                return;
            }
        }
        //END
        
        responseStatus.status = 'Success';
        responseStatus.isSuccess = True;
        responseStatus.errors.clear();
        
        responseStatus.brokerContactId = contactUpdates[0].Azure_ID__c;
        
        RestContext.response.statusCode = 200;
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
        ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_BrokerContact', 'REST_Invsk_BrokerContact.updateContact');
        
    }
    
    
    //START 19656
    private static void brokerLicenseDML (CommingRequest request,  List<Contact> contactList){
        RestRequest req = RestContext.request;
        ResponseUpdateObject responseStatus = new ResponseUpdateObject();
        
        List<Broker_License__c> upsertBrokerLicenseList = new List<Broker_License__c>();
        List<BrokerLicenses> upsertBrokerLicenseWrapList = new List<BrokerLicenses>();
        List<String> brokerLicSetNumber = new List<String>(); 
        
        if(!request.licenses.isEmpty()){
            for(BrokerLicenses brokerLIC : request.licenses){
                if(brokerLIC.brokerLicOperation == 'Delete'){
                   brokerLicSetNumber.add(brokerLIC.licenseState+brokerLIC.licenseNumber);
                }
                else if (brokerLIC.brokerLicOperation == 'Create' || brokerLIC.brokerLicOperation == 'Update'){
                    upsertBrokerLicenseWrapList.add(brokerLIC);
                }            
            }
        }
        
        if(!brokerLicSetNumber.isEmpty()){
            List<Broker_License__c> DelbrokerLicList = [Select Id  From Broker_License__c 
                                                        Where Broker__c=:contactList[0].Id AND licenseStateNumber__c IN:brokerLicSetNumber];
            if(!DelbrokerLicList.isEmpty()){
                delete DelbrokerLicList;                            
            } 
        }
        
        if(!upsertBrokerLicenseWrapList.isEmpty()){
            List<Broker_License__c> blQueryList = [Select Id, License_State__c, License_Number__c, licenseStateNumber__c From Broker_License__c Where Broker__c=:contactList[0].Id];
            
            for(BrokerLicenses brLic : upsertBrokerLicenseWrapList){
                Broker_License__c newLicense = new Broker_License__c();
                
                Boolean licIsExist = true;
                for(Broker_License__c brLICObj:blQueryList){
                    if(brLic.licenseState == brLICObj.License_State__c && brLic.licenseNumber == brLICObj.License_Number__c){
                        licIsExist = false;
                        if(brLICObj.License_State__c !=null && brLICObj.License_Number__c !=null){
                            newLicense.Id = brLICObj.Id;
                        }
                    }
                }
                newLicense.License_Number__c = brLic.licenseNumber;
                newLicense.License_State__c = brLic.licenseState;   
                newLicense.License_Type__c = brLic.licenseType;
                newLicense.License_Entity__c = brLic.licenseEntity;
                if(licIsExist)
                {
                    newLicense.Broker__c = contactList[0].Id;
                }
                
                if(!String.isBlank(newLicense.License_State__c))
                    upsertBrokerLicenseList.add(newLicense);
            }  
            
            if(!upsertBrokerLicenseList.isEmpty()){
                upsert upsertBrokerLicenseList;
            }
            
        } 
    }
    //END
    
    public class CommingRequest{
        public String firstName         {get; set;}
        public String lastName          {get; set;}
        public String emailAddress      {get; set;}
        public String phoneNo           {get; set;}
        public String FEIN              {get; set;}
        public String channelID         {get; set;}
        public String operation         {get; set;}
        public String contactAzureId    {get; set;}
        public boolean appointedFlag    {get; set;}
        public string newcontactAzureId {get;set;}
        public string voucherCode    {get; set;} // 22794
        
        // 2019/03/30 Vinh Hua added
        public AddressInfo address      {get; set;}
        public List<BrokerLicenses> licenses {get; set;}  // 19656
         
    }
    
    //START 19656
    public class BrokerLicenses {
        public String licenseNumber;
        public String licenseType ;
        public String licenseState;
        public String licenseEntity;
        public string brokerLicOperation;
    }
    //END
    
    public class AddressInfo {
        public String addressLine1;
        public String addressLine2;
        public String city;
        public String state;
        public String postalCode;
        public String country;
        public String county; // Quan Tran on 6/20/2019
    }
    
    public class ResponseCreateObject{
        public String status            {get; set;}
        public List<String> errors      {get; set;}
        public Boolean isSuccess        {get; set;}
        public String brokerContactId   {get; set;}
        
        public ResponseCreateObject() {
            this.status = null;
            this.isSuccess = false;
            this.errors = new List<String>();
            this.brokerContactId = null;
        }
    }
    
    public class ResponseUpdateObject{
        public String status            {get; set;}
        public List<String> errors      {get; set;}
        public Boolean isSuccess        {get; set;}
        public String brokerContactId   {get; set;}
        
        public ResponseUpdateObject() {
            this.status = null;
            this.isSuccess = false;
            this.errors = new List<String>();
            this.brokerContactId = null;
        }
    }
}