@isTest
public class RecordFormControllerTest {
	@testsetup static void testSetup(){
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
		insert acc;
        }
    
    @isTest
    static void doingSomethingTest(){
        Test.startTest();
        List<string> fields = new List<string>{'Name'};
        Account acc = [Select Id from Account Limit 1];
        ID accId = acc.Id;
        String sObjName = accId.getSObjectType().getDescribe().getName();
        Set<string> fieldNames = schema.getGlobalDescribe().get(sObjName).getDescribe().fields.getMap().keySet();
        List<String> fieldsList = new List<String>(fieldNames);
        RecordFormController.doingSomething(sObjName, fieldsList);
        Test.stopTest();
    }
}