import { LightningElement, api, track, wire  } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getMainColumns from '@salesforce/apex/QuoteComparisonResponseLwcController.getMainColumns';
import getMainTitles from '@salesforce/apex/QuoteComparisonResponseLwcController.getMainTitles';
import getRatingFromCallOut from '@salesforce/apex/RateController.getRatingFromCallOut';
import createInitQuote from '@salesforce/apex/QuoteComparisonResponseLwcController.createInitQuote';
import initValues from '@salesforce/apex/QuoteComparisonLWC.initValues';

const QUOTE_PROCESS_STATUS_UNDERWRITTING_ANALYSIS = 'Underwritting Analysis';

export default class QuoteComparisonMainLwc extends LightningElement {
    
    @api processRecordId;
    @api isSelectedTab;
    @api quoteLayer = '';
    @api quoteComingThroughEvent = false;
    @api selectedMasterBinder;
    @track quoteTemplates = [];
    @track listWrapper = [];
    @track listWrapper = [];
    @track mainColumnWrappers;
    @track mainTitleWrappers;
    @track isLoading = false;
    @track isPrimaryQuote = true;

    // @api quoteNames = [];
    // @api quoteIds = [];
    @api quoteProcessSubmissionId = '';
    initValuesListWrapper() {
        var obj = { property: "foo" };
    }
    connectedCallback(){
        if(this.isSelectedTab == 'pathAssistant_selectAClosedStepValue'){
            this.quoteComingThroughEvent = false;
        }
        console.log('SubmissionId' + this.quoteProcessSubmissionId);
        console.log("quoteComingThroughEvent connectedcallback-->",this.quoteComingThroughEvent);        
        let quoteTempalte = {};
        quoteTempalte.templateId = 1;
        quoteTempalte.templateName = 'Quote 1';
        this.quoteTemplates.push(quoteTempalte);
        this.listWrapper = [];
        this.listWrapper.push({quoteName : 'Quotest 1',retro : '2020-03-27',status: true , aggregateLimit : '$1M' ,retentionVal : 500, sublimitsAndEndorsements : 'No Sublimits'  });
        this.listWrapper.push({quoteName : 'Quotest 2',retro : '2020-04-27',status: false , aggregateLimit : '$2M' ,retentionVal : 600,  sublimitsAndEndorsements : 'No Sublimits'  });
        this.listWrapper.push({quoteName : 'Quotest 3',retro : '2020-05-27',status: true , aggregateLimit : '$3M' ,retentionVal : 700,  sublimitsAndEndorsements : 'No Sublimits'  });
        //this.handleInitValues();      
    }

    //test
    firstRenderer = false
    renderedCallback() {

        if (this.firstRenderer == false) {
            console.log('I am in rendered callback1');
            this.firstRenderer = true;
            //if (this.quoteCompareItems !== undefined) {
                /*if(this.quoteComingThroughEvent){
                    this.handleInitValues();
                }
                else{
                    this.initValueProcess('');
                }*/
                this.handleInitValues();
                //console.log('quoteCompareItems', JSON.parse(JSON.stringify(this.quoteCompareItems)));
                //this.boundRect = this.template.querySelector('[data-id="parentCompareItem"]').getBoundingClientRect();
                //console.log("BoundRect-Render->", JSON.stringify(this.boundRect));
               
            //}
        }
        //registerListener('refreshPageFromList', this.handleChange, this);
    }
    handleEditQuote(event){
        console.log('Get Quote Detail From Child');
        console.log('Event Detail ' + JSON.stringify(event.detail));
    }

    tabselect(evt) {
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
    }

    handleLoadedFirstBlock() {
        console.log("vao loaded first block");
        getMainTitles({'submissionId': this.quoteProcessSubmissionId, isPrimaryQuote: this.isPrimaryQuote})
        .then((result) => {
            if(result.isSuccess){
                console.log('@@@data1: ' + JSON.stringify(result.data));
                this.mainTitleWrappers = result.data.listRowTitles;
                this.mainColumnWrappers = result.data.compareItems;
                console.log('this.mainColumnWrappers........... ' + JSON.stringify(this.mainColumnWrappers));
                // getMainColumns({'rowValues': JSON.stringify(result.data)})
                // .then((result) => {
                //     if(result.isSuccess){
                //         console.log('@@@data: ' + JSON.stringify(result.data));
                //         this.mainColumnWrappers = result.data;
                //     }else{
                //         console.log('@@@error: ' + JSON.stringify(result.errors));
                //     }
                // })
                // .catch((error) => {
                //     console.log('@@@error: ' + JSON.stringify(error));
                //     //this.error = error;
                // })
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
    /*
    toggleModeEdit(evt){
        this.modeEdit = !this.modeEdit;
        if(this.modeEdit == true) {
            evt.target.classList.add('slds-is-selected');
        }else {
            evt.target.classList.remove('slds-is-selected');
        }
    } */

    handleAddNewQuote(event) {
        let quoteTempalte = {};
        quoteTempalte.templateId = (this.quoteTemplates.length + 1);
        quoteTempalte.templateName = 'Quote ' + (this.quoteTemplates.length + 1);
        this.quoteTemplates.push(quoteTempalte);
        this.listWrapper.push({quoteName : 'Quote ' + (this.listWrapper.length +1) ,retro : '2020-02-27',status: true ,retentionVal: 900,  aggregateLimit : '$3M' , sublimitsAndEndorsements : 'No Sublimits'  });

    }

    handleInitValues() {
        
        //handle create quote here
        console.log('First Init for all of quoteComaparisionMainLwc.handleInitValues');
        console.log("quoteLayer-->",this.quoteLayer);
        console.log("quoteComingThroughEvent-->",this.quoteComingThroughEvent);
        if(!this.quoteLayer){
            //this.showToast('Choose Quote Layer','Please choose a Quote Layer on Underwriting Analysis Tab','warning','dismissable');
           // this.quoteLayer = 'Primary';
            //this.handleChangeQuoteProcessStatus();
            //return;
        }
        //if(this.quoteLayer){
            this.isLoading = true;
            createInitQuote({opportunityId : this.quoteProcessSubmissionId,quoteLayer : this.quoteLayer,
            binderRecordObj : JSON.stringify(this.selectedMasterBinder), quoteComingThroughEvent : this.quoteComingThroughEvent})
            .then(response =>{
                console.log('Create Init Quote' + JSON.stringify(response));
               
                if(response.isSuccess){
                     // Added by Maeran on 1/10/21 for clearing the check of init creation of Quote on click of Compare & Rate time
                
                    this.dispatchEvent(new CustomEvent('resetquotecomingthrough')); 
                
                    var quoteId = response.data ;                    
                    getRatingFromCallOut({objId : quoteId }).then(response =>{
                        console.log('Rating First Time' + JSON.stringify(response));
                        
                        if(response.isSuccess) {
                            this.handleLoadedFirstBlock();
                            this.showToast('Success','Rating Successful!','success');
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
                        this.handleChangeQuoteProcessStatus();
                        return;
                    }else{
                        this.handleLoadedFirstBlock();
                    }
                }
                if(response.data)   this.quoteLayer = response.extraData;
                console.log('## quoteLayer',this.quoteLayer);
                console.log('## response.extraData',response.extraData);
                if(this.quoteLayer == 'Excess'){
                    this.template.querySelector('lightning-tabset').activeTabValue = 'false';
                }else{
                    this.template.querySelector('lightning-tabset').activeTabValue = 'true';
                }


                console.log('vinay reset quotecomingthroughevent: ' + this.quoteComingThroughEvent);
            }).catch(error =>{
                this.showToast('Error !',JSON.stringify(error),'error');
                this.quoteComingThroughEvent = false;
                console.log('vinay reset quotecomingthroughevent catch block: ' + this.quoteComingThroughEvent);
            });

        // }else{
        //     this.showToast('Error !','Error in creating Quote','error');
        //     console.log("Event in handling QuoteLayer-->",this.quoteLayer);
        // }
        this.quoteComingThroughEvent = false;
    }

    handleChangeQuoteProcessStatus() {
        var infos = {status : QUOTE_PROCESS_STATUS_UNDERWRITTING_ANALYSIS};
        const event = new CustomEvent('changequoteprocessstatus', {
            detail: infos
        });
        this.dispatchEvent(event);        
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

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    @api
    updateQuoteComparesionResponse(){
      var   isReadyToSave = false;  
        console.log('inside Compare and rate',JSON.stringify(this.template.querySelector("c-quote-comparison-response-lwc"))); 
        if(this.template.querySelector("c-quote-comparison-response-lwc")!= null){
            this.isReadyToSave = this.template.querySelector("c-quote-comparison-response-lwc").updateQuoteComparesionItemResponse();
            }
            return this.isReadyToSave;
    }
    // handleEditQuoteName(event) {
    //     let quoteName = event.detail.quoteName;
    //     let quoteId = event.detail.quoteId;
    //     for(let i = 0; i < this.quoteIds.length; i++) {
    //         if(this.quoteIds[i] === quoteId) {
    //             this.quoteNames[i] = quoteName;
    //             console.log("changing name");
    //         }
    //     }
    // }
    // handleSetQuoteIdAndName(event) {
    //     var ids = event.detail.quoteIds;
    //     var names = event.detail.quoteNames;
    //     this.quoteIds = ids;
    //     this.quoteNames = names;
    // }
}