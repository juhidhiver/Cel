import { LightningElement, api, wire, track } from 'lwc';
import { createRecord, updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getRecordTypeInfo from '@salesforce/apex/InsureAccountController.getRecordTypeInfo';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import { NavigationMixin } from 'lightning/navigation';
import getAccountInfos from '@salesforce/apex/InsureAccountController.getAccountInfos';

const BROKER_RT = 'Broker';
const INSURANCE_RT = 'Insurance Company Contact';
const BUSINESS_RT = 'Business';
export default class RelatedListLwc extends NavigationMixin(LightningElement) {

    privateCustomColumnsInput;

    @api objectApiName;

    /* START CD-138 */
    @api enableBrokerEdit;
    @api disableRelatedList;
    @api enableBrokerDelete;
    /* END CD-138 */

    @api submissionType;

    @api recordId;
    @api title;

    @api recordInfoDefined;
    @api recordInfo;

    @api isAqueousPI = false;

    @api
    get customcolumnsinput() {
        return this.privateCustomColumnsInput;
    }

    @track _listfields;

    @api get listfields() {
        return this._listfields;
    }
    columnsTable = '';
    set listfields(value) {
        this._listfields = value;
        var tmpColumns = [];
        this._listfields.forEach(function (item) {
            if (item) {
                tmpColumns.push(item.sourceFieldApi);
            }
        });
        this.columnsTable = tmpColumns.join();

    }

    @track objectInfo;
    //@track childRecordTypeId;
    @api childRecordTypeId;
    @track error;

    set customcolumnsinput(value) {
        this.privateCustomColumnsInput = value.toUpperCase();
    }

    @track currentdata = [];
    @track currentcolumns;// = [];
    @track currentPage;

    @api contactId;

    selectedRowId;

    @track openModalCreateInsureContact = false;

    @track _selectedAccountId;
    set selectedAccountId(value) {
        this._selectedAccountId = value;
        this.recordId = this._selectedAccountId;//'0011k00000bsJ9oAAE';
    }

    @api get selectedAccountId() {
        return this._selectedAccountId
    }

    @track accountObj;

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    objectInfo;
	/*
	@wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
	getObjectInfo({error, data}){
       if(data){
			this.objectInfo=data;
			this.error = undefined;

			const rtis = data.recordTypeInfos;
			var checkBroker = this.title;
			//var rt = (this.title === BROKER_SECTION_INFO) ? BROKER_RT : INSURANCE_RT;
			var rt = checkBroker.includes('Broker') ? BROKER_RT : INSURANCE_RT;
			
			this.childRecordTypeId = Object.keys(rtis).find(rti => rtis[rti].name === rt);
			console.log('##get recordType :' + rt);
			console.log('##get recordTypeId :' + this.childRecordTypeId);
       }
       else if(error){
          this.error = error;
		  this.objectInfo = undefined;

		  console.log('##error :' + this.error);
       }
     };
	*/
    hasRecordType;
    connectedCallback() {
        console.log('RecordType Id: ',this.childRecordTypeId);
        /*
        Promise.all([
            loadStyle(this, CustomLocalCss),
        ])
        .then(() => {
            console.log('Files loaded.');
        })
        .catch(error => {
            console.log(error.body.message);
        });*/
        this.recordId = this._selectedAccountId;//'0011k00000bsJ9oAAE';
        getAccountInfos({ recordId: this._selectedAccountId }).then(result => {
            console.log('getAccountInfos', JSON.stringify(result));

            this.accountObj = JSON.parse(JSON.stringify(result));
        })
        
        var checkBroker = this.title;
        console.log('##connectedCallback,this.title:', checkBroker);
        /*if (this.objectInfo.data) {
            const rtis = this.objectInfo.data.recordTypeInfos;
            var rt = checkBroker.includes('Broker') ? BROKER_RT : BUSINESS_RT;
            this.childRecordTypeId = Object.keys(rtis).find(rti => rtis[rti].name === rt);
        } else {
            getRecordTypeInfo({ typeRT: checkBroker })
                .then(result => {
                    this.childRecordTypeId = result;
                })
                .catch(error => {
                    this.error = error;
                });

        }*/
        if (this.objectApiName == 'Contact') {
            this.hasRecordType = true;
        } else {
            this.hasRecordType = false;
        }

    }

    handleRowClick(evt) {
        this.selectedRowId = evt.detail;
    }
    handlePageChanged(event) {
        var brokerId = '';
        var currentdata;
        if(event && event.detail && event.detail.data)  
        currentdata = event.detail.data;
        var currentList = [];
        currentdata.forEach(function (record) {
            var secondObject = {};
            for (var k in record) {
                secondObject[k] = record[k];
            }
            secondObject.linkName = '/' + record.Id;
            currentList.push(secondObject);
        });
        this.currentdata = currentList;
        var brokerAccountName = '';
      this.currentdata.forEach(element => {
          if(element.Broker_Account__c != null){
              var mainStr = element.Broker_Account__c;
              brokerId = mainStr.substring(mainStr.indexOf('"')+1,mainStr.indexOf('"',mainStr.indexOf('"')+1)).replace('/','');
             brokerAccountName = element.Broker_Account__c.replace( /(<([^>]+)>)/ig, '');
             element.Broker_Account__c = '/'+brokerId;
             element.BrokerAccount_Name__c = brokerAccountName;}
      });
     
        var columns = event.detail.columns;
        columns.forEach(element => {
            if(element.fieldName == 'Broker_Account__c'){
                element.type = 'url';
                element.typeAttributes = {label: {fieldName: 'BrokerAccount_Name__c'},target: '_blank'};
            }
        });
        console.log('current column: ',JSON.stringify(columns));
        if (columns) {
            this.currentcolumns = JSON.parse(JSON.stringify(columns));
            this.currentPage = event.detail.currentpage;
        }
    }
    modeEditContact;
    handleUpdateRowSelected(event) {
        if(this.objectApiName == 'Broker_Account__c' && this.disableRelatedList && (!this.isAqueousPI || (this.isAqueousPI && !this.enableBrokerEdit))){
            var oppType = this.submissionType == 'Full Amendment' ? 'Full Amendment' : 'Locked';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'You cannot Edit Record on '+oppType+' Submission.',
                    variant: 'error'
                })
            );
            return;
        }
        this.selectedRowId = event.detail;
        this.openModalCreateInsureContact = true;
        this.modeEditContact = true;
        this.modeCreateContact = false;
        /*
        let temp = {
            type: 'standard__objectPage',
            attributes: {
                recordId: this.selectedRowId,
                objectApiName: 'Contact',
                actionName: 'edit'                
            },
            state : {
                nooverride: '1',
                defaultFieldValues:"AccountId=" + this.selectedAccountId
            }
        };
        this[NavigationMixin.Navigate](temp);*/
        /*
        getRecordInfos({ recordId: event.detail})
        .then((contact) => {
            var listfieldsTmp = JSON.parse(JSON.stringify(this.listfields));
            listfieldsTmp.forEach(function(item) {
                item.value = contact[item.sourceFieldApi];
            });
            this._listfields = listfieldsTmp;
        })
        .catch(error => {
            console.log('handleUpdateRowSelected error:' + JSON.stringify(error));
        });*/
    }

    handleDeleteRowSelected(event) {
        if(this.objectApiName == 'Broker_Account__c' && !this.enableBrokerDelete){
            var oppType = this.submissionType == 'Full Amendment' ? 'Full Amendment' : 'Locked';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'You cannot Delete Record on '+oppType+' Submission.',
                    variant: 'error'
                })
            );
            return;
        }
        var rowId = event.detail;
        deleteRecord(rowId)
            .then(() => {
                this.template.querySelector('c-pagination-lwc').refreshDataTable();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record deleted',
                        variant: 'success'
                    })
                );
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


    handleSelection(event) {
        this.contactId = event.detail.selectedId;
    }

    modeCreateContact;
    handleOpenModalCreateInsureContact(event) {
        /*
        var listfieldsTmp = JSON.parse(JSON.stringify(this.listfields));
        listfieldsTmp.forEach(function(item) {
            item.value = null;
        });
        this._listfields = listfieldsTmp;*/
       if(this.objectApiName == 'Broker_Account__c' && this.disableRelatedList ){
            var oppType = this.submissionType == 'Full Amendment' ? 'Full Amendment' : 'Locked';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'You cannot create New Record on '+oppType+' Submission.',
                    variant: 'error'
                })
            );
            return;
        }
        this.openModalCreateInsureContact = event.detail.openModalCreateInsureContact;
        this.modeCreateContact = true;
        this.modeEditContact = false;
        /*
        let temp = {
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Contact',
                actionName: 'new'                
            },
            state : {
                nooverride: '1',
                defaultFieldValues:"AccountId=" + this.selectedAccountId
            }
        };
        this[NavigationMixin.Navigate](temp);*/

    }
    handleCancel() {
        this.openModalCreateInsureContact = false;
    }

    saveNewContact() {
        this.saveContact();
        this.allowReset();
    }

    saveContact() {
        const fields = {};
        this.template
            .querySelectorAll("c-generate-element-lwc")
            .forEach(element => {
                var tmp = element.getValuesOnForm();
                if (tmp.type == 'textfield') {
                    fields[tmp.key] = tmp.value;
                }
                if (tmp.type == 'address') {
                    var addressFieldKey = tmp.key;
                    addressFieldKey = addressFieldKey.replace('Address', '');
                    var addressFieldJson = JSON.parse(JSON.stringify(tmp));
                    var addressField = addressFieldJson['value'];
                    fields[addressFieldKey + 'Street'] = addressField.street;
                    fields[addressFieldKey + 'City'] = addressField.city;
                    fields[addressFieldKey + 'StateCode'] = addressField.province;
                    fields[addressFieldKey + 'CountryCode'] = addressField.country;
                    fields[addressFieldKey + 'PostalCode'] = addressField.postalCode;
                }
            });
        if (this.selectedAccountId) {
            fields['AccountId'] = this.selectedAccountId;
        }
        if (this.childRecordTypeId) {
            fields['RecordTypeId'] = this.childRecordTypeId;
        }
        //console.log('this.selectedRowId:' + this.selectedRowId);
        if (!this.selectedRowId) {
            const recordInput = { apiName: CONTACT_OBJECT.objectApiName, fields };
            createRecord(recordInput)
                .then(contact => {
                    //this.accountId = account.id;
                    this.template.querySelector('c-pagination-lwc').refreshDataTable();
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Contact created',
                            variant: 'success',
                        }),
                    );
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error creating record',
                            message: error.body.message,
                            variant: 'error',
                        }),
                    );
                });
        } else {
            fields['Id'] = this.selectedRowId;
            const recordInput = { fields };
            //console.log('fields2:' + JSON.stringify(fields));
            updateRecord(recordInput)
                .then(account => {
                    this.selectedRowId = null;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Contact updated',
                            variant: 'success',
                        }),
                    );
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error update record',
                            message: error.body.message,
                            variant: 'error',
                        }),
                    );
                });
        }
    }

    allowReset() {
        this.template.querySelectorAll("c-generate-element-lwc")
            .forEach(element => {
                element.resetValuesOnForm();
            });
    }

    handleOnLoad(event) {
        console.log('acc:', JSON.parse(JSON.stringify(this.accountObj)));
        const acc = JSON.parse(JSON.stringify(this.accountObj));
        const detail = JSON.parse(JSON.stringify(event.detail));
        console.log('fields:', detail);
        const recordContact = detail.record.fields;
        this.template.querySelectorAll('.slds-input').forEach(element => {
            console.log('222:' + JSON.stringify(element));
        });
        if(recordContact.AccountId) {
            recordContact.AccountId.value = this.selectedAccountId;
            recordContact.Account.value = {
                apiName: 'Account',
                childRelationships: {},
                fields: {
                    Id: {
                        displayValue: null,
                        value: this.selectedAccountId
                    },
                    Name: {
                        displayValue: 'INTEL CORPORATION',
                        value: 'INTEL CORPORATION'
    
                    }
                },
                id: this.selectedAccountId,
                lastModifiedById: null,
                lastModifiedDate: new Date().toISOString(),
                recordTypeId: null,
                recordTypeInfo: null,
                systemModstamp: new Date().toISOString()
            };
            recordContact.Account.displayValue = 'INTEL CORPORATION';
        }
    }


handleSubmit(event) {
    event.preventDefault();
    const fields = event.detail.fields;
    //fields.AccountId = this.selectedAccountId;
    console.log('this.selectedAccountId:' + this.selectedAccountId);
    this.template.querySelector('lightning-record-form').submit(fields);
    //this.template.querySelector('lightning-record-form').submit();
}

handleAddSuccess(event) {
    this.template.querySelector('c-pagination-lwc').refreshDataTable();
    this.dispatchEvent(
        new ShowToastEvent({
            title: 'Success',
            message: 'Record saved successfully with id: ' + event.detail.id,
            variant: 'success',
        }),
    )
    this.modeCreateContact = false;
    this.handleCancel();
}

handleEditSuccess(event) {
    this.template.querySelector('c-pagination-lwc').refreshDataTable();
    this.dispatchEvent(
        new ShowToastEvent({
            title: 'Success',
            message: 'Record updated successfully with id: ' + event.detail.id,
            variant: 'success',
        }),
    )
    this.modeEditContact = false;
    this.handleCancel();
}
}