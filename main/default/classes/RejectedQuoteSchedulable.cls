global class RejectedQuoteSchedulable implements Schedulable {
    global void execute(SchedulableContext sc) {
		RejectedQuoteBatch b = new RejectedQuoteBatch();
		database.executebatch(b, 10);
	}
}