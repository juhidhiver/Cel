/**
 * @File Name          : QuoteCompareItemWrapper.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : Vinayesh
 * @Last Modified On   : 08-01-2022
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/22/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public with sharing class QuoteCompareItemWrapper {
    @AuraEnabled
    public String quoteId {get; set;}
    @AuraEnabled
    public String quoteName {get; set;}
    @AuraEnabled
    public String quoteStatus {get; set;}
    @AuraEnabled
    public String quoteRatingStatus {get; set;}
    @AuraEnabled
    public List<QuoteCompareItemField> quoteFields {get; set;}
    @AuraEnabled
    public List<Quote_Version__c> quoteVersions {get; set;}
    @AuraEnabled
    public String lastQuoteVersion {get; set;}
    @AuraEnabled
    public String quoteLayer {get; set;}    
    @AuraEnabled
    public String quoteType {get; set;}
    @AuraEnabled
    public Quote quoteRecord {get; set;}

    public QuoteCompareItemWrapper() {
        this.quoteId = '';
        this.quoteName = '';
        this.quoteStatus = '';
        this.quoteRatingStatus = '';
        this.quoteFields = new List<QuoteCompareItemField>();
        this.quoteVersions = new List<Quote_Version__c>();
        this.lastQuoteVersion = '';
        this.quoteLayer = '';
        this.quoteType = '';
        this.quoteRecord = new Quote();
    }
    public QuoteCompareItemWrapper(Quote q, QuoteCompareItemWrapper compareItem) {
        this.quoteId = q.Id;
        this.quoteName = q.Name;
        this.quoteStatus = q.Status;
        this.quoteRatingStatus = q.Rating_Status__c;
        this.quoteLayer = q.Layer__c;
        this.quoteType = q.Quote_Type__c;
        this.quoteFields = compareItem.quoteFields;
        this.lastQuoteVersion = q.Last_Quote_Version__c;
        this.quoteVersions = compareItem.quoteVersions;
        this.quoteRecord = q;
    }

    //use when the 'new quote' button is clicked
    @AuraEnabled
    public static ResultResponse createNewQuoteHandler(String submissionId, Integer quoteNumber, String quoteLayer,String selectedBinder) {
        Quote newQuote = new Quote();
        ResultResponse response = new ResultResponse();
        List<Opportunity> opps = [SELECT Id, Name, StageName, Policy__c,Main_Profession__c,Product_Name__c, Account.BillingStateCode,Account.BillingState,
                                  (Select Id, Layer__c From Quotes Where Layer__c =: quoteLayer AND  Status = 'Bound'),
                                  Expiration_Date__c,Effective_Date__c FROM Opportunity WHERE Id =: submissionId LIMIT 1];
		String productName = opps[0].Product_Name__c;
        Integer quoteCount = opps[0].Quotes.size();
        //check if Opp state is restricted for PCC product
        Boolean isOppStateAllowed = OpportunityModifiersCmpController.isPrimaryQuoteAllowedForOppState(opps[0]); 
        if( !isOppStateAllowed ){
            response.isSuccess = false;
            response.errors.add('Primary Quote cannot be created for the selected Insured State : '+opps[0].Account.BillingState);
            return response;
        }
       /* if(productName == 'Professional Indemnity' && quoteCount > 0){
            response.isSuccess = false;
            response.errors.add('You cannot create Quote with same Layer whose Status is Bound.');
            return response;
        }*/
        newQuote = QuoteComparePageGenericController.createNewQuote(submissionId,quoteNumber,quoteLayer);        
        try {
            if(String.isNotBlank(selectedBinder) /*&& newQuote.Product_Name__c == 'Professional Indemnity'*/){
                System.debug('selectedBinder-->'+selectedBinder);
                Master_Binder__c masterBinder = (Master_Binder__c)JSON.deserialize(selectedBinder, Master_Binder__c.class);
                newQuote.Master_Binder__c = masterBinder.Id;
                newQuote.MGA_Commission__c = masterBinder.MGA_Commission__c;     
                Quote quoteDoc = getQuoteDocumentLinks(newQuote);
                newQuote.Policy_Wording_Document__c = newQuote.Policy_Wording_Document__c;  
                if(newQuote.Layer__c != 'Excess')	newQuote.IPID_Document__c = newQuote.IPID_Document__c;  	                    
            }
            insert newQuote;
            response.isSuccess = true;
            response.data = newQuote;
        }catch (DMLException ex){
            response.isSuccess = false;
            response.errors.add(ex.getDmlMessage(0));
        } catch(Exception ex) {
            System.debug('Insert Quote Error: ' + ex.getMessage()+ 'Line-->'+ex.getLineNumber());
            response.isSuccess = false;
            response.errors.add(ex.getMessage());
        }
        return response;
    }
    @AuraEnabled
    public static QuoteCompareItemWrapper createQuoteCompareItem(String newQuoteId, String compareItemString){
        if(String.isBlank(compareItemString)){
            return new QuoteCompareItemWrapper();
        }
        QuoteCompareItemWrapper compareItem = (QuoteCompareItemWrapper) System.JSON.deserialize(compareItemString, QuoteCompareItemWrapper.class);
        System.debug('CompareItem ' + JSON.serialize(compareItem));
        Quote newQuote = [SELECT Id, name, status, Rating_Status__c,Layer__c, Last_Quote_Version__c,Quote_Type__c FROM Quote WHERE Id =: newQuoteId LIMIT 1];
        QuoteCompareItemWrapper newCompareItem = new QuoteCompareItemWrapper(newQuote, compareItem);
        System.debug('ParseWrapperCompareItem' + JSON.serialize(newCompareItem));

        try {
            for(Integer i = 0; i < newCompareItem.quoteFields.size(); i++) {
                newCompareItem.quoteFields[i].value = '';
                newCompareItem.quoteFields[i].fieldId = '';
                if(newCompareItem.quoteFields[i].fieldCondition != '') {
                    String query = generateQuery(newCompareItem.quoteFields[i], newQuoteId);
                    System.debug('queryString' + query);
                    //newCompareItem.quoteFields[i].value = query;
                    List<sObject> results = new List<sObject>();
                    results = Database.query(query);
                    if(results.size() > 0) {
                        System.debug('First Result ' + JSON.serialize(results));
                        sObject res = results[0];
                        String value = String.valueOf(res.get(newCompareItem.quoteFields[i].sourceFieldAPI));
                        if(value == null) value = '';
                        String id = String.valueOf(res.get('Id'));
                        if(id == null) id = '';
                        newCompareItem.quoteFields[i].value = value;
                        newCompareItem.quoteFields[i].fieldId = id;

                        if(newCompareItem.quoteFields[i].sourceObject == 'CoveragesLineItem__c') {
                            newCompareItem.quoteFields[i].format =  String.valueOf(res.get('Option_Type__c'));
                            newCompareItem.quoteFields[i].picklistOption = String.valueOf(res.get('Option_Picklist__c'));
                            newCompareItem.quoteFields[i].min = String.valueOf(res.get('Min_amt__c'));
                            newCompareItem.quoteFields[i].max = String.valueOf(res.get('Max_amt__c'));
                        }
                        if(newCompareItem.quoteFields[i].format == null)
                            newCompareItem.quoteFields[i].format = 'Text';
                        if(newCompareItem.quoteFields[i].picklistOption == null)
                            newCompareItem.quoteFields[i].picklistOption = '';
                        if(newCompareItem.quoteFields[i].sourceObject == 'Rating_Modifier_Factor__c') {
                            //newCompareItem.quoteFields[i].format =  String.valueOf(res.getSObject('Rating_Modifier__r').get('Format__c'));
                            //newCompareItem.quoteFields[i].picklistOption = String.valueOf(res.getSObject('Rating_Modifier__r').get('Picklist_Values__c'));
                            newCompareItem.quoteFields[i].min = String.valueOf(res.getSObject('Rating_Modifier__r').get('Factor_Min__c'));
                            newCompareItem.quoteFields[i].max = String.valueOf(res.getSObject('Rating_Modifier__r').get('Factor_Max__c'));
                        }    
         
        
                        if(newCompareItem.quoteFields[i].picklistOption == null)
                            newCompareItem.quoteFields[i].picklistOption = '';
                    }
                }
            }
        }catch(Exception ex) {
            System.debug('Error: ' + ex.getMessage());
        }
        System.debug('Final Results '+ JSON.serialize(newCompareItem));
        return newCompareItem;
    }



    @AuraEnabled
    public static QuoteCompareItemWrapper createQuoteCompareItemQC(String newQuoteId, QuoteCompareItemWrapper compareItemString){
        /*if(String.isBlank(compareItemString)){
            return new QuoteCompareItemWrapper();
        }*/
        QuoteCompareItemWrapper compareItem = compareItemString;
        //(QuoteCompareItemWrapper) System.JSON.deserialize(compareItemString, QuoteCompareItemWrapper.class);
        System.debug('CompareItem ' + JSON.serialize(compareItem));
        Quote newQuote = [SELECT Id, name, status, Rating_Status__c,Layer__c, Last_Quote_Version__c,Quote_Type__c FROM Quote WHERE Id =: newQuoteId LIMIT 1];
        QuoteCompareItemWrapper newCompareItem = new QuoteCompareItemWrapper(newQuote, compareItem);
        System.debug('ParseWrapperCompareItem' + JSON.serialize(newCompareItem));

        try {
            for(Integer i = 0; i < newCompareItem.quoteFields.size(); i++) {
                newCompareItem.quoteFields[i].value = '';
                newCompareItem.quoteFields[i].fieldId = '';
                if(newCompareItem.quoteFields[i].fieldCondition != '') {
                    String query = generateQuery(newCompareItem.quoteFields[i], newQuoteId);
                    System.debug('queryString' + query);
                    //newCompareItem.quoteFields[i].value = query;
                    List<sObject> results = new List<sObject>();
                    results = Database.query(query);
                    if(results.size() > 0) {
                        System.debug('First Result ' + JSON.serialize(results));
                        sObject res = results[0];
                        String value = String.valueOf(res.get(newCompareItem.quoteFields[i].sourceFieldAPI));
                        if(value == null) value = '';
                        String id = String.valueOf(res.get('Id'));
                        if(id == null) id = '';
                        newCompareItem.quoteFields[i].value = value;
                        newCompareItem.quoteFields[i].fieldId = id;

                        if(newCompareItem.quoteFields[i].sourceObject == 'CoveragesLineItem__c') {
                            newCompareItem.quoteFields[i].format =  String.valueOf(res.get('Option_Type__c'));
                            newCompareItem.quoteFields[i].picklistOption = String.valueOf(res.get('Option_Picklist__c'));
                            newCompareItem.quoteFields[i].min = String.valueOf(res.get('Min_amt__c'));
                            newCompareItem.quoteFields[i].max = String.valueOf(res.get('Max_amt__c'));
                        }
                        if(newCompareItem.quoteFields[i].format == null)
                            newCompareItem.quoteFields[i].format = 'Text';
                        if(newCompareItem.quoteFields[i].picklistOption == null)
                            newCompareItem.quoteFields[i].picklistOption = '';
                        if(newCompareItem.quoteFields[i].sourceObject == 'Rating_Modifier_Factor__c') {
                            //newCompareItem.quoteFields[i].format =  String.valueOf(res.getSObject('Rating_Modifier__r').get('Format__c'));
                            //newCompareItem.quoteFields[i].picklistOption = String.valueOf(res.getSObject('Rating_Modifier__r').get('Picklist_Values__c'));
                            newCompareItem.quoteFields[i].min = String.valueOf(res.getSObject('Rating_Modifier__r').get('Factor_Min__c'));
                            newCompareItem.quoteFields[i].max = String.valueOf(res.getSObject('Rating_Modifier__r').get('Factor_Max__c'));
                        }    
         
        
                        if(newCompareItem.quoteFields[i].picklistOption == null)
                            newCompareItem.quoteFields[i].picklistOption = '';
                    }
                }
            }
        }catch(Exception ex) {
            System.debug('Error: ' + ex.getMessage());
        }
        System.debug('Final Results '+ JSON.serialize(newCompareItem));
        return newCompareItem;
    }

    public static String generateQuery(QuoteCompareItemField field, String id) {
        String query = '';
        if(field.sourceObject == 'Quote') {
            query = 'SELECT ' + field.fieldRequire + ' FROM Quote WHERE Id = \'' + id + '\''; 
        } else {
            query = 'SELECT ' + field.fieldRequire + ' FROM ' + field.sourceObject + ' WHERE Quote__c = \'' + id + '\' '
                    + field.fieldCondition;
        }
        return query;
    }
    public static Quote getQuoteDocumentLinks(Quote quoteObj){
        Map<String,String> contentDocIdPolicyWordingMap = new Map<String,String>();
        Map<String,String> contentDocIdIPIDMap = new Map<String,String>();
        Set<Id> binderRelatedDocIdSet = new Set<Id>();
        List<ContentDocumentLink> docList = new List<ContentDocumentLink>();
        if(quoteObj.Master_Binder__c != null){
            docList = [SELECT ContentDocumentId, Id, LinkedEntityId, ContentDocument.Title FROM ContentDocumentLink WHERE 
                                                         LinkedEntityId =: quoteObj.Master_Binder__c ];
        }
        if(docList.size() > 0){
            for(ContentDocumentLink docLinks : docList){
                binderRelatedDocIdSet.add(docLinks.ContentDocumentId);
            }
            contentDocIdPolicyWordingMap = getContentDocIdPolicyWordingMap(binderRelatedDocIdSet,'Policy Wording');
            if(quoteObj.Layer__c != 'Excess')	contentDocIdIPIDMap = getContentDocIdPolicyWordingMap(binderRelatedDocIdSet,'IPID');                        
            if(!contentDocIdPolicyWordingMap.isEmpty()){
                String contentDocId = contentDocIdPolicyWordingMap.get(quoteObj.Policy_Wording__c);
                System.debug('contentPolicyDocId::'+contentDocId);
                ContentDistribution contentDistObj = [SELECT Id, ContentDocumentId, DistributionPublicUrl, ContentDownloadUrl FROM ContentDistribution
                                                      where ContentDocumentId =: contentDocId];
                if(contentDistObj.DistributionPublicUrl != null){
                    quoteObj.Policy_Wording_Document__c = contentDistObj.DistributionPublicUrl;
                    quoteObj.Policy_Wording_ContentDoc_Id__c = contentDocId;
                }  
            }   
            if(!contentDocIdIPIDMap.isEmpty()){
                String contentIPIDDocId = contentDocIdIPIDMap.get(quoteObj.Policy_Wording__c);
                System.debug('contentIPIDDocId::'+contentIPIDDocId);
                ContentDistribution contentDistObj = [SELECT Id, ContentDocumentId, DistributionPublicUrl, ContentDownloadUrl FROM ContentDistribution
                                                      where ContentDocumentId =: contentIPIDDocId limit 1];
                if(contentDistObj.DistributionPublicUrl != null){
                    quoteObj.IPID_Document__c = contentDistObj.DistributionPublicUrl;  
                    quoteObj.IPID_ContentDoc_Id__c = contentIPIDDocId;
                }  
            } 
        }
        return quoteObj;
    }
    public static Map<String,String> getContentDocIdPolicyWordingMap(Set<Id> binderRelatedDocIdSet,String documentType){
        Map<String,String> contentDocIdPolicyWordingMap = new Map<String,String>();
        List<ContentVersion> contentVersionList = [SELECT Id, Title,Document_Type__c, Policy_Wording__c, ContentDocumentId FROM ContentVersion 
                                                  where ContentDocumentId IN :binderRelatedDocIdSet AND Policy_Wording__c != null AND Document_Type__c =: documentType];
        if(contentVersionList.size() > 0){
            for(ContentVersion versionObj : contentVersionList){
				contentDocIdPolicyWordingMap.put(versionObj.Policy_Wording__c,versionObj.ContentDocumentId);             			   
            }  
        }
        return contentDocIdPolicyWordingMap;
    }
    @AuraEnabled
    public static void updateSelectedBinder(String quoteId, String selectedBinder){
        Map<String,String> contentDocIdPolicyWordingMap = new Map<String,String>();
        Map<String,String> contentDocIdIPIDMap = new Map<String,String>();
        Set<Id> binderRelatedDocIdSet = new Set<Id>();
        try{
            List<Quote> quoteList = [Select Id,Name,Policy_Wording_Document__c,Policy_Wording__c,Layer__c,IPID_Document__c,
                                     Product_Name__c,Master_Binder__c,MGA_Commission__c from Quote where Id= :quoteId];
            if(quoteList.size() > 0 && quoteList[0].Product_Name__c=='Professional Indemnity'){
                if(String.isNotBlank(selectedBinder)){
                    Master_Binder__c masterBinder = (Master_Binder__c)JSON.deserialize(selectedBinder, Master_Binder__c.class);
                    quoteList[0].Master_Binder__c = masterBinder.Id;
                    quoteList[0].MGA_Commission__c = masterBinder.MGA_Commission__c;
                    //policy Wording Docuent -- 41099/41100  
                    Quote quoteDoc = getQuoteDocumentLinks(quoteList[0]);
                    quoteList[0].Policy_Wording_Document__c = quoteDoc.Policy_Wording_Document__c;  
                    if(quoteList[0].Layer__c != 'Excess')	quoteList[0].IPID_Document__c = quoteDoc.IPID_Document__c;  	                    
                    update quoteList;
                    System.debug('quoteList-->'+quoteList);
                }
            }            
        }catch(Exception ex){
            throw new AuraHandledException(CommonUtil.getExceptionMessage(ex));
        }
    }

    //use when the 'save' button is clicked
    @AuraEnabled
    public static ResultResponse updateCompareItem(String updateObj, String quoteId, String quoteCompareItemUpdate, List<Quote_Version_Item__c> quoteVerItemsUpdate){
        ResultResponse resultResponse = new ResultResponse();
        System.debug('String update: ' + updateObj);
        ListUpdateObject upObj = (ListUpdateObject) System.JSON.deserialize(updateObj, ListUpdateObject.class);
        List<QuoteCompareItemField> quoteItemFieldsUpdate = new List<QuoteCompareItemField>();
        if(quoteCompareItemUpdate != ''){
            quoteItemFieldsUpdate = (List<QuoteCompareItemField>) System.JSON.deserialize(quoteCompareItemUpdate, List<QuoteCompareItemField>.class);
        }
        System.debug('Update objects: ' + upObj.listUpdate);
        //List<sObject> lstObject = new List<sObject>();
        Map<String, sObject> mapObject = new Map<String, sObject>();
        Savepoint sp = Database.setSavepoint();
        try {
            List<Quote_Version__c> quoteVers = createQuoteVersion(quoteId, quoteItemFieldsUpdate, quoteVerItemsUpdate);
            
            // List<CoveragesLineItem__c> listCoverageLineItem = new List<CoveragesLineItem__c>();
            // List<Rating_Modifier_Factor__c> listRatingModifierFactor = new List<Rating_Modifier_Factor__c>();
            //List<String> coverageNames = new List<String>();
            //List<String> factorNames = new List<String>();
            
            // Map<String, String> mapIdValueCLI = new Map<String, String>();
            // String cliFieldApi = 'Option_Value_Default__c';
            // List<String> coverageFields = new List<String>();
            // List<String> factorFields = new List<String>();
            for(Integer i = 0; i < upObj.listUpdate.size(); i++) {
                if(upObj.listUpdate[i].id != '') {
                    // if(upObj.listUpdate[i].sourceObject == 'CoveragesLineItem__c') {
                    //     coverageNames.add(upObj.listUpdate[i].name);
                    //     if(!coverageFields.contains(upObj.listUpdate[i].fieldAPI))
                    //         coverageFields.add(upObj.listUpdate[i].fieldAPI);
                    // }
                    // else 
                    // if(upObj.listUpdate[i].sourceObject == 'Rating_Modifier_Factor__c') { 
                    //     factorNames.add(upObj.listUpdate[i].name);
                    //     if(!factorFields.contains(upObj.listUpdate[i].fieldAPI))
                    //         factorFields.add(upObj.listUpdate[i].fieldAPI);
                    // }
                    // else {
                        sObject obj;
                        if(mapObject.get(upObj.listUpdate[i].id) == null) {
                            obj = Id.valueOf(upObj.listUpdate[i].id).getSObjectType().newSObject();
                            obj.put('Id', upObj.listUpdate[i].id);
                        } 
                        else obj = mapObject.get(upObj.listUpdate[i].id);
                        
                        if(upObj.listUpdate[i].value == '') {
                            obj.put(upObj.listUpdate[i].fieldAPI, null);
                        } else {
                            SObjectType r = obj.getSObjectType();
                            DescribeSObjectResult d = r.getDescribe();
                            Schema.DescribeFieldResult fieldDescribe = d.fields.getMap().get(upObj.listUpdate[i].fieldApi).getDescribe();
                            System.debug('Field type: ' + fieldDescribe.getType());
                            if(fieldDescribe.getType() == Schema.DisplayType.Double || fieldDescribe.getType() == Schema.DisplayType.Currency
                                || fieldDescribe.getType() == Schema.DisplayType.Percent) {
                                obj.put(upObj.listUpdate[i].fieldApi, Double.valueOf(upObj.listUpdate[i].value));
                                    
                            }
                            else if(fieldDescribe.getType() == Schema.DisplayType.Date)
                                if(upObj.listUpdate[i].value != null){
                                    obj.put(upObj.listUpdate[i].fieldAPI, Date.valueOf(upObj.listUpdate[i].value));
                                }else{
                                    obj.put(upObj.listUpdate[i].fieldAPI, null);
                                }
                            else if(fieldDescribe.getType() == Schema.DisplayType.DateTime)
                                if(upObj.listUpdate[i].value != null){
                                    obj.put(upObj.listUpdate[i].fieldAPI, DateTime.valueOf(upObj.listUpdate[i].value));
                                }else{
                                    obj.put(upObj.listUpdate[i].fieldAPI, null);
                                } 
                            else
                                obj.put(upObj.listUpdate[i].fieldAPI, upObj.listUpdate[i].value);
                        }
                        
                        //lstObject.add(obj);
                        mapObject.put(obj.Id, obj);

                        // if(upObj.listUpdate[i].sourceObject == 'CoveragesLineItem__c') {
                        //     mapIdValueCLI.put(upObj.listUpdate[i].id, upObj.listUpdate[i].value);
                        //     cliFieldApi = upObj.listUpdate[i].fieldApi;
                        // }
                    //}
                }
            }

            // if(coverageNames.size() > 0) {
            //     String query = 'SELECT Id, Name, Limits_Deductibles__r.Name, ' + String.join(coverageFields, ',') + ' FROM CoveragesLineItem__c WHERE Quote__c = \'' + quoteId + '\' AND Limits_Deductibles__r.Name IN (\'' + String.join(coverageNames,  '\',\'') + '\') ';
            //     //Map<Id, CoveragesLineItem__c> itemMap = new Map<Id, CoveragesLineItem__c>((List<CoveragesLineItem__c>) Database.query(query));
            //     List<CoveragesLineItem__c> listItem = (List<CoveragesLineItem__c>) Database.query(query);
            //     for(CoveragesLineItem__c obj : listItem) 
            //         for(Integer i = 0; i < upObj.listUpdate.size(); i++) {
            //             //if(itemMap.get(upObj.listUpdate[i].id) != null) {
            //             if(obj.getSObject('Limits_Deductibles__r').get('Name') == upObj.listUpdate[i].name) {
            //                 //CoveragesLineItem__c obj = itemMap.get(upObj.listUpdate[i].id);
            //                 SObjectType r = obj.getSObjectType();
            //                 DescribeSObjectResult d = r.getDescribe();
            //                 Schema.DescribeFieldResult fieldDescribe = d.fields.getMap().get(upObj.listUpdate[i].fieldApi).getDescribe();
            //                 if(fieldDescribe.getType() == Schema.DisplayType.Double || fieldDescribe.getType() == Schema.DisplayType.Currency
            //                     || fieldDescribe.getType() == Schema.DisplayType.Percent)
            //                     obj.put(upObj.listUpdate[i].fieldApi, Double.valueOf(upObj.listUpdate[i].value));
            //                 else if(fieldDescribe.getType() == Schema.DisplayType.Date)
            //                 obj.put(upObj.listUpdate[i].fieldAPI, Date.valueOf(upObj.listUpdate[i].value));
            //                 else if(fieldDescribe.getType() == Schema.DisplayType.DateTime)
            //                     obj.put(upObj.listUpdate[i].fieldAPI, DateTime.valueOf(upObj.listUpdate[i].value));
            //                 else
            //                     obj.put(upObj.listUpdate[i].fieldAPI, upObj.listUpdate[i].value);
            //                 //lstObject.add(obj);
            //                 mapObject.put(obj.Id, obj);
            //             }
            //         }
            // }
            // if(factorFields.size() > 0) {
            //     String query = 'SELECT Id, Name, Rating_Modifier__r.Name, ' + String.join(factorFields, ',') + ' FROM Rating_Modifier_Factor__c WHERE Quote__c = \'' + quoteId + '\' AND Rating_Modifier__r.Name IN (\'' + String.join(factorNames,  '\',\'') + '\') ';
            //     //Map<Id, Rating_Modifier_Factor__c> itemMap = new Map<Id, Rating_Modifier_Factor__c>((List<Rating_Modifier_Factor__c>) Database.query(query));
            //     List<Rating_Modifier_Factor__c> listItem = (List<Rating_Modifier_Factor__c>) Database.query(query);
            //     for(Rating_Modifier_Factor__c obj : listItem)
            //         for(Integer i = 0; i < upObj.listUpdate.size(); i++) {
            //             //if(itemMap.get(upObj.listUpdate[i].id) != null) {
            //             if(obj.getSObject('Rating_Modifier__r').get('Name') == upObj.listUpdate[i].name) {
            //                 //Rating_Modifier_Factor__c obj = itemMap.get(upObj.listUpdate[i].id);
            //                 SObjectType r = obj.getSObjectType();
            //                 DescribeSObjectResult d = r.getDescribe();
            //                 Schema.DescribeFieldResult fieldDescribe = d.fields.getMap().get(upObj.listUpdate[i].fieldApi).getDescribe();
            //                 if(fieldDescribe.getType() == Schema.DisplayType.Double || fieldDescribe.getType() == Schema.DisplayType.Currency
            //                     || fieldDescribe.getType() == Schema.DisplayType.Percent)
            //                     obj.put(upObj.listUpdate[i].fieldApi, Double.valueOf(upObj.listUpdate[i].value));
            //                 else if(fieldDescribe.getType() == Schema.DisplayType.Date)
            //                     obj.put(upObj.listUpdate[i].fieldAPI, Date.valueOf(upObj.listUpdate[i].value));
            //                 else if(fieldDescribe.getType() == Schema.DisplayType.DateTime)
            //                     obj.put(upObj.listUpdate[i].fieldAPI, DateTime.valueOf(upObj.listUpdate[i].value));
            //                 else
            //                     obj.put(upObj.listUpdate[i].fieldAPI, upObj.listUpdate[i].value);
            //                 // lstObject.add(obj);
            //                 mapObject.put(obj.Id, obj);
            //             }
            //         }
            // }


            // String mplRetentionValue = '';
            // Boolean hasMPLRetention = false;
            // for(UpdateObject obj : upObj.listUpdate) {
            //     if(obj.name == 'MPL - Retention') {
            //         mplRetentionValue = obj.value;
            //         hasMPLRetention = true;
            //         break;
            //     }
            // }
            // if(hasMPLRetention) {
            //     List<CoveragesLineItem__c> listRetention = [SELECT Id, Name FROM CoveragesLineItem__c 
            //                                             WHERE Quote__c =: quoteId
            //                                             AND Coverage__r.Page_Section__c = 'ADDMPLCOVER'
            //                                             AND CoverageLineItemType__c = 'Deductible Option'];
            //     for(CoveragesLineItem__c cov : listRetention) {
            //         cov.Option_Value_Default__c = mplRetentionValue;
            //         mapObject.put(cov.Id, cov);
            //     }
            // }
           /* Quote q = (Quote)mapObject.get(quoteId);
            List<Quote> oldQuotes = [select Id,Effective_Date__c from Quote where id = :quoteId];
            if(q.Effective_Date__c + 5 < oldQuotes[0].Effective_Date__c){
                resultResponse.errors.add('Effective date is more than 5 days backdate');
                return  resultResponse;
            } */
            if(mapObject.values().size() > 0)
                update mapObject.values();
            system.debug('mapObject.values()-->'+mapObject.values());
            // if(String.isBlank(cliFieldApi))
            //     cliFieldApi = 'Option_Value_Default__c';
            // if(!mapIdValueCLI.values().isEmpty())
            //     updateSyncLimitDeductible(mapIdValueCLI, cliFieldApi, quoteId);

            // if(listCoverageLineItem.size() > 0)
            //     upsert listCoverageLineItem;
            // if(listRatingModifierFactor.size() >0)
            //     upsert listRatingModifierFactor;
            resultResponse.isSuccess = true;
            //resultResponse.data = quoteVers;
            resultResponse.data = mapObject.values();
        } catch(Exception ex) {
            System.debug('Update error: ' + ex.getMessage()+'Line Number: '+ex.getLineNumber());
            Database.rollback(sp);
            resultResponse.isSuccess = false;
            resultResponse.data = null;
            resultResponse.errors.add(CommonUtil.getExceptionMessage(ex));
            // return ex.getLineNumber() + ' - ' + ex.getMessage();
        }
        return resultResponse;
    }

    // public static void updateSyncLimitDeductible(Map<String, String> mapIdValueCLI, String fieldApi, String quoteId) {
    //     Map<String, CoveragesLineItem__c> mapCLI = new Map<String, CoveragesLineItem__c> (
    //                                                         [SELECT Id, Name, Limits_Deductibles__r.Sync_From__c 
    //                                                         FROM CoveragesLineItem__c 
    //                                                         WHERE Id IN :mapIdValueCLI.keySet()
    //                                                         AND Quote__c =: quoteId]);
    //     Map<String, String> mapIdValueLimitDeductible = new Map<String, String>();
    //     Map<String, String> mapIdParentChild = new Map<String,String>();
    //     Integer indexRoot = 0;
    //     //get map of id of limit deductble and value of coverage line items;
    //     for(String cliId : mapCLI.keySet()) {
    //         if(mapIdValueCLI.get(cliId) != null) {
    //             mapIdValueLimitDeductible.put(mapCLI.get(cliId).Limits_Deductibles__c, mapIdValueCLI.get(cliId));
    //         }
    //     }
    
    //     Map<String, Coverage_Limits_Deductibles__c> mapChildLimitDeductible = new Map<String, Coverage_Limits_Deductibles__c>();
    //     mapChildLimitDeductible = getChildLimitDeductible(mapIdValueLimitDeductible.keySet());
    //     //use this loop to remove all the value of the child limit deductible if the child and parent is update at the same time.
    //     for(String id : mapChildLimitDeductible.keySet()) {
    //         if(mapIdValueLimitDeductible.get(id) != null) {
    //             mapIdValueLimitDeductible.remove(id);
    //         }
    //     }
   
    //     List<CoveragesLineItem__c> currentCLI = [SELECT Id, Limits_Deductibles__r.Name, Limits_Deductibles__r.Sync_From__c 
    //                                                 FROM CoveragesLineItem__c 
    //                                                 WHERE Limits_Deductibles__c IN : mapChildLimitDeductible.keySet()
    //                                                 AND Quote__c =: quoteId];

    //     List<CoveragesLineItem__c> listUpdateCLI = new List<CoveragesLineItem__c>();
    //     for(String id : mapIdValueLimitDeductible.keySet()) {
    //         List<CoveragesLineItem__c> listSorted = new List<CoveragesLineItem__c>();
    //         listSorted = getChildCLI(id, mapIdValueLimitDeductible.get(id), fieldApi, currentCLI);
    //         listUpdateCLI.addAll(listSorted);
    //     } 

    //     if(!listUpdateCLI.isEmpty())
    //         update listUpdateCLI;
    // }

    // //recursive method to get all the child of that limit deductible
    // public static Map<String, Coverage_Limits_Deductibles__c> getChildLimitDeductible(Set<String> parentId) {
    //     Map<String, Coverage_Limits_Deductibles__c> childLimitDeductible = new Map<String, Coverage_Limits_Deductibles__c> (
    //                                                                             [SELECT Id, Name, Sync_From__c 
    //                                                                             FROM Coverage_Limits_Deductibles__c
    //                                                                             WHERE Sync_From__c IN :parentId]);
        
    //     Map<String, Coverage_Limits_Deductibles__c> grandChildLimitDeductible = new Map<String, Coverage_Limits_Deductibles__c>();
    //     if(!childLimitDeductible.isEmpty()) {
    //         grandChildLimitDeductible = getChildLimitDeductible(childLimitDeductible.keySet());
    //         childLimitDeductible.putAll(grandChildLimitDeductible);
    //     }
    //     return childLimitDeductible;
    // }

    // //recursive method to pass the value from parent to child
    // public static List<CoveragesLineItem__c> getChildCLI(String parentId, String parentValue,
    //                                                     String fieldAPI, List<CoveragesLineItem__c> childCoverageLineItem) {
    //     List<CoveragesLineItem__c> sortedCLI = new List<CoveragesLineItem__c>();
    //     for(CoveragesLineItem__c cli : childCoverageLineItem) {
    //         if(cli.Limits_Deductibles__r.Sync_From__c == parentId) {
    //             SObjectType r = cli.getSObjectType();
    //             DescribeSObjectResult d = r.getDescribe();
    //             Schema.DescribeFieldResult fieldDescribe = d.fields.getMap().get(fieldApi).getDescribe();
    //             if(fieldDescribe.getType() == Schema.DisplayType.Double || fieldDescribe.getType() == Schema.DisplayType.Currency
    //                 || fieldDescribe.getType() == Schema.DisplayType.Percent) 
    //                 cli.put(fieldApi, Double.valueOf(parentValue));
    //             else if(fieldDescribe.getType() == Schema.DisplayType.Date)
    //                 cli.put(fieldAPI, Date.valueOf(parentValue));
    //             else if(fieldDescribe.getType() == Schema.DisplayType.DateTime)
    //                 cli.put(fieldAPI, DateTime.valueOf(parentValue));
    //             else
    //                 cli.put(fieldAPI, parentValue);
                
    //             sortedCLI.add(cli);
    //         }
    //     } 
    //     List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        
    //     if(!sortedCLI.isEmpty()) {
    //         result.addAll(sortedCLI);
    //         for(CoveragesLineItem__c cli : sortedCLI) {
    //             List<CoveragesLineItem__c> sortedCLIChild = new List<CoveragesLineItem__c>();
    //             sortedCLIChild = getChildCLI(cli.Limits_Deductibles__c, parentValue, fieldAPI, childCoverageLineItem);
    //             result.addAll(sortedCLIChild);
    //         }
    //     }
    //     return result;
    // } 

    public static List<Quote_Version__c> createQuoteVersion(String quoteId, List<QuoteCompareItemField> quoteItemFieldsUpdate, List<Quote_Version_Item__c> quoteVerItemsUpdate ) {
        List<Quote_Version__c> quoteVers = new List<Quote_Version__c>();
        if(!String.isBlank(quoteId)){
            List<Quote> quots = [SELECT Id, Last_Quote_Version__c FROM Quote WHERE Id =: quoteId];
            if(!quots.isEmpty()){
                List<Quote_Version__c> quoteVersionList = [SELECT Id, Quote__c, Name
                                                    FROM Quote_Version__c
                                                    WHERE Quote__c =: quoteId];
                // create first Quote Version
                if(quoteVersionList.isEmpty()){
                    Quote_Version__c quoteVersion = new Quote_Version__c();
                    quoteVersion.Quote__c = quoteId;
                    quoteVersion.Name = 'Version 1';
                    upsert quoteVersion;
                    quots[0].Last_Quote_Version__c = 'Version 1';
                    update quots[0];
                    System.debug('@@@quoteVersion: ' + quoteVersion);
                    List<Quote_Version_Item__c> quoteVerItems = new List<Quote_Version_Item__c>();
                    if(!quoteItemFieldsUpdate.isEmpty()){
                        for(QuoteCompareItemField quoteComItemField : quoteItemFieldsUpdate){
                            if(quoteComItemField.fieldId != ''){
                                sObject obj = Id.valueOf(quoteComItemField.fieldId).getSObjectType().newSObject();
                                SObjectType r = obj.getSObjectType();
                                DescribeSObjectResult d = r.getDescribe();
                                String objectAPIName = d.getName();
                                Quote_Version_Item__c quoteVersionItem = new Quote_Version_Item__c();
                                quoteVersionItem.Quote_Version__c = quoteVersion.Id;
                                quoteVersionItem.Object_Id__c = quoteComItemField.fieldId;
                                quoteVersionItem.Source_Field_API__c = quoteComItemField.sourceFieldAPI;
                                quoteVersionItem.Source_Object__c = objectAPIName;
                                quoteVersionItem.Value__c = quoteComItemField.value;
                                quoteVerItems.add(quoteVersionItem);
                            }
                        }
                        if(!quoteVerItems.isEmpty()){
                            upsert quoteVerItems;
                        }
                    }
                }
                // create new Quote Version
                if(quoteVerItemsUpdate != null){
                    String lastQuoteVer = quots[0].Last_Quote_Version__c;
                    if(!String.isBlank(lastQuoteVer)){
                        Integer quoteVerNumber = Integer.valueOf((lastQuoteVer.split(' '))[1]) + 1;
                        Quote_Version__c newQuoteVer = new Quote_Version__c();
                        newQuoteVer.Quote__c = quoteId;
                        newQuoteVer.Name = 'Version ' + quoteVerNumber;
                        upsert newQuoteVer;
                        quots[0].Last_Quote_Version__c = 'Version ' + quoteVerNumber;
                        update quots[0];
                        List<Quote_Version_Item__c> newQuoteVerItems = new List<Quote_Version_Item__c>();
                        for (Integer i = 0; i < quoteVerItemsUpdate.size(); i++) {
                            Quote_Version_Item__c newQuoteVerItem = new Quote_Version_Item__c();
                            newQuoteVerItem.Quote_Version__c = newQuoteVer.Id;
                            newQuoteVerItem.Object_Id__c = quoteVerItemsUpdate[i].Object_Id__c;
                            newQuoteVerItem.Source_Field_API__c = quoteVerItemsUpdate[i].Source_Field_API__c;
                            newQuoteVerItem.Source_Object__c = quoteVerItemsUpdate[i].Source_Object__c;
                            newQuoteVerItem.Value__c = quoteVerItemsUpdate[i].Value__c;
                            newQuoteVerItems.add(newQuoteVerItem);
                        }
                        if(!newQuoteVerItems.isEmpty()){
                            upsert newQuoteVerItems;
                        }
                    }
                    
                }
            }
            quoteVers = [SELECT Id, Quote__c, Name
                            FROM Quote_Version__c
                            WHERE Quote__c =: quoteId];
        }
        return quoteVers;
    }

    //use when 'delete' button is clicked
    @AuraEnabled
    public static Boolean deleteQuoteHandler(String quoteId) {
        Savepoint sp = Database.setSavepoint();
        sObject deleteQuote;
        try {
            if(quoteId != null && quoteId != '') {
                deleteQuote = Id.valueOf(quoteId).getSObjectType().newSObject();
                deleteQuote.put('Id', quoteId);
                delete deleteQuote;
            }

        } catch(Exception ex) {
            System.debug('Delete error: ' + ex.getMessage());
            Database.rollback(sp);
            return false;
        }
        return true;
    }

    //use when user click the clone button
    @AuraEnabled
    public static ResultResponse cloneQuoteHandler(String quoteId){
        ResultResponse result = new ResultResponse();
        // Savepoint sp = Database.setSavepoint();
        
        // try { 
        //     //  List<Rating_Modifier_Factor__c> listRatingModifierFactor = [SELECT CreatedById, Factor_Default_Value__c, Factor_Max__c, Factor_Min__c,
        //     //                                                     Factor_Value__c, LastModifiedById, Rating_Modifier__c 
        //     //                                                     FROM Rating_Modifier_Factor__c WHERE Quote__c =: quoteId];
        //     // List<Rating_Modifier_Factor__c> cloneRatingModifierFactors = new List<Rating_Modifier_Factor__c>();
        //     // for(Integer i = 0; i < listRatingModifierFactor.size(); i++) {
        //     //     Rating_Modifier_Factor__c cloneRMF = listRatingModifierFactor[i].clone(false, true, false, false);
        //     //     cloneRMF.Quote__c = cloneQuote.Id;
        //     //     cloneRatingModifierFactors.add(cloneRMF); 
        //     // }
        //     // List<Rating_Modifier_Factor__c> deleteRMFs = [SELECT Id, Name FROM Rating_Modifier_Factor__c WHERE Quote__c =: cloneQuote.Id];
        //     // delete deleteRMFs; 
        //     // insert cloneRatingModifierFactors;
            
        // } catch(Exception ex) {
        //     System.debug('Clone error: ' + ex.getMessage());
        //     Database.rollback(sp);
        //     return 'Clone error: ' + ex.getMessage();
        // }
        // return cloneQuote.Id;
        Quote quote = [select Id,Product_Name__c,Quote_Type__c from Quote where Id =:quoteId];
        if(quote != null){
            if(quote.Product_Name__c == 'Professional Indemnity' && quote.Quote_Type__c != 'New Business' && quote.Quote_Type__c != 'Renewal'){
                result.errors.add('Amendment/Cancellations Quotes Cannot be Cloned');
            }else{
                result = CloneQuoteHandler.cloneQuoteWithChildren(quoteId, null);
                
                 /******* New Lines for 54090 Ticket *****/
                
              /*  Quote testQuote = (Quote)result.data;
                testQuote.Master_Binder__c = null;
                testQuote.Policy_Wording_Document__c =  null;
                testQuote.IPID_Document__c = null;
                
                update testQuote;*/
                
                

            }
        }  
        return result;
    }

    @AuraEnabled
    public static Boolean checkAdmittedState(String quoteId){
        List<Quote> qt = [Select Account.BillingState From Quote Where Id =: quoteId];
        if(qt.size() > 0){
            if(qt[0].Account.BillingState != null){
                String admittedResult = ApiUtil.getAdmittedStatus(qt[0].Account.BillingState);
                if(admittedResult == 'false'){
                    return false;
                }
            }
        }
        return true;
    }

    @AuraEnabled
    public static ResultResponse cloneExcessQuoteHandler(String quoteId, String quoteLayer){
        ResultResponse result = new ResultResponse();
        Map<String,Object> fieldUpdateMap = new Map<String,Object>();
        fieldUpdateMap.put('Layer__c',quoteLayer);
        result = CloneQuoteHandler.cloneQuoteWithChildren(quoteId, fieldUpdateMap); 
        return result;
    }

    @AuraEnabled
    public static ResultResponse updateQuoteInProgress(String quoteId){
        ResultResponse response = new ResultResponse();
        Savepoint sp = Database.setSavepoint();
        try {

            Quote updateQuote = [SELECT Id, name FROM Quote WHERE Id =: quoteId Limit 1];
            updateQuote.Status = 'In Progress';
            update updateQuote;
            response.isSuccess = true;
            response.data = updateQuote;
            return response;
        } catch (Exception ex) {
            Database.rollback(sp);
            response.isSuccess = false;
            response.errors.add(ex.getMessage());
            return response;
        }
    }

    /**********************************
    * Method Name: fetchMTAs
	* Author: Jai
	* Date: 19-OCT-2021 
	* Params: quoteId
	* Return: Product_Setting__mdt
    ************************************/

    @AuraEnabled(cacheable = true)
    public static boolean fetchMTAs( String quoteId ){
        Quote q = [Select Id, Quote_Type__c, Status, Product_Name__c from Quote where Id = :quoteId];
        Product_Setting__mdt profSetting = [Select Id, DeveloperName, Endorsement_Operation__c from Product_Setting__mdt where MasterLabel = :q.Product_Name__c];
        boolean isMTAQuote = false;
        if( profSetting.DeveloperName != 'Professional_Indemnity' && String.isNotBlank(profSetting.Endorsement_Operation__c) ){
            for( String s : profSetting.Endorsement_Operation__c.split(',') ){
                if( s == q.Quote_Type__c){
                    isMTAQuote = true;
                    break;
                }
            }
        }
        return isMTAQuote;
    }

    // public class FieldProperty {
    //     public List<String> fieldIds {get; set;}
    //     public List<String> fieldValues {get; set;}
    //     public String fieldCondition {get; set;}
    //     public String fieldRequire {get; set;}
    //     public FieldProperty() {
    //         this.fieldIds = new List<String>();
    //         this.fieldValues = new List<String>();
    //         this.fieldCondition = '';
    //         this.fieldRequire = '';
    //     }

    //     public FieldProperty(List<String> ids, List<String> values, String condition, String require) {
    //         this.fieldIds = ids;
    //         this.fieldValues = values;
    //         this.fieldCondition = condition;
    //         this.fieldRequire = require;
    //     }
    // }

    public class UpdateObject {
        public String id {get; set;}
        public String name {get; set;}
        public String sourceObject {get; set;}
        public String fieldApi {get; set;}
        public String value {get; set;}

        public UpdateObject() {
            this.id = '';
            this.name = '';
            this.sourceObject = '';
            this.fieldApi = '';
            this.value = '';
        }
    }

    public class ListUpdateObject {
        public List<UpdateObject> listUpdate;

        public ListUpdateObject() {
            this.listUpdate = new List<UpdateObject>();
        }
    }

}