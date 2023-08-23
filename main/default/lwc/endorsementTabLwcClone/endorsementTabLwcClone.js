import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCategoryOptions from '@salesforce/apex/EndorsementTabLwcController.getCategoryOptions';
import searchCoverage from '@salesforce/apex/EndorsementTabLwcController.searchCoverage';
import insertEndorsementCLI from '@salesforce/apex/EndorsementTabLwcController.insertEndorsementCLI';
import saveUpdatedCLI from '@salesforce/apex/EndorsementTabLwcController.saveUpdatedCLI';
//import getSelectedCLI from '@salesforce/apex/EndorsementTabLwcController.getSelectedCLI';
import getEndorsementCLI from '@salesforce/apex/EndorsementTabLwcController.getEndorsementCLI';
import deleteEndorsementCLI from '@salesforce/apex/EndorsementTabLwcController.deleteEndorsementCLI'
import addNewRow from '@salesforce/apex/EndorsementTabLwcController.addNewRow'
import deleteRow from '@salesforce/apex/EndorsementTabLwcController.deleteRow'
// import insertEndorsementCLISecond from '@salesforce/apex/EndorsementTabLwcController.insertEndorsementCLISecond';
// import addNewRowSecond from '@salesforce/apex/EndorsementTabLwcController.addNewRowSecond'
export default class EndorsementTabLwc extends LightningElement {

    @api quoteId;
    @track currentCoverageId;
    @track categoryValues = [];
    //@track categories = '';
    @track searchName = '';
    @track endorsementCategoryOption = [];
    @track resultedEndorsement = [];
    @track updateCoveraLineItem = [];    
    @track selectingCoverage = '';
    listUpdateRecords = [];
    @track selectedEndorsements = [];
    @track tableColumns = [];
    // @track tableData = [];
    // @track tableRowOffset = [];
    @track draftValues = [];
    @track isLoading = false;
    @track isEditing = false;
    @track isSchedule = false;
    @track showEditModal = false;
    @track currentEditValues;
    rowActions = [];

    //newDataTable
    @track rowData2 = [];
    @track columnData2 = [];
    updateData2 = [];

    get isResultedCoverage() {
        return this.resultedEndorsement.length > 0;
    }
    get isSelectedCoverage() {
        return this.updateCoveraLineItem.length > 0;
    }

    connectedCallback() {
        getCategoryOptions().then(results => {
            var options = [];
            results.forEach(result => {
                let option = {label : result, value : result};
                options.push(option);
            });
            this.endorsementCategoryOption = options;
        })
		/*
        getSelectedCLI({quoteId : this.quoteId})
        .then(result => {
            this.selectedEndorsements = result;
        }).catch(error => {
            this.isLoading = false;
            this.showToast('Error', error, 'error');
        });
		*/
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
        } else {
            this.handleSearchButtonClicked(event);
        }
    }

    handleSearchNameChanged(event) {
        this.searchName = event.target.value;
        
    }

    handleSearchNameKeyUp(event) {
        const isEnterKey = event.keyCode === 13;
        if(isEnterKey) {
            if(this.categoryValues.length == 0 && this.searchName == '') {
                this.resultedEndorsement = [];
            } else {
                this.handleSearchButtonClicked(event);
            }
        }
    }

    handleSearchButtonClicked(event) {
        searchCoverage({searchName: this.searchName, searchCategories: this.categoryValues, existedCoverage: this.selectedEndorsements})
        .then(result => {
                this.resultedEndorsement = JSON.parse(JSON.stringify(result));
            }
        ).catch(error => {
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

    // handleSaveCLI(event) {
    //     saveUpdatedCLI({updatedRecordsString : JSON.stringify(this.listUpdateRecords)}).then(
    //         result => {
    //             this.listUpdateRecords = [];
    //             this.updateCoveraLineItem = [];
    //         }
    //     );
    // }

    handleEditEndorsementCLI(event) {
        let coverageId = event.target.name;
        this.currentCoverageId = coverageId;
        this.showEditEndorsementCLI(coverageId);
        this.categoryValues = [];
        this.resultedEndorsement = [];

    }

    //use to show the coverageLineItem to edit
    showEditEndorsementCLI(coverageId) {
        getEndorsementCLI({quoteId: this.quoteId, coverageId : coverageId})
        .then(result => {
            let dataTable = JSON.parse(JSON.stringify(result));
            this.tableColumns = dataTable.listColumns;
            //this.tableData = dataTable.data;
            this.isSchedule = dataTable.isSchedule;
            
            this.loadDataTable2(this.tableColumns, dataTable.groupedData);
            // let rowActions = {
            //     type:  'button-icon',
            //     initialWidth: 30,
            //     typeAttributes: 
            //     {
            //         title: 'Edit', 
            //         iconName: 'utility:edit', 
            //         name: 'edit'
            //     }
            // }
            // this.tableColumns.push(rowActions);
            
            // if(this.isSchedule) {
            //     rowActions = {
            //         type:  'button-icon',
            //         initialWidth: 30,
            //         typeAttributes: 
            //         {
            //             title: 'Delete', 
            //             iconName: 'utility:delete', 
            //             name: 'delete',
            //         }
            //     }
            //     this.tableColumns.push(rowActions);
            // }
                       
            // this.setDataTableRow(dataTable);
     
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
        })
    }

    handleDeleteEndorsementCLI(event) {
        let coverageId = event.target.name;
        deleteEndorsementCLI({quoteId: this.quoteId, coverageId: coverageId})
        .then(result => {
            if(result) {
                let clone = JSON.parse(JSON.stringify(this.selectedEndorsements));
                clone = clone.filter(item => item.Id != coverageId);
                this.selectedEndorsements = clone;
                this.updateCoveraLineItem = [];

                this.categoryValues = [];
                this.resultedEndorsement = [];
            }
        }).catch(error => {
            this.isLoading = false;
            this.showToast('Error', error, 'error');
        });
    }

    handleCancelEdit(event) {
        this.updateCoveraLineItem = [];
        this.isEditing = false;
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

    // setDataTableRow(dataTable) {
    //     this.tableRowOffset = Object.keys(dataTable.groupedData); 
    //     let cloneTableData = [];
    //     this.tableRowOffset.forEach(row => {
    //         let data = dataTable.groupedData[row];
    //         let rowItem = {};
    //         let recordIds = {};
    //         data.forEach(dataColumn => {
    //             rowItem[dataColumn.Limits_Deductibles__r.Name] = '';
    //             if(dataColumn.Option_Value_Default__c != undefined && dataColumn.Option_Value_Default__c != null)
    //                 rowItem[dataColumn.Limits_Deductibles__r.Name] = dataColumn.Option_Value_Default__c;
    //             recordIds[dataColumn.Limits_Deductibles__r.Name] = dataColumn.Id;
    //         })
    //         rowItem['id'] = row;
    //         // rowItem['Group'] = row;
    //         rowItem['recordIds'] = recordIds;
    //         cloneTableData.push(rowItem);
    //     })
    //     this.tableData = cloneTableData;
        
    // }

    // handleSaveEndorsementTable(event) {
    //     let draft = JSON.parse(JSON.stringify(event.detail.draftValues));
    //     let cloneTableData = JSON.parse(JSON.stringify(this.tableData));
    //     let listUpdateRecords = [];
    //     draft.forEach(rowItem => {
    //         for(let i = 0; i < cloneTableData.length; i++) {
    //             if(cloneTableData[i].id == rowItem.id) {
    //                 for(let fieldName in rowItem) {
    //                     if(fieldName != 'id') {
    //                         cloneTableData[i][fieldName] = rowItem[fieldName];
    //                         listUpdateRecords.push({'id' : cloneTableData[i]['recordIds'][fieldName], 'value' : rowItem[fieldName]});
    //                     }
                        
    //                 }
    //                 break;
    //             };
    //         }
    //     })
    //     saveUpdatedCLI({updatedRecordsString: JSON.stringify(listUpdateRecords)}).then(
    //         result => {
    //             this.tableData = cloneTableData;
    //             this.draftValues = [];
    //     })
        
    // }

    // handleAddNewRow(event) {
    //     if(this.isLoading == false) {
    //         this.isLoading = true;
    //         // addNewRow({quoteId: this.quoteId, coverageId: this.currentCoverageId})
    //         addNewRowSecond({quoteId: this.quoteId, coverageId: this.currentCoverageId})
    //         .then(results => {
    //             let rowData = {}; 
    //             let recordIds = {};
    //             if(results[0] != undefined)
    //                 rowData['id'] = results[0].Group__c
    //             results.forEach(
    //                 item => {
    //                     rowData[item.Limits_Deductibles__r.Name] = '';
    //                     if(item.Option_Value_Default__c != undefined && item.Option_Value_Default__c != null)
    //                         rowData[item.Limits_Deductibles__r.Name] = item.Option_Value_Default__c;
    //                     recordIds[item.Limits_Deductibles__r.Name] = item.Id;
    //                 });
    //             rowData['recordIds'] = recordIds;
    //             let cloneTableData = JSON.parse(JSON.stringify(this.tableData));
    //             cloneTableData.push(rowData);
    //             this.tableData = cloneTableData;
    //             this.isLoading = false;
    //         });
    //     }
    // }

    // handleRowActions(event) {
    //     let actionName = event.detail.action.name;
    //     window.console.log('actionName ====> ' + actionName);
    //     let row = JSON.parse(JSON.stringify(event.detail.row));
    //     switch (actionName) {
    //         case 'edit':
    //             this.editRow(row);
    //             break;
    //         case 'delete':
    //             this.deleteRow(row);
    //             break;
    //     }
    // }

    // editRow(row) {
    //     let editDatas = {};
    //     editDatas.id = row.id;
    //     editDatas.data = [];
    //     for(let name in row) {
    //         if(name != 'id' && name != 'recordIds') {
    //             let data = {};
    //             data.id = row['recordIds'][name];
    //             data.name = name;
    //             data.value = row[name];   
    //             editDatas.data.push(data);
    //         }
    //     }
    //     this.currentEditValues = editDatas;
    //     this.showEditModal = true;
    // }

    // deleteRow(row) {
    //     let deleteObjects = [];
    //     for(let name in row['recordIds']) {
    //         deleteObjects.push(row['recordIds'][name]);
    //     }
    //     deleteRow({listIds : deleteObjects}).then(result =>{
    //         if(result == 'success') {
    //             let cloneTableData = JSON.parse(JSON.stringify(this.tableData));
    //             cloneTableData = cloneTableData.filter(rowData => rowData.id != row.id);
    //             this.tableData = cloneTableData;
    //         }
    //     })
    // }

    // handleOnChangeEditValue(event) {
    //     let id = event.target.name;
    //     let value = event.target.value;
    //     let clone = JSON.parse(JSON.stringify(this.currentEditValues));
    //     clone.data.forEach(item => {
    //         if(item.id === id) {
    //             item.value = value;
    //         }
    //     })
    //     this.currentEditValues = clone;
    // }
    // closeEditModal(event) {
    //     this.currentEditValues = {};
    //     this.showEditModal = false;
    // }

    // saveEditModal(event) {
    //     let listUpdate = [];
    //     this.currentEditValues.data.forEach(item => {
    //         listUpdate.push({id: item.id, value: item.value});
    //     })
    //     saveUpdatedCLI({updatedRecordsString: JSON.stringify(listUpdate)}).then(
    //         result => {
    //             let cloneTableData = JSON.parse(JSON.stringify(this.tableData));
    //             for(let i = 0; i < cloneTableData.length; i++) {
    //                 if(cloneTableData[i].id === this.currentEditValues.id) {
    //                     this.currentEditValues.data.forEach(item => {
    //                         cloneTableData[i][item.name] = item.value;
    //                     })
    //                     this.closeEditModal(event);
    //                     break;
    //                 }
    //             }
    //             this.tableData = cloneTableData;
    //     })
        
    // }

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
                        rowItem.data.push(dataItem);              
                    }
                })      
            })
            
            cloneRowData2.push(rowItem);
        }
        this.rowData2 = cloneRowData2;

    }

    handleOnChangeEditValue2(event) {
        let id = event.target.name;
        let value = event.target.value;
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

    saveTableData(event) {
        let listUpdate = [];
        let cloneRowData2 = JSON.parse(JSON.stringify(this.rowData2));
        cloneRowData2.forEach(row => {
            row.data.forEach(item => {
                listUpdate.push({id: item.id, value: item.value});
            })
        })
        
        saveUpdatedCLI({updatedRecordsString: JSON.stringify(listUpdate)}).then(
            result => {
                if(result.isSuccess) 
                    this.showToast('Success', 'The data is saved successfully', 'success');
                else 
                    this.showToast('Error', result.errors[0], 'error');
                this.isEditing = false;
        }).catch(error => {
            this.isLoading = false;
            this.showToast('Error', error, 'error');
            this.isEditing = false;
        });
    }

    handleAddNewRow2(event) {
        if(this.isLoading == false) {
            this.isLoading = true;
            addNewRow({quoteId: this.quoteId, coverageId: this.currentCoverageId})
            .then(results => {
                let rowData = {}; 
                if(results[0] != undefined)
                    rowData['id'] = results[0].Group__c;
                rowData.data = [];
                let cloneTableColumns = JSON.parse(JSON.stringify(this.tableColumns));
                cloneTableColumns.forEach(column => {
                    results.forEach(item => {
                        // if(item.Limits_Deductibles__r.Name === column.label) {
                        if(column.id === item.Limits_Deductibles__c) {
                            let data = {};
                            data.id = item.Id;
                            data.value = item.Option_Value_Default__c;
                            rowData.data.push(data);
                        }
                    });
                })
                
                let cloneRowData2 = JSON.parse(JSON.stringify(this.rowData2));
                cloneRowData2.push(rowData);
                this.rowData2 = cloneRowData2;
                this.isLoading = false;
            }).catch(error => {
                this.isLoading = false;
                this.showToast('Error', error, 'error');
            });
        }
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


}