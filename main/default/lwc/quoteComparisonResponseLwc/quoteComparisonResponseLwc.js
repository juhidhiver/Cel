import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import createQuoteCompareItem from '@salesforce/apex/QuoteCompareItemWrapper.createQuoteCompareItem'
import createNewQuoteHandler from '@salesforce/apex/QuoteCompareItemWrapper.createNewQuoteHandler'
import cloneQuoteHandler from '@salesforce/apex/QuoteCompareItemWrapper.cloneQuoteHandler';
import cloneExcessQuoteHandler from '@salesforce/apex/QuoteCompareItemWrapper.cloneExcessQuoteHandler';
import deleteQuoteHandler from '@salesforce/apex/QuoteCompareItemWrapper.deleteQuoteHandler';
import updateCompareItem from '@salesforce/apex/QuoteCompareItemWrapper.updateCompareItem'
import { updateRecord } from 'lightning/uiRecordApi';
import getRatingFromCallOut from '@salesforce/apex/RateController.getRatingFromCallOut';
import SYSTEM_ERROR_MSG from '@salesforce/label/c.SYSTEM_ERROR_MSG';
import createInitQuote from '@salesforce/apex/QuoteComparisonResponseLwcController.createInitQuote';
import initValues from '@salesforce/apex/QuoteComparisonLWC.initValues';
import getMasterBinders from '@salesforce/apex/OpportunityModifiersCmpController.getMasterBinders';
import TimeZoneSidKey from '@salesforce/schema/User.TimeZoneSidKey';


export default class QuoteComparisonResponseLwc extends LightningElement {
    @api isPrimaryQuote;
    @track quoteTemplates = [];
    @track listWrapper = [];
    @track listWrapper = [];
    // @api mainColumnWrappers;
    @api mainTitleWrappers;
    @api quoteCompareItems = [];
    @track quoteCompareWrapper = [];
    @track submissionObj = {};
    @track isAqueousProduct = false;
    // @api quoteNames = [];
    // @api quoteIds = [];
    @api quoteProcessSubmissionId = '';
    quoteCompareItemZero;
    firstRenderer = false;
    @track quoteType;
    @track isLoading = false;
    @track showScrollUp = false;

    // @track isDisableButton = false;
    @track isPrimaryDisableButton = false;
    @track isExcessDisableButton = false;
    @track quoteLayer;
    @track quoteCompareWrapperForReloadData = [];
    @track bindersList = [];
    @track originalBindersList = [];
    @track showBinderDialog = false;
    @track layerToCreateQuote;
    @track selectedBinder;
    @track binderColumns = [
        { label: 'Master Binder Name', fieldName: 'Name', type: "text" },
        { label: "Inception Date", fieldName: 'Inception_Date__c', type: "text" },
        { label: "Expiration Date", fieldName: 'Expiry_Date__c', type: "text" }
    ];

    @wire(CurrentPageReference) pageRef;
    initValuesListWrapper() {
        var obj = { property: "foo" };
    }

    @api saveEvent(event) {
        this.handleUpdateQuote(event);
    }

    connectedCallback() {
        let quoteTempalte = {};
        quoteTempalte.templateId = 1;
        quoteTempalte.templateName = 'Quote 1';
        this.quoteTemplates.push(quoteTempalte);
        this.listWrapper = [];
        this.listWrapper.push({ quoteName: 'Quotest 1', retro: '2020-03-27', status: true, aggregateLimit: '$1M', retentionVal: 500, sublimitsAndEndorsements: 'No Sublimits' });
        this.listWrapper.push({ quoteName: 'Quotest 2', retro: '2020-04-27', status: false, aggregateLimit: '$2M', retentionVal: 600, sublimitsAndEndorsements: 'No Sublimits' });
        this.listWrapper.push({ quoteName: 'Quotest 3', retro: '2020-05-27', status: true, aggregateLimit: '$3M', retentionVal: 700, sublimitsAndEndorsements: 'No Sublimits' });

        console.log('quoteProcessSubmissionId', this.quoteProcessSubmissionId);
        getMasterBinders({ opportunityId: this.quoteProcessSubmissionId })
            .then(result => {
                this.originalBindersList = result;
                this.bindersList = result;
                console.log('Binders-->:' + JSON.stringify(result));
            })
            .catch(error => {
                console.log("Error-->", JSON.stringify(error));
            });
        registerListener('deleteQuoteFromList', this.handleDeleteQuoteEvent, this);
        registerListener('addNewCompareItemFromList', this.handleAddNewCompareItem, this);
        registerListener('refreshCompareItemFromList', this.handleRefreshCompareItem, this);
        registerListener('saveCompareItemFromList', this.handleUpdateQuote, this);
        registerListener('refreshPageFromList', this.initValueProcess, this);
        // window.addEventListener('scroll', function () {
        //     if(!this.showScrollUp){
        //         if(window.pageYOffset > 395){
        //             console.log("***ifff");
        //             this.showScrollUp = true;
        //             var scrollButton = this.template.querySelector('[data-id="scrollButton"]');
        //             scrollButton.removeAttribute('style');
        //             console.log("***ifff after");
        //         } 
        //     }
        // });
        // for(let i = 0; i < this.quoteNames.length; i++) {
        //     if(this.mainColumnWrappers[i].mainItem.Id == this.quoteIds[i])
        //         this.mainColumnWrappers[i].mainItem.Name = this.quoteNames[i];
        // }
        // getMainColumns()
        // .then((result) => {
        //     if(result.isSuccess){
        //         console.log('@@@data: ' + JSON.stringify(result.data));
        //         this.mainColumnWrappers = result.data;
        //     }else{
        //         console.log('@@@error: ' + JSON.stringify(result.errors));
        //     }
        // })
        // .catch((error) => {
        //     console.log('@@@error: ' + JSON.stringify(error));
        //     //this.error = error;
        // })

        // getMainTitles()
        // .then((result) => {
        //     if(result.isSuccess){
        //         console.log('@@@data1: ' + JSON.stringify(result.data));
        //         this.mainTitleWrappers = result.data;
        //     }else{
        //         console.log('@@@error1: ' + JSON.stringify(result.errors));
        //     }
        // })
        // .catch((error) => {
        //     console.log('@@@error1: ' + JSON.stringify(error));
        //     //this.error = error;
        // })

    }
    @track boundRect;
    renderedCallback() {
        console.log('I am in rendered callback');
        if (this.firstRenderer == false) {
            if (this.quoteCompareItems !== undefined) {
                this.initValueProcess();

                // let clone =  JSON.parse(JSON.stringify(this.quoteCompareItems));
                // this.quoteCompareItemZero = clone[0];
                // this.quoteCompareItemZero.quoteVersions = [];
                // this.quoteCompareItems = clone;

                console.log('quoteCompareItems', JSON.parse(JSON.stringify(this.quoteCompareItems)));
                // console.log('mainTitleWrappers',JSON.parse(JSON.stringify(this.mainTitleWrappers)));
                this.boundRect = this.template.querySelector('[data-id="parentCompareItem"]').getBoundingClientRect();
                console.log("BoundRect-Render->", JSON.stringify(this.boundRect));
                this.firstRenderer = true;
            }
        }
        //this.styleFixedHeader();
        //window.addEventListener('resize', this.refreshRender.bind(this));        
        // window.onscroll = function() {
        //     console.log('SCROLL -- >> ',window.pageYOffset);
        //     if(!this.showScrollUp){
        //         if(window.pageYOffset > 395){
        //             console.log("***ifff");
        //             this.showScrollUp = true;
        //             var scrollButton = this.template.querySelector('[data-id="scrollButton"]');
        //             scrollButton.removeAttribute('style');
        //             console.log("**vv*ifff after");
        //         } 
        //     }
        //     else{
        //         console.log("***else");
        //         this.showScrollUp = false;
        //     }

        // }
    }


    @api
     initValueProcess() {
        this.isLoading = true;
        initValues({ submissionId: this.quoteProcessSubmissionId, isPrimaryQuote: this.isPrimaryQuote })
            .then((data) => {
                console.log('isPrimaryQuote', this.isPrimaryQuote);
                console.log('Init Data ' + JSON.stringify(data));
                console.log('data.quoteCompareItems -- ', data.quoteCompareItems);
                console.log('data.quoteCompareItems lgt-- ', data.quoteCompareItems.length);
                this.quoteCompareWrapper = data;
                this.quoteCompareWrapperForReloadData = data;
                let cloneParent = JSON.parse(JSON.stringify(data.parents));
                this.submissionObj = data.submission;
                var allQuotes = this.submissionObj.Quotes;

                for (var i = 0; i < allQuotes.length; i++) {
                    var quoteType = allQuotes[i].Quote_Type__c;
                    var quoteStatus = allQuotes[i].Status;
                    var quoteLayer = allQuotes[i].Layer__c;
                    if (this.submissionObj.Product_Name__c == 'Professional Indemnity') {
                        this.isAqueousProduct = true;

                        if (this.submissionObj.Transaction_Status__c == 'Active' &&  this.submissionObj.Type == 'Full Amendment') {
                            this.isPrimaryDisableButton = true;
                            break;
                        } else if (this.submissionObj.Transaction_Status__c == 'Inactive') {
                            this.isPrimaryDisableButton = true;
                            this.isExcessDisableButton = true;
                            break;
                        } else {
                            if ((quoteType == 'New Business' && quoteStatus == 'Bound' && quoteLayer == 'Primary') || (quoteType == 'Renewal' && quoteStatus == 'Bound' && quoteLayer == 'Primary')
                            || quoteType == 'Coverage Amendment' ) {
                                console.log("Bound");
                                this.isPrimaryDisableButton = true;
                            } else if ((quoteType == 'New Business' && quoteStatus == 'Bound' && quoteLayer == 'Excess') || (quoteType == 'Renewal' && quoteStatus == 'Bound' && quoteLayer == 'Excess' 
                            || (quoteType !== 'Coverage Amendment' && quoteStatus == 'Bound' && quoteLayer == 'Excess')
                            || (quoteType !== 'Midterm Cancellation' && quoteStatus == 'Bound' && quoteLayer == 'Excess') || 
                            (quoteType !== 'Flat Cancellation (Ab - Initio)' && quoteStatus == 'Bound' && quoteLayer == 'Excess'))) {
                                //this.isExcessDisableButton = true;
                            } else if (quoteType !== 'New Business' && quoteType !== 'Renewal' && quoteType !== 'Coverage Amendment' 
                            && quoteType !== 'Midterm Cancellation' && quoteType !== 'Flat Cancellation (Ab - Initio)') {
                                this.isPrimaryDisableButton = true;
                                this.isExcessDisableButton = true;
                                break;
                            }
                        }
                    } else {
                        this.isAqueousProduct = false;
                        if ((quoteType == 'New Business' || quoteType == 'Renewal') && (this.submissionObj.StageName == 'Closed Won' || this.submissionObj.StageName == 'Bound Pending' || this.submissionObj.StageName == 'Declined'))  {
                            console.log("Bound Pending");
                            //this.isDisableButton = true;
                            this.isPrimaryDisableButton = true;
                            this.isExcessDisableButton = true;
                            break;
                        } else if (quoteType !== 'New Business' && quoteType !== 'Renewal') {
                            // this.isDisableButton = true;
                            this.isPrimaryDisableButton = true;
                            this.isExcessDisableButton = true;
                            break;
                        }
                    }
                }

                cloneParent.forEach(parent => {
                    parent.title = parent.name;
                    parent.childs.forEach(child => {
                        child.title = child.name;
                        if (child.fieldObject == "Rating_Modifier_Factor__c") {
                            child.title += " (" + child.min + ' - ' + child.max + ")";
                        }
                    })
                })
                this.quoteCompareWrapper.parents = cloneParent;

                let clone = JSON.parse(JSON.stringify(data.quoteCompareItems));

                for (let i = 0; i < clone.length; i++) {
                    for (let j = 0; j < clone[i].quoteFields.length; j++) {
                        console.log('clone[i].quoteFields[j].sourceFieldAPI' + clone[i].quoteFields[j].sourceFieldAPI);
                        if (this.isAqueousProduct && (clone[i].quoteFields[j].sourceFieldAPI == 'Binder__c' || clone[i].quoteFields[j].sourceFieldAPI == 'Policy_Wording__c' || clone[i].quoteFields[j].sourceFieldAPI == 'Territorial_Limits__c' || clone[i].quoteFields[j].sourceFieldAPI == 'Jurisdiction_Limits__c' || clone[i].quoteFields[j].sourceFieldAPI == 'Retroactive_Date__c' || clone[i].quoteFields[j].sourceFieldAPI == 'RetroDate__c')) {
                            clone[i].quoteFields[j].isAQQuotedFields = true;
                            console.log('True -->' + true);
                            console.log('item.isAQQuotedFields -->' + clone[i].quoteFields[j].isAQQuotedFields)
                        }
                        clone[i].quoteFields[j].index = j;
                        if ((clone[i].quoteFields[j].sourceFieldAPI == 'Quote_Type__c' && clone[i].quoteFields[j].value == 'New Business' && (clone[i].quoteStatus == 'Bound' || clone[i].quoteStatus == 'Bound Pending')) ||
                            (clone[i].quoteFields[j].sourceFieldAPI == 'Quote_Type__c' && clone[i].quoteFields[j].value == 'Renewal' && (clone[i].quoteStatus == 'Bound' || clone[i].quoteStatus == 'Bound Pending'))) {

                            console.log('Inside 1', clone[i].quoteFields[j].value);
                            if (!this.isAqueousProduct) {
                                //this.isDisableButton = true;
                                this.isPrimaryDisableButton = true;
                                this.isExcessDisableButton = true;
                            }
                        } else if ((clone[i].quoteFields[j].sourceFieldAPI == 'Quote_Type__c' && clone[i].quoteFields[j].value !== 'New Business')
                            && (clone[i].quoteFields[j].sourceFieldAPI == 'Quote_Type__c' && clone[i].quoteFields[j].value !== 'Renewal')) {
                            console.log('Inside 2', clone[i].quoteFields[j].value);
                            if (!this.isAqueousProduct) {
                                //this.isDisableButton = true;
                                this.isPrimaryDisableButton = true;
                                this.isExcessDisableButton = true;
                            }
                            console.log('isPrimaryDisableButton 2', this.isPrimaryDisableButton + 'Excess:' + this.isExcessDisableButton);
                        }
                    }
                }
                this.quoteCompareItems = clone;
                if (clone.length > 0) {
                    let temp = JSON.parse(JSON.stringify(clone[0]));
                    //quoteVersion cannot be deserialized in Apex so it will cause error when create new QuoteCompareItem
                    temp.quoteVersions = [];
                    this.quoteCompareItemZero = temp;
                }
                this.isLoading = false;
            })
            .catch((error) => {
                console.log('@@@error: ' + JSON.stringify(error));
                this.isLoading = false;
            })
    }

    @api
    reloadData() {
        this.initValueProcess();
        var data = this.quoteCompareWrapperForReloadData;
        console.log('isPrimaryQuote', this.isPrimaryQuote);
        console.log('Init Data reloadData' + JSON.stringify(data));
        console.log('data.quoteCompareItems reloadData-- ', data.quoteCompareItems);
        console.log('data.quoteCompareItems lgt reloadData-- ', data.quoteCompareItems.length);

        let cloneParent = JSON.parse(JSON.stringify(data.parents));
        this.submissionObj = data.submission;
        var allQuotes = this.submissionObj.Quotes;

        for (var i = 0; i < allQuotes.length; i++) {
            var quoteType = allQuotes[i].Quote_Type__c;
            var quoteStatus = allQuotes[i].Status;
            var quoteLayer = allQuotes[i].Layer__c;

            if (this.submissionObj.Product_Name__c == 'Professional Indemnity') {
                this.isAqueousProduct = true;
                if (this.submissionObj.Transaction_Status__c == 'Active' &&  this.submissionObj.Type == 'Full Amendment') {
                    this.isPrimaryDisableButton = true;
                    break;
                } else if (this.submissionObj.Transaction_Status__c == 'Inactive') {
                    this.isPrimaryDisableButton = true;
                    this.isExcessDisableButton = true;
                    break;
                }else{
                    if ((quoteType == 'New Business' && quoteStatus == 'Bound' && quoteLayer == 'Primary') || (quoteType == 'Renewal' && quoteStatus == 'Bound' && quoteLayer == 'Primary')
                        || (quoteType == 'Full Amendment' && quoteStatus == 'Bound' && quoteLayer == 'Primary') || (quoteType == 'Coverage Amendment' && quoteStatus == 'Bound' && quoteLayer == 'Primary')) {
                        console.log("Bound");
                        this.isPrimaryDisableButton = true;
                    } else if ((quoteType == 'New Business' && quoteStatus == 'Bound' && quoteLayer == 'Excess') || (quoteType == 'Renewal' && quoteStatus == 'Bound' && quoteLayer == 'Excess')
                        || (quoteType == 'Coverage Amendment' && quoteStatus == 'Bound' && quoteLayer == 'Excess')) { //|| (quoteType == 'Full Amendment' && quoteStatus == 'Bound' && quoteLayer == 'Excess') 
                        //this.isExcessDisableButton = true;
                    } else if (quoteType !== 'New Business' && quoteType !== 'Renewal' && quoteType !== 'Full Amendment' && quoteType !== 'Coverage Amendment') {
                        this.isPrimaryDisableButton = true;
                        //this.isExcessDisableButton = true;
                        break;
                    }
                }                
            } else {
                this.isAqueousProduct = false;
                if ((quoteType == 'New Business' || quoteType == 'Renewal') && (this.submissionObj.StageName == 'Closed Won' || this.submissionObj.StageName == 'Bound Pending'))  {
                    console.log("Bound Pending");
                    //this.isDisableButton = true;
                    this.isPrimaryDisableButton = true;
                    this.isExcessDisableButton = true;
                    break;
                } else if (quoteType !== 'New Business' && quoteType !== 'Renewal') {
                    // this.isDisableButton = true;
                    this.isPrimaryDisableButton = true;
                    this.isExcessDisableButton = true;
                    break;
                }
            }
        }
        cloneParent.forEach(parent => {
            parent.title = parent.name;
            parent.childs.forEach(child => {
                child.title = child.name;
                if (child.fieldObject == "Rating_Modifier_Factor__c") {
                    child.title += " (" + child.min + ' - ' + child.max + ")";
                }
            })
        })
        this.quoteCompareWrapper.parents = cloneParent;

        let clone = JSON.parse(JSON.stringify(data.quoteCompareItems));

        for (let i = 0; i < clone.length; i++) {
            for (let j = 0; j < clone[i].quoteFields.length; j++) {
                clone[i].quoteFields[j].index = j;
                if ((clone[i].quoteFields[j].sourceFieldAPI == 'Quote_Type__c' && clone[i].quoteFields[j].value == 'New Business' && (clone[i].quoteStatus == 'Bound' || clone[i].quoteStatus == 'Bound Pending')) ||
                    (clone[i].quoteFields[j].sourceFieldAPI == 'Quote_Type__c' && clone[i].quoteFields[j].value == 'Renewal' && (clone[i].quoteStatus == 'Bound' || clone[i].quoteStatus == 'Bound Pending'))) {

                    console.log('Inside 1', clone[i].quoteFields[j].value);
                    if (!this.isAqueousProduct) {
                        //this.isDisableButton = true;
                        this.isPrimaryDisableButton = true;
                        this.isExcessDisableButton = true;
                    }
                } else if ((clone[i].quoteFields[j].sourceFieldAPI == 'Quote_Type__c' && clone[i].quoteFields[j].value !== 'New Business')
                    && (clone[i].quoteFields[j].sourceFieldAPI == 'Quote_Type__c' && clone[i].quoteFields[j].value !== 'Renewal')) {
                    console.log('Inside 2', clone[i].quoteFields[j].value);
                    if (!this.isAqueousProduct) {
                        //this.isDisableButton = true;
                        this.isPrimaryDisableButton = true;
                        this.isExcessDisableButton = true;
                    }
                    console.log('isPrimaryDisableButton 2', this.isPrimaryDisableButton + 'excess: ' + this.isExcessDisableButton);
                }
            }
        }
        this.quoteCompareItems = clone;
        if (clone.length > 0) {
            let temp = JSON.parse(JSON.stringify(clone[0]));
            //quoteVersion cannot be deserialized in Apex so it will cause error when create new QuoteCompareItem
            temp.quoteVersions = [];
            this.quoteCompareItemZero = temp;
        }
        //this.handleStyleFix();
    }

    refreshRender() {
        var valueParent = this.template.querySelector(`[data-id="value-parent"]`);
        var valueContainer = this.template.querySelector(`[data-id="value-container"]`);
        var valueChild = this.template.querySelectorAll(`[data-id="value-child"]`);

        if (!valueChild || !valueContainer || !valueParent || !this.boundRect) return;

        var sticky = valueContainer.getBoundingClientRect();

        const parentWidth = valueParent.getBoundingClientRect().width;
        //this.boundRect = this.template.querySelector('[data-id="parentCompareItem"]').getBoundingClientRect();
        var compareItem = this.template.querySelectorAll(`[data-id="compareItem"]`);
        var responseItems = this.template.querySelectorAll(`c-quote-comparison-response-item`);
        var parentCompareItem = this.template.querySelector('[data-id="parentCompareItem"]')

        if (!compareItem || !responseItems || !parentCompareItem) return;

        if (window.pageYOffset + sticky.height >= this.boundRect.y && window.pageYOffset <= valueParent.getBoundingClientRect().height) {
            valueContainer.classList.add("value-sticky");
            valueChild.forEach(child => child.setAttribute('style', `width: ${parentWidth}px !important`));
        } else {
            valueContainer.classList.remove("value-sticky");
            valueChild.forEach(child => child.removeAttribute('style'));
        }

        const parentRight = parentCompareItem.getBoundingClientRect().right;
        console.log("##parentRight-->", JSON.stringify(parentRight));
        // console.log('sticky',JSON.stringify(sticky));
        compareItem.forEach((item, idx) => {
            console.log("##item-->", JSON.stringify(item));
            console.log("##idx-->", JSON.stringify(idx));
            var left = item.getBoundingClientRect().left;
            console.log("##left-->", JSON.stringify(left));
            responseItems[idx].resizeHeaderStyle(left);
            responseItems[idx].setParentBoundRect(this.boundRect);
            console.log("##responseItems[idx]-->", JSON.stringify(responseItems[idx]));
            if (left <= 85 || left >= parentRight - 5) {
                item.setAttribute('style', 'visibility: hidden');
            } else {
                item.removeAttribute('style');
            }
        });
    }

    styleFixedHeader() {
        var valueParent = this.template.querySelector(`[data-id="value-parent"]`);
        var valueContainer = this.template.querySelector(`[data-id="value-container"]`);
        var valueChild = this.template.querySelectorAll(`[data-id="value-child"]`);

        if (!valueChild || !valueContainer || !valueParent || !this.boundRect) return;


        var sticky = valueContainer.getBoundingClientRect();

        const boundRect = this.boundRect;

        this.scrollStyle();

        window.addEventListener('scroll', function () {
            // console.log("window.pageYOffset", window)
            const parentWidth = valueParent.getBoundingClientRect().width;
            if (boundRect.y < 0) boundRect.y = 0;
            if (window.pageYOffset + sticky.height >= boundRect.y && window.pageYOffset <= valueParent.getBoundingClientRect().height) {
                valueContainer.classList.add("value-sticky");
                valueChild.forEach(child => child.setAttribute('style', `width: ${parentWidth}px !important`));
            } else {
                valueContainer.classList.remove("value-sticky");
                valueChild.forEach(child => child.removeAttribute('style'));
            }
        });
        // this.scrollStyle();
    }

    handleScroll(event) {
        //this.scrollStyle();
    }

    scrollStyle() {
        var compareItem = this.template.querySelectorAll(`[data-id="compareItem"]`);
        var responseItems = this.template.querySelectorAll(`c-quote-comparison-response-item`);
        var parentCompareItem = this.template.querySelector('[data-id="parentCompareItem"]');

        if (!compareItem || !responseItems || !parentCompareItem) return;

        const parentRight = parentCompareItem.getBoundingClientRect().right;
        const parentHeight = parentCompareItem.getBoundingClientRect().height;
        this.boundRect = this.template.querySelector('[data-id="parentCompareItem"]').getBoundingClientRect();
        console.log("BoundRect-->", JSON.stringify(this.boundRect));
        const boundRect = this.boundRect;
        if (boundRect.y < 0) boundRect.y = 0;
        this.boundRect = boundRect;
        // console.log('sticky',JSON.stringify(sticky));
        compareItem.forEach((item, idx) => {
            var left = item.getBoundingClientRect().left;
            console.log("QuoteComparisonResponseLwc -> scrollStyle -> left", left)
            var width = item.getBoundingClientRect().width;
            responseItems[idx].setLeftPosition(left);
            responseItems[idx].setParentBoundRect(this.boundRect);
            if (left <= 85 || left >= parentRight - 5) {
                item.setAttribute('style', 'visibility: hidden');
            } else {
                item.removeAttribute('style');
            }
        });
    }


    handleEditQuote(event) {
        console.log('Get Quote Detail From Child');
        console.log('Event Detail ' + JSON.stringify(event.detail));
    }
    /*
    toggleModeEdit(evt){
        this.modeEdit = !this.modeEdit;
        if(this.modeEdit == true) {
            evt.target.classList.add('slds-is-selected');
        }else {
            evt.target.classList.remove('slds-is-selected');
        }
    } */
    /*
        handleStyleFix(event) {
            var scrollOptions = {
                left: 0,
                top: 0,
                behavior: 'auto'
            }
            window.scrollTo(scrollOptions);
            if (this.isLoading === false) {
                this.isLoading = true;
    
                //this.createCompareItem(quoteId);
                //this.showToast('Success', 'Rate Successfully', 'success');
    
                //this.initValueProcess();
    
                fireEvent(this.pageRef, 'refreshPageFromList', null);
                window.scrollBy(0, 1);
                //window.scrollBy(0, -100);
                this.isLoading = false;
            }
        }*/

    handleAddNewQuote(event) {
        var scrollOptions = {
            left: 0,
            top: 0,
            behavior: 'auto'
        }
        window.scrollTo(scrollOptions);
        var layerName = event.target.value;
        this.quoteLayer = layerName;
        if (layerName == 'Primary') {
            layerName = 'Primary';
        } else {
            layerName = 'Excess';
        }
        if (this.isAqueousProduct) {
            if (this.originalBindersList.length == 0) {
                this.showToast("Error", "No Binders to Map with the Quote", "error");
                return;
            }
            var bindList = [];
            this.layerToCreateQuote = layerName;
            for (var i = 0; i < this.originalBindersList.length; i++) {
                if (this.originalBindersList[i].Layer__c.includes(layerName)) {
                    bindList.push(this.originalBindersList[i]);
                }
            }
            this.bindersList = bindList;
            if (this.bindersList.length > 1 && this.isAqueousProduct) {
                this.showBinderDialog = true;
            } else if (this.bindersList.length == 1 && this.isAqueousProduct) {
                this.selectedBinder = this.bindersList[0];
                this.proceedAheadToCreateQuote(layerName);
            }
        } else {
            this.proceedAheadToCreateQuote(layerName);
        }
        // let quoteTempalte = {};
        // quoteTempalte.templateId = (this.quoteTemplates.length + 1);
        // quoteTempalte.templateName = 'Quote ' + (this.quoteTemplates.length + 1);
        // this.quoteTemplates.push(quoteTempalte);
        // this.listWrapper.push({quoteName : 'Quote ' + (this.listWrapper.length +1) ,retro : '2020-02-27',status: true ,retentionVal: 900,  aggregateLimit : '$3M' , sublimitsAndEndorsements : 'No Sublimits'  });        
    }
    proceedAheadToCreateQuote(layerName) {
        if (this.isAqueousProduct) {
            if (this.selectedBinder == '' || this.selectedBinder == undefined || this.selectedBinder == null) {
                this.showToast("Error", "Please select Binder", "error");
                return;
            }
        }
        if (this.isLoading === false) {
            this.isLoading = true;
            console.log("selectedBinder-->", JSON.stringify(this.selectedBinder))
            createNewQuoteHandler({
                submissionId: this.quoteProcessSubmissionId,
                quoteNumber: this.quoteCompareItems.length, quoteLayer: layerName,
                selectedBinder: JSON.stringify(this.selectedBinder)
            })
                .then(response => {
                    if (response.isSuccess) {
                        console.log('IN handleAddNewQuote -- ', response);
                        let quoteId = response.data.Id;
                        //handle rate quote here
                        getRatingFromCallOut({ objId: quoteId }).then(response => {
                            if (response.isSuccess) {
                                console.log('IN rate success -- ', response);
                                //rate success
                                this.createCompareItem(quoteId);
                                this.showToast('Success', 'Rating Successful!', 'success');
                                //this.initValueProcess();
                                fireEvent(this.pageRef, 'refreshPageFromList', null);
                                window.scrollBy(0, 100);
                            } else {
                                //rate fail
                                this.createCompareItem(quoteId);
                                this.showToast('Error', response.errors[0], 'error');
                                //this.initValueProcess();
                                fireEvent(this.pageRef, 'refreshPageFromList', null);
                            }
                        }).catch((error) => {
                            //fail on lwc
                            this.showToast('Error', JSON.stringify(error), 'error');
                        });
                        //fireEvent(this.pageRef, 'refreshPageFromList', null);


                        console.log('IN navigatetab -- ', response);
                    } else {
                        this.showToast('Error', response.errors[0], 'error');
                        this.isLoading = false;
                    }
                }).catch((error) => {
                    this.showToast('Error', JSON.stringify(error), 'error');
                    this.isLoading = false;
                });
        }
    }
    createQuoteItems(quoteId) {
        let detail = { quoteId: quoteId }
        if (!this.pageRef) {
            this.pageRef = {};
            this.pageRef.attributes = {};
            this.pageRef.attributes.LightningApp = "LightningApp";
        }
        fireEvent(this.pageRef, 'addNewCompareItemFromResponse', detail);
        createQuoteCompareItem({ newQuoteId: quoteId, compareItemString: JSON.stringify(this.quoteCompareItemZero) })
            .then(newCompareItem => {
                let temp = JSON.parse(JSON.stringify(newCompareItem));
                let clone = JSON.parse(JSON.stringify(this.quoteCompareItems));
                clone.push(temp);
                this.quoteCompareItems = clone;
                this.isLoading = false;
            }).catch((error) => {
                this.showToast('Error', JSON.stringify(error), 'error');
                this.isLoading = false;
            })
    }

    handleAddNewCompareItem(event) {
        let quoteId = event.quoteId;
        createQuoteCompareItem({ newQuoteId: quoteId, compareItemString: JSON.stringify(this.quoteCompareItemZero) })
            .then(compareItem => {
                let temp = JSON.parse(JSON.stringify(compareItem));
                let clone = JSON.parse(JSON.stringify(this.quoteCompareItems));
                clone.push(temp);
                this.quoteCompareItems = clone;
                // this.quoteCompareItems.push(temp);
            }).catch((error) => {
                this.showToast('Error', JSON.stringify(error), 'error');
            });;
    }

    handleRefreshCompareItem(event) {
        let quoteId = event.quoteId;
        createQuoteCompareItem({ newQuoteId: quoteId, compareItemString: JSON.stringify(this.quoteCompareItemZero) })
            .then(compareItem => {
                let temp = JSON.parse(JSON.stringify(compareItem));
                let clone = JSON.parse(JSON.stringify(this.quoteCompareItems));
                for (let i = 0; i < clone.length; i++)
                    if (clone[i].quoteId === quoteId)
                        clone[i] = temp;
                this.quoteCompareItems = clone;
                var childItem = this.template.querySelector(`[data-id="${quoteId}"]`);
                childItem.isLoading = false;
            }).catch((error) => {
                this.showToast('Error', JSON.stringify(error), 'error');
            });;
    }

    disconnectCallback() {
        unregisterAllListeners(this);
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
    handleCloneQuote(event) {
        console.log('Handle Clone Quote');
        if (this.isLoading === false) {
            this.isLoading = true;
            let selectedQuote = event.detail.quoteId;
            let primaryToExcessLayer = event.detail.quoteLayer;
            if(primaryToExcessLayer == 'Excess'){
                cloneExcessQuoteHandler({ quoteId: selectedQuote, quoteLayer: primaryToExcessLayer })
                    .then(response => {
                        if (response.isSuccess == false) {
                            this.showToast("Error", response.errors[0], 'Error');
                            this.isLoading = false;
                        }
                        else {
                            let quoteId = response.data.Id;
                            this.createCompareItem(quoteId);
                        }

                    }).catch((error) => {
                        this.showToast('Error', JSON.stringify(error), 'error');
                        this.isLoading = false;
                    });
            }else{
                cloneQuoteHandler({ quoteId: selectedQuote })
                    .then(response => {
                        if (response.isSuccess == false) {
                            this.showToast("Error", response.errors[0], 'Error');
                            this.isLoading = false;
                        }
                        else {
                            let quoteId = response.data.Id;
                            this.createCompareItem(quoteId);
                            //End rate Quote
                        }

                    }).catch((error) => {
                        this.showToast('Error', JSON.stringify(error), 'error');
                        this.isLoading = false;
                    });
            }
        }
    }
    createCompareItem(quoteId) {
        console.log('quoteCompareItems--11>', JSON.stringify(this.quoteCompareItems));
        console.log("Length--11-->", this.quoteCompareItems.length);
        let detail = { quoteId: quoteId }
        if (!this.pageRef) {
            this.pageRef = {};
            this.pageRef.attributes = {};
            this.pageRef.attributes.LightningApp = "LightningApp";
        }
        fireEvent(this.pageRef, 'addNewCompareItemFromResponse', detail);
        createQuoteCompareItem({ newQuoteId: quoteId, compareItemString: JSON.stringify(this.quoteCompareItemZero) })
            .then(newCompareItem => {
                console.log('On create New Compare Item');
                let temp = JSON.parse(JSON.stringify(newCompareItem));
                var allowPush = false;
                console.log("Quote 0-->", JSON.stringify(this.quoteCompareItemZero));
                console.log("temp->", JSON.stringify(temp));
                for (var i = 0; i < this.quoteCompareItems.length; i++) {
                    if (temp.quoteLayer == this.quoteCompareItems[i].quoteLayer &&
                        temp.quoteId == this.quoteCompareItems[i].quoteId) {
                        allowPush = false;
                        break;
                    } else {
                        allowPush = true;
                    }
                }

                if (allowPush){
                    this.quoteCompareItems.push(temp);
                    fireEvent(this.pageRef, 'refreshPageFromList', null);
                }
                console.log("this.quoteLayer->", this.quoteLayer);
                console.log("this.quoteLayerlast->", temp.quoteLayer);
                //Navigate to desired layer tab
                const navigatetab = new CustomEvent(
                    "navigatetab", {
                    detail: temp.quoteLayer,
                });
                this.dispatchEvent(navigatetab);
                this.isLoading = false;
            }).catch((error) => {
                this.showToast('Error', JSON.stringify(error), 'error');
                //Navigate to desired layer tab
                const navigatetab = new CustomEvent(
                    "navigatetab", {
                    detail: this.quoteLayer,
                });
                this.dispatchEvent(navigatetab);
                this.isLoading = false;
            })
    }
    handleDeleteQuote(event) {
        let quoteId = event.detail.quoteId;
        let closeReason = event.detail.closeReason;
        let clone = [];

        this.quoteCompareItems = this.quoteCompareItems.filter(item => item.quoteId !== quoteId);
        // deleteQuoteHandler({quoteId: quoteId}); 
        const fields = {
            Id: quoteId,
            Status: 'Closed',
            Closed_Reason__c: closeReason
        };
        updateRecord({ fields })
            .then((result) => {
                console.log('handleDeleteQuote:', JSON.stringify(result));
            })
            .catch(error => {
                console.log('Error updating record quote status :' + JSON.stringify(error));
            });
        let detail = { quoteId: quoteId }
        if (!this.pageRef) {
            this.pageRef = {};
            this.pageRef.attributes = {};
            this.pageRef.attributes.LightningApp = "LightningApp";
        }
        fireEvent(this.pageRef, 'deleteQuoteFromResponse', detail);
    }

    handleDeleteQuoteEvent(event) {
        let quoteId = event.quoteId;
        this.quoteCompareItems = this.quoteCompareItems.filter(item => item.quoteId !== quoteId);
    }

    handleUpdateQuote(event) {

        // var jsonWrapper = JSON.stringify(event.detail.data);
        // var quoteName = event.detail.quoteName;//JSON.stringify(event.detail.quoteName);
        var sendDate = (new Date()).getMilliseconds();
        var quoteId = event.detail.quoteId;
        var quoteVerId = event.detail.quoteVerId;
        var selectedBinder = event.detail.selectedBinder;
        let updateObjects = { listUpdate: [] };
        let updateData = JSON.parse(JSON.stringify(event.detail.data));

        //quote version
        var isCreateQuoteVer = false;
        // if(event.detail.fromResponse == false){
        //     const child = this.template.querySelector(`[data-id="${quoteId}"]`);
        //     var clone = JSON.parse(JSON.stringify(child.compareItem));
        //     clone.quoteFields.forEach(item => {
        //         if(item.fieldId != '' || item.fieldId != undefined) {
        //             let id = item.fieldId.split('-');
        //             item.fieldId = id[0];
        //         }
        //     })
        //     updateData = JSON.parse(JSON.stringify(clone));
        // }else{
        //     updateData = JSON.parse(JSON.stringify(event.detail.data));
        // }
        console.log("updateData", updateData)
        if (!updateData) return;
        var receiveDate = (new Date()).getMilliseconds();
        console.log('Time estimation :' + (receiveDate - sendDate));
        sendDate = (new Date()).getSeconds();
        if (quoteVerId != '') {
            var selectedQuoteVer = null;
            //var compareItem = JSON.parse(JSON.stringify(event.detail.data));
            updateData.quoteVersions.forEach(quoteVer => {
                if (quoteVer.Id === quoteVerId) {
                    selectedQuoteVer = JSON.parse(JSON.stringify(quoteVer));
                }
            });
            let quoteVerFieldIdValueMap = {};
            if (selectedQuoteVer != null) {
                selectedQuoteVer.Quote_Version_Items__r.forEach(quoteVerItem => {
                    quoteVerFieldIdValueMap[quoteVerItem.Object_Id__c] = quoteVerItem.Value__c;
                });
            }

            updateData.quoteFields.forEach(quoteField => {
                selectedQuoteVer.Quote_Version_Items__r.forEach(quoteVerItem => {
                    if (quoteField.fieldId === quoteVerItem.Object_Id__c
                        && quoteField.value !== quoteVerItem.Value__c) {
                        isCreateQuoteVer = true;
                        quoteVerItem.Value__c = quoteField.value;
                    }
                });
            });
            var quoteVerItemsUpdate = !selectedQuoteVer.Quote_Version_Items__r ? null : selectedQuoteVer.Quote_Version_Items__r;
        }

        //
        var quoteCompareItemUpdate = updateData.quoteFields;
        for (let i = 0; i < this.quoteCompareItems.length; i++) {
            if (this.quoteCompareItems[i].quoteId === quoteId) {
                for (let k = 0; k < this.quoteCompareItems[i].quoteFields.length; k++) {
                    if (this.quoteCompareItems[i].quoteFields[k].isField == true) {
                        if (this.quoteCompareItems[i].quoteFields[k].value != updateData.quoteFields[k].value) {
                            let upObj = {
                                id: updateData.quoteFields[k].fieldId,
                                name: updateData.quoteFields[k].fieldName,
                                sourceObject: updateData.quoteFields[k].sourceObject,
                                fieldApi: updateData.quoteFields[k].sourceFieldAPI,
                                value: updateData.quoteFields[k].value
                            };
                            updateObjects.listUpdate.push(upObj);
                        }
                    }
                }
                break;
            }
        }
        console.log("selectedBinder: " + JSON.stringify(selectedBinder));
        console.log("List update object: " + JSON.stringify(quoteCompareItemUpdate));
        console.log("updateObjects: " + JSON.stringify(updateObjects));
        var isRate = event.detail.isRate;
        console.log('isRate' + isRate);
        receiveDate = (new Date()).getMilliseconds();
        console.log('Time :' + (receiveDate - sendDate));
        sendDate = (new Date()).getMilliseconds();
        if (updateObjects.listUpdate.length > 0) {
            updateCompareItem({
                updateObj: JSON.stringify(updateObjects),
                quoteId: quoteId,
                quoteCompareItemUpdate: quoteCompareItemUpdate !== null ? JSON.stringify(quoteCompareItemUpdate) : '',
                quoteVerItemsUpdate: isCreateQuoteVer ? quoteVerItemsUpdate : null
            })
                .then(result => {
                    console.log('@@@result: ' + JSON.stringify(result));
                    var childItem = this.template.querySelector(`[data-id="${quoteId}"]`);
                    if (result.isSuccess) {
                        // var quoteCompareItemClone = this.quoteCompareItems;
                        // quoteCompareItemClone.forEach(quoteCompareItem => {
                        //     if(quoteCompareItem.quoteId === quoteId){
                        //         console.log('@@@result yes: ');
                        //         quoteCompareItem.quoteVersions = result.data;
                        //     }
                        // });
                        // this.quoteCompareItems = quoteCompareItemClone;

                        if (isRate == true) { // rate for quoteComparision Duc - 8/6/2020
                            childItem.rateQuote();
                        } else {
                            let eventTemp = event;
                            eventTemp.detail.quoteId = quoteId;
                            this.handleRefreshQuote(eventTemp);
                            this.showToast("Success", "Update records successfully!", "success");
                            childItem.isLoading = false;
                        }

                        // if(event.detail.fromResponse == true){
                        //     if (!this.pageRef) {
                        //         this.pageRef = {};
                        //         this.pageRef.attributes = {};
                        //         this.pageRef.attributes.LightningApp = "LightningApp";
                        //     }
                        //     let eventTemp = event;
                        //     // eventTemp.detail.fromResponse = true;
                        //     fireEvent(this.pageRef, 'saveCompareItemFromResponse', eventTemp);
                        // }else{
                        //     if(isRate == true){ // rate for quoteComparision Duc - 8/6/2020
                        //         var childItem = this.template.querySelector(`[data-id="${quoteId}"]`);
                        //         childItem.rateQuote();                      
                        //     }else{
                        //         let eventTemp = event;
                        //         eventTemp.detail.quoteId = quoteId;
                        //         this.handleRefreshQuote(eventTemp);
                        //         this.showToast("Success", "Update records successfully!", "success");
                        //     }
                        // }
                    } else {
                        console.log("@@@error: " + JSON.stringify(result.errors));
                        this.showToast("Error", result.errors[0], "error");
                        childItem.isLoading = false;
                    }
                    receiveDate = (new Date()).getMilliseconds();
                    console.log('Time estimation :' + (receiveDate - sendDate));
                })
                .catch((error) => {
                    console.log("@@@error: " + JSON.stringify(error));
                })
        } else if (isRate == true) { // rate for quoteComparision Duc - 8/6/2020
            var childItem = this.template.querySelector(`[data-id="${quoteId}"]`);
            childItem.rateQuote();
        }
        this.reloadData();
        // {
        //     if(event.detail.fromResponse == true){
        //         if (!this.pageRef) {
        //             this.pageRef = {};
        //             this.pageRef.attributes = {};
        //             this.pageRef.attributes.LightningApp = "LightningApp";
        //         }
        //         let eventTemp = event;
        //         // eventTemp.detail.fromResponse = true;
        //         fireEvent(this.pageRef, 'saveCompareItemFromResponse', eventTemp);
        //     }else if(isRate == true){ // rate for quoteComparision Duc - 8/6/2020
        //         var childItem = this.template.querySelector(`[data-id="${quoteId}"]`);
        //         childItem.rateQuote();                      
        //     }
        // }
    }
    scrollUp() {
        if (window.pageYOffset > 264) {
            var scrollOptions = {
                left: 0,
                top: 264,
                behavior: 'smooth'
            }
            window.scrollTo(scrollOptions);
        }
    }
    scrollLeft(){
        var quotesElement = this.template.querySelector('[data-id="parentCompareItem"]');
        this.sideScroll(quotesElement,'left',25,300,10);
    }
    scrollRight(){
        var quotesElement = this.template.querySelector('[data-id="parentCompareItem"]');
        this.sideScroll(quotesElement,'right',25,quotesElement.scrollWidth/this.quoteCompareItems.length,10);
       //var singleQuotesElement = this.template.querySelector('[data-id="'+this.quoteCompareItems[0].quoteId+'"]');
        //quotesElement.scrollLeft += 100;
        //quotesElement.scrollLeft += 403.55
        console.log(quotesElement.getBoundingClientRect(), quotesElement.scrollWidth,this.quoteCompareItems.length, window.outerWidth*0.38) 
    }
    sideScroll(element,direction,speed,distance,step){
        var scrollAmount = 0;
        var slideTimer = setInterval(()=>{
            if(direction == 'left'){
                element.scrollLeft -= step;
            } else {
                element.scrollLeft += step;
            }
            scrollAmount += step;
            if(scrollAmount >= distance){
                window.clearInterval(slideTimer);
            }
        }, speed);
    }
    handleRefreshQuote(event) {
        if (this.isLoading === false) {
            this.isLoading = true;
            let quoteId = event.detail.quoteId;
            let detail = { quoteId: quoteId }
            if (!this.pageRef) {
                this.pageRef = {};
                this.pageRef.attributes = {};
                this.pageRef.attributes.LightningApp = "LightningApp";
            }
            // fireEvent(this.pageRef, 'refreshCompareItemFromResponse', detail);
            console.log('quoteCompareItemZero', JSON.stringify(this.quoteCompareItemZero));
            fireEvent(this.pageRef, 'refreshPageFromList', null);
            createQuoteCompareItem({ newQuoteId: quoteId, compareItemString: JSON.stringify(this.quoteCompareItemZero) })
                .then(newCompareItem => {
                    let temp = JSON.parse(JSON.stringify(newCompareItem));
                    for (let i = 0; i < this.quoteCompareItems.length; i++) {
                        if (this.quoteCompareItems[i].quoteId == quoteId)
                            this.quoteCompareItems[i] = temp;
                    }
                    this.isLoading = false;
                }).catch((error) => {
                    console.log('error.message', JSON.stringify(error.message));
                    this.showToast('Error', JSON.stringify(error), 'error');
                    this.isLoading = false;
                })

        }
    }
    @api
    updateQuoteComparesionItemResponse() {
        var isReadyToSave = false;
        console.log('inside Compare and rate', JSON.stringify(this.template.querySelector("c-quote-comparison-response-item")));
        if (this.template.querySelector("c-quote-comparison-response-item") != null) {
            this.isReadyToSave = this.template.querySelector("c-quote-comparison-response-item").handleSaveCompareItem();
        }
        return this.isReadyToSave;
    }

    handleOpenDocument() {
        console.log('gen');
        this.template.querySelector("c-quote-comparison-response-item").handleSelectDocumentType();
    }

    handleViewDocument() {
        console.log('view');
        this.template.querySelector("c-quote-comparison-response-item").handleSelectDownloadDocument();
    }
    handleRowSelection(event) {
        var selectedRows = event.detail.selectedRows;
        this.selectedBinder = selectedRows[0];
        console.log("selectedRows-->", JSON.stringify(this.selectedBinder));
    }
    closeBinderModal() {
        this.showBinderDialog = false;
        this.selectedBinder = '';
    }
    createQuote() {
        this.showBinderDialog = false;
        this.proceedAheadToCreateQuote(this.layerToCreateQuote);
    }
}


// import { LightningElement, api, track, wire  } from 'lwc';
// import { ShowToastEvent } from "lightning/platformShowToastEvent";
// import getMainColumns from '@salesforce/apex/quoteComparisonLWC_HangController.getMainColumns'; 
// export default class QuoteComparisonLWC_Hang extends LightningElement {
//     @track mainColumnWrapper;
//     modeEdit = false;
//     retentionVal = 500;
//     supplePaySelected = '10k / 10k';
//     retroDt = '2020/2/27';
//     connectedCallback(){
//         getMainColumns()
//         .then((result) => {
//             if(result.isSuccess){
//                 console.log('@@@data: ' + JSON.stringify(result.data));
//                 this.mainColumnWrapper = result.data;
//             }else{
//                 console.log('@@@error: ' + JSON.stringify(result.errors));
//             }
//         })
//         .catch((error) => {
//             console.log('@@@error: ' + JSON.stringify(error));
//             //this.error = error;
//         })

//         getMainColumns()
//         .then((result) => {
//             if(result.isSuccess){
//                 console.log('@@@data: ' + JSON.stringify(result.data));
//                 this.mainColumnWrapper = result.data;
//             }else{
//                 console.log('@@@error: ' + JSON.stringify(result.errors));
//             }
//         })
//         .catch((error) => {
//             console.log('@@@error: ' + JSON.stringify(error));
//             //this.error = error;
//         })
//     }
//     toggleModeEdit(evt){
//         this.modeEdit = !this.modeEdit;
//         if(this.modeEdit == true) {
//             evt.target.classList.add('slds-is-selected');
//         }else {
//             evt.target.classList.remove('slds-is-selected');
//         }
//     }
//     changeRerentionValue(evt){
//         this.retentionVal = evt.target.value;
//     }
//     changeSupplePaySelect(evt){
//         this.supplePaySelected = evt.target.value; 
//     }
//     changeRetroDt(evt){
//         this.retroDt = evt.target.value; 
//     }
// }