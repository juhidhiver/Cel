import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getOpportunityRecordType from '@salesforce/apex/OpportunityInitFormCmpController.getOpportunityRecordType';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
//show toast
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//end

export default class OpportunityInitFormLwc extends NavigationMixin(LightningElement) {
    @api objectName = '';
    @api recordTypeList;
    @api rctId = '';
    @api productId = '';
    @api accountId = '';
    @api recordTypeId;
    @api isShowNewoppLwc;
    @api isNotShowInitForm = false;

    constructor() {
        super();
        window.addEventListener('showtoast', evt => {
            console.log(JSON.stringify(evt));
        })
    }

    @wire(getOpportunityRecordType, {})
    wireRecordType({ error, data }) {
        console.log(JSON.stringify(data));
        var returning = [];
        for (var i in data) {
            this.rctId = data[0].Id;
            returning.push({ value: data[i].Id, label: data[i].Name });
        }
        this.recordTypeList = returning;
    }

    messageListener(event) {
        console.log(JSON.stringify(event));
    }

    handleToastEvent(event) {
        console.log('Event Listener ' + JSON.stringify(event.target.message));
        console.log('Event Listener ' + JSON.stringify(event));
    }

    handleCancel() {
        console.log('RecordType List ' + JSON.stringify(this.recordTypeList));
        let pageRef = {
            type: "standard__objectPage",
            attributes: {
                objectApiName: 'Quote',
                actionName: 'home',
            },
            state: {
            }
        };
        this[NavigationMixin.Navigate](pageRef);

    }
    handleShowToast(event) {
        console.log('Show Toast Event' + JSON.stringify(event));
    }

    handleNext(event) {
        console.log('Next Form');
        let pageRef = {
            type: "standard__objectPage",
            attributes: {
                objectApiName: 'Opportunity',
                actionName: 'new',
            },
            state: {
                nooverride: '1',
            }
        };
        const defaultFieldValues = {
            Name: 'TestOppName',
            Product__c: this.productId,
            AccountId: this.accountId,
        };
        pageRef.state.defaultFieldValues = encodeDefaultFieldValues(defaultFieldValues);
        this[NavigationMixin.Navigate](pageRef);
        // console.log('Event' + JSON.stringify(event));
    }

    handleSelectedRecord(event) {
        console.log('Event ' + JSON.stringify(event));
        const selectedRecordId = event.detail;
        this.accountId = selectedRecordId.recordId;
    }
    handleChangeInput(event) {
        if (event.target.name == 'productId') {
            this.productId = event.target.value;
        }
    }
    handleLoad() {

    }
    handleError() {

    }
    handleSuccess(e) {
        console.log('@@@ opportunityInitLwc', e);
    }

}