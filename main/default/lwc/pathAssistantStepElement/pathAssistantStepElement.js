import {LightningElement,api,track} from 'lwc';

export default class PathAssistantStepElement extends LightningElement {
    @api isQualified = false;
    @api childStep;

    constructor() {
        super();
    }
    get isQuoteCompare(){
        console.log('Chil step' + JSON.stringify( this.childStep));
        console.log('Chil step' + this.isQualified);
        if( this.childStep == 'Compare & Rate Quotes'){
            console.log('Istruess');
            return true;
        }
        return false;
    }
    get labelStep(){
        return this.childStep;
    }


}