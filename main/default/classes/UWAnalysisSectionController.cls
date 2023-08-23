/*************************************************
* Class Name: UWAnalysisSectionController
* Author: Saumyak Pandey
* Date: 25-Jan-2021
* Requirement/Project Description: 
*************************************************/
public with sharing class UWAnalysisSectionController {
	@AuraEnabled
    public static List<UW_Analysis_Template__c> getUWAnalysisTemplates(String opportunityId){
		 return getTemplates(opportunityId);   
    }
    
    private static List<UW_Analysis_Template__c> getTemplates(String opportunityId){
        List<Opportunity> oppList = [Select Id, Main_Profession__c From Opportunity where Id =:opportunityId];
        String mainProfession = oppList[0].Main_Profession__c;
        List<UW_Analysis_Template__c> returnUWTempList = new List<UW_Analysis_Template__c>();
        List<UW_Analysis_Template__c> uwTempList = [Select Id, UW_Analysis_Name__c,Base_Rates__c 
                                                    From UW_Analysis_Template__c 
                                                    Where Criteria__c =:mainProfession];
        if(!uwTempList.isEmpty()) returnUWTempList = uwTempList;
        return returnUWTempList;
    }
    
    @AuraEnabled
    public static void createUWAnalysisByTemplate(String opportunityId,List<String> uwTemplateIds){
        List<UW_Analysis__c> uwAnalysisListToSave = new List<UW_Analysis__c>();
        if(String.isNotBlank(opportunityId) && !uwTemplateIds.isEmpty()){
            for(UW_Analysis_Template__c uwTemp : [SELECT Id, Name, UW_Analysis_Name__c, Criteria__c, Base_Rates__c,
                                                      UW_Analysis_Code__c, Rating_Factor__c, Sort_Order__c 
                                                      FROM UW_Analysis_Template__c 
                                                      Where Id IN: uwTemplateIds]){
                                                          UW_Analysis__c uwAnalysis = new UW_Analysis__c();
                                                          
                                                          uwAnalysis.UW_Analysis_Name__c = uwTemp.UW_Analysis_Name__c;
                                                          uwAnalysis.Base_Rates__c = uwTemp.Base_Rates__c;
                                                          uwAnalysis.Criteria__c = uwTemp.Criteria__c;
                                                          uwAnalysis.UW_Analysis_Code__c = uwTemp.UW_Analysis_Code__c;
                                                          uwAnalysis.Rating_Factor__c = uwTemp.Rating_Factor__c;
                                                          uwAnalysis.Sort_Order__c = uwTemp.Sort_Order__c;
                                                          uwAnalysis.Submission__c = opportunityId;
                                                          uwAnalysis.UW_Analysis_Template__c = uwTemp.Id;
                                                          uwAnalysisListToSave.add(uwAnalysis);
                                                      }
        }
            
        if(!uwAnalysisListToSave.isEmpty()){
            insert uwAnalysisListToSave;
        }
    }
    
    /*@AuraEnabled
    public static List<UWAnalysisWrapper> getUWAnalysis(String opportunityId){
        List<UWAnalysisWrapper> uwAnalysisList = new List<UWAnalysisWrapper>();
        for(UW_Analysis__c uwAnalysisQuery : [SELECT Id, UW_Analysis_Name__c, Criteria__c, UW_Analysis_Code__c, 
                                              Rating_Factor__c, Sort_Order__c, Split_Percentage__c, Amount__c, 
                                              Submission__c, Notional_Income__c, UW_Analysis_Template__c 
                                              FROM UW_Analysis__c 
                                              Where Submission__c =:opportunityId]){
                                                  UWAnalysisWrapper uw = new UWAnalysisWrapper(uwAnalysisQuery);
                                                  uwAnalysisList.add(uw);
                                              }
        
        return uwAnalysisList;
    }*/
    
    @AuraEnabled
    public static UWAlyProfessionWrapper getUWAnalysis(String opportunityId){
        UWAlyProfessionWrapper uwWrap = new UWAlyProfessionWrapper();
        List<UWAnalysisWrapper> uwAnalysisList = new List<UWAnalysisWrapper>();
        for(UW_Analysis__c uwAnalysisQuery : [SELECT Id, UW_Analysis_Name__c, Criteria__c, UW_Analysis_Code__c, 
                                              Rating_Factor__c, Sort_Order__c, Split_Percentage__c, Amount__c, 
                                              Submission__c, Notional_Income__c, UW_Analysis_Template__c 
                                              FROM UW_Analysis__c 
                                              Where Submission__c =:opportunityId]){
                                                  UWAnalysisWrapper uw = new UWAnalysisWrapper(uwAnalysisQuery);
                                                  uwAnalysisList.add(uw);
                                              }
        List<Opportunity> opp = [Select Id, Main_Profession__c From Opportunity Where Id =:opportunityId];
        if(!opp.isEmpty()) uwWrap.mainProfession = opp[0].Main_Profession__c;
        if(!uwAnalysisList.isEmpty()) uwWrap.uwAlyRecord = uwAnalysisList;
        
        return uwWrap;
    }
    
    @AuraEnabled 
    public static void saveUWAnalysis(String uwAnalysisJson, String opportunityId){
        System.debug('saveUWAnalysis----->');
        List<UWAnalysisWrapper> uwWrapper = (List<UWAnalysisWrapper>)System.JSON.deserialize(uwAnalysisJson, List<UWAnalysisWrapper>.class);  
      
        Map<string,UW_Analysis__c> oldUWAnalysisMap = new  Map<string,UW_Analysis__c>();
        List<UW_Analysis__c> uwListToUpdate = new List<UW_Analysis__c>();
        Boolean isChanged = false;
        
        List<UW_Analysis__c> oldUWAnalysisList = new List<UW_Analysis__c>();
          oldUWAnalysisList  = [SELECT Id,UW_Analysis_Name__c,Rating_Factor__c,UW_Analysis_Template__c,Sort_Order__c,UW_Analysis_Code__c,Split_Percentage__c,Amount__c FROM UW_Analysis__c 
                                                  WHERE Submission__c =: opportunityId];
       
        if(!oldUWAnalysisList.isEmpty()){
            for(UW_Analysis__c uw: oldUWAnalysisList){
                oldUWAnalysisMap.put(uw.Id, uw);
            }
        }

        for(UWAnalysisWrapper newUW : uwWrapper){
            if(oldUWAnalysisMap.get(newUW.identifier).Amount__c != newUW.amount || oldUWAnalysisMap.get(newUW.identifier).Split_Percentage__c != newUW.splitPercentage){
                System.debug('saveUWAnalysis-----newUW--->'+newUW.amount+'-----'+newUW.splitPercentage);
                System.debug('saveUWAnalysis-----newUW--->'+oldUWAnalysisMap.get(newUW.identifier).Amount__c+'-----'+oldUWAnalysisMap.get(newUW.identifier).Split_Percentage__c);
                isChanged = true;
            }
        }
        if(isChanged){
            for(UWAnalysisWrapper uwWrap: uwWrapper){
                UW_Analysis__c uwAly = new UW_Analysis__c();            
                uwAly.Id = uwWrap.identifier;                   
                uwAly.Rating_Factor__c = uwWrap.ratingFactor;            
                uwAly.Split_Percentage__c =	uwWrap.splitPercentage; 
                uwAly.Amount__c = uwWrap.amount;  
                uwAly.Submission__c = uwWrap.opportynityId;
                uwAly.Notional_Income__c = uwWrap.notonalIncome;
                
                uwListToUpdate.add(uwAly);
            }
        }

        if(!uwListToUpdate.isEmpty()) update uwListToUpdate;
    }
    

    //Prachi added
    @AuraEnabled
    public static List<Warnings__c> getWarningsForRiskHealth(String productName, String opportunityId ) {
         List<UW_Analysis__c> uwRecords = [SELECT Id, UW_Analysis_Name__c, Criteria__c, UW_Analysis_Code__c, 
                                              Rating_Factor__c, Sort_Order__c, Split_Percentage__c, Amount__c, 
                                              Submission__c, Notional_Income__c, UW_Analysis_Template__c 
                                              FROM UW_Analysis__c 
                                              Where Submission__c =:opportunityId];
        Set<Id> uwTempSet = new Set<Id>();
        List<Warnings__c> warningsDataList = new List<Warnings__c>();
        List<Warnings__c> warningsRMDataList = new List<Warnings__c>();
        List<Warnings__c> percentWarningsList = new List<Warnings__c>();
        Set<String> uwCodesForPercentCheck = new Set<String>{'WT61','WT64','WT65','WT70','WT71','WT82','WT84','WT73','WT85',
                                                             'WT86','WT88','WT91'};
        List<UW_Analysis__c> dncWorkTypes = new List<UW_Analysis__c>();                                                         
        Rating_Modifier_Template__c rmTempRecord;
        for(UW_Analysis__c rec : uwRecords){
           uwTempSet.add(rec.UW_Analysis_Template__c);
            if(rec.Criteria__c == 'Design & Construct' && uwCodesForPercentCheck.contains(rec.UW_Analysis_Code__c)){
                dncWorkTypes.add(rec);
            } 
        }
        Decimal sumCheck = 0;
        if(!dncWorkTypes.isEmpty()){
            for(UW_Analysis__c uw : dncWorkTypes){
            sumCheck = sumCheck + uw.Split_Percentage__c;
         } 
        }
        Rating_Modifiers__c rmRecord = [SELECT Opportunity__c, Rating_Modifier_Value__c, Name, Rating_Modifier_Code__c 
                                       FROM Rating_Modifiers__c where Name = 'Annual gross fees / turnover'
                                          AND Opportunity__c =:opportunityId];
        //Dynamic query
        List<String> fields = new List<String>();
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
        
        // select condition to query rating modifier warnings
        String filterRMWarning = '';
        String rmTempId='';
        if(rmRecord!=null && (rmRecord.Rating_Modifier_Value__c==NULL || rmRecord.Rating_Modifier_Value__c=='0')){
            rmTempRecord = [SELECT Id, Rating_Modifier_Code__c
                                                            FROM Rating_Modifier_Template__c
                                                            WHERE Rating_Modifier_Code__c =:rmRecord.Rating_Modifier_Code__c];
            rmTempId = rmTempRecord.Id;
            filterRMWarning = 'Rating_Modifier_Template__c =: rmTempId';
            System.debug('filterRMWarning::'+filterRMWarning);
            params.add(filterRMWarning);
        }
        
        String filterUWWarnings = '';
        if(!uwTempSet.isEmpty()){
            filterUWWarnings = 'UW_Analysis_Template__c IN: uwTempSet';
            params.add(filterUWWarnings);
        }
        
        String filterpercentWarnings = '';
        if(sumCheck>50){
            filterpercentWarnings = 'Percent_exceeded__c = true';
            params.add(filterpercentWarnings);
        }
        
         condition = String.join(params, ' OR ');
         String query = CommonUtil.buildQuery(fields, objName, condition);
         System.debug('warning query-->'+query);
         warningsDataList = (List<Warnings__c>) Database.query(query);
         return warningsDataList;
    }
    /**** New Code For CD-145 ********/ 
    @AuraEnabled
    public static  List<Rating_Modifiers__c>  getAnnualModifier(String oppId){
        List<Rating_Modifiers__c> rmRecords = [SELECT Opportunity__c, Rating_Modifier_Value__c, Name, Rating_Modifier_Code__c 
        FROM Rating_Modifiers__c where Name = 'Annual gross fees / turnover'
           AND Opportunity__c =:oppId];
           return rmRecords;
    }
    
   
    public class UWAlyProfessionWrapper {
        @AuraEnabled public List<UWAnalysisWrapper> uwAlyRecord     {get; set;}
		@AuraEnabled public String mainProfession              {get; set;}
    }
    public class UWAnalysisWrapper {
        @AuraEnabled public String identifier        {get; set;}
		@AuraEnabled public String name              {get; set;}                     
		@AuraEnabled public String criteria          {get; set;}               
		@AuraEnabled public String uwCode            {get; set;}             
		@AuraEnabled public Decimal ratingFactor     {get; set;}
		@AuraEnabled public Decimal sortOrder        {get; set;}
		@AuraEnabled public Decimal splitPercentage  {get; set;}
		@AuraEnabled public Decimal amount           {get; set;}
		@AuraEnabled public String opportynityId     {get; set;}
		@AuraEnabled public Decimal notonalIncome    {get; set;}
		@AuraEnabled public String templateId        {get; set;} 
        @AuraEnabled public String amountClass       {get; set;} 
        @AuraEnabled public String splitClass        {get; set;} 
        
        public UWAnalysisWrapper() {}

        public UWAnalysisWrapper(UW_Analysis__c uwAly) {
            this.identifier = uwAly.Id;
			this.name = uwAly.UW_Analysis_Name__c;
			this.criteria = uwAly.Criteria__c;
			this.uwCode = uwAly.UW_Analysis_Code__c;
			this.ratingFactor = uwAly.Rating_Factor__c;
			this.sortOrder = uwAly.Sort_Order__c;
			this.splitPercentage = uwAly.Split_Percentage__c;
			this.amount = uwAly.Amount__c;
			this.opportynityId = uwAly.Submission__c;
			this.notonalIncome = uwAly.Notional_Income__c;
			this.templateId = uwAly.UW_Analysis_Template__c;
            this.amountClass = uwAly.Id+'_amount';
            this.splitClass = uwAly.Id+'_split';
        }
    }
}