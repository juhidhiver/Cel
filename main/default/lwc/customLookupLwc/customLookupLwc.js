import { LightningElement, track, api,wire } from 'lwc';
import findRecords from '@salesforce/apex/CustomLookupControllerLWC.findRecords';
import {refreshApex} from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';

export default class CustomLookup extends NavigationMixin(LightningElement){
    //Attributes
    @api records ;
    @track error ;
    @api selectedRecord ;
    @api isSelected ;
    @api index ;
    @api customLabelLookup ;
    @api relationshipfield ;
    @api searchKey ;
    @api iconname = "standard:account" ;
    @api objectName = 'Account' ;
    @api searchfield = 'Name' ;



    // Get records list
    @wire(findRecords, {searchKey : '$searchKey' ,objectName : '$objectName',    searchField : '$searchfield'})
    accsApex({error,data}) {
        this.records = data;
        this.isSelected = false;
    }
    //Handle search
    handleOnchange(event){
        console.log('=== Isselected === ' + this.isSelected);
        let searchKey = event.detail;
        console.log('=== Search Key ===' +JSON.stringify(searchKey) );
        this.searchKey = searchKey.value + '';
        console.log('===Results== ' + JSON.stringify(this.records));
    }
    //handle select element
    handleSelect(event){
        this.isSelected = true;
        const selectedRecordId = event.detail;
        this.selectedRecord = this.records.find( record => record.Id === selectedRecordId);
        console.log('== Selected record == ' + JSON.stringify (this.selectedRecord));
        console.log('=== Records === ' + JSON.stringify(this.records));

        const selectedRecordEvent = new CustomEvent(
            "selectedrec",
            {
                detail : { recordId : selectedRecordId, index : this.index, relationshipfield : this.relationshipfield}
            }
        );
        this.dispatchEvent(selectedRecordEvent);
    }
    //handle remove element
    handleRemove(event){
        event.preventDefault();
        this.selectedRecord = undefined;
        this.records = undefined;
        this.error = undefined;
        const selectedRecordEvent = new CustomEvent(
            "selectedrec",
            {
                detail : { recordId : undefined, index : this.index, relationshipfield : this.relationshipfield}
            }
        );
        this.dispatchEvent(selectedRecordEvent);
        this.isSelected = false ;

    }
    handleCreateRecord(event){
        let pageRef = {
            type: 'standard__component',
            attributes: {
                componentName: 'c__ChoosingRecordTypeCmp'
            },
            state: {
                c__objName: this.objectName
            }
        };
        this[NavigationMixin.Navigate](pageRef);
        /*
        let pageRef = {
            type: "standard__objectPage",
            attributes: {
                objectApiName: this.objectName ,
                actionName: 'new' ,
            },
            state: {
                nooverride: '1' ,
                navigationLocation: 'LOOKUP' ,
            }
        };
        const defaultFieldValues = {
        };
        pageRef.state.defaultFieldValues = encodeDefaultFieldValues(defaultFieldValues);
        this[NavigationMixin.Navigate](pageRef); */

    }
    onshowtoast(event) {
        console.log('Event' + JSON.stringify(event));
    }
}