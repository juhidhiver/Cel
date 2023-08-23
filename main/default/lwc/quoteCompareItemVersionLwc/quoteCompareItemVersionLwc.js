import {LightningElement,api,wire} from 'lwc';
import getListQuoteVersions from '@salesforce/apex/QuoteVersionController.getListQuoteVersions';

export default class QuoteCompareItemVersionLwc extends LightningElement {
    @api versionList = [];
    @api versionSize;
    @api versionId;

    constructor() {
        super();
        getListQuoteVersions({ quoteId:"0Q025000000EohKCAS"})
            .then(result => {
                console.log('Result ' + JSON.stringify(result));
            this.versionList = result;
            this.versionSize = result.length;
            })
            .catch(error => {
                this.error = error;
            });

    }
    handleSelectedVersionCh(event){
        var selectedVersion = event.detail.versionId;
        const selectVersionEvt2 = new CustomEvent(
            "childversionselected", {
                detail: {
                    versionId: selectedVersion,
                }
            }
        );
        this.dispatchEvent(selectVersionEvt2);
    }





}