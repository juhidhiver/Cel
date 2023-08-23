/**************************************************************************************************
* Class Name: REST_Invsk_Account_v2
* Author: Saumyak Pandey
* Created date: 20-Oct-2020
* Description: Sync from MW to SF
**************************************************************************************************/
@RestResource(urlMapping='/Invsk_Account_v2/*') 
global with sharing class REST_Invsk_Account_v2 {
    @HttpGet
    global static void doGet() {
        
        OutGoingResponseGet outResponse = new OutGoingResponseGet();
        RestRequest req = RestContext.request;
        
        try{
            String accountAzureId = RestContext.request.params.get('AccountId');            
            // Check parameter url is blank
            if(String.isBlank(accountAzureId)) {
                outResponse.status = 'Failed';
                outResponse.isSuccess = false;
                outResponse.errors.add('Missing AccountId');
                
                RestContext.response.statusCode = 200;
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                RestResponse res = RestContext.response;
                
                ApiUtil.logAPICallIn(req, res, 'REST_Invsk_Account_v2', 'REST_Invsk_Account_v2.doGet');
                return;
            }
            
            List<Account> accounts = [SELECT Id, Azure_ID__c,Name,
                                      BillingStreet,BillingCity,
                                      BillingState,BillingStateCode,
                                      BillingPostalCode,BillingCountry,
                                      BillingCountryCode,BillingLatitude,BillingLongitude,
                                      ShippingStreet,ShippingLatitude,ShippingLongitude,
                                      ShippingCity,ShippingState,
                                      ShippingStateCode,ShippingPostalCode,
                                      ShippingCountry,ShippingCountryCode,                                                  
                                      Billing_County__c, Shipping_County__c                                      
                                      FROM Account
                                      WHERE Azure_ID__c =: accountAzureId];
            
            if(accounts.isEmpty()) {
                outResponse.status = 'Failed';
                outResponse.isSuccess = false;
                outResponse.errors.add('AccountId does not exist in Salesforce.');
                
                RestContext.response.statusCode = 200;
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                RestResponse res = RestContext.response;
                
                ApiUtil.logAPICallIn(req, res, 'REST_Invsk_Account_v2', 'REST_Invsk_Account_v2.doGet');
                return;
            }
            
            Account acc = accounts[0];
            
            outResponse.status = 'Success';
            outResponse.isSuccess = true;
            outResponse.accountInfo = acc;
            outResponse.errors.clear();
            
        } catch(Exception ex){
            outResponse.status = 'Failed';
            outResponse.isSuccess = false;
            outResponse.errors.add(CommonUtil.getExceptionMessage(ex));
        }
        
        RestContext.response.statusCode = 200;
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
        RestResponse res = RestContext.response;
        
        ApiUtil.logAPICallIn(req, res, 'REST_Invsk_Account_v2', 'REST_Invsk_Account_v2.doGet');
    }
    
    @HttpPost
    global static void doPost() {        
        OutGoingResponsePost outResponse = new OutGoingResponsePost();
        // Find account base on azure id and/or billing address
        Account foundAccount = null;
        RestRequest req = RestContext.request;
        try {            
            Account requestAccount = (Account)JSON.deserialize(req.requestBody.toString(), Account.class);
            system.debug('123 account N ---- '+ requestAccount);          
   
            List<Account> accs = new list<Account>();
            //Find account by Azure Id
            if (requestAccount.Azure_ID__c != null && requestAccount.Azure_ID__c != '') {
                accs = [SELECT Id, Azure_ID__c,Name,Type,
                        BillingStreet,BillingCity,
                        BillingState,BillingStateCode,
                        BillingPostalCode,BillingCountry,
                        BillingCountryCode,ShippingStreet,
                        ShippingCity,ShippingState,
                        ShippingStateCode,ShippingPostalCode,
                        ShippingCountry,ShippingCountryCode,
                        Billing_County__c, Shipping_County__c 
                        FROM Account
                        WHERE Azure_ID__c = :requestAccount.Azure_ID__c];
            }
            
            Account existingAccount = null;
            if (accs.size() > 0) existingAccount = accs[0];
            system.debug('123 foundAccount ----  '+existingAccount);
            
            if(existingAccount != null){
                foundAccount = requestAccount;
                foundAccount.Id = existingAccount.Id;
                system.debug('123 foundAccount IF ----  '+foundAccount);
                update foundAccount;
            } else{
                foundAccount = requestAccount;                
                insert foundAccount;
                system.debug('123 foundAccount ELSE ----  '+foundAccount);
            }
            
            Account accId = [SELECT Id, Azure_ID__c FROM Account WHERE Id=:foundAccount.Id LIMIT 1];
            system.debug('123 accAzureId ----  '+accId);
            
            outResponse.status = 'Success';
            outResponse.isSuccess = true;
            outResponse.accountId = accId.Id;
            outResponse.azureid = accId.Azure_ID__c;
            outResponse.errors.clear();
            
        } catch (Exception ex) {
            outResponse.status = 'Failed';
            outResponse.isSuccess = false;
            outResponse.errors.add(CommonUtil.getExceptionMessage(ex));
            system.debug('ex.getMessage()'+ex.getMessage());
        }
        
        RestContext.response.statusCode = 200;
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
        ApiUtil.logAPICallIn(RestContext.request, RestContext.response,
                             'REST_Invsk_Account_v2', 'REST_Invsk_Account_v2.doPost');
    }
    
    public class OutGoingResponsePost {
        public String status            {get; set;}
        public Boolean isSuccess        {get; set;}
        public List<String> errors      {get; set;}
        public String accountId         {get; set;}
        public String azureId           {get; set;}
        
        public OutGoingResponsePost() {
            this.status = null;
            this.isSuccess = false;
            this.errors = new List<String>();
            this.accountId = null;
            this.azureId = null;
        }
    }
    
    public class OutGoingResponseGet {
        public String status                 {get; set;}
        public Boolean isSuccess             {get; set;}
        public List<String> errors           {get; set;}
        public Account accountInfo {get; set;}
        public OutGoingResponseGet() {
            this.status = null;
            this.isSuccess = false;
            this.errors = new List<String>();
            this.accountInfo = null;
        }
    }
}