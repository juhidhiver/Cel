import { LightningElement, api, wire, track } from 'lwc';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import FINALIZE_QUOTE_ICON from '@salesforce/resourceUrl/FinalizeQuoteIcon';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import QUOTE_OBJECT from '@salesforce/schema/Quote';
import CLOSED_REASON_FIELD from '@salesforce/schema/Quote.Closed_Reason__c';
import checkIsPrimaryBroker from '@salesforce/apex/FinalizeQuoteController.checkIsPrimaryBroker';
import handleCloseReasons from '@salesforce/apex/FinalizeQuoteController.handleCloseReasons';
import getQuoteApprovalComments from '@salesforce/apex/FinalizeQuoteController.getQuoteApprovalComments';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getRatingFromCallOut from '@salesforce/apex/RateController.getRatingFromCallOut';
import finalizeQuote from '@salesforce/apex/FinalizeQuoteController.finalizeQuote';
import updateQuoteInProgress from '@salesforce/apex/QuoteCompareItemWrapper.updateQuoteInProgress';
import updateSelectedBinder from '@salesforce/apex/QuoteCompareItemWrapper.updateSelectedBinder';
import bindQuoteQC from '@salesforce/apex/BindQuoteController.bindQuoteQC';
import getPayPlanOptions from '@salesforce/apex/BindQuoteController.getInitData';
import getInitData from '@salesforce/apex/BindQuoteController.getInitData';
import getQuoteDetails from '@salesforce/apex/FinalizeQuoteController.getQuoteDetails';
import generateDocId from '@salesforce/apex/GenerateQuoteDocumentController.generateDocId';
import getDocumentEncodeByQuoteId from '@salesforce/apex/ViewDocumentController.getDocumentEncodeByQuoteId';
import getDocumentEncodeByQuoteIdAQ from '@salesforce/apex/ViewDocumentController.getDocumentEncodeByQuoteIdAQ';
import getDocumentEncodeByQuoteIdAQQC from '@salesforce/apex/ViewDocumentController.getDocumentEncodeByQuoteIdAQQC';
import checkSurplusLinesLicense from '@salesforce/apex/BindQuoteController.checkSurplusLinesLicense';
import getFactorSummarys from '@salesforce/apex/FactorSummaryController.getFactorSummarys';
import quoteDetails from '@salesforce/apex/FinalizeQuoteController.quoteDetails';
import getReferralReasons from '@salesforce/apex/FinalizeQuoteController.getReferralReasons';
import getMasterBindersFromQuote from '@salesforce/apex/OpportunityModifiersCmpController.getMasterBindersFromQuote';
import getPreBindDetails from '@salesforce/apex/BindQuoteController.getPreBindDetails';
import generateDocIdAQ from '@salesforce/apex/GenerateQuoteDocumentController.generateDocIdAQ';
import getMastreBinderName from '@salesforce/apex/GenerateQuoteDocumentController.getMastreBinderName';
import generateDocIdAQQC from '@salesforce/apex/GenerateQuoteDocumentController.generateDocIdAQQC';
import getBinder from '@salesforce/apex/GenerateQuoteDocumentController.getBinder';
import { updateRecord } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/Quote.Id';
import STATUS_FIELD from '@salesforce/schema/Quote.Status';
import checkPartFixedEndorsement from '@salesforce/apex/FinalizeQuoteController.checkPartFixedEndorsement';
import checkSelectedQuoteOption from '@salesforce/apex/FinalizeQuoteController.checkSelectedQuoteOption';
import generateApprovalURL from '@salesforce/apex/FinalizeQuoteController.generateApprovalURL';
import validateSyncForQuoteBind from '@salesforce/apex/FinalizeQuoteController.validateSyncForQuoteBind';
import fetchErpProductInfo from '@salesforce/apex/NewEndorsementController.fetchErpProductInfo';
import finalizeAndGenerateDocAQ from '@salesforce/apex/FinalizeService.finalizeAndGenerateDocAQ';

// added By Jai on 12-Nov-2021 for User Story - 52958--- code start----
import Bind_Error_Broker_not_MRe_Appointed from '@salesforce/label/c.Bind_Error_Broker_not_MRe_Appointed';
import Bind_Error_Broker_Agency_not_MRe_Appointed from '@salesforce/label/c.Bind_Error_Broker_Agency_not_MRe_Appointed';
import fetchMReAppointmentDetails from '@salesforce/apex/BindQuoteController.fetchMReAppointmentDetails';
import quoteDetailsFetch from '@salesforce/apex/BindService.fetchQuoteDetail';
import checkAdmittedState from '@salesforce/apex/QuoteCompareItemWrapper.checkAdmittedState';


// ****** for ticket 54090 ****/
import getBinderDetail from '@salesforce/apex/OpportunityModifiersCmpController.getBinderDetail';

// added By Jai on 12-Nov-2021 for User Story - 52958--- code end----

const quoteConsoleTableColumns = [
    { label: 'Limit', fieldName: 'Limit1', type: 'number', cellAttributes: { alignment: 'left' }, fixedWidth: 80 },
    { label: 'BP', fieldName: 'Limit2', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left' }, fixedWidth: 100 },
    { label: 'TP', fieldName: 'Limit3', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left' }, fixedWidth: 100 },
    { label: 'AP', fieldName: 'Limit4', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left' }, fixedWidth: 100 },
    { label: 'BNDP', fieldName: 'Limit5', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left' }, fixedWidth: 100 },
    { label: 'Fee', fieldName: 'Limit6', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left' }, fixedWidth: 90 },
    { label: 'TP Discretion (%)', fieldName: 'Limit7', type: 'number', typeAttributes: { minimumFractionDigits: '2' }, cellAttributes: { alignment: 'left' }, fixedWidth: 80 },
    { label: 'Final Discretion (%)', fieldName: 'Limit8', type: 'number', typeAttributes: { minimumFractionDigits: '2' }, cellAttributes: { alignment: 'left' }, fixedWidth: 80 },
    { label: 'Price Adequacy (%)', fieldName: 'Limit9', type: 'number', typeAttributes: { minimumFractionDigits: '2' }, cellAttributes: { alignment: 'left' }, fixedWidth: 80 },
    { label: 'AP', fieldName: 'Limit10', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left' }, editable: true, fixedWidth: 100 },
    { label: 'BNDP', fieldName: 'Limit11', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left' }, editable: true, fixedWidth: 100 },
    { label: 'Fee', fieldName: 'Limit12', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: 'symbol' }, cellAttributes: { alignment: 'left' }, editable: true, fixedWidth: 90 },
];

export default class QuoteComparisonResponseItem extends NavigationMixin(LightningElement) {
    data = [{ "Limit1": 100000, "Limit2": 1000, "Limit3": 1000, "Limit4": 1000, "Limit5": 1000, "Limit6": 100, "Limit7": 1, "Limit8": 1, "Limit9": 1, "Limit10": 1000, "Limit11": 1000, "Limit12": 100 },
    { "Limit1": 100000, "Limit2": 1000, "Limit3": 1000, "Limit4": 1000, "Limit5": 1000, "Limit6": 100, "Limit7": 1, "Limit8": 1, "Limit9": 1, "Limit10": 1000, "Limit11": 1000, "Limit12": 100 },
    { "Limit1": 100000, "Limit2": 1000, "Limit3": 1000, "Limit4": 1000, "Limit5": 1000, "Limit6": 100, "Limit7": 1, "Limit8": 1, "Limit9": 1, "Limit10": 1000, "Limit11": 1000, "Limit12": 100 },
    { "Limit1": 100000, "Limit2": 1000, "Limit3": 1000, "Limit4": 1000, "Limit5": 1000, "Limit6": 100, "Limit7": 1, "Limit8": 1, "Limit9": 1, "Limit10": 1000, "Limit11": 1000, "Limit12": 100 },
    { "Limit1": 100000, "Limit2": 1000, "Limit3": 1000, "Limit4": 1000, "Limit5": 1000, "Limit6": 100, "Limit7": 1, "Limit8": 1, "Limit9": 1, "Limit10": 1000, "Limit11": 1000, "Limit12": 100 }
    ];
    quoteConsoleTableColumns = quoteConsoleTableColumns;

    // added by Jai 27-Oct-2021
    quoteStatusAndRatingStatus = '';
    // added By Jai on 10-Nov-2021 for User Story - 52958--- code start----
    isAppointExistForBroker;
    isAppointExistForAgency;
    isAppointNeededForBroker;
    isAppointNeededForAgency;
    // added By Jai on 10-Nov-2021 for User Story - 52958--- code end----
    helpTextIneligible = '';
    showQuoteTable = true;
    showPreBindScreen = false;
    jobIdOfPreBindSyncCall;
    @api quoteName = '';
    @api quoteStatus;
    @api submissionObj;
    @api isAqueousProduct;
    isPCCProduct = false;
    @api quoteType;
    @api quoteLayer;
    @api quoteUrl = '';
    @api quoteRatingStatus = '';
    @api isLoading = false;
    @api aggregateLimit;
    @api sublimitsAndEndorsements;
    @track modeEdit = true;
    @track isRateLoading = false;
    isAdmittedState = true;
    @api retentionVal;
    @api supplePaySelected = '10k / 10k';
    @api retroDate;
    @api isReadyToSave = false;
    @api quoteProcessSubmissionId;
    @track disableEndosementButton = false;
    showBindButtonForAmendments = false;
    //@api mainColumnWrapper;
    _compareItem;
    @api quoteId = '';
    @api prevQuoteValues = [];
    @api activeSections = [];
    @api isOptionSelected = false;
    @api isPrimaryDisableButton = false;
    @api isExcessDisableButton = false;
    @api isReferredQuoteLocked;
    isQuoteInceptionDateEdited;
    erpDurationMappings=[];

    //properties to send parameters for Custom Related List: Quotes Related List
    quoteRelatedListHeaderPrimary = 'Primary Quotes';
    quoteRelatedListHeaderExcess = 'Excess Quotes';
    quoteRLIconName = 'standard:quotes';
    quoteRLObjectApiName = 'Quote';
    quoteRLChildRelationshipName = 'Quotes';
    quoteRLRelationshipFieldAPIName = 'OpportunityId';
    quoteRLFieldConfigDetails = '"label":"","apiName":"QuoteNumber","isHyperlink":"true","":"navigateToRecord":"true";;"label":"Quote Name","apiName":"Name","isHyperlink":"true","":"navigateToRecord":"true";;"label":"Status","apiName":"Status","isHyperlink":"false","":"navigateToRecord":"";;"label":"Layer","apiName":"Layer__c","isHyperlink":"false","":"navigateToRecord":"";;"label":"Type","apiName":"Quote_Type__c","isHyperlink":"false","":"navigateToRecord":""';
    relatedListPrimarySoqlWhereCondition = ' AND Layer__c = \'Primary\'';
    relatedListExcessSoqlWhereCondition = ' AND Layer__c = \'Excess\'';
    buttonLabelPrimary = 'New Primary Quote';
    buttonLabelExcess = 'New Excess Quote';

    //properties to send parameters for Custom Related List: Doc Revisions Related List
    docRevisionsRelatedListHeader = 'Document Revisions';
    docRevisionsRLIconName = 'custom:custom20';
    docRevisionsRLObjectApiName = 'Document_Revision__c';
    docRevisionsRLChildRelationshipName = 'Document_Revisions';
    docRevisionsRLRelationshipFieldAPIName = 'Quote_Id__c';
    docRevisionsRLFieldConfigDetails = '"label":"","apiName":"Name","isHyperlink":"true","":"navigateToRecord":"false";;"label":"Created Date","apiName":"CreatedDate","isHyperlink":"false","":"navigateToRecord":""';
    docRevisionsButtonLabel = 'Generate Document';

    finalizeQuoteIcon = FINALIZE_QUOTE_ICON;
    @track isQuotedClear;
    @api isQuotedStatus;
    @api isLockedQuote = false;
    @api isPrimaryQuote;
    @track sortBy;
    @track sortDirection;
    @track showReferralReasonPopUp = false;
    @track referralReasonsList = [];
    @api listMainSections = [];

    @track bindersList = [];
    @track showBinderDialog = false;
    @track selectedBinder;
    @track binderColumns = [
        { label: 'Master Binder Name', fieldName: 'Name', type: "text" },
        { label: "Inception Date", fieldName: 'Inception_Date__c', type: "text" },
        { label: "Expiration Date", fieldName: 'Expiry_Date__c', type: "text" }
    ];
    @track referralReasonColumns = [
        { label: 'Approval Level Required', fieldName: 'ApprovalLevelRequired', type: "text", sortable: "true" },
        { label: "Reason Description", fieldName: 'Reason', type: "text", initialWidth: 400, wrapText: true },        
        { label: "Approval Status", fieldName: 'ApprovalStatus', type: "text", sortable: "true" },
        { label: "Approval/Rejected Date", fieldName: 'ApprovalRejectedDate', type: "date" },
        { label: "Approved By", fieldName: 'ApprovedBy', type: "text" },
        { label: "Reason Type", fieldName: 'ReasonType', type: "text" },
        { label: "Quote Option Limit", fieldName: 'QuoteOptionLimit', type: "text", sortable: "true" }
    ];
    @track approvalCommentsColumns = [
        { label: 'Approved/Rejected By', fieldName: 'actorName', type: "text"},
        { label: 'Approval Status', fieldName: 'approvalStatus', type: "text"},
        { label: "Comments", fieldName: 'comments', type: "text" },                
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

    @track approvalCommentsList;
    @track showCommentsTable = false;

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

    @track approvalLink = '';

    @track noRowSelected = false;
    
    isMasterBinder = false;
    
    generateApprovalURL() {
        generateApprovalURL({ quoteId: this.quoteId })
            .then((result) => {
                if (result !== '') {
                    this.approvalLink = result;
                    window.open(this.approvalLink, '_blank');
                }
                else {
                    this.showToast('', 'There are no quotes for you to approve', 'warning');
                }
            })
            .catch((error) => {
                this.showToast('Error', JSON.stringify(error), 'error');
            })
    }
    closeCommentsTable(){
        this.showCommentsTable = false;
    }
    getQuoteApprovalComments(){        
        getQuoteApprovalComments({ quoteId: this.quoteId })
            .then((result) => {
                if (result) {
                    if(result.length != 0){
                        this.approvalCommentsList = result;
                        this.showCommentsTable = true;
                    }else{
                        this.showToast('', 'There are no Comments available for this Quote', 'warning');
                    }                    
                }
                else {
                    this.showToast('', 'There are no Comments available for this Quote', 'warning');
                }
            })
            .catch((error) => {
                console.log('@@@error: ' + JSON.stringify(error));
                this.showToast('Error', JSON.stringify(error), 'error');
            })
    }

    @track closeReason;
    @track selectedType;

    @track payPlanOptions
    @track payPlanVal;
    @track defaultOpportunityInceptionDate;
    @track bindValue = '';
    get bindOptions() {
      
        return [
            { label: 'Bound Pending', value: 'Bound Pending' },
            { label: 'Bind', value: 'Bind' },
        ];
    }
    @track showBindOptions;
    @track isBoundPending;
    @track isInceptionDateEdited = false;
    @track isBindLoading = false;
    @track partFixedRes = false;
    @wire(getObjectInfo, { objectApiName: QUOTE_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: CLOSED_REASON_FIELD })
    ClosedReasonPicklistValues;

    @api totalPremiumValue;
    @api recordId;
    @api masterBinder;
    //Code modified in 4/8/2020
    @api rateQuote() {
       
        this.isLoading = true;
        if (this.isAqueousProduct && (this.isInceptionDateEdited || this.isQuoteInceptionDateEdited)) {
            if (this.bindersList.length > 1) {
                if (this.selectedBinder != null || this.selectedBinder != undefined || this.selectedBinder != '') {
                    updateSelectedBinder({ quoteId: this.quoteId, selectedBinder: JSON.stringify(this.selectedBinder) })
                        .then(response => {
                            this.isInceptionDateEdited = false;
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
            } else {
                this.showToast("Error", "No Binders Available", "error");
                this.isLoading = false;
            }
        } else {
            this.goToRateQuote();
        }
    }
    goToRateQuote() {
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
                
                //}
                // let rateFinish = new CustomEvent('ratefinish', { detail: { quoteId: this.quoteId } });
                // this.dispatchEvent(rateFinish);
            }
            let refreshQuote = new CustomEvent('refreshquotedetail', { detail: { quoteId: this.quoteId } });
            this.dispatchEvent(refreshQuote);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: (errMsg == '') ? "Success" : "Error",
                    message: (errMsg == '') ? "Rating successfully!" : errMsg,
                    variant: (errMsg == '') ? "Success" : "Error"
                }),
            )
            if(!this.isAqueousProduct){
                this.template.querySelector("c-quote-premium-calculator").handleRefreshPremiumCalculator();
            }
            this.isLoading = false;
        }).catch(error => {
            console.log("error.message", JSON.stringify(error.message));
            this.showToast('Error', error, 'error');
            this.isLoading = false;
        })
    }
    set compareItem(value) { 
        this._compareItem = value;
        var quoteLayer = this.compareItem.quoteLayer;
        this.quoteLayer = quoteLayer;
        var quoteType = this.compareItem.quoteType;
        this.quoteType = quoteType;
        var quoteStatus = this.compareItem.quoteStatus;
        
        //added by Jai 27-Oct-2021
        var quoteRecord = this.compareItem.quoteRecord;
        var boolIsQuoteInceptionDateEdited = false;
        if(quoteRecord.Is_Inception_Date_Edited__c){
            boolIsQuoteInceptionDateEdited = true;
        }
        this.isQuoteInceptionDateEdited = boolIsQuoteInceptionDateEdited;
        this.helpTextIneligible = '';
        /*var listMainSections = JSON.parse(JSON.stringify(this.listMainSections));
        if (
            this.quoteType != 'Full Amendment' ||
            this.quoteType != 'Coverage Amendment' ||
            this.quoteType != 'Midterm Cancellation' ||
            this.quoteType != 'Flat Cancellation'
        ) {
            listMainSections.splice(4, 1);
            // for (var i = 0; i< listMainSections[4].childs.length; i++) {
            //     listMainSections[4].childs[i].readOnly = false;
            // }
        } else {
            for (var i = 0; i< listMainSections[4].childs.length; i++) {
                listMainSections[4].childs[i].readOnly = false;
            }
        }
        this.listMainSections = JSON.parse(JSON.stringify(listMainSections));*/
        var clone = JSON.parse(JSON.stringify(this._compareItem));
        clone.quoteFields.forEach(item => {
            // if(item.value === '')
            //     item.value = 'Default';
            item.options = [];
            let picklistOption = item.picklistOption.split(";");
            for (let i = 0; i < picklistOption.length; i++) {
                let option = { label: picklistOption[i], value: picklistOption[i] };
                item.options.push(option);
            }
            if(item.sourceFieldAPI === 'Policy_Wording__c' && (quoteStatus === 'Bound' || quoteStatus === 'Closed')){
                var options = item.options;
                var value = item.value;
                if(!options.includes(value)){
                    let option = { label: value, value: value };
                    options.push(option);
                }
            }
            if (item.endorsementType && quoteType) {
                if ((item.endorsementType.includes('Midterm Cancellation') && quoteType == 'Midterm Cancellation') ||
                    (item.endorsementType.includes('Full Amendment') && quoteType == 'Full Amendment') ||
                    (item.endorsementType.includes('Coverage Amendment') && quoteType == 'Coverage Amendment') ||
                    (item.endorsementType.includes('Policy Duration Change') && quoteType == 'Policy Duration Change') ||
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
                if ((item.endorsementType.includes('Full Amendment') && quoteType == 'Full Amendment')
                    && (item.sourceFieldAPI == 'Commission_percentage__c' || item.sourceFieldAPI == 'MGA_Commission__c')) {
                    item.readOnly = false;
                }
            }
            if (item.sourceFieldAPI == 'Endorsement_Effective_Date__c' || item.sourceFieldAPI == 'Endorsement_Reason__c') {
                item.readOnly = false;
            }
            if(((quoteType == 'Full Amendment' || quoteType == 'Coverage Amendment'  || quoteType == 'Renewal') && item.sourceFieldAPI == 'Effective_Date__c')
                || ((quoteType == 'Full Amendment' || quoteType == 'Coverage Amendment') && item.sourceFieldAPI == 'ExpirationDate')
                || ((quoteType == 'Midterm Cancellation' || quoteType == 'Flat Cancellation')
                    && ((item.sourceFieldAPI == 'Effective_Date__c' || item.sourceFieldAPI == 'ExpirationDate' || item.sourceFieldAPI == 'Actual_Excess__c')
                        || (item.mainSection == 'Commission Details' || item.mainSection == 'Coverage Details')))
                || ((item.sourceFieldAPI == 'Endorsement_Effective_Date__c')&&(quoteType == 'Flat Cancellation'))){
                            item.readOnly = true;
            }
            if(quoteType == 'Policy Duration Change'
                && (item.sourceFieldAPI == 'Effective_Date__c' || item.sourceFieldAPI == 'Endorsement_Reason__c'
                    || item.sourceFieldAPI == 'Commission_percentage__c' || item.sourceFieldAPI == 'MGA_Commission__c'
                    || item.sourceFieldAPI == 'Policy_Wording__c' || item.sourceFieldAPI == 'Retroactive_Date__c'
                    || item.sourceFieldAPI == 'RetroDate__c' || item.sourceFieldAPI == 'Territorial_Limits__c'
                    || item.sourceFieldAPI == 'Jurisdiction_Limits__c' || item.sourceFieldAPI == 'Limit_Basis__c'
                    || item.sourceFieldAPI == 'Excess_Basis__c' || item.sourceFieldAPI == 'Actual_Excess__c')){
                    item.readOnly = true;
            }
            // Added for R11-S2 MTA changes for PCC 
            if( !clone.quoteName.includes(' PI ')){
                if(quoteType == 'Amendment' && (item.sourceFieldAPI == 'Effective_Date__c' || item.sourceFieldAPI == 'ExpirationDate' ) ){
                    item.readOnly = true;
                }
                if( quoteType == 'Update Insured Name or Address' || quoteType == 'Policy Duration Change' || quoteType == 'Extended Reporting Period (ERP)'
                    || quoteType == 'Broker on Record Change' /* added by  jai for US 53349 */
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

                if( quoteType == 'Policy Duration Change' && item.sourceFieldAPI == 'ExpirationDate' ) {
                    item.readOnly = false;
                }
            }

            if (item.format == 'Picklist') {
                item.isPicklist = true;
            } else if (item.format == 'Radio Button') {
                item.isRadioButton = true;
            } else if (item.format == 'Integer') {
                item.isInteger = true;
            } else if (item.format == 'Percent') {
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
                    this.recordId = clone.quoteId;
                }
            }

            if (item.sourceFieldAPI == 'Effective_Date__c') {
                this.defaultOpportunityInceptionDate = item.value;
            }
            if (item.sourceFieldAPI === 'Master_Binder__c') {
                this.masterBinder = item.value;
            }  
			
			//Default values on load
			if (item.sourceFieldAPI == 'Rate_Charged__c' && !item.readOnly && (item.value=='' || item.value==null)) {
				item.value='100';
			}
			if (item.sourceFieldAPI == 'ERP_Duration__c' && !item.readOnly && (item.value=='' || item.value==null)) {
				item.value='1 Year';
			}
                    

        })

        if (this.masterBinder) {
            getMastreBinderName({ masterBinderId: this.masterBinder })
                .then(result => {
                    this.defaultBinder = result;
                });
        }

        this.selectedType = 'quote';
        this._compareItem = clone;
        this.quoteStatus = clone.quoteStatus;
        this.quoteRatingStatus = clone.quoteRatingStatus;

        // added by Jai 27-Oct-2021
        this.quoteStatusAndRatingStatus = this.quoteStatus;
        if(!clone.quoteName.includes(' PI ')){
            this.quoteStatusAndRatingStatus = this.quoteStatus +' - '+(this.quoteRatingStatus != undefined ? this.quoteRatingStatus : 'None');
        }
        if(this.quoteRatingStatus == 'Ineligible'){
            var uwCode = (quoteRecord.Overall_UW_Codes__c != undefined ? quoteRecord.Overall_UW_Codes__c : '');
            var uwReason = (quoteRecord.UW_Reason__c != undefined ? quoteRecord.UW_Reason__c : '');
            this.generateHelpTextIneligible(uwCode,uwReason);
        }

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
        if (this.quoteStatus == 'Cancelled' || this.quoteStatus == 'Correction') {
            this.isLockedQuote = true;
            this.isDisabledButton = true;
        }
        this.showBindButtonForAmendments = false;
        if (this.quoteType === 'Midterm Cancellation' || this.quoteType === 'Flat Cancellation' ||
            this.quoteType === 'Full Amendment' || this.quoteType === 'Coverage Amendment' || this.quoteType === 'Policy Duration Change') {
            this.showBindButtonForAmendments = true;
        }

        if(!clone.quoteName.includes(' PI ')){
            if(this.quoteLayer == 'Primary'){
                console.log('checkAdmittedState result ' + clone.quoteId);
                checkAdmittedState({ 'quoteId': clone.quoteId })
                .then((result) => {
                    console.log('checkAdmittedState result ' + result);
                    if(result == false){
                        this.isAdmittedState = false;
                    }
                    else{
                        this.isAdmittedState = true;
                    }
                })
                .catch((error) => {
                    console.log('checkAdmittedState error ' + error);
                })
            }
            else{
                this.isAdmittedState = false;
            }
        }
        
    }
    @api
    get compareItem() {
        return this._compareItem;
    }

    @track qId = '';
    @track qType = '';
    @track recId = '';
    connectedCallback() {
        //var quoteLayer = this.quoteLayer;
        //var quoteType = this.quoteType;
        if (this.quoteType === 'Midterm Cancellation' || this.quoteType === 'Flat Cancellation' ||
            this.quoteType === 'Full Amendment' || this.quoteType === 'Coverage Amendment' || this.quoteType === 'Policy Duration Change') {
            this.showBindButtonForAmendments = true;
        }
        /*if(this.isAqueousProduct && this.quoteStatus == 'Referred'){  //Handled at parent cmp DetailLwc
            let checkRecordLock = new CustomEvent('checkreferredquotelocking', { detail: { quoteId: this.quoteId } });
            this.dispatchEvent(checkRecordLock);
        }*/
        var stageName = this.submissionObj.StageName;

        // Added By Rinku Saini For CD-116
        if( stageName == 'Closed Lost' ){
            this.isPrimaryDisableButton = true;
            this.isExcessDisableButton = true;
            this.handleRefreshRelatedListComponent();
        }
        if (this.submissionObj.Product_Name__c == 'Professional Indemnity') {
            if (stageName == 'Closed Won' || stageName == 'Closed Lost' || stageName == 'Declined') {
                this.disableEndosementButton = true;
            }
        }
        if(this.submissionObj.Product_Name__c == 'Private Company Combo'){
            this.isPCCProduct = true;
        }
        
        
        /*var listMainSections = JSON.parse(JSON.stringify(this.listMainSections));
        if (
            this.quoteType != 'Full Amendment' ||
            this.quoteType != 'Coverage Amendment' ||
            this.quoteType != 'Midterm Cancellation' ||
            this.quoteType != 'Flat Cancellation'
        ) {
            listMainSections.splice(4, 1);
            // for (var i = 0; i< listMainSections[4].childs.length; i++) {
            //     listMainSections[4].childs[i].readOnly = false;
            // }
        } else {
            for (var i = 0; i< listMainSections[4].childs.length; i++) {
                listMainSections[4].childs[i].readOnly = false;
            }
        }
        this.listMainSections = JSON.parse(JSON.stringify(listMainSections));*/
        //registerListener('refreshDetailComponent', this.handleRefreshDetailComponent, this);
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
        if (this.quoteStatus == 'Cancelled' || this.quoteStatus == 'Correction') {
            this.isLockedQuote = true;
            this.isDisabledButton = true;
        }

        var quotes = JSON.parse(JSON.stringify(this.submissionObj.Quotes));
        for (let j = 0; j < quotes.length; j++) {
            //console.log('loop::' + quotes[j].Quote_Type__c);
            if (quotes[j].Quote_Type__c == 'Flat Cancellation (Ab - Initio)' || quotes[j].Quote_Type__c == 'Reinstatement') {
                if (quotes[j].Quote_Type__c == 'Reinstatement') {
                    this.qType = 'Reinstatement';
                    this.qId = quotes[j].Id;
                } else {
                    this.qType = 'Flat Cancellation (Ab - Initio)';
                    this.qId = quotes[j].Id;
                }
            }
        }
        this.recId = this.qId !== '' ? this.qId : this.quoteId;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recId, //Redirect to Flat Cancellation/Reinstatement quote if any 
                objectApiName: 'Quote',
                actionName: 'view',
            },
        }).then(url => {
            this.quoteUrl = url;
        });;
        //registerListener('editQuoteName', this.handleEditQuoteName, this);
        //registerListener('refreshTitleFromResponse', this.handleInitValues, this);


        /*
                //START -- Added by Sarthak on 19th June 2020
                getQuoteDetails({quoteId: this.quoteId})
                .then(result =>{
                    this.quoteInfo = result;   
                })
                .catch(error=>{
                })
            //END  -- Added by Sarthak on 19th June 2020
        */

       //this.handleRefreshRelatedListComponent();

       //fetch mapping for ERP and Product Charge
        fetchErpProductInfo({ productName: this.submissionObj.Product_Name__c, effDate: null, policyId: null })
            .then((result) => {
                if (result && result != null && result.productInfo) {
                    var productInfo = JSON.parse(result.productInfo);
                    if (productInfo.Applicable_ERP_Duration_Rate_Charged__c && productInfo.Applicable_ERP_Duration_Rate_Charged__c != null) {
                        this.erpDurationMappings = JSON.parse(productInfo.Applicable_ERP_Duration_Rate_Charged__c);
                    }
                }
            })
            .catch((error) => {
                console.log('@@@error: ' + JSON.stringify(error));
            });
    }

    renderedCallback() {
        if (this.quoteType === 'Midterm Cancellation' || this.quoteType === 'Flat Cancellation' ||
            this.quoteType === 'Full Amendment' || this.quoteType === 'Coverage Amendment' || this.quoteType === 'Policy Duration Change') {
            this.showBindButtonForAmendments = true;
        }
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
        if (!responseItem || !responseItemParent || !responseItemChild || !this.parentCmpBoundRect) return;

        var sticky = responseItem.getBoundingClientRect();
        const parentCmpBoundRect = this.parentCmpBoundRect;

        window.addEventListener('scroll', function (event) {
            var parentWidth = responseItemParent.getBoundingClientRect().width;
            if (window.pageYOffset + sticky.height >= parentCmpBoundRect.y && window.pageYOffset <= parentCmpBoundRect.height) {
                responseItem.classList.add("position-sticky");
                responseItemChild.forEach(child => {
                    child.setAttribute('style', `width: ${parentWidth}px !important`);
                });
            } else {
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

    handleEditQuoteName(event) {
        let quoteName = event.quoteName;
        let quoteId = event.quoteId;
        if (this.quoteId === quoteId) {
            // this.mainColumnWrapper.mainItem.Name = quoteName;
            this.quoteName = quoteName;
        }

    }
    disconnectCallback() {
        unregisterAllListeners(this);
    }
    handleRateQuoteWithPremiumCalculator() {
        this.template.querySelector('c-quote-premium-calculator').handleSaveAndRate();
    }
    //handle rate quote button
    handleRateQuote() {

          /******** Code for 52855 ************/
          if(this.isAqueousProduct){
            var clone = JSON.parse(JSON.stringify(this._compareItem));
            var retroDateOption;
            console.log('clone'+JSON.stringify(clone))
            clone.quoteFields.forEach(item => {
                if (item.sourceFieldAPI == 'Retroactive_Date__c' && item.value != '') {
                    retroDateOption = item.value;
                }


                if (retroDateOption == 'Date') {
                    if (item.sourceFieldAPI == 'RetroDate__c' && (item.value == '' || item.value == undefined || item.value == null)) {
                        this.showToast("Error", "Please enter Date when Retroactive Date option selected is : " + retroDateOption, "error");
                        proceedAhead = false;
                        this.isLoading = false;
                        return;
                    }
                }

            })



        }

        
        console.log('vinay rate quote isAq :' + this.isAqueousProduct);
        console.log('vinay rate quote status :' + this.quoteStatus);
        if (this.quoteStatus == 'In Progress') {
            if(this.isAqueousProduct){
                if(this.noRowSelected){
                    this.showToast('Error', 'Please select atleast one quote option for rating', 'Error');
                    return;
                }
                
                checkIsPrimaryBroker({ quoteId: this.quoteId })
                 .then(response => {

                    console.log('response',JSON.stringify(response));
                    if(response){
                        this.showToast('Warning', 'Primary Broker is Required', 'Warning');
                        return;
                    }else{
                        this.handleRateQuoteController();
                    }
                 })
                 .catch(error => {
                    this.showToast('Error', error, 'error');
                    console.log('error-->'+JSON.stringify(error));
                 })

            }else{
                this.handleRateQuoteController();
            }

        } else {
            if (!this.isAqueousProduct) {
                this.handleClickRateModal();
            } else {
                checkIsPrimaryBroker({ quoteId: this.quoteId })
                 .then(response => {
                    console.log('response',JSON.stringify(response));
                    if(response){
                        this.showToast('Warning', 'Primary Broker is Required', 'Warning');
                        return;
                    }else{
                        this.isConfirmRateQuote = true;
                    }
                 })
                 .catch(error => {
                    this.showToast('Error', error, 'error');
                    console.log('error-->'+JSON.stringify(error));
                 })
            }
        }
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
        const fieldsObj = JSON.parse(JSON.stringify(fields));
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
        
        // added by Jai 27-Oct-2021
        this.quoteStatusAndRatingStatus = this.quoteStatus;
        if(!this.quoteName.includes(' PI ')){
            this.quoteStatusAndRatingStatus = this.quoteStatus +' - '+(fieldsObj.Rating_Status__c != undefined ? fieldsObj.Rating_Status__c : 'None');
        }

        if (this.quoteStatus == 'In Progress') {
            this.isQuotedStatus = false;
            this.isStatusQuoteColumnReadOnly = false;
        }
        if (this.quoteStatus == 'Quoted' || this.quoteStatus === 'Bound Pending') {
            this.isQuotedStatus = true;
            this.isStatusQuoteColumnReadOnly = true;
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
        let refreshQuote = new CustomEvent('refreshquotedetail', { detail: { quoteId: this.quoteId } });
        this.dispatchEvent(refreshQuote);
    }
    openEndorsementModel(event) {
        this.isEndorsementModelOpen = true;

    }
    closeEndorsementModal(event) {
        this.isEndorsementModelOpen = false;
        let refreshQuote = new CustomEvent('refreshquotedetail', { detail: { quoteId: this.quoteId } });
        this.dispatchEvent(refreshQuote);
    }
    @track quoteValues;
    quoteDetails() {
        quoteDetails({ 'quoteId': this.quoteId })
            .then((result) => {
                this.quoteValues = JSON.parse(result);
                console.log('quoteValues:' + JSON.stringify(this.quoteValues));
                this.checkSelectedQuoteOption();
                //this.checkPartFixedEndorsement();
            })
            .catch((error) => {
                this.isLoading = false;
                console.log('@@@error: ' + JSON.stringify(error));
                this.showToast('Error', JSON.stringify(error), 'error');
            })
    }

    checkSelectedQuoteOption() {
        checkSelectedQuoteOption({ 'quoteId': this.quoteId })
            .then((result) => {
                if (result == true) {
                    this.isOptionSelected = true;
                }
                else {
                    this.isOptionSelected = false;
                }
                this.checkPartFixedEndorsement();
            })
            .catch((error) => {
                this.isLoading = false;
                console.log('@@@error: ' + JSON.stringify(error));
                this.showToast('Error', JSON.stringify(error), 'error');
                this.checkPartFixedEndorsement();
            })
    }

    handleFinalizeQuote(event) {
        let isValid = true;
        this.template.querySelectorAll("c-generate-output-element-q-c-l-w-c").forEach(field => {
            let checkValid = field.checkValueOutOfRange();
            if (checkValid == false) isValid = false;
        });
        if (isValid == false) {
            this.showToast('Error', 'Some values are out of range!', 'error')
            return;
        }
        this.isLoading = true;
        console.log("HandleFinalizeQuote:");
        this.quoteDetails();
    }

    handleFinalize() {
    let errorMessage = [];
      var todayDate = new Date().toISOString().slice(0, 10);
      console.log('var date ' + todayDate);
        if ((this.quoteValues.Effective_Date == '' || this.quoteValues.Effective_Date == undefined ||  this.quoteValues.EffectiveDate_45 > todayDate) && this.isAqueousProduct) {
            errorMessage = [...errorMessage, "Maximum advance Period allowed is 45 days"]
        }
        if ((this.quoteValues.Commission_percentage == '' || this.quoteValues.Commission_percentage == undefined) && this.isAqueousProduct) {
            errorMessage = [...errorMessage, "Broker Commission cannot be empty."]
        }
        if ((this.quoteValues.MGA_Commission == '' || this.quoteValues.MGA_Commission == undefined) && this.isAqueousProduct) {
            errorMessage = [...errorMessage, "MGA Commission cannot be empty."];
        }
        if ((this.quoteValues.Binder == '' || this.quoteValues.Binder == undefined) && this.isAqueousProduct) {
            errorMessage = [...errorMessage, "Binder cannot be empty."];
        }
        if ((this.quoteValues.Policy_Wording == '' || this.quoteValues.Policy_Wording == undefined) && this.isAqueousProduct) {
            errorMessage = [...errorMessage, "Policy Wording cannot be empty."];
        }
        if ((this.quoteValues.Territorial_Limits == '' || this.quoteValues.Territorial_Limits == undefined) && this.isAqueousProduct) {
            errorMessage = [...errorMessage, "Territorial Limits cannot be empty."];
        }
        if ((this.quoteValues.Jurisdiction_Limits == '' || this.quoteValues.Jurisdiction_Limits == undefined) && this.isAqueousProduct) {
            errorMessage = [...errorMessage, "Jurisdiction Limits cannot be empty."];
        }
        if ((this.quoteValues.Limit_Basis == '' || this.quoteValues.Limit_Basis == undefined) && this.isAqueousProduct) {
            errorMessage = [...errorMessage, "Limit Basis cannot be empty."];
        }
        if ((this.quoteValues.Excess_Basis == '' || this.quoteValues.Excess_Basis == undefined) && this.isAqueousProduct) {
            // this.showToast("Error", "Excess Basis cannot be empty.", "error");
            // return;
            errorMessage = [...errorMessage, "Excess Basis cannot be empty."];
        }
       if ((this.quoteValues.Account.Sanction_Status === '' || this.quoteValues.Account.Sanction_Status === undefined || (this.quoteValues.Account.Sanction_Status != 'Pass' && this.quoteValues.Account.Sanction_Status != 'Cleared')) && this.isAqueousProduct) {
            errorMessage = [...errorMessage, 'Sanction Status should be Pass'];
        }
        if ((this.quoteValues.InsurerAccountSanction) && this.isAqueousProduct) {
            errorMessage = [...errorMessage, 'All Additional Insured Accounts Sanction Status must be Pass'];
        }
        if (this.isAqueousProduct && (this.quoteValues.Layer == 'Excess')) {
            if (this.checkInsurerDetails(this.quoteValues.Insurer_Layer_Limit)) {
                errorMessage = [...errorMessage, 'Insurer Layer Details cannot be empty'];
            }
        }
        if (this.isAqueousProduct && this.partFixedRes) {
            errorMessage = [...errorMessage, 'Please fill in Part-Fixed Endorsement Values'];
        }
        if (this.isAqueousProduct && !this.isOptionSelected) {
            errorMessage = [...errorMessage, 'Please select atleast one Quote Option before you finalize the Quote'];
        }
        if (errorMessage.length != 0) {
            errorMessage.forEach(item => {
                this.showToast("Error", item, "error");
            })
            this.isLoading = false;
            return;
        }
        this.isLoading = true;
        finalizeQuote({ 'quoteId': this.quoteId })
            .then((result) => {   
                if (result.isSuccess) {
                    var currentQuote = result.data;
                    if(currentQuote.Product_Name__c == 'Professional Indemnity'){
                        finalizeAndGenerateDocAQ({ quote: currentQuote })
                        .then(result => {
                            let finalizedQuote = result;
                            this.quoteStatus = finalizedQuote.Status;

                            let refreshQuote = new CustomEvent('refreshquotedetail', { detail: { quoteId: this.quoteId } });
                            this.isLoading = false;
                            this.isQuotedClear = true;
                            this.dispatchEvent(refreshQuote);
                            this.showToast('Success', 'Finalize quote successfully!', 'success');
                        })
                        .catch(error => {
                            console.log('@@@error: ' + JSON.stringify(error));
                            this.isLoading = false;
                            this.showToast('Error', 'Finalize quote fail!', 'error');
                        });
                    }
                    else{
                        this.quoteStatus = currentQuote.Status;
                        // added by Jai 27-Oct-2021
                        this.quoteStatusAndRatingStatus = this.quoteStatus;
                        if(!this.quoteName.includes(' PI ')){
                            this.quoteStatusAndRatingStatus = this.quoteStatus +' - '+(currentQuote.Rating_Status__c != undefined ? currentQuote.Rating_Status__c:'None');
                        }

                        let refreshQuote = new CustomEvent('refreshquotedetail', { detail: { quoteId: this.quoteId } });

                        this.isLoading = false;
                        this.isQuotedClear = true;
                        this.dispatchEvent(refreshQuote);
                        this.showToast('Success', 'Finalize quote successfully!', 'success');
                    }
                }
                else{
                    console.log('@@@error: ' + JSON.stringify(result.errors));
                    this.isLoading = false;
                    let refreshQuote = new CustomEvent('refreshquotedetail', { detail: { quoteId: this.quoteId } });
                    this.dispatchEvent(refreshQuote);
                    if (result.errors[0] == 'Quote sent for Referral') {
                        this.showToast('', result.errors[0], 'warning');
                    } else if (result.errors[0] == 'Broker Agency is not Appointed') {
                        this.showToast('', result.errors[0], 'error');
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
    handleViewDocument(documentId) {
        this.isSelectDocumentType = false;
        this.isGenerateDocument = true;
        this.viewDocument = true;
        if (this.isAqueousProduct) {
            this.downloadDocumentAQ(documentId);
        } else {
            this.downloadDocumentCel();
        }

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
                if(result.statusCode == 202){
                    this.showToast(
                        '',
                        result.errMsg,
                        'Warning'
                    );
                }
                else{
                    this.showToast(
                        (!result.errMsg) ? 'Success' : 'Error',
                        (!result.errMsg) ? 'Document has been downloaded successfully!' : result.errMsg,
                        (!result.errMsg) ? 'success' : 'error'
                    );
                }
                this.viewDocument = false;
                this.isGenerateDocument = false;
            }
        )
    }

    downloadDocumentAQ(documentId) {
        getDocumentEncodeByQuoteIdAQQC({ submissionId: this.quoteProcessSubmissionId, quoteId: this.quoteId, binder: this.defaultBinder, documentType: this.selectedType, layer: this.isPrimaryQuote === true ? 'Primary' : 'Excess', documentId: documentId })
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
        const cloneQuoteEvent = new CustomEvent(
            "clonequote", {
            detail: { quoteId: this.quoteId }
        });
        this.dispatchEvent(cloneQuoteEvent);
    }

    @track closedReasons = [];
    handleCloseButtonClickEvent(event) {
        handleCloseReasons({quoteId : this.quoteId})
        .then(result => {
            this.closedReasons = [];
            for(let i = 0; i<result.length; i++){
               this.closedReasons.push({ label: result[i].label, value: result[i].value });
               this.closedReasons = JSON.parse(JSON.stringify(this.closedReasons));
               this.isConfirmModalVisible = true;
            }                 
        }).catch(error => { this.showToast('Error', error, 'error');
        console.log('error-->'+JSON.stringify(error)); })
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
        var erpDuration;
        let name = event.detail.fieldId;
        let value = event.detail.fieldValue;
        let fieldName = event.detail.fieldName;
        var quoteRatingWr = JSON.parse(JSON.stringify(this._compareItem));
        quoteRatingWr.quoteFields.forEach(item => {
            if (item.isField && item.fieldId === name) {
                item.value = value;
                if (item.sourceFieldAPI == 'Effective_Date__c') {
                    this.isInceptionDateEdited = true;
                }
                if (item.sourceFieldAPI == 'ERP_Duration__c') {
                    erpDuration=item.value;
                }
            }
        });
        this._compareItem = quoteRatingWr;
        this.isDisabledButton = false;

        //If ERP duration updated, update the Rate Charged
        if(erpDuration)
        {
            this.compareItem.quoteFields.forEach(item1 => {
            if (item1.fieldName == 'Rate Charged' && this.erpDurationMappings && this.erpDurationMappings.length>0) {
                for (var i in this.erpDurationMappings) {
                    if (this.erpDurationMappings[i].ERPDuration == erpDuration) {
                        item1.value=this.erpDurationMappings[i].RateCharged;
                    }
                }
            }	
            });
        }
        if(this.isPCCProduct && fieldName == 'KY_Tax_Rate__c'){
            this.compareItem.quoteFields.forEach(item1 => {
                if (item1.sourceFieldAPI == 'KY_Tax_Rate__c') {
                    item1.value = value;
                }	
                });
        }
    }

    // handleChangeEditMode(event) {
    //     this.modeEdit = !this.modeEdit;
    // }

    // validateField(){
    //     let isValid = true;
    //     this.template.querySelectorAll("c-generate-output-element-lwc").forEach(field => {
    //         let checkValid = field.checkValid();
    //         if(checkValid == false) isValid = false;
    //     })
    //     return isValid;
    // }
    @api
    handleSaveCompareItem(event) {
        console.log('savemethodin');
        // let isValid = true;
        // this.template.querySelectorAll("c-generate-output-element-lwc").forEach(field => {
        //     let checkValid = field.checkValid();
        //     if(checkValid == false) isValid = false;
        // })
        // if(isValid == false) {
        //     this.showToast('Error', 'Some values is invalid!','error')
        //     return;
        // }
        var isValid = true;
        this.template.querySelectorAll("c-generate-output-element-q-c-l-w-c").forEach(field => {
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
        let prevValues = this.prevQuoteValues.quoteFields;
        let newValues = this._compareItem.quoteFields;
        let valuesChanged = 0;
        for (let i = 0; i < prevValues.length; i++) {
            if (prevValues[i].fieldName == 'Binder' || prevValues[i].fieldName == 'Policy Wording' || prevValues[i].fieldName == 'Territorial Limits' || prevValues[i].fieldName == 'Retroactive Date' || prevValues[i].fieldName == 'Date') {
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
            clone.quoteFields.forEach(item => {
                console.log('item- - ', JSON.stringify(item));
                if (this.isAqueousProduct) {
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
                            return;
                        }
                    }
                    if (item.sourceFieldAPI == 'MGA_Commission__c' && this.isAqueousProduct) {
                        if (item.value == '' || item.value == null || item.value == undefined) {
                            this.showToast("Error", "MGA Commission cannot be empty.", "error");
                            proceedAhead = false;
                            this.isLoading = false;
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
                                if (item.value < formulaValue) {
                                    this.showToast("Error", "Broker Netted Down Premium Value cannot be entered very low value", "error");
                                    proceedAhead = false;
                                    this.isLoading = false;
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
        return this.isReadyToSave;
    }

    handleOpenConfirmEdit() {
        this.isConfirmEditModalVisible = true;
    }
    handlerConfirmEdit(event) {
        let status = event.detail.status;
        if (status == 'confirm') {
            if (this.quoteStatus != 'In Progress') {
                updateQuoteInProgress({ quoteId: this.quoteId }).then(response => {
                    if (response.isSuccess) {
                        // this.quoteStatus = 'In Progress';
                        // this.isStatusQuoteColumnReadOnly = false;
                        // this.isQuotedStatus = false;
                        if (this.isSaveQuoteButtonClicked == false) {
                            let refreshQuote = new CustomEvent('refreshquotedetail', { detail: { quoteId: this.quoteId } });
                            this.dispatchEvent(refreshQuote);
                        }

                        if (this.isEditQuoteButtonClicked)
                            this.openModalEditQuote = true;
                        this.isEditQuoteButtonClicked = false;

                        if (this.isSaveQuoteButtonClicked) {

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
                        var errMsg = response.errors[0];
                        if (errMsg.includes("This Quote is locked for editing when status is 'Quoted' or 'Presented' or 'Bound'")) {
                            errMsg = "This Quote is locked for editing when status is 'Quoted' or 'Presented' or 'Bound'."
                        }else if(errMsg.includes('ENTITY_IS_LOCKED')){
                            errMsg = 'This record is locked. If you need to edit it, contact your admin';
                        }
                        this.showToast('Error', errMsg, 'error');
                        this.isLoading = false;
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
        return ((!this.isPCCProduct) && (this.quoteStatus === 'Quoted' || this.quoteStatus === 'Bound Pending') && this.quoteRatingStatus === 'Clear') ? true : false;
    }
    get isQuotedAndClearForPCC() {
        return ((this.isPCCProduct) && (this.quoteStatus === 'Quoted' || this.quoteStatus === 'Bound Pending') && this.quoteRatingStatus === 'Clear') ? true : false;
    }
    handleOpenCloseReferral(event) {
        this.isOpenReferralModel = !this.isOpenReferralModel;
        let refreshQuote = new CustomEvent('refreshquotedetail', { detail: { quoteId: this.quoteId } });
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

    handlesaveandratepremiumcalc(event) {
        console.log('vinay save and rate');
        this.handleRateQuote();
    }

    handlePayPlanChange(event) {
        this.payPlanVal = event.detail.value;
    }
    handleChangeBindValue(event) {
        this.bindValue = event.detail.value;
    }
    handleBindQuote(event) {
        this.openModalBindQuote = true;
    }


    @track brokerAgencyAppointed;
    @track subjectivities;
    @track proposalDate;

    getPreBindDetails() {
        getPreBindDetails({ quoteId: this.quoteId })
            .then(result => {
                result = JSON.parse(result);
                console.log('return: ' + JSON.stringify(result));
                if (result.isSuccess) {
                    this.brokerAgencyAppointed = result.brokerAgencyAppointed;
                    //this.sanctionStatus = data.sanctionStatus;
                    // this.kycStatus = data.kycStatus;
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

    onClickBindQuote() {
        if (this.isAqueousProduct) {
            this.getPreBindDetails();
        }
        else {
            //this.bindPolicyValidation(); //moved below
            //added By Jai on 12-Nov-2021 for User Story - 52958--- code start----
            var insuredState = '';
            var isMReError = false;
            if(this.submissionObj.Account && this.submissionObj.Account.BillingStateCode){
                insuredState = this.submissionObj.Account.BillingStateCode;
            }
            if (this.isPrimaryQuote){
                fetchMReAppointmentDetails({
                    quoteId: this.quoteId,
                    oppId: this.submissionObj.Id,
                    insuredState: insuredState
                })
                .then((result) => {
                    if(result.isAppointNeededForBroker && !result.isAppointExistForBroker){
                        this.showToast("Error!", Bind_Error_Broker_not_MRe_Appointed, "error");
                        this.isLoading = false;
                        isMReError = true;
                    }
                    if(result.isAppointNeededForAgency && !result.isAppointExistForAgency){
                        this.showToast("Error!", Bind_Error_Broker_Agency_not_MRe_Appointed, "error");
                        this.isLoading = false;
                        isMReError = true;
                    }
                    if(isMReError){
                        return;
                    }else{
                        this.bindPolicyValidation();
                    }
                })
                .catch((error) => {
                    console.log('fetchMReAppointmentDetails error : ' + JSON.stringify(error));
                });
            }
            else{
                this.bindPolicyValidation();
            }
            //added By Jai on 12-Nov-2021 for User Story - 52958--- code end----
        }
    }

    handleRowSelection(event) {
        var selectedRows = event.detail.selectedRows;
        this.selectedBinder = selectedRows[0];
    }

    bindPolicyValidation() {
        let errorMessage = [];
        /*if (this.brokerAgencyAppointed && this.isAqueousProduct) {
            // this.showToast('Error', 'Broker Agency is not Appointed', 'error');
            // return;
            errorMessage = [...errorMessage, 'Broker Agency is not Appointed'];
        }*/

     /************ New Code For Sanction *****/
       
        
        quoteDetailsFetch({quoteId : this.quoteId}).then(result => {
            console.log('result+'+JSON.stringify(result))
      
            if((result.Account.CEL_Sanction_Status__c === '' || result.Account.CEL_Sanction_Status__c === undefined 
               || (result.Account.CEL_Sanction_Status__c != 'Pass' && result.Account.CEL_Sanction_Status__c != 'Cleared')) && !this.isAqueousProduct){
            errorMessage = [...errorMessage, 'Sanction Status should be Pass'];
           }

           if (this.subjectivities && this.isAqueousProduct) {
            // this.showToast('Error', 'All Subjectivities should be Clear', 'error');
            // return;
            errorMessage = [...errorMessage, 'All Subjectivities should be Clear'];
        }
        if (this.proposalDate && this.isAqueousProduct) {
            errorMessage = [...errorMessage, 'Proposal Date should not be blank'];
        }
        if (errorMessage.length != 0) {
            this.isLoading = false;
            errorMessage.forEach(item => {
                this.showToast("Error", item, "error");
            })
            return;
        }

        if (!this.isAqueousProduct) {
            this.openModalBindQuote = true;
        }
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
                if (result.showBindOptions) {
                    this.showBindOptions = result.showBindOptions;
                    this.bindValue = this.showBindOptions ? 'Bound Pending' : 'Bind';
                    if(this.isPCCProduct){
                        this.showBindOptions = false;
                        this.bindValue = 'Bind';
                    }
                }
                if (this.isAqueousProduct) {
                    this.handleBindQuote();
                }
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
            if(!(this.isPCCProduct && this.isPrimaryQuote)){
                this.handlecheckSurplusLinesLicense();
            }
        }

        //this.isLoading = !this.isLoading;
        if (this.isAqueousProduct) {
            this.payPlanVal = '';
            this.bindValue = 'Bound';
        }
        this.isBindLoading = !this.isBindLoading;
        getMastreBinderName({ masterBinderId: this.masterBinder })
            .then(result => {
                this.defaultBinder = result;
            });
        bindQuoteQC({ quoteId: this.quoteId, payPlan: this.payPlanVal, isBoundPending: this.bindValue == 'Bound Pending' ? true : false, binder: this.defaultBinder })
            .then(result => {
                this.isLoading = false;
                this.isBindLoading = false;
                var errMsg = '';
                if (result.isSuccess) {
                    if (result.errors) {
                        if(!(this.isPCCProduct && this.isPrimaryQuote)){
                            result.errors.forEach(message => {
                                this.showToast('Warning!', message, 'warning');
                            });
                        }
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

                        // added by Jai 27-Oct-2021
                        this.quoteStatusAndRatingStatus = this.quoteStatus;
                        if(!this.quoteName.includes(' PI ')){
                            this.quoteStatusAndRatingStatus = this.quoteStatus +' - '+(result.extraData.Rating_Status__c != undefined ? result.extraData.Rating_Status__c : 'None');
                        }
                        
                        if (this.quoteStatus == 'Quoted') {
                            errMsg = 'Bind is fail!!';
                        }
                        //this.isLoading = !this.isLoading;
                        this.isBindLoading = !this.isBindLoading;
                        this.isQuotedClear = false;
                        this.openModalBindQuote = !this.openModalBindQuote;
                        let refreshQuote = new CustomEvent('refreshquotedetail', { detail: { quoteId: this.quoteId } });
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
                        message: (errMsg == '') ? "Bind quote successfully!" : errMsg,
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

    @track disableButtons = false;
    get boundDisabled() {
        let noBound = 'main';
        let bound = 'main ' + 'bound-disabled';
        if (this.quoteStatus == 'Bound' || this.quoteStatus === 'Correction' || this.quoteStatus === 'Cancelled' || this.quoteStatus === 'Closed' || this.quoteStatus === 'Rejected' || (this.quoteStatus === 'Referred' && this.isReferredQuoteLocked && this.isAqueousProduct) || (this.quoteStatus === 'Referred' && this.isPCCProduct)) {
            this.disableButtons = true;
            return bound;
        }
        /*else if(this.quoteType === 'Flat Cancellation'){
            return bound;
        }*/ else {
            return noBound;
        }
        //return this.quoteStatus == 'Bound' ? bound : noBound;
    }
    @track binderLayer;
    @track disableBinder = false;
    @api
    handleSelectDocumentType() {
        this.selectedType = 'quote';
        if (this.isAqueousProduct) {
            this.getBinder();
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
    }

    getBinder() {
        getBinder({ submissionId: this.quoteProcessSubmissionId, documentType: this.selectedType, layer: this.isPrimaryQuote === true ? 'Primary' : 'Excess' })
            .then((result) => {
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
                { label: 'Quote', value: 'quote' },
                { label: 'Worksheet ', value: 'worksheet' },
            ];
        }

    }

    handleChangeDocument(event) {
        this.selectedType = event.detail.value;
    }

    handleGenerateDocumentQC() {
        //Adding a spinner and Timeout for bug - CD-87
        //this.isLoading = true;
        if (this.isAqueousProduct) {
            this.handleGenerateDocumentforAqueousQC();  //Removed static spinner after synchronous quote sync
            /*setTimeout(() => 
                this.handleGenerateDocumentforAqueousQC()
            ,5000);*/
        }
        else {
            this.handleGenerateDocument();
        }
    }

    handleGenerateDocumentforAqueousQC() {
        this.selectedType = 'quote';
        if (this.masterBinder) {
            getMastreBinderName({ masterBinderId: this.masterBinder })
                .then(result => {
                    this.defaultBinder = result;
                });
            this.isGenerateDocument = true;
            generateDocIdAQQC({ submissionId: this.quoteProcessSubmissionId, quoteId: this.quoteId, binder: this.defaultBinder, documentType: this.selectedType, layer: this.isPrimaryQuote === true ? 'Primary' : 'Excess' })
                .then((result) => {
                    console.log('Result: ' + JSON.stringify(result));
                    this.isLoading = false;
                    this.showToast(
                        (!result.errMsg) ? 'Success' : 'Error',
                        (!result.errMsg) ? 'Document has been generated successfully!' : result.errMsg,
                        (!result.errMsg) ? 'success' : 'error'
                    );
                    let refreshQuote = new CustomEvent('refreshquotedetail', { detail: { quoteId: this.quoteId } });
                    this.dispatchEvent(refreshQuote);
                    this.isGenerateDocument = false;
                })
                .catch((e) => {
                    this.isLoading = false;
                    this.showToast("Error", JSON.stringify(e), "error");
                    console.log('Error: ' + JSON.stringify(e));
                });
        }
        else {
            this.isLoading = false;
            this.showToast("Error", "Master Binder value is need to generate Document", "error");
        }
        /*this.isGenerateDocument = true;
        generateDocIdAQQC({ submissionId: this.quoteProcessSubmissionId, binder: this.defaultBinder, documentType: this.selectedType, layer: this.isPrimaryQuote == 'true' ? 'Primary' : 'Excess' })
            .then((result) => {
                this.showToast(
                    (!result.errMsg) ? 'Success' : 'Error',
                    (!result.errMsg) ? 'Document has been generated successfully!' : result.errMsg,
                    (!result.errMsg) ? 'success' : 'error'
                );
                this.isGenerateDocument = false;
            })
            .catch((e) => {
                this.showToast("Error", JSON.stringify(e), "error");
            });*/
    }
    handleSortdata(event) {
        this.sortBy = event.detail.fieldName;
        if(event.detail.fieldName == 'Link_Document__c'){
            event.detail.fieldName = 'Name';
        }
        // sort direction
        this.sortDirection = event.detail.sortDirection;
        // calling sortdata function to sort the data based on direction and selected field
        this.sortData(event.detail.fieldName, event.detail.sortDirection);
    }
    sortData(fieldname, direction) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.referralReasonsList));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction 
        let isReverse = direction === 'asc' ? 1: -1;
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
    handleDocumentType(event) {
        let status = event.target.name;
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
        this.isGenerateDocument = true;
        generateDocIdAQ({ submissionId: this.quoteProcessSubmissionId, binder: this.defaultBinder, documentType: this.selectedType, layer: this.isPrimaryQuote == 'true' ? 'Primary' : 'Excess' })
            .then((result) => {
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
                this.handleRefreshRelatedListComponent();
                this.isGenerateDocument = false;
            })
            .catch((e) => this.showToast("Error", JSON.stringify(e), "error"));
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


        /****************** Updated Code for Ticket for 54090 ***************/
        if(this.isAqueousProduct){
            this.isMasterBinder = true; 
            getBinderDetail({quoteId : this.quoteId})
            .then(result => {
                this.isMasterBinder = false;
                if(!result.hasOwnProperty('Master_Binder__c')){
                    console.log('false1');
                    this.isMasterBinder = false;
                }
                else if(result.hasOwnProperty('Master_Binder__c') && result.Master_Binder__c != null && result.Master_Binder__c){
                    console.log('true1');
                    this.isMasterBinder = true;
                }
                //this.proceedAheadToRateQuote();
                if (this.isAqueousProduct && (this.isInceptionDateEdited || this.isQuoteInceptionDateEdited ||  this.isMasterBinder==false)) {
                    getMasterBindersFromQuote({ quoteId: this.quoteId })
                        .then(result => {
                            this.isLoading = false;
                            this.bindersList = result;
                            var quoteLayer = '';
                            if (this.isPrimaryQuote == false) {
                                quoteLayer = 'Excess';
                            } else {
                                quoteLayer = 'Primary';
                            }
                            var bindList = [];
                            for (var i = 0; i < this.bindersList.length; i++) {
                                if (this.bindersList[i].Layer__c.includes(quoteLayer)) {
                                    bindList.push(this.bindersList[i]);
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

            })
            .catch(error => {
                this.isLoading = false;
                console.log("Error-->", JSON.stringify(error));
                this.showToast('Error', error, 'error');
            });
        }
        else{
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
        console.log('vinay procees to rate quote');
        this.isLoading = true;
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
                quoteId: this.quoteId, quoteName: this.quoteName, data: clone, quoteVerId: '', isRate: true,
                fromResponse: true, selectedBinder: this.selectedBinder
            },
        });
        this.dispatchEvent(editQuoteEvt);
        let refreshQuote = new CustomEvent('refreshquotedetail', { detail: { quoteId: this.quoteId } });
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
        if (status == 'confirm') {
            this.isLoading = true;
            updateQuoteInProgress({ quoteId: this.quoteId }).then(response => {
                if (response.isSuccess) {
                    this.handleRateQuoteController();
                    //this.isConfirmRateQuote = false;
                } else {
                    var errMsg = response.errors[0];
                    if(errMsg.includes('ENTITY_IS_LOCKED')){
                        errMsg = 'This record is locked. If you need to edit it, contact your admin';
                    }
                    this.showToast('Error', errMsg, 'error');
                    this.isLoading = false;
                    // this.isConfirmRateQuote = false;
                }
            }).catch(error => {
                var errMsg = error;
                if(errMsg.includes('ENTITY_IS_LOCKED')){
                    errMsg = 'This record is locked. If you need to edit it, contact your admin';
                }
                this.showToast('Error', errMsg, 'error');
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

    closeMasterBinderModal(){
        this.showBinderDialog = false;
    }

    handlePreRateCalculator(event) {
        this.openModalPreBindCalculator = true;
    }
    checkInsurerDetails(insurerDetails) {
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
        console.log('check part fixed:1234');
        checkPartFixedEndorsement({ quoteId: this.quoteId })
            .then(result => {
                console.log('result -->' + JSON.stringify(result))
                if (result == true) {
                    console.log('result:');
                    this.partFixedRes = true;
                    this.handleFinalize();
                    console.log('executed finalize ');
                }
                else {
                    this.partFixedRes = false;
                    this.handleFinalize();
                    console.log('executed finalize2 ');
                }
            })
            .catch(error => {
                this.isLoading = false;
                console.log('error ->' + JSON.stringify(error))
            })
    }

    @api
    handleRefreshDetailComponent(value1, value2, value3, value4) {
        this.listMainSections = value2;
        this.activeSections = value3;
        this.compareItem = value1;
        this.isPrimaryQuote = value4;
        if (this.quoteStatus == 'Bound' || this.quoteStatus === 'Correction' || this.quoteStatus === 'Cancelled' || (this.quoteStatus === 'Referred' && this.isReferredQuoteLocked && this.isAqueousProduct)) {
            this.disableButtons = true;
        }
        else{
            this.disableButtons = false;
        }
        this.template.querySelectorAll("c-generate-output-element-q-c-l-w-c").forEach(element => {
            element.handleRefreshOutputElememt(this.compareItem);
        });
        /*if(this.isPrimaryQuote){
            this.template.querySelector("c-custom-single-related-list").relatedListSoqlWhereCondition = this.relatedListPrimarySoqlWhereCondition;
        }
        else{
            this.template.querySelector("c-custom-single-related-list").relatedListSoqlWhereCondition = this.relatedListExcessSoqlWhereCondition;
 
        }*/
        this.template.querySelectorAll("c-custom-single-related-list").forEach(element => {
            element.handleRefreshRelatedList();
        });
        if(this.isAqueousProduct){
            this.template.querySelector("c-quote-options-table").handleRefreshOptionTable();
        }
        this.template.querySelector("c-quote-coverage-table").quoteId = this.compareItem.quoteId;//added by Jitendra on 10-Jan-2022 for MAT-80
        this.template.querySelector("c-quote-premium-calculator").quoteId = this.compareItem.quoteId;//added by Jitendra on 10-Jan-2022 for MAT-80
        this.template.querySelector("c-quote-coverage-table").handleRefreshCoverageTable();
        this.template.querySelector("c-quote-premium-calculator").handleRefreshPremiumCalculator(); //added by Jitendra on 07-Jan-2022 for MAT-80
        eval("$A.get('e.force:refreshView').fire();");
    }

    @api
    handleRefreshRelatedListComponent() {
        this.template.querySelectorAll("c-custom-single-related-list").forEach(element => {
            element.handleRefreshRelatedList();
        });
    }

    handleSectionToggle(event) {
        const openSections = event.detail.openSections;
    }
    handleBackToQuote() {
        this.showQuoteTable = true;
        this.showPreBindScreen = false;
    }
    handlePreBindSyncCall(event) {
        this.jobIdOfPreBindSyncCall = event.detail;
    }
    handleProceedToBindQuote() {
        this.showQuoteTable = false;

        this.showPreBindScreen = true;
        this.jobIdOfPreBindSyncCall = undefined;
       
        /*** CD-172 ***/
        if(this.isAqueousProduct){
            setTimeout(() => {
            this.template.querySelector("c-quote-options-pre-bind-table").handleRefreshOptionTable();
            },500)
        }


    }
    /**** AQ 51668 */
    handleNoRowSelected(event){
       this.noRowSelected    = event.detail.isSelectedRows;

    }
    handleQuoteBinding() {
        //if (this.proposalDate && this.isAqueousProduct) {
        this.isLoading = true;
        /*if(!this.isMReVerifiedWithState){
            this.showToast("Error!", MRe_Broker_needs_to_be_verified_Msg, "error");
            this.isLoading = false;
            return;
        }*/
        if (this.quoteType === 'Midterm Cancellation' || this.quoteType === 'Flat Cancellation'
            || this.quoteType === 'Full Amendment' || this.quoteType === 'Coverage Amendment' || this.quoteType === 'Policy Duration Change') {
            this.onClickBindQuote();
        }
        else {
            if (this.jobIdOfPreBindSyncCall === undefined) {
                //show Error Toast
                this.showToast("Error!", "Please select a Quote Option.", "error");
                this.isLoading = false;
            }
            else if(this.jobIdOfPreBindSyncCall === 200){
                //proceed To Bind
                this.onClickBindQuote();
            }
            else{
                //show error toast
                this.showToast("Error!", "Sync to middleware failed. Please check api log.", "error");
                this.isLoading = false;
            }
            
        }
    
    }

    viewQuoteRecord() {
        // Navigate to Account record page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                "recordId": this.quoteId,
                "objectApiName": "Quote",
                "actionName": "view"
            },
        });
    }

    handleViewDocEvent(event) {
        var documentId = event.detail.documentId;
        this.handleViewDocument(documentId);
    }

    handleGenerateDocEvent() {
        this.handleGenerateDocumentQC();
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

    //added by Jai 27-Oct-2021
    generateHelpTextIneligible(uwCode,uwReason){
        if(uwCode.length>0){
            let uwCodeList = uwCode.split(',');
            let uwReasonList = uwReason.split('\r\n');
            for(var i=0; i<uwCodeList.length; i++){
            if(this.helpTextIneligible==''){
                this.helpTextIneligible =uwCodeList[i]+(typeof uwReasonList[i] === 'undefined' ? '': ': '+uwReasonList[i]);
            }else{
                this.helpTextIneligible +=', '+uwCodeList[i]+(typeof uwReasonList[i] === 'undefined' ? '': ': '+uwReasonList[i]);
            }
            }
            
        }
    }
    
    handleRefreshQuoteDetail(event){
        console.log('refresh aggregate change');
            //this.isLoading = true;
        let refreshQuote = new CustomEvent('refreshquotedetail', { detail: { quoteId: this.quoteId } });
        this.dispatchEvent(refreshQuote);
    }

    handleSelectedBrokerChange(){
        
    }
    
    /*handleRefreshQuoteDetail(event){
        if (this.isLoading === false) {
            this.isLoading = true;
            let quoteId = event.detail.quoteId;
            let refreshQuote = new CustomEvent('refreshquotedetail', { detail: { quoteId: quoteId } });
            this.dispatchEvent(refreshQuote);
        }
    }*/
}