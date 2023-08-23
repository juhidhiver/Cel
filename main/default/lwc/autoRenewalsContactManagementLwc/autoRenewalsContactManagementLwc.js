import { LightningElement,api } from 'lwc';
import fetchContactsofRenewal from '@salesforce/apex/RenewalService.fetchContactsofRenewal';
import updateRoleOnContact from '@salesforce/apex/RenewalService.updateRoleOnContact';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columnsCon = [
    {label : 'Name', fieldName: 'Name', type: 'text'},
    {label: 'Email', fieldName: 'Email', type: 'text'},
    {label: 'Send Renewal Email?', fieldName: 'IsRenewalRole', type: 'boolean', editable: true ,
        cellAttributes: { alignment: 'left', class: 'slds-border_left', variant:"label-hidden" }
    },    
];
export default class AutoRenewalsContactManagementLwc extends LightningElement {

lstContacts;
lstColumns = columnsCon;
@api renewalid;
draftValues = [];
rowIdDataTable;
isSpinner;
    

    connectedCallback() {
        this.isSpinner = true;
        this.getContactofRenewals();
    }

    getContactofRenewals(){
        fetchContactsofRenewal({renewalId : this.renewalid})
        .then((result) => {
            this.lstContacts = result;            
            if(result.length>0){
                for(var i=0; i<result.length; i++){
                    var RoleList = [];
                    result[i]['tableId'] = 'row-' + i;
                    if(result[i].Role__c){
                        RoleList = result[i].Role__c.split(';');                      
                    }                                      
                    if(RoleList.includes('Renewals')){
                        result[i]['IsRenewalRole'] = true;                       
                    }
                }
            }
            this.isSpinner = false;
            console.log('Contact of Renewal ' , result);
        })
        .catch((error) => {
            console.log('Error : ', error);
            this.isSpinner = false;
        })
    }

    async handleSave(event) {
        this.isSpinner = true;
        // Convert datatable draft values into record objects  
        var removeRoleList = [];
        var addRoleList = [];          
        var conLen = this.lstContacts.length;
        var count = 0;
        const records = event.detail.draftValues.slice().map((draftValue) => {
            const fields = Object.assign({}, draftValue);
            return { fields };
            
        }); 
        for( var i=0; i<this.lstContacts.length;i++){
            var RoleList = [];
            if(this.lstContacts[i].Role__c){
                RoleList = this.lstContacts[i].Role__c.split(';'); 
                if(!RoleList.includes('Renewals')){                           
                    count += 1;   
                    console.log(' 1 count incre  ',count);                     
                }                                     
            }
            else{                
                count += 1;
                console.log(' 3 count incre  ',count);   
            }
        }
        console.log('this.lstContacts ' , this.lstContacts);    
       // const recordUpdate = records.map((record) => {
            for( var j=0; j<records.length; j++){              
            console.log('records : ' ,records, records[j].fields.id,records[j].fields.IsRenewalRole);
            for( var i=0; i<this.lstContacts.length;i++){                
                if(this.lstContacts[i]['tableId'] ==  records[j].fields.id){  
                    if(records[j].fields.IsRenewalRole){
                        addRoleList.push(this.lstContacts[i].Id);                         
                        count -= 1; 
                        console.log('4 count decre ',count);  
                    }   
                    else{
                        count += 1;       
                        removeRoleList.push(this.lstContacts[i].Id);                          
                        console.log('5 count incre ',count);                                                                
                    }                                
                }
            }
        }
        //});
        if(removeRoleList.length>0 || addRoleList.length >0){
            console.log('call function',count,conLen);
            
            if(conLen <= count){
                const event = new ShowToastEvent({
                    title: 'Not Updated!',
                    message: 'Atleast 1 Broker Contact needs to be selected for Renewals.',
                    variant : 'error'
                });
                this.dispatchEvent(event); 
                this.isSpinner = false;               
            }
            else{
                this.updateRoleOnContact(removeRoleList,addRoleList);  
            }
        }
        // Clear all datatable draft values
        this.draftValues = [];
    }

    updateRoleOnContact(removeRoleList, addRoleList){
        console.log('renewal Id : ' + this.renewalid)
        updateRoleOnContact({removeRoleonContact : removeRoleList, addRoleonContact : addRoleList, renewalId : this.renewalid })
        .then((result) => {            
            console.log('Updated Contact Renewal ' , result);
            this.getContactofRenewals(); 
            const selectedEvent = new CustomEvent("save");
            this.dispatchEvent(selectedEvent);           
            const event = new ShowToastEvent({
                title: 'Updated!',
                message: 'Role Updated Successfully.',
                variant : 'success'
            });
            this.dispatchEvent(event); 
        })
        .catch((error) => {
            console.log('Error : ', error);
            this.isSpinner = false;
        })
    }
    handleClose(){
        const selectedEvent2 = new CustomEvent("close");
        this.dispatchEvent(selectedEvent2);
    }
}