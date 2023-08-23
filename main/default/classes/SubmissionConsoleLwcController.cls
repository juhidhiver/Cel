/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 01-18-2022
 * @last modified by  : Vinayesh
 * Modifications Log 
 * Ver   Date         Author     Modification
 * 1.0   07-13-2021   Vinayesh   Initial Version
**/
public with sharing class SubmissionConsoleLwcController {

    private static final String SUBMISSION_COMPONENT = 'Submission Console';
    private static final String ACCOUNT_SOURCE_OBJECT = 'Account';
    private static final String CONTACT_SOURCE_OBJECT = 'Contact';
    public static final String QUOTE_PROCESS_OBJ = 'Quote_Process__c';
    public static final String OPPORTUNITY_OBJ = 'Opportunity';
    private static final String BROKER_SOURCE_OBJECT = 'Broker_Account__c';
    public static final String RECORD_TYPE_CELERITY = 'Celerity';
    public static final Boolean BOOLEAN_TRUE = true;
    public static final String MPL_CELERITY = 'MPL Standalone';
    public static final String CYBER_CELERITY = 'Cyber Standalone';
    public static final String PCC_CELERITY = 'Private Company Combo';
    public static final String PROHIBITED_CLASS = 'Prohibited Class';
    public static final String CLEARED_STATUS = 'Cleared';

    private static Map<String,String> recordTypeMap = new Map<String,String>();

    
    /**
    * @description : Get record type of current record.
    * @author Vinayesh | 08-02-2021 
    * @param quoteProcessId 
    * @return string 
    **/
    @AuraEnabled (cacheable=true)
    public static string getDefaultRecordType(String quoteProcessId) {
        String recordTypeName = [SELECT Id,Record_Type__c FROM Quote_Process__c WHERE Id  = :quoteProcessId Limit 1].Record_Type__c;
        RecordType recordType = [select Id,Name from RecordType where SobjectType='Opportunity' And Name =: recordTypeName];
        return recordType.Id + '__' + recordType.Name;
    }

    /**
    * @description : Get section settings for current record based on product and populate wrapper for UI.
    * @author Vinayesh | 08-02-2021 
    * @param recordId 
    * @return SectionWrapper 
    **/
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
            String submissionId = null;
            if(sObjName == QUOTE_PROCESS_OBJ) {
                List<Quote_Process__c> listQuoteProcess = [SELECT Id, Account__c,Record_Type__c, Submission__c, Submission__r.Product__r.Name FROM Quote_Process__c WHERE Id = :recordId];
                quoteProcessAccountId = listQuoteProcess[0].Account__c;
                submissionId = listQuoteProcess[0].Submission__c;
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
                submissionId = recordId;
                productName =  listOpp[0].Product__r.Name;
                if(productName != null && (productName == MPL_CELERITY || productName == CYBER_CELERITY || productName == PCC_CELERITY)){
                    quoteProcessRecordTypeName = RECORD_TYPE_CELERITY;
                }else{
                    quoteProcessRecordTypeName = listOpp[0].Quote_Process__r[0].Record_Type__c;
                }
            }
            System.debug('productName:' + productName);
            List<String> lstField = new List<String>{'Id','Name','Main_Section__c','Record_Type__c','Profile_Name_for_Read_Only__c','Is_Required__c',
                                                    'Type_Of_Section__c','Sub_Section__c','Source_Object__c','Lookup_To__c','Source_Field_Label__c','Custom_Field_Type__c',
                                                    'Source_Field_API__c','Format__c','Criteria__c','Order__c','Product__c','DisplayType__c'};
            String objName = 'SectionSetting__c';
            String condition = 'Record_Type__c ' + '= \'' + quoteProcessRecordTypeName + '\'';
            condition += ' AND Active__c =' + BOOLEAN_TRUE;
            condition += ' AND Component__c ' + '= \'' + SUBMISSION_COMPONENT + '\'';
            //String condition = 'Record_Type__c = 'Celerity' AND Active__c = true AND Component__c = ' + SUBMISSION_COMPONENT;
            if(String.isNotBlank(productName)) {
                String queryProd = '';
                if (productName.contains('Standalone')) {
                    queryProd = productName.split(' ')[0];
                }
                if (productName == PCC_CELERITY) {
                    queryProd = PCC_CELERITY;
                }
                condition += ' AND Product__c INCLUDES (\'' + String.escapeSingleQuotes(queryProd) + '\')';            
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
                system.debug('vinay mainsectiontitle ' + mainSection);
                if(mainSection == 'Submission Information'){
                    section.isSubmission = true;
                }
                else{
                    section.isSubmission = false;
                }
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
            if(submissionId != null && submissionId != ''){
                CheckComponentForReadOnly(sec, submissionId);
            }
            return sec;
       }catch (Exception ex){
           System.debug('Exception' + ex.getMessage() +ex.getStackTraceString() +ex.getLineNumber());
       }
        return null;
    }

    @AuraEnabled
    public static boolean isDNOCleared(Id submissionId){
        List<Product_Option_Line_Item__c> productOptions = [SELECT Id from 	Product_Option_Line_Item__c where Product__r.Name = 'D&O' AND Submission__c =: submissionId AND Clearance_Status__c = 'Cleared'];
        return !productOptions.isEmpty();
    }

    private static List<WrapperField> convertToListWrapperField(List<SectionSetting__c> params, String currentProflieName) {
        List<WrapperField> listWrapperField = new List<WrapperField>();
        List<String> dependenList = new List<String>();
        for(SectionSetting__c sectionSetting : params) {
            WrapperField a = new WrapperField();
            a.sourceObject = sectionSetting.Source_Object__c;
            a.sourceFieldLabel = sectionSetting.Source_Field_Label__c;
            a.sourceFieldApi = sectionSetting.Source_Field_API__c;
            a.lookupTo = sectionSetting.Lookup_To__c;
            a.format = sectionSetting.Format__c;
            a.filter = sectionSetting.Criteria__c;
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
        listWrapperField.sort();
        return listWrapperField;
    }


    private static void CheckComponentForReadOnly(SectionWrapper sec, String oppId) {
        Boolean isBoundSubmission = CheckBoundSubmission(oppId);
       
        if(isBoundSubmission){
            for(Section sc : sec.sections){
                if(!(sc.isComponent == true)){
                    if(sc.mainSectionFields != null){
                        for(WrapperField sField : sc.mainSectionFields){
                            if(sField.sourceFieldApi == 'StageName') continue;
                                sField.readOnly = true;
                        }
                    }                  
                    if(sc.subSectionChilds != null){
                        for(SubSectionChild subChild : sc.subSectionChilds){
                            if(subChild.subSectionChildFields != null){
                                for(WrapperField subField : subChild.subSectionChildFields){
                                    subField.readOnly = true;
                                }
                            }
                        }
                    }
                }
            }
        }

    }

    @AuraEnabled
    public static Boolean CheckBoundSubmission(String oppId) {
        Boolean isBoundSubmission = false;
        List<Quote> oppQuotes = [Select Status, Quote_Type__c from Quote Where OpportunityId =:oppId];
        for(Quote qt : oppQuotes){
            if(qt.Status == 'Bound'){
                isBoundSubmission = true;
            }
            if(qt.Quote_Type__c == 'Update Insured Name or Address' && (qt.Status == 'Rated'|| qt.Status == 'Quoted' || qt.Status == 'In Progress' || qt.Status == 'Referred')){
                isBoundSubmission = false;
                break;
            }
        }
        return isBoundSubmission;
    }

    /**
    * @description : Get picklist values for given field to populate dropdowns in UI.
    * @author Vinayesh | 08-02-2021 
    * @param objectName 
    * @param fieldName 
    * @param firstValue 
    * @param key 
    * @return List<SelectOptionWrapper> 
    **/
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

    //  @AuraEnabled
    //  public static Contact getRecordInfos(String recordId) {
    //     List<SectionSetting__c> listSectonSetting = [SELECT Id,Source_Object__c,Source_Field_API__c
    //                                  FROM SectionSetting__c
    //                                          WHERE Component__c = :'Account Info'];
    //     Set<String> fieldsList = new Set<String>();
    //     for(SectionSetting__c st : listSectonSetting){
    //         if(st.Source_Object__c == CONTACT_SOURCE_OBJECT){
    //             fieldsList.add(st.Source_Field_API__c);
    //         }
    //     }
    //     String queryString = 'SELECT ' + String.join(new List<String>(fieldsList),' , ') +
    //                             ' FROM Contact WHERE Id = : recordId' ;
    //     List<Contact> listContact = (List<Contact>) Database.query(queryString);
    //     return listContact[0];
    //  }

     @AuraEnabled
     public static Account getAccountInfos(String recordId) {

        List<SectionSetting__c> listSectonSetting = [SELECT Id,Source_Object__c,Source_Field_API__c 
                                                FROM SectionSetting__c
                                             WHERE Component__c =: SUBMISSION_COMPONENT];
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
     public static Opportunity getOpp(String oppId) {
        List<SectionSetting__c> listSectonSetting = [SELECT Id,Source_Object__c,Source_Field_API__c 
                                                         FROM SectionSetting__c
                                                            WHERE Component__c =: SUBMISSION_COMPONENT];
        Set<String> fieldsList = new Set<String>();
        for(SectionSetting__c st : listSectonSetting){
            if(st.Source_Object__c == OPPORTUNITY_OBJ){
                fieldsList.add(st.Source_Field_API__c);
            }
        }
        //added by Jai for Amendment start
        String amendmentType = 'Amendment';
        list<String> amendmentTypes = new list<String>{'Amendment','Update Insured Name or Address'};
        list<String> applicableStatuses = new list<String>{'In Progress','Rated','Referred','Quoted'};
        String innerQueryStr = '(Select Id, Status, Quote_Type__c from Quotes where Status IN :applicableStatuses AND Quote_Type__c IN :amendmentTypes LIMIT 1)';
        //added by Jai for Amendment end
        fieldsList.add('RecordTypeId');
        String queryString = 'SELECT ' + String.join(new List<String>(fieldsList),' , ') + ', '+innerQueryStr +
        ' FROM Opportunity WHERE Id = : oppId' ;
        system.debug('queryString:'+queryString);
        List<Opportunity> listOpps = (List<Opportunity>) Database.query(queryString);
        if(!listOpps.isEmpty())
            return listOpps[0];
        return null;
     }

     @AuraEnabled
     public static Broker_Account__c getBrokerInfos(String oppId) {

        List<SectionSetting__c> listSectonSetting = [SELECT Id,Source_Object__c,Source_Field_API__c 
                                                FROM SectionSetting__c
                                             WHERE Component__c =: SUBMISSION_COMPONENT];
        Set<String> fieldsList = new Set<String>();
        for(SectionSetting__c st : listSectonSetting){
            if(st.Source_Object__c == BROKER_SOURCE_OBJECT){
                fieldsList.add(st.Source_Field_API__c);
            }
        }
        String queryString = 'SELECT ' + String.join(new List<String>(fieldsList),' , ') +
                                ' FROM Broker_Account__c WHERE Opportunity__c = : oppId AND IsPrimaryBroker__c = true' ; // Added by Jai for US:52956
         system.debug('queryString:'+queryString);
        List<Broker_Account__c> listBrokers = (List<Broker_Account__c>) Database.query(queryString);
        if(!listBrokers.isEmpty())
            return listBrokers[0];
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
        public boolean isSubmission                          {get;set;}

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
        public String lookupTo                          {get;set;}
        @AuraEnabled
        public String format                            {get;set;}
        @AuraEnabled
        public String filter                           {get;set;}
        @AuraEnabled
        public Decimal order                            {get;set;}
        @AuraEnabled
        public String value                             {get;set;}
        @AuraEnabled
        public String recordType                        {get;set;}
        @AuraEnabled
        public boolean readOnly                         {get;set;}
        @AuraEnabled
        public Boolean isDependencyPicklist              {get;set;}
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
    
    /**
    * @description : Get product for current record based on quote process or submission.
    * @author Vinayesh | 08-02-2021 
    * @param recordId 
    * @return Product2 
    **/
    @AuraEnabled(cacheable = true)
    public static Product2 getProduct(Id recordId) {
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

            List<Product2> selectedProduct = [SELECT Id,Name FROM Product2
                                                WHERE Name = :productName AND IsComboProduct__c = false];
            if(selectedProduct.size() > 0){
                return selectedProduct[0];
            }
        return null;
    }

    /**
    * @description : Will be used to identify if the Selected Industry is Prohibited for selected MRE clearance on Next button click
    * @author Maeran Shaikh | 07-30-2021 
    * @param oppId 
    * @return String 
    **/

    @AuraEnabled
    public static String getProhibitedClassStatusForIndustry(String oppId){

        // Fetch all POLIS from oppId which are cleared along with its Industry and Sector values
        List<Product_Option_Line_Item__c> lstPolis = [Select Id,Submission__r.Industry__c,Product__r.Name, Submission__r.Service_Classification__c,Is_Selected__c, Clearance_Status__c, Clearance_Date__c, IsManualClearance__c  
                                                        from Product_Option_Line_Item__c where Submission__c =:oppId and Clearance_Status__c  =:CLEARED_STATUS and Is_Selected__c = true ];
        Map<String, String> mapIndustryVsProd = new Map<String, String>();
        String errorMsg = '';
        List<String> prohibitedProds = new List<String>();
 
        // Create basic map of prod vs rating Mod val
        for(Product_Option_Line_Item__c eachPoli :lstPolis ) {
            String ratingModVal = eachPoli.Submission__r.Industry__c+ ':' + eachPoli.Submission__r.Service_Classification__c;
            mapIndustryVsProd.put(eachPoli.Product__r.Name ,ratingModVal );
        }


        // Check across all ES if it exist for selected ori

        for(Eligibility_Status__c eachES:  [Select Id,Rating_Modifier_Value__c, Modifier_Product__c, Rating_Modifier_Name__c 
                            from Eligibility_Status__c where Eligibility_Status__c = :PROHIBITED_CLASS]){
                                if(mapIndustryVsProd.containsKey(eachES.Modifier_Product__c) && mapIndustryVsProd.get(eachES.Modifier_Product__c) ==eachES.Rating_Modifier_Value__c ){
                                    prohibitedProds.add(eachES.Modifier_Product__c);
                                }
                            }
        if(!prohibitedProds.isEmpty()){
            String commaSeperatedProd =  String.join(prohibitedProds,',');

            errorMsg = 'Product(s) '+commaSeperatedProd + ' is(are) prohibited for the selected Industry and Service Classification';
        }
        else{
            errorMsg ='';
        }                    
        return errorMsg;
    }


     /**
    * @description : For PCC for change in Account for submission we only Decline all products if only New Business or Renewal.
    * @author Vinayesh | 01-18-2022
    * @param oppId 
    * @return String 
    **/

    @AuraEnabled
    public static boolean checkDeclineProcessForAccountChange(String oppId){
        Set<Id> oppIds = new Set<Id>();
        oppIds.add((Id)oppId);
        List<Quote> oppQuotes = QuoteQueryUtil.fetchOpenQuotesForOpps(oppIds);
        
        boolean isDeclineOpp = true;
        for(Quote qt: oppQuotes){
            if(!(qt.Quote_Type__c == 'New Business')){
                isDeclineOpp = false;
                break;
            }
        }
        return isDeclineOpp;
    }
}