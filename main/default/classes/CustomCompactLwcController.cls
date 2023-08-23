/**
 * @File Name          : CustomCompactLwcController.cls
 * @Description        :
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              :
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 3/25/2020, 8:35:29 PM
 * @Modification Log   :
 * Ver       Date            Author                  Modification
 * 1.0    3/24/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
 **/
public with sharing class CustomCompactLwcController{
	public class CompactWrapper{
		@AuraEnabled
		public string fieldNameAPI{
			get;

			set;
		}

		@AuraEnabled
		public string fieldName{
			get;

			set;
		}

		@AuraEnabled
		public Object fieldValue{
			get;

			set;
		}

		@AuraEnabled
		public string fieldType{
			get;

			set;
		}

		public CompactWrapper(){
			fieldName = '';
			fieldValue = null;
			fieldType = Schema.DisplayType.ANYTYPE.name();
		}
	}

	@AuraEnabled
	public static ResultResponse getCompactLayoutFields(String objectId){
		ResultResponse response = new ResultResponse();
		try{
			System.debug('@@@start1');
			// String restUrl = 'callout:ApexMDAPI/services/data/v39.0/limits';
			// Http h = new Http();
			// HttpRequest req = new HttpRequest();
			// req.setEndpoint(restUrl);
			// req.setMethod('GET');
			// HttpResponse res = h.send(req);
			//Get object API Name
			Id objectId1 = Id.valueOf(objectId);
			Schema.SObjectType objectAPI = objectId1.getsobjecttype();
			Schema.DescribeSObjectResult r = objectAPI.getDescribe();
			String objectAPIName = r.getName();
			System.debug('objectAPIName ' + objectAPIName);
			//Get recordType API Name
			//recordtypeid
			List<String> fields = new List<String>();
			fields.add('Recordtype.DeveloperName');
			String condition = 'Id =: objectId';
			List<SObject> sObjects = Database.query(CommonUtil.buildQuery(fields, objectAPIName, condition));
			System.debug('@@@sObjects: ' + sObjects);
			String recordTypeId = (String)sObjects[0].get('RecordtypeId');
			//recordtypeAPIName
			List<String> fields2 = new List<String>();
			fields2.add('DeveloperName');
			String condition2 = 'Id =: recordTypeId';
			List<SObject> sObjects2 = Database.query(CommonUtil.buildQuery(fields2, 'RecordType', condition2));
			System.debug('@@@sObjects2: ' + sObjects2);
			String recordTypeAPIName = (String)sObjects2[0].get('DeveloperName');
			System.debug('recordTypeAPIName: ' + recordTypeAPIName);
			//Get compact layout API Name by recordTypeAPIName
			MetadataService.MetadataPort service = MetadataUtil.createService2();
			System.debug('@@@service: ' + service);
			String metadataName = objectAPIName + '.' + recordTypeAPIName;
			MetadataService.RecordType recordType = (MetadataService.RecordType)service.readMetadata('RecordType', new String[]{metadataName}).getRecords()[0];
			System.debug('recordType='+recordType);
			String compactLayoutAPIName = recordType.compactLayoutAssignment;
			System.debug('@@@recordType compactLayoutAPIName: ' + compactLayoutAPIName);
			//
			//MetadataService.MetadataPort service = MetadataUtil.createService1();
			//System.debug('@@@service: ' + service);
			String metadataName2 = objectAPIName + '.' + compactLayoutAPIName;
			MetadataService.CompactLayout compactLayout = (MetadataService.CompactLayout)service.readMetadata('CompactLayout', new String[]{metadataName2}).getRecords()[0];
			System.debug(compactLayout);
			System.debug('@@@compactLayout fields: ' + compactLayout.fields);
			System.debug('@@@compactLayout fieldstypeinfo: ' + compactLayout.fields_type_info);
			System.debug('@@@compactLayout fieldordertypeinfo: ' + compactLayout.field_order_type_info);
			List<String> fieldList = compactLayout.fields;
			String condition3 = 'Id =: objectId1';
			List<SObject> sObjects3 = Database.query(CommonUtil.buildQuery(fieldList, objectAPIName, condition3));
			// List<String> fieldValueList = new List<String>();
			Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
			Schema.SObjectType leadSchema = schemaMap.get(objectAPIName);
			Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
			List<CompactWrapper> fieldObjList = new List<CompactWrapper>();
			if (!sObjects3.isEmpty()){
				//response.data = sObjects3[0];
				for (String field : fieldList){
					// fieldValueList.add(String.valueOf(sObjects3[0].get(field)));
					CompactWrapper item = new CompactWrapper();
					item.fieldNameAPI = field;
					item.fieldName = fieldMap.get(field).getDescribe().getLabel();
					item.fieldValue = sObjects3[0].get(field);
					item.fieldType = fieldMap.get(field).getDescribe().getType().name();
					fieldObjList.add(item);
				}
			}
			// System.debug('@@@fieldValueList: ' + fieldValueList);
			System.debug('@@@fieldObjList: ' + fieldObjList);
			response.data = fieldObjList;
			response.isSuccess = true;
		} catch (Exception ex){
			System.debug('Exception: ' + ex.getMessage());
			response.errors.add(CommonUtil.getExceptionMessage(ex));
		}
		return response;
	}

	@AuraEnabled
	public static String getCompactTitle(Id objectId){
		//Get object API Name
		Schema.SObjectType objectAPI = objectId.getsobjecttype();
		Schema.DescribeSObjectResult r = objectAPI.getDescribe();
		String objectLabel = r.getName() + ' Info';
		return objectLabel.toUpperCase();
	}

	@AuraEnabled
	public static String getCompactObjectName(Id objectId){
		Schema.SObjectType objectAPI = objectId.getsobjecttype();
		Schema.DescribeSObjectResult r = objectAPI.getDescribe();
		String objectAPIName = r.getName();
		return objectAPIName;
	}
	@AuraEnabled
    public static string getOpportunityRecordType(String opportunityId) {
        String recordTypeId = [SELECT Id,RecordTypeId FROM Opportunity WHERE Id  = :opportunityId Limit 1].RecordTypeId;
        RecordType recordType = [select Id,Name from RecordType where SobjectType='Opportunity' And Id =: recordTypeId];
        return recordType.Id + '__' + recordType.Name;
    }
        
    @AuraEnabled (cacheable=true)
  public static string getDefaultRecordType(String quoteProcessId) {	
        String recordTypeName = '';	
        if(Id.valueOf(quoteProcessId).getSObjectType().getDescribe().getName() == 'Quote_Process__c'){	
            Quote_Process__c qp = [SELECT Id,Submission__c, Record_Type__c FROM Quote_Process__c WHERE Id =:quoteProcessId Limit 1];	
            if(String.isNotBlank(qp.Record_Type__c))	
                recordTypeName = qp.Record_Type__c;	
            else	
                recordTypeName = [SELECT Id,Innovisk_Entity_ID__c FROM Opportunity WHERE Id =:qp.Submission__c Limit 1].Innovisk_Entity_ID__c;	
        }   	
        return recordTypeName;	
    }	
}