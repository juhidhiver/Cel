/*************************************************
* Class Name: GenerateQuoteDocumentController 
* Author:
* Date:
* Requirement/Project Description: Generate Quote Document . 
** Revision: Long Ly /  21 May 2019 / Quote Document Call for Endorsement use DocType = ChangeEndorsement
*************************************************/
public with sharing class GenerateQuoteDocumentController {
    
    @AuraEnabled
    public static List<string> getBinder(String submissionId, string documentType, string layer){
        
        List<string> listBinder = new  List<string>();
        set<string> setBinder = new set<string>();
        
        try{
            List<Quote> quoteList = [Select Id,QuoteNumber,AccountId,Master_Binder__r.Name,Opportunity.RecordType.Name, Azure_Id__c,Rating_Status__c
                                     From Quote
                                     WHERE OpportunityId = :submissionId 
                                     AND Status = 'Quoted' 
                                     AND Layer__c =: layer 
                                     AND Rating_Status__c = 'Clear'
                                     AND Master_Binder__c != ''
                                     AND Opportunity.RecordType.Name =: 'Aqueous'
                                     ORDER BY QuoteNumber ASC];
            
            
            if(!quoteList.isEmpty()){
                for(Quote quote :quoteList){
                    setBinder.add(quote.Master_Binder__r.Name); 
                }
                listBinder.addAll(setBinder);
            }
            
        } catch (Exception ex) {
            system.debug('Exception==>'+ex);
        }
        
        return listBinder;
    }

    @AuraEnabled
    public static string getMastreBinderName(String masterBinderId){

        String masterBinderName;
        try {

            List<Master_Binder__c> listMasterBinder =[Select Id, Name from Master_Binder__c where Id =: masterBinderId];
            if(!listMasterBinder.isEmpty()){
                masterBinderName = listMasterBinder[0].Name;
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return masterBinderName;
    }
    
    @AuraEnabled
    public static GenerateDocumentApiHandler.GenerateResult generateDocIdAQ(String submissionId, string binder, string documentType, string layer){
        GenerateDocumentApiHandler.GenerateResult result = new GenerateDocumentApiHandler.GenerateResult();
        
        try {
            List<Quote> quoteList = new List<Quote>();
            List<string> quoteAzureIdList = new  List<string>();
            
            
            system.debug('sub: '+submissionId+' binder: '+binder+' Layer: '+layer);
            quoteList = [Select Id,QuoteNumber,Quote_Type__c,AccountId,Master_Binder__r.Name,Opportunity.RecordType.Name, Azure_Id__c,Rating_Status__c
                         From Quote
                         WHERE OpportunityId = :submissionId 
                         AND Status = 'Quoted' 
                         AND Layer__c =: layer 
                         AND Rating_Status__c = 'Clear'
                         AND Master_Binder__r.Name =: binder
                         AND Opportunity.RecordType.Name =: 'Aqueous'
                         ORDER BY QuoteNumber ASC];
            system.debug('quoteList-->'+quoteList);
            
            if (quoteList.isEmpty()) {
                result.errMsg = Label.QUOTE_PROPOSAL_VALIDATION_MSG;
                return result;
            }
            
            for(Quote quote :quoteList){
                quoteAzureIdList.add(quote.Azure_ID__c);
            }
            if(quoteList[0].Quote_Type__c == 'Midterm Cancellation' || quoteList[0].Quote_Type__c == 'Insured Account Update' ){
                result.errMsg = 'Document cannot be generated for this Quote Type';
                return result;
            }
            
            String docType;
            if(quoteList[0].Quote_Type__c == 'New Business'){
                if(documentType == 'quote' && layer == 'Primary'){ docType = 'QuoteSchedulePrimary';}
                else if(documentType == 'quote' && layer == 'Excess'){ docType = 'QuoteScheduleExcess';}
            }else if(quoteList[0].Quote_Type__c == 'Full Amendment' || quoteList[0].Quote_Type__c == 'Coverage Amendment'){
                if(documentType == 'quote' && layer == 'Primary'){ docType = 'QuoteSchedulePrimaryAmendment';}
                else if(documentType == 'quote' && layer == 'Excess'){ docType = 'QuoteScheduleExcessAmendment';}
            }
           
            string bodyreq;            
            string ProductClassCd = 'Aqueous_PI';
            string accountId = quoteList[0].AccountId;
            string OutputFileName = docType+'.pdf';
            string RequestType = 'Quote';

            bodyreq = '{"DocumentType":"' +docType+ '","Quotes":'+JSON.serialize(quoteAzureIdList)+ ',"ProductClassCd":"'+ProductClassCd+'","OutputFileName" : "'+OutputFileName+'","RequestType" : "'+RequestType+'","AccountId": "'+accountId+'"}';
            
            result = GenerateDocumentApiHandler.generateDocIdAQ('Quote_Id__c', submissionId, accountId, docType, bodyReq,binder);
        } catch (Exception ex) {
            system.debug('Exception==>'+ex);
            result.errMsg = CommonUtil.getExceptionMessage(ex);
        }
        
        return result;
    }

    @AuraEnabled
    public static GenerateDocumentApiHandler.GenerateResult generateDocIdAQQC(String submissionId, String quoteId, string binder, string documentType, string layer){
        GenerateDocumentApiHandler.GenerateResult result = new GenerateDocumentApiHandler.GenerateResult();
        
        try {
            List<Quote> quoteList = new List<Quote>();
            List<string> quoteAzureIdList = new  List<string>();
            
            
            system.debug('sub: '+submissionId+' binder: '+binder+' Layer: '+layer+'Quote'+quoteId);
            quoteList = [Select Id,QuoteNumber,Quote_Type__c,AccountId,Master_Binder__r.Name,Opportunity.RecordType.Name, Azure_Id__c,Rating_Status__c
                         From Quote
                         WHERE Id = :quoteId 
                         AND Status = 'Quoted' 
                         AND Layer__c =: layer 
                         AND Rating_Status__c = 'Clear'
                         AND Master_Binder__r.Name =: binder
                         AND Opportunity.RecordType.Name =: 'Aqueous'
                         ORDER BY QuoteNumber ASC];
            system.debug('quoteList-->'+quoteList);
            
            if (quoteList.isEmpty()) {
                result.errMsg = Label.QUOTE_PROPOSAL_VALIDATION_MSG;
                return result;
            }
            
            for(Quote quote :quoteList){
                quoteAzureIdList.add(quote.Azure_ID__c);
            }
            if(quoteList[0].Quote_Type__c == 'Midterm Cancellation' || quoteList[0].Quote_Type__c == 'Flat Cancellation'){
                result.errMsg = 'Quote Schedule not available for Cancellation';
                return result;
            }
            if(quoteList[0].Quote_Type__c == 'Insured Account Update'){
                result.errMsg = 'Document cannot be generated for this Quote Type';
                return result;
            }
            
            String docType;
            if(quoteList[0].Quote_Type__c == 'New Business' || quoteList[0].Quote_Type__c == 'Renewal'){
                if(documentType == 'quote' && layer == 'Primary'){ docType = 'QuoteSchedulePrimary';}
                else if(documentType == 'quote' && layer == 'Excess'){ docType = 'QuoteScheduleExcess';}
            }else if(quoteList[0].Quote_Type__c == 'Full Amendment' || quoteList[0].Quote_Type__c == 'Coverage Amendment' || quoteList[0].Quote_Type__c == 'Policy Duration Change'){
                if(documentType == 'quote' && layer == 'Primary'){ docType = 'QuoteSchedulePrimaryAmendment';}
                else if(documentType == 'quote' && layer == 'Excess'){ docType = 'QuoteScheduleExcessAmendment';}
            }
           
            string bodyreq;            
            string ProductClassCd = 'Aqueous_PI';
            string accountId = quoteList[0].AccountId;
            string OutputFileName = docType+'.pdf';
            string RequestType = 'Quote';

            bodyreq = '{"DocumentType":"' +docType+ '","Quotes":'+JSON.serialize(quoteAzureIdList)+ ',"ProductClassCd":"'+ProductClassCd+'","OutputFileName" : "'+OutputFileName+'","RequestType" : "'+RequestType+'","AccountId": "'+accountId+'"}';
            
            result = GenerateDocumentApiHandler.generateDocIdAQ('Quote_Id__c', quoteId, accountId, docType, bodyReq,binder);
        } catch (Exception ex) {
            system.debug('Exception==>'+ex);
            result.errMsg = CommonUtil.getExceptionMessage(ex);
        }
        
        return result;
    }
    
    @AuraEnabled
    public static GenerateDocumentApiHandler.GenerateResult generateDocId(String quoteId, string documentType){
        system.debug('@@@ -------------------- GenerateQuoteDocumentController.generateDocId --------------------');    
        GenerateDocumentApiHandler.GenerateResult result = new GenerateDocumentApiHandler.GenerateResult();
        
        try {
            String  productClassCd ;
            String  productName;
            String  accountId;
            String quoteAzureId;
            String docType;
            String include='quoteDataOnly';
            String submissionId;
            String policyId;
            String businessDescription='';
            String lobName='Celerity' ;
            String parentPolicyNumber='';
            
            List<Quote> quotes = [Select Id,Layer__c,OpportunityId,Opportunity.Product__c,Policy__c,AccountId, 
                                  Product_Name__c, Azure_Id__c,Opportunity.Product__r.Name,Status,Opportunity.Source__c,
                                  Rating_Status__c,Parent_Quote__c, Quote_Type__c,
                                  Opportunity.Product__r.Model_ID__c
                                  From Quote
                                  Where Id = :quoteId];
            
            if(quotes[0] == null){
                result.errMsg = 'Invalid QuoteId';
                return result;
            }
            if ((quotes[0].Status != 'Quoted' || quotes[0].Rating_Status__c != 'Clear') && quotes[0].Opportunity.Source__c !='SME' ) {
                system.debug('SME document -- '+quotes[0].Status);
                result.errMsg = Label.QUOTE_PROPOSAL_VALIDATION_MSG;
                return result;
            }
            if (!quotes.isEmpty()) 
            {
                productClassCd = quotes[0].Opportunity.Product__r.Model_ID__c;
                productName=quotes[0].Product_Name__c;
                accountId=quotes[0].AccountId;
                quoteAzureId = quotes[0].Azure_ID__c;
                submissionId= quotes[0].OpportunityId;
                policyId= quotes[0].Policy__c;
            }
            
            docType = 'QuoteProposal';
            
            if(documentType == 'quote')
            { 
                docType = 'QuoteProposal'; 
            }
            else if(documentType == 'worksheet')
            { 
                docType = 'WorkSheet'; 
            }
            String outputFileName = docType +'.pdf';
            
            if(quotes[0].Parent_Quote__c != null && quotes[0].Quote_Type__c !='New Business' && quotes[0].Quote_Type__c != 'Renewal') {

                if(quotes[0].Layer__c == 'Excess'){
                    docType = 'ExcessChangeEndorsementQuote';
                }
                else{
                    docType = 'ChangeEndorsementQuote';
                }
               
            }
            string bodyreq;
            if(quotes[0].Layer__c == 'Excess' && docType == 'QuoteProposal'){
                docType = 'CelerityExcessQuote';
                // bodyreq = '{"documentType":"' + docType + '","quoteId":"' + quoteAzureId + '"}';
            }
            /*else{
bodyreq = '{"documentType":"' + docType + '","quoteId":"' + quoteAzureId + '"}';
}*/
            DocManagementWrapper docManagement = new DocManagementWrapper(submissionId,policyId, lobName, accountId);
            DocumentV2Wrapper docV2Wrapper = new DocumentV2Wrapper(quotes, productClassCd,outputFileName,include,docType,docManagement);
            String v2bodyRequest = JSON.serialize(docV2Wrapper); 
            system.debug('v2bodyRequest'+v2bodyRequest);
            result = GenerateDocumentApiHandler.generateDocId('Quote_Id__c', quoteId, quoteAzureId, docType, v2bodyRequest);
        } catch (Exception ex) {
            system.debug('Exception==>'+ex);
            result.errMsg = CommonUtil.getExceptionMessage(ex);
        }
        
        return result;
    }
    
    
    public class DocumentV2Wrapper {
        public List<String> Quotes { get; set; }
        public String ProductClassCd { get; set;}
        public String OutputFileName {get; set;}
        public String     include {get; set;}
        public String DocumentType { get; set; }
        public  DocManagementWrapper  DocManagement {get; set;}
        
        public DocumentV2Wrapper(List<Quote> quotes, String productClassCd,String outputFileName, String include,String documentType,DocManagementWrapper docManagement) {
            this.ProductClassCd = productClassCd;
            this.OutputFileName = outputFileName;
            this.include = include;
            this.DocumentType = documentType;
            this.DocManagement  = docManagement;
            
            this.Quotes = new List<String>();
            if (quotes != null) {
                for (Quote quote : quotes) {
                    this.Quotes.add(quote.Azure_ID__c);
                }                
            }      
        }
    }
    
    public class DocManagementWrapper {
        public String SubmissionId { get; set;}
        public String PolicyId { get; set; }
        public String LOBName {get; set;}
        public String     AccountId {get; set;}

        public DocManagementWrapper(String submissionId,String policyId, String lobName,String accountId ) {
            this.SubmissionId = submissionId;
            this.PolicyId = policyId;
            this.LOBName = lobName;
            this.AccountId  = accountId;
        }
    }
    
    
    
    
    
    /*************************************************
* Method Name: generateDocId
* Author: 
* Date: 
* Params: String quoteId, String quoteAzureId
* Return:
* Exceptions:
* Revision: 
**************************************************/
    /* public static GenerateDocumentApiHandler.GenerateResult generateDocId(String quoteId, String quoteAzureId){
GenerateDocumentApiHandler.GenerateResult result = new GenerateDocumentApiHandler.GenerateResult();
Quote currentQuote = [SELECT Id,Parent_Quote__c, Quote_Type__c
FROM Quote WHERE Id = :quoteId][0];
String docType = 'QuoteProposal';
//Long Ly - 07/30/2019 -  Quote Document Call for Endorsement use DocType = ChangeEndorsement
if(currentQuote.Parent_Quote__c != null && currentQuote.Quote_Type__c !='New Business') {
docType = 'ChangeEndorsement';
}
//End
try {
String bodyreq = '{"documentType":"' + docType + '","quoteId":"' + quoteAzureId + '"}';
result = GenerateDocumentApiHandler.generateDocId('Quote_Id__c', quoteId, quoteAzureId, docType, bodyReq);
} catch (Exception ex) {
System.debug(ex.getStackTraceString() + ' line number:' + ex.getLineNumber());
result.errMsg = CommonUtil.getExceptionMessage(ex);
}

return result;
}*/
    
    //@AuraEnabled
    //public static GenerateQuoteResult getDocumentEncode(String docAzureId){
    //    system.debug('@@@ -------------------- GenerateQuoteDocumentController.getDocumentEndcode --------------------');
    //    system.debug('@@@ docAzureId= ' + docAzureId);
    //    GenerateQuoteResult result = new GenerateQuoteResult();
    
    //    try {
    //        Blob responseBodyBlob = null;
    //        API_Configuration__mdt apiSettingGetDoc = CommonUtil.getAPIconfiguration('Get_Quote_Document');
    //        if(apiSettingGetDoc == null) throw new AuraHandledException('API Configuration Get Proposal Document are missing');
    //        HttpRequest reqGetDoc = getHttpRequest(apiSettingGetDoc, docAzureId, 'Get_Quote_Document', '');
    //        Http httpGetDoc = new Http();
    //        HttpResponse resGetDoc = httpGetDoc.send(reqGetDoc);
    //        system.debug('@@@ resGetDoc= ' + resGetDoc);
    //        system.debug('@@@ resGetDoc body= ' + resGetDoc.getBody());
    //        if (resGetDoc.getStatusCode() == 200) {
    //            responseBodyBlob = resGetDoc.getBodyAsBlob();
    //        } else { 
    //            result.errMsg = Label.SYSTEM_ERROR_MSG + ': ' + resGetDoc.getBody();
    //        }
    //        system.debug('@@@ responseBodyBlob= ' + responseBodyBlob);
    //        ApiUtil.logAPICall(reqGetDoc, resGetDoc, 'Get_Quote_Document Callout','GenerateQuoteDocumentController.getDocumentEndcode', apiSettingGetDoc.HeaderParams__c, 'Outbound');
    //        result.encodeBlobResponse = (responseBodyBlob == null) ? null : EncodingUtil.base64Encode(responseBodyBlob);
    
    //    } catch (Exception ex) {
    //        result.errMsg = CommonUtil.getExceptionMessage(ex);
    //    }
    //    return result;
    //}
    
    //private static HttpRequest getHttpRequest(API_Configuration__mdt apiSetting, String idData, String nameApi, String documentType) {
    //    String baseUri = apiSetting.Base_Url__c + apiSetting.Endpoint__c;
    //    system.debug('@@@ baseUri= ' + baseUri);
    
    //    Map<String, String> headerParamMap = new Map<String, String>();
    //    for (String headerParam : apiSetting.HeaderParams__c.split(';')) {
    //        List<String> headerKeyValue = headerParam.split(':');
    //        headerParamMap.put(headerKeyValue[0], headerKeyValue[1]);
    //        }
    //    system.debug('@@@ headerParamMap= ' + headerParamMap);
    //    String bodyreq = '{"documentType":"' + documentType + '","quoteId":"' + idData + '"}';
    //    if(nameApi == 'Get_Quote_Document'){
    
    //        baseUri += '/' + idData;
    //        //baseUri += '/071e908f-8e0b-4c2c-8358-49b05ff33d0e';
    
    //    } 
    //    HttpRequest req = new HttpRequest();
    //    req.setEndpoint(baseUri);
    //    req.setMethod(apiSetting.Method__c);
    //    if(nameApi == 'Generate_Quote_Document'){
    //        req.setBody(bodyReq);
    //    } 
    //    req.setTimeout(Integer.valueOf(Label.ApiTimeOut));
    //    for (String headerParamKey : headerParamMap.keySet()) {
    //        req.setHeader(headerParamKey, headerParamMap.get(headerParamKey));
    //    }
    //    system.debug('@@@ req= ' + req);
    //    return req;
    //}
    
    //private class GenerateQuoteResult {
    //    @AuraEnabled String errMsg              {get; set;}
    //    @AuraEnabled String docAzureId          {get; set;}
    //    @AuraEnabled String encodeBlobResponse  {get; set;}
    //}
}