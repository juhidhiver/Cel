import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import fetchCoverageDetails from '@salesforce/apex/QuoteCoverageTableController.fetchCoverageDetails';
import { updateRecord } from 'lightning/uiRecordApi';
import SHAREDAGG_FIELD from '@salesforce/schema/Quote.Shared_Aggregate_Limit__c';
import BEFOREDISCOUNT_FIELD from '@salesforce/schema/Quote.Prior_Discount_Quote_Premium__c';
import AFTERDISCOUNT_FIELD from '@salesforce/schema/Quote.QuotePremium__c';
import MAXAGGLIMIT_FIELD from '@salesforce/schema/Quote.Combined_Max_Agg_Limit_of_Liability__c';
import ID_FIELD from '@salesforce/schema/Quote.Id';
import saveQuotePremium from '@salesforce/apex/QuoteCoverageTableController.saveQuotePremium';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from '@salesforce/apex';

const columnsPrimary = [
    { label: 'Coverage', fieldName: 'productName', type: 'text', editable: false, hideDefaultActions: true },
    { label: 'Limit', fieldName: 'requiredLimit', type: 'currency', typeAttributes: { currencyCode: 'USD' , currencyDisplayAs: 'symbol',minimumFractionDigits:0, maximumFractionDigits: 0 } , editable: false, hideDefaultActions: true },
    { label: 'Deductibles', fieldName: 'policyRetention', type: 'currency', typeAttributes: { currencyCode: 'USD' , currencyDisplayAs: 'symbol',minimumFractionDigits:0, maximumFractionDigits: 0 } , editable: false, hideDefaultActions: true },
    { label: 'Technical Premium', fieldName: 'technicalPremium', type: 'currency', typeAttributes: { currencyCode: 'USD' , currencyDisplayAs: 'symbol',minimumFractionDigits:0, maximumFractionDigits: 0} , editable: false, hideDefaultActions: true }
];

const columnsExcess = [
    { label: 'Coverage', fieldName: 'productName', type: 'text', editable: false, hideDefaultActions: true },
    { label: 'Primary Limit + SIR', fieldName: 'primartLimitRetention', type: 'currency', typeAttributes: { currencyCode: 'USD' , currencyDisplayAs: 'symbol' } , editable: false, hideDefaultActions: true },
    { label: 'Primary Technical Premium', fieldName: 'technicalPremium', type: 'currency', typeAttributes: { currencyCode: 'USD' , currencyDisplayAs: 'symbol' } , editable: false, hideDefaultActions: true },
    { label: 'Excess Technical Premium', fieldName: 'technicalExcessPremium', type: 'currency', typeAttributes: { currencyCode: 'USD' , currencyDisplayAs: 'symbol' } , editable: false, hideDefaultActions: true }
];


export default class QuoteCoverageTable extends NavigationMixin(LightningElement) {

    @api quoteId;
    @api isLoading = false;
    @track wiredata;
    @api totalPremiumBeforeDiscount = 0;
    @api totalPremiumAfterDiscount = 0;
    @api isAggShared = 'No';
    @api objQuote;
    @api disableShared;
    @track maxLiabilityLimit;
    @track maxAggLiabilityLimit;
    minAggLiabilityLimit;
    @track columns = [];
    combineMaxAggLiabilityLabel = '';
    maxLiabilityLabel = '';

    
    @api isAggSharedOptions = [
        { label: 'No', value: 'No' },
        { label: 'Yes - Two coverage sections', value: 'Yes - Two coverage sections' },
        { label: 'Yes - Three coverage sections', value: 'Yes - Three coverage sections' },
        { label: 'Yes - Four or more coverage sections', value: 'Yes - Four or more coverage sections' },
    ];

    data;

    /*@wire(fetchCoverageDetails, {
        quoteId: '$quoteId'
    })
    ratingData(result) {
        this.wiredata = result;
        var data = result.data;
        var error = result.error;
        if (data) {
            var listRecordDetails = data.listRecordDetails;
            this.data = listRecordDetails;
            var objQuote = data.objQuote;
            this.objQuote = objQuote;
            var totalPremiumBeforeDiscount = 0;
            listRecordDetails.forEach(item=>{
                if(item.technicalPremium){
                    totalPremiumBeforeDiscount += parseFloat(item.technicalPremium);
                    this.totalPremiumBeforeDiscount = totalPremiumBeforeDiscount;
                }
            });
            var isAggShared = objQuote.Shared_Aggregate_Limit__c;
            this.isAggShared = isAggShared;
            var discount = this.getDiscoountFactor(isAggShared);
            this.totalPremiumAfterDiscount = this.totalPremiumBeforeDiscount * discount;

        }
    }*/
    // added by Jitendra on 07-Jan-2022 for MTA-80  code start---
    connectedCallback(){
        this.getCoverageDetails();
    }

    // renderedCallback(){
    //     console.log('vinay input css');
    //     console.log("vinay " + this.template.querySelector(".slds-form_horizontal .slds-form-element__control"));
    //     if (this.template.querySelector(".slds-form-element__control.slds-grow") != null) {
    //         console.log('vinay input css');
    //     }
    // }

    getCoverageDetails(){
        fetchCoverageDetails({quoteId: this.quoteId})
        .then(response => {
            //this.wiredata = result;
            var data = response;
            //var error = result.error;
            if (data) {
                var listRecordDetails = data.listRecordDetails;
                this.data = listRecordDetails;
                var objQuote = data.objQuote;
                this.objQuote = objQuote;
                var totalPremiumBeforeDiscount = 0;
                let totalLimit = 0;
                if(objQuote.Layer__c === 'Excess'){
                    this.columns = columnsExcess;
                }
                else{
                    this.columns = columnsPrimary;
                }
                listRecordDetails.forEach(item=>{
                    if(item.technicalPremium){
                        totalPremiumBeforeDiscount += parseFloat(item.technicalPremium);
                        this.totalPremiumBeforeDiscount = totalPremiumBeforeDiscount;
                    }
                    if(item.requiredLimit){
                        totalLimit += item.requiredLimit;
                    }
                });
                this.maxLiabilityLimit = totalLimit;
                this.minAggLiabilityLimit = 1000000;
                // if(totalLimit > 10000000){
                //     this.maxLiabilityLimit = 10000000;
                // }
                // else{
                //     this.maxLiabilityLimit = totalLimit;
                // }
                //this.combineMaxAggLiabilityLabel = 'Combined Maximum Aggregate Limit of Liability ' + '       ' + '(' + this.maxLiabilityLimit + ' Absolute Maximum)';
                this.combineMaxAggLiabilityLabel = 'Combined Maximum Aggregate Limit of Liability';
                this.maxLiabilityLabel = '(' + this.maxLiabilityLimit.toLocaleString() + ' Absolute Maximum)';
                var isAggShared = objQuote.Shared_Aggregate_Limit__c;
                this.isAggShared = isAggShared;
                this.maxAggLiabilityLimit = objQuote.Combined_Max_Agg_Limit_of_Liability__c;
                var discount = this.getDiscoountFactor(isAggShared);
                this.totalPremiumAfterDiscount = this.totalPremiumBeforeDiscount * discount;

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
                    this.disableShared = true;
                }


            }
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Coverage Details',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        });
    }
    // added by Jitendra on 07-Jan-2022 for MTA-80  code end-----
    handleisAggSharedOptionChange(event){

        this.isLoading = true;
        var isAggShared = event.detail.value;
        var discount = 1;
        if(isAggShared){
            this.isAggShared = isAggShared;
            discount = this.getDiscoountFactor(isAggShared);
            this.totalPremiumAfterDiscount = this.totalPremiumBeforeDiscount * discount;

            const fields = {}
            fields[ID_FIELD.fieldApiName] = this.quoteId;
            fields[SHAREDAGG_FIELD.fieldApiName] = this.isAggShared;
            fields[BEFOREDISCOUNT_FIELD.fieldApiName] = this.totalPremiumBeforeDiscount;
            fields[AFTERDISCOUNT_FIELD.fieldApiName] = this.totalPremiumAfterDiscount;

            /*var objQuote = this.objQuote;
            objQuote.QuotePremium__c = this.totalPremiumAfterDiscount;
            objQuote.Prior_Discount_Quote_Premium__c = this.totalPremiumBeforeDiscount;
            objQuote.Shared_Aggregate_Limit__c = this.isAggShared;*/

            saveQuotePremium({
                objQuote: fields
            })
            .then(response => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Success',
                        variant: 'Success'
                    })
                );
                this.dispatchEvent(new CustomEvent('handlerefreshquotedetail'));
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating Discount',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
            this.isLoading = false;
            /*const recordInput = { fields };
            updateRecord(recordInput)
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Success',
                            variant: 'Success'
                        })
                    );
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error updating Discount',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
                this.isLoading = false;*/

        } 
    }

    handlemaxAggLimitFocusChange(event){
        let maxAggLim = event.target.value;
        if(maxAggLim){
            if(maxAggLim > this.maxLiabilityLimit) return;
            if(maxAggLim < this.minAggLiabilityLimit) return;
            this.isLoading = true;
            this.maxAggLiabilityLimit = maxAggLim;
            const fields = {}
            fields[ID_FIELD.fieldApiName] = this.quoteId;
            fields[MAXAGGLIMIT_FIELD.fieldApiName] = this.maxAggLiabilityLimit;

            saveQuotePremium({
                objQuote: fields
            })
            .then(response => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Success',
                        variant: 'Success'
                    })
                );
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating Max Agg Limit of Liability',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
            this.isLoading = false;
            /*const recordInput = { fields };
            updateRecord(recordInput)
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Success',
                            variant: 'Success'
                        })
                    );
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error updating Discount',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
                this.isLoading = false;*/

        }
        else{
            if(this.maxAggLiabilityLimit){
                const tempLimit = this.maxAggLiabilityLimit;
                this.maxAggLiabilityLimit = '';
                setTimeout(() => {
                    this.maxAggLiabilityLimit = tempLimit;
                  }, 500);
            }
        }
    }



    getDiscoountFactor(value){
        var isAggShared = value;
        var discount = 1;
        if(isAggShared == 'Yes - Two coverage sections'){
            discount = 0.94;
        }
        else if(isAggShared == 'Yes - Three coverage sections'){
            discount = 0.92;
        }
        else if(isAggShared == 'Yes - Four or more coverage sections'){
            discount = 0.9;
        }
        else{
            discount = 1;
        }

        return discount;

    }

    handleMaxAggLimitChange(event){
        let aggLimitVal = event.detail.value;
        if(aggLimitVal){
            let inputCmp = event.target;
            if(aggLimitVal > this.maxLiabilityLimit){
                inputCmp.setCustomValidity("Value cannot be greater than " + this.maxLiabilityLimit);
                inputCmp.reportValidity();
            }
            else if(aggLimitVal < this.minAggLiabilityLimit){
                inputCmp.setCustomValidity("Value cannot be less than " + this.minAggLiabilityLimit);
                inputCmp.reportValidity();
            }
            else{
                inputCmp.setCustomValidity('');
                inputCmp.reportValidity();
            }
        } 
    }

    @api
    handleRefreshCoverageTable() {
        this.getCoverageDetails();
        //refreshApex(this.wiredata); //commented by Jitendra on 07-Jan-2022 for MAT-80
        //console.log('this.wiredata' + this.wiredata);
    }

}