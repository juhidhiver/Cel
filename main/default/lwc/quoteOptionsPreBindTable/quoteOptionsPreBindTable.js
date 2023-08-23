import { LightningElement,api,wire,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import fetchQuoteOptions from '@salesforce/apex/QuoteOptionsPreBindTableController.fetchQuoteOptions';
import updateQuoteOptions from '@salesforce/apex/QuoteOptionsPreBindTableController.updateQuoteOptions';
import syncQuoteToMiddleware from '@salesforce/apex/QuoteOptionsPreBindTableController.syncQuoteToMiddleware';

const quoteConsoleTableColumns = [
    { label: 'Limit', fieldName: 'Limit__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' },currencyDisplayAs:'symbol'}, cellAttributes: { alignment: 'left',class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, hideDefaultActions: true},
    { label: 'MP', fieldName: 'Minimum_Premium_Annual__c', type: 'currency',typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' },currencyDisplayAs:'symbol'}, cellAttributes: { alignment: 'left',class: 'slds-border_left' }, hideDefaultActions: true},
    { label: 'Annual BP', fieldName: 'Book_Premium_Annual__c', type: 'currency',typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' },currencyDisplayAs:'symbol'}, cellAttributes: { alignment: 'left',class: 'slds-border_left' }, hideDefaultActions: true},
    { label: 'Annual TP', fieldName: 'Technical_Premium_Annual__c', type: 'currency',typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' },currencyDisplayAs:'symbol'}, cellAttributes: { alignment: 'left',class: 'slds-border_left' }, hideDefaultActions: true},
    { label: 'Annual AP', fieldName: 'Actual_Premium_Annual__c', type: 'currency',typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' },currencyDisplayAs:'symbol'}, cellAttributes: { alignment: 'left',class: 'slds-border_left' }, hideDefaultActions: true},
    { label: 'Annual BNDP', fieldName: 'Broker_Netted_Down_Premium_Annual__c', type: 'currency',typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' },currencyDisplayAs:'symbol'}, cellAttributes: { alignment: 'left',class: 'slds-border_left' }, hideDefaultActions: true},
    { label: 'Annual Fee', fieldName: 'Fee_Annual__c', type: 'currency',typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' },currencyDisplayAs:'symbol'}, cellAttributes: { alignment: 'left',class: 'slds-border_left' }, hideDefaultActions: true},
    { label: 'TPD%', fieldName: 'Technical_Premium_Discretion__c', type: 'number',typeAttributes: { minimumFractionDigits: '2' }, cellAttributes: { alignment: 'left',class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, hideDefaultActions: true },
    { label: 'FD%', fieldName: 'Final_Discretion__c', type: 'number',typeAttributes: { minimumFractionDigits: '2' }, cellAttributes: { alignment: 'left',class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, hideDefaultActions: true },
    { label: 'PA%', fieldName: 'Price_Adequacy__c', type: 'number',typeAttributes: { minimumFractionDigits: '2' }, cellAttributes: { alignment: 'left',class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, hideDefaultActions: true },
    { label: 'Final AP', fieldName: 'Actual_Premium_Final__c', type: 'currency',typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' },currencyDisplayAs:'symbol'}, cellAttributes: { alignment: 'left',class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Final BNDP', fieldName: 'Broker_Netted_Down_Premium_Final__c', type: 'currency',typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' },currencyDisplayAs:'symbol'}, cellAttributes: { alignment: 'left',class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Final Fee', fieldName: 'Fee_Final__c', type: 'currency',typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' },currencyDisplayAs:'symbol'}, cellAttributes: { alignment: 'left',class: 'slds-border_left' }, hideDefaultActions: true },
];

const primaryData = [{"Limit__c":100000,"Book_Premium__c":1000,"Technical_Premium__c":1000,"Actual_Premium_Annual__c":1000,"Broker_Netted_Down_Premium_Annual__c":1000,"Fee_Annual__c":100,"Technical_Premium_Discretion__c":1,"Final_Discretion__c":1,"Price_Adequacy__c":1,"Actual_Premium_Final__c":1000,"Broker_Netted_Down_Premium_Final__c":1000,"Fee_Final__c":100},
{"Limit__c":200000,"Book_Premium__c":2000,"Technical_Premium__c":2000,"Actual_Premium_Annual__c":1000,"Broker_Netted_Down_Premium_Annual__c":1000,"Fee_Annual__c":100,"Technical_Premium_Discretion__c":1,"Final_Discretion__c":1,"Price_Adequacy__c":1,"Actual_Premium_Final__c":1000,"Broker_Netted_Down_Premium_Final__c":1000,"Fee_Final__c":100},
{"Limit__c":300000,"Book_Premium__c":3000,"Technical_Premium__c":3000,"Actual_Premium_Annual__c":1000,"Broker_Netted_Down_Premium_Annual__c":1000,"Fee_Annual__c":100,"Technical_Premium_Discretion__c":1,"Final_Discretion__c":1,"Price_Adequacy__c":1,"Actual_Premium_Final__c":1000,"Broker_Netted_Down_Premium_Final__c":1000,"Fee_Final__c":100},
{"Limit__c":400000,"Book_Premium__c":4000,"Technical_Premium__c":4000,"Actual_Premium_Annual__c":1000,"Broker_Netted_Down_Premium_Annual__c":1000,"Fee_Annual__c":100,"Technical_Premium_Discretion__c":1,"Final_Discretion__c":1,"Price_Adequacy__c":1,"Actual_Premium_Final__c":1000,"Broker_Netted_Down_Premium_Final__c":1000,"Fee_Final__c":100},
{"Limit__c":500000,"Book_Premium__c":5000,"Technical_Premium__c":5000,"Actual_Premium_Annual__c":1000,"Broker_Netted_Down_Premium_Annual__c":1000,"Fee_Annual__c":100,"Technical_Premium_Discretion__c":1,"Final_Discretion__c":1,"Price_Adequacy__c":1,"Actual_Premium_Final__c":1000,"Broker_Netted_Down_Premium_Final__c":1000,"Fee_Final__c":100},
{"Limit__c":600000,"Book_Premium__c":6000,"Technical_Premium__c":6000,"Actual_Premium_Annual__c":1000,"Broker_Netted_Down_Premium_Annual__c":1000,"Fee_Annual__c":100,"Technical_Premium_Discretion__c":1,"Final_Discretion__c":1,"Price_Adequacy__c":1,"Actual_Premium_Final__c":1000,"Broker_Netted_Down_Premium_Final__c":1000,"Fee_Final__c":100},
{"Limit__c":700000,"Book_Premium__c":7000,"Technical_Premium__c":7000,"Actual_Premium_Annual__c":1000,"Broker_Netted_Down_Premium_Annual__c":1000,"Fee_Annual__c":100,"Technical_Premium_Discretion__c":1,"Final_Discretion__c":1,"Price_Adequacy__c":1,"Actual_Premium_Final__c":1000,"Broker_Netted_Down_Premium_Final__c":1000,"Fee_Final__c":100},
{"Limit__c":800000,"Book_Premium__c":8000,"Technical_Premium__c":8000,"Actual_Premium_Annual__c":1000,"Broker_Netted_Down_Premium_Annual__c":1000,"Fee_Annual__c":100,"Technical_Premium_Discretion__c":1,"Final_Discretion__c":1,"Price_Adequacy__c":1,"Actual_Premium_Final__c":1000,"Broker_Netted_Down_Premium_Final__c":1000,"Fee_Final__c":100},
{"Limit__c":900000,"Book_Premium__c":9000,"Technical_Premium__c":9000,"Actual_Premium_Annual__c":1000,"Broker_Netted_Down_Premium_Annual__c":1000,"Fee_Annual__c":100,"Technical_Premium_Discretion__c":1,"Final_Discretion__c":1,"Price_Adequacy__c":1,"Actual_Premium_Final__c":1000,"Broker_Netted_Down_Premium_Final__c":1000,"Fee_Final__c":100},
{"Limit__c":1000000,"Book_Premium__c":10000,"Technical_Premium__c":10000,"Actual_Premium_Annual__c":1000,"Broker_Netted_Down_Premium_Annual__c":1000,"Fee_Annual__c":100,"Technical_Premium_Discretion__c":1,"Final_Discretion__c":1,"Price_Adequacy__c":1,"Actual_Premium_Final__c":1000,"Broker_Netted_Down_Premium_Final__c":1000,"Fee_Final__c":100}
];

export default class QuoteOptionsTable extends NavigationMixin(LightningElement) {

    @api quoteId;
    @api wiredata;
    @track data;
    buttonLabel = 'Back to Quote';
    @track selectedBoundOption = [];
    showSpinner = false;

/*    data = [{"Limit__c":100000,"Book_Premium__c":1000,"Technical_Premium__c":1000,"Actual_Premium_Annual__c":1000,"Broker_Netted_Down_Premium_Annual__c":1000,"Fee_Annual__c":100,"Technical_Premium_Discretion__c":1,"Final_Discretion__c":1,"Price_Adequacy__c":1,"Actual_Premium_Final__c":1000,"Broker_Netted_Down_Premium_Final__c":1000,"Fee_Final__c":100},
        {"Limit__c":100000,"Book_Premium__c":1000,"Technical_Premium__c":1000,"Actual_Premium_Annual__c":1000,"Broker_Netted_Down_Premium_Annual__c":1000,"Fee_Annual__c":100,"Technical_Premium_Discretion__c":1,"Final_Discretion__c":1,"Price_Adequacy__c":1,"Actual_Premium_Final__c":1000,"Broker_Netted_Down_Premium_Final__c":1000,"Fee_Final__c":100},
        {"Limit__c":100000,"Book_Premium__c":1000,"Technical_Premium__c":1000,"Actual_Premium_Annual__c":1000,"Broker_Netted_Down_Premium_Annual__c":1000,"Fee_Annual__c":100,"Technical_Premium_Discretion__c":1,"Final_Discretion__c":1,"Price_Adequacy__c":1,"Actual_Premium_Final__c":1000,"Broker_Netted_Down_Premium_Final__c":1000,"Fee_Final__c":100},
        {"Limit__c":100000,"Book_Premium__c":1000,"Technical_Premium__c":1000,"Actual_Premium_Annual__c":1000,"Broker_Netted_Down_Premium_Annual__c":1000,"Fee_Annual__c":100,"Technical_Premium_Discretion__c":1,"Final_Discretion__c":1,"Price_Adequacy__c":1,"Actual_Premium_Final__c":1000,"Broker_Netted_Down_Premium_Final__c":1000,"Fee_Final__c":100},
        {"Limit__c":100000,"Book_Premium__c":1000,"Technical_Premium__c":1000,"Actual_Premium_Annual__c":1000,"Broker_Netted_Down_Premium_Annual__c":1000,"Fee_Annual__c":100,"Technical_Premium_Discretion__c":1,"Final_Discretion__c":1,"Price_Adequacy__c":1,"Actual_Premium_Final__c":1000,"Broker_Netted_Down_Premium_Final__c":1000,"Fee_Final__c":100}
    ];  */
    quoteConsoleTableColumns = quoteConsoleTableColumns;

    @wire(fetchQuoteOptions, { quoteId: '$quoteId'
                        }) 
    accountData( result ) {
        this.wiredata = result;
        var data = result.data;
        var error = result.error;
        if ( data ) {
            console.log('$$response=', data);
            this.data = data.lstRecords;
            if(data.idOfBoundQuoteOption){
                var boundQuoteOption = [];
                boundQuoteOption.push(data.idOfBoundQuoteOption);
                this.selectedBoundOption = boundQuoteOption;
                //this.selectedBoundOption = data.idOfBoundQuoteOption;
            }
        /*    var fieldWrapper = data.numberOfRecords;
            var clone = JSON.parse(JSON.stringify(fieldWrapper));
            clone.forEach(item => {
                if(item.optionType === 'Free Form'){
                   this.freeFormOption = item;
                   item.fieldDetails.forEach(item1 => {
                        if(item1.fieldAPIName === 'Limit__c')
                            this.freeFormLimit = item1;
                    });
                }

            });     */

        }

    }

    @api
    handleRefreshOptionTable(){
        refreshApex(this.wiredata);
        console.log('this.wiredata'+this.wiredata);
    }

    handleRowSelection(event){
        //Show 5 sec spinner
        this.showSpinner = true;
        /*setTimeout(() => {
            this.showSpinner = false;
        }, 5000);*/
        
        const syncCallTrackerEvt = new CustomEvent("synccalltracker", { detail: '' });
        this.dispatchEvent(syncCallTrackerEvt);
        //server call to update bound checkbox on selected quote option
        const selectedRows = event.detail.selectedRows;
        console.log('$$$$selectedRows=',selectedRows);
        console.log('$$$$selectedRows[0].Id=',selectedRows[0].Id);
        updateQuoteOptions({ quoteId: this.quoteId, quoteOptionId: selectedRows[0].Id })
            .then((result) => {
                syncQuoteToMiddleware({ quoteId: this.quoteId, quoteOptionId: selectedRows[0].Id })
                .then((result) => {
                    const syncCallTrackerEvt = new CustomEvent("synccalltracker", { detail: result.jobIdOfSyncCall });
                    this.dispatchEvent(syncCallTrackerEvt);
                    console.log('$$imperativeCallResultIDD=', result.jobIdOfSyncCall);
                    console.log('imperative call done successfully');
                    this.handleRefreshOptionTable();
                    this.showSpinner = false;
                })
            })
            .catch((error) => {
                console.log('imperative call done with error');
            });

        //callout to sync the final bound quote option

    }

 /*   handleUpdateOfQuoteOptions() {
        updateQuoteOptions({ quoteId: this.quoteId, quoteOptionId: this.selectedQuoteOptionId })
            .then((result) => {
                console.log('imperative call done successfully');
                this.contacts = result;
                this.error = undefined;
            })
            .catch((error) => {
                console.log('imperative call done with error');
                this.error = error;
                this.contacts = undefined;
            });
    }

    @wire(updateQuoteOptions, {
                                quoteId: '$quoteId',
                                quoteOptionId: '$selectedQuoteOptionId'
                            }) 
    quoteOptions( result ) {
        var data = result.data;
        var error = result.error;
        console.log('inside wire methodd');
        if ( data ) {
            alert('$$quoteOptionsUpdateResponse=', data);
        }
    }   */

}