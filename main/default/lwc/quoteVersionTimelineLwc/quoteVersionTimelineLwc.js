import { LightningElement, api } from 'lwc';

export default class QuoteVersionTimelineLwc extends LightningElement {

    @api isOpen = false;
    @api quoteId;
    @api quoteName;

    handleCancel() {
        // handle cancel here
        this.isOpen = !this.isOpen;
        this.dispatchEvent(new CustomEvent('closeversiontimeline'));
    }
    connectedCallback(){
        console.log('@@@ quoteId',this.quoteId);
        
    }

    handleSelectVersion(event){
        var selectedVersion = event.detail.versionId;
        const selectVersionEvt2 = new CustomEvent(
            "selecversionevt", {
                detail: {
                    versionId: selectedVersion,
                }
            }
        );
        this.dispatchEvent(selectVersionEvt2);
    }
}