import {LightningElement, api,wire,track} from 'lwc';

export default class SubmissionInformationLWC extends LightningElement {
    @api recordId = '';
    @track value = '';
    get options() {
        return [
            { label: 'Primary', value: 'option1' },
            { label: 'Excess', value: 'option2' },
        ];
    }
    handleChangeSomething(event){
        console.log('Input Something');
        console.log(event.target.value);
        console.log(JSON.stringify(this.fieldswrapper));
    }
}