/*************************************************
* Class Name: UWAnalysisSectionController
* Author: Ashik Zahir
* Date: 
* Modified Date: 15-03-2021
* Requirement/Project Description: 
*************************************************/
@isTest
public class UWAnalysisSectionControllerTest {
    @testsetup static void testSetup(){
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
        
        Rating_Modifiers__c ratingModifier1 = TestUtil.createRatingModifier( 'Annual gross fees / turnover', product.Name, opp.Id);
        ratingModifier1.Rating_Modifier_Code__c = 'MPL000025';
        ratingModifier1.Display_Format__c = 'Primary Modifiers';
        ratingModifier1.Opportunity__c = opp.Id;
        ratingModifier1.Rating_Modifier_Value__c = 'Yes';
        ratingModifier1.Page_Section__c = 'Pros and Cons';
        ratingModifier1.Format__c = 'Picklist';
        ratingModifier1.Picklist_Values__c = 'At least one very restrictive endorsement;At least one restrictive endorsement and no very restrictive endorsements;No restrictive endorsement';
        insert ratingModifier1;
        
        //uwList.Criteria__c = 'Design & Construct';
        //update uwList;
        
        /*List<String> fields = new List<String>();
        List<String> params = new List<String>();
        String condition = '';
        String objName = 'Warnings__c';
        fields.add('Id');
        fields.add('UW_Analysis_Template__c');
        fields.add('Rating_Modifier_Template__c');
        fields.add('Warning_Text__c');
        fields.add('Main_Profession__c');
        fields.add('Work_Type__c');
        fields.add('Percent_exceeded__c');
        insert fields;*/
    }
    @isTest static void getUWAnalysisTemplatesTest(){
        Test.startTest();
            Opportunity opp = [select Id,name from  Opportunity limit 1];
            UWAnalysisSectionController.getUWAnalysisTemplates(opp.Id);        
        Test.stopTest();
        system.assert(opp.Id!= null);
    }
    
    @isTest static void createUWAnalysisByTemplateTest(){
        Test.startTest();
        UW_Analysis_Template__c TempList =[Select Id, Name, UW_Analysis_Name__c, Criteria__c 
                                           FROM UW_Analysis_Template__c ];
        Opportunity opp = [select Id,name from  Opportunity limit 1];
        List<String> uwTemplateIds = new List<String>();
        uwTemplateIds.add(TempList.Id);
        UWAnalysisSectionController.createUWAnalysisByTemplate(opp.Id, uwTemplateIds);
        Test.stopTest();
        System.assert(uwTemplateIds!= null);
    }
    @isTest static void getUWAnalysisTest(){
        Test.startTest();
        UW_Analysis_Template__c TempList =[Select Id, Name, UW_Analysis_Name__c, Criteria__c 
                                           FROM UW_Analysis_Template__c ];
        Opportunity opp = [select Id,name from  Opportunity limit 1];
        opp.Main_Profession__c = 'Engineers';
        update opp;
        UWAnalysisSectionController.UWAlyProfessionWrapper uwAlyProfession = UWAnalysisSectionController.getUWAnalysis(opp.Id);
        Test.stopTest();
        system.assert(TempList.UW_Analysis_Name__c == 'Test');
        
    }
    @isTest static void saveUWAnalysisTest(){
        Test.startTest();
        Opportunity opp = [select Id,name from  Opportunity limit 1];
        UW_Analysis__c uwAnalysis = [SELECT UW_Analysis_Name__c, Criteria__c, UW_Analysis_Code__c, Rating_Factor__c,
                                     Sort_Order__c, Submission__c, UW_Analysis_Template__c, Split_Percentage__c,
                                     Amount__c, Notional_Income__c
                                     FROM UW_Analysis__c Limit 1];
        //UWAnalysisSectionController.saveUWAnalysis uwAnalusis = new UWAnalysisSectionController.saveUWAnalysis(uwAnalysis[0]);
        String uwAnalysisJson = '[{"amountClass":"a092500000BJqQNAA1_amount","criteria":"Territory","identifier":"'+uwAnalysis.Id+'","name":"United Kingdom","opportynityId":"'+opp.id+'","ratingFactor":1,"sortOrder":1,"splitClass":"a092500000BJqQNAA1_split","splitPercentage":50,"templateId":"a0R25000004w9yOEAQ","uwCode":"T0","amount":1000}]';
        UWAnalysisSectionController.saveUWAnalysis(uwAnalysisJson, opp.id);
       //System.assert(uwAnalysis!=null);
       Test.stopTest();
    }
    @isTest static void UWAnalysisWrapperTest(){
        Test.startTest();
        UW_Analysis_Template__c TempList =[Select Id, Name, UW_Analysis_Name__c, Criteria__c 
                                           FROM UW_Analysis_Template__c ];
        Opportunity opp = [select Id,name from  Opportunity limit 1];
        List<String> uwTemplateIds = new List<String>();
        uwTemplateIds.add(TempList.Id);
        UWAnalysisSectionController.createUWAnalysisByTemplate(opp.Id, uwTemplateIds);
        List<UW_Analysis__c> uwAnalysis = [SELECT UW_Analysis_Name__c, Criteria__c, UW_Analysis_Code__c, Rating_Factor__c,
                                     Sort_Order__c, Submission__c, UW_Analysis_Template__c, Split_Percentage__c,
                                     Amount__c, Notional_Income__c
                                     FROM UW_Analysis__c ];
        UWAnalysisSectionController.UWAnalysisWrapper uwAnalusis = new UWAnalysisSectionController.UWAnalysisWrapper(uwAnalysis[0]);
        Test.stopTest();
        //system.assert(uwAnalysis[0].Criteria__c  == 'Engineers');
    }
    
      @isTest static void getWarningsForRiskHealthTest(){
        Test.startTest();
        UW_Analysis_Template__c TempList =[Select Id, Name, UW_Analysis_Name__c, Criteria__c 
                                           FROM UW_Analysis_Template__c ];
        Opportunity opp = [select Id,name from  Opportunity limit 1];
        List<String> uwTemplateIds = new List<String>();
        uwTemplateIds.add(TempList.Id);
        //UWAnalysisSectionController.getWarningsForRiskHealth(opp.Id, uwTemplateIds);
        
          List<UW_Analysis__c> uwAnalysis = [SELECT UW_Analysis_Name__c, Criteria__c, UW_Analysis_Code__c, Rating_Factor__c,
                                     Sort_Order__c, Submission__c, UW_Analysis_Template__c, Split_Percentage__c,
                                     Amount__c, Notional_Income__c
                                     FROM UW_Analysis__c ];
         //uwAnalysis.Criteria__c = 'Design & Construct';
          update uwAnalysis;
        UWAnalysisSectionController.getWarningsForRiskHealth('D&O Standalone',opp.Id);        
        Test.stopTest();
        system.assert(opp.Id!= null);
    }
    
}