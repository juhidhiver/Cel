import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import initValues from '@salesforce/apex/QuoteComparisonLWC.initValues';
import updateQuote from '@salesforce/apex/QuoteComparisonLWC.updateQuote';
import insertNewVersion from '@salesforce/apex/QuoteVersionController.insertNewVersion';
import createInitQuote from '@salesforce/apex/QuoteComparisonResponseLwcController.createInitQuote';
import getRatingFromCallOut from '@salesforce/apex/RateController.getRatingFromCallOut';

import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';

// import updateCompareObject from '@salesforce/apex/SectionSettingWrapper.updateCompareObject';
import updateCompareItem from '@salesforce/apex/QuoteCompareItemWrapper.updateCompareItem'
//import updateQuoteName from '@salesforce/apex/SectionSettingWrapper.updateQuoteName';
import deleteQuoteHandler from '@salesforce/apex/QuoteCompareItemWrapper.deleteQuoteHandler'
import createNewQuoteHandler from '@salesforce/apex/QuoteCompareItemWrapper.createNewQuoteHandler'
import createQuoteCompareItem from '@salesforce/apex/QuoteCompareItemWrapper.createQuoteCompareItem'
import cloneQuoteHandler from '@salesforce/apex/QuoteCompareItemWrapper.cloneQuoteHandler'
import { fireEvent, registerListener, unregisterAllListeners} from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import { updateRecord } from 'lightning/uiRecordApi';

export default class QuoteComparisonListLwc extends LightningElement {
    @api processRecordId ;
    @track listWrapper = [];
    @track quoteCompareWrapper = [];
    //
    @api childIds = [];
    @api childNames = [];
    @api quoteProcessSubmissionId = '';
    @track quoteCompareItems = []; 
    quoteCompareItemZero;
    @wire(CurrentPageReference) pageRef;
    @track isLoading = false;
    // @wire(CurrentPageReference) wiredPageRef (pageRef) {
    //     this.pageRef = pageRef;
    //     if(this.pageRef) registerListener('editQuoteName', this.handleEditQuoteName, this);
    //   }

    connectedCallback() {
        this.handleInitValues();
        registerListener('deleteQuoteFromResponse', this.handleDeleteQuoteEvent, this);
        registerListener('addNewCompareItemFromResponse', this.handleAddNewCompareItem, this);
        registerListener('refreshCompareItemFromResponse', this.handleRefreshCompareItem, this);
        registerListener('saveCompareItemFromResponse', this.handleEditQuote, this);
    }

    renderedCallback() {

        // this.styleFixedHeader();
        // window.addEventListener('resize',this.refreshRender.bind(this));
    }

    refreshRender(){
        var valueParent = this.template.querySelector(`[data-id="value-parent1"]`);
        var valueContainer = this.template.querySelector(`[data-id="value-container1"]`);
        var valueChild = this.template.querySelectorAll(`[data-id="value-child1"]`);
        var sticky = valueContainer.getBoundingClientRect();
        const parentWidth  = valueParent.getBoundingClientRect().width;
        if (window.pageYOffset + sticky.height >= 1340) {
            valueContainer.classList.add("value-sticky");
            valueChild.forEach(child => child.setAttribute('style',`width: ${parentWidth}px !important`));
        } else {
            valueContainer.classList.remove("value-sticky");
            valueChild.forEach(child => child.removeAttribute('style'));
        }
        var compareItem = this.template.querySelectorAll(`[data-id="compareItem"]`);
        var quoteComare = this.template.querySelectorAll(`c-quote-compare-item-lwc`);
        var parentCompareItem = this.template.querySelectorAll(`[data-id="parentCompareItem"]`);

        const parentRight = parentCompareItem.getBoundingClientRect().right;
        
        // console.log('sticky',JSON.stringify(sticky));
        compareItem.forEach((item,idx) => {
            var left = item.getBoundingClientRect().left;
            quoteComare[idx].resizeHeaderStyle(left); 
            if(left <= 85 || (left >= parentRight)){
                item.setAttribute('style', 'visibility: hidden');
            }else {
                item.removeAttribute('style');
            }
        });
    }

    // styleFixedHeader(){
    //     var valueParent = this.template.querySelector(`[data-id="value-parent1"]`);
    //     var valueContainer = this.template.querySelector(`[data-id="value-container1"]`);
    //     var valueChild = this.template.querySelectorAll(`[data-id="value-child1"]`);
    //     var sticky = valueContainer.getBoundingClientRect();
        
    //     window.addEventListener('scroll', function() {
    //         // console.log("window.pageYOffset", window)
    //         const parentWidth  = valueParent.getBoundingClientRect().width;
    //         if (window.pageYOffset + sticky.height >= 1340) {
    //             valueContainer.classList.add("value-sticky");
    //             valueChild.forEach(child => child.setAttribute('style',`width: ${parentWidth}px !important`));
    //         } else {
    //             valueContainer.classList.remove("value-sticky");
    //             valueChild.forEach(child => child.removeAttribute('style'));
    //         }
    //     });
    //     this.scrollStyle();
    // }

    handleScroll(){
        // this.scrollStyle();
    }

    // scrollStyle(){
    //     var compareItem = this.template.querySelectorAll(`[data-id="compareItem"]`);
    //     var quoteComare = this.template.querySelectorAll(`c-quote-compare-item-lwc`);
    //     var parentCompareItem = this.template.querySelector(`[data-id="parentCompareItem"]`);

    //     const parentRight = parentCompareItem.getBoundingClientRect().right;
        
    //     // console.log('sticky',JSON.stringify(sticky));
    //     compareItem.forEach((item,idx) => {
    //         var left = item.getBoundingClientRect().left;
    //         var width = item.getBoundingClientRect().width;  
    //         quoteComare[idx].setLeftPosition(left); 
    //         if(left <= 85 || left >= parentRight){
    //             item.setAttribute('style', 'visibility: hidden');
    //         }else {
    //             item.removeAttribute('style');
    //         }
    //     });
    // }


    // @wire(initValues,{})
    // wireRecordType({error,data}) {
    //     if (data) {
    //         this.quoteCompareWrapper = data;
    //     } else {
    //         console.log('error ' + error);
    //     }
    // }
    handleInitValues() {
        //handle create quote here
        console.log('First Init for all');
        createInitQuote({opportunityId : this.quoteProcessSubmissionId}).then(response =>{
            console.log('Create Init Quote' + JSON.stringify(response));
            if(response.isSuccess){
                var quoteId = response.data ;
                getRatingFromCallOut({objId : quoteId }).then(response =>{
                    console.log('Rating First Time' + JSON.stringify(response));
                    if(response.isSuccess) {
                        this.showToast('Success','Rating Successful!','success');
                        this.initValueProcess();
                    }else{
                        this.showToast('Fail !','Rate Fail','error');
                        this.initValueProcess();
                    }
                    }).catch(error =>{
                    this.showToast('Error !',JSON.stringify(error),'error');
                   });
            }else{
                this.initValueProcess();
            }
        }).catch(error =>{
            this.showToast('Error !',JSON.stringify(error),'error');

        });

    } 

    initValueProcess(){
        initValues({ 'submissionId': this.quoteProcessSubmissionId })
            .then((data) => {
                console.log('Init Data ' +JSON.stringify(data));
                this.quoteCompareWrapper = data;
                this.childIds = data.childIds;
                this.childNames = data.childNames;
                let cloneParent = JSON.parse(JSON.stringify(data.parents));
                cloneParent.forEach(parent => {
                    parent.title = parent.name;
                    parent.childs.forEach(child => {
                        child.title = child.name;
                        if(child.fieldObject == "Rating_Modifier_Factor__c") {
                            child.title += " (" + child.min + ' - ' + child.max + ")";
                        }
                    })
                })
                this.quoteCompareWrapper.parents = cloneParent;
                // var temp = {name : 'Quote 1', data : this.quoteCompareWrapper, versions : []};
                // this.listWrapper.push(temp);
                // temp = {name : 'Quote 2', data : this.quoteCompareWrapper, versions : []};
                // this.listWrapper.push(temp);
                // temp = {name : 'Quote 3', data : this.quoteCompareWrapper, versions : []};
                // this.listWrapper.push(temp);
                let clone = JSON.parse(JSON.stringify(data.quoteCompareItems));

                for(let i = 0; i < clone.length; i++) {
                    for(let j = 0; j < clone[i].quoteFields.length; j++)
                        clone[i].quoteFields[j].index = j;
                }
                this.quoteCompareItems = clone;
                if(clone.length>0){
                    let temp = JSON.parse(JSON.stringify(clone[0]));
                    //quoteVersion cannot be deserialized in Apex so it will cause error when create new QuoteCompareItem
                    temp.quoteVersions = [];
                    this.quoteCompareItemZero = temp;
                }


                if(this.childIds.length > 0) {
                    // console.log("Children Id length: " + this.childIds.length + " - " + this.childIds);
                    // for (let i = 0; i < this.childNames.length; i++) {
                    //      let temp = { id: this.childIds[i], name: this.childNames[i], data: this.quoteCompareWrapper, versions: [] }
                    //     //let temp = {id: data.quoteCompareItems[i].quoteId, name: data.quoteCompareItem[i].quoteName, data: data.quoteCompareItems[i]};
                    //     this.listWrapper.push(temp);
                    // }

                    // console.log("Child Name length:" + data.childNames.length + " - " + data.childNames);
                }
               /* else {
                    this.showToast("Error", 'This Opportunity is not qualified to build a quote. Please qualify the Opportunity.', 'Error');
                } */

                // for(let i = 0; i < data.quoteCompareItems.length; i++)
                //     console.log("Quote compare Item " + i + " : " + JSON.stringify(data.quoteCompareItems[i]));
                const loadedFirstBlock = new CustomEvent('loadedfirstblock');
                this.dispatchEvent(loadedFirstBlock);
            })
            .catch((error) => {
                console.log('@@@error: ' + JSON.stringify(error));
            })
    }
    handleEditQuote(event) {
        console.log('Quote Name:' + event.detail.quoteName + ' Get Quote Detail From Child 22: ' + JSON.stringify(event.detail.data));
        var jsonWrapper = JSON.stringify(event.detail.data);
        /*
        insertNewVersion({ param1: jsonWrapper, param2: '' })
            .then((result) => {

            })
            .catch((error) => {
                console.log('@@@error: ' + error);
            }); */

        console.log('New Data Map' + jsonWrapper);
        var quoteName = event.detail.quoteName;//JSON.stringify(event.detail.quoteName);
        var quoteId = event.detail.quoteId;
        var quoteVerId = event.detail.quoteVerId;
        var isRate = event.detail.isRate;

        updateQuote({ jsonWrapper: jsonWrapper, quoteName: quoteName })
            .then((result) => {
                // var childItem = this.template.querySelector(`[data-id="${quoteId}"]`);
                // if(isRate == true){
                //     childItem.rateQuote();
                // }
                
        //         console.log('childItem',JSON.stringify(childItem.quoteName)); // .rating child


                // for (var i = 0; i < this.listWrapper.length; i++) {
                //     //if(this.listWrapper[i].name.trim() === quoteName.trim()) {
                //     // if (this.listWrapper[i].id === quoteId) {
                //     //     console.log('222222222222222222222222');
                //     //     var versions = 'Version ' + (this.listWrapper[i].versions.length + 1);
                //     //     this.listWrapper[i].versions.push(versions);
                //     //     this.listWrapper[i].data = event.detail.data;

                //     //     if (this.listWrapper[i].name !== quoteName) {
                //     //         updateQuoteName({ quoteId: quoteId, quoteName: quoteName });  
                //     //         let detail = { quoteId: quoteId, quoteName: quoteName }
                //     //         if (!this.pageRef) {
                //     //             this.pageRef = {};
                //     //             this.pageRef.attributes = {};
                //     //             this.pageRef.attributes.LightningApp = "LightningApp";
                //     //         }
                //     //         fireEvent(this.pageRef, 'editQuoteName', detail);                                                    
                //     //     }
                //     // }
                    
                //     //new
                //     // if(this.quoteCompareItems[i].quoteId === quoteId) {
                //     //     this.quoteCompareItems[i] = event.detail.data;
                //     //     if (this.quoteCompareItems[i].quoteName !== quoteName) {
                //     //         updateQuoteName({ quoteId: quoteId, quoteName: quoteName });  
                //     //         let detail = { quoteId: quoteId, quoteName: quoteName }
                //     //         if (!this.pageRef) {
                //     //             this.pageRef = {};
                //     //             this.pageRef.attributes = {};
                //     //             this.pageRef.attributes.LightningApp = "LightningApp";
                //     //         }
                //     //         fireEvent(this.pageRef, 'editQuoteName', detail);                                                    
                //     //     }
                //     // }

                // }            

                // console.log('final result 1:' + JSON.stringify(this.listWrapper));
                // this.showToast("Success", "Update records successfully!", "success");
            })
                .catch((error) => {
            console.log('@@@error: ' + error);
        });
        
        let updateObjects = {listUpdate: []};
        let updateData;

        if(event.detail.fromResponse == true){
            const child = this.template.querySelector(`[data-id="${quoteId}"]`);
            updateData = JSON.parse(JSON.stringify(child.compareItem));
        }else{
            updateData = JSON.parse(JSON.stringify(event.detail.data));
        }


        var isCreateQuoteVer = false;
        
        if(quoteVerId != ''){
            var selectedQuoteVer = null; 
            //var compareItem = JSON.parse(JSON.stringify(event.detail.data));
            updateData.quoteVersions.forEach(quoteVer => {
                if(quoteVer.Id === quoteVerId ){
                    selectedQuoteVer = JSON.parse(JSON.stringify(quoteVer));
                }
            });
            let quoteVerFieldIdValueMap = {};
            if(selectedQuoteVer != null){
                selectedQuoteVer.Quote_Version_Items__r.forEach(quoteVerItem => {
                    quoteVerFieldIdValueMap[quoteVerItem.Object_Id__c] = quoteVerItem.Value__c;
                });
            }

            updateData.quoteFields.forEach(quoteField => {
                selectedQuoteVer.Quote_Version_Items__r.forEach(quoteVerItem => {
                    if(quoteField.fieldId === quoteVerItem.Object_Id__c 
                    && quoteField.value !== quoteVerItem.Value__c){
                        isCreateQuoteVer = true;
                        quoteVerItem.Value__c = quoteField.value;
                    }
                });
            });
            var quoteVerItemsUpdate = selectedQuoteVer.Quote_Version_Items__r;
            // console.log("@@@quoteVerItemsUpdate: " + JSON.stringify(quoteVerItemsUpdate));
            // console.log("@@@selectedQuoteVer: " + JSON.stringify(selectedQuoteVer));
        }
        var quoteCompareItemUpdate = updateData.quoteFields;
        for(let i = 0; i < this.quoteCompareItems.length; i++) {
            if(this.quoteCompareItems[i].quoteId === quoteId) {
                for(let k = 0; k < this.quoteCompareItems[i].quoteFields.length; k++) {
                    if(this.quoteCompareItems[i].quoteFields[k].isField == true) {
                        if(this.quoteCompareItems[i].quoteFields[k].value != updateData.quoteFields[k].value) {
                            let upObj = {
                                id: updateData.quoteFields[k].fieldId,
                                name: updateData.quoteFields[k].fieldName,
                                sourceObject: updateData.quoteFields[k].sourceObject,
                                fieldApi: updateData.quoteFields[k].sourceFieldAPI,
                                value: updateData.quoteFields[k].value
                            };
                            updateObjects.listUpdate.push(upObj);
                        }
                    }
                }
                break;
            }
        }
        console.log("List update object: " + JSON.stringify(quoteCompareItemUpdate));
        if(updateObjects.listUpdate.length > 0){
            //updateCompareObject({updateObj : JSON.stringify(updateObjects)});
            updateCompareItem({updateObj : JSON.stringify(updateObjects), 
                                quoteId : quoteId,
                                quoteCompareItemUpdate : quoteCompareItemUpdate!== null ? JSON.stringify(quoteCompareItemUpdate) : '',
                                quoteVerItemsUpdate : isCreateQuoteVer ? quoteVerItemsUpdate : null})
            .then(result => {
                console.log('@@@result: ' + JSON.stringify(result));
                if(result.isSuccess){
                    // var quoteCompareItemClone = this.quoteCompareItems;
                    // quoteCompareItemClone.forEach(quoteCompareItem => {
                    //     if(quoteCompareItem.quoteId === quoteId){
                    //         console.log('@@@result yes: ');
                    //         quoteCompareItem.quoteVersions = result.data;
                    //     }
                    // });
                    // this.quoteCompareItems = quoteCompareItemClone;
                    if(event.detail.fromResponse == false){
                        if (!this.pageRef) {
                            this.pageRef = {};
                            this.pageRef.attributes = {};
                            this.pageRef.attributes.LightningApp = "LightningApp";
                        }
                        let eventTemp = event;
                        // eventTemp.detail.fromResponse = true;
                        fireEvent(this.pageRef, 'saveCompareItemFromList', eventTemp);
                    }else{
                        if(isRate == true){ // rate or save for response item Duc - 8/6/2020
                            var childItem = this.template.querySelector(`[data-id="${quoteId}"]`);
                            childItem.rateQuote();                      
                        }else{
                            let eventTemp = event;
                            eventTemp.detail.quoteId = quoteId;
                            this.handleRefreshQuote(eventTemp);
                            this.showToast("Success", "Update records successfully!", "success");
                        }
                    }
                   
                }else{
                    console.log("@@@error: " + JSON.stringify(result.errors));
                    this.showToast("Error", result.errors[0], "error");
                }
            })
            .catch((error) => {
                console.log("@@@error: " + JSON.stringify(error));
            });
        } else {
            if(event.detail.fromResponse == false){
                if (!this.pageRef) {
                    this.pageRef = {};
                    this.pageRef.attributes = {};
                    this.pageRef.attributes.LightningApp = "LightningApp";
                }
                let eventTemp = event;
                // eventTemp.detail.fromResponse = true;
                fireEvent(this.pageRef, 'saveCompareItemFromList', eventTemp);
            }else if(isRate == true){ // rate or save for response item Duc - 8/6/2020
                var childItem = this.template.querySelector(`[data-id="${quoteId}"]`);
                childItem.rateQuote();                      
            }
        }
    }

    handleAddNewQuote(event) {
        // var temp = { name: 'Quote ' + (this.listWrapper.length + 1), data: this.quoteCompareWrapper, versions: [] };
        // this.listWrapper.push(temp);
        // //this.listWrapper.push({quoteName : 'Quote ' + (this.listWrapper.length +1) ,retro : '2020-02-27',status: true ,retentionVal: 900,  aggregateLimit : '$3M' , sublimitsAndEndorsements : 'No Sublimits'  });
        if(this.isLoading === false) {    
            this.isLoading = true;
            createNewQuoteHandler({submissionId : this.quoteProcessSubmissionId, quoteNumber : this.quoteCompareItems.length})
            .then(response => { 
                if(response.isSuccess) {
                    let quoteId = response.data.Id;
                    getRatingFromCallOut({objId : quoteId}).then(response =>{
                        if(response.isSuccess){
                            //rate success
                            this.createNewQuoteCompareItem(quoteId);
                            this.showToast('Success', 'Rating successful!', 'success');
                        }else{
                            //rate fail
                            this.createNewQuoteCompareItem(quoteId);
                            this.showToast('Error', response.errors[0], 'error');
                        }
                    }).catch((error) =>{
                        //fail on lwc
                        this.showToast('Error', JSON.stringify(error), 'error');
                    });
                } else {
                    this.showToast('Error', response.errors[0], 'error');
                    this.isLoading = false;
                }
            }).catch((error) => {
                this.showToast('Error', JSON.stringify(error), 'error');
                this.isLoading = false;
            });
        }
        
    }

    createNewQuoteCompareItem(quoteId){
        let detail = { quoteId: quoteId}
        if (!this.pageRef) {
            this.pageRef = {};
            this.pageRef.attributes = {};
            this.pageRef.attributes.LightningApp = "LightningApp";
        }
        fireEvent(this.pageRef, 'addNewCompareItemFromList', detail);
        createQuoteCompareItem({newQuoteId : quoteId, compareItemString :  JSON.stringify(this.quoteCompareItemZero)})
            .then(newCompareItem => {
                let temp = JSON.parse(JSON.stringify(newCompareItem));
                let clone = JSON.parse(JSON.stringify(this.quoteCompareItems));
                clone.push(temp);
                this.quoteCompareItems = clone;
                this.isLoading = false;
            }).catch((error) => {
            this.showToast('Error', JSON.stringify(error), 'error');
            this.isLoading = false;
        })
    }
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handleDeleteQuote(event) {
        let quoteId = event.detail.quoteId;
        let closeReason = event.detail.closeReason;
        let clone = [];
        
        this.quoteCompareItems = this.quoteCompareItems.filter(item => item.quoteId !== quoteId);
        // deleteQuoteHandler({quoteId: quoteId}); 
        const fields = {
            Id: quoteId,
            Status: 'Closed',
            Closed_Reason__c: closeReason
        };
        updateRecord({ fields })
                .then((result) => {
                    console.log('handleDeleteQuote:' , JSON.stringify(result));
                })
                .catch(error => {
                    console.log('Error updating record quote status :' + JSON.stringify(error));
                });
        let detail = {quoteId: quoteId}
        if (!this.pageRef) {
            this.pageRef = {};
            this.pageRef.attributes = {};
            this.pageRef.attributes.LightningApp = "LightningApp";
        }
        fireEvent(this.pageRef, 'deleteQuoteFromList', detail);
    }

    handleDeleteQuoteEvent(event) {
        let quoteId = event.quoteId;       
        this.quoteCompareItems = this.quoteCompareItems.filter(item => item.quoteId !== quoteId);
    }

    handleRefreshCompareItem(event) {
        let quoteId = event.quoteId;
        createQuoteCompareItem({newQuoteId : quoteId, compareItemString :  JSON.stringify(this.quoteCompareItemZero)})
        .then(compareItem => {
            let temp = JSON.parse(JSON.stringify(compareItem));
            let clone =  JSON.parse(JSON.stringify(this.quoteCompareItems));
            for(let i = 0; i < clone.length; i++) 
                if(clone[i].quoteId === quoteId)
                    clone[i] = temp;
            this.quoteCompareItems = clone;
            var childItem = this.template.querySelector(`[data-id="${quoteId}"]`);
            childItem.isLoading = false; 
        }).catch((error) => {
            this.showToast('Error', JSON.stringify(error), 'error');
        });;
    }

    handleSelectVersion(event){
        var versionId = event.detail.versionId;
        var compareItem = JSON.parse(JSON.stringify(event.detail.data));
        var selectedQuoteVer = null; 
        compareItem.quoteVersions.forEach(quoteVer => {
            if(quoteVer.Id === versionId ){
                selectedQuoteVer = JSON.parse(JSON.stringify(quoteVer));
            }
        });
        console.log("@@@selectedQuoteVer 1: " + JSON.stringify(selectedQuoteVer));
        let quoteVerFieldIdValueMap = {};
        if(selectedQuoteVer != null){
            selectedQuoteVer.Quote_Version_Items__r.forEach(quoteVerItem => {
                quoteVerFieldIdValueMap[quoteVerItem.Object_Id__c] = quoteVerItem.Value__c;
            });
        }
        console.log("@@@quoteVerFieldIdValueMap: " + quoteVerFieldIdValueMap);
        for(let i = 0; i < this.quoteCompareItems.length; i++) {
            if(this.quoteCompareItems[i].quoteId === selectedQuoteVer.Quote__c) {
                for(let k = 0; k < this.quoteCompareItems[i].quoteFields.length; k++) {
                    if(quoteVerFieldIdValueMap[this.quoteCompareItems[i].quoteFields[k].fieldId] !== null 
                        && quoteVerFieldIdValueMap[this.quoteCompareItems[i].quoteFields[k].fieldId] !== undefined){
                            console.log("@@@selectedQuoteVer yes: " );
                            this.quoteCompareItems[i].quoteFields[k].value = quoteVerFieldIdValueMap[this.quoteCompareItems[i].quoteFields[k].fieldId];
                        }
                    }
                    break;
                }
            }
        
        var quoteCompareItemsClone = JSON.parse(JSON.stringify(this.quoteCompareItems));
        this.quoteCompareItems = quoteCompareItemsClone;
    }

    handleCloneQuote(event) {
        if(this.isLoading === false) {    
            this.isLoading = true;
            let selectedQuote = event.detail.quoteId;
            cloneQuoteHandler({quoteId : selectedQuote})
            .then(response => {
                if(response.isSuccess == false) {
                    this.showToast("Error", response.errors[0], 'Error');
                    this.isLoading = false;
                }
                else {
                    let quoteId = response.data.Id;
                    this.createCompareItem(quoteId);
                }

            }).catch((error) => {
                this.showToast('Error', JSON.stringify(error), 'error');
                this.isLoading = false;
            });
        }
    }

    createCompareItem(quoteId){
        let detail = {quoteId: quoteId}
        if (!this.pageRef) {
            this.pageRef = {};
            this.pageRef.attributes = {};
            this.pageRef.attributes.LightningApp = "LightningApp";
        }
        fireEvent(this.pageRef, 'addNewCompareItemFromList', detail);
        createQuoteCompareItem({newQuoteId : quoteId, compareItemString :  JSON.stringify(this.quoteCompareItemZero)})
            .then(newCompareItem => {
                let temp = JSON.parse(JSON.stringify(newCompareItem));
                this.quoteCompareItems.push(temp);

                this.isLoading = false;
            }).catch((error) => {
            this.showToast('Error', JSON.stringify(error), 'error');
            this.isLoading = false;
        })
    }
    handleRefreshQuote(event) {
        if(this.isLoading === false) {
            this.isLoading = true;
            let quoteId = event.detail.quoteId;
            let detail = {quoteId: quoteId}
            if (!this.pageRef) {
                this.pageRef = {};
                this.pageRef.attributes = {};
                this.pageRef.attributes.LightningApp = "LightningApp";
            }
            console.log('compareItemString' + JSON.stringify(this.quoteCompareItemZero));
            console.log('compareItemString' + JSON.stringify(quoteId));

            fireEvent(this.pageRef, 'refreshCompareItemFromList', detail);
            fireEvent(this.pageRef, 'refreshPageFromResponse', null);
            createQuoteCompareItem({newQuoteId : quoteId, compareItemString :  JSON.stringify(this.quoteCompareItemZero)})
            .then(newCompareItem => {
                let temp = JSON.parse(JSON.stringify(newCompareItem));
                for(let i = 0; i < this.quoteCompareItems.length; i++) {
                    if(this.quoteCompareItems[i].quoteId == quoteId)
                        this.quoteCompareItems[i] = temp;
                }
                this.isLoading = false;
            }).catch((error) => {
                this.showToast('Error', JSON.stringify(error), 'error');
                this.isLoading = false;
            })

        }
    }

    handleAddNewCompareItem(event) {
        let quoteId = event.quoteId;
        createQuoteCompareItem({newQuoteId : quoteId, compareItemString :  JSON.stringify(this.quoteCompareItemZero)})
        .then(compareItem => {
            let temp = JSON.parse(JSON.stringify(compareItem));
            let clone =  JSON.parse(JSON.stringify(this.quoteCompareItems));
            clone.push(temp);
            this.quoteCompareItems = clone;
            // this.quoteCompareItems.push(temp);
        }).catch((error) => {
            this.showToast('Error', JSON.stringify(error), 'error');
        });;
    }

    disconnectCallback() {
        unregisterAllListeners(this);
    }
}