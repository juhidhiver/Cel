/**************************************************************************************************
 * Class Name: SortSubSectionCmpControllerTest
 * Author: Giang Phan
 * Date: 01-Nov-2019
 * Description: SortSubSectionCmpControllerTest Test
 **************************************************************************************************/
@isTest (SeeAlldata = false)
public with sharing class SortSubSectionCmpControllerTest {
    private static String oppId;
    @TestSetup
    private static void setupData() {
        //Create Account
        Account acc1 = new Account();
        acc1.Name = 'Test account 1';
        acc1.BillingStreet = '01 Tran Duy Hung';
        acc1.BillingCity = 'Westminster';
        acc1.BillingState = 'California';
        acc1.BillingPostalCode = '90000';
        acc1.BillingCountry = 'United States';
        acc1.IsMailingSameWithBillingAddress__c = true;
        acc1.Date_Started__c = Date.today().addYears(-2);
        insert acc1;

        // Create contact
        Contact con = new Contact(
            Lastname = 'Test broker',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
        );
        insert con;

        Contract contr = new Contract(
            AccountId = acc1.Id,
            Expiration_Date__c = Date.today().addDays(100)
        );
        insert contr;

        //Create Product
        Product2 prd = new Product2(
            Name = 'Private Company Combo',
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Celerity').getRecordTypeId(),
            Innovisk_Entity_ID__c = 'Celerity',
            Package_Indicator__c = true,
            IsActive = true,
            Expiration_Date__c = Date.today().addDays(200),
            Effective_Date__c = Date.today().addDays(-1)
        );
        insert prd;

        // Create opportunity
        Opportunity opp = new Opportunity();
        opp.Name = 'Test opp';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
        opp.Coverage_Product_Options__c = 'D&O';
        opp.AccountId = acc1.Id;
        //opp.Pricebook2Id = Test.getStandardPricebookId();
        opp.Product__c = prd.Id;
        opp.Received_Date__c = Date.today();
        opp.CloseDate = Date.today().addDays(30);
        opp.Effective_Date__c = Date.today();
        opp.Type = 'New Business';
        opp.LeadSource = 'Email';
        opp.StageName = 'New';
        opp.ContractId = contr.Id;
        insert opp;

        oppId = opp.Id;

        Rating_Modifiers__c rm = new Rating_Modifiers__c();
        rm.Name = 'Test Rating Modifiers';
        rm.Sort_Sub_Section__c = 1;
        rm.Sub_Section__c = 'Test SubsectionCmpController';
        rm.Page_Section__c = 'Rate Modifiers';
        rm.Product__c = 'Cyber';
        rm.Opportunity__c = opp.Id;
        insert rm;

        Rating_Modifier_Template__c rmt = new Rating_Modifier_Template__c();
        rmt.Name = 'Test Rating Modifier Template';
        rmt.Sort_Sub_Section__c = 1;
        rmt.Sub_Section__c = 'Test SubsectionCmpController';
        rmt.Page_Section__c = 'Rate Modifiers';
        rmt.Product__c = 'Cyber';
        insert rmt;
    }

    public static testMethod void testGetSortSubSectionsWithNullObjId() {
        String objId = '';
        Test.startTest();
        List<Object> sortSubSectionInfoList = SortSubSectionCmpController.getSortSubSections(objId);
        System.debug('@@@ sortSubSectionInfoList: ' + sortSubSectionInfoList);
        Test.stopTest();
        System.assertEquals(true, sortSubSectionInfoList.size() > 0);
    }
    
    public static testMethod void testUpdateSortSubSections() {
        String objId = '';
        List<SortSubSectionCmpController.SortSubSectionInfo> sortSubSectionInfoList = new List<SortSubSectionCmpController.SortSubSectionInfo>();
        SortSubSectionCmpController.SortSubSectionInfo sortSubSectionInfo = new SortSubSectionCmpController.SortSubSectionInfo();
        sortSubSectionInfo.Id = 'CyberTest Update SortSubSectionsTest Update Func'; 
        sortSubSectionInfo.product = 'Cyber';
        sortSubSectionInfo.pageSection = 'Test Update SortSubSections';
        sortSubSectionInfo.subSection = 'Test Update Func';
        sortSubSectionInfo.sortNo = 3;
        sortSubSectionInfoList.add(sortSubSectionInfo);
        
        Test.startTest();
        SortSubSectionCmpController.updateSortSubSections(sortSubSectionInfoList, oppId);
        Test.stopTest();

        List<Rating_Modifier_Template__c> result = [Select Id, Sort_Sub_Section__c FROM Rating_Modifier_Template__c];
        for (Rating_Modifier_Template__c obj : result) {
            //System.assertEquals(3, obj.Sort_Sub_Section__c);
        }
    }
}