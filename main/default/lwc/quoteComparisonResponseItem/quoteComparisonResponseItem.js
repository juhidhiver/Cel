import { LightningElement, api, wire, track } from 'lwc';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import FINALIZE_QUOTE_ICON from '@salesforce/resourceUrl/FinalizeQuoteIcon';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';

import QUOTE_OBJECT from '@salesforce/schema/Quote';
import CLOSED_REASON_FIELD from '@salesforce/schema/Quote.Closed_Reason__c';

import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getRatingFromCallOut from '@salesforce/apex/RateController.getRatingFromCallOut';
import finalizeQuote from '@salesforce/apex/FinalizeQuoteController.finalizeQuote';
import handleCloseReasons from '@salesforce/apex/FinalizeQuoteController.handleCloseReasons';
import updateQuoteInProgress from '@salesforce/apex/QuoteCompareItemWrapper.updateQuoteInProgress';
import updateSelectedBinder from '@salesforce/apex/QuoteCompareItemWrapper.updateSelectedBinder';
import bindQuoteWithBLInfo from '@salesforce/apex/BindQuoteController.bindQuoteWithBLInfo';
import bindQuote from '@salesforce/apex/BindQuoteController.bindQuote';
import getPayPlanOptions from '@salesforce/apex/BindQuoteController.getInitData'; 
import getInitData from '@salesforce/apex/BindQuoteController.getInitData';
import getQuoteDetails from '@salesforce/apex/FinalizeQuoteController.getQuoteDetails';
import generateDocId from '@salesforce/apex/GenerateQuoteDocumentController.generateDocId';
import getDocumentEncodeByQuoteId from '@salesforce/apex/ViewDocumentController.getDocumentEncodeByQuoteId';
import getDocumentEncodeByQuoteIdAQ from '@salesforce/apex/ViewDocumentController.getDocumentEncodeByQuoteIdAQ';
import checkSurplusLinesLicense from '@salesforce/apex/BindQuoteController.checkSurplusLinesLicense';
import getFactorSummarys from '@salesforce/apex/FactorSummaryController.getFactorSummarys';
import quoteDetails from '@salesforce/apex/FinalizeQuoteController.quoteDetails';
import getReferralReasons from '@salesforce/apex/FinalizeQuoteController.getReferralReasons';
import getMasterBindersFromQuote from '@salesforce/apex/OpportunityModifiersCmpController.getMasterBindersFromQuote';
import getPreBindDetails from '@salesforce/apex/BindQuoteController.getPreBindDetails';
import generateDocIdAQ from '@salesforce/apex/GenerateQuoteDocumentController.generateDocIdAQ';
import getBinder from '@salesforce/apex/GenerateQuoteDocumentController.getBinder';
import fetchMTAs from '@salesforce/apex/QuoteCompareItemWrapper.fetchMTAs';
import { updateRecord } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/Quote.Id';
import STATUS_FIELD from '@salesforce/schema/Quote.Status';
import checkPartFixedEndorsement from '@salesforce/apex/FinalizeQuoteController.checkPartFixedEndorsement';
import quoteDetailsFetch from '@salesforce/apex/BindService.fetchQuoteDetail';

import { refreshApex } from '@salesforce/apex';

export default class QuoteComparisonResponseItem extends NavigationMixin(LightningElement) {
    @api quoteName = '';
    @api quoteStatus;
    @api submissionObj;
    @api isAqueousProduct;
    @api quoteType;
    @api quoteUrl = '';
    @api quoteRatingStatus = '';
    @api isLoading = false;
    @api aggregateLimit;
    @api sublimitsAndEndorsements;
    @track modeEdit = true;
    @track isRateLoading = false;
    @api retentionVal;
    @api supplePaySelected = '10k / 10k';
    @api retroDate;
    @api isReadyToSave = false;
    @api quoteProcessSubmissionId;
    @track disableEndosementButton = false;
    //@api mainColumnWrapper;
    _compareItem;
    @api quoteId = '';
    @api prevQuoteValues = [];
    @track sortBy;
    @track sortDirection;
    finalizeQuoteIcon = FINALIZE_QUOTE_ICON;
    @track isQuotedClear;
    @api isQuotedStatus;
    @api isLockedQuote = false;
    @api isPrimaryQuote;

    @track showReferralReasonPopUp = false;
    @track referralReasonsList = [];

    @track selectedBroker;

    @track bindersList = [];
    @track showBinderDialog = false;
    @track selectedBinder;
    mtaQuote = false;
    @track binderColumns = [
        { label: 'Master Binder Name', fieldName: 'Name', type: "text" },
        { label: "Inception Date", fieldName: 'Inception_Date__c', type: "text" },
        { label: "Expiration Date", fieldName: 'Expiry_Date__c', type: "text" }
    ];
    @track referralReasonColumns = [
        { label: 'Approval Level Required', fieldName: 'ApprovalLevelRequired', type: "text", sortable: "true" },
        { label: "Reason Description", fieldName: 'Reason', type: "text", initialWidth: 400 },
        { label: "Approval Status", fieldName: 'ApprovalStatus', type: "text" },
        { label: "Approval/Rejected Date", fieldName: 'ApprovalRejectedDate', type: "date" },
        { label: "Approved By", fieldName: 'ApprovedBy', type: "text" },
        { label: "Reason Type", fieldName: 'ReasonType', type: "text" }
    ];

    @api setLeftPosition(value,) { // Duc - 5/8/2020
        var responseItem = this.template.querySelector(`[data-id="response-item"]`);
        if (value && responseItem) {
            var left = value + 13.625;
            responseItem.setAttribute('style', `left: ${left}px !important`);
        }
    }
    @api resizeHeaderStyle(value) {
        if (value) {
            var left = value + 13.625;
            var responseItem = this.template.querySelector(`[data-id="response-item"]`);
            var responseItemParent = this.template.querySelector(`[data-id="response-item-parent"]`);
            var responseItemChild = this.template.querySelectorAll(`[data-id="response-item-child"]`);

            if (!responseItem || !responseItemParent || !responseItemChild) return;


            var sticky = responseItem.getBoundingClientRect();
            responseItem.setAttribute('style', `left: ${left}px !important`);

            const parentCmpBoundRect = this.parentCmpBoundRect;
            var parentWidth = responseItemParent.getBoundingClientRect().width;
            // console.log("parentWidth-->",parentWidth);
            // console.log("window.pageYOffset-->",window.pageYOffset);
            // console.log("sticky.height-->",sticky.height);
            // console.log("parentCmpBoundRect.y-->",parentCmpBoundRect.y);
            // console.log("parentCmpBoundRect.height-->",parentCmpBoundRect.height);
            if (window.pageYOffset + sticky.height >= parentCmpBoundRect.y && window.pageYOffset <= parentCmpBoundRect.height) {
                responseItem.classList.add("position-sticky");
                responseItemChild.forEach(child => {
                    child.setAttribute('style', `width: ${parentWidth}px !important`);
                });
            } else {
                responseItem.classList.remove("position-sticky");
                responseItemChild.forEach(child => child.removeAttribute('style'));
            }
        }
    }

    @track parentCmpBoundRect
    @api setParentBoundRect(value) {
        if (value) {
            this.parentCmpBoundRect = value;
        }
    }

    @track isStatusQuoteColumnReadOnly;

    @track isConfirmEditModalVisible = false;
    @track isEndorsementModelOpen = false;
    @track isTimelineModalOpen = false;
    @track isEndorsementClone = false;
    @track isGenerateDocument = false;
    @track isConfirmRateQuote = false;

    @track isSelectDocumentType = false;


    @track openModalEditQuote = false;
    @track openModalBindQuote = false;
    @api openModalPreBindCalculator = false;
    @track isConfirmModalVisible = false;
    @track isDisabledButton = true;
    @api isOpenReferralModel = false;
    isEditQuoteButtonClicked = false;
    isSaveQuoteButtonClicked = false;

    @wire(CurrentPageReference) pageRef;

    @track closeReason;
    @track selectedType;

    @track payPlanOptions
    @track payPlanVal;
    @track defaultOpportunityInceptionDate;
    @track bindValue = '';
    get bindOptions() {
        console.log('inside getOptions::');
        return [
            { label: 'Bound Pending', value: 'Bound Pending' },
            { label: 'Bind', value: 'Bind' },
        ];
    }
    get cloneExcess() {
        console.log('this.mtaQuote', this.mtaQuote)
        return this.mtaQuote.data ? false : (this.isPrimaryQuote == 'true' ? true : false);
    }
    @track showBindOptions;
    @track isBoundPending;
    @track isInceptionDateEdited = false;
    @track editedEffectiveDate;
    @track isBindLoading = false;
    @track partFixedRes = false;
    @wire(getObjectInfo, { objectApiName: QUOTE_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: CLOSED_REASON_FIELD })
    ClosedReasonPicklistValues;

    @wire(fetchMTAs, { quoteId: '$quoteId' })
    mtaQuote;
    /*fetchMTA({ error, data }){  
        try{
            var result = data; 
            console.log('result:', result);
            if (result) {
                var res = JSON.parse(result);
                if( res.ps.Id != null ){
                    if (res.ps.DeveloperName != 'Professional_Indemnity' && res.ps.Endorsement_Operation__c != null && res.ps.Endorsement_Operation__c != undefined) { 
                        var mtaVals = res.ps.Endorsement_Operation__c.split(',');
                        mtaVals.forEach( function(item, index ) {
                            console.log('item:', item, 'q type', res.q.Quote_Type__c );
                            if( item == res.q.Quote_Type__c ){
                                this.mtaQuote = true;
                                console.log('item:', item,index );
                            }
                        });
                    }  
                }
           
            } else if (error) {
                console.log('@@@error: ' + JSON.stringify(error));
            } 
        }catch(err){
            console.log('@@@error2: ', err );
        }
    }*/

    @api totalPremiumValue;
    @api transactionPremiumValue;
    @api recordId;
    //Code modified in 4/8/2020
    @api rateQuote() {
        //console.log('handleRateQuote', this.quoteId);

        this.isLoading = true;
        if (this.isAqueousProduct && this.isInceptionDateEdited) {
            if (this.bindersList.length > 1) {
                if (this.selectedBinder != null || this.selectedBinder != undefined || this.selectedBinder != '') {
                    updateSelectedBinder({ quoteId: this.quoteId, selectedBinder: JSON.stringify(this.selectedBinder) })
                        .then(response => {
                            this.isInceptionDateEdited = false;
                            this.editedEffectiveDate = null;
                            this.goToRateQuote();
                        })
                        .catch(error => {
                            this.isLoading = false;
                            console.log("Error-->", JSON.stringify(error));
                            this.showToast("Error", error, "error");
                        })
                }
            } else if (this.bindersList.length == 1) {
                this.goToRateQuote();
                this.isInceptionDateEdited = false;
                this.editedEffectiveDate = null;
            } else {
                this.showToast("Error", "No Binders Available", "error");
                this.isLoading = false;
            }
        } else {
            this.goToRateQuote();
        }
    }
    goToRateQuote() {
        //this.handlePreRatingValidations();
        //console.log('isRateReady--'+this.rateReady);
        //if(this.rateReady== true){
        getRatingFromCallOut({ objId: this.quoteId }).then(response => {
            var errMsg = '';
            if (!response.isSuccess) {
                //errMsg = 'not rated successfully';
                errMsg = response.errors[0];
                console.log('getRatingFromCallOut fail', JSON.stringify(response.errors));
            } else {
                //check rate result
                console.log('response:' + JSON.stringify(response.data));
                //var currentQuote = result.data;
                //if (currentQuote.Rating_Status__c == 'System Error') {
                //errMsg = 'Quote is not rated successfully';
                //errMsg = currentQuote.Declined_Reason__c;
                //} else {
                //component.set("v.data1", JSON.stringify(result.data));
                //console.log('result:' + result.data);
                //}
                // let rateFinish = new CustomEvent('ratefinish', { detail: { quoteId: this.quoteId } });
                // this.dispatchEvent(rateFinish);
            }
            let refreshQuote = new CustomEvent('refreshquote', { detail: { quoteId: this.quoteId } });
            this.dispatchEvent(refreshQuote);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: (errMsg == '') ? "Success" : "Error",
                    message: (errMsg == '') ? "Rating successful!" : errMsg,
                    variant: (errMsg == '') ? "Success" : "Error"
                }),
            )
            this.isLoading = false;
        }).catch(error => {
            console.log("error.message", JSON.stringify(error.message));
            this.showToast('Error', error, 'error');
            this.isLoading = false;
        })
        //}
    }
    set compareItem(value) {
        // console.log("@@@value: " + JSON.stringify(value));
        //this.fetchMTA();
        var quoteType;
        console.log('this.quoteType  -- ', this.quoteType);
        this._compareItem = value;
        var clone = JSON.parse(JSON.stringify(this._compareItem));

        clone.quoteFields.forEach(item => {
            // if(item.value === '')
            //     item.value = 'Default';
            item.options = [];
            let picklistOption = item.picklistOption.split(";");

            for (let i = 0; i < picklistOption.length; i++) {
                if (item.fieldName == 'MPL Primary Retention') {
                    let option = { label: picklistOption[i].toString().replace(/\B(?=(\d{3})+(?!\d))/g, ","), value: picklistOption[i] };
                    item.options.push(option);
                } else {
                    let option = { label: picklistOption[i], value: picklistOption[i] };
                    item.options.push(option);
                }
            }

            if (item.sourceFieldAPI == 'Quote_Type__c') {
                quoteType = item.value;
            }
            if (item.endorsementType && quoteType) {
                if ((item.endorsementType.includes('Midterm Cancellation') && quoteType == 'Midterm Cancellation') ||
                    (item.endorsementType.includes('Full Amendment') && quoteType == 'Full Amendment') ||
                    (item.endorsementType.includes('Coverage Amendment') && quoteType == 'Coverage Amendment') ||
                    (item.endorsementType.includes('Insured Account Update') && quoteType == 'Insured Account Update') ||
                    (item.endorsementType.includes('Flat Cancellation (Ab - Initio)') && quoteType == 'Flat Cancellation (Ab - Initio)') ||
                    (item.endorsementType.includes('Renewal') && quoteType == 'Renewal') ||
                    (item.endorsementType.includes('Flat Cancellation') && quoteType == 'Flat Cancellation') ||
                    (item.endorsementType.includes('Reinstatement') && quoteType == 'Reinstatement') ||
                    (item.endorsementType.includes('Extension') && quoteType == 'Extension') ||
                    (item.endorsementType.includes('Amendment') && quoteType == 'Amendment') ||
                    (item.endorsementType.includes('New Business') && quoteType == 'New Business')) {
                    item.readOnly = true;
                }
            }
            /* Added by jai to make Quote fields Read Only For MTA Changes */
            if( (quoteType == 'Policy Duration Change' ) || quoteType == 'Update Insured Name or Address' || quoteType == 'Extended Reporting Period (ERP)' 
                || quoteType == 'Broker on Record Change'  /* added by  jai for US 53349 */
            ){
                item.readOnly = true;
            }
            /* added by  jai for US 53346 */
            if(quoteType == 'Midterm Cancellation' ){
                if(item.sourceFieldAPI != 'Override_Premium__c' ){
                    item.readOnly = true;
                }
            }
            /* added by  jai for US 53346 */
            if(quoteType == 'Amendment' && (item.sourceFieldAPI == 'ExpirationDate' || item.sourceFieldAPI == 'Effective_Date__c') ){
                item.readOnly = true;
            }
            if( quoteType == 'Policy Duration Change' && item.sourceFieldAPI == 'ExpirationDate' ) {
                item.readOnly = false;
            }
            /* Added by jai to make Quote fields Read Only For MTA Changes */
            if (item.format == 'Picklist') {
                item.isPicklist = true;
            } else if (item.format == 'Radio Button') {
                item.isRadioButton = true;
            } else if (item.format == 'Integer') {
                item.isInteger = true;
            } else if (item.format == 'Percentage') {
                item.isPercentage = true;
            } else if (item.format == 'Currency') {
                item.isCurrency = true;
            } else if (item.format == 'Number') {
                item.isNumber = true;
            } else if (item.format == 'Date') {
                item.isDate = true;
            } else if (item.format == 'Hyperlink') { //giang phan added 25/Jun/2020
                item.isHyperlink = true;
                //item.policyUrl = ("/" + item.value);
            } else item.isText = true;
            if (item.fieldId === '' || item.fieldId === undefined)
                item.isField = false;
            else
                item.fieldId += '-' + item.fieldName;
            /*if (item.sourceFieldAPI === 'Total_Premium__c') {
                this.totalPremiumValue = item.value;
                this.recordId = clone.quoteId;
            }*/
            if (clone.quoteName.includes(' PI ')) {
                if (item.sourceFieldAPI === 'Broker_Netted_Down_Premium__c') {
                    this.totalPremiumValue = item.value;
                    this.recordId = clone.quoteId;
                }
            } else {
                if (item.sourceFieldAPI === 'QuotePremium__c') {
                    this.totalPremiumValue = item.value;
                    console.log("totalPremiumValue value-->", this.totalPremiumValue);
                    this.recordId = clone.quoteId;
                }
                if (item.sourceFieldAPI === 'Transaction_Premium__c') {
                    this.transactionPremiumValue = item.value;
                    console.log("transactionPremiumValue value-->", this.transactionPremiumValue);
                }
            }

            if (item.sourceFieldAPI == 'Effective_Date__c') {
                this.defaultOpportunityInceptionDate = item.value;
            }
        })

        console.log("defaultOpportunityInceptionDate-->", this.defaultOpportunityInceptionDate);
        console.log("Quote Name-->", this.quoteName);
        console.log("Quote Name-->", this.quoteName.includes('Professional Indemnity'));
        //this._quoteRatingrapper = clone;
        this._compareItem = clone;
        console.log('Compare item -->' + JSON.stringify(this._compareItem));
        this.quoteStatus = clone.quoteStatus;
        this.quoteRatingStatus = clone.quoteRatingStatus;
        if (this.quoteRatingStatus == undefined)
            this.quoteRatingStatus = 'None';
        if (this.quoteStatus === 'Quoted' && this.quoteRatingStatus === 'Clear') {
            this.isQuotedClear = true;
        }
        if (this.quoteStatus === 'Quoted' || this.quoteStatus === 'Bound' || this.quoteStatus === 'Bound Pending') {
            this.isStatusQuoteColumnReadOnly = true;
        }
        if (this.quoteStatus === 'Quoted' || this.quoteStatus === 'Bound Pending') {
            this.isQuotedStatus = true;
        } else this.isQuotedStatus = false;

        if (this.quoteStatus === 'In Approval') {
            this.isLockedQuote = true;
            this.isQuotedStatus = true;
        } else {
            this.isLockedQuote = false;
        }
    }
    @api
    get compareItem() {
        return this._compareItem;
    }

    connectedCallback() {
        console.log("SUbmission details--->", JSON.stringify(this.submissionObj));
        var stageName = this.submissionObj.StageName;
        if (this.submissionObj.Product_Name__c == 'Professional Indemnity') {
            if (stageName == 'Closed Won' || stageName == 'Closed Lost' || stageName == 'Declined') {
                this.disableEndosementButton = true;
            }
        }
        // let clone = JSON.parse(JSON.stringify(this.compareItem));
        // clone.quoteFields.forEach(item => {

        //     if (item.format == 'Picklist') {
        //         item.isPicklist = true;
        //         item.options = [];
        //         let picklistOption = item.picklistOption.split(";");
        //         for (let i = 0; i < picklistOption.length; i++) {
        //             let option = { label: picklistOption[i], value: picklistOption[i] };
        //             item.options.push(option);
        //         }
        //     } else if (item.format == 'Radio Button') {
        //         item.isRadioButton = true;
        //         item.options = [];
        //         let picklistOption = item.picklistOption.split(";");
        //         for (let i = 0; i < picklistOption.length; i++) {
        //             let option = { label: picklistOption[i], value: picklistOption[i] };
        //             item.options.push(option);
        //         }
        //     } else if (item.format == 'Integer') {
        //         item.isInteger = true;
        //     } else if (item.format == 'Percent') {
        //         item.isPercentage = true;
        //     } else if (item.format == 'Currency') {
        //         item.isCurrency = true;
        //     } else if (item.format == 'Number') {
        //         item.isNumber = true;
        //     } else if (item.format == 'Date') {
        //         item.isDate = true;
        //     } else
        //         item.isText = true;
        //     if (item.fieldId === '' || item.fieldId === undefined)
        //         item.isField = false;
        //     else
        //         item.fieldId += '-' + item.fieldName;
        // })
        // this.compareItem = clone;

        if (this.quoteStatus === 'Quoted' && this.quoteRatingStatus === 'Clear') {
            this.isQuotedClear = true;
        }
        if (this.quoteStatus === 'Quoted') {
            this.isQuotedStatus = true;
        }

        if (this.quoteStatus === 'In Approval') {
            this.isLockedQuote = true;
            this.isQuotedStatus = true;
        } else {
            this.isLockedQuote = false;
        }
        //console.log('call back');
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.quoteId,
                objectApiName: 'Quote',
                actionName: 'view',
            },
        }).then(url => {
            this.quoteUrl = url;
        });;
        registerListener('editQuoteName', this.handleEditQuoteName, this);
        registerListener('refreshTitleFromResponse', this.handleInitValues, this);


        /*
                //START -- Added by Sarthak on 19th June 2020
                getQuoteDetails({quoteId: this.quoteId})
                .then(result =>{
                    this.quoteInfo = result;
                    console.log('Quote Info'+JSON.stringify(this.quoteInfo));     
                })
                .catch(error=>{
                    console.error("error"+JSON.stringify(error));
                })
            //END  -- Added by Sarthak on 19th June 2020
        */
    }

    renderedCallback() {
        
        const style = document.createElement('style');
        style.innerText = `
        .bind button, .rate button {
            padding-left: 8px !important;
            padding-right: 8px !important;
          }
        `;
        this.template.querySelector('div').appendChild(style);

        this.styleFixedHeader();
        this.styleMovePopUp();
    }

    styleFixedHeader() {
        var responseItem = this.template.querySelector(`[data-id="response-item"]`);
        var responseItemParent = this.template.querySelector(`[data-id="response-item-parent"]`);
        var responseItemChild = this.template.querySelectorAll(`[data-id="response-item-child"]`);
        console.log("this.parentCmpBoundRect-->", JSON.stringify(this.parentCmpBoundRect));
        if (!responseItem || !responseItemParent || !responseItemChild || !this.parentCmpBoundRect) return;

        var sticky = responseItem.getBoundingClientRect();

        const parentCmpBoundRect = this.parentCmpBoundRect;

        window.addEventListener('scroll', function (event) {
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

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
    toggleModeEdit(evt) {
        var oldMode = this.modeEdit;
        this.modeEdit = !this.modeEdit;
        if (this.modeEdit == true) {
            evt.target.classList.add('slds-is-selected');
        } else {
            evt.target.classList.remove('slds-is-selected');
        }
        if (this.modeEdit == false && oldMode == true) {
            console.log('Edit Done');
            const editQuoteEvt = new CustomEvent(
                "editquote",
                {
                    detail: { retention: this.retentionVal, yearInBussiness: this.retroDate, supplementaryPayments: this.supplePaySelected }
                }
            );
            this.dispatchEvent(editQuoteEvt);
        }

    }
    changeRerentionValue(evt) {
        this.retentionVal = evt.target.value;
    }
    changeSupplePaySelect(evt) {
        this.supplePaySelected = evt.target.value;
    }
    changeRetroDt(evt) {
        this.retroDate = evt.target.value;
    }
    get condition() {
        // if(this.mainColumnWrapper.mainItem.Status !== "Bound"
        // && this.mainColumnWrapper.mainItem.Status !== "Bound Pending"
        // && this.mainColumnWrapper.mainItem.Status !== "Closed"
        // && this.mainColumnWrapper.mainItem.Status !== "Rejected" ){
        //     return true;
        // }
        // if(this.compareItem.Status !== "Bound"
        // && this.compareItem.Status !== "Bound Pending"
        // && this.compareItem.Status !== "Closed"
        // && this.compareItem.Status !== "Rejected" ){
        //     return true;
        // }
        // return false;
        return this.quoteStatus;
    }
    
    get clearQuote() {
        console.log("SUbmission details--->", JSON.stringify(this.submissionObj));
        var stageName = this.submissionObj.StageName;
        if (this.submissionObj.Product_Name__c == 'Professional Indemnity') {
            if (stageName == 'Closed Won' || stageName == 'Closed Lost' || stageName == 'Declined') {
                this.disableEndosementButton = true;
            }
        }
        if (this.quoteRatingStatus == 'Clear') {
            return true;
        } else {
            return false;
        }
    }

    handleEditQuoteName(event) {
        console.log("Event: " + event);
        let quoteName = event.quoteName;
        let quoteId = event.quoteId;
        if (this.quoteId === quoteId) {
            // this.mainColumnWrapper.mainItem.Name = quoteName;
            this.quoteName = quoteName;
            console.log("changing name");
        }

    }
    disconnectCallback() {
        unregisterAllListeners(this);
    }
    //handle rate quote button
    @track rateReady = true;
    @track fromPopup = false;
    handleRateQuote() {
        //code modified in 6/8/2020
        //console.log('Compare Item Values from rate -->'+JSON.stringify(this._compareItem.quoteFields));
        if (this.quoteStatus == 'In Progress') {

            if (this.isAqueousProduct) {
                console.log('I am here..');
                //this.handlePreRatingValidations();
                this.fromPopup = true;
                this.handlePreRatingValidations();
                // console.log('rate ready in pre validation::'+this.rateReady);
                console.log('isRateReady--' + this.rateReady);

            } else {
                this.handleRateQuoteController();
            }


        } else {
            if (!this.isAqueousProduct) {
                this.handleClickRateModal();


            } else {
                this.fromPopup = false;
                this.handlePreRatingValidations();
                //this.isConfirmRateQuote = true;

            }
        }


    }

    handlePreRatingValidations(event) {

        this.rateReady = true;
        var isValid = true;
        this.template.querySelectorAll("c-generate-output-element-lwc").forEach(field => {
            let checkValid = field.checkValueOutOfRange();
            if (checkValid == false) isValid = false;
        });
        this.isReadyToSave = isValid;
        if (isValid == false) {
            this.showToast('Error', 'Some values are out of range!', 'error')
            return;
        }
        this.isLoading = true;
        var retroDateOption = '';
        var actualPremium = '';
        var brokerCommission = '';
        var proceedAhead = true;
        console.log('this.isAqueousProduct - ', this.isAqueousProduct);
        console.log('Compare Item Values -->' + JSON.stringify(this._compareItem.quoteFields));
        console.log('Previous Quote Values -->' + JSON.stringify(this.prevQuoteValues.quoteFields));
        console.log("prev quote -->" + JSON.stringify(this.prevQuoteValues));
        let prevValues = this.prevQuoteValues.quoteFields;
        let newValues = this._compareItem.quoteFields;
        let valuesChanged = 0;
        for (let i = 0; i < prevValues.length; i++) {
            if (prevValues[i].fieldName == 'Binder' || prevValues[i].fieldName == 'Policy Wording' || prevValues[i].fieldName == 'Territorial Limits' || prevValues[i].fieldName == 'Jurisdiction Limits' || prevValues[i].fieldName == 'Retroactive Date' || prevValues[i].fieldName == 'Date') {
                if (prevValues[i].value != newValues[i].value) {
                    console.log("prevValues.fieldName -->" + prevValues[i].fieldName)
                    console.log("newValues.fieldName -->" + newValues[i].fieldName)
                    console.log('prevValues.value -->' + prevValues[i].value)
                    console.log('newValues.value -->' + newValues[i].value)
                    valuesChanged++;
                }
            }
            else {
                if (prevValues[i].value != newValues[i].value) {
                    console.log("prevValues.fieldName -->" + prevValues[i].fieldName)
                    console.log("newValues.fieldName -->" + newValues[i].fieldName)
                    console.log('prevValues.value -->' + prevValues[i].value)
                    console.log('newValues.value -->' + newValues[i].value)
                    valuesChanged = 0;
                    break;
                }
            }
        }
        console.log('valuesChanged -->' + valuesChanged);



        if (this.quoteStatus == 'In Progress' || (this.quoteStatus == 'Rated' && valuesChanged) || (this.quoteStatus == 'Quoted' && valuesChanged)) {
            var clone = JSON.parse(JSON.stringify(this._compareItem));
            console.log('clone::' + clone);
            clone.quoteFields.forEach(item => {
                console.log('item- - ', JSON.stringify(item));
                if (this.isAqueousProduct) {
                    //this.handlePreRatingValidations();
                    console.log('this.isAqueousProduct IN FOREACH- ', this.isAqueousProduct);
                    if (item.sourceFieldAPI == 'Retroactive_Date__c' && item.value != '') {
                        retroDateOption = item.value;
                    }
                    if (item.sourceFieldAPI == 'Actual_Premium__c' && item.value != '') {
                        actualPremium = item.value;
                    }
                    if (item.sourceFieldAPI == 'Commission_percentage__c' && item.value != '') {
                        brokerCommission = item.value;
                    }
                    if (item.sourceFieldAPI == 'Commission_percentage__c' && this.isAqueousProduct) {
                        if (item.value == '' || item.value == null || item.value == undefined) {
                            this.showToast("Error", "Broker Commission cannot be empty.", "error");
                            proceedAhead = false;
                            this.isLoading = false;
                            this.rateReady = false;
                            this.fromPopup = false;
                            return;
                        }
                    }
                    if (item.sourceFieldAPI == 'Option_Value_Default__c' && item.fieldName.includes('Freeform')) {
                        if (item.value) {
                            if (parseFloat(item.value) < 100000 || parseFloat(item.value) > 5000000) {
                                this.showToast("Error", "Freeform Limit Values cannot be below 100,000 or above 5,000,000.", "error");
                                proceedAhead = false;
                                this.isLoading = false;
                                this.rateReady = false;
                                this.fromPopup = false;
                                return;
                            }
                        }
                    }
                    if (item.sourceFieldAPI == 'MGA_Commission__c' && this.isAqueousProduct) {
                        if (item.value == '' || item.value == null || item.value == undefined) {
                            this.showToast("Error", "MGA Commission cannot be empty.", "error");
                            proceedAhead = false;
                            this.isLoading = false;
                            this.rateReady = false;
                            this.fromPopup = false;
                            return;
                        }
                    }

                    if (item.sourceFieldAPI == 'Broker_Netted_Down_Premium__c') {
                        if (item.value != '' || item.value != null || item.value != undefined) {
                            if (actualPremium != '' && brokerCommission != '') {
                                let formulaValue = parseFloat(actualPremium) - ((parseFloat(brokerCommission)) * parseFloat(actualPremium));
                                console.log('item.value - ', item.value);
                                console.log('formulaValue - ', formulaValue);
                                console.log('actualPremium - ', actualPremium);
                                console.log('brokerCommission - ', brokerCommission);
                                if (item.value < formulaValue) {
                                    this.showToast("Error", "Broker Netted Down Premium Value cannot be entered very low value", "error");
                                    proceedAhead = false;
                                    this.isLoading = false;
                                    this.rateReady = false;
                                    this.fromPopup = false;
                                    return;
                                }
                            }
                        }
                    }
                    if (retroDateOption == 'Date') {
                        if (item.sourceFieldAPI == 'RetroDate__c' && (item.value == '' || item.value == undefined || item.value == null)) {
                            this.showToast("Error", "Please enter Date when Retroactive Date option selected is : " + retroDateOption, "error");
                            proceedAhead = false;
                            this.isLoading = false;
                            this.rateReady = false;
                            this.fromPopup = false;
                            return;
                        }
                    }
                }

                if (item.fieldId != '' || item.fieldId != undefined) {
                    let id = item.fieldId.split('-');
                    item.fieldId = id[0];
                }
            })

        }
        console.log('this.isValid===>', this.isReadyToSave);
        //this.rateReady = true;
        console.log('rate ready in pre validation::' + this.rateReady);
        console.log('fromPopup in pre validation::' + this.fromPopup);
        if (this.rateReady == true) {
            console.log('I am in rating..');
            this.handleRateQuoteController();
        } else if (this.fromPopup) {
            this.isConfirmRateQuote = true;
        }
        //return this.isReadyToSave;
    }

    handleCancel() {
        this.openModalEditQuote = false;
    }
    handleShowEditQuote() {
        this.openModalEditQuote = true;
        if (this.quoteStatus != 'Quoted' || this.quoteStatus != 'Bound' || this.quoteStatus != 'Bound Pending') {
            this.isStatusQuoteColumnReadOnly = false;
        }
    }
    handleSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;
        fields.quoteId = this.quoteId;
        console.log('this.selectedQuoteId:' + this.quoteId);
        const fieldsObj = JSON.parse(JSON.stringify(fields));
        console.log('this.compareItem:', this._compareItem);
        this.template.querySelector('lightning-record-form').submit(fields);
        //this.template.querySelector('lightning-record-form').submit();
        if (this.quoteName != fieldsObj.Name) {
            let detail = { quoteId: this.quoteId, quoteName: fieldsObj.Name }
            if (!this.pageRef) {
                this.pageRef = {};
                this.pageRef.attributes = {};
                this.pageRef.attributes.LightningApp = "LightningApp";
            }
            fireEvent(this.pageRef, 'editQuoteName', detail);
        }
        this.quoteName = fieldsObj.Name
        //Edit Status
        if (this.quoteStatus != fieldsObj.Status) {
            let detail = { quoteId: this.quoteId, quoteStatus: fieldsObj.Status }
            if (!this.pageRef) {
                this.pageRef = {};
                this.pageRef.attributes = {};
                this.pageRef.attributes.LightningApp = "LightningApp";
            }
            fireEvent(this.pageRef, 'editQuoteStatus', detail);
        }
        this.quoteStatus = fieldsObj.Status
        if (this.quoteStatus == 'In Progress') {
            this.isQuotedStatus = false;
            this.isStatusQuoteColumnReadOnly = false;
        }
        if (this.quoteStatus == 'Quoted' || this.quoteStatus === 'Bound Pending') {
            this.isQuotedStatus = true;
            this.isStatusQuoteColumnReadOnly = true;
            console.log('isQuotedStatus::' + isQuotedStatus);
        }
    }

    handleEditSuccess(event) {
        //this.template.querySelector('c-pagination-lwc').refreshDataTable();
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Record updated successfully with id: ' + event.detail.id,
                variant: 'success',
            }),
        )
        this.handleCancel();
        // window.location.reload();
        let refreshQuote = new CustomEvent('refreshquote', { detail: { quoteId: this.quoteId } });
        this.dispatchEvent(refreshQuote);
    }
    openEndorsementModel(event) {
        this.isEndorsementModelOpen = true;

    }
    closeEndorsementModal(event) {
        this.isEndorsementModelOpen = false;
        let refreshQuote = new CustomEvent('refreshquote', { detail: { quoteId: this.quoteId } });
        this.dispatchEvent(refreshQuote);
    }
    @track quoteValues;
    quoteDetails() {
        quoteDetails({ 'quoteId': this.quoteId })
            .then((result) => {
                this.quoteValues = result;
                console.log('quoteValues:' + JSON.stringify(this.quoteValues));
                this.checkPartFixedEndorsement();
                
            })
            .catch((error) => {
                console.log('@@@error: ' + JSON.stringify(error));
                this.showToast('Error', JSON.stringify(error), 'error');
            })
    }

    
    handleFinalizeQuote(event) {
        console.log("HandleFinalizeQuote:");
        this.quoteDetails();
    }

    handleFinalize() {
        this.isLoading = true;
        finalizeQuote({ 'quoteId': this.quoteId })
            .then((result) => {

                if (result.isSuccess) {
                    var currentQuote = result.data;
                    this.quoteStatus = currentQuote.Status;
                    var quoteType = currentQuote.Quote_Type__c;
                    console.log('AZquoteStatus---'+currentQuote.Rating_Status__c);
                    var ratingStatus = currentQuote.Rating_Status__c;
                    this.isLoading = false;
                    this.isQuotedClear = true;
                    let refreshQuote = new CustomEvent('refreshquote', { detail: { quoteId: this.quoteId } });
                    this.dispatchEvent(refreshQuote);
                    if(this.isAqueousProduct){
                        this.showToast('Success', 'Finalize quote Successful!', 'success');
                    }else{
                        if(quoteType == 'New Business' || quoteType == 'Renewal'){
                            if(ratingStatus == 'Refer' || ratingStatus == 'Ineligible'){
                                this.showToast('Success', 'Finalize quote Successful!', 'Success');
                            }else{
                                this.showToast('Success', 'Finalize quote and Document Generation Successful!', 'success');
                                this.selectedType = 'quote';
                                setTimeout(() => {
                                   console.log('Set Time for doc' );
                                   this.downloadDocumentCel();
                                }, 3000); 
                            }   
                        }else{
                            this.showToast('Success', 'Finalize quote Successful!', 'Success');
                        }  
                    }
                    // Added by Vinayesh on 24/5/2021 for US: 46242 
                    //this.generateDocumentOnFinalize();        
                } else {
                    console.log('@@@error: ' + JSON.stringify(result.errors));
                    this.isLoading = false;
                    let refreshQuote = new CustomEvent('refreshquote', { detail: { quoteId: this.quoteId } });
                    this.dispatchEvent(refreshQuote);
                    if (result.errors[0] == 'Quote sent for Referral') {
                        this.showToast('', result.errors[0], 'warning');
                    } else {
                        this.showToast('Error', result.errors[0], 'error');
                    }
                }
            })
            .catch((error) => {
                console.log('@@@error: ' + JSON.stringify(error));
                this.isLoading = false;
                this.showToast('Error', 'Finalize quote fail!', 'error');
            })

    }

    closeReferralReasonPopUp() {
        this.showReferralReasonPopUp = false;
    }

    @track viewDocument = false;
    handleViewDocument(event) {
        console.log("DocumentType: " + this.selectedType);
        this.isSelectDocumentType = false;
        this.isGenerateDocument = true;
        this.viewDocument = true;
        if (this.isAqueousProduct) {
            this.downloadDocumentAQ();
        } else {
            this.downloadDocumentCel();
        }

    }

    downloadCelerityQuoteDocument(){
        this.selectedType = 'quote';
        setTimeout(() => {
               console.log('Set Time for doc' );
              this.downloadDocumentCel();
           }, 2000);
    }

    downloadDocumentCel() {
        getDocumentEncodeByQuoteId({ quoteId: this.quoteId, documentType: this.selectedType }).then(
            result => {
                console.log('@@@ result getDocument= ' + JSON.stringify(result));
                if (result.encodeBlobResponse) {
                    setTimeout(function () {
                        var binary = atob(result.encodeBlobResponse.replace(/\s/g, ''));
                        var buffer = new ArrayBuffer(binary.length);
                        var view = new Uint8Array(buffer);
                        for (var i = 0; i < binary.length; i++) {
                            view[i] = binary.charCodeAt(i);
                        }
                        var blob = new Blob([view]);
                        var url = URL.createObjectURL(blob);
                        var link = document.createElement('a');
                        link.href = url;
                        link.download = result.docName;
                        link.click();
                    }, 500);
                }
                this.showToast(
                    (!result.errMsg) ? 'Success' : 'Error',
                    (!result.errMsg) ? 'Document has been downloaded successfully!' : result.errMsg,
                    (!result.errMsg) ? 'success' : 'error'
                );
                this.viewDocument = false;
                this.isGenerateDocument = false;
            }
        )
    }

    downloadDocumentAQ() {
        getDocumentEncodeByQuoteIdAQ({ submissionId: this.quoteProcessSubmissionId, binder: this.defaultBinder, documentType: this.selectedType, layer: this.isPrimaryQuote == 'true' ? 'Primary' : 'Excess' })
            .then(result => {
                console.log('@@@ result getDocument= ' + JSON.stringify(result));
                if (result.encodeBlobResponse) {
                    setTimeout(function () {
                        var binary = atob(result.encodeBlobResponse.replace(/\s/g, ''));
                        var buffer = new ArrayBuffer(binary.length);
                        var view = new Uint8Array(buffer);
                        for (var i = 0; i < binary.length; i++) {
                            view[i] = binary.charCodeAt(i);
                        }
                        var blob = new Blob([view]);
                        var url = URL.createObjectURL(blob);
                        var link = document.createElement('a');
                        link.href = url;
                        link.download = result.docName;
                        link.click();
                    }, 500);
                }
                this.showToast(
                    (!result.errMsg) ? 'Success' : 'Error',
                    (!result.errMsg) ? 'Document has been downloaded successfully!' : result.errMsg,
                    (!result.errMsg) ? 'success' : 'error'
                );
                this.viewDocument = false;
                this.isGenerateDocument = false;
            }
            )
    }

    handleCloneQuote(event) {
        console.log('@@@ quoteId', this.quoteId);
        let layerName = event.target.dataset.layer;
        //console.log('@@@ layerName', layerName);
        const cloneQuoteEvent = new CustomEvent(
            "clonequote", {
            detail: { quoteId: this.quoteId, quoteLayer: layerName}
        });
        this.dispatchEvent(cloneQuoteEvent);
    }

    @track closedReasons = [];
    handleCloseButtonClickEvent(event) {
        console.log('quoteId: ', this.quoteId);
        handleCloseReasons({ quoteId: this.quoteId })
            .then(result => {
                this.closedReasons = [];
                for (let i = 0; i < result.length; i++) {
                    this.closedReasons.push({ label: result[i].label, value: result[i].value });
                    this.closedReasons = JSON.parse(JSON.stringify(this.closedReasons));
                    this.isConfirmModalVisible = true;
                }
                console.log('closedReasons-->' + JSON.stringify(this.closedReasons));
            }).catch(error => {
                this.showToast('Error', error, 'error');
                console.log('error-->' + JSON.stringify(error));
            })
    }
    handleCloseQuoteModal() {
        this.isConfirmModalVisible = false;
        this.closeReason = null;
    }
    handleChangeReason(event) {
        this.closeReason = event.detail.value;
    }

    handleCloseQuote(event) {
        let status = event.target.name;
        if (status == 'confirm') {
            if (!this.closeReason) {
                this.showToast('Error', 'Please choose your reason!', 'error');
                return;
            }
            let detail = { quoteId: this.quoteId, closeReason: this.closeReason };
            const removeQuoteEvt = new CustomEvent(
                "deletequote", {
                detail
            }
            );
            this.dispatchEvent(removeQuoteEvt);
            if (!this.pageRef) {
                this.pageRef = {};
                this.pageRef.attributes = {};
                this.pageRef.attributes.LightningApp = "LightningApp";
            }
            fireEvent(this.pageRef, 'deleteQuote', detail);
            this.isConfirmModalVisible = false;
            this.closeReason = null;
        } else if (status == 'cancel') {
            this.isConfirmModalVisible = false;
            this.closeReason = null;
            refreshApex(this.pageRef);
        }
    }
    openQuoteVersionTimeline(event) {
        this.isTimelineModalOpen = true;
    }

    closeVersionTimeline(event) {
        this.isTimelineModalOpen = false
    }
    openEndorsementClone() {
        this.isEndorsementClone = true;
    }
    handleCanelEndorse() {
        this.isEndorsementClone = false;
    }

    handleChangeInput(event) {
        let name = event.detail.fieldId;
        let value = event.detail.fieldValue;
        var quoteRatingWr = JSON.parse(JSON.stringify(this._compareItem));
        quoteRatingWr.quoteFields.forEach(item => {
            if (item.isField && item.fieldId === name) {
                item.value = value;
                if (item.sourceFieldAPI == 'Effective_Date__c') {
                    this.isInceptionDateEdited = true;
                    this.editedEffectiveDate = item.value;
                    console.log("Effective Date Changed-->", this.isInceptionDateEdited);
                }
                console.log("OK");
            }
        });
        this._compareItem = quoteRatingWr;
        this.isDisabledButton = false;
    }

    // handleChangeEditMode(event) {
    //     this.modeEdit = !this.modeEdit;
    // }

    // validateField(){
    //     let isValid = true;
    //     this.template.querySelectorAll("c-generate-output-element-lwc").forEach(field => {
    //         console.log('field.checkValid()',JSON.stringify(field.checkValid()));
    //         let checkValid = field.checkValid();
    //         if(checkValid == false) isValid = false;
    //     })
    //     return isValid;
    // }


    @api
    handleSaveCompareItem(event) {

        // let isValid = true;
        // this.template.querySelectorAll("c-generate-output-element-lwc").forEach(field => {
        //     console.log('field.checkValid()',JSON.stringify(field.checkValid()));
        //     let checkValid = field.checkValid();
        //     if(checkValid == false) isValid = false;
        // })
        // console.log("handleSaveCompareItem -> isValid", isValid)
        // if(isValid == false) {
        //     this.showToast('Error', 'Some values is invalid!','error')
        //     return;
        // }
        var isValid = true;
        this.template.querySelectorAll("c-generate-output-element-lwc").forEach(field => {
            let checkValid = field.checkValueOutOfRange();
            if (checkValid == false) isValid = false;
        });
        this.isReadyToSave = isValid;
        if (isValid == false) {
            this.showToast('Error', 'Some values are out of range!', 'error')
            return;
        }
        this.isLoading = true;
        var retroDateOption = '';
        var actualPremium = '';
        var brokerCommission = '';
        var proceedAhead = true;
        console.log('this.isAqueousProduct - ', this.isAqueousProduct);
        console.log('Compare Item Values -->' + JSON.stringify(this._compareItem.quoteFields));
        console.log('Previous Quote Values -->' + JSON.stringify(this.prevQuoteValues.quoteFields));
        console.log("prev quote -->" + JSON.stringify(this.prevQuoteValues));
        let prevValues = this.prevQuoteValues.quoteFields;
        let newValues = this._compareItem.quoteFields;
        let valuesChanged = 0;
        for (let i = 0; i < prevValues.length; i++) {
            if (prevValues[i].fieldName == 'Binder' || prevValues[i].fieldName == 'Policy Wording' || prevValues[i].fieldName == 'Territorial Limits' || prevValues[i].fieldName == 'Jurisdiction Limits' || prevValues[i].fieldName == 'Retroactive Date' || prevValues[i].fieldName == 'Date') {
                if (prevValues[i].value != newValues[i].value) {
                    console.log("prevValues.fieldName -->" + prevValues[i].fieldName)
                    console.log("newValues.fieldName -->" + newValues[i].fieldName)
                    console.log('prevValues.value -->' + prevValues[i].value)
                    console.log('newValues.value -->' + newValues[i].value)
                    valuesChanged++;
                }
            }
            else {
                if (prevValues[i].value != newValues[i].value) {
                    console.log("prevValues.fieldName -->" + prevValues[i].fieldName)
                    console.log("newValues.fieldName -->" + newValues[i].fieldName)
                    console.log('prevValues.value -->' + prevValues[i].value)
                    console.log('newValues.value -->' + newValues[i].value)
                    valuesChanged = 0;
                    break;
                }
            }
        }
        console.log('valuesChanged -->' + valuesChanged);



        if (this.quoteStatus == 'In Progress' || (this.quoteStatus == 'Rated' && valuesChanged) || (this.quoteStatus == 'Quoted' && valuesChanged)) {
            var clone = JSON.parse(JSON.stringify(this._compareItem));
            console.log('clone::' + clone);
            clone.quoteFields.forEach(item => {
                console.log('item- - ', JSON.stringify(item));
                if (this.isAqueousProduct) {
                    //this.handlePreRatingValidations();
                    console.log('this.isAqueousProduct IN FOREACH- ', this.isAqueousProduct);
                    if (item.sourceFieldAPI == 'Retroactive_Date__c' && item.value != '') {
                        retroDateOption = item.value;
                    }
                    if (item.sourceFieldAPI == 'Actual_Premium__c' && item.value != '') {
                        actualPremium = item.value;
                    }
                    if (item.sourceFieldAPI == 'Commission_percentage__c' && item.value != '') {
                        brokerCommission = item.value;
                    }
                    if (item.sourceFieldAPI == 'Commission_percentage__c' && this.isAqueousProduct) {
                        if (item.value == '' || item.value == null || item.value == undefined) {
                            this.showToast("Error", "Broker Commission cannot be empty.", "error");
                            proceedAhead = false;
                            this.isLoading = false;
                            this.rateReady = false;
                            return;
                        }
                    }
                    if (item.sourceFieldAPI == 'Option_Value_Default__c' && item.fieldName.includes('Freeform')) {
                        if (item.value) {
                            if (parseFloat(item.value) < 100000 || parseFloat(item.value) > 5000000) {
                                this.showToast("Error", "Freeform Limit Values cannot be below 100,000 or above 5,000,000.", "error");
                                proceedAhead = false;
                                this.isLoading = false;
                                this.rateReady = false;
                                return;
                            }
                        }
                    }
                    if (item.sourceFieldAPI == 'MGA_Commission__c' && this.isAqueousProduct) {
                        if (item.value == '' || item.value == null || item.value == undefined) {
                            this.showToast("Error", "MGA Commission cannot be empty.", "error");
                            proceedAhead = false;
                            this.isLoading = false;
                            this.rateReady = false;
                            return;
                        }
                    }
                    // if (item.sourceFieldAPI == 'ExpirationDate' && item.value != '') {
                    //     var subExpirationDate = new Date(this.submissionObj.Expiration_Date__c);
                    //     var currentExpirationDate = new Date(item.value);
                    //     var maxDate = new Date();
                    //     maxDate.setMonth(new Date(subExpirationDate).getMonth() + 18);
                    //     if (this.isAqueousProduct && currentExpirationDate > maxDate) {
                    //         this.showToast("Error", "Expiration Date cannot go beyond 18 months of Submission's Expiration Date.", "error");
                    //         proceedAhead = false;
                    //         this.isLoading = false;
                    //         return;
                    //     }
                    // }
                    // if (item.sourceFieldAPI == 'Effective_Date__c' && item.value != '') {
                    //     var subInceptionDate = new Date(this.submissionObj.Effective_Date__c);
                    //     var currentInceptionDate = new Date(item.value);
                    //     var maxDate = new Date();
                    //     maxDate.setDate(new Date(subInceptionDate).getDate() + 45);
                    //     if (this.isAqueousProduct && currentInceptionDate > maxDate) {
                    //         this.showToast("Error", "Inception Date can have maximum advance period of 45 days of Submission's Inception Date.", "error");
                    //         proceedAhead = false;
                    //         this.isLoading = false;
                    //         return;
                    //     }
                    // }
                    if (item.sourceFieldAPI == 'Broker_Netted_Down_Premium__c') {
                        if (item.value != '' || item.value != null || item.value != undefined) {
                            if (actualPremium != '' && brokerCommission != '') {
                                let formulaValue = parseFloat(actualPremium) - ((parseFloat(brokerCommission)) * parseFloat(actualPremium));
                                console.log('item.value - ', item.value);
                                console.log('formulaValue - ', formulaValue);
                                console.log('actualPremium - ', actualPremium);
                                console.log('brokerCommission - ', brokerCommission);
                                if (item.value < formulaValue) {
                                    this.showToast("Error", "Broker Netted Down Premium Value cannot be entered very low value", "error");
                                    proceedAhead = false;
                                    this.isLoading = false;
                                    this.rateReady = false;
                                    return;
                                }
                            }
                        }
                    }
                    if (retroDateOption == 'Date') {
                        if (item.sourceFieldAPI == 'RetroDate__c' && (item.value == '' || item.value == undefined || item.value == null)) {
                            this.showToast("Error", "Please enter Date when Retroactive Date option selected is : " + retroDateOption, "error");
                            proceedAhead = false;
                            this.isLoading = false;
                            this.rateReady = false;
                            return;
                        }
                    }
                }

                if (item.fieldId != '' || item.fieldId != undefined) {
                    let id = item.fieldId.split('-');
                    item.fieldId = id[0];
                }
            })
            if (proceedAhead) {
                if (this.quoteStatus == 'Quoted' && valuesChanged) {
                    const fields = {};
                    fields[ID_FIELD.fieldApiName] = this.quoteId;
                    fields[STATUS_FIELD.fieldApiName] = 'Rated';
                    const recordInput = { fields };
                    updateRecord(recordInput)
                        .then(() => {
                            console.log("Quote Status Successfully Updated");
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

                let detail = {
                    quoteId: this.quoteId, quoteName: this.quoteName, data: clone, quoteVerId: '', isRate: false,
                    fromResponse: true
                }
                const editQuoteEvt = new CustomEvent(
                    "updatequote", {
                    detail: detail,
                });
                this.dispatchEvent(editQuoteEvt);
                this.isDisabledButton = true;
            }
        } else {
            this.isConfirmEditModalVisible = true;
            this.isSaveQuoteButtonClicked = true;
        }
        // this.isLoading = false;

        console.log('this.isValid===>', this.isReadyToSave);
        return this.isReadyToSave;
    }

    handleOpenConfirmEdit() {
        this.isConfirmEditModalVisible = true;
        //     // if(this.quoteStatus ==='Quoted' && !this.modeEdit){
        //     //     this.isConfirmEditModalVisible = true;
        //     // }else{
        //     //     this.handleChangeEditMode();
        //     // }
    }
    handlerConfirmEdit(event) {
        let status = event.detail.status;
        console.log('Status' + status);
        if (status == 'confirm') {
            if (this.quoteStatus != 'In Progress') {
                updateQuoteInProgress({ quoteId: this.quoteId }).then(response => {
                    if (response.isSuccess) {
                        // this.quoteStatus = 'In Progress';
                        // this.isStatusQuoteColumnReadOnly = false;
                        // this.isQuotedStatus = false;
                        if (this.isSaveQuoteButtonClicked == false) {
                            let refreshQuote = new CustomEvent('refreshquote', { detail: { quoteId: this.quoteId } });
                            this.dispatchEvent(refreshQuote);
                        }

                        if (this.isEditQuoteButtonClicked)
                            this.openModalEditQuote = true;
                        this.isEditQuoteButtonClicked = false;

                        if (this.isSaveQuoteButtonClicked) {

                            // const isValid = this.validateField();
                            // if(!isValid) {
                            //     this.showToast('Error', 'Some values is invalid!','error')
                            //     return;
                            // }

                            var clone = JSON.parse(JSON.stringify(this._compareItem));
                            clone.quoteFields.forEach(item => {
                                if (item.fieldId != '' || item.fieldId != undefined) {
                                    let id = item.fieldId.split('-');
                                    item.fieldId = id[0];
                                }
                            })
                            const editQuoteEvt = new CustomEvent(
                                "updatequote", {
                                detail: {
                                    quoteId: this.quoteId, quoteName: this.quoteName, data: clone, quoteVerId: ''
                                },
                            });
                            this.dispatchEvent(editQuoteEvt);
                            this.isDisabledButton = true;
                        }
                        this.isSaveQuoteButtonClicked = false;
                    } else {
                        this.showToast('Error', response.errors[0], 'error');
                    }
                }).catch(error => { this.showToast('Error', error, 'error'); })
            } else {
                if (this.isEditQuoteButtonClicked)
                    this.openModalEditQuote = true;
                this.isEditQuoteButtonClicked = false;
            }
        }
        if (status == 'cancel') {
            this.isEditQuoteButtonClicked = false;
            this.isSaveQuoteButtonClicked = false;
            this.isLoading = false;
        }
        this.isConfirmEditModalVisible = false;

    }

    handleShowEditQuote() {
        if (this.quoteStatus == 'In Progress') {
            this.isConfirmEditModalVisible = false;
            this.openModalEditQuote = true;
        } else {
            this.isConfirmEditModalVisible = true;
            this.isEditQuoteButtonClicked = true;
        }
    }

    get disableReferralButton() {
        return (this.quoteStatus == 'Rated') ? false : true;
    }
    get isQuotedAndClear() {
        return ((this.quoteStatus === 'Quoted' || this.quoteStatus === 'Bound Pending') && this.quoteRatingStatus === 'Clear') ? true : false;
    }
    handleOpenCloseReferral(event) {
        this.isOpenReferralModel = !this.isOpenReferralModel;
        let refreshQuote = new CustomEvent('refreshquote', { detail: { quoteId: this.quoteId } });
        this.dispatchEvent(refreshQuote);
    }

    handleClosePreRateCalc(event) {
        this.openModalPreBindCalculator = !this.openModalPreBindCalculator;
    }

    handleSavePreRateCalc(event) {
        this.openModalPreBindCalculator = !this.openModalPreBindCalculator;
        this._compareItem = event.detail;
    }

    handlesaveandratepreratecalc(event) {
        this.openModalPreBindCalculator = !this.openModalPreBindCalculator;
        this._compareItem = event.detail;
        this.handleRateQuote();
    }

    handlePayPlanChange(event) {
        this.payPlanVal = event.detail.value;
    }
    handleChangeBindValue(event) {
        this.bindValue = event.detail.value;
    }
    handleBindQuote(event) {
        console.log("@@@handleBindQuote: ");
        this.openModalBindQuote = true;
    }


    @track brokerAgencyAppointed;
    //@track sanctionStatus;
    //@track kycStatus;
    @track subjectivities;
    @track proposalDate;

    getPreBindDetails() {
        getPreBindDetails({ quoteId: this.quoteId })
            .then(result => {
                result = JSON.parse(result);
                console.log('return: ' + JSON.stringify(result));
                if (result.isSuccess) {
                    console.log('Values: ' + JSON.stringify(result));
                    this.brokerAgencyAppointed = result.brokerAgencyAppointed;
                    this.proposalDate = result.proposalDate;
                    this.subjectivities = result.subjectivities;
                    this.bindPolicyValidation();
                } else {
                    this.showToast('Error', result.errMsg, 'error');
                    console.log('error: ' + JSON.stringify(result));
                }
            })
            .catch(error => {
                console.log('error: ' + JSON.stringify(error));
            })
    }

    onClickBindQuote(event) {
        if (this.isAqueousProduct) {
            this.getPreBindDetails();
        } else {
            this.bindPolicyValidation();
        }

    }

    handleRowSelection(event) {
        var selectedRows = event.detail.selectedRows;
        this.selectedBinder = selectedRows[0];
        console.log("selectedRows-->", JSON.stringify(this.selectedBinder));
    }

    bindPolicyValidation() {



        /************ New Code For Sanction *****/
        let errorMessage = [];
        
            quoteDetailsFetch({quoteId : this.quoteId}).then(result => {
                console.log('result+'+JSON.stringify(result))
               if((result.Account.CEL_Sanction_Status__c === '' || result.Account.CEL_Sanction_Status__c === undefined 
               || (result.Account.CEL_Sanction_Status__c != 'Pass' && result.Account.CEL_Sanction_Status__c != 'Cleared')) && !this.isAqueousProduct){
                errorMessage = [...errorMessage, 'Sanction Status should be Pass'];
               }
            
               
        if (this.brokerAgencyAppointed && this.isAqueousProduct) {
            // this.showToast('Error', 'Broker Agency is not Appointed', 'error');
            // return;
            errorMessage = [...errorMessage, 'Broker Agency is not Appointed'];
        }
        if (this.subjectivities && this.isAqueousProduct) {
            // this.showToast('Error', 'All Subjectivities should be Clear', 'error');
            // return;
            errorMessage = [...errorMessage, 'All Subjectivities should be Clear'];
        }
        if (this.proposalDate && this.isAqueousProduct) {
            // this.showToast('Error', 'Proposal Date should not be blank', 'error');
            // return;
            errorMessage = [...errorMessage, 'Proposal Date should not be blank'];
        }
        if (errorMessage.length != 0) {
            errorMessage.forEach(item => {
                this.showToast("Error", item, "error");
            })
            return;
        }

        this.openModalBindQuote = true;
        getPayPlanOptions({ quoteId: this.quoteId })
            .then(result => {
                console.log('Init Date from Response item =' + JSON.stringify(result));
                let options = [];
                if (result.payplanPicklist) {
                    let picklistOption = result.payplanPicklist;
                    for (let i = 0; i < picklistOption.length; i++) {
                        let option = { label: picklistOption[i], value: picklistOption[i] };
                        options.push(option);
                    }
                    this.payPlanOptions = options;
                }
              /*  if (result.showBindOptions) {
                    this.showBindOptions = result.showBindOptions;
                    this.bindValue = this.showBindOptions ? 'Bound Pending' : 'Bind';
                    console.log('this.showBindOptions::' + this.showBindOptions);
                    console.log('result.showBindOptions::' + result.showBindOptions);
                } */
                console.log('this.bindValue::' + this.bindValue);
            })
            .catch(error => {
                console.error("error" + JSON.stringify(error));
            });
            })

    }

    handlecheckSurplusLinesLicense() {
        checkSurplusLinesLicense({ quoteId: this.quoteId })
            .then(result => {
                if (!result.isSuccess) {
                    this.showToast('Warning!', result.errors[0], 'warning');
                }
            })
    }

    handleBindQuote() {
        if (!this.isAqueousProduct) {
            this.handlecheckSurplusLinesLicense();
        }

        console.log('this.selectedBroker', JSON.stringify(this.selectedBroker));

        //this.isLoading = !this.isLoading;
        if (this.isAqueousProduct) {
            this.payPlanVal = '';
            this.bindValue = 'Bound';
        }
        console.log('bindValue: ' + this.bindValue + 'Pay Plan: ' + this.payPlanVal);
        this.isBindLoading = !this.isBindLoading;
        bindQuoteWithBLInfo({ quoteId: this.quoteId, payPlan: this.payPlanVal, isBoundPending: this.bindValue == 'Bound Pending' ? true : false, blInfo : JSON.stringify(this.selectedBroker) })
        //bindQuote({ quoteId: this.quoteId, payPlan: this.payPlanVal, isBoundPending: this.bindValue == 'Bound Pending' ? true : false })
            .then(result => {
                var errMsg = '';
                if (result.isSuccess) {
                    if (result.errors) {
                        result.errors.forEach(message => {
                            this.showToast('Warning!', message, 'warning');
                        });
                    }
                    //redirect to Policy
                    if (result.data) {
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: result.data,
                                objectApiName: 'relationship_owner__c',
                                actionName: 'view'
                            }
                        });
                    } else {
                        //if stay at Quote compare, will update quote status & refresh page
                        this.quoteStatus = result.extraData.Status;

                        if (this.quoteStatus == 'Quoted') {
                            errMsg = 'Bind is fail!!';
                        }
                        //this.isLoading = !this.isLoading;
                        this.isBindLoading = !this.isBindLoading;
                        this.isQuotedClear = false;
                        this.openModalBindQuote = !this.openModalBindQuote;
                        let refreshQuote = new CustomEvent('refreshquote', { detail: { quoteId: this.quoteId } });
                        this.dispatchEvent(refreshQuote);
                    }
                } else {
                    console.log('@@@error: ' + JSON.stringify(result.errors));
                    //this.isLoading = !this.isLoading;
                    this.isBindLoading = !this.isBindLoading;
                    this.openModalBindQuote = !this.openModalBindQuote;
                    errMsg = result.errors[0];
                    //this.showToast('Error', result.errors[0], 'error');
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: (errMsg == '') ? "Success" : "Error",
                        message: (errMsg == '') ? "Bind Quote Successful" : errMsg,
                        variant: (errMsg == '') ? "Success" : "Error"
                    }),
                )
            })
            .catch(error => {
                console.log('@@@error: ' + JSON.stringify(error));
                this.isLoading = !this.isLoading;
                this.isBindLoading = !this.isBindLoading;
                this.openModalBindQuote = !this.openModalBindQuote;
                this.showToast('Error', 'Bind quote fail!', 'error');
            })
            
    }

    handleCancelBind() {
        this.openModalBindQuote = !this.openModalBindQuote;
    }

    get excessCloneClass(){
        return 'slds-float_right slds-button slds-button_icon slds-button_icon-border-filled '+(this.quoteStatus == 'Referred' ? 'enableEvents' : '');
    }

    get boundDisabled() {
        let noBound = 'main';
        let bound = 'main ' + 'bound-disabled';
        if (this.quoteStatus == 'Bound' || this.quoteStatus == 'Referred' ||
            this.quoteStatus == 'Cancelled' || this.quoteStatus == 'Correction' || //Added by Vinayesh.
            this.quoteStatus == 'Rejected' || this.submissionObj.StageName == 'Declined') {  // Added by Vinith
            return bound;
        } else {
            return noBound;
        }
        //return this.quoteStatus == 'Bound' ? bound : noBound;
    }

    //Added by Vinayesh
    get disableEndorsementsButton() {
        if ((this.boundDisabled != 'main' || this.isLockedQuote) && this.quoteStatus != 'Bound') {
            return true;
        }

        return false;
    }

    get quoteLinkEnabled() {
        if (!this.isAqueousProduct) {
            return this.quoteStatus != 'Bound' ? true : false;
        }
        return true;
    }
    @track binderLayer;
    @track disableBinder = false;
    @api
    handleSelectDocumentType() {
        this.selectedType = 'quote';
        if (this.isAqueousProduct) {
            this.getBinder();
            console.log('isPrimaryQuote-->' + this.isPrimaryQuote);
            if (this.isPrimaryQuote == 'true') {
                this.binderLayer = 'Primary Binder';
            }
            if (this.isPrimaryQuote == 'false') {
                this.binderLayer = 'Excess Binder';
            }
        }
        this.isSelectDocumentType = true;
        this.downloadDocument = false;
    }
    @track binderOptions;
    @track defaultBinder;
    @track binderParam;

    handleBinderOption(event) {
        this.defaultBinder = event.target.value;
        console.log(this.defaultBinder);
    }

    getBinder() {
        getBinder({ submissionId: this.quoteProcessSubmissionId, documentType: this.selectedType, layer: this.isPrimaryQuote == 'true' ? 'Primary' : 'Excess' })
            .then((result) => {
                console.log('Result: ' + JSON.stringify(result));
                this.binderParam = result;
                let options = [];
                let binderOption = result;
                for (let i = 0; i < binderOption.length; i++) {
                    let option = { label: binderOption[i], value: binderOption[i] };
                    options.push(option);
                }

                this.binderOptions = options;
                console.log('binderOptions: ' + JSON.stringify(this.binderOptions));
                if (this.binderOptions.length > 0) {
                    this.disableBinder = false;
                    this.defaultBinder = this.binderOptions[0].value;
                } else {
                    this.disableBinder = true;
                    this.showToast("Warning!", 'Quote should be in Quoted State for Document', "warning");
                    this.isSelectDocumentType = false;
                    this.isGenerateDocument = false;
                }
            })
            .catch((e) => {
                this.showToast("Error", JSON.stringify(e), "error");
                console.log('Error: ' + JSON.stringify(e));
            });

    }
    handleCloseDocument() {
        this.isSelectDocumentType = false;
    }

    @track downloadDocument = false;

    @api
    handleSelectDownloadDocument() {
        if (this.isAqueousProduct) {
            if (this.isPrimaryQuote == 'true') {
                this.binderLayer = 'Primary Binder';
            }
            if (this.isPrimaryQuote == 'false') {
                this.binderLayer = 'Excess Binder';
            }
            this.getBinder();
        }
        this.selectedType = 'quote';
        this.downloadDocument = true;
        this.isSelectDocumentType = true;
    }

    get documentType() {
        if (this.isAqueousProduct) {
            return [
                { label: 'Quote Schedule', value: 'quote' },
                /* { label: 'IPIDs ', value: 'IPIDs' },
                 { label: 'Policy Wording', value: 'policyWording' }*/
            ];
        } else {
            return [
                { label: 'Quote', value: 'quote' }
                //  { label: 'Worksheet ', value: 'worksheet' },
            ];
        }

    }

    handleChangeDocument(event) {
        this.selectedType = event.detail.value;
    }

    handleDocumentType(event) {
        console.log('Document Type: ' + this.selectedType);
        console.log('product: ' + this.isAqueousProduct);
        let status = event.target.name;
        console.log('status: ' + status);
        if (status == 'confirm') {
            if (!this.selectedType) {
                this.showToast('Error', 'Please select a type!', 'error');
                return;
            }
            if (this.isAqueousProduct) {
                if (!this.defaultBinder) {
                    this.showToast('Error!', 'Binder is Mandatory for Document!', 'Error');
                    return;
                }
            }

            this.isSelectDocumentType = false;

            if (this.isAqueousProduct) {
                this.handleGenerateDocumentforAqueous();
            }
            else {
                this.handleGenerateDocument();
            }
        }
        else if (status == 'cancel') {
            this.isSelectDocumentType = false;
        }
    }

    handleGenerateDocumentforAqueous() {
        console.log('Inside Aqueous');
        this.isGenerateDocument = true;
        generateDocIdAQ({ submissionId: this.quoteProcessSubmissionId, binder: this.defaultBinder, documentType: this.selectedType, layer: this.isPrimaryQuote == 'true' ? 'Primary' : 'Excess' })
            .then((result) => {
                console.log('Result: ' + JSON.stringify(result));
                this.showToast(
                    (!result.errMsg) ? 'Success' : 'Error',
                    (!result.errMsg) ? 'Document has been generated successfully!' : result.errMsg,
                    (!result.errMsg) ? 'success' : 'error'
                );
                this.isGenerateDocument = false;
            })
            .catch((e) => {
                this.showToast("Error", JSON.stringify(e), "error");
                console.log('Error: ' + JSON.stringify(e));
            });
    }
    handleSortdata(event) {
        // field name
        this.sortBy = event.detail.fieldName;
        if (event.detail.fieldName == 'Link_Document__c') {
            event.detail.fieldName = 'Name';
        }
        console.log('event.detail.fieldName:' + event.detail.fieldName);
        // sort direction
        this.sortDirection = event.detail.sortDirection;
        console.log('this.sortDirection:' + this.sortDirection);
        // calling sortdata function to sort the data based on direction and selected field
        this.sortData(event.detail.fieldName, event.detail.sortDirection);
    }
    sortData(fieldname, direction) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.referralReasonsList));
        console.log('this.sortDirection:' + this.sortDirection);
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };

        // cheking reverse direction 
        let isReverse = direction === 'asc' ? 1 : -1;

        // sorting data 
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';

            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });

        // set the sorted data to data table data
        this.referralReasonsList = parseData;

    }
    handleGenerateDocument() {
        this.isGenerateDocument = true;
        generateDocId({ quoteId: this.quoteId, documentType: this.selectedType })
            .then((result) => {
                console.log('Result: ' + JSON.stringify(result));
                this.showToast(
                    (!result.errMsg) ? 'Success' : 'Error',
                    (!result.errMsg) ? 'Document has been generated successfully!' : result.errMsg,
                    (!result.errMsg) ? 'success' : 'error'
                );
                this.isGenerateDocument = false;
            })
            .catch((e) => this.showToast("Error", JSON.stringify(e), "error"));
            //setTimeout(() => {
             //   console.log('Set Time for doc' );
             //   this.downloadDocumentCel();
            //}, 5000);
            //this.downloadCelerityQuoteDocument();      
    }


    // Added by Vinayesh on 24/5/2021 for US: 46242
    generateDocumentOnFinalize() {
        this.selectedType = 'quote';
        if (!this.isAqueousProduct) {
            this.handleGenerateDocument();
        }          
    }

    closeBinderModal() {
        this.showBinderDialog = false;
    }
    showReferralReasons() {
        if (this.isAqueousProduct) {
            this.isLoading = true;
            getReferralReasons({ quoteId: this.quoteId })
                .then(result => {
                    if (result.length > 0) {
                        this.referralReasonsList = result;
                        console.log("referralReasonsList-->", JSON.stringify(this.referralReasonsList));
                        this.showReferralReasonPopUp = true;
                        this.isLoading = false;
                    } else {
                        this.isLoading = false;
                        this.showToast("", "There are no Referral Reasons found. Try Rating the quote.", "warning");
                    }
                })
                .catch(error => {
                    this.isLoading = false;
                    console.log("Error-->", JSON.stringify(error));
                    this.showToast('Error', error, 'error');
                });
        }
    }
    handleRateQuoteController() {

        // const isValid = this.validateField();
        // console.log("handleRateQuoteController -> isValid", isValid)
        // if(!isValid) {
        //     this.showToast('Error', 'Some values is invalid!','error')
        //     return;
        // }

        this.isLoading = true;
        //this.proceedAheadToRateQuote();
        if (this.isAqueousProduct && this.isInceptionDateEdited) {
            console.log("this.editedEffectiveDate-->", this.editedEffectiveDate);
            getMasterBindersFromQuote({ quoteId: this.quoteId, effectiveDate: this.editedEffectiveDate })
                .then(result => {
                    this.isLoading = false;
                    this.bindersList = result;
                    var quoteLayer = '';
                    if (this.isPrimaryQuote == 'false') {
                        quoteLayer = 'Excess';
                    } else {
                        quoteLayer = 'Primary';
                    }
                    var bindList = [];
                    for (var i = 0; i < this.bindersList.length; i++) {
                        if (this.bindersList[i].Layer__c.includes(quoteLayer)) {
                            bindList.push(this.bindersList[i]);
                            console.log("Includes");
                        }
                    }
                    this.bindersList = bindList;
                    if (this.bindersList.length > 1) {
                        this.showBinderDialog = true;
                    } else {
                        if (this.bindersList.length == 1) {
                            this.selectedBinder = this.bindersList[0];
                            this.proceedRateQuote();
                        }
                    }
                    console.log('Binders-->:' + JSON.stringify(result));
                })
                .catch(error => {
                    this.isLoading = false;
                    console.log("Error-->", JSON.stringify(error));
                    this.showToast('Error', error, 'error');
                });
        } else if (this.isAqueousProduct && !this.isInceptionDateEdited) {
            this.proceedAheadToRateQuote();
        }
        else {
            this.proceedAheadToRateQuote();
        }
    }
    proceedRateQuote() {
        if (this.isAqueousProduct) {
            if (this.selectedBinder == null || this.selectedBinder == '' || this.selectedBinder == undefined) {
                this.showToast("Error", "Please select a Binder to Rate Quote", "error");
                return;
            } else {
                this.showBinderDialog = false;
                this.proceedAheadToRateQuote();
            }
        }
    }
    proceedAheadToRateQuote() {
        this.isLoading = true;
        var clone = JSON.parse(JSON.stringify(this._compareItem));
        console.log("Binder-->", JSON.stringify(this.selectedBinder));
        clone.quoteFields.forEach(item => {
            if (item.fieldId != '' || item.fieldId != undefined) {
                let id = item.fieldId.split('-');
                item.fieldId = id[0];
            }
        })
        const editQuoteEvt = new CustomEvent(
            "updatequote", {
            detail: {
                quoteId: this.quoteId, quoteName: this.quoteName, data: clone, quoteVerId: '', isRate: true,
                fromResponse: true, selectedBinder: this.selectedBinder
            },
        });
        this.dispatchEvent(editQuoteEvt);
        let refreshQuote = new CustomEvent('refreshquote', { detail: { quoteId: this.quoteId } });
        this.dispatchEvent(refreshQuote);
        this.isDisabledButton = true;
    }
    handleClickRateModal(event) {
        let status;
        if (this.isAqueousProduct) {
            status = event.detail.status;
        } else {
            status = 'confirm';
        }
        console.log('Status' + status);
        /*let status = event.detail.status;;*/
        console.log('status: ' + status);
        if (status == 'confirm') {
            this.isLoading = true;
            updateQuoteInProgress({ quoteId: this.quoteId }).then(response => {
                if (response.isSuccess) {
                    this.handleRateQuoteController();
                    //this.isConfirmRateQuote = false;
                } else {
                    this.showToast('Error', response.errors[0], 'error');
                    this.isLoading = false;
                    // this.isConfirmRateQuote = false;
                }
            }).catch(error => {
                this.showToast('Error', error, 'error');
                this.isLoading = false;
            })
            this.isConfirmRateQuote = false;
        } else {
            this.isConfirmRateQuote = false;
        }
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

    @track columns = [
        { label: 'Name', fieldName: 'name', type: 'text', editable: false, wrapText: true },
        { label: 'Current Value', fieldName: 'currentValue', type: 'text', editable: false, wrapText: true },
        { label: 'Prior Value', fieldName: 'priorValue', type: 'text', editable: false, wrapText: true }
    ];

    @track isFactorSummary;
    @track summaryData;
    @track tableLoading = true;
    handleFactorSummaryClick() {
        getFactorSummarys({ quoteId: this.quoteId })
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
                if (this.isAqueousProduct && oppType == 'Renewal') this.columns = this.columns.filter(col => col.fieldName !== 'priorValue');
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
    // handleError(event){
    //     console.log('event.detail.error:'+error);
    //     this.dispatchEvent(
    //         new ShowToastEvent({
    //             title: 'Error in Record Update',
    //             message: 'Unable to Update Record, Please Enter Valid Data',
    //             variant: 'error',
    //         }),
    //     )  
    // }

    handlePreRateCalculator(event) {
        console.log("@@@handlePreRateCalculator: ");
        this.openModalPreBindCalculator = true;
    }
    checkInsurerDetails(insurerDetails) {
        console.log('Insurer Details --> ' + JSON.stringify(insurerDetails));
        let returnVal = false;
        insurerDetails.every(item => {
            console.log(JSON.stringify(item));
            if (item.Insurer__c == '' || item.Insurer__c == undefined || item.Insurer_Policy_Number__c == '' || item.Insurer_Policy_Number__c == undefined) {
                returnVal = true;
                return false;
            }
            return true;
        })
        console.log('return val -->' + returnVal)
        return returnVal;
    }
    checkPartFixedEndorsement() {
        console.log('check part fixed:');
        checkPartFixedEndorsement({ quoteId: this.quoteId })
            .then(result => {
                console.log('result -->' + JSON.stringify(result))
                if (result == true) {
                    console.log('result:');
                    this.partFixedRes = true;
                    this.handleFinalize();
                }
                else {
                    this.partFixedRes = false;
                    this.handleFinalize();
                }
            })
            .catch(error => {
                console.log('error ->' + JSON.stringify(error))
            })
    }
    handleSelectedBrokerChange( event ) {
        console.log( 'Value from Child LWC is ',JSON.stringify( event.detail ) );
        this.selectedBroker = event.detail;
    }
}