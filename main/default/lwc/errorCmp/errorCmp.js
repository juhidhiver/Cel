import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
//import lightningOverride from '@salesforce/resourceUrl/lightningOverride';

export default class errorCmp extends LightningElement {
    @api value;

    connectedCallback(){
       // loadStyle(this, lightningOverride + '/lightningOverride/icon.css');
    }
}