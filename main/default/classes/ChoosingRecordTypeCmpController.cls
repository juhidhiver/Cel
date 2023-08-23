public class ChoosingRecordTypeCmpController  {
	@AuraEnabled
    public string defaultRecordTypeId {get; set;}
    @AuraEnabled
    public Map<Id, String> objRecordTypes {get; set;}
     
    @AuraEnabled (cacheable=true)
    public static ChoosingRecordTypeCmpController getRecordTypeValues(String objName){
        ChoosingRecordTypeCmpController obj = new ChoosingRecordTypeCmpController();
        Map<Id, String> recordtypeMap = new Map<Id, String>();
        //Get all record types of SObject
		
  		List<Schema.RecordTypeInfo> recordTypeInfoList = ((SObject)Type.forName(objName).newInstance()).getSObjectType().getDescribe().getRecordTypeInfos();
        for(RecordTypeInfo info: recordTypeInfoList) {
            //Check record type is available for current user profile
            if(info.isAvailable()) {
                //Check master record type
                if(info.getName() != 'Master' && info.getName().trim() != ''){
                    recordtypeMap.put(info.getRecordTypeId(), info.getName());
                }
                //Get the default record type for current user profile
                if(info.isDefaultRecordTypeMapping()){
                    obj.defaultRecordTypeId = info.getRecordTypeId();
                }
            }
        }   
		/**/ 
        obj.objRecordTypes = recordtypeMap;
        System.debug('==RecordTypeList==' + obj);
        return obj;
    }


}