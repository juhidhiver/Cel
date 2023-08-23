import { LightningElement, track, api } from 'lwc';

export default class SearchComponent extends LightningElement {
    
    @track searchKey;
    @api customLabel = 'Custom Label';
    handleChange(event){
        const searchKey = event.target.value;
        console.log('===Search key ==' + event.target.value);
        event.preventDefault();
        const searchEvent = new CustomEvent(
            'change', 
            { 
                detail : searchKey
            }
        );
        console.log('Event');
        this.dispatchEvent(searchEvent);
        console.log('== End Fire Key Event ' + JSON.stringify(searchEvent));
    }
}