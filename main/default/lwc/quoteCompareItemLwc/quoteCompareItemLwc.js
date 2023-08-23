import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { fireEvent, registerListener, unregisterAllListeners} from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import getRatingFromCallOut from '@salesforce/apex/RateController.getRatingFromCallOut';
import FINALIZE_QUOTE_ICON from '@salesforce/resourceUrl/FinalizeQuoteIcon';
import finalizeQuote from '@salesforce/apex/FinalizeQuoteController.finalizeQuote';
import bindQuote from '@salesforce/apex/BindQuoteController.bindQuote';
import getPayPlanOptions from '@salesforce/apex/BindQuoteController.getInitData';
import updateQuoteInProgress from '@salesforce/apex/QuoteCompareItemWrapper.updateQuoteInProgress'

import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import QUOTE_OBJECT from '@salesforce/schema/Quote';
import CLOSED_REASON_FIELD from '@salesforce/schema/Quote.Closed_Reason__c';
import { updateRecord } from 'lightning/uiRecordApi';
import getQuoteDetails from '@salesforce/apex/FinalizeQuoteController.getQuoteDetails';
import generateDocId from '@salesforce/apex/GenerateQuoteDocumentController.generateDocId';
import getDocumentEncodeByQuoteId from '@salesforce/apex/ViewDocumentController.getDocumentEncodeByQuoteId';
import checkSurplusLinesLicense from '@salesforce/apex/BindQuoteController.checkSurplusLinesLicense';
// import getApprovalInfo from '@salesforce/apex/FinalizeQuoteController.getApprovalDetails';

export default class QuoteCompareItemLwc extends NavigationMixin(LightningElement) {
    @api isLockedQuote = false;
    @api processRecordId;
    @api quoteName = '';
    @api quoteStatus;
    modeEdit = false;
    @track readonly = false;
    //
    @api quoteId = '';
    @api quoteIndex = 0;
    // @api _quoteRatingrapper;
    @api quoteUrl = '';
    // set quoteRatingWrapper(value) {
    //     this._quoteRatingrapper = value;
    // }
    // @api get quoteRatingWrapper(){
    //     return this._quoteRatingrapper;
    // }
    //@api compareItem


    @api _compareItem;
    @wire(CurrentPageReference) pageRef;
    @track openModalEditQuote = false;
    @track isConfirmModalVisible = false;
    @api isOpenReferralModel = false;
    @api isUpdated;

    @api quoteVerId = '';
    @track quoteVerName = 'Version';

    @track isRateLoading = false;
    @track isEndorsementModelOpen = false;
    @track isTimelineModalOpen = false;
    @track isEndorsementClone = false;
    @track isGenerateDocument = false;

    @api setLeftPosition(value,){ // Duc - 5/8/2020
        var compareItem = this.template.querySelector(`[data-id="compare-item"]`);
        if(value){
            var left = value + 13.625;
            compareItem.setAttribute('style',`left: ${left}px !important`);
        }
    }

    @api resizeHeaderStyle(value){
        if(value){
            var left = value + 13.625;
            var compareItem = this.template.querySelector(`[data-id="compare-item"]`);
            compareItem.setAttribute('style',`left: ${left}px !important`);
            var compareItemParent = this.template.querySelector(`[data-id="compare-item-parent"]`);
            var compareItemChild = this.template.querySelectorAll(`[data-id="compare-item-child"]`);
            var sticky = compareItem.getBoundingClientRect();
            var parentWidth = compareItemParent.getBoundingClientRect().width;
                if (window.pageYOffset + sticky.height >= 1340) {
                    compareItem.classList.add("position-sticky");
                    compareItemChild.forEach(child => child.setAttribute('style',`width: ${parentWidth}px !important`));
                } else {
                    compareItem.classList.remove("position-sticky");
                    compareItemChild.forEach(child =>  child.removeAttribute('style'));
                }
        }
    }

    finalizeQuoteIcon = FINALIZE_QUOTE_ICON;
    @api quoteRatingStatus;
    @track isQuotedClear;
    @track isQuotedStatus;
    @track isBoundStatus;
    @track isStatusQuoteColumnReadOnly;
    @api isLoading = false;
    @track openModalBindQuote = false;
    @track isDisabledButton = true;
    @track isConfirmEditModalVisible = false;
    @track classNameBtnDisabled = 'slds-float_right slds-button slds-button_icon slds-button_icon-border-filled disabled';

    isEditQuoteButtonClicked = false;
    isSaveQuoteButtonClicked = false;

    @track payPlanOptions;
    @track payPlanVal;
    @track isBindLoading = false;
    @track isEdit = false;

    @track closeReason;
    
    @wire(getObjectInfo, { objectApiName: QUOTE_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: CLOSED_REASON_FIELD})
    ClosedReasonPicklistValues;

    @track isUser = false;

    @track isEditLoading = false;
    @track styleEditForm = 'slds-hide';

    @api fieldName;
    @api recordId;
    //Code modified in 4/8/2020
    //@track flag=false;
    @api rateQuote(){
        this.isLoading = true;
        getRatingFromCallOut({ objId: this.quoteId }).then(response => {
            var errMsg = '';
            if (!response.isSuccess) {
                //errMsg = 'not rated successfully';
                errMsg = response.errors[0];
            } else {
                //check rate result
                console.log('response:' + JSON.stringify(response.data));
                //var currentQuote = result.data;
                //if (currentQuote.Rating_Status__c == 'System Error') {
                //errMsg = 'Quote is not rated successfully';
                //errMsg = currentQuote.Declined_Reason__c;
                //} else {
                //component.set("v.data1", JSON.stringify(result.data));
                //console.log('result:' + result.data);
                //}	
                //Modified in 3/8/2020			
            }
            let refreshQuote = new CustomEvent('refreshquote', { detail: { quoteId: this.quoteId } });
            this.dispatchEvent(refreshQuote);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: (errMsg == '') ? "Success" : "Error",
                    message: (errMsg == '') ? "Rating sucessfully!" : errMsg,
                    variant: (errMsg == '') ? "Success" : "Error"
                }),
            )
            this.isLoading = false;
        }).catch(error => {this.showToast('Error', error, 'error');})
    }

    set compareItem(value) {
        console.log("@@@value: " + JSON.stringify(value));
        this._compareItem = value;
        var clone = JSON.parse(JSON.stringify(this._compareItem));
        clone.quoteFields.forEach(item => {
            // if(item.value === '')
            //     item.value = 'Default';
            item.options = [];
            let picklistOption = item.picklistOption.split(";");
            for (let i = 0; i < picklistOption.length; i++) {
                let option = { label: picklistOption[i], value: picklistOption[i] };
                item.options.push(option);
            }

            if (item.format == 'Picklist') {
                item.isPicklist = true;
            } else if (item.format == 'Radio Button') {
                item.isRadioButton = true;
            } else if (item.format == 'Integer') {
                item.isInteger = true;
            } else if (item.format == 'Percentage') {
                item.isPercentage = true;
            } else if (item.format == 'Currency') {
                item.isCurrency = true;
            } else if (item.format == 'Number') {
                item.isNumber = true;
            } else item.isText = true;
            if (item.fieldId === '' || item.fieldId === undefined)
                item.isField = false;
            
            // if(item.sourceObject === 'Rating_Modifier_Factor__c') {
            //     item.fieldName = item.fieldName.split(' (')[0];
            // }
            if (item.sourceFieldAPI === 'Total_Premium__c') {
                this.fieldName =  'Total_Premium__c';
                this.recordId = clone.quoteId;
            }
        })
        //this._quoteRatingrapper = clone;
        this._compareItem = clone;
        this.quoteStatus = clone.quoteStatus;
        this.quoteRatingStatus = clone.quoteRatingStatus;
        if(this.quoteRatingStatus === undefined)
            this.quoteRatingStatus = 'None';
        if (this.quoteStatus === 'Quoted' && this.quoteRatingStatus === 'Clear') {
            this.isQuotedClear = true;
        }
        if (this.quoteStatus === 'Quoted' || this.quoteStatus === 'Bound' || this.quoteStatus === 'Bound Pending') {
            this.isStatusQuoteColumnReadOnly = true;
        }
        if (this.quoteStatus === 'Quoted') 
            this.isQuotedStatus = true;
        else this.isQuotedStatus = false;
        
        if(this.quoteStatus === 'In Approval'){
            this.isLockedQuote = true;
            this.isQuotedStatus = true;
        } else {
            this.isLockedQuote = false;
        }
        console.log('compareItem######');
    }
    @api
    get compareItem() {
        return this._compareItem;
    }

    connectedCallback() {
        //var clone = JSON.parse(JSON.stringify(this._quoteRatingrapper));
        // clone.data.parents.forEach(item => {
        //     if(item.childs != null && item.childs != undefined) {
        //         item.childs.forEach(item1 => {
        //             if(item1.isField) {
        //                 if(item1.fieldValues[this.quoteIndex] != undefined
        //                     && item1.fieldValues[this.quoteIndex] != null) {
        //                     item1.value = item1.fieldValues[this.quoteIndex];
        //                     item1.type = item1.fieldFormats[this.quoteIndex];
        //                     if(item1.type == 'Picklist') {
        //                         let picklistOption = item1.fieldPicklists[this.quoteIndex].split(";");
        //                         item1.picklistOption = [];
        //                         if(item1.value === '')
        //                             item1.value = 'Default';
        //                         for(let i = 0; i < picklistOption.length; i++) {
        //                                 let option = {label : picklistOption[i], value : picklistOption[i]};
        //                                 item1.picklistOption.push(option);
        //                         }
        //                         item1.isPicklist = true;
        //                     } else if(item1.type == 'Number') {
        //                         item1.isNumber = true;
        //                     }
        //                     console.log(item1.fieldFormats + ' - ' + item1.picklistOption + '\n');

        //                 }
        //                 item1.id = item1.fieldIds[this.quoteIndex];  
        //                 if(item1.id === '' || item1.id === undefined) 
        //                     item1.isField = false;                          
        //             }

        //         })
        //     }
        // })
        // var clone = JSON.parse(JSON.stringify(this._compareItem));
        // clone.quoteFields.forEach(item => {
        //     // if(item.value === '')
        //     //     item.value = 'Default';
        //     item.options = [];
        //     let picklistOption = item.picklistOption.split(";");
        //     for (let i = 0; i < picklistOption.length; i++) {
        //         let option = { label: picklistOption[i], value: picklistOption[i] };
        //         item.options.push(option);
        //     }

        //     if (item.format == 'Picklist') {
        //         item.isPicklist = true;
        //     } else if (item.format == 'Radio Button') {
        //         item.isRadioButton = true;
        //     } else if (item.format == 'Integer') {
        //         item.isInteger = true;
        //     } else if (item.format == 'Percentage') {
        //         item.isPercentage = true;
        //     } else if (item.format == 'Currency') {
        //         item.isCurrency = true;
        //     } else if (item.format == 'Number') {
        //         item.isNumber = true;
        //     } else item.isText = true;
        //     if (item.fieldId === '' || item.fieldId === undefined)
        //         item.isField = false;
        // })
        // //this._quoteRatingrapper = clone;
        // this._compareItem = clone;

        if (this.quoteStatus === 'Quoted' && this.quoteRatingStatus === 'Clear') {
            this.isQuotedClear = true;
        }
        if (this.quoteStatus === 'Quoted' || this.quoteStatus === 'Bound' || this.quoteStatus === 'Bound Pending') {
            this.isStatusQuoteColumnReadOnly = true;
        }
        if (this.quoteStatus === 'Quoted') {
            this.isQuotedStatus = true;
        }
        if (this.quoteStatus === 'Bound') {
            this.isBoundStatus = true;
        }

        if(this.quoteStatus === 'In Approval'){
            this.isLockedQuote = true;
            this.isQuotedStatus = true;
        }

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.quoteId,
                objectApiName: 'Quote',
                actionName: 'view',
            },
        }).then(url => {
            this.quoteUrl = url;
        });;
        console.log('Connected callback')
        if(this.quoteRatingStatus === undefined)
            this.quoteRatingStatus = 'None';
        
        
        /*getQuoteDetails({quoteId: this.quoteId})
        .then(result =>{
            this.quoteInfo = result;
            console.log('Quote Info 1'+JSON.stringify(this.quoteInfo));     
        })
        .catch(error=>{
            console.error("getDetailError"+JSON.stringify(error));
        })*/
//added method
    // getApprovalInfo({quoteProcessId: this.processRecordId})
    //     .then(result =>{
    //         this.quoteInfo = result;
    //         console.log('Quote Info'+JSON.stringify(this.quoteInfo));
    //         console.log("Resultt"+JSON.stringify(result));  
    //         console.log("Record Id value"+this.processRecordId);          
    //     })
    //     .catch(error=>{
    //         console.error("error"+JSON.stringify(error));
    //     })



    }

    // toggleModeEdit(evt){
    saveQuote(evt,isRate) {
        // var oldMode = this.modeEdit;
        // this.modeEdit = !this.modeEdit;
        // if(this.modeEdit == true) {
        //     this.readonly = false;
        //     evt.target.classList.add('slds-is-selected');
        // }else {
        //     this.readonly = true;
        //     evt.target.classList.remove('slds-is-selected');
        // }
        // if(this.modeEdit == false && oldMode == true){
        //     console.log('Edit Done');

        // const editQuoteEvt = new CustomEvent(
        //     "editquote", {
        //         detail : {quoteId: this.quoteId, quoteName : this.quoteName, data: this._quoteRatingrapper.data, version : 'Version '
        //                 , index : this.quoteIndex},
        //     }
        // );
        let isValid = true;
        this.template.querySelectorAll("c-generate-output-element-lwc").forEach(field => {
            let checkValid = field.checkValid();
            if(checkValid == false) isValid = false;
        })
        if(!isValid) {
            this.showToast('Error', 'Some values is invalid!','error')
            return;
        }
        if(this.quoteStatus == 'In Progress'){
            this.saveCompareItem(event,false);
        }else{
            this.isConfirmEditModalVisible = true;
            this.isSaveQuoteButtonClicked = true;
        }
    }

    saveCompareItem(event,isRate) {
        var clone = JSON.parse(JSON.stringify(this._compareItem));
            console.log(clone);
            const editQuoteEvt = new CustomEvent(
            "editquote", {
            detail: {
                quoteId: this.quoteId, quoteName: this.quoteName, data: this._compareItem, quoteVerId: this.quoteVerId
                , isRate: isRate, fromResponse : false
            },
        }
        );  
        // this.flag = true;
        this.dispatchEvent(editQuoteEvt);
    }

    handleChangeInputValue(event) {
        console.log("@@@value: " + event.target.value);
        var quoteRatingWr = JSON.parse(JSON.stringify(this._compareItem));
        var valueChange = event.target.value;
        // quoteRatingWr.data.parents.forEach(item => {
        //     console.log("@@@item.Id: " + JSON.stringify(item));
        //     console.log("@@@event.target.name: " + event.target.name);
        //     if(item.id === event.target.name){
        //         item.value = event.target.value;
        //         console.log("OK");
        //     }
        // });
        quoteRatingWr.quoteFields.forEach(item => {
            console.log("@@@item.Id: " + JSON.stringify(item));
            console.log("@@@event.target.name: " + event.target.name);
            if (item.fieldId === event.target.name) {
                item.value = event.target.value;
                console.log("OK");
            }
        });
        this._compareItem = quoteRatingWr;
    }

    handleChangeInput(event) {
        let name = event.detail.fieldId;
        let value = event.detail.fieldValue;
        var quoteRatingWr = JSON.parse(JSON.stringify(this._compareItem));       
        quoteRatingWr.quoteFields.forEach(item => {
            if (item.isField && item.fieldId === name) {
                item.value = value;
                console.log("OK");
            }
        });
        this._compareItem = quoteRatingWr;
        this.isDisabledButton = false;
        this.classNameBtnDisabled = 'slds-float_right slds-button slds-button_icon slds-button_icon-border-filled no-disabled';
    }

    handleChangeInputValueChild(event) {
        console.log("@@@ child value quote name: " + this.quoteName);
        console.log("@@@ child value: " + event.target.value);
        console.log("event name: " + event.target.name);
        var quoteRatingWr = JSON.parse(JSON.stringify(this._compareItem));
        var valueChange = event.target.value;
        // quoteRatingWr.data.parents.forEach(item => {
        //     if(item.childs != null && item.childs != undefined){
        //         item.childs.forEach(item1 => {
        //             // console.log("@@@item.Id: " + item1.id);
        //             // console.log("@@@event.target.name: " + event.target.name);
        //             if(item1.id === event.target.name){
        //                 item1.value = event.target.value;
        //                 console.log("OK");
        //             }
        //         });
        //     }
        // });

        //new
        // quoteRatingWr.data.parents.forEach(item => {
        //     if(item.childs != null && item.childs != undefined) {
        //         item.childs.forEach(item1 => {
        //             if(item1.isField) 
        //                 if(item1.fieldIds[this.quoteIndex] == event.target.name) {
        //                     item1.fieldValues[this.quoteIndex] = event.target.value;
        //                     console.log("Updated: " + item1.fieldIds[this.quoteIndex] + " - " + item1.fieldValues[this.quoteIndex])
        //                 }
        //         })
        //     }
        // })
        quoteRatingWr.quoteFields.forEach(item => {
            if (item.isField && item.fieldId === event.target.name) {
                item.value = event.target.value;
                console.log("OK");
            }
        });
        this._compareItem = quoteRatingWr;
        //  var test1 = JSON.parse(JSON.stringify(this._quoteRatingrapper));
        //  test1.parents.forEach(function(part, index) {
        //     if(this[index] && this[index].childs) {
        //         var newChilds = Object.assign({}, this[index].childs);
        //         this[index].childs.forEach(function(partChild, indexChild) {
        //             let itemChildTemp = Object.assign({}, this[indexChild]);
        //             itemChildTemp.value = event.target.value;
        //             this[indexChild].value = event.target.value;
        //         },this[index].childs);
        //     }
        //   }, test1.parents);
        // this._quoteRatingrapper = test1;
        this.isDisabledButton = false;
        this.classNameBtnDisabled = 'slds-float_right slds-button slds-button_icon slds-button_icon-border-filled no-disabled';
    }

    handleChangePicklist(event) {
        console.log("@@@value: " + event.target.value);
        var quoteRatingWr = JSON.parse(JSON.stringify(this._compareItem));
        var valueChange = event.target.value;
        // quoteRatingWr.data.parents.forEach(item => {
        //     console.log("@@@item.Id: " + JSON.stringify(item));
        //     console.log("@@@event.target.name: " + event.target.name);
        //     if(item.id === event.target.name){
        //         item.value = event.target.value;
        //         console.log("OK");
        //     }
        // });
        quoteRatingWr.quoteFields.forEach(item => {
            if (item.fieldId === event.target.name) {
                item.value = event.target.value;
                console.log("OK");
            }
        });
        this._compareItem = quoteRatingWr;
        this.isDisabledButton = false;
        this.classNameBtnDisabled = 'slds-float_right slds-button slds-button_icon slds-button_icon-border-filled no-disabled';
    }

    
    handleChangePicklistChild(event) {
        console.log("@@@value: " + event.target.value);
        var quoteRatingWr = JSON.parse(JSON.stringify(this._compareItem));
        var valueChange = event.target.value;
        // quoteRatingWr.data.parents.forEach(item => {
        //     if(item.childs != null && item.childs != undefined){
        //         item.childs.forEach(item1 => {
        //             console.log("@@@item.Id: " + item1.id);
        //             console.log("@@@event.target.name: " + event.target.name);
        //             if(item1.id === event.target.name){
        //                 item1.value = event.target.value;
        //                 console.log("OK");
        //             }
        //         });
        //     }     
        // });
        // quoteRatingWr.data.parents.forEach(item => {
        //     if(item.childs != null && item.childs != undefined) {
        //         item.childs.forEach(item1 => {
        //             if(item1.isField) 
        //                 if(item1.fieldIds[this.quoteIndex] == event.target.name) {
        //                     item1.fieldValues[this.quoteIndex] = event.target.value;
        //                     console.log("Updated: " + item1.fieldIds[this.quoteIndex] + " - " + item1.fieldValues[this.quoteIndex])
        //                 }
        //         })
        //     }
        // })
        quoteRatingWr.quoteFields.forEach(item => {
            if (item.isField && item.fieldId === event.target.name) {
                item.value = event.target.value;
                console.log("OK");
            }
        });
        this._compareItem = quoteRatingWr;
    }

    get condition() {
        return this.quoteStatus;
    }

    handleChangeQuoteName(event) {
        this.quoteName = event.target.value;
    }

    handleCloseButtonClickEvent(event) {
        this.isConfirmModalVisible = true;
    }
    handleChangeReason(event){
        this.closeReason = event.detail.value;
    }
    handleCloseQuoteModal(){
        this.isConfirmModalVisible = false;
        this.closeReason = null;
    }
    handleCloseQuote(event) {
        let status = event.target.name;
        if (status == 'confirm') {
            if(!this.closeReason){
                this.showToast('Error', 'Please choose your reason!', 'error');
                return;
            }
            let detail = { quoteId: this.quoteId, closeReason: this.closeReason };
            const removeQuoteEvt = new CustomEvent(
                "deletequote", {
                detail
            }
            );
            this.dispatchEvent(removeQuoteEvt);

            if (!this.pageRef) {
                this.pageRef = {};
                this.pageRef.attributes = {};
                this.pageRef.attributes.LightningApp = "LightningApp";
            }

            fireEvent(this.pageRef, 'deleteQuote', detail);
            this.isConfirmModalVisible = false;
            this.closeReason = null;
        } else if (status == 'cancel') {
            this.isConfirmModalVisible = false;
            this.closeReason = null;
        }

    }


    
    //Edit quote button start
    handleEditQuote() {
        this.isConfirmEditModalVisible = true;
        //this.openModalEditQuote = true;

        // if (this.quoteStatus === 'Quoted') {
        //     updateQuoteInProgress({ quoteId: this.quoteId }).then(response => {
        //         if (response.isSuccess) {
        //             this.quoteStatus = 'In Progress';
        //             this.isStatusQuoteColumnReadOnly = false;
        //             this.isQuotedStatus = false;
        //         } else {
        //             this.dispatchEvent(
        //                 new ShowToastEvent({
        //                     title: 'Error',
        //                     message: response.errors[0],
        //                     variant: 'error',
        //                 }),
        //             )
        //         }
        //     })
        // }
    }

    handleCancel() {
        this.openModalEditQuote = false;
    }
    handleShowEditQuote() {
        // if(this.quoteStatus == 'Quoted'){
        //     this.isConfirmEditModalVisible = true;
        //     this.isEditQuoteButtonClicked = true;
        // }else{
        //     this.isConfirmEditModalVisible = false;
        //     this.openModalEditQuote = true;
        // }
        if(this.quoteStatus == 'In Progress'){
            this.isConfirmEditModalVisible = false;
            this.openModalEditQuote = true;
        }else{
            this.isConfirmEditModalVisible = true;
            this.isEditQuoteButtonClicked = true;
        }
        this.isEditLoading = true;
        this.styleEditForm = 'slds-hide';
        setTimeout(()=>{
            this.isEditLoading = false;
            this.styleEditForm = 'slds-show';
        },1000)
    }

    handlerConfirmEdit(event){
        let status = event.detail.status;
        if (status == 'confirm') {
            if(this.quoteStatus != 'In Progress') {
                updateQuoteInProgress({ quoteId: this.quoteId }).then(response => {
                    if (response.isSuccess) {
                        if(this.isSaveQuoteButtonClicked == false) {
                            let refreshQuote = new CustomEvent('refreshquote', { detail: { quoteId: this.quoteId } });
                            this.dispatchEvent(refreshQuote);
                        }
                        if(this.isEditQuoteButtonClicked)
                            this.openModalEditQuote = true;
                        this.isEditQuoteButtonClicked = false;

                        if(this.isSaveQuoteButtonClicked){
                            this.saveCompareItem(event,false);
                        } 
                        this.isSaveQuoteButtonClicked = false;
                    } else {
                        this.showToast('Error', response.errors[0], 'error');
                    }
                }).catch(error => {this.showToast('Error', error, 'error');})
            } else {
                if(this.isEditQuoteButtonClicked)
                    this.openModalEditQuote = true;
                this.isEditQuoteButtonClicked = false;
            }
        }
        if(status == 'cancel'){
            this.isEditQuoteButtonClicked = false;
            this.isSaveQuoteButtonClicked = false;
        } 
        this.isConfirmEditModalVisible = false;
        
    }

    handleSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;
        fields.quoteId = this.quoteId;
        console.log('this.selectedQuoteId:' + this.quoteId);
        const fieldsObj = JSON.parse(JSON.stringify(fields));
        console.log('this.compareItem:', this._compareItem);
        this.template.querySelector('lightning-record-form').submit(fields);
        //this.template.querySelector('lightning-record-form').submit();
        if (this.quoteName != fieldsObj.Name) {
            let detail = { quoteId: this.quoteId, quoteName: fieldsObj.Name }
            if (!this.pageRef) {
                this.pageRef = {};
                this.pageRef.attributes = {};
                this.pageRef.attributes.LightningApp = "LightningApp";
            }
            fireEvent(this.pageRef, 'editQuoteName', detail);
        }
        this.quoteName = fieldsObj.Name
        //Edit Status
        if (this.quoteStatus != fieldsObj.Status) {
            let detail = { quoteId: this.quoteId, quoteStatus: fieldsObj.Status }
            if (!this.pageRef) {
                this.pageRef = {};
                this.pageRef.attributes = {};
                this.pageRef.attributes.LightningApp = "LightningApp";
            }
            fireEvent(this.pageRef, 'editQuoteStatus', detail);
        }
        this.quoteStatus = fieldsObj.Status
        if (this.quoteStatus = 'In Progress') {
            this.isQuotedStatus = false;
            this.isStatusQuoteColumnReadOnly = false;
        }
        if (this.quoteStatus = 'Quoted') {
            this.isQuotedStatus = true;
            this.isStatusQuoteColumnReadOnly = true;
        }
    }

    handleEditSuccess(event) {
        //this.template.querySelector('c-pagination-lwc').refreshDataTable();
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Record updated successfully with id: ' + event.detail.id,
                variant: 'success',
            }),
        )
        this.handleCancel();
        // window.location.reload();
        let refreshQuote = new CustomEvent('refreshquote', { detail: { quoteId: this.quoteId } });
        this.dispatchEvent(refreshQuote);
    }
    //edit quote button end
    //handle rate quote button
    handleRateQuote() {
        //code modified in 4/8/2020
        this.isLoading = true;
        console.log('handleRateQuote', this.quoteId);
        let isValid = true;
        this.template.querySelectorAll("c-generate-output-element-lwc").forEach(field => {
            let checkValid = field.checkValid();
            if(checkValid == false) isValid = false;
        })
        if(!isValid) {
            this.showToast('Error', 'Some values is invalid!','error')
            return;
        }
        if(this.quoteStatus == 'In Progress'){
            this.saveCompareItem(event,true);
        }else{
            this.showToast("Error", 'Can not rate with this quote status.', 'Error');
            this.isLoading = false;
        }
            // let refreshQuote = new CustomEvent('refreshquote', { detail: { quoteId: this.quoteId} });
            // this.dispatchEvent(refreshQuote);
            // getRatingFromCallOut({ objId: this.quoteId }).then(response => {
            //     var errMsg = '';
            //     if (!response.isSuccess) {
            //         //errMsg = 'not rated successfully';
            //         errMsg = response.errors[0];
            //     } else {
            //         //check rate result
            //         console.log('response:' + JSON.stringify(response.data));
            //         //var currentQuote = result.data;
            //         //if (currentQuote.Rating_Status__c == 'System Error') {
            //         //errMsg = 'Quote is not rated successfully';
            //         //errMsg = currentQuote.Declined_Reason__c;
            //         //} else {
            //         //component.set("v.data1", JSON.stringify(result.data));
            //         //console.log('result:' + result.data);
            //         //}	
            //         //Modified in 3/8/2020			
            //     }
            //     let refreshQuote = new CustomEvent('refreshquote', { detail: { quoteId: this.quoteId } });
            //     this.dispatchEvent(refreshQuote);
            //     this.dispatchEvent(
            //         new ShowToastEvent({
            //             title: (errMsg == '') ? "Success" : "Error",
            //             message: (errMsg == '') ? "Rating sucessfully!" : errMsg,
            //             variant: (errMsg == '') ? "Success" : "Error"
            //         }),
            //     )
            //     this.isLoading = false;
            // })
        
        
        // else{
        //     this.isConfirmEditModalVisible = true;
        //     this.isSaveQuoteButtonClicked = false;
        // }
        // console.log('handleRateQuote', this.quoteId);
        // // this.isLoading = true;
        // if(this.flag == true){
        //     this.isLoading = true;
        //     getRatingFromCallOut({ objId: this.quoteId }).then(response => {
        //         var errMsg = '';
        //         if (!response.isSuccess) {
        //             //errMsg = 'not rated successfully';
        //             errMsg = response.errors[0];
        //         } else {
        //             //check rate result
        //             console.log('response:' + JSON.stringify(response.data));
        //             //var currentQuote = result.data;
        //             //if (currentQuote.Rating_Status__c == 'System Error') {
        //             //errMsg = 'Quote is not rated successfully';
        //             //errMsg = currentQuote.Declined_Reason__c;
        //             //} else {
        //             //component.set("v.data1", JSON.stringify(result.data));
        //             //console.log('result:' + result.data);
        //             //}	
        //             //Modified in 3/8/2020			
        //         }
        //         let refreshQuote = new CustomEvent('refreshquote', { detail: { quoteId: this.quoteId } });
        //         this.dispatchEvent(refreshQuote);
        //         this.dispatchEvent(
        //             new ShowToastEvent({
        //                 title: (errMsg == '') ? "Success" : "Error",
        //                 message: (errMsg == '') ? "Rating sucessfully!" : errMsg,
        //                 variant: (errMsg == '') ? "Success" : "Error"
        //             }),
        //         )
        //         this.isLoading = false;
        //         this.flag = false;
        //     })
        // }
    }


    handleOnselectVersion(event) {
        var selectedVersion = event.detail.value;
        let selectedObject = this._compareItem.quoteVersions.find(function (element) {
            return element.Id === selectedVersion;
        });
        this.quoteVerName = selectedObject.Name;
        this.quoteVerId = selectedVersion;
        console.log("@@@quoteVerName: " + this.quoteVerName + " ,quoteVerId: " + this.quoteVerId);
        const selectVersionEvt = new CustomEvent(
            "selectversion", {
            detail: {
                versionId: selectedVersion, quoteId: this.quoteId,
                data: this._compareItem
            }
        }
        );
        this.dispatchEvent(selectVersionEvt);
    }

    handleOnselectVersionTimeLine(event) {
        console.log('VersionId' +event.detail.versionId);

        var selectedVersion =event.detail.versionId;
        let selectedObject = this._compareItem.quoteVersions.find(function (element) {
            return element.Id === selectedVersion;
        });
        this.quoteVerName = selectedObject.Name;
        this.quoteVerId = selectedVersion;
        const selectVersionEvt = new CustomEvent(
            "selectversion", {
                detail: {
                    versionId: selectedVersion, quoteId: this.quoteId,
                    data: this._compareItem
                }
            }
        );
        this.dispatchEvent(selectVersionEvt);
        this.showToast('Success!','Quote Version Selected','success')
        this.isTimelineModalOpen = false;
    }

    renderedCallback() {
        const style = document.createElement('style');
        style.innerText = `
        table.tblCustom tr:nth-child(odd) input {
            background-color: rgb(243, 242, 242);
          }
        .editDialog .editForm div[role="list"] .slds-align_absolute-center {
            position: fixed;
            bottom: 1.5%;
            left: 0;
            width: 100%;
            background: rgb(243, 242, 242);
            box-shadow: 0 -2px 2px 0 rgba(0, 0, 0, 0.16);
            z-index: 8000;
            padding: 2px;
        }
        `;
        this.template.querySelector('tbody').appendChild(style);

        // this.styleFixedHeader();
    }

    // styleFixedHeader(){
    //     var compareItem = this.template.querySelector(`[data-id="compare-item"]`);
    //     var compareItemParent = this.template.querySelector(`[data-id="compare-item-parent"]`);
    //     var compareItemChild = this.template.querySelectorAll(`[data-id="compare-item-child"]`);
    //     var sticky = compareItem.getBoundingClientRect();
        
    //     window.addEventListener('scroll', function(event) {
            
    //         var parentWidth = compareItemParent.getBoundingClientRect().width;
    //         var parentHeight = compareItemParent.getBoundingClientRect().height;
    //         var parentTop = compareItemParent.getBoundingClientRect().top;
    //         var parentBottom = compareItemParent.getBoundingClientRect().bottom;
    //         if (window.pageYOffset + sticky.height >= 1340) {
    //             compareItem.classList.add("position-sticky");
    //             compareItemChild.forEach(child => child.setAttribute('style',`width: ${parentWidth}px !important`));
    //         } else {
    //             compareItem.classList.remove("position-sticky");
    //             compareItemChild.forEach(child =>  child.removeAttribute('style'));
    //         }
            
    //     });
    // }

    handleCloneQuote(event) {
        console.log('@@@ quoteId', this.quoteId);

        const cloneQuoteEvent = new CustomEvent(
            "clonequote", {
            detail: { quoteId: this.quoteId }
        });
        this.dispatchEvent(cloneQuoteEvent);
    }

    openEndorsementModel(event) {
        this.isEndorsementModelOpen = true;
        console.log("@@@ openEndorsementModel: " + this.quoteStatus);
    }
    closeEndorsementModal(event) {
        this.isEndorsementModelOpen = false;
        let refreshQuote = new CustomEvent('refreshquote', { detail: { quoteId: this.quoteId } });
        this.dispatchEvent(refreshQuote);
    }
    
    handleFinalizeQuote(event) {
        this.isLoading = true;
        console.log("@@@handleFinalizeQuote: ");
        finalizeQuote({ 'quoteId': this.quoteId })
            .then((result) => {
                if (result.isSuccess) {
                    var currentQuote = result.data;
                    this.quoteStatus = currentQuote.Status;
                    this.isLoading = false;
                    this.isQuotedClear = true;
                    let refreshQuote = new CustomEvent('refreshquote', { detail: { quoteId: this.quoteId } });
                    this.dispatchEvent(refreshQuote);
                    this.showToast('Success', 'Finalize quote sucessfully!', 'success');
                } else {
                    console.log('@@@error: ' + JSON.stringify(result.errors));
                    this.isLoading = false;
                    let refreshQuote = new CustomEvent('refreshquote', { detail: { quoteId: this.quoteId } });
                    this.dispatchEvent(refreshQuote);
                    this.showToast('Error', result.errors[0], 'error');
                }
            })
            .catch((error) => {
                console.log('@@@error: ' + JSON.stringify(error));
                this.isLoading = false;
                this.showToast('Error', 'Finalize quote fail!', 'error');
            })
    }

    @track viewDocument = false;
    handleViewDocument(event) {
        console.log("@@@handleViewDocument: ");
        this.isGenerateDocument = true;
        this.viewDocument = true;
        getDocumentEncodeByQuoteId({quoteId: this.quoteId}).then(
            result=>{
                console.log('@@@ result getDocument= ' + JSON.stringify(result));
				if (result.encodeBlobResponse) {
		        	setTimeout(function() {
		        		var binary = atob(result.encodeBlobResponse.replace(/\s/g, ''));
						var buffer = new ArrayBuffer(binary.length);
						var view = new Uint8Array(buffer);
						for (var i = 0; i < binary.length; i++) {
							view[i] = binary.charCodeAt(i);
						}
						var blob = new Blob([view]);
						var url = URL.createObjectURL(blob);
						var link = document.createElement('a');
						link.href = url;
						link.download = result.docName;
						link.click();
		        	}, 500);	
                }
                this.showToast(
                    (!result.errMsg) ? 'Success' : 'Error',
                    (!result.errMsg) ? 'Document has been generated sucessfully!' : result.errMsg,
                    (!result.errMsg) ? 'success' : 'error'
            );
                this.viewDocument = false;
                this.isGenerateDocument = false;
            }
        )
    }

    handleBindQuote(event) {
        console.log("@@@handleBindQuote: ");
        this.openModalBindQuote = true;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
    handlePayPlanChange(event) {
        this.payPlanVal = event.detail.value;
    }
    onClickBindQuote(event) {
        this.openModalBindQuote = true;
        getPayPlanOptions({ quoteId: this.quoteId})
            .then(result => {
                console.log('Init Date ='+JSON.stringify(result));
                let options = []; 
                if(result.payplanPicklist){
                    let picklistOption = result.payplanPicklist;
                    for (let i = 0; i < picklistOption.length; i++) {
                        let option = { label: picklistOption[i], value: picklistOption[i] };
                        options.push(option);
                    }
                    this.payPlanOptions = options;
                }
            })
            .catch(error=>{
                console.error("error"+JSON.stringify(error));
            });
    }

    handlecheckSurplusLinesLicense(){
        checkSurplusLinesLicense({ quoteId: this.quoteId})
        .then(result => {
            if(!result.isSuccess){
                this.showToast('Warning!', result.errors[0], 'warning');
            }
        })
    }

    handleBindQuote() {
        //this.handlecheckSurplusLinesLicense();
        //this.isLoading = !this.isLoading;
        this.isBindLoading = !this.isBindLoading;
        bindQuote({ quoteId: this.quoteId, payPlan: this.payPlanVal })
            .then(result => {
                var errMsg = '';
                if (result.isSuccess) { 
                    if(result.errors) {
                        this.showToast('Warning!', result.errors[0], 'warning');
                    }              
                    //redirect to Policy
                    if(result.data){
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: result.data,
                                objectApiName: 'relationship_owner__c',
                                actionName: 'view'
                            }
                        });
                    } else {
                        //if stay at Quote compare, will update quote status & refresh page
                        this.quoteStatus = result.extraData.Status;
                        //this.isLoading = !this.isLoading;
                        this.isBindLoading = !this.isBindLoading;
                        this.isQuotedClear = false;
                        this.openModalBindQuote = !this.openModalBindQuote;
                        let refreshQuote = new CustomEvent('refreshquote', { detail: { quoteId: this.quoteId } });
                        this.dispatchEvent(refreshQuote);
                    }
                } else {
                    console.log('@@@error: ' + JSON.stringify(result.errors));
                    //this.isLoading = !this.isLoading;
                    this.isBindLoading = !this.isBindLoading;
                    this.openModalBindQuote = !this.openModalBindQuote;
                    errMsg = result.errors[0];
                    //this.showToast('Error', result.errors[0], 'error');
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: (errMsg == '') ? "Success" : "Error",
                        message: (errMsg == '') ? "Bind quote sucessfully!" : errMsg,
                        variant: (errMsg == '') ? "Success" : "Error"
                    }),
                )
            })
            .catch(error => {
                console.log('@@@error: ' + JSON.stringify(error));
                this.isLoading = !this.isLoading;
                this.isBindLoading = !this.isBindLoading;
                this.openModalBindQuote = !this.openModalBindQuote;
                this.showToast('Error', 'Bind quote fail!', 'error');
            })
    }

    handleCancelBind() {
        this.openModalBindQuote = !this.openModalBindQuote;
    }

    openQuoteVersionTimeline(event) {
        this.isTimelineModalOpen = true;
    }

    closeVersionTimeline(event) {
        this.isTimelineModalOpen = false
    }
    openEndorsementClone() {
        this.isEndorsementClone = true;
    }
    handleCanelEndorse() {
        this.isEndorsementClone = false;
    }
    handleOpenCloseReferral(event){
        this.isOpenReferralModel = !this.isOpenReferralModel;
        let refreshQuote = new CustomEvent('refreshquote', { detail: { quoteId: this.quoteId } });
        this.dispatchEvent(refreshQuote);
    }
    
    get disableReferralButton(){
        if(this.quoteStatus == 'Rated') {
            return false;
        }else{
            return true;
        }
    }

    get quoteClear2(){
        if (this.quoteStatus === 'Quoted' && this.quoteRatingStatus === 'Clear') {
            return true;
        }else{
            return  false;
        }
    }


    get boundDisabled(){
        let noBound = 'main';
        let bound = 'main '+'bound-disabled';
        return this.quoteStatus == 'Bound' ? bound: noBound;
    }

    lockQuote() {
        quoteClear2 = true;
        //this.isStatusQuoteColumnReadOnly = true;
    }

    handleOpenConfirmEdit(){
        this.isConfirmEditModalVisible = true;
    }

    handleGenerateDocument() {
      this.isGenerateDocument = true;
      generateDocId({ quoteId: this.quoteId })
      .then((result) => {
            this.showToast(
              (!result.errMsg) ? 'Success' : 'Error',
              (!result.errMsg) ? 'Document has been generated sucessfully!' : result.errMsg,
              (!result.errMsg) ? 'success' : 'error'
              );
            this.isGenerateDocument = false;
        })
        .catch((e) => this.showToast("Error", JSON.stringify(e), "error"));
    }

}