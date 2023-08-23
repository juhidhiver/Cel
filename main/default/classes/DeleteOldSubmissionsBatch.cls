/**************************************************************************************************
 * Class Name: DeleteOldSubmissionsBatch
 * Author: Phuong LA
 * Date: 19-Aug-2020
 * Description: Batch Program to delete old Submissions and all related Quotes
 **************************************************************************************************/
global class DeleteOldSubmissionsBatch implements Database.Batchable<sObject> {
    private static Integer numberOfDays = 0;

    public DeleteOldSubmissionsBatch(Integer days) {
        numberOfDays = days;
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('numberOfDays: ' + numberOfDays);
        Date createdDate = Date.today().addDays(-numberOfDays);
        Integer d = createdDate.day();
        Integer mo = createdDate.month();
        Integer yr = createdDate.year();

        DateTime createdDateDT = DateTime.newInstance(yr, mo, d);
        System.debug('createdDateDT: ' + createdDateDT);

        String strQuery = 'SELECT Id, createdDate FROM Opportunity WHERE createdDate <=: createdDateDT';
        System.debug('Database.getQueryLocator(strQuery): ' + Database.getQueryLocator(strQuery));
        return Database.getQueryLocator(strQuery);
    }
    global void execute(Database.BatchableContext BC, List<Opportunity> opportunityList) {
        System.debug('===== excute =====');
        if(!opportunityList.isEmpty()) {
            delete opportunityList;
        }
    }
    global void finish(Database.BatchableContext BC) {

    }
}