import { LightningElement, wire, track, api} from 'lwc';
import getFFEndorsementByQuoteId from '@salesforce/apex/FreeFormEndorsementTabLwcController.getFFEndorsementByQuoteId';
import getCoverageEffDate from '@salesforce/apex/FreeFormEndorsementTabLwcController.getCoverageEffDate';
import generateFormNumber from '@salesforce/apex/FreeFormEndorsementTabLwcController.generateFormNumber';
import ID_FIELD from '@salesforce/schema/Free_Form_Endorsements__c.Name';
import FORM_NUMBER_FIELD from '@salesforce/schema/Free_Form_Endorsements__c.Form_Number__c';
import ENDORSEMENT_NAME_FIELD from '@salesforce/schema/Free_Form_Endorsements__c.Endorsement_Name__c';
import COV_EFF_DATE_FIELD from '@salesforce/schema/Free_Form_Endorsements__c.Coverage_Effective_Date__c';
import POLICY_WORDING_FIELD from '@salesforce/schema/Free_Form_Endorsements__c.Endorsement_Wording__c';
import QUOTE_FIELD from '@salesforce/schema/Free_Form_Endorsements__c.Quote__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { deleteRecord, updateRecord } from 'lightning/uiRecordApi';
import getProductName from '@salesforce/apex/subjectivityController.getProductName';

// row actions
const actions = [
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' }
];

export default class FreeFormEndorsementTabLwc extends LightningElement {

    @track fields = [ID_FIELD, FORM_NUMBER_FIELD, ENDORSEMENT_NAME_FIELD, COV_EFF_DATE_FIELD, 
                    POLICY_WORDING_FIELD, QUOTE_FIELD];

    @api quoteId;
    @api
    _data;
    get data() {
        return this._data;
    }
    set data(value) {
        this._data = value;
    }
    @track openModalCreateFFEndorsement = false;
    @track modeEditFFEndorsement = false;
    @track modeCreatedFFEndorsement = false;
    @track isLoading = true;
    @track title = 'New Free Form Endorsement';
    @track covEffDate = '';
    @track saving = false;
    @track selectedRowId;
    @track formNumber;
    @api nonEditable;

    @track columnsPI = [
        /*{
            label: 'Free Form Endorsements ID', fieldName: 'linkFFEndorsementName', type: 'url',
            typeAttributes: { label: { fieldName: 'endorsementId' }, target: '_blank' }
        },*/
        { label: 'Form number', fieldName: 'linkFFEndorsementName', type: 'url' ,
          typeAttributes: { label: { fieldName: 'formNumber' }, target: '_blank' }
        },
        { label: 'Endorsement Name', fieldName: 'endorsementName', type: 'text' },
        { label: 'Coverage Effective Date', fieldName: 'covEffectiveDate', type: 'date' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: actions,
            }
        },
    ]
    @track isPI;
    @track productName='';
    @wire(getProductName, { quoteId: '$quoteId' })
    wiregetProductName({ error, data }) {
      if (data) {
          this.productName = data;
          if(this.productName == 'Professional Indemnity'){
              this.isPI = true;
              console.log('@@@isPI::'+this.isPI);
          }
      } else {
        console.log("getProductName error:" + JSON.stringify(error));
      }
    }

    wireResults
    @wire(getFFEndorsementByQuoteId, { quoteId: '$quoteId' })
    imperativeWiring(result) {
        this.wireResults = result;
        if (result.data) {
            console.log('@@@ mydata', JSON.stringify(result.data));
            this.data = result.data; // Get data
            this.isLoading = false;
        }
    }
    handleOpenCreateModal(){
        if(this.nonEditable){           
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'You cannot Create Record for this Quote Status.',
                    variant: 'error'
                })
            );
            return;
        }
        this.openModalCreateFFEndorsement = true;
        //this.modeEditFFEndorsement = true;
        this.modeCreatedFFEndorsement = true;
    }
    handleCancel(){
        this.openModalCreateFFEndorsement = false;
        this.modeEditFFEndorsement = false;
    }
    handleOnLoad(event) {
        console.log('enter handle on load');
        const detail = JSON.parse(JSON.stringify(event.detail))
        const record = detail.record;
        this.recordTypeId = record.recordTypeId;
        //console.log('#this.recordTypeId::'+this.recordTypeId);
        const fields = record.fields;
        fields.Quote__c = this.quoteId;
        fields.Coverage_Effective_Date__c = this.covEffDate;
        //this.generateFormNumber(this.quoteId);
        generateFormNumber({quoteId: this.quoteId })
        .then(formNum => {
            this.formNumber = formNum;
        })
        .catch(error => {
            this.error = error;
            console.log('## error fetching coverage eff date: ' + JSON.stringify(error));
        });
        fields.Form_Number__c = this.formNumber;
        console.log('Cov date field:' + JSON.stringify(this.covEffDate));
        console.log('fields:' + JSON.stringify(fields));
    }
    handleSubmit(event) {
        event.preventDefault();
        this.isLoading = true;
        const fields = event.detail.fields;
        console.log('@@@ fields', JSON.stringify(fields));
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }
    handleAddSuccess(event) {
        this.saving = true;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Record saved successfully with id: ' + event.detail.id,
                variant: 'success',
            }),
        )
        this.handleCancel();
        this.isLoading = false;
        refreshApex(this.wireResults);
        setTimeout(() => {
            this.saving = false;
        }, 500);
    }
    connectedCallback(){
        getCoverageEffDate({quoteId: this.quoteId })
        .then(covDate => {
            this.covEffDate = covDate;
        })
        .catch(error => {
            this.error = error;
            console.log('## error fetching coverage eff date: ' + JSON.stringify(error));
        });
        generateFormNumber({quoteId: this.quoteId })
        .then(formNum => {
            this.formNumber = formNum;
        })
        .catch(error => {
            this.error = error;
            console.log('## error fetching coverage eff date: ' + JSON.stringify(error));
        });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handleUpdateRowSelected(event) {
        if(this.nonEditable){           
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'You cannot Edit Record for this Quote Status.',
                    variant: 'error'
                })
            );
            return;
        }
        this.openModalCreateFFEndorsement = true;
        this.modeEditFFEndorsement = true;
        this.modeCreatedFFEndorsement = false;
        this.selectedRowId = event.detail;
        console.log('@@@ handleUpdateRowSelected', this.selectedRowId);
    }
    handleRowClick(evt) {
        this.selectedRowId = evt.detail;
        console.log('@@@handleRowClick', JSON.stringify(e.detail));

    }
    handleDeleteRowSelected(event) {
        if(this.nonEditable){           
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'You cannot Delete Record for this Quote Status.',
                    variant: 'error'
                })
            );
            return;
        }
        this.isLoading = true;
        var rowId = event.detail;
        console.log('@@@ handleDeleteRowSelected', rowId);
        deleteRecord(rowId)
            .then(() => {
                // this.template.querySelector('c-pagination-lwc').refreshDataTable();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record deleted',
                        variant: 'success'
                    })
                );
                this.isLoading = false;
                refreshApex(this.wireResults);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error deleting record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });

    }

    handleEditSuccess(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Record updated successfully with id: ' + event.detail.id,
                variant: 'success',
            }),
        )
        this.handleCancel();
        refreshApex(this.wireResults);
        this.isLoading = false;
    }
}