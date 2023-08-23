import StayInTouchSubject from '@salesforce/schema/User.StayInTouchSubject';
import { LightningElement,api,track } from 'lwc';

export default class OptionalCoverageLWC extends LightningElement {

    @api optionalCoverages;
    @api recordDetail;
    @api productName;
    @api ratingModifierFactor;
    @api ratingModifier;
    @api listCoverageLineItems;
    @api factorRangeMap;
    @api fieldName;
    @api cLRF;
    @api range;
    @api rangeLower;
    @api rangeUpper;
    @api factorValue = 0.0;
    @api isText;
    @api isLongText;
    @api isPicklist;
    @api isAddress;
    @api isLookup;
    @api isDate;
    @api isDateTime;
    @api isNumber;
    @api isCurrency;
    @api isPercent;
    @api isHyperlink;
    @api isInteger;
    @api isUndefined;
    @api isDOExecCoverage = false;
    @api optionalLoading = 0.0;
    @api readOnly = false;
    @api options = [];
    @api limitfactor;
    @api listLimitRange;
    @api listRetentionMod;
    @api cLRFAjdustment;
    @api cLRFAjdustmentLabel = 'CLRF Adjustment';
    @api commissionAdjustmentFactor = 1;
    @api policyPeriodAdjustmentFactor = 1;
    @api optionalFactorLabel;
    @api selectedRateLabel = 'Selected rate if required';

    _format;
    set format(value) {
        this.setAllFormatFalse();
        console.log('value'+value);
        this._format = value;
        if(this._format == 'Text' ) {
            this.isText = true;
        }
        if(this._format == 'Range') {
            this.isRange = true;
        }
        if(this._format == 'Long Text') {
            this.isText = true;
        }
        if(this._format == 'Picklist') {
            this.isPicklist = true;
        }
        if(this._format == 'Lookup') {
            this.isLookup = true;
        }
        if(this._format == 'Address') {
            this.isAddress = true;
        }
        if(this._format == 'Date') {
            this.isDate = true;
        }
        if(this._format == 'DateTime') {
            this.isDateTime = true;
        }
        
        if(this._format == 'Number') {
            this.isNumber = true;
        }
        if(this._format == 'Currency') {
            this.isCurrency = true;
        }
        if(this._format == 'Percentage') {
            this.isPercent = true;
        }
        if(this._format == 'Hyperlink'){
            this.isHyperlink = true;
        }
        if(this._format == 'Integer') {
            this.isInteger = true;
        }
        if(!this._format){
            this.isUndefined = true
        }
        console.log('format'+this._format);
        console.log('isText'+this.isText);
        console.log('isPicklist'+this.isPicklist);
    }

    @api get format() {
        return this._format;
    }

    setAllFormatFalse() {
        this.isText = false;
        this.isNumber = false;
        this.isLongText = false;
        this.isPicklist = false;
        this.isAddress = false;
        this.isLookup = false;
        this.isDate = false;
        this.isDateTime = false;
        this.isCurrency = false;
        this.isPercent = false;
        this.isHyperlink = false;
        this.isInteger = false;
    }

    connectedCallback() {
        console.log('in Connected Callback');
        var format;
        var optionalCoverages = JSON.parse(JSON.stringify(this.optionalCoverages));
        this.cLRFAjdustment = optionalCoverages.cLRFAjdustment;
        this.optionalFactorLabel = optionalCoverages.optionalFactorLabel;
        if(optionalCoverages.optionalRatingModifierFactor){
            this.ratingModifier = optionalCoverages.optionalRatingModifierFactor.Rating_Modifier__r;
            format = this.ratingModifier.Format__c;
            if(this.ratingModifier.Coverage_Code__c === 'DOExecsCoverage'){
                this.isDOExecCoverage = true;
                this.cLRFAjdustmentLabel = 'Corresponding ILF';
            }
            var fieldName = this.ratingModifier.Name;
            console.log('fieldName-->'+fieldName);
            this.factorValue = this.ratingModifierFactor.Factor_Value__c;
            console.log('Rating_Modifier_Value__c'+this.ratingModifier.Rating_Modifier_Value__c);
            if(this.ratingModifier.Rating_Modifier_Value__c){
                var temp = this.ratingModifier.Rating_Modifier_Value__c;
                var ratingModVal = temp.replace(',','');
                console.log('ratingModVal',ratingModVal)
                var tempCode = this.ratingModifier.Rating_Reference_Name__c;
                console.log('tempCode',tempCode)
                if(tempCode){
                    if(ratingModVal){
                        if(tempCode === 'EPL_PctEmployeesInCA'){
                            if(parseFloat(ratingModVal) < 10){
                                var Range_Lower = "1.00";
                                var Range_Upper = "1.10";
                            }
                            else if(parseFloat(ratingModVal) >= 10 && parseFloat(ratingModVal) < 50){
                                var Range_Lower = "1.10";
                                var Range_Upper = "1.50";
                            }
                            else if(parseFloat(ratingModVal) >= 50){
                                var Range_Lower = "1.50";
                                var Range_Upper = "2.00";
                            }
                            this.rangeLower = Range_Lower;
                            this.rangeUpper = Range_Upper;
                            this.range = Range_Lower + ' - ' +Range_Upper;
                        }
                        else{
                        
                            var factorRangeMap =this.factorRangeMap[tempCode];
                            var factorRange = factorRangeMap[ratingModVal];
                            if(factorRange){
                                var Range_Lower = factorRange.Range_Lower;
                                var Range_Upper = factorRange.Range_Upper;
                                this.rangeLower = Range_Lower;
                                this.rangeUpper = Range_Upper;
                                this.range = Range_Lower + ' - ' +Range_Upper;
                            }
                        }
                    }
                }
                this.fieldName = fieldName;
                var strPicklistOption = this.ratingModifier.Picklist_Values__c;
                if(strPicklistOption){
                    var optionsArr = strPicklistOption.split(";");
                    optionsArr.forEach(key =>{
                        //var value = key.replace(',','');  
                        this.options.push({label : key, value : key});
                    });
                }
            }
            else{
                
                if(this.ratingModifier.Rating_Reference_Name__c){
                    var tempCode = this.ratingModifier.Rating_Reference_Name__c;
                    var factorRangeMap =this.factorRangeMap[tempCode];
                    var factorRange = Object.values(factorRangeMap);
                    console.log('factorRange-->'+factorRange);
                    console.log('factorRange-->'+factorRange.length);
                    if(factorRange.length === 1){
                        var Range_Lower = factorRange[0].Range_Lower;
                        var Range_Upper = factorRange[0].Range_Upper;
                        this.rangeLower = Range_Lower;
                        this.rangeUpper = Range_Upper;
                        this.range = Range_Lower + ' - ' +Range_Upper;
                    }
                    else{
                        if(this.ratingModifier.Sub_Section__c === 'Optional Factors'){
                            var listCoverageLineItems = JSON.parse(JSON.stringify(this.optionalCoverages.listCoverageLineItems));
                            listCoverageLineItems.forEach(item=>{
                                if(item.Coverage__r.Coverage_Code__c === this.ratingModifier.Coverage_Code__c){
                                    if(item.Option_Value_Default__c){
                                        var factorRange = factorRangeMap[item.Option_Value_Default__c];
                                        if(factorRange){
                                            var Range_Lower = factorRange.Range_Lower;
                                            var Range_Upper = factorRange.Range_Upper;
                                            this.rangeLower = Range_Lower;
                                            this.rangeUpper = Range_Upper;
                                            this.range = Range_Lower + ' - ' +Range_Upper;
                                            fieldName = 'Selected rate if required';
                                            this.factorValue = parseFloat(Range_Upper) > 0 ? (parseFloat(Range_Upper) + parseFloat(Range_Lower)) / 2 : 0;

                                        }
                                    }
                                }
                            });
                        }
                    }
                }
                this.fieldName = fieldName;

            }

        }
        this.calculateOptionalCLIValueChange(optionalCoverages.listCoverageLineItems[0],this.productName,false);
        this.format = format;
        /*var format = this.ratingModifier.Format__c;
        if(format){
            this.format = format;
            console.log('format-->'+format);
            console.log('this.format'+this.format);
        }*/
        
         
    }

    handleChangeInput(event){

        var optionValue = event.target.value;
        optionValue = optionValue.trim();
        console.log('optionValue'+optionValue);
        var optionalCoverages = JSON.parse(JSON.stringify(this.optionalCoverages));
        var ratingModifier = optionalCoverages.optionalRatingModifierFactor.Rating_Modifier__r;
        var tempCode = ratingModifier.Rating_Reference_Name__c;
        var Range_Lower;
        var Range_Upper;
        if(tempCode){
            var factorRangeMap =this.factorRangeMap[tempCode];
            var factorRange = factorRangeMap[optionValue];
            if(factorRange){
                Range_Lower = factorRange.Range_Lower;
                Range_Upper = factorRange.Range_Upper;
                this.rangeLower = Range_Lower;
                this.rangeUpper = Range_Upper;
                this.range = Range_Lower + ' - ' +Range_Upper;
            }
        }
        ratingModifier.Rating_Modifier_Value__c = optionValue;
        this.ratingModifier = ratingModifier;

        let factorCmp = this.template.querySelector(".factorCmp");
        let factorCmpValue = factorCmp.value;
        console.log(factorCmpValue);
        if(factorCmpValue > Range_Upper){
            console.log('1'+Range_Upper);
            factorCmp.setCustomValidity("The number is too high.");
        }
        else if(factorCmpValue < Range_Lower){
            console.log('2'+Range_Upper);
            factorCmp.setCustomValidity("The number is too low.");
        }
        else{
            console.log('3'+factorCmpValue);
            factorCmp.setCustomValidity("");
        }
        factorCmp.reportValidity();

        const editldEvt = new CustomEvent(
            "optionalfactorvaluechange", {
            detail: {
                optionalCoverages : this.optionalCoverages,
                productName : this.productName,
                reCalculatePremium : true
            },
        });
        this.dispatchEvent(editldEvt);
        
    }

    handleChangeFactorValue(event){

        var optionalLoading = 0.0;
        var factorValue = event.target.value;
        console.log('factorValue'+factorValue);
        var optionalCoverages = JSON.parse(JSON.stringify(this.optionalCoverages));
        if(optionalCoverages.optionalRatingModifierFactor){
            optionalCoverages.optionalRatingModifierFactor.Factor_Value__c = factorValue;
        }
        let factorCmp = this.template.querySelector(".factorCmp");
        let factorCmpValue = factorCmp.value;
        console.log(factorCmpValue);
        if(factorCmpValue === factorValue && factorCmpValue <= this.rangeUpper && factorCmpValue >= this.rangeLower){
            console.log(this.rangeUpper);
            factorCmp.setCustomValidity("");
        }
        factorCmp.reportValidity();
        if(this.isDOExecCoverage === true){
            var recordDetail = JSON.parse(JSON.stringify(this.recordDetail));
            optionalLoading =this.calculateLoadingforExecLimit(factorValue,recordDetail.limitfactor);
            this.optionalLoading = optionalLoading;
            optionalCoverages.factorValue = optionalLoading;
        }
        else if(optionalCoverages.coverageCode === 'CrimePremises' || optionalCoverages.coverageCode === 'CrimeInTransit'
                || optionalCoverages.coverageCode === 'CrimeForgery' || optionalCoverages.coverageCode === 'CrimeComputerFraud'
                || optionalCoverages.coverageCode === 'CrimeFundsTransferFraud' || optionalCoverages.coverageCode === 'CrimeMoneyOrderFraud'
                || optionalCoverages.coverageCode === 'CrimeCreditCardFraud' || optionalCoverages.coverageCode === 'CrimeClient'
                || optionalCoverages.coverageCode === 'CrimeSocialEngineering'){

                    var limitVal,retentionVal;
                    optionalCoverages.listCoverageLineItems.forEach(item2=>{
                        if(item2.CoverageLineItemType__c === 'Deductible Option'){
                            retentionVal = item2.Option_Value_Default__c;
                        }
                        else if(item2.CoverageLineItemType__c === 'Limit Option'){
                            limitVal = item2.Option_Value_Default__c;
                        }
                    });
                    var recordDetail = JSON.parse(JSON.stringify(this.recordDetail));
                    var limitFactorVal = this.getLimitFactor(limitVal);
                    var retentionFactorVal = this.getRetentionFactor(retentionVal);
                    var cLRFEPL = this.calculateCLRFValue(recordDetail.requiredLimit,recordDetail.policyRetention,recordDetail.limitfactor,recordDetail.retentionFactor);
                    var cLRFVal = cLRFEPL ? this.calculateCLRFValue(limitVal,retentionVal,limitFactorVal,retentionFactorVal) / cLRFEPL : 0;
                    //var overallSchMod = recordDetail.overallRatingModifier;
                    //var overallMod = overallSchMod * recordDetail.snTModifier;
                    var optionalLoading = (factorValue * cLRFVal) / recordDetail.snTModifier;
                    this.optionalLoading = optionalLoading.toFixed(3);
                    optionalCoverages.factorValue = optionalLoading.toFixed(3);

        }
        this.optionalCoverages = optionalCoverages;
        const editldEvt = new CustomEvent(
            "optionalfactorvaluechange", {
            detail: {
                optionalCoverages : this.optionalCoverages,
                productName : this.productName,
                reCalculatePremium : true

            },
        });
        this.dispatchEvent(editldEvt);

    }

    calculateLoadingforExecLimit(value1,value2){

        var factorValue = value1;
        var ratingModifier = JSON.parse(JSON.stringify(this.ratingModifier));
        var limitFactor = value2;
        var execILF = this.cLRF;
        //var execFactor = this.execFactor;
        var optionalLoading = limitFactor && limitFactor > 0 ? (factorValue * execILF) / limitFactor : 0;
        this.optionalLoading = optionalLoading.toFixed(3);
        //this.calculatePremium(productName);

        return optionalLoading;
    }

    @api
    handleratingFactorValue(value1,value2){

        var optionalLoading = 0.0;
        console.log('test');
        var coverageLineItem = value1;
        this.cLRF = value2;
        var factorValue = 0;
        if(coverageLineItem.Coverage__r.Coverage_Code__c === this.ratingModifier.Coverage_Code__c){
            var tempCode = this.ratingModifier.Rating_Reference_Name__c;
            //if(factorRangeMap.has(coverageLineItem.Option_Value_Default__c)){
                console.log('factorRangeMap'+this.factorRangeMap);
                //console.log('factorRangeMap'+this.factorRangeMap.keys());
                //console.log('factorRangeMap'+this.factorRangeMap.has(coverageLineItem.Option_Value_Default__c));
                var factorRangeMap = JSON.parse(JSON.stringify(this.factorRangeMap));
                var factorRange = factorRangeMap[tempCode];
                console.log('factorRange'+factorRange);
                console.log('factorRange'+factorRange[coverageLineItem.Option_Value_Default__c]);
                var factorRangeValue = factorRange[coverageLineItem.Option_Value_Default__c];
                if(factorRangeValue){
                    var Range_Lower = factorRangeValue.Range_Lower;
                    var Range_Upper = factorRangeValue.Range_Upper;
                    this.rangeLower = Range_Lower;
                    this.rangeUpper = Range_Upper;
                    this.range = Range_Lower + ' - ' +Range_Upper;
                    this.factorValue = factorValue = parseFloat(Range_Upper) > 0 ? (parseFloat(Range_Upper) + parseFloat(Range_Lower)) / 2 : 0;
                    //optionalLoading = this.calculateLoadingforExecLimit(this.factorValue);
                }
           // }
        }
        return factorValue;
    }

    handleOptionalCLIValueChange(event){
        
        var coverageLineItem = JSON.parse(JSON.stringify(event.detail.coverageLineItem));
        var productName = JSON.parse(JSON.stringify(event.detail.productName));
        var optionalCoverageName = JSON.parse(JSON.stringify(event.detail.optionalCoverageName));
        console.log('coverageLineItem'+coverageLineItem);
        this.calculateOptionalCLIValueChange(coverageLineItem,productName,true);
        

    }

    @api
    handleCalculateOptionalCLIValueChange(value1,value2,value3){

        this.recordDetail = JSON.parse(JSON.stringify(value1));
        var optionalCoverages = JSON.parse(JSON.stringify(this.optionalCoverages));
        optionalCoverages.listCoverageLineItems.forEach(covItem=>{
            this.calculateOptionalCLIValueChange(covItem,value2,value3);
        });

    }

    calculateOptionalCLIValueChange(value1,value2,value3){

        var coverageLineItem = value1;
        var productName = value2;
        var isUpdate = value3;
        var optionValueDefault;
        var cILF;
        var factorValue = 0;

        var optionalCoverages = JSON.parse(JSON.stringify(this.optionalCoverages));
        if(optionalCoverages.listCoverageLineItems.length === 1){
            var cLItem = optionalCoverages.listCoverageLineItems[0];
            console.log('cLItem'+cLItem);
            if(cLItem.Id === coverageLineItem.Id){
                cLItem.Option_Value_Default__c = coverageLineItem.Option_Value_Default__c;
                optionValueDefault = parseFloat(coverageLineItem.Option_Value_Default__c);
                if(optionalCoverages.hasRatingModifier === false){
                    if(coverageLineItem.Coverage__r.Coverage_Code__c === 'EPLClassRetentionCoverage'){
                        var recordDetail = JSON.parse(JSON.stringify(this.recordDetail));
                        var retentionFactorMC = this.getRetentionFactor(optionValueDefault);
                        var cLRFEPL = this.calculateCLRFValue(recordDetail.requiredLimit,recordDetail.policyRetention,recordDetail.limitfactor,recordDetail.retentionFactor);
                        var cLRFMC = this.calculateCLRFValue(recordDetail.requiredLimit,optionValueDefault,recordDetail.limitfactor,retentionFactorMC);
                        factorValue = ( 0.6 * cLRFEPL + 0.4 * cLRFMC ) / cLRFEPL;
                        this.factorValue = factorValue.toFixed(3);
                        optionalCoverages.factorValue = factorValue.toFixed(3);

                    }
                    if(coverageLineItem.Coverage__r.Coverage_Code__c === 'CrimeExpense'){
                        var recordDetail = JSON.parse(JSON.stringify(this.recordDetail));
                        var limitFactorExpense = this.getLimitFactor(optionValueDefault);
                        var cLRF = this.calculateCLRFValue(recordDetail.requiredLimit,recordDetail.policyRetention,recordDetail.limitfactor,recordDetail.retentionFactor);
                        var aggCLRF = 0;
                        recordDetail.listOptionalCoverages.forEach(itemOptCov=>{
                            if(itemOptCov.coverageCode === 'CrimePremises' || itemOptCov.coverageCode === 'CrimeInTransit'
                            || itemOptCov.coverageCode === 'CrimeForgery' || itemOptCov.coverageCode === 'CrimeComputerFraud'
                            || itemOptCov.coverageCode === 'CrimeFundsTransferFraud' || itemOptCov.coverageCode === 'CrimeMoneyOrderFraud'
                            || itemOptCov.coverageCode === 'CrimeCreditCardFraud' || itemOptCov.coverageCode === 'CrimeClient'){
                                if(itemOptCov.isCoveraheRequired === true){
                                    aggCLRF = itemOptCov.factorValue && itemOptCov.cLRFAjdustment && cLRF ? aggCLRF + (itemOptCov.factorValue * (itemOptCov.cLRFAjdustment / cLRF)) : aggCLRF;
                                }
                            }
                        });
                        var actualPremium = parseFloat(recordDetail.baseRate) * parseFloat(cLRF) * parseFloat(recordDetail.industryMod) * parseFloat(recordDetail.overallRatingModifier) * parseFloat(recordDetail.snTModifier) * this.commissionAdjustmentFactor * this.policyPeriodAdjustmentFactor;
                        console.log('actualPremium'+actualPremium);
                        factorValue = actualPremium.toFixed(0) * 0.1 * limitFactorExpense * ((1 / recordDetail.limitfactor) + aggCLRF);
                        this.factorValue = factorValue.toFixed(3);
                        optionalCoverages.factorValue = factorValue.toFixed(3);

                    }
                }
                else{
                    if(coverageLineItem.Coverage__r.Coverage_Code__c === 'DOExecsCoverage'){
                        var recordDetail = JSON.parse(JSON.stringify(this.recordDetail));
                        cILF = this.calculateLimitChange(optionValueDefault,productName);
                        var factorValue = this.handleratingFactorValue(coverageLineItem,cILF);
                        var optionalLoading = this.calculateLoadingforExecLimit(factorValue,recordDetail.limitfactor);
                        optionalCoverages.optionalRatingModifierFactor.Factor_Value__c = factorValue.toFixed(3);
                        optionalCoverages.factorValue = optionalLoading.toFixed(3);
                        optionalCoverages.cLRFAjdustment = parseFloat(cILF) > 0 ? parseFloat(cILF).toFixed(3) : 1;
                        this.cLRFAjdustment = parseFloat(cILF) > 0 ? parseFloat(cILF).toFixed(3) : 1;
                    }
                }
            }
        }
        else{
            if(optionalCoverages.coverageCode === 'EPLCoverageWH'){
                var exposureWH,limitWH,retentionWH;
                var mapWHLimitFactor = JSON.parse(JSON.stringify(optionalCoverages.mapWHLimitFactor));
                var mapWHRetentionFactor = JSON.parse(JSON.stringify(optionalCoverages.mapWHRetentionFactor));
                optionalCoverages.listCoverageLineItems.forEach(item2=>{
                    if(item2.Id === coverageLineItem.Id){
                        item2.Option_Value_Default__c = coverageLineItem.Option_Value_Default__c;
                    }
                    if(item2.Limits_Deductibles__r.LmtDedCode__c === 'EPLExposureWH'){
                        exposureWH = item2.Option_Value_Default__c;
                    }
                    else if(item2.Limits_Deductibles__r.LmtDedCode__c === 'EPLRetentionWH'){
                        retentionWH = parseFloat(item2.Option_Value_Default__c);
                    }
                    else if(item2.Limits_Deductibles__r.LmtDedCode__c === 'EPLSublimitWH'){
                        limitWH = parseFloat(item2.Option_Value_Default__c);
                    }
                });
                if(limitWH === 0){
                    this.factorValue = 0;
                }
                else{
                    var listLimitFactor = mapWHLimitFactor[exposureWH];
                    var listWHRetentionFactor = mapWHRetentionFactor[exposureWH];
                    var limitFactor,retentionFactor;
                    listLimitFactor.forEach(item=>{
                        var lowerValue = parseFloat(item.lowerValue);
                        var upperValue = parseFloat(item.upperValue);
                        if(limitWH >= lowerValue && limitWH < upperValue){
                            if(lowerValue == limitWH){
                                limitFactor = parseFloat(item.lowerFactor);
                            }
                            else{
                                limitFactor = this.getInterpolationValue(upperValue,lowerValue,limitWH,item.lowerFactor);
                            }
                        }
                    });
                    listWHRetentionFactor.forEach(item=>{
                        var lowerValue = parseFloat(item.lowerValue);
                        var upperValue = parseFloat(item.upperValue);
                        if(retentionWH >= lowerValue && retentionWH < upperValue){
                            if(lowerValue == retentionWH){
                                retentionFactor = parseFloat(item.lowerFactor);
                            }
                            else{
                                limitFactor = this.getInterpolationValue(upperValue,lowerValue,retentionWH,item.lowerFactor);
                            }
                        }
                    });
                    console.log('limitFactor'+limitFactor);
                    console.log('retentionFactor'+retentionFactor);
                    factorValue = optionalCoverages.factorValue = limitFactor && retentionFactor ? limitFactor * retentionFactor : 0;
                    this.factorValue =  optionalCoverages.factorValue = factorValue.toFixed(3);
                }
            }
            else if(optionalCoverages.coverageCode === 'EPLThirdParty'){
                var limitTP,retentionTP;
                optionalCoverages.listCoverageLineItems.forEach(item2=>{
                    if(item2.Id === coverageLineItem.Id){
                        item2.Option_Value_Default__c = coverageLineItem.Option_Value_Default__c;
                    }
                    if(item2.Limits_Deductibles__r.LmtDedCode__c === 'EPLRetentionAmtforThirdParty'){
                        retentionTP = item2.Option_Value_Default__c;
                    }
                    else if(item2.Limits_Deductibles__r.LmtDedCode__c === 'EPLThirdPartyLOL'){
                        limitTP = item2.Option_Value_Default__c;
                    }
                });
                if(limitTP === 0){
                    this.factorValue = 0;
                }
                else{
                    var recordDetail = JSON.parse(JSON.stringify(this.recordDetail));
                    var limitFactorTP = this.getLimitFactor(limitTP);
                    var retentionFactorTP = this.getRetentionFactor(retentionTP);
                    var aggLimit = recordDetail.requiredLimit + parseFloat(limitTP);
                    var limitFactorTPagg = this.getLimitFactor(aggLimit);
                    var cLRFEPL = this.calculateCLRFValue(recordDetail.requiredLimit,recordDetail.policyRetention,recordDetail.limitfactor,recordDetail.retentionFactor);
                    var cLRFTP = this.calculateCLRFValue(limitTP,retentionTP,limitFactorTP,retentionFactorTP);
                    var cLRFTAgg= this.calculateCLRFValue(aggLimit,recordDetail.policyRetention,limitFactorTPagg,recordDetail.retentionFactor);
                    console.log('cLRFTAgg'+cLRFTAgg);
                    factorValue = (( 0.25 * cLRFTAgg + 0.65 * cLRFEPL + 0.1 * cLRFTP ) / cLRFEPL) - 1;
                    this.factorValue =  optionalCoverages.factorValue = factorValue.toFixed(3);
                }
            }
            else if(optionalCoverages.coverageCode === 'CrimePremises' || optionalCoverages.coverageCode === 'CrimeInTransit'
                || optionalCoverages.coverageCode === 'CrimeForgery' || optionalCoverages.coverageCode === 'CrimeComputerFraud'
                || optionalCoverages.coverageCode === 'CrimeFundsTransferFraud' || optionalCoverages.coverageCode === 'CrimeMoneyOrderFraud'
                || optionalCoverages.coverageCode === 'CrimeCreditCardFraud' || optionalCoverages.coverageCode === 'CrimeClient'
                || optionalCoverages.coverageCode === 'CrimeSocialEngineering'){
                var limitVal,retentionVal;
                optionalCoverages.listCoverageLineItems.forEach(item2=>{
                    if(item2.Id === coverageLineItem.Id){
                        item2.Option_Value_Default__c = coverageLineItem.Option_Value_Default__c;
                    }
                    if(item2.CoverageLineItemType__c === 'Deductible Option'){
                        retentionVal = item2.Option_Value_Default__c;
                    }
                    else if(item2.CoverageLineItemType__c === 'Limit Option'){
                        limitVal = item2.Option_Value_Default__c;
                    }
                });
                if(limitVal === 0){
                    this.factorValue = 0;
                }
                else{
                    var recordDetail = JSON.parse(JSON.stringify(this.recordDetail));
                    var limitFactorVal = this.getLimitFactor(limitVal);
                    var retentionFactorVal = this.getRetentionFactor(retentionVal);
                    var cLRFEPL = this.calculateCLRFValue(recordDetail.requiredLimit,recordDetail.policyRetention,recordDetail.limitfactor,recordDetail.retentionFactor);
                    var cLRFVal = cLRFEPL ? this.calculateCLRFValue(limitVal,retentionVal,limitFactorVal,retentionFactorVal) / cLRFEPL : 0;
                    //var overallSchMod = recordDetail.overallRatingModifier;
                    //var overallMod = overallSchMod * recordDetail.snTModifier;
                    var optionalLoading = (this.factorValue * cLRFVal) / recordDetail.snTModifier;
                    this.optionalLoading = optionalLoading.toFixed(3);
                    optionalCoverages.factorValue = optionalLoading.toFixed(3);
                    optionalCoverages.cLRFAjdustment = cLRFVal.toFixed(3);
                    this.cLRFAjdustment = cLRFVal.toFixed(3);
                }
            }
        }
        
        this.optionalCoverages = optionalCoverages;
        /*this.template.querySelectorAll("c-generate-output-element-premium-calculator-lwc").forEach(element => {
            var ratingModifier = JSON.parse(JSON.stringify(element.ratingModifier));
            console.log('ratingmodifier'+ratingModifier);
            if(element.productName === productName && ratingModifier.Sub_Section__c === 'Optional Factors' && ratingModifier.Coverage_Code__c === coverageLineItem.Coverage__r.Coverage_Code__c){
                console.log('test');

                element.handleratingFactorValue(coverageLineItem,cILF);
            }
        });*/

        //if(isUpdate === true){
            console.log('isUpdate value?-->',isUpdate)
            const editldEvt = new CustomEvent(
                "optionalfactorvaluechange", {
                detail: {
                    optionalCoverages : this.optionalCoverages,
                    productName : this.productName,
                    reCalculatePremium : isUpdate
                },
            });
            this.dispatchEvent(editldEvt);
        //}
        
    }

    getInterpolationValue(value1,value2,value3,value4){

        var upperBound = parseFloat(value1);
        var lowerBound = parseFloat(value2);
        var requiredLimit = parseFloat(value3);
        var lowerFactor = parseFloat(value4);
        var limitRange = upperBound - lowerBound;
        var limitexcess = requiredLimit - lowerBound;
        var limitRangePercent = limitexcess/limitRange;
        var limitFactor = lowerFactor + (lowerFactor*limitRangePercent);
        return limitFactor;

    }

    calculateCLRFValue(value1,value2,value3,value4){
        var reqLimit = value1;
        var polRetention = value2;
        var limitFactor = value3;
        var retentionFactor = value4;
        var formulaExponent = this.getFormulaExponent(this.productName);
        var cLRF = 0.0;

        if(reqLimit < 1000000){
            cLRF = parseFloat(limitFactor) * parseFloat(retentionFactor);
        }
        else if(reqLimit >= 1000000 && polRetention < 1000000){
            cLRF = parseFloat(limitFactor) + parseFloat(retentionFactor) - 1;
        }
        else if(reqLimit >= 1000000 && polRetention >= 1000000){
            var ILFLimitRetention = ((reqLimit + polRetention) / 1000000) ** (formulaExponent);
            var ILFRetention = ((polRetention) / 1000000) ** (formulaExponent);
            cLRF = ILFLimitRetention - ILFRetention;
        }

        return cLRF;

    }

    getFormulaExponent(value){
        var formulaExponent = 1;
        switch(value) {
            case 'D&O':
                formulaExponent = 0.65;
              break;
            case 'EPL':
                formulaExponent = 0.5;
              break;
          }
          return formulaExponent;

    }

    getRetentionFactor(value){

        var retentionFactor = 0.0;
        var retention = parseFloat(value);
        var listRetentionMod = this.listRetentionMod;
        listRetentionMod.forEach(item1=>{
            var LowerValue = parseFloat(item1.LowerValue);
            var UpperValue = parseFloat(item1.UpperValue);
            if(LowerValue <= retention && UpperValue > retention){
                if(LowerValue == retention){
                    retentionFactor = item1.lowerFactor;
                }
                else{
                    var retentionRange = UpperValue - LowerValue;
                    var retentionexcess = retention - LowerValue;
                    var retentionRangePercent = retentionexcess/retentionRange;
                    var lowerFactor = parseFloat(item1.lowerFactor);
                    retentionFactor = lowerFactor + (lowerFactor*retentionRangePercent);
                }
            }
            console.log('item1.factorValue'+item1.factorValue);
        });

        return retentionFactor;

    }

    getLimitFactor(value){

        var limitFactor = 0.0;
        var requiredLimit = parseFloat(value);
        var listLimitRange = this.listLimitRange;
        listLimitRange.forEach(item1=>{
            var lowerBound = parseFloat(item1.lowerBound);
            var upperBound = parseFloat(item1.upperBound);
            if(lowerBound <= requiredLimit && upperBound > requiredLimit){
                if(item1.lowerFactor !== 'N/A' && item1.upperFactor !== 'N/A'){
                    if(lowerBound == requiredLimit){
                        limitFactor = item1.lowerFactor;
                    }
                    else{
                        var limitRange = upperBound - lowerBound;
                        var limitexcess = requiredLimit - lowerBound;
                        var limitRangePercent = limitexcess/limitRange;
                        var lowerFactor = parseFloat(item1.lowerFactor);
                        limitFactor = lowerFactor + (lowerFactor*limitRangePercent);
                    }
                }
                else if(item1.formulaExponent !== 'N/A'){
                    var temp = 1000000;
                    limitFactor = (requiredLimit / temp ) ** (parseFloat(item1.formulaExponent));
                }

            }
        });

        return limitFactor;

    }

    @api
    calculateLimitChange(value1,value2){

        var execLimit = value1;
        var productName = value2;
        var execILF;
        
        var listLimitRange = this.listLimitRange;
        if(execLimit > 0){
            listLimitRange.forEach(item1=>{
                var lowerBound = parseFloat(item1.lowerBound);
                var upperBound = parseFloat(item1.upperBound);
                if(lowerBound <= execLimit && upperBound > execLimit){
                    if(item1.lowerFactor !== 'N/A' && item1.upperFactor !== 'N/A'){
                        if(lowerBound == execLimit){
                            execILF = item1.lowerFactor;
                        }
                        else{
                            var limitRange = upperBound - lowerBound;
                            var limitexcess = execLimit - lowerBound;
                            var limitRangePercent = limitexcess/limitRange;
                            var lowerFactor = parseFloat(item1.lowerFactor);
                            var exelimitfactor = lowerFactor + (lowerFactor*limitRangePercent);
                            execILF = exelimitfactor;
                        }
                    }
                    else if(item1.formulaExponent !== 'N/A'){
                        var temp = 1000000;
                        var exelimitfactor = (execLimit / temp ) ** (parseFloat(item1.formulaExponent));
                        execILF = exelimitfactor;
                    }

                }
            });

        }
        else{
            execILF = 0;
        }
        return execILF;

    }


}