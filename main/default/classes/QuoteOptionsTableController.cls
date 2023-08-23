public with sharing class QuoteOptionsTableController {
    public QuoteOptionsTableController() {

    }

    @AuraEnabled( cacheable=true )
    public static RelatedListWrapper fetchQuoteOptions(String quoteId){

        RelatedListWrapper objWrapCacheable = new RelatedListWrapper();
        objWrapCacheable = fetchQuoteOptionsNonCacheable(quoteId);
        return objWrapCacheable;

    }

    @AuraEnabled
    public static RelatedListWrapper fetchQuoteOptionsNonCacheable(String quoteId){

        RelatedListWrapper objWrap = new RelatedListWrapper();
        List<RecordDetails> lstRecordDetailsWrapper = new List<RecordDetails>();
        String componentName = 'Quote Console';
        String recordTypeName = 'Aqueous';
        String mainSection = 'Quote Options';
        String taxPercent;
        String annualGrossFee;
        Integer termLength;
        Integer effectiveTermLength;
        List<String> defaultOptionId = new List<String>();

        Quote objQuote = [Select Id, OpportunityId, layer__c,Status, ExpirationDate, Effective_Date__c 
                            , Endorsement_Effective_Date__c, Quote_Type__c, MGA_Commission__c
                            , Parent_Quote__r.Actual_Premium__c, Parent_Quote__r.Broker_Netted_Down_Premium__c
                            , Parent_Quote__r.Fee__c, Parent_Quote__r.NonProrated_Actual_Premium__c, Parent_Quote__r.NonProRated_BNDP__c
                            , Parent_Quote__r.Rate__c  from Quote where Id = :quoteId];
        
        String layerName = objQuote.layer__c;
        String product = 'Professional Indemnity';
        List<SectionSetting__c> sections =  [SELECT Is_Required__c,Profile_Name_for_Read_Only__c,Component__c, Main_Section__c,
                                                 Sub_Section__c,  Custom_Field_Type__c, DisplayType__c,Quote_Layer__c,
                                                 Format__c, Name, Order__c, Source_Field_API__c, Source_Field_Label__c,
                                                 Source_Object__c, Type_Of_Section__c, Criteria__c, Endorsement_Type__c
                                                 FROM  SectionSetting__c
                                                 WHERE Component__c = :componentName
                                                 AND Record_Type__c =: recordTypeName
                                                 AND Main_Section__c =: mainSection
                                                 AND Quote_Layer__c INCLUDES (:layerName)
                                                 AND Active__c = true AND Product__c INCLUDES (:product)
                                                 Order by  Order__c];
        
        Map<String,List<SectionSetting__c>> mapSections = buildMapSections(sections);
        List<SectionSetting__c> mainSects = new List<SectionSetting__c>();
        List<SectionSetting__c> subSects = new List<SectionSetting__c>();
        List<SectionSetting__c> fieldsSections = new List<SectionSetting__c>();
        if(mapSections.containsKey('MainSection'))	mainSects = mapSections.get('MainSection');
        if(mapSections.containsKey('SubSection'))subSects = mapSections.get('SubSection');
        if(mapSections.containsKey('Field')) fieldsSections = mapSections.get('Field');

        
        List<Quote_Option__c> listQuoteOptions = [Select Id, Limit__c, Minimum_Premium__c, Book_Premium__c, Technical_Premium__c
                                                    , Actual_Premium_Annual__c, Broker_Netted_Down_Premium_Annual__c, Fee_Annual__c
                                                    , Technical_Premium_Discretion__c, Final_Discretion__c, Price_Adequacy__c
                                                    , Actual_Premium_Final__c, Broker_Netted_Down_Premium_Final__c, Fee_Final__c
                                                    , Book_Premium_Annual__c, Minimum_Premium_Annual__c, Technical_Premium_Annual__c
                                                    , Bound__c, Selected__c, Option_Type__c, Final_Technical_Premium__c
                                                    , Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c, Override_Fee_Percent__c
                                                    , Technical_Fee__c, IPT__c, Total_Cost_To_Client__c ,Tax_Percent__c, Rate__c, Rate_Change__c
                                                    , Actual_Premium__c, Broker_Netted_Down_Premium__c, Fee__c, Increased_Limit_Factor__c
                                                    , Change_In_Actual_Premium__c, Change_In_Broker_Netted_Down_Premium__c, Change_In_Fee__c
                                                    , IPT_on_Broker_Netted_Down_Premium__c, Change_in_IPT__c, Change_in_Total_Cost_to_Client__c 
                                                    , Netted_Down_Commission_Percent__c, Netted_Down_Commission_Amount__c, Broker_Commission_Percent__c
                                                    , NonProrated_Actual_Premium__c, NonProRated_BNDP__c from Quote_Option__c 
                                                    where Quote__c = :quoteId Order By Option_Type__c Asc, Limit__c Asc];
		System.debug('termLength'+termLength);
        System.debug('taxPercent'+taxPercent);
        List<Factor_Summary__c> listFactorSummary = [Select Id,Code__c,Value__c,Quote__c from Factor_Summary__c where Quote_Option__c in :listQuoteOptions AND Code__c ='Tax Percent'];
        List<Rating_Modifiers__c> listRatingModifier = [Select Id,Rating_Modifier_Code__c,Rating_Modifier_Value__c,Opportunity__c from Rating_Modifiers__c where Opportunity__c = :objQuote.OpportunityId AND Rating_Modifier_Code__c = 'PI0000015'];
        if(!listFactorSummary.isEmpty()){
            System.debug('43');
            taxPercent = listFactorSummary[0].Value__c;
            objWrap.taxPercent = taxPercent;
        }
        if(!listRatingModifier.isEmpty()){
            annualGrossFee = listRatingModifier[0].Rating_Modifier_Value__c;
            objWrap.annualGrossFee = annualGrossFee;
        }
        termLength = objQuote.Effective_Date__c.daysBetween(objQuote.ExpirationDate) + 1;
        if(objQuote.Endorsement_Effective_Date__c != null){
            effectiveTermLength = objQuote.Endorsement_Effective_Date__c.daysBetween(objQuote.ExpirationDate) + 1;
            objWrap.effectiveTermLength = effectiveTermLength;
        }
        objWrap.mgaCommissionPercent = objQuote.MGA_Commission__c;
        objWrap.termLength = termLength;
        objWrap.lstRecords = listQuoteOptions;
        List<Id> listSelectedOptionIds = new List<Id>();
        for(Quote_Option__c objRecord: listQuoteOptions){
            System.debug('objRecord'+objRecord);
            if(objRecord.Selected__c == true){
                System.debug('selected');
                listSelectedOptionIds.add(objRecord.Id);
            }
            if(objRecord.Bound__c){
                objWrap.idOfBoundQuoteOption = objRecord.Id;
            }
            if(layerName == 'Primary'){
                if(objRecord.Limit__c == 1000000){
                    defaultOptionId.add(objRecord.Id);
                }
            }
            else{
                if(objRecord.Limit__c == 5000000){
                    defaultOptionId.add(objRecord.Id);
                }
            }
            RecordDetails objRecordDetailsWrapper = new RecordDetails();
            objRecordDetailsWrapper.fieldId = objRecord.Id;
            objRecordDetailsWrapper.optionType = objRecord.Option_Type__c;
            List<FieldConfigurations> lstFieldDetailsWrapper = new List<FieldConfigurations>();
            for(SectionSetting__c strField: fieldsSections){
                FieldConfigurations objFieldWrapper = new FieldConfigurations();
                objFieldWrapper.fieldLabel = strField.Source_Field_Label__c;
                objFieldWrapper.fieldAPIName = strField.Source_Field_API__c;
                objFieldWrapper.value = objRecord.get(objFieldWrapper.fieldAPIName) == null? '':objRecord.get(objFieldWrapper.fieldAPIName);
                objFieldWrapper.format = strField.Format__c;
                lstFieldDetailsWrapper.add(objFieldWrapper);
            }
            objRecordDetailsWrapper.fieldDetails = lstFieldDetailsWrapper;
            lstRecordDetailsWrapper.add(objRecordDetailsWrapper);
        }
        objWrap.numberOfRecords = lstRecordDetailsWrapper;
        objWrap.quoteStatus = objQuote.Status;
        objWrap.quoteType = objQuote.Quote_Type__c;
        objWrap.quoteLayer = objQuote.layer__c;
        objWrap.priorAP = objQuote.Parent_Quote__r.Actual_Premium__c;
        objWrap.priorBNDP = objQuote.Parent_Quote__r.Broker_Netted_Down_Premium__c;
        objWrap.priorFee = objQuote.Parent_Quote__r.Fee__c;
        objWrap.priorNonProRatedAP = objQuote.Parent_Quote__r.NonProrated_Actual_Premium__c;
        objWrap.priorNonProRatedBNDP = objQuote.Parent_Quote__r.NonProRated_BNDP__c;
        objWrap.priorRate = objQuote.Parent_Quote__r.Rate__c;
        System.debug('listSelectedOptionIds'+listSelectedOptionIds);
        System.debug('defaultOptionId'+defaultOptionId);
        if(!listSelectedOptionIds.isEmpty()){
            objWrap.lstSelectedRecordIds = listSelectedOptionIds;
        }
        else if(listSelectedOptionIds.isEmpty() && !defaultOptionId.isEmpty()){
            objWrap.lstSelectedRecordIds = defaultOptionId;
        }
        return objWrap;
    }

    public static List<Quote_Option__c> calculatePremiumFields(List<Quote_Option__c> listQuoteOptions, Integer intTermLength, Decimal annualGrossFee){

        for(Quote_Option__c objQuoteOption : listQuoteOptions){

            Decimal finaltechPremium,finalAP,finalBNDP,finalFee,annualAP,annualBNDP,annualFee,finalBookPremium
                    ,finalMinPremium,annualBookPremium,annualMinPremium,annualTechPremium,techfee,iPT
                    ,totalCosttoClient,priorAP,priorBNDP,priorFee,changeinAP,changeinBNDP,changeinFee
                    ,changeinIPT,changeinTotalCosttoClient,priorIPT,priorTotalCosttoClient,nonProRatedAP,nonProRatedBNDP;
            Decimal overrideAP,overrideBNDP,overrideFee,percentTPD,percentfinalD,percentPriceAdequacy;
            Decimal termLength = intTermLength;
            Integer taxPercent = objQuoteOption.Tax_Percent__c != null ? Integer.valueOf(objQuoteOption.Tax_Percent__c) : null;
            if(!objQuoteOption.Factor_Summary_Items__r.isEmpty()){
                taxPercent = Integer.valueOf(objQuoteOption.Factor_Summary_Items__r[0].Value__c);
            }
            String quoteType = objQuoteOption.Quote__r.Quote_Type__c;
            Decimal brokerCommissionPercent = objQuoteOption.Quote__r.Commission_percentage__c;
            Decimal mgaCommissionPercent = objQuoteOption.Quote__r.MGA_Commission__c;
            Decimal nDCPercent,nDCAmount,nDMGACPercent,nDMGACAmount,brokerComAmount = 0,mgaComAmount = 0,diffAPnBNDP = 0,increasedLimitFactor = 0,rate = 0,priorRate = 0,rateChange = 0;
            
            finaltechPremium = objQuoteOption.Technical_Premium__c;
            finalAP = objQuoteOption.Actual_Premium_Final__c;
            finalBNDP = objQuoteOption.Broker_Netted_Down_Premium_Final__c;
            nonProRatedAP = objQuoteOption.NonProrated_Actual_Premium__c;
            nonProRatedBNDP = objQuoteOption.NonProRated_BNDP__c;
            finalFee = objQuoteOption.Fee_Final__c;
            overrideAP = objQuoteOption.Override_Actual_Premium_Percent__c;
            overrideBNDP = objQuoteOption.OverrideBrokerNettedDownPremiumPercent__c;
            overrideFee = objQuoteOption.Override_Fee_Percent__c;
            annualAP = objQuoteOption.Actual_Premium_Annual__c;
            annualBNDP = objQuoteOption.Broker_Netted_Down_Premium_Annual__c;
            annualFee = objQuoteOption.Fee_Annual__c;
            finalBookPremium = objQuoteOption.Book_Premium__c;
            finalMinPremium = objQuoteOption.Minimum_Premium__c;
            annualBookPremium = objQuoteOption.Book_Premium_Annual__c;
            annualMinPremium = objQuoteOption.Minimum_Premium_Annual__c;
            annualTechPremium = objQuoteOption.Technical_Premium_Annual__c;
            percentTPD = objQuoteOption.Technical_Premium_Discretion__c;
            percentfinalD = objQuoteOption.Final_Discretion__c;
            percentPriceAdequacy = objQuoteOption.Price_Adequacy__c;
            techfee = objQuoteOption.Technical_Fee__c;
            iPT = objQuoteOption.IPT__c;
            totalCosttoClient = objQuoteOption.Total_Cost_To_Client__c;
            priorAP = objQuoteOption.Quote__r.Parent_Quote__r.Actual_Premium__c;
            priorBNDP = objQuoteOption.Quote__r.Parent_Quote__r.Broker_Netted_Down_Premium__c;
            priorFee = objQuoteOption.Quote__r.Parent_Quote__r.Fee__c;
            priorIPT = objQuoteOption.Quote__r.Parent_Quote__r.IPT_on_Broker_Netted_Down_Premium__c;
            priorTotalCosttoClient = objQuoteOption.Quote__r.Parent_Quote__r.Total_Cost_To_Client__c;
            changeinAP = objQuoteOption.Change_In_Actual_Premium__c;
            changeinBNDP = objQuoteOption.Change_In_Broker_Netted_Down_Premium__c;
            changeinFee = objQuoteOption.Change_In_Fee__c;
            changeinIPT = objQuoteOption.Change_in_IPT__c;
            changeinTotalCosttoClient = objQuoteOption.Change_in_Total_Cost_to_Client__c;
            nDCPercent = objQuoteOption.Netted_Down_Commission_Percent__c;
            nDCAmount = objQuoteOption.Netted_Down_Commission_Amount__c;
            nDMGACPercent = objQuoteOption.Netted_Down_MGA_Commission_Percent__c;
            nDMGACAmount = objQuoteOption.Netted_Down_MGA_Commission_Amount__c;
            increasedLimitFactor = objQuoteOption.Increased_Limit_Factor__c;
            //rate = objQuoteOption.Rate__c;
            priorRate = objQuoteOption.Quote__r.Parent_Quote__r.Rate__c;
            rateChange = objQuoteOption.Rate_Change__c != null ? objQuoteOption.Rate_Change__c : 0;
            
			System.debug('finalAP'+finalAP);
            /*Double tenPercentfinalAP = finalAP != null ? finalAP*0.1 : null;
            finalBNDP = finalAP != null ? finalAP : finalBNDP;
            if(tenPercentfinalAP != null){
            	finalFee = tenPercentfinalAP > 500 ? 500 : (tenPercentfinalAP < 50 ? 50 : tenPercentfinalAP);
            }*/
            //Calculate Override Premium % and annual Premiums
            if(finaltechPremium != null && nonProRatedAP != null){
                //overrideAP = finaltechPremium > 0 ? finalAP/finaltechPremium*100 : overrideAP;
                annualAP = termLength != null ? nonProRatedAP*(365/termLength) : nonProRatedAP;
                objQuoteOption.Override_Actual_Premium_Percent__c = overrideAP;
            }
            if(nonProRatedBNDP != null && termLength != null){
            	//overrideBNDP =  finalAP > 0 ? finalBNDP/finalAP*100 : overrideBNDP;
                System.debug('overrideBNDP'+overrideBNDP);
            	annualBNDP = termLength != null ? nonProRatedBNDP*(365/termLength) : nonProRatedBNDP;
            	System.debug('annualBNDP'+termLength/365);
            }
            if(finalFee != null && termLength != null){
            	//overrideFee = techfee > 0 ? finalFee/techfee*100 : overrideFee;
            	annualFee = termLength != null ? finalFee*(365/termLength) : finalFee;
            }
            
            annualBookPremium = finalBookPremium != null ? finalBookPremium*(365/termLength) : annualBookPremium;
            annualMinPremium = finalMinPremium != null ? finalMinPremium*(365/termLength) : annualMinPremium;
            annualTechPremium = finaltechPremium != null ? finaltechPremium*(365/termLength) : annualTechPremium;
            //calculate discretion percents
            percentTPD = annualTechPremium != null && annualBookPremium!= null ? annualTechPremium/annualBookPremium*100 : percentTPD;
            percentfinalD = annualAP != null && annualBookPremium != null ? annualAP/annualBookPremium*100 : percentfinalD;
            percentPriceAdequacy = annualAP != null && annualTechPremium != null ? annualAP/annualTechPremium*100 : percentPriceAdequacy;
            if(taxPercent != null && finalBNDP != null){
                iPT = iPT == null ? taxPercent * finalBNDP /100 : iPT;
                System.debug('totalCosttoClient1'+totalCosttoClient);
                totalCosttoClient = totalCosttoClient == null ? finalBNDP + iPT + finalFee : totalCosttoClient;
               	System.debug('totalCosttoClient2'+totalCosttoClient);

            }

            if(quoteType == 'New Business' || quoteType == 'Renewal'){
                changeinAP = finalAP != null ? finalAP : changeinAP;
                changeinBNDP = finalBNDP != null ? finalBNDP : changeinBNDP;
                changeinFee = finalFee != null ? finalFee : changeinFee;
                changeinIPT = iPT != null ? iPT : changeinIPT;
                changeinTotalCosttoClient = totalCosttoClient != null ? totalCosttoClient : changeinTotalCosttoClient;

                if(brokerCommissionPercent != null && finalAP != null && finalBNDP != null){
                    brokerComAmount = finalAP != null ? brokerCommissionPercent * finalAP /100 : 0;
                    diffAPnBNDP = finalAP - finalBNDP;
                    nDCAmount = brokerComAmount - diffAPnBNDP;
                    nDCPercent = finalBNDP != null && finalBNDP != 0 && nDCAmount>= 0 ? nDCAmount / finalBNDP * 100 : 0;
                }

                if(mgaCommissionPercent != null && finalAP != null && finalBNDP != null){
                    mgaComAmount = finalAP != null ? mgaCommissionPercent * finalAP /100 : 0;
                    diffAPnBNDP = finalAP - finalBNDP;
                    nDMGACAmount = mgaComAmount - diffAPnBNDP;
                    nDMGACPercent = finalBNDP != null && finalBNDP != 0 && nDMGACAmount >= 0 ? nDMGACAmount / finalBNDP * 100 : 0;
                }

                if(annualAP != null && increasedLimitFactor != null && annualGrossFee != null){
                    rate = ((annualAP / increasedLimitFactor) / annualGrossFee) * 100;
                    if(quoteType == 'Renewal'){
                        rateChange = rate != null && priorRate != null && priorRate != 0 ? ((rate - priorRate) / priorRate ) * 100 : 0;
                    }
                }

                /*changeinAP = finalAP;
                changeinBNDP = finalBNDP;
                changeinFee = finalFee; */
            }
            if(quoteType == 'Full Amendment' || quoteType == 'Coverage Amendment' || quoteType == 'Midterm Cancellation'
            || quoteType == 'Flat Cancellation' || quoteType == 'Reinstatement' || quoteType == 'Policy Duration Change'){
                changeinAP = (finalAP != null && priorAP != null) ? finalAP - priorAP : 0;
                changeinBNDP = (finalBNDP != null && priorBNDP != null) ? finalBNDP - priorBNDP : 0;
                changeinFee = (finalFee != null && priorFee != null) ? finalFee - priorFee : 0;
                changeinIPT = (taxPercent != null && changeinBNDP != null) ?  taxPercent * changeinBNDP /100 : 0;
                changeinTotalCosttoClient = (changeinIPT != null || changeinBNDP != null || changeinFee != null) ? changeinBNDP + changeinIPT + changeinFee : 0;
                
                if(brokerCommissionPercent != null && changeinAP != null && changeinBNDP != null){
                    brokerComAmount = brokerCommissionPercent * changeinAP /100;
                    diffAPnBNDP = changeinAP - changeinBNDP;
                    nDCAmount = brokerComAmount - diffAPnBNDP;
                    nDCPercent = changeinBNDP != 0 && nDCAmount >= 0 ? nDCAmount / changeinBNDP * 100 : 0;
                }

                if(mgaCommissionPercent != null && changeinAP != null && changeinBNDP != null){
                    mgaComAmount = mgaCommissionPercent * changeinAP /100;
                    diffAPnBNDP = changeinAP - changeinBNDP;
                    nDMGACAmount = mgaComAmount - diffAPnBNDP;
                    nDMGACPercent = changeinBNDP != 0 && nDMGACAmount >= 0 ? nDMGACAmount / changeinBNDP * 100 : 0;
                }

                if(annualAP != null && increasedLimitFactor != null){
                    rate = (annualAP * increasedLimitFactor) / annualGrossFee;
                    //rateChange = ((rate - priorRate) / priorRate ) * 100;
                }

                /*changeinAP = finalAP - priorAP;
                changeinBNDP = finalBNDP - priorBNDP;
                changeinFee = finalFee - priorFee;  */
            }
            
            objQuoteOption.Book_Premium_Annual__c = annualBookPremium != null ? annualBookPremium.setScale(2) : annualBookPremium;
            objQuoteOption.Minimum_Premium_Annual__c = annualMinPremium != null ? annualMinPremium.setScale(0) : annualMinPremium;
            objQuoteOption.Technical_Premium_Annual__c = annualTechPremium != null ? annualTechPremium.setScale(2) : annualTechPremium;
            objQuoteOption.Override_Actual_Premium_Percent__c = overrideAP;
            objQuoteOption.OverrideBrokerNettedDownPremiumPercent__c = overrideBNDP;
            objQuoteOption.Override_Fee_Percent__c = overrideFee;
            objQuoteOption.Actual_Premium_Annual__c = annualAP != null ? annualAP.setScale(2) : annualAP;
            objQuoteOption.Broker_Netted_Down_Premium_Annual__c = annualBNDP != null ? annualBNDP.setScale(2) : annualBNDP;
            objQuoteOption.Fee_Annual__c = annualFee != null ? annualFee.setScale(2) : annualFee;
            objQuoteOption.Technical_Premium_Discretion__c = percentTPD;
            objQuoteOption.Final_Discretion__c = percentfinalD;
            objQuoteOption.Price_Adequacy__c = percentPriceAdequacy;
            objQuoteOption.IPT__c = iPT;
            objQuoteOption.Total_Cost_To_Client__c = totalCosttoClient;
            objQuoteOption.Change_In_Actual_Premium__c = changeinAP != null ? changeinAP.setScale(2) : changeinAP;
            objQuoteOption.Change_In_Broker_Netted_Down_Premium__c = changeinBNDP != null ? changeinBNDP.setScale(2) : changeinBNDP;
            objQuoteOption.Change_In_Fee__c = changeinFee != null ? changeinFee.setScale(2) : changeinFee;
            objQuoteOption.Change_in_IPT__c = changeinIPT;
            objQuoteOption.Change_in_Total_Cost_to_Client__c = changeinTotalCosttoClient;
            objQuoteOption.Netted_Down_Commission_Percent__c = nDCPercent;
            objQuoteOption.Netted_Down_Commission_Amount__c = nDCAmount;
            objQuoteOption.Netted_Down_MGA_Commission_Percent__c = nDMGACPercent;
            objQuoteOption.Netted_Down_MGA_Commission_Amount__c = nDMGACAmount;
            objQuoteOption.Rate__c = rate.setScale(5);
            objQuoteOption.Rate_Change__c = rateChange.setScale(5);
			

        }

        return listQuoteOptions;

    }

    /*@AuraEnabled( cacheable=true )
    public static quoteTableWrapper fetchTaxPercent(String quoteId, String code){
        quoteTableWrapper objWrapper = new quoteTableWrapper();
        String taxPercent;
        Integer termLength;
        try {
            taxPercent = [Select Id,Code__c,Value__c,Quote__c from Factor_Summary__c where Quote__c = :quoteId AND Code__c = :code].Value__c;
            Quote objQuote = [Select Id , ExpirationDate, Effective_Date__c from Quote where Id = :quoteId ];
            termLength = objQuote.ExpirationDate.daysBetween(objQuote.Effective_Date__c);
            objWrapper.taxPercent = taxPercent;
            objWrapper.termLength = termLength;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return objWrapper;
    }*/

    /*public static String saveFreeFormOptions(RecordDetails recDetailWrapper){

        try{

            String quoteOptionId = recDetailWrapper.fieldId;

            Quote_Option__c objQuoteOption = [Select Id, Limit__c, Minimum_Premium__c, Book_Premium__c, Technical_Premium__c
                                                , Actual_Premium_Annual__c, Broker_Netted_Down_Premium_Annual__c, Fee_Annual__c
                                                , Technical_Premium_Discretion__c, Final_Discretion__c, Price_Adequacy__c
                                                , Actual_Premium_Final__c, Broker_Netted_Down_Premium_Final__c, Fee_Final__c
                                                , Bound__c, Selected__c, Option_Type__c from Quote_Option__c 
                                                where Id = :quoteOptionId];
            
            for(FieldConfigurations objfield : recDetailWrapper.fieldDetails){
                objQuoteOption.get(objfield.fieldAPIName) = objfield.value;
            }

            update objQuoteOption;

            return 'success';
        }
        catch(exception e){
            return e;
        }

    }*/
    
    @AuraEnabled
    public static String saveQuoteOptions(List<SObject> listQuoteOptions,string quoteId,Integer selectedRows){
        String returnMsg = '';
        Quote quote = new Quote();
        List<Quote_Option__c> listQuoteOptionsToUpdate = (List<Quote_Option__c>)listQuoteOptions;
        List<Quote_Option__c> quoteOptionList = new List<Quote_Option__c>();
        try{
            //New
            Integer oldSize = 0;
            Boolean isChangeQuoteOption = false;
            if(SelectedRows != null){
                quoteOptionList =  [Select Id, Quote__c,Selected__c FROM Quote_Option__c where Quote__c =:quoteId AND Selected__c = true];
                
                if(!quoteOptionList.isEmpty()){
                    oldSize = quoteOptionList.size();
                } 
                system.debug('oldSize::'+oldSize);
                system.debug('SelectedRows::'+SelectedRows);
                if(quoteId != '' && oldSize != SelectedRows){
                    quote = [Select Id, Status FROM Quote where Id =:quoteId];
                    if(quote.Status!='In Progress' && quote!=null){
                        quote.Status = 'In Progress';
                        isChangeQuoteOption = true;
                    } 
                }
            }
            
            if(!listQuoteOptions.isEmpty()){
                update listQuoteOptionsToUpdate;
                returnMsg = 'success';
            }
            
            if(isChangeQuoteOption){
                update quote;
                returnMsg = 'quoteupdate';
            }
            
            return returnMsg;
        }
        catch(exception e){
            return e.getMessage();
        }
    }

    /*********  Change quote Stage if selected Rows is 0 ticket 51668  ********/
    @AuraEnabled
    public static String saveQuoteStatus(string quoteId){
        String returnMsg = '';
        Boolean isChangeQuoteOption = false;
        Quote quote = new Quote();
        if(quoteId != ''){
            quote = [Select Id, Status FROM Quote where Id =:quoteId];
            if(quote.Status!='In Progress' && quote!=null){
                quote.Status = 'In Progress';
                isChangeQuoteOption = true;
            } 
        }
        if(isChangeQuoteOption){
            update quote;
            returnMsg = 'quoteupdate';
        }
        
        return returnMsg;


    }


    @AuraEnabled
    public static String deleteQuoteOptions(String optionId){
        try {

            
            List<Quote_Option__c> listQuoteOption = [Select Id, Limit__c, Minimum_Premium__c, Book_Premium__c, Technical_Premium__c
                                                    , Actual_Premium_Annual__c, Broker_Netted_Down_Premium_Annual__c, Fee_Annual__c
                                                    , Technical_Premium_Discretion__c, Final_Discretion__c, Price_Adequacy__c
                                                    , Actual_Premium_Final__c, Broker_Netted_Down_Premium_Final__c, Fee_Final__c
                                                    , Bound__c, Selected__c, Option_Type__c, Final_Technical_Premium__c
                                                    , Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c, Override_Fee_Percent__c
                                                    , Technical_Fee__c, IPT__c, Total_Cost_To_Client__c from Quote_Option__c 
                                                    where Id = :optionId];
            
            if(!listQuoteOption.isEmpty()){
                Quote_Option__c objQuoteOption = new Quote_Option__c();
                objQuoteOption.Id = listQuoteOption[0].Id;
                if(listQuoteOption[0].Limit__c != null){
                    objQuoteOption.Limit__c = null;
                }
                objQuoteOption.Selected__c = false;
                objQuoteOption.Bound__c = false;
                objQuoteOption.Option_Type__c = listQuoteOption[0].Option_Type__c;
                update objQuoteOption;

            }
            return 'success';
            
        } catch (Exception e) {
            return e.getMessage();
        }
    }

    public static Map<String,List<SectionSetting__c>> buildMapSections(List<SectionSetting__c> sections ) {
        
        Map<String,List<SectionSetting__c>> results = new Map<String,List<SectionSetting__c>>();
        for(SectionSetting__c item : sections) {
            String key = item.Type_Of_Section__c;
            if(results.containsKey(key)){
                results.get(key).add(item);
            }else{
                results.put(key,new List<SectionSetting__c>{item});
            }
        }
        
        return results;
    }

    public class quoteTableWrapper{
        @AuraEnabled
        public Integer termLength;
        @AuraEnabled
        public String taxPercent;

    }

    public class RelatedListWrapper {
        @AuraEnabled
        public List <SObject> lstRecords;
        @AuraEnabled
        public List <Id> lstSelectedRecordIds;
        @AuraEnabled
        public Id idOfBoundQuoteOption;
        @AuraEnabled
        public Integer recordCount;
        @AuraEnabled
        public List<RecordDetails> numberOfRecords;
        @AuraEnabled
        public Integer termLength;
        @AuraEnabled
        public Integer effectiveTermLength;
        @AuraEnabled
        public Decimal mgaCommissionPercent;
        @AuraEnabled
        public String taxPercent;
        @AuraEnabled
        public String annualGrossFee;
        @AuraEnabled
        public String quoteStatus;
        @AuraEnabled
        public String quoteType;
        @AuraEnabled
        public String quoteLayer;
        @AuraEnabled
        public Double priorAP;
        @AuraEnabled
        public Double priorBNDP;
        @AuraEnabled
        public Double priorFee;
        @AuraEnabled
        public Double priorNonProRatedAP;
        @AuraEnabled
        public Double priorNonProRatedBNDP;
        @AuraEnabled
        public Double priorRate;
    }

    public class RecordDetails {
        @AuraEnabled
        public String fieldId;
        @AuraEnabled
        public String optionType;
        @AuraEnabled
        public List<FieldConfigurations> fieldDetails;
    }
    
    public class FieldConfigurations {
        @AuraEnabled
        public String fieldLabel;
        @AuraEnabled
        public String fieldAPIName;
        @AuraEnabled
        public Object value;
        @AuraEnabled
        public String format;
    }

}