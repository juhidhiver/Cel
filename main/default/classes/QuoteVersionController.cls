public class QuoteVersionController {

	@AuraEnabled
	public static ResultResponse insertNewVersion( String param1, String param2 ){
		System.debug('param1' + param1);
		QuoteCompareItemWrapper items
				= (QuoteCompareItemWrapper)JSON.deserialize(param1, QuoteCompareItemWrapper.class);
		ResultResponse result = new ResultResponse();
		System.debug('Items' + items);
		 /*
		//QuoteCompareItemWrapper newUpdateItem1 = (QuoteCompareItemWrapper)JSON.deserialize(param1,QuoteCompareItemWrapper.class);
		//QuoteComparisonLWC.QuoteComparisonWrapper quoteCompareWrapper1 = (QuoteComparisonLWC.QuoteComparisonWrapper)JSON.deserialize(param2,QuoteComparisonLWC.QuoteComparisonWrapper.class );
		String quoteId = newUpdateItem1.quoteId;
		QuoteCompareItemWrapper oldItem = new QuoteCompareItemWrapper();
		for(QuoteCompareItemWrapper item : quoteCompareWrapper1.quoteCompareItems){
			if(item.quoteId == quoteId ) oldItem = item;
		}
		List<QuoteCompareItemField> fieldsChanged = new List<QuoteCompareItemField>();
		Map<String,QuoteCompareItemField> mapFields = new Map<String,QuoteCompareItemField>();
		for(QuoteCompareItemField field : oldItem.quoteFields){
			mapFields.put(field.fieldId,field);
		}
		for(QuoteCompareItemField field : newUpdateItem1.quoteFields){
			if(field.value != mapFields.get(field.fieldId).value){
				fieldsChanged.add(field);
			}
		}
		Quote_Version__c newQuoteVersion = new Quote_Version__c();
		newQuoteVersion.Quote__c = quoteId;
		List<Quote_Version_Item__c> items = new List<Quote_Version_Item__c>();
		for(QuoteCompareItemField f : fieldsChanged){
			Quote_Version_Item__c item = new Quote_Version_Item__c();
			item.Quote_Version__c = newQuoteVersion.Id;
			item.Label__c = f.fieldName;
			item.Object_Id__c = f.sourceObject;
			item.Value__c = f.value;
			item.Source_Field_API__c = f.sourceFieldAPI;
			item.Operation__c = 'Update';
			items.add(item);
		}
		if(!checkExistVersion(items,quoteId)){
			insert newQuoteVersion;
			insert items;
		} */

		return result;

	}


	public static Boolean checkExistVersion(List<Quote_Version_Item__c> itemsCheck,String quoteId){

		Map<String,Map<String,String>> versionItemsMaps = new Map<String, Map<String,String>>();
		for(Quote_Version_Item__c item : [select Id,Quote_Version__c,Source_Object__c,Source_Field_API__c,Value__c,Label__c,Name from Quote_Version_Item__c where Quote_Version__r.Quote__c = :quoteId]){
			String key = item.Source_Object__c+';'+item.Source_Field_API__c + item.Value__c + '';
			if(!versionItemsMaps.containsKey(item.Quote_Version__c)){
				versionItemsMaps.put(item.Quote_Version__c, new Map<String, String>());
				versionItemsMaps.get(item.Quote_Version__c).put(key,item.Value__c);
			}else{
				versionItemsMaps.get(item.Quote_Version__c).put(key,item.Value__c);
			}
		}
		for(String key: versionItemsMaps.keySet()){
			Map<String,String> existItem =  versionItemsMaps.get(key);
			Boolean isExist = false;
			if(itemsCheck.size() != versionItemsMaps.size()) continue;
			for(Quote_Version_Item__c item : itemsCheck){
				String keyCheck = item.Source_Object__c+';'+item.Source_Field_API__c + item.Value__c + '';
				if(existItem.containsKey(keyCheck)){
					isExist = (existItem.get(key) == item.Value__c)? true : false;
				}else{
					isExist = false;
				}
			}
			if(isExist = true) return true;
		}

		return false;
	}


	@AuraEnabled
	public static List<QuoteVersionWrapper> getListQuoteVersions(String quoteId){
		List<QuoteVersionWrapper> result  = new List<QuoteVersionWrapper>();
		List<Quote_Version_Item__c> items = [select Quote_Version__r.CreatedDate,Quote_Version__c,Quote_Version__r.Quote__r.Total_Premium__c,Quote_Version__r.Quote__r.Name,Quote_Version__r.Name,Id,Old_Value__c,Value__c,
													Source_Object__c,Source_Field_API__c,Name,Operation__c,Object_Id__c,LastModifiedDate
												from Quote_Version_Item__c
												where Quote_Version__r.Quote__c = :quoteId order by Quote_Version__r.CreatedDate];
		if(items.isEmpty()) return result;
		Map<String,List<QuoteVersionItemWrapper>> mapFieldsChanged = new Map<String, List<QuoteVersionController.QuoteVersionItemWrapper>>();
		System.debug('==Items==' + items);
		for(Quote_Version_Item__c item : items){
			QuoteVersionItemWrapper wrapper = new QuoteVersionItemWrapper();
			wrapper.quoteVersionName =  item.Quote_Version__r.Quote__r.Name + ' ' + item.Quote_Version__r.Name ;
			wrapper.fieldChangedName = item.Source_Field_API__c.replace('__c',' ').replace('_',' ');
			wrapper.valueChanged = item.Value__c + '';
			wrapper.versionId = item.Value__c + item.Quote_Version__c;
			wrapper.totalPremium = item.Quote_Version__r.Quote__r.Total_Premium__c + '';
			wrapper.dateChanged = item.LastModifiedDate + '';
			wrapper.quoteVersionCreatedDate = item.Quote_Version__r.CreatedDate + '';
			if(!mapFieldsChanged.containsKey(item.Quote_Version__c)){
				mapFieldsChanged.put(item.Quote_Version__c, new List<QuoteVersionItemWrapper>{wrapper});
			}else{
				mapFieldsChanged.get(item.Quote_Version__c).add(wrapper);
			}
		}
		for(String key : mapFieldsChanged.keySet()){
			QuoteVersionWrapper item = new QuoteVersionWrapper();
			item.versionId = key;
			item.version =  mapFieldsChanged.get(key)[0].quoteVersionName + ''; //modify later
			item.createdDate =  mapFieldsChanged.get(key)[0].quoteVersionCreatedDate + ''; //modify later
			item.fieldsChanged = mapFieldsChanged.get(key);
			result.add(item);
		}
		return result;
	}

	public class QuoteVersionWrapper {
		@AuraEnabled public List<QuoteVersionItemWrapper> fieldsChanged {get;set;}
		@AuraEnabled public String version { get; set; }
		@AuraEnabled public String versionId { get; set; }
		@AuraEnabled public String createdDate { get; set; }
	}

	public class QuoteVersionItemWrapper {

		@AuraEnabled public String fieldChangedName { get; set; }
		@AuraEnabled public String valueChanged { get; set; }
		@AuraEnabled public String versionId { get; set; }
		@AuraEnabled public String totalPremium { get; set; }
		@AuraEnabled public String dateChanged { get; set; }
		@AuraEnabled public String quoteVersionName { get; set; }
		@AuraEnabled public String quoteVersionCreatedDate { get; set; }

		public QuoteVersionItemWrapper(){}
		public QuoteVersionItemWrapper(String fieldName, String value, String versionName, String totalPremium, String dateChanged,String createdDate){
			this.fieldChangedName = fieldName;
			this.valueChanged = value;
			this.quoteVersionName = versionName;
			this.totalPremium = totalPremium;
			this.dateChanged = dateChanged;
			this.quoteVersionCreatedDate = createdDate;
		}
	}
}