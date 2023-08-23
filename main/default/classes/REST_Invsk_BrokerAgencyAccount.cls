/*************************************************
* Class Name: REST_Invsk_BrokerAgencyAccount
* Author: Vinh Hua
* Updated: 2021 Jan 28
* Description: Broker Agency Account 
* 
*************************************************/
@RestResource(urlMapping='/Invsk_BrokerAgencyAccount/*')
global with sharing class REST_Invsk_BrokerAgencyAccount {
    @HttpGet
    global static void getBrokerAgencyAccount() {
        RestRequest req = RestContext.request;
        List<OutcomingResponseGet> outResponseList = new List<OutcomingResponseGet>();
        OutcomingResponseGet outResponse = new OutcomingResponseGet();
        try {
            String accountFEIN = RestContext.request.params.get('FEIN');
            String accountName = RestContext.request.params.get('AgencyName');
            String billingCity = RestContext.request.params.get('City');
            String billingState= RestContext.request.params.get('State');
            List<Account> listAccount = new List<Account>();
            System.debug('accname '+accountName +'billcity '+billingCity+'billingState '+billingState);
            
            if( String.isBlank(accountFEIN) && (String.isBlank(accountName) && String.isBlank(billingCity) && String.isBlank(billingState)) && String.isBlank(accountName)) {
                outResponse.status = 'Failed';
                outResponse.isSuccess = false;
                outResponse.errors.add('URL Data is blank');
                outResponseList.add(outResponse);
            } else {
                Id recordtypeBrokerId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
                if(!String.isBlank(accountFEIN)){
                    listAccount = [SELECT Id ,Name, Azure_ID__c, Appointed_Flag__c
                                   ,BillingStreet, BillingCity, BillingStateCode
                                   ,BillingPostalCode, BillingCountryCode, Billing_County__c,FEIN__c, DoingBusinessAs__c  //06-21 on LyLong
                                   FROM Account WHERE FEIN__c = :Decimal.valueOf(accountFEIN)
                                   AND RecordTypeId = :recordtypeBrokerId limit 1];
                    system.debug('picklist' +listAccount);
                }
                else if (!String.isBlank(accountName) && !String.isBlank(billingCity) && !String.isBlank(billingState)){                   
                    listAccount = [SELECT Id ,Name, Azure_ID__c, Appointed_Flag__c
                                   ,BillingStreet, BillingCity, BillingStateCode
                                   ,BillingPostalCode, BillingCountryCode, Billing_County__c,FEIN__c ,DoingBusinessAs__c
                                   FROM Account WHERE Name =:accountName AND BillingCity =:billingCity AND BillingStateCode =:billingState
                                   AND RecordTypeId =:recordtypeBrokerId LIMIT 1];
                    
                }
                else if(!String.isBlank(accountName)&& String.isBlank(billingCity) && String.isBlank(billingState)){                   
                    string accName = '%'+accountName+'%';                    
               for(Account acc : [SELECT Id ,Name, Azure_ID__c, Appointed_Flag__c
                                   ,BillingStreet, BillingCity, BillingStateCode
                                   ,BillingPostalCode, BillingCountryCode,FEIN__c, Billing_County__c ,DoingBusinessAs__c
                                   FROM Account WHERE RecordTypeId =:recordtypeBrokerId ]){
                    string accNameLower = accountName.tolowercase();
                    if(acc.Name.tolowercase().contains(accNameLower))
                     listAccount.add(acc);
                     }
                }
                
               if(listAccount.isEmpty()){
                    outResponse.status = 'Failed';
                    outResponse.isSuccess = false;
                    outResponse.errors.add('Broker Agency not found');
                    outResponseList.add(outResponse);
                } else {
                    
                    for(Account listvar : listAccount){
                        OutcomingResponseGet outResponse1 = new OutcomingResponseGet();
                        system.debug('listAccount--------------'+listAccount);
                        AccountResponseGet accountResp = new AccountResponseGet();
                        accountResp.AgencyName = listvar.Name;
                        accountResp.FEIN = listvar.FEIN__c;
                        accountResp.AppointedFlag = listvar.Appointed_Flag__c; 
                        AddressInfo addInfo = new AddressInfo();
                        addInfo.addressLine1 = String.isNotBlank(listvar.BillingStreet) ? listvar.BillingStreet : '';
                        addInfo.city = String.isNotBlank(listvar.BillingCity) ? listvar.BillingCity : '';
                        addInfo.state = String.isNotBlank(listvar.BillingStateCode) ? listvar.BillingStateCode : '';
                        addInfo.postalCode = String.isNotBlank(listvar.BillingPostalCode) ? listvar.BillingPostalCode : '';
                        addInfo.country = String.isNotBlank(listvar.BillingCountryCode) ? listvar.BillingCountryCode : '';
                        addInfo.county = String.isNotBlank(listvar.Billing_County__c) ? listvar.Billing_County__c : ''; //06-21 on LyLong
                        accountResp.BillingAddress = addInfo;
                        String str = String.isNotBlank(listvar.DoingBusinessAs__c) ? listvar.DoingBusinessAs__c : '';
						List<String> picklist = str.split(',');
                      //  string picklist = String.isNotBlank(listvar.DoingBusinessAs__c) ? listvar.DoingBusinessAs__c : '';
                        accountResp.DoingBusinessAs=picklist;
                        system.debug('accountResp.DoingBusinessAs '+accountResp.DoingBusinessAs);
                        // system.debug('accountResp.DoingBusinessAs '+accountResp.DoingBusinessAs[1]);
                        outResponse1.status = 'OK';
                        outResponse1.errors.clear();
                        outResponse1.isSuccess = true;
                        outResponse1.accountGet = accountResp;
                        outResponseList.add(outResponse1);
                        system.debug('outputresponse1' +outResponseList);    
                    }
         
                }
            }
            
        }
        catch (Exception ex) {
            outResponse.status = 'Failed';
            outResponse.isSuccess = false;
            outResponse.errors.add(CommonUtil.getExceptionMessage(ex));
            outResponseList.add(outResponse);
            
        }
        RestContext.response.statusCode = 200;
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponseList));
        ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_BrokerAgencyAccount', 'REST_Invsk_BrokerAgencyAccount.doGet');          
    }
    
    @HttpPost
    global static void createBrokerAgencyAccount() {
        OutcomingResponsePost outResponse = new OutcomingResponsePost();
        try {
            AccountRequest accountInfo = (AccountRequest) JSON.deserializeStrict(RestContext.request.requestBody.toString(), AccountRequest.class);
          
               Id recordtypeBrokerId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
                String doingBusinessAsString = String.join(accountInfo.DoingBusinessAs, ',');
                Account newAccount = new Account(
                    Name = accountInfo.AgencyName, 
                    BillingStreet = accountInfo.BillingAddress.addressLine1, 
                    BillingCity = accountInfo.BillingAddress.city, 
                    BillingStateCode = accountInfo.BillingAddress.state, 
                    BillingPostalCode = accountInfo.BillingAddress.postalCode,
                    BillingCountryCode = accountInfo.BillingAddress.country,
                    Billing_County__c = accountInfo.BillingAddress.county, //06-21 on LyLong
                    Phone = accountInfo.PhoneNo,
                    //Azure_Id__c = accountInfo.ChannelID,
                    FEIN__c = accountInfo.FEIN,
                     //SanctionsDate__c =  accountInfo.SanctionsDate,
                    //SanctionsStatus__c = accountInfo.SanctionsStatus,
                    Sanction_Date__c =  accountInfo.SanctionsDate,
                    Sanction_Status__c = accountInfo.SanctionsStatus,
                    SanctionsListsChecked__c = accountInfo.SanctionsListsChecked,
                    Appointed_Flag__c = accountInfo.AppointedFlag,
                    RecordTypeId = recordtypeBrokerId,
                    Producer_Type__c = accountInfo.AgencyType,
                    DoingBusinessAs__c = doingBusinessAsString
                );  insert newAccount;
           
                List<Account> lstAccountCreated = [SELECT Id,Azure_ID__c FROM Account WHERE Id =:newAccount.Id];
                outResponse.status = 'OK';
                outResponse.isSuccess = true;
                outResponse.errors.clear();
                outResponse.AccountAzureId = lstAccountCreated[0].Azure_ID__c;
            }
            
       
        catch (Exception ex){
            outResponse.status = 'Failed';
            outResponse.isSuccess = false;
            outResponse.errors.add(CommonUtil.getExceptionMessage(ex));
        }
        
        RestContext.response.statusCode = 200;
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
        ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_BrokerAgencyAccount', 'REST_Invsk_BrokerAgencyAccount.doPost');
    }
    
    public class AccountRequest {
        public String AgencyName;
        public AddressInfo BillingAddress;
        public String PhoneNo;
        public String ChannelID;
        public Decimal FEIN;
        public Date SanctionsDate;
        public String SanctionsStatus;
        public String SanctionsListsChecked;
        public Boolean AppointedFlag;
        public String AgencyType;
        public List<String> DoingBusinessAs;
    }
    
    public class OutcomingResponseGet {
        public String status;
        public Boolean isSuccess;
        public List<String> errors;
        //public AccountResponse account;
        public AccountResponseGet accountGet;
        public OutcomingResponseGet() {
            this.status = null;
            this.isSuccess = false;
            this.errors = new List<String>();
            // this.account = null;
            this.accountGet = null;
        }
    }
    
    public class OutcomingResponsePost {
        public String status;
        public Boolean isSuccess;
        public List<String> errors;
        public String AccountAzureId;
        public OutcomingResponsePost() {
            this.status = null;
            this.isSuccess = false;
            this.errors = new List<String>();
            this.AccountAzureId = null;
        }
    }
    
    public class AccountResponse {
        public String AgencyName;
        public boolean AppointedFlag;
        public AddressInfo BillingAddress;
        
    }
    
    public class AccountResponseGet {
        public String AgencyName;
        public boolean AppointedFlag;
        public AddressInfo BillingAddress;
        public List<string> DoingBusinessAs;
        public Decimal FEIN;
    }
    
    public class AddressInfo {
        public String addressLine1;
        public String addressLine2;
        public String city;
        public String state;
        public String postalCode;
        public String country;
        public String county; //06-21 on LyLong
    }
}