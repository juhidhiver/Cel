/**************************************************************************************************
 * Class Name: NIPRAccountBatchSchedule
 * Author: Giang PHAN
 * Date: 14-Nov-2019
 * Description: Schedule Batch Program run to NIPRAccountBatch.
 **************************************************************************************************/
global class NIPRAccountBatchSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        NIPRAccountBatch b = new NIPRAccountBatch();
        database.executebatch(b,1);
    }
}