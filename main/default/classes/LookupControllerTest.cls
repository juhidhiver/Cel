@isTest
public class LookupControllerTest {
	@testSetup
    public static void setup() {
        // create broker account 
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert accBroker;
        
        Id brokerRtId1 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Account accBroker1 = TestUtil.createAccount('Account_Broker_Test_02', brokerRtId1, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert accBroker1;
        
        // create product
        Product2 product = TestUtil.createProduct('Test Product');
		insert product;
        
		// create opportunity        
        Opportunity opp = TestUtil.createOpportunity('Test Opportunity', accBroker.Id, product.Id);
        opp.StageName = 'Qualified';
        insert opp;
        
        Id recordTypeContactAgency = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Contact contactBroker = new Contact(
			LastName = 'Contact_Business_Test_01',
			RecordTypeId =recordTypeContactAgency ,
            Azure_Id__c = '1234',
			AccountId = accBroker.Id);
		insert contactBroker;
        
        Id recordTypeContactAgency1 = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId();        
        Contact contactBroker1 = new Contact(
			LastName = 'Contact_Broker_Test_02',
			RecordTypeId = recordTypeContactAgency1 ,
            Azure_Id__c = '4321',
			AccountId = accBroker1.Id);
		insert contactBroker1;
        
        Broker_Account__c newBrokerAccount = new Broker_Account__c(
													Broker_Contact__c = contactBroker1.Id,
													Relationship_Type__c = 'Broker',
													IsPrimaryBroker__c = true,
													Opportunity__c = opp.Id
													);
	    insert newBrokerAccount;
    }
    
    @isTest
    public static void testLookUp() {
        Account acc = [SELECT id,Name FROM Account WHERE Name=:'Account_Business_Test_01' LIMIT 1];
        Schema.SObjectType sObjectType = (acc.id).getSobjectType();
        String objectType = String.valueOf(sObjectType);
        String filter = 'Name=\''+'Account_Business_Test_01'+'\'';
        LookupController.lookUp('Test',objectType,filter);
        LookupController.lookUp('',objectType,'');
        LookupController.lookUp('Test',objectType,'');
       
        
        Opportunity opp = [SELECT id,Name FROM Opportunity WHERE StageName=:'Qualified' LIMIT 1];
        Schema.SObjectType sObjectTypeOpp = (opp.id).getSobjectType();
        String objectTypeOpp = String.valueOf(sObjectTypeOpp);
        String filterOpp = 'Name=\''+'Test Opportunity'+'\'';
        LookupController.lookUp('Test',objectTypeOpp,filterOpp);
        LookupController.lookUp('',objectTypeOpp,'');
        LookupController.lookUp('Test',objectTypeOpp,'');
        
        Contact con = [SELECT id,LastName FROM Contact Where LastName ='Contact_Business_Test_01' LIMIT 1];
        Schema.SObjectType sObjectTypeCon = (con.id).getSobjectType();
        String objectTypeCon = String.valueOf(sObjectTypeCon);
        String filterCon = 'LastName=\''+'Contact_Business_Test_01'+'\'';
        LookupController.lookUp('Test',objectTypeCon,filterCon);
        LookupController.lookUp('',objectTypeCon,'');
        LookupController.lookUp('Test',objectTypeCon,'');
        
      /*  Broker_Account__c BrokerAccount = [SELECT id,Name FROM Broker_Account__c Where Relationship_Type__c=:'Broker' LIMIT 1];
        Schema.SObjectType sObjectTypebrokerAcc = (BrokerAccount.id).getSobjectType();
        String objectTypeBrokkerAcc = String.valueOf(sObjectTypebrokerAcc);
        String filterBrokerAcc = 'Relationship_Type__c=\''+'Broker'+'\'';
        LookupController.lookUp('Test',objectTypeBrokkerAcc,filterBrokerAcc);
        LookupController.lookUp('',objectTypeBrokkerAcc,'');
        LookupController.lookUp('Test',objectTypeBrokkerAcc,'');*/
        
    }
    
    @isTest
    public static void testGetObjectById() {
        Account acc = [SELECT id,Name FROM Account WHERE Name=:'Account_Business_Test_01' LIMIT 1];
        Schema.SObjectType sObjectType = (acc.id).getSobjectType();
        String objectType = String.valueOf(sObjectType);
        sObject result = LookupController.getObjectById(String.valueOf(acc.Id),objectType);
        System.assertEquals('Account_Business_Test_01',((Account)result).Name);
    }
    @isTest
    public static void testGetLastModified() {
        LookupController.getModifiedRecords('User',UserInfo.getUserId());
    }
    
}