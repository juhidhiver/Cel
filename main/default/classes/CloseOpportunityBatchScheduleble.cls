global class CloseOpportunityBatchScheduleble implements Schedulable {
    global void execute(SchedulableContext sc) {
        CloseOpportunityBatch b = new CloseOpportunityBatch();
        database.executebatch(b);
    }
}