import { LightningElement,api } from 'lwc';

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
    @api isEndorsement = false;

    @api min;
    @api max;
    

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
        if(this._format == 'Percent' || this._format == 'Percentage') {
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
        
    }
    handleChangeInput(event){
        const editFieldEvt = new CustomEvent(
            "editfield", {
            detail: {
                fieldId: event.target.name, fieldValue: event.target.value
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
                console.log(JSON.stringify('Min: '+ inputCmp.min  + ' Value : ' + this.fieldValue  + ' Max : ' + inputCmp.max ));
                if(parseFloat(this.fieldValue) <parseFloat(inputCmp.min) || parseFloat(this.fieldValue) > parseFloat(inputCmp.max)){
                    console.log(JSON.stringify('Why?: '+ inputCmp.min  + ' Value : ' + this.fieldValue  + ' Max : ' + inputCmp.max ));
                    return false;
                }
            }
        }
        let isValid = true;
        return isValid;
    }
    @api isaqueous;
}