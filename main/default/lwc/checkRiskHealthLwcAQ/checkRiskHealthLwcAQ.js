import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { updateRecord } from 'lightning/uiRecordApi';
import getWarningsForRiskHealth from '@salesforce/apex/UWAnalysisSectionController.getWarningsForRiskHealth';
import updateStageAndPopulateFieldsLwc from '@salesforce/apex/OpportunityModifiersCmpController.updateStageAndPopulateFieldsLwc';
import checkProceedtoQuote from '@salesforce/apex/OpportunityModifiersCmpController.checkProceedtoQuote';
import getMasterBinders from '@salesforce/apex/OpportunityModifiersCmpController.getMasterBinders';
import getOpportunityDetails from '@salesforce/apex/OpportunityModifiersCmpController.getOpportunityDetails';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import CustomLocalCss from '@salesforce/resourceUrl/CustomLocalCss';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import checkExistingQuote from '@salesforce/apex/OpportunityModifiersCmpController.checkExistingQuote';
//import warning_icon from '@salesforce/resourceUrl/warning_icon';

export default class CheckRiskHealthLwcAQ extends NavigationMixin(LightningElement) {
    @api productName;
    @api disablePrimary;
    @api disableExcess;
    @track quoteLayer;
    @track isLoading = false;
    @api _opportunityId;
    @track data = [];
    @track bindersList = [];
    @track showBinderDialog = false;
    @track showWarningDialog = false;
    @track selectedBinder;
    @track noWarnings = false;
    @track accountCountry;
    disableProceedToQuote = false;
    disableBackToAnalysis = false;
    @track columns = [
        {
            label: 'Work Type Selected', fieldName: 'Work_Type__c', type: 'text', editable: false,
            initialWidth: 200, wrapText: true
        },
        {
            label: 'Warnings', fieldName: 'Warning_Text__c', type: 'text', editable: false, wrapText: true,
            cellAttributes: { iconName: 'utility:warning' }
        }
    ];
    @track binderColumns = [
        { label: 'Master Binder Name', fieldName: 'Name', type: "text" },
        { label: "Inception Date", fieldName: 'Inception_Date__c', type: "text" },
        { label: "Expiration Date", fieldName: 'Expiry_Date__c', type: "text" }
    ];

    //Adding for checking Rateable exposure value when Check Risk Health is clicked - Bug CD-84
    @api mainSectionWraps = [];
    @api
    get opportunityId() {
        return this._opportunityId;
    }
    set opportunityId(value) {
        this._opportunityId = value;
        // console.log('@@@this.productName: ' + this.productName);
        getWarningsForRiskHealth({ productName: this.productName, opportunityId: value })
            .then(data => {
                if (data) {
                    var dataJson = JSON.parse(JSON.stringify(data));
                    dataJson.forEach(function (record) {
                        if (typeof record.Id != 'undefined') {
                            record.showClass = '';
                            if (record.Work_Type__c == '') {
                                record.Work_Type__c = 'All';
                            }
                        }
                    });
                    this.data = dataJson;
                    console.log('@@@warninglist: ' + JSON.stringify(dataJson));
                    //Removing ratebale exposure warning if value entered by user is already more than 0 starts
                    //Bug CD-84 starts
                    let removeRateableExposureError = false;
                    this.mainSectionWraps.forEach(mainSecWrap => {
                        mainSecWrap.items.forEach(obj => {
                            if (obj.item.Name == 'Rateable Exposure') {
                                if (obj.item.Rating_Modifier_Value__c > 0) {
                                    removeRateableExposureError = true;
                                }
                            }
                        })
                    });
                    let indexOf = -1;
                    for (let i = 0; i < this.data.length; i++) {
                        if (this.data[i].Warning_Text__c === 'Rateable Exposure is £0 - is this correct?') {
                            indexOf = i;
                        }
                    }
                    if (removeRateableExposureError && indexOf > -1) {
                        this.data.splice(indexOf, 1);
                    }
                    //Bug CD-84 ends
                    //Removing ratebale exposure warning if value entered by user is already more than 0 ends
                    if (this.data.length === 0) {
                        this.noWarnings = true;
                    }
                } else if (error) {
                    console.log('##error :' + JSON.stringify(error));
                }
            })
            .catch(error => {
                console.log('##error :' + JSON.stringify(error));
            })

    }
    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    newQuoteLayer;

    warningModal(event) {
        this.newQuoteLayer = event.target.value;
        checkExistingQuote({ opportunityId: this._opportunityId, layer: this.newQuoteLayer })
            .then(data => {
                console.log('quote list size - > ' + data);
                if (data.length == 0) {
                    this.proceedToQuote(event);
                } else {
                    this.showWarningDialog = true;
                }
            });

    }

    proceedToQuote(event) {
        this.showWarningDialog = false;
        this.disableBackToAnalysis = true;
        this.disablePrimary = true;
        this.disableExcess = true;
        var scrollOptions = {
            left: 0,
            top: 0,
            behavior: 'smooth'
        }
        window.scrollTo(scrollOptions);
        var quoteLayer = event.target.value;
        console.log('quoteLayer::' + quoteLayer)
        const validatepagenew = new CustomEvent(
            "validatepagenew", {
            detail: this.newQuoteLayer,
        });
        this.dispatchEvent(validatepagenew);
    }

    createQuote() {
        this.disableProceedToQuote = true;
        if (this.productName == 'Professional Indemnity') {
            if (this.selectedBinder == '' || this.selectedBinder == undefined || this.selectedBinder == null) {
                this.disableProceedToQuote = false;
                this.showToast("Error", "Please select Binder", "error");
                return;
            }
        }
        var quoteLayer = this.quoteLayer;
        var selectedBinder = this.selectedBinder;
        console.log("quoteLayer-->", quoteLayer);
        console.log("SelectedBinder-->", JSON.stringify(selectedBinder));
        checkProceedtoQuote({ opportunityId: this.opportunityId })
            .then(result => {
                console.log('resultcheck:' + JSON.stringify(result));
                if (result) {
                    if (!result.isSuccess) {
                        var errorMessage = result.errors.join(', ');
                        this.showToast("Error", errorMessage, "error");
                        //show messs
                        return;
                    }
                    updateStageAndPopulateFieldsLwc({ opportunityId: this.opportunityId })
                        .then(result => {
                            console.log('result:' + result);
                            const sendquotelayer = new CustomEvent(
                                "sendquotelayer", {
                                detail: { quoteLayer, selectedBinder },
                            });
                            this.dispatchEvent(sendquotelayer);
                            this.dispatchEvent(new CustomEvent('changequoteprocessstatus'));
                        })
                        .catch(error => {
                            this.disableProceedToQuote = false;
                            console.log('Error updating record quote process 222 :' + JSON.stringify(error));
                        });
                }
            })
            .catch(error => {
                this.disableProceedToQuote = false;
                console.log('Error check quote process :' + JSON.stringify(error));
            });
    }

    @api proceedToQuoteAfterValidation(quoteLayer) {
        this.quoteLayer = quoteLayer;
        if (this.productName == 'Professional Indemnity') {
            this.isLoading = true;
            getMasterBinders({ opportunityId: this._opportunityId })
                .then(result => {
                    if (result.length == 0) {
                        this.showToast("Error", "No Binders to Map with the Quote", "error");
                        return;
                    }
                    this.originalBindersList = result;
                    this.bindersList = result;
                    var bindList = [];
                    for (var i = 0; i < this.originalBindersList.length; i++) {
                        if (this.originalBindersList[i].Layer__c.includes(quoteLayer)) {
                            bindList.push(this.originalBindersList[i]);
                            console.log("Includes");
                        }
                    }
                    this.bindersList = bindList;
                    this.isLoading = false;
                    if (this.bindersList.length > 1 && this.productName == 'Professional Indemnity') {
                        this.showBinderDialog = true;
                    } else {
                        if (this.bindersList.length == 1) {
                            this.selectedBinder = this.bindersList[0];
                            this.createQuote();
                        }
                    }
                })
                .catch(error => {
                    console.log("Error-->", JSON.stringify(error));
                    this.isLoading = false;
                });
        } else {
            this.createQuote();
        }
        console.log({ quoteLayer });
        // checkProceedtoQuote({ opportunityId: this.opportunityId })
        //     .then(result => {
        //         console.log('resultcheck:' + JSON.stringify(result));
        //         if (result) {
        //             if (!result.isSuccess) {
        //                 var errorMessage = result.errors.join(', ');
        //                 this.showToast("Error", errorMessage, "error");
        //                 //show messs
        //                 return;
        //             }
        //             updateStageAndPopulateFieldsLwc({ opportunityId: this.opportunityId })
        //                 .then(result => {
        //                     console.log('result:' + result);
        //                     const sendquotelayer = new CustomEvent(
        //                         "sendquotelayer", {
        //                         detail: quoteLayer,
        //                     });
        //                     this.dispatchEvent(sendquotelayer);
        //                     this.dispatchEvent(new CustomEvent('changequoteprocessstatus'));
        //                 })
        //                 .catch(error => {
        //                     console.log('Error updating record quote process 222 :' + JSON.stringify(error));
        //                 });
        //         }
        //     })
        //     .catch(error => {
        //         console.log('Error check quote process :' + JSON.stringify(error));
        //     });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }


    connectedCallback() {
        console.log("Opp Id-->", this._opportunityId);
        Promise.all([
            loadStyle(this, CustomLocalCss),
        ])
            .then(() => {
                console.log('Files loaded.');
            })
            .catch(error => {
                console.log(error.body.message);
            });
        getOpportunityDetails({ opportunityId: this._opportunityId })
            .then(result => {
                console.log('result-cc->:' + JSON.stringify(result));
                console.log('acc-cc->:' + JSON.stringify(result.Account.BillingCountry));
                this.accountCountry = result.Account.BillingCountry;

                // Added by Rinku Saini For CD-116
                if (result.StageName === 'Closed Lost') {
                    this.disablePrimary = true;
                    this.disableExcess = true;
                }
            })
            .catch(error => {
                console.log("Error-->", JSON.stringify(error));
            });
    }
    handleRowSelection(event) {
        var selectedRows = event.detail.selectedRows;
        this.selectedBinder = selectedRows[0];
        console.log("selectedRows-->", JSON.stringify(this.selectedBinder));
    }
    closeBinderModal() {
        this.showBinderDialog = false;
        this.selectedBinder = '';
        this.disableBackToAnalysis = false;
        this.disablePrimary = false;
        this.disableExcess = false;
    }

    closeWarningModal() {
        this.showWarningDialog = false;
        this.disableBackToAnalysis = false;
        this.disablePrimary = false;
        this.disableExcess = false;
    }
    closeMasterBinderModal(){
        this.showBinderDialog = false;
    }

}