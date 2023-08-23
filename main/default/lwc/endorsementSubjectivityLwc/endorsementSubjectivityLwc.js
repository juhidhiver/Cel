import {LightningElement, api, wire, track} from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import getProductName from '@salesforce/apex/subjectivityController.getProductName';
import checkIsExcess from '@salesforce/apex/subjectivityController.checkIsExcess';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class EndorsementSubjectivityLwc extends LightningElement {
    //Attributes
    @api isOpen = false;
    @api quoteId;
    @api quoteName;
    @api quoteStatus;
    @api isUpdated;
    @api isPrimaryQuote;
    @api isAqueousProduct;
    @api isReferredQuoteLocked;
    @api quoteType;
    hideSave = false;

    handleCancel() {

        console.log('@@@ quoteStatus ',this.quoteStatus);
        console.log('@@@ isUpdated ',this.isUpdated);

        this.isOpen = !this.isOpen;
        this.dispatchEvent(new CustomEvent('closeendorsement'));
        /*
        if(this.isUpdated == true){
            console.log('@@@ preparing update Quote status ...');
            const fields = {
                Id: this.quoteId,
                Status: 'In Progress'
            };
            updateRecord({ fields })
                .then((result) => {
                    console.log('@@@ updateQuotestatus:',JSON.stringify(result));
                     // handle cancel here
                    this.isOpen = !this.isOpen;
                    this.dispatchEvent(new CustomEvent('closeendorsement'));
                })
                .catch(error => {
                    console.log('Error updating record quote status :' + JSON.stringify(error));
                     // handle cancel here
                    this.isOpen = !this.isOpen;
                    this.dispatchEvent(new CustomEvent('closeendorsement'));
                });
            
        } else {
             // handle cancel here
            this.isOpen = !this.isOpen;
            this.dispatchEvent(new CustomEvent('closeendorsement'));
        }       
        */
    }

    @track isExcess;
    @track layer;

    connectedCallback(){
        console.log('@@@ quoteId',this.quoteId);        
        console.log('@@@ quoteStatus',this.quoteStatus);
        console.log('IS AQ??-->',this.isAqueousProduct)
        this.checkIsExcess();
       
    }

    get hideSaveButton(){
        return this.hideSave || this.boundDisabled;
    }

    get makeEndorsementTabUnEditable(){
        if(((this.quoteStatus == 'Referred' && this.isReferredQuoteLocked) || this.quoteStatus == 'Bound' || this.quoteStatus == 'Closed' || this.quoteType == 'Policy Duration Change') && this.productName == 'Professional Indemnity'){
            return true;
        }else {
            return false;
        }
    }

    checkIsExcess(){
        checkIsExcess({ quoteId: this.quoteId })
        .then((result) =>{
          if (result) {
            this.layer = result;
            if(this.layer == 'Excess'){
                this.isExcess = true;
            }
              console.log('layer: '+this.layer);
          }
        })
        .catch((error) => {
            console.log("checkIsExcess error:" + JSON.stringify(error));
        })     
    }
   
    @track productName='';
    @track isPI;
    @wire(getProductName, { quoteId: '$quoteId' })
    wiregetProductName({ error, data }) {
      if (data) {
          this.productName = data;
          if(this.productName == 'Professional Indemnity'){
              this.isPI = true;
              console.log('@@@isPI from endorsementSubject::'+this.isPI);
          }else{
            this.isPI = false;
          }
      } else {
        console.log("getProductName error:" + JSON.stringify(error));
      }
    }


    hanldeProgressValueChange(event){
        this.isUpdated = event.detail;
    }

    handleTabActive(event){
        this.hideSave = event.target.label === 'Subjectivities';
    }

    handleSave() {
        //this.template.querySelector('c-endorsement-tab-lwc').saveSelectedEndorsement();
        this.template.querySelector('c-endorsement-layout').saveSelectedEndorsement();
    }
    
    get boundDisabled(){
        return this.quoteStatus == 'Bound' ? true: false;
    }
}