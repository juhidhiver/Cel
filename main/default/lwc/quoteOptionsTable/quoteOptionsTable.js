import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import fetchQuoteOptions from '@salesforce/apex/QuoteOptionsTableController.fetchQuoteOptions';
import fetchQuoteOptionsNonCacheable from '@salesforce/apex/QuoteOptionsTableController.fetchQuoteOptionsNonCacheable';
import deleteQuoteOptions from '@salesforce/apex/QuoteOptionsTableController.deleteQuoteOptions';
//import fetchTaxPercent from '@salesforce/apex/QuoteOptionsTableController.fetchTaxPercent';
import saveQuoteOptions from '@salesforce/apex/QuoteOptionsTableController.saveQuoteOptions';
import getFactorSummarysQC from '@salesforce/apex/FactorSummaryController.getFactorSummarysQC';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
//import checkQuoteOptionSize from '@salesforce/apex/QuoteOptionsTableController.checkQuoteOptionSize';

import saveQuoteStatus from '@salesforce/apex/QuoteOptionsTableController.saveQuoteStatus';


const actions = [
    { label: 'Data Summary', name: 'data_summary' },
];




const quoteConsoleTableColumnsEdit = [
    { label: 'Limit', fieldName: 'Limit__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, hideDefaultActions: true },
    { label: 'MP', fieldName: 'Minimum_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol', maximumFractionDigits: '0' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual BP', fieldName: 'Book_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual TP', fieldName: 'Technical_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual AP', fieldName: 'Actual_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual BNDP', fieldName: 'Broker_Netted_Down_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual Fee', fieldName: 'Fee_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'TPD%', fieldName: 'Technical_Premium_Discretion__c', type: 'number', typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, hideDefaultActions: true },
    { label: 'FD%', fieldName: 'Final_Discretion__c', type: 'number', typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, hideDefaultActions: true },
    { label: 'PA%', fieldName: 'Price_Adequacy__c', type: 'number', typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, hideDefaultActions: true },
    { label: 'Final AP', fieldName: 'NonProrated_Actual_Premium__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, editable: true, hideDefaultActions: true },
    { label: 'Final BNDP', fieldName: 'NonProRated_BNDP__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, editable: true, hideDefaultActions: true },
    { label: 'Final Fee', fieldName: 'Fee_Final__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, editable: true, hideDefaultActions: true },
    { type: 'action', typeAttributes: { rowActions: actions }, hideDefaultActions: true },
];

const quoteConsoleTableColumnsEditForRenewal = [
    { label: 'Limit', fieldName: 'Limit__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassLimit' } }, hideDefaultActions: true },
    { label: 'MP', fieldName: 'Minimum_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol', maximumFractionDigits: '0' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassAP' } }, hideDefaultActions: true },
    { label: 'Annual BP', fieldName: 'Book_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassAP' } }, hideDefaultActions: true },
    { label: 'Annual TP', fieldName: 'Technical_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassAP' } }, hideDefaultActions: true },
    { label: 'Annual AP', fieldName: 'Actual_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassAP' } }, hideDefaultActions: true },
    { label: 'Annual BNDP', fieldName: 'Broker_Netted_Down_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassAP' } }, hideDefaultActions: true },
    { label: 'Annual Fee', fieldName: 'Fee_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassAP' } }, hideDefaultActions: true },
    { label: 'TPD%', fieldName: 'Technical_Premium_Discretion__c', type: 'number', typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassDisc' } }, hideDefaultActions: true },
    { label: 'FD%', fieldName: 'Final_Discretion__c', type: 'number', typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassDisc' } }, hideDefaultActions: true },
    { label: 'PA%', fieldName: 'Price_Adequacy__c', type: 'number', typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassDisc' } }, hideDefaultActions: true },
    { label: 'Final AP', fieldName: 'NonProrated_Actual_Premium__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassFP' } }, editable: true, hideDefaultActions: true },
    { label: 'Final BNDP', fieldName: 'NonProRated_BNDP__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassFP' } }, editable: true, hideDefaultActions: true },
    { label: 'Final Fee', fieldName: 'Fee_Final__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassFP' } }, editable: true, hideDefaultActions: true },
    { type: 'action', typeAttributes: { rowActions: actions }, hideDefaultActions: true },
];

const quoteConsoleTableColumnsReadOnly = [
    { label: 'Limit', fieldName: 'Limit__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, hideDefaultActions: true },
    { label: 'MP', fieldName: 'Minimum_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol', maximumFractionDigits: '0' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual BP', fieldName: 'Book_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual TP', fieldName: 'Technical_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual AP', fieldName: 'Actual_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual BNDP', fieldName: 'Broker_Netted_Down_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual Fee', fieldName: 'Fee_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'TPD%', fieldName: 'Technical_Premium_Discretion__c', type: 'number', typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, hideDefaultActions: true },
    { label: 'FD%', fieldName: 'Final_Discretion__c', type: 'number', typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, hideDefaultActions: true },
    { label: 'PA%', fieldName: 'Price_Adequacy__c', type: 'number', typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, hideDefaultActions: true },
    { label: 'Final AP', fieldName: 'NonProrated_Actual_Premium__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, editable: false, hideDefaultActions: true },
    { label: 'Final BNDP', fieldName: 'NonProRated_BNDP__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, editable: false, hideDefaultActions: true },
    { label: 'Final Fee', fieldName: 'Fee_Final__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, editable: false, hideDefaultActions: true },
    { type: 'action', typeAttributes: { rowActions: actions }, hideDefaultActions: true },
];

const quoteConsoleTableColumnsReadOnlyForRenewal = [
    { label: 'Limit', fieldName: 'Limit__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassLimit' } }, hideDefaultActions: true },
    { label: 'MP', fieldName: 'Minimum_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassAP' } }, hideDefaultActions: true },
    { label: 'Annual BP', fieldName: 'Book_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassAP' } }, hideDefaultActions: true },
    { label: 'Annual TP', fieldName: 'Technical_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassAP' } }, hideDefaultActions: true },
    { label: 'Annual AP', fieldName: 'Actual_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassAP' } }, hideDefaultActions: true },
    { label: 'Annual BNDP', fieldName: 'Broker_Netted_Down_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassAP' } }, hideDefaultActions: true },
    { label: 'Annual Fee', fieldName: 'Fee_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassAP' } }, hideDefaultActions: true },
    { label: 'TPD%', fieldName: 'Technical_Premium_Discretion__c', type: 'number', typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassDisc' } }, hideDefaultActions: true },
    { label: 'FD%', fieldName: 'Final_Discretion__c', type: 'number', typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassDisc' } }, hideDefaultActions: true },
    { label: 'PA%', fieldName: 'Price_Adequacy__c', type: 'number', typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassDisc' } }, hideDefaultActions: true },
    { label: 'Final AP', fieldName: 'NonProrated_Actual_Premium__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassFP' } }, editable: false, hideDefaultActions: true },
    { label: 'Final BNDP', fieldName: 'NonProRated_BNDP__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassFP' } }, editable: false, hideDefaultActions: true },
    { label: 'Final Fee', fieldName: 'Fee_Final__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: { fieldName: 'cssClassFP' } }, editable: false, hideDefaultActions: true },
    { type: 'action', typeAttributes: { rowActions: actions }, hideDefaultActions: true },
];

const quoteConsoleTableColumnsReadOnlyForAmendment = [
    { label: 'Limit', fieldName: 'Limit__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, editable: false, hideDefaultActions: true },
    { label: 'MP', fieldName: 'Minimum_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual BP', fieldName: 'Book_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual TP', fieldName: 'Technical_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual AP', fieldName: 'Actual_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual BNDP', fieldName: 'Broker_Netted_Down_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual Fee', fieldName: 'Fee_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'TPD%', fieldName: 'Technical_Premium_Discretion__c', type: 'number', typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, hideDefaultActions: true },
    { label: 'FD%', fieldName: 'Final_Discretion__c', type: 'number', typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, hideDefaultActions: true },
    { label: 'PA%', fieldName: 'Price_Adequacy__c', type: 'number', typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, hideDefaultActions: true },
    { label: 'Final AP', fieldName: 'NonProrated_Actual_Premium__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, editable: false, hideDefaultActions: true },
    { label: 'Final BNDP', fieldName: 'NonProRated_BNDP__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, editable: false, hideDefaultActions: true },
    { label: 'Final Fee', fieldName: 'Fee_Final__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, editable: false, hideDefaultActions: true },
    { label: 'Actual AP/RP', fieldName: 'Change_In_Actual_Premium__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, editable: false, hideDefaultActions: true },
    { label: 'BNDP AP/RP', fieldName: 'Change_In_Broker_Netted_Down_Premium__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, editable: false, hideDefaultActions: true },
    { label: 'Fee AP/RP', fieldName: 'Change_In_Fee__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, editable: false, hideDefaultActions: true },
    { type: 'action', typeAttributes: { rowActions: actions }, hideDefaultActions: true },
];

const quoteConsoleTableColumnsEditForMidTermCancellation = [
    { label: 'Limit', fieldName: 'Limit__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, editable: false, hideDefaultActions: true },
    { label: 'MP', fieldName: 'Minimum_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol', maximumFractionDigits: '0' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual BP', fieldName: 'Book_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual TP', fieldName: 'Technical_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual AP', fieldName: 'Actual_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual BNDP', fieldName: 'Broker_Netted_Down_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual Fee', fieldName: 'Fee_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'TPD%', fieldName: 'Technical_Premium_Discretion__c', type: 'number', typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, hideDefaultActions: true },
    { label: 'FD%', fieldName: 'Final_Discretion__c', type: 'number', typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, hideDefaultActions: true },
    { label: 'PA%', fieldName: 'Price_Adequacy__c', type: 'number', typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, hideDefaultActions: true },
    { label: 'Final AP', fieldName: 'NonProrated_Actual_Premium__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, editable: false, hideDefaultActions: true },
    { label: 'Final BNDP', fieldName: 'NonProRated_BNDP__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, editable: false, hideDefaultActions: true },
    { label: 'Final Fee', fieldName: 'Fee_Final__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, editable: false, hideDefaultActions: true },
    { label: 'Actual AP/RP', fieldName: 'Change_In_Actual_Premium__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, editable: true, hideDefaultActions: true },
    { label: 'BNDP AP/RP', fieldName: 'Change_In_Broker_Netted_Down_Premium__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, editable: true, hideDefaultActions: true },
    { label: 'Fee AP/RP', fieldName: 'Change_In_Fee__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, editable: true, hideDefaultActions: true },
    { type: 'action', typeAttributes: { rowActions: actions }, hideDefaultActions: true },
];

const quoteConsoleTableColumnsForAmendment = [
    { label: 'Limit', fieldName: 'Limit__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, editable: true, hideDefaultActions: true },
    { label: 'MP', fieldName: 'Minimum_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual BP', fieldName: 'Book_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual TP', fieldName: 'Technical_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual AP', fieldName: 'Actual_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual BNDP', fieldName: 'Broker_Netted_Down_Premium_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'Annual Fee', fieldName: 'Fee_Annual__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, hideDefaultActions: true },
    { label: 'TPD%', fieldName: 'Technical_Premium_Discretion__c', type: 'number', typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, hideDefaultActions: true },
    { label: 'FD%', fieldName: 'Final_Discretion__c', type: 'number', typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, hideDefaultActions: true },
    { label: 'PA%', fieldName: 'Price_Adequacy__c', type: 'number', typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, hideDefaultActions: true },
    { label: 'Final AP', fieldName: 'NonProrated_Actual_Premium__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, editable: false, hideDefaultActions: true },
    { label: 'Final BNDP', fieldName: 'NonProRated_BNDP__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, editable: false, hideDefaultActions: true },
    { label: 'Final Fee', fieldName: 'Fee_Final__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-border_left' }, editable: false, hideDefaultActions: true },
    { label: 'Actual AP/RP', fieldName: 'Change_In_Actual_Premium__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, editable: true, hideDefaultActions: true },
    { label: 'BNDP AP/RP', fieldName: 'Change_In_Broker_Netted_Down_Premium__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, editable: true, hideDefaultActions: true },
    { label: 'Fee AP/RP', fieldName: 'Change_In_Fee__c', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left', class: 'slds-theme_shade slds-theme_alert-texture slds-border_left' }, editable: true, hideDefaultActions: true },
    { type: 'action', typeAttributes: { rowActions: actions }, hideDefaultActions: true },
];

const primaryData = [{ "Limit__c": 100000, "Book_Premium__c": 1000, "Technical_Premium__c": 1000, "Actual_Premium_Annual__c": 1000, "Broker_Netted_Down_Premium_Annual__c": 1000, "Fee_Annual__c": 100, "Technical_Premium_Discretion__c": 1, "Final_Discretion__c": 1, "Price_Adequacy__c": 1, "Actual_Premium_Final__c": 1000, "Broker_Netted_Down_Premium_Final__c": 1000, "Fee_Final__c": 100 },
    { "Limit__c": 200000, "Book_Premium__c": 2000, "Technical_Premium__c": 2000, "Actual_Premium_Annual__c": 1000, "Broker_Netted_Down_Premium_Annual__c": 1000, "Fee_Annual__c": 100, "Technical_Premium_Discretion__c": 1, "Final_Discretion__c": 1, "Price_Adequacy__c": 1, "Actual_Premium_Final__c": 1000, "Broker_Netted_Down_Premium_Final__c": 1000, "Fee_Final__c": 100 },
    { "Limit__c": 300000, "Book_Premium__c": 3000, "Technical_Premium__c": 3000, "Actual_Premium_Annual__c": 1000, "Broker_Netted_Down_Premium_Annual__c": 1000, "Fee_Annual__c": 100, "Technical_Premium_Discretion__c": 1, "Final_Discretion__c": 1, "Price_Adequacy__c": 1, "Actual_Premium_Final__c": 1000, "Broker_Netted_Down_Premium_Final__c": 1000, "Fee_Final__c": 100 },
    { "Limit__c": 400000, "Book_Premium__c": 4000, "Technical_Premium__c": 4000, "Actual_Premium_Annual__c": 1000, "Broker_Netted_Down_Premium_Annual__c": 1000, "Fee_Annual__c": 100, "Technical_Premium_Discretion__c": 1, "Final_Discretion__c": 1, "Price_Adequacy__c": 1, "Actual_Premium_Final__c": 1000, "Broker_Netted_Down_Premium_Final__c": 1000, "Fee_Final__c": 100 },
    { "Limit__c": 500000, "Book_Premium__c": 5000, "Technical_Premium__c": 5000, "Actual_Premium_Annual__c": 1000, "Broker_Netted_Down_Premium_Annual__c": 1000, "Fee_Annual__c": 100, "Technical_Premium_Discretion__c": 1, "Final_Discretion__c": 1, "Price_Adequacy__c": 1, "Actual_Premium_Final__c": 1000, "Broker_Netted_Down_Premium_Final__c": 1000, "Fee_Final__c": 100 },
    { "Limit__c": 600000, "Book_Premium__c": 6000, "Technical_Premium__c": 6000, "Actual_Premium_Annual__c": 1000, "Broker_Netted_Down_Premium_Annual__c": 1000, "Fee_Annual__c": 100, "Technical_Premium_Discretion__c": 1, "Final_Discretion__c": 1, "Price_Adequacy__c": 1, "Actual_Premium_Final__c": 1000, "Broker_Netted_Down_Premium_Final__c": 1000, "Fee_Final__c": 100 },
    { "Limit__c": 700000, "Book_Premium__c": 7000, "Technical_Premium__c": 7000, "Actual_Premium_Annual__c": 1000, "Broker_Netted_Down_Premium_Annual__c": 1000, "Fee_Annual__c": 100, "Technical_Premium_Discretion__c": 1, "Final_Discretion__c": 1, "Price_Adequacy__c": 1, "Actual_Premium_Final__c": 1000, "Broker_Netted_Down_Premium_Final__c": 1000, "Fee_Final__c": 100 },
    { "Limit__c": 800000, "Book_Premium__c": 8000, "Technical_Premium__c": 8000, "Actual_Premium_Annual__c": 1000, "Broker_Netted_Down_Premium_Annual__c": 1000, "Fee_Annual__c": 100, "Technical_Premium_Discretion__c": 1, "Final_Discretion__c": 1, "Price_Adequacy__c": 1, "Actual_Premium_Final__c": 1000, "Broker_Netted_Down_Premium_Final__c": 1000, "Fee_Final__c": 100 },
    { "Limit__c": 900000, "Book_Premium__c": 9000, "Technical_Premium__c": 9000, "Actual_Premium_Annual__c": 1000, "Broker_Netted_Down_Premium_Annual__c": 1000, "Fee_Annual__c": 100, "Technical_Premium_Discretion__c": 1, "Final_Discretion__c": 1, "Price_Adequacy__c": 1, "Actual_Premium_Final__c": 1000, "Broker_Netted_Down_Premium_Final__c": 1000, "Fee_Final__c": 100 },
    { "Limit__c": 1000000, "Book_Premium__c": 10000, "Technical_Premium__c": 10000, "Actual_Premium_Annual__c": 1000, "Broker_Netted_Down_Premium_Annual__c": 1000, "Fee_Annual__c": 100, "Technical_Premium_Discretion__c": 1, "Final_Discretion__c": 1, "Price_Adequacy__c": 1, "Actual_Premium_Final__c": 1000, "Broker_Netted_Down_Premium_Final__c": 1000, "Fee_Final__c": 100 }
];

export default class QuoteOptionsTable extends NavigationMixin(LightningElement) {

    @api quoteId;
    @track wiredata;
    @api showFreeForm = false;
    @api freeFormOption;
    @api freeFormLimit;
    @track draftOptions = [];
    @api selectedOptions = [];
    @api taxPercent;
    @api increasedLimitFactor;
    @api annualGrossFee;
    @api termLength;
    @api effectiveTermLength;
    @api mgaCommissionPercent;
    @api quoteStatus;
    @api quoteType;
    @api priorAP;
    @api priorBNDP;
    @api priorFee;
    @api priorRate;
    @api priorNonProRatedAP;
    @api priorNonProRatedBNDP;
    quoteLayer;
    @api isEditable = false;
    maxPossibleRowSelection = "11";
    boundQuoteOptionId;
    @track customCssRecordsForRenewal = [];
    isAmendmentOrCancellation = false;
    showFreeFormButton = true;
    @track isOptionfieldUpdated = false;
    @api isReferredQuoteLocked;
    @api isAqueousProduct;

    @track columns = [
        { label: 'Name', fieldName: 'name', type: 'text', editable: false, wrapText: true },
        { label: 'Current Value', fieldName: 'currentValue', type: 'text', editable: false, wrapText: true },
        { label: 'Prior Value', fieldName: 'priorValue', type: 'text', editable: false, wrapText: true }
    ];

    @track isFactorSummary;
    @track summaryData;
    @track tableLoading = true;
    @track isLoading = false;

    @track noRowSelected = false;

    quoteConsoleTableColumns = [];

    /*data = [{"Limit__c":100000,"Book_Premium__c":1000,"Technical_Premium__c":1000,"Actual_Premium_Annual__c":1000,"Broker_Netted_Down_Premium_Annual__c":1000,"Fee_Annual__c":100,"Technical_Premium_Discretion__c":1,"Final_Discretion__c":1,"Price_Adequacy__c":1,"Actual_Premium_Final__c":1000,"Broker_Netted_Down_Premium_Final__c":1000,"Fee_Final__c":100},
        {"Limit__c":100000,"Book_Premium__c":1000,"Technical_Premium__c":1000,"Actual_Premium_Annual__c":1000,"Broker_Netted_Down_Premium_Annual__c":1000,"Fee_Annual__c":100,"Technical_Premium_Discretion__c":1,"Final_Discretion__c":1,"Price_Adequacy__c":1,"Actual_Premium_Final__c":1000,"Broker_Netted_Down_Premium_Final__c":1000,"Fee_Final__c":100},
        {"Limit__c":100000,"Book_Premium__c":1000,"Technical_Premium__c":1000,"Actual_Premium_Annual__c":1000,"Broker_Netted_Down_Premium_Annual__c":1000,"Fee_Annual__c":100,"Technical_Premium_Discretion__c":1,"Final_Discretion__c":1,"Price_Adequacy__c":1,"Actual_Premium_Final__c":1000,"Broker_Netted_Down_Premium_Final__c":1000,"Fee_Final__c":100},
        {"Limit__c":100000,"Book_Premium__c":1000,"Technical_Premium__c":1000,"Actual_Premium_Annual__c":1000,"Broker_Netted_Down_Premium_Annual__c":1000,"Fee_Annual__c":100,"Technical_Premium_Discretion__c":1,"Final_Discretion__c":1,"Price_Adequacy__c":1,"Actual_Premium_Final__c":1000,"Broker_Netted_Down_Premium_Final__c":1000,"Fee_Final__c":100},
        {"Limit__c":100000,"Book_Premium__c":1000,"Technical_Premium__c":1000,"Actual_Premium_Annual__c":1000,"Broker_Netted_Down_Premium_Annual__c":1000,"Fee_Annual__c":100,"Technical_Premium_Discretion__c":1,"Final_Discretion__c":1,"Price_Adequacy__c":1,"Actual_Premium_Final__c":1000,"Broker_Netted_Down_Premium_Final__c":1000,"Fee_Final__c":100}
    ];*/
    data = [];
    //quoteConsoleTableColumns = quoteConsoleTableColumns;

    @wire(fetchQuoteOptions, {
        quoteId: '$quoteId'
    })
    accountData(result) {
        this.wiredata = result;

        /***  51668 changes*/
        if(this.noRowSelected){
             if(result.data){
                 for(var i=0;i<result.data.lstRecords.length;i++){
                        console.log('result.data'+JSON.stringify(result.data.lstRecords[i]));
                        result.data.lstRecords[i].Selected__c = false;                 
                    }
             }
        }
        this.noRowSelected = false;

        var data = result.data;
        var error = result.error;
        if (data) {
            this.handleData(data);
        }
    }

    handleData(data){
        this.isEditable = true;
        console.log('$$response=', data);
        var lstRecords = data.lstRecords;
        console.log('$$$$selectedOptions1', this.selectedOptions);
        this.selectedOptions = data.lstSelectedRecordIds;
        console.log('$$$$selectedOptions2', this.selectedOptions);
        this.boundQuoteOptionId = data.idOfBoundQuoteOption;
        this.taxPercent = data.taxPercent;
        this.increasedLimitFactor = data.increasedLimitFactor;
        this.annualGrossFee = data.annualGrossFee;
        this.termLength = data.termLength;
        this.effectiveTermLength = data.effectiveTermLength;
        this.mgaCommissionPercent = data.mgaCommissionPercent;
        this.quoteStatus = data.quoteStatus;
        this.quoteType = data.quoteType;
        this.quoteLayer = data.quoteLayer;
        this.priorAP = data.priorAP;
        this.priorBNDP = data.priorBNDP;
        this.priorFee = data.priorFee;
        this.priorRate = data.priorRate;
        this.priorNonProRatedAP = data.priorNonProRatedAP;
        this.priorNonProRatedBNDP = data.priorNonProRatedBNDP;
        this.quoteConsoleTableColumns = quoteConsoleTableColumnsEdit;
        var fieldWrapper = data.numberOfRecords;
        var clone = JSON.parse(JSON.stringify(fieldWrapper));
        clone.forEach(item => {
            if (item.optionType === 'Free Form') {
                //this.freeFormOption = item;
                item.fieldDetails.forEach(item1 => {
                    if (item1.fieldAPIName === 'Limit__c') {
                        this.freeFormLimit = item1;
                    }
                });
            }
        });
        var temp = [];
        lstRecords.forEach(item => {
            console.log(item.Limit__c);
            if (item.Option_Type__c === 'Free Form') {
                this.freeFormOption = item;
                if (item.Limit__c !== undefined) {
                    if (this.quoteType && (this.quoteType === 'Midterm Cancellation'
                        || this.quoteType === 'Flat Cancellation' || this.quoteType === 'Full Amendment'
                        || this.quoteType === 'Coverage Amendment' || this.quoteType === 'Policy Duration Change')) {
                        if (item.Bound__c) {
                            temp.push(item);
                        }
                    }
                    else {
                        temp.push(item);
                    }
                }
            }
            else {
                if (this.quoteType && (this.quoteType === 'Midterm Cancellation'
                    || this.quoteType === 'Flat Cancellation' || this.quoteType === 'Full Amendment'
                    || this.quoteType === 'Coverage Amendment' || this.quoteType === 'Policy Duration Change')) {
                    if (item.Bound__c) {
                        temp.push(item);
                    }
                }
                else {
                    temp.push(item);
                }
            }
        });
        console.log('$$$$temp=', temp);
        this.data = temp;
        this.maxPossibleRowSelection = "11";
        if (this.quoteStatus && this.quoteType) {
            this.isAmendmentOrCancellation = false;
            if (this.quoteType === 'Midterm Cancellation' || this.quoteType === 'Flat Cancellation' || this.quoteType === 'Reinstatement' || this.quoteType === 'Policy Duration Change') {
                this.isAmendmentOrCancellation = true;
                this.maxPossibleRowSelection = "1";
                var boundQuoteOption = [];
                boundQuoteOption.push(this.boundQuoteOptionId);
                this.selectedOptions = boundQuoteOption;
                console.log('$$$$selectedOptions3', this.selectedOptions);
                if((this.quoteType === 'Midterm Cancellation' || this.quoteType === 'Policy Duration Change') && this.quoteStatus !== 'Bound' && this.quoteStatus !== 'Closed' && this.quoteStatus !== 'Rejected' && this.quoteStatus !== 'Correction' && this.quoteStatus !== 'Cancelled' && (this.quoteStatus !== 'Referred' || (this.quoteStatus === 'Referred' && !this.isReferredQuoteLocked))){
                    this.quoteConsoleTableColumns = quoteConsoleTableColumnsEditForMidTermCancellation;
                }
                else{
                    this.quoteConsoleTableColumns = quoteConsoleTableColumnsReadOnlyForAmendment;
                }
            }
            else if (this.quoteType === 'Full Amendment' || this.quoteType === 'Coverage Amendment') {
                this.isAmendmentOrCancellation = true;
                this.maxPossibleRowSelection = "1";
                var boundQuoteOption = [];
                boundQuoteOption.push(this.boundQuoteOptionId);
                console.log('$$$$tempboundQuoteOption', boundQuoteOption);
                this.selectedOptions = boundQuoteOption;
                console.log('$$$$selectedOptions4', this.selectedOptions);
                if (this.quoteStatus === 'Bound' || this.quoteStatus === 'Closed' || this.quoteStatus === 'Rejected' || this.quoteStatus === 'Correction' || this.quoteStatus === 'Cancelled' || (this.quoteStatus === 'Referred' && this.isReferredQuoteLocked)) {
                    this.quoteConsoleTableColumns = quoteConsoleTableColumnsReadOnlyForAmendment;
                }
                else {
                    this.quoteConsoleTableColumns = quoteConsoleTableColumnsForAmendment;
                }
            }
            else if (this.quoteType === 'Renewal' || this.quoteType === 'New Business') {
                var lstRecords = this.data;
                this.customCssRecordsForRenewal = [];
                lstRecords.forEach(item => {
                    let tmpItem = Object.assign({}, item);
                    /*if(item.Bound__c){
                        tmpItem.cssClass = 'slds-theme_shade slds-theme_alert-texture slds-border_left slds-text-color_success slds-text-title_bold';
                        console.log('$$$$temp4=',tmpItem);
                    }
                    else{
                        tmpItem.cssClass = 'slds-theme_shade slds-theme_alert-texture slds-border_left';
                    }*/
                    tmpItem.cssClassLimit = 'slds-theme_shade slds-theme_alert-texture slds-border_left';
                    tmpItem.cssClassAP = 'slds-border_left';
                    tmpItem.cssClassDisc = 'slds-theme_shade slds-theme_alert-texture slds-border_left';
                    tmpItem.cssClassFP = 'slds-border_left';
                    if (item.Bound__c) {
                        tmpItem.cssClassLimit += ' slds-text-color_success slds-text-title_bold';
                        tmpItem.cssClassAP += ' slds-text-color_success slds-text-title_bold';
                        tmpItem.cssClassDisc += ' slds-text-color_success slds-text-title_bold';
                        tmpItem.cssClassFP += ' slds-text-color_success slds-text-title_bold';
                    }
                    this.customCssRecordsForRenewal.push(tmpItem);
                });
                console.log('$$$$temp5=', this.customCssRecordsForRenewal);
                this.data = this.customCssRecordsForRenewal;

                if (this.quoteStatus === 'Bound' || this.quoteStatus === 'Closed' || this.quoteStatus === 'Rejected' || this.quoteStatus === 'Correction' || this.quoteStatus === 'Cancelled' || (this.quoteStatus === 'Referred' && this.isReferredQuoteLocked)) {
                    this.quoteConsoleTableColumns = quoteConsoleTableColumnsReadOnlyForRenewal;
                    this.isAmendmentOrCancellation = true;
                }
                else {
                    this.quoteConsoleTableColumns = quoteConsoleTableColumnsEditForRenewal;
                }
            }
            else {
                if (this.quoteStatus === 'Bound' || this.quoteStatus === 'Closed' || this.quoteStatus === 'Rejected' || this.quoteStatus === 'Correction' || this.quoteStatus === 'Cancelled') {
                    this.isEditable = false;
                    this.quoteConsoleTableColumns = quoteConsoleTableColumnsReadOnly;
                    this.isAmendmentOrCancellation = true;
                }
            }
            if (this.quoteStatus === 'Referred' && this.isReferredQuoteLocked) {
                this.isEditable = false;
                //this.quoteConsoleTableColumns = quoteConsoleTableColumnsReadOnly;
                this.isAmendmentOrCancellation = true;
            }
        }

        //Show-Hide Free Form button
        var showButtons = true;
        if (this.quoteType === 'Midterm Cancellation' || this.quoteType === 'Flat Cancellation'
            || this.quoteType === 'Full Amendment' || this.quoteType === 'Coverage Amendment' || this.quoteType === 'Policy Duration Change'
            || this.quoteStatus === 'Bound' || this.quoteStatus === 'Closed'
            || this.quoteStatus === 'Rejected' || (this.quoteStatus === 'Referred' && this.isReferredQuoteLocked)
            || this.quoteStatus === 'Correction' || this.quoteStatus === 'Cancelled') {
            showButtons = false;
        }
        this.showFreeFormButton = showButtons;
    }

    renderedCallback() {
        //this.styleFixedHeader();
        this.styleMovePopUp();
    }

    styleFixedHeader() {
        var responseItem = this.template.querySelector(`[data-id="response-item"]`);
        var responseItemParent = this.template.querySelector(`[data-id="response-item-parent"]`);
        var responseItemChild = this.template.querySelectorAll(`[data-id="response-item-child"]`);
        //console.log("this.parentCmpBoundRect-->", JSON.stringify(this.parentCmpBoundRect));
        if (!responseItem || !responseItemParent || !responseItemChild || !this.parentCmpBoundRect) return;

        var sticky = responseItem.getBoundingClientRect();

        const parentCmpBoundRect = this.parentCmpBoundRect;

        window.addEventListener('scroll', function(event) {
            //console.log(" window.addEventListene -- ", parentCmpBoundRect);

            var parentWidth = responseItemParent.getBoundingClientRect().width;
            if (window.pageYOffset + sticky.height >= parentCmpBoundRect.y && window.pageYOffset <= parentCmpBoundRect.height) {
                responseItem.classList.add("position-sticky");
                //console.log(" window.addEventListene Sticky IF-- ", parentCmpBoundRect);
                responseItemChild.forEach(child => {
                    child.setAttribute('style', `width: ${parentWidth}px !important`);
                });
            } else {
                //console.log(" window.addEventListene Sticky ELSE-- ", parentCmpBoundRect);
                responseItem.classList.remove("position-sticky");
                responseItemChild.forEach(child => child.removeAttribute('style'));
            }

        });
    }

    styleMovePopUp() {
        let mapWidth = this.template.querySelector('[data-id="drag"]');
        let dragHeader = this.template.querySelector('[data-id="dragHeader"]');
        let offset = [0, 0];
        let isDown = false;
        if (mapWidth && dragHeader) {
            mapWidth.addEventListener('mousedown', e => {
                isDown = true;
                offset = [
                    mapWidth.offsetLeft - e.clientX,
                    mapWidth.offsetTop - e.clientY
                ];
            }, true);
            document.addEventListener('mouseup', e => {
                isDown = false;
            }, true);
            document.addEventListener('mousemove', e => {
                e.preventDefault();
                if (isDown) {
                    mapWidth.style.left = (e.clientX + offset[0]) + 'px';
                    mapWidth.style.top = (e.clientY + offset[1]) + 'px';
                }
            }, true);
        }
    }

    connectedCallback() {
        if (this.quoteId) {
            fetchQuoteOptionsNonCacheable({ quoteId: this.quoteId })
                .then((result) => {
                    console.log('@@@data1: ' + JSON.stringify(result));
                    this.handleData(result);
                })
                .catch((error) => {
                    console.log('@@@error1: ' + JSON.stringify(error));
                })
        }

        if (this.data) {
            //this.calcuatePremiumFields();
        }

    }

    /*calcuatePremiumFields() {

        var temp = JSON.parse(JSON.stringify(this.data));
        temp.forEach(editedData => {
            var finaltechPremium = '';
            var finalAP;
            var finalBNDP;
            var finalFee;
            var overrideAP;
            var overrideBNDP;
            var overrideFee;
            var annualAP;
            var annualBNDP;
            var annualFee;
            var bookPremium;
            var annualTechPremium;
            var percentTPD;
            var percentfinalD
            var percentPriceAdequacy;
            var techfee;
            var termLength = this.termLength;
            var taxPercent = this.taxPercent;
            var iPT;
            var totalCosttoClient;

            finaltechPremium = editedData.Final_Technical_Premium__c;
            finalAP = editedData.Actual_Premium_Final__c;
            finalBNDP = editedData.Broker_Netted_Down_Premium_Final__c;
            finalFee = editedData.Fee_Final__c;
            overrideAP = editedData.Override_Actual_Premium_Percent__c;
            overrideBNDP = editedData.OverrideBrokerNettedDownPremiumPercent__c;
            overrideFee = editedData.Override_Fee_Percent__c;
            annualAP = editedData.Actual_Premium_Annual__c;
            annualBNDP = editedData.Broker_Netted_Down_Premium_Annual__c;
            annualFee = editedData.Fee_Annual__c;
            bookPremium = editedData.Book_Premium__c;
            annualTechPremium = editedData.Technical_Premium__c;
            percentTPD = editedData.Technical_Premium_Discretion__c;
            percentfinalD = editedData.Final_Discretion__c;
            percentPriceAdequacy = editedData.Price_Adequacy__c;
            techfee = editedData.Technical_Fee__c;

            var tenPercentfinalAP = finalAP * 0.1;
            finalBNDP = finalAP;
            finalFee = tenPercentfinalAP > 500 ? 500 : (tenPercentfinalAP < 50 ? 50 : tenPercentfinalAP);
            //Calculate Override Premium % and annual Premiums
            if (finaltechPremium !== '') {
                overrideAP = finalAP / finaltechPremium * 100;
                editedData.Override_Actual_Premium_Percent__c = overrideAP;
            }
            overrideBNDP = finalBNDP / finalAP * 100;
            annualBNDP = termLength ? finalBNDP * (365 / termLength) : finalBNDP;
            overrideFee = finalFee / techfee * 100;
            annualFee = termLength ? finalFee * (365 / termLength) : finalFee;

            //calculate discretion percents
            percentTPD = annualTechPremium / bookPremium * 100;
            percentfinalD = finalAP / bookPremium * 100;
            percentPriceAdequacy = finalAP / annualTechPremium * 100;
            if (taxPercent) {
                iPT = (100 + taxPercent) * finalBNDP;
                totalCosttoClient = finalBNDP + iPT + finalFee;
            }

            //editedData.Actual_Premium_Final__c = finalAP;
            //editedData.Broker_Netted_Down_Premium_Final__c = finalBNDP;
            //editedData.Fee_Final__c = finalFee;
            //editedData.Override_Actual_Premium_Percent__c = overrideAP;
            editedData.OverrideBrokerNettedDownPremiumPercent__c = overrideBNDP;
            editedData.Override_Fee_Percent__c = overrideFee;
            editedData.Actual_Premium_Annual__c = annualAP;
            editedData.Broker_Netted_Down_Premium_Annual__c = annualBNDP;
            editedData.Fee_Annual__c = annualFee;
            editedData.Technical_Premium_Discretion__c = percentTPD;
            editedData.Final_Discretion__c = percentfinalD;
            editedData.Price_Adequacy__c = percentPriceAdequacy;
            editedData.IPT__c = iPT;
            editedData.Total_Cost_To_Client__c = totalCosttoClient;

        });

        this.data = temp;

    }*/

    /*@wire(fetchTaxPercent, { quoteId: '$quoteId',
                             code: 'Tax Percent'
                        }) 
    accountData( result ) {
        var result = result;
        var data = result.data;
        var error = result.error;
        if(data){
            this.taxPercent = data.taxPercent;
            this.termLength = data.termLength;
        }
    }*/

    /*set freeFormOption(value){

        var clone = JSON.parse(JSON.stringify(this.freeFormOption));
        clone.fieldDetails,forEach(item => {
            if(item.fieldAPIName === 'Limit__c')
                this.freeFormLimit = item;
        });

    }

    @api get freeFormOption() {
        return this._compareItem;
    }*/

    @api
    handleRefreshOptionTable() {
        refreshApex(this.wiredata);
        console.log('this.wiredata' + JSON.stringify(this.wiredata));
    }

    handleSectionToggle(event) {
        const openSections = event.detail.openSections;
    }

    handleFreeForm() {
        console.log('this.freeFormOption' + this.freeFormOption);
        console.log('this.freeFormLimit' + this.freeFormLimit);
        this.showFreeForm = true;
    }

    handleDeleteFreeForm() {
        var data = this.data;
        var optionId;
        data.forEach(item => {
            if (item.Option_Type__c === 'Free Form') {
                optionId = item.Id;
            }
        });
        console.log('optionId' + optionId);
        deleteQuoteOptions({ optionId: optionId })
            .then((result) => {
                if (result === 'success') {
                    console.log('@@@data1: ' + JSON.stringify(result));
                    this.handleRefreshOptionTable();
                } else {
                    console.log('@@@error1: ' + JSON.stringify(result));
                }
            })
            .catch((error) => {
                console.log('@@@error1: ' + JSON.stringify(error));
                //this.error = error;
            })
    }

    handleCancel() {
        // handle cancel here
        this.showFreeForm = false;
    }

    handleChange(event) {
        var changevalue = event.detail.value;
        var changelabel = event.target.label;
        var changename = event.target.name;
        var freeFormLimit = JSON.parse(JSON.stringify(this.freeFormLimit));
        if (freeFormLimit.fieldAPIName === 'Limit__c') {
            freeFormLimit.value = changevalue;
        }
        this.freeFormLimit = freeFormLimit;
    }

    handleCellChange(event) {

        this.recalculateOptionss(event.detail.draftValues);

    }

    recalculateOptionss(value) {
        this.draftOptions = value;
        var draftvalue = JSON.parse(JSON.stringify(value[0]));
        var rowId = draftvalue['Id'];
        console.log('rowId' + rowId);
        console.log('draftvalue'+JSON.stringify(draftvalue));
        var limit;
        var finaltechPremium = '';
        var finalAP;
        var finalBNDP;
        var finalFee;
        var overrideAP;
        var overrideBNDP;
        var overrideFee;
        var annualAP;
        var annualBNDP;
        var annualFee;
        var finalBookPremium;
        var finalMinPremium;
        var annualBookPremium;
        var annualMinPremium;
        var annualTechPremium;
        var percentTPD;
        var percentfinalD
        var percentPriceAdequacy;
        var techfee;
        var termLength = this.termLength;
        var taxPercent = this.taxPercent;
        var iPT;
        var totalCosttoClient;
        var changeinAP;
        var changeinBNDP;
        var changeinFee;
        var changeinIPT;
        var changeinTotalCosttoClient;
        var nDCPercent;
        var nDCAmount;
        var brokerCommPercent;
        var nonProRatedAP;
        var nonProRatedBNDP;
        var nDMGACPercent;
        var nDMGACAmount;
        var increasedLimitFactor;
        var rate;
        var rateChange;

        var lstRecords = JSON.parse(JSON.stringify(this.wiredata.data.lstRecords));
        var data = JSON.parse(JSON.stringify(this.data));
        var editedData;
        data.forEach(item => {
            if (item.Id === rowId) {
                editedData = item;
            }
        });

        console.log('editedData' + JSON.stringify(editedData));

        limit = editedData.Technical_Premium__c;
        finaltechPremium = editedData.Technical_Premium__c;
        finalAP = editedData.Actual_Premium_Final__c;
        finalBNDP = editedData.Broker_Netted_Down_Premium_Final__c;
        nonProRatedAP = editedData.NonProrated_Actual_Premium__c;
        nonProRatedBNDP = editedData.NonProRated_BNDP__c;
        finalFee = editedData.Fee_Final__c;
        overrideAP = editedData.Override_Actual_Premium_Percent__c;
        overrideBNDP = editedData.OverrideBrokerNettedDownPremiumPercent__c;
        overrideFee = editedData.Override_Fee_Percent__c;
        annualAP = editedData.Actual_Premium_Annual__c;
        annualBNDP = editedData.Broker_Netted_Down_Premium_Annual__c;
        annualFee = editedData.Fee_Annual__c;
        finalBookPremium = editedData.Book_Premium__c;
        finalMinPremium = editedData.Minimum_Premium__c;
        annualBookPremium = editedData.Book_Premium_Annual__c;
        annualMinPremium = editedData.Minimum_Premium_Annual__c;
        annualTechPremium = editedData.Technical_Premium_Annual__c;
        percentfinalD = editedData.Final_Discretion__c;
        percentPriceAdequacy = editedData.Price_Adequacy__c;
        iPT = editedData.IPT__c;
        totalCosttoClient = editedData.Total_Cost_To_Client__c;
        techfee = editedData.Technical_Fee__c;
        changeinAP = editedData.Change_In_Actual_Premium__c;
        changeinBNDP = editedData.Change_In_Broker_Netted_Down_Premium__c;
        changeinFee = editedData.Change_In_Fee__c;
        changeinIPT = editedData.Change_in_IPT__c;
        changeinTotalCosttoClient = editedData.Change_in_Total_Cost_to_Client__c;
        nDCPercent = editedData.Netted_Down_Commission_Percent__c;
        nDCAmount = editedData.Netted_Down_Commission_Amount__c;
        brokerCommPercent = editedData.Broker_Commission_Percent__c;
        nDMGACPercent = editedData.Netted_Down_MGA_Commission_Percent__c;
        nDMGACAmount = editedData.Netted_Down_MGA_Commission_Amount__c;
        increasedLimitFactor = editedData.Increased_Limit_Factor__c;
        rate = editedData.Rate__c;
        rateChange = editedData.Rate_Change__c ? editedData.Rate_Change__c : 0;

        if (draftvalue['NonProrated_Actual_Premium__c']) {
            this.isOptionfieldUpdated = true;
            nonProRatedAP = finalAP = draftvalue['NonProrated_Actual_Premium__c'];
            var tenPercentfinalAP = finalAP * 0.1;
            nonProRatedBNDP = finalBNDP = finalAP;
            finalFee = tenPercentfinalAP; // > 500 ? 500 : (tenPercentfinalAP < 50 ? 50 : tenPercentfinalAP);
            techfee = finalFee;
            //Calculate Override Premium % and annual Premiums
            if (finaltechPremium !== '') {
                overrideAP = finalAP / finaltechPremium * 100;
                annualAP = termLength ? finalAP * (365 / termLength) : finalAP;
                draftvalue['Override_Actual_Premium_Percent__c'] = overrideAP;
                draftvalue['Actual_Premium_Annual__c'] = (annualAP != null || annualAP != undefined) ? annualAP.toFixed(2) : 0;
            }
            overrideBNDP = finalBNDP / finalAP * 100;
            annualBNDP = termLength ? finalBNDP * (365 / termLength) : finalBNDP;
            draftvalue['OverrideBrokerNettedDownPremiumPercent__c'] = overrideBNDP;
            draftvalue['Broker_Netted_Down_Premium_Annual__c'] =  (annualBNDP != null || annualBNDP != undefined) ? annualBNDP.toFixed(2) : 0;
            overrideFee = finalFee / techfee * 100;
            annualFee = termLength ? finalFee * (365 / termLength) : finalFee;
            draftvalue['Override_Fee_Percent__c'] = overrideFee;
            draftvalue['Fee_Annual__c'] = (annualFee != null || annualFee != undefined) ?  annualFee.toFixed(2) : 0;
            draftvalue['Broker_Netted_Down_Premium_Final__c'] = finalBNDP;
            draftvalue['NonProRated_BNDP__c'] = nonProRatedBNDP;
            draftvalue['Fee_Final__c'] = finalFee;

            annualBookPremium = finalBookPremium ? finalBookPremium * (365 / termLength) : annualBookPremium;
            annualMinPremium = finalMinPremium ? finalMinPremium * (365 / termLength) : annualMinPremium;
            annualTechPremium = finaltechPremium ? finaltechPremium * (365 / termLength) : annualTechPremium;

            /*New code Added By Navdeep 08/02/2022***/
            if (finalBookPremium == undefined || annualTechPremium == undefined) {

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please rate the quote before making any changes.',
                        variant: 'error'
                    })
                );
                return;
            }


            /*New code End By Navdeep 08/02/2022***/


            draftvalue['Book_Premium_Annual__c'] =  (annualBookPremium != null || annualBookPremium != undefined) ? annualBookPremium.toFixed(2) : 0;
            draftvalue['Minimum_Premium_Annual__c'] =  (annualMinPremium != null || annualMinPremium != undefined) ? annualMinPremium.toFixed() : 0;
            draftvalue['Technical_Premium_Annual__c'] = (annualTechPremium != null || annualTechPremium != undefined) ?  annualTechPremium.toFixed(2) : 0;
            //calculate discretion percents
            percentTPD = annualTechPremium / annualBookPremium * 100;
            draftvalue['Technical_Premium_Discretion__c'] = percentTPD;
            percentfinalD = annualAP / annualBookPremium * 100;
            draftvalue['Final_Discretion__c'] = percentfinalD;
            percentPriceAdequacy = annualAP / annualTechPremium * 100;
            draftvalue['Price_Adequacy__c'] = percentPriceAdequacy;
            iPT = taxPercent ? parseInt(taxPercent) * finalBNDP / 100 : 0;
            totalCosttoClient = parseFloat(finalBNDP) + iPT + parseFloat(finalFee);
            draftvalue['IPT__c'] = iPT;
            draftvalue['Total_Cost_To_Client__c'] = totalCosttoClient;

            var brokerComAmount = brokerCommPercent * finalAP / 100;
            var diffAPnBNDP = finalAP - finalBNDP;
            nDCAmount = brokerComAmount - diffAPnBNDP;
            nDCPercent = parseFloat(finalBNDP) != 0 ? nDCAmount / finalBNDP * 100 : 0;

            var mgaComAmount = this.mgaCommissionPercent * finalAP / 100;
            var diffAPnBNDP = finalAP - finalBNDP;
            nDMGACAmount = mgaComAmount - diffAPnBNDP;
            nDMGACPercent = parseFloat(finalBNDP) != 0 ? nDMGACAmount / finalBNDP * 100 : 0;

            rate = annualAP && increasedLimitFactor && this.annualGrossFee ? ((annualAP / increasedLimitFactor) / parseFloat(this.annualGrossFee)) * 100 : 0;
            console.log('rate' + rate);
            if (this.quoteType == 'Renewal') {
                rateChange = rate && this.priorRate && this.priorRate != 0 ? ((rate - this.priorRate) / this.priorRate) * 100 : 0;
                console.log('rateChange' + rateChange);
            }


        } else if (draftvalue['NonProRated_BNDP__c']) {
            this.isOptionfieldUpdated = true;
            nonProRatedBNDP = finalBNDP = draftvalue['NonProRated_BNDP__c'];
            overrideBNDP = finalBNDP / finalAP * 100;
            annualBNDP = termLength ? finalBNDP * (365 / termLength) : finalBNDP;

            console.log('nonProRatedBNDP' + nonProRatedBNDP)
            console.log('annualBNDP' + annualBNDP)


            /*New code Added By Navdeep 08/02/2022***/
            if (editedData.hasOwnProperty('Broker_Netted_Down_Premium_Annual__c') && isNaN(editedData.Broker_Netted_Down_Premium_Annual__c)) {

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please rate the quote before making any changes.',
                        variant: 'error'
                    })
                );
                return;
            }
            if(!editedData.hasOwnProperty('Broker_Netted_Down_Premium_Annual__c')){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please rate the quote before making any changes.',
                        variant: 'error'
                    })
                );
                return;
            }


            /*New code End By Navdeep 08/02/2022***/

            draftvalue['OverrideBrokerNettedDownPremiumPercent__c'] = overrideBNDP;
            draftvalue['Broker_Netted_Down_Premium_Annual__c'] = (annualBNDP != null || annualBNDP != undefined) ? annualBNDP.toFixed(2) : 0;

            annualBookPremium = finalBookPremium ? finalBookPremium * (365 / termLength) : annualBookPremium;
            annualMinPremium = finalMinPremium ? finalMinPremium * (365 / termLength) : annualMinPremium;
            annualTechPremium = finaltechPremium ? finaltechPremium * (365 / termLength) : annualTechPremium;
            draftvalue['Book_Premium_Annual__c'] = (annualBookPremium != null || annualBookPremium != undefined) ? annualBookPremium.toFixed(2) : 0;
            draftvalue['Minimum_Premium_Annual__c'] = (annualMinPremium != null || annualMinPremium != undefined) ? annualMinPremium.toFixed() : 0;
            draftvalue['Technical_Premium_Annual__c'] = (annualTechPremium != null || annualTechPremium != undefined) ? annualTechPremium.toFixed(2) : 0;

            percentTPD = annualTechPremium / annualBookPremium * 100;
            draftvalue['Technical_Premium_Discretion__c'] = percentTPD;

            iPT = taxPercent ? parseInt(taxPercent) * finalBNDP / 100 : 0;
            totalCosttoClient = parseFloat(finalBNDP) + iPT + parseFloat(finalFee);
            draftvalue['IPT__c'] = iPT;
            draftvalue['Total_Cost_To_Client__c'] = totalCosttoClient;

            var brokerComAmount = brokerCommPercent * finalAP / 100;
            var diffAPnBNDP = finalAP - finalBNDP;
            nDCAmount = brokerComAmount - diffAPnBNDP;
            nDCPercent = parseFloat(finalBNDP) != 0 ? nDCAmount / finalBNDP * 100 : 0;

            var mgaComAmount = this.mgaCommissionPercent * finalAP / 100;
            var diffAPnBNDP = finalAP - finalBNDP;
            nDMGACAmount = mgaComAmount - diffAPnBNDP;
            nDMGACPercent = parseFloat(finalBNDP) != 0 ? nDMGACAmount / finalBNDP * 100 : 0;

        } else if (draftvalue['Fee_Final__c']) {
            finalFee = draftvalue['Fee_Final__c'];
            changeinFee = finalFee;
            overrideFee = finalFee / techfee * 100;
            annualFee = termLength ? finalFee * (365 / termLength) : finalFee;
            draftvalue['Override_Fee_Percent__c'] = overrideFee;


            /*New code Added By Navdeep 08/02/2022***/
            if (editedData.hasOwnProperty('Fee_Annual__c') && isNaN(editedData.Fee_Annual__c)) {

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please rate the quote before making any changes.',
                        variant: 'error'
                    })
                );
                return;
            }
            
            if(!editedData.hasOwnProperty('Fee_Annual__c')){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please rate the quote before making any changes.',
                        variant: 'error'
                    })
                );
                return;
            }
            console.log('editedData'+editedData.Fee_Annual__c)
            /*New code Ended By Navdeep 08/02/2022***/



            draftvalue['Fee_Annual__c'] = (annualFee != null || annualFee != undefined) ? annualFee.toFixed(2) : 0;

            annualBookPremium = finalBookPremium ? finalBookPremium * (365 / termLength) : annualBookPremium;
            annualMinPremium = finalMinPremium ? finalMinPremium * (365 / termLength) : annualMinPremium;
            annualTechPremium = finaltechPremium ? finaltechPremium * (365 / termLength) : annualTechPremium;
            console.log('annualBookPremium'+annualBookPremium);
            draftvalue['Book_Premium_Annual__c'] =  (annualBookPremium != null || annualBookPremium != undefined) ?  annualBookPremium.toFixed(2) : 0;
            console.log('draft'+draftvalue['Book_Premium_Annual__c']);
            draftvalue['Minimum_Premium_Annual__c'] = (annualMinPremium != null || annualMinPremium != undefined) ? annualMinPremium.toFixed() : 0;
            draftvalue['Technical_Premium_Annual__c'] = (annualTechPremium != null || annualTechPremium != undefined) ? annualTechPremium.toFixed(2) : 0;

            percentTPD = annualTechPremium / annualBookPremium * 100;
            draftvalue['Technical_Premium_Discretion__c'] = percentTPD;
            iPT = taxPercent ? parseInt(taxPercent) * finalBNDP / 100 : 0;
            totalCosttoClient = parseFloat(finalBNDP) + iPT + parseFloat(finalFee);
            draftvalue['IPT__c'] = iPT;
            draftvalue['Total_Cost_To_Client__c'] = totalCosttoClient;
        } else if (draftvalue['Limit__c']) {
            this.isOptionfieldUpdated = true;
            if (this.quoteType === 'Full Amendment' || this.quoteType === 'Coverage Amendment') {
                console.log('lstRecords' + lstRecords);
                limit = parseFloat(draftvalue['Limit__c']);
                editedData.Limit__c = limit;
                /*var setFreeFormLimit = true;
                lstRecords.forEach(item => {
                    if(item.Limit__c === limit && item.Option_Type__c === 'Fixed Limit'){
                        setFreeFormLimit = false;
                        editedData = item;
                        editedData.Bound__c = true;
                        editedData.Selected__c = true;
                    }
                });
                if(setFreeFormLimit === true){
                    lstRecords.forEach(item => {
                        if(item.Option_Type__c === 'Free Form'){
                            editedData = item;
                            editedData.Limit__c = limit;
                            editedData.Bound__c = true;
                            editedData.Selected__c = true;
                        }
                    });
                }*/
            }

        } else if (draftvalue['Change_In_Actual_Premium__c']) {
            if (this.quoteType === 'Full Amendment' || this.quoteType === 'Coverage Amendment' || this.quoteType === 'Policy Duration Change' || this.quoteType === 'Midterm Cancellation') {
                changeinAP = draftvalue['Change_In_Actual_Premium__c'];
                finalAP = parseFloat(this.priorAP) + parseFloat(changeinAP);
                draftvalue['Actual_Premium_Final__c'] = finalAP;

                var brokerComAmount = brokerCommPercent * changeinAP / 100;
                var diffAPnBNDP = changeinAP - changeinBNDP;
                nDCAmount = brokerComAmount - diffAPnBNDP;
                nDCPercent = parseFloat(changeinBNDP) != 0 ? nDCAmount / changeinBNDP * 100 : 0;

                var mgaComAmount = this.mgaCommissionPercent * changeinAP / 100;
                var diffAPnBNDP = changeinAP - changeinBNDP;
                nDMGACAmount = mgaComAmount - diffAPnBNDP;
                nDMGACPercent = parseFloat(changeinBNDP) != 0 ? nDMGACAmount / changeinBNDP * 100 : 0;

                nonProRatedAP = ((parseFloat(changeinAP) / parseInt(this.effectiveTermLength)) * parseInt(this.termLength)) + this.priorNonProRatedAP;
                draftvalue['NonProrated_Actual_Premium__c'] = nonProRatedAP;
                console.log(nonProRatedAP);
                //finalBNDP = finalAP;
                //Calculate Override Premium % and annual Premiums
                //if (finaltechPremium !== '') { 
                    //overrideAP = finalAP / finaltechPremium * 100;
                    annualAP = termLength ? nonProRatedAP * (365 / termLength) : nonProRatedAP;//uncommenting as part of 54795
                    //draftvalue['Override_Actual_Premium_Percent__c'] = overrideAP;
                    draftvalue['Actual_Premium_Annual__c'] = annualAP.toFixed(2);
                //}
                /*overrideBNDP = finalBNDP / finalAP * 100;
                annualBNDP = termLength ? finalBNDP * (365 / termLength) : finalBNDP;
                draftvalue['OverrideBrokerNettedDownPremiumPercent__c'] = overrideBNDP;
                draftvalue['Broker_Netted_Down_Premium_Annual__c'] = annualBNDP.toFixed(2);
                overrideFee = finalFee / techfee * 100;
                annualFee = termLength ? finalFee * (365 / termLength) : finalFee;
                draftvalue['Override_Fee_Percent__c'] = overrideFee;
                draftvalue['Fee_Annual__c'] = annualFee.toFixed(2);
                draftvalue['Broker_Netted_Down_Premium_Final__c'] = finalBNDP;
                draftvalue['Fee_Final__c'] = finalFee;
                console.log('finalBookPremium' + finalBookPremium);
                annualBookPremium = finalBookPremium ? finalBookPremium * (365 / termLength) : annualBookPremium;
                annualMinPremium = finalMinPremium ? finalMinPremium * (365 / termLength) : annualMinPremium;
                annualTechPremium = finaltechPremium ? finaltechPremium * (365 / termLength) : annualTechPremium;
                console.log('annualTechPremium' + annualTechPremium);
                draftvalue['Book_Premium_Annual__c'] = annualBookPremium.toFixed(2);
                draftvalue['Minimum_Premium_Annual__c'] = annualMinPremium.toFixed();
                draftvalue['Technical_Premium_Annual__c'] = annualTechPremium.toFixed(2);
                console.log('annualTechPremium' + annualTechPremium);*/
                //calculate discretion percents
                /*percentTPD = annualTechPremium / annualBookPremium * 100;
                draftvalue['Technical_Premium_Discretion__c'] = percentTPD;
                percentfinalD = annualAP / annualBookPremium * 100;
                draftvalue['Final_Discretion__c'] = percentfinalD;
                percentPriceAdequacy = annualAP / annualTechPremium * 100;
                draftvalue['Price_Adequacy__c'] = percentPriceAdequacy;

                iPT = taxPercent ? parseInt(taxPercent) * finalBNDP / 100 : 0;
                totalCosttoClient = parseInt(finalBNDP) + iPT + parseInt(finalFee);
                draftvalue['IPT__c'] = iPT;
                draftvalue['Total_Cost_To_Client__c'] = totalCosttoClient;*/
            }
        } else if (draftvalue['Change_In_Broker_Netted_Down_Premium__c']) {
            if (this.quoteType === 'Full Amendment' || this.quoteType === 'Coverage Amendment' || this.quoteType === 'Policy Duration Change' || this.quoteType === 'Midterm Cancellation') {
                changeinBNDP = draftvalue['Change_In_Broker_Netted_Down_Premium__c'];
                finalBNDP = parseFloat(this.priorBNDP) + parseFloat(changeinBNDP);

                var brokerComAmount = brokerCommPercent * changeinAP / 100;
                var diffAPnBNDP = changeinAP - changeinBNDP;
                nDCAmount = brokerComAmount - diffAPnBNDP;
                nDCPercent = parseFloat(changeinBNDP) != 0 ? nDCAmount / changeinBNDP * 100 : 0;

                var mgaComAmount = this.mgaCommissionPercent * changeinAP / 100;
                var diffAPnBNDP = changeinAP - changeinBNDP;
                nDMGACAmount = mgaComAmount - diffAPnBNDP;
                nDMGACPercent = parseFloat(changeinBNDP) != 0 ? nDMGACAmount / changeinBNDP * 100 : 0;
                console.log(nDMGACPercent);
                nonProRatedBNDP = ((parseFloat(changeinBNDP) / parseInt(this.effectiveTermLength)) * parseInt(this.termLength)) + this.priorNonProRatedBNDP;
                draftvalue['NonProRated_BNDP__c'] = nonProRatedBNDP;
                //overrideBNDP = finalBNDP / finalAP * 100;
                annualBNDP = termLength ? nonProRatedBNDP * (365 / termLength) : nonProRatedBNDP;//uncommenting as part of 54795
                //draftvalue['OverrideBrokerNettedDownPremiumPercent__c'] = overrideBNDP;
                draftvalue['Broker_Netted_Down_Premium_Annual__c'] = annualBNDP.toFixed(2);//uncommenting as part of 54795

                /*annualBookPremium = finalBookPremium ? finalBookPremium * (365 / termLength) : annualBookPremium;
                annualMinPremium = finalMinPremium ? finalMinPremium * (365 / termLength) : annualMinPremium;
                annualTechPremium = finaltechPremium ? finaltechPremium * (365 / termLength) : annualTechPremium;
                draftvalue['Book_Premium_Annual__c'] = annualBookPremium.toFixed(2);
                draftvalue['Minimum_Premium_Annual__c'] = annualMinPremium.toFixed();
                draftvalue['Technical_Premium_Annual__c'] = annualTechPremium.toFixed(2);

                percentTPD = annualTechPremium / annualBookPremium * 100;
                draftvalue['Technical_Premium_Discretion__c'] = percentTPD;*/

                iPT = taxPercent ? parseInt(taxPercent) * finalBNDP / 100 : 0;
                totalCosttoClient = parseFloat(finalBNDP) + iPT + parseFloat(finalFee);
                draftvalue['IPT__c'] = iPT;
                draftvalue['Total_Cost_To_Client__c'] = totalCosttoClient;
                changeinIPT = taxPercent ? parseInt(taxPercent) * changeinBNDP / 100 : 0;
                changeinTotalCosttoClient = parseFloat(changeinBNDP) + changeinIPT + parseFloat(changeinFee);

            }
        } else if (draftvalue['Change_In_Fee__c']) {
            if (this.quoteType === 'Full Amendment' || this.quoteType === 'Coverage Amendment' || this.quoteType === 'Policy Duration Change' || this.quoteType === 'Midterm Cancellation') {
                changeinFee = draftvalue['Change_In_Fee__c'];
                finalFee = parseFloat(this.priorFee) + parseFloat(changeinFee);
                //overrideFee = finalFee / techfee * 100;
                annualFee = termLength ? finalFee * (365 / termLength) : finalFee;
                draftvalue['Override_Fee_Percent__c'] = overrideFee;
                draftvalue['Fee_Annual__c'] = (annualFee != null || annualFee != undefined) ?  annualFee.toFixed(2) : 0;

                annualBookPremium = finalBookPremium ? finalBookPremium * (365 / termLength) : annualBookPremium;
                annualMinPremium = finalMinPremium ? finalMinPremium * (365 / termLength) : annualMinPremium;
                annualTechPremium = finaltechPremium ? finaltechPremium * (365 / termLength) : annualTechPremium;
                draftvalue['Book_Premium_Annual__c'] =  (annualBookPremium != null || annualBookPremium != undefined) ? annualBookPremium.toFixed(2) : 0;
                draftvalue['Minimum_Premium_Annual__c'] = (annualMinPremium != null || annualMinPremium != undefined) ? annualMinPremium.toFixed() : 0;
                draftvalue['Technical_Premium_Annual__c'] = (annualTechPremium != null || annualTechPremium != undefined) ? annualTechPremium.toFixed(2) : 0;

                percentTPD = annualTechPremium / annualBookPremium * 100;
                draftvalue['Technical_Premium_Discretion__c'] = percentTPD;

                iPT = taxPercent ? parseInt(taxPercent) * finalBNDP / 100 : 0;
                totalCosttoClient = parseFloat(finalBNDP) + iPT + parseFloat(finalFee);
                draftvalue['IPT__c'] = iPT;
                draftvalue['Total_Cost_To_Client__c'] = totalCosttoClient;
                changeinIPT = taxPercent ? parseInt(taxPercent) * changeinBNDP / 100 : 0;
                changeinTotalCosttoClient = parseFloat(changeinBNDP) + changeinIPT + parseFloat(changeinFee);
            }
        }
        this.draftOptions[0] = draftvalue;

        //populate values on datatable
        //editedData.Limit__c = limit;


        editedData.Actual_Premium_Final__c = finalAP;
        editedData.Actual_Premium__c = finalAP;
        editedData.Broker_Netted_Down_Premium_Final__c = finalBNDP;
        editedData.Broker_Netted_Down_Premium__c = finalBNDP;
        editedData.NonProrated_Actual_Premium__c = nonProRatedAP;
        editedData.NonProRated_BNDP__c = nonProRatedBNDP;
        editedData.Fee_Final__c = finalFee;
        editedData.Fee__c = finalFee;
        editedData.Technical_Fee__c = techfee;
        editedData.Override_Actual_Premium_Percent__c = overrideAP;
        editedData.OverrideBrokerNettedDownPremiumPercent__c = overrideBNDP;
        editedData.Override_Fee_Percent__c = overrideFee;
        editedData.Actual_Premium_Annual__c =(annualAP != null || annualAP != undefined) ? parseFloat(annualAP).toFixed(2) : 0.00;
        editedData.Broker_Netted_Down_Premium_Annual__c = (annualBNDP != null || annualBNDP != undefined) ? parseFloat(annualBNDP).toFixed(2) : 0.00;
        editedData.Fee_Annual__c =  (annualFee != null || annualFee != undefined)  ? parseFloat(annualFee).toFixed(2) : 0.00;
        editedData.Book_Premium_Annual__c =  (annualBookPremium != null || annualBookPremium != undefined)  ? parseFloat(annualBookPremium).toFixed(2) : 0.00;
        editedData.Minimum_Premium_Annual__c = (annualMinPremium != null || annualMinPremium != undefined) ? parseFloat(annualMinPremium).toFixed() : 0.00;
        editedData.Technical_Premium_Annual__c = (annualTechPremium != null || annualTechPremium != undefined) ? parseFloat(annualTechPremium).toFixed(2) : 0.00;
        editedData.Final_Discretion__c = percentfinalD;
        editedData.Price_Adequacy__c = percentPriceAdequacy;
        editedData.IPT__c = iPT;
        editedData.IPT_on_Broker_Netted_Down_Premium__c = iPT;
        editedData.Total_Cost_To_Client__c = totalCosttoClient;
        editedData.Change_In_Actual_Premium__c = changeinAP;
        editedData.Change_In_Broker_Netted_Down_Premium__c = changeinBNDP;
        editedData.Change_In_Fee__c = changeinFee;
        editedData.Change_in_IPT__c = changeinIPT;
        editedData.Change_in_Total_Cost_to_Client__c = changeinTotalCosttoClient;
        editedData.Netted_Down_Commission_Percent__c = nDCPercent;
        editedData.Netted_Down_Commission_Amount__c = nDCAmount;
        editedData.Netted_Down_MGA_Commission_Percent__c = nDMGACPercent;
        editedData.Netted_Down_MGA_Commission_Amount__c = nDMGACAmount;
        editedData.Rate__c = rate = (rate != null || rate != undefined) ?   parseFloat(rate.toFixed(5)) : 0;
        editedData.Rate_Change__c = (rateChange != null || rateChange != undefined) ? parseFloat(rateChange.toFixed(5)) : 0;

        if (this.quoteType !== 'Full Amendment' && this.quoteType !== 'Coverage Amendment' && this.quoteType !== 'Policy Duration Change' && this.quoteType !== 'Midterm Cancellation') {

            data.forEach(item => {
                if (item.Id === rowId) {
                    item = editedData;
                }
            });

        } else {
            var temp = [];
            temp.push(editedData);
            data = temp;
        }

        this.data = data;

    }

    handlesaveOptions() {
        var data = this.data;
        var doSaveOption = true;
        if (this.quoteType === 'Full Amendment' || this.quoteType === 'Coverage Amendment') {
            data.forEach(item => {
                if (item.Bound__c === true) {
                    var limit = parseFloat(item.Limit__c);
                    if (limit < 100000 || limit > 5000000) {
                        doSaveOption = false;
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Limit Values cannot be below 100,000 or above 5,000,000',
                                message: 'error',
                                variant: 'error'
                            })
                        );
                    }
                }
            });
        }
        if (this.quoteType === 'New Business' || this.quoteType === 'Renewal') {
            data.forEach(item => {
                var nonProRatedAP = parseFloat(item.NonProrated_Actual_Premium__c);
                var nonProRatedBNDP = parseFloat(item.NonProRated_BNDP__c);

                if (nonProRatedBNDP > nonProRatedAP) {
                    doSaveOption = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'BNDP cannot be greater than AP',
                            message: 'error',
                            variant: 'error'
                        })
                    );
                }
            });
        } else {
            data.forEach(item => {
                var changeinAP = parseFloat(item.Change_In_Actual_Premium__c);
                var changeinBNDP = parseFloat(item.Change_In_Broker_Netted_Down_Premium__c);
                if (changeinBNDP > changeinAP) {
                    doSaveOption = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'BNDP AP/RP cannot be greater than AP AP/RP',
                            message: 'error',
                            variant: 'error'
                        })
                    );
                }
            });
        }
        if (doSaveOption === true) {
            saveQuoteOptions({
                listQuoteOptions: data,
                quoteId: this.quoteId,
                selectedSelectedRows: null
            }).then(response => {
                if (response === 'success') {
                    //refreshApex(this.wiredata);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Quote Options Successfully Updated',
                            message: 'Success',
                            variant: 'Success'
                        })
                    );
                    if (this.quoteStatus !== 'In Progress' && (this.isOptionfieldUpdated == true || (this.isOptionfieldUpdated == false && this.quoteStatus == 'Quoted'))) {
                        this.draftOptions = [];
                        var status = 'In Progress';
                        var successMsg = 'Quote Status updated to In Progress';
                        if (this.isOptionfieldUpdated == false && this.quoteStatus == 'Quoted') {
                            status = 'Rated';
                            successMsg = 'Quote Status updated to Rated';
                        }
                        const fields = {}
                        fields['Id'] = this.quoteId;
                        fields['Status'] = status;

                        const recordInput = { fields };
                        updateRecord(recordInput)
                            .then(() => {
                                this.isOptionfieldUpdated = false;
                                let refreshQuote = new CustomEvent('refreshquotedetail', { bubbles: true, composed: true, detail: { quoteId: this.quoteId } });
                                this.dispatchEvent(refreshQuote);
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: successMsg,
                                        message: 'Success',
                                        variant: 'Success'
                                    })
                                );
                            })
                            .catch(error => {
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error updating status',
                                        message: error.body.message,
                                        variant: 'error'
                                    })
                                );
                            });
                    } else { 
                        this.isOptionfieldUpdated = false;
                        return refreshApex(this.wiredata).then(() => {

                        // Clear all draft values in the datatable
                        this.draftOptions = [];

                    });
                    }

                } else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error updating options',
                            message: response,
                            variant: 'error'
                        })
                    );
                }
            });
        }

    }

    handleCellChangeCancel() {

        this.handleRefreshOptionTable();

    }

    handleRowSelection(event) {
        //var draftvalues =JSON.parse(JSON.stringify(event.detail.draftValues));
        if (this.isEditable) {
            var selectedRows = JSON.parse(JSON.stringify(event.detail.selectedRows));
            console.log('selectedRowsLength'+selectedRows.length);
            console.log('this.quoteId'+this.quoteId);
         //*** New code for 51668 */
            if(selectedRows==0){
                this.noRowSelected = true;
                saveQuoteStatus({quoteId : this.quoteId}).then(response => {
                    console.log('response'+response);
                    if (response === 'quoteupdate') {
                        console.log(' this.noRowSelected'+ this.noRowSelected);
                        this.handleRefreshOptionTable();  
                        if (response === 'quoteupdate') {
                            console.log('quote update inside');
                            this.isLoading = true;
                            let refreshQuote = new CustomEvent('refreshquotedetail', { bubbles: true, composed: true, detail: { quoteId: this.quoteId } });
                            this.dispatchEvent(refreshQuote);
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Quote Status updated to In Progress',
                                    message: 'Success',
                                    variant: 'Success'
                                })
                            );
                      
                            let rateHandle = new CustomEvent('selectedrows',{detail:{isSelectedRows :this.noRowSelected }});
                            this.dispatchEvent(rateHandle);

                            this.isLoading = false;
                        }
                    }
                })
            }
            if (selectedRows.length > 0 && selectedRows !== undefined && this.quoteStatus != 'Closed') {
                this.noRowSelected = false;
                var selectedRowIds = [];
                selectedRows.forEach(row => {
                    selectedRowIds.push(row.Id);
                });
                //console.log('draftvalues'+draftvalues);
                console.log('selectedRows' + JSON.stringify(selectedRows));
                console.log('selectedRows size' + selectedRows.length);
                console.log('this.quoteId ::' + this.quoteId);

                console.log(' this.noRowSelected1'+ this.noRowSelected);

                      /**** 51668 ***/
                let rateHandle2 = new CustomEvent('selectedrows',{detail:{isSelectedRows : false}});
                this.dispatchEvent(rateHandle2);

                var data = JSON.parse(JSON.stringify(this.data));
                console.log('date' + data);
                data.forEach(item => {
                    if (selectedRowIds.includes(item.Id)) {
                        item.Selected__c = true;
                    } else {
                        item.Selected__c = false;
                    }
                });
                console.log('data' + data);
                /******************* Added this if condition for 51031 */
                console.log('this.quoteStatus1'+this.quoteStatus)
                if(this.quoteStatus !='Rejected'){
                console.log('this.quoteStatus2'+this.quoteStatus)
                saveQuoteOptions({
                    listQuoteOptions: data,
                    quoteId: this.quoteId,
                    selectedRows: selectedRows.length
                }).then(response => {
                    console.log('response>>' + response);             
                    if (response === 'success' || response === 'quoteupdate') {
                        this.handleRefreshOptionTable();
                        if (response === 'quoteupdate') {
                            console.log('quote update inside');
                            this.isLoading = true;
                            let refreshQuote = new CustomEvent('refreshquotedetail', { bubbles: true, composed: true, detail: { quoteId: this.quoteId } });
                            this.dispatchEvent(refreshQuote);
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Quote Status updated to In Progress',
                                    message: 'Success',
                                    variant: 'Success'
                                })
                            );
                            this.isLoading = false;
                        }
                    } else {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error updating options',
                                message: response,
                                variant: 'error'
                            })
                        );
                    }
                });
            }
            }
        }

        //this.data = data;
        //handlesaveOptions();
    }

    handleSaveFreeForm() {
        var freeFormOption = this.freeFormOption;
        var freeFormLimit = this.freeFormLimit;
        var limit = parseFloat(freeFormLimit.value);
        if (limit < 100000 || limit > 5000000) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Freeform Limit Values cannot be below 100,000 or above 5,000,000',
                    message: 'error',
                    variant: 'error'
                })
            );
        } else {
            const fields = {}
            fields['Id'] = freeFormOption.Id;
            var fieldAPIName = freeFormLimit['fieldAPIName'];
            fields[fieldAPIName] = freeFormLimit.value;

            const recordInput = { fields };
            updateRecord(recordInput)
                .then(() => {
                    console.log("Free form Limit Successfully Updated");
                    //refreshApex(this.wiredata);
                    this.handleRefreshOptionTable();
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Free form Limit Successfully Updated',
                            message: 'Success',
                            variant: 'Success'
                        })
                    );
                    if (this.quoteStatus !== 'In Progress') {
                        const fields = {}
                        fields['Id'] = this.quoteId;
                        fields['Status'] = 'In Progress';

                        const recordInput = { fields };
                        updateRecord(recordInput)
                            .then(() => {
                                let refreshQuote = new CustomEvent('refreshquotedetail', { bubbles: true, composed: true, detail: { quoteId: this.quoteId } });
                                this.dispatchEvent(refreshQuote);
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Quote Status updated to In Progress',
                                        message: 'Success',
                                        variant: 'Success'
                                    })
                                );
                            })
                            .catch(error => {
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error updating status',
                                        message: error.body.message,
                                        variant: 'error'
                                    })
                                );
                            });
                    }
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error updating status',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });

            this.showFreeForm = false;
        }

    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'data_summary':
                this.handleFactorSummaryClick(row);
                break;
            default:
        }
    }

    handleFactorSummaryClick(value) {
        var row = JSON.parse(JSON.stringify(value));
        console.log(row.Id);
        getFactorSummarysQC({ quoteOptionId: row.Id })
            .then(result => {
                this.summaryData = result.data.sort((a, b) => a.sortOrder - b.sortOrder);
                if (this.isAqueousProduct) {
                    this.summaryData.forEach(element => {
                        if (element.format == 'Percent') {
                            element.currentValue = element.currentValue + ' %';
                        }
                        if (element.format == 'Currency') {
                            if (element.currencyType == 'USD') {
                                element.currentValue = '$ ' + element.currentValue;
                            } else if (element.currencyType == 'GBP') {
                                element.currentValue = '£ ' + element.currentValue;
                            }
                        }
                    });
                }

                console.log('this.summaryData', JSON.stringify(this.summaryData));
                console.log('product: ', this.isAqueousProduct);
                const extradata = result.extraData;
                const oppType = extradata;
                if (oppType !== 'Renewal') this.columns = this.columns.filter(col => col.fieldName !== 'priorValue');
                this.isFactorSummary = true;
                this.tableLoading = false;
            })
            .catch(error => {
                console.log('Error:' + JSON.stringify(error));
            });

    }

    closeModal() {
        this.isFactorSummary = false;
        this.tableLoading = false;
    }

}