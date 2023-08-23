import { LightningElement, api, wire, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getDefaultRecordType from "@salesforce/apex/OpportunityInitFormCmpController.getDefaultRecordType";
import validateOpportunity from "@salesforce/apex/OpportunityInitFormCmpController.validateOpportunity";
import getSubmissionName from "@salesforce/apex/OpportunityInitFormCmpController.getSubmissionName";
import fetchProductName from "@salesforce/apex/OpportunityInitFormCmpController.fetchProductName";
import getPicklistValues from "@salesforce/apex/OpportunityInitFormCmpController.getPicklistValues";
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";

import ID_FIELD from "@salesforce/schema/Opportunity.Id";
import INNOVISK_ENTITY from "@salesforce/schema/Opportunity.Innovisk_Entity_ID__c";
import MAIN_PROFESSION from "@salesforce/schema/Opportunity.Main_Profession__c";
import LARGEST_WORK_TYPE from "@salesforce/schema/Opportunity.Largest_Work_Type__c";
import RECORDTYPE_FIELD from '@salesforce/schema/Opportunity.RecordTypeId';
import ACCOUNT_FIELD from "@salesforce/schema/Opportunity.AccountId";
import COVERAGE_PRODUCT_OPTIONS_FIELD from "@salesforce/schema/Opportunity.Coverage_Product_Options__c"; // ADDED BY Ravi
import PRODUCT_FIELD from "@salesforce/schema/Opportunity.Product__c";
import STAGENAME_FIELD from "@salesforce/schema/Opportunity.StageName";
import OPPORTUNITY_LOSS_REASON from "@salesforce/schema/Opportunity.Loss_Reason__c";
import CLOSEDATE_FIELD from "@salesforce/schema/Opportunity.CloseDate";
import CREATE_FROM_QP_FIELD from "@salesforce/schema/Opportunity.Create_From_Quote_Process__c";
import OPPORTUNITY_OBJECT from "@salesforce/schema/Opportunity";
import Attachment_Point_FIELD from "@salesforce/schema/Opportunity.Attachment_Point__c";
import TRANSACTION_STATUS_FIELD from "@salesforce/schema/Opportunity.Transaction_Status__c";

import BROKER_ACCOUNT_OBJECT from "@salesforce/schema/Broker_Account__c";

import BROKER_CONTACT_FIELD from "@salesforce/schema/Broker_Account__c.Broker_Contact__c";
import RELATIONSHIP_TYPE_FIELD from "@salesforce/schema/Broker_Account__c.Relationship_Type__c";
import IS_PRIMARY_BROKER_FIELD from "@salesforce/schema/Broker_Account__c.IsPrimaryBroker__c";
import OPPORTUNITY_ID_FIELD from "@salesforce/schema/Broker_Account__c.Opportunity__c";
import getDefaultProduct from "@salesforce/apex/OpportunityInitFormCmpController.getDefaultProduct";

import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { createRecord, updateRecord } from "lightning/uiRecordApi";
import SYSTEM_ERROR_MSG from "@salesforce/label/c.SYSTEM_ERROR_MSG";
import sendSubmissionDetails from "@salesforce/apex/AccountClearanceCallout.sendSubmissionDetails";
import ACCOUNT_CLEARANCE from "@salesforce/schema/Opportunity.Account_Clearance__c";
import checkProductType from "@salesforce/apex/CyberIntelCallout.checkProductType";
import cyberIntelRequest from "@salesforce/apex/CyberIntelCallout.cyberIntelRequest";
import SERVICE_TO_RUN from "@salesforce/schema/Opportunity.Service_to_Run__c";

export default class OpportunityInitCloneLwc extends NavigationMixin(LightningElement) {
    @api objectName = "";
    @api recordTypeList;
    @track rctId = "";
    @api productId = "";
    @api accountId = "";
    @api contactId = "";
    @api oppId = "";
    @api relationship = "Broker";
    @api quoteProcessId = "";

    @api isPrimaryBroker;
    @api recordTypeId;
    @api isConfirmOpenExistSubmission = false;

    @track attachment = '';
    @track accountClearance;
    @track isCyber = false;
    @track serviceToRun;
    @track serviceOptions;
    @track showSpinner = false;
    @track errorLabel = "";
    @track rctName = "";
    @track submissionName;
    @track lookupFilter;
    @track isNextDisabled = false;
    @track isContinueDisabled = false;

    fields = {};

    @track showDuplicateTable = false;
    @track listDuplicateData = {};

    @track nextButtonClicked=false;

    @track columns = [{
            label: "Submission Name",
            fieldName: "recordLink",
            type: "url",
            typeAttributes: { label: { fieldName: "Name" }, tooltip: "Name", target: "_blank" }
        },
        { label: 'Account', fieldName: 'Account_Name', type: "text" },
        { label: "Broker Agency", fieldName: 'Broker_Agency', type: "text" },
        { label: "Broker Producer", fieldName: 'Broker_Producer', type: "text" },
        { label: 'Effective Date', fieldName: 'Effective_Date', type: "date" },
        { label: "Submission Stage", fieldName: "StageName", type: "text" },
    ];

    @track sortBy;
    @track sortDirection = 'asc';


    @track recordInfo = {
        fields: [
            { name: "Name", value: null, initValue: false },
            { name: "RecordTypeId", value: this.recordTypeId, initValue: true },
            { name: "AccountId", value: null, initValue: false },
            { name: "Record_Type_Picklist__c", value: 'Broker', initValue: true }
        ]
    }

    constructor() {
        super();
        window.addEventListener("showtoast", (evt) => {
            console.log(JSON.stringify(evt));
        })
        this.lookupFilter = 'RecordType.Name = \'Broker\'';
    }

    connectedCallback() {
        console.log("productId", this.productId);
        console.log(" accountId", this.accountId);
    }

    renderedCallback() {
        console.log(" rendered call back: isCelerity: ", this.isCelerity);
        //Defaulting Service to Run to 'None'
        if (this.isCelerity) {
            if (!this.serviceOptions) {
                this.getPicklistValues();
                this.serviceToRun = 'None';
            }
        }
    }

    getPicklistValues() {
        getPicklistValues({ fieldName: 'Service_to_Run__c', recordType: this.rctName })
            .then((result) => {
                if (result) {
                    console.log('picklist values: ' + JSON.stringify(result));
                    let tempOptions = [];
                    result.forEach(item => {
                        if (item.label == 'None') {
                            tempOptions.unshift({ label: item.label, value: item.value });
                        } else {
                            tempOptions.push({ label: item.label, value: item.value });
                        }
                    })
                    this.serviceOptions = tempOptions;
                }
            })
            .catch((error) => {
                console.log("error getting picklist values: " + JSON.stringify(error));
            });
    }

    @track isCelerity;
    @wire(getDefaultRecordType, { quoteProcessId: "$quoteProcessId" })
    wireRCTOPP({ error, data }) {
        if (data) {
            console.log("RecordType:" + JSON.stringify(data));
            this.rctName = data.split('__')[1];
            this.rctId = data.split('__')[0]

            if (this.rctName == 'Celerity') {
                this.isCelerity = true;
                // this.attachment = 'Primary'; //Commented for US-40361
            } else {
                this.isCelerity = false;
            }

        } else {
            console.log("getRecordType error:" + JSON.stringify(error));
        }
    }

    @wire(getDefaultProduct, { quoteProcessId: "$quoteProcessId" })
    result({ error, data }) {
        if (data) {
            console.log("Default Product :" + JSON.stringify(data));
            this.productId = data;
            this.checkProductType();
            this.getSubmissionName();
        } else {
            console.log("getDefaultProduct error:" + error);
        }
    }



    getSubmissionName() {
        getSubmissionName({ accountId: this.accountId, productId: this.productId })
            .then((result) => {
                this.submissionName = result;
            })
            .catch((error) => {
                console.log("error message" + JSON.stringify(error));
            });
    }



    messageListener(event) {
        console.log(JSON.stringify(event));
    }

    handleToastEvent(event) {
        console.log("Event Listener " + JSON.stringify(event.target.message));
        console.log("Event Listener " + JSON.stringify(event));
    }

    handleCancel() {
        const opened = new CustomEvent("openedinitform", {
            detail: { opened: false }
        });
        this.dispatchEvent(opened);
    }
    handleShowToast(event) {
        console.log("Show Toast Event" + JSON.stringify(event));
    }

    handleNext(event) {
        this.template.querySelector(".editForm1").submit();
        this.template.querySelector(".editForm2").submit();
        // this.template.querySelector(".editForm3").submit();
        if (this.accountId == null || this.accountId == "") {
            this.showToast("Error", "Account null", "error");
            return;
        }
        if (!this.isCelerity) {
            if (this.mainprofession == null || this.mainprofession == "" || this.mainprofession == 'undefined') {
                this.showToast("Error", "Main Profession is Mandatory", "error");
                return;
            }
            if (this.largestworktype == null || this.largestworktype == "") {
                this.showToast("Error", "Work Type is Mandatory", "error");
                return;
            }
        }
        if (this.productId == null || this.productId == "") {
            this.showToast("Error", "Product null", "error");
            return;
        }
        if (this.contactId == null || this.contactId == "") {
            this.showToast("Error", "Broker contact is Mandatory", "error");
            return;
        }
        if (this.relationship == null || this.relationship == "") {
            this.showToast("Error", "Relationship type null", "error");
            return;
        }

        /* if(this.isCelerity){ //Commented for US-40361
           if (this.attachment == null || this.attachment == "") {
             this.showToast("Error", "Attachment Point null", "error");
             return;
           }
         }*/

        console.log("call validateOpportunity as this.contactId=" + this.contactId);

        this.isNextDisabled = true;
        if (this.isCelerity) {
            this.accountClearanceCallout();
        } else {
            this.nextButtonClicked = true;
            this.validateOpportunity();
        }

    }

    //Create Duplicate Submission for Excess
    handleCreateNew() {
        console.log('handleCreateNew');
        this.isContinueDisabled = true;
        this.createOpportunityValidate(false);
    }

    handleClose() {
        this.isNextDisabled = false;
        this.isContinueDisabled = false;
        this.showDuplicateTable = false;
        this.isConfirmOpenExistSubmission = false;
        this.nextButtonClicked = false;
    }

    @track duplicatePopUptitle;
    @track diffAgencyPopUptitle;
    @track infoMsg;
    @track isShowDiffAgency;
    @track isShowDuplicate;
    @track listDiffAgencyData;

    //validate duplicate submission -- new changes
    validateOpportunity() {
        console.log("validateOpportunity" + this.attachment);
        console.log(' @@ ContactId' + this.contactId);
        validateOpportunity({
                accountId: this.accountId,
                productId: this.productId,
                contactId: this.contactId,
                attachmentPoint: this.attachment
            })
            .then((data) => {
                console.log("Mydata" + JSON.stringify(data));
                if (data.status == true) {
                    console.log('validateOpportunity');
                    this.createOpportunityValidate(false);
                } else {
                    this.isShowDiffAgency = data.isShowDiffAgency;
                    this.isShowDuplicate = data.isShowDuplicate;
                    this.infoMsg = 'Click Submission name to go to existing Submission. Click Continue to create a new Submission';
                    this.errorLabel = data.errorMessage;
                    this.showDuplicateTable = data.showDuplicateList;
                    console.log('@@@this.showDuplicateTable::' + this.showDuplicateTable);

                    if (this.showDuplicateTable) {
                        if (this.isShowDuplicate) {
                            var tempOppList = [];
                            for (var i = 0; i < data.oppList.length; i++) {
                                let tempRecord = Object.assign({}, data.oppList[i]);
                                tempRecord.recordLink = "/" + tempRecord.Id;
                                tempOppList.push(tempRecord);
                            }
                            this.listDuplicateData = tempOppList;
                            this.duplicatePopUptitle = data.duplicatePopUptitle;
                            console.log('Duplicate: ' + this.isShowDuplicate + 'Title: ' + this.duplicatePopUptitle);
                        }
                        if (this.isShowDiffAgency) {
                            var tempOppAgencyList = [];
                            for (var i = 0; i < data.oppAgencyList.length; i++) {
                                let tempRecord = Object.assign({}, data.oppAgencyList[i]);
                                tempRecord.recordLink = "/" + tempRecord.Id;
                                tempOppAgencyList.push(tempRecord);
                            }
                            this.listDiffAgencyData = tempOppAgencyList;
                            this.diffAgencyPopUptitle = data.diffAgencyPopUptitle;
                            console.log('agency: ' + this.isShowDiffAgency + 'Title: ' + this.diffAgencyPopUptitle);
                        }

                        console.log('@@@this.listDuplicateData::' + this.listDuplicateData);
                    }

                    if (data.oppId != null) this.oppId = data.oppId;
                    //this.isConfirmOpenExistSubmission = true;
                    return;
                }


            })
            .catch((error) => {
                this.error = error;
            });
    }

    createOpportunityValidate(isDuplicate) {
            var dayPlus90 = new Date();
            dayPlus90.setDate(new Date().getDate() + 90); //add 90 days - 7397 - Khanh -03Jul2020
            const fields = {};

            fields[ACCOUNT_FIELD.fieldApiName] = this.accountId;
            // ADDED BY Ravi Start
            fetchProductName({ productId: this.productId })
                .then((result) => {
                    let productName = result.Name;
                    if (productName === 'Private Company Combo') {
                        //Added by Vinayesh. This field is not being used now.
                        //fields[COVERAGE_PRODUCT_OPTIONS_FIELD.fieldApiName] = 'D&O'; 
                        console.log("productName :", productName);
                    }

                 /*new Line by Navdeep on 07-02-2022 */
                    if(!this.isCelerity){
                      fields['Name'] = this.submissionName;
                    }
                    else{
                         var submissionNames = this.submissionName.split("PI");
                         fields['Name'] =  submissionNames[0] +''+productName;
                    }
              
                 

                    fields[PRODUCT_FIELD.fieldApiName] = this.productId;
                    fields[CLOSEDATE_FIELD.fieldApiName] = dayPlus90;
                    fields[STAGENAME_FIELD.fieldApiName] = "New";
                    fields[INNOVISK_ENTITY.fieldApiName] = this.rctName;
                    fields[CREATE_FROM_QP_FIELD.fieldApiName] = true;
                    fields[RECORDTYPE_FIELD.fieldApiName] = this.rctId;
                    if (this.isCelerity) {
                        fields[ACCOUNT_CLEARANCE.fieldApiName] = this.accountClearance;
                        fields[SERVICE_TO_RUN.fieldApiName] = this.serviceToRun;
                        // fields[Attachment_Point_FIELD.fieldApiName] = this.attachment;
                    }
                    if (!this.isCelerity) {
                        fields[MAIN_PROFESSION.fieldApiName] = this.mainprofession;
                        fields[LARGEST_WORK_TYPE.fieldApiName] = this.largestworktype;
                        fields[TRANSACTION_STATUS_FIELD.fieldApiName] = 'Active';
                    }

                    console.log(
                        " fields[COVERAGE_PRODUCT_OPTIONS_FIELD.fieldApiName]",
                        fields[COVERAGE_PRODUCT_OPTIONS_FIELD.fieldApiName]
                    );
                    console.log(
                        " fields[ACCOUNT_CLEARANCE.fieldApiName]",
                        fields[ACCOUNT_CLEARANCE.fieldApiName]
                    );
                    console.log(
                        "fields[CLOSEDATE_FIELD.fieldApiName] " +
                        fields[CLOSEDATE_FIELD.fieldApiName]
                    );
                    console.log("vinay new opp values: ", JSON.stringify(fields));
                    const recordInput = { apiName: OPPORTUNITY_OBJECT.objectApiName, fields };
                    createRecord(recordInput)
                        .then((opp) => {
                            console.log("@@@ oppo created succesfully", JSON.stringify(opp));
                            const fields = {};
                            fields[BROKER_CONTACT_FIELD.fieldApiName] = this.contactId;
                            fields[IS_PRIMARY_BROKER_FIELD.fieldApiName] = this.isPrimaryBroker;
                            fields[OPPORTUNITY_ID_FIELD.fieldApiName] = opp.id;
                            this.cyberIntelRequest(opp.id);
                            const recordInputBroker = {
                                apiName: BROKER_ACCOUNT_OBJECT.objectApiName,
                                fields
                            };
                            createRecord(recordInputBroker)
                                .then((broker) => {
                                    console.log("@@@ broker", broker);
                                    const createSubmission = new CustomEvent("next", {
                                        detail: {
                                            opportunity: opp,
                                            broker: broker
                                        }
                                    });
                                    this.handleCancel();
                                    this.dispatchEvent(createSubmission);

                                    console.log("@@@ isDuplicate outside", +isDuplicate);
                                    //Create a new Submission that has the same Insured Account (Opportunity Account), the same Product and a different Broker.
                                    if (isDuplicate == true) {
                                        console.log("@@@ isDuplicate", +isDuplicate);
                                        const fields = {};
                                        fields[ID_FIELD.fieldApiName] = opp.id;
                                        //fields[STAGENAME_FIELD.fieldApiName] = "Closed Lost";
                                        // fields[OPPORTUNITY_LOSS_REASON.fieldApiName] = "Duplicate submission";
                                        const recordInput = { fields };
                                        updateRecord(recordInput);
                                        //this.oppId = opp.id;
                                    }
                                })
                                .catch((e) => {
                                    console.log("Error creating broker:", e);
                                    this.dispatchEvent(
                                        new ShowToastEvent({
                                            title: "Error creating broker",
                                            message: e.body.message,
                                            variant: "error"
                                        })
                                    );
                                });
                        })
                        .catch((error) => {
                            console.log("Error create opp :", JSON.stringify(error));
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: "Error create submission",
                                    message: error.body.message,
                                    variant: "error"
                                })
                            );
                        });

                })
                .catch((error) => {
                    console.log("error:", JSON.stringify(error));
                });
            //// ADDED BY Ravi End

        }
        //end of method validate

    handleSelectedRecord(event) {
        this.contactId = null;
        console.log("Event " + JSON.stringify(event));
        const selectedRecordId = event.detail;
        //this.accountId = selectedRecordId.recordId;
        this.contactId = selectedRecordId.selectedId;
        console.log('selectedRecordId ' + JSON.stringify(selectedRecordId));
        console.log('contactId ' + JSON.stringify(this.contactId));
    }


    getaddress() {
        getaddress({ contactId: this.contactId })
            .then((result) => {
                this.BrokerAgencyOffice = result;
                console.log("Address" + result);
            })
            .catch((error) => {
                console.log("error message" + JSON.stringify(error));
            });
    }

    @track BrokerAgencyOffice;
    @track mainprofession;
    @track largestworktype;
    handleChangeInput(event) {
        switch (event.target.name) {
            case "productId":
                this.productId = event.target.value;
                this.checkProductType();
                break;

            case "contractId":
                this.contactId = event.target.value;
                console.log('New ContactId: ' + this.contactId);
                //this.getaddress(this.contactId);
                break;

            case "MainProfession":
                this.mainprofession = event.target.value;
                console.log('Main Profession: ' + this.mainprofession);
                break;

            case "LargestWorkType":
                this.largestworktype = event.target.value;
                break;

            case "relationshipType":
                this.relationship = event.target.value;
                break;
            case "primaryBroker":
                this.isPrimaryBroker = event.target.value;
                break;

            case "accountId":
                this.accountId = event.target.value;
                break;

            case "servicetoRun":
                this.serviceToRun = event.target.value;
                console.log("Service to Run Value -->" + this.serviceToRun);
                break;

                /*case "attachmentPoint":
                  if(this.rctName == 'Celerity'){ //Commented for US-40361
                    this.attachment = event.target.value;
                  }
                  else{
                    this.attachment = '';
                  }
                  console.log("case attachment" + this.attachment);
                  break;*/
        }
    }

    handlerConfirmOpenSubmission(event) {
        let status = event.detail.status;
        console.log("inside navigation mixin" + this.oppId);
        if (status == "confirm") {
            if (this.oppId) {
                console.log("inside navigation confirm" + this.oppId);
                this[NavigationMixin.Navigate]({
                    type: "standard__recordPage",
                    attributes: {
                        recordId: this.oppId,
                        objectApiName: "Opportunity",
                        actionName: "view"
                    }
                });
            } else {
                console.log("inside else navigation mixin" + this.oppId);
                this.createOpportunityValidate(true);
            }
        } else {
            console.log("inside else null navigation mixin" + this.oppId);
            this.oppId = null;
        }
        this.isConfirmOpenExistSubmission = false;
    }
    @track closePopup = false;
    handleLoad(e) {
        console.log("@@@ load ", e.detail);
    }
    handleError() {}
    handleSubmit(e) {}

    handleSuccess(e) {
        const payload = e.detail;
        console.log(JSON.stringify(payload));
    }
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
    accountClearanceCallout() {
        this.showSpinner = true;
        console.log("this.accountId:", this.accountId);
        console.log("this.productId:", this.productId);
        console.log("accountClearanceCallout this.attachment:", this.attachment);
        sendSubmissionDetails({ accId: this.accountId, productId: this.productId })
            .then((result) => {
                this.accountClearance = result;
                this.showSpinner = false;
                console.log("calling validate before!!");
                this.validateOpportunity();
            })
            .catch((error) => {
                this.showSpinner = false;
                console.log("error:", JSON.stringify(error));
                const toastEvent = new ShowToastEvent({
                    title: "Failure in Munich Clearance Callout",
                    message: error.message,
                    variant: error
                });
                this.dispatchEvent(toastEvent);
            });
    }
    checkProductType() {
        checkProductType({ ProductId: this.productId })
            .then((result) => {
                this.isCyber = result;
            })
            .catch((error) => {
                console.log("error message" + JSON.stringify(error));
            });
    }
    cyberIntelRequest(oppId) {
        let opportunityId = oppId;
        console.log("cyberIntelRequest");
        cyberIntelRequest({ submissionId: opportunityId })
            .then((result) => {
                console.log("result :", JSON.stringify(result));
            })
            .catch((error) => {
                console.log("error:", JSON.stringify(error));
            });
    }
}