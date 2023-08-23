import { LightningElement,track,api,wire } from 'lwc';
import appName from '@salesforce/apex/RenewalService.getRenewalWrappInfo';
export default class AutoRenewalsMainLwc extends LightningElement {
    
    @track currentApp;
    @track recordtypeId;
    @track isRecordTypePresent = false;
    renewalRecordClicked = undefined;
    showRenewalDetailPage = false;
    renewalRecords;
    sectionsettings;
    @track SearchingFilterValues;
    @track selectedRowsforStatusChange;

    isRenewalsDataEmpty = false;
    isLoading = true;

    /**connectedCallback(){
      console.log('CallBack1')
       this.fetchappName();
    }*/

    @wire (appName)
    picklistValues({data, error}){
        console.log('data'+JSON.stringify(data));
        if (data) {
            this.currentApp = data.appName;
            this.recordtypeId = data.renewalRecordType;
            this.isRecordTypePresent = true;
            console.log(' this.currentApp'+  this.currentApp)
            console.log(' this.recordtypeId'+  this.recordtypeId)

        }      
        else if(error){
            console.log(error);
        }                                  
    }

    handleShowRenewalDetailPage(event){
        this.renewalRecordClicked = event.detail.renewalRecordDetails;
        console.log('renewalRecordClicked = ', this.renewalRecordClicked);
        this.showRenewalDetailPage = true;
        console.log(' this.sectionsettings'+JSON.stringify(this.sectionsettings))
    }

    handleSpinnerLoad(){
        this.isLoading = true;
    }

    handleShowRenewalMainPage(){
        this.renewalRecordClicked = undefined;
        this.showRenewalDetailPage = false;
    }
    handlefilteredRecords(event){
        console.log('detail',event.detail);

        this.isLoading = false;

        this.renewalRecords = event.detail;

       if(this.renewalRecords.length==0){
            this.isRenewalsDataEmpty = true;
        }
        else{
            this.isRenewalsDataEmpty = false;
        }

    }
    handleSectionSettings(event){
        console.log('Section settings')
         this.sectionsettings = event.detail;
    }

    handelSearchingValues(event){        
        this.SearchingFilterValues = event.detail;
    }

    handelSelectedRowsfromChild(event){
        console.log('ContatctManagement Send', event.detail);
        if(event.detail.RowId && event.detail.rowStatus){
            this.template.querySelectorAll('c-auto-renewals-search-lwc')[0].helperhandelStatusChange(event.detail.RowId, event.detail.rowStatus);
            this.selectedRowsforStatusChange = event.detail.RowId;
            console.log('Auto Renewal Main detail'+ JSON.stringify(event.detail));
        }
        else{
            this.selectedRowsforStatusChange = event.detail.RowId;
        }
        if(event.detail.RowId && event.detail.ContatctManagement ){
            
            this.template.querySelector('c-auto-renewals-search-lwc').manualSend();
        }

        if(event.detail.RowId && event.detail.rowAction != 'manualSend'){

            this.template.querySelector('c-auto-renewals-search-lwc').handleSendTestEmail(event.detail.RowId);
        }

       else if(event.detail.RowId && event.detail.rowAction == 'manualSend'){
        console.log('Manual Send')
        this.template.querySelector('c-auto-renewals-search-lwc').manualSend();
       }      
        
    }

    
}