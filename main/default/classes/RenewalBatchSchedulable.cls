global class RenewalBatchSchedulable implements Schedulable {
	global void execute(SchedulableContext sc) {
		RenewalBatch b = new RenewalBatch();
		database.executebatch(b, 1);
	}
}