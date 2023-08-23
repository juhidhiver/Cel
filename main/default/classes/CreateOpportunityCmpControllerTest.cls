/**************************************************************************************************
 * Class Name: CreateOpportunityCmpControllerTest
 * Author: Hoang Bui
 * Date: 24-Oct-2019
 * Description: CreateOpportunityCmpControllerTest Test
 **************************************************************************************************/
@isTest
private class CreateOpportunityCmpControllerTest {

    @isTest
    static void TestGetAvailableRecordType() {
        Test.startTest();
        Map<String,String> recordTypeMap = CreateOpportunityCmpController.GetAvailableRecordType('Account');
        Test.stopTest();
        system.assertEquals(false, recordTypeMap.containsKey('Account'));
    }
}