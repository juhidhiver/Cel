public without sharing class ViewDocumentController {
	@AuraEnabled
    public static GenerateDocumentApiHandler.GenerateResult getDocumentEncode(String docId){
        system.debug('@@@ -------------------- ViewDocumentController.getDocumentEndcode  --------------------');
        system.debug('@@@ docId= ' + docId);
        Document_Revision__c doc = [Select Id, Name, Document_Azure_Id__c,Is_ShopX__c FROM Document_Revision__c WHERE Id =:docId];
        GenerateDocumentApiHandler.GenerateResult result = GenerateDocumentApiHandler.getDocumentEncode(doc.Document_Azure_Id__c);
        if(doc.Is_ShopX__c == true){
            result.docName = doc.Name;
        }else{
            result.docName = doc.Name + '.pdf';
        }
        return result;
    }
    
    @AuraEnabled
    public static GenerateDocumentApiHandler.GenerateResult  getDocumentEncodeByQuoteId(String quoteId, string documentType){
        GenerateDocumentApiHandler.GenerateResult result = new  GenerateDocumentApiHandler.GenerateResult();
        
        string docType = documentType;
        if(documentType == 'quote'){
			docType = 'QuoteProposal';
        }else if(documentType == 'worksheet'){
            docType = 'WorkSheet';
        }
        List<Document_Revision__c> docs = new List<Document_Revision__c>();
        
         docs = [Select Id, Name, Document_Azure_Id__c,Document_Type__c,Is_ShopX__c
                                           FROM Document_Revision__c 
                                           WHERE Document_Type__c =:docType AND Quote_Id__c =:quoteId ORDER By CreatedDate DESC Limit 1];
        if(docs.isEmpty()){
            if(docType == 'QuoteProposal' || docType == 'CelerityExcessQuote'){
                result.errMsg = 'There is no Quote Proposal document.';
            }else if(docType == 'WorkSheet'){
                result.errMsg = 'There is no WorkSheet.';
            }else if(docType == 'IPIDs'){
                result.errMsg = 'There is no IPID document.';
            }else if(docType == 'policyWording'){
                result.errMsg = 'There is no policyWording document.';
            }           
            return result;
        }

        result = GenerateDocumentApiHandler.getDocumentEncode(docs[0].Document_Azure_Id__c);
        if(docs[0].Is_ShopX__c == true){
            result.docName = docs[0].Name;
        }else{
            result.docName = docs[0].Name + '.pdf';
        }        return result;
    }
    
     @AuraEnabled
    public static GenerateDocumentApiHandler.GenerateResult  getDocumentEncodeByQuoteIdAQ(String submissionId,string binder, string documentType, string layer){
        GenerateDocumentApiHandler.GenerateResult result = new  GenerateDocumentApiHandler.GenerateResult();
        if(string.isBlank(binder)){
            result.errMsg = 'Binder is blank for Document';
            return result;
        }
        List<Quote> quoteList = new List<Quote>();
        string docType = documentType;
        quoteList = [Select Id,QuoteNumber,Quote_Type__c,Master_Binder__r.Name,Opportunity.RecordType.Name, Azure_Id__c,Rating_Status__c
                         From Quote
                         WHERE OpportunityId = :submissionId 
                         AND Status = 'Quoted' 
                         AND Layer__c =: layer 
                         AND Rating_Status__c = 'Clear'
                         AND Master_Binder__r.Name =: binder
                         AND Opportunity.RecordType.Name =: 'Aqueous'
                         ORDER BY QuoteNumber ASC];
        
        if(quoteList[0].Quote_Type__c == 'New Business'){
            if(documentType == 'quote' && layer == 'Primary'){docType = 'QuoteSchedulePrimary';}
            else if(documentType == 'quote' && layer == 'Excess'){docType = 'QuoteScheduleExcess';}
        }else if(quoteList[0].Quote_Type__c == 'Full Amendment' || quoteList[0].Quote_Type__c == 'Coverage Amendment' || quoteList[0].Quote_Type__c == 'Policy Duration Change'){
            if(documentType == 'quote' && layer == 'Primary'){ docType = 'QuoteSchedulePrimaryAmendment';}
            else if(documentType == 'quote' && layer == 'Excess'){ docType = 'QuoteScheduleExcessAmendment';}
        }
        
        List<Document_Revision__c> docs = new List<Document_Revision__c>();
        
         docs = [Select Id, Name, Document_Azure_Id__c,Document_Type__c,Submission__c,Binder__c 
                                           FROM Document_Revision__c 
                                           WHERE Document_Type__c =:docType AND Binder__c =:binder AND Submission__c =:submissionId ORDER By CreatedDate DESC Limit 1];
       system.debug('docs'+docs);
        if(docs.isEmpty()){
            if(docType == 'QuoteProposal' || docType == 'QuoteScheduleExcess' || docType == 'QuoteSchedulePrimary'){
                result.errMsg = 'There is no Quote Schedule document for '+binder;
            }     
            return result;
        }

        result = GenerateDocumentApiHandler.getDocumentEncodeAQ(docs[0].Document_Azure_Id__c);
        result.docName = docs[0].Name + '.pdf';
        return result;
    }

    @AuraEnabled
    public static GenerateDocumentApiHandler.GenerateResult  getDocumentEncodeByQuoteIdAQQC(String submissionId, String quoteId, string binder, string documentType, string layer, String documentId){
        GenerateDocumentApiHandler.GenerateResult result = new  GenerateDocumentApiHandler.GenerateResult();
        if(string.isBlank(binder)){
            result.errMsg = 'Binder is blank for Document';
            return result;
        }
        List<Quote> quoteList = new List<Quote>();
        string docType = documentType;
        quoteList = [Select Id,QuoteNumber,Quote_Type__c,Master_Binder__r.Name,Opportunity.RecordType.Name, Azure_Id__c,Rating_Status__c
                         From Quote
                         WHERE Id = :quoteId 
                         AND Layer__c =: layer 
                         AND Rating_Status__c = 'Clear'
                         AND Master_Binder__r.Name =: binder
                         AND Opportunity.RecordType.Name =: 'Aqueous'
                         ORDER BY QuoteNumber ASC];
        /*System.debug('quoteId: '+quoteId+' layer: '+layer+' binder: '+binder);
        System.debug('quoteList'+quoteList);
        if(!quoteList.isEmpty()){
            if(quoteList[0].Quote_Type__c == 'New Business'){
                if(documentType == 'quote' && layer == 'Primary'){docType = 'QuoteSchedulePrimary';}
                else if(documentType == 'quote' && layer == 'Excess'){docType = 'QuoteScheduleExcess';}
            }else if(quoteList[0].Quote_Type__c == 'Full Amendment' || quoteList[0].Quote_Type__c == 'Coverage Amendment'){
                if(documentType == 'quote' && layer == 'Primary'){ docType = 'QuoteSchedulePrimaryAmendment';}
                else if(documentType == 'quote' && layer == 'Excess'){ docType = 'QuoteScheduleExcessAmendment';}
            }
        }*/

        String strPolicy = '';
        List<Document_Revision__c> lstDoc = [SELECT Document_Type__c, Policy__c FROM Document_Revision__c WHERE Id =: documentId];
        if(!lstDoc.isEmpty()){
            String strDocType = lstDoc[0].Document_Type__c;
            strPolicy = lstDoc[0].Policy__c;
            if(String.isNotBlank(strDocType)){
                docType = strDocType;
            }
        }
        
        List<Document_Revision__c> docs = new List<Document_Revision__c>();
        
        if(String.isNotBlank(strPolicy)){
            docs = [Select Id, Name, Document_Azure_Id__c,Document_Type__c,Submission__c,Binder__c 
                                           FROM Document_Revision__c 
                                           WHERE Document_Type__c =:docType AND Binder__c =:binder AND Quote_Id__c =:quoteId AND Policy__c =:strPolicy ORDER By CreatedDate DESC Limit 1];
        }
        else{
            docs = [Select Id, Name, Document_Azure_Id__c,Document_Type__c,Submission__c,Binder__c 
                                           FROM Document_Revision__c 
                                           WHERE Document_Type__c =:docType AND Binder__c =:binder AND Quote_Id__c =:quoteId ORDER By CreatedDate DESC Limit 1];
        }
        
       system.debug('docs'+docs);
        if(docs.isEmpty()){
            if(docType == 'QuoteProposal' || docType == 'QuoteScheduleExcess' || docType == 'QuoteSchedulePrimary'){
                result.errMsg = 'There is no Quote Schedule document for '+binder;
            }     
            return result;
        }

        result = GenerateDocumentApiHandler.getDocumentEncodeAQ(docs[0].Document_Azure_Id__c);
        result.docName = docs[0].Name + '.pdf';
        return result;
    }

}