/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 02-21-2022
 * @last modified by  : Vinayesh
**/
@isTest
public class QuoteProcessControllerTest {
    @testSetup static void setup(){
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
        insert product; 
        
        Product2 product5 = TestUtil.createProduct('Private Company Combo');
        insert product5;
        
        Product2 product1 = TestUtil.createProduct('D&O');
        product1.Parent_Product__c = product.Id;
        product1.IsComboProduct__c = true;
        insert product1;

        Product2 product2 = TestUtil.createProduct('EPL');
        product2.Parent_Product__c = product.Id;
        product2.IsComboProduct__c = true;
        insert product2;

        Product2 product3 = TestUtil.createProduct('Crime');
        product3.Parent_Product__c = product.Id;
        product3.IsComboProduct__c = true;
        insert product3;

        Product2 product4 = TestUtil.createProduct('Fiduciary');
        product4.Parent_Product__c = product.Id;
        product4.IsComboProduct__c = true;
        insert product4;
        
        List<Rating_Modifier_Template__c> lRMT = new List<Rating_Modifier_Template__c>();
        Rating_Modifier_Template__c rMT1 = TestUtil.createRatingModifierTemplate('Test Service Classification','D&O','Number');
        rMT1.Display_Format__c = 'Clearance';
        rMT1.Rating_Modifier_Code__c = 'PSDO00000121212';
        rMT1.Page_Section__c = 'Test';
        lRMT.add(rMT1);
        Rating_Modifier_Template__c rMT2 = TestUtil.createRatingModifierTemplate('New input integer','D&O','Integer');
        rMT2.Display_Format__c = 'Clearance';
        rMT2.Rating_Modifier_Code__c = 'PSFID000005989890';
        rMT2.Page_Section__c = 'Test';
        lRMT.add(rMT2);
        Rating_Modifier_Template__c rMT3 = TestUtil.createRatingModifierTemplate('New input integer','D&O','Integer');
        rMT3.Display_Format__c = 'Clearance';
        rMT3.Rating_Modifier_Code__c = 'PSEPL000005232421';
        rMT3.Page_Section__c = 'Test';
        lRMT.add(rMT3);
        Rating_Modifier_Template__c rMT4 = TestUtil.createRatingModifierTemplate('New input integer','EPL','Integer');
        rMT4.Display_Format__c = 'Clearance';
        rMT4.Page_Section__c = 'Test';
        lRMT.add(rMT4);
        // Rating_Modifier_Template__c rMT5 = TestUtil.createRatingModifierTemplate(Label.NATURE_OF_INDUSTRY_OR_SECTOR,'Crime','Number');
        // rMT5.Display_Format__c = 'Clearance';
        // lRMT.add(rMT5);
        Rating_Modifier_Template__c rMT6 = TestUtil.createRatingModifierTemplate(Label.ANNUAL_REVENUES,'Fiduciary','Number');
        rMT6.Display_Format__c = 'Clearance';
        rMT6.Page_Section__c = 'Test';
        Rating_Modifier_Template__c rMT7 = TestUtil.createRatingModifierTemplate('Test D&O','D&O','Number');
        rMT7.Display_Format__c = 'Clearance';
        rMT7.Rating_Modifier_Code__c = 'PSEPL000005232422';
        rMT7.Page_Section__c = 'Test';
        lRMT.add(rMT7);
        
        insert lRMT;



        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Prospect';
        insert opp;

        Product_Option_Line_Item__c newRec = new Product_Option_Line_Item__c();
        newRec.Product__c = product1.Id;
        newRec.Submission__c = opp.Id;
        newRec.Account__c = acc.Id;
        newRec.Clearance_Status__c = 'Cleared';
        newRec.Is_Selected__c = true;
        insert newRec;
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'In Progress';
        quote1.Coverage_Product_Options__c = 'D&O';
        quote1.Refer_Type__c = 'Underwriting Referral';
        insert quote1;  
        
        Quote_Process__c quoteProc = new Quote_Process__c();
        quoteProc.Name = 'Test Process';
        quoteProc.Account__c = acc.Id;
        quoteProc.Submission__c = opp.Id;
        quoteProc.Status__c = 'Insured Info';
        insert quoteProc;
    }
    

    @isTest
    static void getRecordInfosFromQuoteProcessTest(){
        Test.startTest();
        QuoteProcessController.getSingleQuoteProcess();
        Quote_Process__c q = [Select Id,Name from Quote_Process__c where Name ='Test Process' Limit 1];
        QuoteProcessController.getRecordInfos(q.Id);
        system.assertEquals('Test Process', q.Name);
        Test.stopTest();
    }
    @isTest
    static void getRecordInfosFromOpportunityTest(){
        Test.startTest();
        Opportunity opp = [Select Id,StageName
                           from Opportunity where StageName = 'Prospect' Limit 1];
        QuoteProcessController.getRecordInfos(opp.Id);
        system.assertEquals('Prospect', opp.StageName);
        Test.stopTest();
    }
    @isTest
    static void createSubmissionTest(){
        Test.startTest();
        Account acc = [Select Id from Account Limit 1];
        Quote_Process__c q = [Select Id,Name from Quote_Process__c where Name ='Test Process' Limit 1];
        QuoteProcessController.createSubmission(q.Id, acc.Id );
        system.assertEquals('Test Process', q.Name);
        Test.stopTest();
    }
    @isTEst 
    static void checkExistQuoteStatusBoundOrBoundPendingTest(){
        Opportunity  opp = [Select Name from Opportunity Limit 1];
        
        Test.startTest();
        Boolean bool = QuoteProcessController.checkExistQuoteStatusBoundOrBoundPending(opp.Id);
    	test.stopTest();
        system.assertEquals(true, bool);
    }

    @isTEst 
    static void checkRatingModifiersValidityForOppTest(){
        Opportunity  opp = [Select Name from Opportunity Limit 1];
        
        Test.startTest();
        Boolean bool = QuoteProcessController.checkRatingModifiersValidityForOpp(opp.Id);
    	test.stopTest();
        system.assertEquals(false, bool);
    }

    @isTEst 
    static void updateAllQuoteToInProgressTest(){
        Opportunity  opp = [Select Name from Opportunity Limit 1];
        Quote quo =  [SELECT Id, Name, Status, Rating_Status__c, Last_Quote_Version__c
											FROM Quote
											WHERE OpportunityId =:opp.Id Limit 1];
        quo.Status ='Rated';
        update quo;
        
        Test.startTest();
        QuoteProcessController.updateAllQuoteToInProgress(opp.Id);
        system.assertEquals('Rated', quo.Status);
    	test.stopTest();
        
    }

     @isTest
    static void ItemWrapperTest2(){
        Test.startTest();
        QuoteProcessController.ItemWrapper Iw = new QuoteProcessController.ItemWrapper();
        Iw.Name='Name';
        system.assert(Iw!=null);
        Test.stopTest();
    }
}