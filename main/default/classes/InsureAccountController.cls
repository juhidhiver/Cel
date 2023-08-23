/**
 * @File Name          : InsureAccountController.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : Vinayesh
 * @Last Modified On   : 06-29-2021
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/2/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public with sharing class InsureAccountController {

    private static final String ACCOUNT_COMPONENT = 'Account Info';
    private static final String ACCOUNT_SOURCE_OBJECT = 'Account';
    private static final String CONTACT_SOURCE_OBJECT = 'Contact';
    public static final String QUOTE_PROCESS_OBJ = 'Quote_Process__c';
    public static final String OPPORTUNITY_OBJ = 'Opportunity';
    public static final String RECORD_TYPE_CELERITY = 'Celerity';
    public static final Boolean BOOLEAN_TRUE = true;
    public static final String MPL_CELERITY = 'MPL Standalone';
    public static final String CYBER_CELERITY = 'Cyber Standalone';
    public static final String PCC_CELERITY = 'Private Company Combo';
    

    private static Map<String,String> recordTypeMap = new Map<String,String>();

    @AuraEnabled(cacheable = true)
    public static SectionWrapper getListSectionSetting(Id recordId) {
        try {
            List<Profile> lstProfile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
            String currentProflieName = lstProfile[0].Name;

            Schema.DescribeSObjectResult R = Account.SObjectType.getDescribe();
            List<Schema.RecordTypeInfo> RT = R.getRecordTypeInfos();
            for(RecordType rec : [SELECT Id, Name, DeveloperName, Description FROM RecordType WHERE SobjectType = 'Account']) {
                recordTypeMap.put(rec.Name, rec.Id);
            }

            String sObjName = recordId.getSObjectType().getDescribe().getName();
            system.debug('sObjName:' + sObjName);
            String quoteProcessAccountId = null;
            String quoteProcessRecordTypeName = null;
            String productName = null;
            if(sObjName == QUOTE_PROCESS_OBJ) {
                List<Quote_Process__c> listQuoteProcess = [SELECT Id, Account__c,Record_Type__c,Submission__r.Product__r.Name FROM Quote_Process__c WHERE Id = :recordId];
                quoteProcessAccountId = listQuoteProcess[0].Account__c;                
                if(listQuoteProcess[0].Submission__r != null) {
                    productName = listQuoteProcess[0].Submission__r.Product__r.Name;
                }
                if(productName != null && (productName == MPL_CELERITY || productName == CYBER_CELERITY || productName == PCC_CELERITY)){
                    quoteProcessRecordTypeName = RECORD_TYPE_CELERITY;
                }else{
                    quoteProcessRecordTypeName = listQuoteProcess[0].Record_Type__c;
                }
            }
            if(sObjName == OPPORTUNITY_OBJ) {
                List<Opportunity> listOpp = [SELECT Id,StageName,Product__r.Name,(SELECT Id, Account__c,Record_Type__c,Submission__r.StageName, Submission__c, Status__c FROM Quote_Process__r LIMIT 1) FROM Opportunity WHERE Id = :recordId];
                quoteProcessAccountId = listOpp[0].Quote_Process__r[0].Account__c;
                productName =  listOpp[0].Product__r.Name;
                if(productName != null && (productName == MPL_CELERITY || productName == CYBER_CELERITY || productName == PCC_CELERITY)){
                    quoteProcessRecordTypeName = RECORD_TYPE_CELERITY;
                }else{
                    quoteProcessRecordTypeName = listOpp[0].Quote_Process__r[0].Record_Type__c;
                }
            }
            System.debug('productName:' + productName);
            List<String> lstField = new List<String>{'Id','Name','Main_Section__c','Record_Type__c','Profile_Name_for_Read_Only__c','Is_Required__c',
                                                    'Type_Of_Section__c','Sub_Section__c','Source_Object__c','Source_Field_Label__c','Custom_Field_Type__c',
                                                    'Source_Field_API__c','Format__c','Order__c','Product__c','DisplayType__c'};
            String objName = 'SectionSetting__c';
            String condition = 'Record_Type__c ' + '= \'' + quoteProcessRecordTypeName + '\'';
            condition += ' AND Active__c =' + BOOLEAN_TRUE;
            condition += ' AND Component__c ' + '= \'' + ACCOUNT_COMPONENT + '\'';
            //String condition = 'Record_Type__c = 'Celerity' AND Active__c = true AND Component__c = ' + ACCOUNT_COMPONENT;
            if(String.isNotBlank(productName)) {
                if (productName.contains('Standalone')) {
                    productName = productName.split(' ')[0];
                }
                  if(productName != PCC_CELERITY) //Added by Vinayesh. Temporary needs change.
              		  condition += ' AND Product__c INCLUDES (\'' + String.escapeSingleQuotes(productName) + '\')';
             
            }
            String query = CommonUtil.buildQuery(lstField, 'SectionSetting__c', condition);
            System.debug('query:' + query);


            List<SectionSetting__c> listSectonSetting = (List<SectionSetting__c>)Database.query(query);
            Set<String> fieldsList = new Set<String>();
            for(SectionSetting__c st : listSectonSetting){
                if(st.Source_Object__c == ACCOUNT_SOURCE_OBJECT){
                    fieldsList.add(st.Source_Field_API__c);
                }
            }
            /*
            String queryString = 'SELECT ' + String.join(new List<String>(fieldsList),' , ') +
                                ' FROM Account WHERE Id = : quoteProcessAccountId' ;
            List<Account> listAccount = (List<Account>) Database.query(queryString);*/

            //Create parent map without child & field to sort Main section
            Map<String,SectionSetting__c> mapParentNoSubOrderMain = new Map<String,SectionSetting__c>();

            //Create parent map without child & field to sort Sub section
            Map<String,SectionSetting__c> mapParentNoSubOrderSub = new Map<String,SectionSetting__c>();

            //Create parent map without child
            Map<String,List<SectionSetting__c>> mapParentNoSub = new Map<String,List<SectionSetting__c>>();
            //Create parent map with child
            Map<String,List<SectionSetting__c>> mapParentWithSub = new Map<String,List<SectionSetting__c>>();
            //Create map parent with child and sub child
            Map<String,List<SectionSetting__c>> mapParentChildSub = new Map<String,List<SectionSetting__c>>();
            for(SectionSetting__c sectionSetting : listSectonSetting) {
                if(sectionSetting.Type_Of_Section__c == 'MainSection') {
                    mapParentNoSubOrderMain.put(sectionSetting.Main_Section__c,sectionSetting);
                } else {
                    if(sectionSetting.Type_Of_Section__c == 'SubSection') {

                        mapParentNoSubOrderSub.put(sectionSetting.Sub_Section__c,sectionSetting);
                        system.debug('long 222222222222:' + mapParentNoSubOrderSub);
                    } else {
                        if(String.isBlank(sectionSetting.Sub_Section__c)) {
                            if(mapParentNoSub.get(sectionSetting.Main_Section__c) == null) {
                                mapParentNoSub.put(sectionSetting.Main_Section__c, new List<SectionSetting__c> {sectionSetting});
                            } else {
                                mapParentNoSub.get(sectionSetting.Main_Section__c).add(sectionSetting);
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
            }
            Map<String, List<SectionSetting__c>> mapSubChild = new Map<String, List<SectionSetting__c>>();
            for(String mainSection : mapParentWithSub.keySet()) {
                for(SectionSetting__c sectionSetting : mapParentWithSub.get(mainSection)) {
                    String key = sectionSetting.Main_Section__c + ';' + sectionSetting.Sub_Section__c;
                    if(mapSubChild.get(key) == null) {
                        mapSubChild.put(key, new List<SectionSetting__c> {sectionSetting});
                    } else {
                        mapSubChild.get(key).add(sectionSetting);
                    }
                }
            }

            List<Section> listSection = new List<Section>();
            List<String> activeSections = new List<String>();
            for(String mainSection : mapParentNoSub.keySet()) {

                Section section = new Section();
                List<WrapperField> listField = new List<WrapperField>();
                //for(String key : mapParentNoSub.keySet()) {
                listField.addAll(convertToListWrapperField(mapParentNoSub.get(mainSection), currentProflieName));
                //}
                listField.sort();
                section.mainSectionFields = listField;
                section.mainSectionTitle = mainSection;
                section.order = mapParentNoSubOrderMain.get(mainSection).Order__c;
                if(mapParentNoSubOrderMain.get(mainSection).DisplayType__c == 'Open') {
                    activeSections.add(mainSection);
                }
                listSection.add(section);
            }

            for(String mainSection : mapParentWithSub.keySet()) {//key 1 : Main Section
                Section sec = new Section();
                boolean isAdded = true;
                for(Section section : listSection) {
                    if(section.mainSectionTitle  == mainSection) {
                        sec = section;
                        isAdded = false;
                        break;
                    }
                }
                for(String key : mapSubChild.keySet()) {
                    system.debug('mapSubChild :' + key);
                    String [] arr = key.split(';');
                    if(arr[0] == mainSection) { //Child
                        sec.mainSectionTitle = arr[0];
                        SubSectionChild subSectionChild = new SubSectionChild();
                        subSectionChild.subSectionChildTitle = arr[1];
                        sec.isComponent = false;
                        if(mapParentNoSubOrderSub.get(arr[1]) != null) {
                            if(mapParentNoSubOrderSub.get(arr[1]).DisplayType__c == 'Component') {
                                sec.isComponent = true;
                            }
                        }
                        if(sec.isComponent) {
                            sec.sourceObject = mapSubChild.get(key)[0].Source_Object__c;
                        }
                        if(mapParentNoSubOrderSub.get(subSectionChild.subSectionChildTitle).DisplayType__c == 'Open') {
                            activeSections.add(subSectionChild.subSectionChildTitle);
                        }
                        subSectionChild.order = mapParentNoSubOrderSub.get(arr[1]).Order__c;
                        List<WrapperField> subSectionChildFields = new List<WrapperField>();
                        subSectionChildFields.addAll(convertToListWrapperField(mapSubChild.get(key), currentProflieName));
                        subSectionChild.subSectionChildFields = subSectionChildFields;
                        sec.subSectionChilds.add(subSectionChild);
                        sec.subSectionChilds.sort();
                        sec.order = mapParentNoSubOrderMain.get(mainSection).Order__c;
                        if(mapParentNoSubOrderMain.get(mainSection).DisplayType__c == 'Open') {
                            activeSections.add(mainSection);
                        }
                    }
                }
                if(isAdded) {
                    listSection.add(sec);
                }
            }
            //quoteProcessAccountId = '0012500001G0AqvAAF';
            system.debug('quote Process Account ID:' + quoteProcessAccountId);
            SectionWrapper sec = new SectionWrapper();
            sec.accountId = quoteProcessAccountId;
            listSection.sort();
            sec.sections = listSection;
            sec.activeSections = activeSections;
            return sec;
       }catch (Exception ex){
           System.debug('Exception' + ex.getMessage() +ex.getStackTraceString() +ex.getLineNumber());
       }
        return null;
    }

    private static List<WrapperField> convertToListWrapperField(List<SectionSetting__c> params, String currentProflieName) {
        List<WrapperField> listWrapperField = new List<WrapperField>();
        for(SectionSetting__c sectionSetting : params) {
            WrapperField a = new WrapperField();
            a.sourceObject = sectionSetting.Source_Object__c;
            a.sourceFieldLabel = sectionSetting.Source_Field_Label__c;
            a.sourceFieldApi = sectionSetting.Source_Field_API__c;
            a.format = sectionSetting.Format__c;
            a.required = sectionSetting.Is_Required__c;
            a.order = sectionSetting.Order__c;
            a.recordType = recordTypeMap.get(sectionSetting.Record_Type__c);
            if(String.isNotBlank(sectionSetting.Profile_Name_for_Read_Only__c)) {
                if(sectionSetting.Profile_Name_for_Read_Only__c == 'All'){
                    a.readOnly = true;
                } else {
                    a.readOnly = sectionSetting.Profile_Name_for_Read_Only__c.contains(currentProflieName) ? true : false;
                }
            }
            listWrapperField.add(a);
        }
        listWrapperField.sort();
        return listWrapperField;
    }

    @AuraEnabled(cacheable = true)
    public static List<SelectOptionWrapper> getPicklistValues(String objectName, String fieldName, String firstValue, String key) {
        List<SelectOptionWrapper> options = new List<SelectOptionWrapper>();
        String[] values = new String[]{};
        String[] types = new String[]{objectName};
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
        for(Schema.DescribeSobjectResult res : results) {
           for (Schema.PicklistEntry entry : res.fields.getMap().get(fieldName).getDescribe().getPicklistValues()) {
              options.add(new SelectOptionWrapper(entry.getValue(), entry.getLabel()));
           }
        }
        return options;
     }

     @AuraEnabled
     public static Contact getRecordInfos(String recordId) {
        List<SectionSetting__c> listSectonSetting = [SELECT Id,Source_Object__c,Source_Field_API__c
                                     FROM SectionSetting__c
                                             WHERE Component__c = :ACCOUNT_COMPONENT];
        Set<String> fieldsList = new Set<String>();
        for(SectionSetting__c st : listSectonSetting){
            if(st.Source_Object__c == CONTACT_SOURCE_OBJECT){
                fieldsList.add(st.Source_Field_API__c);
            }
        }
        String queryString = 'SELECT ' + String.join(new List<String>(fieldsList),' , ') +
                                ' FROM Contact WHERE Id = : recordId' ;
        List<Contact> listContact = (List<Contact>) Database.query(queryString);
        return listContact[0];
     }

     @AuraEnabled
     public static Account getAccountInfos(String recordId) {

        List<SectionSetting__c> listSectonSetting = [SELECT Id,Source_Object__c,Source_Field_API__c 
                                                FROM SectionSetting__c
                                             WHERE Component__c =: ACCOUNT_COMPONENT];
        Set<String> fieldsList = new Set<String>();
        for(SectionSetting__c st : listSectonSetting){
            if(st.Source_Object__c == ACCOUNT_SOURCE_OBJECT){
                fieldsList.add(st.Source_Field_API__c);
            }
        }
        String queryString = 'SELECT ' + String.join(new List<String>(fieldsList),' , ') +
                                ' FROM Account WHERE Id = : recordId' ;
         system.debug('queryString:'+queryString);
        List<Account> listAccount = (List<Account>) Database.query(queryString);
        if(!listAccount.isEmpty())
            return listAccount[0];
        return null;
     }

	 
	 @AuraEnabled
     public static String getRecordTypeInfo(String typeRT, String objectApiName) {
		String condition = typeRT.contains('Broker') ? 'Broker' : 'Insurance Company Contact';
        List<RecordType> RTList = [select Id from RecordType where sObjectType= 'Contact' AND Name =: condition];
        return RTList.isEmpty() ? '' : RTList[0].Id;
	
    }

    /*
    @AuraEnabled
    public static String getRecordTypeInfo(String objectName, String typeRT) {
       String condition = typeRT.contains('Broker') ? 'Broker' : 'Insurance Company Contact';
       List<RecordType> RTList = [select Id,Name from RecordType where sObjectType= :objectName AND Name =: condition];
       return RTList.isEmpty() ? null : RTList[0].Id;
   
   }*/

    @AuraEnabled
    public static Quote_Process__c getRecordInfos(Id recordId) {
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        if(sObjName == QUOTE_PROCESS_OBJ) {
            return [SELECT Id, Account__c,Submission__r.StageName, Submission__c, Status__c FROM Quote_Process__c WHERE Id = :recordId];
        }
        if(sObjName == OPPORTUNITY_OBJ) {
            List<Opportunity> listOpp = [SELECT Id,StageName,(SELECT Id, Account__c,Submission__r.StageName, Submission__c, Status__c FROM Quote_Process__r LIMIT 1) FROM Opportunity WHERE Id = :recordId];
            return listOpp[0].Quote_Process__r[0];
        }
        return null;
    }

    @AuraEnabled(cacheable = true)
    public static List<AccountLossDetailWrapper> getAccountLossDetailByAccount(String accId){
        List<Account_Loss_Detail__c> lstAccLossDetail = [SELECT Id,Name,Loss_Amount__c,Number_of_Losses__c,
                                                                Product__c,Status__c,Year__c,Number_of_Open_Losses__c
                                                        FROM Account_Loss_Detail__c
                                                        WHERE Account__c = :accId 
                                                        ORDER BY Year__c];
        List<AccountLossDetailWrapper> lstWrapper = new List<AccountLossDetailWrapper>();
        for(Account_Loss_Detail__c accountLossDetail : lstAccLossDetail) {
            lstWrapper.add(new AccountLossDetailWrapper(accountLossDetail));
        }
        return lstWrapper;
    }

    @AuraEnabled(cacheable = true)
    public static String getObjectRecordTypeId(String sObjectName, String recordTypeName) { 
        sObject obj; 
        Map<String,Schema.RecordTypeInfo> recordTypeInfoMap = new Map<String,Schema.RecordTypeInfo>();  
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectName);  
        if(sObjectType != null) {  
            obj = sObjectType.newsObject();  
            Schema.DescribeSObjectResult sObjDesc = obj.getSObjectType().getDescribe();  
            if(sObjDesc != null) {  
                recordTypeInfoMap = sObjDesc.getRecordTypeInfosByName();  
            }  
            if(!recordTypeInfoMap.containsKey(recordTypeName)) { 
                return null;
                //throw new RecordTypeException('Record type "'+ recordTypeName +'" does not exist.');  
            } else {   
                return recordTypeInfoMap.get(recordTypeName).getRecordTypeId();  
            }  
        }  
        return null;  
    }  

    @AuraEnabled
    public static ResultResponse checkQuotedQuote(String selectedAccountId, Id recordId) {
        ResultResponse result = new ResultResponse();
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        String submissionId = null;
        if(sObjName == QUOTE_PROCESS_OBJ) {
            List<Quote_Process__c> quoteProcs = [SELECT Id, Submission__c FROM Quote_Process__c WHERE Id = :recordId];
            if(!quoteProcs.isEmpty()) submissionId = quoteProcs[0].Submission__c;
        }
        if(sObjName == OPPORTUNITY_OBJ) {
            submissionId = recordId;
        }
        if(submissionId == null) {
            result.data = false;
            return result;
        }
        List<Opportunity> opps = [SELECT Id, AccountId, StageName,
                                        (SELECT Id, OpportunityId, Status 
                                            FROM Quotes WHERE Status = 'Quoted')
                                    FROM Opportunity 
                                    WHERE AccountId =: selectedAccountId
                                    AND StageName = 'Qualified'
                                    AND Id =: submissionId];
        System.debug('@@@opps: ' + opps);
        Boolean isHaveQuoted = false;
        if(!opps.isEmpty()){
            if(opps[0].Quotes != null && opps[0].Quotes.size() > 0) isHaveQuoted = true;
        }
        result.data = isHaveQuoted;
        return result;
    }

    @AuraEnabled
    public static void updateQuoteInProgress(String selectedAccountId) {
        try{
            List<Quote> listQuoteToUpdate = new List<Quote>();
            List<Opportunity> opps = [SELECT Id, AccountId, StageName,
                                            (SELECT Id, OpportunityId, Status 
                                                FROM Quotes WHERE Status = 'Quoted')
                                        FROM Opportunity 
                                        WHERE AccountId =: selectedAccountId
                                        AND StageName = 'Qualified'];
            if(!opps.isEmpty()){
                for(Quote quoteObj : opps[0].Quotes){
                    quoteObj.Status = 'In Progress';
                    listQuoteToUpdate.add(quoteObj);
                }
            }
            update listQuoteToUpdate;
        }catch(Exception ex){
            System.debug('@@@Exception: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static void updateQuoteStatusForAQ(Id sObjectId) {
        try{
            String sObjName = sObjectId.getSObjectType().getDescribe().getName();
            List<Quote> listQuoteToUpdate = new List<Quote>();
            if(sObjName == 'Opportunity'){
                List<Opportunity> opps = [SELECT Id, StageName,Opportunity.Product__r.Name,
                                            (SELECT Id, OpportunityId, Status 
                                                FROM Quotes WHERE Status = 'Quoted')
                                        FROM Opportunity 
                                        WHERE Id =: sObjectId
                                        AND StageName = 'Qualified'];
                if(!opps.isEmpty() && opps[0].Product__r.Name == 'Professional Indemnity'){
                    for(Quote quoteObj : opps[0].Quotes){
                        if(quoteObj.Status == 'Quoted'){
                            quoteObj.Status = 'Rated'; 
                        }
                        listQuoteToUpdate.add(quoteObj);
                    }
                }
                System.debug('List of QuoteUpdate -->'+listQuoteToUpdate);
            }
            else{
                List<Quote_Process__c> quoProc = [Select Id, Name,Quote_Process__c.Submission__c 
                                                    FROM Quote_Process__c where Id =:sObjectId];
                List<Opportunity> opps = [SELECT Id, StageName,Opportunity.Product__r.Name,
                                            (SELECT Id, OpportunityId, Status 
                                                FROM Quotes WHERE Status = 'Quoted')
                                        FROM Opportunity 
                                        WHERE Id =: quoProc[0].Submission__c
                                        AND StageName = 'Qualified'];
                if(!opps.isEmpty() && opps[0].Product__r.Name == 'Professional Indemnity'){
                for(Quote quoteObj : opps[0].Quotes){
                    if(quoteObj.Status == 'Quoted'){
                        quoteObj.Status = 'Rated'; 
                        }
                        listQuoteToUpdate.add(quoteObj);
                    }
                }
                 System.debug('List of QuoteUpdate -->'+listQuoteToUpdate);
            } 
            
            update listQuoteToUpdate;
        }catch(Exception ex){
            System.debug('@@@Exception: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static void updateSubmissionAccount(Id sObjectId, Id accountId) {
        try{
            String sObjName = sObjectId.getSObjectType().getDescribe().getName();
            Opportunity updateOpp;
            
            if(sObjName == 'Opportunity'){
                list<Opportunity> oppL = [Select Id, AccountID, QP_link__c FROM Opportunity WHERE Id = :sObjectId];
                if( String.isNotBlank(oppL[0].QP_link__c) ){
                    update new Quote_Process__c(Account__c = accountId, Id = oppL[0].QP_link__c);
                    updateOpp = new Opportunity();
                    updateOpp.AccountId = accountId;
                    updateOpp.Id = sObjectId;
                }
            }
            else if( sObjName == 'Quote_Process__c' ) {
                List<Quote_Process__c> quoProc = [Select Id, Name, Submission__c, Account__c
                                                    FROM Quote_Process__c where Id =:sObjectId];

                if(quoProc != null && !quoProc.isEmpty() && quoProc[0].Submission__c != null ){
                    update new Quote_Process__c(Account__c = accountId, Id = quoProc[0].Id);
                    updateOpp = new Opportunity();
                    updateOpp.AccountId = accountId;
                    updateOpp.Id = quoProc[0].Submission__c;

                } 
            }
            if( updateOpp != null ){
                update updateOpp;
            }
        }catch(Exception ex){
            System.debug('@@@Exception: ' + ex.getMessage());
        }

    }
    public class SelectOptionWrapper {

        @AuraEnabled
        public String label       {get;set;}       
        @AuraEnabled
        public String value     {get;set;}

        public SelectOptionWrapper() {}

        public SelectOptionWrapper(String value, String label) {
            this.label = label;
            this.value = value;
        }
    }

    public class SectionWrapper {
        @AuraEnabled
        public String accountId {get;set;}
        @AuraEnabled
        public List<Section> sections {get;set;}
        @AuraEnabled
        public List<String> activeSections {get;set;}

        public SectionWrapper() {}
        public SectionWrapper(String accountId, List<Section> sections) {
            this.accountId = accountId;
            this.sections = sections;
        }
    }

    public class Section implements Comparable {
        @AuraEnabled
        public String id                                {get;set;}
        @AuraEnabled
        public String mainSectionTitle                       {get;set;}
        @AuraEnabled
        public List<WrapperField> mainSectionFields     {get;set;}
        @AuraEnabled
        public String subSectionTitle                       {get;set;}
        @AuraEnabled
        public List<SubSectionChild> subSectionChilds     {get;set;}

        @AuraEnabled
        public boolean isComponent                          {get;set;}

        @AuraEnabled
        public String sourceObject                          {get;set;}

        @AuraEnabled
        public Decimal order                            {get;set;}
    
        public Section() {
            this.subSectionChilds = new List<SubSectionChild>();
        }

        public Integer compareTo(Object compareTo) {
            Integer returnValue = 0;
            Section wrapper = (Section)compareTo;
            if (wrapper.order > this.order) {
                returnValue = -1;
            } else if (this.order > wrapper.order) {
                returnValue = 1;
            }
            return returnValue; 
        }

    }

    public class SubSectionChild implements Comparable {
        @AuraEnabled
        public String subSectionChildTitle                   {get;set;}
        @AuraEnabled
        public List<WrapperField> subSectionChildFields      {get;set;}
        @AuraEnabled
        public Decimal order                                {get;set;}

        public SubSectionChild() {}

        public Integer compareTo(Object compareTo) {
            Integer returnValue = 0;
            SubSectionChild wrapper = (SubSectionChild)compareTo;
            if (wrapper.order > this.order) {
                returnValue = -1;
            } else if (this.order > wrapper.order) {
                returnValue = 1;
            }
            return returnValue; 
        }
    }

    public class WrapperField implements Comparable {

        @AuraEnabled
        public String sourceObject                      {get;set;}
        @AuraEnabled
        public String sourceFieldLabel                  {get;set;}
        @AuraEnabled
        public String sourceFieldApi                    {get;set;}
        @AuraEnabled
        public String format                            {get;set;}
        @AuraEnabled
        public Decimal order                            {get;set;}
        @AuraEnabled
        public String value                             {get;set;}
        @AuraEnabled
        public String recordType                        {get;set;}
        @AuraEnabled
        public boolean readOnly                         {get;set;}
        @AuraEnabled
        public boolean required                         {get;set;}
        
        public WrapperField() {
            this.readOnly = false;
        }

        public Integer compareTo(Object compareTo) {
            Integer returnValue = 0;
            WrapperField wrapper = (WrapperField)compareTo;
            if (wrapper.order > this.order) {
                returnValue = -1;
            } else if (this.order > wrapper.order) {
                returnValue = 1;
            }
            return returnValue; 
        }
    }

    public class AccountLossDetailWrapper{
		@AuraEnabled public String Id {get; set;}
		@AuraEnabled public String name {get; set;}
		@AuraEnabled public String linkAccountLossDetailName {get; set;}
		@AuraEnabled public Decimal lossAmount {get; set;}
        @AuraEnabled public Decimal numberOfLosses {get; set;}
        @AuraEnabled public Decimal numberOfOpenLosses {get; set;} //Giang added 3/Sep/2020
        @AuraEnabled public String product {get; set;}
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public String year {get; set;}
        public AccountLossDetailWrapper() {
        }
        public AccountLossDetailWrapper(Account_Loss_Detail__c accountLossDetail) {
            this.Id = accountLossDetail.Id;
            this.name = accountLossDetail.Name;
            this.linkAccountLossDetailName = '/'+accountLossDetail.Id;
            this.lossAmount = accountLossDetail.Loss_Amount__c;
            this.numberOfLosses = accountLossDetail.Number_of_Losses__c;
            this.numberOfOpenLosses = accountLossDetail.Number_of_Open_Losses__c; //Giang added 3/Sep/2020
            this.product = accountLossDetail.Product__c;
            this.status = accountLossDetail.Status__c;
            this.year = accountLossDetail.Year__c;
            
        }
    }
    
    @AuraEnabled(cacheable = true)
    public static Opportunity getOpportunity(Id recordId) {
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        system.debug('sObjName:' + sObjName);
        Opportunity opp = new Opportunity();
        if(sObjName == OPPORTUNITY_OBJ) {
            List<Opportunity> listOpp = [SELECT Id,StageName,Product__r.Name,
                                        (SELECT Id, Quote_Type__c, Status FROM Quotes ) 
                                        FROM Opportunity 
                                        WHERE Id = :recordId];
            if(!listOpp.isEmpty() ){
                opp = listOpp[0];
            }
        }
        return opp;
    }

    @AuraEnabled(cacheable = true)
    public static String getProductName(Id recordId) {
            List<Profile> lstProfile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
            String currentProflieName = lstProfile[0].Name;

            Schema.DescribeSObjectResult R = Account.SObjectType.getDescribe();
            List<Schema.RecordTypeInfo> RT = R.getRecordTypeInfos();
            for(RecordType rec : [SELECT Id, Name, DeveloperName, Description FROM RecordType WHERE SobjectType = 'Account']) {
                recordTypeMap.put(rec.Name, rec.Id);
            }

            String sObjName = recordId.getSObjectType().getDescribe().getName();
            system.debug('sObjName:' + sObjName);
            String productName = null;
            if(sObjName == QUOTE_PROCESS_OBJ) {
                List<Quote_Process__c> listQuoteProcess = [SELECT Id,Product__c FROM Quote_Process__c WHERE Id = :recordId];
                productName = listQuoteProcess[0].Product__c;
            }
            if(sObjName == OPPORTUNITY_OBJ) {
                List<Opportunity> listOpp = [SELECT Id,StageName,Product__r.Name,(SELECT Id, Account__c,Record_Type__c,Submission__r.StageName, Submission__c, Status__c FROM Quote_Process__r LIMIT 1) FROM Opportunity WHERE Id = :recordId];
                productName =  listOpp[0].Product__r.Name;                
            }
            System.debug('productName:' + productName);
        return productName;
    }
}