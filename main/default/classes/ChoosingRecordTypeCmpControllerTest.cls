@isTest
private class ChoosingRecordTypeCmpControllerTest {


    static testMethod void testGetRecordTypeValues() {

    	String defaultRecordTypeId = 'Quote';
        Test.startTest();
        ChoosingRecordTypeCmpController obj =   ChoosingRecordTypeCmpController.getRecordTypeValues(defaultRecordTypeId);
        System.assertEquals(true, obj != null);
        Test.stopTest();
    }
}