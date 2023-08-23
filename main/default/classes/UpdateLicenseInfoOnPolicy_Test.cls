@isTest
public class UpdateLicenseInfoOnPolicy_Test {
    
    public static testmethod void testbrokerpolicy(){
        
        test.startTest();
        
        // Account Business
		Account accBusiness = TestUtil.createBusinessAccount('Bussiness Account Test', 'Broker_Account', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        
		insert accBusiness;

	/*	// Create Contact Broker
        Id recordTypeContactAgency = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
		Contact contactBroker = TestUtil.createContact(accBusiness.Id, 'Broker', 'New broker contact');
		contactBroker.RecordTypeId = recordTypeContactAgency;
		insert contactBroker;
        */
        Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Broker_Contact').getRecordTypeId();
        system.debug('broker id' + recordTypeId);
		Contact newContact = new Contact(
			LastName ='New broker contact',
			RecordTypeId = recordTypeId,
			AccountId = accBusiness.Id);
        system.debug('hello'+newContact);
        insert newContact;

		Product2 product = TestUtil.createProduct('MPL Standalone');
		insert product;

        Opportunity oppt = TestUtil.createOpportunity('Opp Test',accBusiness.Id, product.Id);
		insert oppt;
		TriggerHandler.bypass('BrokerAccountTriggerBaseHandler');
		
        // Add Broker to Opportunity
			Broker_Account__c broAcc = new Broker_Account__c();
			broAcc.Relationship_Type__c = 'Broker';
			broAcc.Broker_Contact__c = newContact.Id;
			broAcc.Opportunity__c = oppt.Id;
			broAcc.IsPrimaryBroker__c = true;
		insert broAcc;
        TriggerHandler.bypass('BrokerAccountTriggerBaseHandler');
        system.debug('BrokerAccount' + broAcc);
        
        Quote quote = TestUtil.createQuote('New Quote Test',oppt.Id);
		quote.Coverage_Product_Options__c ='MPL';
		insert quote;	
        
         
        Policy__c policy = new Policy__c();
        policy.Account__c = accBusiness.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);
        insert policy;
        
        UpdateLicenseInfoOnPolicy m =  new UpdateLicenseInfoOnPolicy();
        UpdateLicenseInfoOnPolicy.getBrokerDetail(quote.id);
        UpdateLicenseInfoOnPolicy.getBrokerDetail(policy.Id);
        UpdateLicenseInfoOnPolicy.updatePolicyBLInfo(policy.Id,'{"blOwner":"Agency","id":"a082500000IxAI5AAN","blOwnerName":"Test User","blNo":"1407112","liceseState":"TX","NPNStatus":"Pass","blOwnerAddress":"Test User, 15687 Thistle Court, New York, New York, 40000"}');
        
        test.stopTest();
    }
    
}