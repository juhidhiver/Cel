import { LightningElement, track, api, wire } from 'lwc';
import getRecordTypePicklist from '@salesforce/apex/ContactNewFormLwcController.getRecordTypePicklist';
export default class ContactNewFormLwc extends LightningElement {
    @api accountId;
    @track recordTypePl;
    @track recordTypeId;
    @track recordTypeName;
    @track openNext = false;

    @wire (getRecordTypePicklist)
    wiredRecordType({ error, data }) {
        if (data) {
            console.log('@@@data: ' + JSON.stringify(data));
            this.recordTypePl = data;
            this.error = undefined;
        } else if (error) {
            console.log('@@@error: ' + JSON.stringify(error));
            this.error = error;
            this.recordTypePl = undefined;
        }
    }

    handleRecordTypeChange(event){
        this.recordTypeId = event.detail.value;
        this.recordTypePl.forEach(recType => {
            if(recType.value === event.detail.value){
                this.recordTypeName = recType.label;
            }
        });
        
    }

    handleClose(){
        console.log("Close");
        const closeQA = new CustomEvent("close");
        // Dispatches the event.
        this.dispatchEvent(closeQA);
    }
    handleNext(){
        console.log("Close");
        //const closeQA = new CustomEvent("close");
        // Dispatches the event.
        //this.dispatchEvent(closeQA);
        this.openNext = true;
    }
}