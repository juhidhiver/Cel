/*************************************************
* Class Name: GenerateDocumentApiHandler
* Author:
* Updated: 
* Description: 
* Revison : 
*************************************************/
public with sharing class GenerateDocumentApiHandler {
    /*************************************************
    * Method Name: generateDocId
    * Author: 
    * Date: 
    * Params: String parentAzureId, String bodyRequest
    * Return:
    * Exceptions:
    * Revision: 
    *************************************************/
    public Static GenerateResult generateDocId(String parentAzureId, String bodyRequest){
        system.debug('@@@ ------------------- GenerateDocumentApiHandler.generateDocId --------------------');

        GenerateResult result = new GenerateResult();
        API_Configuration__mdt apiSettingGenerateDoc = CommonUtil.getAPIconfiguration('Generate_Document');
        if (apiSettingGenerateDoc == null){
            result.errMsg = 'API Configuration Generate Document are missing';
            return result;
        }
        try {
            HttpRequest reqGenerateDoc = getHttpRequest(apiSettingGenerateDoc, parentAzureId, 'Generate_Document');            
            reqGenerateDoc.setBody(bodyRequest);
            Http httpGenerateDoc = new Http();
            HttpResponse resGenerateDoc = httpGenerateDoc.send(reqGenerateDoc);
            system.debug('@@@ >> resGenerateDoc= ' + resGenerateDoc);
            system.debug('@@@ >> resGenerateDoc.getBody()= ' + resGenerateDoc.getBody());

            if (resGenerateDoc.getStatusCode() == 200) {
                Map<String, Object> resGenerateDocBody = (Map<String, Object>) JSON.deserializeUntyped(resGenerateDoc.getBody());
                String docAzureId = (String) resGenerateDocBody.get('documentId');
                system.debug('@@@ >> docAzureId= ' + docAzureId);

                result.docAzureId = docAzureId;    
            } else {
                result.errMsg = resGenerateDoc.getBody();
            }     

        } catch (Exception ex) {
            result.errMsg = CommonUtil.getExceptionMessage(ex);
        }

        return result;
    }

    public Static GenerateResult  generateDocIdAQ(String parentObjectField, String submissionId, String parentAzureId, String documentType, String bodyRequest, string binder){
        
        Id sObjectId = (Id)submissionId;
        String sObjectName = sObjectId.getSObjectType().getDescribe().getName();
        string apiName = 'Generate_Document_V2';
        
        GenerateResult result = new GenerateResult();
		API_Configuration__mdt apiSettingGenerateDoc = CommonUtil.getAPIconfiguration(apiName);
        system.debug('apiSettingGenerateDoc'+apiSettingGenerateDoc);   
        
        if (apiSettingGenerateDoc == null){
        	result.errMsg = 'API Configuration Generate Document are missing';
        }
        try {
        	HttpRequest reqGenerateDoc = getHttpRequest(apiSettingGenerateDoc, parentAzureId, apiName);
            system.debug('reqGenerateDoc==>'+reqGenerateDoc);
             system.debug('bodyRequest==>'+bodyRequest);
            reqGenerateDoc.setBody(bodyRequest);
	        Http httpGenerateDoc = new Http();
	        HttpResponse resGenerateDoc = httpGenerateDoc.send(reqGenerateDoc);
            system.debug('@@@ >> resGenerateDoc= ' + resGenerateDoc);
            system.debug('@@@ >> resGenerateDoc.getBody()= ' + resGenerateDoc.getBody());

	        if (resGenerateDoc.getStatusCode() == 200) {
                system.debug('@@@ >> resGenerateDoc.getBody()= ' + resGenerateDoc.getBody());
	            Map<String, Object> resGenerateDocBody = (Map<String, Object>) JSON.deserializeUntyped(resGenerateDoc.getBody());
                String docAzureId = (String) resGenerateDocBody.get('DocumentId');  
                system.debug('docAzureId-->'+docAzureId);
	            result.docAzureId = docAzureId;

                String recordTypeId = '';
                if (parentObjectField == 'Policy__c') {
                    recordTypeId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByDeveloperName().get('Policy').getRecordTypeId();
                } else {
                    recordTypeId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByDeveloperName().get('Quote').getRecordTypeId();
                }
                
               
                Document_Revision__c newDoc = new Document_Revision__c();
                if(sObjectName != 'Policy__c'){
                    newDoc.Name = documentType + '_' + String.valueOf(Datetime.now());
                }
                else{//New changes done by Navdeep
                    DateTime dates = DateTime.now();
                    String datesStr = dates.format('dd-MM-yyyy');
                    newDoc.Name = documentType + '_' +'Insured Account Update'+' '+String.valueOf(datesStr);  
                }
                newDoc.Document_Azure_Id__c = docAzureId;
                newDoc.Document_Type__c = documentType;
                newDoc.Binder__c = binder;
                newDoc.RecordTypeId = recordTypeId; 
                if(sObjectName == 'Opportunity'){
                    newDoc.Submission__c = submissionId;
                }
                if(sObjectName == 'Quote'){
                    newDoc.Quote_Id__c = submissionId;
                }
                /*** New if added by Navdeep to handle policy doc generation **/
                if(sObjectName == 'Policy__c'){
                    newDoc.Policy__c = submissionId;
                }
                
                insert newDoc;

				}else {
                system.debug(' inside else resGenerateDoc.getBody()= ' + resGenerateDoc.getBody());
                result.errMsg = 'Generate Document Failed!';
            }
        	ApiUtil.logAPICall(reqGenerateDoc, resGenerateDoc, apiName+' Callout','GenerateDocumentApiHandler.generateDocId', apiSettingGenerateDoc.HeaderParams__c, 'Outbound');
            
        } catch (Exception ex) {
            system.debug('Exception==>'+ex);
            result.errMsg = CommonUtil.getExceptionMessage(ex);
       }
        system.debug('result->'+result);                                           
		return result;
	}
  
	public Static GenerateResult  generateDocId(String parentObjectField, String parentId, String parentAzureId, String documentType, String bodyRequest){
       
        Quote currentQuote = [Select Id,AccountId, Product_Name__c, Azure_Id__c From Quote Where Policy__c = :parentId OR Id =:parentId][0];
        
		string recordTypeProduct = [select Name,RecordType.Name from Product2 where Name =: currentQuote.Product_Name__c].RecordType.Name;
        string apiName;
        if(recordTypeProduct == 'Celerity'){
            apiName = 'Generate_Document_V2';
        }
        GenerateResult result = new GenerateResult();
		API_Configuration__mdt apiSettingGenerateDoc = CommonUtil.getAPIconfiguration(apiName);
          system.debug('apiSettingGenerateDoc'+apiSettingGenerateDoc);                               
        if (apiSettingGenerateDoc == null){
        	result.errMsg = 'API Configuration Generate Document are missing';
        }
        try {
        	HttpRequest reqGenerateDoc = getHttpRequest(apiSettingGenerateDoc, parentAzureId, apiName);
            system.debug('reqGenerateDoc==>'+reqGenerateDoc);
             system.debug('bodyRequest==>'+bodyRequest);
            reqGenerateDoc.setBody(bodyRequest);
	        Http httpGenerateDoc = new Http();
	        HttpResponse resGenerateDoc = httpGenerateDoc.send(reqGenerateDoc);
            system.debug('@@@ >> resGenerateDoc= ' + resGenerateDoc);
            system.debug('@@@ >> resGenerateDoc.getBody()= ' + resGenerateDoc.getBody());

	        if (resGenerateDoc.getStatusCode() == 200) {
                system.debug('@@@ >> resGenerateDoc.getBody()= ' + resGenerateDoc.getBody());
	            Map<String, Object> resGenerateDocBody = (Map<String, Object>) JSON.deserializeUntyped(resGenerateDoc.getBody());
                String docAzureId = (String) resGenerateDocBody.get('DocumentId');              
	            result.docAzureId = docAzureId;

                String recordTypeId = '';
                if (parentObjectField == 'Policy__c') {
                    recordTypeId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByDeveloperName().get('Policy').getRecordTypeId();
                } else {
                    recordTypeId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByDeveloperName().get('Quote').getRecordTypeId();
                }

	            // insert new Quote Document Record
                if(documentType == 'CelerityExcessQuote'){
                    documentType = 'QuoteProposal';
                }
                if(documentType == 'CelerityExcessPolicy'){
                    documentType = 'PolicyForm';
                }
                if(documentType == 'CelerityExcessBinder'){
                    documentType = 'Binder';
                }
	            Document_Revision__c newDoc = new Document_Revision__c(
	            	Name = documentType + ' ' + DateTime.now().format('yyyy/MM/dd hh:mm:ss'),
	                Document_Azure_Id__c = docAzureId,
	                Document_Type__c = documentType,
                    RecordTypeId = recordTypeId
	            );
	            newDoc.put(parentObjectField, parentId);            
	            insert newDoc;
                
                if(documentType == 'QuoteProposal' && recordTypeProduct == 'Celerity'){
                    List<Quote> currentQuotes = [Select Id, OpportunityId From Quote Where Id = :parentId];
                    if(!currentQuotes.isEmpty()){
                        List<Opportunity> opps = [SELECT Submission_Quote_Date__c FROM Opportunity WHERE Id = :currentQuotes[0].OpportunityId];
                        if(!opps.isEmpty()){    
                            if(opps[0].Submission_Quote_Date__c == null){
                                opps[0].Submission_Quote_Date__c = System.Now();
                                update opps;
                            }
                        }
                    }
                }
            } else {
                system.debug(' inside else resGenerateDoc.getBody()= ' + resGenerateDoc.getBody());
                result.errMsg = resGenerateDoc.getBody();
            }
        	ApiUtil.logAPICall(reqGenerateDoc, resGenerateDoc, apiName+' Callout','GenerateDocumentApiHandler.generateDocId', apiSettingGenerateDoc.HeaderParams__c, 'Outbound');
        
        } catch (Exception ex) {
            system.debug('Exception==>'+ex);
            result.errMsg = CommonUtil.getExceptionMessage(ex);
       }
        system.debug('result->'+result);                                           
		return result;
	}
    
    /*************************************************
    * Method Name: generateDocRevisionPolicy
    * Author: 
    * Date: 
    * Params: String parentId, String parentAzureId, String documentType, String bodyRequest
    * Return:
    * Exceptions:
    * Revision: Long Ly - 05-06-2019 - Clone from generateDocId, used for Batch GenerateDocumentByBatch
    *************************************************/
    public static Document_Revision__c generateDocRevisionPolicy(String parentId, String parentAzureId, 
                                                                    String documentType, String bodyRequest){
        
        system.debug('@@@ -------------------- GenerateDocumentApiHandler.generateDocResultBatch --------------------');
        API_Configuration__mdt apiSettingGenerateDoc = CommonUtil.getAPIconfiguration('Generate_Document');
        if (apiSettingGenerateDoc == null){
            return null;
        }
        HttpRequest reqGenerateDoc = null;
        HttpResponse resGenerateDoc = null;
        try {
            reqGenerateDoc = getHttpRequest(apiSettingGenerateDoc, parentAzureId, 'Generate_Document');
            reqGenerateDoc.setBody(bodyRequest);
            Http httpGenerateDoc = new Http();
            resGenerateDoc = httpGenerateDoc.send(reqGenerateDoc);

            if (resGenerateDoc.getStatusCode() == 200) {
                Map<String, Object> resGenerateDocBody = (Map<String, Object>) JSON.deserializeUntyped(resGenerateDoc.getBody());
                String docAzureId = (String) resGenerateDocBody.get('documentId');
                system.debug('@@@ >> docAzureId= ' + docAzureId);

                String recordTypeId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByDeveloperName().get('Policy').getRecordTypeId();
               
                // insert new Quote Document Record
                Document_Revision__c newDoc = new Document_Revision__c(
                    Name = documentType + '_' + String.valueOf(Datetime.now()),
                    Document_Azure_Id__c = docAzureId,
                    Document_Type__c = documentType,
                    RecordTypeId = recordTypeId,
                    Policy__c = parentId
                );
                return newDoc;      
            }
            ApiUtil.logAPICall(reqGenerateDoc, resGenerateDoc, 'Generate_Document Callout','GenerateDocumentApiHandler.generateDocResultBatch', apiSettingGenerateDoc.HeaderParams__c, 'Outbound');         
        } catch (Exception ex) {
            ApiUtil.logAPICall(new HttpRequest(), new HttpResponse(), 'Generate_Document Callout','GenerateDocumentApiHandler.generateDocResultBatch', apiSettingGenerateDoc.HeaderParams__c, 'Outbound');
            return null;
        }
        return null;
    }

    /*************************************************
    * Method Name: getDocumentEncode
    * Author: 
    * Date: 
    * Params: String docAzureId
    * Return:
    * Exceptions:
    * Revision: 
    **************************************************/
	public static GenerateResult getDocumentEncodeAQ(String docAzureId){
        system.debug('@@@ -------------------- GenerateDocumentApiHandler.getDocumentEndcode --------------------');        
        GenerateResult result = new GenerateResult();
        string apiName = 'Get_Document_V2';
        try {
            Blob responseBodyBlob = null;
            API_Configuration__mdt apiSettingGetDoc = CommonUtil.getAPIconfiguration(apiName);
            system.debug('apiSettingGetDoc-->'+apiSettingGetDoc);
            if (apiSettingGetDoc == null) {
                result.errMsg = 'API Configuration Get Document is missing';
                return result;
            }
            HttpRequest reqGetDoc = getHttpRequest(apiSettingGetDoc, docAzureId, apiName);
             system.debug('@@@ reqGetDoc= ' + reqGetDoc);
            Http httpGetDoc = new Http();
            HttpResponse resGetDoc = httpGetDoc.send(reqGetDoc);
            system.debug('@@@ resGetDoc= ' + resGetDoc);
            system.debug('@@@ resGetDoc body= ' + resGetDoc.getBody());
            if (resGetDoc.getStatusCode() == 200) {
                responseBodyBlob = resGetDoc.getBodyAsBlob();
            } else { 
                result.errMsg = Label.SYSTEM_ERROR_MSG + ': ' + resGetDoc.getBody();
            }
            system.debug('@@@ responseBodyBlob= ' + responseBodyBlob);
            
            result.encodeBlobResponse = (responseBodyBlob == null) ? null : EncodingUtil.base64Encode(responseBodyBlob);
        	ApiUtil.logAPICall(reqGetDoc, resGetDoc, 'Get_Document_V2 Callout','GenerateDocumentApiHandler.getDocumentEncodeAQ', apiSettingGetDoc.HeaderParams__c, 'Outbound');
        } catch (Exception ex) {
            system.debug(ex.getLineNumber() + ' message :' + ex.getMessage() + ' cause:' + ex.getCause());
            result.errMsg = CommonUtil.getExceptionMessage(ex);
        }
        system.debug('result= ' + result);
        return result;
    }
    
    public static GenerateResult getDocumentEncode(String docAzureId){
        system.debug('@@@ -------------------- GenerateDocumentApiHandler.getDocumentEndcode --------------------');        
        GenerateResult result = new GenerateResult();
        Quote quoteProduct = new Quote();
        Opportunity oppProduct = new Opportunity();

        string apiName;
        if(docAzureId == 'Policy Wording'){
            result.errMsg = 'Please use the Policy Wording Link to view the document.';
            return result;
        }
        Document_Revision__c docRev = [Select Id,Quote_Id__c,Submission__c, Policy__r.Product_Name__c,Document_Type__c, Document_Azure_Id__c FROM Document_Revision__c WHERE Document_Azure_Id__c =:docAzureId limit 1];
        
        if(docRev.Document_Type__c == 'QuoteProposal' || docRev.Document_Type__c == 'CeleritySignaturePackForQuote' || docRev.Document_Type__c == 'WorkSheet' || docRev.Document_Type__c == 'CelerityExcessQuote' || docRev.Document_Type__c == 'QuoteSchedulePrimary' || docRev.Document_Type__c == 'QuoteScheduleExcess' || docRev.Document_Type__c == 'QuoteSchedulePrimaryAmendment' || docRev.Document_Type__c == 'QuoteScheduleExcessAmendment')
        {
            if(string.isNotBlank(docRev.Quote_Id__c)) {
                quoteProduct = [select Id,Product_Name__c from Quote where Id =:docRev.Quote_Id__c];
                
                if(String.isNotBlank(quoteProduct.Product_Name__c)){
                    if(quoteProduct.Product_Name__c.contains('Standalone'))
                        apiName = 'Get_Document_V2';
                    
                    else if(quoteProduct.Product_Name__c == 'Professional Indemnity'){
                        apiName = 'Get_Document_V2';
                    }
                    // Added by Maeran for PCC on 6/9/2021
                    else if (quoteProduct.Product_Name__c == System.Label.Product_Name_for_PCC){
                        apiName = 'Get_Document_V2';
                    }
                }
            }else if(string.isNotBlank(docRev.Submission__c)){
                 oppProduct = [select Id,Product_Name__c from Opportunity where Id =:docRev.Submission__c];
                if(String.isNotBlank(oppProduct.Product_Name__c)) apiName = 'Get_Document_V2';
            }

        }
        else{
            if(string.isNotBlank(docRev.Policy__r.Product_Name__c))
            {
                if(docRev.Policy__r.Product_Name__c.contains('Standalone'))
                    apiName = 'Get_Document_V2';
                
                else if(docRev.Policy__r.Product_Name__c == 'Professional Indemnity')
                    apiName = 'Get_Document_V2';
                 // Added by Maeran for PCC on 6/9/2021
                 else if (docRev.Policy__r.Product_Name__c == System.Label.Product_Name_for_PCC){
                    apiName = 'Get_Document_V2';
                }
            }
        }
        try {
            Blob responseBodyBlob = null;
            API_Configuration__mdt apiSettingGetDoc = CommonUtil.getAPIconfiguration(apiName);
            if (apiSettingGetDoc == null) {
                //throw new AuraHandledException('API Configuration Get Document is missing');
                result.errMsg = 'API Configuration Get Document is missing';
                return result;
            }
            HttpRequest reqGetDoc = getHttpRequest(apiSettingGetDoc, docAzureId, apiName);
            system.debug('@@@ reqGetDoc= ' + reqGetDoc);
            Http httpGetDoc = new Http();
            HttpResponse resGetDoc = httpGetDoc.send(reqGetDoc);
            system.debug('@@@ resGetDoc= ' + resGetDoc);
            system.debug('@@@ resGetDoc body= ' + resGetDoc.getBody());
            if (resGetDoc.getStatusCode() == 200) {
                responseBodyBlob = resGetDoc.getBodyAsBlob();
            }
            else if (resGetDoc.getStatusCode() == 202 && docRev.Policy__r.Product_Name__c != 'Professional Indemnity'){
                result.statusCode = 202;
                result.errMsg = 'The document is still being processed, please try again in a few moments.';
            } 
            else { 
                result.errMsg = Label.SYSTEM_ERROR_MSG + ': ' + resGetDoc.getBody();
            }
            system.debug('@@@ responseBodyBlob= ' + responseBodyBlob);
            //Commented by Siva as Log API throwing exception as the message is huge.
            if (resGetDoc.getStatusCode() != 200)
           ApiUtil.logAPICall(reqGetDoc, resGetDoc, 'Get_Document Callout_V2','GenerateDocumentApiHandler.getDocumentEndcode', apiSettingGetDoc.HeaderParams__c, 'Outbound');
            result.encodeBlobResponse = (responseBodyBlob == null) ? null : EncodingUtil.base64Encode(responseBodyBlob);
        
        } catch (Exception ex) {
            system.debug(ex.getLineNumber() + ' message :' + ex.getMessage() + ' cause:' + ex.getCause());
            result.errMsg = CommonUtil.getExceptionMessage(ex);
        }
        return result;
    }
    

    /*************************************************
    * Method Name: getHttpRequest
    * Author: 
    * Date: 
    * Params: Custom Metadata API_Configuration__mdt apiSetting, String idData, String nameApi
    * Return:
    * Exceptions:
    * Revision: 
    *************************************************/
	public static HttpRequest getHttpRequest(API_Configuration__mdt apiSetting, String idData, String nameApi) {
        String baseUri = apiSetting.Base_Url__c + apiSetting.Endpoint__c;
        system.debug('@@@ baseUri= ' + baseUri);

        Map<String, String> headerParamMap = new Map<String, String>();
        for (String headerParam : apiSetting.HeaderParams__c.split(';')) {
            List<String> headerKeyValue = headerParam.split(':');
            headerParamMap.put(headerKeyValue[0], headerKeyValue[1]);
        }
        system.debug('@@@ headerParamMap= ' + headerParamMap);

        if(nameApi == 'Get_Document' || nameApi == 'Get_Document_V2'){
            baseUri += '/' + idData;
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUri);
        req.setMethod(apiSetting.Method__c);
        req.setTimeout(Integer.valueOf(Label.ApiTimeOut));
        for (String headerParamKey : headerParamMap.keySet()) {
            req.setHeader(headerParamKey, headerParamMap.get(headerParamKey));
        }
        system.debug('@@@ req= ' + req);
        return req;
    }
    
     public static GenerateResult getQuoteDocumentEncode(String contentId){
        system.debug('@@@ -------------------- GenerateDocumentApiHandler.getDocumentEndcode1 --------------------');        
        GenerateDocumentApiHandler.GenerateResult result = new GenerateDocumentApiHandler.GenerateResult();
   		ContentVersion cv=[select Id, ContentDocumentId, VersionData, Title from ContentVersion where ContentDocumentId=:contentId];
		Blob responseBodyBlob = cv.VersionData; 
        result.encodeBlobResponse = EncodingUtil.base64Encode(responseBodyBlob);
        result.docName = cv.Title+'.pdf';
		System.debug('result.encodeBlobResponse::'+result.encodeBlobResponse);
        system.debug('#result::'+result); 
      	return result;
     }
    
	public class GenerateResult {
        @AuraEnabled public String errMsg              	{get; set;}
        @AuraEnabled public String docAzureId          	{get; set;}
        @AuraEnabled public String encodeBlobResponse  	{get; set;}
        @AuraEnabled public String docName  			{get; set;}
        @AuraEnabled public Integer statusCode  			{get; set;}
    }


}