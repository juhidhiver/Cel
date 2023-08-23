/*************************************************
* Class Name: REST_Invsk_GetBrokerProfile
* Author: Priyanka Fulwani
* Created: 05-03-2020
* Description:
*************************************************/
@RestResource(urlMapping='/Invsk_GetBrokerProfile/*')
global with sharing class REST_Invsk_GetBrokerProfile{

	@HttpGet
	global static void doGet(){
		RestRequest req = RestContext.request;
		ResponseGetObject responseStatus = new ResponseGetObject();
		String brokerContactId = RestContext.request.params.get('brokerID');
		String productId = RestContext.request.params.get('productID');

		try{
			String requestString = req.requestBody.toString();
            system.debug('REQ--'+requestString);
			//Handle error
			if(String.isBlank(brokerContactId)|| String.isBlank(productId)){
				handleResponse(responseStatus,req,'Contact Broker Id Or Product Id is Empty',false,'Failed',400,'doGet','REST_Invsk_GetBrokerProfile');
				return;
			}
			List<Contact> contacts = [select AccountId,Account.Azure_ID__c,id, Account.Name, Account.FEIN__c,Account.Description,//Account.Tax_Code__c,
                                      Account.Phone,Account.Website,
											Account.BillingStateCode,Account.BillingCity,Account.BillingCountry,Account.BillingCountryCode,Account.BillingPostalCode,
											Account.BillingState,Account.BillingStreet,Account.Billing_County__c,
											Name, Email, Phone,Appointed_Flag__c, Azure_Id__c,NIPR_License_flag__c,Home_License_no__c,Type__c,
											MailingCity,MailingState,MailingStreet,MailingPostalCode,	MailingCountry, Mailing_County__c,
											FirstName,LastName
										from Contact
										where Azure_ID__c = :brokerContactId];
            if(contacts.isEmpty()){	
				handleResponse(responseStatus,req,'Contact Broker Id does not exist in Salesforce : [ '+brokerContactId+' ]',false,'Failed',400,'doGet','REST_Invsk_GetBrokerProfile');	
				return;	
            }
			//Create broker's contact details
			ContactDetailWrapper ContactWrapper = new ContactDetailWrapper();
            system.debug('ContactWrapper --'+ContactWrapper);
			ContactWrapper.homeLicense =contacts[0].Home_License_no__c + '';
			ContactWrapper.NIPRLicenseFlag =contacts[0].NIPR_License_flag__c + '';
			ContactWrapper.type =contacts[0].Type__c + '';
			ContactWrapper.contactAccountName = contacts[0].Name + '';
            ContactWrapper.contactId = contacts[0].Azure_ID__c + '';
            ContactWrapper.contactName = contacts[0].Name + '';
			// Added by Maeran for US:50111 on 22/9/2021
			ContactWrapper.contactFirstName = contacts[0].FirstName+ '';
			ContactWrapper.contactLastName = contacts[0].LastName+'';
			
            ContactWrapper.phone = contacts[0].Phone + '';
            ContactWrapper.appointedFlag = contacts[0].Appointed_Flag__c + '';
            
            
			//create broker's contact address
			AddressInfo contactInfor = new AddressInfo();
			contactInfor.addressLine1 = String.isNotBlank( contacts[0].MailingStreet) ? contacts[0].MailingStreet : '';
			contactInfor.city = String.isNotBlank(contacts[0].MailingCity) ? contacts[0].MailingCity : '';
			contactInfor.state = String.isNotBlank(contacts[0].MailingState) ? contacts[0].MailingState : '';
			contactInfor.postalCode = String.isNotBlank(contacts[0].MailingPostalCode) ? contacts[0].MailingPostalCode : '';
			contactInfor.country = String.isNotBlank(contacts[0].MailingCountry) ? contacts[0].MailingCountry : '';
			contactInfor.county = String.isNotBlank(contacts[0].Mailing_County__c) ? contacts[0].Mailing_County__c : '';
			ContactWrapper.address = contactInfor;
			responseStatus.brokerContactDetails = ContactWrapper;
			//create broker's account details
			AccountDetailWrapper accountWrapper = new AccountDetailWrapper();
			accountWrapper.accountName = contacts[0].Account.Name + '';
			accountWrapper.fEINNumber = contacts[0].Account.FEIN__c + '';
		//	accountWrapper.taxCode = contacts[0].Account.Tax_Code__c + '';
			accountWrapper.description = contacts[0].Account.Description + '';
			accountWrapper.website = contacts[0].Account.Website + '';
			accountWrapper.phone = contacts[0].Account.Phone + '';
			//create account's address detail
			AddressInfo addInfo = new AddressInfo();
			addInfo.addressLine1 = String.isNotBlank( contacts[0].Account.BillingStreet) ? contacts[0].Account.BillingStreet : '';
			addInfo.city = String.isNotBlank(contacts[0].Account.BillingCity) ? contacts[0].Account.BillingCity : '';
			addInfo.state = String.isNotBlank(contacts[0].Account.BillingStateCode) ? contacts[0].Account.BillingStateCode : '';
			addInfo.postalCode = String.isNotBlank(contacts[0].Account.BillingPostalCode) ? contacts[0].Account.BillingPostalCode : '';
			addInfo.country = String.isNotBlank(contacts[0].Account.BillingCountryCode) ? contacts[0].Account.BillingCountryCode : '';
			addInfo.county = String.isNotBlank(contacts[0].Account.Billing_County__c) ? contacts[0].Account.Billing_County__c : '';
			accountWrapper.address = addInfo;
			responseStatus.brokerAccountDetails = accountWrapper;
			//Get commission on Account product
			String commission = '';
			List<Account_Product__c> accProducts = [select Id,Commission_percentage__c from Account_Product__c where Product_Id__r.Azure_ID__c=:productId AND Account_Id__c = :contacts[0].AccountId];
			commission = (accProducts[0].Commission_percentage__c != null)?  accProducts[0].Commission_percentage__c + '': '';
			responseStatus.commission = commission;
			//Handle success
			handleResponse(responseStatus,req,null,true,'Success',200,'doGet','REST_Invsk_GetBrokerProfile');

		}catch(Exception ex){
			handleResponse(responseStatus,req,ex.getMessage() + ex.getLineNumber(),false,'Failed',400,'doGet','REST_Invsk_GetBrokerProfile');
		}
	}

	public static void handleResponse(ResponseGetObject responseStatus,RestRequest req,String errorMessage,Boolean  isSuccess, String status, Integer statusCode,String method,String apiName ){
		responseStatus.status = status;
		responseStatus.isSuccess = isSuccess;
		responseStatus.errors.add(errorMessage);
		RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
		RestContext.response.statusCode = statusCode;
		RestContext.response.addHeader('Content-Type', 'application/json');
		ApiUtil.logAPICallIn(req, RestContext.response, apiName, apiName+ '.' +method);
	}

	public class AddressInfo {
		public String addressLine1  			{get;set;}
		public String city 						{get;set;}
		public String state  					{get;set;}
		public String postalCode  				{get;set;}
		public String country 					{get;set;}
		public String county 					{get;set;}
	}

	public class AccountDetailWrapper{
		public String accountName			 {get;set;}
		public String fEINNumber      		 {get;set;}
		public String phone  				 {get;set;}
		public String taxCode  				 {get;set;}
		public String description 			 {get;set;}
		public String website  				 {get;set;}
		public AddressInfo address   		 {get;set;}
	}

	public class ResponseGetObject{
		public String status								{get; set;}
		public List<String> errors							{get; set;}
		public Boolean isSuccess							{get; set;}
		public ContactDetailWrapper brokerContactDetails 	{get; set;}
		public AccountDetailWrapper brokerAccountDetails 	{get; set;}
		public String commission							{get; set;}
		public ResponseGetObject() {
			this.status = null;
			this.isSuccess = false;
			this.errors = new List<String>();
		}
		}

	public class ContactDetailWrapper{
		public String type							{get;set;}
		public String homeLicense 					{get;set;}
		public String NIPRLicenseFlag 				{get;set;}
		public AddressInfo address					{get;set;}
		public String contactId						{get;set;}
		public String contactName 					{get;set;}
		public String contactFirstName 					{get;set;}
		public String contactLastName 					{get;set;}
		public String contactAccountName 			{get;set;}
		public String phone							{get;set;}
		public String appointedFlag    				{get;set;}
		public string contactAddress 				{get;set;}
        
	}



}