/**************************************************************************************************
 * Class Name: TestUtil
 * Author: Hoang Bui
 * Date: 27-Aug-2019
 * Description: TestUtil support for create data in test class
 **************************************************************************************************/
@isTest
public with sharing class TestUtil {
    
	/*************************************************
    * Author: Hoang Bui
    * Date: 23-Aug-2019
    * Params:
    * Return: TriggerSettings__c
    * Description: initial TriggerSetting
    * Revision: 
    *************************************************/
    public static TriggerSettings__c initialTriggerSetting(){
		TriggerSettings__c setting = new TriggerSettings__c();
		setting.BypassAccountLocationTrigger__c = true;
		setting.BypassAccountTrigger__c = true;
		setting.BypassBrokerAccountTrigger__c = true;
		setting.BypassCoverageLineItemTrigger__c = true;
		setting.BypassCoverageTrigger__c = true;
		setting.BypassLimitDeductibleTrigger__c = true;
		setting.BypassOpportunityTrigger__c = true;
		setting.BypassQuoteLineItemTrigger__c = true;
		setting.BypassQuoteLocationTrigger__c = true;
		setting.BypassQuoteTrigger__c = true;

		insert setting;
		return setting;
	}

	/*************************************************
    * Author: Hoang Bui
    * Date: 23-Aug-2019
    * Params:
    * Return: Contact
    * Description: create a new Contact
    * Revision: 
    *************************************************/
	public static Contact createContact(Id accountId, String recordTypeName, String contactName){
		Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();
		Contact newContact = new Contact(
			LastName = contactName,
			RecordTypeId = recordTypeId,
			AccountId = accountId);
		return newContact;
	}

	/*************************************************
    * Author: Hoang Bui
    * Date: 23-Aug-2019
    * Params:
    * Return: Broker_Account__c
    * Description: create a Broker Account
    * Revision: 
    *************************************************/
	public static Broker_Account__c createBrokerAccount(String contactId, String opptId) {
		Broker_Account__c broAcc = new Broker_Account__c(
			Relationship_Type__c = 'Broker',
			Broker_Contact__c = contactId,
			Opportunity__c = opptId,
			IsPrimaryBroker__c = true
		);

		return broAcc;
	}

	/*************************************************
    * Author: Hoang Bui
    * Date: 23-Aug-2019
    * Params: address, city, country, postalCode, state
    * Return: Location__c
    * Description: create a new Location
    * Revision: 
    *************************************************/
	public static Location__c createNewLocation(String address, String city, String country, 
												String postalCode, String state){
		Location__c loc = new Location__c(
			Address__c = address,
	        City__c = city, 
	        Country__c = country,
	        Postal_Code__c = postalCode, 
	        State_Province__c = state
		);
		
		return loc;
	}
	/*************************************************
	* Author: Hai Bui
	* Date: 11-November-2019
	* Params: quoteId, deductibleID, coverRageId, optionType.
	* Return: CoveragesLineItem__c
	* Description: create a coverage line item
	* Revision:
	*************************************************/
	public static CoveragesLineItem__c createCoverageLineItem(String quoteId, String deductibleID, String coverRageId ,String optionType ){
		CoveragesLineItem__c coverLi = new CoveragesLineItem__c();
		coverLi.Coverage__c  = coverRageId;
		coverLi.Option_Type__c = optionType;
		coverLi.Quote__c = quoteId;
		coverLi.Coverage_Product__c ='D&O';
		coverLi.Coverage_Premium__c  = 'Text Premium';
		coverLi.Min_amt__c  = 1000;
		coverLi.Max_amt__c  = 5000;
		coverLi.Option_Picklist__c = 'Option1;option2;option3';
		coverLi.Limits_Deductibles__c = deductibleID;
		coverLi.Deductible_Frequency__c  = 'Daily';
		coverLi.Options_Value_Percent__c  = 5;
		coverLi.Factor_Value__c = 3 ;
		coverLi.Factor_Min__c = 4;
		coverLi.Factor_Max__c = 5;
		coverLi.Option_Value_Default__c = 'Default';

		return coverLi;
	}


	/*************************************************
    * Author: Hoang Bui
    * Date: 23-Aug-2019
    * Params: accountName, recordTypeName, street, city, country, postalCode, state
    * Return: Account
    * Description: Create a new Bussiness account
    * Revision: 
    *************************************************/
    public static Account createBusinessAccount(String accountName, String recordTypeName, String street, String city, String state, String postalCode, String country){
		Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();
		Account newAccount = new Account(
			Name = accountName,
			RecordTypeId = recordTypeId,
			ShippingStreet = street,
			ShippingCity = city,
			ShippingState = state,
			ShippingPostalCode = postalCode,
			ShippingCountry = country);
		return newAccount;
	}

    /*************************************************
    * Author: Hoang Bui
    * Date: 23-Aug-2019
    * Params: product name
    * Return: Product2
    * Description: create a new product
    * Revision: 
    *************************************************/
    public static Product2 createProduct(String name){
		return new Product2(
			Name = name, 
            IsActive = true, 
			Package_Indicator__c = true,
            Innovisk_Entity_ID__c = 'Celerity',
			Effective_Date__c = Date.today(), 
            Expiration_Date__c = Date.today().addYears(1)
		);
	}

	/*************************************************
    * Author: Hoang Bui
    * Date: 23-Aug-2019
    * Params: oppt name, accountId, productId
    * Return: Opportunity
    * Description: Create Opportunity
    * Revision: 
    *************************************************/
	public static Opportunity createOpportunity(String name, String accountId, String productId){
		return new Opportunity(
			Name = name, 
			StageName = 'New',
			AccountId = accountId,
			Product__c = productId,
			Received_Date__c = Date.today(),
			CloseDate = Date.today().addMonths(2),
			Effective_Date__c = Date.today().addMonths(1),
			Expiration_Date__c = Date.today().addMonths(2),
			Type = 'New Business',
			LeadSource = 'Email'
		);
	}

	/*************************************************
    * Author: Hoang Bui
    * Date: 23-Aug-2019
    * Params: Quote Name, opportunityId
    * Return: Quote
    * Description: Create Quote
    * Revision: 
    *************************************************/
	public static Quote createQuote(String name, String opportunityId){
		return new Quote(
			Name = name, 
            OpportunityId = opportunityId
		);
	}

    /*************************************************
    * Author: Hoang Bui
    * Date: 23-Aug-2019
    * Params: Coverage name, productName
    * Return: Quote
    * Description: Create Coverage
    * Revision: 
    *************************************************/
	public static Coverage__c createCoverage(String name, String productName){
		return new Coverage__c(
            Name = name,
			Coverage_Product__c = productName
        );
	}

	/*************************************************
    * Author: Hoang Bui
    * Date: 23-Aug-2019
    * Params: LimitsDeductibles name, parentCoverageId
    * Return: Coverage_Limits_Deductibles__c
    * Description: create limit/deductible coverage
    * Revision: 
    *************************************************/
	public static Coverage_Limits_Deductibles__c creatLimitsDeductibles(String name, String parentCoverageId){
		return new Coverage_Limits_Deductibles__c(
			Name = name, 
            Parent_Coverage__c = parentCoverageId
		);
	}

	/*************************************************
    * Author: Hoang Bui
    * Date: 23-Aug-2019
    * Params: Rating Modifier Template name, productName, formatField
    * Return: Rating_Modifier_Template__c
    * Description: create Rating Modifier Template
    * Revision: 
    *************************************************/
    public static Rating_Modifier_Template__c createRatingModifierTemplate(String name, String productName, String formatField){
		return new Rating_Modifier_Template__c(
			Name = name, 
			Product__c = productName,
			Modifier_Format__c = formatField
		);
	}

	/*************************************************
    * Author: Hoang Bui
    * Date: 23-Aug-2019
    * Params: Rating Modifier Template name, productName, OppId
    * Return: Rating_Modifiers__c
    * Description: create Rating Modifier
    * Revision: 
    *************************************************/
    public static Rating_Modifiers__c createRatingModifier(String name, String productName, String OppId){
		return new Rating_Modifiers__c(
			Name = name, 
			Product__c = productName,
			Opportunity__c = OppId
		);
	}

	/*************************************************
    * Author: Hoang Bui
    * Date: 23-Aug-2019
    * Params: Rating Modifier Template name, productName, OppId, formatField
    * Return: Rating_Modifiers__c
    * Description: create Rating Modifier Format
    * Revision: 
    *************************************************/
    public static Rating_Modifiers__c createRatingModifierFormat(String name, String productName, String OppId, String formatField){
		return new Rating_Modifiers__c(
			Name = name, 
			Product__c = productName,
			Opportunity__c = OppId,
			Format__c = formatField,
			Sub_Section__c = 'Test SubsectionCmpController',
			Page_Section__c = 'A) Eligibility',
			Eligibility_Weighting_Factor__c = 2            
		);
	}

	/*************************************************
    * Author: Hoang Bui
    * Date: 23-Aug-2019
    * Params: quoteId, productName, locationId, primaryLocation
    * Return: Quote_Location__c
    * Description: Create Quote Location
    * Revision: 
    *************************************************/
	public static Quote_Location__c createQuoteLocation(String quoteId, String locationId, Boolean primaryLocation) {
		Quote_Location__c newQuoteLoc = new Quote_Location__c(
			Quote__c = quoteId,
			Locations__c =  locationId,
			Primary_Location__c = primaryLocation
		);

		return newQuoteLoc;
	}


	/*************************************************
    * Author: Khanh TRAN
    * Date: 31-Oct-2019
    * Params: String name, Id recordtypeId, String street, 
			  String city, String state, String postalCode, String country
    * Return: Account
    * Description: Create Account
    *************************************************
    */
	public static Account createAccount(String name, Id recordtypeId, String street, 
									String city, String state, String postalCode, String country) {
	Account acc = new Account(
		Name 				= name,
		BillingStreet		= street,
		BillingCity			= city,
		BillingState		= state,
		BillingPostalCode	= postalCode,
		BillingCountry		= country,
		RecordTypeId 		= recordtypeId			
	);
	return acc;
	}


	/*************************************************
    * Author: Hoang Bui
    * Date: 31-Oct-2019
    * Params: 
    * Return: 
    * Description: Create Quote on the new Opportunity
    * Revision: 
    *************************************************/
	public static void createQuoteOnOpportunity() {		
		// Account Business
		Account accBusiness = createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
		insert accBusiness;

		// Create Contact Broker
        Id recordTypeContactAgency = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
		Contact contactBroker = createContact(accBusiness.Id, 'Broker_Contact', 'New broker contact');
		contactBroker.RecordTypeId = recordTypeContactAgency;
		insert contactBroker;

		Product2 product = createProduct('MPL Standalone');
		insert product;

        Opportunity oppt = createOpportunity('Opp Test',accBusiness.Id, product.Id);
		insert oppt;
		TriggerHandler.bypass('BrokerAccountTriggerHandler');
		
        // Add Broker to Opportunity
		Broker_Account__c newBroAccount = createBrokerAccount(contactBroker.Id, oppt.Id);
		insert newBroAccount;
		TriggerHandler.clearBypass('BrokerAccountTriggerHandler');

		// Qualify Opportunity
		oppt.StageName = 'Qualified';
		update oppt;

		//Create coverage
		Coverage__c cov = createCoverage('Coverage test', 'D&O');
		insert cov;
        
        //Create coverage
		Coverage__c cov1 = createCoverage('Coverage test', 'MPL');
		insert cov1;
        
       //create limit deductables
		Coverage_Limits_Deductibles__c ded = creatLimitsDeductibles('Deductible test', cov1.Id);
        insert ded;

        Quote quote = createQuote('New Quote Test',oppt.Id);
		quote.Coverage_Product_Options__c ='MPL';
		insert quote;		
	}

	// Cerate product2
	public static Product2 createProduct(String name, Id recordtypeId, String innoviskEntity){
		return new Product2(
			Name = name, 
			IsActive = true, 
			Package_Indicator__c = true,
			Effective_Date__c = Date.today(), 
			Expiration_Date__c = Date.today().addYears(1),
			Innovisk_Entity_ID__c = innoviskEntity,
			RecordTypeId = recordtypeId
		);
	}

	// Create PricebookEntry
	public static PricebookEntry createPricebookEntry(String pricebook2Id, String productId){
		return new PricebookEntry(
		    Pricebook2Id = pricebook2Id, 
			Product2Id = productId, 
			UnitPrice = 10000, 
			IsActive = true
	    );
	}

	public static Opportunity createOpportunity(String name, String accountId, 
							String productId, Id recordtypeId, String innoviskEntity){
		return new Opportunity(
			Name = name, 
			StageName = 'New',
			AccountId = accountId,
			Product__c = productId,
			Received_Date__c = Date.today(),
			CloseDate = Date.today().addMonths(1),
			Effective_Date__c = Date.today().addMonths(1),
			Type = 'New Business',
			LeadSource = 'Email',
			Innovisk_Entity_ID__c = innoviskEntity,
			RecordTypeId = recordtypeId
		);
	}

	/*************************************************
    * Author: Quoc DO
    * Date: 12-Nov-2019
    * Params: Contact contactBroker, String licenseState, String licenseNumber
    * Return: 
    * Description: Create Broker_License__c
    * Revision: 
    *************************************************/
	public static Broker_License__c createBrokerLicense(Contact contactBroker, String licenseState, String licenseNumber) {
		return new Broker_License__c(Broker__c = contactBroker.Id,
									License_State__c = licenseState,
  									License_Number__c = licenseNumber);
	}

	public static Additional_Interests__c createAdditionalInterests(id additionalAccountID, id quoteID, String relationshipType) {
		return new Additional_Interests__c(
			Additional_Interest_Account__c = additionalAccountID,
			Quote__c = quoteID,
			Relationship_Type__c = relationshipType);
	}
}