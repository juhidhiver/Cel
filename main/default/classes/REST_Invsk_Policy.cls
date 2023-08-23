/*************************************************
* Class Name: REST_Invsk_Policy 
* Author: Saumyak Pandey
* Date: 
* Requirement/Project Name: 
* Requirement/Project Description: 
*************************************************/

@RestResource(urlMapping='/Invsk_Policies/*')
global with sharing class REST_Invsk_Policy{
    
    @HttpPost
    global static void getPolicies() {
        RestRequest req = RestContext.request;        
        OutgoingResponse outResponse = new OutgoingResponse();                
        try{
            String channelKey = RestContext.request.headers.get('Channel-Key');            
            if(String.isBlank(channelKey)){
                setAPIErrorsLog(req,outResponse,'Missing Channel Key');
                return;
            }
            
            List<Account> channelAccount = [SELECT Id FROM Account Where Azure_Id__c =: channelKey];            
            if(channelAccount.isEmpty()){
                setAPIErrorsLog(req,outResponse,'Channel Key does not exist');
                return;
            }
            
            // get Broker Id from headers
            String brokerId = RestContext.request.headers.get('Broker-Key');
            if(String.isBlank(brokerId)){
                setAPIErrorsLog(req,outResponse,'Broker Id is blank');
                return;
            }
            
            // get list of Product of Channel Key
            Set<String> productIds = new Set<String>();
            for(Account_Product__c accProduct : [SELECT Id, Product_Id__c From Account_Product__c 
                                                 Where Account_Id__c =: channelAccount[0].Id]){
                                                     productIds.add(accProduct.Product_Id__c);
                                                 }
            
            Set<Id> opptIds = new Set<Id>();
            // Repeat Broker Account assosiated Contact
            for(Broker_Account__c ba : [Select Id,Opportunity__c From Broker_Account__c 
                                        Where Broker_Contact__r.Azure_Id__c =: brokerId
                                        And Opportunity__r.Product__c IN: productIds]){
                                            opptIds.add(ba.Opportunity__c);
                                        }
            
            if(opptIds.isEmpty()) {
                setAPIErrorsLog(req,outResponse,'Broker Account is empty');
                return;
            }
            
            IncomingRequest incRequest = (IncomingRequest) JSON.deserializeStrict(req.requestBody.toString(), IncomingRequest.class);
            
            List<String> fieldsList = new List<String>{'Id,Status,Quote_Type__c,Total_Premium__c,CreatedDate,Endorsement_Quote_Bound_Date__c, '
                +'Accept_Terror_Premium__c,Tax,Commission__c,Endorsement_Effective_Date__c,Sequence_Number__c,Product_Name__c, '
                +'Policy__r.Name,Policy__r.Policy_Number__c,Policy__r.Effective_Date__c, Policy__r.Expiration_Date__c, Opportunity.Name, '
                +'Policy__r.Initial_Premium__c,Policy__r.Total_Premium__c,Policy__r.Net_Endorsement__c,Policy__r.Account__c, '
                +'Policy__r.Cancellation_Date__c,Policy__r.Cancellation_Reason__c,Policy__r.Azure_ID__c,Policy__r.Policy_Status__c, '
                +'Policy__r.Product_Name__c,Policy__r.NIPR_Results__c,Policy__r.Binding_License_Number__c,Policy__r.NJ_Transaction_Code__c, '
                +'Policy__r.Invoice_Status__c,Policy__r.Policy_Document_sent__c,Policy__r.Number_Open_Subjectivity_Bound_Quote__c, '
                +'OpportunityId,Opportunity.AccountId,Opportunity.Account.Name,Opportunity.Account.Azure_ID__c,Opportunity.RecordType.Name, '
                +'Opportunity.Product__c,Opportunity.Product__r.Name,Opportunity.Product__r.Azure_ID__c,Policy__c, Opportunity.Account.Id,'
                +'(SELECT Id,QuoteId__c,CoverageName__c,Deleted_Record_Summary__c,FieldName__c,Name,New_Record_Summary__c,NewValue__c,'
                +' ObjectName__c,OldValue__c,Operation__c,SubCoverageName__c,Update_Record_Summary__c,Limit_Deductible__c, '
                +' QuoteId__r.Sequence_Number__c FROM QuoteEndorsementChangeSummaries__r),'
                +'(SELECT Id, Name, RecordTypeId, Document_Azure_Id__c, Document_Type__c, Quote_Id__c, Sent_to_Billing__c, Policy__c '
                +'FROM Document_Revisions__r)'};
                    
            Set<Id> policyIds = new Set<Id>();        
            List<Quote> quoteEndorsementList = new List<Quote>();
            
            // Account Id and Policy Id both are blank --- return all the accounts and policies 
            if(String.isBlank(incRequest.AccountId) && String.isBlank(incRequest.PolicyAzureId)){
                String condition = 'OpportunityId IN: opptIds And Policy__c != null Order By Opportunity.Account.Id ASC, Opportunity.Name ASC,Policy__r.Policy_Number__c ASC';
                for(Quote qt : Database.query( CommonUtil.buildQuery(fieldsList, 'Quote', condition))){                            
                    quoteEndorsementList.add(qt);
                    policyIds.add(qt.Policy__c);
                }
            }// Account Id is present and Policy Id is blank --- return all the policie
            else if(String.isNotBlank(incRequest.AccountId) && String.isBlank(incRequest.PolicyAzureId)){
                String value =  incRequest.AccountId;
                String condition = 'Opportunity.Account.Azure_ID__c =:value And Policy__c != null';
                for(Quote qt : Database.query( CommonUtil.buildQuery(fieldsList, 'Quote', condition))){                            
                    quoteEndorsementList.add(qt);
                    policyIds.add(qt.Policy__c);
                }
                
                if(quoteEndorsementList.isEmpty()){
                    setAPIErrorsLog(req,outResponse,'AccountId is not exist.');
                    return;
                }
            }// Account Id is blank and Policy Id is present 
            else if(String.isBlank(incRequest.AccountId) && String.isNotBlank(incRequest.PolicyAzureId)){
                String value =  incRequest.PolicyAzureId;
                String condition = 'Policy__r.Azure_ID__c =:value';
                for(Quote qt : Database.query( CommonUtil.buildQuery(fieldsList, 'Quote', condition))){                            
                    quoteEndorsementList.add(qt);
                    policyIds.add(qt.Policy__c);
                }
                
                if(quoteEndorsementList.isEmpty()){
                    setAPIErrorsLog(req,outResponse,'PolicyAzureId is not exist.');
                    return;
                }
            }
            
            // Create Document Revision Map with key is Policy__c Id
            Map<Id, List<Document_Revision__c>> docRevWithContIdMap = createDocumentRevisionMap(policyIds);
            Set<String> opptAndContDupls = new Set<String>();
            Map<Id, AccountWrapper> accWrapWithAccIdMap = new Map<Id, AccountWrapper>();
            Set<String> cancelOrBoundStatus = new Set<String> {'Cancelled', 'Bound'};
            Set<String> typeEndorsementQuotes = new Set<String> {'Amendment', 'Extension', 'Flat Cancellations', 'Mid Term Cancellation', 'Reinstatement'};
            Map<String, PolicyWrapper> policyWrapMap = new Map<String, PolicyWrapper>();
            String keyAccDuplId = '';
            system.debug('123 quoteEndorsementList ==' + quoteEndorsementList);
            
            for(Quote qt : quoteEndorsementList) {          
                // Check Opportunities have assosiated Policy__c
                if(opptIds.contains(qt.OpportunityId)) {
                    // Duplicate Account on Opportunity
                    if(accWrapWithAccIdMap.containsKey(qt.Opportunity.AccountId)){
                        keyAccDuplId = qt.Opportunity.AccountId;                    
                        AccountWrapper duplicateJPW = accWrapWithAccIdMap.get(keyAccDuplId);// Get Account Wrapper existed
                        String keyOpptCont = qt.OpportunityId + ''+ qt.Policy__c;// Create key is Opportunity Id and Policy__c Id
                        
                        // If not duplicate Oppt and Policy__c then create new Policy record
                        if(!policyWrapMap.containsKey(keyOpptCont)) {                        
                            PolicyWrapper policyWrap = createPolicyWrap(qt, docRevWithContIdMap);                        
                            if(cancelOrBoundStatus.contains(qt.Policy__r.Policy_Status__c) && typeEndorsementQuotes.contains(qt.Quote_Type__c) && qt.Status == 'Bound'){
                                EndorsementQuoteWrapper endorQuoteWrap = setEndorsementQuoteWrapper(qt);
                                policyWrap.EndorsementQuote.add(endorQuoteWrap);
                            }
                            
                            policyWrapMap.put(keyOpptCont, policyWrap);
                            duplicateJPW.policies.add(policyWrap);                        
                            accWrapWithAccIdMap.put(keyAccDuplId, duplicateJPW);
                        }else {                            
                            // the Endorsement Quotes with Bound,Cancelled Status along with the Endorsement Change Summary records
                            //only 'Bound' status endorsement quotes in the response of Get Policies API                            
                            if(cancelOrBoundStatus.contains(qt.Policy__r.Policy_Status__c) && typeEndorsementQuotes.contains(qt.Quote_Type__c) && qt.Status == 'Bound'){
                                EndorsementQuoteWrapper endorQuoteWrap = setEndorsementQuoteWrapper(qt);
                                policyWrapMap.get(keyOpptCont).EndorsementQuote.add(endorQuoteWrap);
                            }
                        }
                    } else {
                        if(!policyWrapMap.isEmpty()) {
                            AccountWrapper oldJPW = accWrapWithAccIdMap.get(keyAccDuplId);
                            oldJPW.policies.clear();
                            oldJPW.policies.addAll(policyWrapMap.values());
                            accWrapWithAccIdMap.put(keyAccDuplId, oldJPW);
                        }
                        
                        keyAccDuplId = qt.Opportunity.AccountId;
                        policyWrapMap = new Map<String, PolicyWrapper>(); // reset Oppt and Policy__c key when Account different
                        
                        // Create new Account Wrapper record
                        AccountWrapper newJPW = new AccountWrapper();
                        newJPW.accountId = qt.Opportunity.Account.Azure_ID__c;
                        newJPW.accountName = qt.Opportunity.Account.Name;
                        
                        PolicyWrapper policyWrap = createPolicyWrap(qt, docRevWithContIdMap);
                        
                        if(cancelOrBoundStatus.contains(qt.Policy__r.Policy_Status__c) && typeEndorsementQuotes.contains(qt.Quote_Type__c) && qt.Status == 'Bound'){
                            EndorsementQuoteWrapper endorQuoteWrap = setEndorsementQuoteWrapper(qt);
                            policyWrap.EndorsementQuote.add(endorQuoteWrap);
                        }
                        
                        newJPW.policies.add(policyWrap);
                        policyWrapMap.put(qt.OpportunityId + '' + qt.Policy__c, policyWrap);                    
                        // Create map with key is Account Id and  value is Account Wrapper record
                        accWrapWithAccIdMap.put(keyAccDuplId, newJPW);
                    }
                }
            }           
            
            outResponse.status = 'OK';
            outResponse.isSuccess = true;
            outResponse.errors.clear();
            outResponse.accounts.addAll(accWrapWithAccIdMap.values());
            
            RestContext.response.statusCode = 200;
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
            RestResponse res = RestContext.response;
            ApiUtil.logAPICallIn(req, res, 'REST_Invsk_Policies', 'REST_Invsk_Policies.getPolicies');
            
        } catch(Exception ex){
            setAPIErrorsLog(req,outResponse,CommonUtil.getExceptionMessage(ex));
        }
    }
    @testVisible
    private static EndorsementQuoteWrapper setEndorsementQuoteWrapper(Quote qt) {
        EndorsementQuoteWrapper endorQuoteWrap = new EndorsementQuoteWrapper();
        endorQuoteWrap.EndorsementCreatedDate =  Date.valueOf(qt.CreatedDate); 
        endorQuoteWrap.EndorsementBoundDate = qt.Endorsement_Quote_Bound_Date__c;                        
        endorQuoteWrap.EndorsementEffectiveDate = qt.Endorsement_Effective_Date__c;                        
        endorQuoteWrap.TermPremium = qt.Total_Premium__c;
        endorQuoteWrap.status = qt.Status;
        endorQuoteWrap.QuoteEndorsementChangeSummary = QuoteEndorsementChangeSummaryUtil.getMapQECSFilterSection(qt.QuoteEndorsementChangeSummaries__r);
        endorQuoteWrap.TerrorismPremium = String.valueOf(qt.Accept_Terror_Premium__c);
        endorQuoteWrap.Tax = String.valueOf(qt.Tax); 
        endorQuoteWrap.Commission = String.valueOf(qt.Commission__c);
        endorQuoteWrap.sequenceNumber = qt.Sequence_Number__c;
        //endorQuoteWrap.EndorsementDocumentID = (qt.Quote_Documents__r.isEmpty()? null: qt.Quote_Documents__r[0].Document_Azure_Id__c);//10-Dec-19 Hoang added     
                       
        return endorQuoteWrap;
    }
    
    /** Create Document Revisions Map assosiated Policy__c and newest Document type duplicate Policy__c
    *** @param: policyIds List of Policy__c Id */
    @testVisible
    private static Map<Id, List<Document_Revision__c>> createDocumentRevisionMap(Set<Id> policyIds) {
        Set<String> docTypePolicyDupl = new Set<String>();// Check Policy__c and Document type duplicate
        Set<Id> policyIdDupls = new Set<Id>();// Check Policy__c Id duplicate
        Map<Id, List<Document_Revision__c>> docRevWithContIdMap = new Map<Id, List<Document_Revision__c>>();
        
        // Repeat Document Revisions assosiated Policy__c
        for(Document_Revision__c docRev : [Select Id, Name,Policy__c, Policy__r.Policy_Number__c, Document_Azure_Id__c, Document_Type__c 
                                            From Document_Revision__c Where Policy__c IN: policyIds
                                            And (Document_Type__c = 'PolicyForm' OR Document_Type__c = 'Invoice') 
                                            Order By CreatedDate DESC]){
            String key = docRev.Policy__c + '' + docRev.Document_Type__c;
            if(!policyIdDupls.contains(docRev.Policy__c)){// If Policy__c Id did not duplicate
                policyIdDupls.add(docRev.Policy__c);
                docTypePolicyDupl.add(key);
                docRevWithContIdMap.put(docRev.Policy__c, new List<Document_Revision__c>{docRev});
            }else{ // If Policy__c and Document type do not duplicate
                if(!docTypePolicyDupl.contains(key)){
                    docTypePolicyDupl.add(key);
                    docRevWithContIdMap.get(docRev.Policy__c).add(docRev);
                }
            }
        }        
        return docRevWithContIdMap;
    }
    @testVisible
    private static PolicyWrapper createPolicyWrap(Quote qt, Map<Id, List<Document_Revision__c>> docRevMap) {
        PolicyWrapper policyWrap = new PolicyWrapper();
        policyWrap.productId = qt.Opportunity.Product__r.Azure_ID__c;
        policyWrap.productName = qt.Opportunity.Product__r.Name;
        policyWrap.status = qt.Policy__r.Policy_Status__c;
        policyWrap.policyNumber = qt.Policy__r.Policy_Number__c;
        policyWrap.policyId = qt.Policy__r.Azure_ID__c;
        policyWrap.TermPremium = qt.Policy__r.Total_Premium__c;
        policyWrap.effectiveDate = qt.Policy__r.Effective_Date__c;
        policyWrap.expireDate = qt.Policy__r.Expiration_Date__c;
                
        if(docRevMap.containsKey(qt.Policy__c)) {
            for(Document_Revision__c dr : docRevMap.get(qt.Policy__c)) {
                if(dr.Document_Type__c == 'PolicyForm') policyWrap.DocumentID.add(dr.Document_Azure_Id__c);
                if(dr.Document_Type__c == 'Invoice') policyWrap.InvoiceDocumentID.add(dr.Document_Azure_Id__c);
            }       
        }        
        return policyWrap;
    }
    
    private static void setAPIErrorsLog(RestRequest req, OutgoingResponse res, String errMessage) {
        res.status = 'Failed';
        res.isSuccess = false;
        res.errors.add(errMessage);
        RestContext.response.statusCode = 200;
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));
        ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_Policies', 'REST_Invsk_Policies.getPolicies');
    }
    
    public class OutgoingResponse {
        public String status                   {get; set;}
        public Boolean isSuccess               {get; set;}
        public List<String> errors             {get; set;}
        public List<AccountWrapper> accounts   {get; set;}
        public OutgoingResponse() {
            this.status = null;
            this.isSuccess = false;
            this.errors = new List<String>();
            this.accounts = new List<AccountWrapper>();
        }
    }
    
    public class AccountWrapper {
        public String accountId             {get; set;}
        public String accountName           {get; set;}
        public List<PolicyWrapper> policies {get; set;}
        public AccountWrapper() {
            accountId = '';
            accountName = '';
            policies = new List<PolicyWrapper>();
        }
    }
    
    public class PolicyWrapper {
        public String productId                               {get; set;}
        public String productName                             {get; set;}
        public String status                                  {get; set;}
        public String policyNumber                            {get; set;}
        public String policyId                                {get; set;}
        public Decimal TermPremium                            {get; set;}
        public Date effectiveDate                             {get; set;}
        public Date expireDate                                {get; set;} 
        public List<String> DocumentID 						  {get; set;}        
        public List<String> InvoiceDocumentID                 {get; set;}      
        public List<EndorsementQuoteWrapper> EndorsementQuote {get; set;}        
        public PolicyWrapper() {
            productId = '';
            productName = '';
            status = '';
            policyNumber = '';
            policyId = '';
            TermPremium = null;
            effectiveDate = null;
            expireDate = null;           
            DocumentID = new List<String>();
            InvoiceDocumentID = new List<String>();  
            EndorsementQuote = new List<EndorsementQuoteWrapper>();
        }
    }
    
    public class EndorsementQuoteWrapper {
        public Decimal TermPremium                    {get; set;}
        public String status                          {get; set;}
        public String EndorsementDocumentID           {get; set;}      
        public Date EndorsementCreatedDate            {get; set;}
        public Datetime EndorsementBoundDate          {get; set;}
        public Map<String,List<QuoteEndorsementChangeSummaryUtil.QuoteEndorsementChangeSummaryInfo>> QuoteEndorsementChangeSummary {get; set;}
        public String TerrorismPremium; 
        public String Tax; 
        public String Commission;         
        public Date endorsementEffectiveDate          {get; set;}
        public decimal sequenceNumber                 {get; set;} 
    } 
    
    public class IncomingRequest {        
        public String AccountId         {get; set;}
        public String PolicyAzureId     {get; set;}         
    }
}