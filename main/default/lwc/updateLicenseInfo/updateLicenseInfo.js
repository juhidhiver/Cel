import { LightningElement, wire, api, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getBrokerDetail from '@salesforce/apex/UpdateLicenseInfoOnPolicy.getBrokerDetail';
import updateBLInfo from '@salesforce/apex/UpdateLicenseInfoOnPolicy.updatePolicyBLInfo';
// import standard toast event
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
 
import { CloseActionScreenEvent } from 'lightning/actions';

export default class UpdateLicenseInfo extends LightningElement {

    @api isAgencyLicnseSelected;
    @api isBrokerLicnseSelected;
    
    //for bind quote page
    @api quoteId;
    //for policy record page
    @api policyId;
    @track isPolicy = false;   
    
    @track brokerLicesesData = [];
    @track agencyLicesesData = [];
    //to set selected broker (either Agency broker or indivdual broker)
    @api selectedBroker = {};

    apexResult;
    _recordId;
    
    columns = [
        { label: 'Broker', fieldName: 'blOwnerName' },
        { label: 'Broker licese number', fieldName: 'blNo' },
        { label: 'License State', fieldName: 'liceseState' },
        { label: 'NPN Status', fieldName: 'NPNStatus' },
    ];
   
    //Public property
    @api
    get isAgencyDataAvailable(){
        return this.agencyLicesesData.length > 0 ? true : false;
    }

    @api
    get isBrokerDataAvailable(){
        return this.brokerLicesesData.length > 0 ? true : false;
    }

    @api
    get disableSubmit(){
        if( Object.keys(this.selectedBroker).length === 0 ){
            return true;
        }else{
            return false;
        }
    }
    @api get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        this.brokerDataForPolicy();
    }
    connectedCallback() {
        console.log('in callback');
        this.brokerDataForQuote();
    }
    
    brokerDataForPolicy(){
        getBrokerDetail({recId : this._recordId})
        .then(data => {
            if (data) {
                console.log('wire policy',data, this.policyId, this._recordId  );
                this.policyId = data.p.Id;
                this.isPolicy = true;
                let productName = data.p.Product_Name__c;
                if( data.opp ){
                    let oppRecordType = data.opp.RecordType.Name;
                
                    if( oppRecordType == 'Celerity' /*&& productName != 'Private Company Combo'*/ ){
                        this.processBrokerData(data);
                    }else{
                        this.showErrorMessage('Update broker is only applicable for MPL and Cyber');
                        this.handleCancel();
                    }      
                }else{
                    this.showErrorMessage('No Opportunity found');
                }   
            }
        })
        .catch(error => {
            this.disableSubmit = true;
            console.log('quote Error-->' +error.body.message);
        });
    }
     
    brokerDataForQuote(){
        getBrokerDetail({recId : this.quoteId})
        .then(data => {
            this.handleRefreshdata(data);
        })
        .catch(error => {
            console.log('quote Error-->' +error.body.message);
        });
    }
    handleRefreshdata(value){
        var data = value;
        console.log('wire quote',data );
        if (data) {
            console.log('wire quote',data, this.quoteId );
            let productName = data.q.Product_Name__c;
            if( data.opp ){
                let oppRecordType = data.opp.RecordType.Name;
            
                if( oppRecordType == 'Celerity' /*&& productName != 'Private Company Combo'*/ ){
                    this.processBrokerData(data);
                }else{
                    this.showErrorMessage('Update broker is only applicable for Celerity MPL and Cyber');
                }      
            }else{
                this.showErrorMessage('No Opportunity found');
            }
        }
    }

    processBrokerData( result ){        
        this.isAgencyLicnseSelected = true;
        console.log('result=', JSON.stringify(result));
        for(var i = 0 ; i< result.alList.length ; i++ ){
            var alic = result.alList[i];
            var alObj = {
                oppRecordType : result.opp.RecordType.Name,
                productName : result.q ? result.q.Product_Name__c : result.p.Product_Name__c,
                blOwner : 'Agency',
                id : alic.Id,
                blOwnerName : alic.Agency__r.Name,
                blNo : alic.License_Number__c, 
                liceseState : alic.License_State__c, 
                NPNStatus :  alic.NIPR_License_Status__c,
                blOwnerAddress : alic.Agency__r.Name +', '+ alic.Agency__r.BillingStreet +', '+ alic.Agency__r.BillingCity +', '+ alic.Agency__r.BillingState +', '+ alic.Agency__r.BillingPostalCode
            };
            this.agencyLicesesData.push(alObj);
        }

        for(var i = 0 ; i< result.blList.length ; i++ ){
            var blic = result.blList[i];
            var blObj = {
                oppRecordType : result.opp.RecordType.Name,
                productName : result.q ? result.q.Product_Name__c : result.p.Product_Name__c,
                blOwner : 'Producer',
                id : blic.Id,
                blOwnerName : blic.Broker__r.Name,
                blNo : blic.License_Number__c, 
                liceseState : blic.License_State__c, 
                NPNStatus :  blic.NPN__c,
                blOwnerAddress : blic.Broker__r.Account.Name +', '+ blic.Broker__r.Account.BillingStreet +', '+ blic.Broker__r.Account.BillingCity +', '+ blic.Broker__r.Account.BillingState +', '+ blic.Broker__r.Account.BillingPostalCode
            };
            this.brokerLicesesData.push(blObj);
        }
    }

    handelAgencyBrokerLicense(event){
        this.selectedBroker = {};
        this.setSelectedBroker();
        if(event.target.checked){
            this.isBrokerLicnseSelected = false;
            this.isAgencyLicnseSelected = true;
        }else{
            this.isAgencyLicnseSelected = false;
        }
    }

    handelIndividualBrokerLicense(event){
        this.selectedBroker = {};
        this.setSelectedBroker();
        if(event.target.checked == true){
            this.isAgencyLicnseSelected = false;
            this.isBrokerLicnseSelected = true;
        }else{
            this.isBrokerLicnseSelected = false;
        }
    }

    handleAgencySelection(event){
        const selectedRows = event.detail.selectedRows;
        console.log('SelectedData' + JSON.stringify(selectedRows));
        if( selectedRows.length > 0 ){
            this.selectedBroker = this.setBindingLicenseInfo(selectedRows[0]);
            console.log('this.selectedBroker',this.selectedBroker);
        }else{
            this.selectedBroker = {};
        }
        if( !this.isPolicy ){
            this.setSelectedBroker();
        }
    }

    handleBrokerSelection(event){
        const selectedRows = event.detail.selectedRows;
        console.log('SelectedData' + JSON.stringify(selectedRows));
        if( selectedRows.length > 0 ){
            this.selectedBroker = this.setBindingLicenseInfo(selectedRows[0]);
            console.log('this.selectedBroker',this.selectedBroker);
        }else{
            this.selectedBroker = {};
        }
        if( !this.isPolicy ){
            this.setSelectedBroker();
        }
    }
    
    setSelectedBroker(){
        this.dispatchEvent( new CustomEvent( 'selectedbrokerchange', {
            detail: this.selectedBroker
        }));
    }

    handleSubmit(){
        if(this.isPolicy){
            console.log('this.selectedBroker',this.selectedBroker);
            updateBLInfo({ policyId: this.policyId, blInfo : JSON.stringify(this.selectedBroker) })
            .then(result => {
                const event = new ShowToastEvent({
                    title: 'Success',
                    message: 'Policy updated',
                    variant: 'success'
                });
                this.dispatchEvent(event);
                this.handleCancel();
            })
            .catch(error => {
                console.log('@@@error: ' + JSON.stringify(error));
                const event = new ShowToastEvent({
                    title : 'Error',
                    message : JSON.stringify(error),
                    variant : 'error'
                });
                this.dispatchEvent(event);
            })
        }                

    }

    showErrorMessage(errormsg){
         this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error Occured',
                message: JSON.stringify(errormsg),
                variant: 'error'
            })
        );
    }

    handleCancel(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    setBindingLicenseInfo( selectedRowObj ){
        return {
            oppRecordType : selectedRowObj.oppRecordType,
            productName : selectedRowObj.productName,
            blOwner : selectedRowObj.blOwner,
            blOwnerName : selectedRowObj.blOwnerName,
            blNo : selectedRowObj.blNo,
            blOwnerAddress : selectedRowObj.blOwnerAddress,
        };
    }
}