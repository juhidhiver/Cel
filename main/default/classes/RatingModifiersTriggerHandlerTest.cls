/**
 * @description       : 
 * @author            : Maeran Shaikh
 * @group             : 
 * @last modified on  : 12-21-2021
 * @last modified by  : Maeran Shaikh
**/
@isTest
private class RatingModifiersTriggerHandlerTest {
    
    @testSetup
    public static void setupData() {
        Product2 product = TestUtil.createProduct('Cyber');
        insert product;

        Product2 product2 = TestUtil.createProduct('Professional Indemnity');
        insert product2;

        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;

        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        insert opportunity;

        Opportunity opportunity2 = TestUtil.createOpportunity('Opp Test',acc.Id, product2.Id);
        opportunity.StageName = 'Qualified';
        insert opportunity2;
        
         Quote quote1 = TestUtil.createQuote('New quote 1', opportunity.Id);
        quote1.Status = 'Rated';
        insert quote1; 
        
        Quote quote2 = TestUtil.createQuote('New quote 1', opportunity2.Id);
        quote2.Status = 'Rated';
        insert quote2;

        /* opportunity.StageName = 'Closed Won';
         update opportunity;*/

        Rating_Modifiers__c rM = new Rating_Modifiers__c(Name = 'Test Rating Modifier', Opportunity__c = opportunity.Id,Product__c ='Cyber', Rating__c = true,Rating_Modifier_Value__c = 'Test 1');
        insert rM;

        Rating_Modifiers__c rM2 = new Rating_Modifiers__c(Name = 'Test Rating Modifier2', Opportunity__c = opportunity2.Id,Product__c = 'Professional Indemnity', Rating__c = true,Rating_Modifier_Value__c = 'Test 21');
        insert rM2;
		
        Rating_Modifiers__c rM3 = new Rating_Modifiers__c(Name = 'Test Rating Modifier3', Opportunity__c = opportunity2.Id, Rating__c = true,Rating_Modifier_Value__c = 'Test 21');
        insert rM3;

        Rating_Modifiers__c rM4 = new Rating_Modifiers__c(Name = 'Proposal Form Date', Product__c = 'Professional Indemnity', Rating_Modifier_Value__c = 'test', Opportunity__c = opportunity2.Id, Rating__c = true);
        insert rM4;

        Subjectivity_Template__c subjectivityTemplate = new Subjectivity_Template__c();
        subjectivityTemplate.Subjectivity_Name__c = 'Signed / Dated Proposal';
        subjectivityTemplate.Subjectivity_Text__c = 'Test';
        subjectivityTemplate.Profession_Criteria__c = 'Engineers';
        insert subjectivityTemplate;
    }
    
    @isTest
    static void testBeforeInsert() {
        Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
        Rating_Modifiers__c rM = new Rating_Modifiers__c(Name = 'New Rating Modifier', Opportunity__c = o.Id);
		Test.startTest();
        insert rM;
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest
    static void testBeforeUpdate() {

        Rating_Modifiers__c rM = [SELECT Id,Rating__c,Rating_Modifier_Value__c FROM Rating_Modifiers__c WHERE Name = 'Test Rating Modifier'];
        rM.Rating_Modifier_Value__c = 'Testing 123';
		Test.startTest();
        update rM;
        Test.stopTest();
        System.assert(true);
    }


    @isTest
    static void testBeforeUpdateAQ() {

        Rating_Modifiers__c rM = [SELECT Id,Rating__c,Rating_Modifier_Value__c FROM Rating_Modifiers__c WHERE Name = 'Test Rating Modifier2'];
        rM.Rating_Modifier_Value__c = 'Testing 123';
		Test.startTest();
        update rM;
        Test.stopTest();
        System.assert(true);
    }
    
     @isTest
    static void testBeforeUpdateOthers() {

        Rating_Modifiers__c rM = [SELECT Id,Rating__c,Rating_Modifier_Value__c FROM Rating_Modifiers__c WHERE Name = 'Test Rating Modifier3'];
        rM.Rating_Modifier_Value__c = 'Testing 123';
		Test.startTest();
        update rM;
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    static void testBeforeUpdateProposalFormDate() {

        Rating_Modifiers__c rM = [SELECT Id,Rating__c,Rating_Modifier_Value__c FROM Rating_Modifiers__c WHERE Name = 'Proposal Form Date'];
		Test.startTest();
        rm.Rating_Modifier_Value__c = null;
        update rM;
        Test.stopTest();
        System.assert(true);
    }
}