import { LightningElement,track } from 'lwc';

export default class AddEndorsementLwc extends LightningElement {
    @track isModalOpen = true;
    closeModal () {
        this.isModalOpen = false;
    }
}