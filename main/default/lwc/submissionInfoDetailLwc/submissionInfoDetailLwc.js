import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { updateRecord } from 'lightning/uiRecordApi';
import getListSectionSetting from '@salesforce/apex/SubmissionInfoDetailLWCCtrl.getListSectionSetting'; 
import getOpp from '@salesforce/apex/SubmissionInfoDetailLWCCtrl.getOpp'; 
export default class SubmissionInfoDetailLwc extends LightningElement {
    @api oppId;
    @track sectionList;
    @track mainActiveSections;
    @track isEditForm = false;
    @track error;
    @track specialFieldMap = {};
    @track opp;

    connectedCallback(){
        getListSectionSetting({})
        .then((result) => {
            //console.log('@@@data: ' + JSON.stringify(result));
            this.sectionList = result.sections;
            this.mainActiveSections = result.activeSections;
            var fieldList = [];
            this.sectionList.forEach(section => {
                section.mainSectionFields.forEach(field => {
                    fieldList.push(field.sourceFieldApi);
                });
            });
            this.getOpportunity(fieldList);
        })
        .catch((error) => {
            console.log('@@@error: ' + JSON.stringify(error));
        }) 
    }

    getOpportunity(fieldList){
        getOpp({
            oppId : this.oppId,
            fieldList : JSON.stringify(fieldList)
        })
        .then((result) => {
            console.log("@@@result opp: " + JSON.stringify(result) );
            var fieldValueMap = result;
            this.sectionList.forEach(section => {
                section.mainSectionFields.forEach(field => {
                    field.value = fieldValueMap[field.sourceFieldApi];
                });
            });
        })
        .catch((error) => {
            console.log('@@@error 2: ' + JSON.stringify(error));
        })
    }

    handleEditClick(){
        this.isEditForm = !this.isEditForm;
    }

    handleSave(){
        const fields = {};
        this.sectionList.forEach(section => {
            section.mainSectionFields.forEach(field => {
                fields[field.sourceFieldApi] = field.value;
            });
        });
        this.template
            .querySelectorAll("c-generate-element-lwc")
            .forEach(element => {
                var tmp = element.getValuesOnForm();
                if(tmp != null) {
                    fields[tmp.key] = tmp.value;
                }             
            });
        fields['Id'] = this.oppId;
        console.log("@@@handle save: " + JSON.stringify(fields));
        const recordInput = { fields };
        updateRecord(recordInput)
        .then(account => {
            this.isEditForm = !this.isEditForm;
            this.showToast('Success', 'Update records successfully!', "success");
        })
        .catch(error => {
            console.log("@@@error: " + JSON.stringify(error));
            this.showToast('Error', 'Update fail!', "error");
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

    handleLookUpChildSelection(event) {
        this.sectionList.forEach(section => {
            section.mainSectionFields.forEach(field => {
                if(field.sourceFieldApi === event.detail.fieldNameAPI)
                field.value = event.detail.selectedId;
            });
        });
    }
}