import { LightningElement, api, wire, track } from 'lwc';
import { getRecord,updateRecord,createRecord} from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import getRecordEndorsement from '@salesforce/apex/EndorsementProcessLwcController.getRecordEndorsement';
//import getSingleEndorsementProcess from '@salesforce/apex/EndorsementProcessLwcController.getSingleEndorsementProcess';

const ENDORSEMENT_PROCESS_STATUS_POLICY = 'Policy';
const ENDORSEMENT_PROCESS_STATUS_MANAGE_ENDORSEMENTS = 'Manage Endorsements';
const ENDORSEMENT_PROCESS_STATUS_QUOTE_AND_CHANGESUMMARY = 'Quote and Change Summary';
const ENDORSEMENT_PROCESS_STATUS_ENDORSEMENT_DOCUMENTS = 'Endorsement Documents';

export default class EndorsementProcessLwc extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api validRecordId;

    @track endorsement_process;
    @track endorsementProcessStatus;

    @track isPolicyStatus;
    @track isManageEndorsementsStatus;
	@track isQuoteAndChangeSummaryStatus;
    @track isEndorsementDocumentsStatus;

    /*@wire(getSingleEndorsementProcess)
    endorsementProcess;

    connectedCallback() {
    }
    @wire(getRecordEndorsement, { recordId: '$recordId'})
    wiredRecord({ error, data }) {
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading',
                    message,
                    variant: 'error',
                }),
            );
        } else if (data) {
            this.endorsementProcessStatus = data.Status__c;
            this.validRecordId = data.Id;
			console.log('validRecordId:', this.validRecordId);
            
            switch (this.endorsementProcessStatus) {
				case ENDORSEMENT_PROCESS_STATUS_POLICY:
					this.isPolicyStatus = true;
					break;
				case ENDORSEMENT_PROCESS_STATUS_MANAGE_ENDORSEMENTS:
					this.isManageEndorsementsStatus = true;
					break;
				case ENDORSEMENT_PROCESS_STATUS_QUOTE_AND_CHANGESUMMARY:
					this.isQuoteAndChangeSummaryStatus = true;
					break;
				case ENDORSEMENT_PROCESS_STATUS_ENDORSEMENT_DOCUMENTS:
					this.isEndorsementDocumentsStatus = true;
					break;
				default:
					break;
			 }		 
        }
    }
	*/
    handleChangeRefresh(event) {
        var currentStatus = event.detail.currentStatus;
		switch (currentStatus) {
				case ENDORSEMENT_PROCESS_STATUS_POLICY:
					this.isPolicyStatus = true;
					this.isManageEndorsementsStatus = false;
					this.isQuoteAndChangeSummaryStatus = false;
					this.isEndorsementDocumentsStatus = false;
					break;
				case ENDORSEMENT_PROCESS_STATUS_MANAGE_ENDORSEMENTS:
					this.isPolicyStatus = false;
					this.isManageEndorsementsStatus = true;
					this.isQuoteAndChangeSummaryStatus = false;
					this.isEndorsementDocumentsStatus = false;
					break;
				case ENDORSEMENT_PROCESS_STATUS_QUOTE_AND_CHANGESUMMARY:
					this.isPolicyStatus = false;
					this.isManageEndorsementsStatus = false;
					this.isQuoteAndChangeSummaryStatus = true;
					this.isEndorsementDocumentsStatus = false;
					break;
				case ENDORSEMENT_PROCESS_STATUS_ENDORSEMENT_DOCUMENTS:
					this.isPolicyStatus = false;
					this.isManageEndorsementsStatus = false;
					this.isQuoteAndChangeSummaryStatus = false;
					this.isEndorsementDocumentsStatus = true;
					break;
				default:
					break;
		}
        console.log('refresh Endorsement Status:' + currentStatus);

    }
}