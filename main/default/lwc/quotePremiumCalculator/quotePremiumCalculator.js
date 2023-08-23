import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import fetchRatingModifiers from '@salesforce/apex/QuotePremiumCalculatorController.fetchRatingModifiers';
import saveRatingModifiers from '@salesforce/apex/QuotePremiumCalculatorController.saveRatingModifiers';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import TickerSymbol from '@salesforce/schema/Account.TickerSymbol';


export default class QuotePremiumCalculator extends NavigationMixin(LightningElement) {

    @api quoteId;
    @api selectedProducts = [];
    @track ratingModifiers = [];
    @api industryRatingModifier;
    @api factorRangeMap;
    @api stateCap;
    @api stateMin;
    @api stateMax;
    @api listLimitRange;
    @api limitfactor;
    @api baseRate;
    //@api stateRelativityFactor;
    @api retentionFactor;
    @api totalPremium;
    @track wiredata;
    @api isLoading = false;
    @track backgroundColorHeader = 'slds-accordion__summary slds-box header-background-blue';
    @api isOptionalCoverage = false;
    @api optionalCoverage = 'No';
    @api optionalCoverageMassRetention = 'No';
    @api execILF = 0.00;
    @api execFactor = 0.175;
    @api optionalLoading = 0.00;
    @api quoteLayer;
    @track isExcess = false;
    @api underlyingExcessLimit;
    @api underlyingExcessAttachment;
    @api commissionAdjustmentFactor;
    @api policyPeriodAdjustmentFactor;
    @api rateableEmplyee;
    @api disableCal = 'slds-grid slds-wrap slds-box ';
    @api objQuote;
    @api annualRevenue;
    @api planAssets;
    @api optionalCoverageOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' },
    ];

    @api optionalCoverageLimit = [
        { label: 0, value: 0 },
        { label: 250000, value: 250000 },
        { label: 500000, value: 500000 },
        { label: 1000000, value: 1000000 },
    ];

    rmColSize = 6;
    /*@wire(fetchRatingModifiers, {
        quoteId: '$quoteId'
    })
    ratingData(result) {
        console.log('result'+result);
        this.wiredata = result;
        var data = result.data;
        var error = result.error;
        if (data) {

            var ratingModifiers = data.listRecordDetails;;
            this.ratingModifiers = ratingModifiers;
            this.selectedProducts = data.lstSelectedProduct;
            var factorRangeMap = data.factorRangeMap;
            this.factorRangeMap = factorRangeMap;
            this.totalPremium = data.totalPremium;
            this.quoteLayer = data.quoteLayer;
            this.isExcess = data.quoteLayer === 'Excess' ? true : false;
            var stateRange = data.stateRange;
            this.baseRate = data.baseRate;
            this.stateRelativityFactor = data.stateRelativityFactor;
            var listLimitRange = data.listLimitRange;
            var listRetentionMod = data.listRetentionMod;
            this.underlyingExcessLimit = data.underlyingExcessLimit;
            this.underlyingExcessAttachment = data.underlyingExcessAttachment;
            this.commissionAdjustmentFactor = data.commissionAdjustmentFactor;
            this.policyPeriodAdjustmentFactor = data.policyPeriodAdjustmentFactor;
            this.productNames = data.productNames;
            if(stateRange){
                var maxStateCap = stateRange.maxCredit;
                var minStateCap = stateRange.maxDebit;
                var stateMax = 1+parseFloat(maxStateCap);
                var stateMin = 1-parseFloat(minStateCap);
                var stateCap = 'Min '+stateMin+' - Max '+stateMax;
                this.stateMax = stateMax;
                this.stateMin = stateMin;
                this.stateCap = stateCap;
                console.log('stateCap'+stateCap)
            }
            if(listLimitRange){
                this.listLimitRange = listLimitRange;
                ratingModifiers.forEach(item=>{
                    if(item.productName === 'D&O'){
                        var execLimit = item.executiveLimit;
                        if(execLimit > 0){
                            this.optionalCoverage = 'Yes';
                            this.isOptionalCoverage = true;
                            listLimitRange.forEach(item1=>{
                                var lowerBound = parseFloat(item1.lowerBound);
                                var upperBound = parseFloat(item1.upperBound);
                                if(lowerBound <= execLimit && upperBound > execLimit){
                                    if(item1.lowerFactor !== 'N/A' && item1.upperFactor !== 'N/A'){
                                        if(lowerBound == execLimit){
                                            this.execILF = item1.lowerFactor;
                                        }
                                        else{
                                            var limitRange = upperBound - lowerBound;
                                            var limitexcess = execLimit - lowerBound;
                                            var limitRangePercent = limitexcess/limitRange;
                                            var lowerFactor = parseFloat(item1.lowerFactor);
                                            var exelimitfactor = lowerFactor + (lowerFactor*limitRangePercent);
                                            this.execILF = exelimitfactor;
                                        }
                                    }
                                    else if(item1.formulaExponent !== 'N/A'){
                                        var temp = 1000000;
                                        var exelimitfactor = (execLimit / temp ) ** (parseFloat(item1.formulaExponent));
                                        this.execILF = exelimitfactor;
                                    }
    
                                }
                            });
                        }
                    }
                    else if(item.productName === 'EPL'){
                        if(item.employeeDetails){
                            this.rateableEmplyee = item.employeeDetails.RatableEmployee;
                        }
                    }
                    listLimitRange.forEach(item1=>{
                        var lowerBound = parseFloat(item1.lowerBound);
                        var upperBound = parseFloat(item1.upperBound);
                        if(lowerBound <= item.requiredLimit && upperBound > item.requiredLimit){
                            if(item1.lowerFactor !== 'N/A' && item1.upperFactor !== 'N/A'){
                                if(lowerBound == item.requiredLimit){
                                    this.limitfactor = item1.lowerFactor;
                                }
                                else{
                                    var limitRange = upperBound - lowerBound;
                                    var limitexcess = item.requiredLimit - lowerBound;
                                    var limitRangePercent = limitexcess/limitRange;
                                    var lowerFactor = parseFloat(item1.lowerFactor);
                                    var limitfactor = lowerFactor + (lowerFactor*limitRangePercent);
                                    this.limitfactor = limitfactor;
                                }
                            }
                            else if(item1.formulaExponent !== 'N/A'){
                                var temp = 1000000;
                                var limitfactor = (item.requiredLimit / temp ) ** (parseFloat(item1.formulaExponent));
                                this.limitfactor = limitfactor;
                            }

                        }
                    });
                });
                
            }
            if(listRetentionMod){
                this.listRetentionMod = listRetentionMod;
                ratingModifiers.forEach(item=>{
                   // if(item.productName === 'D&O'){
                        listRetentionMod.forEach(item1=>{
                            var LowerValue = parseFloat(item1.LowerValue);
                            var UpperValue = parseFloat(item1.UpperValue);
                            if(LowerValue <= item.policyRetention && UpperValue > item.policyRetention){
                                if(LowerValue == item.policyRetention){
                                    this.retentionFactor = item1.lowerFactor;
                                }
                                else{
                                    var retentionRange = UpperValue - LowerValue;
                                    var retentionexcess = item.policyRetention - LowerValue;
                                    var retentionRangePercent = retentionexcess/retentionRange;
                                    var lowerFactor = parseFloat(item1.lowerFactor);
                                    var retentionFactor = lowerFactor + (lowerFactor*retentionRangePercent);
                                    this.retentionFactor = retentionFactor;
                                }
                            }
                        });
                    //}
                });
            }
            

        }

    }*/
    // added by Jitendra on 07-Jan-2022 for MTA-80  code start---
    getRatingModifiers(){
        fetchRatingModifiers({quoteId: this.quoteId})
        .then(response => {
            console.log('result'+response);
            var data = response;
            if (data) {

                var ratingModifiers = data.listRecordDetails;
                this.ratingModifiers = ratingModifiers;
                this.selectedProducts = data.lstSelectedProduct;
                var factorRangeMap = data.factorRangeMap;
                this.factorRangeMap = factorRangeMap;
                this.totalPremium = data.totalPremium;
                this.quoteLayer = data.quoteLayer;
                this.annualRevenue = data.annualRevenue;
                this.planAssets = data.planAssets;
                this.isExcess = data.quoteLayer === 'Excess' ? true : false;
                var stateRange = data.stateRange;
                this.baseRate = data.baseRate;
                //this.stateRelativityFactor = data.stateRelativityFactor;
                var listLimitRange = data.listLimitRange;
                var listRetentionMod = data.listRetentionMod;
                this.underlyingExcessLimit = data.underlyingExcessLimit;
                this.underlyingExcessAttachment = data.underlyingExcessAttachment;
                this.commissionAdjustmentFactor = data.commissionAdjustmentFactor;
                this.policyPeriodAdjustmentFactor = data.policyPeriodAdjustmentFactor;
                this.productNames = data.productNames;
                if( data.objQuote ){
                    this.objQuote = data.objQuote;
                    if( this.objQuote.Product_Name__c == 'Private Company Combo' &&  
                        ( 
                            ( this.objQuote.Quote_Type__c == 'Amendment' && this.objQuote.Status == 'Quoted') ||
                            ( this.objQuote.Quote_Type__c == 'Update Insured Name or Address') || 
                            ( this.objQuote.Quote_Type__c == 'Policy Duration Change' ) ||
                            ( this.objQuote.Quote_Type__c == 'Reinstatement' ) ||
                            ( this.objQuote.Quote_Type__c == 'Midterm Cancellation' ) ||
                            ( this.objQuote.Quote_Type__c == 'Flat Cancellation' ) ||
                            ( this.objQuote.Quote_Type__c == 'Extended Reporting Period (ERP)' ) ||
                            ( this.objQuote.Quote_Type__c == 'Broker on Record Change' )
                        )
                        
                    ){
                        this.disableCal +=' bound-disabled';
                    }
                }

                if(stateRange){
                    var maxStateCap = stateRange.maxCredit;
                    var minStateCap = stateRange.maxDebit;
                    var stateMax = 1+parseFloat(maxStateCap);
                    var stateMin = 1-parseFloat(minStateCap);
                    var stateCap = 'Min '+stateMin+' - Max '+stateMax;
                    this.stateMax = stateMax;
                    this.stateMin = stateMin;
                    this.stateCap = stateCap;
                    console.log('stateCap'+stateCap)
                }
                if(listLimitRange){
                    this.listLimitRange = listLimitRange;
                    ratingModifiers.forEach(item=>{
                        if(item.productName === 'D&O'){
                            var execLimit = item.executiveLimit;
                            if(execLimit > 0){
                                this.optionalCoverage = 'Yes';
                                this.isOptionalCoverage = true;
                                listLimitRange.forEach(item1=>{
                                    var lowerBound = parseFloat(item1.lowerBound);
                                    var upperBound = parseFloat(item1.upperBound);
                                    if(lowerBound <= execLimit && upperBound > execLimit){
                                        if(item1.lowerFactor !== 'N/A' && item1.upperFactor !== 'N/A'){
                                            if(lowerBound == execLimit){
                                                this.execILF = item1.lowerFactor;
                                            }
                                            else{
                                                var limitRange = upperBound - lowerBound;
                                                var limitexcess = execLimit - lowerBound;
                                                var limitRangePercent = limitexcess/limitRange;
                                                var lowerFactor = parseFloat(item1.lowerFactor);
                                                var exelimitfactor = lowerFactor + (lowerFactor*limitRangePercent);
                                                this.execILF = exelimitfactor;
                                            }
                                        }
                                        else if(item1.formulaExponent !== 'N/A'){
                                            var temp = 1000000;
                                            var exelimitfactor = (execLimit / temp ) ** (parseFloat(item1.formulaExponent));
                                            this.execILF = exelimitfactor;
                                        }
        
                                    }
                                });
                            }
                        }
                        else if(item.productName === 'EPL'){
                            if(item.employeeDetails){
                                this.rateableEmplyee = item.employeeDetails.RatableEmployee;
                            }
                        }

                        console.log('rmColSize-->', this.rmColSize);
                        listLimitRange.forEach(item1=>{
                            var lowerBound = parseFloat(item1.lowerBound);
                            var upperBound = parseFloat(item1.upperBound);
                            if(lowerBound <= item.requiredLimit && upperBound > item.requiredLimit){
                                if(item1.lowerFactor !== 'N/A' && item1.upperFactor !== 'N/A'){
                                    if(lowerBound == item.requiredLimit){
                                        this.limitfactor = item1.lowerFactor;
                                    }
                                    else{
                                        var limitRange = upperBound - lowerBound;
                                        var limitexcess = item.requiredLimit - lowerBound;
                                        var limitRangePercent = limitexcess/limitRange;
                                        var lowerFactor = parseFloat(item1.lowerFactor);
                                        var limitfactor = lowerFactor + (lowerFactor*limitRangePercent);
                                        this.limitfactor = limitfactor;
                                    }
                                }
                                else if(item1.formulaExponent !== 'N/A'){
                                    var temp = 1000000;
                                    var limitfactor = (item.requiredLimit / temp ) ** (parseFloat(item1.formulaExponent));
                                    this.limitfactor = limitfactor;
                                }

                            }
                        });
                    });
                    
                }
                if(listRetentionMod){
                    this.listRetentionMod = listRetentionMod;
                    ratingModifiers.forEach(item=>{
                    // if(item.productName === 'D&O'){
                            listRetentionMod.forEach(item1=>{
                                var LowerValue = parseFloat(item1.LowerValue);
                                var UpperValue = parseFloat(item1.UpperValue);
                                if(LowerValue <= item.policyRetention && UpperValue > item.policyRetention){
                                    if(LowerValue == item.policyRetention){
                                        this.retentionFactor = item1.lowerFactor;
                                    }
                                    else{
                                        var retentionRange = UpperValue - LowerValue;
                                        var retentionexcess = item.policyRetention - LowerValue;
                                        var retentionRangePercent = retentionexcess/retentionRange;
                                        var lowerFactor = parseFloat(item1.lowerFactor);
                                        var retentionFactor = lowerFactor + (lowerFactor*retentionRangePercent);
                                        this.retentionFactor = retentionFactor;
                                    }
                                }
                            });
                        //}
                    });
                }
                

            }
        })
        .catch(error => {
            console.log('cal c');
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Rating Modifiers',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        });
    }
    // added by Jitendra on 07-Jan-2022 for MTA-80  code end----
    connectedCallback() {
        this.getRatingModifiers();
        //window.addEventListener('scroll', this.scrollHandler.bind(this));
    }

    handleToggleSection(event) {
        this.activeSectionMessage =
            'Open section name:  ' + event.detail.openSections;
    }

    handleAccordianClick(event){
        var name = event.target.name;
        if(name === undefined){
            var temp = event.currentTarget.id
            name = temp.split('-')[0];
        }
        var ratingModifiers = JSON.parse(JSON.stringify(this.ratingModifiers));
        ratingModifiers.forEach(item=>{
            console.log('Section Name-->',name)
            if(item.productName === name){
                var isSectionHidden = !item.isSectionHidden;
                item.isSectionHidden = isSectionHidden;
                if(!isSectionHidden){
                    item.backgroundColorHeader = 'slds-accordion__summary slds-box header-background-blue';
                }
                else{
                    item.backgroundColorHeader = 'slds-accordion__summary slds-box header-background-grey';
                }
            }
        });
        this.ratingModifiers = ratingModifiers;

    }

    handleOptionalCoverage(event){

        var value = event.target.value;
        var productName = event.target.name;
        var label = event.target.label;
        var ratingModifiers = JSON.parse(JSON.stringify(this.ratingModifiers));
        ratingModifiers.forEach(item=>{
            if(item.productName === productName){
                item.listOptionalCoverages.forEach(item1=>{
                    if(label === item1.optionalCoverageName){
                        item1.strCoveraheRequired = value;
                        if(value === 'Yes'){
                            item1.isCoveraheRequired = true;
                        }
                        else{
                            item1.isCoveraheRequired = false;
                            item1.listCoverageLineItems.forEach(covItem=>{
                                if(covItem.CoverageLineItemType__c === 'Limit Option' || (covItem.CoverageLineItemType__c === 'Deductible Option' && covItem.Coverage__r.Coverage_Code__c === 'EPLClassRetentionCoverage')){
                                    covItem.Option_Value_Default__c = '0';
                                }
                            });
                            item1.factorValue = 0;
                            if(item1.optionalRatingModifierFactor){
                                item1.optionalRatingModifierFactor.Factor_Value__c = '0';
                            }
                        }
                    }
                });
            }
        });
        this.ratingModifiers = ratingModifiers;
        this.calculatePremium(productName);
        /*this.optionalCoverage = value;
        if(value === 'Yes'){
            this.isOptionalCoverage = true;
        }
        else{
            this.isOptionalCoverage = false;
            var ratingModifiers = JSON.parse(JSON.stringify(this.ratingModifiers));
            ratingModifiers.forEach(item=>{
                if(item.productName == productName){
                    item.executiveLimit = 0;
                }
            });
            this.ratingModifiers = ratingModifiers;
            this.execILF = 0;
            this.calculateLoadingforExecLimit(productName);
        }*/

    }

    @api
    calculateLimitChange(value1,value2){

        var execLimit = value1;
        var productName = value2;
        
        var ratingModifiers = JSON.parse(JSON.stringify(this.ratingModifiers));
        ratingModifiers.forEach(item=>{
            if(item.productName == productName){
                item.executiveLimit = execLimit;
                var listLimitRange = item.listLimitRange;
                if(execLimit > 0){
                    listLimitRange.forEach(item1=>{
                        var lowerBound = parseFloat(item1.lowerBound);
                        var upperBound = parseFloat(item1.upperBound);
                        if(lowerBound <= execLimit && upperBound > execLimit){
                            if(item1.lowerFactor !== 'N/A' && item1.upperFactor !== 'N/A'){
                                if(lowerBound == execLimit){
                                    this.execILF = item1.lowerFactor;
                                }
                                else{
                                    var limitRange = upperBound - lowerBound;
                                    var limitexcess = execLimit - lowerBound;
                                    var limitRangePercent = limitexcess/limitRange;
                                    var lowerFactor = parseFloat(item1.lowerFactor);
                                    var exelimitfactor = lowerFactor + (lowerFactor*limitRangePercent);
                                    this.execILF = exelimitfactor;
                                }
                            }
                            else if(item1.formulaExponent !== 'N/A'){
                                var temp = 1000000;
                                var exelimitfactor = (execLimit / temp ) ** (parseFloat(item1.formulaExponent));
                                this.execILF = exelimitfactor;
                            }

                        }
                    });

                }
                else{
                    this.execILF = 0;
                }
            }
        });
        //this.ratingModifiers = ratingModifiers;

        //this.calculateLoadingforExecLimit(productName);

        return this.execILF;

    }

    handleChangeExecFactorValue(event){

        var execFactor = event.target.value;
        var productName = event.target.name;
        this.execFactor = execFactor;
        this.calculateLoadingforExecLimit(productName);
    }

    calculateLoadingforExecLimit(value){

        var productName = value;
        var ratingModifiers = JSON.parse(JSON.stringify(this.ratingModifiers));
        ratingModifiers.forEach(item=>{
            if(item.productName == productName){
                var limitFactor = this.limitfactor;
                var execILF = this.execILF;
                var execFactor = this.execFactor;
                var optionalLoading = (execFactor * execILF) / limitFactor;
                this.optionalLoading = optionalLoading.toFixed(3);
            }
        });
        this.calculatePremium(productName);
    }

    handleFactorValueChange(event){
        console.log('test');
        var value = event.target.value;
        var ratingModifierFactor = JSON.parse(JSON.stringify(event.detail.ratingModifierFactor));
        var productName = JSON.parse(JSON.stringify(event.detail.productName));
        console.log('value---->'+value);
        console.log('ratingModifierFactor---->'+ratingModifierFactor);

        var ratingModifiers = JSON.parse(JSON.stringify(this.ratingModifiers));
        console.log('ratingModifiers---->',ratingModifiers);
        ratingModifiers.forEach(item=>{
            if(item.productName == productName){
                var isEmployeeRatioChange = false;
                var partTimeRatio = 0;
                var foreignRatio = 0;
                item.listRatingModifier.forEach(item1=>{
                    if(item1.Id == ratingModifierFactor.Id){
                        item1.Factor_Value__c = ratingModifierFactor.Factor_Value__c;
                        if(item1.Rating_Modifier__r.Rating_Modifier_Code__c === 'EPL000017' || item1.Rating_Modifier__r.Rating_Modifier_Code__c === 'EPL000018'){
                            isEmployeeRatioChange = true;
                        }
                    }
                    if(item1.Rating_Modifier__r.Rating_Modifier_Code__c === 'EPL000017'){
                        partTimeRatio = ratingModifierFactor.Factor_Value__c;
                    }
                    else if(item1.Rating_Modifier__r.Rating_Modifier_Code__c === 'EPL000018'){
                        foreignRatio = ratingModifierFactor.Factor_Value__c;
                    }
                });
                if(isEmployeeRatioChange === true){
                    var employeeDetails = item.employeeDetails;
                    var partTimeEmployees = employeeDetails.partTimeEmployee ? employeeDetails.partTimeEmployee * partTimeRatio : 0;
                    var foreignEmployees = employeeDetails.foreignEmployee ? employeeDetails.foreignEmployee * foreignRatio : 0;

                    item.employeeDetails.RatableEmployee = employeeDetails.fullTimeEmployee + partTimeEmployees + foreignEmployees;
                }
                
            }
        });
        this.ratingModifiers = ratingModifiers;
        this.calculatePremium(productName);

    }

    handleFactorOptionChange(event){
        console.log('test');
        var value = event.target.value;
        var ratingModifier = JSON.parse(JSON.stringify(event.detail.ratingModifier));
        var ratingModifierFactor = JSON.parse(JSON.stringify(event.detail.ratingModifierFactor));
        var productName = JSON.parse(JSON.stringify(event.detail.productName));
        console.log('value---->'+value);
        console.log('ratingModifier---->'+ratingModifier);

        var ratingModifiers = JSON.parse(JSON.stringify(this.ratingModifiers));
        ratingModifiers.forEach(item=>{
            if(item.productName == productName){
                item.listRatingModifier.forEach(item1=>{
                    if(item1.Rating_Modifier__r.Id == ratingModifier.Id){
                        item1.Rating_Modifier__r.Rating_Modifier_Value__c = ratingModifier.Rating_Modifier_Value__c;
                        item1.Factor_Value__c = ratingModifierFactor.Factor_Value__c;
                    }
                });
            }
        });
        this.ratingModifiers = ratingModifiers;

        this.calculatePremium(productName);

    }

    /*handleOptionalCLIValueChange(event){
        console.log('value');
        var value = event.target.value;
        var coverageLineItem = JSON.parse(JSON.stringify(event.detail.coverageLineItem));
        var productName = JSON.parse(JSON.stringify(event.detail.productName));
        var optionalCoverageName = JSON.parse(JSON.stringify(event.detail.optionalCoverageName));
        var limitValue;
        var cILF;

        var ratingModifiers = JSON.parse(JSON.stringify(this.ratingModifiers));
        ratingModifiers.forEach(item=>{
            if(item.productName === productName){
                item.listOptionalCoverages.forEach(item1=>{
                    if(item1.optionalCoverageName === optionalCoverageName){
                        item1.listCoverageLineItems.forEach(item2=>{
                            if(item2.Id === coverageLineItem.Id){
                                item2.Option_Value_Default__c = coverageLineItem.Option_Value_Default__c;
                                limitValue = coverageLineItem.Option_Value_Default__c;
                                if(limitValue && coverageLineItem.Coverage__r.Coverage_Code__c === 'DOExecsCoverage'){
                                    cILF = this.calculateLimitChange(limitValue,productName);
                                }
                                if(item1.hasRatingModifier === false){
                                    var retention = parseFloat(limitValue);
                                    var listRetentionMod = item.listRetentionMod;
                                    listRetentionMod.forEach(item1=>{
                                        var LowerValue = parseFloat(item1.LowerValue);
                                        var UpperValue = parseFloat(item1.UpperValue);
                                        if(LowerValue <= retention && UpperValue > retention){
                                            if(LowerValue == retention){
                                                var retentionFactor = item1.lowerFactor;
                                                item1.factorValue = retentionFactor;
                                            }
                                            else{
                                                var retentionRange = UpperValue - LowerValue;
                                                var retentionexcess = retention - LowerValue;
                                                var retentionRangePercent = retentionexcess/retentionRange;
                                                var lowerFactor = parseFloat(item1.lowerFactor);
                                                var retentionFactor = lowerFactor + (lowerFactor*retentionRangePercent);
                                                item1.factorValue = retentionFactor;
                                            }
                                        }
                                        console.log('item1.factorValue'+item1.factorValue);
                                    });
                                }
                            }
                        });
                    }
                });
            }
        });
        console.log('test');
        this.ratingModifiers = ratingModifiers;
        console.log('test');
        
        

        this.template.querySelectorAll("c-generate-output-element-premium-calculator-lwc").forEach(element => {
            var ratingModifier = JSON.parse(JSON.stringify(element.ratingModifier));
            console.log('ratingmodifier'+ratingModifier);
            if(element.productName === productName && ratingModifier.Sub_Section__c === 'Optional Factors' && ratingModifier.Coverage_Code__c === coverageLineItem.Coverage__r.Coverage_Code__c){
                console.log('test');

                element.handleratingFactorValue(coverageLineItem,cILF);
            }
        });

    }*/

    handleLimitRetentionChange(event){

        var value = event.target.value;
        var productName = event.target.name;
        var label = event.target.label;
        console.log('label'+label);
        console.log('value'+value);

        var ratingModifiers = JSON.parse(JSON.stringify(this.ratingModifiers));
        var recordDetail;
        ratingModifiers.forEach(item=>{
            if(item.productName == productName){
                recordDetail = item;
                if(label == 'Required Limit'){
                    item.requiredLimit = parseFloat(value);
                    var listLimitRange = item.listLimitRange;
                    listLimitRange.forEach(item1=>{
                        var lowerBound = parseFloat(item1.lowerBound);
                        var upperBound = parseFloat(item1.upperBound);
                        if(lowerBound <= item.requiredLimit && upperBound > item.requiredLimit){
                            if(item1.lowerFactor !== 'N/A' && item1.upperFactor !== 'N/A'){
                                if(lowerBound == item.requiredLimit){
                                    this.limitfactor = item1.lowerFactor;
                                    item.limitfactor = item1.lowerFactor;
                                }
                                else{
                                    var limitRange = upperBound - lowerBound;
                                    var limitexcess = item.requiredLimit - lowerBound;
                                    var limitRangePercent = limitexcess/limitRange;
                                    var lowerFactor = parseFloat(item1.lowerFactor);
                                    var upperFactor = parseFloat(item1.upperFactor);
                                    var factorarange = upperFactor - lowerFactor;
                                    var limitfactor = lowerFactor + (factorarange*limitRangePercent);
                                    this.limitfactor = limitfactor;
                                    item.limitfactor = limitfactor;
                                }
                            }
                            else if(item1.formulaExponent !== 'N/A'){
                                var temp = 1000000;
                                var limitfactor = (item.requiredLimit / temp ) ** (parseFloat(item1.formulaExponent));
                                this.limitfactor = limitfactor;
                                item.limitfactor = limitfactor;
                            }

                        }
                    });
                }
                else if(label == 'Policy Retention'){
                    item.policyRetention = parseFloat(value);
                    var listRetentionMod = item.listRetentionMod;
                    listRetentionMod.forEach(item1=>{
                        var LowerValue = parseFloat(item1.LowerValue);
                        var UpperValue = parseFloat(item1.UpperValue);
                        if(LowerValue <= item.policyRetention && UpperValue > item.policyRetention){
                            if(LowerValue == item.policyRetention){
                                this.retentionFactor = item1.lowerFactor;
                                item.retentionFactor = item1.lowerFactor;
                            }
                            else{
                                var retentionRange = UpperValue - LowerValue;
                                var retentionexcess = item.policyRetention - LowerValue;
                                var retentionRangePercent = retentionexcess/retentionRange;
                                var lowerFactor = parseFloat(item1.lowerFactor);
                                var upperFactor = parseFloat(item1.upperFactor);
                                var factorarange = upperFactor - lowerFactor;
                                var retentionFactor = lowerFactor + (factorarange*retentionRangePercent);
                                this.retentionFactor = retentionFactor;
                                item.retentionFactor = retentionFactor;
                            }
                        }
                    });
                }
            }
        });
        console.log('test'+ratingModifiers);
        this.ratingModifiers = ratingModifiers;
        this.template.querySelectorAll("c-optional-coverage-l-w-c").forEach(element => {
            if(element.productName === productName){
                element.handleCalculateOptionalCLIValueChange(recordDetail,productName,false);
            }
        });
        this.calculatePremium(productName);

    }

    handleExcessLimitAttachmntChange(event){

        var value = event.target.value;
        var label = event.target.label;
        console.log('label'+label);
        console.log('value'+value);
        if(label == 'Underlying excess limit'){
            this.underlyingExcessLimit = parseFloat(value);
        }
        else if(label == 'Excess Attachment'){
            this.underlyingExcessAttachment = parseFloat(value);
        }
        this.calculatePremium();

    }

    calculatePremium(value){

        var productName = value;
        var productNames = [];
        if(productName){
            productNames.push(productName);
        }
        else{
            productNames.push(this.productNames);
        }
        var ratingModifiers = JSON.parse(JSON.stringify(this.ratingModifiers));
        var reqLimit;
        var pRetention;
        var IndustryMod;
        var sTnCMod;
        var stateMax = this.stateMax;
        var stateMin = this.stateMin;
        var totalPremium = 0;
        
        ratingModifiers.forEach(item=>{
            //if(productNames.includes(item.productName)){
                reqLimit = item.requiredLimit;
                var indicativePremium = 0;
                if(reqLimit){
                    pRetention = item.policyRetention;
                    var metadataSetting = item.metadataSetting;
                    var OverallRatingMod = 1;
                    var cLRF;
                    var formulaExponent = this.getFormulaExponent(item.productName);
                    var partTimeRatio = 0, foreignRatio = 0;
                    var commissionAdjustmentFactor = parseFloat(this.commissionAdjustmentFactor);
                    var policyPeriodAdjustmentFactor = parseFloat(this.policyPeriodAdjustmentFactor);
                    var percentCA;
                    item.listRatingModifier.forEach(item1=>{
                        if(item1.Rating_Modifier__r.Product__c == metadataSetting.productName && item1.Rating_Modifier__r.Rating_Modifier_Code__c == metadataSetting.industryModifierCode){
                            IndustryMod = parseFloat(item1.Factor_Value__c);
                            console.log('IndustryMod'+IndustryMod);
                        }
                        else if(item1.Rating_Modifier__r.Product__c == metadataSetting.productName && item1.Rating_Modifier__r.Rating_Modifier_Code__c == metadataSetting.snTModifierCode){
                            sTnCMod = parseFloat(item1.Factor_Value__c);
                            console.log('sTnCMod'+sTnCMod);
                        }
                        else if(item1.Rating_Modifier__r.Product__c == 'EPL' && item1.Rating_Modifier__r.Rating_Modifier_Code__c == 'EPL000017'){
                            partTimeRatio = parseFloat(item1.Factor_Value__c);
                        }
                        else if(item1.Rating_Modifier__r.Product__c == 'EPL' && item1.Rating_Modifier__r.Rating_Modifier_Code__c == 'EPL000018'){
                            foreignRatio = parseFloat(item1.Factor_Value__c);

                        }
                        else if(item1.Rating_Modifier__r.Product__c == 'EPL' && item1.Rating_Modifier__r.Rating_Modifier_Code__c == 'EPL000001'){
                            percentCA = parseFloat(item1.Factor_Value__c);
                        }
                        else{
                            if(!item1.Rating_Modifier__r.Rating_Modifier_Code__c.includes('Notes0000')){
                                console.log('item1.Factor_Value__c--->'+item1.Factor_Value__c);
                                OverallRatingMod *= item1.Factor_Value__c;
                                console.log('OverallRatingMod--->'+OverallRatingMod);
                            }
                        }
                    });
                    item.overallRatingModifier = OverallRatingMod.toFixed(3);
                    item.snTModifier = sTnCMod.toFixed(3);
                    if(OverallRatingMod > stateMax){
                        OverallRatingMod = stateMax;
                    }
                    else if(OverallRatingMod < stateMin){
                        OverallRatingMod = stateMin;
                    }
                    //item.overallRatingModifier = OverallRatingMod;
                    console.log('OverallRatingMod'+OverallRatingMod);
                    if(reqLimit < 1000000){
                        cLRF = parseFloat(item.limitfactor) * parseFloat(item.retentionFactor);
                    }
                    else if(reqLimit >= 1000000 && pRetention < 1000000){
                        cLRF = parseFloat(item.limitfactor) + parseFloat(item.retentionFactor) - 1;
                    }
                    else if(reqLimit >= 1000000 && pRetention >= 1000000){
                        var ILFLimitRetention = ((reqLimit + pRetention) / 1000000) ** (formulaExponent);
                        var ILFRetention = ((pRetention) / 1000000) ** (formulaExponent);
                        cLRF = ILFLimitRetention - ILFRetention;
                    }
                    item.cLRF = cLRF;
                    var baseRate = 0;
                    if(item.productName === 'EPL'){
                        if(item.employeeDetails){
                            var employeeDetails = item.employeeDetails;
                            var rateableEmplyee = employeeDetails.fullTimeEmployee + (employeeDetails.partTimeEmployee * partTimeRatio) + (employeeDetails.foreignEmployee * foreignRatio);
                            rateableEmplyee = rateableEmplyee > 2500 ? 2500 : rateableEmplyee;
                            employeeDetails.rateableEmplyee = rateableEmplyee;
                            this.rateableEmplyee = rateableEmplyee;
                            if(employeeDetails.listRatableEmployeeFactorTable){
                                employeeDetails.listRatableEmployeeFactorTable.forEach(item2=>{
                                    if(rateableEmplyee >= item2.lowerValue && rateableEmplyee < item2.upperValue){
                                        var rateableEmployeeFactor = item2.rateableEmployeeFactor;
                                        var base_rate = parseFloat(rateableEmployeeFactor.base_rate);
                                        var perEmployeeRate = parseFloat(rateableEmployeeFactor.per_employee_rate);
                                        var rangeLowerLimit = parseFloat(rateableEmployeeFactor.range_lower_limit);
                                        baseRate = (base_rate + ((rateableEmplyee - rangeLowerLimit) * perEmployeeRate)) * item.stateRelativityFactor;
                                        console.log('baseRate'+baseRate);
                                    }
                                });
                            }
                            item.employeeDetails = employeeDetails;
                            item.baseRate = baseRate;
                        }
                    }
                    else if(item.productName === 'D&O'){
                        baseRate = parseInt(item.baseRate);
                    }
                    else{
                        baseRate = parseInt(item.baseRate);
                    }
                    console.log('baseRate'+baseRate);
                    console.log('cLRF'+cLRF);
                    console.log('IndustryMod'+IndustryMod);
                    console.log('OverallRatingMod'+OverallRatingMod);
                    console.log('sTnCMod'+sTnCMod);
                    console.log('test'+baseRate.toFixed(3)+'------'+cLRF.toFixed(3)+'------'+IndustryMod+'------'+OverallRatingMod.toFixed(3)+'------'+sTnCMod+'------'+commissionAdjustmentFactor.toFixed(3)+'------'+policyPeriodAdjustmentFactor.toFixed(3));
                    indicativePremium = baseRate.toFixed(3) * cLRF.toFixed(3) * IndustryMod * OverallRatingMod.toFixed(3) * sTnCMod * commissionAdjustmentFactor.toFixed(3) * policyPeriodAdjustmentFactor.toFixed(3);
                    if(item.productName === 'EPL'){
                        indicativePremium =  percentCA ? indicativePremium * percentCA : indicativePremium;
                    }
                    item.actualPremiumWOOptionalCoverage = indicativePremium.toFixed(0);
                    if(item.listOptionalCoverages){
                        var optionalfactor = 1;
                        item.listOptionalCoverages.forEach(itemOptional=>{
                            if(itemOptional.isCoveraheRequired === true){
                                if(item.productName === 'EPL'){
                                    if(itemOptional.coverageCode === 'EPLClassRetentionCoverage'){
                                        indicativePremium = itemOptional.factorValue && itemOptional.factorValue != 0 ? indicativePremium * parseFloat(itemOptional.factorValue) : indicativePremium
                                    }
                                    else{
                                        optionalfactor = itemOptional.factorValue ? optionalfactor + parseFloat(itemOptional.factorValue) : optionalfactor;
                                    }
                                }
                                else if(item.productName === 'Crime'){
                                    if(itemOptional.coverageCode === 'CrimeExpense'){
                                        indicativePremium = indicativePremium + parseFloat(itemOptional.factorValue);
                                    }
                                    else{
                                        indicativePremium = indicativePremium + parseFloat(itemOptional.factorValue) * indicativePremium;
                                    }
                                }
                                else{
                                    optionalfactor = itemOptional.factorValue ? optionalfactor + parseFloat(itemOptional.factorValue) : optionalfactor;
                                }
                            }
                        });
                        indicativePremium *= optionalfactor;
                    }
                    if(this.quoteLayer === 'Excess'){
                        var underlyingExcessLimit = this.underlyingExcessLimit;
                        var underlyingExcessAttachment = this.underlyingExcessAttachment;
                        var premiumBase = indicativePremium / cLRF ;
                        var iLFAtt = ((reqLimit + pRetention + underlyingExcessAttachment) / 1000000 ) ** formulaExponent;
                        var iLFAttLimit = ((reqLimit + pRetention + underlyingExcessAttachment + underlyingExcessLimit) / 1000000 ) ** formulaExponent;
                        var xsffFactor = iLFAttLimit - iLFAtt;
                        var excessPremium = premiumBase * xsffFactor;
                        indicativePremium = excessPremium;
                        console.log('excessPremium'+excessPremium);
                    }
                    
                }
                item.actualPremium = indicativePremium.toFixed(0);
                totalPremium = totalPremium + parseFloat(indicativePremium.toFixed(0));
            //}
        });
        console.log('ratingModifiers---->'+ratingModifiers);
        this.ratingModifiers = ratingModifiers;
        this.totalPremium = totalPremium;


    }

    handleOptionalFactorValueChange(event){

        var optionalCoverages = JSON.parse(JSON.stringify(event.detail.optionalCoverages));
        var productName = JSON.parse(JSON.stringify(event.detail.productName));
        var reCalculatePremium = JSON.parse(JSON.stringify(event.detail.reCalculatePremium));
        var ratingModifiers = JSON.parse(JSON.stringify(this.ratingModifiers));
        ratingModifiers.forEach(item=>{
            if(item.productName === productName){
                item.listOptionalCoverages.forEach(item1=>{
                    if(item1.coverageCode === optionalCoverages.coverageCode){
                        item1.listCoverageLineItems.forEach(item2=>{
                            optionalCoverages.listCoverageLineItems.forEach(itemCLI=>{
                                if(item2.Id === itemCLI.Id){
                                    item2.Option_Value_Default__c = itemCLI.Option_Value_Default__c;
                                }
                            });
                        });
                        if(item1.optionalRatingModifierFactor){
                            item1.optionalRatingModifierFactor.Factor_Value__c = optionalCoverages.optionalRatingModifierFactor.Factor_Value__c;
                            if(optionalCoverages.optionalRatingModifierFactor.Rating_Modifier__r.Rating_Modifier_Value__c){
                                item1.optionalRatingModifierFactor.Rating_Modifier__r.Rating_Modifier_Value__c = optionalCoverages.optionalRatingModifierFactor.Rating_Modifier__r.Rating_Modifier_Value__c;
                            }
                        }
                        if(optionalCoverages.factorValue){
                            item1.factorValue = optionalCoverages.factorValue;
                        }
                    }
                });
            }
        });
        console.log('here');
        this.ratingModifiers = ratingModifiers;
        console.log('here'+reCalculatePremium);
        if(reCalculatePremium === true){
            this.calculatePremium();
        }

    }
    
    @api
    handleSaveAndRate(event){
        
        var showError = this.validateRatingModifiers();
        if(!showError){
            this.isLoading = true;
            var ratingModifiers = JSON.parse(JSON.stringify(this.ratingModifiers));
            var listOptionalCoverages = [];
            ratingModifiers.forEach(item=>{
                item.listOptionalCoverages.forEach(item1=>{
                    listOptionalCoverages.push(item1);
                });
            });
            saveRatingModifiers({
                ratingModifiers : ratingModifiers ,
                listOptionalCoverages : listOptionalCoverages,
                quoteId : this.quoteId ,
                underlyingExcessLimit : this.underlyingExcessLimit,
                underlyingExcessAttachment : this.underlyingExcessAttachment
            }).then(response => {
                if (response === 'success') {
                    /*this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Rating Modifiers Successfully Updated',
                            message: 'Success',
                            variant: 'Success'
                        })
                    );*/
                    this.dispatchEvent(new CustomEvent('saveandratepremiumcalc'));
                    //this.handleRefreshPremiumCalculator();
                }
                else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error updating modifiers',
                            message: response,
                            variant: 'error'
                        })
                    );
                }
                //this.handleRefreshPremiumCalculator();
                this.isLoading = false;
            });
        }
        else{
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Please provide a valid input for Limits and Modifiers',
                    message: response,
                    variant: 'error'
                })
            );
        }
    }

    validateRatingModifiers(){
        var showError = false;
        var ratingModifiers = JSON.parse(JSON.stringify(this.ratingModifiers));
        ratingModifiers.forEach(item=>{
            if(item.requiredLimit > 10000000 || item.policyRetention > 750000){
                showError = true;
            }
            item.listRatingModifier.forEach(item1=>{
                console.log(item1.Factor_Value__c);
                if(item1.Rating_Modifier__r.Rating_Modifier_Value__c){
                    var temp = item1.Rating_Modifier__r.Rating_Modifier_Value__c;
                    var ratingModVal = temp.replace(',','');
                    var tempCode = item1.Rating_Modifier__r.EPL_PctEmployeesInCA;
                    if(tempCode){
                        if(tempCode === 'EPL_PctEmployeesInCA'){
                            var Range_Lower,Range_Upper;
                            if(parseFloat(ratingModVal) < 10){
                                Range_Lower = "1.00";
                                Range_Upper = "1.10";
                            }
                            else if(parseFloat(ratingModVal) >= 10 && parseFloat(ratingModVal) < 50){
                                Range_Lower = "1.10";
                                Range_Upper = "1.50";
                            }
                            else if(parseFloat(ratingModVal) >= 50){
                                Range_Lower = "1.50";
                                Range_Upper = "2.00";
                            }
                            if(parseFloat(item1.Factor_Value__c) > parseFloat(Range_Upper) || parseFloat(item1.Factor_Value__c) < parseFloat(Range_Lower)){
                                showError = true;
                            }
                        }
                        else if(tempCode === 1731 || tempCode === 1732){
                            var factorRangeMap =this.factorRangeMap[tempCode];
                            var factorRange = Object.values(factorRangeMap);
                            console.log('factorRange-->'+factorRange);
                            console.log('factorRange-->'+factorRange.length);
                            if(factorRange.length === 1){
                                var Range_Lower = parseFloat(factorRange[0].Range_Lower);
                                var Range_Upper = parseFloat(factorRange[0].Range_Upper);
                                if(parseFloat(item1.Factor_Value__c > Range_Upper) || parseFloat(item1.Factor_Value__c) < Range_Lower){
                                    showError = true;
                                }
                            }
                        }
                        else{
                            var factorRangeMap =this.factorRangeMap[tempCode];
                            var factorRange = factorRangeMap[ratingModVal];
                            if(factorRange){
                                var Range_Lower = parseFloat(factorRange.Range_Lower);
                                var Range_Upper = parseFloat(factorRange.Range_Upper);
                                if(parseFloat(item1.Factor_Value__c) > Range_Upper || parseFloat(item1.Factor_Value__c) < Range_Lower){
                                    showError = true;
                                }
                            }
                        }
                    }
                }
                else{
                    if(item1.Rating_Modifier__r.Rating_Reference_Name__c){
                        var tempCode = item1.Rating_Modifier__r.Rating_Reference_Name__c;
                        var factorRangeMap =this.factorRangeMap[tempCode];
                        var factorRange = Object.values(factorRangeMap);
                        console.log('factorRange-->'+factorRange);
                        console.log('factorRange-->'+factorRange.length);
                        if(factorRange.length === 1){
                            var Range_Lower = parseFloat(factorRange[0].Range_Lower);
                            var Range_Upper = parseFloat(factorRange[0].Range_Upper);
                            if(parseFloat(item1.Factor_Value__c) > Range_Upper || parseFloat(item1.Factor_Value__c) < Range_Lower){
                                showError = true;
                            }
                        }
                    }
                }
            });
        });
        console.log('showError'+showError);
        return showError;
        /*if(showError){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Please provide a valid input for Limits and Modifiers',
                    message: response,
                    variant: 'error'
                })
            );
        }*/
    }

    @api
    handleRefreshPremiumCalculator() {
        this.getRatingModifiers();// added by Jitendra on 07-Jan-2022 for MAT-80
        //refreshApex(this.wiredata);
        //console.log("this.wiredata" + this.wiredata);
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
            case 'EPL':
                formulaExponent = 0.52;
                break;
            case 'EPL':
                formulaExponent = 0.6;
                break;
          }
          return formulaExponent;

    }

    handleAdditionalCLIValueChange(event){

        var coverageLineItem = JSON.parse(JSON.stringify(event.detail.coverageLineItem));
        var productName = JSON.parse(JSON.stringify(event.detail.productName));
        var ratingModifiers = JSON.parse(JSON.stringify(this.ratingModifiers));
        ratingModifiers.forEach(item=>{
            if(item.productName === productName){
                item.listAdditionalCoverageLineItems.forEach(item1=>{
                    if(item1.Id === coverageLineItem.Id){
                        item1.Option_Value_Default__c = coverageLineItem.Option_Value_Default__c;
                    }
                });
            }
        });
        this.ratingModifiers = ratingModifiers;

    }


}