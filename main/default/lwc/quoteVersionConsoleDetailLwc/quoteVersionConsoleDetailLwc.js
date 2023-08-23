import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import createQuoteCompareItem from '@salesforce/apex/QuoteCompareItemWrapper.createQuoteCompareItem'
import createQuoteCompareItemQC from '@salesforce/apex/QuoteCompareItemWrapper.createQuoteCompareItemQC'
import createNewQuoteHandler from '@salesforce/apex/QuoteCompareItemWrapper.createNewQuoteHandler'
import cloneQuoteHandler from '@salesforce/apex/QuoteCompareItemWrapper.cloneQuoteHandler';
import deleteQuoteHandler from '@salesforce/apex/QuoteCompareItemWrapper.deleteQuoteHandler';
import updateCompareItem from '@salesforce/apex/QuoteCompareItemWrapper.updateCompareItem'
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import getRatingFromCallOut from '@salesforce/apex/RateController.getRatingFromCallOut';
import SYSTEM_ERROR_MSG from '@salesforce/label/c.SYSTEM_ERROR_MSG';
import createInitQuote from '@salesforce/apex/QuoteComparisonResponseLwcController.createInitQuote';
import initValuesQC from '@salesforce/apex/QuoteComparisonLWC.initValuesQC';
import getMasterBinders from '@salesforce/apex/OpportunityModifiersCmpController.getMasterBinders';
import updateExistingReferredQuotes from '@salesforce/apex/SubmissionInfoLwcController.updateExistingReferredQuotes';

const QUOTE_PROCESS_STATUS_UNDERWRITTING_ANALYSIS = 'Underwritting Analysis';

export default class QuoteVersionConsoleDetailLwc extends LightningElement {

    @api isPrimaryQuote;
    @track quoteTemplates = [];
    @track listWrapper = [];
    @track listWrapper = [];
    // @api mainColumnWrappers;
    @api mainTitleWrappers;
    @api quoteCompareItems;
    @api compareItem = [];
    @track quoteCompareWrapper = [];
    @track submissionObj = {};
    @track isAqueousProduct = false;
    @api quoteNames = [];
    @api quoteIds = [];
    @api quoteProcessSubmissionId = '';
    @api quoteCompareItemZero = [];
    firstRenderer = false;
    @track quoteType;
    @track isLoading = false;
    @track showScrollUp = false;
    @track showDetails = false;
    @api listMainSections = [];
    @api activeSections = [];
    @api quoteLayer;
    @api selectedMasterBinder;
    @api quoteComingThroughEvent = false;

    // @track isDisableButton = false;
    @api isPrimaryDisableButton = false;
    @api isExcessDisableButton = false;
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
    // current record's id
    @api currentRecordId;
    isReferredQuoteLocked = false;

    /*get subProduct() {
        return this.submission.data.fields.Product_Name__c.value;
    }*/
    
    @wire(CurrentPageReference) pageRef;

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
        //registerListener('deleteQuoteFromList', this.handleDeleteQuoteEvent, this);
        //registerListener('addNewCompareItemFromList', this.handleAddNewCompareItem, this);
        //registerListener('refreshCompareItemFromList', this.handleRefreshCompareItem, this);
        //registerListener('saveCompareItemFromList', this.handleUpdateQuote, this);
        //registerListener('refreshPageFromList', this.initValueProcess, this);
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
    a = 0;
    renderedCallback() {
        this.a++;
        console.log('I am in rendered callback iteration ' + this.a);
        console.log('I am in rendered callback');
        console.log('quoteProcessSubmissionId'+this.quoteProcessSubmissionId);
        console.log('quoteCompareItems'+this.quoteCompareItems);
        console.log('firstRenderer '+this.firstRenderer);
        if (this.firstRenderer == false) {
            console.log('I am in rendered callback1');
            this.firstRenderer = true;
            //if (this.quoteCompareItems !== undefined) {
                /*if(this.quoteComingThroughEvent){
                    this.handleInitValues();
                }
                else{
                    this.initValueProcess('');
                }*/
                this.handleInitValues();
                //console.log('quoteCompareItems', JSON.parse(JSON.stringify(this.quoteCompareItems)));
                //this.boundRect = this.template.querySelector('[data-id="parentCompareItem"]').getBoundingClientRect();
                //console.log("BoundRect-Render->", JSON.stringify(this.boundRect));
               
            //}
        }
        //registerListener('refreshPageFromList', this.handleChange, this);
    }
    handleChangeQuoteProcessStatus() {
        var infos = {status : QUOTE_PROCESS_STATUS_UNDERWRITTING_ANALYSIS};
        const event = new CustomEvent('changequoteprocessstatus', {
            detail: infos
        });
        this.dispatchEvent(event);        
    }

    @wire(getRecord, { recordId: '$currentRecordId', fields: ['Quote_Process__c.Name'] })
    underWriterWorkbenchRecord;

    /*get subStage() {
        return this.underWriterWorkbenchRecord.data.fields.Name.value;
    }*/

    handleInitValues() {
        //handle create quote here
        console.log('First Init for all of quoteComaparisionMainLwc.handleInitValues');
        console.log('vinay quote console layer: ' + this.quoteLayer);
        this.isLoading = true;
        console.log('quoteComingThroughEvent'+this.quoteComingThroughEvent);
        createInitQuote({opportunityId : this.quoteProcessSubmissionId,quoteLayer : this.quoteLayer,
        binderRecordObj : JSON.stringify(this.selectedMasterBinder), quoteComingThroughEvent : this.quoteComingThroughEvent})
        .then(response =>{
            console.log('Create Init Quote' + JSON.stringify(response));
            
            if(response.isSuccess){
                //Resetting the boolean propoerty to avoid multiple quotes creation (#54036) - similar to Cel
                this.dispatchEvent(new CustomEvent('resetquotecomingthrough'));

                var quoteId = response.data ;                    
                getRatingFromCallOut({objId : quoteId }).then(response =>{
                    console.log('Rating First Time' + JSON.stringify(response));
                    let errMsg = '';
                    if(response.isSuccess) {
                        this.showToast('Success !','Rating Successful','success');
                        this.initValueProcess(quoteId);
                    }else{
                        errMsg = response.errors[0];
                        this.showToast('Failed!','Rating has failed. Please contact your Administrator','error');
                        this.initValueProcess(quoteId);
                    }
                    }).catch(error =>{
                    this.showToast('Error !',JSON.stringify(error),'error');
                    //c/confirmationDialogLwc
                    this.initValueProcess(quoteId);
                });
            }else {
                if(response.errors){
                    if(this.quoteComingThroughEvent){                        
                        this.showToast('Failed to Create Quote',response.errors[0],'error');
                        this.handleChangeQuoteProcessStatus();
                        return;
                    }/*else                        
                        this.showToast('Error',response.errors[0],'error'); */
                }
                if(response.data == this.quoteProcessSubmissionId){
                    /*Commenting this alert temporarily. Need to check for better handling of cause.*/
                    //this.showToast('Choose Quote Layer','Please choose a Quote Layer on Underwriting Analysis Tab','warning','dismissable');
                    console.log('warning: ' + 'Please choose a Quote Layer on Underwriting Analysis Tab');
                    //this.handleChangeQuoteProcessStatus();
                    //this.initValueProcess('');
                    //return;
                }
                this.initValueProcess('');
                //this.template.querySelector("c-quote-version-console-detail-item-lwc").handleRefreshRelatedListComponent(this.quoteCompareItemZero,this.listMainSections,this.activeSections,this.isPrimaryQuote);
            }
            //this.initValueProcess('');
            //this.isLoading = false;
        }).catch(error =>{
            this.showToast('Error !',JSON.stringify(error),'error');
            this.initValueProcess('');

        });
        
    }


    @api
    initValueProcess(value1,value2) {
        this.isLoading = true;
        var quoteId = value1;
        var doChildRefresh = value2;
        initValuesQC({ submissionId: this.quoteProcessSubmissionId, isPrimaryQuote: this.isPrimaryQuote })
            .then((data) => {
                console.log('isPrimaryQuote', this.isPrimaryQuote);
                console.log('Init Data ' + JSON.stringify(data));
                console.log('data.quoteCompareItems -- ', JSON.stringify(data.quoteCompareItems));
                console.log('data.quoteCompareItems lgt-- ', data.quoteCompareItems.length);
                this.quoteCompareWrapper = data;
                this.quoteCompareWrapperForReloadData = data;
                let cloneParent = JSON.parse(JSON.stringify(data.parents));
                this.submissionObj = data.submission;
                var allQuotes = this.submissionObj.Quotes;
                this.listMainSections = JSON.parse(JSON.stringify(data.parents));
                var selectedQuoteStatus;
                var hasAnyReferredQuote = false;
                
                for (var i = 0; i < allQuotes.length; i++) {
                    var quoteType = allQuotes[i].Quote_Type__c;
                    var quoteStatus = allQuotes[i].Status;
                    var quoteLayer = allQuotes[i].Layer__c;
                    if (this.submissionObj.Product_Name__c == 'Professional Indemnity') {
                        if(quoteId == allQuotes[i].Id){
                            selectedQuoteStatus = allQuotes[i].Status;
                        }
                        if(quoteStatus == 'Referred'){
                            hasAnyReferredQuote = true;
                        }
                        this.isAqueousProduct = true;
                        if (this.submissionObj.Transaction_Status__c){
                            console.log("Transaction_Status__c null check");
                            if(this.submissionObj.Transaction_Status__c == 'Inactive'){
                                //this.isExcessDisableButton = true;
                                console.log("Transaction_Status__c IN");
                            }
                        }
                        if(this.submissionObj.StageName === 'Declined'){
                            this.isPrimaryDisableButton = true;
                            this.isExcessDisableButton = true;
                        }

                        
                        if ((quoteType == 'New Business' && quoteStatus == 'Bound' && quoteLayer == 'Primary') || (quoteType == 'Renewal' && quoteStatus == 'Bound' && quoteLayer == 'Primary')) {
                            console.log("Bound");
                            this.isPrimaryDisableButton = true;
                            break;
                        } else if (quoteType !== 'New Business' && quoteType !== 'Renewal') {
                            this.isPrimaryDisableButton = true;
                            break;
                        }
                    } else {
                        this.isAqueousProduct = false;
                        if ((quoteType == 'New Business' && (quoteStatus == 'Bound' || quoteStatus == 'Bound Pending')) ||
                            (quoteType == 'Renewal' && (quoteStatus == 'Bound' || quoteStatus == 'Bound Pending'))) {
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
                
                

                if(quoteId){
                    if(selectedQuoteStatus == 'Referred'){
                        this.isReferredQuoteLocked = false;
                        this.handleUpdateExistingReferredQuotes(quoteId);
                    }
                }
                else{
                    if(hasAnyReferredQuote){
                        this.isReferredQuoteLocked = false;
                        this.handleUpdateExistingReferredQuotes(this.quoteProcessSubmissionId);
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
                let endorsementReasonsAQ = JSON.parse(JSON.stringify(data.listOfAQEndorsementReasons));
                let mapOfAQEndorsementVsReasons = new Map();
                for(let i = 0; i < endorsementReasonsAQ.length; i++){
                    mapOfAQEndorsementVsReasons.set(endorsementReasonsAQ[i].Label, endorsementReasonsAQ[i].Endorsement_Reason__c);
                }

                for (let i = 0; i < clone.length; i++) {
                    for (let j = 0; j < clone[i].quoteFields.length; j++) {
                        console.log('clone[i].quoteFields[j].sourceFieldAPI'+clone[i].quoteFields[j].sourceFieldAPI);
                        if(this.isAqueousProduct && (clone[i].quoteFields[j].sourceFieldAPI == 'Binder__c' || clone[i].quoteFields[j].sourceFieldAPI == 'Policy_Wording__c' || clone[i].quoteFields[j].sourceFieldAPI == 'Territorial_Limits__c' || clone[i].quoteFields[j].sourceFieldAPI == 'Jurisdiction_Limits__c' || clone[i].quoteFields[j].sourceFieldAPI == 'Retroactive_Date__c' || clone[i].quoteFields[j].sourceFieldAPI == 'RetroDate__c')){
                            clone[i].quoteFields[j].isAQQuotedFields = true;
                            console.log('True -->'+true);
                            console.log('item.isAQQuotedFields -->'+clone[i].quoteFields[j].isAQQuotedFields)
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

                            if( this.submissionObj.StageName === 'Closed Lost' ){
                                this.isPrimaryDisableButton = true;
                                this.isExcessDisableButton = true; 
                            }
                            console.log('isPrimaryDisableButton 2', this.isPrimaryDisableButton + 'Excess:' + this.isExcessDisableButton);
                        }
                        if(this.isAqueousProduct && clone[i].quoteFields[j].sourceFieldAPI == 'Endorsement_Reason__c'
                            && mapOfAQEndorsementVsReasons && mapOfAQEndorsementVsReasons.has(clone[i].quoteType)){
                            let allEndorsementReasons = clone[i].quoteFields[j].picklistOption.split(';');
                            let segregatedEndorsementReasons = '';
                            for(let k = 0; k < allEndorsementReasons.length; k++){
                                if(mapOfAQEndorsementVsReasons.get(clone[i].quoteType).includes(allEndorsementReasons[k])){
                                    if(segregatedEndorsementReasons){
                                        segregatedEndorsementReasons = segregatedEndorsementReasons + ';' + allEndorsementReasons[k];
                                    }
                                    else{
                                        segregatedEndorsementReasons = allEndorsementReasons[k];
                                    }
                                }
                            }
                            clone[i].quoteFields[j].picklistOption = segregatedEndorsementReasons;
                        }
                    }
                }
                this.quoteCompareItems = clone;
                if (clone.length > 0) {
                    let temp;
                    if(this.submissionObj.Product_Name__c == 'Private Company Combo'){
                        // for (let i = clone.length - 1; i > -1; i--){
                        //     temp = JSON.parse(JSON.stringify(clone[i]));
                        //     if(temp.quoteStatus != 'Closed') break;
                        // }
                        for (let i = 0; i < clone.length; i++){
                            temp = JSON.parse(JSON.stringify(clone[i]));
                            if(temp.quoteStatus != 'Closed') break;
                        }
                    }
                    else{
                        temp = JSON.parse(JSON.stringify(clone[clone.length - 1]));
                    }
                    
                    //quoteVersion cannot be deserialized in Apex so it will cause error when create new QuoteCompareItem
                    temp.quoteVersions = [];
                    console.log('Quote ID:'+quoteId);
                    if(quoteId !== ''){
                        clone.forEach(item => {
                            if(item.quoteId === quoteId){
                                this.quoteCompareItemZero = item;
                                if(item.quoteLayer === 'Excess'){
                                    this.isPrimaryQuote = false;
                                }
                                else{
                                    this.isPrimaryQuote = true;
                                }
                            }
                        });
                    }
                    else{
                        this.quoteCompareItemZero = temp;
                        if(temp.quoteLayer === 'Excess'){
                            this.isPrimaryQuote = false;
                        }
                        else{
                            this.isPrimaryQuote = true;
                        }
                    }
                    
                }
                var quoteCompareItemZero = this.quoteCompareItemZero;
                var quoteLayer = quoteCompareItemZero.quoteLayer;
                var quoteType = quoteCompareItemZero.quoteType;
                var listMainSections = JSON.parse(JSON.stringify(this.listMainSections));
                var activeSections = [];
                listMainSections.forEach(function(item,index) {
                    if (
                        (quoteType !== 'Full Amendment' &&
                        quoteType !== 'Coverage Amendment' &&
                        quoteType !== 'Midterm Cancellation' &&
                        quoteType !== 'Flat Cancellation (Ab - Initio)' &&
                        quoteType !== 'Flat Cancellation') &&
                        item.name === 'Change in Premiums'
                    ) {
                        listMainSections.splice(index, 1);
                    }
                    else {
                        for (var i = 0; i< listMainSections[index].childs.length; i++) {
                            listMainSections[index].childs[i].readOnly = false;
                        }
                        
                    }
                });
                listMainSections.forEach(function(item,index) {
                    console.log(quoteLayer);
                    var itemLayer = item.quoteLayer.split(';');
                    console.log(itemLayer);
                    if(itemLayer.includes(quoteLayer)){
                        if(!activeSections.includes(item.name)){
                            activeSections.push(item.name);
                        }
                    }
                    else{
                        listMainSections.splice(index, 1);
                    }
                });
                this.activeSections = activeSections;
                let isAQPI = this.isAqueousProduct;
                listMainSections.forEach(function(item,index) {
                    if(item.name == 'Quote Details' && quoteLayer == 'Primary'){
                        item.childs.forEach(function(item2,index2) {
                            if(item2.name == 'Total Underlying Layer'){
                                item.childs.splice(index2, 1);
                            }
                        });
                    }

                    let itemsToRemove = [];
                    item.childs.forEach(function(item2,index2) {
                        console.log('vinay quote layer ' + quoteLayer + ' ' + item2.quoteLayer + ' ' + isAQPI);
                        if(!isAQPI && item2.quoteLayer && item2.quoteLayer != '' && !item2.quoteLayer.includes(quoteLayer)){
                            console.log('vinay quote layer remove ' + quoteLayer + ' ' + item2.quoteLayer + ' ' + isAQPI);
                            //item.childs.splice(index2, 1);
                            itemsToRemove.push(index2);
                        }
                    });
                    for (var i = itemsToRemove.length -1; i >= 0; i--)
                        item.childs.splice(itemsToRemove[i], 1);

                    if(item.name == 'Quote Details' && (quoteType !== 'Full Amendment' && quoteType !== 'Coverage Amendment'
                        && quoteType !== 'Flat Cancellation' && quoteType !== 'Midterm Cancellation' &&  quoteType !== 'Amendment') &&
                        quoteType !== 'Policy Duration Change' && quoteType !== 'Update Insured Name or Address' && quoteType !== 'Extended Reporting Period (ERP)' ){
                        item.childs.forEach(function(item2,index2) {
                            if(item2.name == 'Endorsement Effective Date'){
                                if(isAQPI){
                                    item.childs.splice(index2, 2);
                                }
                                else{
                                    item.childs.splice(index2, 1);
                                }
                            }
                        });
                    }
                });
                console.log("listMainSections details--->",JSON.stringify(listMainSections));
                console.log("quoteCompareItemZero details--->",JSON.stringify(quoteCompareItemZero));
                this.listMainSections = JSON.parse(JSON.stringify(listMainSections));
                if(doChildRefresh === true){
                    console.log("quoteCompareItemZero details--->",JSON.stringify(quoteCompareItemZero));
                    this.template.querySelector("c-quote-version-console-detail-item-lwc").handleRefreshDetailComponent(this.quoteCompareItemZero,this.listMainSections,this.activeSections,this.isPrimaryQuote);
                }
                //this.setcompareItem(this.quoteCompareItemZero);
                this.isLoading = false;
                this.showDetails = true;
            })
            .catch((error) => {
                console.log('@@@error: ' + JSON.stringify(error));
                this.isLoading = false;
            })
    }

    handleReferredQuoteLocking(event){
        let quoteId = event.detail.quoteId;
        this.handleUpdateExistingReferredQuotes(quoteId);
    }

    handleUpdateExistingReferredQuotes(quoteId){
        updateExistingReferredQuotes({ recordId: quoteId })
        .then(result => {
            console.log("Success");
        })
        .catch((error) => {
            console.log("Error"+error);
            if (error.body.message.includes('ENTITY_IS_LOCKED')) {
                this.isReferredQuoteLocked = true;
            }
        });
    }

    setcompareItem(value) {
        // console.log("@@@value: " + JSON.stringify(value));
        var quoteType;
        this._compareItem = value;
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
            if(item.endorsementType == 'Midterm Cancellation'){
                item.readOnly = true;
            }            
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
            }

            if (item.sourceFieldAPI == 'Effective_Date__c') {
                this.defaultOpportunityInceptionDate = item.value;
            }
        })

        console.log("defaultOpportunityInceptionDate-->", this.defaultOpportunityInceptionDate);
        this._compareItem = clone;
        console.log('Compare item -->'+JSON.stringify(this._compareItem));
        
    }

    handleUpdateQuote(event) {

        var sendDate = (new Date()).getMilliseconds();
        var quoteId = event.detail.quoteId;
        var quoteVerId = event.detail.quoteVerId;
        var selectedBinder = event.detail.selectedBinder;
        let updateObjects = { listUpdate: [] };
        let updateData = JSON.parse(JSON.stringify(event.detail.data));

        var isCreateQuoteVer = false;
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
                        /******** Fix for 54090 ******/
                        if(this.quoteCompareItems[i].quoteFields[k].fieldName == 'Binder' && this.quoteCompareItems[i].quoteFields[k].value == '' && updateData.quoteFields[k].value == ''){
                            console.log('Master Binder Selected')
                            let upBinder = {
                                id: updateData.quoteFields[k].fieldId,
                                name: updateData.quoteFields[k].fieldName,
                                sourceObject: updateData.quoteFields[k].sourceObject,
                                fieldApi: updateData.quoteFields[k].sourceFieldAPI,
                                value: selectedBinder.Id
                            };
                            updateObjects.listUpdate.push(upBinder);
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

                        if (isRate == true) { // rate for quoteComparision Duc - 8/6/2020
                            childItem.rateQuote();
                        } else {
                            let eventTemp = event;
                            eventTemp.detail.quoteId = quoteId;
                            this.handleRefreshQuoteDetail(eventTemp);
                            this.showToast("Success", "Update records successfully!", "success");
                            childItem.isLoading = false;
                        }

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
        //this.reloadData();
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

    handleRefreshQuoteDetail(event){
        console.log('in handleRefreshQuoteDetail');
        console.log('in handleRefreshQuoteDetail inside if');
        this.isLoading = true;
        //this.showDetails = false;
        let quoteId;
        if(event){
            quoteId = event.detail.quoteId;
        }
        
        if(quoteId){
            console.log('quoteId'+quoteId);
            let clone = JSON.parse(JSON.stringify(this.quoteCompareItems));
            clone.forEach(item => {
                if(item.quoteId === quoteId){
                    let temp = JSON.parse(JSON.stringify(item));
                    this.quoteCompareItemZero = temp;
                }
            })
            console.log('this.quoteCompareItemZero'+this.quoteCompareItemZero);
            this.initValueProcess(quoteId,true);
            //this.template.querySelector("c-quote-version-console-detail-item-lwc").handleRefreshDetailComponent(this.quoteCompareItemZero,this.listMainSections,this.activeSections,this.isPrimaryQuote);
        }
        else{
            this.initValueProcess('',true);
            //this.template.querySelector("c-quote-version-console-detail-item-lwc").handleRefreshDetailComponent(this.quoteCompareItemZero,this.listMainSections,this.activeSections,this.isPrimaryQuote);
        }
        
    }

    handleAddNewQuote(layerName) {
    //    var layerName = event.target.value;
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
                                //this.createCompareItem(quoteId);
                                this.showToast('Success', 'Rating Successful', 'success');
                                this.initValueProcess(quoteId,true);
                                //this.template.querySelector("c-quote-version-console-detail-item-lwc").handleRefreshDetailComponent(this.quoteCompareItemZero,this.listMainSections,this.activeSections,this.isPrimaryQuote);
                            } else {
                                //rate fail
                                ///this.createCompareItem(quoteId);
                                this.showToast('Error', response.errors[0], 'error');
                                this.initValueProcess(quoteId,true);
                                //this.template.querySelector("c-quote-version-console-detail-item-lwc").handleRefreshDetailComponent(this.quoteCompareItemZero,this.listMainSections,this.activeSections,this.isPrimaryQuote);
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

                if (allowPush) {
                this.quoteCompareItems.push(temp);
                this.quoteCompareItemZero = temp;
                console.log('allowPush===',allowPush);
                console.log('this.quoteCompareItemZero===',this.quoteCompareItemZero);
                this.template.querySelector("c-quote-version-console-detail-item-lwc").handleRefreshDetailComponent(this.quoteCompareItemZero,this.listMainSections,this.activeSections,this.isPrimaryQuote
                    
                    
                    
                    
                    );
                }
                console.log("this.quoteLayer->", this.quoteLayer);
                console.log("this.quoteLayerlast->", temp.quoteLayer);
                //Navigate to desired layer tab
                /*const navigatetab = new CustomEvent(
                    "navigatetab", {
                    detail: temp.quoteLayer,
                });
                this.dispatchEvent(navigatetab);*/
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

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handleQuoteCreation(event){
        const layerName = event.detail.layerName;
        this.handleAddNewQuote(layerName);
    }

    handleCloneQuote(event) {
        console.log('Handle Clone Quote');
        if (this.isLoading === false) {
            this.isLoading = true;
            let selectedQuote = event.detail.quoteId;
            cloneQuoteHandler({ quoteId: selectedQuote })
                .then(response => {
                    if (response.isSuccess == false) {
                        console.log('Handle Clone Quote FAILURE');
                        this.showToast("Error", response.errors[0], 'Error');
                        this.isLoading = false;
                    }
                    else {
                        console.log('Handle Clone Quote SUCCESS');
                        let eventTemp = event;
                        eventTemp.detail.quoteId = response.data.Id;
                        this.handleRefreshQuoteDetail(eventTemp);
                        //this.createCompareItem(quoteId);
                        //End rate Quote
                    }

                }).catch((error) => {
                    this.showToast('Error', JSON.stringify(error), 'error');
                    this.isLoading = false;
                });
        }
    }

    handleDeleteQuote(event) {
        let quoteId = event.detail.quoteId;
        let closeReason = event.detail.closeReason;
        let clone = [];

        this.quoteCompareItems = this.quoteCompareItems.filter(item => item.quoteId !== quoteId);
         //deleteQuoteHandler({quoteId: quoteId}); 
        const fields = {
            Id: quoteId,
            Status: 'Closed',
            Closed_Reason__c: closeReason
        };
        updateRecord({ fields })
            .then((result) => {
                console.log('handleDeleteQuote:', JSON.stringify(result));
                let eventTemp;
                this.handleRefreshQuoteDetail();
            })
            .catch(error => {
                console.log('Error updating record quote status :' + JSON.stringify(error));
            });
    }

}