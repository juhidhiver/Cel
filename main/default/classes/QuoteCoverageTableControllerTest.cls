/**
 * @description       : 
 * @author            : Maeran Shaikh
 * @group             : 
 * @last modified on  : 11-10-2021
 * @last modified by  : Maeran Shaikh
**/
@isTest
public class QuoteCoverageTableControllerTest {
    public static Product2 product;
    public static Product2 product1;
    public static Product2 product2;
    public static Account acc;
    public static Opportunity opp;
    public static Quote objQuote;

    static {
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = false;
        setting.BypassAccountTrigger__c = true;
        setting.BypassProductTrigger__c = true;
        update setting;
        
        acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        product = TestUtil.createProduct('Private Company Combo');
        insert product;
        
        product1 = TestUtil.createProduct('D&O');
        product1.Parent_Product__c = product.Id;
        product1.IsComboProduct__c = true;
        insert product1;

        product2 = TestUtil.createProduct('EPL');
        product2.Parent_Product__c = product.Id;
        product2.IsComboProduct__c = true;
        insert product2;

        opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.Total_Revenues__c = 100;
        insert opp;
        
        objQuote = TestUtil.createQuote('Quote Test',opp.Id);
        objQuote.Status = 'IN PROGRESS';
        objQuote.Azure_ID__c = 'Test Az 1';
        insert objQuote;
    }
    
    @isTest static void testFetchCoverageDetails() {

        Product_Option_Line_Item__c newRec = new Product_Option_Line_Item__c();
        newRec.Product__c = product1.Id;
        newRec.Submission__c = opp.Id;
        newRec.Account__c = acc.Id;
        newRec.Clearance_Status__c = 'Cleared';
        newRec.Is_Selected__c = true;
        newRec.Clearance_Date__c = Datetime.now();
        insert newRec;
        
        Product_Option_Line_Item__c newRec2 = new Product_Option_Line_Item__c();
        newRec2.Product__c = product2.Id;
        newRec2.Submission__c = opp.Id;
        newRec2.Account__c = acc.Id;
        newRec2.Clearance_Status__c = 'Cleared';
        newRec2.Is_Selected__c = true;
        newRec2.Clearance_Date__c = Datetime.now();
        insert newRec2;
        
        //Create coverage
        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'D&O');
        cov.Coverage_Code__c = 'DOCoverage';
        insert cov;
        
        //Create coverage
        Coverage__c cov1 = TestUtil.createCoverage('Coverage test', 'EPL');
        cov1.Coverage_Code__c = 'EPLCoverage';
        insert cov1;
        
        // Coverages Line Item
        CoveragesLineItem__c coverLi = new CoveragesLineItem__c();
        coverLi.Coverage__c  = cov.Id; 
        coverLi.Quote__c = objQuote.Id;
        coverLi.Coverage_Premium__c  = '1.1'; 
        coverLi.Min_amt__c  = 1000;
        coverLi.Max_amt__c  = 5000;
        coverLi.Deductible_Frequency__c  = 'Daily';
        coverLi.Options_Value_Percent__c  = 5;
        insert coverLi;

        QuoteCoverageTableController.RelatedListWrapper objWrapper = QuoteCoverageTableController.fetchCoverageDetails(objQuote.Id);
    }
    
    @isTest static void testSaveQuotePremium() {
        
        String strResult = '';
        strResult = QuoteCoverageTableController.saveQuotePremium(objQuote);
        System.assertEquals('success', strResult);
    }
}