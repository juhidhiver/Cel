import { LightningElement,api,track } from 'lwc';

export default class GenerateOutputElementPremiumCalculatorOptionalLwc extends LightningElement {

    @api coverageLineItem;
    @api optionalCoverageName;
    @api productName;
    @api isOptional = false;
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
    @api isRange;
    @api readOnly = false;
    isRangeWoo = false;
    @api options = [];

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
        if(this._format == 'RangeWOO') {
            this.isRangeWoo = true;
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
        this.isRange = false;
    }

    connectedCallback() {
        var coverageLineItem = JSON.parse(JSON.stringify(this.coverageLineItem));
        var format = coverageLineItem.Option_Type__c;
        if(format){
            this.format = format;
            console.log('format-->'+format);
            console.log('this.format'+this.format);
        }
        if(coverageLineItem.Page_Section__c === 'Optional Coverage'){
            this.isOptional = true;
        }
        // Remove space from left 
        if(coverageLineItem.Limits_Deductibles__r.LmtDedCode__c == 'FiduciaryCoverageInsAggBMaxAggLOL' || coverageLineItem.Limits_Deductibles__r.LmtDedCode__c =='FiduciaryCoverageVolCompSettleRetention'){
            this.format = 'RangeWOO';
        }
        coverageLineItem.Option_Value__c = coverageLineItem.Option_Value__c ? coverageLineItem.Option_Value__c : coverageLineItem.Option_Value_Default__c ? coverageLineItem.Option_Value_Default__c : 0 ;
        var strPicklistOption = coverageLineItem.Option_Picklist__c;
        if(strPicklistOption){
            var optionsArr = strPicklistOption.split(";");
            optionsArr.forEach(key =>{
                //var value = key.replace(',','');  
                this.options.push({label : key, value : key});
            });
        }
    }

    handleChangeInput(event){

        var inputValue = event.target.value;
        var coverageLineItem = JSON.parse(JSON.stringify(this.coverageLineItem));
        if(inputValue){
            coverageLineItem.Option_Value_Default__c = inputValue;
        }
        this.coverageLineItem = coverageLineItem;
        if(coverageLineItem.Page_Section__c === 'Optional Coverage'){
            const editldEvt = new CustomEvent(
                "optionalclivaluechange", {
                detail: {
                    coverageLineItem : this.coverageLineItem,
                    productName : this.productName,
                    optionalCoverageName : this.optionalCoverageName
                },
            });
            this.dispatchEvent(editldEvt);
        }
        else{
            const editldEvt = new CustomEvent(
                "additionalclivaluechange", {
                detail: {
                    coverageLineItem : this.coverageLineItem,
                    productName : this.productName,
                    optionalCoverageName : this.optionalCoverageName
                },
            });
            this.dispatchEvent(editldEvt);
        }
        
    }

}