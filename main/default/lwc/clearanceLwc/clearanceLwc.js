import { LightningElement, track, api, wire } from 'lwc';
import getProductId from "@salesforce/apex/ClearanceLwcController.getProductId";
import getAccountId from "@salesforce/apex/ClearanceLwcController.getAccountId";
import getSubmissionId from "@salesforce/apex/ClearanceLwcController.getSubmissionId";
import checkBoundSubmission from "@salesforce/apex/ClearanceLwcController.CheckBoundSubmission";
import checkProceedtoQuote from '@salesforce/apex/OpportunityModifiersCmpController.checkProceedtoQuote';
import updateStageAndPopulateFieldsLwc from '@salesforce/apex/OpportunityModifiersCmpController.updateStageAndPopulateFieldsLwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const QUOTE_PROCESS_STATUS_INSURED_INFO = 'Insured Info';
const QUOTE_PROCESS_STATUS_SUBMISSION_INFO = 'Submission Info';
const QUOTE_PROCESS_STATUS_SUBMISSION_CONSOLE = 'Submission Console';
const QUOTE_PROCESS_STATUS_QUOTE_CONSOLE = 'Quote Console';

export default class ClearanceLwc extends LightningElement {
    @api recordId;
    @api oppId;
    @track productId;
    accountId;
    @track isEditForm = true;
    @track error;
    selectedProduct;
    selectedProducts;
    originalMessage = '';
    showSpinner = false;
    @track isDialogVisible = false;
    @track boundDisabled = false;

    @wire(getProductId, { recordId: '$recordId' })
    getProductId({ error, data }) {
        if (data) {
            this.productId = data;
            console.log('vinay ' + this.productId);
            //Added by Vinayesh: Hardcoding only for testing. 
            if (!this.productId) {
                //this.productId = '01t250000044dpQAAQ';
            }

            console.log('vinay1 ' + this.productId);
        } else {
            console.log('error ' + JSON.stringify(error));
        }
    }

    @wire(getAccountId, { recordId: '$recordId' })
    getAccountId({ error, data }) {
        if (data) {
            this.accountId = data;
            console.log('vinay ' + this.accountId);
        } else {
            console.log('error ' + JSON.stringify(error));
        }
    }

    connectedCallback() {
        console.log('this.recordId:' + this.recordId);
        //alert('---OpportunityId--->>> '+this.oppId)
        this.fetchData();
    }

    renderedCallback() {
        if (this.oppId) {
            checkBoundSubmission({ oppId: this.oppId })
              .then((result) => {
                console.log('vinay check bound opp:' + result);
                this.boundDisabled = result;
                // if(result){
                //     this.template.querySelectorAll(".saveButton, .primaryButton, .excessButton").forEach(element => {
                //         console.log('vinay bound button:' + result);
                //         element.disabled = 'true';
                //  });
                // }
              });
          }
    }

    fetchData() {

        getSubmissionId({
            recordId: this.recordId
        })
            .then((result) => {
                //tuan.d.nguyen added 24-Jun-2020
                console.log('getSubmissionId');
                this.oppId = result;
                console.log('vinay opp ' + this.oppId);
                if (!this.oppId) {
                    // this.oppId = '0062500000NE1XxAAL';
                }
            })
            .catch((error) => {
                console.log('@@@error: ' + JSON.stringify(error));
            })
    }

    handleProductChange() {
        //this.template.querySelector("c-accordian-section-pcc-lwc").refreshView();
    }

    handelProductName(event) {
        return;
        console.log('---<<<eventName>>>--- ', event.detail);
        this.selectedProduct = event.detail;
        this.template.querySelector("c-clearance-l-w-c-page").handleSelectedProduct(this.selectedProduct);

    }

    //Commenting this method as the event removeproductname is not fired 
    /*handleRemoveProductName(event){
            
        this.selectedProduct = event.detail;
        this.template.querySelector("c-clearance-l-w-c-page").removeAllProductName(this.selectedProduct);
    }*/

    handleProductsSelected(event) {
        return;
        console.log('vinay event product ' + JSON.stringify(event.detail));
        this.selectedProducts = event.detail;
        this.template.querySelector("c-clearance-accordian-lwc").handleSelectedProduct(this.selectedProducts);
    }

    handleClick(event) {
        this.isDialogVisible = false;
    }

    handleNextButton(event) {
        //this.isDialogVisible = true;
        //Saving the Clearance data when the user is moving to Submission Info tab
        // let isValidated = this.handleSave();
        // console.log('vinay clearance next validity ' + isValidated);
        // if(!isValidated){
        //     return;
        // }
        // this.handleSave()
        // .then((result) => {
        //     if(result == true){
        //         var status = QUOTE_PROCESS_STATUS_SUBMISSION_INFO;
        //         console.log('vinay insured info ' + this.productName);

        //         var infos = { status: status, accountId: null};
        //         const nextEvent = new CustomEvent("changequoteprocessstatus", {
        //         detail: infos
        //         });
        //         this.dispatchEvent(nextEvent);
        //     }

        // });
    }


    handlePreviousButton(event) {
        //Saving the Clearance data when user navigates
        // let isValidated = this.handleSave();
        // console.log('vinay clearance previous validity ' + isValidated);
        // if(!isValidated){
        //     return;
        // }
        // var status = QUOTE_PROCESS_STATUS_INSURED_INFO;
        // var infos = { status: status };
        // const prevEvent = new CustomEvent('changequoteprocessstatus', {
        //     detail: infos
        // });
        // this.dispatchEvent(prevEvent);
        this.handleSave()
            .then((result) => {
                console.log('vinay prev button ' + result);
                if (result == true) {
                    var status = QUOTE_PROCESS_STATUS_SUBMISSION_CONSOLE;
                    var infos = { status: status };
                    const prevEvent = new CustomEvent('changequoteprocessstatus', {
                        detail: infos
                    });
                    this.dispatchEvent(prevEvent);
                }

            });
    }

    @api handleSave() {
        console.log('clicked on save');
        return this.template.querySelector("c-clearance-accordian-lwc").handleSave();
    }

    handleSaveButtonClick(){
       return this.template.querySelector("c-clearance-accordian-lwc").handleSaveButtonClick();
    }
    // Will be used to handle Quote Creation from Underwriter Console
    async handleQuoteCreation(event) {
        this.showSpinner = true;
        let quoteLayer = event.target.value
        console.log('quote Layer -->',quoteLayer)
        let isReadyToSave = await this.template.querySelector("c-clearance-accordian-lwc").handleSave();
        if(!isReadyToSave) {
            this.showSpinner = false;
            return;
        }
        
        checkProceedtoQuote({ opportunityId: this.oppId })
            .then(result => {
                console.log('resultcheck:' + JSON.stringify(result));
                if (result) {
                    if (!result.isSuccess) {
                        var errorMessage = result.errors.join(', ');
                        this.showToast("Error", errorMessage, "error");
                        //show messs
                        return;
                    }
                    if( quoteLayer == 'Primary' && result.data ){
                        var data = JSON.parse(result.data);
                        if( !data.isOppStateAllowed ){
                            var errorMessage = 'Primary Quote cannot be created for the seleted State.';
                            this.showToast("Error", errorMessage, "error");
                            //show messs
                            this.showSpinner = false;
                            return;
                        }
                    }
                    updateStageAndPopulateFieldsLwc({ opportunityId: this.oppId })
                    .then(result => {
                        this.showSpinner = false;
                        console.log('result:' + result);
                        let selectedBinder = null;
                        const sendquotelayer = new CustomEvent(
                            "sendquotelayer", {
                            detail: {quoteLayer,selectedBinder},
                        });
                        console.log('vinay change to quote layer: ' + quoteLayer);
                        this.dispatchEvent(sendquotelayer);
                        // var status = QUOTE_PROCESS_STATUS_QUOTE_CONSOLE;
                        // var infos = { status: status };
                        // this.dispatchEvent(new CustomEvent('changequoteprocessstatus', {
                        //     detail: infos
                        // }));
                        this.dispatchEvent(new CustomEvent('changequoteprocessstatustocomparerate'));
                    })
                }
                else{
                    this.showSpinner = false;
                }
                
            })
            .catch(error => {
                console.log('Error updating record quote process 222 :' + JSON.stringify(error));
                this.showToast("Error", error.message, "error");
            });
    }

    // Show toast message 
    
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}