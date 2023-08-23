@isTest
private class RelatedListCmpControllerTest {
    @testSetup
    public static void setup() {
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
		setting.BypassQuoteTrigger__c = false;
        setting.BypassCoverageLineItemTrigger__c = false;
        setting.BypassContactTrigger__c = true;
		update setting;

		Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Account acc = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert acc;

        // Create Contact Broker
        Id recordTypeContactAgency = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
		Contact contactBroker = TestUtil.createContact(acc.Id, 'Broker_Contact', 'New broker contact');
		contactBroker.RecordTypeId = recordTypeContactAgency;
		insert contactBroker;

		
    }
    
    
   @isTest
    static void fetchDataTest () {
        Account acc = [SELECT id FROM Account LIMIT 1];
        Contact contact = [SELECT id FROM Contact LIMIT 1];
        String infoJSON = '{"pageNumber":1,"recordToDisplay":10,"objectType":"Contact","parentRecordId":"'+acc.Id+'","recordId":"'+contact.Id+'","fields":"Name,LastName,Type__c","orderBy":"Type__c"}';
    	RelatedListCmpController.fetchData(infoJSON);
    }
    
    @isTest
    public static void testGetDataTable() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        Contact contact = [SELECT id FROM Contact LIMIT 1];
        String infoJSON = '{"pageNumber":1,"recordToDisplay":10,"objectType":"Contact","parentRecordId":"'+acc.Id+'","recordId":"'+contact.Id+'","fields":"","orderBy":"Type__c"}';
    	ResultResponse result = RelatedListCmpController.getDataTable(infoJSON);
        System.assertEquals('Missing some Component attribute. Please contact your administrators.',String.ValueOf(result.errors[0]));
        
        String infoJSONVal = '{"pageNumber":1,"recordToDisplay":10,"objectType":"Contact","parentRecordId":"'+acc.Id+'","recordId":"'+contact.Id+'","fields":"Name,LastName,Type__c","orderBy":"Type__c"}';
        ResultResponse resultVal = RelatedListCmpController.getDataTable(infoJSONVal);
        System.assertEquals(true,resultVal.isSuccess);
        
        String infoJSONExp = '';
        ResultResponse resultNull = RelatedListCmpController.getDataTable(infoJSONExp);
        System.assertEquals('An error occurred while retrieving data. Please contact administrator for more information.',String.ValueOf(resultNull.errors[0]));
    }
    
    @isTest
    public static void testDeleteRecord() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        Contact contact = [SELECT id FROM Contact LIMIT 1];
        String infoJSON = '{"pageNumber":1,"recordToDisplay":10,"objectType":"Contact","parentRecordId":"'+acc.Id+'","recordId":"'+contact.Id+'","fields":"","orderBy":"Type__c"}';
    	RelatedListCmpController.deleteRecord(infoJSON);
        try{
            RelatedListCmpController.ComponentInfo relWrap = new RelatedListCmpController.ComponentInfo();
            
        } catch(Exception ex) {
            
        }
    }
}