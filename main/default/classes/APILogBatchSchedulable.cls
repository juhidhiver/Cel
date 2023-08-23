/**************************************************************************************************
 * Class Name: APILogBatchSchedulable
 * Author: 
 * Date: 25-May-2022
 * Description: API Log Batch Schedulable
 **************************************************************************************************/
global class APILogBatchSchedulable implements Schedulable {
    global void execute(SchedulableContext sc) {
		APILogBatch b = new APILogBatch('API_Log__c');
		database.executebatch(b);         
    }
}