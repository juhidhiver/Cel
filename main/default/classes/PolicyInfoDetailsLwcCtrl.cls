/**
 * @File Name          : PolicyInfoDetailsLwcCtrl.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 6/1/2020, 3:33:35 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/1/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public with sharing class PolicyInfoDetailsLwcCtrl {
	//public static final String ENDORSEMENT_PROCESS_OBJ = 'Endorsement_Process__c';
    public static final String OPPORTUNITY_OBJ = 'Opportunity';

	///* long ly 01/06/2020 - delete
	/*
	@AuraEnabled
	public static string getPolicyRecordId(String endorsementProcessid){
		System.debug('@@@Policy Id' + endorsementProcessid);
		if(String.isBlank(endorsementProcessid)) return null;
		return [select Id,Policy__c from Endorsement_Process__c where Id = :endorsementProcessid limit 1].Policy__c;
	}*/

	//Find RecordIds sObject
	@AuraEnabled
    public static String getRecordInfos(String sObjectId) {
		Id recordId;
		if(String.isNotBlank(sObjectId)){
			recordId = sObjectId;
		}
		String sObjName = recordId.getSObjectType().getDescribe().getName();
		/* long ly 01/06/2020 - delete
        if(sObjName == ENDORSEMENT_PROCESS_OBJ) {
            return [SELECT Id, Policy__c FROM Endorsement_Process__c WHERE Id = :sObjectId limit 1].Policy__c;
        }*/
        if(sObjName == OPPORTUNITY_OBJ) {
            List<Opportunity> listOpp = [SELECT Id, Policy__c FROM Opportunity WHERE Id = :sObjectId];
            return listOpp[0].Policy__c;
        }
        return null;
	}	

	@AuraEnabled
	public static TabItem getListSectionSetting() {
		TabItem tabItem = new TabItem();
		List<SectionSetting__c> listSectonSetting = [SELECT Id,Name,Main_Section__c,Order__c,
		Sub_Section__c,Source_Object__c,Source_Field_Label__c,
		Source_Field_API__c,Format__c, Component__c, DisplayType__c
		FROM SectionSetting__c
		WHERE Component__c = 'Policy Info'
		ORDER BY Order__c ASC];
		Map<Decimal, SectionSetting__c> orderSectionSettingMap = new Map<Decimal, SectionSetting__c>();
		Map<String,List<SectionSetting__c>> mapParentNoSub = new Map<String,List<SectionSetting__c>>();
		Map<String,List<SectionSetting__c>> mapParentWithSub = new Map<String,List<SectionSetting__c>>();
		Map<String,List<SectionSetting__c>> mapParentChildSub = new Map<String,List<SectionSetting__c>>();
		for(SectionSetting__c sectionSetting : listSectonSetting) {
			if(String.isBlank(sectionSetting.Source_Object__c) && String.isBlank(sectionSetting.Sub_Section__c)){
				orderSectionSettingMap.put(sectionSetting.Order__c, sectionSetting);
			}else{
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

	private static List<WrapperField> convertToListWrapperField(List<SectionSetting__c> params) {
		List<WrapperField> listWrapperField = new List<WrapperField>();
		for(SectionSetting__c sectionSetting : params) {
			WrapperField a = new WrapperField();
			a.sourceObject = sectionSetting.Source_Object__c;
			a.sourceFieldLabel = sectionSetting.Source_Field_Label__c;
			a.sourceFieldApi = sectionSetting.Source_Field_API__c;
			a.format = sectionSetting.Format__c;
			listWrapperField.add(a);
		}
		return listWrapperField;
	}

	public static List<String> getActiveSections(List<Section> sections) {
		List<String> result = new List<String>();
		for (Section section : sections) {
			result.add(section.mainSectionTitle);
		}
		return result;
	}

	@AuraEnabled
    public static Map<String, Object> getPol(String policyId, String fieldList) {
        
        List<String> fields = (List<String>) JSON.deserialize(fieldList, List<String>.class);
        String condition = 'Id =: policyId';
        List<Policy__c> poli = Database.query(CommonUtil.buildQuery(fields, 'Policy__c', condition));
        Map<String, Object> fieldValueMap = new Map<String, Object>();
        if(!poli.isEmpty()){
            for(String field : fields){
                fieldValueMap.put(field, poli[0].get(field));
            }
        }
        System.debug('@@@fieldValueMap: ' + fieldValueMap);
        return fieldValueMap;
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

		public WrapperField() {}
	}
}