/*************************************************
* Class Name: REST_Invsk_Broker
* Author: 
* Created: 
* Description: Broker Contact API 
* * Updated:               
*************************************************/
@RestResource(urlMapping='/Invsk_Broker/*')
global with sharing class REST_Invsk_Broker 
{

	@HttpPost
	global static void doPost(){
		RestRequest req = RestContext.request;
		ResponsePostObject responseStatus = new ResponsePostObject();
		
		Savepoint sp = Database.setSavepoint();
		try {
			String requestString = req.requestBody.toString();
	        CommingRequest request = (CommingRequest)JSON.deserialize(requestString, CommingRequest.class);
	        system.debug('###request####' + request);

	        Boolean hasError = false;

	        Opportunity opp = null;
			List<Opportunity> opps = [Select Id From Opportunity Where Azure_ID__c = :request.OpportunityId];
			if (!opps.isEmpty()) opp = opps[0];

			Contact con = null;
			List<Contact> cons = [SELECT Id, Azure_ID__c From Contact Where Azure_ID__c =: request.ContactId LIMIT 1];
			if (!cons.isEmpty()) con = cons[0];

	        if (String.isBlank(request.OpportunityId) 
        	|| String.isBlank(request.ContactId) 
        	|| opp == null 
        	|| con == null) {
	        	hasError = true;
				String errMsg ='';
				if(String.isBlank(request.OpportunityId) || request.OpportunityId == 'null') errMsg='Missing OpportunityId parameter';
				if(String.isBlank(request.ContactId) || request.ContactId == 'null') errMsg='Missing ContactId parameter';
				if(opp == null) errMsg='The Opportunity is not existing on Database ';
				if(con == null) errMsg='The Contact is not existing on Database ';
	        	responseStatus.status = 'Failed';
	        	responseStatus.isSuccess = false;
	        	responseStatus.errors.add(errMsg);
	        	RestContext.response.statusCode = 200;
	            RestContext.response.addHeader('Content-Type', 'application/json');
	            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
	        	ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_Broker', 'REST_Invsk_Broker.doPost');
				return;
	        }
		
			//String contactAzureId = [Select Azure_ID__c From Contact Where Id = :con.Id][0].Azure_ID__c;
			List<Broker_Account__c> brokers = new List<Broker_Account__c>([Select Id, IsPrimaryBroker__c From Broker_Account__c 
																			Where Opportunity__c =: opp.Id 
																			And IsPrimaryBroker__c = true]) ;
			if(!brokers.isEmpty()){
				for(Broker_Account__c broker : brokers){
					broker.IsPrimaryBroker__c = false;
				}

				update brokers;
			}
			//String contactAzureId = con.Azure_ID__c;
			Broker_Account__c newBrokerAccount = new Broker_Account__c(
													Broker_Contact__c = con.Id,
													Relationship_Type__c = 'Broker',
													IsPrimaryBroker__c = true,
													Opportunity__c = opp.Id
													);
			insert newBrokerAccount;
		
			/////////////
			responseStatus.status = 'Success';
	        responseStatus.isSuccess = true;
            //responseStatus.ContactId = contactAzureId;
			//responseStatus.AccountId = contactAzureId;
			responseStatus.errors.clear();

	        RestContext.response.statusCode = 200;
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
            ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_Broker', 'REST_Invsk_Broker.doPost');

	    } catch(Exception ex) {
	    	system.debug('@@@ REST_Invsk_Broker.doPost.ex found= ' + ex.getMessage() + ', location: ' + ex.getStackTraceString());
			Database.rollback(sp);
        	responseStatus.status = 'Failed';
        	responseStatus.isSuccess = false;
        	responseStatus.errors.add(CommonUtil.getExceptionMessage(ex));
        	RestContext.response.statusCode = 200;
	        RestContext.response.addHeader('Content-Type', 'application/json');
	        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
	        ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_Broker', 'REST_Invsk_Broker.doPost');
	    }
        
	} 
@HttpGet
	global static void doGet(){
		RestRequest req = RestContext.request;
		ResponseGetObject responseStatus = new ResponseGetObject();
        String strEmail = RestContext.request.params.get('brokerEmail');
       
		try{
           
			String requestString = req.requestBody.toString();
			Boolean hasError = false;
	   
			if(String.isBlank(strEmail)||strEmail=='null'||!validateEmail(strEmail))
			{
				String errorMsg='';
				if(String.isBlank(strEmail)||strEmail=='null') errorMsg = 'Missing Email input';
				else errorMsg = 'Got the wrong pattern of email';

	        	hasError = true;
	        	responseStatus.status = 'Failed';
	        	responseStatus.isSuccess = false;
	        	responseStatus.errors.add(errorMsg);
	        	RestContext.response.statusCode = 200;
	            RestContext.response.addHeader('Content-Type', 'application/json');
	            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
	        	ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_Broker', 'REST_Invsk_Broker.doGet');
				return;
	        }
			
			//Set<WrapperObject> responseSet = new Set<WrapperObject>();
			Map<String,WrapperObject> responseMap = new Map<String,WrapperObject>();

			for(List<Broker_Account__c> brokers : [SELECT Id, Broker_Contact__c, Opportunity__c , 
														Broker_Contact__r.Name, Broker_Contact__r.Phone,
														Broker_Contact__r.Account.Name,
                                                        Broker_Contact__r.Account.FEIN__c,
														Broker_Contact__r.Azure_ID__c,
                                                   		Broker_Contact__r.Appointed_Flag__c
														FROM Broker_Account__c WHERE Broker_Contact__r.Email =: strEmail]){
             	
				for(Broker_Account__c broker : brokers){
					WrapperObject wo = new WrapperObject();

					wo.BrokerAccountName = broker.Broker_Contact__r.Account.Name;
            		wo.BrokerContactId = broker.Broker_Contact__r.Azure_ID__c;
                    wo.FEINNumber = String.valueOf(broker.Broker_Contact__r.Account.FEIN__c);
					wo.BrokerContactName = broker.Broker_Contact__r.Name;
					wo.BrokerPhone = broker.Broker_Contact__r.Phone;
					wo.AppointedFlag = broker.Broker_Contact__r.Appointed_Flag__c;
					//if(!responseSet.contains(wo))   responseSet.add(wo);
					responseMap.put(wo.BrokerContactId,wo);
				}
 			}
            
            if(responseMap.isEmpty())
            {
                list<Contact> ConList = [select id, Name, Email, Phone, Account.Name, Account.FEIN__c,Appointed_Flag__c, Azure_Id__c from Contact
                                           where Email = :strEmail];
                    
                    WrapperObject wo = new WrapperObject();
                
                for(Contact Con: Conlist)
                {
					wo.BrokerAccountName = Con.Account.Name;
            		wo.BrokerContactId = Con.Azure_ID__c;
					wo.BrokerContactName = Con.Name;
					wo.BrokerPhone = Con.Phone;
                    wo.FEINNumber = String.valueOf(con.Account.FEIN__c);
					wo.AppointedFlag = Con.Appointed_Flag__c;
					//if(!responseSet.contains(wo))   responseSet.add(wo);
					responseMap.put(wo.BrokerContactId,wo);
                
                }
            }

			if(responseMap.isEmpty())
			{
				String errorMsg='';
				
	        	hasError = true;
	        	responseStatus.status = 'Failed';
	        	responseStatus.isSuccess = false;
	        	responseStatus.errors.add('Broker email Id does not exist in the system');
	        	RestContext.response.statusCode = 200;
	            RestContext.response.addHeader('Content-Type', 'application/json');
	            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
	        	ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_Broker', 'REST_Invsk_Broker.doGet');
				return;
	        }

            responseStatus.status = 'Success';
	        responseStatus.isSuccess = true;
	       
			//responseStatus.objs = new List<WrapperObject>(responseSet);
			responseStatus.objs = responseMap.values();

	        RestContext.response.statusCode = 200;
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
           	ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_Broker', 'REST_Invsk_Broker.doGet');
        }catch(Exception ex){
        	responseStatus.status = 'Failed';
        	responseStatus.isSuccess = false;
        	responseStatus.errors.add(CommonUtil.getExceptionMessage(ex));
        	RestContext.response.statusCode = 200;
	        RestContext.response.addHeader('Content-Type', 'application/json');
	        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
	       	ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_Broker', 'REST_Invsk_Broker.doGet');
	    }
	}

	public class CommingRequest{
		public String OpportunityId			{get; set;}
		//public String AccountId				{get; set;}  
		public String ContactId				{get; set;} 
	
		//public ContactWrapper ContactDetail	{get; set;} 
	}

	public class ResponsePostObject {
        public String status					{get; set;}
        public Boolean isSuccess				{get; set;}
        public List<String> errors				{get; set;}

		//public String AccountId					{get; set;}
		//public String ContactId					{get; set;}
	
        public ResponsePostObject() {
            this.status = null;
            this.isSuccess = false;
            this.errors = new List<String>();
			
			//this.ContactId = '';
	    }
    }

	public class ResponseGetObject{
	    public String status			{get; set;}
	    public List<String> errors		{get; set;}
	    public Boolean isSuccess		{get; set;}
		public List<WrapperObject> objs {get; set;}

		public ResponseGetObject() {
            this.status = null;
            this.isSuccess = false;
            this.errors = new List<String>();
	
			this.objs = new List<WrapperObject>();
        }
	}
	
	public class WrapperObject{
		public String BrokerContactId	{get; set;}
		public String BrokerContactName {get; set;}
		public String BrokerAccountName {get; set;}
		public String BrokerPhone		{get; set;} 
        public boolean AppointedFlag    {get;set;}
        public String FEINNumber       {get;set;}
	}
	
	public static Boolean validateEmail(String email) {
		Boolean res = true;
	
		String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'; 
		Pattern MyPattern = Pattern.compile(emailRegex);
		Matcher MyMatcher = MyPattern.matcher(email);

		if (!MyMatcher.matches()) 
			res = false;
		return res;	
	}
}