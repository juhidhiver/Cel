import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { updateRecord } from 'lightning/uiRecordApi';
import getRatingModifiersForRiskHealth from '@salesforce/apex/OpportunityModifiersCmpController.getRatingModifiersForRiskHealth';
import updateStageAndPopulateFieldsLwc from '@salesforce/apex/OpportunityModifiersCmpController.updateStageAndPopulateFieldsLwc';
import checkProceedtoQuote from '@salesforce/apex/OpportunityModifiersCmpController.checkProceedtoQuote';
import getMasterBinders from '@salesforce/apex/OpportunityModifiersCmpController.getMasterBinders';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import CustomLocalCss from '@salesforce/resourceUrl/CustomLocalCss';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import getSubmissionDetails from '@salesforce/apex/OpportunityModifiersCmpController.getSubmissionDetails';


export default class CheckRiskHealthLwc extends NavigationMixin(LightningElement) {
    @api productName;
    @track isLoading = false;
    @track quoteLayer;
    @api _opportunityId;
    @track data = [];
    @track bindersList = [];
    @track originalBindersList = [];
    @track showBinderDialog = false;
    @track selectedBinder;
    @track isDisableButton = false;
    @track columns = [
        { label: 'Rating Factor', fieldName: 'Name', type: 'text', editable: false },
        { label: 'Value', fieldName: 'Rating_Modifier_Value__c', type: 'text', editable: false },
        {
            label: 'Suggestion', fieldName: 'Eligibility_Status__c', type: 'text', editable: false,
            cellAttributes: {
                class: { fieldName: 'showClass' } // textColor is a class for each record
            }
        },
    ];    
    @track binderColumns = [        
        { label: 'Master Binder Name', fieldName: 'Name', type: "text" },
        { label: "Inception Date", fieldName: 'Inception_Date__c', type: "text" },
        { label: "Expiration Date", fieldName: 'Expiry_Date__c', type: "text" }        
       ];

    set opportunityId(value) {
        this._opportunityId = value;
        // console.log('@@@this.productName: ' + this.productName);
        getRatingModifiersForRiskHealth({ productName: this.productName, opportunityId: value })
            .then(data => {
                if (data) {
                    var dataJson = JSON.parse(JSON.stringify(data));
                    var test = 'Stop!Decline!';
                    dataJson.forEach(function (record) {
                        if (typeof record.Id != 'undefined') {
                            switch (record.Eligibility_Status__c) {
                                case 'Stop!Decline!':
                                    console.log('Stop decline');
                                    record.showClass = 'Stop';
                                    break;
                                case 'Proceed':
                                    record.showClass = 'Proceed';
                                    break;
                                case 'Proceed with Caution':
                                    record.showClass = 'Caution';
                                    break;
                                default: record.showClass = ''; break;
                            }
                            // record.showClass = record.Eligibility_Status__c === "Proceed" ? "Proceed" : "Caution";
                        }
                    });
                    this.data = dataJson;
                    console.log('@@@data: ' + JSON.stringify(dataJson));
                } else if (error) {
                    console.log('##error :' + JSON.stringify(error));
                }
            })
            .catch(error => {
                console.log('##error :' + JSON.stringify(error));
            })

    }
    @api
    get opportunityId() {
        return this._opportunityId;
    }
    // @wire(getRatingModifiersForRiskHealth, { productName: '$productName', opportunityId: '$opportunityId' })
    // wiredGetRatModForRiskHealth({error, data}) {
    //     if(data){
    //         var dataJson = JSON.parse(JSON.stringify(data));
    //         dataJson.forEach(function(record){ 
    //             if(typeof record.Id != 'undefined'){ 
    //                 record.showClass = record.Eligibility_Status__c === "Proceed" ? "Proceed" : "Caution";
    //             }
    //         });
    //         // data.map(record => {
    //         //     var textColor = record.Eligibility_Status__c === "Proceed" ? "Proceed" : "Caution";
    //         //     const result = JSON.parse(JSON.stringify(Object.assign(record, { textColor: textColor })));
    //         //     return result;
    //         // })
    //         this.data = dataJson;
    //         //this.data = data;
    //         console.log('@@@data: ' + JSON.stringify(this.data));
    //     }else if(error){
    //         console.log('##error :' + JSON.stringify(error));
    //     }
    // }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    proceedToQuote(event) {
        var scrollOptions = {
            left: 0,
            top: 0,
            behavior: 'smooth'
        }
        window.scrollTo(scrollOptions);
        var quoteLayer = event.target.value;
        const validatepage = new CustomEvent(
            "validatepage", {
            detail: quoteLayer,
        });
        this.dispatchEvent(validatepage);
    }

    createQuote(){
        var quoteLayer = this.quoteLayer;
        var selectedBinder = this.selectedBinder;
        console.log("quoteLayer-->",quoteLayer);
        console.log("SelectedBinder-->",JSON.stringify(selectedBinder));
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
                                detail: {quoteLayer,selectedBinder},
                            });
                            this.dispatchEvent(sendquotelayer);
                            this.dispatchEvent(new CustomEvent('changequoteprocessstatus'));
                        })
                        .catch(error => {
                            console.log('Error updating record quote process 222 :' + JSON.stringify(error));
                        });
                }
            })
            .catch(error => {
                console.log('Error check quote process :' + JSON.stringify(error));
            });
    }

    @api proceedToQuoteAfterValidation(quoteLayer) {
        this.quoteLayer = quoteLayer;
        if(this.productName == 'Professional Indemnity'){
            this.isLoading = true;
            getMasterBinders({ opportunityId: this._opportunityId })
                .then(result => {                
                    this.originalBindersList = result;      
                    this.bindersList = result;                
                    var bindList = [];
                    for(var i=0;i<this.result.length;i++){
                        if(this.result[i].Layer__c.includes(quoteLayer)){
                            bindList.push(this.result[i]);
                            console.log("Includes");
                        }
                    }
                    this.bindersList = bindList;
                    this.isLoading = false;
                    if(this.bindersList.length > 1 && this.productName == 'Professional Indemnity'){
                        this.showBinderDialog = true;
                    }else{       
                        if(this.bindersList.length == 1){
                            this.selectedBinder = this.bindersList[0];     
                            this.createQuote();
                        } 
                    }
                })
                .catch(error => {
                    console.log("Error-->",JSON.stringify(error));
                    this.isLoading = false;
                });    
        }else{
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
        console.log("Opp Id-->",this._opportunityId);

        getSubmissionDetails({ opportunityId: this._opportunityId })
        .then(result => {                                       
            let oppStage = result.submissionDetails.StageName;
            let prodName = result.submissionDetails.Product_Name__c; 
            console.log("stageName-->",oppStage);  
            console.log("isCelerityProduct-->",prodName);             
            if(prodName == 'Cyber Standalone' || prodName == 'MPL Standalone'){
                if(oppStage == 'Closed Won' || oppStage == 'Bound Pending' || oppStage == 'Declined'){
                    this.isDisableButton = true;
                }
            } 
        })

        Promise.all([
            loadStyle(this, CustomLocalCss),
        ])
            .then(() => {
                console.log('Files loaded.');
            })
            .catch(error => {
                console.log(error.body.message);
            });
            getMasterBinders({ opportunityId: this._opportunityId })
            .then(result => {                
                this.originalBindersList = result;      
                this.bindersList = result;                
                console.log('Binders-->:' + JSON.stringify(result));
            })
            .catch(error => {
                console.log("Error-->",JSON.stringify(error));
            });
    }
    handleRowSelection(event){
        var selectedRows=event.detail.selectedRows;
        this.selectedBinder = selectedRows[0];
        console.log("selectedRows-->",JSON.stringify(this.selectedBinder));
    }
    closeBinderModal(){
        this.showBinderDialog = false;
        this.selectedBinder = '';
    }
}