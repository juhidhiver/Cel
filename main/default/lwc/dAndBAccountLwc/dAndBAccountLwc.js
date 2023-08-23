import {LightningElement, api, wire, track} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getDbBForQuoteProcess from '@salesforce/apex/AutoCompleteController.getDbBForQuoteProcess';
import insertDnBAccount from '@salesforce/apex/AutoCompleteController.insertDnBAccount';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import COUNTRY_FIELD from '@salesforce/schema/Account.Country_Code__c';
import checkAqueousProduct from '@salesforce/apex/AutoCompleteController.checkAqueousProduct';
export default class DAndBAccount extends NavigationMixin(LightningElement){
    //Attributes
    @api label = '';//Search label
    @api selectedOption;
    @api results;
    @api isLoading = false;
    @api inputValue ='';
    @api address ;
    //@api returnSize = 0;
    @api selectedRecordA;
    @api isDisableInput = false;
    @api countryCodeD;
    @api dunNumb;
    @api selectedDnbAddress;
    //Flow attributes
    @api dbAccountId = '';
    @api sObjectId;
    @track isAqueous;
    @track showSpinner;
  
    disableSave;
    constructor() {
        super();
    }

    clearOption(){
        this.results = undefined;
        this.isLoading = false;
        this.inputValue = '';
        this.selectedOption  = '';
        this.address = null;
        this.selectedDnbAddress = null;
        this.isDisableInput = false;
    }
    @wire(checkAqueousProduct, {sObjectId : '$sObjectId'})
    getProductType({error, data}){
        if(data){
            this.isAqueous = data == 'Aqueous' ? true : false;
            console.log('data -->'+JSON.stringify(data));
            console.log('this.isAqueous -->'+this.isAqueous);
        }else{
            console.log('error -->'+JSON.stringify(error));
        }
    }


    get options() {
        if(this.isAqueous){
            return [
                { label: 'United Kingdom', value: 'GB' },
                { label: 'Ireland', value: 'IE' },
                { label: 'Isle of Man', value: 'IM' },
                { label: 'Guernsey', value: 'GG' },
                { label: 'Jersey', value: 'JE' }
            ];
        }
        else{
            return [
                { label: 'United States', value: 'US' }
            ];
        }
       
    }
   
    selectRecord(event){
        var dunNumber = event.currentTarget.getAttribute("data-value");
        this.dunNumb = dunNumber;
        var selectedDB;
        for(var i = 0;i<=this.results.length - 1;i++){
            if(this.results[i].duns == dunNumber ){
                selectedDB = this.results[i];
            }
        }
        this.inputValue =  selectedDB.primaryName;
        this.isDisableInput = true;
        this.selectedDnbAddress = selectedDB;
       // this.getCorporateIntelInfor(dunNumber);
        console.log('Selected DB First API: ' + JSON.stringify(selectedDB));
        this.results = null;
    }
    
    handleNext(event){
        this.disableSave = true;
        //set spinner true
        this.isLoading = true;
        console.log('Insert Account');
        console.log('Selected DB' + JSON.stringify(this.selectedDnbAddress));
           //fire accountRecordId+name to account infor
        insertDnBAccount({jsonString : JSON.stringify(this.selectedDnbAddress)} )
        .then(result => {
            
            this.dbAccountId = result.Id;
            console.log('Account createed' + JSON.stringify(result));
            const selectedDnbAddress = new CustomEvent(
                "accountinfo",
                {
                    detail : { accountdb :result }
                }
            );
            this.dispatchEvent(selectedDnbAddress);
        })
        .catch(error => {
            this.isLoading = false;
            this.error = error;
            console.log('error' + error);
        });
        //this.getCorporateIntelInfor(this.dunNumb);
        //this.dispatchEvent(selectedRecordEvent);
        //this.navigateToQuoteView();
    }
    
    handleCancel(event){
        //this.navigateToQuoteView();
        this.dispatchEvent(new CustomEvent('canceldb'));
    }
    get isDisableSave(){
        if( !this.selectedDnbAddress || (this.isAqueous && !this.countryCodeD) || this.disableSave ){
            return true ;
        }else{
            return false;
        }
    }

    handleChangeCountry(event){
        if(event.target.name == 'countryCodeId'){
            this.countryCodeD = event.target.value;
            console.log(JSON.stringify(this.countryCodeD));
        }
    }
    handleLoadDnBData() {
        getDbBForQuoteProcess({searchString: this.inputValue,countryCode : this.countryCodeD})
            .then(data => {
                if(this.isDisableInput) return;
                console.log('Mydata' + JSON.stringify(data));
                if(data && data.length>0){
                    this.results = data;
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error;
            });
    }

    navigateToQuoteView(){
        let pageRef = {
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Quote',
                actionName: 'home'
            },
            state: {
            }
        };
        this[NavigationMixin.Navigate](pageRef);
        }

    searchHandler(event){
        this.inputValue = event.target.value;
        if(event && event.key === 'Enter') this.searchDnBData(); 
    }
    searchHandlerButton(event){
        if(event && event.target.label === 'Search')  this.searchDnBData(); 
    }

    searchDnBData(){
        if(this.isDisableInput) return;
        const comboBox = this.template.querySelector('lightning-combobox');
        if(this.inputValue.length >= 3){
            if(comboBox.checkValidity()){
                this.isLoading = true;
                this.handleLoadDnBData();
            }else{
                comboBox.reportValidity();
            }
        }else{
            comboBox.reportValidity();
            this.isLoading = false;
        }
    }
}