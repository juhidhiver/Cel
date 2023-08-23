/**
 * @description       : 
 * @author            : Maeran Shaikh
 * @group             : 
 * @last modified on  : 08-13-2021
 * @last modified by  : Maeran Shaikh
**/
@isTest
public class AccountClearanceCalloutTest {
       public class RatingMockResponse implements HttpCalloutMock {
         public HTTPResponse respond(HTTPRequest req) {
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"submitPackageForAutoClearanceResult":{"result":{"wasCleared":"true","submissionPackageReferenceId":"709327","submissions":{"pwsSubmission":[{"submissionReferenceId":"768990","quoteEffectiveDate":"2020-12-04T00:00:00","feinNumber":"N/A","submissionPackageReferenceId":"709327","quotedInsured":{"legalName":null,"taxId":"N/A","name":"CAPGEMINI INC."},"quotedRiskLocation":{"zipCode":"30088","state":"GA","city":"STONE MOUNTAIN","streetAddress":"5353 KEMPER PL"},"lineOfBusiness":{"code":"I","name":"Errors and Omissions"},"submissionClearance":{"clearanceDate":"2020-12-03T00:00:00","comments":"","wasCleared":"true"}}]}},"errors":{"domainError":[]},"succeded":"true"},"xmlns":"http://riskclearance.munichreamerica.biz/"}');
        res.setStatusCode(200);
        return res;
    	}
    }
      
	@isTest
    public static void sendSubmissionDetailsTest(){
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account acc = TestUtil.createAccount('Account Test', recordTypeId, '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        Product2 prod = TestUtil.createProduct('MPL Standalone');
        prod.Model_ID__c = 'Celerity_MPL';
        prod.IsActive = True;
        insert prod;
        
        RatingMockResponse mock = new RatingMockResponse();
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        String result = AccountClearanceCallout.sendSubmissionDetails(acc.Id, prod.Id);
        System.assertEquals('Cleared', result);
        Test.stopTest();
               
    }

    @isTest
    public static void testGetClearanceDetailsForPCC(){

        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account acc = TestUtil.createAccount('Test PCC0289', recordTypeId, '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        Product2 prod = TestUtil.createProduct('Private Company Combo');
        
        prod.IsActive = True;
        prod.Model_ID__c = 'Celerity_PCC';
        insert prod;

        Product2 prodChild = TestUtil.createProduct('D&O');
        prodChild.Munich_LOB_Code__c = 'G';
        prodChild.IsActive = True;
        prodChild.Parent_Product__c = prod.Id;
        insert prodChild;

        Opportunity opp = TestUtil.createOpportunity('Test Opportunity', acc.Id, prod.Id);
        opp.StageName = 'New';
        insert opp;

        ComboProductSelectionLwcController.ItemWrapper testIT= new  ComboProductSelectionLwcController.ItemWrapper();
        String datStr = '2021-08-01';
        Date dt = Date.ValueOf(datStr);
        testIT.ProductId = prodChild.Id;
        testIT.SubmissionId =opp.Id;
        testIT.AccountId = acc.Id;
        testIT.Status ='Cleared';
        testIT.Name =prodChild.Name ;
        testIT.Notes ='';
        testIT.DisableCheckBox = false;
        testIT.ManualClearance = false;
        testIT.Selected = true;
        testIT.submissionAzureId = opp.Azure_ID__c;
        testIT.modelId = prod.Model_ID__c ;
        testIT.accountName =acc.Name;
        testIT.quoteEffectiveDate = dt;
        testIT.coverages =new List<String>{prodChild.Munich_LOB_Code__c};
        ComboProductSelectionLwcController.QuotedRiskLocation testqr = new ComboProductSelectionLwcController.QuotedRiskLocation ();
        testqr.City = 'Whiteriver';
        testqr.State='AZ';
        testqr.StreetAddress ='AZ-77';
        testqr.ZipCode ='85941';
        testIT.locationDetails = testqr;
        RatingMockResponse mock = new RatingMockResponse();
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        AccountClearanceCallout.ResponseWrapper testStr = AccountClearanceCallout.getClearanceDetailsForPCC(testIT);
        Test.stopTest();
        System.debug('TestSte --> '+ testStr);
        System.assertEquals(true, testStr != null);
    }
}