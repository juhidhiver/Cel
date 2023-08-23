/* eslint-disable no-console */
/* eslint-disable @lwc/lwc/no-async-operation */

import lookUp from '@salesforce/apex/LookupController.lookUp';
import getObjectById from '@salesforce/apex/LookupController.getObjectById';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import NAME_FIELD from "@salesforce/schema/Account.Name";
import { api, LightningElement, track, wire } from 'lwc';

let FIELDS = ['User.Owner.Name'];

export default class LookUpLwc extends LightningElement {

    @api valueId;
    @api _objName;
    @api fieldName;
    @api iconName;
    @api labelName;
    @api readOnly;
    @api required;
    @api filter = '';
    @api showLabel = false;
    @api uniqueKey;
    objLabelName;

    /*Create Record Start*/
    @api recordTypeName;
    @api createRecord;
    @track recordTypeOptions;
    @track createRecordOpen;
    @track recordTypeSelector;
    @track mainRecord;
    @track isLoaded = false;

    @api isCelerity;

    /*  @track isShowpill = true;
      @api isPillRequired;*/
    //stencil
    @track cols = [1, 2];
    @track opacs = ['opacity: 1', 'opacity: 0.9', 'opacity: 0.8', 'opacity: 0.7', 'opacity: 0.6', 'opacity: 0.5', 'opacity: 0.4', 'opacity: 0.3', 'opacity: 0.2', 'opacity: 0.1'];
    @track double = true;

    //For Stencil
    @track stencilClass = '';
    @track stencilReplacement = 'slds-hide';
    //css
    @track myPadding = 'slds-modal__content';
    /*Create Record End*/

    @api searchTerm; // long update to add @api
    @track valueObj;
    href;
    @track options; //lookup values
    @track isValue;
    @track blurTimeout;

    blurTimeout;

    //css
    @track boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    @track inputClass = 'inputCmp';

    @track fieldList = [];

    // Rendered CallBack check
    isLoaded = false


    @api get objName() {
        return this._objName;
    }
    set objName(value) {
        this._objName = value;
        console.log('@@@value objName: ' + value);        
          var fieldName = value + '.Name';
        this.fieldList.push(fieldName);
    }

    selectedIdReturned;
    @api getSelectedIdReturned() {
        var infos = { objectname: this._objName, key: this.fieldName, value: this.selectedIdReturned, Name: this.searchTerm, type: 'lookup' };
        return infos;
    }

    @api checkValidity() {
        var inputCmp = this.template.querySelector(".inputCmp");
        if (inputCmp) {
            var value = inputCmp.value;
            if (!value) {
                inputCmp.setCustomValidity("Please Enter a valid Value");
                inputCmp.focus();
            } else {
                inputCmp.setCustomValidity("");
                inputCmp.value = value;
            }
            inputCmp.reportValidity();
        }
    }

    @api resetSelectedIdReturned() {
        var field = this.template.querySelector('.inputCmp');
        if (field) field.reset();
        console.log('lookup fields :' , field );
    }
    
    // Vivek on 21-07-2022 for clearing input box ,Bug -58570 
    @api clearInputBox(){
        this.handleRemovePill();
    }

    connectedCallback() {
        //console.log("Pill", this.isPillRequired);

        //Added by Vinayesh
        if(this.isCelerity == undefined){
            this.isCelerity = true;
        }
        console.log("objName", this._objName);
        // FIELDS.push(this.objName+'.Name');
        console.log("FIELDS", FIELDS);
        console.log("filter", this.filter);
    }

    renderedCallback() {

        //Logic added to increase pill size to 100% width 

            if(this.template.querySelector('lightning-pill')){
                const style = document.createElement('style')
                style.innerText= `c-look-up-lwc .slds-pill{
                    width:100%!important;
                }`
                this.template.querySelector('lightning-pill').appendChild(style)
            }


        // if (this.template.querySelector('lightning-pill')) {
        //     console.log(' Pill check')
            
        //     style.innerText = `.c-look-up-lwc .slds-pill{
        //         width:100%;
        //     }`
        //     const element = this.template.querySelector('lightning-pill')
        //     element.className += 'pillSize' 
        // }
            if (this._objName) {
                let temp = this._objName;
                if (temp.includes('__c')) {
                    let newObjName = temp.replace(/__c/g, "");
                    if (newObjName.includes('_')) {
                        let vNewObjName = newObjName.replace(/_/g, " ");
                        this.objLabelName = vNewObjName;
                    } else {
                        this.objLabelName = newObjName;
                    }

                } else {
                    this.objLabelName = this._objName;
                }
            }


            console.log("In rendered", this._objName);
        }

        //Used for creating Record Start
        @wire(getObjectInfo, { objectApiName: '$_objName' })
        wiredObjectInfo({ error, data }) {
            if (data) {
                this.record = data;
                this.error = undefined;

                let recordTypeInfos = Object.entries(this.record.recordTypeInfos);
                console.log("ObjectInfo length", recordTypeInfos.length);
                if (recordTypeInfos.length > 1) {
                    let temp = [];
                    recordTypeInfos.forEach(([key, value]) => {
                        console.log(key);
                        if (value.available === true && value.master !== true) {
                            console.log("Inside ifff", JSON.stringify(key, value));

                            temp.push({ "label": value.name, "value": value.recordTypeId });
                        }
                    });
                    this.recordTypeOptions = temp;
                    console.log("recordTypeOptions", this.recordTypeOptions);
                } else {
                    this.recordTypeId = this.record.defaultRecordTypeId;
                }

                console.log("this.recordTypeOptions", JSON.stringify(this.recordTypeOptions));
            } else if (error) {
                this.error = error;
                this.record = undefined;
                console.log("this.error", this.error);
            }
        }
        //Used for creating Record End (, recordTypeName : '$recordTypeName')

        @wire(lookUp, { searchTerm: '$searchTerm', myObject: '$_objName', filter: '$filter' })
        wiredRecords({ error, data }) {
            console.log('search: ',this.searchTerm, 'object:  ',this.objName, 'filter: ',this.filter);
            if (data) {
                console.log('Return Values: ' + JSON.stringify(data));
                var results = [];
                for (var i = 0; i < data.length; i++) {
                    var result = { Id: data[i].Id, Name: data[i].Name };
                    if(this.isCelerity){
                        if (data[i].Search_Label__c != undefined) {
                            result.Name += ' ' + data[i].Search_Label__c;
                            console.log('data: ' + data[i].Search_Label__c);
                        }
                        results.push(result);
                    }else{
                        if(data[i].Account != null){
                            if(data[i].Account.Pending_By_Aqueous__c || data[i].Account.Appointed__c){
                                if (data[i].Search_Label__c != undefined) {
                                    result.Name += ' ' + data[i].Search_Label__c;
                                }
                                results.push(result);
                            }
                        }
                    }

           
                   
                }
                console.log('isCelerity: ',this.isCelerity);
                this.record = results;
                this.error = undefined;
                this.options = this.record;
                
                console.log("common this.options", JSON.stringify(this.options));
            } else if (error) {
                this.error = error;
                this.record = undefined;
                console.log("wire.error", this.error);
            }
        }

        //To get preselected or selected record
        @wire(getRecord, { recordId: '$valueId', fields: '$fieldList' })
        wiredOptions({ error, data }) {
            console.log('this.fieldList'+JSON.stringify(this.fieldList))
            console.log('value id 2222222222222222222222222222222222:' + this.valueId);
            if (data) {
                console.log('Data from wired Option:' + data);

                this.record = data;
                console.log('this.record-->'+ JSON.stringify(this.record))
                this.error = undefined;
                
                /*************** New Condition for Auto Renewals */
          
                this.valueObj = this.record.fields.Name.value;
                this.href = '/' + this.record.id;
                this.isValue = true;
                this.selectedIdReturned = this.record.id;
                console.log("Value:", this.valueObj);
                console.log("this.href", this.href);
                console.log("this.record", JSON.stringify(this.record));
            } else if (error) {
                this.error = error;
                this.record = undefined;
                console.log("this.error", this.error);
            }
        }

        //when valueId changes
        valueChange() {
            console.log("In valueChange");
        }

        handleClick() {
            console.log("In handleClick");

            // this.searchTerm = '';
            this.inputClass = 'slds-has-focus inputCmp';
            this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';
            //let combobox = this.template.querySelector('#box');
            //combobox.classList.add("slds-is-open"); 
        }

        inblur() {
            console.log("In inblur");
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this.blurTimeout = setTimeout(() => { this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus' }, 300);
        }
        /*
        onSelect(event) {
            console.log("In onSelect");
            let ele = event.currentTarget;
            let selectedId = ele.dataset.id;
            console.log("In onSelect:" + JSON.stringify(ele.dataset));
            console.log("selectedId", selectedId);
            //As a best practise sending selected value to parent and inreturn parent sends the value to @api valueId
            let key = this.uniqueKey;
            const valueSelectedEvent = new CustomEvent('valueselect', {
                detail: { selectedId, key },
            });
            this.dispatchEvent(valueSelectedEvent);
    
            this.searchTerm  = event.target.name;
    
            if(this.blurTimeout) {
                clearTimeout(this.blurTimeout);
            }
            this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
        }*/

        onSelect(event) {
            console.log("In onSelect");
            let ele = event.currentTarget;
            let selectedId = ele.dataset.id;
            this.selectedIdReturned = selectedId;
            getObjectById({ objectId: selectedId, myObject: this._objName })
                .then(result => {
                    console.log("Success" + JSON.stringify(result));
                    //let resultReturned = JSON.parse(result); 
                    //console.log("Success111" + JSON.stringify(resultReturned));
                    let key = this.uniqueKey;
                    const valueSelectedEvent = new CustomEvent('valueselect', {
                        detail: { selectedId, key },
                    });
                    this.dispatchEvent(valueSelectedEvent);

                    this.searchTerm = result.Name;

                    if (this.blurTimeout) {
                        clearTimeout(this.blurTimeout);
                    }
                    this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
                })
                .catch(error => {
                    console.log("err0rrrrrr" + JSON.stringify(error));
                })


        }

        onChange(event) {
            console.log("In onChange");
            this.searchTerm = event.target.value;
            if(this.isCelerity){
                console.log('vinay event target: ' + event.currentTarget);
                let currTarget = event.currentTarget;
                currTarget.setCustomValidity("");
                currTarget.reportValidity();
            }
            console.log("searchTerm", this.searchTerm);
            const valueChangedEvent = new CustomEvent('valuechange', {
                detail: { searchTerm: this.searchTerm },
            });
            this.dispatchEvent(valueChangedEvent);
        }

        handleRemovePill() {
            console.log("In handleRemovePill");
            this.isValue = false;
            this.searchTerm = null;//long update
            let selectedId = '';
            let key = this.uniqueKey;
            this.selectedIdReturned = selectedId;
            const valueSelectedEvent = new CustomEvent('valueselect', {
                detail: { selectedId, key },
            });
            this.dispatchEvent(valueSelectedEvent);
        }

        createRecordFunc() {
            if (this.recordTypeOptions) {
                if (this.labelName == 'Additional Insurer') {
                    const createAdditional = new CustomEvent('createadditionalinsurer', {
                    });
                    this.dispatchEvent(createAdditional);

                } else {
                    this.recordTypeSelector = true;
                }
            } else {
                this.recordTypeSelector = false;
                this.mainRecord = true;
                //stencil before getting data
                this.stencilClass = '';
                this.stencilReplacement = 'slds-hide';
            }
            this.createRecordOpen = true;
        }

        handleRecTypeChange(event) {
            console.log("In handleRecTypeChange", event.target.value);
            this.recordTypeId = event.target.value;
        }

        createRecordMain() {
            this.recordTypeSelector = false;
            this.mainRecord = true;
            //stencil before getting data
            this.stencilClass = '';
            this.stencilReplacement = 'slds-hide';
        }

        handleLoad(event) {
            let details = event.detail;

            if (details) {
                setTimeout(() => {
                    this.stencilClass = 'slds-hide';
                    this.stencilReplacement = '';
                    this.myPadding = 'slds-p-around_medium slds-modal__content';
                }, 1000);
            }

        }

        handleSubmit() {
            this.template.querySelector('lightning-record-form').submit();
        }

        /*handleSuccess(event) {
     
            this.createRecordOpen = false;
            this.mainRecord = false;
            this.stencilClass = '';
            this.stencilReplacement = 'slds-hide';
    
            let selectedId = event.detail.id;
            let key = this.uniqueKey;
            const valueSelectedEvent = new CustomEvent('valueselect', {
                detail: { selectedId, key },
            });
            //this.dispatchEvent(valueSelectedEvent);
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title : 'Success',
                    message : `Record saved successfully with id: ${event.detail.id}`,
                    variant : 'success',
                }),
            )
        }*/

        handleSuccess(event) {

            this.createRecordOpen = false;
            this.mainRecord = false;
            this.stencilClass = '';
            this.stencilReplacement = 'slds-hide';
            let selectedId = event.detail.id;
            let key = this.uniqueKey;
            getObjectById({ objectId: selectedId, myObject: this._objName })
                .then(result => {
                    const valueSelectedEvent = new CustomEvent('valueselect', {
                        detail: { selectedId, key },
                    });
                    this.dispatchEvent(valueSelectedEvent);
                    this.searchTerm = result.Name;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: `Record saved successfully with id: ${event.detail.id}`,
                            variant: 'success',
                        }),
                    )
                })
                .catch(error => {
                    console.log("err0rrrrrr" + JSON.stringify(error));
                })


        }

        handleError() {

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error saving the record',
                    variant: 'error',
                }),
            )
        }

        closeModal() {
            this.stencilClass = '';
            this.stencilReplacement = 'slds-hide';
            this.createRecordOpen = false;
            this.recordTypeSelector = false;
            this.mainRecord = false;
        }


        @api recordInfo;
        @api isCustom = false;
        get recordInfoDefined() {
            return this.recordInfo !== undefined && this.recordInfo.fields !== undefined
        }
    }