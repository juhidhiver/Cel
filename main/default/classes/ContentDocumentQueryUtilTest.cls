/**************************************************************************************************
 * Class Name: ContentDocumentQueryUtilTest
 * Author: Vinay V
 * Date: Dec 28th, 2021
 * Description: Test class for ContentDocumentQueryUtil
 **************************************************************************************************/
@isTest
public class ContentDocumentQueryUtilTest {
    @testsetup
	static void testSetup(){

		TriggerSettings__c setting = new TriggerSettings__c();
		setting.BypassContentDocumentLinkTrigger__c = true;
		insert setting;
		System.assert(setting != null);

		Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
		Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio', '43623', 'United States');
		insert accBroker;

		// create product
		Product2 product = TestUtil.createProduct('MPL Standalone');
		insert product;

		// create opportunity
		Opportunity opp = TestUtil.createOpportunity('Test Opportunity', accBroker.Id, product.Id);
		opp.StageName = 'Qualified';
		insert opp;

		Coverage__c cov1 = new Coverage__c(Name = 'Coverage Name', Form_Number__c = 'ACMP 27 03 08 04', Coverage_Product__c = 'MPL', Coverage_Type__c = 'Endorsement');
		insert cov1;

		ContentVersion contentVersion = new ContentVersion(
			Title = 'ACMP 27 03 Coverage Name', 
			PathOnClient = 'ACMP 27 03 Coverage Name', 
			VersionData = Blob.valueOf('ACMP 27 03 Coverage Name')
		);
		insert contentVersion;
	}

    public static testmethod void test_fetchContentDocumentsByIDs(){
        Set<Id> documentIds = new Set<Id>();
        for(ContentDocument cd : [Select id from ContentDocument]){
            documentIds.add(cd.Id);
        }
        Test.startTest();
        List<ContentDocument> documents = ContentDocumentQueryUtil.fetchContentDocumentsByIDs(documentIds);
        system.assert(documents.size() > 0);
        Test.stopTest();
    }
}