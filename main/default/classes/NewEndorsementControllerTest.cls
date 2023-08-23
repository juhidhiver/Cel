/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 08-05-2022
 * @last modified by  : Vinayesh
**/
@isTest
public class NewEndorsementControllerTest {
    @testSetup
    public static void setup() { 
        
        Account acc1 = new Account();
        acc1.Name = 'Test account 2';
        acc1.BillingStreet = '11 Tran Duy Hung';
        acc1.BillingCity = 'Westminster';
        acc1.BillingState = 'California';
        acc1.BillingPostalCode = '90000';
        acc1.BillingCountry = 'United States';
        //acc1.Billing_County__c;
        acc1.IsMailingSameWithBillingAddress__c = true;
        acc1.Date_Started__c = Date.today().addYears(-2);
        insert acc1;
        
        Product2 product = TestUtil.createProduct('MPL');
        insert product;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc1.Id, product.Id);
        insert opportunity;
        
        Policy__c policy = new Policy__c();
        policy.Account__c = acc1.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);
        insert policy;
        
        Subjectivity_Template__c subjectivityTemplate = new Subjectivity_Template__c();
        subjectivityTemplate.Subjectivity_Name__c = 'Signed / Dated Proposal';
        subjectivityTemplate.Subjectivity_Text__c = 'Test';
        subjectivityTemplate.Profession_Criteria__c = 'Engineers';
        insert subjectivityTemplate;
        
        Quote_Process__c qp = new Quote_Process__c();
        qp.Account__c = acc1.Id;
        qp.Submission__c = opportunity.Id;
        insert qp;

        update new Opportunity(Id = opportunity.Id, QP_link__c = qp.Id);

        Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote.Coverage_Product_Options__c ='MPL';
        quote.Policy__c = policy.Id;
        quote.Effective_Date__c = Date.today().addDays(-6);
        insert quote;

        
        
        Subjectivity__c subj = new Subjectivity__c();
        subj.Subjectivity__c = 'Testing';
        subJ.Subjectivity_Status__c = 'Open';
        subJ.Subjectivity_Type__c = 'MPL';
        subJ.Quote__c = quote.Id;
        subJ.RecordTypeId = Schema.SObjectType.Subjectivity__c.getRecordTypeInfosByName().get(GlobalVariables.RT_NAME_SUBJECTIVITY_CELERITY).getRecordTypeId();
        insert subJ;
        
        Id recordTypeAccBroker = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Account accBroker = new Account(
            Name='Account_Broker_Test_01', 
            RecordTypeId = recordTypeAccBroker, 
            BillingStreet = '5305, Monroe Street',
            BillingCity = 'Toledo', 
            BillingState = 'Ohio',
            BillingPostalCode = '43623', 
            BillingCountry = 'United States',
            FEIN__c = 12345
        );
        insert accBroker;

        List<Contact> brokerConList = new List<Contact>();
        Id recordTypeConBroker = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Contact contactBroker1 = new Contact(
            FirstName = 'Test',
			LastName = 'Broker_Contact_1',
			RecordTypeId =recordTypeConBroker ,
            Azure_Id__c = '1234',
            Email = 'test1@broker.com',
			AccountId = accBroker.Id
        );
		brokerConList.add(contactBroker1);

        Contact contactBroker2 = new Contact(
            FirstName = 'Test',
			LastName = 'Broker_Contact_2',
			RecordTypeId =recordTypeConBroker ,
            Azure_Id__c = '1235',
            Email = 'test2@broker.com',
			AccountId = accBroker.Id
        );
		brokerConList.add(contactBroker2);

        Contact contactBroker3 = new Contact(
            FirstName = 'Test',
			LastName = 'Broker_Contact_3',
			RecordTypeId =recordTypeConBroker ,
            Azure_Id__c = '1236',
            Email = 'test3@broker.com',
			AccountId = accBroker.Id
        );
		brokerConList.add(contactBroker3);
        insert brokerConList;

        List<Broker_Account__c> brokerAccList = new List<Broker_Account__c>();
        Broker_Account__c brokerAccount1 = new Broker_Account__c(
			Broker_Contact__c = contactBroker1.Id,
			Opportunity__c = opportunity.Id,
			IsPrimaryBroker__c = false,
			Relationship_Type__c = 'Broker'
		);
		brokerAccList.add(brokerAccount1);
        Broker_Account__c brokerAccount2 = new Broker_Account__c(
			Broker_Contact__c = contactBroker2.Id,
			Opportunity__c = opportunity.Id,
			IsPrimaryBroker__c = true,
			Relationship_Type__c = 'Broker'
		);
		brokerAccList.add(brokerAccount2);
        insert brokerAccList;

        Coverage__c cov = Testutil.createCoverage('Coverage 1', 'D&O');
        insert cov;
        
        Coverage_Limits_Deductibles__c covLD = TestUtil.creatLimitsDeductibles('test LD', cov.id);
        insert covLD;

        GlobalStaticVar.byPassCoverageLineItemTrigger = true;
        CoveragesLineItem__c covLineItem = testUtil.createCoverageLineItem(quote.id, covLD.id, cov.Id, 'Picklist');
        covLineItem.Azure_ID__c = '61b1c13d-24a5-4181-8ccc-d3929c1b4edd';
        covLineItem.Coverage_Product__c = 'D&O';
        insert covLineItem;

        Quote_Option__c quoteOpt = new Quote_Option__c();
        quoteOpt.Azure_ID__c = 'Test';
        quoteOpt.Quote__c =  quote.Id;
        quoteOpt.Selected__c = true;
        insert quoteOpt;

        Location__c loc = TestUtil.createNewLocation('234, 1st Avenuet','New York', 'United States', '10593', 'California');
        loc.State_Code__c  = 'LA';
        insert loc;                            
        
        Quote_Location__c ql = TestUtil.createQuoteLocation(quote.Id, loc.Id, true);   
        insert ql;

        //Additional_Interests__c addInt = TestUtil.createAdditionalInterests(acc1.Id, quote.Id, 'Additional Insured');
        //insert addInt;

        Insurer_Layer_Limit__c insurerLayerLimit = new Insurer_Layer_Limit__c();
        insurerLayerLimit.Quote__c = quote.Id;
        insurerLayerLimit.Layer__c = 'Test';
        insurerLayerLimit.CurrencyIsoCode = 'GBP';
        insert insurerLayerLimit;

        //Rating Modifires
        Rating_Modifiers__c rMod = new Rating_Modifiers__c();
        rMod.Opportunity__c = opportunity.Id;
        insert rMod;     
        
        //Rating Modifier Factor
        Rating_Modifier_Factor__c rm = new Rating_Modifier_Factor__c();
        rm.Factor_Default_Value__c = 123;
        rm.Factor_Max__c = 300;
        rm.Factor_Min__c = 100;
        rm.Factor_Value__c = 120;
        rm.Rating_Modifier__c = rMod.Id;
        rm.Quote__c = quote.Id;    
        insert rm; 

        Free_Form_Endorsements__c free = new Free_Form_Endorsements__c();
        free.Quote__c = quote.id;
        insert free;

        GlobalStaticVar.byPassQuoteTrigger = true;
    }
    
    public class WebServiceMockRatingImpl implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Quote_ID":"0Q025000000F0qzCAC","Azure_ID__c":"955cf433-f722-4676-9656-e9618bb52507","QuoteNumber":"00001669","ProductClassCd":"Celerity_MPL","Master_Set_ID__c":"1","Quote_Type__c":"New Business","Effective_Date__c":"' + Date.today().addDays(-5)  + '","ExpirationDate":"2021-07-11","TechnicalPremium__c":"220865","Status":"Clear","CoveragePremium__c":"220865","QuotePremium__c":"220865","AcceptedTerrorism_Premium":"","RejectedTerrorism_Premium":"","SelectedTerrorism_Premium":"","Taxes":"","Fees":"","ProductName":"MPL Standalone","ProductId":"c502328a-df80-44d4-ae6e-df4fa44630ea","WritingCompany":"0012500001E5djsAAB","commissionAmount":"0","Commission_percentage__c":"","nonProratedQuotePremium":"220865","Accounts":[{"Id":null,"Name":"FLOWERS INC","Azure_ID__c":"76b6d907-52f5-4cec-a5a5-90c6939e8591","PrimaryAddress":{"Latitude":null,"Longitude":null,"Address1":"325 CLEVELAND RD","Address2":"","City":"BOGART","County":"","StateProvCd":"GA","CountryCd":"US","PostalZipCd":"30622","LocLatitude":null,"LocLongitude":null,"LocCountry":null,"LocLevel1":null,"LocLevel2":null,"LocLevel3":null,"LocLevel4":null,"LocLevel5":null,"LocType":null}}],"RatingModifiers":[{"azureID":"7de76104-ad6d-4606-8343-59878d2e9f4a","ratingModifierName":"Average years of experience of your staff in this industry","ratingModifierCode":"MPL000004","ratingModifierValue":"5+ years","factorValue":"0.875","factorMin":"0.75","factorMax":"1.0","defaultValue":"0.875"},{"azureID":"e99e9f01-6de8-4383-8202-b8c722f45d02","ratingModifierName":"Claim Free Credit","ratingModifierCode":"MPL000005","ratingModifierValue":"Claim Free","factorValue":"0.875","factorMin":"0.75","factorMax":"1.0","defaultValue":"0.875"},{"azureID":"347136cd-d1a9-4181-aeee-df576fbe7289","ratingModifierName":"Jurisdiction","ratingModifierCode":"MPL000012","ratingModifierValue":"Unfavorable","factorValue":"1.125","factorMin":"1.0","factorMax":"1.25","defaultValue":"1.125"},{"azureID":"cbd48ac4-6763-41a1-9212-bcf3e8b555b3","ratingModifierName":"Restrictive Endorsement Factor selected","ratingModifierCode":"MPL000020","ratingModifierValue":"At least one restrictive endorsement and no very restrictive endorsements","factorValue":"0.900","factorMin":"0.8","factorMax":"1.0","defaultValue":"0.9"},{"azureID":"53c2e38f-2f3e-4404-b5b5-3e245a1e20e2","ratingModifierName":"Expansive Endorsement Factor selected","ratingModifierCode":"MPL000009","ratingModifierValue":"At least one very expansive endorsement","factorValue":"1.900","factorMin":"1.3","factorMax":"2.5","defaultValue":"1.9"},{"azureID":"a5ba23b9-0ae4-4333-ba7a-fc48012cb3c6","ratingModifierName":"Merger/Acquisition Activity","ratingModifierCode":"MPL000014","ratingModifierValue":null,"factorValue":"1.000","factorMin":"0.75","factorMax":"1.25","defaultValue":"1.0"},{"azureID":"55928043-3981-4858-a4a4-ed1e44581c7d","ratingModifierName":"Material Changes in Revenues","ratingModifierCode":"MPL000013","ratingModifierValue":null,"factorValue":"1.000","factorMin":"0.75","factorMax":"1.25","defaultValue":"1.0"},{"azureID":"4148f847-a0be-40d0-84c4-1fa50b165fcd","ratingModifierName":"Risk Management Procedures/Controls","ratingModifierCode":"MPL000021","ratingModifierValue":null,"factorValue":"1.000","factorMin":"0.75","factorMax":"1.25","defaultValue":"1.0"},{"azureID":"414b7957-936d-4ebe-89c9-c4a0b7e57c22","ratingModifierName":"Claims/Litigation History","ratingModifierCode":"MPL000006","ratingModifierValue":null,"factorValue":"1.000","factorMin":"0.75","factorMax":"1.25","defaultValue":"1.0"},{"azureID":"257dc64a-4f3a-40c0-8303-aab7fdc4a3ce","ratingModifierName":"Percentage of Written Contracts Used","ratingModifierCode":"MPL000018","ratingModifierValue":"75% to 99%","factorValue":"1.000","factorMin":"1.0","factorMax":"1.0","defaultValue":"1.0"},{"azureID":"c0551800-aeab-4eae-8343-4b97206def69","ratingModifierName":"Nature of Services","ratingModifierCode":"MPL000015","ratingModifierValue":null,"factorValue":"1.000","factorMin":"0.75","factorMax":"1.25","defaultValue":"1.0"},{"azureID":"d427eb63-d33e-4323-86c6-7d61cdbb59d6","ratingModifierName":"Extended Reporting Period Factor (ERPF)","ratingModifierCode":"MPL000011","ratingModifierValue":"One Year","factorValue":"1","factorMin":"1","factorMax":"1","defaultValue":"1"},{"azureID":"6d973d09-c156-4050-abeb-119b78293cdc","ratingModifierName":"Annual Revenues","ratingModifierCode":"MPL000000","ratingModifierValue":"52100000","factorValue":null,"factorMin":null,"factorMax":null,"defaultValue":null},{"azureID":"3cfbd1a3-1f6a-4272-8303-d4523fc80b85","ratingModifierName":"Service Classification","ratingModifierCode":"MPL000002","ratingModifierValue":"Dispute Resolution","factorValue":"0.600","factorMin":"0.25","factorMax":"0.95","defaultValue":"0.6"},{"azureID":"f4109844-2206-4646-a3e3-2645e4347ac5","ratingModifierName":"Prior acts coverage","ratingModifierCode":"MPL000019","ratingModifierValue":"4 Years","factorValue":"0.962","factorMin":"0.962","factorMax":"0.962","defaultValue":"0.962"},{"azureID":"d69ee754-377c-4696-b535-754c0fc5ab0d","ratingModifierName":"Number of Years in Business","ratingModifierCode":"MPL000016","ratingModifierValue":"1 to 3 years","factorValue":"1.125","factorMin":"1.0","factorMax":"1.25","defaultValue":"1.125"},{"azureID":"587f89cb-e299-4ece-8949-30c4fb3a53c9","ratingModifierName":"Use of Independent Contractors","ratingModifierCode":"MPL000025","ratingModifierValue":"25% or Less","factorValue":"1.050","factorMin":"1.0","factorMax":"1.1","defaultValue":"1.05"},{"azureID":"f5f23569-d5a6-4a0a-a969-5d5588503a57","ratingModifierName":"Written Contracts Used","ratingModifierCode":"MPL000027","ratingModifierValue":"Yes","factorValue":"1.000","factorMin":"1.0","factorMax":"1.0","defaultValue":"1.0"},{"azureID":"7749c5d4-0af8-4515-b6b6-f3d000154ce5","ratingModifierName":"Contracts Reviewed by Counsel","ratingModifierCode":"MPL000008","ratingModifierValue":"No","factorValue":"1.125","factorMin":"1.0","factorMax":"1.25","defaultValue":"1.125"},{"azureID":"6e791ead-8bf5-4d7d-a5e5-1abe3c163106","ratingModifierName":"Use of written training and procedural manuals","ratingModifierCode":"MPL000026","ratingModifierValue":"Yes","factorValue":"0.950","factorMin":"0.9","factorMax":"1.0","defaultValue":"0.95"}],"overallUWCodes":[],"overallUWDescriptions":[],"CoverageLineItems":[{"id":"c3147334-7d28-4181-b272-2320e2041c72","Coverage__c":"a0425000007aIF4AAM","name":"Contingent BIPD Coverage (Without Other Insurance Amendment)EndorsementSublimit","Coverage_Code__c":"ContigentBIPDWithoutAmend","Coverage_Premium__c":"24183.434951999996","Override_Premium__c":"24183","nonProratedCoveragePremium":"24183.434951999996","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"8934a810-ae39-41b1-b5f5-feac954eb79d","name":"BIPD Aggregate Limit w/o Amendment","Code__c":"BIPDWithoutInsuranceAmendment","Option_Value_Default__c":"100k - 100k","Option_Type__c":"Picklist","Coverage__c":"a0425000007aIF4AAM","Option_Picklist__c":["No Coverage","100k - 100k","100k - 300k","250k - 250k","250k - 500k","300k - 300k","300k - 500k","500k - 500k","500k - 1m","1m - 1m","1m - 2m","1m - 3m","2m - 2m","2m -5m","3m - 3m","3m - 5m","4m - 4m","5m - 5m","6m - 6m","7m - 7m","8m - 8m","9m - 9m","10m - 10m","11m - 11m","12m - 12m","13m - 13m","14m -14m","15m - 15m"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"a5f0a189-e538-45d5-8383-ae2afa809fd3","Coverage__c":"a0425000007aHevAAE","name":"Open House Sublimit Endorsement","Coverage_Code__c":"OpenHouse","Coverage_Premium__c":"1323.72","Override_Premium__c":"1324","nonProratedCoveragePremium":"1323.72","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"ef28071c-65f3-4474-aaea-e12a55de4aef","name":"OpenHouseSublimit","Code__c":"OpenHouseSublimit","Option_Value_Default__c":"001000","Option_Type__c":"Range","Coverage__c":"a0425000007aHevAAE","Min_amt__c":"0","Max_amt__c":"5000000","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"41ba9b9a-2f7d-4080-8e0e-693e4fc12095","Coverage__c":"a0425000007aHeuAAE","name":"Failure to Disclose Pollutants Sublimit","Coverage_Code__c":"FailurtoDisclose","Coverage_Premium__c":"3309.3","Override_Premium__c":"3309","nonProratedCoveragePremium":"3309.3","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"8ec7fe9d-8f8b-4a3a-ad2d-c51663f91dab","name":"Failure to Disclose Sublimit","Code__c":"FailurtoDiscloseSublimit","Option_Value_Default__c":"1000","Option_Type__c":"Range","Coverage__c":"a0425000007aHeuAAE","Min_amt__c":"0","Max_amt__c":"5000000","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"ef4d7cc6-0bd9-4626-8c4c-9df46629a3c8","Coverage__c":"a0425000007aHehAAE","name":"Infringement of Copyright","Coverage_Code__c":"InfringementOfCopyright2","Coverage_Premium__c":"0.0","Override_Premium__c":"0","nonProratedCoveragePremium":"0.0","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"2c0dcd05-5303-4cbc-a9a9-10bf82bbbd0e","name":"Limit","Code__c":"CopyrightLimit","Option_Value_Default__c":"No Coverage","Option_Type__c":"Picklist","Coverage__c":"a0425000007aHehAAE","Option_Picklist__c":["No Coverage","100k - 100k","100k - 300k","250k - 250k","250k - 500k","300k - 300k","300k - 500k","500k - 500k","500k - 1m","1m - 1m","1m - 2m","1m - 3m","2m - 2m","2m -5m","3m - 3m","3m - 5m","4m - 4m","5m - 5m","6m - 6m","7m - 7m","8m - 8m","9m - 9m","10m - 10m","11m - 11m","12m - 12m","13m - 13m","14m -14m","15m - 15m"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"bcb4940f-653e-4888-b030-d1e6bc36a6ef","name":"Retention","Code__c":"InfringementRetention","Option_Value_Default__c":"0","Option_Type__c":"Range","Coverage__c":"a0425000007aHehAAE","Min_amt__c":"0","Max_amt__c":"99999999999","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"7a813c0a-5939-46b6-9b1b-6f2e52cd9f40","Coverage__c":"a0425000007aHdvAAE","name":"Independent Contractor Extension Endorsement","Coverage_Code__c":"IndependentContractorExtension","Coverage_Premium__c":"0.0","Override_Premium__c":"0","nonProratedCoveragePremium":"0.0","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"5c945d28-60c9-40a0-80c0-66d07a334e6b","name":"Limit","Code__c":"IndependentLimit","Option_Value_Default__c":"No Coverage","Option_Type__c":"Picklist","Coverage__c":"a0425000007aHdvAAE","Option_Picklist__c":["No Coverage","100k - 100k","100k - 300k","250k - 250k","250k - 500k","300k - 300k","300k - 500k","500k - 500k","500k - 1m","1m - 1m","1m - 2m","1m - 3m","2m - 2m","2m -5m","3m - 3m","3m - 5m","4m - 4m","5m - 5m","6m - 6m","7m - 7m","8m - 8m","9m - 9m","10m - 10m","11m - 11m","12m - 12m","13m - 13m","14m -14m","15m - 15m"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"138a3827-e236-4212-8606-8af5cdb841b6","name":"Retention","Code__c":"IndependentContractorRetention","Option_Value_Default__c":"0","Option_Type__c":"Range","Coverage__c":"a0425000007aHdvAAE","Min_amt__c":"0","Max_amt__c":"99999999999","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"60eece9f-3943-4424-9717-a2f4eb7cb3c5","Coverage__c":"a0425000007aHduAAE","name":"Theft of Funds","Coverage_Code__c":"TheftOfFund","Coverage_Premium__c":"1985.58","Override_Premium__c":"1986","nonProratedCoveragePremium":"1985.58","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"6b8c547e-c9ab-47c7-96d6-56380114267a","name":"Theft Of Fund Sublimit","Code__c":"TheftOfFundSublimit","Option_Value_Default__c":"001000","Option_Type__c":"Range","Coverage__c":"a0425000007aHduAAE","Min_amt__c":"0","Max_amt__c":"5000000","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"176f7710-e7b7-4ebe-b333-b8cfdddf8e1f","Coverage__c":"a0425000007aHdsAAE","name":"Subpoena Compliance Sublimit","Coverage_Code__c":"SubpoenaSublimit","Coverage_Premium__c":"1323.72","Override_Premium__c":"1324","nonProratedCoveragePremium":"1323.72","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"5d7156aa-3a53-4f0f-b171-24f7182d5047","name":"SubpoenaComplianceAmount","Code__c":"SubpoenaComplianceAmount","Option_Value_Default__c":"001000","Option_Type__c":"Range","Coverage__c":"a0425000007aHdsAAE","Min_amt__c":"0","Max_amt__c":"5000000","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"e3b72633-f25a-4181-9898-b4b2aa995cd3","Coverage__c":"a0425000007aHdrAAE","name":"CFPB Claim Expenses","Coverage_Code__c":"ClaimExpenses","Coverage_Premium__c":"1323.72","Override_Premium__c":"1324","nonProratedCoveragePremium":"1323.72","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"2361a341-5d3e-4d9d-9616-ed0ad68e0540","name":"CFPBClaimSublimit","Code__c":"CFPBClaimSublimit","Option_Value_Default__c":"1000","Option_Type__c":"Range","Coverage__c":"a0425000007aHdrAAE","Min_amt__c":"0","Max_amt__c":"5000000","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"7a44d7e4-b22d-4363-9757-c112e69abc68","Coverage__c":"a0425000007aHdqAAE","name":"Negligent Failure to Prevent Dishonest Conduct","Coverage_Code__c":"DishonestConduct","Coverage_Premium__c":"1323.72","Override_Premium__c":"1324","nonProratedCoveragePremium":"1323.72","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"d5b406cd-8eaf-4757-8e4e-bf1103473583","name":"NegFailPreventDishonestConductSublimit","Code__c":"NegFailPreventDishonestConductSublimit","Option_Value_Default__c":"001000","Option_Type__c":"Range","Coverage__c":"a0425000007aHdqAAE","Min_amt__c":"0","Max_amt__c":"5000000","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"4da3091f-04bb-4f5f-8dcd-0e1dd0bfbbe7","Coverage__c":"a0425000007aHdlAAE","name":"Lock Box BI PD Carve Back","Coverage_Code__c":"LockBoxBIPD","Coverage_Premium__c":"8061.144983999999","Override_Premium__c":"8061","nonProratedCoveragePremium":"8061.144983999999","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"b149f78a-b3e1-4a4a-a222-4307bb62606d","name":"Lock Box Limit","Code__c":"LockBoxBIPDLimit","Option_Value_Default__c":"100k - 100k","Option_Type__c":"Picklist","Coverage__c":"a0425000007aHdlAAE","Option_Picklist__c":["No Coverage","100k - 100k","100k - 300k","250k - 250k","250k - 500k","300k - 300k","300k - 500k","500k - 500k","500k - 1m","1m - 1m","1m - 2m","1m - 3m","2m - 2m","2m -5m","3m - 3m","3m - 5m","4m - 4m","5m - 5m","6m - 6m","7m - 7m","8m - 8m","9m - 9m","10m - 10m","11m - 11m","12m - 12m","13m - 13m","14m -14m","15m - 15m"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"e88e3ede-7eb3-4cec-80c0-ad448499cda9","name":"Retention","Code__c":"LockBoxRetention","Option_Value_Default__c":"0","Option_Type__c":"Range","Coverage__c":"a0425000007aHdlAAE","Min_amt__c":"0","Max_amt__c":"99999999999","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"05ea4e35-e485-4626-baba-fd04039dfc32","Coverage__c":"a0425000007aHdkAAE","name":"Infringement of Copyright & Trademark for Media Related Providers","Coverage_Code__c":"InfringementOfCopyright","Coverage_Premium__c":"0.0","Override_Premium__c":"0","nonProratedCoveragePremium":"0.0","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"80070c4e-06e5-4fdf-86c6-68734c04a0f8","name":"Limit","Code__c":"TrademarkLimit","Option_Value_Default__c":"No Coverage","Option_Type__c":"Picklist","Coverage__c":"a0425000007aHdkAAE","Option_Picklist__c":["No Coverage","100k - 100k","100k - 300k","250k - 250k","250k - 500k","300k - 300k","300k - 500k","500k - 500k","500k - 1m","1m - 1m","1m - 2m","1m - 3m","2m - 2m","2m -5m","3m - 3m","3m - 5m","4m - 4m","5m - 5m","6m - 6m","7m - 7m","8m - 8m","9m - 9m","10m - 10m","11m - 11m","12m - 12m","13m - 13m","14m -14m","15m - 15m"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"9b679cf1-504f-4747-b131-0d274cb12bfc","name":"Retention","Code__c":"TrademarkRetention","Option_Value_Default__c":"0","Option_Type__c":"Range","Coverage__c":"a0425000007aHdkAAE","Min_amt__c":"0","Max_amt__c":"99999999999","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"0de5582f-3631-4989-9a1a-c29e7213a64e","Coverage__c":"a0425000007aHdVAAU","name":"Miscellaneous Professional Liability","Coverage_Code__c":"MPL","Coverage_Premium__c":"88262.0","Override_Premium__c":"88262.0","nonProratedCoveragePremium":null,"Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"6ab9c4ca-b7f5-4cbc-bfbf-94afc1077a27","name":"MPL - Desired Limits","Code__c":"MPLLimit","Option_Value_Default__c":"100k - 300k","Option_Type__c":"Picklist","Coverage__c":"a0425000007aHdVAAU","Option_Picklist__c":["100k - 100k","100k - 300k","250k - 250k","250k -500k","300k - 300k","300k - 500k","500k - 500k","500k - 1m","1m - 1m","1m - 2m","1m - 3m","2m - 2m","2m - 5m","3m - 3m","3m - 5m","4m - 4m","5m - 5m","6m - 6m","7m - 7m","8m - 8m","9m - 9m","10m - 10m","11m - 11m","12m - 12m","13m - 13m","14m - 14m","15m - 15m"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"249d759b-b6fc-4f5f-b8f8-daa6e8f6e11a","name":"MPL - Retention","Code__c":"MPLDed","Option_Value_Default__c":"0","Option_Type__c":"Picklist","Coverage__c":"a0425000007aHdVAAU","Option_Picklist__c":["0","500","750","1000","1500","2500","5000","7500","10000","15000","25000","50000","75000","100000","150000","175000","200000","250000","300000","500000","750000","1000000"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"7a72ad28-1804-4939-9292-9312053c1ebc","Coverage__c":"a0425000007aHdPAAU","name":"Class Action SubLimit","Coverage_Code__c":"EndClassAction","Coverage_Premium__c":"3309.3","Override_Premium__c":"3309","nonProratedCoveragePremium":"3309.3","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"b45978cb-e31e-4090-a3a3-c062ecd2d064","name":"LawsuitSublimit","Code__c":"LawsuitSublimit","Option_Value_Default__c":"001000","Option_Type__c":"Range","Coverage__c":"a0425000007aHdPAAU","Min_amt__c":"0","Max_amt__c":"5000000","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"363cdc7f-6f07-4b2b-a727-85e6ba25450d","name":"LawsuitRetention","Code__c":"LawsuitRetention","Option_Value_Default__c":"0","Option_Type__c":"Picklist","Coverage__c":"a0425000007aHdPAAU","Option_Picklist__c":["0"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"820e9c03-3563-4ded-b676-f682d8a190a7","Coverage__c":"a0425000007aHdOAAU","name":"Claim Expenses Outside the Limit Endorsement","Coverage_Code__c":"EndClaimExpense","Coverage_Premium__c":"12897.8319744","Override_Premium__c":"12898","nonProratedCoveragePremium":"12897.8319744","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"03683978-1693-47a7-bd7d-6e41972a9c0c","name":"Limit","Code__c":"ClaimExpenseLimit","Option_Value_Default__c":"100k - 100k","Option_Type__c":"Picklist","Coverage__c":"a0425000007aHdOAAU","Option_Picklist__c":["No Coverage","100k - 100k","100k - 300k","250k - 250k","250k - 500k","300k - 300k","300k - 500k","500k - 500k","500k - 1m","1m - 1m","1m - 2m","1m - 3m","2m - 2m","2m -5m","3m - 3m","3m - 5m","4m - 4m","5m - 5m","6m - 6m","7m - 7m","8m - 8m","9m - 9m","10m - 10m","11m - 11m","12m - 12m","13m - 13m","14m -14m","15m - 15m"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"bb120a5b-a2ce-4151-aa6a-00b04b0fe78f","name":"Retention","Code__c":"ClaimExpenseRetention","Option_Value_Default__c":"0","Option_Type__c":"Range","Coverage__c":"a0425000007aHdOAAU","Min_amt__c":"0","Max_amt__c":"99999999999","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"69c7bfdf-aba3-40f0-89c9-58628f6ec560","Coverage__c":"a0425000007aHdNAAU","name":"Antitrust Claim Defense Sublimit","Coverage_Code__c":"EndAntitrustClaim","Coverage_Premium__c":"2647.44","Override_Premium__c":"2647","nonProratedCoveragePremium":"2647.44","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"0b5b1b7c-ce31-4878-a9e9-1f4208c4ed0f","name":"AntitrustSublimit","Code__c":"AntitrustSublimit","Option_Value_Default__c":"001000","Option_Type__c":"Range","Coverage__c":"a0425000007aHdNAAU","Min_amt__c":"0","Max_amt__c":"5000000","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"51effa0a-8787-4464-8747-935b80b6180a","Coverage__c":"a0425000007aHdEAAU","name":"Mitigation Expense Coverage Endorsement","Coverage_Code__c":"MitigationExpense","Coverage_Premium__c":"1323.72","Override_Premium__c":"1324","nonProratedCoveragePremium":"1323.72","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"9aa6b175-288a-49e9-9212-b134a8814fbd","name":"Mitigation Limit","Code__c":"MitigaLimit","Option_Value_Default__c":"001000","Option_Type__c":"Range","Coverage__c":"a0425000007aHdEAAU","Min_amt__c":"0","Max_amt__c":"5000000","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"3ad723e3-7be4-48a8-b070-f748c34fa7e2","name":"Retention","Code__c":"MitgaDed","Option_Value_Default__c":"0","Option_Type__c":"Picklist","Coverage__c":"a0425000007aHdEAAU","Option_Picklist__c":["0"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"716cbff1-26b3-4575-9010-1fde604bdb1f","Coverage__c":"a0425000007aHdDAAU","name":"Media Liability Including Advertising","Coverage_Code__c":"EndMediaLiability","Coverage_Premium__c":"0.0","Override_Premium__c":"0","nonProratedCoveragePremium":"0.0","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"97c0c7bc-fd37-4fff-a6a6-364b341cac41","name":"Media Liability - Limit","Code__c":"MediaLiabilityLimit","Option_Value_Default__c":"No Coverage","Option_Type__c":"Picklist","Coverage__c":"a0425000007aHdDAAU","Option_Picklist__c":["No Coverage","100k - 100k","100k - 300k","250k - 250k","250k - 500k","300k - 300k","300k - 500k","500k - 500k","500k - 1m","1m - 1m","1m - 2m","1m - 3m","2m - 2m","2m -5m","3m - 3m","3m - 5m","4m - 4m","5m - 5m","6m - 6m","7m - 7m","8m - 8m","9m - 9m","10m - 10m","11m - 11m","12m - 12m","13m - 13m","14m -14m","15m - 15m"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"97a20fd7-80c2-4f8f-9414-3951dca5cc35","name":"Media Liability - Retention","Code__c":"MediaLiabilityDed","Option_Value_Default__c":"0","Option_Type__c":"Range","Coverage__c":"a0425000007aHdDAAU","Min_amt__c":"0","Max_amt__c":"99999999999","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"c732e5e1-14d3-4d8d-b4f4-3accbd558b34","Coverage__c":"a0425000007aHf7AAE","name":"Contingent PD only","Coverage_Code__c":"ContingentPD","Coverage_Premium__c":"1985.58","Override_Premium__c":"1986","nonProratedCoveragePremium":"1985.58","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"021fef56-6a52-4b5b-be7e-14f8046e2caa","name":"Contingent PD only - Limit","Code__c":"ContingentPDLimit","Option_Value_Default__c":"01000","Option_Type__c":"Range","Coverage__c":"a0425000007aHf7AAE","Min_amt__c":"0","Max_amt__c":"5000000","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"922ffd47-f8fb-4181-9919-ceff9fc8a1de","name":"Contingent PD only - Retention","Code__c":"ContingentPDDed","Option_Value_Default__c":"0","Option_Type__c":"Picklist","Coverage__c":"a0425000007aHf7AAE","Option_Picklist__c":["0"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"3149ce7d-289a-4a1a-9656-a3167a23480c","Coverage__c":"a0425000007aHf4AAE","name":"Contingent BIPD Endorsement","Coverage_Code__c":"ContigentBIPD","Coverage_Premium__c":"24183.434951999996","Override_Premium__c":"24183","nonProratedCoveragePremium":"24183.434951999996","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"49f190ed-3db5-4828-8848-a274e9b71a12","name":"Contingent BI/PD - Limit","Code__c":"ContigentBIPDLimit","Option_Value_Default__c":"100k - 100k","Option_Type__c":"Picklist","Coverage__c":"a0425000007aHf4AAE","Option_Picklist__c":["No Coverage","100k - 100k","100k - 300k","250k - 250k","250k - 500k","300k - 300k","300k - 500k","500k - 500k","500k - 1m","1m - 1m","1m - 2m","1m - 3m","2m - 2m","2m -5m","3m - 3m","3m - 5m","4m - 4m","5m - 5m","6m - 6m","7m - 7m","8m - 8m","9m - 9m","10m - 10m","11m - 11m","12m - 12m","13m - 13m","14m -14m","15m - 15m"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"cd82164e-80bd-4565-9858-3158d78c2a4c","name":"Contingent BI/PD - Retention","Code__c":"ContigentBIPDDed","Option_Value_Default__c":"0","Option_Type__c":"Range","Coverage__c":"a0425000007aHf4AAE","Min_amt__c":"0","Max_amt__c":"99999999999","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"0b9c1d87-35d5-4cac-b878-724241125366","Coverage__c":"a0425000007aIEzAAM","name":"Contingent BIPD Coverage Endorsement  Sublimit Only","Coverage_Code__c":"ContigentBIPDSub","Coverage_Premium__c":"24183.434951999996","Override_Premium__c":"24183","nonProratedCoveragePremium":"24183.434951999996","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"6141cbb0-b271-4fcf-9d9d-57c07004d0e0","name":"BIPD Endorsement Aggregate Limit","Code__c":"ContigentBIPDSublimit","Option_Value_Default__c":"100k - 100k","Option_Type__c":"Picklist","Coverage__c":"a0425000007aIEzAAM","Option_Picklist__c":["No Coverage","100k - 100k","100k - 300k","250k - 250k","250k - 500k","300k - 300k","300k - 500k","500k - 500k","500k - 1m","1m - 1m","1m - 2m","1m - 3m","2m - 2m","2m -5m","3m - 3m","3m - 5m","4m - 4m","5m - 5m","6m - 6m","7m - 7m","8m - 8m","9m - 9m","10m - 10m","11m - 11m","12m - 12m","13m - 13m","14m -14m","15m - 15m"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null}]}');
                        res.setStatusCode(200);
                        return res;
                        
                        }
                        }
                        
                        @isTest
                        public static void testInitData() {
                            Test.startTest();
                            NewEndorsementController.initData('','MPL Standalone','Cancelled',Date.today(),Date.today().addMonths(2));
                            NewEndorsementController.initData('','MPL Standalone','Cancelled',Date.today(),null);
                            List<PicklistOption> result = NewEndorsementController.getQuotesEdorsementCancelPicklist();
                            list<String> endorsementOperations = new list<String> ();
                            for(PicklistOption po : result){
                                endorsementOperations.add(po.value);
                            }
                            NewEndorsementController.getEndorsementOperationsHelpText(endorsementOperations);
                            Policy__c p = [Select Id from Policy__c limit 1];
                            NewEndorsementController.fetchPolicyExistQuts(p.Id);
                            NewEndorsementController.fetchErpProductInfo('MPL Standalone', '2021-08-08', 'Extension');
                            Test.stopTest();
                            System.assert(result!= null);
                            
                        }
                        
                        @isTest
                        public static void testRatingQuoteEndorsement() {
                            Quote quote = [SELECT id, Effective_Date__c FROM Quote LIMIT 1];
                            System.debug('Effective date: ' + quote.Effective_Date__c);
                            Test.startTest();
                            
                            Test.setMock(HttpCalloutMock.class, new WebServiceMockRatingImpl());
                            String result = NewEndorsementController.ratingQuoteEndorsement(quote.Id);
                            
                            Test.stopTest();
                            System.assert(result!= null);
                        }
                        
                        @isTest
                        public static void testBindQuoteEndorsement() {
                            Test.startTest();
                            Quote quote = [SELECT id FROM Quote LIMIT 1];
                            String result= NewEndorsementController.bindQuoteEndorsement(quote.Id,'2021-08-08','Non-Payment');
                            Policy__c policy = [SELECT id FROM Policy__c LIMIT 1];
                            Opportunity opp = [Select id from Opportunity limit 1];
                            NewEndorsementController.checkOpenQuotes('Test');
                            NewEndorsementController.checkEndorsementDate('Test','2021-08-08');
                            NewEndorsementController.getEndorsementReasons();
                            test.stopTest();
                            System.assertEquals('',result);
                        }
                        
                        @isTest
                        public static void testCreateNewEndorsement() {
                            Test.startTest();
                            GlobalStaticVar.byPassOpportunityTrigger = true;
                            Quote quote = [SELECT id,Status FROM Quote LIMIT 1];
                            Policy__c policy = [SELECT id FROM Policy__c LIMIT 1];
                            
                            
                            //NewEndorsementController.createNewEndorsement(policy.Id,'2021-08-08','Extension','Non-Payment', 'Cancellation','{"expDate":"2021-08-10", "ERP_Duration":"1 Year", "rateCharged":"100%", "brokerContact":""}');
                            // By pass trigger to insert quote
                            TriggerSettings__c settings = new TriggerSettings__c();
                            settings.BypassQuoteTrigger__c = true;
                            insert settings;
                            quote.Status = 'Bound';
                            update Quote;

                           
                            GlobalStaticVar.byPassOpportunityTrigger = true;
                            GlobalStaticVar.byPassCoverageLineItemTrigger = true;
                            // NewEndorsementController.createNewEndorsement(policy.Id,'2021-08-08','Amendment','Non-Payment', 'Cancellation','{"expDate":"2021-08-10", "ERP_Duration":"", "rateCharged":"", "brokerContact":""}');
                            
                            
                            GlobalStaticVar.byPassOpportunityTrigger = true;
                            GlobalStaticVar.byPassCoverageLineItemTrigger = true;
                            NewEndorsementController.ResultWrapper result = NewEndorsementController.createNewEndorsement(policy.Id,'2021-08-08','Midterm Cancellation','Non-Payment', 'Cancellation','{"expDate":"2021-08-10", "ERP_Duration":"1 Year", "rateCharged":"100%", "brokerContact":""}');
                            //NewEndorsementController.ResultWrapper result1 = NewEndorsementController.createNewEndorsement(policy.Id,'2021-08-08','Midterm Cancellation','Non-Payment', 'Cancellation','2021-08-10');
                            NewEndorsementController.AccountWrapper naObj = new NewEndorsementController.AccountWrapper();
                            naObj.accId = 'TEST';
                            naObj.name = 'TEST';
                            naObj.dunsNumber = 'TEST';
                            naObj.billingStreet = 'TEST';
                            naObj.type = 'TEST';
                            result.accList.add( naObj );
                            GlobalStaticVar.byPassOpportunityTrigger = true;
                            GlobalStaticVar.byPassQuoteTrigger = true;
                            NewEndorsementController.showQuotes(policy.Id, '2021-08-08', 'Extension');
                            
                            NewEndorsementController.fetchErpProductInfo('MPL Standalone', '2021-08-08', 'Extension');
                            
                            Test.stopTest();
                            System.assert(settings != null);
                            System.assertEquals('Bound',quote.Status);
                        }
                         
                        @isTest
                        public static void testCreateNewEndorsementBORCase1() {
                            Test.startTest();
                            Quote quote = [SELECT id,Status FROM Quote LIMIT 1];
                            Policy__c policy = [SELECT id FROM Policy__c LIMIT 1];
                            Contact contactBroker1 = [SELECT Id FROM Contact WHERE Email='test1@broker.com' LIMIT 1];
                            Contact contactBroker2 = [SELECT Id FROM Contact WHERE Email='test2@broker.com' LIMIT 1];
                            Contact contactBroker3 = [SELECT Id FROM Contact WHERE Email='test3@broker.com' LIMIT 1];
                            
                            GlobalStaticVar.byPassOpportunityTrigger = true;
                            // By pass trigger to insert quote
                            TriggerSettings__c settings = new TriggerSettings__c();
                            settings.BypassQuoteTrigger__c = true;
                            insert settings;
                            quote.Status = 'Bound';
                            update Quote;
                            
                            NewEndorsementController.ResultWrapper result = NewEndorsementController.createNewEndorsement(policy.Id,'2021-08-08','Broker on Record Change','', '','{"expDate":"", "ERP_Duration":"", "rateCharged":"", "brokerContact":"'+contactBroker1.Id+'"}');

                            NewEndorsementController.AccountWrapper naObj = new NewEndorsementController.AccountWrapper();
                            naObj.accId = 'TEST';
                            naObj.name = 'TEST';
                            naObj.dunsNumber = 'TEST';
                            naObj.billingStreet = 'TEST';
                            naObj.type = 'TEST';
                            result.accList.add( naObj );

                            NewEndorsementController.showQuotes(policy.Id, '2021-08-08', 'Extension');
                            Test.stopTest();
                            System.assert(settings != null);
                            System.assertEquals('Bound',quote.Status);
                        }
                        @isTest
                        public static void testCreateNewEndorsementBORCase2() {
                            Test.startTest();
                            Quote quote = [SELECT id,Status FROM Quote LIMIT 1];
                            Policy__c policy = [SELECT id FROM Policy__c LIMIT 1];
                            Contact contactBroker1 = [SELECT Id FROM Contact WHERE Email='test1@broker.com' LIMIT 1];
                            Contact contactBroker2 = [SELECT Id FROM Contact WHERE Email='test2@broker.com' LIMIT 1];
                            Contact contactBroker3 = [SELECT Id FROM Contact WHERE Email='test3@broker.com' LIMIT 1];
                            
                            GlobalStaticVar.byPassOpportunityTrigger = true;
                            // By pass trigger to insert quote
                            TriggerSettings__c settings = new TriggerSettings__c();
                            settings.BypassQuoteTrigger__c = true;
                            insert settings;
                            quote.Status = 'Bound';
                            update Quote;
                            
                            NewEndorsementController.ResultWrapper result = NewEndorsementController.createNewEndorsement(policy.Id,'2021-08-08','Broker on Record Change','', '','{"expDate":"", "ERP_Duration":"", "rateCharged":"", "brokerContact":"'+contactBroker2.Id+'"}');

                            NewEndorsementController.AccountWrapper naObj = new NewEndorsementController.AccountWrapper();
                            naObj.accId = 'TEST';
                            naObj.name = 'TEST';
                            naObj.dunsNumber = 'TEST';
                            naObj.billingStreet = 'TEST';
                            naObj.type = 'TEST';
                            result.accList.add( naObj );

                            NewEndorsementController.showQuotes(policy.Id, '2021-08-08', 'Extension');
                            Test.stopTest();
                            System.assert(settings != null);
                            System.assertEquals('Bound',quote.Status);
                        }
                        @isTest
                        public static void testCreateNewEndorsementBORCase3() {
                            Test.startTest();
                            Quote quote = [SELECT id,Status FROM Quote LIMIT 1];
                            Policy__c policy = [SELECT id FROM Policy__c LIMIT 1];
                            Contact contactBroker1 = [SELECT Id FROM Contact WHERE Email='test1@broker.com' LIMIT 1];
                            Contact contactBroker2 = [SELECT Id FROM Contact WHERE Email='test2@broker.com' LIMIT 1];
                            Contact contactBroker3 = [SELECT Id FROM Contact WHERE Email='test3@broker.com' LIMIT 1];
                         
                            GlobalStaticVar.byPassOpportunityTrigger = true;
                            // By pass trigger to insert quote
                            TriggerSettings__c settings = new TriggerSettings__c();
                            settings.BypassQuoteTrigger__c = true;
                            insert settings;
                            quote.Status = 'Bound';
                            update Quote;
                            
                            NewEndorsementController.ResultWrapper result = NewEndorsementController.createNewEndorsement(policy.Id,'2021-08-08','Broker on Record Change','', '','{"expDate":"", "ERP_Duration":"", "rateCharged":"", "brokerContact":"'+contactBroker3.Id+'"}');

                            NewEndorsementController.AccountWrapper naObj = new NewEndorsementController.AccountWrapper();
                            naObj.accId = 'TEST';
                            naObj.name = 'TEST';
                            naObj.dunsNumber = 'TEST';
                            naObj.billingStreet = 'TEST';
                            naObj.type = 'TEST';
                            result.accList.add( naObj );

                            NewEndorsementController.showQuotes(policy.Id, '2021-08-08', 'Extension');
                            Test.stopTest();
                            System.assert(settings != null);
                            System.assertEquals('Bound',quote.Status);
                        }

                        @isTest
                        public static void testshowQuotes() {
                            Test.startTest();
                            GlobalStaticVar.byPassOpportunityTrigger = true;
                            Quote quote = [SELECT id,Status FROM Quote LIMIT 1];
                            Policy__c policy = [SELECT id FROM Policy__c LIMIT 1];
                                                  
                            // By pass trigger to insert quote
                            TriggerSettings__c settings = new TriggerSettings__c();
                            settings.BypassQuoteTrigger__c = true;
                            insert settings;
                            quote.Status = 'Bound';
                            update Quote;
                            
                            NewEndorsementController.showQuotes(policy.Id, '2021-08-08', 'Extension');
                            NewEndorsementController.showQuotes('', '2021-08-08', 'Extension');
                            NewEndorsementController.coverageCancelProcess('',Date.today(), '2021-10-08', policy.Id);
                            NewEndorsementController.coverageCancelProcess(quote.Id,Date.today(), '2021-10-08', policy.Id);
                           // NewEndorsementController.FullAmendmentCancelProcess(quote.id,Date.today(), '2021-10-08', policy.Id);
                            Test.stopTest();
                            System.assert(settings != null);
                            System.assertEquals('Bound',quote.Status);
                        }
                        
                        @isTest
                        public static void testEndorsementChangeDescription(){
                            Test.startTest();
                            NewEndorsementController.getEndorsementChangeDescription();
                            Test.stopTest();
                        }
                     
                        
}