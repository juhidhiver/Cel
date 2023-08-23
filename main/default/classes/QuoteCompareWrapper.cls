public with sharing class QuoteCompareWrapper {
	@AuraEnabled public String quoteName 				{ get; set; }
	@AuraEnabled public String status 					{ get; set; }
	@AuraEnabled public String version 					{ get; set; }
	@AuraEnabled public String aggregateLimit 			{ get; set; }
	@AuraEnabled public String retention 				{ get; set; }
	@AuraEnabled public String sublimitsAndEndorsements { get; set; }
	@AuraEnabled public String supplementaryPayments 	{ get; set; }
	@AuraEnabled public String retro 					{ get; set; }
	@AuraEnabled public String ratingAdjustments 		{ get; set; }
	@AuraEnabled public String yearInBussiness 			{ get; set; }


}