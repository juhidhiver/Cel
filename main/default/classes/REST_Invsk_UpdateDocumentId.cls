/*************************************************
* Class Name: REST_Invsk_UpdateDocumentId
* Author: Vinith K
* Created: 15 Feb 2021
* Description:
*************************************************/
@RestResource(urlMapping='/Invsk_UpdateDocumentId/*')
global with sharing class REST_Invsk_UpdateDocumentId {
    
    /*************************************************
* Method Name: doGet
* Author: Trupti Tamboli
* Created: 15 Feb 2021
* Params:
* Return:
* Description: get list document revision
*************************************************/
    @HttpGet
    global static void doGet(){
        RestRequest req = RestContext.request;
        ResponseGetObject responseStatus = new ResponseGetObject();
        String quoteAzureId = RestContext.request.params.get('quoteId');
        try{
            //Handle error
            if(String.isBlank(quoteAzureId)){
                handleResponse(responseStatus,req,'Quote id is Empty',false,'Failed',200,'doGet','REST_Invsk_UpdateDocumentId');
                return;
            }
            List<Quote> quotes = [select Id,Policy__c,Azure_ID__c from Quote where Azure_ID__c = :quoteAzureId];
            List<Document_Revision__c> docs = [select Id,name,Document_Type__c from Document_Revision__c where Quote_Id__r.Azure_ID__c = :quoteAzureId or Policy__c = :quotes[0].Policy__c ];
            if(docs.isEmpty()) {
                handleResponse(responseStatus,req,'Quote id is not exist',false,'Failed',200,'doGet','REST_Invsk_UpdateDocumentId');
                return;
            }
            List<ResponseBodyWrapper> docInfos = new List<ResponseBodyWrapper>();
            
            for(Document_Revision__c doc : docs){
                ResponseBodyWrapper documentInfor = new ResponseBodyWrapper();
                documentInfor.docName = String.isNotBlank(doc.Name ) ? doc.Name  : '';
                documentInfor.docType = String.isNotBlank(doc.Document_Type__c ) ? doc.Document_Type__c  : '';
                documentInfor.docRevisionId = String.isNotBlank(doc.Id ) ? doc.Id  : '';
                docInfos.add(documentInfor);
            }
            responseStatus.documentInfo = docInfos;
            handleResponse(responseStatus,req,null,true,'Success',200,'doGet','REST_Invsk_UpdateDocumentId');
        }catch(Exception ex){
            handleResponse(responseStatus,req,ex.getMessage() + ex.getLineNumber(),false,'Failed',200,'doGet','REST_Invsk_UpdateDocumentId');
        }
    }
    /*************************************************
* Method Name: dopost
* Author: Vinith K
* Date: 15 Feb 2021
* Params: quoteId
* Return:
* Description: update document azure Id
*************************************************/
    @HttpPost
    global static void dopost()
    {
        RestRequest req = RestContext.request;
        OutComingResponse outResponse = new OutComingResponse();
        Savepoint ss = Database.setSavepoint();
        try{
            //parse request to list ComingRequestWrapper
            List<ComingRequestWrapper> inComingRequests = (List<ComingRequestWrapper>)JSON.deserialize(req.requestBody.toString(),List<ComingRequestWrapper>.class );
          
            if(inComingRequests == null){//handle request is incorrect format
                handleResponseDoPost(outResponse,req,'Invalid Request',false,'Failed',200,'doPost','REST_Invsk_UpdateDocumentId');
                return;
            }
            //Map key is quote Azure Id value is ComingRequestWrapper
            Map<String,List<ComingRequestWrapper>> mapWrapper = new Map<String, List<ComingRequestWrapper>>();
            for(Integer i =0;i<=inComingRequests.size() - 1;i++){
                if(!validRequest(inComingRequests[i],outResponse,req,i+1)) continue;
             
                if(!mapWrapper.containsKey(inComingRequests[i].quoteId)){
                    mapWrapper.put(inComingRequests[i].quoteId,new List<ComingRequestWrapper>{inComingRequests[i]});
                }else{
                    mapWrapper.get(inComingRequests[i].quoteId).add(inComingRequests[i]);
                }
            }
            
            //Query update
            List<Quote> quotes = [select Id,Status,Policy__c,AccountId, Azure_ID__c,Product_Name__c, Endorsement_Effective_Date__c, Effective_Date__c,Quote_Type__c,Policy__r.Effective_Date__c, Policy__r.Expiration_Date__c, Policy__r.Policy_Number__c from Quote where Azure_ID__c in :mapWrapper.keySet()];
            Set<String> policyIds = new Set<String>();
            for(Quote q : quotes){
                policyIds.add(q.Policy__c);
            }
            Map<String,String> docRevisionSfMap = new Map<String, string>();
            for(Document_Revision__c docRevision : [select Id,Document_Azure_Id__c,Quote_Id__c,Policy__c ,Document_Type__c
                                                    from Document_Revision__c
                                                    where Quote_Id__r.Azure_ID__c in : mapWrapper.keySet() Or Policy__c in:policyIds  Order by CreatedDate DESC ]) {
                  String key;
                   if(docRevision.Policy__c != NULL){
                      key  = docRevision.Document_Type__c + docRevision.Quote_Id__c +docRevision.Policy__c ;                                
                  }else{
                       key = docRevision.Document_Type__c + docRevision.Quote_Id__c;                                  
                  }
                     if(!docRevisionSfMap.containsKey(key)){
                             docRevisionSfMap.put(key,docRevision.Id);
                        system.debug('docRevisionSfMap-->'+docRevisionSfMap);
                       }
                   }
            List<Document_Revision__c> listUpsert = new List<Document_Revision__c>();
            Id docPolicyRecordType = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId();
            Id rdQuoteId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByDeveloperName().get('Quote').getRecordTypeId();
            string docName;
            //Todo: Process logic insert and update
            for(Quote q : quotes){
                for(ComingRequestWrapper docWrapper : mapWrapper.get(q.Azure_ID__c) ) {
                    Document_Revision__c doc = new Document_Revision__c(Document_Azure_Id__c=docWrapper.docId,Document_Type__c = docWrapper.docType,Name = docWrapper.Name,Is_ShopX__c = true);
                     system.debug('QID 2---> '+q.id);
                    if(docWrapper.docType == 'QuoteProposal' ){
                        doc.RecordTypeId = rdQuoteId;
                        doc.Quote_Id__c = q.id;
                        
                    }else if(docWrapper.docType != 'QuoteProposal' && docWrapper.docType !='SOA'){                      
                        doc.RecordTypeId = docPolicyRecordType;
                        doc.Policy__c = q.Policy__c;
						 if(docWrapper.docType == 'ChangeEndorsement'){ 
                     		doc.Quote_Id__c = q.Id;
                         }
                    } else{//other case policy doc                        
                        doc.RecordTypeId = docPolicyRecordType;
                        doc.Policy__c = q.Policy__c;
                    }
                    if(String.isBlank(doc.Quote_Id__c))  doc.Quote_Id__c = q.Id; //Added by Juhi to handle doctypes based value - BUG 57496
                    //check document is exist in Sf
                    
                    //Change part2 
                    String key;
                    if(doc.Policy__c != NULL){
                         key = doc.Name+doc.Document_Type__c + doc.Quote_Id__c +doc.Policy__c;
                    }else{
                         key = doc.Name+doc.Document_Type__c + doc.Quote_Id__c;
                    }
                    system.debug('KEY-->'+key);
                    if(docRevisionSfMap.containsKey(key)) doc.id = docRevisionSfMap.get(key);
                    listUpsert.add(doc);
                    system.debug('listUpsert-->'+listUpsert);
                }
            }

            //Todo : upsert data partial
            Set<String> idsUpsert = new Set<String>();
            if(!listUpsert.isEmpty()){
                Database.UpsertResult [] upsertResult = Database.upsert(listUpsert, false);
                for(Database.UpsertResult item :upsertResult){
                    if(item.isSuccess()){
                        idsUpsert.add(item.getId());
                    } else {
                        outResponse.errors.add('Error:'+String.join(item.getErrors(),','));
                    }
                }
            }
            
           //Added by Vinayesh : US-52358
            List<Document_Revision__c> updatedDocuments = [select Id,Document_Azure_Id__c,Quote_Id__c,Policy__c ,Document_Type__c
                                                            from Document_Revision__c
                                                            where Id in : idsUpsert];
            List<Quote> updatedQuotes = new List<Quote>();
            Set<String> updatedQuoteIds = new Set<String>();
            for(Document_Revision__c updatedDoc : updatedDocuments){
                for(Quote q : quotes){
                    if(updatedDoc.Quote_Id__c == q.Id){
                        if(!updatedQuoteIds.contains(q.Id)){
                            updatedQuoteIds.add(q.Id);
                            updatedQuotes.add(q);
                        }
                    }
                }
            }
            ID jobID;
            if(updatedQuotes.size() > 0){
                //jobID = System.enqueueJob(new SyncQuoteQueueable(updatedQuotes));
            }

            handleResponseDoPost(outResponse,req,null,true,'Success',200,'doPost','REST_Invsk_UpdateDocumentId');
            
        } catch(exception e) {
            Database.rollback(ss);
            handleResponseDoPost(outResponse,req,CommonUtil.getExceptionMessage(e) +' Line '+ e.getLineNumber(),false,'Failed',200,'doPost','REST_Invsk_UpdateDocumentId');
        }
        
    }
    /*************************************************
* Method Name: validRequest
* Author: Trupti Tamboli
* Created: 15 Feb 2021
* Params: ComingRequestWrapper, OutComingResponse, RestRequest, index
* Return: Boolean
* Description: valid request add error
*************************************************/
    public static Boolean validRequest(ComingRequestWrapper commingRequest, OutComingResponse outComingResponse, RestRequest req, Integer index){
        
        if(String.isBlank(commingRequest.quoteId)){
            outComingResponse.errors.add(index + ' Element ' +'Quote Id is Empty' );
            return false;
        }
        if(String.isBlank(commingRequest.docId)){
            outComingResponse.errors.add(index + ' Element ' +'Document Id is Empty' );
            return false;
        }
        if(String.isBlank(commingRequest.docType)){
            outComingResponse.errors.add(index + ' Element ' +'Document Type is Empty' );
            return false;
        }
        if(String.isBlank(commingRequest.Name)){
            outComingResponse.errors.add(index + ' Element ' +'Document Name is Empty' );
            return false;
        }
        return true;
    }
    /*************************************************
* Method Name: handleResponse
* Author: Trupti Tamboli
* Created: 15 Feb 2021
* Params: ResponseGetObject responseStatus,RestRequest req,String errorMessage,Boolean  isSuccess, String status, Integer statusCode,String method,String apiName
* Return:
* Description: using on doget Method
*************************************************/
    public static void handleResponse(ResponseGetObject responseStatus,RestRequest req,String errorMessage,Boolean  isSuccess, String status, Integer statusCode,String method,String apiName ){
        responseStatus.status = status;
        responseStatus.isSuccess = isSuccess;
        responseStatus.errors.add(errorMessage);
        //Common information
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
        RestContext.response.statusCode = statusCode;
        RestContext.response.addHeader('Content-Type', 'application/json');
        ApiUtil.logAPICallIn(req, RestContext.response, apiName, apiName+ '.' +method);
    }
    /*************************************************
* Method Name: handleResponseDoPost
* Author: Trupti Tamboli
* Created: 15 Feb 2021
* Params: OutComingResponse responseStatus, RestRequest req, String errorMessage, Boolean  isSuccess, String status, Integer statusCode, String method, String apiName
* Return:
* Description: using on doGet Method
*************************************************/
    public static void handleResponseDoPost(OutComingResponse responseStatus, RestRequest req, String errorMessage, Boolean  isSuccess, String status, Integer statusCode, String method, String apiName){
        responseStatus.status = status;
        responseStatus.isSuccess = isSuccess;
        if(errorMessage!=null)responseStatus.errors.add(errorMessage);
        //Common information
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseStatus));
        RestContext.response.statusCode = statusCode;
        RestContext.response.addHeader('Content-Type', 'application/json');
        ApiUtil.logAPICallIn(req, RestContext.response, apiName, apiName+ '.' +method);
    }
    
    public class ResponseGetObject{
        public String status            {get; set;}
        public List<String> errors      {get; set;}
        public Boolean isSuccess        {get; set;}
        public List<ResponseBodyWrapper> documentInfo {get; set;}
        public ResponseGetObject() {
            this.status = null;
            this.isSuccess = false;
            this.errors = new List<String>();
            
        }
    }
    
    public class ResponseBodyWrapper{
        public String docRevisionId         {get; set;}
        public String docType               {get; set;}
        public String docName               {get; set;}
    }
    
    public class OutComingResponse{       
        public String status                {get; set;}
        public Boolean isSuccess            {get; set;}
        public List<String> errors          {get; set;}
        
        public OutComingResponse(){
            this.errors = new List<String>();
            this.status = null;
            this.isSuccess = false;
        }       
    }
    
    public class ComingRequestWrapper {
        public String quoteId;
        public String docType;
        public String docId;
        public String Name;
    }
}