import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
export default class ContactInitFormLwc extends NavigationMixin(LightningElement) {
    @api accountId;
    @api recordTypeId;
    @api recordTypeName;
    
    handleClose(){
        const closeQA = new CustomEvent("close");
        // Dispatches the event.
        this.dispatchEvent(closeQA);
    }
    handleSuccess(event){
        var contactId = event.detail.id;
        console.log("@@@contactId: " + contactId);
        this.showToast();
        this.handleClose();
        this.handleNavigateToRecord(contactId);
    }
    handleNavigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
          type: "standard__recordPage",
          attributes: {
            recordId: recordId,
            objectApiName: "Contact",
            actionName: "view"
          }
        });
    }
    showToast() {
        const event = new ShowToastEvent({
          title: "Success",
          message: "New Contact is created in success!",
          variant: "success"
        });
        this.dispatchEvent(event);
    }
}