/*************************************************
* Class Name: REST_Rating 
* Author: 
* Date: 
* Requirement/Project Name: Innovisk
* Requirement/Project Description: This class is going to call the microservice with payload to do the rating.
** Revision: Binh Dang /  18 April 2019 / Fix: there's no log when got Exception 
** Revision: Binh Dang /  23 May 2019 / add Sage_Quantile__c, Sage_Score_Rate__c to the response
* *Revision: Hai Bui /  15 Jan 2020 / add bind plus information
*************************************************/
public class REST_Rating {
    public static Quote getRatedQuote(Quote updatedQuote) {
//         system.debug('updatedQuote'+updatedQuote);
//         API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration('Rate_Quote');
//         if(apiSetting == null) return updatedQuote;

//         HttpRequest req = new HttpRequest();
//         HttpResponse res = new HttpResponse();
//         try {
//             req = getHttpRequest(apiSetting, updatedQuote);
//             system.debug('updatedQuote@@@-->'+updatedQuote);
//             SYstem.debug('---req--->'+req);
//             Http h = new Http();
//             res = h.send(req);

//             system.debug('response @@@' +res);
//             // If status code is 200 --> parse the response
//             // If status code is different 200 or exception found 
//             // --> update quote status to 'System Error' and fillup Declined_Reason__c
//             if (res.getStatusCode() == 200) {
//                 updatedQuote.Status = 'Rated';
//                 updatedQuote.Declined_Reason__c = null;
//                 //Added by Siva on 07/22/2019
//                 updatedQuote.Zipcode_Accumulation__c = ApiUtil.postalcodeAccumTIV;
//                 updatedQuote.County_Accumulation__c = ApiUtil.CountyAccumTIV;
//                 updatedQuote.State_Accumulation__c = ApiUtil.StateAccumTIV;
//                 updatedQuote.Accumulation_Date_Time__c = System.Now();
//                 RateQuoteResult rqResult = (RateQuoteResult) JSON.deserialize(res.getBody().replace('__c', ''), RateQuoteResult.class);
             
//                 if (rqResult != null) {
//                     system.debug('rqresult obj>>>' + rqResult);
//                     system.debug('rqResult status >>>>' + rqResult.overallUWStatus + rqResult.Status);
//                     // Update quote
//                     updatedQuote.Tax = String.isNotBlank(rqResult.Surcharge) ? CommonUtil.convertStringToDecimal(rqResult.Surcharge) : updatedQuote.Tax;
//                     updatedQuote.Overall_UW_Codes__c = (rqResult.overallUWCodes != null) ? String.join(rqResult.overallUWCodes, ',') : updatedQuote.Overall_UW_Codes__c;
//                     updatedQuote.QuotePremium__c = String.isNotBlank(rqResult.QuotePremium) ? CommonUtil.convertStringToDecimal(rqResult.QuotePremium) : updatedQuote.QuotePremium__c;
//                     updatedQuote.Rating_Status__c = String.isNotBlank(rqResult.overallUWStatus) ? rqResult.overallUWStatus : rqResult.Status;
//                     updatedQuote.Commission__c = String.isNotBlank(rqResult.commissionAmount) ? CommonUtil.convertStringToDecimal(rqResult.commissionAmount) : updatedQuote.Commission__c;
//                     updatedQuote.Accept_Terror_Premium__c = String.isNotBlank(rqResult.AcceptedTerrorism_Premium) ? CommonUtil.convertStringToDecimal(rqResult.AcceptedTerrorism_Premium) : updatedQuote.Accept_Terror_Premium__c;
                  
//                     system.debug('rating status is'+ updatedQuote.Rating_Status__c);
//                  //   updatedQuote.TerrorismPremium__c = String.isNotBlank(rqResult.AcceptedTerrorism_Premium) ? CommonUtil.convertStringToDecimal(rqResult.AcceptedTerrorism_Premium) : updatedQuote.Accept_Terror_Premium__c;
                  
//                     updatedQuote.RejectTerrorPremium__c = String.isNotBlank(rqResult.RejectedTerrorism_Premium) ? CommonUtil.convertStringToDecimal(rqResult.RejectedTerrorism_Premium) : updatedQuote.RejectTerrorPremium__c;
//                     updatedQuote.SelectedTerrorPremium__c = String.isNotBlank(rqResult.SelectedTerrorism_Premium) ? CommonUtil.convertStringToDecimal(rqResult.SelectedTerrorism_Premium) : updatedQuote.SelectedTerrorPremium__c;
//                     updatedQuote.SFP_State__c = String.isNotBlank(rqResult.SFP_State_Indicator) ? rqResult.SFP_State_Indicator : updatedQuote.SFP_State__c;
//                     updatedQuote.CoveragePremium__c = String.isNotBlank(rqResult.CoveragePremium) ? CommonUtil.convertStringToDecimal(rqResult.CoveragePremium) : updatedQuote.CoveragePremium__c;
//                     if(String.isNotBlank(rqResult.ExpirationDate)) //long ly - 08-28-2019 - Add exp date  updatedQuote.Opportunity.Product__r.Name == 'Surety'
//                         updatedQuote.ExpirationDate = Date.valueOf(rqResult.ExpirationDate);
//                     if(String.isNotBlank(rqResult.nonCAT_Premium ))                         
//                         updatedQuote.Non_Cat_Premium__c = CommonUtil.convertStringToDecimal(rqResult.nonCAT_Premium );                    
//                     if(String.isNotBlank(rqResult.caT_Premium))                         
//                         updatedQuote.Cat_Premium__c = CommonUtil.convertStringToDecimal(rqResult.caT_Premium);
                    
//                     // Quang Pham 01-20-2020 Add bindplusQuoteId, accumulationLoadPercentage Start
//                     if(String.isNotBlank(rqResult.bindplusQuoteId)) {
//                         updatedQuote.Hiscoxs_Quote_ID__c = rqResult.bindplusQuoteId;
//                     }
//                     if(String.isNotBlank(rqResult.accumulationLoadPercentage)) {
//                         updatedQuote.Accumulation__c = CommonUtil.convertStringToDecimal(rqResult.accumulationLoadPercentage);
//                     }
//                     if(String.isNotBlank(rqResult.bindplusRatingStatus)) {
//                         updatedQuote.Bind_Plus_Rating_Status__c = rqResult.bindplusRatingStatus;
//                     }

//                     if(String.isNotBlank(rqResult.bindplusRatingErrors)) {
//                         updatedQuote.Bind_Plus_Rating_Errors__c = rqResult.bindplusRatingErrors;
//                     }
//                     if(String.isNotBlank(rqResult.bindPlusAOPStatus)) {
//                         updatedQuote.BindPlusAOPStatus__c = rqResult.bindPlusAOPStatus; // Added by Hai Bui 10 Feb 2020 Ticket 10818
//                     }
//                     //BindPlus_AOP_Premium__c
//                     if(String.isNotBlank(rqResult.bindPlusAOPPremium)) {
//                         updatedQuote.BindPlus_AOP_Premium__c = CommonUtil.convertStringToDecimal(rqResult.bindPlusAOPPremium); // Added by Hai Bui 25 Feb 2020 Ticket 11272
//                     }
//                     // start modified by Quan Tran on 14-05-2019                                          
//                     if(String.isNotBlank(rqResult.nonProratedQuotePremium)) 
//                         updatedQuote.Non_Prorated_Quote_Premium__c = CommonUtil.convertStringToDecimal(rqResult.nonProratedQuotePremium);
//                     if(String.isNotBlank(rqResult.NonProratedCoveragePremium)) 
//                         updatedQuote.Non_Prorated_Coverage_Premium__c = CommonUtil.convertStringToDecimal(rqResult.NonProratedCoveragePremium);
//                     if(String.isNotBlank(rqResult.NonProratedTerrorPremium)) 
//                         updatedQuote.Non_Prorated_Terror_Premium__c = CommonUtil.convertStringToDecimal(rqResult.NonProratedTerrorPremium);
//                     if(String.isNotBlank(rqResult.NonProratedCommission)) 
//                         updatedQuote.Non_Prorated_Commission__c = CommonUtil.convertStringToDecimal(rqResult.NonProratedCommission);
    
//                     if(String.isNotBlank(rqResult.nonProratedTotalPremium)) 
//                         updatedQuote.Non_prorated_Total_Premium__c = CommonUtil.convertStringToDecimal(rqResult.nonProratedTotalPremium);
//                     // end modified by Quan Tran on 14-05-2019

//                     // Added Non_Prorated_Tax__c
//                     if(String.isNotBlank(rqResult.nonProratedTax))
//                         updatedQuote.Non_Prorated_Tax__c = CommonUtil.convertStringToDecimal(rqResult.nonProratedTax);  

//                     // start modified by Quan Tran on 23-05-2019                                                              
//                     if(String.isNotBlank(rqResult.Sage_Quantile))   
//                         updatedQuote.Sage_Quantile__c = CommonUtil.convertStringToDecimal(rqResult.Sage_Quantile);                                                                                      
      
//                     if(String.isNotBlank(rqResult.Sage_Score_Rate))     
//                         updatedQuote.Sage_Score_Rate__c = CommonUtil.convertStringToDecimal(rqResult.Sage_Score_Rate);                                                                                                                                
                                                            
//                     // end modified by Quan Tran on 23-05-2019                

//                     // Quang Pham 04-04 Add MasterSetId, Quote Type Start
//                     if(String.isNotBlank(rqResult.Master_Set_ID)) updatedQuote.Master_Set_ID__c = rqResult.Master_Set_ID;
//                     if(String.isNotBlank(rqResult.Quote_Type)) updatedQuote.Quote_Type__c = rqResult.Quote_Type;
//                     // Quang Pham 04-04 Add MasterSetId, Quote Type End

//                     // 06-25-19 Quang Pham TIV values in Rating Add Start
//                     if(String.isNotBlank(rqResult.TIV)) updatedQuote.TIV__c = Decimal.valueOf(rqResult.TIV);
//                     // 06-25-19 Quang Pham TIV values in Rating Add End

//                     // 10-25-19 Hoang Bui add TechnicalPremium in Rating
//                     if(String.isNotBlank(rqResult.TechnicalPremium)){
//                         updatedQuote.Technical_Premium__c = Decimal.valueOf(rqResult.TechnicalPremium);
//                     }
                    
//                     if(String.isNotBlank(rqResult.Taxes)){
//                         updatedQuote.Tax = Decimal.valueOf(rqResult.Taxes);
//                     }
                    
//                     if(String.isNotBlank(rqResult.Fees)){
//                         updatedQuote.Fees__c = Decimal.valueOf(rqResult.Fees);
//                     }
					
//                     if (rqResult.overallUWDescriptions != null && !rqResult.overallUWDescriptions.isEmpty()) {
//                         String uwReason = '';
//                         for (OverallUWDescription description : rqResult.overallUWDescriptions ) {
//                             uwReason += description.message_text + '\n';
//                         }
//                         updatedQuote.UW_Reason__c = uwReason;
//                     }

                           
//                     String productName = updatedQuote.Opportunity.Product__r.Name; // added by ramola
//                     // Update coverage line items returned by response
//                     if (rqResult.CoverageLineItems != null && !rqResult.CoverageLineItems.isEmpty()) {
//                         Set<String> uniqueIds = new Set<String>();
//                         List<CoveragesLineItem__c> clisToUpsert = new List<CoveragesLineItem__c>();
//                         for (CoverageLineItemWrapper cliWrap : rqResult.CoverageLineItems) {
//                             if (String.isBlank(cliWrap.id)) continue;
// system.debug('rqResult.CoverageLineItems'+rqResult.CoverageLineItems);
//                             system.debug('cliWrap'+cliWrap);
                            
//                             // Don't treat duplicate Id
//                             if (!uniqueIds.isEmpty() && uniqueIds.contains(cliWrap.id)) continue;
//                             else uniqueIds.add(cliWrap.id);
               
//                             CoveragesLineItem__c cli = new CoveragesLineItem__c(Id = cliWrap.id);
//                             cli.Option_Value_Default__c = cliWrap.Option_Value_Default;
//                             system.debug('cliWrap.id-->'+cliWrap.id);
//                             system.debug('cli.IsIncluded__c-->1'+cli.IsIncluded__c);
//                             system.debug('cliWrap.IsIncluded-->1'+cliWrap.IsIncluded);
//                             //Boolean chck = (cliWrap.IsIncluded == null);
//                             //system.debug('chck-->1'+chck);
//                             //Boolean chck2 = Boolean.valueOf(cliWrap.IsIncluded);
//                             //system.debug('chck-->2'+chck2);
//                             cli.IsIncluded__c = (cliWrap.IsIncluded == null) ? false : Boolean.valueOf(cliWrap.IsIncluded);
//                             system.debug('cli.IsIncluded__c-->2'+cli.IsIncluded__c);
//                             if(cliWrap.IsIncluded == 'Yes')  cli.IsIncluded__c = Boolean.valueOf('true');
//                             system.debug('cli.IsIncluded__c-->3'+cli.IsIncluded__c);
//                             cli.Coverage_Premium__c = cliWrap.Coverage_Premium;
//                             //Condition removed by Siva on 5/4/2020 and changed the expression to avoid overriting null values
//                            // if (productName == Label.PN_MTC) {//for MTC Prodcts only - added by ramola
//                             if(String.isNotBlank(cliWrap.Override_Premium))  cli.Override_Premium__c = Decimal.valueOf(cliWrap.Override_Premium) ; //: cli.Override_Premium__c; //added by hai bui 28 April 2020 ticket 16185
//                            // }                            
//                             cli.Option_Type__c = (cliWrap.Option_Type == null) ? 'Fixed value' : cliWrap.Option_Type;
                            
//                             if (cliWrap.Option_Type == 'Range') {
//                                 cli.Min_amt__c = CommonUtil.convertStringToDecimal(cliWrap.Min_amt);
//                                 cli.Max_amt__c = CommonUtil.convertStringToDecimal(cliWrap.Max_amt);
//                                 cli.Increment_Step__c = CommonUtil.convertStringToDecimal(cliWrap.Increment_Step);
                            
//                             } else if (cliWrap.Option_Type == 'Picklist') {
//                                 cli.Option_Picklist__c = (cliWrap.Option_Picklist == null) ? null : String.join(cliWrap.Option_Picklist, ',');
//                             }

//                             // start modified by Quan Tran on 14-05-2019                                          
//                             if(String.isNotBlank(cliWrap.nonProratedCoveragePremium)){
//                                    cli.Non_Prorated_Coverage_Premium__c = cliWrap.nonProratedCoveragePremium;
//                             }  
//                             // end modified by Quan Tran on 14-05-2019                                          

//                             clisToUpsert.add(cli);
//                         }                                                

//                         if (!clisToUpsert.isEmpty()) upsert clisToUpsert;
//                     }

//                     // Update account returned by response
//                     if (rqResult.Accounts != null && !rqResult.Accounts.isEmpty()) {
//                         Map<String, AccountWrapper> uniqueAccountIds = new Map<String, AccountWrapper>();
//                         Set<String> naicsIndusNames = new Set<String>();

//                         for (AccountWrapper accWrap : rqResult.Accounts) {
//                             if (String.isBlank(accWrap.Id)) continue;
//                             if(!uniqueAccountIds.containsKey(accWrap.Id)) uniqueAccountIds.put(accWrap.Id, accWrap);
//                             if(String.isNotBlank(accWrap.Customer_Intel_Ordered_Date)
//                                 && String.isNotBlank(accWrap.NAICS_Industry)) {
//                                 naicsIndusNames.add(accWrap.NAICS_Industry);
//                             }
//                         }

//                         Map<String, String> naicsIndusMap = new Map<String, String>();
//                         for(NAICS_Industry__c ni : [Select Name, Id From NAICS_Industry__c Where Name IN: naicsIndusNames]) {
//                             naicsIndusMap.put(ni.Name, ni.Id);
//                         }

//                         //for to update sObject or not
//                         List<Account> sAcc = [select Id, Sic, Year_Started__c, NAICS_Industry_Code__c from Account where Id IN: uniqueAccountIds.keySet()];
//                         List<Account> accUpdates = new List<Account>();
//                         for(Account acc : sAcc) {
//                             if(!uniqueAccountIds.containsKey(acc.Id)) continue;
//                             AccountWrapper accWrap = uniqueAccountIds.get(acc.Id);

//                             if (String.isNotBlank(accWrap.Tax_Code_Ordered_Date)) {
//                                 acc.Tax_Code_Ordered_Date__c = CommonUtil.parseDatetimeFromString(accWrap.Tax_Code_Ordered_Date);
//                                 acc.Tax_Code__c = accWrap.Tax_Code;
//                             }

//                             if(String.isNotBlank(accWrap.Customer_Intel_Ordered_Date)) {
//                                 acc.Customer_Intel_Ordered_Date__c = CommonUtil.parseDatetimeFromString(accWrap.Customer_Intel_Ordered_Date);
//                                 //Long ly - 03/10/2020 - Change data type to String to apply the encryption
//                                 //acc.Credit_Score__c = CommonUtil.convertStringToInteger(accWrap.Credit_Score);
//                                 acc.Credit_Score__c = accWrap.Credit_Score;
//                                 //End

//                                 if (acc.NAICS_Industry_Code__c == null && naicsIndusMap.containsKey(accWrap.NAICS_Industry)) 
//                                     acc.NAICS_Industry_Code__c = naicsIndusMap.get(accWrap.NAICS_Industry);
                               
//                                 if(acc.Sic == null)  acc.Sic = accWrap.SIC_Industry;
//                                 if (String.IsBlank(acc.Year_Started__c)) acc.Year_Started__c = accWrap.Year_Started;
//                             }
//                             accUpdates.add(acc);
//                         }

//                         if (!accUpdates.isEmpty()) update accUpdates;
//                     }
//                     //Update BindPlus information
//                     List<CoveragesLineItem__c> listCovUpdate = updatedQuote.Product_Name__c.contains('Sage') ? getUpdateCoverageLineItems(rqResult): new List<CoveragesLineItem__c>(); //Added by hai
//                     // Update location returned by response
//                     if (rqResult.Locations != null && !rqResult.Locations.isEmpty()) {
//                         Set<String> uniqueLocationIds = new Set<String>();
//                         List<Location__c> locationsToUpsert = new List<Location__c>();
//                         List<Equipment__c> equipmentsToUpsert = new List<Equipment__c>();
//                         for (LocationWrapper locWrap : rqResult.Locations) {
//                             if (String.isBlank(locWrap.Id)) continue;
//                             // Don't treat duplicate Id
//                             if (!uniqueLocationIds.isEmpty() && uniqueLocationIds.contains(locWrap.Id)) continue;
//                             else uniqueLocationIds.add(locWrap.Id);
      
//                             Location__c loc = new Location__c(Id = locWrap.Id);
//                             if(String.isNotBlank(locWrap.LocationIntelOrderDate)) {
//                                 loc.Location_Intel_Order__c = CommonUtil.parseDatetimeFromString(locWrap.LocationIntelOrderDate);
//                                 loc.Distance_To_Brush__c = locWrap.Distance_To_Brush;
//                                 loc.Distance_To_Shore__c = locWrap.Distance_To_Shore;
//                                 loc.Earthquake_Risk_Score__c = locWrap.Earthquake_Risk_Score;
//                                 loc.EarthquakeMMI__c = locWrap.EarthquakeMMI;
//                                 loc.Flood_Risk_Score__c = locWrap.Flood_Risk_Score;
//                                 loc.Flood_Score__c = locWrap.Flood_Score;
//                                 loc.Hail_Probability__c = locWrap.Hail_Probability;
//                                 loc.Hurricane_Probability__c = locWrap.Hurricane_Probability;
//                                 loc.Protection_Class__c = locWrap.Protection_Class;
//                                 loc.Convective_Storm_Value__c = locWrap.Convective_Storm_Value;
//                                 loc.Crime_Score__c = locWrap.Crime_Score;
//                                 loc.Storm_Surge_Score__c = locWrap.Storm_Surge_Score;
//                                 loc.Straight_Wind_Probability__c = locWrap.Straight_Wind_Probability;
//                                 loc.Wild_Fire_Risk__c = locWrap.Wild_Fire_Risk;
//                                 locationsToUpsert.add(loc);
//                             }
                           
//                             // Update equipment returned by response
//                             if (locWrap.Assets != null && !locWrap.Assets.isEmpty()) {
//                                 Set<String> uniqueEquipmentIds = new Set<String>();
//                                 for (AssetWrapper assWrap : locWrap.Assets) {
//                                     if (String.isBlank(assWrap.Equipment_Id)) continue;

//                                     // Don't treat duplicate Id
//                                     if (!uniqueEquipmentIds.isEmpty() && uniqueEquipmentIds.contains(assWrap.Equipment_Id)) {
//                                         continue;
//                                     }else uniqueEquipmentIds.add(assWrap.Equipment_Id);
           
//                                     Equipment__c equip = new Equipment__c(Id = assWrap.Equipment_Id);
//                                     if(String.isNotBlank(assWrap.Equipment_Intel_Ordered_Date)) {
//                                         equip.Equipment_Intel_Ordered_Date__c = CommonUtil.parseDatetimeFromString(assWrap.Equipment_Intel_Ordered_Date);
//                                         equip.Equipment_Watch_Type__c = assWrap.Equipment_Watch_Type;
//                                         equip.Equipment_Watch_Sub_Type__c = assWrap.Equipment_Watch_Sub_Type;
//                                         equip.Fair_Market_Value__c = CommonUtil.convertStringToInteger(assWrap.Fair_Market_Value);
//                                     }
//                                     equip.Type__c = assWrap.Type;
//                                     equipmentsToUpsert.add(equip);
//                                 }
//                             }
//                         }

//                         if (!locationsToUpsert.isEmpty()) upsert locationsToUpsert;
//                         if (!equipmentsToUpsert.isEmpty()) upsert equipmentsToUpsert;
//                         if(!listCovUpdate.isEmpty()) upsert listCovUpdate;
//                     }
//                 }

//             } else {
//                 String errMsg = '';
//                 Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
//                 if (resultMap.containsKey('error')) {
//                     Map<String, Object> errorMap = (Map<String, Object>) resultMap.get('error');
//                     errMsg = (String) errorMap.get('message');
//                 } else if (resultMap.containsKey('message')) {
//                     errMsg = (String) resultMap.get('message');
//                 }
//                 updatedQuote.Status = 'In Progress';
//                 updatedQuote.Rating_Status__c = 'System Error';
//                 updatedQuote.Declined_Reason__c = errMsg;
//             }

//             // log API Call
//             ApiUtil.logAPICall(req,res,'RatingAPI Callout','REST_Rating.getRatedQuote', apiSetting.HeaderParams__c, 'Outbound');        
//             return updatedQuote;

//         } catch (Exception ex) {
//             updatedQuote.Status = 'In Progress';
//             updatedQuote.Rating_Status__c = 'System Error';
//             updatedQuote.Declined_Reason__c = CommonUtil.getExceptionMessage(ex);
//             // log API Call
//             ApiUtil.logAPICall(req,res,'RatingAPI Callout','REST_Rating.getRatedQuote', apiSetting.HeaderParams__c, 'Outbound');            
//             return updatedQuote;
//         }
      	return updatedQuote;
    }
    /*************************************************
  * Method Name: getUpdateCoverageLineItemsUpdate
  * Author: Hai Bui
  * Date: 15 Jan 2020
  * Params: RateQuoteResult
  * Return: List<CoveragesLineItem__c>
  * Exceptions:
  * Revision:
  *************************************************/
    // private static List<CoveragesLineItem__c> getUpdateCoverageLineItems(RateQuoteResult rateQuoteResult){
    //     List<CoveragesLineItem__c> listCov = new List<CoveragesLineItem__c>();
    //     if (rateQuoteResult.BindPlusCoverageLineItems != null)
    //     {
    //         BindPlusCoverageLineItemWrapper bindPlusCovItems = rateQuoteResult.BindPlusCoverageLineItems;
    //         Map<String,String> mapCovIdOptionNumber = new  Map<String,String>();
    //         if(!bindPlusCovItems.coverageOptions.isEmpty()){
    //             for(CoverageOptionWrapper covItem : bindPlusCovItems.coverageOptions){
    //                 mapCovIdOptionNumber.put(covItem.Id,covItem.optionNumber);
    //             }
    //         }
    //         if(!bindPlusCovItems.additionalCoverageOptions.isEmpty()){
    //             for(CoverageOptionWrapper covItem : bindPlusCovItems.additionalCoverageOptions){
    //                 mapCovIdOptionNumber.put(covItem.Id,covItem.optionNumber);
    //             }
    //         }
    //         for(CoveragesLineItem__c cov : [select Id,Option_Number__c from CoveragesLineItem__c where id in :mapCovIdOptionNumber.keySet()] ){
    //             if(mapCovIdOptionNumber.containsKey(cov.Id)){
    //                 cov.Option_Number__c = CommonUtil.convertStringToInteger( mapCovIdOptionNumber.get(cov.Id));
    //                 listCov.add(cov);
    //             }
    //         }
    //     }
    //     return listCov;
    // }

    /*************************************************
    * Method Name: getHttpRequest
    * Author: 
    * Date:
    * Params: apiSetting custom metadata of Rating Quote
              updatedQuote Rating Quote
    * Return: req request call Azure Server
    * Exceptions:
    * Revision:
    *************************************************/
    // public static HttpRequest getHttpRequest(API_Configuration__mdt apiSetting, Quote updatedQuote) {
    //     system.debug('quote product' +updatedQuote.Product_Name__c);
    //     String baseUri = apiSetting.Base_Url__c + getEndPointString(apiSetting.Endpoint__c, updatedQuote.Product_Name__c); //13 Mar 2020: Binh add - new Rating Endpoint for Motor Truck Cargo Product

    //     Map<String, String> headerParamMap = new Map<String, String>();
    //     for (String headerParam : apiSetting.HeaderParams__c.split(';')) {
    //         List<String> headerKeyValue = headerParam.split(':');
    //         headerParamMap.put(headerKeyValue[0], headerKeyValue[1]);
    //     }

    //     HttpRequest req = new HttpRequest();
    //     req.setEndpoint(baseUri);
    //     req.setMethod(apiSetting.Method__c);
    //     req.setTimeout(Integer.valueOf(Label.ApiTimeOut));

    //     // 04-22-2019 Quang Pham Fields to be added to Rating call for In Force Quote Edit Start
    //     String strBody =  ApiUtil.getRatingJsonString(updatedQuote.Id);
    //     strBody = updatedQuote.Quote_Type__c == 'New Business' ? strBody + '}' : strBody + ',';
    //     if(updatedQuote.Quote_Type__c != 'New Business' && (updatedQuote.Parent_Quote__c != null
    //         && String.isNotBlank(updatedQuote.Parent_Quote__c))){
    //         strBody = strBody + ApiUtil.getBoundQuoteJson(updatedQuote.Parent_Quote__c) + '}';
    //     }        
    //     req.setBody(strBody);
    //     for (String headerParamKey : headerParamMap.keySet()) {
    //         req.setHeader(headerParamKey, headerParamMap.get(headerParamKey));
    //     }
    //     return req;
    // }

    // public static String getEndPointString(String endpoint, String productName){
    //     if(!endpoint.contains('{')) return endpoint; //That means it's not a Map
    //     Map<String, Object> objAPI_FieldsAPIMap = (Map<String, Object>)JSON.deserializeUntyped(endpoint);
    //     if(objAPI_FieldsAPIMap.containsKey(productName))
    //         return (String)objAPI_FieldsAPIMap.get(productName);
    //     else 
    //         return (String)objAPI_FieldsAPIMap.get('Default');
    // }

    public class RateQuoteResult {
        public String Surcharge                                     {get; set;}
        public List<String> overallUWCodes                          {get; set;}
        public List<OverallUWDescription> overallUWDescriptions     {get; set;}
        public String QuotePremium                                  {get; set;}
        public String overallUWStatus                               {get; set;}
        public String Status                                        {get; set;}
        public String commissionAmount                              {get; set;}
        public String AcceptedTerrorism_Premium                     {get; set;}
        public String RejectedTerrorism_Premium                     {get; set;}
        public String SelectedTerrorism_Premium                     {get; set;}
        public String SFP_State_Indicator                           {get; set;}
        public String CoveragePremium                               {get; set;}
        public String TIV                                           {get; set;} // 06-25-19 Quang Pham
        public String ExpirationDate                                {get; set;} // 08-28-19 Long Ly
        public String EffectiveDate                                 {get; set;} // 08-29-19 Quan Tran
        
        // start modified by Quan Tran on 18-07-2019    
        public String nonCAT_Premium                                {get; set;}
        public String caT_Premium                                   {get; set;}

        // start modified by Quan Tran on 14-05-2019
        public String nonProratedQuotePremium                       {get; set;}
        public String nonProratedTotalPremium                       {get; set;} 
        public String NonProratedCoveragePremium                       {get; set;}  
        public String NonProratedTerrorPremium                       {get; set;}  
        public String nonProratedTax                      {get; set;}  
        public String NonProratedCommission                                {get; set;} //Added Non_Prorated_Tax__c     
        // end modify by Quan Tran on 14-05-2019       

        // start modified by Quan Tran on 23-05-2019
        public String Sage_Quantile                                 {get; set;}                
        public String Sage_Score_Rate                               {get; set;}                
        // end modified by Quan Tran on 23-05-2019

        // Quang Pham 04-04 Add MasterSetId, Quote Type 
        public String Master_Set_ID                                 {get; set;}
        public String Quote_Type                                    {get; set;}
        public String TechnicalPremium                              {get; set;} //25-Oct-2019: Hoang Bui added
        public String Taxes                                         {get; set;} //25-Oct-2019: Siva added
        public String Fees                                          {get; set;} //25-Oct-2019: Siva added

        public List<AccountWrapper> Accounts                        {get; set;}
        public List<LocationWrapper> Locations                      {get; set;}
        public List<CoverageLineItemWrapper> CoverageLineItems      {get; set;}
      //public List<CoverageLineItemWrapper> AssetCoverageLineItems      {get; set;}
        public BindPlusCoverageLineItemWrapper BindPlusCoverageLineItems  {get; set;}
        
        public String bindplusQuoteId                                {get; set;}
        public String accumulationLoadPercentage                     {get; set;}
        public String bindplusRatingStatus                           {get; set;}
        public String bindplusRatingErrors                           {get; set;}
        public String bindPlusAOPStatus                              {get; set;} // Added by Hai Bui 10 Feb 2020 Ticket 10818
        public String bindPlusAOPPremium                             {get; set;} // Added by Hai Bui 25 Feb 2020 Ticket 11272
    }

    public class OverallUWDescription {
        public String reason_code   {get; set;}
        public String message_text  {get; set;}
    } 

    public class CoverageLineItemWrapper {
        public String id                        {get; set;}
        public String LineItemType              {get; set;}
        public String DataValueForCoverage      {get; set;}
        public String DataValueCode             {get; set;}
        public String DataValueAppliesToCode    {get; set;}
        public String Option_Value_Default      {get; set;}
        public String Option_Type               {get; set;}
        public String Min_amt                   {get; set;}
        public String Max_amt                   {get; set;}
        public String Increment_Step            {get; set;}
        public List<String> Option_Picklist     {get; set;}
        public String IsIncluded                {get; set;}    
        public String SubCoverageName           {get; set;}
        public String Coverage_Premium          {get; set;}
        public String Override_Premium          {get; set;}
        public String nonProratedCoveragePremium  {get; set;} // Modify by Quan Tran on 14-05-2019
                  
    }

    public class AccountWrapper {
        public String Id                            {get; set;}
        public String Tax_Code                      {get; set;}
        public String Tax_Code_Ordered_Date         {get; set;}
        public String Customer_Intel_Ordered_Date   {get; set;}
        public String NAICS_Industry                {get; set;}
        public String Credit_Score                  {get; set;}
        public String Year_Started                  {get; set;}
        public String SIC_Industry                  {get; set;}      
    }

    public class LocationWrapper {
        public String Id                        {get; set;}
        public String LocationIntelOrderDate    {get; set;}     
        public String Distance_To_Brush         {get; set;}     
        public String Hurricane_Probability     {get; set;}
        public String Protection_Class          {get; set;}
        public String Convective_Storm_Value    {get; set;}
        public String Crime_Score               {get; set;}
        public String Storm_Surge_Score         {get; set;}    
        public String Straight_Wind_Probability {get; set;}
        public String Wild_Fire_Risk            {get; set;}
        public String Hail_Probability          {get; set;}
        public String Flood_Score               {get; set;}
        public String Flood_Risk_Score          {get; set;}
        public String EarthquakeMMI             {get; set;}    
        public String Earthquake_Risk_Score     {get; set;}      
        public String Distance_To_Shore         {get; set;}
        public List<AssetWrapper> Assets        {get; set;}
    }

    public class AssetWrapper {
        public String Equipment_Watch_Type          {get; set;}
        public String Equipment_Watch_Sub_Type      {get; set;}
        public String Fair_Market_Value             {get; set;}     
        public String Equipment_Intel_Ordered_Date  {get; set;}
        public String Equipment_Id                  {get; set;}
        public String Type                          {get; set;}
        public String UWStatus                      {get; set;}
        public List<String> UWCodes                 {get; set;}
    }
    public class BindPlusCoverageLineItemWrapper {
        public List<CoverageOptionWrapper> coverageOptions               {get; set;}
        public List<CoverageOptionWrapper> additionalCoverageOptions     {get; set;}
        public BindPlusCoverageLineItemWrapper(){
            coverageOptions = new List<CoverageOptionWrapper>();
            additionalCoverageOptions = new List<CoverageOptionWrapper>();
        }
    }

    public class CoverageOptionWrapper {
        public String id                         {get; set;}
        public String optionNumber               {get; set;}
        public String optionName                 {get; set;}
        public String perilType                  {get; set;}
    }

}