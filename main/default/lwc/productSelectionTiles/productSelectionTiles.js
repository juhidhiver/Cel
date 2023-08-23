import { LightningElement,api,wire, track} from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import createQuoteProcess from '@salesforce/apex/QuoteProcessLWCController.createQuoteProcess';
import addAccount from '@salesforce/apex/QuoteProcessLWCController.addAccount';
//import createQuoteProcessPcc from '@salesforce/apex/productSelectionController.createQuoteProcessPcc';
import insertPlaceholderSubmission from '@salesforce/apex/productSelectionController.insertPlaceholderSubmission';
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
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import PCC_PROD_NAME from '@salesforce/label/c.Product_Name_for_PCC';
import DEFAULT_SUBMISSION_NAME_FOR_PCC from '@salesforce/label/c.DEFAULT_SUBMISSION_NAME_PCC';

//53990 Start
import getPolicyList from '@salesforce/apex/QuoteProcessLWCController.getPolicyList';
import fetchOpportunity from '@salesforce/apex/QuoteProcessLWCController.fetchOpportunity';
import fletchData from '@salesforce/apex/QuoteProcessLWCController.fletchData';
import getRecordTypeObject from "@salesforce/apex/QuoteProcessLWCController.getRecordTypeObject";

//Constructor show actions
const actions = [
    { label: 'Show details', name: 'show_details' },
];

//53990 Stop

export default class ProductSelectionTiles extends NavigationMixin(LightningElement) {
    @api eachProd={}
    @api accountId = ''
    oppId=''
    productId
    submbissionRecordTypeId
    showSpinner

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

    //53990 start
    //--------------------------------Merge cmps----------------
    @track offset = 0;
    @track recordNumber = 5;
    @api quoteProcessId1;
    @track valueChecked = 'Existing Submission';
    @api pickedValue = 'Existing Submission';
    @track openmodel = false;
    @track openmodal = false;
    @track opps = [];
    @track oppsList = [];
    @api isAccount = false;
    @api accountId1 = '';
    @track isloaddata = true;
    @api objectName = 'Opportunity';
    showSpinner
    //Data Table attributes
    @track columns = [
        {
            label: 'Submissions Name', fieldName: 'linkOpportunityName', type: 'url', sortable: true,
            typeAttributes: { label: { fieldName: 'opportunityName' }, target: '_blank' }
        },
        {
            type: 'action',
            typeAttributes: { rowActions: actions },
        },
        { label: 'Product', fieldName: 'productSub', sortable: true },
        { label: 'Amount', fieldName: 'amountSub', sortable: true },
        { label: 'Effective Date', fieldName: 'effectiveSub', sortable: true },
        { label: 'Expiration Date', fieldName: 'expirationSub', sortable: true },
        { label: 'Stage', fieldName: 'stageSub', sortable: true },
        { label: 'Lead Source', fieldName: 'leadSub', sortable: true },
        { label: 'Created Date', fieldName: 'createdSub', sortable: true },
    ];
    @track sortBy;
    @track sortDirection = 'asc';
    constructor() {
        super();
        this.loadMoreData(this.offset, this.recordNumber, true);
        //this.fletchDataOnSF('',this.objectName,'');
        this.fletchDataPol('');
    }
    //Get Options Label
    get options() {
        return [
           // { label: 'New Submission', value: 'newSubmission' },
           { label: 'Existing Policies', value: 'Existing Policies' },
            { label: 'Existing Submission', value: 'Existing Submission' },
            
        ];
    }

    lazyLoad(event) {
        this.offset = parseInt(this.offset) + 1;
        console.log('Lazy Load Offset ' + this.offset);
        this.loadMoreData(this.offset, this.recordNumber, false);
    }
    loadMoreData(offset, recordNumber, isInit) {
        fletchData({ offset: offset, recordNumber: recordNumber, isInit: isInit })
            .then(result => {
                if (result.length == 0) {
                    this.isloaddata = false;
                }
                let currentData = [];
                result.forEach((row) => {
                    let rowData = {};
                    rowData.linkOpportunityName = '/' + row.QpId;
                    rowData.opportunityName = row.Name;
                    rowData.stageSub = row.StageName;
                    rowData.leadSub = row.LeadSource;
                    rowData.createdSub = row.CreatedDate;
                    rowData.amountSub = row.Amount;
                    rowData.productSub = row.Product_Name;
                    rowData.effectiveSub = row.Effective_Date;
                    rowData.expirationSub = row.Expiration_Date;
                    currentData.push(rowData);
                });
                this.oppsList = this.oppsList.concat(currentData);;
            })
            .catch(error => {
                this.error = error;
            });
    }
//Navigate to Quote Process Page
navigateToRecordViewPage() {
    console.log('This is recordId: ' + this.quoteProcessId1);
    let pageRef = {
        type: 'standard__recordPage',
        attributes: {
            recordId: this.quoteProcessId1,
            objectApiName: 'Quote_Process__c',
            actionName: 'view'
        },
        state: {
            //c__recordId : this.recordId
        }
    };
    this[NavigationMixin.Navigate](pageRef);
}

//Onclick Close Modal
closeModal() {
    this.openmodel = false;
    this.openmodal = false;
    this.dispatchEvent(new CustomEvent('hidebar'));
    this.dispatchEvent(new CustomEvent('closemodal'));
}

//Handle Row Action event show
handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;
    switch (actionName) {
        case 'show_details':
            this.showRowDetails(row);
            break;
        default:
    }
}

//Show details record
showRowDetails(row) {
    // let recordid = row.opportunityId;
    // this.navigateToRecordViewPage(recordid);
}

fletchDataOnSF(searchKey, objectName, accId) {
    this.offset = 0;
    this.isloaddata = false;
    if (!searchKey && !this.isAccount) {
        this.isloaddata = true;
    }
    fetchOpportunity({ searchKey: searchKey, objectName: objectName, accId: accId, recordNumber: this.recordNumber })
        .then(result => {
            let currentData = [];
            result.forEach((row) => {
                let rowData = {};
                rowData.linkOpportunityName = '/' + row.QpId;
                rowData.opportunityName = row.Name;
                rowData.stageSub = row.StageName;
                rowData.leadSub = row.LeadSource;
                rowData.createdSub = row.CreatedDate;
                rowData.amountSub = row.Amount;
                rowData.productSub = row.Product_Name;
                rowData.effectiveSub = row.Effective_Date;
                rowData.expirationSub = row.Expiration_Date;
                currentData.push(rowData);
            });
            this.oppsList = currentData;
        })
        .catch(error => {
            this.error = error;
        });

}
handleKeyChange(event) {
    this.fletchDataOnSF(event.target.value, this.objectName, this.accountId1);
}

@track value = 'inProgress';

get optionscombobox() {
    return [
        { label: 'Submission', value: 'subSearch' },
        { label: 'Account', value: 'accountSearch' },
    ];
}

onchangeAccount(event) {
    this.accountId1 = event.target.value;
    this.fletchDataOnSF(null, this.objectName, event.target.value);
}

handleChange(event) {
    console.log('Search Object ' + event.target.value);
    this.value = event.detail.value;
    if (event.target.value == 'accountSearch') {
        this.isAccount = true;
        this.objectName = 'Account';
    } else {
        this.objectName = 'Opportunity';
        this.isAccount = false;
    }

}

//Existing Policy Submission--------------
@track polList = [];

get optionscomboboxPolicy() {
    return [
        { label: 'Policies', value: 'policySearch' },
    ];
}

//Data Table attributes
@track columnsPol = [
    {
        label: 'Policy Name', fieldName: 'linkPolicyName', type: 'url',
        typeAttributes: { label: { fieldName: 'policyName' }, target: '_blank' }
    },
    {
        type: 'action',
        typeAttributes: { rowActions: actions },
    },
    { label: 'Policy Number', fieldName: 'polNumber' },
    { label: 'Policy Status', fieldName: 'polStatus' },
    { label: 'Effective Date', fieldName: 'effectivePol' },
    { label: 'Expiration Date', fieldName: 'expirationPol' },
    { label: 'Total Premium', fieldName: 'totalPre' },
];

fletchDataPol(searchKeyPol) {
    getPolicyList({ searchKeyPol: searchKeyPol })
        .then(result => {
            let currentData = [];
            result.forEach((row) => {
                let rowData = {};
                rowData.linkPolicyName = '/' + row.QpId;
                rowData.policyName = row.Name;
                rowData.polNumber = row.Policy_Number;
                rowData.polStatus = row.Policy_Status;
                rowData.totalPre = row.Total_Premium;
                rowData.effectivePol = row.Effective_Date;
                rowData.expirationPol = row.Expiration_Date;
                currentData.push(rowData);
            });
            this.polList = currentData;
        })
        .catch(error => {
            this.error = error;
        });

}

handleKeyChangepolicy(event) {
    this.fletchDataPol(event.target.value);
}

handleChangePolicy(event) {
    console.log('Search Object 1111' + event.target.value);
    this.value = event.detail.value;
}
handlerSort(event) {
    // event.preventDefault();
    const { fieldName: sortedBy, sortDirection } = event.detail;
    console.log(this.sortBy === sortedBy);
    if (this.sortBy === sortedBy || sortedBy == 'linkOpportunityName') {
        if (this.sortDirection == 'asc') {
            this.sortDirection = 'desc';
        } else if (this.sortDirection == 'desc') {
            this.sortDirection = 'asc';
        }
    }
    this.sortBy = sortedBy == 'linkOpportunityName' ? 'opportunityName' : sortedBy;
    console.log(JSON.stringify(event.detail));

    console.log('sortBy', this.sortBy);
    console.log('sortDirection', this.sortDirection);
    this.sortData(this.sortBy, this.sortDirection);
}
sortData(fieldname, direction) {
    // serialize the data before calling sort function
    let parseData = JSON.parse(JSON.stringify(this.oppsList));

    // Return the value stored in the field
    let keyValue = (a) => {
        return a[fieldname];
    };

    // cheking reverse direction 
    let isReverse = direction === 'asc' ? 1 : -1;

    // sorting data 
    parseData.sort((x, y) => {
        const valx = keyValue(x) ? keyValue(x) : ''; // handling null values
        const valy = keyValue(y) ? keyValue(y) : '';
        // sorting values based on direction
        return isReverse * ((valx > valy) - (valy > valx));
    });

    // set the sorted data to data table data
    this.oppsList = parseData;

}


@track recordTypeOptions;
@track recordTypeSelector;
@track recordTypeId;
@track recordTypeName;
@track record;

//Used for creating Record Start
@wire(getRecordTypeObject, { sObjectName: 'Opportunity' })
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
        console.log('RecordId:'+this.recordTypeId+ 'Name: '+this.recordTypeName)
      }
      

  }
  else if (error) {
      this.record = undefined;
      console.log("error ", error);
  }
}

//Used for creating Record End
closeChooseRecordTypeModal() {
this.recordTypeSelector = false;
console.log('inside optionworkjs');
this.dispatchEvent(new CustomEvent("hidebar"));

}
//End
    //53990 stop
     

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

    handleClickNextWithRecordType(event){
        this.showSpinner = true
        this.submbissionRecordTypeId = this.getRecordTypeId('Celerity')
        console.log('Datasets-->',JSON.stringify(event.target.dataset) )
        console.log('Dataset Target-->',JSON.stringify(event.currentTarget.dataset) )
        const {recordtype,prodcode} = event.target.dataset
        console.log('recordTypeName: '+recordtype )
        //53990 start
       if(prodcode == 'NA' && recordtype == 'Celerity')
       {
            console.log('inside NA if');
            this.showSpinner = true
            this.pickedValue = event.target.value;
            const {value} = event.target.dataset;
            this.pickedValue = value;
            if (this.pickedValue == 'Existing Submission') { 

              this.openmodel = true;
              this.dispatchEvent(new CustomEvent('openmodal'));
              this.showSpinner = false   
            }
            if (this.pickedValue == 'Existing Policies') {
                this.showSpinner = false 
              this.openmodal = true;
              this.dispatchEvent(new CustomEvent('openmodal'));
             
            }

       }//53990 Stop
         else{
               console.log('Not PCC')
            createQuoteProcess({recordTypeName :recordtype, productName :prodcode})
            .then(result => {
                    this.quoteProcessId = result;
                    if(prodcode != PCC_PROD_NAME){
                        
                        if (this.accountPage == 'Account') {
                            addAccount({ quoteProcessId: this.quoteProcessId, accountId: this.accountId }).then(result => {
                                console.log('addAccount ');
                                //this.dispatchEvent(new CustomEvent('ultilitybarclose'));
                                this.showSpinner = false
                                this.navigateToRecordViewPage();
                            })
                        } else {
                            //this.dispatchEvent(new CustomEvent('ultilitybarclose'));
                            this.showSpinner = false
                            this.navigateToRecordViewPage();
                        }
                    }

                    else{

                        //let closeDate = this.formatDateWithDaysAdded(365)
                        var closeDate = new Date();
                        closeDate.setDate(new Date().getDate() + 90);
            
                        let effectiveDate = this.formatDateWithDaysAdded(1)


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
                    this.showSpinner = false
                    console.log('Error @@Creating Quoteprocess: '+ JSON.stringify(error));
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'title',
                        message: error.message,
                        variant: 'error'
                    }));
                });    
            }
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
    
}