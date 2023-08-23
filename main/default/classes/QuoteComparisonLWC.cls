/**
 * @File Name          : QuoteComparisonLWCHang.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : Vinayesh
 * @Last Modified On   : 02-25-2022
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    3/18/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public with sharing class QuoteComparisonLWC {

    @AuraEnabled
    public static QuoteComparisonWrapper initValues(String submissionId, Boolean isPrimaryQuote) {
        QuoteComparisonLWC.QuoteComparisonWrapper quoteComparisonWrapper =  new QuoteComparisonLWC.QuoteComparisonWrapper();
        String layerName = isPrimaryQuote? 'Primary' : 'Excess';
        try{
            List<Opportunity> oppList = [Select Id,Name,Product_Name__c,StageName,Transaction_Status__c,Type,(Select Id,Name,Status,Quote_Type__c,Layer__c from Quotes),
                                         Effective_Date__c,Expiration_Date__c from Opportunity where Id=:submissionId];
            if(oppList.size() > 0) quoteComparisonWrapper.submission = oppList[0];
            // QuoteComparePageGenericController.QuoteResultItemWrapper result = new QuoteComparePageGenericController().getQuoteResultItemWrapper(submissionId,'Compare Quotes');
            //QuoteComparePageGenericController.QuoteResultItemWrapper result = new QuoteComparePageGenericController().getQuoteResultItemWrapper(submissionId,'Rate Quotes');
            QuoteComparePageGenericController.QuoteResultItemWrapper result = new QuoteComparePageGenericController().getQuoteResultItemWrapper(submissionId,'Rate Quotes',layerName);
            quoteComparisonWrapper.parents = getParentFromWrapper(result.mainSections);
            quoteComparisonWrapper.childIds = result.childIds;
            quoteComparisonWrapper.childNames = result.childNames;
            quoteComparisonWrapper.quoteCompareItems = result.quoteCompareItems;
            return  quoteComparisonWrapper;

        }catch (Exception ex){
            System.debug(ex.getMessage() + ex.getStackTraceString());
        }

        return quoteComparisonWrapper;
    }

    @AuraEnabled
    public static QuoteComparisonWrapper initValuesQC(String submissionId, Boolean isPrimaryQuote) {
        QuoteComparisonLWC.QuoteComparisonWrapper quoteComparisonWrapper =  new QuoteComparisonLWC.QuoteComparisonWrapper();
        String layerName = isPrimaryQuote? 'Primary' : 'Excess';
        try{
            List<Opportunity> oppList = [Select Id,Name,Product_Name__c,StageName,Transaction_Status__c,Type, Account.BillingStateCode,(Select Id,Name,Status,Quote_Type__c,Layer__c from Quotes),
                                         Effective_Date__c,Expiration_Date__c from Opportunity where Id=:submissionId];
            if(oppList.size() > 0) quoteComparisonWrapper.submission = oppList[0];
            // QuoteComparePageGenericController.QuoteResultItemWrapper result = new QuoteComparePageGenericController().getQuoteResultItemWrapper(submissionId,'Compare Quotes');
            //QuoteComparePageGenericController.QuoteResultItemWrapper result = new QuoteComparePageGenericController().getQuoteResultItemWrapper(submissionId,'Rate Quotes');
            QuoteComparePageGenericController.QuoteResultItemWrapper result = new QuoteComparePageGenericController().getQuoteResultItemWrapperQC(submissionId,'Quote Console');
            quoteComparisonWrapper.parents = getParentFromWrapper(result.mainSections);
            quoteComparisonWrapper.childIds = result.childIds;
            quoteComparisonWrapper.childNames = result.childNames;
            quoteComparisonWrapper.quoteCompareItems = result.quoteCompareItems;
            quoteComparisonWrapper.mainSections = result.mainSections;

            //used SOQL because getAll() returned only 255 characters for Long Text Area field
            List<AQ_Endorsements__mdt> lstAQEndorsementReasons = [SELECT Label, Endorsement_Reason__c FROM AQ_Endorsements__mdt];
            quoteComparisonWrapper.listOfAQEndorsementReasons = lstAQEndorsementReasons;

            return  quoteComparisonWrapper;

        }catch (Exception ex){
            System.debug(ex.getMessage() + ex.getStackTraceString());
        }

        return quoteComparisonWrapper;
    }

    @AuraEnabled
    public static ResultResponse updateQuote(String jsonWrapper, String quoteName) {
        ResultResponse response = new ResultResponse();
        try{
            System.debug('@@@jsonWrapper: ' + jsonWrapper + ' quoteName: ' + quoteName);
            QuoteComparisonWrapper items 
                    = (QuoteComparisonWrapper)JSON.deserialize(jsonWrapper, QuoteComparisonWrapper.class);
            System.debug('@@@items: ' + items);     
            
        }catch(Exception ex){
            System.debug('@@@Exception: ' + ex.getMessage());
            response.isSuccess = false;
            response.errors.add('@@@Exception: ' + ex.getMessage());
            response.data = null;
        }
        return response;
    }

    public static String getFieldType(String fieldName, String sObjectName){
        // Assume that "sObjectName" is populated elsewhere
        Schema.SObjectType t = Schema.getGlobalDescribe().get(sObjectName);
        
        Schema.DescribeSObjectResult r = t.getDescribe();
        Schema.DescribeFieldResult f = r.fields.getMap().get(fieldName).getDescribe();
        
        if (f.getType() == Schema.DisplayType.String){
            return 'String';
        }
        else if (f.getType() == Schema.DisplayType.Picklist){
            return 'Picklist';
        }
        return null;
    }
    

    public class QuoteComparisonWrapper {
        @AuraEnabled
        public Quote quote        {get;set;}
        @AuraEnabled
        public Opportunity submission        {get;set;}
        @AuraEnabled
        public List<Parent> parents        {get;set;}
        //
        @AuraEnabled
        public List<String> childIds {get; set;}
        @AuraEnabled
        public List<String> childNames {get; set;}
        @AuraEnabled
        public List<QuoteCompareItemWrapper> quoteCompareItems {get; set;}
        @AuraEnabled
        public List<QuoteComparePageGenericController.MainSection> mainSections {get; set;}
        @AuraEnabled
        public List<AQ_Endorsements__mdt> listOfAQEndorsementReasons {get; set;}

        public QuoteComparisonWrapper() {

        }
    }
    public class Parent {
        @AuraEnabled
        public String id            {get;set;}
        @AuraEnabled
        public String name          {get;set;}
        @AuraEnabled
        public String value         {get;set;}
        @AuraEnabled
        public boolean display      {get;set;}
        @AuraEnabled
        public String type          {get;set;}//pick list, text 
        @AuraEnabled
        public List<Child> childs   {get;set;}
        @AuraEnabled
        public Boolean isPicklist          {get;set;}
        @AuraEnabled
        public String quoteLayer          {get;set;}
        @AuraEnabled
        public List<PicklistOption> pickOptList          {get;set;}
        
        //
        @AuraEnabled
        public Boolean isField {get; set;}
        @AuraEnabled
        public List<String> fieldValues {get; set;}
        
        public Parent() {
            
        }
        public Parent(String id, String name, String value, String quoteLayer) {
            this.id = id;
            this.name = name;
            this.value = value;
            this.display = true;
            this.isPicklist = false;
            this.isField = false;
            this.quoteLayer = quoteLayer;
            this.fieldValues = new List<String>();
        }

    }

    public class Child {
        @AuraEnabled
        public String id      {get;set;}
        @AuraEnabled      
        public String name          {get;set;}
        @AuraEnabled
        public String value         {get;set;}
        @AuraEnabled
        public boolean display         {get;set;}
        @AuraEnabled
        public String type         {get;set;}//pick list, text
        @AuraEnabled
        public Boolean isPicklist          {get;set;}
        @AuraEnabled
        public List<PicklistOption> pickOptList          {get;set;}
        @AuraEnabled
        public String fieldObject {get; set;}
        @AuraEnabled
        public String min {get;set;}
        @AuraEnabled
        public String max {get;set;}
        @AuraEnabled
        public String quoteLayer {get;set;}

        public Child() {
            
        }

        public Child(String id, String name, String value) {
            this.id = id;
            this.name = name;
            this.value = value;
            this.display = true;
            this.isPicklist = false;
        }

    }

    public static List<QuoteComparisonLWC.Parent> getParentFromWrapper(List<QuoteComparePageGenericController.MainSection> mainSections ) {
        List<QuoteComparisonLWC.Parent> listParent = new List<QuoteComparisonLWC.Parent>();
        List<QuoteComparisonLWC.Child> listChild = new List<QuoteComparisonLWC.Child>();
        String currentSection = '';
        String quoteLayer = '';
        QuoteComparisonLWC.Parent par = new QuoteComparisonLWC.Parent();
        Integer mainSectionId = 1;
        Double subSectionId = 1;
        for(Integer i = 0; i < mainSections.size(); i++) {
            for(Integer j = 0; j < mainSections[i].fields.size(); j++) {
                subSectionId += 0.1;
                QuoteComparisonLWC.Child c = new QuoteComparisonLWC.Child(String.valueOf(subSectionId), mainSections[i].fields[j].sourceFieldLabel, '');
                c.fieldObject = mainSections[i].fields[j].sourceObject;
                c.min = mainSections[i].fields[j].min;
                c.max = mainSections[i].fields[j].max;
                c.quoteLayer = mainSections[i].fields[j].quoteLayer;
                listChild.add(c);
            }

            for(Integer j = 0; j < mainSections[i].subSections.size(); j++) {
                subSectionId += 0.1;
                QuoteComparisonLWC.Child child1 = new QuoteComparisonLWC.Child(String.valueOf(subSectionId), mainSections[i].subSections[j].name, '');
                listChild.add(child1);

                for(Integer k = 0; k < mainSections[i].subSections[j].fields.size(); k++) {
                    subSectionId += 0.01;
                    QuoteComparisonLWC.Child child2 = new QuoteComparisonLWC.Child(String.valueOf(subSectionId), mainSections[i].subSections[j].fields[k].sourceFieldLabel, '');
                    child2.fieldObject =  mainSections[i].subSections[j].fields[k].sourceObject;
                    child2.min =  mainSections[i].subSections[j].fields[k].min;
                    child2.max =  mainSections[i].subSections[j].fields[k].max;
                    child2.quoteLayer = mainSections[i].subSections[j].fields[k].quoteLayer;
                    listChild.add(child2);
                }
            }
            currentSection = mainSections[i].name;
            quoteLayer = mainSections[i].quoteLayer;
            mainSectionId++;
            subSectionId = Double.valueOf(mainSectionId);

            par = new QuoteComparisonLWC.Parent(String.valueOf(mainSectionId), currentSection, '', quoteLayer);
            par.childs = listChild;
            listParent.add(par);
            listChild = new List<QuoteComparisonLWC.Child>();
        }

        return listParent;

    }

    
}