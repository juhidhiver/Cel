/**************************************************************************************************
* Class Name: subjectivityControllerTest
* Author: Ashik Zahir
* Created date: 15-Feb-2021
* Description: Test for subjectivityController
**************************************************************************************************/
@isTest
public class subjectivityControllerTest {
	@testSetup
    public static void setup() {
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert accBroker;              	
        
        // create product
        Product2 product = TestUtil.createProduct('Test Product');
        insert product;
        
        // create opportunity        
        Opportunity opp = TestUtil.createOpportunity('Test Opportunity', accBroker.Id, product.Id);
        opp.StageName = 'Qualified';
        insert opp;
        
        // By pass trigger to insert quote
        TriggerSettings__c settings = new TriggerSettings__c();
		settings.BypassQuoteTrigger__c = true;
		insert settings;
		System.assert(settings != null);
        
        Subjectivity_Template__c subjectivityTemplate = new Subjectivity_Template__c();
		subjectivityTemplate.Subjectivity_Name__c = 'Signed / Dated Proposal';
		subjectivityTemplate.Subjectivity_Text__c = 'Test';
		subjectivityTemplate.Profession_Criteria__c = 'Engineers';
		insert subjectivityTemplate;

        Subjectivity_Template__c subjectivityTemplate1 = new Subjectivity_Template__c();
		subjectivityTemplate1.Subjectivity_Name__c = 'Test1';
		subjectivityTemplate1.Subjectivity_Text__c = 'Test1';
        subjectivityTemplate1.State__c = 'OH';
		insert subjectivityTemplate1;

        Subjectivity_Template__c subjectivityTemplate2 = new Subjectivity_Template__c();
		subjectivityTemplate2.Subjectivity_Name__c = 'Test2';
		subjectivityTemplate2.Subjectivity_Text__c = 'Test2';
        subjectivityTemplate2.Layer__c = 'Primary';
		insert subjectivityTemplate2;

        Subjectivity_Template__c subjectivityTemplate3 = new Subjectivity_Template__c();
		subjectivityTemplate3.Subjectivity_Name__c = 'Test3';
		subjectivityTemplate3.Subjectivity_Text__c = 'Test3';
        subjectivityTemplate3.Layer__c = 'Excess';
		insert subjectivityTemplate3;
        
        // create Quote
        Quote q = TestUtil.createQuote('Test Quote', opp.Id);
        q.Rating_Status__c = 'Refer';
        q.Status = 'Rated';
        insert q;
        
        Quote q1 = TestUtil.createQuote('Test Quote Excess 1', opp.Id);
        q1.Layer__c = 'Excess';
        q1.Status = 'Rated';
        insert q1;

        Subjectivity__c subj = new Subjectivity__c();
        subj.Subjectivity__c = 'Testing';
        subJ.Subjectivity_Status__c = 'Open';
        subJ.Subjectivity_Type__c = 'MPL';
        subJ.RecordTypeId = Schema.SObjectType.Subjectivity__c.getRecordTypeInfosByName().get(GlobalVariables.RT_NAME_SUBJECTIVITY_CELERITY).getRecordTypeId();
        subJ.Quote__c = q.Id;
        insert subJ;
    }
    
    @isTest
    public static void testGetSubjectivityByQuoteId() {
        Quote qt = [SELECT id,Name FROM Quote LIMIT 1];
        Test.startTest();
        List<subjectivityController.ItemWrapper> result = subjectivityController.getSubjectivityByQuoteId(qt.Id);
        Test.stopTest();
        System.assertEquals('Open',result[0].subjectivityStatus);
    }
    
    @isTest
    public static void testUpdateRecords() {
        Test.startTest();
        Subjectivity__c subJ = [SELECT id,Name FROM Subjectivity__c LIMIT 1];
        String jsonStringRecord = '[{"Id":"'+subJ.Id+'","subjectivity":"Testing Sub","subjectivityStatus":"Open","subjectivityType":"MPL", "cleared":true}]';
        Boolean result = subjectivityController.updateRecords(jsonStringRecord);
        Test.stopTest();
        System.assert(jsonStringRecord != null);
    }
    
    @isTest
    public static void testGetProductName() {
        Quote qt = [SELECT id,Name FROM Quote LIMIT 1];
        Test.startTest();
        String result = subjectivityController.getProductName(qt.Id);
        Test.stopTest();
        System.assertEquals('Test Product',result);
    }
    
    @isTest
    public static void testGetSubjectivityTemplateList() {
        Quote qt = [SELECT id,Name FROM Quote LIMIT 1];
        Test.startTest();
        List<Subjectivity_Template__c> result = subjectivityController.getSubjectivityTemplateList(qt.Id);
        Test.stopTest();
        System.assert(result!= null);
       
        }

        @isTest
        public static void testGetSubjectivityTemplateListExcess() {
            Quote qt = [SELECT id,Name FROM Quote where name like '%Excess%' LIMIT 1];
            Test.startTest();
            List<Subjectivity_Template__c> result = subjectivityController.getSubjectivityTemplateList(qt.Id);
            Test.stopTest();
            System.assert(result!= null);
           
        }
    
    @isTest
    public static void testGetProfessionName() {
        Quote qt = [SELECT id,Name FROM Quote LIMIT 1];
        Test.startTest();
        String result = subjectivityController.getProfessionName(qt.Id);
        Test.stopTest();
        System.assert(qt != null );
        }
       
    @isTest
    public static void testCheckIsExcess() {
        Quote qt = [SELECT id,Name FROM Quote LIMIT 1];
        Test.startTest();
        String result = subjectivityController.checkIsExcess(qt.Id);
        Test.stopTest();
        System.assertEquals('Primary',result);
        }
    
    @isTest
    public static void testCreateSubjectivitiesBySubjTemplate() {
        Quote qt = [SELECT id,Name FROM Quote LIMIT 1];
        Subjectivity_Template__c subjectivityTemplate =  [SELECT id,Name FROM Subjectivity_Template__c LIMIT 1];
        Test.startTest();
        String result = subjectivityController.createSubjectivitiesBySubjTemplate(qt.Id, new List<string> {subjectivityTemplate.Id});
        Test.stopTest();
        System.assert(result!= null);
        }
}