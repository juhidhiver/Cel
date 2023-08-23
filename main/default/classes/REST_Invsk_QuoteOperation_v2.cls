/**************************************************************************************************
* Class Name: REST_Invsk_QuoteOperation_v2
* Author: Priyanka Fulwani
* Created date: 04-Nov-2020
* Description: REST web service API for Quote Operation v2
**************************************************************************************************/
@RestResource(urlMapping='/Invsk_QuoteOperation_v2/*')
global with sharing class REST_Invsk_QuoteOperation_v2 {
    @HttpPost
    global static void doPost() {
        
        OutcomingResponse outResponse = new OutcomingResponse();
        RestRequest req = RestContext.request;
        CommingRequest commingRequest = (CommingRequest) JSON.deserializeStrict(req.requestBody.toString(), CommingRequest.class);
        
        try {
            
            if (String.isBlank(commingRequest.quoteAzureId)) {
                outResponse.status = 'Failed';
                outResponse.isSuccess = false;
                outResponse.errors.add('Quote AzureId cannot be Empty');
                RestContext.response.statusCode = 400;
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_QuoteOperation_v2', 'REST_Invsk_QuoteOperation_v2.doPost');
                return;
            }
            
            List<Quote> QuoteList = [SELECT Id,Azure_Id__c,Status,Product_Name__c FROM Quote WHERE Azure_Id__c = :commingRequest.quoteAzureId];
            
            if(QuoteList.isEmpty()) {
                outResponse.status = 'Failed';
                outResponse.isSuccess = false;
                outResponse.errors.add('Invalid Quote AzureId');
                RestContext.response.statusCode = 400;
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_QuoteOperation_v2', 'REST_Invsk_QuoteOperation_v2.doPost');
                return;
            } 
            
            if (commingRequest.operation != 'FinalizeQuote'
                && commingRequest.operation != 'BindQuote'
                && commingRequest.operation != 'StatusUpdate'
                && commingRequest.operation != 'ChangeSummary') {
                    outResponse.status = 'Failed';
                    outResponse.isSuccess = false;
                    outResponse.errors.add('INVALID OPERATION');
                    RestContext.response.statusCode = 200;
                    RestContext.response.addHeader('Content-Type', 'application/json');
                    RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                    ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_QuoteOperation_v2', 'REST_Invsk_QuoteOperation_v2.doPost');
                    return;
                }
            
            if (commingRequest.operation == 'StatusUpdate' && String.isBlank(commingRequest.status)) {
                outResponse.status = 'Failed';
                outResponse.isSuccess = false;
                outResponse.errors.add('Status value is required for operation StatusUpdate');
                RestContext.response.statusCode = 200;
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_QuoteOperation_v2', 'REST_Invsk_QuoteOperation_v2.doPost');
                return;
            }
            
            if(commingRequest.operation == 'ChangeSummary'){
                QuoteEndorsementChangeSummaryCtrl.getQuoteEndorsementChangeSummary(QuoteList[0].Id,true);
            }
            
            if(commingRequest.operation == 'FinalizeQuote'){
                
                ResultResponse result =  FinalizeQuoteController.finalizeQuote(QuoteList[0].Id);
                 outResponse.status = 'Passed';
                 outResponse.isSuccess = true;
                system.debug('result==>'+result);
                if(!result.errors.isEmpty()){
                    outResponse.status = 'Failed';
                    outResponse.isSuccess = false;
                    outResponse.errors.add(result.errors[0]);
                    RestContext.response.statusCode = 400;
                    RestContext.response.addHeader('Content-Type', 'application/json');
                    RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                    ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_QuoteOperation_v2', 'REST_Invsk_QuoteOperation_v2.doPost');
                    return;   
                }
                
            }else if(commingRequest.operation == 'BindQuote'){
                if(QuoteList[0].Status =='Quoted' || QuoteList[0].Status =='Presented' || QuoteList[0].Status =='Bound Pending'){
                    system.debug('PN->'+QuoteList[0].Product_Name__c);
                    BindQuoteController.bindQuoteIncoming(QuoteList[0].Id, commingRequest.billingType, false);
                    if (QuoteList[0].Product_Name__c == 'Cyber Standalone' || QuoteList[0].Product_Name__c == 'MPL Standalone' ){
                       BindQuoteController.bindQuoteWithBLInfo(QuoteList[0].Id, commingRequest.billingType, false, req.requestBody.toString());
                       system.debug('Bind all license info');
                    }
                    outResponse.status = 'Passed';
                    outResponse.isSuccess = true;
                }
                else{
                    outResponse.status = 'Failed';
                    outResponse.isSuccess = false;
                    outResponse.errors.add('The Quote Status must be Quoted/Presented/Bound Pending to Bind Quote.');
                    RestContext.response.statusCode = 400;
                    RestContext.response.addHeader('Content-Type', 'application/json');
                    RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                    ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_QuoteOperation_v2', 'REST_Invsk_QuoteOperation_v2.doPost');
                    return;   
                }
                //Fetch latest generated Policy Id -
                Quote quote = [Select Id, Policy__r.Policy_Number__c,Endorsement_Quote_Bound_Date__c, 
                               Sequence_Number__c,Policy__r.Policy_Status__c, Azure_Id__c, Policy__c, Quote_Type__c
                               FROM QUOTE WHERE Azure_Id__c =:commingRequest.quoteAzureId];
                // Added for US:52026 on 23/9/2021
                if(String.isNotBlank(commingRequest.policyBoundDate)){
                    quote.Endorsement_Quote_Bound_Date__c = Datetime.valueOf(commingRequest.policyBoundDate);
                    TriggerHandler.bypass('QuoteTriggerBaseHandler');
                    update quote;
                    TriggerHandler.clearBypass('QuoteTriggerBaseHandler');  

                }

                if(String.isNotBlank(quote.Policy__c))
                {
                    if(commingRequest.paymentDetails != null) // Check and insert Payment Detail
                    { 
                        commingRequest.paymentDetails.Policy__c = quote.Policy__c;
                        insert commingRequest.paymentDetails;
                    }
                    
                    String quoteType = quote.Quote_Type__c;                   
                    String contractStatus = quote.Policy__r.Policy_Status__c;
                    // Added for US:52026 on 23/9/2021
                    Policy__c policy = new Policy__c(Id = quote.Policy__c);
                    if(String.isNotBlank(commingRequest.policyAzureId)){
                        policy.Azure_ID__c = commingRequest.policyAzureId;
                    }
                    if(String.isNotBlank(commingRequest.policyNumber)){
                        policy.Policy_Number__c = commingRequest.policyNumber;
                    }

                    if((quoteType == 'Midterm Cancellation' || quoteType == 'Flat Cancellation') && contractStatus=='Cancelled')
                    {                        
                        
                        policy.Cancellation_Date__c =String.isNotBlank(commingRequest.CancellationDate)?Date.valueOf(commingRequest.CancellationDate):null;
                        policy.Cancellation_Reason__c = String.isNotBlank(commingRequest.CancellationReason)?commingRequest.CancellationReason:null;
                       
                    }
                    update policy;
                }
                outResponse.result.put('PolicyNumber', quote.Policy__r.Policy_Number__c);
                outResponse.result.put('Quote Type', quote.Quote_Type__c);
                outResponse.result.put('BoundDateTime', quote.Endorsement_Quote_Bound_Date__c.format('YYYY-MM-dd kk:mm:ss'));
            } 
            else if (commingRequest.operation == 'StatusUpdate') {
                
                Quote currentQuote = QuoteList[0];
                currentQuote.Status = commingRequest.status;
                if (currentQuote.Status == 'Quoted') {
                    currentQuote.Rating_Status__c = 'Clear';
                }
                if (currentQuote.Status == 'Closed') {
                    currentQuote.Closed_Reason__c = commingRequest.closedReason;
                }
                update currentQuote;
                outResponse.result.put('closedReason', commingRequest.closedReason);
            }
            
        Quote Quoteresult = [SELECT Azure_Id__c, Status,Rating_Status__c, (select Id, Document_Azure_Id__c from Document_Revisions__r) FROM Quote WHERE Azure_Id__c = :commingRequest.quoteAzureId];
        
        outResponse.result.put('quoteId', commingRequest.quoteAzureId);
        outResponse.result.put('Quote Status', Quoteresult.Status);
        if(Quoteresult.Status =='Quoted' && Quoteresult.Rating_Status__c =='Clear')
        outResponse.result.put('documentId', Quoteresult.Document_Revisions__r[0].Document_Azure_Id__c);
        
        RestContext.response.statusCode = 200;
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
            outResponse.status = 'Success';
            outResponse.isSuccess = true;
            outResponse.errors.clear();
        } catch (Exception ex) {
            outResponse.status = 'Failed';
            outResponse.isSuccess = false;
            outResponse.errors.add(CommonUtil.getExceptionMessage(ex)); 
        } 
        ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_QuoteOperation_v2', 'REST_Invsk_QuoteOperation_v2.doPost');       
        
    }
    public class CommingRequest {
        public String quoteAzureId;
        public String operation;
        public String status;
        public String channelType;
        public String closedReason;
        public String CancellationDate; 
        public String CancellationReason;
        public Payment_Detail__c paymentDetails;
        public String billingType; 
        // Added by Maeran for US: 52026
        public String policyNumber; 
        public String policyAzureId; 
        public String policyBoundDate; 
        //Added by Juhi for US: 57225
        public String bindingLicenseNumber;
        public String bindingLicenseOwner;
        public String bindingLicenseOwnerAddress;
        public String bindingLicenseOwnerName;
        public Boolean IsSignaturePackUploaded;
    }
    
    public class OutcomingResponse {
        public String status                {get; set;}
        public List<String> errors          {get; set;}
        public Boolean isSuccess            {get; set;}
        public Map<String, Object> result   {get; set;}
        
        public OutcomingResponse() {
            this.status = null;
            this.isSuccess = false;
            this.errors = new List<String>();
            this.result = new Map<String, Object>();
        }
    }
    
}