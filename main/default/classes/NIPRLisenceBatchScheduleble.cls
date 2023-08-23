/**************************************************************************************************
 * Class Name: NIPRLisenceBatchScheduleble
 * Author: Giang PHAN
 * Date: 14-Nov-2019
 * Description: Schedule Batch Program run to NIPRLisenceBatch.
 **************************************************************************************************/
global class NIPRLisenceBatchScheduleble implements Schedulable {
    global void execute(SchedulableContext sc) {
        NIPRLisenceBatch b = new NIPRLisenceBatch();
        database.executebatch(b,1);
    }
}