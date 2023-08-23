import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import CUSTOM_CSS from '@salesforce/resourceUrl/CustomStyle';
import { loadStyle } from 'lightning/platformResourceLoader';



export default class AutoRenewalsDetailLwc extends LightningElement {

    @api renewalRecordClicked;
    @api sectionList;
    @api sectionSettings;
    @track mainActiveSections;
    @api searchingFilterValues;
    renewalRecordIdClicked;
    renewalStatus;
    isRenewalExpired;
    isContactManagement;
    //@track SelectedBroker = 'a082500000Jn0ALAAZ';

    connectedCallback(){       

        loadStyle(this, CUSTOM_CSS)
        .then(() => {
            console.log('Files loaded');
        })
        .catch(error => {
            console.log( error.body.message );
       });

       this.renewalRecordClicked = JSON.parse(JSON.stringify(this.renewalRecordClicked ));
       this.renewalRecordIdClicked = this.renewalRecordClicked.Id;
       this.renewalStatus = this.renewalRecordClicked.Status__c;
       if(this.renewalRecordClicked.Status__c == 'Expired'){
            this.isRenewalExpired = true;
       }
       else{
        this.isRenewalExpired = false;
       }
       console.log('this.renewalRecordClicked'+JSON.stringify(this.renewalRecordClicked));

       console.log("this.sectionList2"+JSON.stringify(this.sectionList))
       this.sectionList = JSON.parse(JSON.stringify(this.sectionSettings.allSections));
       this.mainActiveSections = JSON.parse(JSON.stringify(this.sectionSettings.activeSections));
        for(var i=0; i<this.sectionList.length; i++){
            for(var j=0; j<this.sectionList[i].mainSectionFields.length; j++){
                if(this.sectionList[i].mainSectionFields[j].format == 'Lookup'){
                    this.sectionList[i].mainSectionFields[j]['isCustomLookup'] = true;
                }
                else{
                    this.sectionList[i].mainSectionFields[j]['isCustomLookup'] = false;
                }
                if(this.sectionList[i].mainSectionFields[j].sourceFieldApi == 'Documents_Required__c'
                    || this.sectionList[i].mainSectionFields[j].sourceFieldApi == 'Additional_Information__c'){
                    this.sectionList[i].mainSectionFields[j]['fullWidth'] = true;
                }
                else{
                    this.sectionList[i].mainSectionFields[j]['fullWidth'] = false;
                }
                if(this.sectionList[i].mainSectionFields[j].sourceFieldApi == 'Broker__c'){
                    this.sectionList[i].mainSectionFields[j]['fieldValue'] = this.renewalRecordClicked.BrokerName;
                    this.sectionList[i].mainSectionFields[j]['navigationURL'] = this.renewalRecordClicked.BrokerURL;
                }
                else if(this.sectionList[i].mainSectionFields[j].sourceFieldApi == 'Policy__c'){
                    this.sectionList[i].mainSectionFields[j]['fieldValue'] = this.renewalRecordClicked.PolicyNum;
                    this.sectionList[i].mainSectionFields[j]['navigationURL'] = this.renewalRecordClicked.PolicyURL;
                }
                else if(this.sectionList[i].mainSectionFields[j].sourceFieldApi == 'Insured_Account__c'){
                    this.sectionList[i].mainSectionFields[j]['fieldValue'] = this.renewalRecordClicked.InsuredName;
                    this.sectionList[i].mainSectionFields[j]['navigationURL'] = this.renewalRecordClicked.InsuredAccURL;
                }
            }
        }
       // this.sectionList = this.sectionList;

    /*    getListSectionSetting({ productName: 'Professional Indemnity' })
        .then((result) => {
            console.log('@@@data1: ' + JSON.stringify(result));
           
            
            //this.handleData(result);
        })
        .catch((error) => {
            console.log('@@@error1: ' + JSON.stringify(error));
        })*/
    }

    handelInputChange(event){
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );        
        console.log('events fire ' , event.target.fieldName , event.target.value);
        
            if(event.target.fieldName == 'Payment_Warning__c' && event.target.value == true ){
                console.log('test payment ' );
                for( var j=0; j<inputFields.length; j++){ 
                    if(inputFields[j].fieldName == 'Broker_Warning__c'){
                        if(!inputFields[j].value ){
                            console.log('test broker');
                            inputFields[j].value = 'This risk has outstanding payments which will need to be paid in order for us to renew. Please provide evidence of this with the renewal submission.';
                        }  
                    }
                }
            }
                
    }

    handleBack(){
        this.renewalRecordClicked = undefined;
        let showRenewalMainPage = new CustomEvent('showrenewalmainpage');
        this.dispatchEvent(showRenewalMainPage);
        const selectedEvent2 = new CustomEvent("getsearchingvalues", {
            detail: this.searchingFilterValues
          });
        this.dispatchEvent(selectedEvent2);
    }

    handelContactManagement(){
        if(!this.renewalRecordClicked.Broker__r){
            const event = new ShowToastEvent({
                title: 'Error!',
                message: 'Cannot access Contact Management since there is no Broker Account on this record.',
                variant : 'error'
            });
            this.dispatchEvent(event); 
        } 
        else{        
            this.isContactManagement = true;
        }
    }

    handelCloseFromChild(){
        this.isContactManagement = false;
    }

    handleSuccess() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success!',
                message: 'Changes have been saved successfully.',
                variant: 'Success'
            })
        );
    }
}