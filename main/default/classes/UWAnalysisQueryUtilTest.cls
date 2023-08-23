/**************************************************************************************************
* Class Name: UWAnalysisQueryUtilTest
* Author:  RINKU SAINI
* Date: Dec 30, 2021
* Description: 
**************************************************************************************************/
@isTest
public class UWAnalysisQueryUtilTest {
    
    public static testmethod void coverUWAnalysisQuery(){
        Test.startTest();
        
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account acc  =TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster',
                                             'California','90000', 'United States');
        acc.Azure_ID__c = '8042ac98-ae5a-4692-9880-58d92d0eb9d9';
        insert acc;
        
        Product2 product = TestUtil.createProduct('MPL');
        insert product; 
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today()+365;
        opp.StageName = 'New';
        opp.Azure_ID__c = 'f70e4c82-3378-41ce-870b-57f4df415874';
        insert opp;
        
        UW_Analysis_Template__c TempList = new UW_Analysis_Template__c();
        TempList.UW_Analysis_Name__c = 'Test';
        TempList.Criteria__c = 'Engineers';
        TempList.UW_Analysis_Code__c ='Code';
        TempList.Rating_Factor__c= 5000;
        TempList.Sort_Order__c = 100;
        insert TempList;
        
        UW_Analysis__c uwList = new UW_Analysis__c();
        uwList.Amount__c = 1000;
        //uwList.Name = 'Test';
        uwList.UW_Analysis_Name__c = 'UW Test';
        uwList.Criteria__c = 'Territory';
        uwList.UW_Analysis_Code__c = 'T1';
        uwList.Rating_Factor__c = 1000;
        uwList.Sort_Order__c = 10;
        uwList.Submission__c = opp.Id;
        uwList.UW_Analysis_Template__c = TempList.Id;
        uwList.Sort_Order__c = 10;
        uwList.Notional_Income__c = 1000;
        insert uwList;
        
        UWAnalysisQueryUtil.fetchUWAnalysisForOpps( New List<Id>{opp.Id});
        Test.stopTest();
    }
}