@isTest
public class RatingRequestTest {
 	@testsetup static void testSetup(){
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.BypassCoverageLineItemTrigger__c = true;
        ts.BypassQuoteTrigger__c = true;
        insert ts;
        Account acc = TestUtil.createBusinessAccount('Business Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
		insert acc;
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
		insert product; 

        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Closed Won';
    	opp.Expiration_Date__c = Date.today()+60;
        insert opp;
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'In Progress';
        quote1.Coverage_Product_Options__c = 'D&O';
     	quote1.Refer_Type__c = 'Underwriting Referral';
    	quote1.Tax = 222000;
        insert quote1;  

		Quote quote2 = Testutil.createQuote('New Quote 2', opp.Id);
        quote2.Status = 'Bound';
        quote2.Coverage_Product_Options__c = 'D&O';
        quote2.Refer_Type__c = 'Underwriting Referral';
    	quote2.Tax = 2122000;
        insert quote2;
        
        
        Quote childQuote = TestUtil.createQuote('New child quote', opp.Id);
        childQuote.Status = 'In Progress';
        childQuote.Quote_Type__c = 'Amendment';
        childQuote.Coverage_Product_Options__c = 'D&O';
        childQuote.Refer_Type__c = 'Underwriting Referral';
        childQuote.Tax = 222000;
        childQuote.Parent_Quote__c = quote1.Id;
        insert childQuote; 
        

        
        Coverage__c cov = TestUtil.createCoverage('Test Coverage 1', 'D&O');
        cov.Rating__c = True;
        insert cov;
        
        Coverage__c cov2 = TestUtil.createCoverage('Test Coverage 1', 'D&O');
        cov2.RecordTypeId = Schema.SObjectType.Coverage__c.getRecordTypeInfosByName().get('Sub Coverage').getRecordTypeId();
        cov2.Coverage_or_Sub__c = cov.Id;
        insert cov2;
        
        Coverage_Limits_Deductibles__c covLd = TestUtil.creatLimitsDeductibles('Test Ld', cov.id);
        insert covLd;
        
        CoveragesLineItem__c covLineItem = TestUtil.createCoverageLineItem(quote1.Id, covLd.id, cov.Id, 'Picklist');
        covLineItem.Sub_Coverage__c = cov2.Id;
		//covLineItem.Rating__c = True;
        insert covLineItem;
        
        Rating_Modifiers__c rateMod = TestUtil.createRatingModifier('Test Rate Modifier 1', 'MPL', opp.Id);
        insert rateMod;
        
        Rating_Modifier_Factor__c rateFactor = new Rating_Modifier_Factor__c();
        rateFactor.Rating_Modifier__c = rateMod.Id;
        rateFactor.Quote__c = quote1.Id;
        rateFactor.Factor_Default_Value__c=82.866;
        rateFactor.Factor_Value__c=76.324;
        rateFactor.Factor_Max__c=3.588;
        rateFactor.Factor_Min__c=43.539;
        insert rateFactor;
        
        Account_Loss_Detail__c accountLoss = new Account_Loss_Detail__c();
        accountLoss.Account__c = acc.Id;
        accountLoss.Product__c = 'Cyber';
        accountLoss.Loss_Amount__c = 123;
        accountLoss.Status__c = 'Open';
        accountLoss.Year__c = '2020';
        accountLoss.Number_of_Losses__c = 23;
        insert accountLoss;
        
        Submission_Loss_Detail__c subLoss = new Submission_Loss_Detail__c();
        subLoss.Submission__c = opp.Id;
    	subLoss.Loss_Amount__c = 22200;
        subLoss.Status__c = 'Open';
        subLoss.Year__c ='2019';
        subLoss.Number_of_Losses__c=2;
        subLoss.Account_Loss_Detail__c = accountLoss.Id;
        insert subLoss;
    }
    
    @isTest
    static void getRatingRequestTest(){
        Test.startTest();
        Quote q = [Select Id from Quote Limit 1];
		Opportunity opp = [Select Id from Opportunity Limit 1];
        
       RatingRequest result = new RatingRequest();
        result = RatingRequest.getRatingRequest(q.id, opp.id);       
        Test.stopTest();
        system.assert(result != null);
    }
    
    @isTest
    static void getRatingRequestTest2(){
        Test.startTest();
         Account acc = TestUtil.createBusinessAccount('Business Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
		insert acc;
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
		insert product; 

        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Closed Won';
    	opp.Expiration_Date__c = Date.today()+60;
        insert opp;
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'In Progress';
        quote1.Coverage_Product_Options__c = 'D&O';
     	quote1.Refer_Type__c = 'Underwriting Referral';
    	quote1.Tax = 222000;
        insert quote1;  

		Quote quote2 = Testutil.createQuote('New Quote 2', opp.Id);
        quote2.Status = 'Bound';
        quote2.Coverage_Product_Options__c = 'D&O';
        quote2.Refer_Type__c = 'Underwriting Referral';
    	quote2.Tax = 2122000;
        insert quote2;
        
        Coverage__c cov = TestUtil.createCoverage('Test Coverage 1', 'D&O');
        cov.Rating__c = True;
        insert cov;
        
        Coverage__c cov2 = TestUtil.createCoverage('Test Coverage 1', 'D&O');
        cov2.RecordTypeId = Schema.SObjectType.Coverage__c.getRecordTypeInfosByName().get('Sub Coverage').getRecordTypeId();
        cov2.Coverage_or_Sub__c = cov.Id;
        insert cov2;
        
        Coverage_Limits_Deductibles__c covLd = TestUtil.creatLimitsDeductibles('Test Ld', cov.id);
        covLd.RecordTypeId =Schema.SObjectType.Coverage_Limits_Deductibles__c.getRecordTypeInfosByName().get('Limit Option').getRecordTypeId();
        insert covLd;
        
        CoveragesLineItem__c covLineItem = TestUtil.createCoverageLineItem(quote1.Id, covLd.id, cov.Id, 'Picklist');
        covLineItem.Sub_Coverage__c = cov2.Id;
		//covLineItem.Rating__c = True;
        insert covLineItem;
        
        Rating_Modifiers__c rateMod = TestUtil.createRatingModifier('Test Rate Modifier 1', 'MPL', opp.Id);
        insert rateMod;
        
        Rating_Modifier_Factor__c rateFactor = new Rating_Modifier_Factor__c();
        rateFactor.Rating_Modifier__c = rateMod.Id;
        rateFactor.Quote__c = quote1.Id;
        rateFactor.Factor_Default_Value__c=82.866;
        rateFactor.Factor_Value__c=76.324;
        rateFactor.Factor_Max__c=3.588;
        rateFactor.Factor_Min__c=43.539;
        insert rateFactor;
        
        Account_Loss_Detail__c accountLoss = new Account_Loss_Detail__c();
        accountLoss.Account__c = acc.Id;
        accountLoss.Product__c = 'Cyber';
        accountLoss.Loss_Amount__c = 123;
        accountLoss.Status__c = 'Open';
        accountLoss.Year__c = '2020';
        accountLoss.Number_of_Losses__c = 23;
        insert accountLoss;
        
        Submission_Loss_Detail__c subLoss = new Submission_Loss_Detail__c();
        subLoss.Submission__c = opp.Id;
    	subLoss.Loss_Amount__c = 22200;
        subLoss.Status__c = 'Open';
        subLoss.Year__c ='2019';
        subLoss.Number_of_Losses__c=2;
        subLoss.Account_Loss_Detail__c = accountLoss.Id;
        insert subLoss;
        
        RatingRequest.PriorLimitItem ps = new RatingRequest.PriorLimitItem(covLineItem);
        RatingRequest.PriorCoverageItem pci = new RatingRequest.PriorCoverageItem(covLineItem);
        RatingRequest.CoverageItem ci = new RatingRequest.CoverageItem(covLineItem);
        RatingRequest.CoverageItem ci1 = new RatingRequest.CoverageItem();
        RatingRequest.SubCoverageItem sci = new RatingRequest.SubCoverageItem(covLineItem);
        RatingRequest.SubCoverageItem sci1 = new RatingRequest.SubCoverageItem();
        RatingRequest.LimitItem li = new RatingRequest.LimitItem(covLineItem);
        RatingRequest.LimitItem li1 = new RatingRequest.LimitItem();
        RatingRequest.DeductibleItem di = new RatingRequest.DeductibleItem(covLineItem);
        RatingRequest.DeductibleItem di1 = new RatingRequest.DeductibleItem();
        
        
        
        //RatingRequest.generateLimitDeductible(new List<CoveragesLineItem__c>{covLineItem});
        
        
        RatingRequest result = new RatingRequest();
        result = RatingRequest.getRatingRequest(quote1.id, opp.id);        
        Test.stopTest();
        system.assert(result != null);
    }
    
    @isTest
    static void getRatingRequestTestforException(){
        Test.startTest();
        Quote q = [Select Id from Quote Limit 1];
		Opportunity opp = [Select Id from Opportunity Limit 1];
       
        try{
           RatingRequest.getRatingRequest('111', '22');
        }
        catch(Exception ex){
            System.assert(ex.getMessage()!=null);
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testgetRatingRequest(){
        Quote childQuote = [Select Id from Quote where Name = 'New child quote' Limit 1];
        Opportunity opp = [Select Id from Opportunity Limit 1];        
        Test.startTest();
        RatingRequest result = RatingRequest.getRatingRequest(childQuote.Id, opp.Id);
     	RatingRequest.QuoteWrapper resultQuote = new RatingRequest.QuoteWrapper();
        resultQuote = result.quote;        
        Test.stopTest();
        system.assertEquals('New child quote', resultQuote.quoteName);
    }
    
    @isTest
    static void testgetBoundQuote(){
        Quote childQuote = [Select Id from Quote where Name = 'New child quote' Limit 1];
        Opportunity opp = [Select Id from Opportunity Limit 1];
        Test.startTest();
        Quote quote = RatingRequest.getBoundQuote(childQuote.Id);       
        Test.stopTest();
        system.assertEquals(childQuote.Id, quote.Id);
    }
    
    @isTest
    static void testgetPriorCoverageLineItem2(){
        Quote childQuote = [Select Id from Quote where Name = 'New child quote' Limit 1];
        Opportunity opp = [Select Id from Opportunity Limit 1];
        Test.startTest();
        List<CoveragesLineItem__c> covList = RatingRequest.getPriorCoverageLineItem2(childQuote.Id);                
        Test.stopTest();
        system.assertEquals('Test Coverage 1', covList[0].Coverage__r.Name);
    }
    


   
}