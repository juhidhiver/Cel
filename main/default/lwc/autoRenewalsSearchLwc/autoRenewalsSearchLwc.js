import { LightningElement, track, api, wire } from 'lwc';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import RENEWAL_OBJECT from '@salesforce/schema/Renewal__c';
import STATUS_FIELD from '@salesforce/schema/Renewal__c.Status__c';
import { refreshApex } from '@salesforce/apex';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import Account from '@salesforce/schema/Account';
import fetchRenewalRecords from '@salesforce/apex/RenewalService.fetchRenewalRecords';
import updateRenewalRecords from '@salesforce/apex/RenewalService.updateRenewalRecords';
import filteredRenewalRecords from '@salesforce/apex/RenewalService.fetchFilteredRenewalRecords';
import getListSectionSetting from '@salesforce/apex/RenewalService.getListSectionSetting';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendTestEmail from '@salesforce/apex/RenewalService.sendTestEmail';






export default class AutoRenewalsSearchLwc extends LightningElement {
    @api  getAppName;
    @api renewalRecordType;
    @api searchingFilterValues;
    @api selectedRowsForStatusChange;

    statusValue = '';
    monthValue;
    yearValue;
    SelectedBroker = '';
    SelectedInsured = '';
    lstRenewals;

    @track accountRecordTypeId;
    @track recordtypefilter;
    @track brokertypefilter;
    @track statusPickList;
    @track policyPremium = 0;
    @track numOfReadyToSend = 0;
    @track totalRenewalsRecords = 0;
    @track monthName;
    @track sixtyDaysNotice;

    renewalWarning = false;
    islargeClaim = false;
    isHasClaim = false;
    isNoRecepient = false;
    isDocRequired = false;
    isPaymentWarning = false;
    isBRokerWarning = false;

    
    @track monthPicklist = [{label:'January',value:'1'},
                    {label:'February',value:'2'},
                    {label:'March',value:'3'},
                    {label:'April',value:'4'},
                    {label:'May',value:'5'},
                    {label:'June',value:'6'},
                    {label:'July',value:'7'},
                    {label:'August',value:'8'},
                    {label:'September',value:'9'},
                    {label:'October',value:'10'},
                    {label:'November',value:'11'},
                    {label:'December',value:'12'}
                ]
      @track yearPicklist;          


    
    @wire(getObjectInfo,  { objectApiName: Account })
    getObjectData({data, error}){
        
        if (data) {
            let recordtypeinfo = data.recordTypeInfos;

            console.log('recordtypeinfo'+  JSON.stringify(recordtypeinfo))
           
            for(var eachRecordtype in  recordtypeinfo){
                if(recordtypeinfo[eachRecordtype].name==='Business'){    
                    this.accountRecordTypeId = recordtypeinfo[eachRecordtype].recordTypeId;
                    console.log(' this.accountRecordTypeId'+ this.accountRecordTypeId);
                    this.recordtypefilter = 'recordtypeid='+ '\''+ this.accountRecordTypeId + '\'';
                
                }
                if(recordtypeinfo[eachRecordtype].name==='Broker'){   
                  let brokerRecordType = recordtypeinfo[eachRecordtype].recordTypeId;
                    this.brokertypefilter = 'recordtypeid='+ '\''+ brokerRecordType + '\'';
                }
            }
        }      
        else if(error){
            console.log(error);
        }                                  
    }


    @wire(getPicklistValuesByRecordType, {
        objectApiName: RENEWAL_OBJECT,
        recordTypeId: '$renewalRecordType',
        fieldApiName: STATUS_FIELD
        
    })
    picklistValues({ error, data }){
         console.log('this.recordTypeId1'+this.renewalRecordType)
         console.log('this.getAppName'+this.getAppName)
         console.log('picklistdata'+JSON.stringify(data));
    	if(data){
        	console.log(data);          
            var result = data.picklistFieldValues.Status__c.values;  
            var updatedStatusPicklist = [{"label":"All","value":""}];
            for( var i=0; i<result.length;i++){
                updatedStatusPicklist.push({"label" : result[i].label, "value" : result[i].value});
            }                
            this.statusPickList = updatedStatusPicklist;
            console.log('this.statusPickList  '+JSON.stringify(this.statusPickList))
             

        }else if(error){
        	console.log(error);
        }
    }

    connectedCallback(){
        console.log('CallBack2')
        console.log('this.recordTypeId2-->'+this.renewalRecordType)
        console.log('this.getAppName2-->'+this.getAppName)

        this.currentMonthYearCalculation(); 
        this.getSectionSettings();
    }

    getSectionSettings(){
        getListSectionSetting({ productName: 'Professional Indemnity' })
        .then((result) => {
            console.log('@@@data1: ' + JSON.stringify(result));
            const selectedEvent1 = new CustomEvent("sectionsettingshandle", {
                detail: {allSections: result.sections, activeSections: result.activeSections}
              });
            this.dispatchEvent(selectedEvent1);

            console.log('--->Section')
            
            //this.handleData(result);
        })
        .catch((error) => {
            console.log('@@@error1: ' + JSON.stringify(error));
        })
    }

    currentMonthYearCalculation(){

        var arr = [];
        const d = new Date();
        let year = d.getFullYear();
        let nextyear = d.getFullYear()+1;
        let previousyear = d.getFullYear()-1;

        arr.push({label:previousyear , value: JSON.stringify(previousyear)});
        arr.push({label:year , value: JSON.stringify(year)});
        arr.push({label:nextyear , value: JSON.stringify(nextyear)});

        this.yearPicklist = arr;
        console.log('yearPicklist',JSON.stringify(this.yearPicklist))
        this.yearValue = JSON.stringify(year);

        
        for(var i=0;i<this.monthPicklist.length;i++){
            if(i == d.getMonth()){
              this.monthValue = this.monthPicklist[i].value;  
              this.monthName =  this.monthPicklist[i].label;
            }
        }


         /*********************** Calculate 60 days date ******************/
        var dateObj = new Date();
        dateObj.setMonth(dateObj.getMonth() - 2);
        var noticemonth = dateObj.getUTCMonth() + 1; //months from 1-12
        var noticeday = dateObj.getUTCDate();
        var noticeyear = dateObj.getUTCFullYear();
        noticemonth = noticemonth < 10 ? "0" + noticemonth : noticemonth;

        this.sixtyDaysNotice = "01" + "/" + noticemonth + "/" + noticeyear;



        if(this.searchingFilterValues){
            var searchboolean = true;
            this.handleSearch(searchboolean);
        }
        else{
            this.getRenewalRecordsOnLoad();
        }
        
    }

    getRenewalRecordsOnLoad(){

        console.log('this.renewalRecordType'+this.renewalRecordType);
        fetchRenewalRecords({renewalRecordTypeId : this.renewalRecordType}).then(response => {
            let returnedData = response;
            let renewalRecords = [];
            console.log('returnedData'+JSON.stringify(returnedData));
            if(returnedData){
                var totalReadyToSend = 0;
                var totalRecords = 0;
                var premium = 0;
                returnedData.forEach( ( record ) => {
                    totalRecords++;
                    console.log('record'+record);
                    let tempRec = Object.assign( {}, record );  
                    if(tempRec.Renewal_Date__c){
                        const options = {year: 'numeric', month: 'long', day: 'numeric'}; 
                        var dateform = new Date(tempRec.Renewal_Date__c );
                        tempRec.Renewal_Date__c = (dateform.getDate()<10 ? '0' + dateform.getDate() : dateform.getDate() ) + '/' + ((dateform.getMonth() + 1)<10 ? '0' + (dateform.getMonth() + 1) : (dateform.getMonth() + 1)) + '/' + dateform.getFullYear();
                        //new Intl.DateTimeFormat('en-US', options).format(new Date( tempRec.Renewal_Date__c )); 
                    }
                    if(tempRec.hasOwnProperty('Policy_Premium__c')){
                        premium = +premium + +tempRec.Policy_Premium__c;
                    }  

                    if(tempRec.Status__c == 'Suppressed'){
                        tempRec.colorStatus = 'slds-text-color_error slds-text-title_bold';
                    }
                    if(tempRec.Status__c == 'Ready to Send'){
                        tempRec.colorStatus = 'slds-text-color_success slds-text-title_bold';
                        totalReadyToSend++;
                    }                                       
                    if ( tempRec.Policy__c ) {
                        tempRec.PolicyNum = tempRec.Policy__r.Policy_Number__c;
                        tempRec.PolicyURL = '/' + tempRec.Policy__c;
                    }
                    if ( tempRec.Policy__c && tempRec.Insured_Account__c ) {
                        tempRec.InsuredName = tempRec.Insured_Account__r.Name;
                        tempRec.InsuredAccURL = '/' + tempRec.Insured_Account__c;
                    }
                    if ( tempRec.Broker__c && tempRec.Broker__r.Broker_Contact__c &&  tempRec.Broker__r.Broker_Contact__r.Account) {
                        tempRec.BrokerName = tempRec.Broker__r.Broker_Contact__r.Account.Name;

                        tempRec.BrokerURL = '/' + tempRec.Broker__r.Broker_Contact__r.Account.Id;
                    }
                    if(tempRec.Assigned_Underwriter__c){
                        tempRec.AssignedUWName = tempRec.Assigned_Underwriter__r.Name;  
                    }
                    renewalRecords.push( tempRec );
                });

                this.policyPremium = premium.toFixed(2);
                this.numOfReadyToSend = totalReadyToSend;
                this.totalRenewalsRecords = totalRecords;

            }
            this.lstRenewals = renewalRecords;
            console.log('this.lstRenewals: ' ,this.lstRenewals);
            const selectedEvent = new CustomEvent("filteredrenewalsrecords", {
                detail: this.lstRenewals
              });
            this.dispatchEvent(selectedEvent);

          

        }).catch(error => {
            console.log('Error: ' +error);
        });
    }


    @api refreshRenewalPicklist() {
        console.log('this.recordTypeId3-->'+this.renewalRecordType)
     
        refreshApex(picklistValues);

        console.log('this.getAppName3-->'+this.getAppName)
    }

    handleStatusChange(event){
        this.statusValue = event.detail.value;

    }

    handleMonthChange(event){
        this.monthValue = event.detail.value;

        console.log(' this.monthValue'+ this.monthValue);

    }
    handleYearChange(event){
        console.log(' event.detail.value year'+ event.detail.value);
        this.yearValue =  event.detail.value;
        console.log('year2'+JSON.stringify(this.yearPicklist))
        console.log('this.yearValue'+this.yearValue);

    }
    handleBrokerSelect(event){
        const selectedRecordId = event.detail;
        this.SelectedBroker = selectedRecordId.selectedId;
    }

    handleInsuredSelect(event){
        const selectedRecordId = event.detail;
        this.SelectedInsured = selectedRecordId.selectedId;
    }

    handleRenewalWarning(event){
        this.renewalWarning = event.target.checked;
    }
    handleLargeClaimAmount(event){
        this.islargeClaim = event.target.checked;
    }
    handleHasClaims(event){
        this.isHasClaim = event.target.checked;
    }
    handleNoRecepients(event){
        this.isNoRecepient = event.target.checked;
    }
    handleNoDocumentsRequired(event){
        this.isDocRequired = event.target.checked;
    }
    handlePaymentWarning(event){
        this.isPaymentWarning = event.target.checked;
    }
    handleBrokerNotAppointed(event){
        this.isBRokerWarning =  event.target.checked;
    }
    handleSearch(searchboolean){


       this.monthName =  this.monthPicklist[ this.monthValue-1].label;

       var dateObj = new Date(this.yearValue,this.monthValue,1);
       console.log('dateObj'+dateObj);
       dateObj.setMonth(dateObj.getMonth() - 2);
       var noticemonth = dateObj.getUTCMonth() + 1; //months from 1-12
       var noticeday = dateObj.getUTCDate();
       var noticeyear = dateObj.getUTCFullYear();
       noticemonth = noticemonth < 10 ? "0" + noticemonth : noticemonth;

       console.log('noticemonth'+noticemonth);
       console.log('noticeyear'+noticeyear);

       this.sixtyDaysNotice = "01" + "/" + noticemonth + "/" + noticeyear;

        const selectedEvent1 = new CustomEvent("loadingspinner", {
            detail: true
          });
        this.dispatchEvent(selectedEvent1);

        console.log('handleSelectedBroker'+this.SelectedInsured);
        console.log('handleSelectedBroker'+this.SelectedBroker);

        this.lstRenewals = [];
        var filteredObj;

        if(this.searchingFilterValues && searchboolean == true){
            filteredObj = this.searchingFilterValues;
            var selectedValues = JSON.parse(JSON.stringify(filteredObj));
            this.yearValue = selectedValues.year;
            this.monthValue = selectedValues.month;
            this.SelectedBroker = selectedValues.selectedBroker;
            this.SelectedInsured = selectedValues.selectedInsured;
            this.statusValue = selectedValues.statusValue;
            this.renewalWarning = selectedValues.renewalWarning;
            this.islargeClaim = selectedValues.largeClaimWarning;
            this.isHasClaim = selectedValues.hasClaimWarning;
            this.isNoRecepient = selectedValues.noRecepientWarning;
            this.isDocRequired = selectedValues.docRequiredWarning; 
            this.isPaymentWarning = selectedValues.paymentWarning;
            this.isBRokerWarning = selectedValues.brokerWarning;
           // let checkboxes = this.template.querySelector('.BrokerWarning')
            //checkboxes.checked = selectedValues.brokerWarning;
            /*for(var i=0; i<checkboxes.length; i++) {
                checkboxes[i].checked = selectedValues.brokerWarning;
            }*/
                
            }
        else{
            filteredObj = {
                year                : this.yearValue,
                month               : this.monthValue,
                selectedBroker      : this.SelectedBroker,
                selectedInsured     : this.SelectedInsured,
                statusValue         : this.statusValue,
                renewalWarning      : this.renewalWarning,
                largeClaimWarning   : this.islargeClaim,
                hasClaimWarning     : this.isHasClaim, 
                noRecepientWarning  : this.isNoRecepient,
                docRequiredWarning  : this.isDocRequired, 
                paymentWarning      : this.isPaymentWarning,
                brokerWarning       : this.isBRokerWarning
             }
        }
      
        

        const selectedEvent2 = new CustomEvent("getsearchingvalues", {
            detail: filteredObj
          });
        this.dispatchEvent(selectedEvent2);

        filteredRenewalRecords({filterWrapper : JSON.stringify(filteredObj),renewalRecordTypeId : this.renewalRecordType}).then(response => {
            let returnedData = response;
            let renewalRecords = [];
            console.log('returnedData'+JSON.stringify(returnedData));
          
            this.policyPremium = 0;
            this.numOfReadyToSend = 0;
            this.totalRenewalsRecords = 0;

         
            if(returnedData){
                var readytoSend = 0;
                var numOfRecords = 0;
                var premium = 0;
                returnedData.forEach( ( record ) => {
                    numOfRecords++;
                    console.log('record'+record);
                    let tempRec = Object.assign( {}, record );  
                    if(tempRec.Renewal_Date__c){
                        const options = {year: 'numeric', month: 'long', day: 'numeric'}; 
                        var dateform = new Date(tempRec.Renewal_Date__c );
                        tempRec.Renewal_Date__c = (dateform.getDate()<10 ? '0' + dateform.getDate() : dateform.getDate() ) + '/' + ((dateform.getMonth() + 1)<10 ? '0' + (dateform.getMonth() + 1) : (dateform.getMonth() + 1)) + '/' + dateform.getFullYear();
                        //tempRec.Renewal_Date__c =  new Intl.DateTimeFormat('en-US', options).format(new Date( tempRec.Renewal_Date__c )); 
                    }
                    if(tempRec.Status__c == 'Suppressed'){
                        tempRec.colorStatus = 'slds-text-color_error slds-text-title_bold';
                    }
                    if(tempRec.Status__c == 'Ready to Send'){
                        tempRec.colorStatus = 'slds-text-color_success slds-text-title_bold';
                        readytoSend++;
                    }                    
                    if(tempRec.hasOwnProperty('Policy_Premium__c')){
                        premium = +premium + +tempRec.Policy_Premium__c;
                    }  
                    if ( tempRec.Policy__c ) {
                        tempRec.PolicyNum = tempRec.Policy__r.Policy_Number__c;
                        tempRec.PolicyURL = '/' + tempRec.Policy__c;
                    }
                    if ( tempRec.Policy__c && tempRec.Insured_Account__c ) {
                        tempRec.InsuredName = tempRec.Insured_Account__r.Name;
                        tempRec.InsuredAccURL = '/' + tempRec.Insured_Account__c;
                    }
                    if ( tempRec.Broker__c && tempRec.Broker__r.Broker_Contact__c &&  tempRec.Broker__r.Broker_Contact__r.Account ) {
                        tempRec.BrokerName = tempRec.Broker__r.Broker_Contact__r.Account.Name;
                        tempRec.BrokerURL = '/' + tempRec.Broker__r.Broker_Contact__r.Account.Id;
                    }
                    if(tempRec.Assigned_Underwriter__c){
                        tempRec.AssignedUWName = tempRec.Assigned_Underwriter__r.Name;  
                    }
                    renewalRecords.push( tempRec );
                });
                this.totalRenewalsRecords = numOfRecords;  
                this.numOfReadyToSend = readytoSend;
                this.policyPremium = premium.toFixed(2);
            }
            
  
            this.lstRenewals = renewalRecords;

    
            
            const selectedEvent = new CustomEvent("filteredrenewalsrecords", {
                detail: this.lstRenewals
              });
            this.dispatchEvent(selectedEvent);


        }).catch(error => {
            console.log('Error: ' +error);
        });


    }
    handleClearfilter(){        
        this.template.querySelectorAll('c-look-up-lwc')[0].clearInputBox();
        this.template.querySelectorAll('c-look-up-lwc')[1].clearInputBox();
        this.searchingFilterValues = '';
        this.yearValue = '';
        this.monthValue = '';
        this.SelectedBroker = null;
        this.SelectedInsured = null;
        this.statusValue = '';
        this.renewalWarning = false;
        this.islargeClaim = false;
        this.isHasClaim = false;
        this.isNoRecepient = false;
        this.isDocRequired = false; 
        this.isPaymentWarning = false;
        this.isBRokerWarning = false;
        this.currentMonthYearCalculation(); 
        this.getSectionSettings();        
    }
      
    handelStatusChange(event){
        var status = event.target.label;       
        this.helperhandelStatusChange(this.selectedRowsForStatusChange, status);
    }

    @api helperhandelStatusChange(RowIds, status){        
        var Rows = [];
        var notCallFucntiontoUpdate = false;
        var errorMsg;
        Rows = RowIds;
        console.log('status serach ' + status, Rows);
        for(var i=0; i<this.lstRenewals.length; i++){
            for(var j=0; j<Rows.length; j++){
                if(this.lstRenewals[i].Id == Rows[j] && this.lstRenewals[i].Status__c != 'Ready to Send' && this.lstRenewals[i].Status__c != 'Suppressed' && status == 'Suppressed'){
                    console.log('status serach 1' + status, Rows);
                    notCallFucntiontoUpdate = true;
                    errorMsg = 'Only Ready to Send Renewals can be marked as Suppressed.';
                    break;
                }
                else if(this.lstRenewals[i].Id == Rows[j] && this.lstRenewals[i].Status__c != 'Suppressed' && this.lstRenewals[i].Status__c != 'Ready to Send' && status == 'Ready to Send'){
                    console.log('status serach 2' + status, Rows);
                    notCallFucntiontoUpdate = true;
                    errorMsg = 'Only Suppressed Renewals can be marked as Ready to Send.';
                    break;
                }
                else if(this.lstRenewals[i].Id == Rows[j] && this.lstRenewals[i].Status__c == 'Suppressed'  && this.lstRenewals[i].Status__c != 'Ready to Send' && status == 'Ready to Send' && this.lstRenewals[i].No_Recipients__c == true ){
                    console.log('status serach 3' + status, Rows);
                    notCallFucntiontoUpdate = true;
                    errorMsg = 'Atleast 1 Broker Contact needs to be selected on the Suppressed Renewal Record(s).';
                    break;
                }
                else{
                    console.log('status serach 4' + status, Rows);                    
                }
            }
        }
        if(notCallFucntiontoUpdate){
            const event = new ShowToastEvent({
                title: 'Error!',
                message: errorMsg,
                variant : 'error'
            });
            this.dispatchEvent(event);
        }
        else{        
            updateRenewalRecords({RenewalIds: RowIds, RenewalStatus: status})
            .then((result) =>{
                const event = new ShowToastEvent({
                    title: 'Saved!',
                    message: 'Status Changed Succesfully',
                    variant : 'success'
                });
                this.dispatchEvent(event);
                this.handleSearch(true);
            })
            .catch((error) => {
                console.log('error ', error);
            })
        }
    }

    @api handleSendTestEmail(RowIds){

        console.log('RowIds'+RowIds);

        sendTestEmail({renewalId : RowIds})
        .then((result) =>{
         
        })
        .catch((error) => {
            console.log('error ', error);
        })
    }

    @api manualSend(){
        console.log('manualSend');
        this.handleSearch(true);
    }
   
}