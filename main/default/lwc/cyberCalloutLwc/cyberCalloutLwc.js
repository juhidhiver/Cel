import { api, LightningElement, track, wire } from "lwc";
import cyberIntelRequest from "@salesforce/apex/CyberIntelCallout.cyberIntelRequest";
import getOppId from "@salesforce/apex/CyberIntelCallout.getOppId";
import { updateRecord } from 'lightning/uiRecordApi';
import SERVICE_TO_RUN_FIELD from '@salesforce/schema/Opportunity.Service_to_Run__c';
import ID_FIELD from '@salesforce/schema/Opportunity.Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { fireEvent} from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
export default class CyberCalloutLwc extends LightningElement {
    @track openmodel = true;
    @api oppId;
    @api serviceToRun;
    @track saving = false;
    @track showMPLError = false;
    @track showToast = false;
    @wire(CurrentPageReference) pageRef;
    get options() {
        return [
            { label: 'None', value: 'None' },
            { label: 'Bit Sight', value: 'Bit Sight' }
        ];
    }
    handleCallout() {
        this.saving = true;
        console.log("Opportunity ID -->" + this.oppId);
        const fields = {};
        fields[SERVICE_TO_RUN_FIELD.fieldApiName] = this.serviceToRun;
        fields[ID_FIELD.fieldApiName] = this.oppId;
        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => {
                console.log('valuess -->');
                this.cyberIntelRequest(this.oppId);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Updating Service to Run values',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }
    cyberIntelRequest(oppId) {
        let opportunityId = oppId;
        console.log("cyberIntelRequest");
        cyberIntelRequest({ submissionId: opportunityId })
            .then((result) => {
                console.log("result :", JSON.stringify(result));
                this.saving = false;
                this.openmodel = false;
                this.handleClose();
                fireEvent(this.pageRef, 'refreshUnderwritterAnalysisTab',true);
            })
            .catch((error) => {
                console.log("error:", JSON.stringify(error));
                this.saving = false;
                this.openmodel = false;

            });
    }
    handleClose() {
        const showToast = this.showToast;
        const closeQA = new CustomEvent("close" , {detail: {showToast}});
        this.dispatchEvent(closeQA);
        console.log("Hello from LWC");
    }
    connectedCallback() {
        setTimeout(() => {
            console.log('Opp Id -->' + this.oppId);
            this.getOppId();
        }, 100);

    }
    getOppId() {
        getOppId({ sobjectId: this.oppId })
            .then(result => {
                console.log('result -->' + JSON.stringify(result));
                if(result.Product_Name__c == 'Cyber Standalone' && result.StageName != 'Declined'){
                    this.serviceToRun = result.Service_to_Run__c;
                    this.oppId = result.Id;
                }
                else{
                    this.openmodel = false;
                    this.showToast = true;
                    this.handleClose()
                }
            })
            .catch(error => {
                console.log('Error -->' + error);
            })
    }
    handleChange() {
        this.serviceToRun = this.template.querySelector('lightning-combobox').value;
        console.log('Service to run -- >' + this.serviceToRun);
    }

}