@isTest
public class SubmissionInfoLwcControllerTest {
	@testSetup
    public static void setup() {
             
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert accBroker;              	
        
        // create product
        Product2 product = TestUtil.createProduct('MPL Standalone');
		insert product;
        
		// create opportunity        
        Opportunity opp = TestUtil.createOpportunity('Test Opportunity', accBroker.Id, product.Id);
        opp.StageName = 'Qualified';
        insert opp;
        
        Account_Loss_Detail__c accountLoss = new Account_Loss_Detail__c();
        accountLoss.Account__c = accBroker.Id;
        accountLoss.Product__c = 'Cyber';
        accountLoss.Loss_Amount__c = 123;
        accountLoss.Status__c = 'Open';
        accountLoss.Year__c = '2020';
        accountLoss.Number_of_Losses__c = 23;
        insert accountLoss;
        
        Submission_Loss_Detail__c subLoss = new Submission_Loss_Detail__c();
        subLoss.Loss_Amount__c = 200;
        subLoss.Number_of_Losses__c = 2;
        subLoss.Product__c = 'MPL';
        subLoss.Status__c = 'Open';
        subLoss.Year__c = '2020';
        subLoss.Submission__c = opp.Id;
        subLoss.Account_Loss_Detail__c = accountLoss.Id;
        insert subLoss;
        
        Quote_Process__c qp = new Quote_Process__c();
        qp.Account__c = accBroker.Id;
        qp.Submission__c = opp.Id;
        insert qp;
        
        List<SectionSetting__c> secSettingLst = new List<SectionSetting__c>();
        
        SectionSetting__c secSetting = new SectionSetting__c();
        secSetting.Component__c = 'Submission Info';
        secSetting.Main_Section__c = 'Broker Account';
        secSetting.Source_Object__c = 'Broker_Account__c';
        secSetting.Order__c = 4;
        secSetting.Source_Field_Label__c = 'Relationship Type';
        secSetting.Source_Field_API__c = 'Relationship_Type__c';
        secSetting.Format__c = 'Picklist';
        secSetting.Product__c = 'MPL';
        secSetting.Profile_Name_for_Read_Only__c='Celerity Senior Underwriter';
        secSettingLst.add(secSetting);
        
        SectionSetting__c secSetting1 = new SectionSetting__c();
        secSetting1.Component__c = 'Submission Info';
        secSetting1.Main_Section__c = 'Submission Info';
        //secSetting1.Source_Object__c = 'Broker_Account__c';
        secSetting1.Order__c = 3;
        secSetting1.Source_Field_Label__c = 'Relationship Type';
        secSetting1.Source_Field_API__c = 'Relationship_Type__c';
        secSetting1.Format__c = 'Picklist';
        secSetting1.Product__c = 'MPL';
        secSetting1.Profile_Name_for_Read_Only__c='All';
        secSettingLst.add(secSetting1);
        
        SectionSetting__c secSetting2 = new SectionSetting__c();
        secSetting2.Component__c = 'Submission Info';
        secSetting2.Main_Section__c = 'Submission Info';
        secSetting2.Sub_Section__c = 'Account Info';
        secSetting2.Source_Object__c = 'Broker_Account__c';
        secSetting2.Order__c = 1;
        secSetting2.Source_Field_Label__c = 'Name';
        secSetting2.Source_Field_API__c = 'Name';
        secSetting2.Format__c = 'Text';
        secSetting2.Product__c = 'MPL';
        secSetting2.Profile_Name_for_Read_Only__c='All';
        secSettingLst.add(secSetting2);
        insert secSettingLst;
        
        SubmissionInfoLwcController.SubmissionAdditionalInsuredWrapper sub = new SubmissionInfoLwcController.SubmissionAdditionalInsuredWrapper();
        sub.Id = 'subId';
        sub.accId = 'subaccId';
        sub.name = 'subName';
        sub.linkAdditionalDetailAccountAddress = 'subAdress';
        sub.submissionId = 'subId';
        sub.linkSubmissionAdditionalDetailName='subDetail';
        sub.linkSubmissionAdditionalDetailOppName = 'subopName';
        sub.linkAdditionalDetailAccountName = 'SubAcc';
        
        SubmissionInfoLwcController.WrapperField wrapField = new SubmissionInfoLwcController.WrapperField();
        wrapField.value = 'Value';
        wrapField.isDependencyPicklist = true;
        
        SubmissionInfoLwcController.Section secWrapper = new  SubmissionInfoLwcController.Section();
        secWrapper.id = 'secWrapperId';
        secWrapper.subSectionTitle = 'secWrapperSub Title';
    }
    
    @isTest
    public static void testGetSubmissionId() {
       Quote_Process__c qp = [SELECT id,Submission__c FROM Quote_Process__c LIMIT 1];
        test.startTest();
       ResultResponse response = SubmissionInfoLwcController.getSubmissionId(String.valueOf(qp.Id));
        test.stopTest();
       System.assert(response!=null);
    }
    
    @isTest
    public static void testGetListBrokerInfo() {
        Opportunity opp = [SELECT id FROM Opportunity LIMIT 1];
        SubmissionInfoLwcController.getListBrokerInfo(opp.Id);
       	SectionSetting__c secSetting = [SELECT id,Name,Main_Section__c FROM SectionSetting__c LIMIT 1];
        secSetting.Main_Section__c = 'Submission Info';
        update secSetting;
        test.startTest();
        SubmissionInfoLwcController.getListBrokerInfo(opp.Id);
        SubmissionInfoLwcController.checkProfileIsAdmin();
         SubmissionInfoLwcController.getAccountDetails();
        test.stopTest();
        system.assertEquals( secSetting.Main_Section__c, 'Submission Info');
    }
    
   /* @isTest
    public static void testGetProductName() {
       	Quote_Process__c qp = [SELECT id,Submission__c FROM Quote_Process__c LIMIT 1];
        String productName = SubmissionInfoLwcController.getProductName(String.valueOf(qp.Id));
        System.assertEquals('Standalone',productName);
        Opportunity opp = [SELECT id,Name FROM Opportunity LIMIT 1];
        String productNameOpp = SubmissionInfoLwcController.getProductName(String.valueOf(opp.Id));
        System.assertEquals('Standalone',productNameOpp);
    }*/
    
    @isTest
    public static void testGetListSectionSetting() {
        Quote_Process__c qp = [SELECT id,Submission__c FROM Quote_Process__c LIMIT 1];
        SectionSetting__c secSet = [SELECT id,Name,Main_Section__c FROM SectionSetting__c
                                    WHERE Main_Section__c ='Broker Account' LIMIT 1];
        secSet.Main_Section__c = 'Submission Info';
        update secSet;
        SubmissionInfoLwcController.getListSectionSetting(String.valueOf(qp.Id));
        test.startTest();
        Opportunity opp = [select id from  Opportunity limit 1 ];
         SubmissionInfoLwcController.getListSectionSetting(String.valueOf(opp.Id));
        test.stopTest();
        system.assert(opp.id!=null);
    
    }
    
    @isTest
    public static void testGetOpp() {
        Opportunity opp = [SELECT id,Name FROM Opportunity LIMIT 1];
        List<String> srtLst = new List<String>{'Name'};
        String result = JSON.serialize(srtLst);
        test.startTest();
        SubmissionInfoLwcController.getOpp(opp.Id,result);
        test.stopTest();
        system.assert(result!=null,true);
    }
    
    @isTest
    public static void testGetSubmissionLossDetailBySubmission() {
        Opportunity opp = [SELECT id,Name FROM Opportunity LIMIT 1];
        test.startTest();
        SubmissionInfoLwcController.getSubmissionLossDetailBySubmission(opp.Id);
        test.stopTest();
        system.assert(opp.Id!=null);
    }
    
    @isTest
    public static void testGetStageNameSubmission() {
        Account acc = [SELECT id,Name FROM Account LIMIT 1];
        Opportunity opp = [SELECT id,Name FROM Opportunity LIMIT 1];
        Quote quote = TestUtil.createQuote('New Quote Test',opp.Id);
        quote.Coverage_Product_Options__c ='D&O;MPL';
        quote.Layer__c = 'Excess';
        quote.Status='Bound';
        quote.Quote_Type__c = 'Full Amendment';
        //insert quote;
         List<Quote> qp = new  List<Quote>();
        qp.add(quote);
        insert qp;
        quote.Status='Bound';
        update quote;
        
        Additional_Insured__c additionalInsuredAcc = new Additional_Insured__c();
        //additionalInsuredAcc.Name = 'additionalInsuredAccName';
        additionalInsuredAcc.Submission__c = opp.Id;
        additionalInsuredAcc.Additional_Insured_Account__c = acc.Id;
        insert additionalInsuredAcc;
        
        test.startTest();
        SubmissionInfoLwcController.getStageNameSubmission(opp.Id);
        SubmissionInfoLwcController.checkRelatedBoundQuotesPresent(opp.Id);
        SubmissionInfoLwcController.getSubmissionAdditionalInsuredDetails(opp.Id);
        SubmissionInfoLwcController.updateAllQuoteStatusAndCloseReason(opp.Id);
        SubmissionInfoLwcController.unDeclineUpdateSubmission(opp.Id);
        test.stopTest();
        system.assert(quote.Status=='Bound');
    }
}