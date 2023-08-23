import { LightningElement,api,wire } from 'lwc';
import getProductNameTabsLwc from '@salesforce/apex/OpportunityModifiersCmpController.getProductNameTabsLwc';


export default class UnderwrittingAnalysisLwc extends LightningElement {

    @api quoteProcessSubmissionId;
    @api listTabs = [];

    @wire(getProductNameTabsLwc, {opportunityId : '$quoteProcessSubmissionId'})
	getMainSectionFromProduct({error, data}){
       if(data){
            this.listTabs = data;
            // console.log('Final result:' + JSON.stringify(this.listTabs));
       } else if(error){
		  console.log('##error :' + JSON.stringify(error));
       }
    }

    changeQuoteProcessStatus(event){
        this.dispatchEvent(new CustomEvent('changequoteprocessstatus'));
    }
    @api
    updateUnderwrittingTab(){
      var   isReadyToSave = false;  
        console.log('inside Compare and rate',JSON.stringify(this.template.querySelector("c-underwritting-analysis-tab-lwc"))); 
        if(this.template.querySelector("c-underwritting-analysis-tab-lwc")!= null){
            this.isReadyToSave = this.template.querySelector("c-underwritting-analysis-tab-lwc").saveRecord();
            }
            return this.isReadyToSave;
    }
    handleSendQuoteLayer(event){

        const sendquotelayer = new CustomEvent(
            "sendquotelayer", {
            detail: event.detail,
        });
        this.dispatchEvent(sendquotelayer);
    }
    handleQPStatusChange(event){
        this.dispatchEvent(new CustomEvent('quoteprocessstatuschange',{detail: event.detail}));
    }
}