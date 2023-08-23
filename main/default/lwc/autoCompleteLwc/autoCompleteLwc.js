import {LightningElement, api, wire} from 'lwc';
import getRecords from '@salesforce/apex/AutoCompleteController.getRecords';

export default class AutoCompleteLwc extends LightningElement {
    @api label;
    @api selectedOption;
    @api results;
    @api isLoading = false;
    @api notOpenDropDown = false;
    @api inputValue ='willia';
    @api address ;
    @api returnSize = 0;

    constructor() {
        super();
        this.notOpenDropDown = true;
    }

    clearOption(){
        this.results = [];
        this.isLoading = false;
        this.inputValue = '';
        this.selectedOption  = '';
        this.address = null;
    }
    selectRecord(event){
        console.log(JSON.stringify(event.currentTarget.getAttribute("data-value").value()));
        console.log(JSON.stringify(event.currentTarget));


        /*
        const selectedRecordEvent = new CustomEvent(
            "selectedrecordatevt",
            {
                detail : { recordId : selectedRecordId, index : this.index, relationshipfield : this.relationshipfield}
            }
        );
        this.dispatchEvent(selectedRecordEvent); */
    }
    @wire(getRecords,{searchString: '$inputValue',countryCode : 'AF'})
    wireResults({error,data}) {
        console.log('Mydata' + JSON.stringify(data));
        this.results = data;
        this.isLoading = false;

    }
    searchHandler(event){
        if(event.target.value.length>=3){
            this.isLoading = true;
            console.log('loading' + this.isLoading);
            this.notOpenDropDown = false;
            this.inputValue = event.target.value;
             }else{
            this.isLoading = false;
            this.inputValue = event.target.value;
            this.notOpenDropDown = true;
        }
    }
}