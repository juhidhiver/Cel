public without sharing  class CustomLookupControllerLWC {
	public CustomLookupControllerLWC() {

	}
	@AuraEnabled (cacheable=true)
	public static List<SObject> findRecords(String searchKey, String objectName, String searchField){
		if(String.isBlank(searchKey)) return null;
		System.debug('Search Key : ' + searchKey+ 'Object Name : ' + objectName+'Search Field : ' + searchField);
		String key ='\'' + searchKey +  '%'  +'\'' ;
		System.debug('==key== ' + key);
		String QUERY = 'Select Id, '+searchField+' From '+objectName +' Where '+searchField +' LIKE ' + key;
		System.debug(System.LoggingLevel.DEBUG, QUERY);
		List<SObject> sObjectList = Database.query(QUERY);
		System.debug('===ListObject '+  sObjectList);

		return sObjectList;
	}
	
}