public class RecordFormController {

	@AuraEnabled (cacheable=true)
	public static List<ObjectFieldsWrapper> doingSomething(String objectName , List<String> fields){
		List<ObjectFieldsWrapper> wrappers = new List<ObjectFieldsWrapper>();
		for(String f : fields){
			ObjectFieldsWrapper wrapper = new ObjectFieldsWrapper();
			wrapper.label = f;
			wrapper.value = objectName + '.' + f;
			wrappers.add(wrapper);
		}
		System.debug('==Wrapper== ' +wrappers );
		return wrappers;
	}

	public class ObjectFieldsWrapper{
		@AuraEnabled
		public String label { get ; set ; }
		@AuraEnabled
		public String value { get ; set ; }
	}

}