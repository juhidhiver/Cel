import { LightningElement, api, wire, track } from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getBrokersContactsList from '@salesforce/apex/RenewalService.getListOfBrokerContacts';
import manualEmailSend from '@salesforce/apex/RenewalService.manualEmailSend';




const actions = [   
    { label: 'Mark Suppressed', name: 'markSuppressed' },
    { label: 'Mark Ready to Send', name: 'markReadyToSend' },  
    { label: 'Contact Management', name: 'contactManagement'},
    { label: 'Send Test Email', name: 'sendTestEmail' }, 
    { label: 'Manual Email Send', name: 'manualSendEmail' }, 
     
];

/*const columns = [
    { label: 'TestField', fieldName: 'test1', type: 'string' },
        { 
            label : 'Renewals',
            fieldName: 'renewalRecord',
            type: 'button', 
            typeAttributes: {
                label: { fieldName: 'renewalRecord' },
               variant : 'base'
            }
        }
            
];*/

const columnsAQ = [
    {
        label : 'Renewal', fieldName: 'Name', type: 'button', 
        typeAttributes: {
            label: { fieldName: 'Name' },
            variant : 'base'
        },
        hideDefaultActions: true
    },
    {
        label: 'Policy Number', fieldName: 'PolicyURL', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'PolicyNum'
            },
            tooltip: {
                fieldName: 'PolicyNum'
            },
            target: '_blank'
        },
        hideDefaultActions: true
    },
    {
        label: 'Broker Name', fieldName: 'BrokerURL', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'BrokerName'
            },
            tooltip: {
                fieldName: 'BrokerName'
            },
            target: '_blank'
        },
        hideDefaultActions: true
    },
    {
        label: 'Insured Name', fieldName: 'InsuredAccURL', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'InsuredName'
            },
            tooltip: {
                fieldName: 'InsuredName'
            },
            target: '_blank'
        },
        hideDefaultActions: true
    },
    { label: 'Status', fieldName: 'Status__c', type: 'text', hideDefaultActions: true,cellAttributes:{
        class:{fieldName:'colorStatus'}
    } },
    { label: 'Renewal Date', fieldName: 'Renewal_Date__c', type: 'Date', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    { label: 'Claims #', fieldName: 'Claims_Number__c', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    { label: 'Total Incurred Amount', fieldName: 'Claim_Amount__c', type: 'currency', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    { label: 'No Recipients', fieldName: 'No_Recipients__c', type: 'boolean', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    { label: 'Renewal Warning', fieldName: 'Renewal_Warning__c', type: 'boolean', hideDefaultActions: true },
    { label: 'Assigned Underwriter', fieldName: 'AssignedUWName', type: 'text', hideDefaultActions: true },
    {
        type: 'action',
        typeAttributes: { rowActions: actions },
    }
];

export default class AutoRenewalsListLwc extends LightningElement {
    @api lstRenewals;
    lstColumns = columnsAQ;
    @api isRenewalsEmpty;
    selectedRowsforstatusChange;   
    selectedRows;
    renewalId;
    isContactManagement;
   @api showModal = false;
    brokerContacts;
    renewalId;
    renewalStatus;
    showLoading = false;

    connectedCallback(){  
        //this.selectedRows = null;   
        this.selectedRowsforstatusChange = {};   
       /*fetchRenewalRecords().then(response => {
           this.lstRenewals = response;
            if(this.lstRenewals){
                this.lstRenewals.forEach(
                    item => item['PolicyURL'] = '/lightning/r/Policy__c/' +item['Policy__c'] +'/view'
                );
                this.lstRenewals.forEach(
                    item => item['BrokerURL'] = '/lightning/r/Broker__c/' +item['Broker__c'] +'/view'
                );
            }
           let returnedData = response;
            let renewalRecords = [];
            if(returnedData){
                returnedData.forEach( ( record ) => {
                    let tempRec = Object.assign( {}, record );  
                    if ( tempRec.Policy__c ) {
                        tempRec.PolicyNum = tempRec.Policy__r.Policy_Number__c;
                        tempRec.PolicyURL = '/' + tempRec.Policy__c;
                    }
                    if ( tempRec.Policy__c && tempRec.Policy__r.Account__c ) {
                        tempRec.InsuredName = tempRec.Policy__r.Account__r.Name;
                        tempRec.InsuredAccURL = '/' + tempRec.Policy__r.Account__c;
                    }
                    if ( tempRec.Broker__c ) {
                        tempRec.BrokerName = tempRec.Broker__r.Broker_Name__c;
                        tempRec.BrokerURL = '/' + tempRec.Broker__c;
                    }
                    renewalRecords.push( tempRec );
                });
            }
            this.lstRenewals = renewalRecords;
        }).catch(error => {
            console.log('Error: ' +error);
        });*/
    }

    handleRowAction(event) {
        console.log('insideHandleRowAction1');
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        console.log('actionName = ', actionName);
        console.log('row = ', row);
        console.log('rowStringify = ', JSON.stringify(row));
        console.log('rowId = ', row.Id);    
        this.renewalId = row.Id;      
        for( var i=0; i<this.lstRenewals.length; i++){
            if(this.lstRenewals[i].Id == row.Id){
                this.renewalStatus = this.lstRenewals[i].Status__c;                      
            }
        }
        if(actionName === undefined && row){
            console.log('ShowCustomScreen');
            this.showDetailPage(row);
        }
        else if(actionName){
            this.selectedRowsforstatusChange = {};
            switch (actionName) {
                case 'sendTestEmail':
                    console.log('sendTestEmailClicked');
                    for( var i=0; i<this.lstRenewals.length; i++){
                        if(this.lstRenewals[i].Id == row.Id && this.lstRenewals[i].Status__c != 'Ready to Send'){
                            const evt = new ShowToastEvent({
                                title: 'Error!',
                                message: 'Only Ready to Send renewals can be triggered!',
                                variant: 'error',
                                mode: 'dismissable'
                            });
                            this.dispatchEvent(evt);
                            return;
                        }
                        else if(this.lstRenewals[i].Id == row.Id && this.lstRenewals[i].Status__c == 'Ready to Send'){
                            const evt = new ShowToastEvent({
                                title: 'Success!',
                                message: 'Email has been triggered Successfully!',
                                variant: 'success',
                                mode: 'dismissable'
                            });
                            this.dispatchEvent(evt);

                        }
                    }

                    const selectedEvent2 = new CustomEvent("getselecterows", {
                      detail:  {"RowId": row.Id ,"rowAction":"Email Send"}
                    });
                    this.dispatchEvent(selectedEvent2);
                 
                    break;
                case 'markSuppressed':
                    for( var i=0; i<this.lstRenewals.length; i++){
                        console.log('markSuppressed is Clicked' + this.lstRenewals[i].Status__c , this.lstRenewals[i], row.Id);
                        if(this.lstRenewals[i].Id == row.Id && this.lstRenewals[i].Status__c == 'Ready to Send'){                           
                            const selectedEvent2 = new CustomEvent("getselecterows", {
                                detail:  {"RowId": row.Id, "rowStatus": "Suppressed"}
                                });
                            this.dispatchEvent(selectedEvent2);                                
                        }
                        else if(this.lstRenewals[i].Id == row.Id && this.lstRenewals[i].Status__c != 'Ready to Send'){
                            const event = new ShowToastEvent({
                                title: 'Error!',
                                message: 'Only Ready to Send Renewals can be marked as Suppressed.',
                                variant : 'error'
                            });
                            this.dispatchEvent(event);
                        }
                    }                    
                    break;
                case 'markReadyToSend':
                    for( var i=0; i<this.lstRenewals.length; i++){
                        console.log('markReadyToSendClicked');
                        if(this.lstRenewals[i].Id == row.Id && this.lstRenewals[i].Status__c == 'Suppressed'){
                            if(this.lstRenewals[i].No_Recipients__c == true){
                                console.log('recepit');
                                const event = new ShowToastEvent({
                                    title: 'Error!',
                                    message: 'Atleast 1 Broker Contact needs to be selected on the Renewal Record.',
                                    variant : 'error'
                                });
                                this.dispatchEvent(event);
                            }
                            else{
                                console.log('recepit false');
                                const selectedEvent2 = new CustomEvent("getselecterows", {
                                    detail:  {"RowId": row.Id, "rowStatus": "Ready to Send"}
                                  });
                                this.dispatchEvent(selectedEvent2);  
                            }
                                                       
                        }
                        else if(this.lstRenewals[i].Id == row.Id && this.lstRenewals[i].Status__c != 'Suppressed'){
                            const event = new ShowToastEvent({
                                title: 'Error!',
                                message: 'Only Suppressed Renewals can be marked as Ready to Send.',
                                variant : 'error'
                            });
                            this.dispatchEvent(event);
                        }
                    }                    
                    break;  
                case 'contactManagement': 
                    for( var i=0; i<this.lstRenewals.length; i++){
                        if(this.lstRenewals[i].Id == row.Id && this.lstRenewals[i].Status__c == 'Expired'){
                            const event = new ShowToastEvent({
                                title: 'Error!',
                                message: 'Cannot access Contact Management on Expired records.',
                                variant : 'error'
                            });
                            this.dispatchEvent(event);                      
                        }
                        else if(this.lstRenewals[i].Id == row.Id && !this.lstRenewals[i].Broker__r){
                            const event = new ShowToastEvent({
                                title: 'Error!',
                                message: 'Cannot access Contact Management since there is no Broker Account on this record.',
                                variant : 'error'
                            });
                            this.dispatchEvent(event); 
                        }
                        else if(this.lstRenewals[i].Id == row.Id){
                            this.openPopUp();  
                        }
                    }                                                                           
                    break;     
                    
                case 'manualSendEmail':
                    for( var i=0; i<this.lstRenewals.length; i++){
                        if(this.lstRenewals[i].Id == row.Id && this.lstRenewals[i].Status__c != 'Ready to Send'){
                            const evt = new ShowToastEvent({
                                title: 'Error!',
                                message: 'Only Ready to Send renewals can be triggered!',
                                variant: 'error',
                                mode: 'dismissable'
                            });
                            this.dispatchEvent(evt);
                            return;
                        }
                        else if(this.lstRenewals[i].Id == row.Id && this.lstRenewals[i].Status__c == 'Ready to Send'){
                           /* const evt = new ShowToastEvent({
                                title: 'Success!',
                                message: 'Email has been triggered Successfully!',
                                variant: 'success',
                                mode: 'dismissable'
                            });
                            this.dispatchEvent(evt);*/
                            this.renewalId = row.Id;

                            this.getBrokerContacts();
                        }
                    }   
                break;   
                default:
            }
        }
    }

    openPopUp(){
        console.log('fire');
        this.isContactManagement = true; 
    }

    getBrokerContacts(){
        console.log('showModal'+this.showModal);
        getBrokersContactsList({renewalId : this.renewalId})
        .then((result) => {
            console.log('result'+result);
           
        //   console.log('result Data'+result.data);
 
           if(result.length==0){
            const evt = new ShowToastEvent({
                title: 'Error!',
                message: 'Atleast 1 Broker Contact needs to be selected for Renewals',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
            return;

           }
           else{
           this.showModal = true;
           this.brokerContacts = result;
           }
        })
        .catch((error) => {
            console.log('@@@Exception---: ' + JSON.stringify(error));
        })
        
    }

    handelRowSelection(event){
        this.selectedRowsforstatusChange = {};
        var selectedRows = event.detail.selectedRows;    
        var slectedRowIds = [];   
        // Display that fieldName of the selected rows
        for (var i = 0; i < selectedRows.length; i++){            
            slectedRowIds.push(selectedRows[i].Id);            
        }  
        if(slectedRowIds){
            this.selectedRowsforstatusChange = slectedRowIds;
        }
        
        console.log("You selected: " , JSON.stringify(slectedRowIds));   
        const selectedEvent2 = new CustomEvent("getselecterows", {
            detail: {"RowId": this.selectedRowsforstatusChange}
          });
        this.dispatchEvent(selectedEvent2);
       
    }

    showDetailPage(recordDetails){
        console.log('insideShowDetailPage');
        let showRenewalDetailPage = new CustomEvent('showrenewaldetailpage', { detail: { renewalRecordDetails: recordDetails } });
        this.dispatchEvent(showRenewalDetailPage);
    }

    handelCloseFromChild(){
        this.isContactManagement = false;        
    }
    handelSaveFromChild(){
        const selectedEvent2 = new CustomEvent("getselecterows", {
            detail: {"RowId":  this.renewalId, "ContatctManagement": "true"}
          });
        this.dispatchEvent(selectedEvent2);
    }
    hideModalBox(){
     this.showModal = false;   
    }

    manualSend(){
        this.showLoading = true;
        this.showModal = true;
         const evt = new ShowToastEvent({
                                title: 'Success!',
                                message: 'Email has been triggered Successfully!',
                                variant: 'success',
                                mode: 'dismissable'
                            });
        this.dispatchEvent(evt);
        manualEmailSend({renewalId : this.renewalId})
        .then((result) => {
            this.showLoading = false;
            this.showModal = false;
            const selectedEvent2 = new CustomEvent("getselecterows", {
                detail:  {"RowId": this.renewalId ,"rowAction":"manualSend"}
              });
            this.dispatchEvent(selectedEvent2);
            
        //   console.log('result Data'+result.data);
        })
        .catch((error) => {
            this.showLoading = false;
            console.log('@@@Exception---: ' + JSON.stringify(error));
        })
    }

    /*renderedCallback() {
        setTimeout(() => {
        console.log('this.a'+JSON.stringify(this.getElementsByTagName('span')));

        },2000)
    }
    func(event){
        event,target.Id
    }*/
}