import {LightningElement, api,wire} from 'lwc';
import doingSomething from '@salesforce/apex/RecordFormController.doingSomething';

export default class RecordFormCmp extends LightningElement {
    @api fields = [];
    @api objectname;
    @api recordid;
    @api sobject;
    @wire(doingSomething, { objectName: 'sobject', fields: '$fields'})
    fieldswrapper;

    handleChangeSomething(event){
        console.log('Input Something');
        console.log(event.target.value);
        console.log(JSON.stringify(this.fieldswrapper));
    }
    handlesm(event){
        console.log('Event Params ' + JSON.stringify(event));
    }

}