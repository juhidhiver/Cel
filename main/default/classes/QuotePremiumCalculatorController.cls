/**
**/
public with sharing class QuotePremiumCalculatorController {
    public QuotePremiumCalculatorController() {

    }

    @AuraEnabled
    public static RelatedListWrapper fetchRatingModifiers(String quoteId){

        RelatedListWrapper objWrap = new RelatedListWrapper();

        Quote objQuote = [Select Id,Quote_Type__c, Status,Product_Name__c, OpportunityId, Opportunity.AnnualRevenue__c, Opportunity.Plan_Assets__c,Total_Premium__c, Underlying_Excess_Limit__c, Underlying_Excess_Attachment__c, Layer__c, Opportunity.Full_Time_Employees__c, Opportunity.Part_Time_Employees__c, Opportunity.Foreign_Employees__c, Commission_percentage__c, Effective_Date__c, ExpirationDate from Quote where Id =: quoteId];
        objWrap.objQuote = objQuote;
        Map<String,List<Rating_Modifier_Factor__c>> mapRatingModifier = new Map<String,List<Rating_Modifier_Factor__c>>();
        Map<String,List<Rating_Modifier_Factor__c>> mapRatingModifierOptional = new Map<String,List<Rating_Modifier_Factor__c>>();

        List<String> productNames = new list<String>();//{'D&O','EPL','Crime','Fiduciary'};
        for(Product_Option_Line_Item__c objPOLI : [Select Id, Product__c, Product__r.Name, Is_Selected__c from Product_Option_Line_Item__c 
                                                    where Submission__c = :objQuote.OpportunityId and Is_Selected__c = true AND Clearance_Status__c = 'Cleared']){
                                                    
                                                        productNames.add(objPOLI.Product__r.Name);

        }

        Map<String, Pre_Rate_Calculator_Setting__mdt> mapMetadataSettings = new Map<String, Pre_Rate_Calculator_Setting__mdt>();
        Pre_Rate_Calculator_Setting__mdt metadataSettingExcess  = new Pre_Rate_Calculator_Setting__mdt();
        for(Pre_Rate_Calculator_Setting__mdt metadataSettings : [Select Id, Active__c,  County_Table_Name__c, Industry_Modifier_Code__c, LimitILF_Table_Name__c, Policy_Retention_Table_Name__c, 
                                                            ProductName__c, SnT_Modifier_Code__c, Order__c, Coverage_Code__c, CLI_Type_Deductible_Option__c, CLI_Type_Limit_Option__c, 
                                                            CLI_Type_Main_Option__c, Exec_Coverage_Code__c, ExecLmtDedCode__c, LmtDedCode__c, LmtDedRetentionCode__c, Base_Rate_Table__c, 
                                                            AdditionalCoverageCodes__c 
                                                            from Pre_Rate_Calculator_Setting__mdt order By Order__c Asc]){
                                                                if(productNames.contains(metadataSettings.ProductName__c)){
                                                                    //productNames.add(metadataSettings.ProductName__c);
                                                                    mapRatingModifier.put(metadataSettings.ProductName__c,new List<Rating_Modifier_Factor__c>());
                                                                    mapMetadataSettings.put(metadataSettings.ProductName__c, metadataSettings);
                                                                }
                                                                if(metadataSettings.ProductName__c == 'Excess'){
                                                                    metadataSettingExcess = metadataSettings;
                                                                }
                                                            }

        

        Decimal requiredLimit;

        /*for(Product_Option_Line_Item__c objPOLI : [Select Id, Product__c, Product__r.Name, Is_Selected__c from Product_Option_Line_Item__c 
                                                    where Submission__c = :objQuote.OpportunityId and Is_Selected__c = true]){
                                                    
            productNames.add(objPOLI.Product__r.Name);

        }*/

        for(Rating_Modifier_Factor__c objRatingModifierFactor : [SELECT Id, Factor_Default_Value__c, Factor_Max__c, Factor_Min__c,
                                Factor_Value__c, Rating_Modifier__c, Rating_Modifier__r.Rating_Modifier_Value__c,
                                Rating_Modifier__r.Rating_Modifier_Code__c, Rating_Modifier__r.Format__c,
                                Rating_Modifier__r.Name, Rating_Modifier__r.Product__c,Rating_Modifier__r.Factor_Max__c,
                                Rating_Modifier__r.Factor_Min__c,Rating_Modifier__r.Factor_Value__c,
                                Rating_Modifier__r.Azure_ID__c, Rating_Modifier__r.Page_Section__c, Rating_Modifier__r.Sub_Section__c,
                                Rating_Modifier__r.Picklist_Values__c, Rating_Modifier__r.Rating_Modifier_Template_Code__c,
                                Rating_Modifier__r.Rating_Reference_Name__c, Rating_Modifier__r.Coverage_Code__c
                                FROM Rating_Modifier_Factor__c where Quote__c =: quoteId AND Rating_Modifier__r.Page_Section__c = 'Premium Calculator' Order By Rating_Modifier__r.Sort_Order__c Asc]){

                                    if(productNames.contains(objRatingModifierFactor.Rating_Modifier__r.Product__c)){

                                        if(objRatingModifierFactor.Rating_Modifier__r.Sub_Section__c == 'Primary Factors'){
                                            if(mapRatingModifier.containsKey(objRatingModifierFactor.Rating_Modifier__r.Product__c)){
                                                List<Rating_Modifier_Factor__c> listRatingMod = new List<Rating_Modifier_Factor__c>();
                                                listRatingMod = mapRatingModifier.get(objRatingModifierFactor.Rating_Modifier__r.Product__c);
                                                listRatingMod.add(objRatingModifierFactor);
                                                mapRatingModifier.put(objRatingModifierFactor.Rating_Modifier__r.Product__c,listRatingMod);
                                            }
                                            else{
                                                List<Rating_Modifier_Factor__c> listRatingMod = new List<Rating_Modifier_Factor__c>();
                                                listRatingMod.add(objRatingModifierFactor);
                                                mapRatingModifier.put(objRatingModifierFactor.Rating_Modifier__r.Product__c,listRatingMod);
                                            }
                                        }
                                        else if(objRatingModifierFactor.Rating_Modifier__r.Sub_Section__c == 'Optional Factors'){
                                            if(mapRatingModifierOptional.containsKey(objRatingModifierFactor.Rating_Modifier__r.Product__c)){
                                                List<Rating_Modifier_Factor__c> listRatingMod = new List<Rating_Modifier_Factor__c>();
                                                listRatingMod = mapRatingModifierOptional.get(objRatingModifierFactor.Rating_Modifier__r.Product__c);
                                                listRatingMod.add(objRatingModifierFactor);
                                                mapRatingModifierOptional.put(objRatingModifierFactor.Rating_Modifier__r.Product__c,listRatingMod);
                                            }
                                            else{
                                                List<Rating_Modifier_Factor__c> listRatingMod = new List<Rating_Modifier_Factor__c>();
                                                listRatingMod.add(objRatingModifierFactor);
                                                mapRatingModifierOptional.put(objRatingModifierFactor.Rating_Modifier__r.Product__c,listRatingMod);
                                            }
                                        }

                                    }

                                }
        
        
        List<RecordDetails> lstRecordDetails = new List<RecordDetails>();
        Decimal totalPremium = 0.0;
        for(String product : mapRatingModifier.Keyset()){
            System.debug('product'+product);
            System.debug('mapRatingModifier.get(product)'+mapRatingModifier.get(product));
            Pre_Rate_Calculator_Setting__mdt metadataSettings = mapMetadataSettings.get(product);
            List<String> listAddCovCodes = new List<String>();
            if(metadataSettings.AdditionalCoverageCodes__c != null){
                listAddCovCodes = metadataSettings.AdditionalCoverageCodes__c.split(';');
            }
            RecordDetails objRecordDetails = new RecordDetails();
            PremiumCalculatorSetting metadataSetting = new PremiumCalculatorSetting();
            metadataSetting.productName = metadataSettings.ProductName__c;
            metadataSetting.snTModifierCode = metadataSettings.SnT_Modifier_Code__c;
            metadataSetting.industryModifierCode = metadataSettings.Industry_Modifier_Code__c;
            objRecordDetails.metadataSetting = metadataSetting;
            objRecordDetails.productName = product;
            Decimal overallFactor = 1;
            Decimal snTModifier = 0;
            Decimal industryMod = 0;
            Decimal partTimeRatio = 0;
            Decimal percentCA = 0;
            Decimal foreignRatio = 0;
            Decimal RatableEmployee = 0;
            Decimal technicalPremium = 0;
            Decimal baseRate = 0;
            
            for(Rating_Modifier_Factor__c ratingModFactor : mapRatingModifier.get(product)){
                if(ratingModFactor.Rating_Modifier__r.Rating_Modifier_Code__c == 'EPL000001'){
                    percentCA = ratingModFactor.Factor_Value__c != null ? ratingModFactor.Factor_Value__c : 0; 
                }
                if(ratingModFactor.Rating_Modifier__r.Rating_Modifier_Code__c == 'EPL000017'){
                    partTimeRatio = ratingModFactor.Factor_Value__c != null ? ratingModFactor.Factor_Value__c : 0; 
                }
                else if(ratingModFactor.Rating_Modifier__r.Rating_Modifier_Code__c == 'EPL000018'){
                    foreignRatio = ratingModFactor.Factor_Value__c != null ? ratingModFactor.Factor_Value__c : 0; 
                }
                else if(ratingModFactor.Rating_Modifier__r.Rating_Modifier_Code__c == metadataSettings.SnT_Modifier_Code__c){
                    snTModifier = ratingModFactor.Factor_Value__c;
                }
                else if(ratingModFactor.Rating_Modifier__r.Rating_Modifier_Code__c == metadataSettings.Industry_Modifier_Code__c){
                    industryMod = ratingModFactor.Factor_Value__c;
                }
                else if(ratingModFactor.Factor_Value__c != null){
                    overallFactor *= ratingModFactor.Factor_Value__c;
                }

                // Size change for Rich text area
                if(ratingModFactor.Rating_Modifier__r.Format__c == 'Rich Text Area'){
                    objRecordDetails.colSize  = 12;
                }
                else{
                    objRecordDetails.colSize  = 6;
                }
            }
            objRecordDetails.stateRelativityFactor = RatingFactorsHelper.getStateCountyFactor(product,objQuote.OpportunityId);
            if(product == 'D&O'){
                objRecordDetails.isSectionHidden = false;
                objRecordDetails.isProductDO = true;
                objRecordDetails.backgroundColorHeader = 'slds-accordion__summary slds-box header-background-blue';
                baseRate = RatingFactorsHelper.getRatingRangesBaseRate(product,objQuote.OpportunityId,metadataSettings.Base_Rate_Table__c);
                System.debug('baseRate---->'+baseRate);
                System.debug('objRecordDetails.stateRelativityFactor---->'+objRecordDetails.stateRelativityFactor);
                objRecordDetails.baseRate = objRecordDetails.stateRelativityFactor != null ? baseRate != null ? baseRate * objRecordDetails.stateRelativityFactor : 0 : baseRate;
            }
            else if(product == 'EPL'){
                objRecordDetails.isProductEPL = true;
                objRecordDetails.isSectionHidden = true;
                objRecordDetails.backgroundColorHeader = 'slds-accordion__summary slds-box header-background-grey';
                EPLEmployeeDetails employeedetails = new EPLEmployeeDetails();
                Decimal fullTimeEmployee = employeedetails.fullTimeEmployee = objQuote.Opportunity.Full_Time_Employees__c;
                Decimal partTimeEmployee = employeedetails.partTimeEmployee = objQuote.Opportunity.Part_Time_Employees__c;
                Decimal foreignEmployee = employeedetails.foreignEmployee = objQuote.Opportunity.Foreign_Employees__c;
                if(partTimeRatio != null && partTimeRatio > 0 && partTimeEmployee != null){
                    partTimeEmployee = partTimeEmployee * partTimeRatio;
                }
                if(foreignRatio != null && foreignRatio > 0 && foreignEmployee != null){
                    foreignEmployee = foreignEmployee * foreignRatio;
                }
                RatableEmployee = fullTimeEmployee != null && partTimeEmployee != null && foreignEmployee != null ? fullTimeEmployee + partTimeEmployee + foreignEmployee > 2500 ? 2500 : fullTimeEmployee + partTimeEmployee + foreignEmployee : 0;
                employeedetails.RatableEmployee = RatableEmployee;
                employeedetails.listRatableEmployeeFactorTable = RatingFactorsHelper.getRatableEmployeeFactor();
                objRecordDetails.employeeDetails = employeedetails;
                if(employeeDetails.listRatableEmployeeFactorTable != null && !employeeDetails.listRatableEmployeeFactorTable.isEmpty()){
                    for(RatingFactorsHelper.RateableEmployeesTable objRateableEmpTable : employeeDetails.listRatableEmployeeFactorTable){
                        if(RatableEmployee >= objRateableEmpTable.lowerValue && RatableEmployee < objRateableEmpTable.upperValue){
                            RatingFactorsHelper.RateableEmployeeFactor rateableEmployeeFactor = objRateableEmpTable.rateableEmployeeFactor;
                            Decimal base_rate = Decimal.valueOf(rateableEmployeeFactor.base_rate);
                            Decimal perEmployeeRate = Decimal.valueOf(rateableEmployeeFactor.per_employee_rate);
                            Decimal rangeLowerLimit = Decimal.valueOf(rateableEmployeeFactor.range_lower_limit);
                            baseRate = (base_rate + ((RatableEmployee - rangeLowerLimit) * perEmployeeRate));
                            objRecordDetails.baseRate = objRecordDetails.stateRelativityFactor != null ? baseRate * objRecordDetails.stateRelativityFactor : baseRate;
                        }
                    }
                }
            }
            else{
                if(product == 'Fiduciary'){
                    objRecordDetails.isProductFiduciary = true;
                }
                else if(product == 'Crime'){
                    objRecordDetails.isProductCrime = true;
                }
                objRecordDetails.baseRate = RatingFactorsHelper.getRatingRangesBaseRate(product,objQuote.OpportunityId,metadataSettings.Base_Rate_Table__c);
                objRecordDetails.isSectionHidden = true;
                objRecordDetails.backgroundColorHeader = 'slds-accordion__summary slds-box header-background-grey';
            }
            objRecordDetails.overallRatingModifier = overallFactor;
            objRecordDetails.snTModifier = snTModifier;
            objRecordDetails.industryMod = industryMod;
            objRecordDetails.listLimitRange = RatingFactorsHelper.getLimitILF(product,metadataSettings.LimitILF_Table_Name__c);
            objRecordDetails.listRetentionMod = RatingFactorsHelper.getRetentionILF(objQuote.OpportunityId,product,metadataSettings.Policy_Retention_Table_Name__c,RatableEmployee);

            Map<String,OptionalCoverages> mapOptionalCoverages = new Map<String,OptionalCoverages>();
            System.debug('mapRatingModifierOptional'+mapRatingModifierOptional);
            for(CoveragesLineItem__c covLineItem : [Select Id, Coverage_Premium__c, Coverage_Product__c, Coverage_Product_Combo__c,
                                    CoverageLineItemType__c, Quote__c, Override_Premium__c, Option_Value_Default__c, Option_Value__c, Option_Type__c, Coverage__c, Option_Picklist__c,
                                    Coverage__r.Coverage_Code__c, Coverage__r.Coverage_Product__c, Page_Section__c, Optional_Coverage_Name__c, Optional_Factor_Label__c,
                                    Coverage__r.Name, Limits_Deductibles__c, Limits_Deductibles__r.Name, Limits_Deductibles__r.LmtDedCode__c 
                                    from CoveragesLineItem__c where Quote__c = : quoteId]){

                                        if(covLineItem.Coverage__r.Coverage_Code__c == metadataSettings.Coverage_Code__c && covLineItem.Limits_Deductibles__r.LmtDedCode__c == metadataSettings.LmtDedCode__c && covLineItem.CoverageLineItemType__c == metadataSettings.CLI_Type_Limit_Option__c){
                                            requiredLimit = covLineItem.Option_Value_Default__c != null ? Decimal.valueOf(covLineItem.Option_Value_Default__c) : null;// update by Jitendra on 07-Jan-2022 for MAT-80
                                            objRecordDetails.requiredLimit = requiredLimit;
                                            objRecordDetails.limitfactor = RatingFactorsHelper.getLimitFactor(requiredLimit,objRecordDetails.listLimitRange);
                                        }
                                        if(covLineItem.Coverage__r.Coverage_Code__c == metadataSettings.Coverage_Code__c && covLineItem.Limits_Deductibles__r.LmtDedCode__c == metadataSettings.LmtDedRetentionCode__c && covLineItem.CoverageLineItemType__c == metadataSettings.CLI_Type_Deductible_Option__c){
                                            objRecordDetails.policyRetention = covLineItem.Option_Value_Default__c != null ? Decimal.valueOf(covLineItem.Option_Value_Default__c) : null;// update by Jitendra on 07-Jan-2022 for MAT-80
                                            objRecordDetails.retentionFactor = RatingFactorsHelper.getRetentionFactor(objRecordDetails.policyRetention,objRecordDetails.listRetentionMod);

                                        }
                                        if(covLineItem.Coverage_Product_Combo__c == product && covLineItem.CoverageLineItemType__c == metadataSettings.CLI_Type_Main_Option__c){
                                            technicalPremium += covLineItem.Coverage_Premium__c != null ? Decimal.valueOf(covLineItem.Coverage_Premium__c) : 0;// update by Jitendra on 07-Jan-2022 for MAT-80
                                            objRecordDetails.actualPremium += covLineItem.Override_Premium__c != null ? covLineItem.Override_Premium__c : 0;
                                            //totalPremium += objRecordDetails.technicalPremium;
                                            
                                        }
                                        if(!listAddCovCodes.isEmpty()){
                                            if(covLineItem.Coverage__r.Coverage_Code__c == metadataSettings.Coverage_Code__c && listAddCovCodes.contains(covLineItem.Limits_Deductibles__r.LmtDedCode__c)){
                                                //List<CoveragesLineItem__c> listCLI = new List<CoveragesLineItem__c>();
                                                //listCLI.add(covLineItem);
                                                objRecordDetails.listAdditionalCoverageLineItems.add(covLineItem);
                                            }
                                        }
                                        /*if(covLineItem.Coverage__r.Coverage_Code__c == metadataSettings.Exec_Coverage_Code__c && covLineItem.Limits_Deductibles__r.LmtDedCode__c == metadataSettings.ExecLmtDedCode__c && covLineItem.CoverageLineItemType__c == metadataSettings.CLI_Type_Limit_Option__c){
                                            objRecordDetails.executiveLimit = covLineItem.Option_Value_Default__c != null ? Decimal.valueOf(covLineItem.Option_Value_Default__c) : 0;// update by Jitendra on Jan-Dec-2022 for MAT-80
                                            objRecordDetails.exelimitfactor = RatingFactorsHelper.getLimitFactor(objRecordDetails.executiveLimit,objRecordDetails.listLimitRange);
                                        }*/
                                        if(covLineItem.Coverage_Product__c == GlobalVariables.PROD_NAME_FOR_PCC && covLineItem.Coverage_Product_Combo__c == product && covLineItem.Page_Section__c == 'Optional Coverage'){
                                            System.debug('here---->');
                                            OptionalCoverages objOptionalCoverages = new OptionalCoverages();
                                            if(!mapOptionalCoverages.isEmpty() && mapOptionalCoverages.containsKey(covLineItem.Coverage__c)){
                                                objOptionalCoverages = mapOptionalCoverages.get(covLineItem.Coverage__c);
                                            }
                                            if(covLineItem.CoverageLineItemType__c == metadataSettings.CLI_Type_Main_Option__c){
                                                objOptionalCoverages.coverageId = covLineItem.Coverage__c;
                                                objOptionalCoverages.optionalCoverageName = covLineItem.Optional_Coverage_Name__c;
                                                objOptionalCoverages.optionalFactorLabel= covLineItem.Optional_Factor_Label__c;
                                                objOptionalCoverages.coverageCode = covLineItem.Coverage__r.Coverage_Code__c;
                                                if(covLineItem.Coverage__r.Coverage_Code__c == 'EPLCoverageWH'){
                                                    objOptionalCoverages.mapWHLimitFactor = RatingFactorsHelper.getWHFactorMap(product,'EPL_WageHourSublimitFactor');
                                                    objOptionalCoverages.mapWHRetentionFactor = RatingFactorsHelper.getWHFactorMap(product,'EPL_WageHourRetentionFactor');
                                                }
                                                if(covLineItem.Coverage__r.Coverage_Code__c == 'DOExecsCoverage'){
                                                    objOptionalCoverages.cLRFAjdustment = 1;
                                                }
                                            }
                                            else{
                                                if(((covLineItem.Coverage__r.Coverage_Code__c == 'EPLClassRetentionCoverage' && covLineItem.CoverageLineItemType__c == metadataSettings.CLI_Type_Deductible_Option__c) || covLineItem.CoverageLineItemType__c == metadataSettings.CLI_Type_Limit_Option__c) && covLineItem.Option_Value_Default__c != null && covLineItem.Option_Value_Default__c != '0'){
                                                    objOptionalCoverages.isCoveraheRequired = true;
                                                    objOptionalCoverages.strCoveraheRequired = 'Yes';
                                                }
                                                System.debug('covLineItem'+covLineItem);
                                                System.debug('objOptionalCoverages.listCoverageLineItems'+objOptionalCoverages.listCoverageLineItems);
                                                List<CoveragesLineItem__c> listCoverageLineItems = new List<CoveragesLineItem__c>();
                                                if(!objOptionalCoverages.listCoverageLineItems.isEmpty()){
                                                    listCoverageLineItems = objOptionalCoverages.listCoverageLineItems;
                                                    listCoverageLineItems.add(covLineItem);
                                                    objOptionalCoverages.listCoverageLineItems = listCoverageLineItems;
                                                }
                                                else{
                                                    listCoverageLineItems.add(covLineItem);
                                                    objOptionalCoverages.listCoverageLineItems = listCoverageLineItems;
                                                }
                                            }
                                            if(mapRatingModifierOptional.containsKey(product)){
                                                for(Rating_Modifier_Factor__c ratingModFactor : mapRatingModifierOptional.get(product)){
                                                    System.debug('ratingModFactor---->'+ratingModFactor);
                                                    if(ratingModFactor.Rating_Modifier__r.Coverage_Code__c != null){
                                                        String coverageCode = ratingModFactor.Rating_Modifier__r.Coverage_Code__c;
                                                        List<String> listCoverageCodes = coverageCode.split(';');
                                                        if(listCoverageCodes.contains(covLineItem.Coverage__r.Coverage_Code__c)){
                                                            objOptionalCoverages.hasRatingModifier = true;
                                                            objOptionalCoverages.optionalRatingModifierFactor = ratingModFactor;
                                                        }
                                                    }
                                                }
                                            }
                                            System.debug('objOptionalCoverages'+objOptionalCoverages);
                                            mapOptionalCoverages.put(covLineItem.Coverage__c, objOptionalCoverages);
                                        }

            }
            totalPremium += technicalPremium;
            objRecordDetails.technicalPremium  = technicalPremium;
            objRecordDetails.listOptionalCoverages = mapOptionalCoverages.values();
            objRecordDetails.listRatingModifier = mapRatingModifier.get(product);
            objRecordDetails.listOptionalRatingModifier = mapRatingModifierOptional.get(product);
            if(objRecordDetails.requiredLimit != null && objRecordDetails.policyRetention != null){
                Decimal reqLimit = objRecordDetails.requiredLimit;
                Decimal pRetention = objRecordDetails.policyRetention;
                Decimal cLRF = 0;
                if(reqLimit < 1000000){
                    cLRF = objRecordDetails.limitfactor * objRecordDetails.retentionFactor;
                }
                else if(reqLimit >= 1000000 && pRetention < 1000000){
                    cLRF = objRecordDetails.limitfactor + objRecordDetails.retentionFactor - 1;
                }
                else if(reqLimit >= 1000000 && pRetention >= 1000000){
                    Double formulaExponent = getFormulaExponent(product);
                    Double limRet = (reqLimit + pRetention) / 1000000;
                    Double pRet = (pRetention) / 1000000;
                    Decimal ILFLimitRetention = (Decimal)Math.pow( limRet , formulaExponent);
                    Decimal ILFRetention = (Decimal)Math.pow( pRet, formulaExponent);
                    cLRF = ILFLimitRetention - ILFRetention;
                }
                objRecordDetails.cLRF = cLRF;
            }
            lstRecordDetails.add(objRecordDetails);
        }
        objWrap.listRecordDetails = lstRecordDetails;
        objWrap.lstSelectedProduct = productNames;
        objWrap.factorRangeMap = RatingFactorsHelper.getRatingRangesMap(objQuote.OpportunityId);
        objWrap.stateRange = RatingFactorsHelper.getRatingRangesState(objQuote.OpportunityId);
        objWrap.totalPremium = totalPremium;
        objWrap.annualRevenue = objQuote.Opportunity.AnnualRevenue__c;
        objWrap.planAssets = objQuote.Opportunity.Plan_Assets__c;
        //objWrap.stateRelativityFactor = RatingFactorsHelper.getStateCountyFactor(product,objQuote.OpportunityId);
        objWrap.quoteLayer = objQuote.Layer__c;
        if(objQuote.Layer__c == 'Excess' && metadataSettingExcess != null){
            //Pre_Rate_Calculator_Setting__mdt metadataSettingExcess = mapMetadataSettings.get('Excess');

            for(CoveragesLineItem__c covLineItem : [Select Id, Coverage_Premium__c, Coverage_Product__c, Coverage_Product_Combo__c,
                                    CoverageLineItemType__c, Quote__c, Override_Premium__c, Option_Value_Default__c, Coverage__c, 
                                    Coverage__r.Coverage_Code__c, Coverage__r.Coverage_Product__c, 
                                    Coverage__r.Name, Limits_Deductibles__c, Limits_Deductibles__r.Name, Limits_Deductibles__r.LmtDedCode__c 
                                    from CoveragesLineItem__c where Quote__c = : quoteId AND Coverage_Code__c = :metadataSettingExcess.Coverage_Code__c]){
                                        
                                        if(covLineItem.Coverage__r.Coverage_Code__c == metadataSettingExcess.Coverage_Code__c && covLineItem.Limits_Deductibles__r.LmtDedCode__c == metadataSettingExcess.LmtDedCode__c && covLineItem.CoverageLineItemType__c == metadataSettingExcess.CLI_Type_Limit_Option__c){
                                            Decimal excessLimit = covLineItem.Option_Value_Default__c != null ? Decimal.valueOf(covLineItem.Option_Value_Default__c) : 0;// update by Jitendra on 10-Jan-2022 for MAT-80
                                            objWrap.underlyingExcessLimit = excessLimit;
                                        }
                                        if(covLineItem.Coverage__r.Coverage_Code__c == metadataSettingExcess.Coverage_Code__c && covLineItem.Limits_Deductibles__r.LmtDedCode__c == metadataSettingExcess.LmtDedRetentionCode__c && covLineItem.CoverageLineItemType__c == metadataSettingExcess.CLI_Type_Deductible_Option__c){
                                            Decimal excessLimitAttachment = covLineItem.Option_Value_Default__c != null ? Decimal.valueOf(covLineItem.Option_Value_Default__c) : 0;// update by Jitendra on 10-Jan-2022 for MAT-80
                                            objWrap.underlyingExcessAttachment = excessLimitAttachment;
                                        }

                                    }
        }
        //objWrap.baseRate = RatingFactorsHelper.getRatingRangesBaseRate(objQuote.OpportunityId);
        objWrap.listLimitRange = RatingFactorsHelper.getLimitILF();
        objWrap.listRetentionMod = RatingFactorsHelper.getRetentionILF(objQuote.OpportunityId);
        objWrap.commissionAdjustmentFactor = objQuote.Commission_percentage__c != null ? (0.85/ (1-(objQuote.Commission_percentage__c/100))) : 0;
        Decimal policyTerm = objQuote.Effective_Date__c.daysBetween(objQuote.ExpirationDate);
        objWrap.policyPeriodAdjustmentFactor = policyTerm < 365 || policyTerm > 366 ? policyTerm / 365 : 1;
        objWrap.productNames = productNames;
        return objWrap;
        
    }

    @AuraEnabled
    public static String saveRatingModifiers(List<RecordDetails> ratingModifiers, List<OptionalCoverages> listOptionalCoverages, String quoteId, Decimal underlyingExcessLimit, Decimal underlyingExcessAttachment){

        System.debug('strRatingModifiers'+ratingModifiers);
        //List<RecordDetails> ratingModifiers = (List<RecordDetails>)System.JSON.deserialize(strRatingModifiers, List<RecordDetails>.class);
        //System.debug('ratingModifiers'+ratingModifiers);
        String returnMsg = '';
        Quote objQuote = [Select Id, OpportunityId, Total_Premium__c, Underlying_Excess_Limit__c, Underlying_Excess_Attachment__c, Layer__c from Quote where Id =: quoteId];
        List<Rating_Modifier_Factor__c> ratingModifierFactortoUpdate = new List<Rating_Modifier_Factor__c>();
        List<Rating_Modifiers__c> ratingModifiertoUpdate = new List<Rating_Modifiers__c>();
        Map<String,Decimal> mapReqLimit = new Map<String,Decimal>();
        Map<String,Decimal> mapPolRetention = new Map<String,Decimal>();
        Map<String,Decimal> mapExecRetention = new Map<String,Decimal>();
        Map<String, Pre_Rate_Calculator_Setting__mdt> mapMetadataSettings = new Map<String, Pre_Rate_Calculator_Setting__mdt>();
        Pre_Rate_Calculator_Setting__mdt metadataSettingExcess  = new Pre_Rate_Calculator_Setting__mdt();
        for(Pre_Rate_Calculator_Setting__mdt metadataSettings : [Select Id, Active__c,  County_Table_Name__c, Industry_Modifier_Code__c, LimitILF_Table_Name__c, Policy_Retention_Table_Name__c, 
                                                            ProductName__c, SnT_Modifier_Code__c, Order__c, Coverage_Code__c, CLI_Type_Deductible_Option__c, CLI_Type_Limit_Option__c, 
                                                            CLI_Type_Main_Option__c, Exec_Coverage_Code__c, ExecLmtDedCode__c, LmtDedCode__c, LmtDedRetentionCode__c from Pre_Rate_Calculator_Setting__mdt order By Order__c Asc]){
                                                                if(metadataSettings.ProductName__c == 'Excess'){
                                                                    metadataSettingExcess = metadataSettings;
                                                                }
                                                                else{
                                                                    mapMetadataSettings.put(metadataSettings.ProductName__c, metadataSettings);
                                                                }
                                                            }
        try{

            List<CoveragesLineItem__c> covLineItemtoUpdate = new List<CoveragesLineItem__c>();

            for(RecordDetails recDetail : ratingModifiers){
                System.debug('test'+recDetail);
                mapReqLimit.put(recDetail.productName, recDetail.requiredLimit);
                mapPolRetention.put(recDetail.productName, recDetail.policyRetention);
                mapExecRetention.put(recDetail.productName, recDetail.executiveLimit);
                //if(recDetail.productName == 'D&O'){
                    for(Sobject sObj : recDetail.listRatingModifier){
                        Rating_Modifier_Factor__c ratingModFac = (Rating_Modifier_Factor__c)sObj;
                        Rating_Modifier_Factor__c ratingModFactor = new Rating_Modifier_Factor__c();
                        ratingModFactor.Id = ratingModFac.Id;
                        ratingModFactor.Factor_Value__c = ratingModFac.Factor_Value__c;
                        ratingModifierFactortoUpdate.add(ratingModFactor);
                        Rating_Modifiers__c ratingMod = new Rating_Modifiers__c();
                        ratingMod.Id = ratingModFac.Rating_Modifier__c;
                        ratingMod.Rating_Modifier_Value__c = ratingModFac.Rating_Modifier__r.Rating_Modifier_Value__c != null ? ratingModFac.Rating_Modifier__r.Rating_Modifier_Value__c : '';
                        ratingModifiertoUpdate.add(ratingMod);
                    }
                    System.debug('recDetail.listOptionalCoverages'+recDetail.listOptionalCoverages);
                    System.debug('recDetail.listLimitRange'+recDetail.listLimitRange);
                    if(recDetail.listOptionalCoverages != null && !recDetail.listOptionalCoverages.isEmpty()){
                        System.debug('recDetail.listOptionalCoverages'+recDetail.listOptionalCoverages);
                        for(OptionalCoverages objOptCov : recDetail.listOptionalCoverages){
                            if(objOptCov.isCoveraheRequired){
                                covLineItemtoUpdate.addAll((List<CoveragesLineItem__c>)objOptCov.listCoverageLineItems);
                                Rating_Modifier_Factor__c ratingModFac = (Rating_Modifier_Factor__c)objOptCov.optionalRatingModifierFactor;
                                Rating_Modifier_Factor__c ratingModFactor = new Rating_Modifier_Factor__c();
                                ratingModFactor.Id = ratingModFac.Id;
                                ratingModFactor.Factor_Value__c = ratingModFac.Factor_Value__c;
                                ratingModifierFactortoUpdate.add(ratingModFactor);
                                Rating_Modifiers__c ratingMod = new Rating_Modifiers__c();
                                ratingMod.Id = ratingModFac.Rating_Modifier__c;
                                ratingMod.Rating_Modifier_Value__c = ratingModFac.Rating_Modifier__r.Rating_Modifier_Value__c != null ? ratingModFac.Rating_Modifier__r.Rating_Modifier_Value__c : '';
                                ratingModifiertoUpdate.add(ratingMod);
                            }
                        }
                    }
                    if(recDetail.listAdditionalCoverageLineItems != null && !recDetail.listAdditionalCoverageLineItems.isEmpty()){
                        covLineItemtoUpdate.addAll((List<CoveragesLineItem__c>)recDetail.listAdditionalCoverageLineItems);
                    }
                //}
            }

            if(listOptionalCoverages != null && !listOptionalCoverages.isEmpty()){
                
                System.debug('listOptionalCoverages'+listOptionalCoverages);
                for(OptionalCoverages objOptCov : listOptionalCoverages){
                    covLineItemtoUpdate.addAll((List<CoveragesLineItem__c>)objOptCov.listCoverageLineItems);
                    if(objOptCov.optionalRatingModifierFactor != null){
                        Rating_Modifier_Factor__c ratingModFac = (Rating_Modifier_Factor__c)objOptCov.optionalRatingModifierFactor;
                        Rating_Modifier_Factor__c ratingModFactor = new Rating_Modifier_Factor__c();
                        ratingModFactor.Id = ratingModFac.Id;
                        ratingModFactor.Factor_Value__c = ratingModFac.Factor_Value__c;
                        ratingModifierFactortoUpdate.add(ratingModFactor);
                        Rating_Modifiers__c ratingMod = new Rating_Modifiers__c();
                        ratingMod.Id = ratingModFac.Rating_Modifier__c;
                        ratingMod.Rating_Modifier_Value__c = ratingModFac.Rating_Modifier__r.Rating_Modifier_Value__c != null ? ratingModFac.Rating_Modifier__r.Rating_Modifier_Value__c : '';
                        ratingModifiertoUpdate.add(ratingMod);
                    }
                }

            }
    
            
            for(CoveragesLineItem__c covLineItem : [Select Id, Coverage_Premium__c, Coverage_Product__c, Coverage_Product_Combo__c,
                                            CoverageLineItemType__c, Quote__c, Override_Premium__c, Option_Value_Default__c, Coverage__c, 
                                            Coverage__r.Coverage_Code__c, Coverage__r.Coverage_Product__c, 
                                            Coverage__r.Name, Limits_Deductibles__c, Limits_Deductibles__r.Name, Limits_Deductibles__r.LmtDedCode__c 
                                            from CoveragesLineItem__c where Quote__c = : quoteId]){
                                                if(mapReqLimit.containsKey(covLineItem.Coverage_Product_Combo__c) && mapPolRetention.containsKey(covLineItem.Coverage_Product_Combo__c) && mapMetadataSettings.containsKey(covLineItem.Coverage_Product_Combo__c)){
                                                    Pre_Rate_Calculator_Setting__mdt mapMetadataSetting = mapMetadataSettings.get(covLineItem.Coverage_Product_Combo__c);
                                                    if(covLineItem.Coverage__r.Coverage_Code__c == mapMetadataSetting.Coverage_Code__c && covLineItem.Limits_Deductibles__r.LmtDedCode__c == mapMetadataSetting.LmtDedCode__c && covLineItem.CoverageLineItemType__c ==  mapMetadataSetting.CLI_Type_Limit_Option__c){
                                                        covLineItem.Option_Value_Default__c = String.valueOf(mapReqLimit.get(covLineItem.Coverage_Product_Combo__c));
                                                        covLineItemtoUpdate.add(covLineItem);
                                                    }
                                                    if(covLineItem.Coverage__r.Coverage_Code__c == mapMetadataSetting.Coverage_Code__c && covLineItem.Limits_Deductibles__r.LmtDedCode__c == mapMetadataSetting.LmtDedRetentionCode__c && covLineItem.CoverageLineItemType__c == mapMetadataSetting.CLI_Type_Deductible_Option__c){
                                                        covLineItem.Option_Value_Default__c = String.valueOf(mapPolRetention.get(covLineItem.Coverage_Product_Combo__c));
                                                        covLineItemtoUpdate.add(covLineItem);
                                                    }
                                                    /*if(covLineItem.Coverage__r.Coverage_Code__c == mapMetadataSetting.Exec_Coverage_Code__c && covLineItem.Limits_Deductibles__r.LmtDedCode__c == mapMetadataSetting.ExecLmtDedCode__c && covLineItem.CoverageLineItemType__c == mapMetadataSetting.CLI_Type_Limit_Option__c){
                                                        covLineItem.Option_Value_Default__c = String.valueOf(mapExecRetention.get(covLineItem.Coverage_Product_Combo__c));
                                                        covLineItemtoUpdate.add(covLineItem);
                                                    }*/
                                                }
                                                if(objQuote.Layer__c == 'Excess' && metadataSettingExcess != null && underlyingExcessLimit != null && underlyingExcessAttachment != null){
                                                    if(covLineItem.Coverage__r.Coverage_Code__c == metadataSettingExcess.Coverage_Code__c && covLineItem.Limits_Deductibles__r.LmtDedCode__c == metadataSettingExcess.LmtDedCode__c && covLineItem.CoverageLineItemType__c == metadataSettingExcess.CLI_Type_Limit_Option__c){
                                                        covLineItem.Option_Value_Default__c = String.valueOf(underlyingExcessLimit);
                                                        covLineItemtoUpdate.add(covLineItem);
                                                    }
                                                    if(covLineItem.Coverage__r.Coverage_Code__c == metadataSettingExcess.Coverage_Code__c && covLineItem.Limits_Deductibles__r.LmtDedCode__c == metadataSettingExcess.LmtDedRetentionCode__c && covLineItem.CoverageLineItemType__c == metadataSettingExcess.CLI_Type_Deductible_Option__c){
                                                        covLineItem.Option_Value_Default__c = String.valueOf(underlyingExcessAttachment);
                                                        covLineItemtoUpdate.add(covLineItem);
                                                    }
                                                }
    
                    }
                    
            
            if(!ratingModifierFactortoUpdate.isEmpty()){
                System.debug('test1');
                update ratingModifierFactortoUpdate;
            }
            if(!ratingModifiertoUpdate.isEmpty()){
                System.debug('test1');
                update ratingModifiertoUpdate;
            }
            if(!covLineItemtoUpdate.isEmpty()){
                System.debug('test1');
                update covLineItemtoUpdate;
            }
            return 'success';

        }
        catch(exception e){
            return e.getMessage();
        }

    }

    public static Decimal getFormulaExponent(String productName){
        Decimal formulaExponent = 1;
        if(productName == 'D&O'){
            formulaExponent = 0.65;
        }
        else if(productName == 'EPL'){
            formulaExponent = 0.5;
        }
        else if(productName == 'Fiduciary'){
            formulaExponent = 0.52;
        }
        else if(productName == 'Crime'){
            formulaExponent = 0.6;
        }
        return formulaExponent;

    }
    

    public class RelatedListWrapper {
        @AuraEnabled
        public List <RecordDetails> listRecordDetails;
        @AuraEnabled
        public List <sObject> lstRecords;
        @AuraEnabled
        public List <String> lstSelectedProduct;
        @AuraEnabled
        public Map<String, Map<String, RatingFactorsHelper.FactorRange>> factorRangeMap;
        @AuraEnabled
        public RatingFactorsHelper.StateRange stateRange; 
        @AuraEnabled
        public Decimal totalPremium;
        @AuraEnabled
        public Decimal annualRevenue;
        @AuraEnabled
        public Decimal planAssets;
        @AuraEnabled
        public Decimal underlyingExcessLimit;
        @AuraEnabled
        public Decimal underlyingExcessAttachment;
        @AuraEnabled
        public Decimal commissionAdjustmentFactor;
        @AuraEnabled
        public Decimal policyPeriodAdjustmentFactor;
        @AuraEnabled
        public String quoteLayer;
        @AuraEnabled
        public String baseRate;
        @AuraEnabled
        public List<String> productNames;
        @AuraEnabled
        public List<RatingFactorsHelper.LimitILF> listLimitRange; 
        @AuraEnabled
        public List<RatingFactorsHelper.RetentionILF> listRetentionMod;
        @AuraEnabled
        public Quote objQuote;

    }

    public class RecordDetails {
        @AuraEnabled
        public String productName {get;set;}
        @AuraEnabled
        public Boolean isSectionHidden {get;set;}
        @AuraEnabled
        public Boolean isProductDO {get;set;}
        @AuraEnabled
        public Boolean isProductEPL {get;set;}
        @AuraEnabled
        public Boolean isProductFiduciary {get;set;}
        @AuraEnabled
        public Boolean isProductCrime {get;set;}
        @AuraEnabled
        public Boolean isOptionalCoverage {get;set;}
        @AuraEnabled
        public String backgroundColorHeader {get;set;}
        @AuraEnabled
        public Decimal overallRatingModifier {get;set;}
        @AuraEnabled
        public Decimal stateRelativityFactor {get;set;}
        @AuraEnabled
        public Decimal snTModifier {get;set;}
        @AuraEnabled
        public Decimal industryMod {get;set;}
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
        public Decimal actualPremiumWOOptionalCoverage{get;set;}
        @AuraEnabled
        public Decimal limitfactor{get;set;}
        @AuraEnabled
        public Decimal exelimitfactor{get;set;}
        @AuraEnabled
        public Decimal retentionFactor{get;set;}
        @AuraEnabled
        public Decimal baseRate;
        @AuraEnabled
        public Decimal cLRF;
        @AuraEnabled
        public EPLEmployeeDetails employeeDetails{get;set;}
        @AuraEnabled
        public PremiumCalculatorSetting metadataSetting{get;set;}
        @AuraEnabled
        public List<SObject> listRatingModifier{get;set;}
        @AuraEnabled
        public List<SObject> listOptionalRatingModifier{get;set;}
        @AuraEnabled
        public List<RatingFactorsHelper.LimitILF> listLimitRange; 
        @AuraEnabled
        public List<RatingFactorsHelper.RetentionILF> listRetentionMod;
        @AuraEnabled
        public List<SObject> listAdditionalCoverageLineItems{get;set;}
        @AuraEnabled
        public List<OptionalCoverages> listOptionalCoverages;
        @AuraEnabled
        public Integer colSize{get;set;}

        public RecordDetails(){
            this.productName = '';
            this.isSectionHidden = false;
            this.isProductDO = false;
            this.isProductEPL = false;
            this.isProductFiduciary = false;
            this.isProductCrime = false;
            this.isOptionalCoverage = false;
            this.backgroundColorHeader = 'slds-accordion__summary slds-box header-background-grey';
            this.overallRatingModifier = 0.0;
            this.stateRelativityFactor = 1;
            this.snTModifier = 0.0;
            //this.requiredLimit = 0.0;
            this.technicalPremium = 0.0;
            //this.policyRetention = 0.0;
            this.actualPremium = 0.0;
            this.limitfactor = 0.0;
            this.exelimitfactor = 0.0;
            this.retentionFactor = 0.0;
            this.colSize = 6;
            employeeDetails = new EPLEmployeeDetails();
            listRatingModifier = new List<Rating_Modifier_Factor__c>();
            listAdditionalCoverageLineItems = new List<CoveragesLineItem__c>();
        }
    }

    public class EPLEmployeeDetails {

        @AuraEnabled
        public Decimal fullTimeEmployee{get;set;}
        @AuraEnabled
        public Decimal partTimeEmployee{get;set;}
        @AuraEnabled
        public Decimal foreignEmployee{get;set;}
        @AuraEnabled
        public Decimal RatableEmployee{get;set;}
        @AuraEnabled
        public List<RatingFactorsHelper.RateableEmployeesTable> listRatableEmployeeFactorTable{get;set;}

    }

    public class PremiumCalculatorSetting {

        @AuraEnabled
        public String productName{get;set;}
        @AuraEnabled
        public String snTModifierCode{get;set;}
        @AuraEnabled
        public String industryModifierCode{get;set;}

    }

    public class OptionalCoverages {

        @AuraEnabled
        public Id coverageId{get;set;}
        @AuraEnabled
        public String coverageCode{get;set;}
        @AuraEnabled
        public String optionalCoverageName{get;set;}
        @AuraEnabled
        public String optionalFactorLabel{get;set;}
        @AuraEnabled
        public Boolean isCoveraheRequired{get;set;}
        @AuraEnabled
        public String strCoveraheRequired{get;set;}
        @AuraEnabled
        public Decimal factorValue{get;set;}
        @AuraEnabled
        public Decimal cLRFAjdustment{get;set;}
        @AuraEnabled
        public List<SObject> listCoverageLineItems{get;set;}
        @AuraEnabled
        public Boolean hasRatingModifier{get;set;}
        @AuraEnabled
        public SObject optionalRatingModifierFactor{get;set;}
        @AuraEnabled
        public Map<String,List<RatingFactorsHelper.WageHourFactor>> mapWHLimitFactor; 
        @AuraEnabled
        public Map<String,List<RatingFactorsHelper.WageHourFactor>> mapWHRetentionFactor; 

        public OptionalCoverages(){
            this.optionalCoverageName = '';
            this.isCoveraheRequired = false;
            this.strCoveraheRequired = 'No';
            this.cLRFAjdustment = 0.0;
            this.factorValue = 0.0;
            this.listCoverageLineItems = new List<SObject>();
            this.hasRatingModifier = false;
        }

    }

}