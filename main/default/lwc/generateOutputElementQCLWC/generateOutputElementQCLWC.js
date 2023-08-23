import { LightningElement,api, track } from 'lwc';

export default class GenerateOutputElementLwc extends LightningElement {

    @api readOnly;
    @api fieldValue;
    @api objName;
    @api fieldName;
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
    @api child;
    @api quotefield;
    _compareItem;

    @api min;
    @api max;
    @api mainSection;
    @api sectionName;
    @api displayField = false;
    @api isQuotedStatus = false;

    @api fieldId;

    //tuan.d.nguyen added 25-Jun-2020
    @api options;
    _format;
    set format(value) {
        this.setAllFormatFalse();
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
        if(this._format == 'Percent') {
            this.isPercent = true;
        }
        if(this._format == 'Hyperlink'){
            this.isHyperlink = true;
        }
        if(this._format == 'Integer') {
            this.isInteger = true;
        }
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

    //GiangPhan added 29/Jun/2020
    connectedCallback() {
        if(this.readOnly === undefined)
            this.readOnly = false;  
            
        var child = this.child;
        console.log('child --: ', JSON.parse(JSON.stringify(child)));
        var quotefield;
        var clone = JSON.parse(JSON.stringify(this.compareItem));
        console.log('clone'+clone);
        clone.quoteFields.forEach(item => {
            console.log('item --: ', JSON.parse(JSON.stringify(item)));
            if(item.fieldName === child.name){
                this.format = item.format;
                this.fieldValue = item.value;
                this.fieldId = item.fieldId;
                this.options = item.options;
                this.objName = item.sourceFieldAPI;
                this.fieldName = item.fieldName;
                //this.readOnly = child.readOnly === undefined ? item.readOnly : child.readOnly;
                if(this.isQuotedStatus === true){
                    if(item.isAQQuotedFields === false){
                        this.readOnly = true;
                        console.log('this.readOnly-- inside aq if: ',this.fieldName,'', this.readOnly);
                    }
                    else{
                        this.readOnly = item.readOnly !== undefined ? item.readOnly : false;
                        console.log('this.readOnly-- inside qa  else: ',this.fieldName,'', this.readOnly);
                    }
                }
                else{
                    this.readOnly = item.readOnly !== undefined ? item.readOnly : false;
                }
                console.log('this.readOnly--: ',this.fieldName,'', this.readOnly);
            }

        })
        
    }
    kyTaxRate;
    handleChangeInput(event){
        console.log('vinay ' + this.objName);
        if(this.objName == 'KY_Tax_Rate__c'){
            let taxRate = event.detail.value;
            if(taxRate){
                let inputCmp = event.target;
                if(taxRate < 0 || taxRate > 15){
                    inputCmp.setCustomValidity("Value should be between 0 and 15%");
                    inputCmp.reportValidity();
                }
                else{
                    inputCmp.setCustomValidity('');
                    inputCmp.reportValidity();
                }
            } 
        }
        const editFieldEvt = new CustomEvent(
            "editfield", {
            detail: {
                fieldId: event.target.name, fieldValue: event.target.value, fieldName: this.objName
            },
        });
        this.dispatchEvent(editFieldEvt);
    }

    @api
    checkValid() {
        var inputCmp;
        inputCmp = this.template.querySelector("lightning-input");
        if(this._format == 'Picklist')
            inputCmp = this.template.querySelector('lightning-combobox');
        if(this._format == 'Hyperlink')
            inputCmp = this.template.querySelector('lightning-formatted-rich-text');

        let isValid = inputCmp.reportValidity()
        return isValid;
    }
    @api
    checkValueOutOfRange() {
        var inputCmp;
        inputCmp = this.template.querySelector("lightning-input");
        if(this._format == 'Range' || this._format =='Number'){
            if(this.fieldValue && inputCmp.min  && inputCmp.max ){
                console.log('valueooooo +........'+this.fieldValue);
                console.log(JSON.stringify('Min: '+ inputCmp.min  + ' Value : ' + this.fieldValue  + ' Max : ' + inputCmp.max ));
                if(parseFloat(this.fieldValue) <parseFloat(inputCmp.min) || parseFloat(this.fieldValue) > parseFloat(inputCmp.max)){
                    console.log(JSON.stringify('Why?: '+ inputCmp.min  + ' Value : ' + this.fieldValue  + ' Max : ' + inputCmp.max ));
                    return false;
                }
            }
        }
        if(this.objName == 'KY_Tax_Rate__c'){
            if(!this.fieldValue || this.fieldValue < 0 || this.fieldValue > 15){
                inputCmp.setCustomValidity("Value should be between 0 and 15%");
                inputCmp.reportValidity();
                return false;
            }
        }
        let isValid = true;
        return isValid;
    }
    @api isaqueous;

    set compareItem(value) {
        this._compareItem = value;
        if(this.child){
            var child = this.child;
            var quotefield;
            var clone = JSON.parse(JSON.stringify(this._compareItem));
            clone.quoteFields.forEach(item => {
                if(item.fieldName === child.name){
                    this.format = item.format;
                    this.fieldValue = item.value;
                    this.fieldId = item.fieldId;
                    this.options = item.options;
                    this.objName = item.sourceFieldAPI;
                    this.fieldName = item.fieldName;
                    if(this.isQuotedStatus === true){
                        if(item.isAQQuotedFields === false){
                            this.readOnly = true;
                        }
                        else{
                            this.readOnly = item.readOnly !== undefined ? item.readOnly : false;
                        }
                    }
                    else{
                        this.readOnly = item.readOnly !== undefined ? item.readOnly : false;
                    }
                }

            })
        }
        
    }

    @api
    get compareItem() {
        return this._compareItem;
    }

    @api
    handleRefreshOutputElememt(value){
        console.log('In handleRefreshOutputElememt');
        this._compareItem = value;
        if(this.isLookup){
            this.template.querySelector("c-look-up-lwc-aq").handleRefreshLookuo(this.fieldValue);
        }
    }
}