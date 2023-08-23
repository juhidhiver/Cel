/**************************************************************************************************
* Class Name: OpportunityModifiersCmpControllerTest
* Modified By : Ashik Zahir
* Modified Date: 15-Feb-2021
* Description: Unit test for OpportunityModifiersCmpController
**************************************************************************************************/
@isTest
public class OpportunityModifiersCmpControllerTest {
    @testSetup
    public static void setup() {
        TriggerSettings__c setting = new TriggerSettings__c();
        setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        setting.BypassRatingModifiersTrigger__c = true;
        insert setting;
        
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
        
        Policy__c policy = new Policy__c();
        policy.Account__c = acc1.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);
        insert policy;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc1.Id, product.Id);
        opportunity.Policy__c = policy.Id;
        opportunity.Coverage_Product_Options__c='MPL';
        insert opportunity;
        
        //Create Rating_Modifier_Template__c list
        List<Rating_Modifier_Template__c> listRatingModifierTemp = new List<Rating_Modifier_Template__c>();
        Rating_Modifier_Template__c ratingModifiersTemp1 = TestUtil.createRatingModifierTemplate('Input number field', product.Name , 'Number');
        ratingModifiersTemp1.Rating_Modifier_Code__c = 'MPL000025';
        Rating_Modifier_Template__c ratingModifiersTemp2 = TestUtil.createRatingModifierTemplate('Input number field', 'MPL' , 'Integer');
        listRatingModifierTemp.add(ratingModifiersTemp1);
        listRatingModifierTemp.add(ratingModifiersTemp2);
        insert listRatingModifierTemp;
        
        //Create Eligibility Status
        Eligibility_Status__c es = new Eligibility_Status__c();
        es.Rating_Modifier_Template__c = listRatingModifierTemp[0].Id;
        es.Rating_Modifier_Value__c = 'Yes';
        es.Eligibility_Status__c = 'Proceed';
        es.Modifier_Product__c = 'MPL';
        insert es;
        
        
        //Create Rating_Modifiers__c list
        List<Rating_Modifiers__c> lstRatingModifier = new List<Rating_Modifiers__c>();
        Rating_Modifiers__c ratingModifier1 = TestUtil.createRatingModifier('Rating field test1', product.Name, opportunity.Id);
        ratingModifier1.Rating_Modifier_Code__c = 'MPL000025';
        ratingModifier1.Display_Format__c = 'Primary Modifiers';
        ratingModifier1.Opportunity__c = opportunity.Id;
        ratingModifier1.Rating_Modifier_Value__c = 'Yes';
        ratingModifier1.Page_Section__c = 'Pros and Cons';
        ratingModifier1.Format__c = 'Picklist';
        ratingModifier1.Picklist_Values__c = 'At least one very restrictive endorsement;At least one restrictive endorsement and no very restrictive endorsements;No restrictive endorsement';
        Rating_Modifiers__c ratingModifier2 = TestUtil.createRatingModifier('Rating field test2', 'MPL', opportunity.Id);
        ratingModifier2.Display_Format__c = 'Pros and Cons';
        ratingModifier2.Rating_Modifier_Value__c = '27';
        ratingModifier2.Rating_Modifier_Code__c = 'MPL000004';
        ratingModifier2.Page_Section__c = 'Industry Class';
        ratingModifier2.Sub_Section__c = 'Company Info'; 
        ratingModifier2.Opportunity__c = opportunity.Id;
        ratingModifier2.Format__c = 'Percentage';
        lstRatingModifier.add(ratingModifier1);
        lstRatingModifier.add(ratingModifier2);
        
        for(Integer i=0;i<5;i++) {
            Rating_Modifiers__c ratingModifier = TestUtil.createRatingModifier('Rating field test'+String.valueOf(i+5),'MPL', opportunity.Id);                 
            ratingModifier.Rating_Modifier_Code__c = 'MPL0000'+String.ValueOf((i+20));
            
            ratingModifier.Opportunity__c = opportunity.Id;
            ratingModifier.Rating_Modifier_Value__c = '27';
            ratingModifier.Page_Section__c = 'Pros and Cons';
            if(i==0) {
                ratingModifier.Sub_Section__c = 'Company Info';  
                ratingModifier.Format__c = 'Currency';
                ratingModifier.Display_Format__c = 'Primary Modifiers';  
            } else if(i==1) {
                ratingModifier.Format__c = 'Integer';
                ratingModifier.Display_Format__c = 'Primary Modifiers';  
            } else if(i==2) {
                ratingModifier.Format__c = 'Number';
                ratingModifier.Display_Format__c = 'Primary Modifiers';
            } else if(i==3) {
                ratingModifier.Format__c = 'Text';
                ratingModifier.Display_Format__c = 'Primary Modifiers';
                ratingModifier.Profile_Name_for_Read_Only__c = 'Celerity Senior Underwriter';  
            } else if(i==4) {
                ratingModifier.Display_Format__c = 'Primary Modifiers';
                ratingModifier.Profile_Name_for_Read_Only__c = 'All';  
            }
            
            lstRatingModifier.add(ratingModifier);
        }
        insert lstRatingModifier;
        
        Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote.Coverage_Product_Options__c ='MPL';
        quote.Policy__c = policy.Id;
        quote.OpportunityId=opportunity.Id;
        quote.Status = 'Rated';
        quote.Effective_Date__c = date.today();
        insert quote;
        
        Quote_Process__c qp = new Quote_Process__c();
        qp.Account__c = acc1.Id;
        qp.Submission__c = opportunity.Id;
        insert qp;
        
        Master_Binder__c masterBind =  new Master_Binder__c();
        masterBind.Name = 'masterBind Name';
        masterBind.Expiry_Date__c = Date.today()+365;
        masterBind.Inception_Date__c = Date.today();
        masterBind.MGA_Commission__c = 15;
        masterBind.Layer__c = 'Primary;Excess';
        masterBind.Coverholder_Name__c = ' masterBind Holder';
        masterBind.Coverholder_Pin__c = 'masterBind Pin';
        insert masterBind;
        
    }
    
    @isTest
    public static void testGetProductNameTabs() {
        Test.startTest();
        
        List<String> oppId = OpportunityModifiersCmpController.getProductNameTabs([SELECT id FROM Opportunity LIMIT 1].id);
        
        OpportunityModifiersCmpController.getProductNameTabsLwc([SELECT id FROM Opportunity LIMIT 1].id);
        Test.stopTest();
        System.assert(oppId != null);
    }
    
    @isTest
    public static void testSaveRecordTabLwc() {
        Test.startTest();
        Rating_Modifiers__c ratMod = [SELECT id,Name,Display_Format__c,Rating_Modifier_Code__c 
                                      FROM Rating_Modifiers__c 
                                      WHERE Name='Rating field test1' LIMIT 1];
        
        Rating_Modifiers__c ratModSubSec = [SELECT id,Name,Display_Format__c,Rating_Modifier_Code__c 
                                            FROM Rating_Modifiers__c 
                                            WHERE Name='Rating field test2' LIMIT 1];
        
        PicklistOption po = new PicklistOption('Test','Test');
        
        OpportunityModifiersCmpController.ItemWrapper itmWrp = new OpportunityModifiersCmpController.ItemWrapper();
        itmWrp.pickOptList = new List<PicklistOption>{po};
            itmWrp.strFactorMax = '20';
        itmWrp.strFactorMin = '10';
        itmWrp.item = ratMod;
        
        OpportunityModifiersCmpController.ItemWrapper itmWrpSubSec = new OpportunityModifiersCmpController.ItemWrapper();
        itmWrpSubSec.pickOptList = new List<PicklistOption>{po};
            itmWrpSubSec.strFactorMax = '30';
        itmWrpSubSec.strFactorMin = '20';
        itmWrpSubSec.item = ratModSubSec;
        
        OpportunityModifiersCmpController.SectionItem sI = new OpportunityModifiersCmpController.SectionItem();
        sI.name = 'Account Info';
        sI.items = new List<OpportunityModifiersCmpController.ItemWrapper>{itmWrp};
            
            OpportunityModifiersCmpController.SectionItem subSecItem = new OpportunityModifiersCmpController.SectionItem();
        subSecItem.name = 'Contact Info';
        subSecItem.items = new List<OpportunityModifiersCmpController.ItemWrapper>{itmWrpSubSec};    
            
            OpportunityModifiersCmpController.SubSection subSec = new OpportunityModifiersCmpController.SubSection('Contact Info');
        subSec.items =  subSecItem.items;
        
        OpportunityModifiersCmpController.MainSection ms = new OpportunityModifiersCmpController.MainSection();
        ms.name = 'Account Info';
        ms.items = sI.items;
        ms.subActiveSections = new List<String>{'Account Info'};
            ms.subSections =  new List<OpportunityModifiersCmpController.SubSection>{subSec};   
                ms.isActiveSection = true;
        
        String jsonWrap = JSON.serialize(new List<OpportunityModifiersCmpController.MainSection>{ms});
        OpportunityModifiersCmpController.saveRecordTabLwc(jsonWrap,[SELECT id FROM Opportunity LIMIT 1].id, true);  
        Test.stopTest();
        system.assert(jsonWrap !=null);
        
        
    }
    
    @isTest
    public static void testGetRatingModifiersForRiskHealth() {
        Test.startTest();
        List<Rating_Modifiers__c> ratingModifiers = OpportunityModifiersCmpController.getRatingModifiersForRiskHealth('MPL',[SELECT id FROM Opportunity LIMIT 1].id);
        Test.stopTest();
        system.assert(ratingModifiers !=null);
    }
    
    @isTest
    public static void testUpdateStageAndPopulateFields() {
        Test.startTest();
        Boolean oppId = OpportunityModifiersCmpController.updateStageAndPopulateFields([SELECT id FROM Opportunity LIMIT 1].id);
        Test.stopTest();
        system.assert( oppId !=null);
    }
    
    @isTest
    public static void testGetMainSectionByProduct() {
        Opportunity opportunity = [SELECT id FROM Opportunity LIMIT 1];
        Test.startTest();
        TriggerSettings__c setting = [Select id FROM TriggerSettings__c LIMIT 1];
        setting.BypassProductTrigger__c = true;
        update setting;
        
        ResultResponse opp = OpportunityModifiersCmpController.getMainSectionFromProduct('MPL',[SELECT id FROM Opportunity LIMIT 1].id);
        OpportunityModifiersCmpController.getMainSectionFromProductLwc('MPL',[SELECT id FROM Opportunity LIMIT 1].id);
        
        
        OpportunityModifiersCmpController.getMainSectionFromProduct('MPL',[SELECT id FROM Opportunity LIMIT 1].id);
        Test.stopTest();
        system.assert(opp !=null);
    }
    
    @isTest
    public static void testUpdateStageAndPopulateFieldsLwc() {
        Test.startTest();
        String opp = OpportunityModifiersCmpController.updateStageAndPopulateFieldsLwc([SELECT id FROM Opportunity LIMIT 1].id);
        Test.stopTest();
        system.assert(opp !=null);
    }
    
    @isTest
    public static void testCheckProceedtoQuote() {
        Test.startTest();
        ResultResponse opp = OpportunityModifiersCmpController.checkProceedtoQuote([SELECT id FROM Opportunity LIMIT 1].id); 
        Test.stopTest();
        system.assert(opp !=null);
    }
    
    @isTest
    public static void testupdateQuoteStatus() {
        Test.startTest();
        List<Rating_Modifiers__c> ratMod = [SELECT id,Name,Display_Format__c,Rating_Modifier_Code__c, Opportunity__c 
                                            FROM Rating_Modifiers__c 
                                            WHERE Name='Rating field test1' LIMIT 1];
        OpportunityModifiersCmpController.updateQuoteStatus(ratMod); 
        Test.stopTest();
        system.assert(ratMod !=null);
    }
    
    @isTest
    public static void testGetMainProfession() {
        Test.startTest();
        String opp = OpportunityModifiersCmpController.getMainProfession([SELECT id FROM Opportunity LIMIT 1].id); 
        Test.stopTest();
        system.assert(opp ==null);
    }
    
    @isTest
    public static void testGetMasterBindersFromQuote() {
        Test.startTest();
        List<Master_Binder__c> binderList = new List<Master_Binder__c>();
        
        List<Quote> quoteList = [Select Id,Name,OpportunityId,Effective_Date__c from Quote LIMIT 1];
        //Quote q = [Select Effective_Date__c from Quote LIMIT 1];
        List<Master_Binder__c> opp = OpportunityModifiersCmpController.getMasterBindersFromQuote(quoteList[0].Id, string.valueof(quoteList[0].Effective_Date__c)); 
        Test.stopTest();
        system.assert(opp !=null);
    }
    
    @isTest
    public static void testgetOpportunityDetails() {
        Test.startTest();
        List<Opportunity> oppList = [Select Id,Name from Opportunity ];
        Opportunity opp = OpportunityModifiersCmpController.getOpportunityDetails(oppList[0].Id); 
        Test.stopTest();
        system.assert(opp !=null);
    }
    @isTest
    public static void testgetSubmissionDetails() {
        Test.startTest();
        Quote qt = [Select Id,Name,OpportunityId,Quote_Type__c from Quote Limit 1];
        qt.Quote_Type__c='Flat Cancellation';
        update qt;
        OpportunityModifiersCmpController.OpportunityWrapper opp = OpportunityModifiersCmpController.getSubmissionDetails(qt.OpportunityId); 
        OpportunityModifiersCmpController.MainSection main= new OpportunityModifiersCmpController.MainSection('Account Info');
        Test.stopTest();
        system.assert(opp !=null);
    }
    
    
}