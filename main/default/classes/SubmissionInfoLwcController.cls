/**
 * @File Name          : SubmissionInfoLwcController.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : Vinayesh
 * @Last Modified On   : 09-22-2021
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/3/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public with sharing class SubmissionInfoLwcController {
    public static final String QUOTE_PROCESS_OBJ = 'Quote_Process__c';
    public static final String OPPORTUNITY_OBJ = 'Opportunity';

    /*************************************************
    * Method Name: getSubmissionId
    * Author: Hang Lam
    * Date: 03/04/2020
    * Params: recordId - Record Id
    * Return: oppId - Opportunity Id
    * Description: get opportunity Id from record Id
    * Revision: 
    *************************************************/
    @AuraEnabled
    public static ResultResponse getSubmissionId(Id recordId) {
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        String oppId;
        ResultResponse result = new ResultResponse();
        system.debug('sObjName:::' + sObjName);
        if(sObjName == QUOTE_PROCESS_OBJ) {
            List<Quote_Process__c> quotePrs = [SELECT Id, Submission__c FROM Quote_Process__c WHERE Id = :recordId];
            if(!quotePrs.isEmpty()){
                if(quotePrs[0].Submission__c != null){
                    oppId = quotePrs[0].Submission__c;
                }
            }
        }
        if(sObjName == OPPORTUNITY_OBJ) {
            oppId = recordId;
        }
        //tuan.d.nguyen added 24-Jun-2020 
        // inner query added by Jai
        list<String> applicableStatuses = new list<String>{'In Progress','Rated','Referred','Quoted'};
        Opportunity opp = [SELECT Id, StageName, 
                          ( SELECT Id, Quote_Type__c from Quotes where Status IN :applicableStatuses AND Quote_Type__c = 'Amendment' LIMIT 1 ) 
                          FROM Opportunity WHERE Id =: oppId LIMIT 1];
        result.isSuccess = true;
        result.data = opp;
        return result;
    }

    /*************************************************
    * Method Name: getListBrokerInfo
    * Author: Giang Phan
    * Date: 
    * Params: 
    * Return: 
    * Description:
    * Revision: 
    *************************************************/
    @AuraEnabled
    public static List<WrapperField> getListBrokerInfo(string submissionId){
        string oppRecordType = [select Id,RecordType.Name from Opportunity where Id =:submissionId].RecordType.Name;
        List<SectionSetting__c> listSectonSetting = [SELECT Id,Name,Main_Section__c,Order__c,Product__c,Record_Type__c,
                                                        Sub_Section__c,Source_Object__c,Source_Field_Label__c,
                                                        Source_Field_API__c,Format__c, Component__c, DisplayType__c,
                                                        Lookup_To__c, Is_Required__c,Profile_Name_for_Read_Only__c
                                                      FROM SectionSetting__c
                                                        WHERE Component__c = 'Submission Info' 
                                                        AND Main_Section__c = 'Broker Account'
                                                        ORDER BY Order__c ASC];

        for(Integer i = 0; i < listSectonSetting.size(); i++){
            if(string.isNotBlank(oppRecordType) && oppRecordType == 'Celerity' && listSectonSetting[i].Record_Type__c == 'Aqueous'){
                listSectonSetting.remove(i);
            }
        }
        
        if(!listSectonSetting.isEmpty()){
            return convertToListWrapperField(listSectonSetting);
        } 
        return null;                                                     
    }

    @AuraEnabled
    public static String getProductName(Id recordId){
        String result = null;
        String productName = null;
        String quoteProcessAccountId = null;
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        Map<String,String> recordTypeMap = new Map<String,String>();

        for(RecordType rec : [SELECT Id, Name, DeveloperName, Description FROM RecordType WHERE SobjectType = 'Account']) {
            recordTypeMap.put(rec.Name, rec.Id);
        }
        system.debug('sObjName:' + sObjName);
        if(sObjName == QUOTE_PROCESS_OBJ) {
            List<Quote_Process__c> listQuoteProcess = [SELECT Id, Account__c,Submission__r.Product__r.Name FROM Quote_Process__c WHERE Id = :recordId];
            quoteProcessAccountId = listQuoteProcess[0].Account__c;
            if(listQuoteProcess[0].Submission__r != null) {
                productName = listQuoteProcess[0].Submission__r.Product__r.Name;
            }
        }
        if(sObjName == OPPORTUNITY_OBJ) {
            List<Opportunity> listOpp = [SELECT Id,StageName,Product__r.Name,(SELECT Id, Account__c,Submission__r.StageName, Submission__c, Status__c FROM Quote_Process__r LIMIT 1) FROM Opportunity WHERE Id = :recordId];
            quoteProcessAccountId = listOpp[0].Quote_Process__r[0].Account__c;
            productName =  listOpp[0].Product__r.Name;
        }
        if(productName.contains('Standalone')){
            result = productName.split(' ')[0];
        }else{
            result = productName;
        }
        System.debug('result:' + result);
        return result;
    }
    /*************************************************
    * Method Name: getListSectionSetting
    * Author: Hang Lam
    * Date: 03/04/2020
    * Params: 
    * Return: TabItem - tab information
    * Description: get List Section Setting
    * Revision:
    *************************************************/
    @AuraEnabled
    public static TabItem getListSectionSetting(Id recordId) {
        String productName = getProductName(recordId);
        System.debug('>>>productName>>>'+productName);
        //Added by Vinayesh for testing. Needs to be modified.
        // if(productName == 'Private Company Combo'){
        //     productName = 'Cyber';
        // }
        TabItem tabItem = new TabItem();
        List<SectionSetting__c> listSectonSetting = [SELECT Id,Name,Main_Section__c,Order__c,
                                            Sub_Section__c,Source_Object__c,Source_Field_Label__c,
                                            Source_Field_API__c,Format__c, Component__c, DisplayType__c,
                                            Lookup_To__c, Is_Required__c,Profile_Name_for_Read_Only__c
                                            FROM SectionSetting__c
                                            WHERE Component__c = 'Submission Info'
                                            AND Main_Section__c != 'Broker Account'
                                            AND Product__c INCLUDES (:productName)
                                            ORDER BY Order__c ASC];    
		Map<Decimal, SectionSetting__c> orderSectionSettingMap = new Map<Decimal, SectionSetting__c>();
        Map<String,List<SectionSetting__c>> mapParentNoSub = new Map<String,List<SectionSetting__c>>();
        Map<String,List<SectionSetting__c>> mapParentWithSub = new Map<String,List<SectionSetting__c>>();
        Map<String,List<SectionSetting__c>> mapParentChildSub = new Map<String,List<SectionSetting__c>>();
        for(SectionSetting__c sectionSetting : listSectonSetting) {
			if(String.isBlank(sectionSetting.Source_Object__c) && String.isBlank(sectionSetting.Sub_Section__c)){
				orderSectionSettingMap.put(sectionSetting.Order__c, sectionSetting);
			}else{
                //if(String.isBlank(sectionSetting.Source_Object__c)) continue;
                if(String.isBlank(sectionSetting.Sub_Section__c)) {
                    if(mapParentNoSub.containsKey(sectionSetting.Main_Section__c)){
                        mapParentNoSub.get(sectionSetting.Main_Section__c).add(sectionSetting);
                    }else{
                        mapParentNoSub.put(sectionSetting.Main_Section__c, new List<SectionSetting__c>{sectionSetting});
                    }
                } else {
                    if(mapParentWithSub.get(sectionSetting.Main_Section__c) == null) {
                        mapParentWithSub.put(sectionSetting.Main_Section__c, new List<SectionSetting__c> {sectionSetting});
                    } else {
                        mapParentWithSub.get(sectionSetting.Main_Section__c).add(sectionSetting);
                    }
                }
            }
        }
        Map<String, List<SectionSetting__c>> mapSubChild = new Map<String, List<SectionSetting__c>>();
        for(String key1 : mapParentWithSub.keySet()) {
            for(SectionSetting__c sectionSetting : mapParentWithSub.get(key1)) {
                String key = sectionSetting.Main_Section__c + ';' + sectionSetting.Sub_Section__c;
                if(mapSubChild.get(key) == null) {       
                    mapSubChild.put(key, new List<SectionSetting__c> {sectionSetting});
                } else {
                    mapSubChild.get(key).add(sectionSetting);
                }
            }
        }
        Map<String, Section> mainTitleSectionMap = new Map<String, Section>();
        //List<Section> listSection = new List<Section>();
        for(String key1 : mapParentNoSub.keySet()) {
            Section a1 = new Section();
            List<WrapperField> list1 = new List<WrapperField>();
            //for(String key : mapParentNoSub.keySet()) {
                list1.addAll(convertToListWrapperField(mapParentNoSub.get(key1)));
            //}
            a1.mainSectionFields = list1;
            a1.mainSectionTitle = key1;
            //listSection.add(a1);
            
			mainTitleSectionMap.put(a1.mainSectionTitle, a1);
        }
        
        for(String key1 : mapParentWithSub.keySet()) {
            Section a = new Section();
            for(String key : mapSubChild.keySet()) {     
                String [] arr = key.split(';');
                //Child
                a.mainSectionTitle = arr[0];
                SubSectionChild subSectionChild = new SubSectionChild();
                subSectionChild.subSectionChildTitle = arr[1];
                List<WrapperField> subSectionChildFields = new List<WrapperField>();
                subSectionChildFields.addAll(convertToListWrapperField(mapSubChild.get(key)));
                subSectionChild.subSectionChildFields = subSectionChildFields;
                a.subSectionChilds.add(subSectionChild);
                //End        
            }
            //listSection.add(a);
            mainTitleSectionMap.put(a.mainSectionTitle, a);
        }
        System.debug('>>>mainTitleSectionMap>>>'+mainTitleSectionMap);
		List<Section> sectionOrdered = getSortedKeyset(mainTitleSectionMap, orderSectionSettingMap);
        System.debug('>>>sectionOrdered>>>'+sectionOrdered);
        tabItem.sections = sectionOrdered;
        tabItem.activeSections = getActiveSections(sectionOrdered);
        System.debug('End'+  Datetime.now().second());
        return tabItem;
    }

    /*************************************************
    * Method Name: getOpp
    * Author: Hang Lam
    * Date: 03/04/2020
    * Params: Opportunity Id, list of fields
    * Return: fieldValueMap
    * Description: get Opportunity field Map
    * Revision: 
    *************************************************/
    @AuraEnabled
    public static Map<String, Object> getOpp(Id oppId, String fieldList) {
        List<String> fields = (List<String>) JSON.deserialize(fieldList, List<String>.class);
        fields.add('Id');
        fields.add('RecordTypeId');
        //String openChildQuotes = '(Select Id, Quote_Type__c, Status from Quotes where Quote_Type__c = \'Full Amendment\' AND Status NOT IN (\'Bound\',\'Closed\',\'Rejected\',\'Correction\',\'Cancelled\') )';
        String openChildQuotes = '(Select Id, Quote_Type__c, Status from Quotes )';
        fields.add(openChildQuotes);
        String condition = 'Id =: oppId';
        List<Opportunity> opps = Database.query(CommonUtil.buildQuery(fields, 'Opportunity', condition));
        Map<String, Object> fieldValueMap = new Map<String, Object>();
        fields.remove(fields.size() - 1);
        if(!opps.isEmpty()){
            for(String field : fields){
                fieldValueMap.put(field, opps[0].get(field));
            }
            fieldValueMap.put('Quotes', opps[0].Quotes );
        }
        return fieldValueMap;
    }

    /*************************************************
    * Method Name: getSubmissionLossDetailByAccount
    * Author: Hang Lam
    * Date: 16/06/2020
    * Params: oppId - Opportunity Id
    * Return: List SubmissionLossDetailWrapper
    * Description: get SubmissionLossDetail info
    * Revision: 
    *************************************************/
    @AuraEnabled(cacheable = true)
    public static List<SubmissionLossDetailWrapper> getSubmissionLossDetailBySubmission(String oppId){
        List<Submission_Loss_Detail__c> lstSubLossDetail = [SELECT Id,Name,Loss_Amount__c,Number_of_Losses__c,
                                                                Product__c,Status__c,Year__c
                                                        FROM Submission_Loss_Detail__c
                                                        WHERE Submission__c = :oppId];
        List<SubmissionLossDetailWrapper> lstWrapper = new List<SubmissionLossDetailWrapper>();
        for(Submission_Loss_Detail__c submissionLossDetail : lstSubLossDetail) {
            lstWrapper.add(new SubmissionLossDetailWrapper(submissionLossDetail));
        }
        return lstWrapper;
    }
    @AuraEnabled(cacheable = true)
    public static List<SubmissionAdditionalInsuredWrapper> getSubmissionAdditionalInsuredDetails(String oppId){
        List<Additional_Insured__c> additionalInsuredList = [SELECT Id,Name,Additional_Insured_Account__c,Additional_Insured_Account__r.Name,
                                                             Submission__c,Additional_Insured_Account__r.BillingCountry, Additional_Insured_Account__r.AQ_Sanction_Status__c,Additional_Insured_Account__r.Sanction_Date__c,
                                                             Additional_Insured_Account__r.BillingCity,Additional_Insured_Account__r.BillingStreet,
                                                             Additional_Insured_Account__r.BillingPostalCode,Additional_Insured_Account__r.BillingState
                                                        FROM Additional_Insured__c
                                                        WHERE Submission__c = :oppId];
        List<SubmissionAdditionalInsuredWrapper> lstWrapper = new List<SubmissionAdditionalInsuredWrapper>();
        for(Additional_Insured__c additionalInsuredObj : additionalInsuredList) {
            lstWrapper.add(new SubmissionAdditionalInsuredWrapper(additionalInsuredObj));
        }
        system.debug('additionalInsuredList->'+additionalInsuredList);
        system.debug('lstWrapper->'+lstWrapper);
        return lstWrapper;
    }

    /*************************************************
    * Method Name: getSortedKeyset
    * Author: Hang Lam
    * Date: 03/04/2020
    * Params: mainTitleSectionMap, orderSectionSettingMap
    * Return: List Section in order
    * Description: get Sorted key set
    * Revision: tuan.d.nguyen 7-Dec-2020
    *************************************************/
    public static List<Section> getSortedKeyset(Map<String, Section> mainTitleSectionMap, Map<Decimal, SectionSetting__c> orderSectionSettingMap) {
        List<Section> result = new List<Section>();
		List<String> mainTitleOrdered = new List<String>();
        List<Decimal> keySetList = new List<Decimal>();
        keySetList.addAll(orderSectionSettingMap.keySet());
        keySetList.sort();
        // for(Decimal key: keySetList){
        //     System.debug('orderSectionSettingMap.get(key).Main_Section__c'+orderSectionSettingMap.get(key).Main_Section__c);
        //     mainTitleOrdered.add(orderSectionSettingMap.get(key).Main_Section__c);
        // }
		// for(String mainTitle : mainTitleOrdered){
        //     System.debug('>>>mainTitle>>>'+mainTitle);
		// 	result.add(mainTitleSectionMap.get(mainTitle));
        // }
        
        //tuan.d.nguyen added 7-Dec-2020 start collapsed main section
        List<SectionSetting__c> listMainSectionOrdered = new List<SectionSetting__c>();
        for(Decimal key: keySetList){
            System.debug('orderSectionSettingMap.get(key).Main_Section__c'+orderSectionSettingMap.get(key).Main_Section__c);
            listMainSectionOrdered.add(orderSectionSettingMap.get(key));
        }
		for(SectionSetting__c section : listMainSectionOrdered){
            System.debug('>>>mainTitle>>>'+section.Main_Section__c);
            Section mainSection = mainTitleSectionMap.get(section.Main_Section__c);
            mainSection.displayType = section.DisplayType__c;
			result.add(mainSection);
        } //tuan.d.nguyen added 7-Dec-2020 end
        return result;
    }

    /*************************************************
    * Method Name: convertToListWrapperField
    * Author: Hang Lam
    * Date: 03/04/2020
    * Params: list section setting
    * Return: List WrapperField
    * Description: convert section setting list to List of WrapperField
    * Revision: 
    *************************************************/
    private static List<WrapperField> convertToListWrapperField(List<SectionSetting__c> params) {
        
        List<Profile> lstProfile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        String currentProflieName = lstProfile[0].Name;
        
        List<WrapperField> listWrapperField = new List<WrapperField>();
        List<String> dependenList = new List<String>();
        for(SectionSetting__c sectionSetting : params) {
            WrapperField a = new WrapperField();
            a.sourceObject = sectionSetting.Source_Object__c;
            a.sourceFieldLabel = sectionSetting.Source_Field_Label__c;
            a.sourceFieldApi = sectionSetting.Source_Field_API__c;
            a.format = sectionSetting.Format__c;
            a.lookupTo = sectionSetting.Lookup_To__c;
            a.required = sectionSetting.Is_Required__c;
            a.sourceMainSectionTitle = sectionSetting.Main_Section__c; //Added by GP
            if(String.isNotBlank(sectionSetting.Profile_Name_for_Read_Only__c)) {
                if(sectionSetting.Profile_Name_for_Read_Only__c == 'All'){
                    a.readOnly = true;
                } else {
                    a.readOnly = sectionSetting.Profile_Name_for_Read_Only__c.contains(currentProflieName) ? true : false;
                }
            }
            if(sectionSetting.Format__c == 'Picklist'){
                SObjectType objType = Schema.getGlobalDescribe().get(sectionSetting.Source_Object__c);
                Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
                SObjectField controllingPicklist = fieldMap.get(sectionSetting.Source_Field_API__c).getDescribe().getController();
                if(controllingPicklist != null) {
                    a.isDependencyPicklist = true;
                    dependenList.add(controllingPicklist+'');
                }
            }
            listWrapperField.add(a);
        }
        for(WrapperField wrapperField : listWrapperField){
            if(dependenList.contains(wrapperField.sourceFieldApi)) wrapperField.isDependencyPicklist = true;
        }
        return listWrapperField;
    }

    /*************************************************
    * Method Name: getActiveSections
    * Author: Hang Lam
    * Date: 03/04/2020
    * Params: list section
    * Return: List active section
    * Description: get list of Active Section 
    * Revision: tuan.d.nguyen 7-Dec-2020
    *************************************************/
    public static List<String> getActiveSections(List<Section> sections) {
        List<String> result = new List<String>();
        for (Section section : sections) {
            //tuan.d.nguyen added 7-Dec-2020 start collapsed main section
            if(section.displayType != 'Collapsed') //tuan.d.nguyen added 7-Dec-2020 end
                result.add(section.mainSectionTitle);
        }
        return result;
    }

    /*************************************************
    * Method Name: getStageNameSubmission
    * Author: Giang Phan
    * Date: 19/June/2020
    * Params: submissionId
    * Return: stageName
    * Description: get StageName of Submission
    * Revision: 
    *************************************************/
    @AuraEnabled
    public static String getStageNameSubmission(String submissionId){
        Opportunity opp = [SELECT Id,RecordType.Name, StageName FROM Opportunity WHERE Id =: submissionId LIMIT 1];
        string product = '';
        String stageName = '';
        string quoteType = '';
        
        if(opp != null){
            product = opp.RecordType.Name;
            List<Quote> quoteList = [select Id,Quote_Type__c,OpportunityId from Quote where OpportunityId =:submissionId];
            if(!quoteList.isEmpty()){
                for(Quote quote : quoteList){
                    if(quote.Quote_Type__c == 'Full Amendment'){
                        quoteType = 'Full Amendment';
                        break;
                    } 
                }  
            }
            if(product == 'Aqueous'){
                stageName = opp.StageName +'-'+quoteType;
            }else{
                stageName = opp.StageName;
            } 
        }
        return stageName;
    }


    /*************************************************
    * Method Name: checkProfileIsAdmin
    * Author: Duc Pham
    * Date: 20/July/2020
    * Params: submissionId
    * Return: Boolean
    * Description: Check current profile name is System Administrator
    * Revision:
    *************************************************/
    @AuraEnabled
    public static Boolean checkProfileIsAdmin(){
        List<Profile> lstProfile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        String currentProflieName = lstProfile[0].Name;
        System.debug(currentProflieName);
        return currentProflieName == 'System Administrator';
    }
	@AuraEnabled
    public static Boolean checkRelatedBoundQuotesPresent(String submissionId){
        Boolean proceedToChangeStage = false;
        Opportunity opp = [SELECT Id, StageName,(Select Id,Status from Quotes) FROM Opportunity WHERE Id =: submissionId LIMIT 1];
        if(opp.Quotes.size() > 0){
            for(Quote quoteObj : opp.Quotes){
                if(quoteObj.Status == 'Bound'){
                    proceedToChangeStage=true;
                    break;
                }	
            }
        }
        return proceedToChangeStage;
    }
    @AuraEnabled
    public static void updateAllQuoteStatusAndCloseReason(Id oppId) {
        try{
            // Update quotes - We must set the Quote Status on any Quotes that are not closed back to In Progress.
            List<Quote> quotes = [SELECT Id,Closed_Reason__c, OpportunityId,Opportunity.Name, Status, Opportunity.StageName,
                                            Opportunity.Loss_Reason__c
                                            FROM Quote 
                                            WHERE OpportunityId =: oppId
                                            AND Status NOT IN ('Closed')];
            if(!quotes.isEmpty()){
                for(Quote quot : quotes){
                    quot.Status = 'Closed';
                    if(quot.Opportunity.StageName == 'Closed Lost'){
                        quot.Closed_Reason__c = 'Submission Closed';
                    }else if(quot.Opportunity.StageName == 'Declined'){
                        quot.Closed_Reason__c = 'Submission Declined';
                    }
                }
            }
            upsert quotes;
        }catch(Exception ex){
            System.debug('@@@Exception: '+ ex.getMessage()+ex.getStackTraceString()+ex.getLineNumber());
            throw new AuraHandledException(CommonUtil.getExceptionMessage(ex) + '' + ex.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static ResultResponse unDeclineUpdateSubmission(Id oppId) {
        ResultResponse result = new ResultResponse();
        Boolean isQualified = false;
        try{
            List<Opportunity> oppList = [select Id,Submission_Status__c,StageName,Loss_Reason__c from Opportunity where Id=: oppId limit 1];
            
            List<Quote> quotes = [SELECT Id,Rating_Status__c,Closed_Reason__c, OpportunityId,Opportunity.Name, Status, Opportunity.StageName,
                                            Opportunity.Loss_Reason__c
                                            FROM Quote 
                                            WHERE OpportunityId =: oppId
                                            AND Status IN ('Closed')];
            if(!quotes.isEmpty()){
                for(Quote quot : quotes){
                    if(quot.Closed_Reason__c == 'Submission Declined'){
                        isQualified = true;
                    }
                    quot.Status = 'In Progress';
                    quot.Rating_Status__c = '';
                    quot.Closed_Reason__c = '';
                }
                upsert quotes;
            }
            if(!oppList.isEmpty()){
                if(isQualified){
                    oppList[0].StageName = 'Qualified';
                }else{
                    oppList[0].StageName = 'New';
                }
                oppList[0].Loss_Reason__c = '';
                oppList[0].Submission_Status__c = '';
                
                update oppList;
            }
           
            
            result.isSuccess = true;
            result.data = oppList;
            result.extraData = isQualified;
            return result;
        }catch(Exception ex){
            System.debug('@@@Exception: '+ ex.getMessage()+ex.getStackTraceString()+ex.getLineNumber());
            throw new AuraHandledException(CommonUtil.getExceptionMessage(ex) + '' + ex.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static string getAccountDetails() {
        string returnValue = '';
        RecordType recordType = new RecordType();
        recordType = [select Id,Name,sObjectType from RecordType where Name = 'Business' AND sObjectType = 'Account' limit 1];
        if(recordType != null){
            if(string.isNotBlank(recordType.Name) && string.isNotBlank(recordType.Id)){
                returnValue = recordType.Name + ';' + recordType.Id;  
            }
        }
        return returnValue;
    }
    
   	@AuraEnabled
    public static void makeAllQuotedQuotesRated(String submissionId){			//49432
        try{
            List<Quote> quoteList = [Select Id,Name,Status from Quote where Status = 'Quoted' AND OpportunityId =:submissionId];
            for(Quote quoteObj : quoteList){
                quoteObj.Status = 'Rated';
            }
            if(quoteList.size() > 0)	update quoteList;
        }catch(Exception ex){throw new AuraHandledException(CommonUtil.getExceptionMessage(ex));}
    }

    @AuraEnabled
    public static void updateExistingReferredQuotes(String recordId){			//51910
        try{
            List<Quote> quoteList = new List<Quote>();
            if(recordId.startsWithIgnoreCase('006')){
                quoteList = [Select Id,Name,Status from Quote where OpportunityId =:recordId AND Product_Name__c = 'Professional Indemnity' AND Status = 'Referred'];
            }
            else{
                quoteList = [Select Id,Name,Status from Quote where Id =:recordId AND Product_Name__c = 'Professional Indemnity' AND Status = 'Referred'];
            }
            if(quoteList.size() > 0)	update quoteList;
        }catch(Exception ex){throw new AuraHandledException(CommonUtil.getExceptionMessage(ex));}
    }
    

    public class TabItem {
        @AuraEnabled public List<String> activeSections         {get; set;}
        @AuraEnabled public List<Section> sections              {get; set;}

        public TabItem() {
            activeSections = new List<String>();
            sections = new List<Section>();
        }
    }
    public class Section {
        @AuraEnabled
        public String id                                    {get;set;}
        @AuraEnabled
        public String mainSectionTitle                      {get;set;}
        @AuraEnabled
        public List<WrapperField> mainSectionFields         {get;set;}
        @AuraEnabled
        public String subSectionTitle                       {get;set;}
        @AuraEnabled
        public List<SubSectionChild> subSectionChilds       {get;set;}
        @AuraEnabled
        public String displayType                           {get;set;}
    
        public Section() {
            this.subSectionChilds = new List<SubSectionChild>();
        }

    }

    public class SubSectionChild {
        @AuraEnabled
        public String subSectionChildTitle                   {get;set;}
        @AuraEnabled
        public List<WrapperField> subSectionChildFields      {get;set;}
        public SubSectionChild() {}
    }
    
    public class WrapperField {
        @AuraEnabled
        public String sourceMainSectionTitle            {get;set;} //Added by GP       
        @AuraEnabled
        public String sourceObject                      {get;set;}
        @AuraEnabled
        public String sourceFieldLabel                  {get;set;}
        @AuraEnabled
        public String sourceFieldApi                    {get;set;}
        @AuraEnabled
        public String format                            {get;set;}
        @AuraEnabled
        public String value                             {get;set;}
        @AuraEnabled
        public String lookupTo                          {get;set;}
        @AuraEnabled
        public Boolean isDependencyPicklist              {get;set;}
        //tuan.d.nguyen added 24-Jun-2020
        @AuraEnabled
        public Boolean readOnly                          {get;set;}
        @AuraEnabled
        public Boolean required                          {get;set;}
        @AuraEnabled
        public Boolean isDeclinedStageField              {get;set;}
        public WrapperField() {
            this.required = false;
            this.isDeclinedStageField = false;
        }
    }    
    public class SubmissionAdditionalInsuredWrapper{
        @AuraEnabled public String Id {get; set;}
        @AuraEnabled public String accId {get; set;}
        @AuraEnabled public String submissionId {get; set;}
		@AuraEnabled public String name {get; set;}
		@AuraEnabled public String linkSubmissionAdditionalDetailName {get; set;}
		@AuraEnabled public String linkAdditionalDetailAccountName {get; set;}
        @AuraEnabled public String linkAdditionalDetailAccountAddress {get; set;}
        @AuraEnabled public String linkSubmissionAdditionalDetailOppName {get; set;}
        @AuraEnabled public String sanctionStatus {get; set;}
        @AuraEnabled public Date sanctionDate {get; set;}

        public SubmissionAdditionalInsuredWrapper() {
        }
        public SubmissionAdditionalInsuredWrapper(Additional_Insured__c additionalInsuredObj){
            this.Id = additionalInsuredObj.Id;
            this.accId = '/'+additionalInsuredObj.Additional_Insured_Account__c;
            this.submissionId = additionalInsuredObj.Submission__c;
            this.name = additionalInsuredObj.Name;
            this.linkAdditionalDetailAccountAddress = additionalInsuredObj.Additional_Insured_Account__r.BillingStreet + ', '+
                								additionalInsuredObj.Additional_Insured_Account__r.BillingCity + ', '+ 
                								additionalInsuredObj.Additional_Insured_Account__r.BillingState + ', '+
                								additionalInsuredObj.Additional_Insured_Account__r.BillingPostalCode + ', '+
                								additionalInsuredObj.Additional_Insured_Account__r.BillingCountry;                
			this.linkSubmissionAdditionalDetailName = '/'+additionalInsuredObj.Id;
            this.linkAdditionalDetailAccountName = additionalInsuredObj.Additional_Insured_Account__r.Name;
            this.linkSubmissionAdditionalDetailOppName = '/'+additionalInsuredObj.Submission__c;
            this.sanctionStatus = additionalInsuredObj.Additional_Insured_Account__r.AQ_Sanction_Status__c;
            this.sanctionDate = additionalInsuredObj.Additional_Insured_Account__r.Sanction_Date__c;
        }
    }
    public class SubmissionLossDetailWrapper{
		@AuraEnabled public String Id {get; set;}
		@AuraEnabled public String name {get; set;}
		@AuraEnabled public String linkSubmissionLossDetailName {get; set;}
		@AuraEnabled public Decimal lossAmount {get; set;}
        @AuraEnabled public Decimal numberOfLosses {get; set;}
        @AuraEnabled public String product {get; set;}
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public String year {get; set;}
        public SubmissionLossDetailWrapper() {
        }
        public SubmissionLossDetailWrapper(Submission_Loss_Detail__c submissionLossDetail) {
            this.Id = submissionLossDetail.Id;
            this.name = submissionLossDetail.Name;
            this.linkSubmissionLossDetailName = '/'+submissionLossDetail.Id;
            this.lossAmount = submissionLossDetail.Loss_Amount__c;
            this.numberOfLosses = submissionLossDetail.Number_of_Losses__c;
            this.product = submissionLossDetail.Product__c;
            this.status = submissionLossDetail.Status__c;
            this.year = submissionLossDetail.Year__c;
            
        }
    }
}