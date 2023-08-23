import { LightningElement, api, wire, track } from 'lwc';
import { updateRecord, getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import getSingleQuoteProcess from '@salesforce/apex/QuoteProcessController.getSingleQuoteProcess';
import checkRatingModifiersValidityForOpp from '@salesforce/apex/QuoteProcessController.checkRatingModifiersValidityForOpp';
import getRecordInfos from '@salesforce/apex/QuoteProcessController.getRecordInfos';
import STATUS_FIELD from '@salesforce/schema/Quote_Process__c.Status__c';
import ACCOUNT_FIELD from '@salesforce/schema/Quote_Process__c.Account__c';
import QUOTE_PROCESS_SUBMISSION_ID from '@salesforce/schema/Quote_Process__c.Submission__c';
import ID_FIELD from '@salesforce/schema/Quote_Process__c.Id';
import createSubmission from '@salesforce/apex/QuoteProcessController.createSubmission';
import checkProfileIsAdmin from '@salesforce/apex/SubmissionInfoLwcController.checkProfileIsAdmin';
import checkExistQuoteStatusBoundOrBoundPending from '@salesforce/apex/QuoteProcessController.checkExistQuoteStatusBoundOrBoundPending';
import updateAllQuoteToInProgress from '@salesforce/apex/QuoteProcessController.updateAllQuoteToInProgress';
//import TickerSymbol from '@salesforce/schema/Account.TickerSymbol';

import { createRecord } from 'lightning/uiRecordApi';
import QUOTE_PROCESS_OBJECT from '@salesforce/schema/Quote_Process__c';

import PCC_PRODUCT_NAME from '@salesforce/label/c.Product_Name_for_PCC';


const OPEN_MODAL_TO_SELECT_CLOSED_STEP = 'pathAssistant_selectAClosedStepValue';
const QUOTE_PROCESS_STATUS_INSURED_INFO = 'Insured Info';
//Added by Vinayesh
const QUOTE_PROCESS_STATUS_PRE_SCREENING = 'Underwriting Console';
const QUOTE_PROCESS_STATUS_SUBMISSION_CONSOLE = 'Submission Console';
const QUOTE_PROCESS_STATUS_SUBMISSION_INFO = 'Submission Info';
const QUOTE_PROCESS_STATUS_UNDERWRITTING_ANALYSIS = 'Underwritting Analysis';
const QUOTE_PROCESS_STATUS_COMPARE_RATE_QUOTES = 'Compare & Rate Quotes';
const QUOTE_PROCESS_STATUS_QUOTE_VERSION_CONSOLE = 'Quote Console';

export default class QuoteProcessLwc extends NavigationMixin(LightningElement) {
    @api recordId;
    @api validRecordId;//quoteprocessId
    @api objectApiName;
    @api quoteLayer;
    @track quoteComingThroughEvent = false;
    @track selectedMasterBinder;
    @track quote_process;
    @track quoteProcessAccountId;
    @track quoteProcessSubmissionId;
    @track submissionStage;
    @track isSelectedTab;
    @track isInsuredInfoStatus;
    //Added by Vinayesh
    @track isClearanceStatus = false;
    @track isSubmissionConsoleStatus = false;
    @track isSubmissionInfoStatus;
    @track isUnderwrittingAnalysisStatus;
    @track isCompareRateQuotesStatus;
    @track isQuoteVersionConsoleStatus;
    @track isReadyToSave = false;
    @track submissionType;
    isAqueous = false;
    isPCC = false;
    //Added by Vinayesh
    productName;

    @track isChangeQuoteToInProcess = false;


    @wire(getSingleQuoteProcess)
    quoteProcess;
    modeCreateSubmission = false;


    wireActivities;
    @wire(getRecordInfos, { recordId: '$recordId' })
    wiredRecord(value) {
        console.log('$$$$$insideWireMethod');
        this.wireActivities = value;
        const { data, error } = value;
        if (data && data.Id == null) {
            console.log('$$$$$1');
            const fields = {};
            fields[ACCOUNT_FIELD.fieldApiName] = data.Account__c;
            fields[QUOTE_PROCESS_SUBMISSION_ID.fieldApiName] = data.Submission__c;
            fields[STATUS_FIELD.fieldApiName] = data.Status__c;
            const recordInput = { apiName: QUOTE_PROCESS_OBJECT.objectApiName, fields };
            createRecord(recordInput)
                .then(newQuoteProcess => {
                    this.validRecordId = newQuoteProcess.id;
                    this.quoteProcessAccountId = (data.Account__c) ? data.Account__c : null;
                    this.quoteProcessSubmissionId = (data.Submission__c) ? data.Submission__c : null;
                    this.renderLWCByQuoteProcessStatus(data.Status__c);
                    this.redirectToQuoteProcess();
                }).catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error creating record',
                            message: error.body.message,
                            variant: 'error',
                        }),
                    );
                });
        }
        else if (error) {
            console.log('$$$$$2');
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading contact',
                    message,
                    variant: 'error',
                }),
            );
        } else if (data) {
            console.log('$$$$$3');
            console.log('Get Record Data -->' + JSON.stringify(data));
            console.log('recordId ' + this.recordId);
            this.validRecordId = data.Id;
            this.quoteProcessAccountId = (data.Account__c) ? data.Account__c : null;
            this.quoteProcessSubmissionId = (data.Submission__c) ? data.Submission__c : null;
            if(data.Product__c == 'Professional Indemnity' || data.Submission_Product__c == 'Professional Indemnity'){
                console.log('$$$$$isAqueous');
                this.isAqueous = true;
            }
            //Added by Vinayesh
            if(data.Product__c == PCC_PRODUCT_NAME || data.Submission_Product__c == PCC_PRODUCT_NAME){
                console.log('vinay');
                this.productName = PCC_PRODUCT_NAME;
                this.isPCC = true;
            }

            if(this.quoteProcessSubmissionId){
                console.log('vinay quote process submission1: ' + this.quoteProcessSubmissionId);
                this.submissionStage = data.Submission__r.StageName;
                this.submissionType = data.Submission__r.Type;
                console.log("Type-->",data.Submission__r.Type);
            }
            //data.Status__c == 'Insured Info'>> removed by Yogesh from below for 58961 
            if(this.productName == PCC_PRODUCT_NAME ){
                data.Status__c = QUOTE_PROCESS_STATUS_SUBMISSION_CONSOLE;
            }                
            this.renderLWCByQuoteProcessStatus(data.Status__c);
            if(!(this.productName == PCC_PRODUCT_NAME)){
                this.redirectToQuoteProcess();
            }
            
        }
    }

    renderedCallback() {
        console.log('I am in rendered callback quote process quotecomingthroughevent' + this.quoteComingThroughEvent);
        // if (this.firstRenderer == false) {
        //     console.log('I am in rendered callback1');
        //     this.firstRenderer = true;
        // }
    }
    redirectToQuoteProcess() {
        console.log('quoteprocessId', this.validRecordId);
        const curObjApiName = window.location.href.split('/').find(item => item == this.objectApiName)

        if (curObjApiName == 'Opportunity') {
            checkProfileIsAdmin().then(
                data => {
                    if (!data) {
                        let pageRef = {
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: this.validRecordId,
                                objectApiName: 'Quote_Process__c',
                                actionName: 'view'
                            },
                            state: {
                                //c__recordId : this.recordId
                            }
                        };
                        this[NavigationMixin.Navigate](pageRef);
                    }
                }
            )
        }

    }

    handleSendQuoteLayer(event) {        
        this.quoteLayer = event.detail.quoteLayer;
        this.selectedMasterBinder = event.detail.selectedBinder;
        
        this.quoteComingThroughEvent = true;
        console.log('vinay inside hanldesenquotelayer event: ' + this.quoteComingThroughEvent);   
    }

    handleChangeQuoteProcessStatus(event) {
        var status = event.detail.status;
        var accountId = event.detail.accountId; //Acount Id from the Insure Info
        this.quoteProcessAccountId = accountId;
        const fields = {};
        console.log('Valid record Id' + this.validRecordId);
        fields[ID_FIELD.fieldApiName] = this.validRecordId;

        if (accountId) { //handle event  from Insure Account
            fields[ACCOUNT_FIELD.fieldApiName] = accountId;
            createSubmission({ quoteProcessId: this.validRecordId, accountId: accountId })
                .then(submission => {
                    if (submission == null) {
                        this.updateQPFields(fields, true);//Create new Submission Mode, open Model to create new submission
                    } else {
                        this.quoteProcessSubmissionId = submission;
                        fields[QUOTE_PROCESS_SUBMISSION_ID.fieldApiName] = submission;
                        if(status == QUOTE_PROCESS_STATUS_PRE_SCREENING){                
                            fields[STATUS_FIELD.fieldApiName] = QUOTE_PROCESS_STATUS_PRE_SCREENING;
                        }
                        else{
                            fields[STATUS_FIELD.fieldApiName] = QUOTE_PROCESS_STATUS_SUBMISSION_INFO;
                        }
                        
                        this.updateQPFields(fields, false);
                    }
                })
                .catch(error => {
                    console.log('Error creating record submission :' + JSON.stringify(error));
                });
        } else { // event fire not from Account Info form (accountId=null)
            fields[STATUS_FIELD.fieldApiName] = status;
            this.updateQPFields(fields, false);
        }
    }

    handleCreateSubmissionSuccess(event) {
        var submissionId = event.detail.opportunity.id;
        this.quoteProcessSubmissionId = submissionId;
        var brokerId = event.detail.broker.id
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.validRecordId;
        fields[QUOTE_PROCESS_SUBMISSION_ID.fieldApiName] = submissionId;
        //Added by Vinayesh
        if(this.productName == PCC_PRODUCT_NAME){
            fields[STATUS_FIELD.fieldApiName] = QUOTE_PROCESS_STATUS_PRE_SCREENING;
        }
        else{
            fields[STATUS_FIELD.fieldApiName] = QUOTE_PROCESS_STATUS_SUBMISSION_INFO;
        }
        
        this.updateQPFields(fields, false);
    }

    handleCancel() {
        this.modeCreateSubmission = false;
    }

    @track nextStatus;
    handleChangeRefresh(event) {
        console.log('handleChangeRefresh', event.detail.currentStatus);
        // console.log('handleChangeRefresh',JSON.stringify(event.detail));
        // this.nextStatus = event.detail.currentStatus;
        // if(this.isCompareRateQuotesStatus && event.detail.currentStatus != QUOTE_PROCESS_STATUS_COMPARE_RATE_QUOTES){
        //     checkExistQuoteStatusBoundOrBoundPending({submissionId: this.quoteProcessSubmissionId}).then(
        //         data => {
        //             let existBoundOrBoundPending = data;
        //             console.log("existBoundOrBoundPending", JSON.stringify(existBoundOrBoundPending))
        //             if(!existBoundOrBoundPending){
        //                 this.isChangeQuoteToInProcess = true;
        //             }else {
        //                 this.renderLWCByQuoteProcessStatus(event.detail.currentStatus);
        //             }
        //         }
        //         ).catch(error => {
        //         console.log('checkExistQuoteStatusBoundOrBoundPending',JSON.stringify(e));
        //         this.dispatchEvent(
        //             new ShowToastEvent({
        //                 title: 'Error check exist Quote with status bound or bound pending',
        //                 message: error.body.message,
        //                 variant: 'error',
        //             }),
        //             );
        //         })
        // }else {
        /*        // }
        if(this.isReadyToSave  == '' || this.isReadyToSave  == undefined){
            this.renderLWCByQuoteProcessStatus(event.detail.currentStatus); 
        }
        else{
            this.renderLWCByQuoteProcessStatus(QUOTE_PROCESS_STATUS_SUBMISSION_INFO); 
        }*/
       
        this.renderLWCByQuoteProcessStatus(event.detail.currentStatus);
    
        console.log('Change tabs');
    }

    changeQuoteProcessStatusToCompareRate(event) {
        //Added by GiangPhan fixbug 34805
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.validRecordId;
        if(this.isAqueous || this.isPCC){
            fields[STATUS_FIELD.fieldApiName] = QUOTE_PROCESS_STATUS_QUOTE_VERSION_CONSOLE;
        }
        else{
            fields[STATUS_FIELD.fieldApiName] = QUOTE_PROCESS_STATUS_COMPARE_RATE_QUOTES;
        }
        this.updateQPFields(fields, false);
        //End fix
        if(this.isAqueous || this.isPCC){
            this.renderLWCByQuoteProcessStatus(QUOTE_PROCESS_STATUS_QUOTE_VERSION_CONSOLE);
        }
        else{
            this.renderLWCByQuoteProcessStatus(QUOTE_PROCESS_STATUS_COMPARE_RATE_QUOTES);
        }
        
    }

    handleResetQuoteComingThrough(event){
        console.log('vinay reset quotecomingthrough: ' + this.quoteComingThroughEvent);
        this.quoteComingThroughEvent = false;
    }

    //Modified by Vinayesh: Pre-Sceening status and Submission Console status
    renderLWCByQuoteProcessStatus(status) {
        console.log('renderLWCByQuoteProcessStatus status==>', status);
        switch (status) {
            case QUOTE_PROCESS_STATUS_SUBMISSION_CONSOLE:
                this.isSubmissionConsoleStatus = true;
                this.isInsuredInfoStatus = false;
                this.isClearanceStatus = false;
                this.isSubmissionInfoStatus = false;
                this.isUnderwrittingAnalysisStatus = false;
                this.isCompareRateQuotesStatus = false;
                this.isQuoteVersionConsoleStatus = false;
                break;
            case QUOTE_PROCESS_STATUS_INSURED_INFO:
                this.isInsuredInfoStatus = true;
                this.isSubmissionConsoleStatus = false;
                this.isClearanceStatus = false;
                this.isSubmissionInfoStatus = false;
                this.isUnderwrittingAnalysisStatus = false;
                this.isCompareRateQuotesStatus = false;
                this.isQuoteVersionConsoleStatus = false;
                break;
            //Added by Vinayesh
            case QUOTE_PROCESS_STATUS_PRE_SCREENING:
                this.isClearanceStatus = true;
                this.isSubmissionConsoleStatus = false;
                this.isInsuredInfoStatus = false;
                this.isSubmissionInfoStatus = false;
                this.isUnderwrittingAnalysisStatus = false;
                this.isCompareRateQuotesStatus = false;
                this.isQuoteVersionConsoleStatus = false;
                break;
            case QUOTE_PROCESS_STATUS_SUBMISSION_INFO:
                this.isSubmissionInfoStatus = true;
                this.isSubmissionConsoleStatus = false;
                this.isInsuredInfoStatus = false;
                this.isClearanceStatus = false;
                this.isUnderwrittingAnalysisStatus = false;
                this.isCompareRateQuotesStatus = false;
                this.isQuoteVersionConsoleStatus = false;
                break;
            case QUOTE_PROCESS_STATUS_UNDERWRITTING_ANALYSIS:
                this.isUnderwrittingAnalysisStatus = true;
                this.isSubmissionConsoleStatus = false;
                this.isInsuredInfoStatus = false;
                this.isClearanceStatus = false;
                this.isSubmissionInfoStatus = false;
                this.isCompareRateQuotesStatus = false;
                this.isQuoteVersionConsoleStatus = false;
                break;
            case QUOTE_PROCESS_STATUS_COMPARE_RATE_QUOTES:
                this.isCompareRateQuotesStatus = true;
                this.isSubmissionConsoleStatus = false;
                this.isInsuredInfoStatus = false;
                this.isClearanceStatus = false;
                this.isSubmissionInfoStatus = false;
                this.isUnderwrittingAnalysisStatus = false;
                this.isQuoteVersionConsoleStatus = false;
                break;
            case QUOTE_PROCESS_STATUS_QUOTE_VERSION_CONSOLE:
                this.isQuoteVersionConsoleStatus = true;
                this.isSubmissionConsoleStatus = false;
                this.isInsuredInfoStatus = false;
                this.isClearanceStatus = false;
                this.isSubmissionInfoStatus = false;
                this.isUnderwrittingAnalysisStatus = false;
                this.isCompareRateQuotesStatus = false;
                break;
            default:
                break;
        }
        console.log('##renderLWCByQuoteProcessStatus:' + status);
    }

    updateQPFields(fields, isCreateMode) {
        const recordInput = { fields };
        updateRecord(recordInput)
            .then((record) => {
                    //Added by Vinayesh- Navigate to Opportunity page if Opp Id available. Only for PCC
                    let currSubmission = record.fields.Submission__c.value;
                    console.log('vinay change quote redirect status: ' + record.fields.Status__c.value)
                    if(this.productName == PCC_PRODUCT_NAME && currSubmission &&
                        this.recordId != currSubmission){
                            this[NavigationMixin.Navigate]({
                                type: 'standard__recordPage',
                                attributes: {
                                    recordId: currSubmission,
                                    objectApiName: 'Opportunity',
                                    actionName: 'view'
                                }
                            });
                    }
                    else if(this.productName == PCC_PRODUCT_NAME){
                        if(record.fields.Status__c.value == QUOTE_PROCESS_STATUS_QUOTE_VERSION_CONSOLE){
                            refreshApex(this.wireActivities);
                            refreshApex(this.quoteProcess);// Display fresh data in the form 
                        }
                        this.renderLWCByQuoteProcessStatus(fields[STATUS_FIELD.fieldApiName]);
                        //Commented by Vinayesh. Refresh doesnt seem necessary here.
                        // refreshApex(this.wireActivities);
                        // refreshApex(this.quoteProcess);// Display fresh data in the form                       
                    }
                    else{
                        
                        refreshApex(this.wireActivities);
                        refreshApex(this.quoteProcess);// Display fresh data in the form 
                        if (isCreateMode) this.modeCreateSubmission = true;
                        else{
                            this.renderLWCByQuoteProcessStatus(fields[STATUS_FIELD.fieldApiName]);
                            if(this.isAqueous && record.fields.Status__c.value == QUOTE_PROCESS_STATUS_INSURED_INFO && this.template.querySelector("c-insured-account-lwc") != null){
                                console.log('Call child method');
                                this.template.querySelector('c-insured-account-lwc').handleAccountDataRefresh();
                            }
                        }
                        this.handleRefreshSanctionWarningBanner();
                    }                   
            })
            .catch(error => {
                console.log('Error during update Quote Process :' + JSON.stringify(error));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error update Quote Process',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
            });

    }
    handleSubmissionSaveSuccess(event) {
        console.log('handleSubmissionSaveSuccess ' + JSON.stringify(event.detail));
        console.log('validRecordId ', this.validRecordId);
        console.log('recordId ', this.recordId);
        console.log('quoteProcessSubmissionId ', this.quoteProcessSubmissionId);
        refreshApex(this.wireActivities);
        refreshApex(this.quoteProcess);
    }
    handlerConfirmModal(event) {
        let status = event.detail.status;
        console.log("event.detail.status", JSON.stringify(event.detail.status))
        if (status == 'confirm') {
            updateAllQuoteToInProgress({ submissionId: this.quoteProcessSubmissionId }).then(
                data => {
                    if (data.isSuccess) {
                        this.isChangeQuoteToInProcess = false;
                        const fields = {};
                        fields[ID_FIELD.fieldApiName] = this.validRecordId;
                        fields[QUOTE_PROCESS_SUBMISSION_ID.fieldApiName] = this.quoteProcessSubmissionId;
                        fields[STATUS_FIELD.fieldApiName] = this.nextStatus;
                        this.updateQPFields(fields, false);
                    } else {
                        // this.dispatchEvent(
                        //     new ShowToastEvent({
                        //         title: 'Error update Quote Status',
                        //         message: JSON.stringify(data.errors),
                        //         variant: 'error',
                        //     }),
                        // );
                        console.log('updateAllQuoteToInProgress ', JSON.stringify(data.errors));
                    }
                }
            )
                .catch(error => {
                    console.log('Error during update Quote Status :' + JSON.stringify(error));
                    // const fields = {};
                    // fields[ID_FIELD.fieldApiName] = this.validRecordId;
                    // fields[QUOTE_PROCESS_SUBMISSION_ID.fieldApiName] = this.quoteProcessSubmissionId;
                    // fields[STATUS_FIELD.fieldApiName] = this.prevStatus;
                    // this.updateQPFields(fields,false);
                    // this.dispatchEvent(
                    //     new ShowToastEvent({
                    //         title: 'Error update Quote Status',
                    //         message: error.body.message,
                    //         variant: 'error',
                    //     }),
                    // );
                });
        }
        if (status == 'cancel') {
            this.isChangeQuoteToInProcess = false;
            console.log('this.prevStatus when cancel', JSON.stringify(this.prevStatus));
            const fields = {};
            fields[ID_FIELD.fieldApiName] = this.validRecordId;
            fields[QUOTE_PROCESS_SUBMISSION_ID.fieldApiName] = this.quoteProcessSubmissionId;
            fields[STATUS_FIELD.fieldApiName] = QUOTE_PROCESS_STATUS_COMPARE_RATE_QUOTES;
            this.updateQPFields(fields, false);
        }

    }
    async handlepathassistantevent(event) {
        // if((this.isAqueous || this.isPCC) && this.quoteComingThroughEvent){
        //     this.quoteComingThroughEvent = false;
        // }
        //To stop quote creation on click of compare and rate quote for celerity as well.
        this.quoteComingThroughEvent = false;
        var isSelectedTab = event.detail.selectedvalue;
        var lastStepLabel = event.detail.lastStepLabel;
        this.isSelectedTab = isSelectedTab;
        console.log('inside pathassistance ==>', lastStepLabel);
        console.log("isSelectedTab-->",isSelectedTab);
        //  console.log('lastStepLabel==>',json.stringify(this.template.querySelector("c-quote-comparison-main-lwc")));
        //Added by Vinayesh: Clearance tab check.
        if (isSelectedTab == 'Insured Info' || isSelectedTab == 'Submission Console' || isSelectedTab == 'Underwriting Console' || isSelectedTab == 'Submission Info' || isSelectedTab == 'Underwritting Analysis' || isSelectedTab == 'Compare & Rate Quotes' || isSelectedTab == 'pathAssistant_selectAClosedStepValue') {
            console.log("441");
            if (this.template.querySelector("c-insured-account-lwc") != null) {
                this.isReadyToSave = this.template.querySelector("c-insured-account-lwc").saveAccount();
                if (!this.isReadyToSave) {
                    return;
                }
            }
            else {
                this.isReadyToSave = true;
            }

            //Added by Vinayesh. Need to check again whether handleSave returns status.
            if (this.template.querySelector("c-submission-console-lwc") != null) {
                console.log("454");
                this.isReadyToSave = await this.template.querySelector("c-submission-console-lwc").handleSaveOnNavigate();
                if(this.isReadyToSave && isSelectedTab == 'pathAssistant_selectAClosedStepValue'){
                    this.isReadyToSave = await this.checkRatingModifiersValidity();
                    if(!this.isReadyToSave){
                        this.dispatchEvent(ShowToastEvent({
                            "title": "Navigation to Quote Console prohibited",
                            "message": 'Please update mandatory fields on Underwriting Console',
                            "variant": "error"
                        }))
                    }
                }
                if (!this.isReadyToSave) {
                    return;
                }
                //Temporary for PCC. Refactor needed.
                else if(isSelectedTab == 'Underwriting Console'){
                    const fields = {};
                    console.log('vinay record Id' + this.validRecordId);
                    fields[ID_FIELD.fieldApiName] = this.validRecordId;
                    fields[STATUS_FIELD.fieldApiName] = QUOTE_PROCESS_STATUS_PRE_SCREENING;
                    //this.updateQPFields(fields, false);
                }
            }
            else {
                this.isReadyToSave = true;
            }

            //Added by Vinayesh. Need to check again whether handleSave returns status.

            //commented by Vinay. Prevent save of clearance on path change
            if (this.template.querySelector("c-clearance-lwc") != null) {
                console.log("454");
                this.isReadyToSave = await this.template.querySelector("c-clearance-lwc").handleSave();
                if (!this.isReadyToSave) {
                    return;
                }
            }
            else {
                this.isReadyToSave = true;
            }
            this.isReadyToSave = true;

            if (this.template.querySelector("c-submission-info-lwc") != null) {
                console.log("465");
                this.isReadyToSave = this.isReadyToSave = await this.template.querySelector("c-submission-info-lwc").handleSave();
                if (!this.isReadyToSave) {
                    return;
                }
            }
            else {
                this.isReadyToSave = true;
            }
            if (this.template.querySelector("c-underwritting-analysis-lwc") != null) {
                console.log("475");
                this.isReadyToSave = this.template.querySelector("c-underwritting-analysis-lwc").updateUnderwrittingTab();
                if (!this.isReadyToSave) {
                    return;
                }
            }
            else {
                this.isReadyToSave = true;
            }

            /*  if(this.template.querySelector("c-quote-comparison-main-lwc")!= null){
                  this.isReadyToSave = this.template.querySelector("c-quote-comparison-main-lwc").updateQuoteComparesionResponse();
                  if(!this.isReadyToSave){
                      return;
                      }
              }
              else{
                  this.isReadyToSave = true;  
              } */

        }
        /* else if(isSelectedTab =='Submission Info'){
              if(this.template.querySelector("c-insured-account-lwc") != null){
                  this.isReadyToSave = this.template.querySelector("c-insured-account-lwc").saveAccount();
                  if(!this.isReadyToSave){
                      return;
                      }
              }
              else{
                  this.isReadyToSave = true;  
              }
          }
          else if(isSelectedTab =='Underwritting Analysis'){
              console.log('json:',JSON.stringify(this.template.querySelector("c-insured-account-lwc")));
              if(this.template.querySelector("c-insured-account-lwc") != null){
                  this.isReadyToSave = this.template.querySelector("c-insured-account-lwc").saveAccount();
                  if(!this.isReadyToSave){
                      return;
                      }
              }
              else{
                  this.isReadyToSave = true;  
              }
              console.log('json:',JSON.stringify(this.template.querySelector("c-submission-info-lwc")));
              if(this.template.querySelector("c-submission-info-lwc")!= null){
                this.isReadyToSave =  this.template.querySelector("c-submission-info-lwc").handleSave();
              // isReadyToSave ?  this.renderLWCByQuoteProcessStatus(isSelectedTab) :this.renderLWCByQuoteProcessStatus(QUOTE_PROCESS_STATUS_SUBMISSION_INFO);
              if(!this.isReadyToSave){
              return;
              }
          }
              else{
                  this.isReadyToSave = true;  
              }
              
          }
          else if(isSelectedTab =='Compare & Rate Quotes' || isSelectedTab =='pathAssistant_selectAClosedStepValue'){
              //isSelectedTab =='pathAssistant_selectAClosedStepValue'
              
              if(this.template.querySelector("c-insured-account-lwc") != null){
                  this.isReadyToSave =   this.template.querySelector("c-insured-account-lwc").saveAccount();
                  if(!this.isReadyToSave){
                      return;
                      }
              }
              else{
                  this.isReadyToSave = true;  
              }
              if(this.template.querySelector("c-submission-info-lwc")!= null){
                  this.isReadyToSave =  this.isReadyToSave = this.template.querySelector("c-submission-info-lwc").handleSave();
                  if(!this.isReadyToSave){
                      return;
                      }
              }
              else{
                  this.isReadyToSave = true;  
              }
              if(this.template.querySelector("c-underwritting-analysis-lwc")!= null){
                  this.isReadyToSave = this.template.querySelector("c-underwritting-analysis-lwc").updateUnderwrittingTab();
                  if(!this.isReadyToSave){
                      return;
                      }
             // this.template.querySelector("c-underwritting-analysis-tab-lwc").saveRecord();
              }
              else{
                  this.isReadyToSave = true;  
              }
             }*/

        if (this.isReadyToSave) {
            console.log("565");
            console.log('ready: '+this.isReadyToSave);
            this.template.querySelector("c-path-assistant-lwc")._setCurrentScenario();
            var currentStatus = (isSelectedTab === OPEN_MODAL_TO_SELECT_CLOSED_STEP) ? lastStepLabel : isSelectedTab;
            this.template.querySelector("c-path-assistant-lwc")._updateRecord(currentStatus);
            this.isReadyToSave = false;
        }

    }

    handleRefreshSanctionWarningBanner(){
        this.template.querySelector("c-u-w-sanction-warning-message-component-l-w-c").handleRefreshSanctionWarningMessage();
    }

    /***** New Code 26/04/2022 *******/
    handleSanctionOnInusredAccountUpdate(event){
        console.log('handleSanctionOnInusredAccountUpdate');
        console.log('event.detail'+event.detail);
        this.template.querySelector("c-u-w-sanction-warning-message-component-l-w-c").handleSanctionWarningStatusCheck(event.detail);
    }
    /***** New Code Ended 26/04/2022 *******/

    async checkRatingModifiersValidity() {
        var isRatingValid = false;
        await checkRatingModifiersValidityForOpp({ opportunityId: this.quoteProcessSubmissionId })
                .then((data) => {
                    isRatingValid = data;
                })
                .catch((error) => {
                    isRatingValid = false;
                    this.dispatchEvent(ShowToastEvent({
                        "title": "Error",
                        "message": error.message,
                        "variant": "error"
                    }))
                });
        return isRatingValid;
    }

    /**
     * Using this event handler for navigating next from submission console.
     * @param {*} event 
     */
    navigatenext(event){
        // var currOppId = event.detail.oppId;
        // this.template.querySelector("c-path-assistant-lwc")._setCurrentScenario();
        // var currentStatus = event.detail.status;
        // this.template.querySelector("c-path-assistant-lwc")._updateRecord(currentStatus)
        // .then(() => {
        //     if(this.productName = PCC_PRODUCT_NAME && currOppId != this.recordId){
        //         this[NavigationMixin.Navigate]({
        //             type: 'standard__recordPage',
        //             attributes: {
        //                 recordId: currOppId,
        //                 objectApiName: 'Opportunity',
        //                 actionName: 'view'
        //             }
        //         });
        //     }
        // })

        refreshApex(this.wireActivities);
        var currOppId = event.detail.oppId;
        if(this.productName = PCC_PRODUCT_NAME && currOppId != this.recordId){
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: currOppId,
                    objectApiName: 'Opportunity',
                    actionName: 'view'
                }
            });
        }
    
    }

    handleRefreshComponent(event){
        //console.log('inside refresh',event.detail.selectedvalue);
        console.log('inside refresh 1' );
        if (this.template.querySelectorAll("c-underwritting-analysis-tab-lwc") != null) {
            console.log(' not NULL');
            //this.template.querySelector("c-underwritting-analysis-tab-lwc").refreshUnderwritterAnalysis();
            if (this.template.querySelectorAll("c-underwritting-analysis-lwc") != null) {
                this.isReadyToSave = this.template.querySelector("c-underwritting-analysis-lwc").updateUnderwrittingTab();
            }
            
        }else{
            console.log('NULL');
        }
           // this.template.querySelector("c-underwritting-analysis-tab-lwc").refreshUnderwritterAnalysis();
           // this.template.querySelector("c-underwritting-analysis-tab-lwc").saveRecord();
           
    }

}