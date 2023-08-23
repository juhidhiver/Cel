public class CreateOpportunityCmpController{
    
    @AuraEnabled
    public static Map<String,String> GetAvailableRecordType(String objName)
    {
        Map<String,String> recordTypeMap = new Map<String,String>();
              
        for(RecordType rec : [SELECT Id,  Name, DeveloperName, Description FROM RecordType WHERE SobjectType =: objName]) {
            recordTypeMap.put(rec.Name, rec.Id);
           
        }
		system.debug('###recordtype' + recordtypemap);
        return recordTypeMap;
    }   

	
}