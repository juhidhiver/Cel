@isTest
public class AutoRenewalsEmailBatch_Test {
    public static testmethod void  test(){
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = true;
        setting.BypassAccountTrigger__c = true;
        setting.BypassProductTrigger__c = true;
        setting.BypassQuoteTrigger__c  = true;
        update setting;
       
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
		Account acc  =TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster',
												'California','90000', 'United States');
        insert acc;
        
         // Create contact
		Contact con = new Contact(
			Lastname = 'Test broker',
			RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId(),
            Role__c='Renewals',
            Email = 'abc@gmail.com',
            AccountId = acc.Id
		);
		insert con;
        
        Product2 product = TestUtil.createProduct('D&O');
        insert product;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        opportunity.Main_Profession__c = 'Property Professionals';
        insert opportunity; 
      	
        List<Policy__c> policyList = new List<Policy__c>();
        Policy__c policy = new Policy__c();
        	policy.Account__c = acc.Id;
        	policy.Product_Name__c = 'Professional Indemnity';
        	policy.Expiration_Date__c = Date.today().addmonths(2);
        	policy.Total_Premium__c = 2000;
        	policy.Initial_Premium__c = null;
        	policy.Policy_Status__c = 'Bound';        	
        	policyList.add(policy);
        
        	Policy__c policy1 = new Policy__c();
        	policy1.Account__c = acc.Id;
        	policy1.Product_Name__c = 'Professional Indemnity';
        	policy1.Expiration_Date__c = Date.today().addmonths(2);
        	policy1.Total_Premium__c = 2000;
        	policy1.Initial_Premium__c = null;
        	policy1.Policy_Status__c = 'Bound';
        	policyList.add(policy1);
        insert policyList;
        
        Quote quote = TestUtil.createQuote('Quote Test',opportunity.Id);
        quote.Azure_ID__c = 'Test Az 1';
        quote.Policy__c = policy.Id;
        quote.Status = 'Bound';
        quote.Layer__c = 'Primary';
        insert quote;
        
         Quote quote1 = TestUtil.createQuote('Quote Test1',opportunity.Id);
        quote1.Azure_ID__c = 'Testaz2';
        quote1.Policy__c = policy1.Id;
        quote1.Status = 'Bound';
        quote1.Layer__c = 'Primary';
        insert quote1;
        
        // Create broker
		Broker_Account__c broketAccount = new Broker_Account__c(
			Broker_Contact__c = con.Id,
			Opportunity__c = opportunity.Id,
			IsPrimaryBroker__c = true,
			Relationship_Type__c = 'Broker'
		);
		insert broketAccount;
        
            //Create coverage
        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'Professional Indemnity');
        cov.Coverage_Type__c = 'Endorsement';
        insert cov;
        
         // Coverages Line Item
         CoveragesLineItem__c coverLi = new CoveragesLineItem__c();
         coverLi.Coverage__c  = cov.Id; 
         coverLi.Quote__c = quote.Id;
         coverLi.Coverage_Premium__c  = 'Text Premium'; 
         coverLi.Min_amt__c  = 1000;
         coverLi.Max_amt__c  = 5000;
         coverLi.Deductible_Frequency__c  = 'Daily';
         coverLi.Options_Value_Percent__c  = 5;
         coverLi.Parent_Coverages_Line_Item__c = null; 
         coverLi.Form_Number__c = 'AQUW153';
         insert coverLi;
        
        Claim_Data__c cd = new Claim_Data__c();
        cd.Account__c = acc.id;
        cd.Policy__c  = policy.id;
        cd.Claim_status__c = 'Test Status';
        cd.Indemnity_Paid__c = 10000.7;
        cd.Fees_Paid__c = 2000.66;
        cd.Fees_Reserve__c = 3000.24;
        cd.Indemnity_Reserve__c = 4000.11;
        cd.TPA_Fees__c = 1223.11;
        insert cd;
        
        Quote_Option__c quoteOpt = new Quote_Option__c();
        quoteOpt.Azure_ID__c = 'Test 1';
        quoteOpt.Quote__c =  quote.Id;
        quoteOpt.Bound__c = true;
        insert quoteOpt;
        
       	Rating_Modifiers__c ratingModifier = TestUtil.createRatingModifier('Is the business regulated by the Royal Institution of Chartered Surveyors?', 'Professional Indemnity', opportunity.Id);
        ratingModifier.Rating_Modifier_Value__c ='YES';
        insert ratingModifier;
        
        Payment_Data__c paymentData = new  Payment_Data__c();
        paymentData.Policy__c = policy.Id ; 
        paymentData.Quote__c = quote.id;
        paymentData.Paid_Status__c = 'Not Paid';        
        paymentData.Last_Modified_Date__c = System.now();
        insert paymentData;
        
        String RecordTypeIdREN = Schema.SObjectType.Renewal__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Renewal__c rn = new Renewal__c(
        Broker__c = broketAccount.id,
        Policy__c = policy.Id,
        recordtypeId = RecordTypeIdREN,
        status__c= 'Ready to Send',
        Documents_Required__c = 'Accountants Proposal Form;Accountants Renewal Declaration Form');
        insert rn;
        
        // rn.status__c= 'Ready to Send';
        // update rn;
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
        Group grp = new Group();
        grp.name = 'Admin Renewals';
        grp.Type = 'Regular'; 
        Insert grp;
        
        //Create Group Member
        GroupMember grpMem1 = new GroupMember();
        grpMem1.UserOrGroupId = UserInfo.getUserId();
        grpMem1.GroupId = grp.Id;
        Insert grpMem1;
        }

        Test.startTest();
        AutoRenewalsEmailBatch b = new AutoRenewalsEmailBatch(true, Date.today(), 'Professional Indemnity');
        database.executebatch(b,2);
        Test.stopTest();
    }
}