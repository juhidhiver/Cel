/**
 * @File Name          : SubmissionInfoDetailLWCCtrl.cls
 * @Author             : Hang Lam
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Data   : 03/04/2020
**/
public with sharing class SubmissionInfoDetailLWCCtrl {
    public static final String QUOTE_PROCESS_OBJ = 'Quote_Process__c';
    public static final String OPPORTUNITY_OBJ = 'Opportunity';

    /*************************************************
    * Method Name: getListSectionSetting
    * Author: Hang Lam
    * Date: 03/04/2020
    * Params: 
    * Return: TabItem - tab information
    * Exceptions:
    * Revision: 
    *************************************************/
    @AuraEnabled
    public static TabItem getListSectionSetting() {
        TabItem tabItem = new TabItem();
        List<SectionSetting__c> listSectonSetting = [SELECT Id,Name,Main_Section__c,Order__c,
                                            Sub_Section__c,Source_Object__c,Source_Field_Label__c,
                                            Source_Field_API__c,Format__c, Component__c, DisplayType__c,
                                            Lookup_To__c 
                                            FROM SectionSetting__c
                                            WHERE Component__c = 'Submission Info' 
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
		List<Section> sectionOrdered = getSortedKeyset(mainTitleSectionMap, orderSectionSettingMap);
        tabItem.sections = sectionOrdered;
        tabItem.activeSections = getActiveSections(sectionOrdered);
        return tabItem;
    }

    /*************************************************
    * Method Name: getOpp
    * Author: Hang Lam
    * Date: 03/04/2020
    * Params: Opportunity Id, list of fields
    * Return: fieldValueMap
    * Exceptions:
    * Revision: 
    *************************************************/
    @AuraEnabled
    public static Map<String, Object> getOpp(Id oppId, String fieldList) {
        List<String> fields = (List<String>) JSON.deserialize(fieldList, List<String>.class);
        fields.add('Id');
        String condition = 'Id =: oppId';
        List<Opportunity> opps = Database.query(CommonUtil.buildQuery(fields, 'Opportunity', condition));
        Map<String, Object> fieldValueMap = new Map<String, Object>();
        if(!opps.isEmpty()){
            for(String field : fields){
                fieldValueMap.put(field, opps[0].get(field));
            }
        }
        return fieldValueMap;
    }

    /*************************************************
    * Method Name: getSortedKeyset
    * Author: Hang Lam
    * Date: 03/04/2020
    * Params: mainTitleSectionMap, orderSectionSettingMap
    * Return: List Section in order
    * Exceptions: 
    * Revision: 
    *************************************************/
    public static List<Section> getSortedKeyset(Map<String, Section> mainTitleSectionMap, Map<Decimal, SectionSetting__c> orderSectionSettingMap) {
        List<Section> result = new List<Section>();
		List<String> mainTitleOrdered = new List<String>();
        List<Decimal> keySetList = new List<Decimal>();
        keySetList.addAll(orderSectionSettingMap.keySet());
        keySetList.sort();
        for(Decimal key: keySetList){
            mainTitleOrdered.add(orderSectionSettingMap.get(key).Main_Section__c);
        }
		for(String mainTitle : mainTitleOrdered){
			result.add(mainTitleSectionMap.get(mainTitle));
		}
        return result;
    }

    /*************************************************
    * Method Name: convertToListWrapperField
    * Author: Hang Lam
    * Date: 03/04/2020
    * Params: list section setting
    * Return: List WrapperField
    * Exceptions: 
    * Revision: 
    *************************************************/
    private static List<WrapperField> convertToListWrapperField(List<SectionSetting__c> params) {
        List<WrapperField> listWrapperField = new List<WrapperField>();
        for(SectionSetting__c sectionSetting : params) {
            WrapperField a = new WrapperField();
            a.sourceObject = sectionSetting.Source_Object__c;
            a.sourceFieldLabel = sectionSetting.Source_Field_Label__c;
            a.sourceFieldApi = sectionSetting.Source_Field_API__c;
            a.format = sectionSetting.Format__c;
            a.lookupTo = sectionSetting.Lookup_To__c;
            listWrapperField.add(a);
        }
        return listWrapperField;
    }

    /*************************************************
    * Method Name: getActiveSections
    * Author: Hang Lam
    * Date: 03/04/2020
    * Params: list section
    * Return: List active section
    * Exceptions: 
    * Revision: 
    *************************************************/
    public static List<String> getActiveSections(List<Section> sections) {
        List<String> result = new List<String>();
        for (Section section : sections) {
            result.add(section.mainSectionTitle);
        }
        return result;
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

        public WrapperField() {}
    }    
}