public class RatingResponse {
    /*
   * Comment for new response on Oct 30
   * public Container ratingResponse {get;set;}
   * public RatingResponse() {
   * this.ratingResponse = new Container();
   * }
   * public class Container {
   * public QuoteWrapper quote {get;set;}
   * public OpportunityWrapper opportunity {get;set;}
   * public Container() {
   * this.quote = new QuoteWrapper();
   * this.opportunity = new OpportunityWrapper();
   * }
   * }
   */

    /*public RatingResponse() {
        this.quote = new QuoteWrapper();
        this.opportunity = new OpportunityWrapper();
        this.products = new Map<String, RatingResponse.CoverageLineItemWrapper>();
        this.ratingModifiers = new Map<String, List<RatingResponse.RatingModifier>>();
    }*/

    public QuoteWrapper quote {get;set;}
    public OpportunityWrapper opportunity {get;set;}
    public Map<String, RatingResponse.CoverageLineItemWrapper> products {get; set;}
    public Map<String, List<RatingResponse.RatingModifier>> ratingModifiers {get; set;}

    public class UWDescriptionsWrapper{
        public String uwcode;
        public String message_text;
    }
     public class QuoteWrapper1 {
        // public List<ProductConfigAttributes> productConfigAttributes;
        public Quote quote;
        public List<UWDescriptionsWrapper> overallUWDescriptions;
        public String overallUWCodes;
        // public Opportunity opportunity;
    }
    public class QuoteWrapper {
        //
        public String quote_Id {get;set;}
        public String coveragePremium {get;set;}
        public String acceptedTerrorism_Premium {get;set;}
        public String rejectedTerrorism_Premium {get;set;}
        public String selectedTerrorism_Premium {get;set;}
        public String productName {get;set;}
        public String writingCompany {get;set;}
        public String commission_Percentage {get;set;}
       
        public String azure_Id {get; set;}
        public String caT_Premium {get;set;}
        public String commissionAmount {get;set;}
        public String effective_Date {get; set;}
        public String expirationDate {get; set;}
        public String fees {get;set;}
        public String master_Set_Id {get;set;}
        public String nonProratedQuotePremium {get;set;}
        public String nonCAT_Premium {get;set;}
        //public String overallUWStatus {get;set;}
        public String productClassCd {get;set;}
        public String quoteNumber {get; set;}
        public String quotePremium {get;set;}
        public String quote_Type {get;set;}
        public String surcharge {get;set;}
        public String status {get;set;}
        public String taxes {get;set;}        
        public String technicalPremium {get;set;}              
        public String MPLQuotePremium {get;set;} // Quan Tran on 11-12-2019
        public String cyberQuotePremium {get;set;} // Quan Tran on 11-12-2019
        public List<String> overallUWCodes {get;set;}
        //public Map<String,CoverageLineItemWrapper> products {get; set;}  

        //
        public List<AccountWrapper> accounts {get;set;}
        public List<RatingModifier> ratingModifiers {get;set;}
        public List<OverallUWDescriptions> overallUWDescriptions {get;set;}
        public List<CoverageLineItemWrapper> coverageLineItems {get;set;}

        public QuoteWrapper() {
            //this.products = new Map<String,CoverageLineItemWrapper>();
            this.overallUWCodes = new List<String>();
        }

        public QuoteWrapper(Quote item) {
            if (item == null) {
                return;
            }

            this.azure_Id = item.Azure_ID__c;
            this.effective_Date = item.Effective_Date__c != null ?
                                 String.valueOf(item.Effective_Date__c) : null;
            //this.quoteNumber = item.QuoteNumber;
            this.expirationDate = item.ExpirationDate != null ?
                                  String.valueOf(item.ExpirationDate) : null;
            this.master_Set_Id = CommonUtil.convertToStringOrNull(item.Master_Set_ID__c);            
            this.mplquotepremium = CommonUtil.convertToString(item.MPLQuotePremium__c);  
            this.cyberQuotePremium = CommonUtil.convertToString(item.CyberQuotePremium__c);  
            //this.quoteType = CommonUtil.convertToStringOrNull(item.Quote_Type__c);
            //this.productClassCd = null;

            //this.products = new Map<String,CoverageLineItemWrapper>();
        }

        /*
      * ***********************************************
      * Author:Tuan Nguyen
      * Date: Oct 09 2019
      * Desciption: generate quote from quote wrapper
      * Revision:
      * ***********************************************
      */
        public Quote generateQuote() {
            Quote result = new Quote();
            system.debug(' generateQuote this -- '+this);
            try {
                if (this == null) {
                    return result;
                }

                result.Azure_ID__c = this.azure_Id;

                if (String.isNotBlank(this.commissionAmount)) {
                    result.Commission__c = Decimal.valueOf(this.commissionAmount);
                }

                if (String.isNotBlank(this.effective_Date)) {
                    result.Effective_Date__c = Date.valueOf(this.effective_Date);
                }

                if (String.isNotBlank(this.expirationDate)) {
                    result.ExpirationDate = Date.valueOf(this.expirationDate);
                }

                result.Master_Set_ID__c = this.master_Set_Id;

                if (String.isNotBlank(this.nonProratedQuotePremium)) {
                    result.Non_Prorated_Quote_Premium__c = Decimal.valueOf(this.nonProratedQuotePremium);
                }

                if (String.isNotBlank(this.quotePremium)) {
                    result.QuotePremium__c = Decimal.valueOf(this.quotePremium);
                }
               
                if (String.isNotBlank(this.MPLQuotePremium)) {
                    result.MPLQuotePremium__c = Decimal.valueOf(this.MPLQuotePremium);
                }
               
                if (String.isNotBlank(this.CyberQuotePremium)) {
                    result.CyberQuotePremium__c = Decimal.valueOf(this.CyberQuotePremium);
                }              

                result.Rating_Status__c = this.status;
               
                if (String.isNotBlank(this.taxes)) {
                    result.Tax = Decimal.valueOf(this.taxes);
                }

                if (this.overallUWCodes != null) {
                    result.Overall_UW_Codes__c = String.join(this.overallUWCodes, ';');
                }
               
                if (String.isNotBlank(this.MPLQuotePremium)) {
                    result.MPLQuotePremium__c = Decimal.valueOf(this.MPLQuotePremium);
                }                
               
                if (String.isNotBlank(this.cyberQuotePremium)) {
                    result.CyberQuotePremium__c = Decimal.valueOf(this.cyberQuotePremium);
                }
                if (String.isNotBlank(this.surcharge)){
                    result.Surcharges__c = Decimal.valueOf(this.surcharge);
                }

                //tuan.d.nguyen added 17-Jun-2020
                result.Quote_Type__c = this.quote_Type;
                result.Id = this.quote_Id;  
                if (String.isNotBlank(this.acceptedTerrorism_Premium)) {
                    result.Accept_Terror_Premium__c = Decimal.valueOf(this.acceptedTerrorism_Premium);
                }    
           
                if (String.isNotBlank(this.commission_Percentage)) {
                    result.Commission_percentage__c = Decimal.valueOf(this.commission_Percentage);
                }    
                if (String.isNotBlank(this.technicalPremium)) {
                    result.Technical_Premium__c = Decimal.valueOf(this.technicalPremium);
                }
                if (this.overallUWDescriptions != null && !this.overallUWDescriptions.isEmpty()) {
                    String uwReason = '';
                    for (OverallUWDescriptions description : this.overallUWDescriptions ) {
                        uwReason += description.message_text + '\n';
                    }
                    result.UW_Reason__c = uwReason;
                }
                else{
          result.UW_Reason__c = null;
        }


                } catch (Exception ex) {
                throw new Warnings.RatingException('Failed to generate Quote from response.');
            }
            return result;
        }

        public Boolean isExist() {
            String obj = 'Quote';
            return RatingResponse.isExist(obj, this.azure_Id);
        }
    }

    /*
   * ***********************************************
   * Author:Tuan Nguyen
   * Date: Nov 1 2019
   * Desciption: new mock response on Oct 30
   * Revision:
   * ***********************************************
   */


    public class CoverageLineItemWrapper{
        public List<CoverageItem> CoverageLineItems {
            get;set;
        }

        //tuan.d.nguyen added 17-Jun-2020
        public String id {get;set;}
    public String coverage {get;set;}
    public String name {get;set;}
    public String coverage_Code {get;set;}
    public String coverage_Premium {get;set;}
    public String override_Premium {get;set;}
    public String non_Prorated_Coverage_Premium {get;set;}
    public String override_Premium_Percent {get;set;}
    public List<String> option_Picklist {get;set;}
    public String option_Value_Default {get;set;}
    public String min_Amt {get;set;}
    public String max_Amt {get;set;}
    public String increment_Step {get;set;}
    public String is_Included {get;set;}
    public String option_Type {get;set;}
    public String code {get;set;}

        public CoverageLineItemWrapper() {
            this.CoverageLineItems = new List<CoverageItem>();
        }
    }

    public virtual class CoverageClass extends LimitDeductible {

    }

    public class CoverageItem extends CoverageClass {
        public String coverageCode {
            get; set;
        }
        public String coverageName {
            get; set;
        }
        public List<SubCoverageItem> subCoverages {
            get; set;
        }
        public List<LimitItem> limits {
            get; set;
        }
        public List<DeductibleItem> deductibles {
            get; set;
        }

        public CoverageItem() {
            this.coverageCode = '';
            this.coverageName = '';
            this.subCoverages = new List<SubCoverageItem>();
            this.limits = new List<LimitItem>();
            this.deductibles = new List<DeductibleItem>();
        }

        /*
      * ***********************************************
      * Author:Tuan Nguyen
      * Date: Oct 09 2019
      * Desciption: generate Coverage Line Item from Main Coverage
      * Revision:
      * ***********************************************
      */
        public override CoveragesLineItem__c generateCoverageLineItem() {
            CoveragesLineItem__c result = new CoveragesLineItem__c();
            try {
                if (this == null) {
                    return result;
                }

                result.Azure_ID__c = this.azureId;
                result.Coverage_Premium__c = this.coveragePremium;

                if (String.isNotBlank(this.factorDefaultValue)) {
                    result.Factor_Default_Value__c = Decimal.valueOf(this.factorDefaultValue);
                }

                if (String.isNotBlank(this.factorMax)) {
                    result.Factor_Max__c = Decimal.valueOf(this.factorMax);
                }

                if (String.isNotBlank(this.factorMin)) {
                    result.Factor_Min__c = Decimal.valueOf(this.factorMin);
                }

                if (String.isNotBlank(this.factorValue)) {
                    result.Factor_Value__c = Decimal.valueOf(this.factorValue);
                }

                if (String.isNotBlank(this.included)) {
                    result.IsIncluded__c = Boolean.valueOf(this.included);
                }

                if (String.isNotBlank(this.overridePremium)) {
                    result.Override_Premium__c = Decimal.valueOf(this.overridePremium);
                }
            } catch (Exception ex) {
                System.debug(ex.getMessage());
                String msg = 'Coverage ' + this.coverageName;
                throw new Warnings.RatingException(msg);
            }
            return result;
        }

        /*
      * ***********************************************
      * Author:Tuan Nguyen
      * Date: Oct 09 2019
      * Desciption: get Coverage Line Item from Main Coverage and all childs
      * Revision:
      * ***********************************************
      */
        public List<CoveragesLineItem__c> getCoverageLineItems() {
            return RatingResponse.getCoverageLineItems(this);
        }
    }

    public class SubCoverageItem extends CoverageClass {
        public String subCoverageCode {
            get; set;
        }
        public String subCoverageName {
            get; set;
        }
        public List<LimitItem> limits {
            get; set;
        }
        public List<DeductibleItem> deductibles {
            get; set;
        }

        public SubCoverageItem() {
            this.limits = new List<LimitItem>();
            this.deductibles = new List<DeductibleItem>();
        }

        /*
      * ***********************************************
      * Author:Tuan Nguyen
      * Date: Oct 09 2019
      * Desciption: generate Coverage Line Item from Sub Coverage
      * Revision:
      * ***********************************************
      */
        public override CoveragesLineItem__c generateCoverageLineItem() {
            CoveragesLineItem__c result = new CoveragesLineItem__c();
            try {
                if (this == null) {
                    return result;
                }

                result.Azure_ID__c = this.azureId;
                result.Coverage_Premium__c = this.coveragePremium;

                if (String.isNotBlank(this.factorDefaultValue)) {
                    result.Factor_Default_Value__c = Decimal.valueOf(this.factorDefaultValue);
                }

                if (String.isNotBlank(this.factorMax)) {
                    result.Factor_Max__c = Decimal.valueOf(this.factorMax);
                }

                if (String.isNotBlank(this.factorMin)) {
                    result.Factor_Min__c = Decimal.valueOf(this.factorMin);
                }

                if (String.isNotBlank(this.factorValue)) {
                    result.Factor_Value__c = Decimal.valueOf(this.factorValue);
                }

                if (String.isNotBlank(this.included)) {
                    result.IsIncluded__c = Boolean.valueOf(this.included);
                }

                if (String.isNotBlank(this.overridePremium)) {
                    result.Override_Premium__c = Decimal.valueOf(this.overridePremium);
                }
            } catch (Exception ex) {
                System.debug(ex.getMessage());
                String msg = 'Sub Coverage ' + this.subCoverageName;
                throw new Warnings.RatingException(msg);
            }
            return result;
        }

        /*
      * ***********************************************
      * Author:Tuan Nguyen
      * Date: Oct 09 2019
      * Desciption: get Coverage Line Item from Sub Coverage and all iof its childs
      * Revision:
      * ***********************************************
      */
        public List<CoveragesLineItem__c> getCoverageLineItems() {
            return RatingResponse.getCoverageLineItems(this);
        }
    }

    public virtual class LimitDeductible {
        public String azureId {
            get;set;
        }
        public String coveragePremium {
            get;set;
        }
        public String factorDefaultValue {
            get;set;
        }
        public String factorMax {
            get;set;
        }
        public String factorMin {
            get;set;
        }
        public String factorValue {
            get;set;
        }
        public String included {
            get;set;
        }
        public String overridePremium {
            get;set;
        }

        public virtual CoveragesLineItem__c generateCoverageLineItem() {
            return new CoveragesLineItem__c();
        }
    }

    public class LimitItem extends LimitDeductible {
        public String limitName {
            get; set;
        }
        public String increment {
            get; set;
        }
        public String maxAmt {
            get; set;
        }
        public String minAmt {
            get; set;
        }
        public String optionType {
            get; set;
        }
        public String optionValueDefault {
            get; set;
        }
        public List<String> optionList {
            get;set;
        }

        public LimitItem() {
            this.optionList = new List<String>();
        }

        /*
      * ***********************************************
      * Author:Tuan Nguyen
      * Date: Oct 09 2019
      * Desciption: generate Coverage Line Item from LimitItem wrapper
      * Revision:
      * ***********************************************
      */
        public override CoveragesLineItem__c generateCoverageLineItem() {
            CoveragesLineItem__c result = new CoveragesLineItem__c();
            try {
                if (this == null) {
                    return result;
                }

                result.Azure_ID__c = this.azureId;
                result.Coverage_Premium__c = this.coveragePremium;

                if (String.isNotBlank(this.factorDefaultValue)) {
                    result.Factor_Default_Value__c = Decimal.valueOf(this.factorDefaultValue);
                }

                if (String.isNotBlank(this.factorMax)) {
                    result.Factor_Max__c = Decimal.valueOf(this.factorMax);
                }

                if (String.isNotBlank(this.factorMin)) {
                    result.Factor_Min__c = Decimal.valueOf(this.factorMin);
                }

                if (String.isNotBlank(this.factorValue)) {
                    result.Factor_Value__c = Decimal.valueOf(this.factorValue);
                }

                if (String.isNotBlank(this.included)) {
                    result.IsIncluded__c = Boolean.valueOf(this.included);
                }

                if (String.isNotBlank(this.increment)) {
                    result.Increment_Step__c = Decimal.valueOf(this.increment);
                }

                if (String.isNotBlank(this.minAmt)) {
                    result.Min_amt__c = Decimal.valueOf(this.minAmt);
                }

                if (String.isNotBlank(this.maxAmt)) {
                    result.Max_amt__c = Decimal.valueOf(this.maxAmt);
                }

                if (String.isNotBlank(this.optionType)) {
                    result.Option_Type__c = this.optionType;
                }

                if (String.isNotBlank(this.optionValueDefault)) {
                    result.Option_Value_Default__c = this.optionValueDefault;
                }

                if (String.isNotBlank(this.overridePremium)) {
                    result.Override_Premium__c = Decimal.valueOf(this.overridePremium);
                }

                if (this.optionList != null) {
                    result.Option_Picklist__c = String.join(this.optionList, ';');
                }
            } catch (Exception ex) {
                System.debug(ex.getMessage());
                String msg = 'Limit ' + this.limitName;
                throw new Warnings.RatingException(msg);
            }
            return result;
        }
    }

    public class DeductibleItem extends LimitDeductible {
        public String deductibleName {
            get; set;
        }
        public String increment {
            get; set;
        }
        public String maxAmt {
            get; set;
        }
        public String minAmt {
            get; set;
        }
        public String optionType {
            get; set;
        }
        public String optionValueDefault {
            get; set;
        }
        public List<String> optionList {
            get;set;
        }

        public DeductibleItem() {
            this.optionList = new List<String>();
        }

        /*
      * ***********************************************
      * Author:Tuan Nguyen
      * Date: Oct 09 2019
      * Desciption: generate Coverage Line Item from Deductible wrapper
      * Revision:
      * ***********************************************
      */
        public override CoveragesLineItem__c generateCoverageLineItem() {
            CoveragesLineItem__c result = new CoveragesLineItem__c();
            try {
                if (this == null) {
                    return result;
                }

                if (String.isNotBlank(this.azureId)) {
                    result.Azure_ID__c = this.azureId;
                }

                if (String.isNotBlank(this.coveragePremium)) {
                    result.Coverage_Premium__c = this.coveragePremium;
                }

                if (String.isNotBlank(this.factorDefaultValue)) {
                    result.Factor_Default_Value__c = Decimal.valueOf(this.factorDefaultValue);
                }

                if (String.isNotBlank(this.factorMax)) {
                    result.Factor_Max__c = Decimal.valueOf(this.factorMax);
                }

                if (String.isNotBlank(this.factorMin)) {
                    result.Factor_Min__c = Decimal.valueOf(this.factorMin);
                }

                if (String.isNotBlank(this.factorValue)) {
                    result.Factor_Value__c = Decimal.valueOf(this.factorValue);
                }

                if (String.isNotBlank(this.included)) {
                    result.IsIncluded__c = Boolean.valueOf(this.included);
                }

                if (String.isNotBlank(this.increment)) {
                    result.Increment_Step__c = Decimal.valueOf(this.increment);
                }

                if (String.isNotBlank(this.minAmt)) {
                    result.Min_amt__c = Decimal.valueOf(this.minAmt);
                }

                if (String.isNotBlank(this.maxAmt)) {
                    result.Max_amt__c = Decimal.valueOf(this.maxAmt);
                }

                if (String.isNotBlank(this.optionType)) {
                    result.Option_Type__c = this.optionType;
                }

                if (String.isNotBlank(this.optionValueDefault)) {
                    result.Option_Value_Default__c = this.optionValueDefault;
                }

                if (String.isNotBlank(this.overridePremium)) {
                    result.Override_Premium__c = Decimal.valueOf(this.overridePremium);
                }

                if (this.optionList != null) {
                    result.Option_Picklist__c = String.join(this.optionList, ';');
                }
            } catch (Exception ex) {
                System.debug(ex.getMessage());
                String msg = 'Deductible ' + this.deductibleName;
                throw new Warnings.RatingException(msg);
            }
            return result;
        }
    }

    public class OpportunityWrapper {
        public String annualRevenue {
            get; set;
        }
        public String attachmentPoint {
            get;set;
        }
        public String cashFlow {
            get; set;
        }
        public String currentAssets {
            get; set;
        }
        public String currentLiabilities {
            get; set;
        }
        public String longTermDebt {
            get; set;
        }
        public String netIncome {
            get; set;
        }
        public String opportunityAzureId {
            get; set;
        }
        public String opportunityName {
            get; set;
        }
        public String retainedErning {
            get; set;
        }
        public String shareHoldersEquity {
            get; set;
        }
        public String totalAssets {
            get; set;
        }
        public String totalLiabilities {
            get; set;
        }
        public String totalRevenues {
            get; set;
        }
        //public AccountWrapper account {get;set;}
        //public Map<String,List<RatingModifier>> products {get; set;}

        public OpportunityWrapper() {
            //this.account = new AccountWrapper();
            //this.products = new Map<String,List<RatingModifier>>();
        }

        /*
      * ***********************************************
      * Author:Tuan Nguyen
      * Date: Oct 09 2019
      * Desciption: generate opportunity from Opportunity wrapper
      * Revision:
      * ***********************************************
      */
        public Opportunity generateOpportunity() {
            Opportunity result = new Opportunity();
            try {
                if (this == null) {
                    return result;
                }

                result.Azure_ID__c = this.opportunityAzureId;
                result.Name = this.opportunityName;

                if (String.isNotBlank(this.annualRevenue)) {
                    result.AnnualRevenue__c = Decimal.valueOf(this.annualRevenue);
                }

                if (String.isNotBlank(this.attachmentPoint)) {
                    result.Attachment_Point__c = this.attachmentPoint;
                }

                if (String.isNotBlank(this.cashFlow)) {
                    result.Cash_Flow_From_Operating_Activities__c = Decimal.valueOf(this.cashFlow);
                }

                if (String.isNotBlank(this.currentAssets)) {
                    result.Current_Assets__c = Decimal.valueOf(this.currentAssets);
                }

                if (String.isNotBlank(this.currentLiabilities)) {
                    result.Current_Liabilities__c = Decimal.valueOf(this.currentLiabilities);
                }

                if (String.isNotBlank(this.longTermDebt)) {
                    result.Long_Term_Debt__c = Decimal.valueOf(this.longTermDebt);
                }

                if (String.isNotBlank(this.netIncome)) {
                    result.Net_Income__c = Decimal.valueOf(this.netIncome);
                }

                if (String.isNotBlank(this.retainedErning)) {
                    result.Retained_Earnings__c = Decimal.valueOf(this.retainedErning);
                }

                if (String.isNotBlank(this.shareHoldersEquity)) {
                    result.Shareholders_Equity__c = Decimal.valueOf(this.shareHoldersEquity);
                }

                if (String.isNotBlank(this.totalAssets)) {
                    result.Total_Assets__c = Decimal.valueOf(this.totalAssets);
                }

                if (String.isNotBlank(this.totalLiabilities)) {
                    result.Total_Liabilities__c = Decimal.valueOf(this.totalLiabilities);
                }

                if (String.isNotBlank(this.totalRevenues)) {
                    result.Total_Revenues__c = Decimal.valueOf(this.totalRevenues);
                }

            } catch (Exception ex) {
                throw new Warnings.RatingException('Failed to generate Opportunity from response.');
            }
            return result;
        }

        public Boolean isExist() {
            String obj = 'Opportunity';
            return RatingResponse.isExist(obj, this.opportunityAzureId);
        }
    }

    public class AccountWrapper {
        public String azureID {
            get; set;
        }
        public String name {
            get; set;
        }
        public Address billingAddress {
            get; set;
        }
        public String dunsNumber {
            get; set;
        }
        public String compositCredit {
            get;set;
        }
        public String dBRatingClassification {
            get;set;
        }
        //tuan.d.nguyen added 17-Jun-2020
        public String id {
            get; set;
        }
        public String azure_ID {
            get; set;
        }
        public PrimaryAddress primaryAddress {
            get; set;
        }

        public AccountWrapper() {

        }

        /*
      * ***********************************************
      * Author:Tuan Nguyen
      * Date: Oct 09 2019
      * Desciption: Generate Account from Account
      * Revision:
      * ***********************************************
      */
        public Account generateAccount() {
            Account result = new Account();
            try {
                result.Azure_ID__c = this.azureId;
                result.Name = this.name;

                if (this.billingAddress != null) {
                    result.BillingStreet = this.billingAddress.street;
                    result.BillingCity = this.billingAddress.city;
                    result.BillingState = this.billingAddress.state;
                    result.BillingPostalCode = this.billingAddress.postalCode;
                    result.BillingCountry = this.billingAddress.country;
                    result.BillingLatitude = this.billingAddress.latitude;
                    result.BillingLongitude = this.billingAddress.longitude;
                }

                if (String.isNotBlank(this.compositCredit)) {
                    result.Composite_Credit_Appraisal__c = this.compositCredit;
                }

                if (String.isNotBlank(this.dunsNumber)) {
                    result.Duns_Number__c = this.dunsNumber;
                }

                if (String.isNotBlank(this.dBRatingClassification)) {
                    result.D_B_Rating_Classification__c = this.dBRatingClassification;
                }

            } catch (Exception ex) {
                System.debug(ex.getMessage());
                result = new Account();
            }

            return result;
        }
    }

    public class RatingModifier {
        public String azureID {
            get; set;
        }
        public String ratingModifierCode {
            get; set;
        }
        public String ratingModifierName {
            get; set;
        }
        public String ratingModifierValue {
            get; set;
        }
        public String factorMin {
            get; set;
        }
        public String factorMax {
            get; set;
        }
        public String factorValue {
            get; set;
        }
        public String format {
            get; set;
        }
        public String factordefaultValue {
            get; set;
        }
        //tuan.d.nguyen added 17-Jun-2020
        public String defaultValue {
            get; set;
        }
        public RatingModifier() {

        }

        public RatingModifier(Rating_Modifiers__c item) {
            if (item == null) return;

            this.azureID = CommonUtil.convertToStringOrNull(item.Azure_ID__c);
            this.ratingModifierName = CommonUtil.convertToStringOrNull(item.Name);
            this.ratingModifierValue = CommonUtil.convertToStringOrNull(item.Rating_Modifier_Value__c);
            //this.factorMin = CommonUtil.convertToStringOrNull(item.Factor_Min__c);
            //this.factorMax = CommonUtil.convertToStringOrNull(item.Factor_Max__c);
            //this.factorValue = CommonUtil.convertToStringOrNull(item.Factor_Value__c);
            this.format = CommonUtil.convertToStringOrNull(item.Format__c);
            //this.factordefaultValue = CommonUtil.convertToStringOrNull(item.Factor_Default_Value__c);
        }

        /*
      * ***********************************************
      * Author:Tuan Nguyen
      * Date: Nov 11 2019
      * Desciption: generate Rating Modifier from Rating Modifier wrapper
      * Revision:
      * ***********************************************
      */
        public Rating_Modifiers__c generateRatingModifier() {
            Rating_Modifiers__c result = new Rating_Modifiers__c();
            try {
                if (this == null) {
                    return result;
                }

                result.Azure_ID__c = this.azureID;
                result.Name = this.ratingModifierName;

                if (String.isNotBlank(this.ratingModifierValue)) {
                    result.Rating_Modifier_Value__c = this.ratingModifierValue;
                }

                if (String.isNotBlank(this.factordefaultValue)) {
                    //result.Factor_Default_Value__c = Decimal.valueOf(this.factordefaultValue);
                }

                if (String.isNotBlank(this.factorMax)) {
                    //result.Factor_Max__c = Decimal.valueOf(this.factorMax);
                }

                if (String.isNotBlank(this.factorMin)) {
                    //result.Factor_Min__c = Decimal.valueOf(this.factorMin);
                }

                if (String.isNotBlank(this.factorValue)) {
                    //result.Factor_Value__c = Decimal.valueOf(this.factorValue);
                }

                if (String.isNotBlank(this.format)) {
                    result.Format__c = this.format;
                }

            } catch (Exception ex) {
                throw new Warnings.RatingException('Failed to generate Rating Modifier from response.');
            }
            return result;
        }
    }

    /*
   * ***********************************************
   * Author:Tuan Nguyen
   * Date: Oct 09 2019
   * Desciption: Check whether object is exist
   * Revision:
   * ***********************************************
   */
    public static Boolean isExist(String obj, String azureId) {
        Boolean result = false;
        try {
            List<String> fields = new List<String>();
            fields.add('Id');

            String condition = ' Azure_ID__c = \'' + azureId + '\'';
            String query = CommonUtil.buildQuery(fields, obj, condition);

            List<sObject> items = Database.query(query);

            if (!items.isEmpty()) {
                result = true;
            }
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            result = false;
        }
        return result;
    }

    /*
   * ***********************************************
   * Author:Tuan Nguyen
   * Date: Oct 09 2019
   * Desciption: get Coverage Line Item for all Main Coverage and its childs
   * Revision:
   * ***********************************************
   */
    public List<CoveragesLineItem__c> getCoverageLineItems() {
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        String product = '';

        try {
            if (this.products == null) {
                return result;
            }

            for (String key : this.products.keySet()) {
                product = key;
                List<CoveragesLineItem__c> covItems = getCoverageLineItems(this.products.get(key));
                result.addAll(covItems);
            }
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            String msg = 'Failed to convert Coverage Line Item for ' + product + ' - ' + ex.getMessage();
            throw new Warnings.RatingException(msg);
        }
        return result;
    }

    /*
   * ***********************************************
   * Author:Tuan Nguyen
   * Date: Oct 11 2019
   * Desciption: get Rating Modifiers for all product
   * Revision:
   * ***********************************************
   */
    public List<Rating_Modifiers__c> getRatingModifiers() {
        List<Rating_Modifiers__c> result = new List<Rating_Modifiers__c>();
        String product = '';

        try {
            if (this.ratingModifiers == null) {
                return result;
            }

            // loop through each product
            for (String key : this.ratingModifiers.keySet()) {
                product = key;
                // get rating modifiers for this product
                List<RatingModifier> items = this.ratingModifiers.get(key);

                // generate rating modifier from its wrapper
                for (RatingModifier item : items) {
                    Rating_Modifiers__c obj = item.generateRatingModifier();
                    result.add(obj);
                }
            }
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            String msg = 'Failed to convert Rating modifiers for ' + product + ' - ' + ex.getMessage();
            throw new Warnings.RatingException(msg);
        }
        return result;
    }

    /*
   * ***********************************************
   * Author:Tuan Nguyen
   * Date: Oct 09 2019
   * Desciption: get Coverage Line Item for all Main Coverage and its childs
   * Revision:
   * ***********************************************
   */
    public static List<CoveragesLineItem__c> getCoverageLineItems(CoverageLineItemWrapper obj) {
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        try {
            if (obj == null) {
                return result;
            }

            for (CoverageItem item : obj.coverageLineItems) {
                List<CoveragesLineItem__c> covItems = getCoverageLineItems(item);
                result.addAll(covItems);
            }
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            throw new Warnings.RatingException(ex.getMessage());
        }
        return result;
    }

    /*
   * ***********************************************
   * Author:Tuan Nguyen
   * Date: Oct 09 2019
   * Desciption: get Coverage Line Item for a Main Coverage and its childs
   * Revision:
   * ***********************************************
   */
    public static List<CoveragesLineItem__c> getCoverageLineItems(Coverageitem obj) {
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        try {
            if (obj == null) {
                return result;
            }

            // add main coverage
            result.add(obj.generateCoverageLineItem());

            // get coverage line item for limit
            List<CoveragesLineItem__c> limitItems = getCoverageLineItems(obj.limits);
            // get coverage line item for deductible
            List<CoveragesLineItem__c> deductItems = getCoverageLineItems(obj.deductibles);
            List<CoveragesLineItem__c> subItems = new List<CoveragesLineItem__c>();

            // get coverage line item for sub coverage
            for (SubCoverageItem subItem : obj.subCoverages) {
                subItems = getCoverageLineItems(subItem);
                result.addAll(subItems);
            }

            result.addAll(limitItems);
            result.addAll(deductItems);
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            throw new Warnings.RatingException(ex.getMessage());
        }
        return result;
    }

    /*
   * ***********************************************
   * Author:Tuan Nguyen
   * Date: Oct 09 2019
   * Desciption: get Coverage Line Item for a Sub Coverage and its childs
   * Revision:
   * ***********************************************
   */
    public static List<CoveragesLineItem__c> getCoverageLineItems(SubCoverageitem obj) {
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        try {
            if (obj == null) {
                return result;
            }
            // get coverage line item for sub coverage
            result.add(obj.generateCoverageLineItem());
            // get coverage line item for limit
            List<CoveragesLineItem__c> limitItems = getCoverageLineItems(obj.limits);
            // get coverage line item for deductible
            List<CoveragesLineItem__c> deductItems = getCoverageLineItems(obj.deductibles);

            result.addAll(limitItems);
            result.addAll(deductItems);
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            throw new Warnings.RatingException(ex.getMessage());
        }
        return result;
    }

    /*
   * ***********************************************
   * Author:Tuan Nguyen
   * Date: Oct 09 2019
   * Desciption: get Coverage Line Item for LimitAndDeductible
   * Revision:
   * ***********************************************
   */
    public static List<CoveragesLineItem__c> getCoverageLineItems(List<LimitDeductible> items) {
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        try {
            if (items == null || items.isEmpty()) {
                return result;
            }
            // get coverage line item for limit deductible
            for (LimitDeductible item : items) {
                result.add(item.generateCoverageLineItem());
            }

        } catch (Exception ex) {
            System.debug(ex.getMessage());
            throw new Warnings.RatingException(ex.getMessage());
        }
        return result;
    }

    /*
   * ***********************************************
   * Author:Tuan Nguyen
   * Date: NOV 11 2019
   * Desciption: FOR TESTING PURPOSE. REMOVE AFTER DONE TESTING
   * Revision:
   * ***********************************************
   */
    public static HttpResponse createResponse(Integer statusCode, String body) {
        HttpResponse result = new HttpResponse();

        result.setHeader('Content-Type', 'application/json');
        result.setStatusCode(statusCode);
        result.setBody(body);

        return result;
    }

    /*
   * ***********************************************
   * Author:Tuan Nguyen
   * Date: NOV 11 2019
   * Desciption: FOR TESTING PURPOSE. REMOVE AFTER DONE TESTING
   * Revision:
   * ***********************************************
   */
    public static HTTPResponse generateRatingResponse(String body) {
        HTTPResponse res = new HttpResponse();

        try {
            RatingRequest obj = (RatingRequest)JSON.deserialize(body, RatingRequest.class);

            Date today = System.today();
            RatingResponse.QuoteWrapper quote = new RatingResponse.QuoteWrapper();
            quote.azure_Id = obj.quote.quoteAzureId;
            quote.caT_Premium = '123';
            quote.commissionAmount = '1234';
            quote.effective_Date = today.format();
            quote.expirationDate = today.addDays(7).format();
            quote.fees = '1234';
            quote.master_Set_Id = 'abc';
            quote.nonProratedQuotePremium = '123';
            quote.nonCAT_Premium = '4321';
            quote.quotePremium = '2000';
            quote.surcharge = '1000';
            quote.status = 'Rated';
            quote.taxes = '246';
            quote.technicalPremium = '369';

            RatingResponse.OpportunityWrapper opp = new RatingResponse.OpportunityWrapper();
            opp.opportunityAzureId = obj.opportunity.opportunityAzureId;
            opp.opportunityName = obj.opportunity.opportunityName;
            opp.netIncome = '123';
            opp.shareHoldersEquity = '1234';
            opp.cashFlow = '12345';
            opp.retainedErning = '123456';
            opp.annualRevenue = '1235';
            opp.totalRevenues = '1236';
            opp.currentAssets = '1237';
            opp.totalAssets = '1238';
            opp.longTermDebt = '1239';
            opp.currentLiabilities = '1230';
            opp.totalLiabilities = '124';
            opp.attachmentPoint = 'Primary';

            Map<String, RatingResponse.CoverageLineItemWrapper> products =
                    new Map<String, RatingResponse.CoverageLineItemWrapper>();
            for (String key : obj.quote.products.keySet()) {
                RatingRequest.CoverageProductWrapper item = obj.quote.products.get(key);
                RatingResponse.CoverageLineItemWrapper newItem = new RatingResponse.CoverageLineItemWrapper();
                Integer i = 0;
                // generate main coverage
                for (RatingRequest.CoverageItem cov : item.CoverageLineItems) {
                    RatingResponse.CoverageItem newCov = new RatingResponse.CoverageItem();
                    newCov.coverageCode = cov.coverageCode;
                    newCov.azureId = cov.azureId;
                    newCov.coveragePremium = cov.coveragePremium;
                    newCov.factorDefaultValue = cov.factorDefaultValue;
                    newCov.factorMax = cov.factorMax;
                    newCov.factorMin = cov.factorMin;
                    newCov.factorValue = cov.factorValue;
                    newCov.overridePremium = cov.overridePremium;
                    newCov.included = 'true';

                    // generate sub Coverage
                    for (RatingRequest.SubCoverageItem subCov : cov.subCoverages) {
                        RatingResponse.SubCoverageItem newSubCov = new RatingResponse.SubCoverageItem();
                        newSubCov.subCoverageCode = subCov.subCoverageCode;
                        newSubCov.azureId = subCov.azureId;
                        newSubCov.coveragePremium = subCov.coveragePremium;
                        newSubCov.factorDefaultValue = subCov.factorDefaultValue;
                        newSubCov.factorMax = subCov.factorMax;
                        newSubCov.factorMin = subCov.factorMin;
                        newSubCov.factorValue = subCov.factorValue;
                        newSubCov.overridePremium = subCov.overridePremium;
                        newSubCov.included = 'true';

                        i = 0;
                        // generate limit
                        for (RatingRequest.LimitDeductible lim : subCov.limits) {

                            RatingResponse.LimitItem newLim = new RatingResponse.LimitItem();
                            newLim.limitName = 'limit' + String.valueOf(i++);
                            newLim.azureId = lim.azureId;
                            newLim.coveragePremium = lim.coveragePremium;
                            newLim.factorDefaultValue = lim.factorDefaultValue;
                            newLim.factorMax = lim.factorMax;
                            newLim.factorMin = lim.factorMin;
                            newLim.factorValue = lim.factorValue;
                            newLim.increment = '1';
                            newLim.minAmt = '2';
                            newLim.maxAmt = '3';
                            newLim.optionType = 'Range';
                            newLim.optionValueDefault = '1';
                            newLim.overridePremium = lim.overridePremium;
                            newLim.optionList = new List<String>{'1', '2'};
                            newSubCov.limits.add(newLim);
                        }

                        i = 0;
                        // generate limit
                        for (RatingRequest.LimitDeductible ded : subCov.deductibles) {

                            RatingResponse.DeductibleItem newDed = new RatingResponse.DeductibleItem();
                            newDed.deductibleName = 'deductible' + String.valueOf(i++);
                            newDed.azureId = ded.azureId;
                            newDed.coveragePremium = ded.coveragePremium;
                            newDed.factorDefaultValue = ded.factorDefaultValue;
                            newDed.factorMax = ded.factorMax;
                            newDed.factorMin = ded.factorMin;
                            newDed.factorValue = ded.factorValue;
                            newDed.increment = '1';
                            newDed.minAmt = '2';
                            newDed.maxAmt = '3';
                            newDed.optionType = 'Range';
                            newDed.optionValueDefault = '1';
                            newDed.overridePremium = ded.overridePremium;
                            newDed.optionList = new List<String>{'1', '2'};
                            newSubCov.deductibles.add(newDed);
                        }
                        newCov.subCoverages.add(newSubCov);
                    }

                    i = 0;
                    // generate limit
                    for (RatingRequest.LimitDeductible lim : cov.limits) {

                        RatingResponse.LimitItem newLim = new RatingResponse.LimitItem();
                        newLim.limitName = 'limit' + String.valueOf(i++);
                        newLim.azureId = lim.azureId;
                        newLim.coveragePremium = lim.coveragePremium;
                        newLim.factorDefaultValue = lim.factorDefaultValue;
                        newLim.factorMax = lim.factorMax;
                        newLim.factorMin = lim.factorMin;
                        newLim.factorValue = lim.factorValue;
                        newLim.increment = '1';
                        newLim.minAmt = '2';
                        newLim.maxAmt = '3';
                        newLim.optionType = 'Range';
                        newLim.optionValueDefault = '1';
                        newLim.overridePremium = lim.overridePremium;
                        newLim.optionList = new List<String>{'1', '2'};
                        newCov.limits.add(newLim);
                    }

                    i = 0;
                    // generate limit
                    for (RatingRequest.LimitDeductible ded : cov.deductibles) {

                        RatingResponse.DeductibleItem newDed = new RatingResponse.DeductibleItem();
                        newDed.deductibleName = 'deductible' + String.valueOf(i++);
                        newDed.azureId = ded.azureId;
                        newDed.coveragePremium = ded.coveragePremium;
                        newDed.factorDefaultValue = ded.factorDefaultValue;
                        newDed.factorMax = ded.factorMax;
                        newDed.factorMin = ded.factorMin;
                        newDed.factorValue = ded.factorValue;
                        newDed.increment = '1';
                        newDed.minAmt = '2';
                        newDed.maxAmt = '3';
                        newDed.optionType = 'Range';
                        newDed.optionValueDefault = '1';
                        newDed.overridePremium = ded.overridePremium;
                        newDed.optionList = new List<String>{'1', '2'};
                        newCov.deductibles.add(newDed);
                    }

                    newItem.CoverageLineItems.add(newCov);
                }

                products.put(key, newItem);
            }

            Map<String, List<RatingResponse.RatingModifier>> modifierMap =
                    new Map<String, List<RatingResponse.RatingModifier>>();
            for (String key : obj.opportunity.products.keySet()) {
                List<RatingRequest.RatingModifier> items = obj.opportunity.products.get(key);
                List<RatingResponse.RatingModifier> modifiers = new List<RatingResponse.RatingModifier>();
                for (RatingRequest.RatingModifier item : items) {
                    RatingResponse.RatingModifier newItem = new RatingResponse.RatingModifier();
                    newItem.azureID = item.azureID;
                    newItem.ratingModifierName = item.ratingModifierName;
                    newItem.ratingModifierValue = item.ratingModifierValue;
                    //newItem.factorMin = item.factorMin;
                    //newItem.factorMax = item.factorMax;
                    //newItem.factorValue = item.factorValue;
                    newItem.format = item.format;
                    //newItem.factorDefaultValue = item.defaultValue;

                    modifiers.add(newItem);
                }
                modifierMap.put(key, modifiers);
            }

            RatingResponse resObj = new RatingResponse();
            resObj.quote = quote;
            resObj.opportunity = opp;
            resObj.products = products;
            resObj.ratingModifiers = modifierMap;

            String jsonObj = JSON.serialize(resObj);
            res = createResponse(200, jsonObj);

        } catch (Exception ex) {
            res = createResponse(400, 'Failed to create response');
        }
        return res;
    }

    //tuan.d.nguyen added 17-Jun-2020
    public List<CoveragesLineItem__c> getCoverageLineItemsNew(Quote currentQuote) {
        Map<String, CoveragesLineItem__c> mapCLI = new Map<String, CoveragesLineItem__c>();
        System.debug('Cli size: ' + this.quote.coverageLineItems.size());
        for(CoverageLineItemWrapper cliWrapper : this.quote.coverageLineItems) {
           
            CoveragesLineItem__c cli = new CoveragesLineItem__c();

            cli.Azure_ID__c = cliWrapper.id;
            cli.Coverage__c = cliWrapper.coverage;
            cli.Coverage_Premium__c = cliWrapper.coverage_Premium;
            if(String.isNotBlank(cliWrapper.override_Premium)) {
                cli.Override_Premium__c = Decimal.valueOf(cliWrapper.override_Premium);
            }
            cli.Non_Prorated_Coverage_Premium__c = cliWrapper.non_Prorated_Coverage_Premium;
            if(cliWrapper.option_Picklist != null && !cliWrapper.option_Picklist.isEmpty())
                cli.Option_Picklist__c = String.join(cliWrapper.option_Picklist, ';');
            cli.Option_Value_Default__c = cliWrapper.option_Value_Default;
            if(String.isNotBlank(cliWrapper.min_Amt)) {
                cli.Min_amt__c = Decimal.valueOf(cliWrapper.min_Amt);
            }
            if(String.isNotBlank(cliWrapper.max_Amt)) {
                cli.Max_amt__c = Decimal.valueOf(cliWrapper.max_Amt);
            }
            if(String.isNotBlank(cliWrapper.is_Included)) {
                cli.IsIncluded__c = Boolean.valueOf(cliWrapper.is_Included);
            }
            if(String.isNotBlank(cliWrapper.increment_Step)) {
                cli.Increment_Step__c = Decimal.valueOf(cliWrapper.increment_Step);
            }
            cli.Option_Type__c = cliWrapper.option_Type;
            System.debug('CliWrapper: ' + cliWrapper);  
            mapCLI.put(cli.Azure_ID__c, cli);
        }

        List<CoveragesLineItem__c> listCurrentCLI = [SELECT Id, Name, Azure_ID__c FROM CoveragesLineItem__c WHERE Quote__c =: currentQuote.Id];
        System.debug('Current CLI: ' + listCurrentCLI.size());
        List<CoveragesLineItem__c> listUpdateCLI = new List<CoveragesLineItem__c>();
        for(CoveragesLineItem__c cli : listCurrentCLI) {
            if(mapCLI.get(cli.Azure_ID__c) != null) {
                CoveragesLineItem__c newCLI = mapCLI.get(cli.Azure_ID__c);
                newCLI.Id = cli.Id;
                listUpdateCLI.add(newCLI);
                             
            }
        }
        System.debug('Update CLI: ' + listUpdateCLI.size());  
        return listUpdateCLI;
    }

    //tuan.d.nguyen added 18-Jun-2020
    public List<Rating_Modifiers__c> getRatingModifiersNew(Quote currentQuote) {
        Map<String, Rating_Modifiers__c> mapRating = new Map<String, Rating_Modifiers__c>();
        for(RatingModifier ratingModWrapper : this.quote.ratingModifiers) {
            Rating_Modifiers__c ratingMod = new Rating_Modifiers__c();
            ratingMod.Rating_Modifier_Value__c = ratingModWrapper.ratingModifierValue;
            if(String.isNotBlank(ratingModWrapper.factorMax)) {
                ratingMod.Factor_Max__c = Decimal.valueOf(ratingModWrapper.factorMax);
            }
            if(String.isNotBlank(ratingModWrapper.factorMin)) {
                ratingMod.Factor_Min__c = Decimal.valueOf(ratingModWrapper.factorMin);
            }
            mapRating.put(ratingModWrapper.azureID, ratingMod);
            System.debug('Added Map AzureID: ' + ratingModWrapper.azureID);
        }

        List<Rating_Modifiers__c> listCurrentRating = [SELECT Id, Name, Azure_ID__c FROM Rating_Modifiers__c WHERE Opportunity__c =: currentQuote.OpportunityId];
        System.debug('Current Rating: ' + listCurrentRating.size());
        List<Rating_Modifiers__c> listUpdateRating = new List<Rating_Modifiers__c>();
        for(Rating_Modifiers__c rating : listCurrentRating) {
            if(mapRating.get(rating.Azure_ID__c) != null) {
                Rating_Modifiers__c newRating = mapRating.get(rating.Azure_ID__c);
                newRating.Id = rating.Id;
                listUpdateRating.add(newRating);
               
            }
        }
        System.debug('Update rating: ' + listUpdateRating.size());  
        return listUpdateRating;
    }

    //tuan.d.nguyen added 18-Jun-2020
    public List<Rating_Modifier_Factor__c> getRatingModifierFactors(Quote currentQuote) {
        Map<String, Rating_Modifier_Factor__c> mapFactor = new Map<String, Rating_Modifier_Factor__c>();
        for(RatingModifier ratingMod : this.quote.ratingModifiers) {
            Rating_Modifier_Factor__c factor = new Rating_Modifier_Factor__c();

            if(String.isNotBlank(ratingMod.factorValue)) {
                factor.Factor_Value__c = Decimal.valueOf(ratingMod.factorValue);
            }
            if(String.isNotBlank(ratingMod.defaultValue)) {
                factor.Factor_Default_Value__c = Decimal.valueOf(ratingMod.defaultValue);
            }
            mapFactor.put(ratingMod.ratingModifierCode, factor);
        }

        List<Rating_Modifier_Factor__c> listCurrentFactor = [SELECT Id, Name, Rating_Modifier__r.Rating_Modifier_Code__c FROM Rating_Modifier_Factor__c WHERE Quote__c =: currentQuote.Id];
        List<Rating_Modifier_Factor__c> listUpdateFactor = new List<Rating_Modifier_Factor__c>();
        for(Rating_Modifier_Factor__c factor : listCurrentFactor) {
            if(mapFactor.get(factor.Rating_Modifier__r.Rating_Modifier_Code__c) != null) {
                Rating_Modifier_Factor__c newFactor = mapFactor.get(factor.Rating_Modifier__r.Rating_Modifier_Code__c);
                newFactor.Id = factor.Id;
                listUpdateFactor.add(newFactor);
            }
        }
    System.debug('Update factor: ' + listUpdateFactor.size());  
        return listUpdateFactor;
    }

    //tuan.d.nguyen added 19/06/2020
    public static String getFakeResponse(String quoteId) {
        Quote q = [SELECT Id, Name, Azure_ID__c, QuoteNumber FROM Quote WHERE Id =: quoteId LIMIT 1];
        String response = '';
        response += '{"Quote_ID":"' + q.Id + '", "Azure_ID__c":"' + q.Azure_ID__c + '", "QuoteNumber":"' + q.QuoteNumber + '",';
        response += '"ProductClassCd":"Celerity_MPL","Master_Set_ID__c":"1","Quote_Type__c":"New Business","Effective_Date__c":"2020-06-19",'
                + '"ExpirationDate":"2021-06-19","TechnicalPremium__c":"64483","Status":"Refer","CoveragePremium__c":"64483","QuotePremium__c":"64483",'
                + '"AcceptedTerrorism_Premium":"","RejectedTerrorism_Premium":"","SelectedTerrorism_Premium":"","Taxes":"","Fees":"","ProductName":"MPL Standalone","WritingCompany":"0012500001E5djsAAB","commissionAmount":"0",';
        response += '"Commission_percentage__c":"","nonProratedQuotePremium":"64483","Accounts":[{"Id":null,"Name":"ADVANCED MICRO DEVICES, INC.","Azure_ID__c":"a5d2ede1-b50e-4d6d-9d1d-93383f75aebb",'
                + '"PrimaryAddress":{"Latitude":null,"Longitude":null,"Address1":"2485 AUGUSTINE DR","Address2":"","City":null,"County":"","StateProvCd":null,"CountryCd":"US","PostalZipCd":"95054","LocLatitude":null,'
                + '"LocLongitude":null,"LocCountry":null,"LocLevel1":null,"LocLevel2":null,"LocLevel3":null,"LocLevel4":null,"LocLevel5":null,"LocType":null}}],';
        response += '"RatingModifiers":[{"azureID":"780b0595-4c3c-4dbd-9c9c-f25382012e50","ratingModifierName":"Average years of experience of your staff in this industry","ratingModifierCode":"MPL000004","ratingModifierValue":"3 to 5 years","factorValue":"1.0","factorMin":"1.0","factorMax":"1.0","defaultValue":"1.0"},'
                + '{"azureID":"14b5abe5-870c-4c7c-b979-349465bba152","ratingModifierName":"Claim Free Credit","ratingModifierCode":"MPL000005","ratingModifierValue":"Claim Free","factorValue":"0.875","factorMin":"0.75","factorMax":"1.0","defaultValue":"0.875"},'
                + '{"azureID":"acd3ae1f-199e-4717-9111-2fb6b78e5f9c","ratingModifierName":"Jurisdiction","ratingModifierCode":"MPL000012","ratingModifierValue":"Favorable","factorValue":"1.0","factorMin":"1.0","factorMax":"1.0","defaultValue":"1.0"},'
                + '{"azureID":"f2cae773-90f5-41b1-96d6-1307b9cd1bd8","ratingModifierName":"Restrictive Endorsement Factor selected","ratingModifierCode":"MPL000020","ratingModifierValue":"At least one very restrictive endorsement","factorValue":"0.65","factorMin":"0.5","factorMax":"0.8","defaultValue":"0.65"},'
                + '{"azureID":"992d9845-515d-48f8-a727-11a35dca113f","ratingModifierName":"Expansive Endorsement Factor selected","ratingModifierCode":"MPL000009","ratingModifierValue":"At least one expansive endorsement and no very expansive endorsement","factorValue":"1.15","factorMin":"1.0","factorMax":"1.3","defaultValue":"1.15"},'
                + '{"azureID":"3eafccec-267f-4dad-9ada-99e0a54c03d4","ratingModifierName":"Merger/Acquisition Activity","ratingModifierCode":"MPL000014","ratingModifierValue":null,"factorValue":"1.0","factorMin":"0.75","factorMax":"1.25","defaultValue":"1.0"},'
                + '{"azureID":"6152a228-886f-4424-8b8b-72eb87b239b1","ratingModifierName":"Material Changes in Revenues","ratingModifierCode":"MPL000013","ratingModifierValue":null,"factorValue":"1.0","factorMin":"0.75","factorMax":"1.25","defaultValue":"1.0"},'
                + '{"azureID":"d260002f-3265-4141-b737-09189f8c3e95","ratingModifierName":"Risk Management Procedures/Controls","ratingModifierCode":"MPL000021","ratingModifierValue":null,"factorValue":"1.0","factorMin":"0.75","factorMax":"1.25","defaultValue":"1.0"},'
                + '{"azureID":"9a7338fe-1a83-4dfd-a161-a40017398f4e","ratingModifierName":"Claims/Litigation History","ratingModifierCode":"MPL000006","ratingModifierValue":null,"factorValue":"1.0","factorMin":"0.75","factorMax":"1.25","defaultValue":"1.0"},'
                + '{"azureID":"10a9f086-2d45-49d9-9252-165a3875103e","ratingModifierName":"Percentage of Written Contracts Used","ratingModifierCode":"MPL000018","ratingModifierValue":"75% to 99%","factorValue":"1.0","factorMin":"1.0","factorMax":"1.0","defaultValue":"1.0"},'
                + '{"azureID":"b3ddb868-2350-4636-9f1f-2653fde11b4a","ratingModifierName":"Nature of Services","ratingModifierCode":"MPL000015","ratingModifierValue":null,"factorValue":"1.0","factorMin":"0.75","factorMax":"1.25","defaultValue":"1.0"},'
                + '{"azureID":"6d2c2850-3131-4787-bfff-c8c992e43c9a","ratingModifierName":"Extended Reporting Period Factor (ERPF)","ratingModifierCode":"MPL000011","ratingModifierValue":"One Year","factorValue":"1","factorMin":"1","factorMax":"1","defaultValue":"1"},'
                + '{"azureID":"ed2e9808-eb6a-4545-9b9b-558c94f9d137","ratingModifierName":"Annual Revenues","ratingModifierCode":"MPL000000","ratingModifierValue":"50000000","factorValue":null,"factorMin":null,"factorMax":null,"defaultValue":null},'
                + '{"azureID":"c8bdd70e-c969-49e9-88c8-4529177beae6","ratingModifierName":"Service Classification","ratingModifierCode":"MPL000002","ratingModifierValue":"Hardware: Design","factorValue":"0.65","factorMin":"0.05","factorMax":"1.25","defaultValue":"0.65"},'
                + '{"azureID":"9f6df155-7363-44f4-b5f5-83c0a4be9d23","ratingModifierName":"Prior acts coverage","ratingModifierCode":"MPL000019","ratingModifierValue":"4 Years","factorValue":"0.962","factorMin":"0.962","factorMax":"0.962","defaultValue":"0.962"},'
                + '{"azureID":"6a7bcbb6-d116-4808-9414-358284aa1dca","ratingModifierName":"Number of Years in Business","ratingModifierCode":"MPL000016","ratingModifierValue":"1 to 3 years","factorValue":"1.125","factorMin":"1.0","factorMax":"1.25","defaultValue":"1.125"},'
                + '{"azureID":"2618bfa3-784b-4cac-9f1f-3c6b3fa172cb","ratingModifierName":"Use of Independent Contractors","ratingModifierCode":"MPL000025","ratingModifierValue":"25% or Less","factorValue":"1.05","factorMin":"1.0","factorMax":"1.1","defaultValue":"1.05"},'
                + '{"azureID":"da8f4da0-95fc-4030-8202-8b1478c40d36","ratingModifierName":"Written Contracts Used","ratingModifierCode":"MPL000027","ratingModifierValue":"No","factorValue":"1.125","factorMin":"1.0","factorMax":"1.25","defaultValue":"1.125"},'
                + '{"azureID":"c00ef3ab-8217-4636-a0e0-02177631a8ed","ratingModifierName":"Contracts Reviewed by Counsel","ratingModifierCode":"MPL000008","ratingModifierValue":"No","factorValue":"1.125","factorMin":"1.0","factorMax":"1.25","defaultValue":"1.125"},'
                + '{"azureID":"c082cb8a-ea5a-4484-9c9c-5bf57086af69","ratingModifierName":"Use of written training and procedural manuals","ratingModifierCode":"MPL000026","ratingModifierValue":"Yes","factorValue":"0.95","factorMin":"0.9","factorMax":"1.0","defaultValue":"0.95"}],';
               
        response += '"overallUWCodes":[null],"overallUWDescriptions":[{"ReasonCode":"ACC-005","ReasonDescription":""}],'
                + '"CoverageLineItems":[{"id":"32f2ee60-d5e5-4030-bd7d-92ddf1f06f56","Coverage__c":null,"name":"Contingent BIPD Coverage Endorsement  Sublimit Only","Coverage_Code__c":"ContigentBIPDSub","Coverage_Premium__c":"0","Override_Premium__c":"0","nonProratedCoveragePremium":"0","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},'
                + '{"id":"bd830d49-b4af-4242-bbbb-f22b80ee7141","name":"BIPD Endorsement Aggregate Limit","Code__c":"ContigentBIPDSublimit","Option_Value_Default__c":"0","Option_Type__c":"Picklist","Option_Picklist__c":["0"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"17b6feed-0690-4898-9c5c-69b725e77c21","Coverage__c":null,"name":"Contingent BIPD Endorsement","Coverage_Code__c":"ContigentBIPD","Coverage_Premium__c":"0.0","Override_Premium__c":"0.0","nonProratedCoveragePremium":null,"Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},'
                + '{"id":"b3ec5418-80fd-4787-b171-efae58b0abb6","name":"Contingent BI/PD - Limit","Code__c":"ContigentBIPDLimit","Option_Value_Default__c":"No Coverage","Option_Type__c":"Picklist","Option_Picklist__c":["No Coverage","100k - 100k","100k - 300k","250k - 250k","250k - 500k","300k - 300k","300k - 500k","500k - 500k","500k - 1m","1m - 1m","1m - 2m","1m - 3m","2m - 2m","2m -5m","3m - 3m","3m - 5m","4m - 4m","5m - 5m","6m - 6m","7m - 7m","8m - 8m","9m - 9m","10m - 10m","11m - 11m","12m - 12m","13m - 13m","14m -14m","15m - 15m"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"746e3f8f-6507-4444-a161-e46fcc82a24b","name":"Contingent BI/PD - Retention","Code__c":"ContigentBIPDDed","Option_Value_Default__c":"5000","Option_Type__c":"Picklist","Option_Picklist__c":["1000","1500","2500","5000","7500","10000","15000","25000","50000","75000","100000","150000","175000","200000","250000","300000","500000","750000","1000000"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"1000fbbf-e626-4bdb-a727-c4f96bf857bd","Coverage__c":null,"name":"Contingent PD only","Coverage_Code__c":"ContingentPD","Coverage_Premium__c":"0","Override_Premium__c":"0","nonProratedCoveragePremium":"0","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},'
                + '{"id":"cf6f624f-9f76-40f0-95d5-88f0e9fb3567","name":"Contingent PD only - Limit","Code__c":"ContingentPDLimit","Option_Value_Default__c":"-1","Option_Type__c":"Range","Min_amt__c":"0","Max_amt__c":"250000","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"ab4ce005-1ad7-4343-8909-d85eab09cd03","name":"Contingent PD only - Retention","Code__c":"ContingentPDDed","Option_Value_Default__c":"0","Option_Type__c":"Picklist","Option_Picklist__c":["0"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"08bd3f4d-49ab-47b7-8ece-e8341bdb5d2b","Coverage__c":null,"name":"Media Liability Including Advertising","Coverage_Code__c":"EndMediaLiability","Coverage_Premium__c":"0.0","Override_Premium__c":"0.0","nonProratedCoveragePremium":null,"Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},'
                + '{"id":"da3c8581-ee59-47d7-bebe-31f7e60240b6","name":"Media Liability - Limit","Code__c":"MediaLiabilityLimit","Option_Value_Default__c":"No Coverage","Option_Type__c":"Picklist","Option_Picklist__c":["No Coverage","100k - 100k","100k - 300k","250k - 250k","250k - 500k","300k - 300k","300k - 500k","500k - 500k","500k - 1m","1m - 1m","1m - 2m","1m - 3m","2m - 2m","2m -5m","3m - 3m","3m - 5m","4m - 4m","5m - 5m","6m - 6m","7m - 7m","8m - 8m","9m - 9m","10m - 10m","11m - 11m","12m - 12m","13m - 13m","14m -14m","15m - 15m"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"ec2ee0ae-adb2-4ccc-9d5d-b235225585df","name":"Media Liability - Retention","Code__c":"MediaLiabilityDed","Option_Value_Default__c":"5000","Option_Type__c":"Picklist","Option_Picklist__c":["1000","1500","2500","5000","7500","10000","15000","25000","50000","75000","100000","150000","175000","200000","250000","300000","500000","750000","1000000"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"f22ff51d-42c5-4969-a727-a7f45ce5e2a9","Coverage__c":null,"name":"Mitigation Expense Coverage Endorsement","Coverage_Code__c":"MitigationExpense","Coverage_Premium__c":"0.0","Override_Premium__c":"0.0","nonProratedCoveragePremium":null,"Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},'
                + '{"id":"033b2224-a700-41e1-a020-837c6a7c9776","name":"Mitigation Limit","Code__c":"MitigaLimit","Option_Value_Default__c":"-1","Option_Type__c":"Range","Min_amt__c":"0","Max_amt__c":"250000","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"b5de4aa2-4a4d-4848-8484-f56ae4a4ee8d","name":"Retention","Code__c":"MitgaDed","Option_Value_Default__c":"0","Option_Type__c":"Picklist","Option_Picklist__c":["0"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"a4bfaf2e-ca9a-43d3-a7e7-83c7c14d5a1e","Coverage__c":null,"name":"Antitrust Claim Defense Sublimit","Coverage_Code__c":"EndAntitrustClaim","Coverage_Premium__c":"0.0","Override_Premium__c":"0.0","nonProratedCoveragePremium":null,"Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},'
                + '{"id":"d9424e81-3526-4434-9cdc-1cde02a48dc2","name":"AntitrustSublimit","Code__c":"AntitrustSublimit","Option_Value_Default__c":"-1","Option_Type__c":"Range","Min_amt__c":"0","Max_amt__c":"250000","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"bae02195-563f-4737-85c5-353da61c6cbb","Coverage__c":null,"name":"Claim Expenses Outside the Limit Endorsement","Coverage_Code__c":"EndClaimExpense","Coverage_Premium__c":"0.0","Override_Premium__c":"0.0","nonProratedCoveragePremium":null,"Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},'
                + '{"id":"94d78284-8917-4bbb-99d9-5221db38ee69","name":"Limit","Code__c":"ClaimExpenseLimit","Option_Value_Default__c":"No Coverage","Option_Type__c":"Picklist","Option_Picklist__c":["No Coverage","100k - 100k","100k - 300k","250k - 250k","250k - 500k","300k - 300k","300k - 500k","500k - 500k","500k - 1m","1m - 1m","1m - 2m","1m - 3m","2m - 2m","2m -5m","3m - 3m","3m - 5m","4m - 4m","5m - 5m","6m - 6m","7m - 7m","8m - 8m","9m - 9m","10m - 10m","11m - 11m","12m - 12m","13m - 13m","14m -14m","15m - 15m"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"d8080e74-6fd3-43c3-9111-c9312d609a8b","name":"Retention","Code__c":"ClaimExpenseRetention","Option_Value_Default__c":"5000","Option_Type__c":"Picklist","Option_Picklist__c":["1000","1500","2500","5000","7500","10000","15000","25000","50000","75000","100000","150000","175000","200000","250000","300000","500000","750000","1000000"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"0928646f-a188-4a1a-8505-58a691c19f6d","Coverage__c":null,"name":"Class Action SubLimit","Coverage_Code__c":"EndClassAction","Coverage_Premium__c":"0.0","Override_Premium__c":"0.0","nonProratedCoveragePremium":null,"Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"bb6b7465-c35b-43a3-8a4a-7bdae892d61f","name":"LawsuitSublimit","Code__c":"LawsuitSublimit","Option_Value_Default__c":"-1","Option_Type__c":"Range","Min_amt__c":"0","Max_amt__c":"250000","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"45219142-4659-4343-85c5-f86de62c055f","name":"LawsuitRetention","Code__c":"LawsuitRetention","Option_Value_Default__c":"0","Option_Type__c":"Picklist","Option_Picklist__c":["0"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"17de7827-5eb8-4262-b474-f5307e4568bf","Coverage__c":null,"name":"Miscellaneous Professional Liability","Coverage_Code__c":"MPL","Coverage_Premium__c":"86634.0","Override_Premium__c":"86634.0","nonProratedCoveragePremium":null,"Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},'
                + '{"id":"407511e3-53c4-4404-8a0a-b685522a0c8f","name":"MPL - Desired Limits","Code__c":"MPLLimit","Option_Value_Default__c":"1m - 1m","Option_Type__c":"Picklist","Option_Picklist__c":["100k - 100k","100k - 300k","250k - 250k","250k -500k","300k - 300k","300k - 500k","500k - 500k","500k - 1m","1m - 1m","1m - 2m","1m - 3m","2m - 2m","2m - 5m","3m - 3m","3m - 5m","4m - 4m","5m - 5m","6m - 6m","7m - 7m","8m - 8m","9m - 9m","10m - 10m","11m - 11m","12m - 12m","13m - 13m","14m - 14m","15m - 15m"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"f1bd7be0-90bc-4868-8b0b-1fb217d8475b","name":"MPL - Retention","Code__c":"MPLDed","Option_Value_Default__c":"5000","Option_Type__c":"Picklist","Option_Picklist__c":["0","500","750","1000","1500","2500","5000","7500","10000","15000","25000","50000","75000","100000","150000","175000","200000","250000","300000","500000","750000","1000000"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"ce673469-e705-44e4-a0a0-018321efdfd1","Coverage__c":null,"name":"Infringement of Copyright & Trademark for Media Related Providers","Coverage_Code__c":"InfringementOfCopyright","Coverage_Premium__c":"0.0","Override_Premium__c":"0.0","nonProratedCoveragePremium":null,"Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},'
                + '{"id":"0b5a6a94-3f5a-4616-9414-877bee08b2a8","name":"Limit","Code__c":"TrademarkLimit","Option_Value_Default__c":"No Coverage","Option_Type__c":"Picklist","Option_Picklist__c":["No Coverage","100k - 100k","100k - 300k","250k - 250k","250k - 500k","300k - 300k","300k - 500k","500k - 500k","500k - 1m","1m - 1m","1m - 2m","1m - 3m","2m - 2m","2m -5m","3m - 3m","3m - 5m","4m - 4m","5m - 5m","6m - 6m","7m - 7m","8m - 8m","9m - 9m","10m - 10m","11m - 11m","12m - 12m","13m - 13m","14m -14m","15m - 15m"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"3ef1a313-ed89-47a7-8c8c-057bea3493d3","name":"Retention","Code__c":"TrademarkRetention","Option_Value_Default__c":"5000","Option_Type__c":"Picklist","Option_Picklist__c":["1000","1500","2500","5000","7500","10000","15000","25000","50000","75000","100000","150000","175000","200000","250000","300000","500000","750000","1000000"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"6da786eb-a75c-4323-b070-b534bea0aff9","Coverage__c":null,"name":"Lock Box BI PD Carve Back","Coverage_Code__c":"LockBoxBIPD","Coverage_Premium__c":"0.0","Override_Premium__c":"0.0","nonProratedCoveragePremium":null,"Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},'
                + '{"id":"9059aaf8-4d8c-49d9-b979-562e9d41a7e7","name":"Lock Box Limit","Code__c":"LockBoxBIPDLimit","Option_Value_Default__c":"No Coverage","Option_Type__c":"Picklist","Option_Picklist__c":["No Coverage","100k - 100k","100k - 300k","250k - 250k","250k - 500k","300k - 300k","300k - 500k","500k - 500k","500k - 1m","1m - 1m","1m - 2m","1m - 3m","2m - 2m","2m -5m","3m - 3m","3m - 5m","4m - 4m","5m - 5m","6m - 6m","7m - 7m","8m - 8m","9m - 9m","10m - 10m","11m - 11m","12m - 12m","13m - 13m","14m -14m","15m - 15m"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"be3affb9-829e-4fcf-9ede-508a411ff698","name":"Retention","Code__c":"LockBoxRetention","Option_Value_Default__c":"5000","Option_Type__c":"Picklist","Option_Picklist__c":["1000","1500","2500","5000","7500","10000","15000","25000","50000","75000","100000","150000","175000","200000","250000","300000","500000","750000","1000000"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"3cb65802-b61d-4d4d-a666-b8af92cfd355","Coverage__c":null,"name":"Negligent Failure to Prevent Dishonest Conduct","Coverage_Code__c":"DishonestConduct","Coverage_Premium__c":"0.0","Override_Premium__c":"0.0","nonProratedCoveragePremium":null,"Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},'
                + '{"id":"523c7638-2a79-4dbd-84c4-bf9bfecc6b18","name":"NegFailPreventDishonestConductSublimit","Code__c":"NegFailPreventDishonestConductSublimit","Option_Value_Default__c":"-1","Option_Type__c":"Range","Min_amt__c":"0","Max_amt__c":"250000","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"4e71dd4b-ad56-43e3-9454-77b40b78ebd1","Coverage__c":null,"name":"CFPB Claim Expenses","Coverage_Code__c":"ClaimExpenses","Coverage_Premium__c":"0.0","Override_Premium__c":"0.0","nonProratedCoveragePremium":null,"Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},'
                + '{"id":"85ae08e6-6a02-4ece-99d9-083dd7c29c94","name":"CFPBClaimSublimit","Code__c":"CFPBClaimSublimit","Option_Value_Default__c":"-1","Option_Type__c":"Range","Min_amt__c":"0","Max_amt__c":"250000","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"1389be1e-e9fd-41c1-a0a0-7fa13a1dbb67","Coverage__c":null,"name":"Subpoena Compliance Sublimit","Coverage_Code__c":"SubpoenaSublimit","Coverage_Premium__c":"0.0","Override_Premium__c":"0.0","nonProratedCoveragePremium":null,"Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},{"id":"b3af1b3b-a72e-4404-b1f1-c21d4682ac99","name":"SubpoenaComplianceAmount","Code__c":"SubpoenaComplianceAmount","Option_Value_Default__c":"-1","Option_Type__c":"Range","Min_amt__c":"0","Max_amt__c":"250000","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"a4b9ba60-7d11-4eee-8c4c-c880e921f225","Coverage__c":null,"name":"Theft of Funds","Coverage_Code__c":"TheftOfFund","Coverage_Premium__c":"0.0","Override_Premium__c":"0.0","nonProratedCoveragePremium":null,"Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},'
                + '{"id":"8b136bee-fd4c-4858-9454-6c95955a70cf","name":"Theft Of Fund Sublimit","Code__c":"TheftOfFundSublimit","Option_Value_Default__c":"-1","Option_Type__c":"Range","Min_amt__c":"0","Max_amt__c":"250000","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"2d82bc9e-c66f-4c5c-8808-c473a9ca3901","Coverage__c":null,"name":"Independent Contractor Extension Endorsement","Coverage_Code__c":"IndependentContractorExtension","Coverage_Premium__c":"0.0","Override_Premium__c":"0.0","nonProratedCoveragePremium":null,"Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},'
                + '{"id":"507c33a8-e494-49a9-b979-d7e2bab21e37","name":"Limit","Code__c":"IndependentLimit","Option_Value_Default__c":"No Coverage","Option_Type__c":"Picklist","Option_Picklist__c":["No Coverage","100k - 100k","100k - 300k","250k - 250k","250k - 500k","300k - 300k","300k - 500k","500k - 500k","500k - 1m","1m - 1m","1m - 2m","1m - 3m","2m - 2m","2m -5m","3m - 3m","3m - 5m","4m - 4m","5m - 5m","6m - 6m","7m - 7m","8m - 8m","9m - 9m","10m - 10m","11m - 11m","12m - 12m","13m - 13m","14m -14m","15m - 15m"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"1e072a98-8ce7-4a6a-9a5a-1710db2e2cbd","name":"Retention","Code__c":"IndependentContractorRetention","Option_Value_Default__c":"5000","Option_Type__c":"Picklist","Option_Picklist__c":["1000","1500","2500","5000","7500","10000","15000","25000","50000","75000","100000","150000","175000","200000","250000","300000","500000","750000","1000000"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"e5016c05-3275-49d9-be7e-da08db7e04f4","Coverage__c":null,"name":"Infringement of Copyright","Coverage_Code__c":"InfringementOfCopyright2","Coverage_Premium__c":"0.0","Override_Premium__c":"0.0","nonProratedCoveragePremium":null,"Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},'
                + '{"id":"d702079f-f074-4606-a4e4-061f835aec77","name":"Limit","Code__c":"CopyrightLimit","Option_Value_Default__c":"No Coverage","Option_Type__c":"Picklist","Option_Picklist__c":["No Coverage","100k - 100k","100k - 300k","250k - 250k","250k - 500k","300k - 300k","300k - 500k","500k - 500k","500k - 1m","1m - 1m","1m - 2m","1m - 3m","2m - 2m","2m -5m","3m - 3m","3m - 5m","4m - 4m","5m - 5m","6m - 6m","7m - 7m","8m - 8m","9m - 9m","10m - 10m","11m - 11m","12m - 12m","13m - 13m","14m -14m","15m - 15m"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"0c3a767a-1716-44e4-a363-3457f03591fc","name":"Retention","Code__c":"InfringementRetention","Option_Value_Default__c":"5000","Option_Type__c":"Picklist","Option_Picklist__c":["1000","1500","2500","5000","7500","10000","15000","25000","50000","75000","100000","150000","175000","200000","250000","300000","500000","750000","1000000"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null},{"id":"940f51d4-a738-4bab-9858-068cbeb9670a","Coverage__c":null,"name":"Failure to Disclose Pollutants Sublimit","Coverage_Code__c":"FailurtoDisclose","Coverage_Premium__c":"0.0","Override_Premium__c":"0.0","nonProratedCoveragePremium":null,"Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},'
                + '{"id":"c4f3af85-fc4d-4a1a-9e5e-e5c7db28af4c","name":"Sublimit","Code__c":"FailurtoDiscloseSublimit","Option_Value_Default__c":"-1","Option_Type__c":"Range","Min_amt__c":"0","Max_amt__c":"250000","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"715510bf-866a-45c5-a868-151b97449d80","Coverage__c":null,"name":"Open House Sublimit Endorsement","Coverage_Code__c":"OpenHouse","Coverage_Premium__c":"0.0","Override_Premium__c":"0.0","nonProratedCoveragePremium":null,"Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},'
                + '{"id":"a9750168-d8fa-4e3e-80c0-c1c5a44daf1d","name":"OpenHouseSublimit","Code__c":"OpenHouseSublimit","Option_Value_Default__c":"-1","Option_Type__c":"Range","Min_amt__c":"0","Max_amt__c":"250000","Increment_Step__c":"1","Option_Picklist__c":[],"Coverage_Premium__c":null,"IsIncluded__c":null},'
                + '{"id":"5b5d18db-68ef-4868-9ddd-3f1d8b169e5e","Coverage__c":null,"name":"Contingent BIPD Coverage (Without Other Insurance Amendment)EndorsementSublimit","Coverage_Code__c":"ContigentBIPDWithoutAmend","Coverage_Premium__c":"0","Override_Premium__c":"0","nonProratedCoveragePremium":"0","Override_Premium_Percentage__c":null,"Option_Picklist__c":[],"Option_Value_Default__c":null,"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"IsIncluded__c":null,"Option_Type__c":"Coverage"},'
                + '{"id":"79136d42-a5db-4e4e-abab-3504a2cf89a6","name":"BIPD Aggregate Limit w/o Amendment","Code__c":"BIPDWithoutInsuranceAmendment","Option_Value_Default__c":"0","Option_Type__c":"Picklist","Option_Picklist__c":["0"],"Min_amt__c":null,"Max_amt__c":null,"Increment_Step__c":null,"Coverage_Premium__c":null,"IsIncluded__c":null}]}';
            System.debug('Response Test'+response);            
        return response;
    }
    //tuan.d.nguyen added 17-Jun-2020
    public class OverallUWDescriptions {
    public String uwcode;
    public String message_text;
    }
    public class PrimaryAddress {
    public String latitude {get;set;}
    public String longitude {get;set;}
    public String address1 {get;set;}
    public String address2 {get;set;}
    public String city {get;set;}
    public String county {get;set;}
    public String stateProvCd {get;set;}
    public String countryCd {get;set;}
    public String postalZipCd {get;set;}
    public String locLatitude {get;set;}
    public String locLongitude {get;set;}
    public String locCountry {get;set;}
    public String locLevel1 {get;set;}
    public String locLevel2 {get;set;}
    public String locLevel3 {get;set;}
    public String locLevel4 {get;set;}
    public String locLevel5 {get;set;}
    public String locType {get;set;}
  }

}