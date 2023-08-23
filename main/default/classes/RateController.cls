/**
 * @description       : 
 * @author            : Maeran Shaikh
 * @group             : 
 * @last modified on  : 04-11-2022
 * @last modified by  : Vinayesh
**/
global with sharing class RateController {
    @AuraEnabled
    public static ResultResponse getRatingFromCallOut(String objId){        
        ResultResponse result = new ResultResponse();
        List<Quote> quotes = new List<Quote>();
        String quoteOppRecordType;
        String resp;
        try {
            quotes = [SELECT Id,OpportunityId,MGA_Commission__c, Status,Opportunity.Type, Opportunity.RecordType.Name,
                      Parent_Quote__c,Parent_Quote__r.Rate__c, Quote_Type__c, Product_Name__c,Shared_Aggregate_Limit__c, Combined_Max_Agg_Limit_of_Liability__c
                      FROM Quote 
                      WHERE Id = :objId LIMIT 1];
            if (quotes.isEmpty()) {
                result.errors.add('Quote is not existed');
                return result;
            }
            
            Quote currentQuote = quotes[0];
            quoteOppRecordType = currentQuote.Opportunity.RecordType.Name;
            
            if(currentQuote.Status != 'IN PROGRESS') {
                result.errors.add('Can not rate with this quote status');
                return result;
            } 
            
            // Call rating api            
            ResponseObject res = Invsk_Callout.getRatingRequest(currentQuote);
            System.debug('res'+res);
            
            // rating failed
            if (res.statusCode != 200) {
                if(res.errors != null){
                    result.errors.addAll(res.errors);     
                result.errors.addAll(res.errors);                
                    result.errors.addAll(res.errors);     
                result.errors.addAll(res.errors);                
                    result.errors.addAll(res.errors);     
                }
                else{
                    result.errors.add('Rating has failed. Please contact your Administrator');
                }          
                return result;
            }
            
            resp = res.body;
            
            if(quoteOppRecordType == 'Aqueous'){
                result = getRatingForAQ(resp, quotes);
            }else if(quoteOppRecordType == 'Celerity'){
                result = getRatingForCelerity(resp, quotes);
            }
        }
        catch (NullPointerException ex){   
            ErrorLogsUtilityHelper.logError(ex, 'RateController.getRatingFromCallOut', CommonUtil.getExceptionMessage(ex), '', 'AQ_Exceptions', '', String.valueOf(ex.getLineNumber()));         
            System.debug('NullException-->'+ex.getLineNumber()+' '+ex.getStackTraceString()+' '+ex.getMessage());
            result.errors.add('Failed to read the response body. Please check api log ');
        } catch (Exception ex) {
            ErrorLogsUtilityHelper.logError(ex, 'RateController.getRatingFromCallOut', CommonUtil.getExceptionMessage(ex), '', 'AQ_Exceptions', '', String.valueOf(ex.getLineNumber()));
            System.debug('Exception-->'+ex.getLineNumber()+' '+ex.getStackTraceString()+' '+ex.getMessage());
            result.errors.add(ex.getMessage());            
        }        
        return result;
    }
    
    public static ResultResponse getRatingForAQ(String resp, List<Quote> quotes){
        ResultResponse result = new ResultResponse();
        try{            
            Quote currentQuote = quotes[0];
            
            QuoteWrapper1 responseJSONString = (QuoteWrapper1)JSON.deserialize(resp,QuoteWrapper1.class);
            System.debug('responseJSONString'+responseJSONString);
            
            //For Quote
            Quote quoteResponse = responseJSONString.quote;
            
            if(quoteResponse.Quote_Type__c == 'Amendment'){
                quoteResponse.Quote_Type__c = currentQuote.Quote_Type__c;
            }
            
            if(quoteResponse != null){              
                //Add UW Code and Reasons to quote
                if(!responseJSONString.overallUWDescriptions.isEmpty()){
                    
                    List<String> UWCode = new List<String>();
                    List<String> UWReason = new List<String>();
                    
                    for(UWDescriptionsWrapper description : responseJSONString.overallUWDescriptions){
                        UWCode.add(description.uwcode);
                        UWReason.add(description.message_text);
                    }
                    quoteResponse.Overall_UW_Codes__c = String.join(UWCode, ',');
                    quoteResponse.UW_Reason__c = String.join(UWReason, '\n');
                    
                }                
                quoteResponse.Id=responseJSONString.quote.Id;

            }
            
            //Factor Summary
            List<Factor_Summary__c> factorSummaryList = new  List<Factor_Summary__c>();
            Decimal currentQuoteRateValue = 0.0;
            if(responseJSONString.quote.Factor_Summary_Items__r.size() > 0){
                factorSummaryList = responseJSONString.quote.Factor_Summary_Items__r;
                if(responseJSONString.quote.Name.contains(' PI ')){
                    Factor_Summary__c dataSum = new Factor_Summary__c();
                    dataSum.Code__c = 'MGA Commission Percent';
                    dataSum.Value__c = String.valueOf(currentQuote.MGA_Commission__c);
                    factorSummaryList.add(dataSum);
                    for(Factor_Summary__c fs :factorSummaryList){
                        String value = fs.Value__c != null ? fs.Value__c.replace(',', '') : null;
                        if(fs.Code__c == 'Rate' && string.isNotBlank(fs.Value__c)){                            
                            quoteResponse.Rate__c = Decimal.valueOf(value); 
                            currentQuoteRateValue = Decimal.valueOf(value); 
                        }
                        else if(fs.Code__c == 'Netted Down Premium MGA Commission Percent' && string.isNotBlank(fs.Value__c)){                            
                            quoteResponse.Netted_Down_Premium_MGA_Commission__c = Decimal.valueOf(value); 
                            quoteResponse.Revised_MGA_Commission__c = Decimal.valueOf(value); 
                        }
                        else if(fs.Code__c == 'Netted Down Premium Broker Commission Percent' && string.isNotBlank(fs.Value__c)){
                            quoteResponse.Netted_Down_Premium_Broker_Commission__c = Decimal.valueOf(value); 
                            quoteResponse.Revised_Broker_Commission__c = Decimal.valueOf(value); 
                        }
                        else if(fs.Code__c == 'Lloyds Risk Code' && string.isNotBlank(fs.Value__c)){
                            quoteResponse.Lloyds_Risk_Code__c = fs.Value__c; 
                        }
                        else if(fs.Code__c == 'MGA Commission Amount' && string.isNotBlank(fs.Value__c)){
                            quoteResponse.MGA_Commission_Sum__c = Decimal.valueOf(value); 
                        }
                        else if(fs.Code__c == 'Rateable Exposure' && string.isNotBlank(fs.Value__c)){
                            quoteResponse.Rateable_Exposure__c = Decimal.valueOf(value); 
                        }
                        else if(fs.Code__c == 'Netted Down Premium MGA Commission Sum' && string.isNotBlank(fs.Value__c)){
                            quoteResponse.Netted_Down_Premium_MGA_Commission_Sum__c = Decimal.valueOf(value); 
                        }
                        else if(fs.Code__c == 'Netted Down Premium Broker Commission Sum' && string.isNotBlank(fs.Value__c)){
                            quoteResponse.Netted_Down_Premium_BrokerCommission_Sum__c = Decimal.valueOf(value); 
                        }
                        else if(fs.Code__c == 'Broker Commission Amount' && string.isNotBlank(fs.Value__c)){
                            quoteResponse.Broker_Commission_Sum__c = Decimal.valueOf(value); 
                        }

                    }
                    if(currentQuote.Opportunity.Type == 'Renewal' && currentQuote.Parent_Quote__r != null){
                        Factor_Summary__c dataSum1 = new Factor_Summary__c();
                        dataSum1.Code__c = 'Rate - Previous Year';
                        dataSum1.Value__c = String.valueOf(currentQuote.Parent_Quote__r.Rate__c);
                        Factor_Summary__c dataSum2 = new Factor_Summary__c();
                        dataSum2.Code__c = 'Rate Change';
                        if(String.isNotBlank(dataSum1.Value__c) && Decimal.valueOf(dataSum1.Value__c) != 0){        //added for null pointer exception
                            dataSum2.Value__c = currentQuoteRateValue != null ? String.valueOf(((currentQuoteRateValue - Decimal.valueOf(dataSum1.Value__c))/Decimal.valueOf(dataSum1.Value__c) *100).setScale(2)) : '0';
                        }
                        else{
                            dataSum1.Value__c = '0';
                            dataSum2.Value__c = '0';
                        }
                        if(Decimal.valueOf(dataSum2.Value__c) > 0)	dataSum2.Value__c = '+'+dataSum2.Value__c;
                        factorSummaryList.add(dataSum1);
                        factorSummaryList.add(dataSum2);
                    }                                        
                    //update quoteResponse;
                } 
                //CreateFactorSummary.createNewFactorSummary(factorSummaryList,quoteResponse.Id);                
            }           
            
            //For Coverage Line Items
            Map<String,CoveragesLineItem__c> azureIdToCLIResponseMap = new Map<String,CoveragesLineItem__c>();
            Map<String,CoveragesLineItem__c> azureIdToCLIQueryMap = new Map<String,CoveragesLineItem__c>();
            List<CoveragesLineItem__c> cliToUpdateList = new List<CoveragesLineItem__c>();
            List<Coverage_Limits_Deductibles__c > cliUpdateDeductToUpdateList = new List<Coverage_Limits_Deductibles__c >();
            Set<String> cliAzureIdSet = new Set<String>();
            Set<String> cliAzureLimitIdSet = new Set<String>();
            Map<String,Coverage_Limits_Deductibles__c> LimitMap = new Map<String,Coverage_Limits_Deductibles__c>();
            List<String> optList = new List<String>();
            
            for(CoveragesLineItem__c cliRecord: responseJSONString.quote.Coverages_Line_Items__r){                       
                cliAzureIdSet.add(cliRecord.Azure_ID__c);
                azureIdToCLIResponseMap.put(cliRecord.Azure_ID__c, cliRecord);                
            }
            
            for(CoveragesLineItem__c cliQuery: [SELECT Id,Azure_ID__c, Quote__c, Coverage__c, Option_Type__c, CoverageLineItemType__c,
                                                Limits_Deductibles__c, Option_Value_Default__c, Option_Picklist__c,
                                                Increment_Step__c, Max_amt__c, Min_amt__c,Limits_Deductibles__r.LmtDedCode__c
                                                FROM CoveragesLineItem__c WHERE Azure_ID__c IN:cliAzureIdSet]){
                                                    azureIdToCLIQueryMap.put(cliQuery.Azure_ID__c,cliQuery);                                                    
                                                }            
            
            for(String cliAzureId: azureIdToCLIResponseMap.keySet()){
                if(azureIdToCLIQueryMap.get(cliAzureId) != null){
                    CoveragesLineItem__c cliUpd = azureIdToCLIQueryMap.get(cliAzureId);
                    CoveragesLineItem__c cliResponse = azureIdToCLIResponseMap.get(cliAzureId);
                    
                    if(String.isNotBlank(cliResponse.Option_Type__c)) cliUpd.Option_Type__c = cliResponse.Option_Type__c;
                    system.debug('before cliResponse.Option_Value_Default__c'+cliResponse.Option_Value_Default__c);
                    if(String.isNotBlank(cliResponse.Option_Value_Default__c)) cliUpd.Option_Value_Default__c = cliResponse.Option_Value_Default__c;
                     system.debug('aftercliResponse.Option_Value_Default__c'+cliResponse.Option_Value_Default__c);
                    if(String.isNotBlank(cliResponse.Option_Picklist__c)) 
                        cliUpd.Option_Picklist__c = cliResponse.Option_Picklist__c;
                    if(cliResponse.Increment_Step__c != NULL) cliUpd.Increment_Step__c = cliResponse.Increment_Step__c;
                    if(cliResponse.Min_amt__c != NULL) cliUpd.Min_amt__c = cliResponse.Min_amt__c;
                    if(cliResponse.Max_amt__c != NULL) cliUpd.Max_amt__c = cliResponse.Max_amt__c;
                    if(cliResponse.Technical_Premium__c != NULL) cliUpd.Technical_Premium__c = cliResponse.Technical_Premium__c; // Added by Maeran for US:52760
                    if(cliResponse.Coverage_Premium__c != NULL) cliUpd.Coverage_Premium__c = cliResponse.Coverage_Premium__c;
                    if(cliResponse.Override_Premium__c != NULL) cliUpd.Override_Premium__c = cliResponse.Override_Premium__c;
                    if(cliResponse.Non_Prorated_Coverage_Premium__c != NULL) cliUpd.Non_Prorated_Coverage_Premium__c = cliResponse.Non_Prorated_Coverage_Premium__c;
                    if(cliResponse.IsIncluded__c != NULL) cliUpd.IsIncluded__c = cliResponse.IsIncluded__c;
                    
                    cliToUpdateList.add(cliUpd);
                }                
            }
            
            System.debug('cliToUpdateList-before->'+cliToUpdateList);            
            if(!cliToUpdateList.isEmpty()){
                update cliToUpdateList;
            }
            System.debug('cliToUpdateList-after->'+cliToUpdateList);   
            
            
            // For Quote Options
            Set<String> setOfQOAzureId = new Set<String>();
            Map<String,Quote_Option__c> mapOfAzureIdToQOResponse = new Map<String,Quote_Option__c>();
            Map<String,Quote_Option__c> mapOfAzureIdToQOUpdate = new Map<String,Quote_Option__c>();
            List<Quote_Option__c> lstQuoteOptionToUpsert = new List<Quote_Option__c>();
            Map<String,Id> quoteOptionIdtoAzureIdMap = new Map<String,Id>();
            Map<String, List<Factor_Summary__c>> mapOfOptionIdVsListOfFactorSummary = new Map<String, List<Factor_Summary__c>>();
            String totalTechnicalAdj;

            if(responseJSONString.quote.Quote_Options__r.size() > 0){
                Integer intCount = 1;
                for(Quote_Option__c objQuoteOption: responseJSONString.quote.Quote_Options__r){
                    if(objQuoteOption.Azure_ID__c != null){
                        setOfQOAzureId.add(objQuoteOption.Azure_ID__c);
                        mapOfAzureIdToQOResponse.put(objQuoteOption.Azure_ID__c, objQuoteOption);
                    }
                    else{
                        mapOfAzureIdToQOResponse.put(String.valueOf(intCount), objQuoteOption);
                        intCount += 1;
                    }
                }
                
                for(Quote_Option__c objQORecord: [SELECT Id, Quote__c, Azure_ID__c, Actual_Premium_Annual__c, Actual_Premium_Final__c, 
                                                Book_Premium__c, Broker_Netted_Down_Premium_Annual__c, 
                                                Broker_Netted_Down_Premium_Final__c, Fee_Annual__c, Fee_Final__c, 
                                                Final_Discretion__c, Limit__c, Minimum_Premium__c, Price_Adequacy__c, 
                                                Technical_Premium__c, Technical_Premium_Discretion__c, 
                                                Selected__c, Bound__c, Option_Type__c, Final_Technical_Premium__c,
                                                Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c, Override_Fee_Percent__c,
                                                Technical_Fee__c,IPT__c,Total_Cost_To_Client__c, Actual_Premium__c,
                                                Broker_Netted_Down_Premium__c, Fee__c, IPT_on_Broker_Netted_Down_Premium__c FROM Quote_Option__c WHERE Azure_ID__c IN:setOfQOAzureId]){
                    mapOfAzureIdToQOUpdate.put(objQORecord.Azure_ID__c, objQORecord);
                }
                
                for(String azureIdOfQOResponse: mapOfAzureIdToQOResponse.keySet()){
                    Quote_Option__c objQOToUpsert = new Quote_Option__c();
                    if(!mapOfAzureIdToQOUpdate.isEmpty() && mapOfAzureIdToQOUpdate.containsKey(azureIdOfQOResponse) && mapOfAzureIdToQOUpdate.get(azureIdOfQOResponse) != null){
                        objQOToUpsert = mapOfAzureIdToQOUpdate.get(azureIdOfQOResponse);
                    }
                    Quote_Option__c objQOResponse = mapOfAzureIdToQOResponse.get(azureIdOfQOResponse);
                    
                    objQOToUpsert.Actual_Premium_Annual__c = objQOResponse.Actual_Premium_Annual__c;
                    objQOToUpsert.Actual_Premium_Final__c = objQOResponse.Actual_Premium__c;
                    objQOToUpsert.Actual_Premium__c = objQOResponse.Actual_Premium__c;
                    objQOToUpsert.Book_Premium__c = objQOResponse.Book_Premium__c;
                    objQOToUpsert.Broker_Netted_Down_Premium_Annual__c = objQOResponse.Broker_Netted_Down_Premium_Annual__c;
                    objQOToUpsert.Broker_Netted_Down_Premium_Final__c = objQOResponse.Broker_Netted_Down_Premium__c;
                    objQOToUpsert.Broker_Netted_Down_Premium__c = objQOResponse.Broker_Netted_Down_Premium__c;
                    objQOToUpsert.Fee_Annual__c = objQOResponse.Fee_Annual__c;
                    objQOToUpsert.Fee_Final__c = objQOResponse.Fee__c;
                    objQOToUpsert.Fee__c = objQOResponse.Fee__c;
                    objQOToUpsert.Final_Discretion__c = objQOResponse.Final_Discretion__c;
                    objQOToUpsert.Limit__c = objQOResponse.Limit__c;
                    objQOToUpsert.Minimum_Premium__c = objQOResponse.Minimum_Premium__c;
                    objQOToUpsert.Price_Adequacy__c = objQOResponse.Price_Adequacy__c;
                    objQOToUpsert.Technical_Premium__c = objQOResponse.Technical_Premium__c;
                    objQOToUpsert.Technical_Premium_Discretion__c = objQOResponse.Technical_Premium_Discretion__c;
                    objQOToUpsert.Option_Type__c = objQOResponse.Option_Type__c;
                    objQOToUpsert.Final_Technical_Premium__c = objQOResponse.Final_Technical_Premium__c;
                    objQOToUpsert.Override_Actual_Premium__c = objQOResponse.Override_Actual_Premium__c;
                    objQOToUpsert.Override_BNDP__c = objQOResponse.Override_BNDP__c;
                    objQOToUpsert.Technical_Fee__c = objQOResponse.Technical_Fee__c;
                    objQOToUpsert.IPT__c = objQOResponse.IPT_on_Broker_Netted_Down_Premium__c;
                    objQOToUpsert.IPT_on_Broker_Netted_Down_Premium__c = objQOResponse.IPT_on_Broker_Netted_Down_Premium__c;
                    objQOToUpsert.Total_Cost_To_Client__c = objQOResponse.Total_Cost_To_client__c;
                    objQOToUpsert.NonProRated_Actual_Premium__c = objQOResponse.NonProRated_Actual_Premium__c;
                    objQOToUpsert.NonProRated_BNDP__c = objQOResponse.NonProRated_BNDP__c;
                    objQOToUpsert.NDPB_Commission_Percent__c = objQOResponse.NDPB_Commission_Percent__c;
                    
                    //lstQuoteOptionToUpsert.add(objQOToUpsert);

                    Decimal currentQuoteRateValueQC = 0.0;
                    if(objQOResponse.Factor_Summary_Items__r.size() > 0){
                        List<Factor_Summary__c> factorSummaryListQC = new  List<Factor_Summary__c>();
                        factorSummaryListQC = objQOResponse.Factor_Summary_Items__r;
                        for(Factor_Summary__c fs :factorSummaryListQC){
                            if(fs.Code__c == 'Rate' && string.isNotBlank(fs.Value__c)){   
                                currentQuoteRateValueQC = Decimal.valueOf(fs.Value__c); 
                                objQOToUpsert.Rate__c = Decimal.valueOf(fs.Value__c); 
                                System.debug('rate----->'+currentQuoteRateValueQC);
                            }
                            if(fs.Code__c == 'Netted Down Premium Broker Commission Percent' && string.isNotBlank(fs.Value__c)){   
                                objQOToUpsert.Netted_Down_Commission_Percent__c = Decimal.valueOf(fs.Value__c); 
                            }
                            if(fs.Code__c == 'Netted Down Premium Broker Commission Sum' && string.isNotBlank(fs.Value__c)){   
                                objQOToUpsert.Netted_Down_Commission_Amount__c = Decimal.valueOf(fs.Value__c); 
                            }
                            if(fs.Code__c == 'Broker Commission Percent' && string.isNotBlank(fs.Value__c)){   
                                objQOToUpsert.Broker_Commission_Percent__c = Decimal.valueOf(fs.Value__c); 
                            }
                            if(fs.Code__c == 'Netted Down Premium MGA Commission Percent' && string.isNotBlank(fs.Value__c)){   
                                objQOToUpsert.Netted_Down_MGA_Commission_Percent__c = Decimal.valueOf(fs.Value__c); 
                            }
                            if(fs.Code__c == 'Netted Down Premium MGA Commission Sum' && string.isNotBlank(fs.Value__c)){   
                                objQOToUpsert.Netted_Down_MGA_Commission_Amount__c = Decimal.valueOf(fs.Value__c); 
                            }
                            if(fs.Code__c == 'Increased Limit Factor' && string.isNotBlank(fs.Value__c)){  
                                objQOToUpsert.Increased_Limit_Factor__c = Decimal.valueOf(fs.Value__c); 
                            }
                            
                        }
                        
                        System.debug('test factor---->');
                        if(currentQuote.Quote_Type__c == 'Renewal' && currentQuote.Parent_Quote__r != null){
                            Factor_Summary__c dataSum1 = new Factor_Summary__c();
                            dataSum1.Code__c = 'Rate - Previous Year';
                            dataSum1.Value__c = String.valueOf(currentQuote.Parent_Quote__r.Rate__c);
                            System.debug('dataSum1.Value__c'+dataSum1.Value__c);
                            Factor_Summary__c dataSum2 = new Factor_Summary__c();
                            dataSum2.Code__c = 'Rate Change';
                            if(String.isNotBlank(dataSum1.Value__c) && Decimal.valueOf(dataSum1.Value__c) != 0){        //added for null pointer exception
                                dataSum2.Value__c = currentQuoteRateValue!=null ? String.valueOf(((currentQuoteRateValueQC - Decimal.valueOf(dataSum1.Value__c))/Decimal.valueOf(dataSum1.Value__c) *100).setScale(2)) : '0';
                            }
                            else{
                                dataSum1.Value__c = '0';
                                dataSum2.Value__c = '0';
                            }
                            if(Decimal.valueOf(dataSum2.Value__c) > 0)	dataSum2.Value__c = '+'+dataSum2.Value__c;
                            factorSummaryListQC.add(dataSum1);
                            factorSummaryListQC.add(dataSum2);
                        }
                        
                        //Create Map and call logic after for loop to avoid 101
                        String strQuoteOptionId = objQOToUpsert.Id;
                        if(String.isNotBlank(strQuoteOptionId)){
                            mapOfOptionIdVsListOfFactorSummary.put(strQuoteOptionId, factorSummaryListQC);
                        }
                        
                    }

                    lstQuoteOptionToUpsert.add(objQOToUpsert);
                }
                
                
                //Call the new method
                if(!mapOfOptionIdVsListOfFactorSummary.isEmpty()){
                    CreateFactorSummary.createNewFactorSummaryQC(mapOfOptionIdVsListOfFactorSummary);
                }
                
                if(!lstQuoteOptionToUpsert.isEmpty()){
                    upsert lstQuoteOptionToUpsert;
                }
				
                for(Quote_Option__c option : lstQuoteOptionToUpsert){
                    quoteOptionIdtoAzureIdMap.put(option.Azure_ID__c,option.Id);
                }
            }

            //Rating Modifiers        
            Map<String,Rating_Modifiers__c> codeToRatingModResponseMap = new Map<String,Rating_Modifiers__c>();
            Map<String,Rating_Modifiers__c> CodeToRatingModQueryMap = new Map<String,Rating_Modifiers__c>();
            Map<String,Rating_Modifier_Factor__c> CodeToRatingModFactorQueryMap = new Map<String,Rating_Modifier_Factor__c>();
            List<Rating_Modifiers__c> RatingModToUpdateList = new List<Rating_Modifiers__c>();
            Set<String> RatingModCodeIdSet = new Set<String>();
            if(!mapOfAzureIdToQOResponse.isEmpty()){
                for(Factor_Summary__c fs : mapOfAzureIdToQOResponse.values()[0].Factor_Summary_Items__r){
                    if(fs.Code__c == 'Technical Premium Discretion Percent' && string.isNotBlank(fs.Value__c)){  
                        totalTechnicalAdj = fs.Value__c; 
                    }
                }
            }
            System.debug('totalTechnicalAdj-------->'+totalTechnicalAdj);
            
            for(integer i = 0;i<responseJSONString.quote.Rating_Modifier_Factors__r.size();i++){
                Rating_Modifiers__c rmRecord = responseJSONString.quote.Rating_Modifier_Factors__r[i].Rating_Modifier__r;
                Rating_Modifier_Factor__c rmRecordfactor = responseJSONString.quote.Rating_Modifier_Factors__r[i];               
                RatingModCodeIdSet.add(rmRecord.Rating_Modifier_Code__c);
                codeToRatingModResponseMap.put(rmRecord.Rating_Modifier_Code__c, rmRecord);
                CodeToRatingModFactorQueryMap.put(rmRecord.Rating_Modifier_Code__c,rmRecordfactor);
                
            }
            
            for(Rating_Modifiers__c rmQuery: [SELECT Rating_Modifier_Code__c,Name,Azure_ID__c
                                              FROM Rating_Modifiers__c WHERE Rating_Modifier_Code__c IN:RatingModCodeIdSet and  Opportunity__c =:quotes[0].OpportunityId]){
                                                  CodeToRatingModQueryMap.put(rmQuery.Rating_Modifier_Code__c,rmQuery);
                                                  
                                              }
            
            for(String rmratingcodeId: codeToRatingModResponseMap.keySet()){
                if(CodeToRatingModQueryMap.get(rmratingcodeId) != null){
                    Rating_Modifiers__c  rmUpd = CodeToRatingModQueryMap.get(rmratingcodeId);
                    Rating_Modifiers__c rmResponse = codeToRatingModResponseMap.get(rmratingcodeId);                    
                    
                    if(rmResponse.Rating_Modifier_Code__c!= NULL) rmUpd.Rating_Modifier_Code__c= rmResponse.Rating_Modifier_Code__c;
                    if(rmResponse.Rating_Modifier_Value__c!= NULL) rmUpd.Rating_Modifier_Value__c = rmResponse.Rating_Modifier_Value__c;
                    if(rmResponse.Factor_Max__c!= NULL) rmUpd.Factor_Max__c = rmResponse.Factor_Max__c;
                    if(rmResponse.Factor_Min__c!= NULL) rmUpd.Factor_Min__c = rmResponse.Factor_Min__c;
                    if(rmResponse.Rating_Modifier_Code__c != NULL && rmResponse.Rating_Modifier_Code__c == 'PI0000036' && totalTechnicalAdj != null){
                        System.debug('totalTechnicalAdj-------->'+totalTechnicalAdj);
                        rmUpd.Rating_Modifier_Value__c = totalTechnicalAdj;
                    }
                    
                    RatingModToUpdateList.add(rmUpd);
                }                
            }
            
            if(!RatingModToUpdateList .isEmpty()){                
                update RatingModToUpdateList ;
            }
            
            //Rating Modifiers Fators            
            Map<String,Rating_Modifier_Factor__c> codeToRatingQueryMap = new Map<String,Rating_Modifier_Factor__c>();
            List<Rating_Modifiers__c> RatingfacToUpdateList = new List<Rating_Modifiers__c>();
            List<Rating_Modifier_Factor__c> RatingToUpdateList = new List<Rating_Modifier_Factor__c>();
            Set<String> RatingAzureIdSet = new Set<String>();
            
            for(Rating_Modifier_Factor__c rmfactQuery: [SELECT Factor_Max__c,Factor_Default_Value__c,
                                                        Factor_Min__c,Factor_Value__c,Name,Azure_ID__c,Rating_Modifier__r.Azure_ID__c,
                                                        Rating_Modifier__r.Rating_Modifier_Code__c, Rating_Modifier__r.Factor_Max__c,
                                                        Rating_Modifier__r.Factor_Min__c
                                                        FROM Rating_Modifier_Factor__c 
                                                        WHERE Rating_Modifier__r.Rating_Modifier_Code__c IN:RatingModCodeIdSet 
                                                        AND Quote__c=:responseJSONString.quote.Id]){
                                                            codeToRatingQueryMap.put(rmfactQuery.Rating_Modifier__r.Rating_Modifier_Code__c,rmfactQuery);                                                            
                                                        }
            
            for(String rmcodeId: codeToRatingQueryMap.keySet()){
                if(codeToRatingQueryMap.get(rmcodeId) != null){
                    Rating_Modifier_Factor__c rmfactorUpd = codeToRatingQueryMap.get(rmcodeId);
                    Rating_Modifier_Factor__c rmfactorResponse = CodeToRatingModFactorQueryMap.get(rmcodeId);
                    Rating_Modifiers__c  rmUpd1 = CodeToRatingModQueryMap.get(rmcodeId);
                    
                    if(rmfactorResponse.Factor_Max__c!= NULL) rmUpd1.Factor_Max__c = rmfactorResponse.Factor_Max__c;
                    if(rmfactorResponse.Factor_Min__c!= NULL) rmUpd1.Factor_Min__c = rmfactorResponse.Factor_Min__c;
                    
                    if(rmfactorResponse.Factor_Max__c!= NULL) rmfactorUpd.Factor_Max__c = rmfactorResponse.Factor_Max__c;
                    if(rmfactorResponse.Factor_Default_Value__c!= NULL) rmfactorUpd.Factor_Default_Value__c = rmfactorResponse.Factor_Default_Value__c;
                    if(rmfactorResponse.Factor_Min__c!= NULL) rmfactorUpd.Factor_Min__c = rmfactorResponse.Factor_Min__c;
                    if(rmfactorResponse.Factor_Value__c!= NULL) rmfactorUpd.Factor_Value__c = rmfactorResponse.Factor_Value__c;                    
                    
                    RatingToUpdateList.add(rmfactorUpd);
                    RatingfacToUpdateList.add(rmUpd1);
                }                
            }
            
            if(!RatingToUpdateList.isEmpty()){              
                update RatingToUpdateList;
                update RatingfacToUpdateList;
            }   
            
            //Referral_Reason__c
            List<Referral_Reason__c> referralReasonList = new  List<Referral_Reason__c>();
            List<Referral_Reason__c> referralReasontToDeleteList = new List<Referral_Reason__c>();
            List<Referral_Reason__c> referralReasonAutoApprovedList = new  List<Referral_Reason__c>();
            
            if(responseJSONString.quote.Referral_Reasons__r.size() > 0){
                User currentUser = [SELECT Level__c FROM User WHERE Id =: UserInfo.getUserId()];
                if(currentUser.Level__c == null){
                    result.errors.add('Current user does not have a Level assigned. Please contact your Admin.');
                	return result;
                }
                referralReasonList = responseJSONString.quote.Referral_Reasons__r;
                
                system.debug('##currentUser.Level__c -- '+ currentUser.Level__c);
                system.debug('##referralReasonList -- '+ referralReasonList);
                
                for(Referral_Reason__c refReason: referralReasonList){
                    if(String.isNotBlank(refReason.Option_Id__c) && quoteOptionIdtoAzureIdMap.containsKey(refReason.Option_Id__c)){
                        refReason.Quote_Option__c = quoteOptionIdtoAzureIdMap.get(refReason.Option_Id__c);
                        refReason.Quote_Option_Limit__c = mapOfAzureIdToQOResponse.get(refReason.Option_Id__c).Limit__c;
                    }
                    if(refReason.Approval_Level_Required__c.contains(currentUser.Level__c)){
                        refReason.Approval_Rejected_Date__c = System.Date.today();
                        refReason.Approved_By__c = UserInfo.getUserId();
                        refReason.Approval_Status__c = 'Approved';
                        refReason.Is_Auto_Approved__c = true;
                        refReason.Approver_Level__c = currentUser.Level__c;
                        referralReasonAutoApprovedList.add(refReason);
                    }
                }                         
            }
            
            referralReasontToDeleteList = [SELECT Id,Approval_Level_Required__c 
                                               FROM Referral_Reason__c
                                               WHERE Approval_Status__c != 'Approved'
                                               AND Quote__c =: currentQuote.Id]; 
           
            if(!referralReasonList.isEmpty()){                
                insert referralReasonList;
                
                if(referralReasonAutoApprovedList.size() == referralReasonList.size()){ //Check if all the referral resons were auto approved
                    quoteResponse.Rating_Status__c = 'Clear';
                }
            }
            
            if(!referralReasontToDeleteList.isEmpty()){
                delete referralReasontToDeleteList;
            } 
            
            if(quoteResponse != null){
                update quoteResponse;
            }
            
            result.isSuccess = true;
            return result;
        }catch (NullPointerException ex){
            //Database.rollback(sp);
            ErrorLogsUtilityHelper.logError(ex, 'RateController.getRatingForAQ', CommonUtil.getExceptionMessage(ex), '', 'AQ_Exceptions', '', String.valueOf(ex.getLineNumber()));
            System.debug('NullException-->'+ex.getLineNumber()+' '+ex.getStackTraceString()+' '+ex.getMessage());
            result.errors.add('Failed to read the response body. Please check api log ');
        }catch(Exception ex){
            ErrorLogsUtilityHelper.logError(ex, 'RateController.getRatingForAQ', CommonUtil.getExceptionMessage(ex), '', 'AQ_Exceptions', '', String.valueOf(ex.getLineNumber()));
            System.debug('Exception-->'+ex.getLineNumber()+' '+ex.getStackTraceString()+' '+ex.getMessage());
            result.errors.add(CommonUtil.getExceptionMessage(ex)); 
        }
        return result;
    }
    
    public static ResultResponse getRatingForCelerity(String resp, List<Quote> quotes){
        ResultResponse result = new ResultResponse();
        Quote currentQuote = quotes[0];
        
        QuoteWrapper1 responseJSONString = (QuoteWrapper1)JSON.deserialize(resp,QuoteWrapper1.class);
        System.debug('responseJSONString'+responseJSONString);
        
        //For Quote
        Quote quoteResponse = responseJSONString.quote;
        
        if(quoteResponse != null){
            //Add UW Code and Reasons to quote
            if(!responseJSONString.overallUWDescriptions.isEmpty()){
                
                List<String> UWCode = new List<String>();
                List<String> UWReason = new List<String>();
                
                for(UWDescriptionsWrapper description : responseJSONString.overallUWDescriptions){
                    UWCode.add(description.uwcode);
                    UWReason.add(description.message_text);
                }
                quoteResponse.Overall_UW_Codes__c = String.join(UWCode, ',');
                quoteResponse.UW_Reason__c = String.join(UWReason, '\n');                
            }                
            quoteResponse.Id=responseJSONString.quote.Id;
            // Added for US:52873 by Maeran
            if(responseJSONString.quote.Override_Premium_Percentage__c != null) quoteResponse.Override_Premium_Percentage__c = responseJSONString.quote.Override_Premium_Percentage__c;

            quoteResponse.Shared_Aggregate_Limit__c = currentQuote.Shared_Aggregate_Limit__c; // In order to avoid value returned from MW which is Yes/No
            
        }
        
        //Factor Summary
        List<Factor_Summary__c> factorSummaryList = new  List<Factor_Summary__c>();
        
        if(responseJSONString.quote.Factor_Summary_Items__r.size() > 0){
            factorSummaryList = responseJSONString.quote.Factor_Summary_Items__r; 
            //Update Commission Adjustment factor US: 55409
            for(Factor_Summary__c fs :factorSummaryList){
                if(fs.Code__c == 'Commission Factor' && string.isNotBlank(fs.Value__c)){
                     quoteResponse.CommissionAdjustmentFactor__c = fs.Value__c != null? Decimal.valueOf(fs.Value__c):null;
                }
            }
            
            CreateFactorSummary.createNewFactorSummary(factorSummaryList,quoteResponse.Id);                
        }           
        
        //For Coverage Line Items
        Map<String,CoveragesLineItem__c> azureIdToCLIResponseMap = new Map<String,CoveragesLineItem__c>();
        Map<String,CoveragesLineItem__c> azureIdToCLIQueryMap = new Map<String,CoveragesLineItem__c>();
        List<CoveragesLineItem__c> cliToUpdateList = new List<CoveragesLineItem__c>();
        List<Coverage_Limits_Deductibles__c > cliUpdateDeductToUpdateList = new List<Coverage_Limits_Deductibles__c >();
        Set<String> cliAzureIdSet = new Set<String>();
        Set<String> cliAzureLimitIdSet = new Set<String>();
        Map<String,Coverage_Limits_Deductibles__c> LimitMap = new Map<String,Coverage_Limits_Deductibles__c>();
        List<String> optList = new List<String>();

        Set<String> productNames = new Set<String>();
        //This query needs to be run only for PCC
        for(Product_Option_Line_Item__c objPOLI : [Select Id, Product__c, Product__r.Name, Is_Selected__c from Product_Option_Line_Item__c 
                where Submission__c = :currentQuote.OpportunityId and Is_Selected__c = true AND Clearance_Status__c = 'Cleared']){
                
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
                                mapMetadataSettings.put(metadataSettings.Coverage_Code__c, metadataSettings);
                            }
        }
        
        for(CoveragesLineItem__c cliRecord: responseJSONString.quote.Coverages_Line_Items__r){                       
            cliAzureIdSet.add(cliRecord.Azure_ID__c);
            azureIdToCLIResponseMap.put(cliRecord.Azure_ID__c, cliRecord);                
        }
        
        for(CoveragesLineItem__c cliQuery: [SELECT Id,Azure_ID__c, Quote__c, Coverage__c, Option_Type__c, CoverageLineItemType__c,
                                            Limits_Deductibles__c, Option_Value_Default__c, Option_Picklist__c,Coverage__r.Coverage_Code__c,
                                            Increment_Step__c, Max_amt__c, Min_amt__c,Limits_Deductibles__r.LmtDedCode__c
                                            FROM CoveragesLineItem__c WHERE Azure_ID__c IN:cliAzureIdSet]){
                                                azureIdToCLIQueryMap.put(cliQuery.Azure_ID__c,cliQuery);                                                    
                                            } 
                   
        decimal combinedMaxAggLiabilityLimit = 0;
        for(String cliAzureId: azureIdToCLIResponseMap.keySet()){
            if(azureIdToCLIQueryMap.get(cliAzureId) != null){
                CoveragesLineItem__c cliUpd = azureIdToCLIQueryMap.get(cliAzureId);
                CoveragesLineItem__c cliResponse = azureIdToCLIResponseMap.get(cliAzureId);
                Pre_Rate_Calculator_Setting__mdt metadataSettings;
                if(cliUpd.Coverage__r.Coverage_Code__c != null && mapMetadataSettings.containsKey(cliUpd.Coverage__r.Coverage_Code__c)){
                    metadataSettings = mapMetadataSettings.get(cliUpd.Coverage__r.Coverage_Code__c);
                }
                
                if(String.isNotBlank(cliResponse.Option_Type__c)) cliUpd.Option_Type__c = cliResponse.Option_Type__c;
                system.debug('before.Option_Value_Default__c'+cliResponse.Option_Value_Default__c);
                if(String.isNotBlank(cliResponse.Option_Value_Default__c)) cliUpd.Option_Value_Default__c = cliResponse.Option_Value_Default__c;
                   system.debug('after .Option_Value_Default__c'+cliResponse.Option_Value_Default__c);
                if(String.isNotBlank(cliResponse.Option_Picklist__c)) 
                    cliUpd.Option_Picklist__c = cliResponse.Option_Picklist__c;
                if(metadataSettings!=null && cliUpd.Limits_Deductibles__r.LmtDedCode__c == metadataSettings.LmtDedCode__c && cliUpd.CoverageLineItemType__c == metadataSettings.CLI_Type_Limit_Option__c){
                    combinedMaxAggLiabilityLimit += cliResponse.Option_Value_Default__c != null ? Decimal.valueOf(cliResponse.Option_Value_Default__c) : 0;
                }
                if(cliResponse.Increment_Step__c != NULL) cliUpd.Increment_Step__c = cliResponse.Increment_Step__c;
                if(cliResponse.Min_amt__c != NULL) cliUpd.Min_amt__c = cliResponse.Min_amt__c;
                if(cliResponse.Max_amt__c != NULL) cliUpd.Max_amt__c = cliResponse.Max_amt__c;
                if(cliResponse.Coverage_Premium__c != NULL) cliUpd.Coverage_Premium__c = cliResponse.Coverage_Premium__c;
                if(cliResponse.Override_Premium__c != NULL) cliUpd.Override_Premium__c = cliResponse.Override_Premium__c;
                if(cliResponse.Non_Prorated_Coverage_Premium__c != NULL) cliUpd.Non_Prorated_Coverage_Premium__c = cliResponse.Non_Prorated_Coverage_Premium__c;
                if(cliResponse.IsIncluded__c != NULL) cliUpd.IsIncluded__c = cliResponse.IsIncluded__c;
                if(cliResponse.Technical_Premium__c != NULL) cliUpd.Technical_Premium__c = cliResponse.Technical_Premium__c; // Added by Maeran for US:52760
                
                cliToUpdateList.add(cliUpd);
            }                
        }
        if(currentQuote.Combined_Max_Agg_Limit_of_Liability__c == null || currentQuote.Combined_Max_Agg_Limit_of_Liability__c == 0){
            quoteResponse.Combined_Max_Agg_Limit_of_Liability__c = combinedMaxAggLiabilityLimit;
        }
        update quoteResponse;
        
        
        if(currentQuote.Product_Name__c == 'Private Company Combo' && !quoteResponse.Surcharge_Breakdown__r?.isEmpty()){
            System.debug('ky surcharges-before->'+quoteResponse.Surcharge_Breakdown__r);            
            List<Surcharge_Breakdown__c> surchargesToUpdate = new List<Surcharge_Breakdown__c>();
            List<Surcharge_Breakdown__c> surchargesToInsert = new List<Surcharge_Breakdown__c>();
            Map<String,Surcharge_Breakdown__c> existingSurchargesMap = new Map<String,Surcharge_Breakdown__c>();
            for(Surcharge_Breakdown__c sc : [SELECT Id, Code__c, Quote__c, Description__c, Value__c
                                            FROM Surcharge_Breakdown__c WHERE Quote__c =: currentQuote.Id]){
                existingSurchargesMap.put(sc.Code__c, sc);          
            }          
            for(Surcharge_Breakdown__c scNew : quoteResponse.Surcharge_Breakdown__r){
                if(existingSurchargesMap.containsKey(scNew.Code__c)){
                    Surcharge_Breakdown__c sc = existingSurchargesMap.get(scNew.Code__c);
                    sc.Description__c = scNew.Description__c;
                    sc.Value__c = scNew.Value__c;
                    surchargesToUpdate.add(sc);
                }
                else{
                    scNew.Quote__c = currentQuote.Id;
                    surchargesToInsert.add(scNew);
                }
            }
            if(surchargesToInsert.size() > 0) insert surchargesToInsert;
            if(surchargesToUpdate.size() > 0) update surchargesToUpdate;
        }

        System.debug('cliToUpdateList-before->'+cliToUpdateList);            
        if(!cliToUpdateList.isEmpty()){
            update cliToUpdateList;
        }
        System.debug('cliToUpdateList-after->'+cliToUpdateList);   
        
        //Rating Modifiers            
        Map<String,Rating_Modifiers__c> codeToRatingModResponseMap = new Map<String,Rating_Modifiers__c>();
        Map<String,Rating_Modifiers__c> CodeToRatingModQueryMap = new Map<String,Rating_Modifiers__c>();
        Map<String,Rating_Modifier_Factor__c> CodeToRatingModFactorQueryMap = new Map<String,Rating_Modifier_Factor__c>();
        List<Rating_Modifiers__c> RatingModToUpdateList = new List<Rating_Modifiers__c>();
        Set<String> RatingModCodeIdSet = new Set<String>();
        
        for(integer i = 0;i<responseJSONString.quote.Rating_Modifier_Factors__r.size();i++){
            Rating_Modifiers__c rmRecord = responseJSONString.quote.Rating_Modifier_Factors__r[i].Rating_Modifier__r;
            Rating_Modifier_Factor__c rmRecordfactor = responseJSONString.quote.Rating_Modifier_Factors__r[i];               
            RatingModCodeIdSet.add(rmRecord.Rating_Modifier_Code__c);
            codeToRatingModResponseMap.put(rmRecord.Rating_Modifier_Code__c, rmRecord);
            CodeToRatingModFactorQueryMap.put(rmRecord.Rating_Modifier_Code__c,rmRecordfactor);
            
        }
        
        for(Rating_Modifiers__c rmQuery: [SELECT Rating_Modifier_Code__c,Name,Azure_ID__c, Rating_Modifier_Value__c
                                          FROM Rating_Modifiers__c WHERE Rating_Modifier_Code__c IN:RatingModCodeIdSet and  Opportunity__c =:quotes[0].OpportunityId]){
                                              CodeToRatingModQueryMap.put(rmQuery.Rating_Modifier_Code__c,rmQuery);
                                              
                                          }
        
        for(String rmratingcodeId: codeToRatingModResponseMap.keySet()){
            if(CodeToRatingModQueryMap.get(rmratingcodeId) != null){
                Rating_Modifiers__c  rmUpd = CodeToRatingModQueryMap.get(rmratingcodeId);
                Rating_Modifiers__c rmResponse = codeToRatingModResponseMap.get(rmratingcodeId);                    
                
                if(rmResponse.Rating_Modifier_Code__c!= NULL) rmUpd.Rating_Modifier_Code__c= rmResponse.Rating_Modifier_Code__c;
                if(currentQuote.Product_Name__c == 'Private Company Combo'){
                    if(rmResponse.Rating_Modifier_Code__c != NULL && rmResponse.Rating_Modifier_Value__c != NULL && rmUpd.Rating_Modifier_Value__c != NULL){
                        String code = rmResponse.Rating_Modifier_Code__c;
                        if(code.contains('EPL000')){
                            String value1 = rmUpd.Rating_Modifier_Value__c;
                            String value2 = rmResponse.Rating_Modifier_Value__c;
                            if(value1.toLowerCase() != value2.toLowerCase()){
                                rmUpd.Rating_Modifier_Value__c = rmResponse.Rating_Modifier_Value__c;
                            }

                        }
                        
                    }
                    // Added by Maeran to handle null for Rating_Modifier_Value__c
                    // else if(String.isBlank(rmResponse.Rating_Modifier_Value__c) && rmResponse.Rating_Modifier_Code__c.contains('EPL000')){
                    //     rmUpd.Rating_Modifier_Value__c = 'Default';
                    // }
                    String value = rmResponse.Rating_Modifier_Value__c;
                }
                else{
                    if(rmResponse.Rating_Modifier_Value__c!= NULL) rmUpd.Rating_Modifier_Value__c = rmResponse.Rating_Modifier_Value__c;
                }
                if(rmResponse.Factor_Max__c!= NULL) rmUpd.Factor_Max__c = rmResponse.Factor_Max__c;
                if(rmResponse.Factor_Min__c!= NULL) rmUpd.Factor_Min__c = rmResponse.Factor_Min__c;
                
                RatingModToUpdateList.add(rmUpd);
            }                
        }
        
        if(!RatingModToUpdateList .isEmpty()){                
            update RatingModToUpdateList ;
        }
        
        //Rating Modifiers Fators            
        Map<String,Rating_Modifier_Factor__c> codeToRatingQueryMap = new Map<String,Rating_Modifier_Factor__c>();
        List<Rating_Modifiers__c> RatingfacToUpdateList = new List<Rating_Modifiers__c>();
        List<Rating_Modifier_Factor__c> RatingToUpdateList = new List<Rating_Modifier_Factor__c>();
        Set<String> RatingAzureIdSet = new Set<String>();
        
        for(Rating_Modifier_Factor__c rmfactQuery: [SELECT Factor_Max__c,Factor_Default_Value__c,
                                                    Factor_Min__c,Factor_Value__c,Name,Azure_ID__c,Rating_Modifier__r.Azure_ID__c,
                                                    Rating_Modifier__r.Rating_Modifier_Code__c, Rating_Modifier__r.Factor_Max__c,
                                                    Rating_Modifier__r.Factor_Min__c
                                                    FROM Rating_Modifier_Factor__c 
                                                    WHERE Rating_Modifier__r.Rating_Modifier_Code__c IN:RatingModCodeIdSet 
                                                    AND Quote__c=:responseJSONString.quote.Id]){
                                                        codeToRatingQueryMap.put(rmfactQuery.Rating_Modifier__r.Rating_Modifier_Code__c,rmfactQuery);                                                            
                                                    }
        
        for(String rmcodeId: codeToRatingQueryMap.keySet()){
            if(codeToRatingQueryMap.get(rmcodeId) != null){
                Rating_Modifier_Factor__c rmfactorUpd = codeToRatingQueryMap.get(rmcodeId);
                Rating_Modifier_Factor__c rmfactorResponse = CodeToRatingModFactorQueryMap.get(rmcodeId);
                Rating_Modifiers__c  rmUpd1 = CodeToRatingModQueryMap.get(rmcodeId);
                
                if(rmfactorResponse.Factor_Max__c!= NULL) rmUpd1.Factor_Max__c = rmfactorResponse.Factor_Max__c;
                if(rmfactorResponse.Factor_Min__c!= NULL) rmUpd1.Factor_Min__c = rmfactorResponse.Factor_Min__c;
                
                if(rmfactorResponse.Factor_Max__c!= NULL) rmfactorUpd.Factor_Max__c = rmfactorResponse.Factor_Max__c;
                if(rmfactorResponse.Factor_Default_Value__c!= NULL) rmfactorUpd.Factor_Default_Value__c = rmfactorResponse.Factor_Default_Value__c;
                if(rmfactorResponse.Factor_Min__c!= NULL) rmfactorUpd.Factor_Min__c = rmfactorResponse.Factor_Min__c;
                if(rmfactorResponse.Factor_Value__c!= NULL) rmfactorUpd.Factor_Value__c = rmfactorResponse.Factor_Value__c;                    
                
                RatingToUpdateList.add(rmfactorUpd);
                RatingfacToUpdateList.add(rmUpd1);
            }                
        }
        
        if(!RatingToUpdateList.isEmpty()){              
            update RatingToUpdateList;
            update RatingfacToUpdateList;
        }            
        
        // Upsert Quote Premium object US: 53340
        if(currentQuote.Product_Name__c == System.Label.Product_Name_for_PCC && responseJSONString.quote.Quote_Premiums__r.size() >0){

            Map<String,Quote_Premium__c> mapexistProdvsQPrem = new Map<String,Quote_Premium__c>();
            Map<String,Quote_Premium__c> mapUpsertProdvsQPrem = new Map<String,Quote_Premium__c>();
            //Set<Id> existingQPIds = new Set<Id>();
            for(Quote_Premium__c eachQ: [Select Id,Product_Name__c,Quote_Premium__c,Excess_Premium__c from Quote_Premium__c where Quote__c =: responseJSONString.quote.Id]){
                mapexistProdvsQPrem.put(eachQ.Product_Name__c,eachQ);
            }
            
            for(Quote_Premium__c eachQP : responseJSONString.quote.Quote_Premiums__r){
                if(mapexistProdvsQPrem.containskey(eachQP.Product_Name__c)){
                    Quote_Premium__c existingQP = new Quote_Premium__c();
                    existingQP.Id = mapexistProdvsQPrem.get(eachQP.Product_Name__c).Id;
                    existingQP.Quote_Premium__c = eachQP.Quote_Premium__c;
                    existingQP.Excess_Premium__c = eachQP.Excess_Premium__c;
                    //existingQP.Quote__c = currentQuote.Id;
                    mapUpsertProdvsQPrem.put(eachQP.Product_Name__c, existingQP);
                    
                }
                else{
                    //Quote_Premium__c newQP =  new Quote_Premium__c();
                    
                    eachQP.Quote__c   = currentQuote.Id;
                    mapUpsertProdvsQPrem.put(eachQP.Product_Name__c,eachQP );
                }
            }
            
            if(!mapUpsertProdvsQPrem.isEmpty()){
                System.debug('mapUpsertProdvsQPrem'+mapUpsertProdvsQPrem);
                upsert mapUpsertProdvsQPrem.values();
            }
        }
     

        
        result.isSuccess = true;
        return result;
    }
    
    /*public static void createNewFactorSummary(List<Factor_Summary__c> newFactorSummary, String quoteId) {
        Map<String,Factor_Summary_Template__c> mapTemplate = new Map<String,Factor_Summary_Template__c>();
        
        if(string.isBlank(quoteId)){
            return;
        }
        List<Factor_Summary__c> fsList =  [SELECT Id FROM Factor_Summary__c WHERE Quote__c = : quoteId];
        if(!fsList.isEmpty()) delete fsList;
        
        AggregateResult result = [SELECT MAX(Sort_Order__c) FROM Factor_Summary_Template__c];
        Decimal max = result.get('expr0') == null ? 0 : (Decimal)result.get('expr0');
        for (Factor_Summary_Template__c item : [SELECT Id,Sort_Order__c,Code__c FROM Factor_Summary_Template__c]) {
            mapTemplate.put(item.Code__c,item);
        }
        
        for(Factor_Summary__c fs : newFactorSummary) {
            fs.Quote__c = quoteId;
            if(!mapTemplate.containsKey(fs.Code__c)){
                Factor_Summary_Template__c template = new Factor_Summary_Template__c();
                template.Code__c = fs.Code__c;
                template.Sort_Order__c = ++max;
                mapTemplate.put(fs.Code__c, template);
            }
        }
        if(!mapTemplate.values().isEmpty()){
            upsert mapTemplate.values();
        }
        insert newFactorSummary;
    }*/
    
    public class UWDescriptionsWrapper{
        public String uwcode;
        public String message_text;
    }
    
    public class QuoteWrapper1 {
        
        public Quote quote;
        public List<UWDescriptionsWrapper> overallUWDescriptions;
        public String overallUWCodes;
        //Public Opportunity opportunity;        
    }    

}