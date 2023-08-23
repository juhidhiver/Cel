import {LightningElement, api, wire} from 'lwc';
import getRecordTypeValues from '@salesforce/apex/ChoosingRecordTypeCmpController.getRecordTypeValues';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';

export default class ChoosingRecordTypeLwc extends NavigationMixin(LightningElement) {
    @api recordTypeMap;
    @api selectedRecordTypeId;
    @api isShow = false;
    @api objectName = 'Account' ;

    @wire(getRecordTypeValues, {objName : '$objectName'})
    recordTypeApex({error,data}){
        console.log('RecordType Apex Client ');
        console.log('Record Type Returned ' + JSON.stringify(data));
        if(data != undefined){
            var count = 0;
            var recordTypes = data.objRecordTypes;
            var recordtypeMapRe = [];
            for(var key in recordTypes){
                recordtypeMapRe.push({label: recordTypes[key], value: key});
                count++;
            }
            this.recordTypeMap = recordtypeMapRe;
            this.selectedRecordTypeId = data.defaultRecordTypeId;
            if(count != 0 ){
                this.isShow = true;
            }
        }
    }

    handleCancel(){

    }

    handleNext(){
        let pageRef = {
            type: "standard__objectPage",
            attributes: {
                objectApiName: this.objectName ,
                actionName: 'new' ,
            },
            state: {
                nooverride: '1',
                navigationLocation: 'LOOKUP' ,
            }
        };
        const defaultFieldValues = {
            RecordTypeId: this.selectedRecordTypeId,
        };
        pageRef.state.defaultFieldValues = encodeDefaultFieldValues(defaultFieldValues);
        this[NavigationMixin.Navigate](pageRef);
    }
}