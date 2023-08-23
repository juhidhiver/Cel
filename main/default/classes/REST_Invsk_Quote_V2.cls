/*************************************************
* Class Name: REST_Invsk_Quote
* Author: Sarthak Roy
* Updated: 03-Nov-2020
* Description: Rest api for Quote object
*
*************************************************/
@RestResource(urlMapping='/Invsk_Quote_V2/*')
global with sharing class REST_Invsk_Quote_V2  {
    @HttpGet
    global static void getQuoteDetail() {
        String azureId = RestContext.request.params.get('quoteId');
        OutcomingResponseGet outResponse = new OutcomingResponseGet();
        try{
            if (String.isBlank(azureId)){
                outResponse.status = 'Failed';
                outResponse.isSuccess = false;
                outResponse.errors.add('Missing Azure Id');
                RestContext.response.statusCode = 500;
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                
                ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_Quote_V2', 'REST_Invsk_Quote_V2.getQuoteDetail');
                return;
            }
             Quote quote =[Select Id,Commission_percentage__c,Azure_ID__c, Effective_Date__c, QuoteNumber, ExpirationDate,
                          AccountId, Coverage_Product_Options__c, Master_Set_ID__c, Endorsement_Effective_Date__c,                
                          Quote_Type__c, Name, Status, Override_Premium__c, Override_Premium_Percentage__c,Parent_Quote__c, 
                          Technical_Premium__c,QuotePremium__c,Total_Premium__c,Opportunity.Name,Opportunity.Azure_ID__c,
                          Non_Prorated_Quote_Premium__c,Non_prorated_Total_Premium__c,    
                          (SELECT ID, Name, Azure_ID__c, Coverage_Type__c, Sub_Coverage__r.Id, 
                           Sub_Coverage__r.Name,Sub_Coverage__r.Coverage_Code__c, Coverage__r.Coverage_Code__c,
                           Coverage__r.Id, Coverage__r.Name, Coverage_Premium__c,Coverage__r.Coverage_Type__c,
                           Factor_Value__c, Coverage__r.Coverage_Product__c,
                           Factor_Min__c, Factor_Max__c, Increment_Step__c, 
                           Factor_Default_Value__c,Limits_Deductibles__c, 
                           Limits_Deductibles__r.Name, Limits_Deductibles__r.Type__c,
                           Limits_Deductibles__r.RecordTypeId,Limits_Deductibles__r.LmtDedCode__c,
                           Limits_Deductibles__r.RecordType.DeveloperName,
                           Limits_Deductibles__r.RecordType.Name, Max_amt__c, Min_amt__c,
                           Option_Type__c, Option_Value_Default__c,CoverageLineItemType__c,
                           Option_Picklist__c,Override_Premium__c, Rating__c  
                           FROM Coverages_Line_Items__r),
                          (SELECT Id, Name, Subjectivity__c, Subjectivity_Status__c, Subjectivity_Type__c, Stage__c, Due_Date__c 
                           FROM Subjectivity__r),
                          (SELECT Id, Name, Additional_Interest_Account__c, Quote__c, Azure_ID__c, Relationship_Type__c, 
                           Parent_Additional_Interest__c, Loan_Reference_number__c,Loss_Payee_Interest__c,Primary_Mortgage_Servicer__c, 
                           Entity_Type__c
                           FROM Additional_Interests__r),
                          (SELECT Id, AccountId__c,Azure_ID__c,OpportunityId__c, OriginCreation__c, 
                           Primary_Location__c,Name,Usage_Type__c,State_Review_Required__c,
                           Quote_Location__c.Locations__r.State_Province__c,
                           Quote_Location__c.Locations__r.Address__c,
                           Quote_Location__c.Locations__r.Azure_ID__c,
                           Quote_Location__c.Locations__r.City__c,
                           Quote_Location__c.Locations__r.Country__c,
                           Quote_Location__c.Locations__r.Country_Code__c,
                           Quote_Location__c.Locations__r.County__c,
                           Quote_Location__c.Locations__r.Geolocation__c,
                           Quote_Location__c.Locations__r.Name,
                           Quote_Location__c.Locations__r.Postal_Code__c,
                           Quote_Location__c.Locations__r.State_Code__c
                           FROM Quote_Locations__r) 
                          FROM Quote WHERE Azure_ID__c=:azureId];
            if(quote!=null){
                outResponse.status = 'OK';
                outResponse.isSuccess = true;
                outResponse.errors.clear();
                outResponse.quote = quote;
                RestContext.response.statusCode = 200;
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_Quote_V2', 'REST_Invsk_Quote_V2.getQuoteDetail');
                return;
            }
            if(quote==null){
                outResponse.status = 'Failed';
                outResponse.isSuccess = false;
                outResponse.errors.add('Invalid Azure Id');
                RestContext.response.statusCode = 500;
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_Quote_V2', 'REST_Invsk_Quote_V2.getQuoteDetail');
                return;
            }
        }
        catch(Exception ex){
            outResponse.status = 'Failed';
            outResponse.isSuccess = false;
            outResponse.errors.add('An error occurred '+ex.getMessage());
            RestContext.response.statusCode = 500;
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
            ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_Quote_V2', 'REST_Invsk_Quote_V2.getQuoteDetail');
            return;
        }
    }
    @HttpPost
    global static void createQuote() {
        RestRequest quoteRequest  = RestContext.request;
        String requestBody = quoteRequest.requestBody.toString();
        System.debug('requestBody'+requestBody);
        OutcomingResponsePost outResponse = new OutcomingResponsePost();
        //try{
            Quote quoteReq = (Quote)JSON.deserialize(requestBody, Quote.class);
             if(String.isBlank(quoteReq.OpportunityId)) {
                outResponse.status = 'Failed';
                outResponse.isSuccess = false;
                outResponse.errors.add('Opportunity Id is empty');

                RestContext.response.statusCode = 200;
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                RestResponse res = RestContext.response;

                ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_Quote_V2', 'REST_Invsk_Quote_V2.createQuote');
                return;
            }
            List<Opportunity> oppts = [Select Id, Name From Opportunity Where Azure_Id__c =: quoteReq.OpportunityId];
             if(oppts.isEmpty()) {
                outResponse.status = 'Failed';
                outResponse.isSuccess = false;
                outResponse.errors.add('Opportunity does not exist in Salesforce');

                RestContext.response.statusCode = 200;
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                RestResponse res = RestContext.response;

                ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_Quote_V2', 'REST_Invsk_Quote_V2.createQuote');
                return;
            }
            Quote parentQuote = new Quote();
            if(String.isNotBlank(quoteReq.Parent_Quote__c)){
                parentQuote = [Select Id,Azure_ID__c from Quote where Azure_ID__c =:quoteReq.Parent_Quote__c LIMIT 1];    
            }
            //Check whether the Quote exists
           List<Quote> exisQuoteList = [Select Id,Azure_ID__c from Quote where Azure_ID__c=:quoteReq.Azure_ID__c Limit 1];
            Integer quoteNumber = [Select count() from quote where OpportunityId=:oppts[0].Id];
            System.debug('quoteNumber'+quoteNumber);
            Quote newQuote = new Quote();
            newQuote.OpportunityId = oppts[0].Id;
            newQuote.Quote_Type__c = quoteReq.Quote_Type__c;
            if(String.isNotBlank(quoteReq.Parent_Quote__c)){
                newQuote.Parent_Quote__c = parentQuote.Id;              
            }   
             if(String.isNotBlank(quoteReq.Azure_ID__c)) {               
                  newQuote.Azure_ID__c = quoteReq.Azure_ID__c;                              
            }
            if(!exisQuoteList.isEmpty()){
                newQuote.id = exisQuoteList[0].id;
            }
            else{
                 newQuote.Name = (quoteNumber != null)? oppts[0].Name + ' ' + (quoteNumber + 1) : oppts[0].Name + ' 1';
            }
             upsert newQuote;
            
            
            Quote respQuote = [Select Id, Azure_ID__c from Quote where Azure_ID__c=:quoteReq.Azure_ID__c];
                outResponse.status = 'OK';
                outResponse.isSuccess = true;
                outResponse.errors.clear();
                outResponse.quote = respQuote;
                RestContext.response.statusCode = 200;
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_Quote_V2', 'REST_Invsk_Quote_V2.createQuote');
                return;
        /*}
        catch(Exception ex){
            outResponse.status = 'Failed';
            outResponse.isSuccess = false;
            outResponse.errors.add('An error occurred '+ex.getMessage());
            RestContext.response.statusCode = 500;
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
            ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_Quote_V2', 'REST_Invsk_Quote_V2.createQuote');
            return;
        }*/
    }
    public class OutcomingResponseGet {
        public String status                {get; set;}
        public Boolean isSuccess            {get; set;}
        public List<String> errors          {get; set;}
        public Quote quote   {get; set;}
        public OutcomingResponseGet() {
            this.status = null;
            this.isSuccess = false;
            this.errors = new List<String>();
            this.quote = new Quote();
        }
    }
    public class OutcomingResponsePost {
        public String status                {get; set;}
        public Boolean isSuccess            {get; set;}
        public List<String> errors          {get; set;}
        public Quote quote   {get; set;}
        public OutcomingResponsePost() {
            this.status = null;
            this.isSuccess = false;
            this.errors = new List<String>();
            this.quote = new Quote();
        }
    }
    
}