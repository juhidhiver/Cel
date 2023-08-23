import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCategoryOptions from '@salesforce/apex/EndorsementTabLwcController.getCategoryOptions';
import searchCoverage from '@salesforce/apex/EndorsementTabLwcController.searchCoverage';
import insertEndorsementCLI from '@salesforce/apex/EndorsementTabLwcController.insertEndorsementCLI';
import saveUpdatedCLI from '@salesforce/apex/EndorsementTabLwcController.saveUpdatedCLI';
import getSelectedEndorsement from '@salesforce/apex/EndorsementTabLwcController.getSelectedEndorsement';
import getEndorsementCLI from '@salesforce/apex/EndorsementTabLwcController.getEndorsementCLI';
import deleteEndorsementCLI from '@salesforce/apex/EndorsementTabLwcController.deleteEndorsementCLI';
import addNewRow from '@salesforce/apex/EndorsementTabLwcController.addNewRow';
import deleteRow from '@salesforce/apex/EndorsementTabLwcController.deleteRow';
import addEndorsementCLI from '@salesforce/apex/EndorsementTabLwcController.addEndorsementCLI';
import saveEndorsement from '@salesforce/apex/EndorsementTabLwcController.saveEndorsement';
import getSelectedCoverages from '@salesforce/apex/EndorsementTabLwcController.getSelectedCoverages';

const COLS=[
    {label:'Form Name',fieldName:'Endorsement_Categories__c', type:'text'},
    {label: 'Endorsement Name', fieldName: 'Link_Document__c', type: 'url', typeAttributes: {label: { fieldName: 'Name'}, target: '_blank'}}
]; 

export default class EndorsementLayout extends LightningElement {
    isSidebarCollapsed = false;
    isBodyCollapsed = false;
    contentSortDirection = 'asc';
    contentSortField = 'formNumber';
    @api quoteId;
    @track currentCoverageId;
    @track currentRow;
    @track categoryValues = [];
    @api isUpdated;
    //@track categories = '';
    @track searchName = '';
    @track endorsementCategoryOption = [];
    @track resultedEndorsement = [];
    @track selectedCoverages = [];
    @track selectedRows = [];
    @track updateCoveraLineItem = [];    
    @track selectingCoverage = '';
    listUpdateRecords = [];
    @track selectedEndorsements = [];
    @track tableColumns = [];
    @api isPrimaryQuote;
    @api isAqueousProduct;
    @api isPcc;
    @track hideEndorsementTagDropdown;
    @api boundDisabled = false;
    // @track tableData = [];
    // @track tableRowOffset = [];
    @track draftValues = [];
    @track isLoading = false;
    @track isEditing = false;
    @track isSchedule = false;
    @track showEditModal = false;
    @track currentEditValues;
    rowActions = [];
    cols = COLS;
    @track sortBy;
    @track sortDirection;
    @api nonEditable;

    //newDataTable
    @track rowData2 = [];
    @track columnData2 = [];
    updateData2 = [];
    @api isAqueous;
    @api recordId;

    handleSidebarCollapse(){
        this.isSidebarCollapsed = false;
        this.isBodyCollapsed = !this.isBodyCollapsed;
    }

    handleCollapse(){
        this.isBodyCollapsed = false;
        this.isSidebarCollapsed = !this.isSidebarCollapsed;
    }

    get formNumberSortDirection(){
        return this.contentSortField == 'formNumber' ? (this.contentSortDirection == 'asc' ? '↑' : '↓') : '';
    }

    get endorsementSortDirection(){
        return this.contentSortField == 'name' ? (this.contentSortDirection == 'asc' ? '↑' : '↓') : '';
    }

    get notesSortDirection(){
        return this.contentSortField == 'note' ? (this.contentSortDirection == 'asc' ? '↑' : '↓') : '';
    }

    get effectiveDateSortDirection(){
        return this.contentSortField == 'effectiveDate' ? (this.contentSortDirection == 'asc' ? '↑' : '↓') : '';
    }

    get contentSize(){
        return !this.showSidebar ? 12 : 8;
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

    get buttonTitle(){
        return this.isSidebarCollapsed ? 'Open Search and Add Endorsement' : 'Collapse Search and Add Endorsement';
    }

    get buttonIcon(){
        return this.isSidebarCollapsed ? 'utility:jump_to_right' : 'utility:jump_to_left';
    }

    get buttonName(){
        return this.isSidebarCollapsed ? 'Expand' : 'Collapse';
    }

    get isResultedCoverage() {
        return this.resultedEndorsement.length > 0;
    }
    get isSelectedCoverage() {
        return this.updateCoveraLineItem.length > 0;
    }
    
    get showSidebar(){
        return !this.isSidebarCollapsed && !this.boundDisabled;
    }

    connectedCallback() {
        if(this.isAqueous){
            this.hideEndorsementTagDropdown = true;
        }
        if(this.isPrimaryQuote == 'false'){
            this.isPrimaryQuote = false;
        }else{
            this.isPrimaryQuote = true;
        }
        if(!this.isAqueousProduct ){
            this.handleSearchButtonClicked(event);
            if(!this.isPrimaryQuote) this.hideEndorsementTagDropdown = true;
        }
        getCategoryOptions({quoteId : this.quoteId}).then(results => {
            var options = [];
            results.forEach(result => {
                let option = {label : result, value : result};
                options.push(option);
            });
            this.endorsementCategoryOption = options;
        })

        getSelectedEndorsement({quoteId : this.quoteId})
        .then(result => {
            this.selectedEndorsements = result;
        }).catch(error => {
            this.isLoading = false;
            this.showToast('Error', error, 'error');
        });
        if(this.isAqueous  ){
            this.handleSearchButtonClicked(event);
        }        
    }
    
    handleChangeComboBox(event) {
        let value = event.detail.value;
        let prosConsCombobox = this.template.querySelector('[data-id="categoryCmb"]');
        prosConsCombobox.value = null;
        if(!this.categoryValues.includes(value))
            this.categoryValues.push(value);
        this.handleSearchButtonClicked(event);
        //this.categories = this.values.join(', ');
    }

    handleRemoveSearchOption(event) {
        let item = event.detail.name;
        let prosConsCombobox = this.template.querySelector('[data-id="categoryCmb"]');
        prosConsCombobox.value = null;
        this.categoryValues = this.categoryValues.filter(value => value != item);
        if(this.categoryValues.length == 0 && this.searchName == '') {
            this.resultedEndorsement = [];
            this.handleSearchButtonClicked();
        } else {
            
            this.handleSearchButtonClicked(event);
        }
     }

    handleSearchNameChanged(event) {
        this.searchName = event.target.value;
        if(this.isAqueous) this.handleSearchButtonClicked(event);
        
    }

    handleSearchNameKeyUp(event) {
        const isEnterKey = event.keyCode === 13;
        if(isEnterKey) {
            if(this.categoryValues.length == 0 && this.searchName == '') {
                this.resultedEndorsement = [];     
                this.handleSearchButtonClicked(event);           
            } else {
                this.handleSearchButtonClicked(event);
            }
        }
    }

    @track loading = false;
    handleSearchButtonClicked(event) {
        this.loading = true;
        searchCoverage({searchName: this.searchName, searchCategories: this.categoryValues, quoteId: this.quoteId})
        .then(result => {
            //this.resultedEndorsement = this.result.filter(col => col.Additional_Requirements__c'');
            //result.Additional_Requirements__c.filter(col => col.contains('Rating Required'));
            this.resultedEndorsement = result;
            this.loading = false;
            this.isLoading = false;
            return getSelectedCoverages({quoteId : this.quoteId, items: this.resultedEndorsement});
        }).then(result => {
            this.selectedRows = result;
        }).catch(error => {
            this.isLoading = false;
            this.showToast('Error', error, 'error');
        });
    }

    handleSelectCoverage(event) {
        let rowId = event.target.name;
        this.currentCoverageId = rowId;
        // let temp = JSON.parse(JSON.stringify(this.resultedEndorsement));
        // let addingCoverage;
        // let checkIsExisted = false;
        // temp.forEach(row => {
        //     if(row.Id === rowId) {
        //         checkIsExisted = this.checkIsExistedEndorsement(row.Id);
        //         if(checkIsExisted == false) {
        //             this.selectingCoverage = row.Name;
        //             //this.selectedEndorsements.push(row);
        //             this.addNewSelectedEndorsement(row);
        //         }
        //     }
        // });
        // if(checkIsExisted == false)
        //     // insertEndorsementCLISecond({quoteId: this.quoteId, coverageId: rowId}).then(
        //     insertEndorsementCLI({quoteId: this.quoteId, coverageId: rowId}).then(
        //         result => {
        //             this.showEditEndorsementCLI(rowId);
        //         }
        //     ).catch(error => {
        //         this.isLoading = false;
        //         this.showToast('Error', error, 'error');
        //     }); 

        insertEndorsementCLI({quoteId: this.quoteId, coverageId: rowId})
        .then(response => {
            if(response.isSuccess) {
                this.showEditEndorsementCLI(rowId);
                let temp = JSON.parse(JSON.stringify(this.resultedEndorsement));
                temp.forEach(row => {
                    if(row.Id === rowId) {
                        this.selectingCoverage = row.Name;
                        this.addNewSelectedEndorsement(row);
                    }
                });
            } else {
                this.showToast('Error', response.errors[0], 'error');
            }
            this.categoryValues = [];
            this.resultedEndorsement = [];

        }).catch(error => {
            this.isLoading = false;
            this.showToast('Error', error, 'error');
        }); 
        
    }

    addRecord() {
        this.isLoading = true;
        var selectedRecords =  this.template.querySelector("lightning-datatable").getSelectedRows();
        if (selectedRecords.length > 0) {
            addEndorsementCLI({quoteId: this.quoteId, items: selectedRecords, tags: this.categoryValues})
            .then(response =>{
                if(response.isSuccess) {
                    this.selectedEndorsements = response.data;
                    this.showToast('Success', 'The data is saved successfully', 'success');
                    for(let record of selectedRecords) {
                        this.resultedEndorsement = this.resultedEndorsement.filter(item => item.Id != record.Id);
                    }
                } else {
                    if(response.errors[0].includes('ENTITY_IS_LOCKED')){
                        this.showToast('Error', 'This record is locked. If you need to edit it, contact your admin', 'error');
                    }else {
                        this.showToast('Error', response.errors[0], 'error');
                    }
                }
                this.isLoading = false;
            }).catch(error => {
                this.isLoading = false;
                this.showToast('Error', error, 'error');
            });
        }	
        else{	
            this.showToast("Select Endorsement", "Please select at least one Endorsement", "error");	
        }
    }

    @api
    saveSelectedEndorsement() {
        this.isLoading = true;

        saveEndorsement({items: this.selectedEndorsements})
        .then(response =>{
            if(response.isSuccess) {
                //this.selectedEndorsements = response.data;
                this.showToast('Success', 'The data is saved successfully', 'success');
            } else {
                this.showToast('Error', response.errors[0], 'error');
            }
            this.isLoading = false;
        }).catch(error => {
            this.isLoading = false;
            this.showToast('Error', error, 'error');
        });
    }

    handleRowChange(event) {
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id;
        this.selectedEndorsements[event.target.dataset.id][event.target.name] = event.target.value;
    }

    addNewSelectedEndorsement(endorsement) {
        let listNewEndorsement = [];
        listNewEndorsement.push(endorsement);
        let clone = JSON.parse(JSON.stringify(this.selectedEndorsements));
        clone.forEach(item => {
            listNewEndorsement.push(item);
        })
        this.selectedEndorsements = listNewEndorsement;
    }

    handleOnChangeValue(event) {
        let existed = false;
        let recordId = event.target.name;
        for(let i = 0; i < this.listUpdateRecords.length; i++) {
            if(this.listUpdateRecords[i].id == recordId) {
                existed = true;
                this.listUpdateRecords[i].value = event.target.value;
            }
        }
        if(!existed) {
            let temp = {id: event.target.name, value : event.target.value};
            let clone = JSON.parse(JSON.stringify(this.listUpdateRecords));
            clone.push(temp);
            this.listUpdateRecords = clone;
        }
    }

    handleEditEndorsementCLI(event) {
        //let coverageId = event.target.name;
        //this.currentCoverageId = coverageId;

        var row = this.selectedEndorsements[event.target.dataset.id];
        this.currentRow = this.selectedEndorsements[event.target.dataset.id];
        this.currentCoverageId = this.currentRow.id;
        this.showEditEndorsementCLI(this.currentRow.id);
        //this.showEditEndorsementCLI(coverageId);
        this.categoryValues = [];
        //this.resultedEndorsement = [];
    }

    //use to show the coverageLineItem to edit
    showEditEndorsementCLI(coverageId) {
        getEndorsementCLI({quoteId: this.quoteId, coverageId : coverageId})
        .then(result => {
            this.handleLoadDataTable(result);
        })
    }

    handleLoadDataTable(result) {
        let dataTable = JSON.parse(JSON.stringify(result));
        this.tableColumns = dataTable.listColumns;
        //this.tableData = dataTable.data;
        this.isSchedule = dataTable.isSchedule;
        
        this.loadDataTable2(this.tableColumns, dataTable.groupedData);
    
        let temp = dataTable.onlyCoverageCLI;
        for(let i = 0; i < temp.length; i++)
            if(temp[i].Limits_Deductibles__r !== undefined) {
                if(temp[i].Limits_Deductibles__r.Name !== undefined && temp[i].Limits_Deductibles__r.Name !== '')
                    temp[i].Name = temp[i].Limits_Deductibles__r.Name;
            }
            else 
                temp[i].Name = temp[i].Coverage__r.Name;
        this.updateCoveraLineItem = temp;
        this.selectingCoverage = temp[0].Coverage__r.Name;

        this.isEditing = true;
        this.isLoading = false;
    }

    handleDeleteEndorsementCLI(event) {
        let coverageLineItemId = event.target.name;
        this.isLoading = true;
        deleteEndorsementCLI({quoteId: this.quoteId, coverageLineItemId: coverageLineItemId})
        .then(result => {
            if(result) {
                let clone = JSON.parse(JSON.stringify(this.selectedEndorsements));
                clone = clone.filter(item => item.cli != coverageLineItemId);
                this.selectedEndorsements = clone;
                this.updateCoveraLineItem = [];

                this.categoryValues = [];
                this.resultedEndorsement = [];

                this.isUpdated = true;
                // Creates the event with the data.
                const updatedEvent = new CustomEvent('progressvaluechange', {
                    detail: this.isUpdated
                });
                // Dispatches the event.
                //this.isLoading = false;
                this.dispatchEvent(updatedEvent); 
                this.handleSearchButtonClicked(event);
                              
            }
        }).catch(error => {
            this.isLoading = false;
            this.showToast('Error', error, 'error');
        });
    }

    handleCancelEdit(event) {
        this.updateCoveraLineItem = [];
        this.isEditing = false;
        this.handleSearchButtonClicked();
    }

    checkIsExistedEndorsement(endorsementId) {
        let clone = JSON.parse(JSON.stringify(this.selectedEndorsements));
        let isExisted = false;
        clone.forEach(item => {
            if(item.Id === endorsementId) {
                const evt = new ShowToastEvent({
                    title: 'Insert Error',
                    message: 'This endorsement is already existed in the quote',
                    variant: 'Error',
                });
                this.dispatchEvent(evt);
                isExisted = true;
                
            }
        })
        return isExisted;
    }

    loadDataTable2(columns, data){
        let cloneRowData2 = [];
        let cloneColumns = JSON.parse(JSON.stringify(columns));
        let cloneData = JSON.parse(JSON.stringify(data));
        for(let name in cloneData) {
            let rowItem = {};
            rowItem.id = name;
            rowItem.data = [];
            cloneColumns.forEach(column => {
                cloneData[name].forEach(item => {
                    // if(column.label === item.Limits_Deductibles__r.Name) {
                    if(column.id === item.Limits_Deductibles__c) {
                        let dataItem = {};
                        dataItem.id = item.Id;
                        dataItem.value = item.Option_Value_Default__c;
                        //14-Jul-2020 start
                        dataItem.format = 'Text';
                        if(item.Option_Type__c)
                            dataItem.format = item.Option_Type__c;
                            console.log('vinay data format ' + item.Option_Type__c);
                        //dataItem.options = item.Option_Picklist__c;
                        if(item.Option_Picklist__c) {
                            let splitOptions = item.Option_Picklist__c.split(";");
                            let options = [];
                            for(let option of splitOptions) {
                                options.push({label: option, value: option});
                            }
                            dataItem.options = options;
                        }
                        dataItem.min = item.Min_amt__c;
                        dataItem.max = item.Max_amt__c;
                        //14-Jul-2020 end
                        rowItem.data.push(dataItem);              
                    }
                })      
            })
            
            cloneRowData2.push(rowItem);
        }
        this.rowData2 = cloneRowData2;

    }

    handleSort(event){
        // sort direction
        this.contentSortDirection = this.contentSortDirection == 'asc' ? 'desc' : 'asc';
        this.contentSortField = event.currentTarget.dataset.col;
        // calling sortdata function to sort the data based on direction and selected field
        this.selectedEndorsements = this.sortData(event.currentTarget.dataset.col, this.contentSortDirection, JSON.parse(JSON.stringify(this.selectedEndorsements)));
    }

    handleOnChangeEditValue2(event) {
        // let id = event.target.name;
        // let value = event.target.value;
        let id = event.detail.fieldId;
        let value = event.detail.fieldValue;
        let clone = JSON.parse(JSON.stringify(this.rowData2));
        clone.forEach(row => {
            row.data.forEach(item => {
                if(item.id === id) {
                    item.value = value;
                }
            })
        })
        this.rowData2 = clone;
    }

    saveTableData(event, eventTypeName) {
        var isInteger = true;
        if(this.isAqueous){
            this.rowData2.forEach(element => {
                element.data.forEach(element => {
                    if(element.format == 'Currency' && element.value!=null){
                        if(element.value % 1 != 0){
                            this.showToast('Error', 'Only Integer values allowed', 'error')
                            isInteger = false;
                            return;
                        }
                    }
                });
            });
        }
        if(isInteger == true){
            let eventType = eventTypeName;
            let listUpdate = [];
            let cloneRowData2 = JSON.parse(JSON.stringify(this.rowData2));
            cloneRowData2.forEach(row => {
                row.data.forEach(item => {
                    listUpdate.push({id: item.id, value: item.value});
                })
            })
                        
            this.isLoading = true;
            saveUpdatedCLI({
                updatedRecordsString: JSON.stringify(listUpdate),
                endorsement: this.currentRow,
                quoteId: this.quoteId
            }).then(
                result => {
                    if(result.isSuccess){
                        this.isUpdated = true;
                        this.showToast('Success', 'The data is saved successfully', 'success');
                        
                        // Creates the event with the data.
                        const updatedEvent = new CustomEvent('progressvaluechange', {
                            detail: this.isUpdated
                        });
                        // Dispatches the event.
                        this.dispatchEvent(updatedEvent);
                        //this.handleSearchButtonClicked(event);
                        getSelectedEndorsement({quoteId : this.quoteId})
                        .then(result => {
                            this.isLoading = false;
                            this.selectedEndorsements = result;
                        }).catch(error => {
                            this.isLoading = false;
                            this.showToast('Error', error, 'error');
                        });
                        if(eventType == 'newRow'){
                            this.saveNewRow();
                            eventType = '';
                        } 
                    }
                    else 
                        this.showToast('Error', result.errors[0], 'error');
    
                    this.currentRow = null;    
                    this.isEditing = false;
            }).catch(error => {
                this.isLoading = false;
                this.showToast('Error', error, 'error');
                this.isEditing = false;
            });
        }
    }

    handleAddNewRow2(event) {
        let eventTypeName = event.target.name;      
        //this.saveTableData(event, eventTypeName);
        
        // Added by Maeran for US:52871
        if(eventTypeName == 'newRow'){
            this.saveNewRow();
            eventTypeName = '';
        } 
        //this.currentRow = null;    
        this.isEditing = false;
    }

    handleDeleteRow(event) {
        let rowId = event.target.name;
        let cloneRowData2 = JSON.parse(JSON.stringify(this.rowData2));
        let selectedRow = cloneRowData2.filter(item => item.id === rowId);
        let deleteObjects = [];
        selectedRow.forEach(row => {
            row.data.forEach(item => {
                deleteObjects.push(item.id)
            })
        })
        deleteRow({listIds : deleteObjects}).then(result =>{
            if(result == 'success') {
                cloneRowData2 = cloneRowData2.filter(item => item.id !== rowId);
                this.rowData2 = cloneRowData2;
                this.isUpdated = true;
                // Creates the event with the data.
                const updatedEvent = new CustomEvent('progressvaluechange', {
                    detail: this.isUpdated
                });
                // Dispatches the event.
                this.dispatchEvent(updatedEvent);
            }
        }).catch(error => {
            this.isLoading = false;
            this.showToast('Error', error, 'error');
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
    get columns() {
        if (this.isAqueous) {
            return [
                // {label:'Endorsement Name',fieldName:'Name', type:'text'}, 
                { label: 'Form Name', fieldName: 'Form_Number__c', type: 'text' , sortable: "true"}, 
                {
                    label: 'Endorsement Name', fieldName: 'Link_Document__c', type: 'url', sortable: "true",
                    typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }
                },    
                { label: 'Endorsement Type', fieldName: 'Additional_Requirements__c', type: 'text', sortable: "true" }
            ];
        } else {
            return [
                // {label:'Endorsement Name',fieldName:'Name', type:'text'},  
                { label: 'Form Name', fieldName: 'Form_Number__c', type: 'text' },
                {
                    label: 'Endorsement Name', fieldName: 'Link_Document__c', type: 'url',
                    typeAttributes: { tooltip: { fieldName: 'Name' }, label: { fieldName: 'Name' }, target: '_blank' }
                }
            ];
        }
    }
    saveNewRow(){
        if(this.isLoading == false) {
            this.isLoading = true;
            addNewRow({quoteId: this.quoteId, coverageId: this.currentCoverageId})
            .then(results => {
                this.handleLoadDataTable(results);
                
            }).catch(error => {
                this.isLoading = false;
                this.showToast('Error', error, 'error');
            });
        }
    }

    handleSortdata(event) {
        // field name
        this.sortBy = event.detail.fieldName;
        if(event.detail.fieldName == 'Link_Document__c'){
            event.detail.fieldName = 'Name';
        }
        // sort direction
        this.sortDirection = event.detail.sortDirection;
        // calling sortdata function to sort the data based on direction and selected field
        this.resultedEndorsement = this.sortData(event.detail.fieldName, event.detail.sortDirection, JSON.parse(JSON.stringify(this.resultedEndorsement)));
    }

    sortData(fieldname, direction, parseData) {
        // serialize the data before calling sort function
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };

        // cheking reverse direction 
        let isReverse = direction === 'asc' ? 1: -1;

        // sorting data 
        return parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';

            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });

    }
}