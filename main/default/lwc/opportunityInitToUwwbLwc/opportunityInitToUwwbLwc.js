import { LightningElement, api,track,wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import createQuoteProcess from '@salesforce/apex/QuoteProcessLWCController.createQuoteProcess';
import addAccount from '@salesforce/apex/QuoteProcessLWCController.addAccount';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import getRecordTypeObject from '@salesforce/apex/QuoteProcessLWCController.getRecordTypeObject';
import getDefaultProductName from '@salesforce/apex/QuoteProcessLWCController.getDefaultProductName';
import mapRecordTypeWithProductName from '@salesforce/apex/QuoteProcessLWCController.mapRecordTypeWithProductName';
import deletePlaceholderOppsAndGetProdId from '@salesforce/apex/productSelectionController.deletePlaceholderOppsAndGetProdId';

// For PlaceHolder Opportunity Insert
import SUBMISSION_OBJECT from '@salesforce/schema/Opportunity';
import SUBMISSION_NAME_FIELD from '@salesforce/schema/Opportunity.Name';
import SUBMISSION_CLOSEDATE_FIELD from '@salesforce/schema/Opportunity.CloseDate';
import SUBMISSION_EFFECTIVEDATE_FIELD from '@salesforce/schema/Opportunity.Effective_Date__c';
import SUBMISSION_STAGENAME_FIELD from '@salesforce/schema/Opportunity.StageName';
import SUBMISSION_RECORDTYPEID_FIELD from '@salesforce/schema/Opportunity.RecordTypeId';
import SUBMISSION_PRODUCT_FIELD from '@salesforce/schema/Opportunity.Product__c';
import SUBMISSION_TYPE_FIELD from '@salesforce/schema/Opportunity.Type';
import SUBMISSION_CREATE_FROM_QP_FIELD from "@salesforce/schema/Opportunity.Create_From_Quote_Process__c";

// To Associate QuoteProcess with the PlaceHolder Opp
import QUOTE_PROCESS_OBJECT from '@salesforce/schema/Quote_Process__c';
import QUOTE_PROCESS_ID_FIELD from '@salesforce/schema/Quote_Process__c.Id';
import QUOTE_PROCESS_SUBMISSION_FIELD from '@salesforce/schema/Quote_Process__c.Submission__c';
import QUOTE_PROCESS_STATUS_FIELD from '@salesforce/schema/Quote_Process__c.Status__c';

import { getObjectInfo, getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { getRecord, createRecord, updateRecord, deleteRecord, getRecordUi, getFieldValue, getFieldDisplayValue, getRecordCreateDefaults, createRecordInputFilteredByEditedFields, generateRecordInputForCreate, generateRecordInputForUpdate } from 'lightning/uiRecordApi';

import PCC_PROD_NAME from '@salesforce/label/c.Product_Name_for_PCC';
import DEFAULT_SUBMISSION_NAME_FOR_PCC from '@salesforce/label/c.DEFAULT_SUBMISSION_NAME_PCC';



export default class OpportunityInitToUwwbLwc extends NavigationMixin(LightningElement) {
    @api quoteProcessId;
    @api accountId = '';
    @api accountPage = '';
    @api recordTypeId = '';
    submbissionRecordTypeId

    @track productOptions;
    @track defaultProductByRecordTypes;
    @track defaultProductByRecordType;

    @track recordTypeOptions;
    @track recordTypeName;
    @track recordTypeProducts;
    @track record;

    @wire(getObjectInfo,{objectApiName:SUBMISSION_OBJECT})
    getOppInfo

    getRecordTypeId(recordTypeName) {
        let recordtypeinfo = this.getOppInfo.data.recordTypeInfos;
        let recordTypeId
        for(var eachRecordtype in  recordtypeinfo){
            if(recordtypeinfo[eachRecordtype].name===recordTypeName){
                recordTypeId = recordtypeinfo[eachRecordtype].recordTypeId;
                break;
            }
        }
        return recordTypeId;
    }

    disconnectedCallback(){
        this.dispatchEvent(new CustomEvent('destroy'));
    }

    get disabledBtn(){
        return !this.recordTypeOptions || !this.productOptions;
    }

    connectedCallback() {
        getRecordTypeObject({sObjectName: 'Opportunity'}).then(data => {
            if (data) {
                let recordTypeInfos =  Object.entries(data);
                if(recordTypeInfos) {
                    let temp = [];
                    let recordTypeNameOptions = [];
                    let checked = false;
                    recordTypeInfos.forEach(([key, value]) => {
                    temp.push({"label" : value.label, "value" : value.value});
                    recordTypeNameOptions.push(value.label);
                    if(this.recordTypeId === value.value && !checked) {
                        this.recordTypeName = value.label;
                        checked = true;
                    }
                    });
                    this.recordTypeOptions = temp;
                    if(!this.recordTypeId && this.recordTypeOptions) {
                    this.recordTypeId = this.recordTypeOptions[0].value;
                    this.recordTypeName = this.recordTypeOptions[0].label;
                    }
                   getDefaultProductName({recordTypeNames : recordTypeNameOptions})
                    .then((result) => {
                        this.defaultProductByRecordTypes = result;
                        this.defaultProductByRecordType = this.defaultProductByRecordTypes[this.recordTypeName];
                    });
                    mapRecordTypeWithProductName({recordTypeName: this.recordTypeName}).then(
                        data => {
                        this.recordTypeProducts = data;
                        this.productOptions = this.recordTypeProducts[this.recordTypeName];
                        console.log('Products: '+JSON.stringify(this.productOptions));
                        }
                    );
                }
            }
        })
    }


    navigateToRecordViewPage() {
        console.log('This is recordId: ' + this.quoteProcessId);
        let pageRef = {
            type: 'standard__recordPage',
            attributes: {
                recordId: this.quoteProcessId,
                objectApiName: 'Quote_Process__c',
                actionName: 'view'
            },
            state: {
                //c__recordId : this.recordId
            }
        };
        this[NavigationMixin.Navigate](pageRef);
    }

    
    handleChangeProductOptions(event) {
        console.log('Change Product:' + event.target.value);
        this.defaultProductByRecordType = event.target.value
    }
    closeChooseRecordTypeModal() {
        console.log('inside closeChooseRecordTypeModal');
        this.dispatchEvent(new CustomEvent('close'));
        this.dispatchEvent(new CustomEvent('ultilitybarclose'));
    }

    handleClickNextWithRecordType(){
        console.log('recordTypeName: '+JSON.stringify(this.recordTypeName)+ 'productName: '+JSON.stringify(this.defaultProductByRecordType));
        this.submbissionRecordTypeId = this.getRecordTypeId('Celerity');
        createQuoteProcess({recordTypeName : this.recordTypeName, productName : this.defaultProductByRecordType})
        .then(result => {
                this.quoteProcessId = result;
                if(this.defaultProductByRecordType != PCC_PROD_NAME){
                    if (this.accountPage == 'Account') {
                        addAccount({ quoteProcessId: this.quoteProcessId, accountId: this.accountId }).then(result => {
                            console.log('addAccount ');
                            this.dispatchEvent(new CustomEvent('ultilitybarclose'));
                            this.navigateToRecordViewPage();
                        })
                    } else {
                        this.dispatchEvent(new CustomEvent('ultilitybarclose'));
                        this.navigateToRecordViewPage();
                    }
                }else{
                    
                    var closeDate = new Date();
                    closeDate.setDate(new Date().getDate() + 90);
        
                    let effectiveDate = this.formatDateWithDaysAdded(1);


                    deletePlaceholderOppsAndGetProdId({prodName:PCC_PROD_NAME})
                    .then((prodId)=>{
                        this.productId = prodId
                        const fields = {};

                        fields[SUBMISSION_NAME_FIELD.fieldApiName] = DEFAULT_SUBMISSION_NAME_FOR_PCC;
                        fields[SUBMISSION_CLOSEDATE_FIELD.fieldApiName] = closeDate;
                        //fields[SUBMISSION_EFFECTIVEDATE_FIELD.fieldApiName] = effectiveDate;
                        fields[SUBMISSION_RECORDTYPEID_FIELD.fieldApiName] = this.submbissionRecordTypeId;
                        fields[SUBMISSION_STAGENAME_FIELD.fieldApiName] = 'New'
                        fields[SUBMISSION_TYPE_FIELD.fieldApiName] = "New Business";
                        fields[SUBMISSION_PRODUCT_FIELD.fieldApiName] = this.productId;
                        fields[SUBMISSION_CREATE_FROM_QP_FIELD.fieldApiName] = true;
                        
                        let recordInput = {apiName:SUBMISSION_OBJECT.objectApiName,fields:fields}
                        createRecord(recordInput).then(result=>{
                            console.log('Result-->',result)
                            this.oppId = result.id
                            console.log('Opp id -->',this.oppId )
                            const fields = {}
                            fields[QUOTE_PROCESS_ID_FIELD.fieldApiName] = this.quoteProcessId
                            fields[QUOTE_PROCESS_SUBMISSION_FIELD.fieldApiName] = this.oppId
                            fields[QUOTE_PROCESS_STATUS_FIELD.fieldApiName] = 'Submission Console'
                            
                            const recordInput = { fields }
                            updateRecord(recordInput)
                            .then(()=>{
                                this.showSpinner = false
                                this.navigateToSubmissionRecordViewPage(this.oppId)
                            })
                        })
                    })
                    .catch(error => {
                        this.showSpinner = false
                        console.log('Error Creating Quoteprocess: '+ JSON.stringify(error));
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'title',
                            message: error.message,
                            variant: 'error'
                        }));
                    });
                }
            })
            .catch(error => {
                console.log('Error Creating Quoteprocess: '+ JSON.stringify(error));
            });
    }
    navigateToSubmissionRecordViewPage(oppId){
        console.log('Oppid -->',oppId)
        let pageRef = {
            type: 'standard__recordPage',
            attributes: {
                recordId: oppId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            },
            state: {
                //c__recordId : this.recordId
            }
        };
        this[NavigationMixin.Navigate](pageRef);
    }
    formatDateWithDaysAdded(days){
        let d = new Date();
        d.setDate(d.getDate() + days);
        let month = '' + (d.getMonth() + 1);
        let day = '' + d.getDate();
        let year = d.getFullYear();

        if (month.length < 2) 
            month = '0' + month;
        if (day.length < 2) 
            day = '0' + day;
        return [year, month, day].join('-');
    }
  //Used for creating Record Start
   /* @wire(getRecordTypeObject, { sObjectName: 'Opportunity' })
    wiredObjectInfo({ error, data }) {
        if (data) {
            let recordTypeInfos =  Object.entries(data);;
            console.log("ObjectInfo length", recordTypeInfos.length);
            if(recordTypeInfos) {
                let temp = [];
                let recordTypeNameOptions = [];
                recordTypeInfos.forEach(([key, value]) => {
                console.log(key);
                temp.push({"label" : value.label, "value" : value.value});
                recordTypeNameOptions.push(value.label);
                if(value.defaultRecordTypeMapping) {
                    this.recordTypeId = value.value;
                    this.recordTypeName = value.label;
                }
                });
                this.recordTypeOptions = temp;
                if(!this.recordTypeId && this.recordTypeOptions) {
                this.recordTypeId = this.recordTypeOptions[0].value;
                this.recordTypeName = this.recordTypeOptions[0].label;
                }
                getDefaultProductName({recordTypeNames : recordTypeNameOptions})
                .then((result) => {
                this.defaultProductByRecordTypes = result;
                this.defaultProductByRecordType = this.defaultProductByRecordTypes[this.recordTypeName];
                });
            }
            

        }
        else if (error) {
            this.record = undefined;
            console.log("error ", error);
        }
    }*/
  
  handleRecTypeChange(event) {
      console.log('RecordType: '+this.recordTypeId);
    this.recordTypeId = event.target.value;
    this.recordTypeOptions.forEach(item => {
        if(item.value == this.recordTypeId) {
          this.recordTypeName = item.label;
          this.productOptions = this.recordTypeProducts[this.recordTypeName];
          this.defaultProductByRecordType = this.defaultProductByRecordTypes[this.recordTypeName];
        }
    });
  }
}