@isTest
public class REST_RatingTest {
    @testSetup static void setup(){
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
        insert product; 
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Prospect';
        insert opp;
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'In Progress';
        quote1.Coverage_Product_Options__c = 'D&O';
        quote1.Refer_Type__c = 'Underwriting Referral';
        insert quote1;          
    }
    @isTest
    static void WrapperTest(){
        Test.startTest();
        //CoverageOptionWrapper
        REST_Rating.CoverageOptionWrapper covOpt = new REST_Rating.CoverageOptionWrapper();
        covOpt.id = '22';
        covOpt.optionName = 'test opt';
        covOpt.optionNumber = '222';
        covOpt.perilType = 'test type';
        
        //BindPlusCoverageLineItemWrapper
        REST_Rating.BindPlusCoverageLineItemWrapper bindCovWrap = new REST_Rating.BindPlusCoverageLineItemWrapper();
        bindCovWrap.coverageOptions = new List<REST_Rating.CoverageOptionWrapper>{covOpt};
        bindCovWrap.additionalCoverageOptions = new List<REST_Rating.CoverageOptionWrapper>{covOpt};
            
        //AssetWrapper
        REST_Rating.AssetWrapper assetWrap = new REST_Rating.AssetWrapper();
        assetWrap.Equipment_Id = '2123';
        assetWrap.Equipment_Intel_Ordered_Date = String.valueOf(Date.today());
        assetWrap.Equipment_Watch_Sub_Type = 'Test';
        assetWrap.Equipment_Watch_Type = 'Test Sub';
        assetWrap.Fair_Market_Value = '1000';
        assetWrap.Type = 'Test type';
        assetWrap.UWCodes = new List<String>{'1','2','3'};
        assetWrap.UWStatus = 'Test status';
            
        //LocationWrapper
        REST_Rating.LocationWrapper locWrap =  new REST_Rating.LocationWrapper();   
        locWrap.Id = 'Test Id';
        locWrap.Assets = new List<REST_Rating.AssetWrapper>{assetWrap};            
        locWrap.LocationIntelOrderDate = 'Test Loc';
        locWrap.Distance_To_Brush = 'Test Dist';
        locWrap.Hurricane_Probability = 'None';
        locWrap.Protection_Class = 'Test Class';
        locWrap.Convective_Storm_Value = 'Test Storm Value';
        locWrap.Crime_Score= 'Test Storm Value';
        locWrap.Storm_Surge_Score= 'Test Storm Value';
       locWrap.Straight_Wind_Probability = 'Test Storm Value';
        locWrap.Wild_Fire_Risk  = 'Test Storm Value';         
        locWrap.Hail_Probability  = 'Test Storm Value';  
       locWrap.Flood_Score = 'Test Storm Value';
        locWrap.Flood_Risk_Score= 'Test Storm Value';
        locWrap.EarthquakeMMI     = 'Test Storm Value';
       locWrap.Earthquake_Risk_Score  = 'Test Storm Value';        
        locWrap.Distance_To_Shore = 'Test Storm Value';
        
        //AccountWrapper
        REST_Rating.AccountWrapper accWrap =  new REST_Rating.AccountWrapper();
		accWrap.Id = 'Test ID';                         
        accWrap.Tax_Code = 'Test';                
        accWrap.Tax_Code_Ordered_Date= 'Test';     
        accWrap.Customer_Intel_Ordered_Date= 'Test';   
        accWrap.NAICS_Industry = 'Test';               
        accWrap.Credit_Score   = 'Test';        
        accWrap.Year_Started  = 'Test';               
        accWrap.SIC_Industry= 'Test';
        
        
        //CoverageLineItemWrapper
        REST_Rating.CoverageLineItemWrapper covLineWrap = new REST_Rating.CoverageLineItemWrapper(); 
        covLineWrap.id = 'Test ID';
        covLineWrap.LineItemType = 'Test';
        covLineWrap.DataValueForCoverage  = 'Test'; 
        covLineWrap.DataValueCode       = 'Test';  
        covLineWrap.DataValueAppliesToCode    = 'Test';
        covLineWrap.Option_Value_Default   = 'Test';  
        covLineWrap.Option_Type  = 'Test';  
        covLineWrap.Min_amt   = 'Test';
        covLineWrap.Max_amt   = 'Test'; 
        covLineWrap.Increment_Step  = 'Test';   
        covLineWrap.Option_Picklist = new List<String>{'one','two'};
        covLineWrap.IsIncluded    = 'Test'; 
        covLineWrap.SubCoverageName   = 'Test';
        covLineWrap.Coverage_Premium = 'Test'; 
        covLineWrap.Override_Premium    = 'Test';
        covLineWrap.nonProratedCoveragePremium  = 'Test';
        
        //OverallUWDescription
        REST_Rating.OverallUWDescription owDescpWrap = new REST_Rating.OverallUWDescription();
        owDescpWrap.reason_code = 'Test Reason';
        owDescpWrap.message_text = 'Message';
        
        REST_Rating.RateQuoteResult rateWrap = new REST_Rating.RateQuoteResult();
        		rateWrap.Surcharge = 'Test';                             
        rateWrap.overallUWCodes= new List<String>{'a','b'};                       
            rateWrap.overallUWDescriptions = new List<REST_Rating.OverallUWDescription>{owDescpWrap};     
         rateWrap.QuotePremium= 'Test';                            
         rateWrap.overallUWStatus= 'Test';                               
         rateWrap.Status= 'Test';                                        
         rateWrap.commissionAmount= 'Test';                              
         rateWrap.AcceptedTerrorism_Premium= 'Test';                     
         rateWrap.RejectedTerrorism_Premium= 'Test';                     
         rateWrap.SelectedTerrorism_Premium= 'Test';                     
         rateWrap.SFP_State_Indicator= 'Test';                           
         rateWrap.CoveragePremium= 'Test';                               
         rateWrap.TIV= 'Test';                                            
         rateWrap.ExpirationDate= 'Test';                                 
         rateWrap.EffectiveDate= 'Test';                                  
        
   
         rateWrap.nonCAT_Premium= 'Test';                                
         rateWrap.caT_Premium= 'Test';                                   


         rateWrap.nonProratedQuotePremium= 'Test';                       
         rateWrap.nonProratedTotalPremium= 'Test';                        
         rateWrap.NonProratedCoveragePremium= 'Test';                         
         rateWrap.NonProratedTerrorPremium= 'Test';                         
         rateWrap.nonProratedTax= 'Test';                        
         rateWrap.NonProratedCommission= 'Test';                                  
  

         rateWrap.Sage_Quantile= 'Test';                                                 
         rateWrap.Sage_Score_Rate= 'Test';                                               
    


         rateWrap.Master_Set_ID= 'Test';                                 
         rateWrap.Quote_Type= 'Test';                                    
         rateWrap.TechnicalPremium= 'Test';                              
         rateWrap.Taxes= 'Test';                                         
         rateWrap.Fees= 'Test';                                         

        rateWrap.Accounts = new List<REST_Rating.AccountWrapper>{accWrap};                       
        rateWrap.Locations =new List<REST_Rating.LocationWrapper>{locWrap};                      
        rateWrap.CoverageLineItems = new List<REST_Rating.CoverageLineItemWrapper>{covLineWrap};     
 
        rateWrap.BindPlusCoverageLineItems  =bindCovWrap;
        
         rateWrap.bindplusQuoteId= 'Test';                                
         rateWrap.accumulationLoadPercentage = 'Test';                    
         rateWrap.bindplusRatingStatus      = 'Test';                     
         rateWrap.bindplusRatingErrors = 'Test';                          
         rateWrap.bindPlusAOPStatus   = 'Test';                           
         rateWrap.bindPlusAOPPremium  = 'Test';          
     
        System.assert(rateWrap!=null);
        Test.stopTest();
    }
   
}