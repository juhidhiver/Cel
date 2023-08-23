/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 01-24-2022
 * @last modified by  : Vinayesh
**/
public with sharing class QuoteCoverageTableController {
    public QuoteCoverageTableController() {

    }

    @AuraEnabled
    public static RelatedListWrapper fetchCoverageDetails(String quoteId){

        RelatedListWrapper objWrap = new RelatedListWrapper();

        Quote objQuote = [Select Id,Quote_Type__c, Status,Product_Name__c, OpportunityId, QuotePremium__c, Prior_Discount_Quote_Premium__c, Shared_Aggregate_Limit__c, Combined_Max_Agg_Limit_of_Liability__c from Quote where Id =: quoteId];

        List<String> productNames = new List<String>();// = {'D&O','EPL','Crime','Fiduciary'};

        Decimal requiredLimit;

        for(Product_Option_Line_Item__c objPOLI : [Select Id, Product__c, Product__r.Name, Is_Selected__c from Product_Option_Line_Item__c 
                                                    where Submission__c = :objQuote.OpportunityId and Is_Selected__c = true AND Clearance_Status__c = 'Cleared']){
                                                    
            productNames.add(objPOLI.Product__r.Name);

        }

        Map<String, Pre_Rate_Calculator_Setting__mdt> mapMetadataSettings = new Map<String, Pre_Rate_Calculator_Setting__mdt>();
        Pre_Rate_Calculator_Setting__mdt metadataSettingExcess  = new Pre_Rate_Calculator_Setting__mdt();
        for(Pre_Rate_Calculator_Setting__mdt metadataSettings : [Select Id, Active__c,  County_Table_Name__c, Industry_Modifier_Code__c, LimitILF_Table_Name__c, Policy_Retention_Table_Name__c, 
                                                            ProductName__c, SnT_Modifier_Code__c, Order__c, Coverage_Code__c, CLI_Type_Deductible_Option__c, CLI_Type_Limit_Option__c, 
                                                            CLI_Type_Main_Option__c, Exec_Coverage_Code__c, ExecLmtDedCode__c, LmtDedCode__c, LmtDedRetentionCode__c, Base_Rate_Table__c 
                                                            from Pre_Rate_Calculator_Setting__mdt order By Order__c Asc]){
                                                                if(productNames.contains(metadataSettings.ProductName__c)){
                                                                    //productNames.add(metadataSettings.ProductName__c);
                                                                    mapMetadataSettings.put(metadataSettings.ProductName__c, metadataSettings);
                                                                }
                                                                if(metadataSettings.ProductName__c == 'Excess'){
                                                                    metadataSettingExcess = metadataSettings;
                                                                }
                                                            }

        List<RecordDetails> lstRecordDetails = new List<RecordDetails>();
        for(String product : productNames){

            RecordDetails objRecordDetails = new RecordDetails();
            objRecordDetails.productName = product;
            Decimal technicalPremium = 0;
            Pre_Rate_Calculator_Setting__mdt metadataSettings = mapMetadataSettings.get(product);
            for(CoveragesLineItem__c covLineItem : [Select Id, Coverage_Premium__c, Coverage_Product__c, Coverage_Product_Combo__c,
                                        CoverageLineItemType__c, Quote__c, Override_Premium__c, Option_Value_Default__c, Coverage__c, 
                                        Coverage__r.Coverage_Code__c, Coverage__r.Coverage_Product__c, 
                                        Coverage__r.Name, Limits_Deductibles__c, Limits_Deductibles__r.Name, Limits_Deductibles__r.LmtDedCode__c 
                                        from CoveragesLineItem__c where Quote__c = : quoteId]){

                                            if(covLineItem.Coverage__r.Coverage_Code__c == metadataSettings.Coverage_Code__c && covLineItem.Limits_Deductibles__r.LmtDedCode__c == metadataSettings.LmtDedCode__c && covLineItem.CoverageLineItemType__c == metadataSettings.CLI_Type_Limit_Option__c){
                                                requiredLimit = covLineItem.Option_Value_Default__c != null ? Decimal.valueOf(covLineItem.Option_Value_Default__c) : 0;// update by Jitendra on 07-Jan-2022 for MAT-80
                                                objRecordDetails.requiredLimit = requiredLimit;
                                            }
                                            if(covLineItem.Coverage__r.Coverage_Code__c == metadataSettings.Coverage_Code__c && covLineItem.Limits_Deductibles__r.LmtDedCode__c == metadataSettings.LmtDedRetentionCode__c && covLineItem.CoverageLineItemType__c == metadataSettings.CLI_Type_Deductible_Option__c){
                                                objRecordDetails.policyRetention = covLineItem.Option_Value_Default__c != null ? Decimal.valueOf(covLineItem.Option_Value_Default__c) : 0;// update by Jitendra on 07-Jan-2022 for MAT-80
                                                
                                            }
                                            if(covLineItem.Coverage_Product_Combo__c == product && covLineItem.CoverageLineItemType__c == metadataSettings.CLI_Type_Main_Option__c){
                                                technicalPremium += covLineItem.Coverage_Premium__c != null ? Decimal.valueOf(covLineItem.Coverage_Premium__c) : 0;// update by Jitendra on 07-Jan-2022 for MAT-80
                                                objRecordDetails.actualPremium += covLineItem.Override_Premium__c != null? covLineItem.Override_Premium__c : 0;
                                            }
                                            /*if(product == 'D&O'){
                                                if(covLineItem.Coverage__r.Coverage_Code__c == 'DOCoverage'&& covLineItem.CoverageLineItemType__c == 'Main Coverage'){
                                                    objRecordDetails.technicalPremium = covLineItem.Coverage_Premium__c != null ? Decimal.valueOf(covLineItem.Coverage_Premium__c) : 0;// update by Jitendra on 07-Jan-2022 for MAT-80
                                                    objRecordDetails.actualPremium = covLineItem.Override_Premium__c != null ? covLineItem.Override_Premium__c : 0;
                                                }
                                                if(covLineItem.Coverage__r.Coverage_Code__c == 'DOCoverage' && covLineItem.Limits_Deductibles__r.LmtDedCode__c == 'DOMaxAggLOL' && covLineItem.CoverageLineItemType__c == 'Limit Option'){
                                                    requiredLimit = covLineItem.Option_Value_Default__c != null ? Decimal.valueOf(covLineItem.Option_Value_Default__c) : 0;// update by Jitendra on 07-Jan-2022 for MAT-80
                                                    objRecordDetails.requiredLimit = requiredLimit;
                                                }
                                                if(covLineItem.Coverage__r.Coverage_Code__c == 'DOCoverage' && covLineItem.Limits_Deductibles__r.LmtDedCode__c == 'DORetentionAmt' && covLineItem.CoverageLineItemType__c == 'Deductible Option'){
                                                    objRecordDetails.policyRetention = covLineItem.Option_Value_Default__c != null ? Decimal.valueOf(covLineItem.Option_Value_Default__c) : 0;// update by Jitendra on 07-Jan-2022 for MAT-80
                                                }
                                            }
                                            else if(product == 'EPL'){
                                                if(covLineItem.Coverage__r.Coverage_Code__c == 'EPLCoverage'&& covLineItem.CoverageLineItemType__c == 'Main Coverage'){
                                                    objRecordDetails.technicalPremium = covLineItem.Coverage_Premium__c != null ? Decimal.valueOf(covLineItem.Coverage_Premium__c) : 0;
                                                    objRecordDetails.actualPremium = covLineItem.Override_Premium__c != null ? covLineItem.Override_Premium__c : 0;
                                                }
                                                if(covLineItem.Coverage__r.Coverage_Code__c == 'EPLCoverage' && covLineItem.Limits_Deductibles__r.LmtDedCode__c == 'EPLMaxAggLOL' && covLineItem.CoverageLineItemType__c == 'Limit Option'){
                                                    requiredLimit = covLineItem.Option_Value_Default__c != null ? Decimal.valueOf(covLineItem.Option_Value_Default__c) : 0;
                                                    objRecordDetails.requiredLimit = requiredLimit;
                                                }
                                                if(covLineItem.Coverage__r.Coverage_Code__c == 'EPLCoverage' && covLineItem.Limits_Deductibles__r.LmtDedCode__c == 'EPLRetentionAmt' && covLineItem.CoverageLineItemType__c == 'Deductible Option'){
                                                    objRecordDetails.policyRetention = covLineItem.Option_Value_Default__c !=null ? Decimal.valueOf(covLineItem.Option_Value_Default__c) : 0;
                                                }
                                            }*/

                                        }

            objRecordDetails.technicalPremium = technicalPremium;
            lstRecordDetails.add(objRecordDetails);

        }

        objWrap.listRecordDetails = lstRecordDetails;
        objWrap.objQuote = objQuote;
        return objWrap;
        
    }

    @AuraEnabled
    public static String saveQuotePremium(Quote objQuote){

        String returnMsg = '';
        if(objQuote != null){
            update objQuote;
            returnMsg = 'success';
        }

        return returnMsg;

    }

    public class RelatedListWrapper {
        @AuraEnabled
        public List <RecordDetails> listRecordDetails;
        @AuraEnabled
        public Quote objQuote;
        @AuraEnabled
        public List <String> lstSelectedProduct;
    }

    public class RecordDetails {
        @AuraEnabled
        public String productName {get;set;}
        @AuraEnabled
        public Boolean isSectionHidden {get;set;}
        @AuraEnabled
        public Boolean isOptionalCoverage {get;set;}
        @AuraEnabled
        public String backgroundColorHeader {get;set;}
        @AuraEnabled
        public Decimal overallRatingModifier {get;set;}
        @AuraEnabled
        public Decimal requiredLimit{get;set;}
        @AuraEnabled
        public Decimal executiveLimit{get;set;}
        @AuraEnabled
        public Decimal policyRetention{get;set;}
        @AuraEnabled
        public Decimal technicalPremium{get;set;}
        @AuraEnabled
        public Decimal actualPremium{get;set;}
        @AuraEnabled
        public List<SObject> listRatingModifier{get;set;}

        public RecordDetails(){
            this.productName = '';
            this.isSectionHidden = false;
            this.isOptionalCoverage = false;
            this.backgroundColorHeader = 'slds-accordion__summary slds-box header-background-grey';
            this.overallRatingModifier = 0.0;
            this.requiredLimit = 0.0;
            this.technicalPremium = 0.0;
            this.policyRetention = 0.0;
            this.actualPremium = 0.0;
            listRatingModifier = new List<Rating_Modifier_Factor__c>();
        }
    }

}