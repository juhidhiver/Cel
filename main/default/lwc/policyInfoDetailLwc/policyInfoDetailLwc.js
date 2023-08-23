import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
//import getListSectionSetting from '@salesforce/apex/SubmissionInfoDetailLWCCtrl.getListSectionSetting';
import getListSectionSetting from '@salesforce/apex/PolicyInfoDetailsLwcCtrl.getListSectionSetting';
import getRecordInfos from '@salesforce/apex/PolicyInfoDetailsLwcCtrl.getRecordInfos';


export default class PolicyInfoDetailLwc extends LightningElement {
    @track sectionList;
    @track mainActiveSections;
    @track isEditForm = false;
    @track error;
    @track specialFieldMap = {};
    @track isComplete = false;
    @track policyId = '';
    @api endorsementProcessRecordId;


    connectedCallback(){
        console.log('RecordId111' + this.endorsementProcessRecordId);
        //get policy Id
        getRecordInfos({sObjectId : this.endorsementProcessRecordId 
        })
        .then((result) => {
            console.log('@@@data: ' + JSON.stringify(result));
            this.policyId = result;
            this.isComplete = true;
        })
        .catch((error) => {
            console.log('@@@error: ' + JSON.stringify(error));
        }) 
        //get section
        getListSectionSetting({
         
        })
        .then((result) => {
            console.log('@@@data: ' + JSON.stringify(result));
            this.sectionList = result.sections;
            this.mainActiveSections = result.activeSections;
        })
        .catch((error) => {
            console.log('@@@error: ' + JSON.stringify(error));
        }) 
    }
  

    handleEditClick(){
        this.isEditForm = !this.isEditForm;
    }

    handleChangeInputValue(event){
        var valueChange = event.target.value;
        this.sectionList.forEach(section => {
            section.mainSectionFields.forEach(field => {
                if(field.sourceFieldApi === event.target.name){
                    this.specialFieldMap[field.sourceFieldApi] = valueChange;
                }
            });
        });
    }
    
    handleSubmit(event) {
        console.log('onsubmit: '+ event.detail.fields);
        console.log('specialFieldMap: '+ JSON.stringify(this.specialFieldMap));
        event.preventDefault();       // stop the form from submitting
        const fields = event.detail.fields;
        //fields.Current_Assets__c = '32';
        this.sectionList.forEach(section => {
            section.mainSectionFields.forEach(field => {
                if (this.specialFieldMap.hasOwnProperty(field.sourceFieldApi)) {
                    fields[field.sourceFieldApi] = this.specialFieldMap[field.sourceFieldApi];
                }
            });
        });
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSuccess(event){
        console.log('Save success: ');
        const payload = event.detail;
        console.log(JSON.stringify(payload));
        this.isEditForm = !this.isEditForm;
        // //console.log('onsuccess: ', updatedRecord);
        this.showToast('Success', 'Update records successfully!', "success");
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
          title: title,
          message: message,
          variant: variant
        });
        this.dispatchEvent(event);
    }

    handleLookUpChildSelection(event) {
        console.log("@@@value Look up: " + JSON.stringify(event.detail));
    }
}