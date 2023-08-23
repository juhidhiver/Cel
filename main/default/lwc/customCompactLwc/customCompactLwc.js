import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

import { updateRecord } from 'lightning/uiRecordApi';
import getDefaultRecordType from "@salesforce/apex/CustomCompactLwcController.getDefaultRecordType";
import getCompactLayoutFields from '@salesforce/apex/CustomCompactLwcController.getCompactLayoutFields';
import getCompactTitle from '@salesforce/apex/CustomCompactLwcController.getCompactTitle';
import getCompactObjectName from '@salesforce/apex/CustomCompactLwcController.getCompactObjectName';
import getOpportunityRecordType from '@salesforce/apex/CustomCompactLwcController.getOpportunityRecordType';
import getStageNameSubmission from '@salesforce/apex/SubmissionInfoLwcController.getStageNameSubmission';
import cloneOpportunity from '@salesforce/apex/CloneOpportunityController.cloneOpportunity';
import unDeclineUpdateSubmission from '@salesforce/apex/SubmissionInfoLwcController.unDeclineUpdateSubmission';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';

export default class CustomCompactLwc extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectId;
    @api isShowLossDetail;
    @api isShowAdditionalInsured;
    @track opp;
    @track fieldTop;
    @track fieldListBelow = [];
    @track errors;
    @track compactTitle;
    @track obj;
    @track notSubmissionPage = true;
    @track opportunityRecordType;
    @track rctId;
    @track oppStage;
    // @api objectId = "0011k00000bsJ9oAAE";
    @api disabledDecline = false;
    @api disabledClose = false;

    @track rctName;
    @track isCelerity;
    @api isAqueous;
    @wire(getDefaultRecordType, { quoteProcessId: "$recordId" })
    wireRctAcc({ error, data }) {
      if (data) {
          console.log("RecordType:" + JSON.stringify(data));
          this.rctName = data;
          if(this.rctName == 'Celerity'){
              this.isCelerity = true;
          }
          if(this.rctName == 'Aqueous'){
            this.isAqueous = true;
          }
      } else {
        console.log("getRecordType error:" + JSON.stringify(error));
      }
    }


    connectedCallback() {
        console.log("qp--" + this.recordId);
        console.log("@@@connectedCallback1" + this.objectId);
        console.log("@@@isShowLossDetail" + this.isShowLossDetail);
        this.checkIsSubmissionPage();

        getCompactObjectName({ objectId: this.objectId })
            .then((result) => {
                this.obj = result;
                    if (this.obj == 'Opportunity') {
                        this.getStageNameSubmission();
                        getOpportunityRecordType({ opportunityId: this.objectId })
                            .then(result => {
                                this.opportunityRecordType = result.split('__')[1];
                                console.log("this.opportunityRecordType-->",this.opportunityRecordType);
                                if(this.isShowAdditionalInsured && this.opportunityRecordType=='Aqueous'){
                                    this.isShowAdditionalInsured = true;
                                }else{
                                    this.isShowAdditionalInsured = false;
                                }
                                this.rctId = result.split('__')[0]
                                
                            })
                            .catch(error => {
                                console.log('@@@error getOpportunityRecordType: ' + JSON.stringify(error));
                            })
                    }
            })  
            .catch((error) => {
                console.log('@@@error getCompactObjectName: ' + JSON.stringify(error));
            })

            this.getCompactTitle();         

    }

    @api getCompactTitle(){
       // this.fieldListBelow = [];
        var arr = [];
        getCompactTitle({ objectId: this.objectId })
        .then((result) => {
            this.compactTitle = result;
            getCompactLayoutFields({ objectId: this.objectId })
            .then((result) => {
                console.log('@@@this.objectId: ' + this.objectId);
                if (result.isSuccess) {
                    console.log('@@@data: ' + JSON.stringify(result.data));
                    this.opp = result.data;
                    const listField = [];
                    if (result.data.length > 0) {
                        this.fieldTop = result.data[0].fieldValue;
                        console.log('this.isCelerity' +this.isCelerity);
                        console.log('this.isAQ' +this.isAqueous);
                        for (let index = 1; index < result.data.length; index++) {
                            if(this.isCelerity){
                                if(result.data[index].fieldNameAPI !== "Sanctions_Check__c"){
                                    arr.push(result.data[index]);
                                }
                            }
                            else if(this.isAqueous){
                                if(result.data[index].fieldNameAPI !== "Sanctions_Check_CEL__c"){
                                    arr.push(result.data[index]);
                                }
                            }
                            else{
                          //  this.fieldListBelow.push(result.data[index]);
                          arr.push(result.data[index]); 
                            }
                        }
                        this.fieldListBelow  = undefined;
                        console.log('this.fieldListBelow' +this.fieldListBelow);
                        this.fieldListBelow = JSON.parse(JSON.stringify(arr)); 
                    }

                } else {
                    console.log('@@@error result.getCompactLayoutFields: ' + JSON.stringify(result.errors));
                }
            })
            .catch((error) => {
                console.log('@@@error getCompactLayoutFields: ' + JSON.stringify(error));
                //this.error = error;
            })
        })
        .catch((error) => {
            console.log('@@@error getCompactTitle: ' + JSON.stringify(error));
            //this.error = error;
        })
    }


    checkIsSubmissionPage() {
        let url = window.location.href;
        let newUrl = new URL(url).pathname.split('/');
        this.notSubmissionPage = newUrl[3] !== 'Opportunity';
    }
    clickLossDetail(event){
        const objAPIName = this.compactTitle.split(' ')[0];
        this.dispatchEvent(new CustomEvent('lossdetail', {
            detail: {
                objectName: objAPIName
            }
        }));
    }
    clickAdditionalInsuredDetail(){
        const objAPIName = this.compactTitle.split(' ')[0];
        this.dispatchEvent(new CustomEvent('additionalinsured', {
            detail: {
                objectName: objAPIName
            }
        }));
    }
    clickAddFile(event){
        const objAPIName = this.compactTitle.split(' ')[0];
        this.dispatchEvent(new CustomEvent('notesandfiles', {
            detail: {
                objectName: objAPIName
            }
        }));
    }
    get showDeclineCloseButton(){
        return this.compactTitle == 'OPPORTUNITY INFO' && this.opportunityRecordType == 'Aqueous'? true : false ;
    }
    handleClick(event){
        let action = event.target.name;
        console.log('Action -->'+action);
        switch (action) {
            case 'decline':
                this.dispatchEvent(new CustomEvent('decline',{detail: {actionType: 'decline', oppRecordId: this.rctId}}));
                break;
            default:
                this.dispatchEvent(new CustomEvent('close',{detail: {actionType: 'close', oppRecordId: this.rctId}}));
                break;
        }
    }
    @track isShowUndeclined = false;
    @track disabledCopy = false;
    @track quoteType;
    @api getStageNameSubmission(){
        getStageNameSubmission({submissionId : this.objectId})
            .then(result => {
                var splitStr = result.split('-');
                this.oppStage = splitStr[0];
                this.quoteType = splitStr[1];
                console.log('Opp Stage: '+this.oppStage +'& QuoteType: '+this.quoteType);
                if(this.oppStage == 'Closed Won' || this.oppStage == 'Closed Lost' || this.oppStage == 'Declined'){
                    this.disabledClose = true;
                    this.disabledDecline = true;
                }
                if(this.oppStage == 'Closed Lost' || this.oppStage == 'Declined'){
                    this.disabledCopy = true;
                }
                if(this.oppStage == 'Declined'){
                    this.isShowUndeclined = true;
                }
                if(this.oppStage == 'Qualified'){
                    if(this.quoteType == 'Full Amendment'){
                        this.disabledDecline = true;
                    }
                }
            })
            .catch(error =>
                console.log('Error-->'+JSON.stringify(error))
            ) 
    } 
@track isCloneSubmission = false;
@track isClone =false;
    handleClickCopy(){
        console.log('object: '+this.objectId);
        this.isClone = true;
        this.isCloneSubmission = true;
        cloneOpportunity({ oppId: this.objectId })//oppId
            .then((result) => {
                this.isCloneSubmission = false;
                console.log('clone return:' + JSON.stringify(result));
                if(result.isSuccess){
                    this[NavigationMixin.GenerateUrl]({
                        type: "standard__recordPage",
                        attributes: {
                            recordId: result.oppClonedId,
                            objectApiName: 'Opportunity',
                            actionName: 'view'
                        }
                    }).then(url => {
                        window.open(url, "_blank");
                    });
                    this.showToast('Success', 'Submission Cloned Successfully!', 'success');
                }else{
                    this.showToast('Error', result.msgError, 'error');
                }
            })
            .catch((error) => {
                console.log('@@@error: ' + JSON.stringify(error));
                this.showToast('Error', JSON.stringify(error), 'error');
                this.isCloneSubmission = false;
            })
    }

    handleUnDecline(){
        this.isClone = false;
        this.isCloneSubmission = true;
        console.log('oppRecordId-->'+this.objectId);
        this.dispatchEvent(new CustomEvent('undecline',{detail: {oppRecordId: this.objectId}}));
    }

    @api handleAfterUnDecline(){
        this.isCloneSubmission = false;
        this.isShowUndeclined = false;
        this.disabledClose = false;
        this.disabledDecline = false;
        this.disabledCopy = false;
        this.getStageNameSubmission();
        this.showToast('Success', 'Submission Un Declined Successfully!', 'success');
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}