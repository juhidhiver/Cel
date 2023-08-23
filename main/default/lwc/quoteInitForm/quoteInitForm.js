import { LightningElement, track, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getOpportunity from '@salesforce/apex/QuoteInitFormLWCController.getOpportunity';
import LANG from '@salesforce/i18n/dateTime';

export default class QuoteInitForm extends NavigationMixin(LightningElement) {
  @track quoteId = "";
  @track loaded = false;
  @track saving = false;
  @api recordId;
  @track oppObj;

  connectedCallback() {
    setTimeout(() => {
      this.handleLoad();
  }, 500);
    
  }

  handleLoad() {
    this.loaded = !this.loaded;
  }

  @wire(getOpportunity, {oppId : '$recordId' })
    wiredOpp({ error, data }) {
        if (data) {
            console.log('@@@data: ' + JSON.stringify(data));
            this.oppObj = data;
            this.error = undefined;
        } else if (error) {
            console.log('@@@error: ' + error);
            this.error = error;
            this.oppObj = undefined;
        }
    }
    get closeDate() {
        const today = new Date();
        const finalDate = new Date(today);
        finalDate.setDate(today.getDate() + 30);
        var options = {year: 'numeric', month: 'short', day: 'numeric' };
        var dateTimeFormat = new Intl.DateTimeFormat('en-US', options);
        var closeDate = dateTimeFormat.format(finalDate);
        console.log(closeDate.toString());
        return closeDate.toString();
    }
    get quoteType() {
      return this.oppObj.StageName == 'Closed Won'? 'Amendment' : 'New Bussiness';
    }
  handleClose() {
    const closeQA = new CustomEvent("close");
    // Dispatches the event.
    this.dispatchEvent(closeQA);
    console.log("Hello from LWC");
  }

  handleSuccess(event) {
    this.saving = true;
    console.log("Success");
    var quoteId = event.detail.id;
    
    setTimeout(() => {
      this.saving = false;
      this.showToast();
      this.handleClose();
      this.handleNavigateToRecord(quoteId);
    }, 500);
    
  }

  handleNavigateToRecord(quoteId) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: quoteId,
        objectApiName: "Quote",
        actionName: "view"
      }
    });
  }

  showToast() {
    const event = new ShowToastEvent({
      title: "Success",
      message: "New Quote is created in success!",
      variant: "success"
    });
    this.dispatchEvent(event);
  }
}