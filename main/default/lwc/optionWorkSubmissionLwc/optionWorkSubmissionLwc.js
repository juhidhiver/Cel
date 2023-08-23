import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import createQuoteProcess from '@salesforce/apex/QuoteProcessLWCController.createQuoteProcess';
import getPolicyList from '@salesforce/apex/QuoteProcessLWCController.getPolicyList';
import fetchOpportunity from '@salesforce/apex/QuoteProcessLWCController.fetchOpportunity';
import fletchData from '@salesforce/apex/QuoteProcessLWCController.fletchData';
import getRecordTypeObject from "@salesforce/apex/QuoteProcessLWCController.getRecordTypeObject";


//Constructor show actions
const actions = [
    { label: 'Show details', name: 'show_details' },
];

export default class OptionWorkSubmissionLwc extends NavigationMixin(LightningElement) {
    @track offset = 0;
    @track recordNumber = 5;
    @api quoteProcessId;
    @track valueChecked = 'newSubmission';
    @api pickedValue = 'newSubmission';
    @track openmodel = false;
    @track openmodal = false;
    @track opps = [];
    @track oppsList = [];
    @api isAccount = false;
    @api accountId = '';
    @track isloaddata = true;
    @api objectName = 'Opportunity';
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
            { label: 'New Submission', value: 'newSubmission' },
            { label: 'Existing Submission', value: 'existingSubmission' },
            { label: 'Existing Policy Submission', value: 'existingPolicySubmission' },
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



    //Handle Button Click Next
    handleClickNext() {
        if (this.pickedValue == 'newSubmission') {
         /*   createQuoteProcess().then(result => {
                this.dispatchEvent(new CustomEvent('hidebar'));
                this.quoteProcessId = result;
                this.navigateToRecordViewPage();
        });*/
        
      if(this.recordTypeOptions && this.recordTypeOptions.length > 1) {
        this.recordTypeSelector = true;
      }
      if(this.recordTypeOptions && this.recordTypeOptions.length == 1) {
        this.recordTypeSelector = true;
      }
    }
    else {
        this.handleClickNextWithRecordType();
        }
    }

    handleClickNextWithRecordType() {
       
        if (this.pickedValue == 'existingSubmission') {
            this.openmodel = true;
            this.dispatchEvent(new CustomEvent('openmodal'));

        }
        if (this.pickedValue == 'existingPolicySubmission') {
            this.openmodal = true;
            this.dispatchEvent(new CustomEvent('openmodal'));
        }
    }

    //Handle Picked value
    handlepicked(event) {
        this.pickedValue = event.target.value;;
    }

    //Navigate to Quote Process Page
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
        this.fletchDataOnSF(event.target.value, this.objectName, this.accountId);
    }

    @track value = 'inProgress';

    get optionscombobox() {
        return [
            { label: 'Submission', value: 'subSearch' },
            { label: 'Account', value: 'accountSearch' },
        ];
    }

    onchangeAccount(event) {
        this.accountId = event.target.value;
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
    this.dispatchEvent(new CustomEvent("hidebar"));
  }
  //End

}