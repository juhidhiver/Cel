/**
 * @description       : 
 * @author            : Maeran Shaikh
 * @group             : 
 * @last modified on  : 10-21-2021
 * @last modified by  : Maeran Shaikh
**/
public class RatingRequest {
   
    public QuoteWrapper quote {get;set;}
    public OpportunityWrapper opportunity {get;set;}
    public ProductWrapper productConfigAttributes {get;set;}
    public List<PriorCoverageItem> priorQuoteCoverageLineItems {get;set;}//tuan.d.nguyen added 21-Jul-2020
	//public List<CoveragesLineItem__c> priorQuoteCoverageLineItems {get;set;}
    public RatingRequest() {
        this.quote = new QuoteWrapper();
        this.opportunity = new OpportunityWrapper();
        this.productConfigAttributes = new ProductWrapper();
        this.priorQuoteCoverageLineItems = new List<PriorCoverageItem>();
		//this.priorQuoteCoverageLineItems = new List<CoveragesLineItem__c>();
    }
    public class QuoteWrapper {
        public String commissionPercentage {get;set;} //Added by Hai Bui
        public String masterSetId {get;set;}
        public String productClassCd {get;set;}
        public String quoteAzureId {get; set;}
        public String quoteId {get; set;}
        public String quoteEffectiveDate {get; set;}
        public String quoteNumber {get; set;}
        public String quoteExpirationDate {get; set;}
        public String quoteType {get;set;} 
        public String quoteName {get;set;}
        public String status {get;set;}
        public String overridePremium {get;set;} //Phuc added on 23 June 20
        public String overridePremiumPercent {get;set;}
        public Map<String,CoverageProductWrapper> products {get; set;}          
        public String priorNonProratedQuotePremium {get;set;}  //tuan.d.nguyen added 20-Jul-2020
        public String priorQuotePremium {get;set;}
        public String endorsementEffectiveDate {get;set;} 
        
        public QuoteWrapper (){
            this.products = new Map<String,CoverageProductWrapper>();
       }	

        public QuoteWrapper (Quote item){
            if (item == null) {
                return;
            }
            System.debug('rating quote: ' + item);
            this.commissionPercentage = CommonUtil.convertToString(item.Commission_percentage__c);            
            this.quoteAzureId = item.Azure_ID__c;
            this.QuoteId = item.Id;
            this.quoteEffectiveDate = item.Effective_Date__c != null ? String.valueOf(item.Effective_Date__c) : null;
            this.quoteNumber = item.QuoteNumber;
            this.quoteExpirationDate = item.ExpirationDate != null ? String.valueOf(item.ExpirationDate) : null;
            this.masterSetId = CommonUtil.convertToStringOrNull(item.Master_Set_ID__c);
            this.quoteType = CommonUtil.convertToStringOrNull(item.Quote_Type__c);
            this.productClassCd = null;
            this.quoteName = item.Name;
            this.status = item.Status;
            this.overridePremium = CommonUtil.convertToStringOrNull(item.Override_Premium__c);
            this.overridePremiumPercent = CommonUtil.convertToStringOrNull(item.Override_Premium_Percentage__c);

            this.products = new Map<String,CoverageProductWrapper>();

            //tuan.d.nguyen added 20-Jul-2020
            this.endorsementEffectiveDate = item.Endorsement_Effective_Date__c != null ? 
                                                String.valueOf(item.Endorsement_Effective_Date__c) : null;
            if(item.Quote_Type__c != 'New Business' && String.isNotBlank(item.Parent_Quote__c)){
                Quote parentQuote = getBoundQuote(item.Parent_Quote__c);
                this.priorNonProratedQuotePremium = CommonUtil.convertToStringOrNull(parentQuote.Non_Prorated_Quote_Premium__c);
                this.priorQuotePremium = CommonUtil.convertToStringOrNull(parentQuote.QuotePremium__c);
            }    

        }	
    }
    
    public class CoverageProductWrapper{
        public List<CoverageItem> coverageLineItems {get;set;}
        public List<RatingModifierFactor> factors {get;set;}

        public CoverageProductWrapper() {
            this.coverageLineItems = new List<CoverageItem>();
            this.factors = new List<RatingModifierFactor>();
        }
    }

    public virtual class CoverageClass extends LimitDeductible {
        
    }

    public class CoverageItem extends CoverageClass {
        public String coverageCode {get; set;}
        public String coverageName {get; set;}
        public List<SubCoverageItem> subCoverages {get; set;}
        public List<LimitDeductible> limits	{get; set;}
		public List<LimitDeductible> deductibles {get; set;}

        public CoverageItem() {
            this.coverageCode = '';
            this.coverageName = '';
            this.subCoverages = new List<SubCoverageItem>();
            this.limits = new List<LimitDeductible>();
            this.deductibles = new List<LimitDeductible>();
        }

        public CoverageItem(CoveragesLineItem__c item) {
            this.coverageCode = item.Coverage__r.Coverage_Code__c;
            this.coverageName = item.Coverage__r.Name;
            this.azureId = CommonUtil.convertToStringOrNull(item.Azure_ID__c);
            this.coveragePremium = CommonUtil.convertToStringOrNull(item.Coverage_Premium__c);
            this.factorDefaultValue = CommonUtil.convertToStringOrNull(item.Factor_Default_Value__c);
            this.factorMax = CommonUtil.convertToStringOrNull(item.Factor_Max__c);
            this.factorMin = CommonUtil.convertToStringOrNull(item.Factor_Min__c);
            this.factorValue = CommonUtil.convertToStringOrNull(item.Factor_Value__c);
            this.overridePremium = CommonUtil.convertToStringOrNull(item.Override_Premium__c);
            this.coverageId = CommonUtil.convertToStringOrNull(item.Coverage__r.Id);
            this.subCoverages = new List<SubCoverageItem>();
            this.limits = new List<LimitDeductible>();
            this.deductibles = new List<LimitDeductible>();
        }
    }

    public class SubCoverageItem extends CoverageClass {
        public String subCoverageCode 				{get; set;}
		public String subCoverageName 				{get; set;}
        public List<LimitDeductible> limits			{get; set;}
		public List<LimitDeductible> deductibles	{get; set;}

        public SubCoverageItem() {
            this.limits = new List<LimitDeductible>();
            this.deductibles = new List<LimitDeductible>();
        }

        public SubCoverageItem(CoveragesLineItem__c item) {
            this.subCoverageCode = item.Sub_Coverage__r.Coverage_Code__c;
            this.subCoverageName = item.Sub_Coverage__r.Name; 
            this.azureId = CommonUtil.convertToStringOrNull(item.Azure_ID__c);
            this.coveragePremium = CommonUtil.convertToStringOrNull(item.Coverage_Premium__c);
            this.factorDefaultValue = CommonUtil.convertToStringOrNull(item.Factor_Default_Value__c);
            this.factorMax = CommonUtil.convertToStringOrNull(item.Factor_Max__c);
            this.factorMin = CommonUtil.convertToStringOrNull(item.Factor_Min__c);
            this.factorValue = CommonUtil.convertToStringOrNull(item.Factor_Value__c);
            this.overridePremium = CommonUtil.convertToStringOrNull(item.Override_Premium__c);

            this.limits = new List<LimitDeductible>();
            this.deductibles = new List<LimitDeductible>();
        }
    }

    public virtual class LimitDeductible {
		public String azureId {get;set;}
        public String coveragePremium {get;set;}
        public String factorDefaultValue {get;set;}
        public String factorMax {get;set;}
        public String factorMin {get;set;}
        public String factorValue {get;set;}
        public String overridePremium {get;set;}
        public String coverageId {get;set;}
	}

    public class LimitItem extends LimitDeductible {
        public String limitName {get; set;}
        public String increment {get; set;}
        public String maxAmt {get; set;}
		public String minAmt {get; set;}
        public String optionType {get; set;}
        public String optionValueDefault {get; set;}
        public List<String> optionList {get;set;}
        public String limitCode {get; set;}

        public LimitItem() {
            this.optionList = new List<String>();
        }
       
        public LimitItem(CoveragesLineItem__c item) {
            this.limitName = CommonUtil.convertToStringOrNull(item.Limits_Deductibles__r.Name);
            this.azureId = CommonUtil.convertToStringOrNull(item.Azure_ID__c);
            this.coveragePremium = CommonUtil.convertToStringOrNull(item.Coverage_Premium__c);
            this.factorDefaultValue = CommonUtil.convertToStringOrNull(item.Factor_Default_Value__c);
            this.factorMax = CommonUtil.convertToStringOrNull(item.Factor_Max__c);
            this.factorMin = CommonUtil.convertToStringOrNull(item.Factor_Min__c);
            this.factorValue = CommonUtil.convertToStringOrNull(item.Factor_Value__c);
            this.increment = CommonUtil.convertToStringOrNull(item.Increment_Step__c);
            this.minAmt = CommonUtil.convertToStringOrNull(item.Min_amt__c);
            this.maxAmt = CommonUtil.convertToStringOrNull(item.Max_amt__c);
            this.optionType = CommonUtil.convertToStringOrNull(item.Option_Type__c);
            this.optionValueDefault = CommonUtil.convertToStringOrNull(item.Option_Value_Default__c);
            this.overridePremium = CommonUtil.convertToStringOrNull(item.Override_Premium__c);
            this.optionList = String.isNotBlank(item.Option_Picklist__c) ? 
                                    item.Option_Picklist__c.split(';') : new List<String>();
            this.limitCode = CommonUtil.convertToStringOrNull(item.Limits_Deductibles__r.LmtDedCode__c);
            this.coverageId = CommonUtil.convertToStringOrNull(item.Coverage__r.Id);
        }
    }

    public class DeductibleItem extends LimitDeductible {
        public String deductibleName {get; set;}
        public String increment {get; set;}
        public String maxAmt {get; set;}
		public String minAmt {get; set;}
        public String optionType {get; set;}
        public String optionValueDefault {get; set;}
        public List<String> optionList {get;set;}
        public String deductibleCode {get; set;}

        public DeductibleItem() {
            this.optionList = new List<String>();
        }
        
        public DeductibleItem(CoveragesLineItem__c item) {
            this.deductibleName = CommonUtil.convertToStringOrNull(item.Limits_Deductibles__r.Name);
            this.azureId = CommonUtil.convertToStringOrNull(item.Azure_ID__c);
            this.coveragePremium = CommonUtil.convertToStringOrNull(item.Coverage_Premium__c);
            this.factorDefaultValue = CommonUtil.convertToStringOrNull(item.Factor_Default_Value__c);
            this.factorMax = CommonUtil.convertToStringOrNull(item.Factor_Max__c);
            this.factorMin = CommonUtil.convertToStringOrNull(item.Factor_Min__c);
            this.factorValue = CommonUtil.convertToStringOrNull(item.Factor_Value__c);
            this.increment = CommonUtil.convertToStringOrNull(item.Increment_Step__c);
            this.minAmt = CommonUtil.convertToStringOrNull(item.Min_amt__c);
            this.maxAmt = CommonUtil.convertToStringOrNull(item.Max_amt__c);
            this.optionType = CommonUtil.convertToStringOrNull(item.Option_Type__c);
            this.optionValueDefault = CommonUtil.convertToStringOrNull(item.Option_Value_Default__c);
            this.overridePremium = CommonUtil.convertToStringOrNull(item.Override_Premium__c);
            this.optionList = String.isNotBlank(item.Option_Picklist__c) ? 
                                    item.Option_Picklist__c.split(';') : new List<String>();
            this.deductibleCode = CommonUtil.convertToStringOrNull(item.Limits_Deductibles__r.LmtDedCode__c);
            this.coverageId = CommonUtil.convertToStringOrNull(item.Coverage__r.Id);
        }
    }

    public class OpportunityWrapper {
        public String annualRevenue {get; set;}
        public String attachmentPoint {get;set;}
        public String cashFlow {get; set;}
        public String currentAssets {get; set;}
        public String currentLiabilities {get; set;}
        public String longTermDebt {get; set;}
        public String netIncome {get; set;}
        public String opportunityAzureId {get; set;}
        public String opportunityName {get; set;}
        public String retainedErning {get; set;}
        public String shareHoldersEquity {get; set;}
        public String totalAssets {get; set;}
        public String totalLiabilities {get; set;}
        public String totalRevenues {get; set;}
        public String Industry {get; set;}
        //Added by Maeran Shaikh US:47350 on 10/6/2021
        //public String businessDescription {get; set;}
        
        public AccountWrapper account {get;set;}
        public Map<String,List<RatingModifier>> products {get; set;} 
        public List<SubmissionLossDetailWrapper> submissionLossDetail {get;set;}

        public OpportunityWrapper() {
            this.account = new AccountWrapper();
            this.products = new Map<String,List<RatingModifier>>();
            this.submissionLossDetail = new List<SubmissionLossDetailWrapper>();
        }
        
        public OpportunityWrapper(Opportunity item) {
            this.opportunityAzureId = CommonUtil.convertToStringOrNull(item.Azure_ID__c);
            this.opportunityName    = CommonUtil.convertToStringOrNull(item.Name);
            this.Industry 			= CommonUtil.convertToStringOrNull(item.Industry__c); 
            this.netIncome          = CommonUtil.convertToStringOrNull(item.Net_Income__c);
            this.shareHoldersEquity = CommonUtil.convertToStringOrNull(item.Shareholders_Equity__c);
            this.cashFlow           = CommonUtil.convertToStringOrNull(item.Cash_Flow_From_Operating_Activities__c);
            this.retainedErning     = CommonUtil.convertToStringOrNull(item.Retained_Earnings__c);
            this.annualRevenue      = CommonUtil.convertToStringOrNull(item.AnnualRevenue__c);
            this.totalRevenues      = CommonUtil.convertToStringOrNull(item.Total_Revenues__c);
            this.currentAssets      = CommonUtil.convertToStringOrNull(item.Current_Assets__c);
            this.totalAssets        = CommonUtil.convertToStringOrNull(item.Total_Assets__c);
            this.longTermDebt       = CommonUtil.convertToStringOrNull(item.Long_Term_Debt__c);
            this.currentLiabilities = CommonUtil.convertToStringOrNull(item.Current_Liabilities__c);
            this.totalLiabilities   = CommonUtil.convertToStringOrNull(item.Total_Liabilities__c);
            this.attachmentPoint = CommonUtil.convertToStringOrNull(item.Attachment_Point__c);
            
            ////Added by Maeran Shaikh US:47350 on 10/6/2021
            //this.businessDescription = CommonUtil.convertToStringOrNull(item.Description);

            this.account = new AccountWrapper();
            this.products = new Map<String,List<RatingModifier>>();
            this.submissionLossDetail = new List<SubmissionLossDetailWrapper>();
        }
    }

    public class SubmissionLossDetailWrapper{
        public String addName {get;set;} 
        public String addLossAccount {get;set;}
        public String addNumberofLosses {get;set;}
        public String addStatus {get;set;}
        public String addYear {get; set;}
        
        public SubmissionLossDetailWrapper() {

        }
       
		public SubmissionLossDetailWrapper(Submission_Loss_Detail__c item) {
			this.addName = CommonUtil.convertToStringOrNull(item.Name);
            this.addLossAccount = CommonUtil.convertToStringOrNull(item.Loss_Amount__c);
            this.addNumberofLosses = CommonUtil.convertToStringOrNull(item.Number_of_Losses__c);
            this.addStatus = CommonUtil.convertToStringOrNull(item.Status__c);
            this.addYear = CommonUtil.convertToStringOrNull(item.Year__c);
        }        
    }


    public class ProductWrapper {
        public String Azure_ID {get;set;}
        public String carrierCommission {get;set;}
        public String description {get;set;}
        public String displayUrl {get;set;}
        public String effectiveDate {get;set;}
        public String expirationDate {get;set;}
        public String externalId {get;set;}
        public String family {get;set;}
        public String innoviskEntityID {get;set;}
        public String isActive {get;set;}
        public String marketingMinimumPremium {get;set;}
        public String modelID {get;set;}
        public String name {get;set;}
        public String offer {get;set;}
        public String packageIndicator {get;set;}
        public List<String> payPlan {get;set;}
        public String productFeatures {get;set;}
        public String productImageURL {get;set;}
        public String productCode {get;set;}
        public String quantityUnitOfMeasure {get;set;}
        public String stockKeepingUnit {get;set;}
        public String umr {get;set;}
        public String writingCompany {get;set;}

        public ProductWrapper() {
 
        }

        public ProductWrapper(Product2 item) {
            this.Azure_ID = CommonUtil.convertToStringOrNull(item.Azure_ID__c);
            this.carrierCommission = CommonUtil.convertToStringOrNull(item.Carrier_Commission__c);
            this.description = CommonUtil.convertToStringOrNull(item.Description);
            this.displayUrl = CommonUtil.convertToStringOrNull(item.DisplayUrl);
            this.effectiveDate = item.Effective_Date__c != null ? String.valueOf(item.Effective_Date__c) : null;
            this.expirationDate = item.Expiration_Date__c != null ? String.valueOf(item.Expiration_Date__c) : null;                                
            this.externalId = CommonUtil.convertToStringOrNull(item.ExternalId);
            this.family = CommonUtil.convertToStringOrNull(item.Family);
            this.innoviskEntityID = CommonUtil.convertToStringOrNull(item.Innovisk_Entity_ID__c);
            this.isActive = CommonUtil.convertToStringOrNull(item.IsActive);
            this.marketingMinimumPremium = CommonUtil.convertToStringOrNull(item.Marketing_Minimum_premium__c);
            this.modelID = CommonUtil.convertToStringOrNull(item.Model_ID__c);
            this.name = CommonUtil.convertToStringOrNull(item.Name);
            this.offer = CommonUtil.convertToStringOrNull(item.Offer__c);
            this.packageIndicator = CommonUtil.convertToStringOrNull(item.Package_Indicator__c);
            this.payPlan = String.isNotBlank(item.Pay_Plan__c) ? item.Pay_Plan__c.split(';') : new List<String>();
            this.productFeatures = CommonUtil.convertToStringOrNull(item.Product_Features__c);
            this.productImageURL = CommonUtil.convertToStringOrNull(item.Product_Image_URL__c);
            this.productCode = CommonUtil.convertToStringOrNull(item.ProductCode);
            this.quantityUnitOfMeasure = CommonUtil.convertToStringOrNull(item.QuantityUnitOfMeasure);
            this.stockKeepingUnit = CommonUtil.convertToStringOrNull(item.StockKeepingUnit);
            this.umr = CommonUtil.convertToStringOrNull(item.UMR__c);
            this.writingCompany = CommonUtil.convertToStringOrNull(item.Writing_Company__c);
        }
    }

    public class AccountWrapper {
        public String azureID {get; set;}
        public String name {get; set;}
        public Address billingAddress {get; set;}
        public String dunsNumber {get; set;}
        public String compositCredit {get;set;}
        public String dBRatingClassification {get;set;}
              
        public AccountWrapper () {

        }
        
        public AccountWrapper(Account item) {
            this.azureID = CommonUtil.convertToStringOrNull(item.Azure_ID__c);
            this.name = CommonUtil.convertToStringOrNull(item.Name);
            this.billingAddress = item.BillingAddress;
            this.dunsNumber = CommonUtil.convertToStringOrNull(item.Duns_Number__c);
            this.compositCredit = CommonUtil.convertToStringOrNull(item.Composite_Credit_Appraisal__c);
            this.dBRatingClassification = CommonUtil.convertToStringOrNull(item.D_B_Rating_Classification__c);
        }
    }
	
	public class RatingModifier {
        public String azureID {get; set;}
        public String format {get; set;}
        public String ratingModifierName {get; set;}
        public String ratingModifierValue {get; set;}
        public String ratingModifierCode {get; set;}
        public String pageSection {get; set;}
        public RatingModifier() {

        }

        public RatingModifier(Rating_Modifiers__c item) {
            if (item == null) return;

            this.azureID = CommonUtil.convertToStringOrNull(item.Azure_ID__c);
            this.format = CommonUtil.convertToStringOrNull(item.Format__c);
            this.ratingModifierName = CommonUtil.convertToStringOrNull(item.Name);
            this.ratingModifierValue = CommonUtil.convertToStringOrNull(item.Rating_Modifier_Value__c);
            this.ratingModifierCode = CommonUtil.convertToStringOrNull(item.Rating_Modifier_Code__c);
            this.pageSection = CommonUtil.convertToStringOrNull(item.Page_Section__c);
        }
	}

    public class RatingModifierFactor {
        public String defaultValue {get; set;}
        public String factorMin	{get; set;}
        public String factorMax	{get; set;}
        public String factorValue {get; set;}
        public RatingModifier modifier {get;set;}

        public RatingModifierFactor() {

        }

        public RatingModifierFactor(Rating_Modifier_Factor__c item) {
            if (item == null) return;

            this.factorMin = CommonUtil.convertToStringOrNull(item.Factor_Min__c);
            this.factorMax = CommonUtil.convertToStringOrNull(item.Factor_Max__c);
            this.factorValue = CommonUtil.convertToStringOrNull(item.Factor_Value__c);
            this.defaultValue = CommonUtil.convertToStringOrNull(item.Factor_Default_Value__c);
            this.modifier = new RatingModifier(item.Rating_Modifier__r);
        }
    }

    /*************************************************
    * Author:Tuan Nguyen
    * Date: Otc 08 2019
    * Params: 
    * Return: 
    * Desciption: get rating request obj
    * Revision: 
     *************************************************/
    public static RatingRequest getRatingRequest(String quoteId, String oppId) {
        RatingRequest result = new RatingRequest();
        try {
            result.quote = getQuoteWrapper(quoteId);
            result.opportunity = getOpportunityWrapper(oppId);
            Product2 p = getProductForRating(oppId);

            result.productConfigAttributes = new ProductWrapper(p);
            //get parent quote's coverage line items
            //result.priorQuoteCoverageLineItems = getPriorCoverageLineItem(quoteId);
            //result.priorQuoteCoverageLineItems = getPriorCoverageLineItem2(quoteId);
            List<CoveragesLineItem__c> priorCliItems = getPriorCoverageLineItem2(quoteId);
            // generate sub coverage map
            Map<String, Map<String, List<CoveragesLineItem__c>>> priorCliMap = getSubCoveragesMap(priorCliItems);
            // generate coverage line item response
            result.priorQuoteCoverageLineItems = generatePriorCoverageItems(priorCliMap);

        } catch (Exception ex) {
            throw new Warnings.RatingException(ex.getMessage());
        }
        

        return result;
    }

    public static QuoteWrapper getQuoteWrapper(String quoteId){ 
        QuoteWrapper result = new QuoteWrapper();
        try {
            // get quote
            Quote ratedQuote = getQuoteForRating(quoteId);

            // generate Quote wrapper
            result = new QuoteWrapper(ratedQuote);

            // get Coverage Line Items by quote
            // can't use direct assignment when there're too many child records
            List<CoveragesLineItem__c> clis = getCoverageLineItems(quoteId);                        
            List<Rating_Modifier_Factor__c> factors = getRatingModifierFactors(quoteId);      
            // group Coverage line item by product
            Map<String,List<CoveragesLineItem__c>> cliProductMap = new Map<String,List<CoveragesLineItem__c>>();
            cliProductMap = generateCoverageProductMap(clis);

            // group Rating Modifier Factors by product
            Map<String,List<RatingModifierFactor>> factorProductMap = new Map<String,List<RatingModifierFactor>>();
            factorProductMap = generateFactorProductMap(factors);

            Map<String,CoverageProductWrapper> resultMap = new Map<String,CoverageProductWrapper>();
            
            // combine all products because quote might not have all products from Submission
            Set<String> cliProducts = cliProductMap.keySet();
            Set<String> factorProducts = factorProductMap.keySet();
            Set<String> products = new Set<String>();
            products.addAll(cliProducts);
            products.addAll(factorProducts);

            // loop through each product
            for(String key : products) {
                // get coverage line item by product
                List<CoveragesLineItem__c> cliItems = cliProductMap.get(key);
                // get rating modifier factor by product
                List<RatingModifierFactor> factorItems = factorProductMap.get(key);

                CoverageProductWrapper covWrapper = new CoverageProductWrapper();

                if (cliItems != null) {
                    // generate sub coverage map
                    Map<String, Map<String, List<CoveragesLineItem__c>>> cliMap = getSubCoveragesMap(cliItems);
                    // generate coverage line item response
                    covWrapper.coverageLineItems = generateCoverageItems(cliMap);
                }
                
                if (factorItems != null) {
                    covWrapper.factors = factorItems;
                }
                
                resultMap.put(key, covWrapper);
            }
            result.products = resultMap;

        } catch (Exception ex) {
            result = new quoteWrapper();
            System.debug(ex.getMessage() + ' - ' + ex.getLineNumber());
        }
        return result;
    }

    public static OpportunityWrapper getOpportunityWrapper(String oppId){
        OpportunityWrapper result = new OpportunityWrapper(); 
        try {
            Opportunity opp = getOpportunityForRating(oppId);
            // can't use direct assignment when there're too many child records
            List<Rating_Modifiers__c> items = getRatingModifiers(oppId);

            Map<String, List<RatingModifier>> mapTemp = new Map<String, List<RatingModifier>>();

            for(Rating_Modifiers__c item : items) {
                RatingModifier tmp = new RatingModifier(item);
                if(mapTemp.containsKey(item.Product__c)) {
                    mapTemp.get(item.Product__c).add(tmp);
                } else {
                    mapTemp.put(item.Product__c, new List<RatingModifier> {tmp});
                }   
            }
            
            result = new OpportunityWrapper(opp);
            result.Account = new AccountWrapper(opp.Account);
            result.Products = mapTemp;
            result.submissionLossDetail = getSubmissionLossDetail(oppId);
        } catch (Exception ex) {
            result = new OpportunityWrapper();
            throw new Warnings.RatingException('Failed to generate Opportunity Wrapper');
        }
        return result;
    }   
    
    //Tien added on 4 June 20 , Submission Loss Detail 
    public static List<SubmissionLossDetailWrapper> getSubmissionLossDetail(String submissionId){
        List<SubmissionLossDetailWrapper> result = new List<SubmissionLossDetailWrapper>();
        try {
            for(Submission_Loss_Detail__c  c : [Select Name, Loss_Amount__c, Status__c, Year__c,Number_of_Losses__c from Submission_Loss_Detail__c
                                              where Submission__c =: submissionId])
            {
            result.add(new SubmissionLossDetailWrapper(c));
            }          
        } catch (Exception ex) {
            result = new List<SubmissionLossDetailWrapper>();
            throw new Warnings.RatingException('Failed to generate Submission Loss Detail');
        }
        return result;
	}

    /*************************************************
    * Author:Tuan Nguyen
    * Date: Sep 26 2019
    * Params: 
    * Return: 
    * Desciption: group Coverage line item by product
    * Revision: 
     *************************************************/
    private static Map<String,List<CoveragesLineItem__c>> generateCoverageProductMap(List<CoveragesLineItem__c> items) {
        Map<String,List<CoveragesLineItem__c>> result = new Map<String,List<CoveragesLineItem__c>>();
        try {
            for (CoveragesLineItem__c cli : items) {  
                String productName = '';
                // get product name
                if (cli.Coverage__r != null) {
                    productName = cli.Coverage__r.Coverage_Product__c;
                }

                if (result.containsKey(productName)) {
                    result.get(productName).add(cli);     
                } else {
                    result.put(productName, new List<CoveragesLineItem__c> {cli});
                }     
            }
        } catch (Exception ex) {
            result = new Map<String,List<CoveragesLineItem__c>>();
            throw new Warnings.RatingException('Failed to generate Product Map for Coverage Line Item');
        }
        return result;
    }

    /*************************************************
    * Author:Tuan Nguyen
    * Date: March 24 2020
    * Params: 
    * Return: 
    * Desciption: group Rating Modifier Factor by product
    * Revision: 
     *************************************************/
    private static Map<String,List<RatingModifierFactor>> generateFactorProductMap(List<Rating_Modifier_Factor__c> items) {
        Map<String,List<RatingModifierFactor>> result = new Map<String,List<RatingModifierFactor>>();
        try {
            for (Rating_Modifier_Factor__c item : items) {  
                String productName = '';
                // get product name
                if (item.Rating_Modifier__r != null) {
                    productName = item.Rating_Modifier__r.Product__c;
                }

                RatingModifierFactor factor = new RatingModifierFactor(item);
                if (result.containsKey(productName)) {
                    result.get(productName).add(factor);     
                } else {
                    result.put(productName, new List<RatingModifierFactor> {factor});
                }     
            }
        } catch (Exception ex) {
            result = new Map<String,List<RatingModifierFactor>>();
            throw new Warnings.RatingException('Failed to generate Product Map For Factors');
        }
        return result;
    }

    /*************************************************
    * Author:Tuan Nguyen
    * Date: Sep 26 2019
    * Params: 
    * Return: 
    * Desciption: group Coverage line item by product
    * Revision: 
     *************************************************/
    private static List<CoverageItem> generateCoverageItems(Map<String, Map<String, List<CoveragesLineItem__c>>> objMap) {
        
        List<CoverageItem> result = new List<CoverageItem>();
        try {
            // loop through coverage map
            for (String key : objMap.keySet()) {
                // create coverage
                CoverageItem cov = new CoverageItem();
                List<SubCoverageItem> subCoverages = new List<SubCoverageItem>();
                //cov.coverageName = key;

                Map<String, List<CoveragesLineItem__c>> subMap = objMap.get(key);
                Map<String, List<LimitDeductible>> limitMap = new Map<String, List<LimitDeductible>>();				       
                
                // loop through sub coverage map
                for (String subKey : subMap.keySet()) {
                    // create sub coverage
                    SubCoverageItem subCov = new SubCoverageItem();

                    // get limit and deductible
                    List<CoveragesLineItem__c> items = subMap.get(subKey);

                    // group limit and deductible by subcoverage
                    limitMap = generateLimitDeductible(items);
                    List<LimitDeductible> limItems = limitMap.get('Limit');
                    List<LimitDeductible> deductItems = limitMap.get('Deduct');

                    // Get main or sub coverage item node
                    CoveragesLineItem__c cli = generateMainSubCoverage(items);

                    // Main Coverage
                    if (String.isBlank(subKey)) {
                        cov = new CoverageItem(cli);
                        cov.limits = limItems;
                        cov.deductibles = deductItems;

                    // Sub coverage    
                    } else {
                        subCov = new SubCoverageItem(cli);
                        subCov.limits = limItems;
                        subCov.deductibles = deductItems;

                        subCoverages.add(subCov);
                    }
                }

                cov.subCoverages = subCoverages;
                
                result.add(cov);
            }
        } catch (Exception ex) {
            result.clear();
            throw new Warnings.RatingException('Failed to generate Coverage Item');
        }
        return result;
    }

    /*************************************************
    * Author:Tuan Nguyen
    * Date: Sep 26 2019
    * Params: 
    * Return: 
    * Desciption: group Coverage line item by product
    * Revision: 
     *************************************************/
    private static List<PriorCoverageItem> generatePriorCoverageItems(Map<String, Map<String, List<CoveragesLineItem__c>>> objMap) {
        
        List<PriorCoverageItem> result = new List<PriorCoverageItem>();
        try {
            // loop through coverage map
            for (String key : objMap.keySet()) {
                // create coverage
                PriorCoverageItem cov = new PriorCoverageItem();
                List<PriorSubCoverageItem> subCoverages = new List<PriorSubCoverageItem>();
                //cov.coverageName = key;

                Map<String, List<CoveragesLineItem__c>> subMap = objMap.get(key);
                Map<String, List<LimitDeductible>> limitMap = new Map<String, List<LimitDeductible>>();				       
                
                // loop through sub coverage map
                for (String subKey : subMap.keySet()) {
                    // create sub coverage
                    PriorSubCoverageItem subCov = new PriorSubCoverageItem();

                    // get limit and deductible
                    List<CoveragesLineItem__c> items = subMap.get(subKey);

                    // group limit and deductible by subcoverage
                    //limitMap = generatePriorLimitDeductible(items);
                    List<PriorLimitItem> limItems = new List<PriorLimitItem>();
                    List<PriorDeductibleItem> deductItems = new List<PriorDeductibleItem>();
                    for (CoveragesLineItem__c cli : items) {
                        // Coverage line item is either main or sub coverage
                        if (cli.Limits_Deductibles__r == null) continue;				
                        if (cli.Limits_Deductibles__r.RecordType.DeveloperName == 'Limit_Option') {
                            PriorLimitItem item = new PriorLimitItem(cli);
                            limItems.add(item);
                        } else {
                            PriorDeductibleItem item = new PriorDeductibleItem(cli);
                            deductItems.add(item);
                        }
                    }


                    //List<PriorLimitItem> limItems = limitMap.get('Limit');
                    //List<PriorDeductibleItem> deductItems = limitMap.get('Deduct');

                    // Get main or sub coverage item node
                    CoveragesLineItem__c cli = generateMainSubCoverage(items);

                    // Main Coverage
                    if (String.isBlank(subKey)) {
                        cov = new PriorCoverageItem(cli);
                        cov.limits = limItems;
                        cov.deductibles = deductItems;

                    // Sub coverage    
                    } else {
                        subCov = new PriorSubCoverageItem(cli);
                        subCov.limits = limItems;
                        subCov.deductibles = deductItems;

                        subCoverages.add(subCov);
                    }
                }

                cov.subCoverages = subCoverages;
                
                result.add(cov);
            }
        } catch (Exception ex) {
            result.clear();
            throw new Warnings.RatingException('Failed to generate Coverage Item');
        }
        return result;
    }

    /*************************************************
    * Author:Tuan Nguyen
    * Date: Sep 26 2019
    * Params: 
    * Return: 
    * Desciption: generate Main or sub coverage item
    * INPUT MUST BE A SUB COVERAGE MAP
    * Revision: 
     *************************************************/
    private static CoveragesLineItem__c generateMainSubCoverage(List<CoveragesLineItem__c> items) {
        CoveragesLineItem__c result = new CoveragesLineItem__c();
        if (items == null)
            return result;

        for (CoveragesLineItem__c item : items) {
            // not a main or sub coverage
            if (item.Limits_Deductibles__r == null) {
                result = item;
                break;
            }
        }

        return result;
    }

    /*************************************************
    * Author:Tuan Nguyen
    * Date: Sep 26 2019
    * Params: 
    * Return: 
    * Desciption: generate Limit and deductible map base on coverage and sub coverage
    * Revision: 
     *************************************************/
    private static Map<String, List<LimitDeductible>> generateLimitDeductible(List<CoveragesLineItem__c> items) {
        Map<String, List<LimitDeductible>> result = new Map<String, List<LimitDeductible>>();
        List<LimitItem> limItems = new List<LimitItem>();
        List<DeductibleItem> deductItems = new List<DeductibleItem>();

        try {
            for (CoveragesLineItem__c cli : items) {
                // Coverage line item is either main or sub coverage
                if (cli.Limits_Deductibles__r == null) continue;				
                if (cli.Limits_Deductibles__r.RecordType.DeveloperName == 'Limit_Option') {
                    LimitItem item = new LimitItem(cli);
                    limItems.add(item);
                } else {
                    DeductibleItem item = new DeductibleItem(cli);
                    deductItems.add(item);
                }
            }
            result.put('Limit', limItems);
            result.put('Deduct', deductItems);

        } catch (Exception ex) {
            result.clear();
            System.debug(ex.getMessage() + ' - ' + ex.getLineNumber());
            throw new Warnings.RatingException('Failed to generate Limit And Deductible');
        }
        return result;
    }

    private static Map<String, Map<String, List<CoveragesLineItem__c>>> getSubCoveragesMap(List<CoveragesLineItem__c> items) {
        Map<String, Map<String, List<CoveragesLineItem__c>>> result = new Map<String, Map<String, List<CoveragesLineItem__c>>>();
        try {
            for (CoveragesLineItem__c cli : items) {
                String key = '';
                String subKey = '';
            
                if (cli.Coverage__r != null) key = cli.Coverage__r.Name;  // get coverage name
                if (cli.Sub_Coverage__r != null) subKey = cli.Sub_Coverage__r.Name; // get sub coverage name

				// Coverage is new
                Map<String, List<CoveragesLineItem__c>> subMap = result.get(key);
                if (subMap == null) subMap = new Map<String, List<CoveragesLineItem__c>>();
                
				// Sub coverage is new
                List<CoveragesLineItem__c> subItems = subMap.get(subKey);
                if (subItems == null) subItems = new List<CoveragesLineItem__c>();
  
                subItems.add(cli);
                subMap.put(subKey, subItems);
                result.put(key, subMap);
            }
        } catch (Exception ex) {
            result = new Map<String, Map<String, List<CoveragesLineItem__c>>>();
            System.debug(ex.getMessage() + ' - ' + ex.getLineNumber());
            throw new Warnings.RatingException('Failed to generate Sub Coverage Map');
        }
        return result;
    } 

    private static Quote getQuoteForRating(String quoteId) {
        Quote result = new Quote();
        try {
            List<Quote> quotes = [SELECT Id,Commission_percentage__c,Azure_ID__c, Effective_Date__c, QuoteNumber, ExpirationDate,
                                    AccountId, Coverage_Product_Options__c, Master_Set_ID__c, Endorsement_Effective_Date__c,                
                                    Quote_Type__c, Name, Status, Override_Premium__c, Override_Premium_Percentage__c,Parent_Quote__c
                                FROM Quote Where Id = :quoteId
                                AND OpportunityId != null AND Opportunity.Product__c != null];
            if (!quotes.isEmpty()) result = quotes[0];
            
        } catch (Exception ex) {
            result = new Quote();
            throw new Warnings.RatingException('Failed to get Quote');
        }

        return result;
    }

    private static Opportunity getOpportunityForRating(String oppId) {
        Opportunity result = new Opportunity();
        try {
            List<Opportunity> listOpp = [SELECT Id,Azure_ID__c, Name,Industry__c,Total_Revenues__c,
                                        AnnualRevenue__c, Cash_Flow_From_Operating_Activities__c,
                                        Current_Assets__c, Current_Liabilities__c,
                                        Long_Term_Debt__c, Net_Income__c, Retained_Earnings__c,
                                        Shareholders_Equity__c, Total_Assets__c, Total_Liabilities__c,
                                        Attachment_Point__c, Account.Name, Account.Azure_ID__c,
                                        Account.BillingAddress, Account.Duns_Number__c,
                                        Account.D_B_Rating_Classification__c, 
                                        Account.Composite_Credit_Appraisal__c,
                                        Product__r.Azure_ID__c, Product__r.Carrier_Commission__c,
                                        Product__r.Description, Product__r.DisplayUrl,
                                        Product__r.Effective_Date__c, Product__r.Expiration_Date__c,
                                        Product__r.ExternalId, Product__r.Family, 
                                        Product__r.Innovisk_Entity_ID__c, Product__r.IsActive,
                                        Product__r.Marketing_Minimum_premium__c, Product__r.Model_ID__c,
                                        Product__r.Name, Product__r.Offer__c, Product__r.Package_Indicator__c, 
                                        Product__r.Pay_Plan__c, Product__r.Product_Features__c, 
                                        Product__r.Product_Image_URL__c, Product__r.ProductCode,
                                        Product__r.QuantityUnitOfMeasure, Product__r.StockKeepingUnit, 
                                        Product__r.UMR__c, Product__r.Writing_Company__c
                                         // //Added by Maeran Shaikh US:47350 on 10/6/2021
                                        //Description
                                    FROM Opportunity WHERE Id = :oppId];
 
            if(!listOpp.isEmpty()) result = listOpp[0];
        } catch (Exception ex) {
            result = new Opportunity();
            throw new Warnings.RatingException('Failed to get Opportunity');
        }
        return result;
    }

    private static Product2 getProductForRating(String oppId) {
        Product2 result = new Product2();
        try {
            List<Opportunity> listOpp = [SELECT Id,
                                        Product__r.Azure_ID__c, Product__r.Carrier_Commission__c,
                                        Product__r.Description, Product__r.DisplayUrl,
                                        Product__r.Effective_Date__c, Product__r.Expiration_Date__c,
                                        Product__r.ExternalId, Product__r.Family, 
                                        Product__r.Innovisk_Entity_ID__c, Product__r.IsActive,
                                        Product__r.Marketing_Minimum_premium__c, Product__r.Model_ID__c,
                                        Product__r.Name, Product__r.Offer__c, Product__r.Package_Indicator__c, 
                                        Product__r.Pay_Plan__c, Product__r.Product_Features__c, 
                                        Product__r.Product_Image_URL__c, Product__r.ProductCode,
                                        Product__r.QuantityUnitOfMeasure, Product__r.StockKeepingUnit, 
                                        Product__r.UMR__c, Product__r.Writing_Company__c
                                    FROM Opportunity WHERE Id = :oppId];
            if(!listOpp.isEmpty()) result = listOpp[0].Product__r;
        } catch (Exception ex) {
            result = new Product2();
            throw new Warnings.RatingException('Failed to get Product');
        }
        return result;
    }

    private static List<Rating_Modifiers__c> getRatingModifiers(String oppId) {
        List<Rating_Modifiers__c> result = new List<Rating_Modifiers__c>();
        try {
            result = [SELECT Id, Name, Product__c, Rating_Modifier_Value__c,  
                      Rating_Modifier_Code__c, Format__c, Azure_ID__c, Page_Section__c
                    FROM Rating_Modifiers__c WHERE Opportunity__c =:oppId 
                    AND (NOT Page_Section__c LIKE '%Eligibility')];
        } catch (Exception ex) {
            result.clear();
            //System.debug(ex.getMessage() + ' - ' + ex.getLineNumber());
            throw new Warnings.RatingException('Failed to get Rating Modifiers');
        }
        return result;
    }

    private static List<CoveragesLineItem__c> getCoverageLineItems(String quoteId) {
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        try {
            result = [SELECT ID, Name, Azure_ID__c, 
                        Sub_Coverage__r.Id, Sub_Coverage__r.Name,
                        Sub_Coverage__r.Coverage_Code__c, Coverage__r.Coverage_Code__c,
                        Coverage__r.Id, Coverage__r.Name, Coverage_Premium__c,
                        Factor_Value__c, Coverage__r.Coverage_Product__c,
                        Factor_Min__c, Factor_Max__c, Increment_Step__c, 
                        Factor_Default_Value__c,Limits_Deductibles__c, 
                        Limits_Deductibles__r.Name, Limits_Deductibles__r.Type__c,
                        Limits_Deductibles__r.RecordTypeId,Limits_Deductibles__r.LmtDedCode__c,
                        Limits_Deductibles__r.RecordType.DeveloperName,
                        Limits_Deductibles__r.RecordType.Name, Max_amt__c, Min_amt__c,
                        Option_Type__c, Option_Value_Default__c,
                        Option_Picklist__c,Override_Premium__c, Rating__c 
                    FROM CoveragesLineItem__c WHERE Quote__c = :quoteId 
                    AND Rating__c = true]; //adding Rating__c to filter as #20058 - KhanhTran

        } catch (Exception ex) {
            result.clear();
            System.debug(ex.getMessage() + ' - ' + ex.getLineNumber());
            throw new Warnings.RatingException('Failed to get Coverage Line Items');
        }

        return result;
    }

    private static List<Rating_Modifier_Factor__c> getRatingModifierFactors(String quoteId) {
        List<Rating_Modifier_Factor__c> result = new List<Rating_Modifier_Factor__c>();
        try {
            result = [SELECT Factor_Default_Value__c, Factor_Max__c, Factor_Min__c,
                        Factor_Value__c, Rating_Modifier__r.Rating_Modifier_Value__c,
                        Rating_Modifier__r.Rating_Modifier_Code__c, Rating_Modifier__r.Format__c,
                        Rating_Modifier__r.Name, Rating_Modifier__r.Product__c,
                        Rating_Modifier__r.Azure_ID__c, Rating_Modifier__r.Page_Section__c
                    FROM Rating_Modifier_Factor__c WHERE Quote__c = :quoteId
                    AND (NOT Rating_Modifier__r.Page_Section__c LIKE '%Eligibility')];

        } catch (Exception ex) {
            result.clear();
            System.debug(ex.getMessage() + ' - ' + ex.getLineNumber());
            throw new Warnings.RatingException('Failed to get Rating Modifier Factors');
        }

        return result;
    }

    public static Quote getBoundQuote(String quoteId) {     
        Quote currentQuote = [Select Id, QuotePremium__c, Non_Prorated_Quote_Premium__c
                              From Quote Where Id = :quoteId LIMIT 1];  
        return currentQuote;
    }


	virtual class PriorCoverage {
        public String azureId {get;set;}
        public String nonProratedCoveragePremium {get;set;}
        public String coveragePremium  {get;set;}
    }
    //tuan.d.nguyen added 21-Jul-2020 
    public class PriorCoverageItem extends PriorCoverage{
        public String coverageName {get;set;}
        public String coverageCode {get;set;}
        public List<PriorSubCoverageItem> subCoverages {get; set;}
        public List<PriorLimitItem> limits	{get; set;}
		public List<PriorDeductibleItem> deductibles {get; set;}

        public PriorCoverageItem() {
            this.coverageCode = '';
            this.coverageName = '';
            this.subCoverages = new List<PriorSubCoverageItem>();
            this.limits = new List<PriorLimitItem>();
            this.deductibles = new List<PriorDeductibleItem>();
        }

        public PriorCoverageItem(CoveragesLineItem__c cli) {
            this.azureID = CommonUtil.convertToStringOrNull(cli.Azure_ID__c);
            this.coverageName = CommonUtil.convertToStringOrNull(cli.Coverage__r.Name);
            this.coverageCode = CommonUtil.convertToStringOrNull(cli.Coverage__r.Coverage_Code__c);
            this.nonProratedCoveragePremium = CommonUtil.convertToStringOrNull(cli.Non_Prorated_Coverage_Premium__c);
            this.coveragePremium = CommonUtil.convertToStringOrNull(cli.Coverage_Premium__c);
            this.subCoverages = new List<PriorSubCoverageItem>();
            this.limits = new List<PriorLimitItem>();
            this.deductibles = new List<PriorDeductibleItem>(); 
		}
    }

    public class PriorSubCoverageItem extends PriorCoverage{
        public String subCoverageCode 				{get; set;}
		public String subCoverageName 				{get; set;}
        public List<PriorLimitItem> limits			{get; set;}
		public List<PriorDeductibleItem> deductibles	{get; set;}

        public PriorSubCoverageItem() {
            this.limits = new List<PriorLimitItem>();
            this.deductibles = new List<PriorDeductibleItem>();
        }

        public PriorSubCoverageItem(CoveragesLineItem__c item) {
            this.subCoverageCode = item.Sub_Coverage__r.Coverage_Code__c;
            this.subCoverageName = item.Sub_Coverage__r.Name; 
            this.azureId = CommonUtil.convertToStringOrNull(item.Azure_ID__c);
            this.nonProratedCoveragePremium = CommonUtil.convertToStringOrNull(item.Non_Prorated_Coverage_Premium__c);
            this.coveragePremium = CommonUtil.convertToStringOrNull(item.Coverage_Premium__c);        
            this.limits = new List<PriorLimitItem>();
            this.deductibles = new List<PriorDeductibleItem>();
        }
    }

    public class PriorLimitItem extends PriorCoverage {
        public String limitName {get; set;}
        public String limitCode {get; set;}

        public PriorLimitItem(CoveragesLineItem__c item) {
            this.limitName = CommonUtil.convertToStringOrNull(item.Limits_Deductibles__r.Name);
            this.limitCode = CommonUtil.convertToStringOrNull(item.Limits_Deductibles__r.LmtDedCode__c);
            this.azureId = CommonUtil.convertToStringOrNull(item.Azure_ID__c);
            this.nonProratedCoveragePremium = CommonUtil.convertToStringOrNull(item.Non_Prorated_Coverage_Premium__c);
            this.coveragePremium = CommonUtil.convertToStringOrNull(item.Coverage_Premium__c);
        }
    }

    public class PriorDeductibleItem extends PriorCoverage {
        public String deductibleName {get; set;}
        public String deductibleCode {get; set;}
        
        public PriorDeductibleItem(CoveragesLineItem__c item) {
            this.deductibleName = CommonUtil.convertToStringOrNull(item.Limits_Deductibles__r.Name);
            this.deductibleCode = CommonUtil.convertToStringOrNull(item.Limits_Deductibles__r.LmtDedCode__c);
            this.azureId = CommonUtil.convertToStringOrNull(item.Azure_ID__c);
            this.nonProratedCoveragePremium = CommonUtil.convertToStringOrNull(item.Non_Prorated_Coverage_Premium__c);
            this.coveragePremium = CommonUtil.convertToStringOrNull(item.Coverage_Premium__c);         
        }
    }
	/*
    public static List<PriorCoverageItem> getPriorCoverageLineItem(String quoteId) {         
        Quote ratedQuote = getQuoteForRating(quoteId);
        List<PriorCoverageItem> listPriorCoverageLineItems = new List<PriorCoverageItem>();
        //generate priorCoverageLineItem 
        if(ratedQuote.Quote_Type__c != 'New Business' && String.isNotBlank(ratedQuote.Parent_Quote__c))
		{
            for(CoveragesLineItem__c cli : [SELECT Azure_ID__c, CoverageLineItemType__c,
										Coverage__r.Coverage_Code__c, Coverage__r.Name, 
										Sub_Coverage__r.Coverage_Code__c, Sub_Coverage__r.Name, 
										Limits_Deductibles__r.LmtDedCode__c, Limits_Deductibles__r.Name,
										Non_Prorated_Coverage_Premium__c,Coverage_Premium__c
                                        FROM CoveragesLineItem__c WHERE Quote__c = :ratedQuote.Parent_Quote__c
										Order by Coverage__r.Coverage_Code__c, Sub_Coverage__r.Coverage_Code__c]) 
			{
				PriorCoverageItem priorCLI = new PriorCoverageItem(cli);
				listPriorCoverageLineItems.add(priorCLI);
            }
        }
        
        return listPriorCoverageLineItems;
    }
    */
    
    /*************************************************
    * Author:Tuan Nguyen
    * Date: Sep 26 2019
    * Params: 
    * Return: 
    * Desciption: generate Limit and deductible map base on coverage and sub coverage
    * Revision: 
     *************************************************/
    /*private static Map<String, List<LimitDeductible>> generatePriorLimitDeductible(List<CoveragesLineItem__c> items) {
        Map<String, List<LimitDeductible>> result = new Map<String, List<LimitDeductible>>();
        List<PriorLimitItem> limItems = new List<PriorLimitItem>();
        List<PriorDeductibleItem> deductItems = new List<PriorDeductibleItem>();

        try {
            for (CoveragesLineItem__c cli : items) {
                // Coverage line item is either main or sub coverage
                if (cli.Limits_Deductibles__r == null) continue;				
                if (cli.Limits_Deductibles__r.RecordType.DeveloperName == 'Limit_Option') {
                    PriorLimitItem item = new PriorLimitItem(cli);
                    limItems.add(item);
                } else {
                    PriorDeductibleItem item = new PriorDeductibleItem(cli);
                    deductItems.add(item);
                }
            }
            result.put('Limit', limItems);
            result.put('Deduct', deductItems);

        } catch (Exception ex) {
            result.clear();
            System.debug(ex.getMessage() + ' - ' + ex.getLineNumber());
            throw new Warnings.RatingException('Failed to generate Limit And Deductible');
        }
        return result;
    }*/

	public static List<CoveragesLineItem__c> getPriorCoverageLineItem2(String quoteId) {         
        Quote ratedQuote = getQuoteForRating(quoteId);
		List<CoveragesLineItem__c> listPriorCoverageLineItems = new List<CoveragesLineItem__c>();
        
        //generate priorCoverageLineItem 
        if(ratedQuote.Quote_Type__c != 'New Business' && String.isNotBlank(ratedQuote.Parent_Quote__c))
		{
            listPriorCoverageLineItems = [SELECT Azure_ID__c, CoverageLineItemType__c,
										Coverage__r.Coverage_Code__c, Coverage__r.Name, 
										Sub_Coverage__r.Coverage_Code__c, Sub_Coverage__r.Name, 
                                        Limits_Deductibles__r.LmtDedCode__c, Limits_Deductibles__r.Name,
                                        Limits_Deductibles__r.RecordType.DeveloperName,
										Non_Prorated_Coverage_Premium__c,Coverage_Premium__c
                                        FROM CoveragesLineItem__c WHERE Quote__c = :ratedQuote.Parent_Quote__c
										Order by Coverage__r.Coverage_Code__c, Sub_Coverage__r.Coverage_Code__c,
										 Limits_Deductibles__r.LmtDedCode__c NULLS FIRST];
        }
        
        return listPriorCoverageLineItems;
    }
}