import { LightningElement,api,track } from 'lwc';

export default class GenerateOutputElementPremiumCalculatorLwc extends LightningElement {

    @api ratingModifierFactor;
    @api ratingModifier;
    @api listCoverageLineItems;
    @api factorRangeMap;
    @api productName;
    @api fieldName;
    @api cLRF;
    @api range;
    @api rangeLower;
    @api rangeUpper;
    @api factorValue;
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
    @api isRicktext;
    @api isUndefined;
    @api isDOExecCoverage = false;
    @api optionalLoading;
    @api readOnly = false;
    @api options = [];
    @api limitfactor;

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
        if(this._format == 'Rich Text Area') {
            this.isRicktext = true;
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
        this.isRicktext = false;
    }

    connectedCallback() {
        console.log('in Connected Callback');
        var format = this.ratingModifier.Format__c;
        if(format){
            this.format = format;
            console.log('format-->'+format);
            console.log('this.format'+this.format);
        }
        if(this.ratingModifier.Coverage_Code__c === 'DOExecsCoverage'){
            this.isDOExecCoverage = true;
        }
        var fieldName = this.ratingModifier.Name;
        console.log('fieldName-->'+fieldName);
        this.factorValue = this.ratingModifierFactor.Factor_Value__c;
        console.log('Rating_Modifier_Value__c'+this.ratingModifier.Rating_Modifier_Value__c);
        if(this.ratingModifier.Rating_Modifier_Value__c){
            var temp = this.ratingModifier.Rating_Modifier_Value__c;
            var ratingModVal = temp.replace(',','');
            console.log('ratingModVal',ratingModVal)
            /*if(this.productName == 'EPL'){
                ratingModVal = this.upperCaseFirstLetter(this.lowerCaseAllWordsExceptFirstLetters(ratingModVal));
                this.ratingModifier.Rating_Modifier_Value__c = ratingModVal;
                console.log('ratingModVal----liwercase----->'+ratingModVal);
            }*/
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
                        var listCoverageLineItems = JSON.parse(JSON.stringify(this.listCoverageLineItems));
                        listCoverageLineItems.forEach(item=>{
                            if(item.Coverage__r.Coverage_Code__c === this.ratingModifier.Coverage_Code__c){
                                var factorRange = JSON.parse(JSON.stringify(factorRangeMap[item.Option_Value_Default__c]));
                                if(factorRange){
                                    var Range_Lower = factorRange.Range_Lower;
                                    var Range_Upper = factorRange.Range_Upper;
                                    this.rangeLower = Range_Lower;
                                    this.rangeUpper = Range_Upper;
                                    this.range = Range_Lower + ' - ' +Range_Upper;
                                    fieldName = 'Selected rate if required';
                                    this.factorValue = parseFloat(Range_Upper) > 0 ? ((parseFloat(Range_Upper) + parseFloat(Range_Lower)) / 2).toFixed(3) : 0;

                                }
                            }
                        });
                    }
                }
            }
            this.fieldName = fieldName;

        }
        
        
        
    }

    handleChangeInput(event){

        var optionValue = event.target.value;
        optionValue = optionValue.trim();
        console.log('optionValue'+optionValue);
        var ratingModifier = JSON.parse(JSON.stringify(this.ratingModifier));
        var ratingModifierFactor = JSON.parse(JSON.stringify(this.ratingModifierFactor));
        var tempCode = ratingModifier.Rating_Reference_Name__c;
        var Range_Lower;
        var Range_Upper;
        if(tempCode){
            if(tempCode === 'EPL_PctEmployeesInCA'){
                if(parseFloat(optionValue) < 10){
                    var Range_Lower = "1.00";
                    var Range_Upper = "1.10";
                }
                else if(parseFloat(optionValue) >= 10 && parseFloat(optionValue) < 50){
                    var Range_Lower = "1.10";
                    var Range_Upper = "1.50";
                }
                else if(parseFloat(optionValue) >= 50){
                    var Range_Lower = "1.50";
                    var Range_Upper = "2.00";
                }
                this.rangeLower = Range_Lower;
                this.rangeUpper = Range_Upper;
                this.range = Range_Lower + ' - ' +Range_Upper;
                this.factorValue = (parseFloat(Range_Lower) + parseFloat(Range_Upper)) / 2;
                ratingModifierFactor.Factor_Value__c = this.factorValue;
            }
            else{
                var factorRangeMap =this.factorRangeMap[tempCode];
                var factorRange = factorRangeMap[optionValue];
                if(factorRange){
                    Range_Lower = factorRange.Range_Lower;
                    Range_Upper = factorRange.Range_Upper;
                    this.rangeLower = Range_Lower;
                    this.rangeUpper = Range_Upper;
                    this.range = Range_Lower + ' - ' +Range_Upper;
                    this.factorValue = ((parseFloat(Range_Lower) + parseFloat(Range_Upper)) / 2).toFixed(3);
                    ratingModifierFactor.Factor_Value__c = this.factorValue;
                }
            }
        }
        ratingModifier.Rating_Modifier_Value__c = optionValue;
        this.ratingModifier = ratingModifier;
        this.ratingModifierFactor = ratingModifierFactor;

        /*let factorCmp = this.template.querySelector(".factorCmp");
        if( factorCmp ){
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
        }*/
        const editldEvt = new CustomEvent(
            "factoroptionchange", {
            detail: {
                ratingModifier : this.ratingModifier,
                ratingModifierFactor : this.ratingModifierFactor,
                productName : this.productName
            },
        });
        this.dispatchEvent(editldEvt);
        
    }

    handleChangeFactorValue(event){

        var factorValue = event.target.value;
        console.log('factorValue'+factorValue);
        var ratingModifierFactor = JSON.parse(JSON.stringify(this.ratingModifierFactor));
        ratingModifierFactor.Factor_Value__c = factorValue;
        this.ratingModifierFactor = ratingModifierFactor;
        let factorCmp = this.template.querySelector(".factorCmp");
        let factorCmpValue = factorCmp.value;
        console.log(factorCmpValue);
        if(factorCmpValue === factorValue && factorCmpValue <= this.rangeUpper && factorCmpValue >= this.rangeLower){
            console.log(this.rangeUpper);
            factorCmp.setCustomValidity("");
        }
        factorCmp.reportValidity();
        if(this.isDOExecCoverage === true){
            this.calculateLoadingforExecLimit(factorValue);
        }
        const editldEvt = new CustomEvent(
            "factorvaluechange", {
            detail: {
                ratingModifierFactor : this.ratingModifierFactor,
                productName : this.productName
            },
        });
        this.dispatchEvent(editldEvt);

    }

    calculateLoadingforExecLimit(value){

        var factorValue = value;
        var ratingModifier = JSON.parse(JSON.stringify(this.ratingModifier));
        var limitFactor = this.limitfactor;
        var execILF = this.cLRF;
        //var execFactor = this.execFactor;
        var optionalLoading = (factorValue * execILF) / limitFactor;
        this.optionalLoading = optionalLoading.toFixed(3);
        //this.calculatePremium(productName);
    }

    upperCaseFirstLetter(string) {
        return string.charAt(0).toUpperCase() + string.slice(1);
    }
    
    lowerCaseAllWordsExceptFirstLetters(string) {
        return string.replace(/\S*/g, function (word) {
            return word.charAt(0) + word.slice(1).toLowerCase();
        });
    }

    @api
    handleratingFactorValue(value1,value2){
        console.log('test');
        var coverageLineItem = value1;
        this.cLRF = value2;
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
                    this.factorValue = parseFloat(Range_Upper) > 0 ? (parseFloat(Range_Upper) + parseFloat(Range_Lower)) / 2 : 0;
                    this.calculateLoadingforExecLimit(this.factorValue);
                }
           // }
        }

    }

}