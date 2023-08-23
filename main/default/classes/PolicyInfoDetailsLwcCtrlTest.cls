@isTest
public class PolicyInfoDetailsLwcCtrlTest {
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
        
        Policy__c policy = new Policy__c();
        policy.Account__c = acc1.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);
        insert policy;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc1.Id, product.Id);
        opportunity.Policy__c = policy.Id;
        insert opportunity;
        
        List<SectionSetting__c> secSettLst = new List<SectionSetting__c>(); 
        SectionSetting__c secSetting = new SectionSetting__c();
        secSetting.Component__c = 'Policy Info';
        secSetting.Main_Section__c = 'Policy Info';
        secSetting.Source_Object__c = 'Account';
        secSetting.Order__c = 4;
        secSetting.Source_Field_Label__c = 'Relationship Type';
        //secSetting.Source_Field_API__c = 'Relationship_Type__c';
        secSetting.Format__c = 'Picklist';
        secSetting.Product__c = 'MPL';
        secSetting.Active__c = true;
        secSetting.Record_Type__c = 'Celerity';
        secSettLst.add(secSetting);
        
         SectionSetting__c secSetting1 = new SectionSetting__c();
        secSetting1.Component__c = 'Policy Info';
        secSetting1.Main_Section__c = 'Policy Info';
        secSetting1.Sub_Section__c = 'Policy Info';
        secSetting1.Source_Object__c = 'Account';
        secSetting1.Order__c = 4;
        secSetting1.Source_Field_Label__c = 'Relationship Type';
        //secSetting.Source_Field_API__c = 'Relationship_Type__c';
        secSetting1.Format__c = 'Picklist';
        secSetting1.Product__c = 'MPL';
        secSetting1.Active__c = true;
        secSetting1.Record_Type__c = 'Celerity';
        secSettLst.add(secSetting1);
        
        insert secSettLst;
    }
    
    @isTest
    public static void testGetRecordInfos() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        Opportunity opp = [SELECT id FROM Opportunity LIMIT 1];
        Policy__c policy = [SELECT id FROM Policy__c LIMIT 1];
        String polAcc = PolicyInfoDetailsLwcCtrl.getRecordInfos(acc.Id);
        System.assertEquals(null, polAcc);
        String polOpp = PolicyInfoDetailsLwcCtrl.getRecordInfos(opp.Id);
        System.assertEquals(policy.Id, polOpp);
    }
    
    @isTest
    public static void testGetListSectionSetting() {
        PolicyInfoDetailsLwcCtrl.TabItem tabItem = PolicyInfoDetailsLwcCtrl.getListSectionSetting();
        SYstem.assertEquals(true,tabItem.sections!=null); 
    }
    
    @isTest
    public static void testGetPol() {
        Policy__c pol = [SELECT id FROM Policy__c LIMIT 1];
        List<String> srtLst = new List<String>{'Name'};
        String result = JSON.serialize(srtLst);    
        Map<String,Object> policyMap = PolicyInfoDetailsLwcCtrl.getPol(pol.Id,result);
        System.assertEquals(true, policyMap.size() > 0);
    }
}