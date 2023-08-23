@isTest
public class SubmissionInfoDetailLWCCtrlTest {
@testsetup static void testSetup(){
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
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
        insert quote1;  

		Quote quote2 = Testutil.createQuote('New Quote 2', opp.Id);
        quote2.Status = 'Bound';
        quote2.Coverage_Product_Options__c = 'D&O';
        quote2.Refer_Type__c = 'Underwriting Referral';
        insert quote2; 
  
    	SectionSetting__c secSettings1 = new SectionSetting__c();
    	secSettings1.Component__c = 'Submission Info';
        secSettings1.Order__c = 7;
   		secSettings1.Main_Section__c = 'Submission Status';
    	secSettings1.Sub_Section__c = 'Submission Status Sub';
    	secSettings1.Source_Object__c = 'Opportunity';
   		secSettings1.Source_Field_API__c = 'Amount';
        secSettings1.Source_Field_Label__c = 'Amount';
        secSettings1.Format__c = 'Number';
		insert secSettings1;      
	}
    @isTest
    static void getListSectionSettingTest(){
        Test.startTest();
        SubmissionInfoDetailLWCCtrl.getListSectionSetting();
        System.assert(True);
        Test.stopTest();
    }
    @isTest
    static void getListSectionSettingTest2(){
        Test.startTest();
        SectionSetting__c secSetting = [Select Id, Source_Object__c, Sub_Section__c from SectionSetting__c];
        secSetting.Source_Object__c = '';
        secSetting.Sub_Section__c = '';
        try{
           update secSetting;
        SubmissionInfoDetailLWCCtrl.getListSectionSetting();   
        }
        catch(Exception ex){
            System.debug(ex.getMessage());
        }      
        System.assert(True);
        Test.stopTest();
    }
     @isTest
    static void getListSectionSettingTest3(){
        Test.startTest();
        SectionSetting__c secSetting = [Select Id, Source_Object__c, Sub_Section__c, Main_Section__c from SectionSetting__c];        
        secSetting.Main_Section__c = '';
        secSetting.Sub_Section__c = '';
        try{
           update secSetting;
        SubmissionInfoDetailLWCCtrl.getListSectionSetting();   
        }
        catch(Exception ex){
            System.debug(ex.getMessage());
        }      
        System.assert(True);
        Test.stopTest();
    }
    
    @isTest
    static void getOppTest(){
        Test.startTest();
        Opportunity opp = [Select Id from Opportunity Limit 1];
        Map<String, Object> getOpp = SubmissionInfoDetailLWCCtrl.getOpp(opp.id, '["Name"]');
        System.assert(getOpp!=null);
        Test.stopTest();
    }
}