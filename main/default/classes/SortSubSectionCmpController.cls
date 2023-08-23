public class SortSubSectionCmpController {
	@AuraEnabled
    public static List<SortSubSectionInfo> getSortSubSections(String objId){
		Map<String, SortSubSectionInfo> sortMap = new Map<String, SortSubSectionInfo>();
		// String DynamicfieldName = String.isBlank(objId) ?  'Modifier_Product__c': 'Product__c';
		String DynamicfieldName = 'Product__c';
		String DynamicObjName = String.isBlank(objId) ?  'Rating_Modifier_Template__c': 'Rating_Modifiers__c';
		String soql = 'Select Id, Sort_Sub_Section__c, Sub_Section__c, Page_Section__c, '+ DynamicfieldName + 
					' FROM ' + DynamicObjName + 
					' WHERE Sub_Section__c !=null ' +
					(String.isBlank(objId) ?  '': 'AND Opportunity__c =:objId') +
					' ORDER BY ' +
					'Page_Section__c, Sort_Sub_Section__c ASC';
		List<SObject> getList = Database.query(soql);
		System.debug(soql);
		System.debug(getList);
        for (SObject obj : getList)
		{
 			  String key = (String)obj.get(DynamicfieldName) + (String)obj.get('Page_Section__c') +	(String)obj.get('Sub_Section__c');
			  if(!sortMap.containsKey(key)){
					SortSubSectionInfo subobj = new SortSubSectionInfo();
					subobj.Id = key;
					subobj.pageSection = (String)obj.get('Page_Section__c');
					subobj.subSection = (String)obj.get('Sub_Section__c');
					subobj.sortNo = Integer.valueOf(obj.get('Sort_Sub_Section__c'));
					subobj.product = (String)obj.get(DynamicfieldName);
				
					sortMap.put(key, subobj);
			  }
        } 
        return sortMap.values();
    }

	@AuraEnabled
    public static void updateSortSubSections(List<SortSubSectionInfo> odr, String objId ){
		Map<String, Integer> sortMap = new Map<String, Integer>();
		// String DynamicfieldName = String.isBlank(objId) ?  'Modifier_Product__c': 'Product__c';
		String DynamicfieldName = 'Product__c';
		String DynamicObjName = String.isBlank(objId) ?  'Rating_Modifier_Template__c': 'Rating_Modifiers__c';
		for (SortSubSectionInfo obj : odr)
		{
			String key = obj.Id;
         	if(!sortMap.containsKey(key))	sortMap.put(key, obj.sortNo);
	    }

		String soql = 'Select Id, Sort_Sub_Section__c, Sub_Section__c, Page_Section__c, '+ DynamicfieldName +
					' FROM ' + DynamicObjName+ 
					' WHERE Sub_Section__c !=null ' +
					(String.isBlank(objId) ?  '': 'AND Opportunity__c =:objId') ;

		List<SObject> updateList = Database.query(soql);
        for (SObject obj : updateList)
		{	
			String key = (String)obj.get(DynamicfieldName) + (String)obj.get('Page_Section__c') + (String)obj.get('Sub_Section__c');
			if(sortMap.containsKey(key)) obj.put('Sort_Sub_Section__c', sortMap.get(key));
        } 

		if(!updateList.isEmpty()) update updateList;
    }

	public class SortSubSectionInfo {
		@AuraEnabled
		public String Id			{get; set;}
		@AuraEnabled
		public String product		{get; set;}
		@AuraEnabled
		public String pageSection	{get; set;}
		@AuraEnabled
		public String subSection    {get; set;}
		@AuraEnabled
		public Integer sortNo		{get; set;}
	}
	
}