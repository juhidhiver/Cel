import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CheckForCelerityPccProduct from '@salesforce/apex/CloneOpportunityController_Celerity.CheckForCelerityPccProduct';
import { NavigationMixin } from 'lightning/navigation';

export default class CopySubmissionQuickActionLwc extends NavigationMixin (LightningElement) {
    @api recordId;

    connectedCallback() {
        CheckForCelerityPccProduct({ oppId: this.recordId })
            .then(result => {
                if (result.isSuccess == true) {
                    this.closeEventAndShowMessage('Success', 'Submission copied successfully!', 'success');
                    this.navigateToRecordPage(result.oppClonedId);
                } else if (result.isSuccess == false && result.msgError != '') {
                    this.closeEventAndShowMessage('Error', result.msgError, 'error');
                } else {
                    this.closeEventAndShowMessage('Error', 'Error occurred while copying sumission.', 'error');
                }
            })
            .catch(error => {
                if (error) {
                    if (Array.isArray(error.body)) {
                        this.closeEventAndShowMessage('Error', error.body.map(e => e.message), 'error');
                    }
                    else if (error.body && typeof error.body.message === 'string') {
                        this.closeEventAndShowMessage('Error', error.body.message, 'error');
                    }
                    else if (typeof error.message === 'string') {
                        this.closeEventAndShowMessage('Error', error.message, 'error');
                    } else {
                        this.closeEventAndShowMessage('Error', 'Unknown Error Occurred', 'error');
                    }

                }
            });

    }

    navigateToRecordPage( newOppId ) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: newOppId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
    }

    closeEventAndShowMessage(title, message, variant) {
        // Close the modal window and display a success toast
        this.dispatchEvent(new CustomEvent('close'));
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }


}