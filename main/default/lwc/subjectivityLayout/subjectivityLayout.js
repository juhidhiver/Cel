import { refreshApex } from '@salesforce/apex';
import getSubjectivityByQuoteId from '@salesforce/apex/subjectivityController.getSubjectivityByQuoteId';
import getProductName from '@salesforce/apex/subjectivityController.getProductName';
import getProfessionName from '@salesforce/apex/subjectivityController.getProfessionName';
import getSubjectivityTemplateList from '@salesforce/apex/subjectivityController.getSubjectivityTemplateList';
import createSubjectivitiesBySubjTemplate from '@salesforce/apex/subjectivityController.createSubjectivitiesBySubjTemplate';
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

export default class subjectivityLayout extends NavigationMixin(LightningElement) {
    isDialogVisible = false;
    isSidebarCollapsed = false;
    isBodyCollapsed = false;

    searchTerm;
    mainProfession;
    subTemplates = [];
    holdSubTemplates = [];
    subList = [];
    selectedSubjTemplate = [];
    selectedRow;
    sortDirection;
    sortedBy;
    privateChildren = {};
    isComponentLoaded;
    lastSavedData;
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
    //coment 
    @track isLoading = false;
    
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
    disableSaveBtn= false;

    handleSidebarCollapse(){
        this.isSidebarCollapsed = false;
        this.isBodyCollapsed = !this.isBodyCollapsed;
    }

    handleCollapse(){
        this.isBodyCollapsed = false;
        this.isSidebarCollapsed = !this.isSidebarCollapsed;
    }

    renderedCallback() {
        if (!this.isComponentLoaded) {
            /* Add Click event listener to listen to window click to reset the picklist selection 
            to text view if context is out of sync*/
            window.addEventListener('click', (evt) => {
                this.handleWindowOnclick(evt);
            });
            this.isComponentLoaded = true;
        }
    }

    disconnectedCallback() {
        window.removeEventListener('click', () => { });
    }

    get sidebarSize(){
        return this.isBodyCollapsed ?  12 : 4;
    }

    get sidebarButtonIcon(){
        return this.isBodyCollapsed ? 'utility:jump_to_left' : 'utility:jump_to_right';
    }

    get sidebarButtonTitle(){
        return this.isBodyCollapsed ? 'Open Endorsement List' : 'Collapse Endorsement List';
    }

    get sidebarButtonName(){
        return this.isBodyCollapsed ? 'Expand' : 'Collapse';
    }

    get contentSize(){
        return !this.showSidebar ? 12 : 8;
    }

    get buttonTitle(){
        return this.isSidebarCollapsed ? 'Open Search and Add Endorsement' : 'Collapse Search and Add Endorsement';
    }

    get buttonIcon(){
        return this.isSidebarCollapsed ? 'utility:jump_to_right' : 'utility:jump_to_left';
    }

    get buttonName(){
        return this.isSidebarCollapsed ? 'Expand' : 'Collapse';
    }

    get showSidebar(){
        return !this.isSidebarCollapsed && !this.boundDisabled;
    }

    get option(){
        return [
            { label: this.mainProfession, value: this.mainProfession}
        ];
    }

    @track columns = [
        /*{
            label: 'Subjectivity ID', fieldName: 'linkSubjectivityName', type: 'url',
            typeAttributes: { label: { fieldName: 'name' }, target: '_blank' }
        },
        { label: 'Subjectivity', fieldName: 'subjectivity', type: 'text', editable: true },
        { label: 'Subjectivity Status', fieldName: 'subjectivityStatus', type: 'text', editable: true },
        { label: 'Subjectivity Type', fieldName: 'subjectivityType', type: 'text' },*/
        { 
            label: 'Subjectivity', 
            fieldName: 'subjectivity',
            type: 'text', 
            sortable: true,
            editable : true
        },
        { 
            label: 'Stage', 
            fieldName: 'subjectivityStage',
            type: 'picklist',
            sortable: true,
            typeAttributes: {
                placeholder: 'Choose Stage',
                options: [
                    { label: 'Pre-Bind', value: 'Pre-Bind' },
                    { label: 'Post-Bind', value: 'Post-Bind' }
                ],
                value: { fieldName: 'subjectivityStage' },
                context: { fieldName: 'Id' },
                variant: 'label-hidden',
                name: 'Stage',
                label: 'Stage'
            },
            cellAttributes: {
                class: { fieldName: 'stageClass' }
            }
        },
        { 
            label: 'Subjectivity Status', 
            fieldName: 'subjectivityStatus', 
            type: 'picklist',
            sortable: true,
            typeAttributes: {
                placeholder: 'Choose Status',
                options: [
                    { label: 'Open', value: 'Open' },
                    { label: 'Completed', value: 'Completed' },
                    { label: 'Waived', value: 'Waived' }
                ],
                value: { fieldName: 'subjectivityStatus' },
                context: { fieldName: 'Id' },
                variant: 'label-hidden',
                name: 'Status',
                label: 'Status'
            },
            cellAttributes: {
                class: { fieldName: 'statusClass' }
            } 
        },
        { 
            label: 'Due Date', 
            sortable: true,
            fieldName: 'subjectivityDueDate', 
            type: 'date', 
            editable : true
        },
        { 
            label: 'Subjectivity Type', 
            fieldName: 'subjectivityType', 
            type: 'picklist',
            sortable: true,
            typeAttributes: {
                placeholder: 'Choose Type',
                options: [
                    { label: 'General', value: 'General' },
                    { label: 'D&O', value: 'D&O' },
                    { label: 'EPL', value: 'EPL' },
                    { label: 'Fiduciary', value: 'Fiduciary' },
                    { label: 'MPL', value: 'MPL' },
                    { label: 'Crime', value: 'Crime' },
                    { label: 'Cyber', value: 'Cyber' }
                ],
                value: { fieldName: 'subjectivityType' },
                context: { fieldName: 'Id' },
                variant: 'label-hidden',
                name: 'Type',
                label: 'Type'
            },
            cellAttributes: {
                class: { fieldName: 'typeClass' }
            }
        },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'Delete', name: 'delete' }
                ]
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
        }
    }
  }

    @wire(getObjectInfo, { objectApiName: SUBJECTIVITY_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: SUBJECTIVITY_TYPE_FIELD })
    TypePicklistValues;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: SUBJECTIVITY_STATUS_FIELD })
    StatusPicklistValues;

    connectedCallback() {

        this.fetchProfessionName();
        this.fetchSubjectivityTemplates();

        if (this.objectInfo.data) {
            const rtis = this.objectInfo.data.defaultRecordTypeId;
            this.recordTypeId = rtis;
        }
    }

    fetchProfessionName(){
        getProfessionName({quoteId: this.quoteId })
        .then(result => {
            this.mainProfession = result;
        })
        .catch(error => {
            this.error = error;
            this.subTempList = undefined;
        });
    }

    handleWindowOnclick(context) {
        this.resetPopups('c-datatable-picklist', context);
    }

    //create object value of datatable picklist markup to allow to call callback function with window click event listener
    resetPopups(markup, context) {
        let elementMarkup = this.privateChildren[markup];
        if (elementMarkup) {
            Object.values(elementMarkup).forEach((element) => {
                element.callbacks.reset(context);
            });
        }
    }

    // Event to register the datatable picklist mark up.
    handleItemRegister(event) {
        event.stopPropagation(); //stops the window click to propagate to allow to register of markup.
        const item = event.detail;
        if (!this.privateChildren.hasOwnProperty(item.name))
            this.privateChildren[item.name] = {};
        this.privateChildren[item.name][item.guid] = item;
    }

    handleCancel(event) {
        event.preventDefault();
        this.records = JSON.parse(JSON.stringify(this.lastSavedData));
        this.handleWindowOnclick('reset');
        this.draftValues = [];
    }

    handleCellChange(event) {
        event.preventDefault();
        this.updateDraftValues(event.detail.draftValues[0]);
    }

    handleValueChange(event) {
        event.stopPropagation();
        let dataRecieved = event.detail.data;
        let updatedItem;
        switch (dataRecieved.label) {
            case 'Stage':
                updatedItem = {
                    Id: dataRecieved.context,
                    subjectivityStage: dataRecieved.value
                };
                // Set the cell edit class to edited to mark it as value changed.
                this.setClassesOnData(
                    dataRecieved.context,
                    'stageClass',
                    'slds-cell-edit slds-is-edited'
                );
                break;
            case 'Status':
                updatedItem = {
                    Id: dataRecieved.context,
                    subjectivityStatus: dataRecieved.value
                };
                // Set the cell edit class to edited to mark it as value changed.
                this.setClassesOnData(
                    dataRecieved.context,
                    'statusClass',
                    'slds-cell-edit slds-is-edited'
                );
                break;
            case 'Type':
                updatedItem = {
                    Id: dataRecieved.context,
                    subjectivityType: dataRecieved.value
                };
                // Set the cell edit class to edited to mark it as value changed.
                this.setClassesOnData(
                    dataRecieved.context,
                    'typeClass',
                    'slds-cell-edit slds-is-edited'
                );
                break;
            default:
                this.setClassesOnData(dataRecieved.context, '', '');
                break;
        }
        this.updateDraftValues(updatedItem);
        this.updateDataValues(updatedItem);
    }

    updateDataValues(updateItem) {
        let copyData = JSON.parse(JSON.stringify(this.data));
        copyData.forEach((item) => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
            }
        });
        this.data = [...copyData];
    }

    updateDraftValues(updateItem) {
        let draftValueChanged = false;
        let copyDraftValues = JSON.parse(JSON.stringify(this.draftValues));
        copyDraftValues.forEach((item) => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
                draftValueChanged = true;
            }
        });
        if (draftValueChanged) {
            this.draftValues = [...copyDraftValues];
        } else {
            this.draftValues = [...copyDraftValues, updateItem];
        }
    }

    fetchSubjectivityTemplates(){
        getSubjectivityTemplateList({quoteId: this.quoteId })
        .then(subTemplateList => {
            this.error = undefined;
            this.subTemplates = [];
                this.holdSubTemplates = [];
                var sList = [];
                subTemplateList.forEach(sTemplate => {
                    if (this.subList.some(e => e.name === sTemplate.Subjectivity_Name__c)) {
                    } else {
                        sList.push(sTemplate);

                    }
                });
                sList.sort(function (a, b) {
                    if (a.Subjectivity_Name__c < b.Subjectivity_Name__c) { return -1; }
                    if (a.Subjectivity_Name__c > b.Subjectivity_Name__c) { return 1; }
                    return 0;
                });
                this.subTemplates = sList;
                this.holdSubTemplates = sList;
        })
        .catch(error => {
            this.error = error;
            this.subTempList = undefined;
        });
    }

    handleEdit(event) {
        event.preventDefault();
        let dataRecieved = event.detail.data;
        this.handleWindowOnclick(dataRecieved.context);
        switch (dataRecieved.label) {
            case 'Stage':
                this.setClassesOnData(
                    dataRecieved.context,
                    'stageClass',
                    'slds-cell-edit'
                );
                break;
            case 'Status':
                this.setClassesOnData(
                    dataRecieved.context,
                    'statusClass',
                    'slds-cell-edit'
                );
                break;
            case 'Type':
                this.setClassesOnData(
                    dataRecieved.context,
                    'typeClass',
                    'slds-cell-edit'
                );
                break;
            case 'Type':
                this.setClassesOnData(
                    dataRecieved.context,
                    'typeClass',
                    'slds-cell-edit'
                );
                break;
            default:
                this.setClassesOnData(dataRecieved.context, '', '');
                break;
        };
    }

    setClassesOnData(id, fieldName, fieldValue) {
        let records = JSON.parse(JSON.stringify(this.data));
        records.forEach((detail) => {
            if (detail.Id === id) {
                detail[fieldName] = fieldValue;
            }
        });
        this.data = records;
    }

    selectAllRow(event) {
        if (event.target.checked) {
            this.template.querySelectorAll('.chkBox').forEach(each => {
                each.checked = event.target.checked;
            })
            this.selectedSubjTemplate = [];
            this.subTemplates.forEach(item => {
                this.selectedSubjTemplate.push(item.Id);
            })
        } else {
            this.template.querySelectorAll('.chkBox').forEach(each => {
                each.checked = event.target.checked;
            })
            this.selectedSubjTemplate = [];
        }
    }
    
    selectRow(event) {
        if (event.target.checked) {
            this.selectedSubjTemplate.push(event.target.value);
            if (this.selectedSubjTemplate.length == this.subTemplates.length) {
                var selectAllChkBox = this.template.querySelector('.selectAllChkBox');
                selectAllChkBox.checked = event.target.checked;
            }
        }
        if (!event.target.checked) {
            //this.selectedSubjTemplate.pop(event.target.value);
            this.removeA(this.selectedSubjTemplate, event.target.value );
            var selectAllChkBox = this.template.querySelector('.selectAllChkBox');
            selectAllChkBox.checked = event.target.checked;
        }
    }

    removeA(arr) {
        var what, a = arguments, L = a.length, ax;
        while (L > 1 && arr.length) {
            what = a[--L];
            while ((ax= arr.indexOf(what)) !== -1) {
                arr.splice(ax, 1);
            }
        }
        return arr;
    }

    handleRowAction(event) {   
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        this.selectedRow = row;
        switch (actionName) {
            case 'edit':
                this.editRow(row);
                break;
            case 'delete':
                //this.openmodel = true;
                this.deleteRow(row);
                break;
            case 'show_details':
                this.showRowDetails(row);
                break;
            default:
        }
    }

    editRow(row) {  
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
        this.selectedRowId = row.Id;
    }

    deleteRow(row) {
        if(this.title == 'Additional Insured Details' && this.nonEditable){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: "Cannot Modify Additional Insurer Account for this Stage",
                    variant: "error"
                })
            );
            return;
        }else{
            this.isDialogVisible = true;
        }
    }

    showRowDetails(row) {            
        let recordid = row.opportunityId;
        this.navigateToRecordViewPage(recordid);
    }

    navigateToRecordViewPage(oppRecordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId :oppRecordId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
    }

    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field];
              };

        return function (a, b) {
            a = key(a);
            b = key(b);

            if (!a) return reverse * -1;
            else if (!b) return reverse * 1;

            return reverse * ((a > b) - (b > a));
        };
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.data];
        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
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
                message: 'Record saved successfully.',
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

    handleSearchTextChange(event) {
        this.searchTerm = event.target.value;
        if (this.searchTerm === '') {
            this.subTemplates = this.holdSubTemplates;
        } else {
            var searchRows = [];
            this.holdSubTemplates.forEach(element => {
                if (element.Subjectivity_Name__c.toLowerCase().includes(this.searchTerm.toLowerCase())) {
                    searchRows.push(element);
                }
            });
            this.subTemplates = searchRows;
        }
    }

    async handleAddSubjectivities(event) {
        if (this.selectedSubjTemplate.length > 0) {
            var selectAllChkBox = this.template.querySelector('.selectAllChkBox');
            selectAllChkBox.checked = false;

            try {
                this.isLoading = true;
                const operation = await createSubjectivitiesBySubjTemplate({ quoteId: this.quoteId, subjTemplates: this.selectedSubjTemplate });
                if (operation == 'success') {
                    this.showToast("Success", "Subjectivities added successfully.", "success");
                    refreshApex(this.wireResults);
                    this.fetchSubjectivityTemplates();
                    this.selectedSubjTemplate = [];
                    this.isLoading = false;
                }
            } catch (error) {
                var errorMsg = 'Error in adding Subjectivities.';
                if(error.body.pageErrors[0].message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                    var err = error.body.pageErrors[0].message;
                    errorMsg = err.substring(err.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION')+34,err.indexOf(': []'));
                }
                if(error.body.pageErrors[0].message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION, This Quote is locked for editing')){
                    var err = error.body.pageErrors[0].message;
                    errorMsg = 'This Quote is locked for editing when status is Quoted or Bound';
                }else if(error.body.pageErrors[0].statusCode.includes('ENTITY_IS_LOCKED')){
                    errorMsg = 'This record is locked. If you need to edit it, contact your admin';
                }
                this.selectedSubjTemplate = [];
                this.showToast("Error", errorMsg, "error");
            }
        }
        else {
            this.showToast("Select Subjectivity", "Please select at least one Subjectivity", "error");
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
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
        this.template.querySelector('lightning-record-form').submit(fields);
    }
    handleOnLoad(event) {
        const detail = JSON.parse(JSON.stringify(event.detail))
        const record = detail.record;
        this.recordTypeId = record.recordTypeId;
        const fields = record.fields;
        fields.Quote__c = this.quoteId;
    }
    /** Added by Vinay **/
    handleOnSubmit(event){
        event.preventDefault();
        const fields = event.detail.fields;
        fields.Quote__c = this.quoteId;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
        this.isLoading = true;
    }

    handleSaveComplete(event){
       this.isLoading = false;
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

    handleEditRow(event) {
        //when user clicks outside of the dialog area, the event is dispatched with detail value  as 1
        if(event.detail !== 1){
            if(event.detail.status === 'confirm') {
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
                var rowId = this.selectedRow.Id;

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
                    this.fetchSubjectivityTemplates();
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
            }else if(event.detail.status === 'cancel'){
                this.isDialogVisible = false;
            }
        }
        this.isDialogVisible = false;
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

    handleSave(event) {
        event.preventDefault();
        this.isLoading = true;
        // Update the draftvalues
        updateRecords({ jsonStringRecord: JSON.stringify(this.draftValues) })
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Subjectivities updated successfully',
                    variant: 'success'
                })
            );
            //Get the updated list with refreshApex.
            refreshApex(this.wireResults);
            this.isLoading = false;
            this.draftValues = [];
            this.handleCancel();
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error occured while updating subjectivities',
                    variant: 'error'
                })
            );
            this.handleCancel();
            this.isLoading = false;
        });
    }

    handleEditAll(evt) {
        this.saving = true;
        
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
            console.log(error);
            // Handle error
        });
    }
    //@track fieldName;
    handleOnChange(event) {
        const recordId = event.target.getAttribute('data-id');
        const fieldName = event.target.getAttribute('data-field');
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

        var oldRecord = this.data.filter(item => item.Id === recordId)[0];
        var newRecord = { ...oldRecord }
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
    }
    populateDate(event){
        console('populate date fn');
        if (event.target.checked) {
            this.clearedDate = new Date();
        }
    }
}