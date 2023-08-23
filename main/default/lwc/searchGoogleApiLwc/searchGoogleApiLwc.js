import {LightningElement, api, wire, track} from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import { NavigationMixin } from 'lightning/navigation';
import searchLocation from '@salesforce/apex/SearchAddressGoogleApiLwcController.searchLocation';
import searchPlace from '@salesforce/apex/SearchAddressGoogleApiLwcController.searchPlace';

import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SearchGoogleApiLwc extends LightningElement {

    @api label = 'Google Location';//Search label
    @api selectedOption;
    @api results;
    @api isLoading = false;
    @api inputValue ='';
    @api address ;
    @api selectedRecordA;
    @api isDisableInput = false;
    @api dunNumb;
    @api selectedDnbAddress;

    @api country = 'VN';
    @api state = 'HCM';
    @api city  = 'HCM';
    @api street = 'PVH';




    constructor() {
        super();
    }

    handleChangeInput(event) {
        if (event.target.name == 'searchKey') {
            this.inputValue = event.target.value;
        }
    }
    handleSearchLocation(event){
        console.log('Do Something');
    }

    handleNext(event){
        /*
        console.log('Insert Account');
        console.log('Selected DB' + JSON.stringify(this.selectedDnbAddress));
        //fire accountRecordId+name to account infor
        insertDnBAccount({jsonString : JSON.stringify(this.selectedDnbAddress)} )
            .then(result => {
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
                this.error = error;
                console.log('eeror' + JSON.stringify(error));
            }); */

    }

    handleCancel(event){
        //handle cancel
    }

    handleLoadDnBData() {
        searchLocation({searchTerm: this.inputValue})
            .then(data => {
                if(this.isDisableInput) return;
                console.log('Mydata' + JSON.stringify(data));
                if(data && data.predictions.length>0){
                    this.results = data.predictions;
                    console.log('Results ' + JSON.stringify(this.results));
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error;
            });
    }
    handleInitAddress(){
        const cityChange = new FlowAttributeChangeEvent('city', this.city);
        const countryChange = new FlowAttributeChangeEvent('country', this.country);
        const streetChange = new FlowAttributeChangeEvent('street', this.street);
        const stateChange = new FlowAttributeChangeEvent('state', this.state);
        this.dispatchEvent(cityChange);
        this.dispatchEvent(countryChange);
        this.dispatchEvent(streetChange);
        this.dispatchEvent(stateChange);

    }

    selectRecord(event){
        var placeId = event.currentTarget.getAttribute("data-value");
        searchPlace({placeId: placeId})
            .then(data => {
                console.log('Billing Address' + JSON.stringify(data));
                this.city = data.city;
                this.country = data.country;
                this.state = data.state;
                this.street= data.addressFull;
                this.handleInitAddress();
            })
            .catch(error => {
                this.error = error;
            });
    }
    searchHandler(event){
        if(this.isDisableInput) return;
        if(event.target.value.length>=2){
            this.isLoading = true;
            this.inputValue = event.target.value;
            console.log('Input Value ' + this.inputValue);
            this.handleLoadDnBData();
        }else{
            this.isLoading = false;
            this.inputValue = event.target.value;
        }

    }
}