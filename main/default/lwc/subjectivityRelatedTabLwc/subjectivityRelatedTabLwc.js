import { refreshApex } from '@salesforce/apex';
import getSubjectivityByQuoteId from '@salesforce/apex/subjectivityController.getSubjectivityByQuoteId';
import getProductName from '@salesforce/apex/subjectivityController.getProductName';
import SUBJECTIVITY_OBJECT from '@salesforce/schema/Subjectivity__c';
import ID_FIELD from '@salesforce/schema/Subjectivity__c.Name';
import SUBJECTIVITY_STATUS_FIELD from '@salesforce/schema/Subjectivity__c.Subjectivity_Status__c';
import SUBJECTIVITY_TYPE_FIELD from '@salesforce/schema/Subjectivity__c.Subjectivity_Type__c';
import SUBJECTIVITY_FIELD from '@salesforce/schema/Subjectivity__c.Subjectivity__c';
import SUBJECTIVITY_TEXT_FIELD from '@salesforce/schema/Subjectivity__c.Subjectivity_Text__c';
import CLEARED_FIELD from '@salesforce/schema/Subjectivity__c.Cleared__c';
import CLEARED_DATE_FIELD from '@salesforce/schema/Subjectivity__c.Cleared_Date__c';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { deleteRecord, updateRecord } from 'lightning/uiRecordApi';
import { api, LightningElement, track, wire } from 'lwc';
import updateRecords from '@salesforce/apex/subjectivityController.updateRecords';


// row actions
const actions = [
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' }
];

export default class SubjectivityRelatedTabLwc extends NavigationMixin(LightningElement) {

    @api quoteId;
    @api quoteName;
    @api
    _data;
    get data() {
        return this._data;
    }
    set data(value) {
        this._data = value;
    }
    @track isLoading = true;
    @track saving = false;
    @track draftValues = [];
    @track draftId = [];

    @track clearedValue = false;
    @track clearedDate='';

    @track openModalCreateSubjectivity = false;
    @track modeEditSubjectivity = false;
    @track modeCreatedSubjectivity = false;
    @track modeEditAll = false;

    @track refreshValue;
    @api nonEditable;

    @track selectedRowId;
    @track recordTypeId;
    @track fields = [ID_FIELD, SUBJECTIVITY_FIELD, SUBJECTIVITY_STATUS_FIELD, SUBJECTIVITY_TYPE_FIELD, SUBJECTIVITY_TEXT_FIELD,
        CLEARED_FIELD, CLEARED_DATE_FIELD];


    @track isPI;
    @track columns = [
       /* {
            label: 'Subjectivity ID', fieldName: 'linkSubjectivityName', type: 'url',
            typeAttributes: { label: { fieldName: 'name' }, target: '_blank' }
        },*/
        { label: 'Subjectivity', fieldName: 'subjectivity', type: 'text' },
        { label: 'Subjectivity Status', fieldName: 'subjectivityStatus', type: 'text' },
        //{ label: 'Subjectivity Type', fieldName: 'subjectivityType', type: 'text' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: actions,
            }
        },
    ]
    @track columnsPI = [
        /*{
            label: 'Subjectivity ID', fieldName: 'linkSubjectivityName', type: 'url',
            typeAttributes: { label: { fieldName: 'name' }, target: '_blank' }
        },*/
        { label: 'Subjectivity', fieldName: 'linkSubjectivityName', type: 'url' ,
        typeAttributes: { label: { fieldName: 'subjectivity' }, target: '_blank' }
        },
        { label: 'Subjectivity Text', fieldName: 'subjectivityText', type: 'text' },
        { label: 'Cleared', fieldName: 'cleared', type: 'boolean' },
        { label: 'Cleared Date', fieldName: 'clearedDate', type: 'date' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: actions,
            }
        },
    ]
    wireResults
    @wire(getSubjectivityByQuoteId, { quoteId: '$quoteId' })
    imperativeWiring(result) {
        this.wireResults = result;
        if (result.data) {
            console.log('@@@ mydata', JSON.stringify(result.data));
            this.data = result.data; // Get data
            this.isLoading = false;
        }
    }

  
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

    @wire(getObjectInfo, { objectApiName: SUBJECTIVITY_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: SUBJECTIVITY_TYPE_FIELD })
    TypePicklistValues;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: SUBJECTIVITY_STATUS_FIELD })
    StatusPicklistValues;

    connectedCallback() {
        if (this.objectInfo.data) {
            const rtis = this.objectInfo.data.defaultRecordTypeId;
            console.log('@@@rtis ', JSON.stringify(rtis));
            this.recordTypeId = rtis;
        }
    }
    
    /*handleFieldValues(event){
        event.preventDefault();
        const fields = event.detail.fields;
        if (fields.Cleared__c == true){
            const jsDate  = new Date().toString();
            console.log('@@@jsDate ', jsDate);
            const formattedDate = jsDate.substr(0, jsDate.indexOf('T'));
            console.log('@@@formattedDate ', formattedDate);
            fields.Cleared_Date__c = this.formattedDate;
            console.log('@@@Cleared_Date__c ', JSON.stringify(fields.Cleared_Date__c));
        }
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }*/
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

    refreshValueFromConfiguredSubModal (event){
        this.refreshValue = true;
        console.log('@@@refreshValue from SubjRelatedTab::'+this.refreshValue); 
        console.log('@@@refreshValue from event.detail::'+event.detail);     
        if(this.refreshValue == true){
            refreshApex(this.wireResults);
            setTimeout(() => {
                this.saving = false;
            }, 500);
        }
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
    handleCancel() {
        this.openModalCreateSubjectivity = false;
        this.modeCreatedSubjectivity = false;
        this.modeEditSubjectivity = false;
        this.modeEditFull = false;
    }
    handleSubmit(event) {
        event.preventDefault();
        this.isLoading = true;
        const fields = event.detail.fields;
        console.log('@@@ fields', JSON.stringify(fields));
        this.template.querySelector('lightning-record-form').submit(fields);
    }
    handleOnLoad(event) {
        const detail = JSON.parse(JSON.stringify(event.detail))
        const record = detail.record;
        this.recordTypeId = record.recordTypeId;
        console.log('#this.recordTypeId::'+this.recordTypeId);
        const fields = record.fields;
        fields.Quote__c = this.quoteId;
        console.log('fields:' + JSON.stringify(fields));
    }
    handleOpenCreateModal() {
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
        this.openModalCreateSubjectivity = true;
        this.modeCreatedSubjectivity = true;
        // this.navigateToCreateRecord();
        this.modeEditAll = false;
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
        this.openModalCreateSubjectivity = true;
        this.modeEditSubjectivity = true;
        this.modeEditAll = false;
        this.selectedRowId = event.detail;
        console.log('@@@ handleUpdateRowSelected', this.selectedRowId);

    }
    navigateToCreateRecord() {
        let pageRef = {
            type: "standard__objectPage",
            attributes: {
                objectApiName: 'Subjectivity__c',
                actionName: 'new',
            },
            state: {
                nooverride: '1',
            }
        };
        const defaultFieldValues = {
            Quote__c: this.quoteId
        };
        pageRef.state.defaultFieldValues = encodeDefaultFieldValues(defaultFieldValues);
        this[NavigationMixin.Navigate](pageRef);
    }
    showEditALl() {
        this.openModalCreateSubjectivity = true;
        this.modeEditAll = true;
    }

    /*@track checkAllBoxes = false;
    handleClearAll(event){
        let items =  this.template.querySelectorAll('[data-field="cleared"]');
        //var items=document.getElementsByName('clearedBox');
        console.log('##items::'+items);
        for(var i=0; i<items.length; i++){
            if(items[i].type=='checkbox')
                items[i].checked=true;
        }
        this.checkAllBoxes = true;
        //this.handleOnChange(items);

    }*/

    handleEditAll(evt) {
        this.saving = true;
        console.log('@draftValues::'+JSON.stringify(this.draftValues));
        updateRecords({ jsonStringRecord: JSON.stringify(this.draftValues) }).then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Subjectivity updated',
                    variant: 'success'
                })
            );
            // Clear all draft values
            this.draftValues = [];
            this.draftId = [];
            this.saving = false;

            this.handleCancel();

            // Display fresh data in the datatable
            return refreshApex(this.wireResults);
        }).catch(error => {
            // Handle error
        });
    }
    //@track fieldName;
    handleOnChange(event) {
        console.log('@@@ handleOnChange', event.target.getAttribute('data-id'), event.target.getAttribute('data-field'), event.detail.value);
        const recordId = event.target.getAttribute('data-id');
        const fieldName = event.target.getAttribute('data-field');
        //console.log('##this.checkAllBoxes::'+this.checkAllBoxes);
        //const fieldValue = event.detail.value;
       // console.log('checkd value::'+event.detail.checked);
       //const fieldValue
        if(fieldName == 'cleared'){
            //var fieldValue = event.detail.value==undefined || event.detail.checked==true? true : false;
            if(event.detail.checked==true){
                var fieldValue = true;
            }
            else if(event.detail.checked==false){
                var fieldValue = false;
            }
            /*if(this.checkAllBoxes == true){
                fieldName = 'cleared';
                var fieldValue = true;
            }*/
        }
        else{
            var fieldValue = event.detail.value;
        }

        console.log('@@fieldValue::'+fieldValue);
        var oldRecord = this.data.filter(item => item.Id === recordId)[0];
        console.log('oldRecord::'+oldRecord);
        var newRecord = { ...oldRecord }
        console.log('newRecord::'+newRecord);
        if (this.draftId.indexOf(recordId) === -1) {
            newRecord[fieldName] = fieldValue;
            this.draftValues.push(newRecord);
            this.draftId.push(recordId);
        } else {
            this.draftValues.forEach(item => {
                if (item.Id === recordId) {
                    item[fieldName] = fieldValue;
                    if(item[fieldName] == 'cleared'){

                    }
                }
                return item;
            })
        }
        console.log('@@@ oldRecord', JSON.stringify(oldRecord));
        console.log('@@@ this.draftValues', JSON.stringify(this.draftValues));
        console.log('@@@ this.draftId', JSON.stringify(this.draftId));

    }
    populateDate(event){
        console('populate date fn');
        if (event.target.checked) {
            this.clearedDate = new Date();
        }
    }
}