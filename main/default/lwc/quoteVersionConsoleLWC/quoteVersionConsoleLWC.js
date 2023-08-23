import { LightningElement, api, track, wire  } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getMainColumns from '@salesforce/apex/QuoteComparisonResponseLwcController.getMainColumns';
import getMainTitles from '@salesforce/apex/QuoteComparisonResponseLwcController.getMainTitles';
import getRatingFromCallOut from '@salesforce/apex/RateController.getRatingFromCallOut';
import createInitQuote from '@salesforce/apex/QuoteComparisonResponseLwcController.createInitQuote';
import initValues from '@salesforce/apex/QuoteComparisonLWC.initValues';

export default class QuoteVersionConsoleLWC extends LightningElement {

    @api quoteProcessSubmissionId = '';
    @api quoteLayer;
    @api selectedMasterBinder;
    @api quoteComingThroughEvent;
    @api isLoading = false;
    @track mainColumnWrappers;
    @track mainTitleWrappers;
    @api isPrimaryQuote = false;
    @api showQuoteDetail = false;

 /*   tabselect(evt) {
        console.log('I am In tabselect');
        this.isPrimaryQuote =  evt.target.value;
        this.template.querySelectorAll('c-quote-comparison-response-lwc')
        .forEach(element => {
            if(element.isPrimaryQuote == this.isPrimaryQuote){
                console.log('element.isPrimaryQuote -- ',element.isPrimaryQuote);
                element.reloadData();
                //element.handleStyleFix();
                //element.initValueProcess();
            }
        });
    }   */

    connectedCallback(){
        console.log('quoteProcessSubmissionId'+this.quoteProcessSubmissionId);
        this.handleInitValues();      
    }

    handleInitValues() {
        
        //handle create quote here
        console.log('First Init for all of quoteComaparisionMainLwc.handleInitValues');
        
        this.isLoading = true;
        createInitQuote({opportunityId : this.quoteProcessSubmissionId,quoteLayer : this.quoteLayer,
        binderRecordObj : JSON.stringify(this.selectedMasterBinder), quoteComingThroughEvent : this.quoteComingThroughEvent})
        .then(response =>{
            console.log('Create Init Quote' + JSON.stringify(response));
            
            if(response.isSuccess){
                var quoteId = response.data ;                    
                getRatingFromCallOut({objId : quoteId }).then(response =>{
                    console.log('Rating First Time' + JSON.stringify(response));
                    
                    if(response.isSuccess) {
                        this.handleLoadedFirstBlock();
                        this.showToast('Success !','Rate Successfully','success');
                    }else{
                        this.handleLoadedFirstBlock();
                        this.showToast('Fail !','Rate Fail','error');
                    }
                    }).catch(error =>{
                    this.showToast('Error !',JSON.stringify(error),'error');
                });
            }else {
                if(response.data == this.quoteProcessSubmissionId){
                    this.showToast('Choose Quote Layer','Please choose a Quote Layer on Underwriting Analysis Tab','warning','dismissable');
                    //this.handleChangeQuoteProcessStatus();
                    return;
                }else{
                    this.handleLoadedFirstBlock();
                }
            }
            if(response.data)   this.quoteLayer = response.extraData;
            console.log('## quoteLayer',this.quoteLayer);
            console.log('## response.extraData',response.extraData);
            //this.template.querySelector('c-quote-version-console-detail-lwc').isPrimaryQuote = 'false';
            if(this.quoteLayer == 'Excess'){
                this.template.querySelector('lightning-tabset').activeTabValue = 'false';
            }else{
                this.template.querySelector('lightning-tabset').activeTabValue = 'true';
            }
            this.isLoading = false;
        }).catch(error =>{
            this.showToast('Error !',JSON.stringify(error),'error');

        });
        
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handleLoadedFirstBlock() {
        console.log("vao loaded first block");
        getMainTitles({'submissionId': this.quoteProcessSubmissionId, isPrimaryQuote: this.isPrimaryQuote})
        .then((result) => {
            if(result.isSuccess){
                console.log('@@@data1: ' + JSON.stringify(result.data));
                this.mainTitleWrappers = result.data.listRowTitles;
                this.mainColumnWrappers = result.data.compareItems;
                this.isLoading = false;
            }else{
                console.log('@@@error1: ' + JSON.stringify(result.errors));
            }
        })
        .catch((error) => {
            console.log('@@@error1: ' + JSON.stringify(error));
            //this.error = error;
        })
    }

    handleNavigateTab(event){
        if(event.detail){
            if(event.detail == 'Primary'){
                this.template.querySelector('lightning-tabset').activeTabValue = 'true';
            }else{
                this.template.querySelector('lightning-tabset').activeTabValue = 'false';
            }
        }                
    }

}