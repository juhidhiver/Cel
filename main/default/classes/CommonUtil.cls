/**************************************************************************************************
 * Class Name: CommonUtil
 * Author: Huy Tran
 * Date: 13-Sep-2018
 * Description: Common util that used in many class
 **************************************************************************************************/
global with sharing class CommonUtil {
    
    public static Boolean isSetEmpty(Set<String> setString) 
    {
        if (setString == null || setString.isEmpty()) return true;
        List<String> listString = new List<String>(setString);
        if (listString.size() == 1 && listString[0] == null) return true;
        return false;
    }

    public static String getExceptionMessage(Exception ex) 
    {
        String friendlyErrMsg = '';
        String exMsg = ex.getMessage();
        if (exMsg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) 
            friendlyErrMsg = exMsg.substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ' , ': [');
        else if (exMsg.contains('ALREADY_IN_PROCESS')) 
            friendlyErrMsg = exMsg.substringBetween('ALREADY_IN_PROCESS, ' , ': [');
        else if (exMsg.contains('DUPLICATES_DETECTED')) 
            friendlyErrMsg = exMsg.substringBetween('DUPLICATES_DETECTED, ' , ': [');
        else friendlyErrMsg = exMsg;
        
        return friendlyErrMsg;
    }

    public static String getDatabaseErrorMessage(List<Database.Error> errs) {
        List<String> errMsgList = new List<String>();
        for (Database.Error err : errs) {
            errMsgList.add(err.getMessage());
        }
        return String.join(errMsgList, ';');
    }

    public static Decimal convertStringToDecimal(String inputString) {
        Decimal returnVal = null;
        if (String.isNotBlank(inputString)) returnVal = Decimal.valueOf(inputString);
        return returnVal;
    }

    public static Integer convertStringToInteger(String inputString) {
        Integer returnVal = null;
        if (String.isNotBlank(inputString)) returnVal = Integer.valueOf(inputString);
        return returnVal;
    }

    public static String convertNumberToString(Decimal decConvert) {
        if(decConvert == null){
            return '';
        }

        return String.valueOf(decConvert);
    }

    public static String convertDateToString(Date dtConvert) {
        if(dtConvert == null){
            return '';
        }
        
        return String.valueOf(dtConvert);
    }

    public static List<PicklistOption> getPicklistValueFromObjectField(String objApiName, String fieldApiName) {
        List<PicklistOption> plOptions = new List<PicklistOption>();
        SObjectType objectType = Schema.getGlobalDescribe().get(objApiName);
        List<Schema.PicklistEntry> plEntries = objectType.getDescribe().fields.getMap().get(fieldApiName).getDescribe().getPickListValues();
        for (Schema.PicklistEntry plEntry : plEntries) {  
            //system.debug('########plEntry###' + plEntry);                 
            plOptions.add(new PicklistOption(plEntry.getValue(), plEntry.getLabel())); 
        }
        return plOptions;
    }

    public static Map<String, String> getPicklistValueMapFromObjectField(String objApiName, String fieldApiName) {
        Map<String, String> returnMap = new Map<String, String>();
        SObjectType objectType = Schema.getGlobalDescribe().get(objApiName);
        List<Schema.PicklistEntry> plEntries = objectType.getDescribe().fields.getMap().get(fieldApiName).getDescribe().getPickListValues();
        for (Schema.PicklistEntry plEntry : plEntries) {                   
            returnMap.put(plEntry.getValue(), plEntry.getLabel()); 
        }
        return returnMap;
    }

    public static List<String> getPicklistListFromObjectField(String objApiName, String fieldApiName) {
        List<String> plOptions = new List<String>();
        SObjectType objectType = Schema.getGlobalDescribe().get(objApiName);
        List<Schema.PicklistEntry> plEntries = objectType.getDescribe().fields.getMap().get(fieldApiName).getDescribe().getPickListValues();
        for (Schema.PicklistEntry plEntry : plEntries) {  
            plOptions.add(plEntry.getValue()); 
        }
        return plOptions;
    }

    public static List<PicklistOption> getPicklistValueByRecordType(String obj, String field, String recordType) {
        List<PicklistOption> result = new List<PicklistOption>();
        List<String> items = new List<String>(); 
        List<PicklistOption> optionsPicklist = CommonUtil.getPicklistValueFromObjectField(obj, field);

        for (String item : MetadataUtil.getPicklistValuesByRecordType(obj, field, recordType)) {
            for(PicklistOption picklst : optionsPicklist){
                if(picklst.value == item){
                    result.add(picklst);
                }
            }
        }
        return result;
    }
    
    public static Boolean isTriggerBypass(String triggerName) {
        try {
            TriggerSettings__c cs = TriggerSettings__c.getInstance();
            String apiFieldName = 'Bypass' + triggerName + '__c';
            Object isBypass = cs.get(apiFieldName);
            return (isBypass == null) ? false : (Boolean) isBypass;
        } catch (Exception ex) {
            return false;   
        }
    }

    public static API_Configuration__mdt getAPIconfiguration(String argAPIconfigurationName){
        API_Configuration__mdt[] apiConfigurations = [SELECT MasterLabel, DeveloperName, Base_Url__c, Body_Request__c,
                                                            Client_Key__c, Content_Type__c, Endpoint__c, Secret_Key__c,
                                                            HeaderParams__c, Method__c, API_Key__c, Token_URI__c
                                                     FROM API_Configuration__mdt 
                                                     WHERE DeveloperName = :argAPIconfigurationName];
        return apiConfigurations.isEmpty() ? null : apiConfigurations[0];
    }

    public static List<API_Configuration__mdt> getAPIconfigurations() {
        List<API_Configuration__mdt> result = new List<API_Configuration__mdt>();

        result = [SELECT MasterLabel, DeveloperName, Base_Url__c, Body_Request__c,
                    Client_Key__c, Content_Type__c, Endpoint__c, Secret_Key__c,
                    HeaderParams__c, Method__c, API_Key__c, Token_URI__c
                FROM API_Configuration__mdt];

        return result;
    }

    public static Map<String, Product_Setting__mdt> getProductSettingMap(){
        Map<String, Product_Setting__mdt> prodSettingMap = new Map<String, Product_Setting__mdt>();

        for(Product_Setting__mdt prodSetting: [Select Id,MasterLabel,DeveloperName,Eligibility_Status_API__c 
                                                    From Product_Setting__mdt]){
            prodSettingMap.put(prodSetting.MasterLabel, prodSetting);
        }
        return prodSettingMap;
    }

    public static void generateExternalID(String externalIdField, List<SObject> sobjectNews){
        for(SObject rec : sobjectNews){
            if(rec.get(externalIdField) == null){
                rec.put(externalIdField, new GuidUtil().NewGuid());
            }
        }
    }

    public static void sendEmailWithPdf(EmailTemplate emailTemp, String objId, String fileName, 
                                        List<String> emails, Blob pdfBlob,
                                        Map<String,String> valuesReplace) {
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        attach.setContentType('application/pdf');
        attach.setFileName(fileName+'.pdf');
        attach.setInline(false);
        attach.setBody(pdfBlob);

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(objId);
        mail.setTreatTargetObjectAsRecipient(false);
        mail.setUseSignature(false);
        mail.setToAddresses(emails);
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attach });

        String htmlBody = emailTemp.HtmlValue;
        String strBody = emailTemp.Body;
        if(String.isNotBlank(htmlBody)){
            htmlBody = htmlBody.replace('<![CDATA[', '');
            htmlBody = htmlBody.replace(']]>', '');
            
            for(String key : valuesReplace.keySet()){
                if(htmlBody.contains(key)) {
                    // ex: key = '{!Contact.FirstName}'
                    htmlBody = htmlBody.replace(key, valuesReplace.get(key));
                }
                if(strBody.contains(key)) {
                    // ex: key = '{!Contact.FirstName}'
                    strBody = strBody.replace(key, valuesReplace.get(key));
                }
            }
        }
       
        mail.setSubject(emailTemp.Subject);
        mail.setHtmlBody(htmlBody);
        mail.setPlainTextBody(strBody);
        mail.setTemplateId(emailTemp.Id);
        // Send the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
    }
    
    /*Prachi added*/
    
    public static void sendEmail(EmailTemplate emailTemp, Quote q, 
                                        List<String> emails, String subName) {
        Quote quoteToUse = [Select Id, Quote.Opportunity.Name, UW_Link__c from Quote where Id=: q.Id ];                                
        String subject = quoteToUse.Opportunity.Name; 
        String htmlBody = emailTemp.HtmlValue;
        htmlBody = htmlBody.replace('{!Quote.UW_Link__c}', quoteToUse.UW_Link__c);
        htmlBody = htmlBody.replace('{!Approval_Requesting_User.Name}', subName);                                       
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(UserInfo.getUserId());
        mail.setWhatId(q.Id);                                    
        mail.setTreatTargetObjectAsRecipient(false);
        mail.setSaveAsActivity(false);                                    
        mail.setUseSignature(false);
        mail.setToAddresses(emails);   
        mail.setSubject(subject);                                 
        mail.setHtmlBody(htmlBody);
        //mail.setPlainTextBody(strBody);
        mail.setTemplateId(emailTemp.Id);
        
        system.debug('emails'+emails);                                     
        // Send the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
    }


    /*************************************************
    * Author: Tuan
    * Date: 1-Aug-2019
    * @param: fields - list of field needed to be queried
    * @param: objectName - Sobject or custom metadata name
    * @param: condition -  formatted condition without 'WHERE'          
    * Return: valid soql
    * Revision: 
    *************************************************/
    public static String buildQuery(List<String> fields, String objName, String condition) {
        String result = '';
        List<String> params = new List<String>();
        String format = 'SELECT {0} FROM {1} {2}';

        String fieldParam = String.join(fields, ', ');
        params.add(fieldParam);
        params.add(objName);
        if (String.isNotBlank(condition)) {
            String conParam = 'WHERE ' + condition;
            params.add(conParam);
        } else {
            params.add(condition);
        }

        result = String.format(format, params);
        return result;
    }

    public static String buildQuery(QueryObject obj) {
        String result = '';
        List<String> params = new List<String>();
        String orderParam = '';
        String limitParam = '';
        String offsetParam = '';

        try {
            String format = '{0} {1} {2}';
            String query = buildQuery(obj.fields, obj.name, obj.condition);
            
            params.add(query);

            if (String.isNotBlank(obj.orderByField)) {
                orderParam = 'ORDER BY ' + obj.orderByField + ' ' + obj.orderType;
            }

            if (obj.pageSize > 0) {
                limitParam = 'LIMIT ' + obj.pageSize;
            }

            if (obj.pageNumber > 0) {
                offsetParam = 'OFFSET ' + (obj.pageNumber - 1) * obj.pageSize;
            }

            params.add(orderParam);
            params.add(limitParam);
            params.add(offsetParam);

            result = String.format(format, params);
        } catch (Exception ex) {
            result = '';
        }
        return result;
    }

    /*************************************************
    * Author: Tuan
    * Date: 3-Sep-2019
    * @param: obj - Sobject Name
    * @param: condition -  formatted condition without 'WHERE'          
    * Return: valid soql
    * Description: Build a dynamic select * query 
    *              Limit to objects with less than 100 fields
    * Revision: 
    *************************************************/
    public static String buildQuerySelectAll(String obj, String condition) {
        String result = '';

        if (String.isBlank(obj)) {
            return result;
        }
        try {
            SObjectType objType = Schema.getGlobalDescribe().get(obj);
            DescribeSObjectResult desResult = objType.getDescribe(); 
            List<String> fields = new List<String>(desResult.fields.getMap().keySet());
            if (fields.isEmpty()) {
                return result;
            }

            result = CommonUtil.buildQuery(fields, obj, condition);

        } catch (Exception ex) {
            result = '';
        }
        
        return result;
    }

    public static String getObjectNameById(String id) {
        String result = '';
        if (String.isBlank(id)) {
            return result;
        }

        try {
            Id parentId = id;
            DescribeSObjectResult desResult = parentId.getSObjectType().getDescribe(); 
            result = desResult.getName();
        } catch (Exception ex) {
            result = '';
        }
        
        return result;
    }

    /*************************************************
    * Author: Tuan Nguyen
    * Date: 22-Aug-2019
    * Params: none  
    * Return: List of Rating_Modifier_Template__c
    * Description: Get all rating template
    * Revision: 
    *************************************************/
    public static List<Rating_Modifier_Template__c> getRatingTemplatesByProducts(List<String> products) {
        List<Rating_Modifier_Template__c> result = new List<Rating_Modifier_Template__c>();
        List<String> fields = new List<String>();
        String condition = '';
        try {
            fields.add('Factor_Default_Value__c');
            fields.add('Factor_Max__c');
            fields.add('Factor_Min__c');
            fields.add('Modifier_Format__c');
            fields.add('Product__c');
            fields.add('Name');
            fields.add('Page_Section__c');
            fields.add('Picklist_Default_Value__c');
            fields.add('Picklist_Range__c'); 
            fields.add('Picklist_Values__c');
            fields.add('Sort_Order__c');
            fields.add('Sort_Sub_Section__c');
            fields.add('Comment__c');
            fields.add('Sub_Section__c');
            fields.add('Eligibility_Weighting_Factor__c');
            fields.add('Rating_Modifier_Code__c');
            fields.add('Display_Format__c');
            fields.add('Profile_Name_for_Read_Only__c');
            fields.add('Is_Required__c');
            fields.add('Create_Criteria__c');
            fields.add('Order_of_Page_Section__c');
            fields.add('Rating__c'); // Added for US:53759
            String objName = 'Rating_Modifier_Template__c';
            if (products !=null && !products.isEmpty()) {
                condition = 'Product__c INCLUDES (\''+ String.join(products,'\',\'') + '\') ';
                // condition = 'Modifier_Product__c in (\''+ String.join(products,'\',\'') + '\')';
            }
            
            String query = CommonUtil.buildQuery(fields, objName, condition);
            System.debug(query);
            result = Database.query(query);
        } catch (Exception ex) {
            result = new List<Rating_Modifier_Template__c>();
        }

        return result;
    }

    public static List<Rating_Modifiers__c> getRatingModifiersByOppIds(Set<String> ids) {
        List<Rating_Modifiers__c> result = new List<Rating_Modifiers__c>();
        try {
            result = [SELECT Id, Eligibility_Weighting_Factor__c,
                        Factor_Default_Value__c, Factor_Max__c,
                        Factor_Min__c, Name, Opportunity__c, 
                        Product__c, Page_Section__c,
                        Picklist_Values__c, Rating_Modifier_Code__c,  
                        Sort_Order__c, Sub_Section__c
                    FROM Rating_Modifiers__c
                    WHERE Opportunity__c IN :ids];
            
        } catch (Exception ex) {
            result = new List<Rating_Modifiers__c>();
        }

        return result;
    }

    public static List<CoveragesLineItem__c> getCoveragesLineItemsByQuotes(List<String> ids){
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        try {
            if (ids.isEmpty()) {
                return result;
            }

            String condition = 'Quote__c in (\''+ String.join(ids,'\',\'') + '\')';
            String query = CommonUtil.buildQuerySelectAll('CoveragesLineItem__c', condition);

            result = Database.query(query);           
        } catch (Exception ex) {
            result.clear();
        }

        return result;
    }

    /*************************************************
    * Author: Tuan
    * Date: 9-Sep-2019
    * @param: parentObj - Parent object api name
    * @param: objName - Child object     
    * Return: Lookup or master detail field
    * Description: Get relationship field based on 2 input object
    * Revision: 
    *************************************************/
    public static String getRelationshipField(String parentObj , String objName) {
        String parent_field;
        try {
            SObjectType objType = Schema.getGlobalDescribe().get(objName);
            if (objType == null || String.isBlank(parentObj)) return parent_field;

            for(Schema.SobjectField strFld: objType.getDescribe().fields.getMap().Values()) 
            { 
                if(strFld.getDescribe().getType() == Schema.DisplayType.REFERENCE && 
                    strFld.getDescribe().getReferenceTo().get(0).getDescribe().getName()== parentObj) 
                { 
                    parent_field = strFld.getDescribe().getLocalName();
                    break;
                }  
            } 
        } catch (Exception ex) {
            parent_field = '';
        }
        return parent_field;
    }

    public static String convertToString(Object o) {
        return o != null ? String.valueOf(o) : '';
    }

    public static String convertToStringOrNull(Object o) {
        return o != null ? String.valueOf(o) : null;
    }

    public static Date parseDateFromString(String stringDate) {
        // stringDate format is YYYY-MM-DD
        // For example: 2019-02-20
        Date returnDate = null;
        if (String.isNotBlank(stringDate)) {
            List<String> dateElements = stringDate.split('-');
            returnDate =  Date.newInstance(Integer.valueOf(dateElements[0]),   // year
                                           Integer.valueOf(dateElements[1]),   // month
                                           Integer.valueOf(dateElements[2]));  // day
        }
        return returnDate;
    }
    /*************************************************
    * Author: Priyanka
    * Date: 04-Nov-2020
    * Description: Parse DateTime From String
    * Revision: 
    *************************************************/
        public static Datetime parseDatetimeFromString(String stringDatetime) {
        // stringDatetime format is YYYY-MM-DDTHH:mm:SS+00:00
        // For example: 2019-02-20T07:06:37+00:00
        Datetime returnDatetime = null;
        if (String.isNotBlank(stringDatetime)) {
            List<String> yearMonthDayElements = stringDatetime.split('T')[0].split('-');
            List<String> hourMinuteSecondElements = stringDatetime.split('T')[1].split(':');
            Integer year = Integer.valueOf(yearMonthDayElements[0]);
            Integer month = Integer.valueOf(yearMonthDayElements[1]);
            Integer day = Integer.valueOf(yearMonthDayElements[2]);
            Integer hour = Integer.valueOf(hourMinuteSecondElements[0]);
            Integer minute = Integer.valueOf(hourMinuteSecondElements[1]);
            Integer second = Integer.valueOf(hourMinuteSecondElements[2].left(2));
            returnDatetime = Datetime.newInstance(year, month, day, hour, minute, second);
        }
        return returnDatetime;
    }

    //////////////////////////////Lightning Data Table Stuff///////////////////
    private static String getRelationShipName(String parent, String child) {
        String result = '';
        // get object describe
        SObjectType objType = Schema.getGlobalDescribe().get(parent);
        DescribeSObjectResult desResult = objType.getDescribe(); 

        // get all child relationship from parent 
        List<Schema.ChildRelationship> rels = desResult.getChildRelationships();
        for (Schema.ChildRelationship item : rels) {
            if (item.getChildSObject().getDescribe().getName().equals(child)) {
                result = item.getRelationshipName();
                break;
            }
        }
        return result;
    }
    
    public static LightningDataTableWrapper generateDatatable(Id parentId, String childObj, Object fieldsObj, String childRecordTypeId) {
        LightningDataTableWrapper result = new LightningDataTableWrapper();
        LightningDataTableWrapper.DatatableColumn actionColumn = new LightningDataTableWrapper.DatatableColumn();
        List<Schema.SObjectField> fieldList = new List<Schema.SObjectField>();
        
        try {
            String parentObj = parentId.getSObjectType().getDescribe().getName();
            String condition = getRelationshipField(parentObj, childObj) + '= \'' + parentId + '\'';
            
            if(String.isNotBlank(childRecordTypeId)) {
                List<RecordType> RTList = [select Id from RecordType where sObjectType= :childObj AND Id =: childRecordTypeId];
                if(!RTList.isEmpty()) {
                    condition += ' AND RecordType.Id ' + '= \'' + childRecordTypeId + '\'';
                }
               
            }
            String combinedFields = String.valueOf(fieldsObj);
            // object is empty
            if (String.isBlank(combinedFields)) return result;
            
            List<String> fields = combinedFields.split(',');

            // get field list
            fieldList = getFieldList(fields, childObj);
            System.debug(fieldList);
            //Get data
            //fields.add('Id');
            System.debug('build Query:' + CommonUtil.buildQuery(fields, childObj, condition));
            result.data = Database.query(CommonUtil.buildQuery(fields, childObj, condition));
            //       
            result.columns = generateDatatableColumn(fieldList);
            result.name = getObjectLabel(childObj);
            result.nameAPI = childObj;
            result.parentFieldAPI = getRelationshipField(parentObj, childObj);
            result.relationshipName = getRelationShipName(parentObj,childObj);
            result.permission = LightningDataTableWrapper.getObjectPermission(childObj);

            // get row actions
            actionColumn = LightningDataTableWrapper.getTableRowActionByPermission(result.permission);
            result.columns.add(actionColumn);
        } catch (Exception ex) {
            //System.debug(ex.getMessage());
            result = new LightningDataTableWrapper();
        }
        return result;
    }

    private static List<LightningDataTableWrapper.DatatableColumn> generateDatatableColumn(List<Schema.SObjectField> items) {
        List<LightningDataTableWrapper.DatatableColumn> result = new List<LightningDataTableWrapper.DatatableColumn>();
        try {
            for(Schema.SObjectField item : items) {
                Schema.DescribeFieldResult fieldResult = item.getDescribe();
                LightningDataTableWrapper.DatatableColumn col = new LightningDataTableWrapper.DatatableColumn();
                String fieldName = fieldResult.getName();
                String lbl = fieldResult.getLabel();
                String fieldType = fieldResult.getType().name();
                System.debug(fieldResult.getType());
                System.debug(fieldName);
                if (fieldName.toLowerCase().equals('name') || fieldName.toLowerCase().equals('lastname')) col = LightningDataTableWrapper.generateRecordLinkColumn(fieldName, lbl);
                else {
                    col.label = lbl;
                    col.fieldName = fieldName;
                    col.type = LightningDataTableWrapper.getColumnTypeByFieldType(fieldType);
                    col.typeAttributes = LightningDataTableWrapper.generateTypeAttribute(fieldResult);
                    col.cellAttributes = LightningDataTableWrapper.generateCellAttribute(col.type);
                }

                col.sortable = fieldResult.isSortable();
                //col.type = 'text';
                result.add(col);
            }
        } catch (Exception ex) {
            result = new List<LightningDataTableWrapper.DatatableColumn>();
        }
        
        return result;
    }

        public static String getObjectLabel(String objName) {
            String result = '';
            try {
                SObjectType objType = Schema.getGlobalDescribe().get(objName);
                DescribeSObjectResult desResult = objType.getDescribe();  
                // user don't have access to object  
                if (!desResult.isAccessible()) return result;
                result = desResult.getLabel();
            } catch (Exception ex) {
                System.debug(ex.getMessage());
            }
            return result;
        }

    public static List<Schema.SObjectField> getFieldList(List<String> fields, String objName) {
        List<Schema.SObjectField> result = new List<Schema.SObjectField>();
        try {
            SObjectType objType = Schema.getGlobalDescribe().get(objName);
            Boolean isObjAccessible = objType.getDescribe().isAccessible();  
            // user don't have access to object  
            if (!isObjAccessible)  return result;
   
            Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
            Set<String> fieldSet = fieldMap.keyset();
            String lowerCaseName = '';

            for (String fieldName : fields) {
                // Convert field to lower case to compare
                lowerCaseName = fieldName.toLowerCase();
                // field is not exist
                if (!fieldSet.contains(lowerCaseName)) continue;

                // user don't have access to field
                Schema.SObjectField field = fieldMap.get(lowerCaseName);
                if (field.getDescribe().isAccessible()) result.add(field);
            }
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            result = new List<Schema.SObjectField>();
        }
        return result;
    }

    public static String getReportIdByDevName(String rptName) {
        String reportId = '';
        List<Report> reports = [Select Id From Report where DeveloperName =: rptName limit 1];
        if(!reports.isEmpty()) reportId = reports[0].Id;
        
        return reportId;
    }

    public static String getReportFilterString(String rptName, List<Reports.ReportFilter> rptFilterList) {
        String returnStr='';
        String reportId = getReportIdByDevName(rptName);
        if(String.isNotBlank(reportId)) {
            returnStr = '/lightning/r/Report/' + reportId + 
                        '/view?reportFilters=' + EncodingUtil.urlEncode(JSON.serialize(rptFilterList),'UTF-8');
        }
        return returnStr;
    }

    public static List<Id> getUserIdInGroupByGroupName(String groupName) {
        List<Id> returnUserIds = new List<Id>();
        try {
            String groupId = [Select Id From Group Where Name = :groupName][0].Id;
            for (GroupMember gm : [Select UserOrGroupId From GroupMember Where GroupId = :groupId]) {
                returnUserIds.add(gm.UserOrGroupId);
            }    
        } catch (Exception ex) {
            //system.debug('CommonUtil.getUserListInGroupByGroupName.ex= ' + CommonUtil.getExceptionMessage(ex));
        }
        return returnUserIds; 
    }

    /*************************************************
    * Author: Binh Dang
    * Date: 19-Sept-2019
    * Params: Object API Name, list of fields  
    * Return: Map<API field Name,field Label>
    * Description: For QuoteEndorsementChangeSummaryCtrl
    *************************************************/
    public static Map<String, String> getCustomFieldsByObjectMap(String objName, List<String> fieldList) {
        Map<String, String> returnMap = new Map<String, String> ();
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(objName).getDescribe().fields.getMap();
        for(Schema.SObjectField sfield : fieldMap.Values())
        {
            Schema.DescribeFieldResult dfield = sfield.getDescribe();
            if(fieldList.isEmpty()){
                if(dfield.getname().contains('__c')) returnMap.put(dfield.getname(),dfield.getLabel());
            }else{
                if(dfield.getname().contains('__c') && fieldList.contains(dfield.getname()))
                    returnMap.put(dfield.getname(),dfield.getLabel());
            }
        }

        return returnMap;
    }

    /*************************************************
    * Method Name: getProductSettingMdtByField
    * Author: Binh Dang
    * Date: 20-Sept-2019
    * Params: 
    * Return: mdt record
    * Exceptions:
    * Revision: 
    *************************************************/
    public static sObject getMetaDataTypeSettingByField(String mdtName, String fieldsGet, String fieldCheck,String valueCheck){
        // validate parameters are blank
        if(String.isBlank(valueCheck) || String.isBlank(fieldCheck) || String.isBlank(mdtName)) return null;
        sObject settingReturn = null;
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(mdtName).getDescribe().fields.getMap();
    
        List<String> slist = new List<String>();
        for(Schema.SObjectField sfield : fieldMap.Values())
        {
            Schema.DescribeFieldResult dfield = sfield.getDescribe();
            if(dfield.getname().contains('__c')) slist.add(dfield.getname());
        }
      
        String soql = 'Select Label, DeveloperName, MasterLabel, '+ 
                        (String.isBlank(fieldsGet) ? String.join(sList,',') : fieldsGet) +
                        ' From ' + mdtName + ' Where ' + fieldCheck + ' =: valueCheck' +
                        ' And Active__c = true';
        for(sObject tmp : Database.query(soql)) 
        {
            String fieldValue = (String)tmp.get(fieldCheck);
            // Check field has multiple value that format ","
            if(fieldValue.indexOf(',') != -1) {
                for(String value : fieldValue.split(',')) {
                    if(valueCheck.contains(value)) {
                        settingReturn = tmp;
                        break;
                    }
                } 
            } else if(valueCheck.contains(fieldValue)) settingReturn = tmp;
        }
        
        return settingReturn;
    }

    /*************************************************
    * Method Name: createAuraHandledException
    * Author: Hoang Bui
    * Date: 06-Oct-2019
    * Description: Display the custom error message
    * Params: 
    * Return: AuraHandledException
    * Exceptions:
    * Revision: 
    *************************************************/    
    public static AuraHandledException createAuraHandledException(String methodName,String Message){
        AuraHandledException e = new AuraHandledException(Message);
        e.setMessage(Message);
        system.debug(methodName + e);
        return e; 
    }

    public static LightningDataTableWrapper generateDatatable(Id parentId, String childObj, Object fieldsObj) {
        LightningDataTableWrapper result = new LightningDataTableWrapper();
       LightningDataTableWrapper.DatatableColumn actionColumn = new LightningDataTableWrapper.DatatableColumn();
       List<Schema.SObjectField> fieldList = new List<Schema.SObjectField>();
       
       try {
           String parentObj = parentId.getSObjectType().getDescribe().getName();
           String condition = getRelationshipField(parentObj, childObj) + '= \'' + parentId + '\'';

           String combinedFields = String.valueOf(fieldsObj);
           // object is empty
           if (String.isBlank(combinedFields)) return result;
           
           List<String> fields = combinedFields.split(',');

           // get field list
           fieldList = getFieldList(fields, childObj);
           System.debug(fieldList);
           //Get data
           //fields.add('Id');
           result.data = Database.query(CommonUtil.buildQuery(fields, childObj, condition));
           //       
           result.columns = generateDatatableColumn(fieldList);
           result.name = getObjectLabel(childObj);
           result.nameAPI = childObj;
              result.parentFieldAPI = getRelationshipField(parentObj, childObj);
           result.relationshipName = getRelationShipName(parentObj,childObj);
           result.permission = LightningDataTableWrapper.getObjectPermission(childObj);

           // get row actions
           actionColumn = LightningDataTableWrapper.getTableRowActionByPermission(result.permission);
           result.columns.add(actionColumn);
       } catch (Exception ex) {
           //System.debug(ex.getMessage());
           result = new LightningDataTableWrapper();
       }
       return result;
   }

   

    public static List<PicklistOption> getPicklistEndorsementOperations(String productName) {
       //Added by Vinayesh on 04/06/2021 for US: Cd :15 
       System.debug('vinay -' + productName);
       
        List<PicklistOption> lstResult = new List<PicklistOption>(); // return values
        List<PicklistOption> lstReturnResult = new List<PicklistOption>();
        if(String.isBlank(productName)) return lstResult;
        List<Product_Setting__mdt> settings = new List<Product_Setting__mdt>();
        if(productName == 'Professional Indemnity'){
            settings = getProductSettingsAQ(productName.replace(' ', '_'));
        }else{
            //Added by Vinayesh on 04/06/2021 for US: Cd :15 
            if(productName == 'Cyber Standalone'){
                productName = 'Cyber';
                settings = getProductSettings(productName.replace(' ', '_')); //Get product setting to get picklist option from Endorsement_Operation__c field
            }else if( productName == Label.Product_Name_for_PCC ){
                settings = getProductSettings(productName.replace(' ', '_')); //Get product setting to get picklist option from Endorsement_Operation__c field
            }else if( productName == 'MPL Standalone' ){
                settings = getProductSettings(productName.replace(' ', '_')); //Get product setting to get picklist option from Endorsement_Operation__c field
            }
        }
       
        if (!settings.isEmpty() && String.isNotBlank(settings[0].Endorsement_Operation__c)) {       
            lstResult.clear();// remove old value
            List<PicklistOption> plOptions = new List<PicklistOption>();
            for(String operation : settings[0].Endorsement_Operation__c.split(',')){
                plOptions.add(new PicklistOption(operation, operation)); 
            }
            lstResult.addAll(plOptions);
        }else {
            lstResult = CommonUtil.getPicklistValueFromObjectField('Quote', 'Quote_Type__c');
            for(Integer i = 0; i < lstResult.size(); i++){
                System.debug('lstResult[i].value-->'+lstResult[i].value);
                if( lstResult[i].value == 'New Business' || lstResult[i].value == 'Extension' || lstResult[i].value == 'Full Amendment')
                lstResult.remove(i);
                if(lstResult[i].value == 'Coverage Amendment')  lstResult.remove(i);
                if(productName == 'Professional Indemnity'){
                    if(lstResult[i].value == 'Policy Duration Change')	lstResult.remove(i);
                }
                //if(lstResult[i].value == 'Flat Cancellation') lstResult.remove(i);
                if(lstResult[i].value == 'Insured Account Update')  lstResult.remove(i);
            }
            System.debug('lstResult-->'+lstResult);
        }
        return lstResult;
    }
    
     /*************************************************
    * Author: Jai Singh
    * Date: 17-Sep-2021
    * Params: Endorsement Operations
    * Return: map<String,String> (Text for each Endorsement Operation)
    * Revision: 
    *************************************************/

    public static map<String,String> getEndorsementOperationsHelpText(list<String> endorsementOperations) {
        Map<String,String> result = new Map<String,String>();
        if( !endorsementOperations.isEmpty() ){
            List<Amendment_Configuration__mdt> utilConfigList = new List<Amendment_Configuration__mdt>();
            List<String> fields = new List<String>();
            List<String> conditions = new List<String>();
            try {
                //fields.add('MasterLabel');
                fields.add('Help_Text__c');
                fields.add('Amendment_Name__c');
                
                String objName = 'Amendment_Configuration__mdt';
                String nameCon = '';
                for( String endOp : endorsementOperations){
                    if( String.isNotBlank(nameCon) ){
                        nameCon += ',';
                    }
                    nameCon += '\''+endOp+'\'';
                }
                nameCon = 'Amendment_Name__c IN ('+nameCon+')';
                conditions.add('Active__c = true');
                conditions.add(nameCon);
                String con = String.join(conditions, ' AND ');

                String query = CommonUtil.buildQuery(fields, objName, con);
                System.debug('query-->'+query);
                utilConfigList = (List<Amendment_Configuration__mdt>)Database.query(query);
                System.debug('utilConfig: '+utilConfigList);
                for(Amendment_Configuration__mdt utilConfig : utilConfigList){
                    result.put(utilConfig.Amendment_Name__c, utilConfig.Help_Text__c);
                }
            } catch (Exception ex) {
                System.debug(ex.getMessage());
            }
        }
        return result;
   }

     public static List<PicklistOption> getPicklistEndorsementOperationsAQ(String endorsementType) {
       // string endoLabel;
        List<PicklistOption> lstResult = new List<PicklistOption>(); 
        if(String.isBlank(endorsementType)) return lstResult;
        List<AQ_Endorsements__mdt> settings = new List<AQ_Endorsements__mdt>();
         
         if(endorsementType == 'Flat Cancellation') endorsementType = 'Flat Cancellation';
         endorsementType = endorsementType.replace(' ', '_');
         endorsementType = endorsementType.replace('&', 'And');
         settings = getAQEndorsement(endorsementType);
         //settings = getAQEndorsement(endorsementType.replace(' ', '_'));
         
        if (!settings.isEmpty() && String.isNotBlank(settings[0].Endorsement_Reason__c)) {       
            lstResult.clear();// remove old value
            List<PicklistOption> plOptions = new List<PicklistOption>();
            for(String operation : settings[0].Endorsement_Reason__c.split(',')){
                plOptions.add(new PicklistOption(operation, operation)); 
            }
            lstResult.addAll(plOptions);
        }
        return lstResult;
    }
     
    public static List<Product_Setting__mdt> getProductSettings(String settingName) {
        List<Product_Setting__mdt> result = new List<Product_Setting__mdt>();
        List<String> fields = new List<String>();
        List<String> conditions = new List<String>();
        try {
            fields.add('MasterLabel');
            fields.add('Endorsement_Operation__c');//add 20 Aug 2019
             //Added by Vinayesh on 04/06/2021 for US: Cd :15 
            //fields.add('Quote_Product_Column__c');

            fields.add('DeveloperName');

            //Added by Vinayesh on 04/06/2021 for US: Cd :15 
            //fields.add('Icons__c');
            
            String objName = 'Product_Setting__mdt';
            String nameCon = 'DeveloperName= \'' + settingName + '\'';
            conditions.add('Active__c = true');
            conditions.add(nameCon);
            String con = String.join(conditions, ' AND ');

            String query = CommonUtil.buildQuery(fields, objName, con);
            System.debug('query-->'+query);
            result = Database.query(query);
            System.debug('return: '+result);
        } catch (Exception ex) {
            //Added by Vinayesh on 04/06/2021 for US: Cd :15 
            System.debug(ex.getMessage());
        }
      
        return result;
    }
    
    public static List<AQ_Endorsements__mdt> getAQEndorsement(String settingName) {
        List<AQ_Endorsements__mdt> result = new List<AQ_Endorsements__mdt>();
        List<String> fields = new List<String>();
        List<String> conditions = new List<String>();
        try {
            fields.add('MasterLabel');
            fields.add('Endorsement_Reason__c');
            fields.add('DeveloperName');
            
            String objName = 'AQ_Endorsements__mdt';
            String nameCon = 'DeveloperName= \'' + settingName + '\'';
            conditions.add(nameCon);
            String con = String.join(conditions, ' AND ');

            String query = CommonUtil.buildQuery(fields, objName, con);
            System.debug('query-->'+query);
            result = Database.query(query);
            System.debug('return: '+result);
        } catch (Exception ex) {            
        }
        return result;
    }
    
    public static List<Product_Setting__mdt> getProductSettingsAQ(String settingName) {
        List<Product_Setting__mdt> result = new List<Product_Setting__mdt>();
        List<String> fields = new List<String>();
        List<String> conditions = new List<String>();
        try {
            fields.add('MasterLabel');
            fields.add('Endorsement_Operation__c');
            fields.add('DeveloperName');
            
            String objName = 'Product_Setting__mdt';
            String nameCon = 'DeveloperName= \'' + settingName + '\'';
            conditions.add(nameCon);
            String con = String.join(conditions, ' AND ');

            String query = CommonUtil.buildQuery(fields, objName, con);
            System.debug('query-->'+query);
            result = Database.query(query);
            System.debug('return: '+result);
        } catch (Exception ex) {            
        }
        return result;
    }

    /*************************************************
    * Author: Giang Phan
    * Date: 09-June-2020
    * Params: Setting Name - Fields Get - Fields Check - Value Check
    * Return: getSettingByField
    * Revision: 
    *************************************************/
    public static sObject getSettingByField(String settingName, String fieldsGet, String fieldCheck,String valueCheck){
        // validate parameters are blank
        if(String.isBlank(valueCheck) || String.isBlank(fieldCheck) || String.isBlank(settingName)) return null;
        sObject settingReturn = null;
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(settingName).getDescribe().fields.getMap();
        
        List<String> slist = new List<String>();
        for(Schema.SObjectField sfield : fieldMap.Values())
        {
            Schema.DescribeFieldResult dfield = sfield.getDescribe();
            if(dfield.getname().contains('__c'))  slist.add(dfield.getname());
        }
        
        Set<String> fieldsSet = settingName.contains('__mdt') ? new Set<String>{'Label','DeveloperName','MasterLabel'} : new Set<String>{'Name'};
            if(String.isBlank(fieldsGet)) fieldsSet.addAll(slist);
        else{
            if(fieldsGet.contains(',')) fieldsSet.addAll(fieldsGet.split(','));
            else fieldsSet.add(fieldsGet);
        }
        fieldsSet.add(fieldCheck);
        String condition = fieldCheck +  '=:valueCheck And Active__c = true';
        for(sObject tmp : Database.query(CommonUtil.buildQuery(new List<String>(fieldsSet), settingName, condition) )) 
        {
            String fieldValue = (String)tmp.get(fieldCheck);
            // Check field has multiple value that format ","
            if(fieldValue.indexOf(',') != -1) {
                for(String value : fieldValue.split(',')) {
                    if(valueCheck.contains(value)) {
                        settingReturn = tmp;
                        break;
                    }
                } 
            } else if(valueCheck.contains(fieldValue)) settingReturn = tmp;
        }
        
        return settingReturn;
    }

    /*************************************************
    * Author: Giang Phan
    * Date: 09-June-2020
    * Params: Id
    * Return: getProductNameByQuoteId
    * Revision: 
    *************************************************/
    @AuraEnabled
    public static String getProductNameByQuoteId(String id){
        String result = '';
        try {
            List<Quote> quotes = [SELECT Id, Opportunity.Product__r.Name FROM Quote WHERE Id =: id LIMIT 1];
            result = quotes.isEmpty() ? '' : quotes[0].Opportunity.Product__r.Name;
        } catch (Exception ex) {
            System.debug(ex.getMessage());
        }
        return result;
    }

    /*************************************************
    * Author: Giang Phan
    * Date: 09-June-2020
    * Params: Parent Object - Object Name
    * Return: getParentFieldFromChildObj
    * Revision: 
    *************************************************/
    public static String getParentFieldFromChildObj(String parentObj , String objName) {
        String parent_field;
        try {
            SObjectType objType = Schema.getGlobalDescribe().get(objName);
            if (objType == null || String.isBlank(parentObj)) return parent_field;
            
            for(Schema.SobjectField strFld: objType.getDescribe().fields.getMap().Values()) 
            { 
                if(strFld.getDescribe().getType() == Schema.DisplayType.REFERENCE && 
                   strFld.getDescribe().getReferenceTo().get(0).getDescribe().getName()== parentObj) 
                { 
                    parent_field = strFld.getDescribe().getLocalName();
                    break;
                }  
            } 
        } catch (Exception ex) {
            parent_field = '';
        }
        return parent_field;
    }

    /*************************************************
    * Author: Giang Phan
    * Date: 09-June-2020
    * Params: Parent Object - Childs Name
    * Return: getRelationShipNames
    * Revision: 
    *************************************************/
    public static String getRelationShipNames(String parentObj, String childObj) {
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        List<Schema.ChildRelationship> RList = schemaMap.get(parentObj).getDescribe().getChildRelationships();
        for (Schema.ChildRelationship s : RList) {
            if( String.valueOf(s.getChildSObject()) == childObj) return String.valueOf(s.getRelationshipName());
        }
        return '';
    }
    public static Change_Log__c createChangeLog(String policyId, String endorsementType,string oppId){
        Change_Log__c clRec = new Change_Log__c();
        clRec.Policy__c = policyId;
        clRec.Change_Date__c = System.today();
        clRec.Change_Type__c = endorsementType;
        
        if(oppId!=null){
          clRec.Opportunity__c=oppId; 
        }
        return clRec;
    }
    
    /*************************************************
    * Author: Vinayesh
    * Date: 19-July-2021
    * Params: Opportunities Map
    * Return: None
    * Description: Update Rating Modifiers Industry and Service Classification records for PCC
    *************************************************/
    public static void updateRatingModifiersForOpps(Map<Id, Opportunity> oppMap, Map<Id, Opportunity> oldOppMap) {
     try {
        Map<Id, Opportunity> pccOppMap = new Map<Id, Opportunity>();
        for(Opportunity opp : oppMap.values()){
            if(opp.Product_Name__c == 'Private Company Combo'){
                if(oldOppMap == null){
                    pccOppMap.put(opp.Id, opp);
                }
                else if(opp.Industry__c != oldOppMap.get(opp.Id).Industry__c || 
                opp.Service_Classification__c != oldOppMap.get(opp.Id).Service_Classification__c){
                    pccOppMap.put(opp.Id, opp);
                }
            }
        }
        List<Rating_Modifiers__c> ratingMods = new List<Rating_Modifiers__c>();
        List<Rating_Modifiers__c> ratingModsToUpdate = new List<Rating_Modifiers__c>();
        
            ratingMods = [SELECT Id, Eligibility_Weighting_Factor__c,
                        Factor_Default_Value__c, Factor_Max__c,
                        Factor_Min__c, Name, Opportunity__c, 
                        Product__c, Page_Section__c, Rating_Modifier_Value__c,
                        Picklist_Values__c, Rating_Modifier_Code__c,  
                        Sort_Order__c, Sub_Section__c, Eligibility_Status__c,
                        Dependent_Picklist_Value__c, Controlling_Picklist_Value__c
                        FROM Rating_Modifiers__c
                        WHERE Opportunity__c IN :pccOppMap.keySet() 
                        AND ((Controlling_Picklist_API_Name__c = 'Industry__c'
                        AND Dependent_Picklist_API_Name__c = 'Service_Classification__c') OR (Name like 'Selected Industry'))];
            for(Rating_Modifiers__c rm : ratingMods){
                Opportunity currOpp = pccOppMap.get(rm.Opportunity__c);
                if(rm.Name.containsIgnoreCase('Selected Industry')){
                    rm.Rating_Modifier_Value__c = currOpp.Industry__c + ' - ' + currOpp.Service_Classification__c;
                    rm.Eligibility_Status__c = null;
                    ratingModsToUpdate.add(rm);
                }
                else if(rm.Controlling_Picklist_Value__c != currOpp.Industry__c || 
                    rm.Dependent_Picklist_Value__c != currOpp.Service_Classification__c){
                        rm.Controlling_Picklist_Value__c = currOpp.Industry__c;
                        rm.Dependent_Picklist_Value__c = currOpp.Service_Classification__c;
                        rm.Rating_Modifier_Value__c = currOpp.Industry__c + ' - ' + currOpp.Service_Classification__c;
                        rm.Eligibility_Status__c = null;
                        ratingModsToUpdate.add(rm);
                    }
                }

           if(ratingModsToUpdate.size() > 0){
               update ratingModsToUpdate;
           }
            
        } catch (Exception ex) {
            System.debug(ex.getMessage());
        }
    }


     /*************************************************
    * Author: Vinayesh
    * Date: 21-May-2022
    * Params: quote id
    * Return: None
    * Description: Update overall rating factor calculated value for all coverage products for PCC quote. 
                   For reporting purposes. Need not be immediately available so using future method.
    *************************************************/
    public static void updateOverallRatingFactorForPccQuote(String quoteId) {
        try {
            QuotePremiumCalculatorController.RelatedListWrapper calcWrapper = QuotePremiumCalculatorController.fetchRatingModifiers(quoteId);
            Map<String,decimal> prodFactorMap = new Map<String,decimal>();
            decimal stateMax = 0.0, stateMin = 0.0;
            if(calcWrapper != null){
                if(calcWrapper.stateRange != null){
                    if(calcWrapper.stateRange.maxCredit != null){
                        stateMax = 1 + Decimal.valueOf(calcWrapper.stateRange.maxCredit);
                    }
                    if(calcWrapper.stateRange.maxDebit != null){
                        stateMin = 1 - Decimal.valueOf(calcWrapper.stateRange.maxDebit);
                    }
                }
                if(calcWrapper.listRecordDetails != null){
                    for(QuotePremiumCalculatorController.RecordDetails prodCalc : calcWrapper.listRecordDetails){
                        if(prodCalc.productName != null){
                            decimal overallFactorValue = prodCalc.overallRatingModifier;
                            if(overallFactorValue != null){
                                if(overallFactorValue > stateMax){
                                    overallFactorValue = stateMax;
                                }
                                if(overallFactorValue < stateMin){
                                    overallFactorValue = stateMin;
                                }
                            }
                            prodFactorMap.put(prodCalc.productName, overallFactorValue);
                        }
                    }
                }
            }
            if(prodFactorMap.size() > 0){
                List<Quote_Premium__c> qpList = new List<Quote_Premium__c>();
                for(Quote_Premium__c objQP : [Select Id, Overall_Rating_Factor__c, Excess_Premium__c, Quote_Premium__c, Product_Name__c, Quote__c 
                                              from Quote_Premium__c where Quote__c = :quoteId]){
                    if(prodFactorMap.containsKey(objQP.Product_Name__c)){
                        objQP.Overall_Rating_Factor__c = prodFactorMap.get(objQP.Product_Name__c);
                        qpList.add(objQP);
                    }
                }
                update qpList;
            }

           } catch (Exception ex) {
               System.debug(ex.getMessage());
           }
       }

       @future
       public static void updateOverallRatingFactorForPccQuoteAsync(String quoteId){
           updateOverallRatingFactorForPccQuote(quoteId);
       }
   
}