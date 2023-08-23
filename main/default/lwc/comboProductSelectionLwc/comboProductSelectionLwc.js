import { LightningElement, api, wire, track } from 'lwc';
import getProductOptionLineItems from "@salesforce/apex/ComboProductSelectionLwcController.getProductOptionLineItems";
import checkClearanceForProduct from "@salesforce/apex/ComboProductSelectionLwcController.checkClearanceForProduct";
import checkClearanceForProducts from "@salesforce/apex/ComboProductSelectionLwcController.checkClearanceForProducts";
import saveProductOptionLine from "@salesforce/apex/ComboProductSelectionLwcController.saveProductOptionLine";
import saveProductOptionLines from "@salesforce/apex/ComboProductSelectionLwcController.saveProductOptionLines";
import deletePoliData from "@salesforce/apex/ComboProductSelectionLwcController.deletePoliData";
import getPicklistValues from '@salesforce/apex/InsureAccountController.getPicklistValues';
import checkAvailableClearedPoli from "@salesforce/apex/ComboProductSelectionLwcController.checkAvailableClearedPoli";
import deleteExistingRatingModifiers from "@salesforce/apex/ComboProductSelectionLwcController.deleteExistingRatingModifiers";
import getClearanceDetailsForPCC from '@salesforce/apex/AccountClearanceCallout.getClearanceDetailsForPCC';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// import {
//     subscribe,
//     unsubscribe,
//     APPLICATION_SCOPE,
//     MessageContext
// } from 'lightning/messageService';
// import refreshComponent from '@salesforce/messageChannel/refreshComponent__c';

const CLEARED_STATUS = 'Cleared';
const CLOSED_MARKET_STATUS = 'Closed Market';
const SERVICE_FAILURE_STATUS = 'Service failed';
const DandO_Product_Name = 'D&O';

export default class ComboProductSelectionLwc extends LightningElement {
    @api productId;
    @api oppId;
    @track wiredData;
    @track comboProducts;
    @track statusOptions = [];
    @track productStatus = null;
    @track productNotes = '';
    @track selectedRecord;
    @track selectedRecords = [];
    @track isModalOpen = false;
    @track showSpinner = false;
    isClearanceProcessing = false;
    isEventHandling = false;
    @api boundDisabled = false;

    // @wire(MessageContext)
    // messageContext;

    /**
     * Property to disable button when there are no new products selected for clearance.
     */
    get disableButton() {
        // let btnDisabled = true;
        // if (this.comboProducts) {
        //     for (let prod of this.comboProducts) {
        //         if (!prod.Status && prod.Selected) {
        //             btnDisabled = false;
        //         }
        //     }
        // }
        // return btnDisabled;
        return this.boundDisabled;
    }

    /**
     * Load component data.
     */
    @wire(getProductOptionLineItems, { parentProductId: '$productId', submissionId: '$oppId' })
    getComboProdLines(result) {
        this.showSpinner = true;
        this.wiredData = result;
        if (result.data) {

            const dataList = result.data;
            const newList = [];
            dataList.forEach(prod => {
                let tempRec = Object.assign({}, prod);
                tempRec.DisableCheckBox = false;
                if (prod.Status != CLEARED_STATUS && prod.Status) {
                    tempRec.DisableCheckBox = true;
                }

                //D&O checkbox always disabled
                if (prod.Name == DandO_Product_Name) {
                    tempRec.DisableCheckBox = true;
                }

                newList.push(tempRec);
            });
            this.comboProducts = newList;
            getPicklistValues({ objectName: 'Product_Option_Line_Item__c', fieldName: 'Clearance_Status__c', firstValue: null })
                .then(result => {
                    this.statusOptions = result;
                })
                .catch(error => {
                    console.log('clearance picklist error :' + JSON.stringify(error));
                });

            let checkedProducts = [];
            if (this.comboProducts) {
                for (let prod of this.comboProducts) {
                    if (prod.Selected && prod.Status == CLEARED_STATUS) {
                        checkedProducts.push(prod.Name);
                    }
                }
                const productsUpdatedEvent = new CustomEvent('productsselected', { detail: checkedProducts });
                this.dispatchEvent(productsUpdatedEvent);
            }

            //this.updateBadgeColor();
            this.showSpinner = false;

        } else {
            this.showSpinner = false;
            console.log('data load error ' + JSON.stringify(result.error));
        }
    }


    // subscribeToMessageChannel() {
    //     if (!this.subscription) {
    //         this.subscription = subscribe(
    //             this.messageContext,
    //             refreshComponent,
    //             (message) => this.handleMessage(message),
    //             { scope: APPLICATION_SCOPE }
    //         );
    //     }
    // }

    /**
     * Event handler for edit cleareance button click for user to modify clearance value.
     * @param {*} event 
     */
    handleEditClearanceButtonClick(event) {
        let tempRec = Object.assign({}, this.comboProducts[event.target.dataset.index]);
        this.selectedRecord = tempRec;
        // this.productNotes = tempRec.Notes;
        this.productStatus = tempRec.Status;
        this.isModalOpen = true;
    }
    closeModal() {
        this.isModalOpen = false;
    }
    submitDetails() {
        this.isModalOpen = false;
    }

    /**
     * Event handler to handle product checkbox toggle event.
     * @param {*} event 
     * @returns 
     */
    handleCheckboxChange(event) {

        if (this.isEventHandling) return;
        this.isEventHandling = true;

        let tempRec = this.comboProducts[event.target.dataset.index];
        if (event.target.checked) {
            tempRec.Selected = true;
        }
        else {
            tempRec.Selected = false;
        }

        if (tempRec.Status == CLEARED_STATUS) {
            let checkedProducts = [];
            for (let prod of this.comboProducts) {
                if (prod.Name == tempRec.Name) {
                    if (tempRec.Selected) {
                        checkedProducts.push(prod.Name);
                    }
                }
                else if (prod.Selected && prod.Status == CLEARED_STATUS) {
                    checkedProducts.push(prod.Name);
                }
            }

            const selectedEvent = new CustomEvent('productsselected', { detail: checkedProducts });
            this.dispatchEvent(selectedEvent);

        }
        //Need to check if productselected event needs to be raised after save.
        if (tempRec.RecordId) {
            let recordsToSave = [];
            recordsToSave.push(tempRec);
            this.saveRecords(recordsToSave);
        }
        this.isEventHandling = false;
    }


   

    /**
     * Method to perform clearance for checked process. Called from external component.
     * @returns 
     */
    @api
    processClearance() {

        if (this.selectedRecords.length == 0) {
            alert("Please select atleast one product for clearance.");
            return;
        }
        //Assign newly created OppId to pre selected products in Submission console page.
        for (let prod of this.selectedRecords) {

            prod.SubmissionId = this.comboProducts[0].SubmissionId;
            prod.AccountId = this.comboProducts[0].AccountId;
        }
        checkClearanceForProducts({ products: this.selectedRecords })
            .then((result) => {
                let tempRecords = result;
                for (let prod of tempRecords) {
                    if (prod.Status != CLEARED_STATUS) {
                        prod.Selected = false;
                    }
                    prod.ManualClearance = false;
                }
                this.saveRecords(tempRecords);
            })
            .catch((error) => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.message,
                    variant: 'error'
                }));
            });
    }

    clearanceProcessingError = false;
    declineProcessRunning = false;
    /**
      * API call to be made for Clearance check
     * @param none 
     */
    @api
    async processClearanceApi(addressChanged) {
        console.log('Is API called?')
        this.showSpinner = true;
        let addressChangedProds = [];
        if (this.clearanceProducts.length > 0) {
            for (let eachProd of this.comboProducts) {
                // this.selectedRecords.push(eachProd) 
                //this.selectedRecords = [{...this.selectedRecords, ...this.comboProducts}]
                for (let selProd of this.clearanceProducts) {
                    if (selProd == eachProd.Name) {
                        this.selectedRecords.push(eachProd);
                    }
                }
            }
        }
        else if (addressChanged) {
            this.declineProcessRunning = true;
            await this.declineAllProducts();
            this.showSpinner = true;
            for (let eachProd of this.comboProducts) {
                if (eachProd.RecordId) {
                    addressChangedProds.push(eachProd);
                    continue;
                }

                // this.selectedRecords.push(eachProd) 
                //this.selectedRecords = [{...this.selectedRecords, ...this.comboProducts}]
                for (let selProd of this.selectedRecords) {
                    if (!eachProd.RecordId && (selProd.Name == eachProd.Name)) {
                        addressChangedProds.push(eachProd);
                    }
                }
            }

            this.selectedRecords = addressChangedProds;
        }
        if (this.selectedRecords.length == 0) {
            this.dispatchEvent(new ShowToastEvent({
                message: 'Please select atleast one new product for clearance.',
                variant: 'error'
            }));
            //alert("Please select atleast one new product for clearance.");
            this.showSpinner = false;
            return;
        }

        //Assign newly created OppId to pre selected products in Submission console page.
        // for (let prod of this.selectedRecords) {

        //     prod.SubmissionId = this.comboProducts[0].SubmissionId;
        //     prod.AccountId = this.comboProducts[0].AccountId;

        // }

        console.log('vinay show spinner');
        this.isClearanceProcessing = true;
        // Get all Clearance response and then Update POLI records accordingly
        const promises = this.selectedRecords.map(async eachItem => {
            await getClearanceDetailsForPCC({ itemWrapper: eachItem })
                .then(response => {

                    eachItem.ManualClearance = false
                    // When we get Cleared as response
                    if (response.wasCleared == 'true' && response.isSuccess == true && response.isSuccessFromMRE == true) {
                        eachItem.Status = CLEARED_STATUS
                        eachItem.Selected = true
                        eachItem.ClearanceDate = response.clearanceDate
                    }
                    // When we get Closed Market as response
                    else if (response.wasCleared == 'false' && response.isSuccess == true && response.isSuccessFromMRE == true) {
                        eachItem.Status = CLOSED_MARKET_STATUS
                        eachItem.Selected = false
                    }
                    // In case of Service failure
                    else {
                        eachItem.Status = SERVICE_FAILURE_STATUS
                        eachItem.Selected = false
                    }

                })
                .catch(error => {
                    this.showSpinner = false;
                    this.isClearanceProcessing = false;
                    this.clearanceProcessingError = true;
                    console.error(error);
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'MRE clearance call failed. Please try again',
                        message: error.message,
                        variant: 'error'
                    }));
                })


        })
        await Promise.all(promises)

        // Save POLI records
        if(!this.clearanceProcessingError) await this.saveRecords(this.selectedRecords)
        this.clearanceProcessingError = false;
        this.showSpinner = false;
        this.isClearanceProcessing = false;

    }



    /**
     * Method to save batch of records.
     * @param {*} currRecords 
     */
    async saveRecords(currRecords) {
        this.showSpinner = true;
        await saveProductOptionLines({ records: currRecords })
            .then((result) => {
                if(!this.declineProcessRunning){
                    let checkedProducts = [];
                    for (let prod of currRecords) {
                        if (prod.Selected) {
                            checkedProducts.push(prod.Name);
                        }
                    }
                    //If there are no checked products we are just passing empty list.
                    const selectedEvent = new CustomEvent('productsselected', { detail: checkedProducts });
                    this.dispatchEvent(selectedEvent);
                    // this.showSpinner = true;
                    refreshApex(this.wiredData);
                    this.clearanceProducts = [];
                    //this.showSpinner = false;
                }
                else{
                    this.declineProcessRunning = false;
                }
                
            })
            .catch((error) => {
                //this.error = error;
                console.log('error clearance: ', error);
                this.showSpinner = false;
            });
    }


    handleStatusPicklistChange(event) {
        let prodStatus = event.target.value;
        this.selectedRecord.Status = prodStatus;
        if (prodStatus == 'Cleared') {
            this.selectedRecord.Selected = true;
            this.selectedRecord.ManualClearance = true;
        }
        else {
            this.selectedRecord.Selected = false;
            this.selectedRecord.ManualClearance = true;
        }

        let recordsToSave = [];
        recordsToSave.push(this.selectedRecord);
        this.saveRecords(recordsToSave);
        this.isModalOpen = false;
    }


    //This method also only for testing. Needs to go.
    @track hasRendered1 = false;
    connectedCallback() {
        if (!this.hasRendered1) {
            this.hasRendered1 = true;

            this.showSpinner = true;
            refreshApex(this.wiredData);
            //this.refresh();
        }
    }

    //Using this method to pass list of checked products on load of page. 
    //Wont be needing it if we implement deleting of rating modifiers on uncheck and save.
    @track hasRendered = false;
    renderedCallback() {
        this.updateBadgeColor();
        this.setComponentEnabled();
        if (!this.hasRendered) {
            //this.subscribeToMessageChannel();
            let checkedProducts = [];
            if (this.comboProducts) {
                for (let prod of this.comboProducts) {
                    if (prod.Selected && prod.Status == CLEARED_STATUS) {
                        checkedProducts.push(prod.Name);
                    }
                }
                this.hasRendered = true;
                const selectedEvent = new CustomEvent('productsselected', { detail: checkedProducts });
                this.dispatchEvent(selectedEvent);
                this.showSpinner = false;
            }

        }
    }

    updateBadgeColor() {
        this.template.querySelectorAll("lightning-badge").forEach(element => {
            if (element.classList.contains('slds-theme_error')) {
                element.classList.remove('slds-theme_error');
            }
            if (element.classList.contains('slds-theme_warning')) {
                element.classList.remove('slds-theme_warning');
            }
            if (element.getAttribute('data-manual-clearance') == 'true') {
                element.classList.add('slds-theme_warning');
            }
			if (element.getAttribute('data-status') == 'Decline') {
				element.classList.add('slds-theme_error');
			}
        });
    }

    setComponentEnabled() {
        if(this.boundDisabled){
            this.template.querySelectorAll(".cmpContainer").forEach(element => {
                element.classList.add('bound-disabled');
            });
        }
    }

    handleMessage(message) {
        this.refreshView();
    }

    @api
    focusComponent() {
        this.template.querySelector("lightning-button").focus();
    }

    /**
     * Reload component.
     */
    @api
    refreshView() {
        this.showSpinner = true;
        refreshApex(this.wiredData);
        //this.showSpinner = false;
    }
    /**
    * Check if Poli data available for submission
    */
    @api
    async checkPoliAvailable() {
        let poliAvailable = false;
        await checkAvailableClearedPoli({ submissionId: this.oppId })
            .then((result) => {
                poliAvailable = result;
            })
            .catch((error) => {
                //this.error = error;
                console.log('vinay clearance' + error);
            });

        return poliAvailable;
    }


    clearanceProducts = [];
    /**
    * Hold products that have clearance processed before account changed.
    */
    @api
    populateClearanceCompletedProducts() {
        for (let prod of this.comboProducts) {
            if (prod.Status) {
                this.clearanceProducts.push(prod.Name);
            }
        }
    }

      /**
    * Set status of all products to 'Decline'
    */
       @api
       async declineAllProducts() {
           let declinedProducts = []
           for (let origProd of this.comboProducts) {
                let prod = Object.assign({}, origProd);
                if (prod.Status && prod.Status != 'Decline') {
                    prod.Status = 'Decline';
                    prod.Selected = false;
                    declinedProducts.push(prod);
                }           
           }
           if(declinedProducts.length > 0){
               await this.saveRecords(declinedProducts);
           }
		   this.showSpinner = false;         
       }

  










/*********Not using these methods currently **********/

	 //Method to check clearance per product. Not using it for now.
	 checkClearance(currRecord) {
        this.showSpinner = true;
        let clearanceStatus = '';
        checkClearanceForProduct({ record: JSON.stringify(currRecord) })
            .then((result) => {
                currRecord.Status = result;
                if (currRecord.Status != CLEARED_STATUS) {
                    currRecord.Selected = false;
                }
                this.saveRecord(currRecord);
                this.showSpinner = false;
            })
            .catch((error) => {
                //this.error = error;
                //this.contacts = undefined;
                this.showSpinner = false;
            });
        return clearanceStatus;
    }


    //Method to save single record at a time.
    saveRecord(currRecord) {
        this.showSpinner = true;
        saveProductOptionLine({ record: JSON.stringify(currRecord) })
            .then((result) => {
                this.showSpinner = true;
                refreshApex(this.wiredData);
                this.showSpinner = false;
                //return result;
            })
            .catch((error) => {
                //this.error = error;
                this.showSpinner = false;
            });
    }

	  // Method to delete POli data for current Opportunity. Just for testing
	  refresh() {
        deletePoliData({ submissionId: this.oppId })
            .then((result) => {
                let checkedProducts = [];
                const selectedEvent = new CustomEvent('productsselected', { detail: checkedProducts });
                this.dispatchEvent(selectedEvent);
                refreshApex(this.wiredData);
            })
            .catch((error) => {
                //this.error = error;
            });
    }

	 /**
     * Method to check clearance for selected products.
     * @param {*} event 
     * @returns 
     */
	  handleMreClearance(event) {
        this.selectedRecords = [];
        for (let prod of this.comboProducts) {
            if (prod.Selected && !prod.Status) {
                this.selectedRecords.push(prod);
            }
        }

        const validateClearance = new CustomEvent('validateclearance');
        this.dispatchEvent(validateClearance);
        return;
        // if(this.selectedRecords.length > 0){
        //     // if(!this.oppId || this.oppId == ''){
        //         const validateClearance = new CustomEvent('validateclearance');
        //         this.dispatchEvent(validateClearance);
        //         return;
        //     // }
        //     //this.processClearance();
        // }  

    }

}