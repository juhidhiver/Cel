import { LightningElement,api,wire } from 'lwc';
import getProductNameTabsLwc from '@salesforce/apex/OpportunityModifiersCmpController.getProductNameTabsLwc';

export default class OpportunityModifiersLwc extends LightningElement {

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
}