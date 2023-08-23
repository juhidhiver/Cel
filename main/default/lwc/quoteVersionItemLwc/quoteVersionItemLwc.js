import {LightningElement,api , wire} from 'lwc';

export default class QuoteVersionItemLwc extends LightningElement {

    @api versionName = '';
    @api listFieldsChanged = [];
    @api createdDate = '';
    @api versionId;
    constructor() {
        super();
        console.log('Changed ' + JSON.stringify(this.listFieldsChanged));
    }


    handleSelectVersionChild(){
        const selectVersionEvt2 = new CustomEvent(
            "childversionselected", {
                detail: {
                    versionId: this.versionId,
                }
            }
        );
        this.dispatchEvent(selectVersionEvt2);
    }



}