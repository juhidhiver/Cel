import { LightningElement, wire, api, track } from 'lwc';
import getMainSectionFromProductLwc from '@salesforce/apex/OpportunityModifiersCmpController.getMainSectionFromProductLwc';
import saveRecordTabLwc from '@salesforce/apex/OpportunityModifiersCmpController.saveRecordTabLwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import ERROR_CANNOT_UPDATE_SUBMISSION_HAS_LOCKED_QUOTE from '@salesforce/label/c.ERROR_CANNOT_UPDATE_SUBMISSION_HAS_LOCKED_QUOTE';
import getMainProfession from '@salesforce/apex/OpportunityModifiersCmpController.getMainProfession';
import getSubmissionDetails from '@salesforce/apex/OpportunityModifiersCmpController.getSubmissionDetails';
import updateExistingReferredQuotes from '@salesforce/apex/SubmissionInfoLwcController.updateExistingReferredQuotes';
import saveUWAnalysis from '@salesforce/apex/UWAnalysisSectionController.saveUWAnalysis';
import { refreshApex } from '@salesforce/apex';
import {registerListener, unregisterAllListeners} from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
const QUOTE_PROCESS_STATUS_SUBMISSION_INFO = 'Submission Info';

export default class UnderwrittingAnalysisTabLwc extends LightningElement {

    @api productName;
    @api _opportunityId;
    @api mainSectionWraps = [];
    @api mainActiveSections = [];
    @track isOpenModal = false;
    @track isNotHaveData = false;
    @track inputClass = 'inputCmp';
    @track workTypeAnalysisSection = 'Splits Table';
    @api annualGrossFee;
    @track isPrimaryDisableButton = false;
    @track isExcessDisableButton = false;
    @track isProductAQPI = false;
    @track proposalFormFullProposal = false;
    @track rateablePreviousYear = false;
    @track rateablePreviousYearValue;
    @track annualGrossPreviousYear = false;
    @track annualGrossPreviousYearValue;
    @track mainProfession;
    @track lastFullProposalFormFilePreviousValue;
    @track ratingModValuesChnged = [];
    @track disableSaveButton = false;
    @track disableProsAndCons = false;
    //Mary Start
    @track claimCountReturned  ;
    @track claimDetails;
    @track noClaimsReturned = false;

    handleClaimDetailLabel(event)
    {   
        this.claimCountReturned = event.detail;
   
        if(this.claimCountReturned == 0)
        {
            this.noClaimsReturned = true
         }
        else
        {
            this.noClaimsReturned = false;
        }
        this.claimDetails = 'Claim Details'+' ('+ this.claimCountReturned +')' ;
        console.log('claimCountReturned'+ this.claimCountReturned );

    }
// Mary Stop
    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        registerListener('refreshUnderwritterAnalysisTab', this.refreshUnderwritterAnalysis, this); 
        this.getSubmissionData();        
    }
    refreshUnderwritterAnalysis(){
        this.getMainSections();
    }
    getSubmissionData(){
        getSubmissionDetails({ opportunityId: this._opportunityId })
            .then(result => {                                       
                let oppStage = result.submissionDetails.StageName;
                let prodName = result.submissionDetails.Product_Name__c;
                if(oppStage == "Closed Won" || oppStage == "Closed Lost" || oppStage == "Declined" || result.disableSplitSection){                    
                    this.disableSaveButton = true;
                    if(oppStage == "Declined") this.disableProsAndCons = true;
                }
                if(prodName == 'Professional Indemnity'){        
                    this.isExcessDisableButton = result.isExcessButtonDisabled;
                    this.isPrimaryDisableButton = result.isPrimaryButtonDisabled;
                }
            })
            .catch(error => {
                console.log("Error-->",JSON.stringify(error));
            });
    }
    set opportunityId(value) {
        this._opportunityId = value;
        console.log('@@@this.productName: ' + this.productName);
        console.log('@@@this.opportunityId: ' + value);
        if (this.productName == 'Professional Indemnity') this.isProductAQPI = true;
        this.getMainSections();
    }
    @api
    get opportunityId() {
        return this._opportunityId;
    }

    getMainSections = () => {
        getMainSectionFromProductLwc({ productName: this.productName, opportunityId: this._opportunityId })
            .then(data => {
                if (data) {
                    this.mainSectionWraps = data.data;
                    this.mainActiveSections = data.data.activeSections;
                    console.log('Main acion section :' + JSON.stringify(this.mainActiveSections));
                    var tmp = JSON.parse(JSON.stringify(data.data));
                    if (tmp.mainSections.length > 0) {
                        var mainSecWrap = tmp.mainSections;
                        for (var i = 0; i < mainSecWrap.length; i++) {
                            var obj = JSON.parse(JSON.stringify(mainSecWrap[i].items));
                            console.log("On load Values =>"+(JSON.stringify(mainSecWrap[i].items)));
                            for (var j = 0; j < obj.length; j++) {
                                if (this.isProductAQPI) {
                                    if (obj[j].item.Name == 'Annual gross fees / turnover' && obj[j].item.Rating_Modifier_Value__c != undefined) {
                                        this.annualGrossFee = obj[j].item.Rating_Modifier_Value__c;
                                        console.log('Inside for each Annual gross fees / turnover', obj[j].item.Rating_Modifier_Value__c);
                                        console.log('Inside for each Annual gross fees / turnover', obj[j].item.Name);
                                    }
                                    if (obj[j].item.Name == 'Is the Proposal Form a full Proposal?') {
                                        if (obj[j].item.Rating_Modifier_Value__c == 'Yes') {
                                            this.proposalFormFullProposal = true;
                                        } else {
                                            this.proposalFormFullProposal = false;
                                        }
                                    }
                                    if (obj[j].item.Name == 'Rateable Exposure - Previous Year') {
                                        if (obj[j].item.Rating_Modifier_Value__c) {
                                            this.rateablePreviousYear = true;
                                            this.rateablePreviousYearValue = obj[j].item.Rating_Modifier_Value__c;
                                            console.log("this.rateablePreviousYearValue-->",this.rateablePreviousYearValue);
                                        }
                                    } else if (obj[j].item.Name == 'Annual gross fees / turnover - Previous Year') {
                                        if (obj[j].item.Rating_Modifier_Value__c) {
                                            this.annualGrossPreviousYear = true;
                                            this.annualGrossPreviousYearValue = obj[j].item.Rating_Modifier_Value__c;
                                            console.log("this.annualGrossPreviousYearValue-->",this.annualGrossPreviousYearValue);
                                        }
                                    }
                        
                                    if(this.disableSaveButton){
                                        obj[j].isReadOnly = true;
                                    }                                                                                                    
                                }


                                console.log('Format 1:' + obj[j].item.Format__c);
                                switch (obj[j].item.Format__c) {
                                    case 'Date': {
                                        obj[j].item.isDate = true;
                                        break;
                                    }
                                    case 'Picklist': {
                                        obj[j].item.isPicklist = true;
                                        break;
                                    }
                                    case 'Radio Button': {
                                        obj[j].item.isRadioButton = true;
                                        break;
                                    }
                                    case 'Currency': {
                                        obj[j].item.isCurrency = true;
                                        break;
                                    }
                                    case 'Percentage': {
                                        obj[j].item.isPercentage = true;
                                        break;
                                    }
                                    case 'Integer': {
                                        obj[j].item.isInteger = true;
                                        break;
                                    }
                                    case 'Number': {
                                        obj[j].item.isNumber = true;
                                        break;
                                    }
                                    case 'Text': {
                                        obj[j].item.isText = true;
                                        break;
                                    }
                                    case 'Text Area': {
                                        obj[j].item.isTextArea = true;                                        
                                        break;
                                    }
                                }

                            }
                            mainSecWrap[i].items = obj;
                            var subSecWrap = mainSecWrap[i].subSections;
                            for (var j = 0; j < subSecWrap.length; j++) {
                                var subObj = JSON.parse(JSON.stringify(subSecWrap[j].items));
                                for (var k = 0; k < subObj.length; k++) {
                                    switch (subObj[k].item.Format__c) {
                                        case 'Date': {
                                            subObj[k].item.isDate = true;
                                            break;
                                        }
                                        case 'Picklist': {
                                            subObj[k].item.isPicklist = true;
                                            break;
                                        }
                                        case 'Radio Button': {
                                            subObj[k].item.isRadioButton = true;
                                            break;
                                        }
                                        case 'Currency': {
                                            subObj[k].item.isCurrency = true;
                                            break;
                                        }
                                        case 'Percentage': {
                                            subObj[k].item.isPercentage = true;
                                            break;
                                        }
                                        case 'Integer': {
                                            subObj[k].item.isInteger = true;
                                            break;
                                        }
                                        case 'Number': {
                                            subObj[k].item.isNumber = true;
                                            break;
                                        }
                                        case 'Text': {
                                            subObj[k].item.isText = true;
                                            break;
                                        }
                                    }
                                }
                                subSecWrap[j].items = subObj;
                            }

                        }
                        this.mainSectionWraps = tmp;
                    } else {
                        this.isNotHaveData = true;
                    }

                    console.log('Final result DATA:' + JSON.stringify(this.mainSectionWraps));
                    /*
                    tmp.mainSections.forEach(function(mainSecWrap) {
                        mainSecWrap.forEach(function(obj) {
                            console.log('Format:' + obj.item.Format__c);
                        });
                        
                    });*/
                    //console.log('mainSectionWraps mainSectionWraps.mainSections:' + JSON.stringify(this.mainSectionWraps));
                }
                else if (error) {
                    console.log('##error :' + JSON.stringify(error));
                }
            })
            .catch(error => {
                console.log('##error :' + JSON.stringify(error));
            })

        if (this.isProductAQPI) {
            if (!this.mainProfession) {
                getMainProfession({ opportunityId: this.opportunityId })
                    .then(result => {
                        if (result) this.mainProfession = result;
                        console.log(result);
                    })
            }
        }
    }

    refreshDataAfterValueChange = (mainSectionWrs) =>{
        console.log('IN refresh data');
        if (mainSectionWrs) {
            var mainSecWrap = mainSectionWrs;
            for (var i = 0; i < mainSecWrap.length; i++) {
                var obj = JSON.parse(JSON.stringify(mainSecWrap[i].items));
                console.log("On load Values =>"+(JSON.stringify(mainSecWrap[i].items)));
                for (var j = 0; j < obj.length; j++) {
                    if (this.isProductAQPI) {
                        if (obj[j].item.Name == 'Annual gross fees / turnover' && obj[j].item.Rating_Modifier_Value__c != undefined) {
                            this.annualGrossFee = obj[j].item.Rating_Modifier_Value__c;
                            console.log('Inside for each Annual gross fees / turnover', obj[j].item.Rating_Modifier_Value__c);
                            console.log('Inside for each Annual gross fees / turnover', obj[j].item.Name);
                        }
                        if (obj[j].item.Name == 'Is the Proposal Form a full Proposal?') {
                            if (obj[j].item.Rating_Modifier_Value__c == 'Yes') {
                                this.proposalFormFullProposal = true;
                            } else {
                                this.proposalFormFullProposal = false;
                            }
                        }
                        if (obj[j].item.Name == 'Rateable Exposure - Previous Year') {
                            if (obj[j].item.Rating_Modifier_Value__c) {
                                this.rateablePreviousYear = true;
                                this.rateablePreviousYearValue = obj[j].item.Rating_Modifier_Value__c;
                                console.log("this.rateablePreviousYearValue-->",this.rateablePreviousYearValue);
                            }
                        } else if (obj[j].item.Name == 'Annual gross fees / turnover - Previous Year') {
                            if (obj[j].item.Rating_Modifier_Value__c) {
                                this.annualGrossPreviousYear = true;
                                this.annualGrossPreviousYearValue = obj[j].item.Rating_Modifier_Value__c;
                                console.log("this.annualGrossPreviousYearValue-->",this.annualGrossPreviousYearValue);
                            }
                        }  
                    }


                    console.log('Format 1:' + obj[j].item.Format__c);
                    switch (obj[j].item.Format__c) {
                        case 'Date': {
                            obj[j].item.isDate = true;
                            break;
                        }
                        case 'Picklist': {
                            obj[j].item.isPicklist = true;
                            break;
                        }
                        case 'Radio Button': {
                            obj[j].item.isRadioButton = true;
                            break;
                        }
                        case 'Currency': {
                            obj[j].item.isCurrency = true;
                            break;
                        }
                        case 'Percentage': {
                            obj[j].item.isPercentage = true;
                            break;
                        }
                        case 'Integer': {
                            obj[j].item.isInteger = true;
                            break;
                        }
                        case 'Number': {
                            obj[j].item.isNumber = true;
                            break;
                        }
                        case 'Text': {
                            obj[j].item.isText = true;
                            break;
                        }
                        case 'Text Area': {
                            obj[j].item.isTextArea = true;                                        
                            break;
                        }
                    }

                }
                mainSecWrap[i].items = obj;
                var subSecWrap = mainSecWrap[i].subSections;
                for (var j = 0; j < subSecWrap.length; j++) {
                    var subObj = JSON.parse(JSON.stringify(subSecWrap[j].items));
                    for (var k = 0; k < subObj.length; k++) {
                        switch (subObj[k].item.Format__c) {
                            case 'Date': {
                                subObj[k].item.isDate = true;
                                break;
                            }
                            case 'Picklist': {
                                subObj[k].item.isPicklist = true;
                                break;
                            }
                            case 'Radio Button': {
                                subObj[k].item.isRadioButton = true;
                                break;
                            }
                            case 'Currency': {
                                subObj[k].item.isCurrency = true;
                                break;
                            }
                            case 'Percentage': {
                                subObj[k].item.isPercentage = true;
                                break;
                            }
                            case 'Integer': {
                                subObj[k].item.isInteger = true;
                                break;
                            }
                            case 'Number': {
                                subObj[k].item.isNumber = true;
                                break;
                            }
                            case 'Text': {
                                subObj[k].item.isText = true;
                                break;
                            }
                        }
                    }
                    subSecWrap[j].items = subObj;
                }

            }
        }
        console.log('END refresh data');
    }

    handleNotionalIncomeChange(event) {
        var notionalIncome = event.detail;
        console.log("notionalIncome-->",notionalIncome);
        console.log("@@@ notionalIncome update");
        if (notionalIncome && this.mainProfession == 'Design & Construct') {
            var mainSectionWrs = JSON.parse(JSON.stringify(this.mainSectionWraps.mainSections));
            this.handleRateableExpChange(notionalIncome, mainSectionWrs);
        }
    }

    handleRateableExpChange = (newVal, jsonStr) => {
        var mainSectionWrs = jsonStr;
        var rateableExposure;
        if (newVal) {
            //var mainSectionWrs = JSON.parse(JSON.stringify(this.mainSectionWraps.mainSections));     
            mainSectionWrs.forEach(mainSecWrap => {
                console.log("@@@mainSecWrap.items: " + mainSecWrap.items);
                mainSecWrap.items.forEach(obj => {
                    if (obj.item.Name == 'Rateable Exposure') {
                        console.log("@@@ Rateable Exposure update");
                        obj.item.Rating_Modifier_Value__c = newVal;
                        rateableExposure = obj.item.Rating_Modifier_Value__c;
                        console.log("@@@Rateable Exposure value: " + obj.item.Rating_Modifier_Value__c);
                        console.log("@@@ Rateable Exposure mainSectionWr: " + JSON.stringify(mainSectionWrs));
                    }
                    if (this.rateablePreviousYear) {
                        if (obj.item.Name == 'Rateable Exposure - Change') {
                            console.log('rateableExposure-->',rateableExposure);
                            console.log('inside change thing');
                            //Rateable Exposure" / "Rateable Exposure - Previous Year
                            if (newVal) {
                                console.log('this.newVal --', newVal, '  this.rateablePreviousYearValue--', this.rateablePreviousYearValue);
                                if(this.rateablePreviousYearValue){
                                    obj.item.Rating_Modifier_Value__c = ((parseFloat(newVal) - parseFloat(this.rateablePreviousYearValue))/ parseFloat(this.rateablePreviousYearValue) * 100).toFixed(2);
                                }                                                                
                                if(obj.item.Rating_Modifier_Value__c){
                                    if(obj.item.Rating_Modifier_Value__c > 0){
                                        obj.item.Rating_Modifier_Value__c = '+'+obj.item.Rating_Modifier_Value__c+'%';
                                    }else{
                                        obj.item.Rating_Modifier_Value__c += '%';
                                    }  
                                }
                            }
                        }
                    }                    
                });
            });
            this.refreshDataAfterValueChange(mainSectionWrs);
            this.mainSectionWraps.mainSections = mainSectionWrs;
        }
    }

    changeProposalFormDate = (date, jsonStr) => {
        console.log('this.proposalFormFullProposal', this.proposalFormFullProposal);
        var mainSectionWrs = jsonStr;
        if (date) {
            //var mainSectionWrs = JSON.parse(JSON.stringify(this.mainSectionWraps.mainSections));     
            mainSectionWrs.forEach(mainSecWrap => {
                console.log("@@@mainSecWrap.items: " + mainSecWrap.items);
                mainSecWrap.items.forEach(obj => {
                    if (obj.item.Name == 'Date of Last Full Proposal Form on file') {
                        this.lastFullProposalFormFilePreviousValue = obj.item.Rating_Modifier_Value__c;
                        console.log("@@@ changeProposalFormDate update--", date);
                        obj.item.Rating_Modifier_Value__c = date;
                    }
                });
            });
            console.log('11 this.lastFullProposalFormFilePreviousValue -- >',this.lastFullProposalFormFilePreviousValue); 
            return this.mainSectionWraps.mainSections = mainSectionWrs;
        } else {
            console.log('Inside change propsal dqate YES -- ', date, '--', jsonStr);
            var proposalDate;
            mainSectionWrs.forEach(mainSecWrap => {
                console.log("@@@mainSecWrap.items: " + mainSecWrap.items);
                mainSecWrap.items.forEach(obj => {
                    if (obj.item.Name == 'Proposal Form Date') {
                        proposalDate = obj.item.Rating_Modifier_Value__c;
                        console.log("@@@ proposalDate: " + obj.item.Rating_Modifier_Value__c);
                    }
                    if (obj.item.Name == 'Date of Last Full Proposal Form on file') {
                        this.lastFullProposalFormFilePreviousValue = obj.item.Rating_Modifier_Value__c;
                        obj.item.Rating_Modifier_Value__c = proposalDate;
                        console.log("@@@ lastProposalDate: " + obj.item.Rating_Modifier_Value__c);
                    }
                });
            });
            console.log('12 this.lastFullProposalFormFilePreviousValue -- >',this.lastFullProposalFormFilePreviousValue); 
            return this.mainSectionWraps.mainSections = mainSectionWrs;
        }
    }    
    handleChangeForPriorValues = (newVal, jsonStr) => {
        var mainSectionWrs = jsonStr;
        if (newVal) {
            //var mainSectionWrs = JSON.parse(JSON.stringify(this.mainSectionWraps.mainSections));     
            mainSectionWrs.forEach(mainSecWrap => {
                console.log("@@@mainSecWrap.items: " + mainSecWrap.items);
                mainSecWrap.items.forEach(obj => {
                    if (obj.item.Name == 'Annual gross fees / turnover - change') {
                        if (this.annualGrossPreviousYear) {
                            obj.item.Rating_Modifier_Value__c = ((parseFloat(newVal) - parseFloat(this.annualGrossPreviousYearValue)) / parseFloat(this.annualGrossPreviousYearValue) * 100).toFixed(2);                            
                        }                        
                        if(obj.item.Rating_Modifier_Value__c){
                            if(obj.item.Rating_Modifier_Value__c > 0){
                                obj.item.Rating_Modifier_Value__c = '+'+obj.item.Rating_Modifier_Value__c+'%';
                            }else{
                                obj.item.Rating_Modifier_Value__c += '%';
                            }  
                        }                     
                    }
                    if (obj.item.Name == 'Rateable Exposure - Change') {
                        if (this.rateablePreviousYear) {
                            obj.item.Rating_Modifier_Value__c = ((parseFloat(newVal) - parseFloat(this.rateablePreviousYearValue)) / parseFloat(this.rateablePreviousYearValue) * 100).toFixed(2);                            
                        }                        
                        if(obj.item.Rating_Modifier_Value__c){
                            if(obj.item.Rating_Modifier_Value__c > 0){
                                obj.item.Rating_Modifier_Value__c = '+'+obj.item.Rating_Modifier_Value__c+'%';
                            }else{
                                obj.item.Rating_Modifier_Value__c += '%';
                            }  
                        }                        
                    }
                });
            });
            this.mainSectionWraps.mainSections = mainSectionWrs;
        }
    }

    handleChangeForPriorValuesForDnC = (newVal, jsonStr) => {
        var mainSectionWrs = jsonStr;
        if (newVal) {
            //var mainSectionWrs = JSON.parse(JSON.stringify(this.mainSectionWraps.mainSections));     
            mainSectionWrs.forEach(mainSecWrap => {
                console.log("@@@mainSecWrap.items: " + mainSecWrap.items);
                mainSecWrap.items.forEach(obj => {
                    if (obj.item.Name == 'Annual gross fees / turnover - change') {
                        if (this.annualGrossPreviousYear) {
                            obj.item.Rating_Modifier_Value__c = ((parseFloat(newVal) - parseFloat(this.annualGrossPreviousYearValue)) / parseFloat(this.annualGrossPreviousYearValue) * 100).toFixed(2);                            
                        }
                        if(obj.item.Rating_Modifier_Value__c){
                            if(obj.item.Rating_Modifier_Value__c > 0){
                                obj.item.Rating_Modifier_Value__c = '+'+obj.item.Rating_Modifier_Value__c+'%';
                            }else{
                                obj.item.Rating_Modifier_Value__c += '%';
                            }  
                        }                        
                    }
                });
            });
            this.mainSectionWraps.mainSections = mainSectionWrs;
        }
    }
    @track didFieldValuesChange = false;
    handleChangeMain(event) {

        var valueChange = event.target.value;
        //console.log("@@@valueChange: " + valueChange);
        var mainSectionWrs = JSON.parse(JSON.stringify(this.mainSectionWraps.mainSections));
        //console.log("@@@mainSectionWr: " + JSON.stringify(mainSectionWr));

        var mainSectionSave = [];
        mainSectionWrs.forEach(mainSecWrap => {
            //console.log("@@@mainSecWrap.items: " + mainSecWrap.items);
            mainSecWrap.items.forEach(obj => {
                //console.log("@@@obj.item.Id: " + obj.item.Id);
                if (obj.item.Id === event.target.name) {
                    console.log("@@@is update");
                    obj.item.Rating_Modifier_Value__c = event.target.value;
                    console.log("@@@rating value: " + obj.item.Rating_Modifier_Value__c);
                    console.log("rating mod name -->"+ obj.item.Name);
                    this.ratingModValuesChnged.push(obj.item.Name);
                    if (this.isProductAQPI) {
                        if (obj.item.Name == 'Annual gross fees / turnover') {
                            this.annualGrossFee = event.target.value;
                            console.log('Inside for each Annual gross fees / turnover', event.target.value);
                            if (this.mainProfession != 'Design & Construct') {
                                console.log('Inside the rateable xp');
                                mainSectionSave = this.handleRateableExpChange(event.target.value, mainSectionWrs);
                                console.log("@@@ mainProfession != 'Design & Construct': " + JSON.stringify(mainSectionWrs));
                            }
                            if (this.mainProfession != 'Design & Construct' && (this.rateablePreviousYear || this.annualGrossPreviousYear)) {
                                this.handleChangeForPriorValues(event.target.value, mainSectionWrs);
                            } else if (this.mainProfession == 'Design & Construct' && (this.annualGrossPreviousYear)) {
                                this.handleChangeForPriorValuesForDnC(event.target.value, mainSectionWrs);
                            }                            
                        }
                        if (obj.item.Name == 'Is the Proposal Form a full Proposal?') {
                            if (event.target.value == 'Yes') {
                                this.proposalFormFullProposal = true;
                                mainSectionSave = this.changeProposalFormDate(null, mainSectionWrs);
                            } else {
                                this.proposalFormFullProposal = false;
                                if(!this.lastFullProposalFormFilePreviousValue){
                                    mainSectionWrs.forEach(mainSecWrap => {
                                        console.log("@@@mainSecWrap.items: " + mainSecWrap.items);
                                        mainSecWrap.items.forEach(obj => {
                                            if (obj.item.Name == 'Date of Last Full Proposal Form on file') {                                                
                                                console.log("@@@ changeProposalFormDate NULL IF--");
                                                obj.item.Rating_Modifier_Value__c = null;
                                            }
                                        });
                                    });
                                }else{
                                    mainSectionSave = this.changeProposalFormDate(this.lastFullProposalFormFilePreviousValue, mainSectionWrs); 
                                }
                                console.log('this.lastFullProposalFormFilePreviousValue -- >',this.lastFullProposalFormFilePreviousValue);                     
                            }
                            //this.proposalFormFullProposal = event.target.value;
                            console.log('this.proposalFormFullProposal??? -- ', this.proposalFormFullProposal);
                            //if (!event.target.value) this.proposalFormFullProposal = false;
                        }
                        if (obj.item.Name == 'Proposal Form Date' && this.proposalFormFullProposal) {
                            console.log('in date chnge');
                            console.log('event.target.value for date'+ event.target.value);
                            mainSectionSave = this.changeProposalFormDate(event.target.value, mainSectionWrs);
                        }
                    }

                }
            });
        });
        this.didFieldValuesChange = true;
        if (typeof mainSectionSave != "undefined" && mainSectionSave != null && mainSectionSave.length != null && mainSectionSave.length > 0) mainSectionWrs = mainSectionSave;
        this.mainSectionWraps.mainSections = mainSectionWrs;
        this.mainSectionWraps.mainSections.forEach(mainSecWrap => {
            mainSecWrap.items.forEach(obj => {
                console.log("@@@obj: " + JSON.stringify(obj.item.Rating_Modifier_Value__c));
            });

        });

    }

    handleBlur(event) {
        //var objCompare = 'Number of years Prior Acts coverage';
        if (event.target.value < 0) {
            event.target.value = 0;
            event.target.focus();
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Warning',
                    message: 'Value  is invalid. This field does not allow the negative values.',
                    variant: 'warning',
                }),
            )

        }
    }

    handleChangeChild(event) {
        var valueChange = event.target.value;
        console.log("@@@valueChange: " + valueChange);
        var mainSectionWr = JSON.parse(JSON.stringify(this.mainSectionWraps));
        console.log("@@@mainSectionWr: " + JSON.stringify(mainSectionWr));

        mainSectionWr.mainSections.forEach(mainSecWrap => {
            console.log("@@@mainSecWrap.items: " + mainSecWrap.items);
            mainSecWrap.subSections.forEach(subSec => {
                subSec.items.forEach(obj => {
                    console.log("@@@obj.item.Id: " + obj.item.Id);
                    console.log("@@@Factor_Min: " + obj.item.Factor_Min__c);
                    if (obj.item.Id === event.target.name) {
                        obj.item.Rating_Modifier_Value__c = event.target.value;
                    }
                })
            });
        });
        this.mainSectionWraps = mainSectionWr;
        this.didFieldValuesChange = true;
    }

    @api validateWorkType() {
        const saveSuccess = this.template.querySelector("c-work-type-analysis-section");
        var isOkayToSave = true;
        if (saveSuccess) {
            var response = saveSuccess.validateToSave();
            if (!response) {
                isOkayToSave = false;
                return isOkayToSave;
            } else {
                return isOkayToSave;
            }
        }
    }

    @api saveWorkType() {
        const saveSuccess = this.template.querySelector("c-work-type-analysis-section");
        var isSaveDone = true;
        if (saveSuccess) {
            var response = saveSuccess.handleSaveTableDataFromParent();
            if (!response) {
                isSaveDone = false;
                return isSaveDone;
            } else {
                return isSaveDone;
            }
        }
    }

    handleValidateDate() {
        var proposalDate;
        var lastProposalDate;
        var doSave;
        var errorMsg = '';
        var mainSectionWrs = JSON.parse(JSON.stringify(this.mainSectionWraps.mainSections));
        mainSectionWrs.forEach(mainSecWrap => {
            mainSecWrap.items.forEach(obj => {
                if (obj.item.Name == 'Proposal Form Date') {
                    proposalDate = obj.item.Rating_Modifier_Value__c;
                    console.log("@@@ proposalDate: " + obj.item.Rating_Modifier_Value__c);
                } else if (obj.item.Name == 'Date of Last Full Proposal Form on file') {
                    lastProposalDate = obj.item.Rating_Modifier_Value__c;
                    console.log("@@@ lastProposalDate: " + obj.item.Rating_Modifier_Value__c);
                }
            });
        });

        let todaysDate = new Date().toISOString().slice(0, 10);        
        if(proposalDate > todaysDate){            
            doSave = true;
            errorMsg = 'Proposal Form Date cannot be a future date';
        }else{
            if (proposalDate != undefined && lastProposalDate != undefined && proposalDate != null && lastProposalDate != null) {
                if (proposalDate != lastProposalDate) {
                    doSave = true;
                    errorMsg = 'Proposal Form Date & Date of Last Full Proposal Form on file need to be same';
                } else {
                    doSave = false;
                }
            }
        }

        var returnObj = {
            doSave: doSave,
            errorMsg: errorMsg
        }

        return returnObj;
    }

    handleEventToAllowSaveWorkType(event){
        var value = event.detail;
        console.log({value});
        if(value){
            this.didFieldValuesChange = value;
        }
    }

    @api
    saveRecord() {
        var mainSectionWr = this.mainSectionWraps;
        console.log('Outbound DATA mainSectionWr ', JSON.stringify(mainSectionWr));
        //Check isReady to Save
        var isReadyToSave = true;
        
            var tmp = this.validateRequiredField();
            if (!tmp) isReadyToSave = false;
            var validateDate = false;
            if (this.isProductAQPI && isReadyToSave) {
                var isValidateOk = this.validateWorkType();
                if (!isValidateOk) {
                    var isReadyToSave = false;
                    this.isOpenModal = false;
                    return;
                }
                if (this.proposalFormFullProposal) {
                    var validateDate = this.handleValidateDate();
                    console.log({validateDate});
                    if (validateDate.doSave) isReadyToSave = false;
                    if (validateDate.doSave) {
                        this.isOpenModal = false;
                        this.showToast('Error', validateDate.errorMsg, "error");
                        return;
                    }
                }
                const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
                    .reduce((validSoFar, inputField) => {
                        inputField.reportValidity();
                        console.log({ validSoFar, inputField });
                        return validSoFar && inputField.checkValidity();
                    }, true);
                if (!isInputsCorrect) {
                    this.isOpenModal = false;
                    this.showToast('Error', 'Please fill the fields correctly', "error");                
                    return;
                }
            }
            let item;
            let checkRatVal = true;
            console.log('this.ratingModValuesChnged -->'+this.ratingModValuesChnged);
            for(item = 0; item < this.ratingModValuesChnged.length; item++){
                console.log('no of loop'+this.ratingModValuesChnged[item]);
                if(this.ratingModValuesChnged[item] !='Proposal Form Date' && 
                this.ratingModValuesChnged[item] !='Is the Proposal Form a full Proposal?' && 
                this.ratingModValuesChnged[item] !='Date of Last Full Proposal Form on file' && 
                this.ratingModValuesChnged[item] !='Professional Business Description'){
                    console.log('inside If');
                    checkRatVal = false;
                    break;
                }
            }
            console.log('checkRatVal -->'+checkRatVal);
            if(this.didFieldValuesChange){
            if (isReadyToSave) {
                updateExistingReferredQuotes({ recordId: this.opportunityId })
                .then(result => {
                    console.log("Success");
                    if (this.isProductAQPI) {
                        var saveOk = this.saveWorkType();
                        console.log({ saveOk });
                        //if(!saveOk){
                        //    return;
                        //}                
                    }
                    console.log('saveRecordTabLwc: '+JSON.stringify(mainSectionWr.mainSections));
                    saveRecordTabLwc({
                        jsonTabWrap: JSON.stringify(mainSectionWr.mainSections),
                        opportunityId: this.opportunityId,
                        checkRatVal: checkRatVal
                    })
                        .then(() => {
                            this.showToast("Success", "Update records successfully!", "success");
                            this.didFieldValuesChange = false;
                            this.getMainSections();
                            //return refreshApex(this.opptiesOverAmount);
                        })
                        .catch((error) => {
                            var message = error.body.message.includes('ENTITY_IS_LOCKED') ? ERROR_CANNOT_UPDATE_SUBMISSION_HAS_LOCKED_QUOTE : ('Error received: code' + error.errorCode + ', ' +
                                'message ' + error.body.message);
                            console.log('@@@error 1: ' + JSON.stringify(error.body.message));
                            this.showToast("Error", message, "error");
                        });
                })
                .catch((error) => {
                    var message = '';
                    if (error.body.message.includes('ENTITY_IS_LOCKED')) {
                        message = ERROR_CANNOT_UPDATE_SUBMISSION_HAS_LOCKED_QUOTE;
                    }
                    this.showToast('Error', message, "error");
                });
            } else {
                this.isOpenModal = false;
                if (!this.isProductAQPI) {
                    if (!tmp) this.showToast('Error', 'Please complete required field!', "error");
                } else {
                    this.showToast('Error', 'Please complete required field!', "error");
                }
            }           
        }
        return isReadyToSave;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    clickCheckRiskHealth() {
        console.log("@@@open modal");
        this.isOpenModal = !this.isOpenModal;
    }

    closeModal() {
        this.isOpenModal = !this.isOpenModal;
    }

    get isProductCyber() {
        return this.productName === 'Cyber';
    }

    //---------------------------------------

    validateRequiredField() {
        var result = true;
        if(this.disableSaveButton == true) return true;// For US 49436
        this.template.querySelectorAll('.required-field').forEach(element => {
            console.log("@@@element value: " + JSON.stringify(element.value));
            var value = element.value;
            console.log('valueeee ' + value);
            if (!value || value == undefined) {
                element.setCustomValidity("Please Enter a valid Value");
                console.log('valueeeevvvv ' + value);
                result = false;
            }
            else {
                element.setCustomValidity("");
            }
            element.reportValidity();
        });
        return result;
    }

    changeQuoteProcessStatus(event) {
        this.dispatchEvent(new CustomEvent('changequoteprocessstatus'));
    }
    handleSendQuoteLayer(event) {

        const sendquotelayer = new CustomEvent(
            "sendquotelayer", {
            detail: event.detail,
        });
        this.dispatchEvent(sendquotelayer);
    }

    handleValidateProceedToQuote(event) {
        var isSaved = this.saveRecord();
        var quoteLayer = event.detail;
        console.log({isSaved});
        console.log('this.isProductAQPI::'+this.isProductAQPI);
        if(isSaved && this.isProductAQPI == false){
            this.template.querySelector("c-check-risk-health-lwc").proceedToQuoteAfterValidation(quoteLayer);
        }
        if(isSaved && this.isProductAQPI){
            this.template.querySelector("c-check-risk-health-lwc-a-q").proceedToQuoteAfterValidation(quoteLayer);
        }
        // var quoteLayer = event.detail;
        // var isReadyToSave = true;
        // var tmp = this.validateRequiredField();
        // if (!tmp) isReadyToSave = false;
        // var validateDate = false;
        // if (this.isProductAQPI && isReadyToSave) {
        //     var isValidateOk = this.validateWorkType();
        //     if (!isValidateOk) {
        //         var isReadyToSave = false;
        //         this.isOpenModal = !this.isOpenModal;
        //         return;
        //     }
        //     if (this.proposalFormFullProposal) {
        //         var validateDate = this.handleValidateDate();
        //         if (validateDate) isReadyToSave = false;
        //         if (validateDate) {
        //             this.showToast('Error', 'Proposal Form Date & Date of Last Full Proposal Form on file need to be same', "error");
        //             this.isOpenModal = !this.isOpenModal;
        //             return;
        //         }
        //     }
        //     const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
        //         .reduce((validSoFar, inputField) => {
        //             inputField.reportValidity();
        //             console.log({ validSoFar, inputField });
        //             return validSoFar && inputField.checkValidity();
        //         }, true);
        //     if (!isInputsCorrect) {
        //         this.showToast('Error', 'Please fill the fields correctly', "error");
        //         this.isOpenModal = !this.isOpenModal;
        //         return;
        //     }
        // }

        // if (isReadyToSave) {
        //     this.template.querySelector("c-check-risk-health-lwc").proceedToQuoteAfterValidation(quoteLayer);
        // } else {
        //     this.isOpenModal = !this.isOpenModal;
        //     if (!this.isProductAQPI) {
        //         if (!tmp) this.showToast('Error', 'Please complete required field!', "error");
        //     } else {
        //         this.showToast('Error', 'Please complete required field!', "error");
        //     }
        // }
    }

    handlePreviousScreen() {
        var status = QUOTE_PROCESS_STATUS_SUBMISSION_INFO;
        var infos = { status: status };
        const event = new CustomEvent('quoteprocessstatuschange', {
            detail: infos
        });
        this.dispatchEvent(event);
    }
}