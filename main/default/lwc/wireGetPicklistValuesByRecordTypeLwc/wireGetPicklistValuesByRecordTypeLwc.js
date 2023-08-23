import { LightningElement, wire, api } from 'lwc';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import SUBMISSION_RECORD from '@salesforce/schema/Opportunity';

export default class WireGetPicklistValuesByRecordTypeLwc extends LightningElement {
    treeModel;
    error;
    @api fieldName = 'StageName';

    @wire(getPicklistValuesByRecordType, {
        objectApiName: SUBMISSION_RECORD,
        recordTypeId: ''
    })
    wiredValues({ error, data }) {
        if (data) {
            //console.log('data.picklistFieldValues:' + JSON.stringify(data.picklistFieldValues));
            this.treeModel = this.getModelByField(data.picklistFieldValues, this.fieldName);
            console.log('data.picklistFieldValues:' + JSON.stringify(this.treeModel));
            this.error = undefined;
        } else {
            this.error = error;
            this.treeModel = undefined;
        }
    }

    buildTreeModel(picklistValues) {
        const treeNodes = [];
        Object.keys(picklistValues).forEach((picklist) => {
            treeNodes.push({
                label: picklist,
                items: picklistValues[picklist].values.map((item) => ({
                    label: item.label,
                    name: item.value
                }))
            });
        });
        return treeNodes;
    }

    getModelByField(picklistValues,fieldName) {
        var result = null;
        Object.keys(picklistValues).forEach((picklist) => {
            if(fieldName.localeCompare(picklist) == 0) {
                result = picklistValues[picklist].values.map((item) => ({
                    label: item.label,
                    name: item.value
                }));
            } 
        });
        return result;
    }
}