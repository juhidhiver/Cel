import { LightningElement,api,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class ListLwc extends NavigationMixin(LightningElement) {

    @api objectApiName;
    @track currenObjectName;
    @api currenrecordid;
    @api title;
    @api product;
    @api nonEditable;

    @api listfields;
    @track quoteId;

    // Private var to track @api accountId
    _accId = undefined;

    set accId(value) {
        this._accId = value;
        //this.data = this.listdata;
    }
    
    // getter for accountId
    @api get accId(){
        return this._accId;
    }
    @track isFreeFormEndo = false;
    @track isSubjectivity = false;
    @track isAdditionlaInsured = false;
    connectedCallback() {
        console.log('Title: '+this.title);
        if(this.title == 'Free Form Endorsements'){
            this.isFreeFormEndo = true;
        }else if(this.title == 'Subjectivity'){
            this.isSubjectivity = true;
        }else if(this.title == 'Additional Insured Details'){
            this.isAdditionlaInsured = true;
        }
        this.currenObjectName = this.objectApiName;
        console.log('@@@currenrecordid::'+this.currenrecordid);
        console.log('@@@Column::'+JSON.stringify(this.columns));
        this.quoteId = this.currenrecordid;
        console.log('@@@product::'+this.product);
    }
    @api recId;
    @api listdata = [];
    
    @api columns;
    @track listdata;

    @api defaultSortDirection;
    @api sortDirection;
    sortedBy;

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
        console.log('this.listdata before sort: ',this.listdata);
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.listdata];
        console.log('this.listdata before sort: ',cloneData);
        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.listdata = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }
    
    @track openmodel = false;
    @track subjectivitySearchComponent;
    showSubjectivityModal(){
        this.subjectivitySearchComponent = true;
        console.log('@@@this.subjectivitySearchComponent::'+this.subjectivitySearchComponent);
        console.log('@@@currenrecordid::'+this.currenrecordid);
    }

    navigateToRecordViewPage(oppRecordId) {
        console.log('eventId:'+oppRecordId);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId :oppRecordId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
    }

    handleClick(event) {
        event.preventDefault();
        event.stopPropagation();
        this.navigateToRecordViewPage(event.detail);
    }


    findRowIndexById(id) {
        let ret = -1;
        this.data.some((row, index) => {
            if (row.id === id) {
                ret = index;
                return true;
            }
            return false;
        });
        return ret;
    }

    @track selectedRow;
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
        const event = new CustomEvent('updaterowselected', {
            detail: row.Id// + Math.floor(Math.random() * 100)
        });
        // Fire the event from c-tile
        this.dispatchEvent(event);
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

    closeModal(){
        this.openmodel = false;
    }
    closeSubjectivityModal(event){
        this.subjectivitySearchComponent = event.detail;
    }
    @track refreshValue;
    refreshevent(event){
        this.refreshValue = true;
        console.log('set refresh value in listlwc');
        const refreshEventFromList = new CustomEvent("refresheventfromlist", {
            detail: this.refreshValue
            });
        this.dispatchEvent(refreshEventFromList);
    }

    handleClickOpenModalInsureContact() {
        console.log('handleClickOpenModalInsureContact');
        var openModalCreateInsureContact = true;
        var infos = {openModalCreateInsureContact : true, formName : this.title};

        const event = new CustomEvent('createnewone', {
            detail: infos
        });
        // Fire the event from c-tile
        this.dispatchEvent(event);
    }

    @track isDialogVisible = false;
    @track originalMessage;
    @track displayMessage = 'Click on the \'Open Confirmation\' button to test the dialog.';
    
    handleClick(event) {
        //when user clicks outside of the dialog area, the event is dispatched with detail value  as 1
        if(event.detail !== 1){
            if(event.detail.status === 'confirm') {
                const event = new CustomEvent('deleterowselected', {
                    detail: this.selectedRow.Id
                });
                this.dispatchEvent(event);
            }else if(event.detail.status === 'cancel'){
                this.isDialogVisible = false;
            }
        }
        this.isDialogVisible = false;
    }
}