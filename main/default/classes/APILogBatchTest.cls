@isTest
public class APILogBatchTest {
@isTest
static void insertAPILogTest(){
    API_Log__c apiLog = new API_Log__c();
apiLog.Name = 'Test';
apiLog.Business_Name__c = 'Leopanthera';
apiLog.Status__c = 'Success';
apilog.Functionality__c = 'Rating';
insert apilog;
Datetime yesterday = Datetime.now().addDays(-22);
Test.setCreatedDate(apilog.Id, yesterday);
test.startTest();

String myJSON = JSON.serialize(apilog);
// APILogBatch.insertAPILog(myJSON);
APILogBatchSchedulable a = new APILogBatchSchedulable();
a.execute(null);
test.stopTest();
}
//ScheduleTerritoryInactiveMemberCheck sh1 = new ScheduleTerritoryInactiveMemberCheck();//String sch = '0 0 23 * * ?'; system.schedule('Test Territory Check', sch, sh1); Test.stopTest();
}