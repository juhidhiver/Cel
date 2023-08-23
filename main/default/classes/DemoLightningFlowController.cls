public class DemoLightningFlowController {

	@InvocableMethod(label='Create Opportunity ' description='Return Opportunity Created' category='Opportunity')
	public static List<Opportunity> createOpportunity(List<Opportunity> ids) {
		System.debug('Opportunity' + ids);
		List<Account> accs  = [select Id,Name from Account where id = :ids[0].AccountId];
		List<Product2> products  = [select Id,Name from Product2 where id = :ids[0].Product__c];
		ids[0].CloseDate = Date.today() +30;
		ids[0].StageName = 'New';
		ids[0].Name =  products[0].Name + 	accs[0].Name + 'Submission ';

		insert ids[0];
		return ids;
	}

}