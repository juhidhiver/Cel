public with sharing class ContactNewFormLwcController {
    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getRecordTypePicklist(){
        List<PicklistOption> plOptions = new List<PicklistOption>();
        List<Schema.RecordTypeInfo> recordtypes = Contact.SObjectType.getDescribe().getRecordTypeInfos();
        //recordtypemap = new Map<Id, String>();
        //recordtypemap.put(null, '-None-');
        for(RecordTypeInfo rt : recordtypes){
            if(rt.getName() != 'Master')
                //recordtypemap.put(rt.getRecordTypeId(), rt.getName());
                plOptions.add(new PicklistOption(rt.getRecordTypeId(), rt.getName()));
        }
        return plOptions;
    }
}