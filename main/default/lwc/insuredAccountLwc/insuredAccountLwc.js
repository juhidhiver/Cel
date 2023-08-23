import { LightningElement, api, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import {
  updateRecord,
  createRecord,
  deleteRecord
} from "lightning/uiRecordApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import getProductName from "@salesforce/apex/InsureAccountController.getProductName";
import getListSectionSetting from "@salesforce/apex/InsureAccountController.getListSectionSetting";
import getRecordInfos from "@salesforce/apex/InsureAccountController.getRecordInfos";
import getAccountInfos from "@salesforce/apex/InsureAccountController.getAccountInfos";
import getAccountLossDetailByAccount from "@salesforce/apex/InsureAccountController.getAccountLossDetailByAccount";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import CONTACT_OBJECT from "@salesforce/schema/Contact";
import { refreshApex } from "@salesforce/apex";
import getObjectRecordTypeId from "@salesforce/apex/InsureAccountController.getObjectRecordTypeId";
import checkQuotedQuote from "@salesforce/apex/InsureAccountController.checkQuotedQuote";
import updateQuoteInProgress from "@salesforce/apex/InsureAccountController.updateQuoteInProgress";
import ACC_LOSS_DETAIL_QUOTE_CHANGE_TO_INPROGESS_CONFIRMATION from "@salesforce/label/c.ACC_LOSS_DETAIL_QUOTE_CHANGE_TO_INPROGESS_CONFIRMATION";
import updateQuoteStatusForAQ from "@salesforce/apex/InsureAccountController.updateQuoteStatusForAQ";
import getOpportunity from "@salesforce/apex/InsureAccountController.getOpportunity";
import updateSubmissionAccount from "@salesforce/apex/InsureAccountController.updateSubmissionAccount";
import validateSanctionCheckOnExistingAccount from "@salesforce/apex/CommonAccountUtil.validateSanctionCheckOnExistingAccount";


const ACCOUNT_BUSINESS_RT = "Business";
const CONTACT_BUSINESS_RT = "Business";

const PCC_PRODUCT_NAME = "Private Company Combo";

const QUOTE_PROCESS_STATUS_INSURED_INFO = "Insured Info";
const QUOTE_PROCESS_STATUS_SUBMISSION_INFO = "Submission Info";
const QUOTE_PROCESS_STATUS_CLEARANCE = "Clearance";

const actions = [
  { label: "Edit", name: "edit" },
  { label: "Delete", name: "delete" }
];

export default class InsuredAccountLwc extends LightningElement {
  label = {
    ACC_LOSS_DETAIL_QUOTE_CHANGE_TO_INPROGESS_CONFIRMATION
  };

  @track selectedAccountId = null;
  @track accName;
  @track contactId;
  @track isShowLossDetail = true;
  @api submissionStage;
  @track disableFirstTab = false;
  @track mapData = [];
  @track activeSections = [];
  @api recordId;
  @track isOpenDB = false;
  @track createRecord = false;

  //@track kycStatusOriginal;
  @track santionStatusOriginal;

  @track isAqueous;
  @track productName;
  //Added by Vinayesh
  @track showClearance = false;
  @track accountData = [];
  @api submissionType;

  @api oppRecord = null;
  @api isNameAddressUpdate = false;
  @api isBound = false;
  @track isCreatedNewAccount = false;
  
  /*added by Jai Start*/
  @wire(getOpportunity, { recordId :  "$recordId" })
  wireOpportunity({ error, data }) {
      if (data) {
        this.oppRecord = data;
        console.log("Opp:", this.oppRecord);
        if( this.oppRecord && this.oppRecord.Quotes && this.oppRecord.Quotes.length > 0){
          
            this.oppRecord.Quotes.forEach((quote) => {
            if( quote.Quote_Type__c == "Update Insured Name or Address" && !this.isNameAddressUpdate &&
              ( quote.Status == "In Progress" || quote.Status == "Quoted" || quote.Status == "Rated") ){
                this.isNameAddressUpdate = true;
            }
            if( quote.Status == "Bound" && !this.isBound ){
              this.isBound = true;
            }
          });
        }
        if( this.isBound ){
            this.disableFirstTab = true;
        }
        if(this.isNameAddressUpdate){
          this.disableFirstTab = false;
        }
        this.handleGetAccountInfo();

      } 
  }
/*added by Jai end*/

  contactRecordTypeBusiness = null;
  @wire(getObjectRecordTypeId, {
    sObjectName: "Contact",
    recordTypeName: "Business"
  })
  wireContactRecordType({ error, data }) {
    if (data) {
      this.contactRecordTypeBusiness = data;
      console.log(
        "contactRecordTypeBusiness :" + this.contactRecordTypeBusiness
      );
      this.recordInfo.fields.forEach((element) => {
        console.log("RecordId contact " +this.contactRecordTypeBusiness);
       if (element.name == "RecordTypeId") {
          element.value = this.contactRecordTypeBusiness;
          element.disabled = true;
        }
      });
    } else {
      console.log("error " + JSON.stringify(error));
    }
  }
 

   @wire(getProductName, { recordId: '$recordId'})
          getProductName({ error, data}) {
              if(data) {
                  this.productName = data;
                  if(this.productName == 'Professional Indemnity'){
                      this.isAqueous = true;
                      console.log("Child Stage cccc-->",this.submissionStage);
                      if(this.submissionStage == "Closed Won" || this.submissionStage == "Closed Lost" || this.submissionStage == "Declined" 
                      || this.submissionType == 'Full Amendment'){
                          this.disableFirstTab = true;
                      }
                      console.log('Product Name: '+this.productName);
                      console.log('isAqueous: '+this.isAqueous);
                  }
                  //Added by Vinayesh
                  else if(this.productName == PCC_PRODUCT_NAME){
                    this.showClearance = true;
                  }
              } else {
                  console.log('error ' + JSON.stringify(error));
              }
          }

//   getProductMethod() {
//     getProductName({ recordId: this.recordId })
//       .then((data) => {
//         this.productName = data;
//         if (this.productName == "Professional Indemnity") {
//           this.isAqueous = true;
//           console.log("Product Name: " + this.productName);
//           console.log("isAqueous: " + this.isAqueous);
//         }
//       })
//       .catch((error) => {
//         console.log("Error in product name" + JSON.stringify(error));
//       });
//   }

  accWireResult;
  @wire(getListSectionSetting, { recordId: "$recordId" })
  wireRecordType(result) {
    this.accWireResult = result;
    const { data, error } = result;
    console.log("wire record type :::::::::::" + this.recordId);
    if (data) {
      console.log("Section data:" + JSON.stringify(data));
      //console.log('wire record type 1111111 :::::::::::' + this.recordId);
      this.mapData = data.sections;
      this.activeSections = data.activeSections;
      this.selectedAccountId = data.accountId;
      if (!this.selectedAccountId) {
        getRecordInfos({ recordId: this.recordId }).then((quoteProcess) => {
          this.selectedAccountId = quoteProcess.Account__c;
          console.log("5555555555555555555:" + this.selectedAccountId);

          this.handleGetAccountInfo();


        });
      } else {
        //console.log('666666666666:' + this.selectedAccountId );

        this.handleGetAccountInfo();
      }
      //console.log(JSON.stringify(this.mapData));
    } else {
      console.log("error " + JSON.stringify(error));
    }
  }
  accountRecordTypeBusiness = null;
  @wire(getObjectRecordTypeId, {
    sObjectName: "Account",
    recordTypeName: "Business"
  })
  wireAccountRecordType({ error, data }) {
    if (data) {
      this.accountRecordTypeBusiness = data;
      console.log(
        "accountRecordTypeBusiness :" + this.accountRecordTypeBusiness
      );
    } else {
      console.log("error " + JSON.stringify(error));
    }
  }
 
  

  connectedCallback() {    
    console.log("RecordId " +this.recordId);
    this.accountRecordTypeBusiness = this.getRecordTypeByName(
      ACCOUNT_BUSINESS_RT,
      this.objectAccountInfo
    );
    console.log("accountRecordTypeBusiness contact " +this.accountRecordTypeBusiness);
   /* this.contactRecordTypeBusiness = this.getRecordTypeByName(
      CONTACT_BUSINESS_RT,
      this.objectContactInfo
    );*/
    this.recordInfo.fields.forEach((element) => {
      console.log("RecordId contact " +this.contactRecordTypeBusiness);
     /* if (element.name == "RecordTypeId") {
        element.value = this.contactRecordTypeBusiness;
        element.disabled = true;
      }*/
      if (element.name == "AccountId") {
        element.value = this.selectedAccountId;
      }
    });
  }

  getRecordTypeByName(recordTypeName, objectInfo) {
    if (objectInfo) {
      const recordtypeinfo = objectInfo.data.recordTypeInfos;
      return Object.keys(recordtypeinfo).find(
        (rti) => recordtypeinfo[rti].name === recordTypeName
      );
    }
  }

  @api
  handleAccountDataRefresh(){
    console.log('Inside account refresh');
    refreshApex(this.accWireResult);
  }

  handleSelection(event) {
    this.contactId = event.detail.selectedId;
  }

  handleLookUpChildSelection(event) {
    this.selectedAccountId = event.detail.selectedId;
    console.log("fields-->",JSON.stringify(this.recordInfo.fields));
    this.recordInfo.fields.forEach((element) => {
      if (element.name == "AccountId") {
        element.value = this.selectedAccountId;
      }
    });
    this.handleGetAccountInfo();
  }

  handleGetAccountInfo() {
    this.recordInfo.fields.forEach((element) => {
      if (element.name == "RecordTypeId") {
        element.value = this.contactRecordTypeBusiness;
        element.disabled = true;
      }
      if (element.name == "AccountId") {
        element.value = this.selectedAccountId;
      }
    });



    getAccountInfos({ recordId: this.selectedAccountId })
      .then((account) => {
        this.accountData = account;
        var listMainFields = [];
        var listSubMainFields = [];
        var mapDataJson = JSON.parse(JSON.stringify(this.mapData));
        var bound = JSON.parse(JSON.stringify(this.isBound));
        var addressName = JSON.parse(JSON.stringify(this.isNameAddressUpdate));
        //console.log('@@@ mapDataJson', mapDataJson, this.mapData);

        mapDataJson.forEach(function (item) {
          if (item.mainSectionFields) {
            listMainFields = item.mainSectionFields;
          }
          console.log('listMainFields:', JSON.stringify(listMainFields));
          console.log('bound', bound);
          if (item.subSectionChilds && !item.isComponent) {
            item.subSectionChilds.forEach(function (item1) {
              if (item1.subSectionChildFields) {
                item1.subSectionChildFields.forEach(function (item2) {
                  if( bound ){
                      item2.readOnly = true;
                  }
                  if(  addressName && (item2.sourceFieldApi == 'BillingAddress' || item2.sourceFieldApi == 'ShippingAddress') ){
                      item2.readOnly = false;
                  }
                  listSubMainFields.push(item2);
                });
              }
            });
          }
        });
        console.log("listSubMainFields: " , JSON.stringify(listSubMainFields) );
        if (listMainFields) {
          listMainFields.forEach(function (item) {
            if (item) {
              if( bound ){
                  item.readOnly = true;
              }
              if( addressName && item.sourceFieldApi == 'Id'){
                  item.readOnly = false;
              }
              item.value = account == null ? "" : account[item.sourceFieldApi];
            }
          });
        }
        if (listSubMainFields) {
          listSubMainFields.forEach(function (item) {
            if (item) {
              item.value = account == null ? "" : account[item.sourceFieldApi];
            }
          });
        }
        console.log('listMainFields:', JSON.stringify(listMainFields));
        console.log("listSubMainFields: " , JSON.stringify(listSubMainFields));
        this.mapData = mapDataJson;
        
      })
      .catch((error) => {
        console.log(
          "error handleLookUpChildSelection :" + JSON.stringify(error)
        );
      });
  }
  isChangeOnAccount = false;
  isDialogVisible = false;
  handleChangeQuoteProcessStatus() {
    if (!this.selectedAccountId) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error changing status",
          message: "Please save the account before moving to next",
          variant: "error"
        })
      );
      return;
    }

    //Check change on Account form
      
    this.template
      .querySelectorAll("c-insured-account-child-lwc")
      .forEach((element) => {
         if (!this.isChangeOnAccount)
                  this.isChangeOnAccount = element.checkChangesOnAccount();
          
        //if(isChangeOnAccount) return false;
        //console.log('Change account:' + element.checkChangesOnAccount());
      });
    if (this.isChangeOnAccount) {
      this.isDialogVisible = true;
      return;
    }
       //End

    if(this.isAqueous){
      validateSanctionCheckOnExistingAccount({accountId: this.selectedAccountId})
      .then((result) => {
        var status = QUOTE_PROCESS_STATUS_SUBMISSION_INFO;
        var infos = { status: status, accountId: this.selectedAccountId };
        const event = new CustomEvent("changequoteprocessstatus", {
          detail: infos
        });
        this.dispatchEvent(event);
        const event1 = new CustomEvent("refreshsanctionwarningbanner", {
          detail: infos
        });
        this.dispatchEvent(event1);
      })
      .catch((error) => {
        console.log("Error: " + JSON.stringify(error));
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error in Sanction Search",
            message: error.body.message,
            variant: "error"
          })
        );
      });
    }
    else{
      validateSanctionCheckOnExistingAccount({accountId: this.selectedAccountId})
      .then((result) => {
        var status = QUOTE_PROCESS_STATUS_SUBMISSION_INFO;
        if(this.productName == PCC_PRODUCT_NAME){
          status = QUOTE_PROCESS_STATUS_CLEARANCE;
        }
        
        var infos = { status: status, accountId: this.selectedAccountId };
        const event = new CustomEvent("changequoteprocessstatus", {
          detail: infos
        });
        this.dispatchEvent(event);
        const event2 = new CustomEvent("refreshsanctionwarningbanner", {
        });
        this.dispatchEvent(event2);
      })
      .catch((error) => {
        console.log("Error: " + JSON.stringify(error));
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error in Sanction Search",
            message: error.body.message,
            variant: "error"
          })
        );
      });
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
  checkIfAccountDataChanged(newData, oldData){
    for(var field in oldData){
      if(field == 'BillingAddress'){
        for(var addressField in oldData[field]){
          var newAddressFieldValue = newData['Billing'+addressField.charAt(0).toUpperCase() + addressField.slice(1)];
          if(newAddressFieldValue != undefined && oldData[field][addressField] != newAddressFieldValue){
            return true;
          }
        }
      }
    }
    for(var item in newData){
      if(!item.includes('Billing') || item.includes('Billing_County__c')){
        if((newData[item] != oldData[item] && (oldData[item] != undefined)) || ((oldData[item] === undefined) && newData[item])){ 
          return true;
        }
      }
    }
    return false;
  }

@api
  saveAccount() {
    this.isChangeOnAccount = false;
    this.isDialogVisible = false;
    var isAllValid = true;
    console.log("Save Account");
    var listMainFields = [];
    var mapDataJson = JSON.parse(JSON.stringify(this.mapData));
    mapDataJson.forEach(function (item) {
      if (item.mainSectionFields) {
        listMainFields = item.mainSectionFields;
      }
    });
    // console.log('listMainFields', listMainFields);
    var fields = {};
    this.template
      .querySelectorAll("c-insured-account-child-lwc")
      .forEach((insureAccountChild) => {
        var formInsureAccountChild = insureAccountChild.getValuesOnForm();
        if (formInsureAccountChild != null) {
          formInsureAccountChild.forEach((element) => {
            if (element.type != "address") {
              fields[element.key] = element.value;
              if (element.Name) {
                fields["Name"] = element.Name;
              }
            }
            if (element.type == "address") {
              var addressFieldKey = element.key;
              addressFieldKey = addressFieldKey.replace("Address", "");
              var addressFieldJson = JSON.parse(JSON.stringify(element));
              var addressField = addressFieldJson["value"];
              console.log('addressFieldJson -->'+JSON.stringify(addressFieldJson));
              console.log('addressField -->'+JSON.stringify(addressField));
              if (addressField) {
                fields[addressFieldKey + "Street"] = addressField.street;
                fields[addressFieldKey + "City"] = addressField.city;
                fields[addressFieldKey + "StateCode"] = addressField.province;
                fields[addressFieldKey + "CountryCode"] = addressField.country;
                fields[addressFieldKey + "PostalCode"] =
                  addressField.postalCode;
              }
            }
          });
        }
      });


  
    if (!this.selectedAccountId) {
     if (!fields["Name"]) {
        this.showToast("Error","Please add Account","error");
        return;
      }
    }
  
     
      if(this.isAqueous){

        // if (fields["BillingStateCode"] == 'England') {
        //   console.log('BillingStateCode-->'+fields["BillingStateCode"]);
        //   fields["BillingStateCode"] = 'KS';
        // }
          console.log('Product is Aqueous');
          if (!fields["BillingStreet"] || !fields["BillingCountryCode"]) {
            this.showToast("Error","Please add complete Address","error");
            return;
          }
      }
     

    if (!this.selectedAccountId) {
        // if (fields["KYC_Status__c"] || fields["KYC_Date__c"]) {
        //     if (fields["KYC_Date__c"] > new Date().toJSON().slice(0, 10)) {
        //         this.showToast("Error","KYC Date should not be greater than today's date","error"
        //         );
        //         return;
        //       } else {
        //           if(fields["KYC_Status__c"]) fields["KYC_Date__c"] = new Date().toJSON().slice(0, 10);
        //       }
        // }
        //if (fields["Sanction_Status__c"] || fields["Sanction_Date__c"]) {
        if (fields["AQ_Sanction_Status__c"] || fields["Sanction_Date__c"]) {
            if (fields["Sanction_Date__c"] > new Date().toJSON().slice(0, 10)) {
                this.showToast("Error","Sanction Date should not be greater than today's date","error"
                );
                return;
              } else {
                //if(fields["Sanction_Status__c"]) fields["Sanction_Date__c"] = new Date().toJSON().slice(0, 10);
                if(fields["AQ_Sanction_Status__c"]) fields["Sanction_Date__c"] = new Date().toJSON().slice(0, 10);
              }
        }


    } else {
      var accValues = {};
      accValues = this.mapData[0].subSectionChilds[1].subSectionChildFields;
      console.log("accValues : " + JSON.stringify(accValues));
      accValues.forEach((element) => {
        // if (element.sourceFieldApi == "KYC_Status__c") {
        //   this.kycStatusOriginal = element.value;
        // }
        //if (element.sourceFieldApi == "Sanction_Status__c") {
        if (element.sourceFieldApi == "AQ_Sanction_Status__c") {
          this.santionStatusOriginal = element.value;
        }
      });

      //var kycStatus = fields["KYC_Status__c"];
      //var SanctionStatus = fields["Sanction_Status__c"];
      var SanctionStatus = fields["AQ_Sanction_Status__c"];
      // if(fields["KYC_Status__c"] || fields["KYC_Date__c"]){
      //   if (fields["KYC_Date__c"] > new Date().toJSON().slice(0, 10)) {
      //       this.showToast("Error","KYC Date should not be greater than today's date","error"
      //       );
      //       return;
      //     } else {
      //       if ( this.kycStatusOriginal != kycStatus) {
      //         fields["KYC_Date__c"] = new Date().toJSON().slice(0, 10);
      //       }
      //     }
      // }
      //if(fields["Sanction_Status__c"] || fields["Sanction_Date__c"]){
      if(fields["AQ_Sanction_Status__c"] || fields["Sanction_Date__c"]){
        if (fields["Sanction_Date__c"] > new Date().toJSON().slice(0, 10)) {
            this.showToast("Error","Sanction Date should not be greater than today's date","error"
            );
            return;
          } else {
            if (this.santionStatusOriginal != SanctionStatus) {
              fields["Sanction_Date__c"] = new Date().toJSON().slice(0, 10);
            }
          }
     }
    }
    //console.log(fields["KYC_Status__c"], 'san ', fields["Sanction_Status__c"], 'date -- ', fields["KYC_Date__c"], fields["Sanction_Date__c"]);

    //console.log('isAllValid:' + isAllValid);
    if (isAllValid) {
      //console.log('Map Infos q:' + JSON.stringify(fields));
      //console.log('this.selectedAccountId:' + JSON.stringify(this.selectedAccountId));
      if (this.selectedAccountId) {
        if(this.isAqueous){
          validateSanctionCheckOnExistingAccount({accountId: this.selectedAccountId})
          .then((result) => {
            fields["Id"] = this.selectedAccountId;
            console.log("Account Field: " + JSON.stringify(fields));
            console.log("this.accountData: " + JSON.stringify(this.accountData));
            var isAccountDataChanged = false;
            const event1 = new CustomEvent("refreshsanctionwarningbanner", {
            });
            this.dispatchEvent(event1);
            isAccountDataChanged = this.checkIfAccountDataChanged(fields, this.accountData);
            console.log('isAccountDataChanged',isAccountDataChanged)
            const recordInput = { fields };
            if(isAccountDataChanged){
              updateRecord(recordInput)
                .then((account) => {
                  if(this.isAqueous){
                    updateSubmissionAccount( {sObjectId : this.recordId, accountId: this.selectedAccountId } )
                    .then( (result) => {
                      console.log(result);
                      this.handleGetAccountInfo();
                      //this.updateQuoteStatusforAQ();
                      this.dispatchEvent(
                        new ShowToastEvent({
                          title: "Success",
                          message: "Account updated",
                          variant: "success"
                        })
                      );
                      this.updateQuoteStatusforAQ();
                    });
                  }
                  else{
                    this.handleGetAccountInfo();
                    //this.updateQuoteStatusforAQ();
                    this.dispatchEvent(
                      new ShowToastEvent({
                        title: "Success",
                        message: "Account updated",
                        variant: "success"
                      })
                    );
                    this.updateQuoteStatusforAQ();
                  }
                  /*
                  this.handleGetAccountInfo();
                  //this.updateQuoteStatusforAQ();
                  this.dispatchEvent(
                    new ShowToastEvent({
                      title: "Success",
                      message: "Account updated",
                      variant: "success"
                    })
                  );
                  this.updateQuoteStatusforAQ();*/
                })
                .catch((error) => {
                  console.log("Error: " + JSON.stringify(error));
                  this.dispatchEvent(
                    new ShowToastEvent({
                      title: "Error creating record",
                      message: error.body.message,
                      variant: "error"
                    })
                  );
                });
              }
            })
          .catch((error) => {
            console.log("Error: " + JSON.stringify(error));
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Error in Sanction Search",
                message: error.body.message,
                variant: "error"
              })
            );
          });
        }
        else{
          validateSanctionCheckOnExistingAccount({accountId: this.selectedAccountId})
          .then((result) => {
            fields["Id"] = this.selectedAccountId;
            console.log("Account Field: " + JSON.stringify(fields));
            console.log("this.accountData: " + JSON.stringify(this.accountData));
            var isAccountDataChanged = false;
            isAccountDataChanged = this.checkIfAccountDataChanged(fields, this.accountData);
            console.log('isAccountDataChanged',isAccountDataChanged)
            const recordInput = { fields };
            if(isAccountDataChanged){
              updateRecord(recordInput)
                .then((account) => {
                  if(this.isAqueous){
                    updateSubmissionAccount( {sObjectId : this.recordId, accountId: this.selectedAccountId } )
                    .then( (result) => {
                      console.log(result);
                      this.handleGetAccountInfo();
                      //this.updateQuoteStatusforAQ();
                      this.dispatchEvent(
                        new ShowToastEvent({
                          title: "Success",
                          message: "Account updated",
                          variant: "success"
                        })
                      );
                      this.updateQuoteStatusforAQ();
                    });
                  }
                  else{
                    this.handleGetAccountInfo();
                    //this.updateQuoteStatusforAQ();
                    this.dispatchEvent(
                      new ShowToastEvent({
                        title: "Success",
                        message: "Account updated",
                        variant: "success"
                      })
                    );
                    this.updateQuoteStatusforAQ();
                  }
                  /*
                  this.handleGetAccountInfo();
                  //this.updateQuoteStatusforAQ();
                  this.dispatchEvent(
                    new ShowToastEvent({
                      title: "Success",
                      message: "Account updated",
                      variant: "success"
                    })
                  );
                  this.updateQuoteStatusforAQ();*/
                })
                .catch((error) => {
                  console.log("Error: " + JSON.stringify(error));
                  this.dispatchEvent(
                    new ShowToastEvent({
                      title: "Error creating record",
                      message: error.body.message,
                      variant: "error"
                    })
                  );
                });
              }
          })
          .catch((error) => {
            console.log("Error: " + JSON.stringify(error));
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Error in Sanction Search",
                message: error.body.message,
                variant: "error"
              })
            );
          });
        }
      } else {
        this.isCreatedNewAccount = true;
        // 01225000000EnmaAAC
        delete fields["Id"];
        /*
                        var recordTypeId;
                        listMainFields.forEach(item => {
                            if(item.sourceObject == 'Account' && item.sourceFieldApi == 'Id'){
                                recordTypeId = item.recordType;
                            }
                        })
                        if(recordTypeId){
                            fields['RecordTypeId'] = this.accountRecordTypeBusiness;//'01225000000EnmaAAC';//recordTypeId;
                        }*/
        if (this.accountRecordTypeBusiness) {
          fields["RecordTypeId"] = this.accountRecordTypeBusiness; //'01225000000EnmaAAC';//recordTypeId;
        }
        //if(this.isAqueous){
        fields['IsSyncSanctionSearch__c'] = true;
        //}
        const recordInput = { apiName: ACCOUNT_OBJECT.objectApiName, fields };
        //console.log('@@@ recordInput ',JSON.stringify(recordInput));
        createRecord(recordInput)
          .then((account) => {
          
            console.log("createRecord ", JSON.stringify(account));
            this.selectedAccountId = account.id;
             this.handleGetAccountInfo();
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Success",
                message: "Account created",
                variant: "success"
              })
            );
            //if(this.isAqueous){
             
            validateSanctionCheckOnExistingAccount({accountId: this.selectedAccountId})
            .then((result) => {
              console.log('result1'+JSON.stringify(result))
              console.log('updateQuoteStatusforAQ');
             // this.updateQuoteStatusforAQ();
       

              const event1 = new CustomEvent("insuredaccountsanctionwarningbanner", {
                detail: this.selectedAccountId
              });
              this.dispatchEvent(event1);

          
                if(result.length>0){
                  console.log('custom compact');
                    this.template.querySelector('c-custom-compact-lwc').getCompactTitle();
                    this.selectedAccountId = account.id;
                }
             
              /*var status = QUOTE_PROCESS_STATUS_SUBMISSION_INFO;
              var infos = { status: status, accountId: this.selectedAccountId };
              const event = new CustomEvent("changequoteprocessstatus", {
                detail: infos
              });
              this.dispatchEvent(event);*/
         
            })
            .catch((error) => {
              console.log("Error: " + JSON.stringify(error));
              this.dispatchEvent(
                new ShowToastEvent({
                  title: "Error in Sanction Search",
                  message: error.body.message,
                  variant: "error"
                })
              );
            });
          //}

            console.log('Created New Acc');
            console.log('this.selectedAccountId'+this.selectedAccountId);
           /* setTimeout(() => {   
              const event1 = new CustomEvent("insuredaccountsanctionwarningbanner", {
              detail: this.selectedAccountId
            });
            this.dispatchEvent(event1);
          }, 500);*/
          
          })
          .catch((error) => {
            console.log("Error: " + JSON.stringify(error));
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Error creating record",
                message: error.body.message,
                variant: "error"
              })
            );
          });
      }
    }
    if(this.isCreatedNewAccount==false && this.isAqueous){
    /**** New code on 26/04/2022 ********/
    const event1 = new CustomEvent("insuredaccountsanctionwarningbanner", {
      detail: this.selectedAccountId
    });
    this.dispatchEvent(event1);
  }
    /******* New code Ended on 26/04/2022 *********/

    return isAllValid;
  }

  /*
      saveAccount() {
          this.isChangeOnAccount = false;
          this.isDialogVisible = false;
          var isAllValid = true;
          console.log('Save Account');
          var listMainFields = [];
          var mapDataJson = JSON.parse(JSON.stringify(this.mapData));
          mapDataJson.forEach(function (item) {
              if (item.mainSectionFields) {
                  listMainFields = item.mainSectionFields;
              }
          });
          //console.log('listMainFields', listMainFields);
          var fields = {};
          this.template
              .querySelectorAll("c-generate-element-lwc")
              .forEach(element => {
                  var tmp = element.getValuesOnForm();
                  if (tmp != null) {
                      //console.log('tmp:' + JSON.stringify(tmp));
                      if (tmp.objectname == 'Account' && tmp.key == 'Id' && !tmp.value && !tmp.Name) {
                          //console.log('isAllValid :' + isAllValid);
                          this.template.querySelectorAll("c-generate-element-lwc").forEach(element => {
                              element.checkValidity();
                              isAllValid = false;
                          });
                      }
  
                      if (tmp.type != 'address')
                      {
                          fields[tmp.key] = tmp.value;
                          if (tmp.Name) {
                              fields['Name'] = tmp.Name;
                          }
                      }
                      if (tmp.type == 'address') {
                          var addressFieldKey = tmp.key;
                          addressFieldKey = addressFieldKey.replace('Address', '');
                          var addressFieldJson = JSON.parse(JSON.stringify(tmp));
                          var addressField = addressFieldJson['value'];
                          if(addressField) {
                              fields[addressFieldKey + 'Street'] = addressField.street;
                              fields[addressFieldKey + 'City'] = addressField.city;
                              fields[addressFieldKey + 'StateCode'] = addressField.province;
                              fields[addressFieldKey + 'CountryCode'] = addressField.country;
                              fields[addressFieldKey + 'PostalCode'] = addressField.postalCode;
                          }
                          
                      }
                  }
              });
          //console.log('isAllValid:' + isAllValid);
          if (isAllValid) {
              //console.log('Map Infos q:' + JSON.stringify(fields));
              //console.log('this.selectedAccountId:' + JSON.stringify(this.selectedAccountId));
              if (this.selectedAccountId) {
                  fields['Id'] = this.selectedAccountId;
                  const recordInput = { fields };
                  updateRecord(recordInput)
                      .then(account => {
                          this.dispatchEvent(
                              new ShowToastEvent({
                                  title: 'Success',
                                  message: 'Account updated',
                                  variant: 'success',
                              }),
                          );
                      })
                      .catch(error => {
                          this.dispatchEvent(
                              new ShowToastEvent({
                                  title: 'Error creating record',
                                  message: error.body.message,
                                  variant: 'error',
                              }),
                          );
                      });
              } else {
                  // 01225000000EnmaAAC
                  delete fields['Id'];
                  var recordTypeId;
                  listMainFields.forEach(item => {
                      if(item.sourceObject == 'Account' && item.sourceFieldApi == 'Id'){
                          recordTypeId = item.recordType;
                      }
                  })
                  if(recordTypeId){
                      fields['RecordTypeId'] = this.accountRecordTypeBusiness;//'01225000000EnmaAAC';//recordTypeId;
                  }
                  const recordInput = { apiName: ACCOUNT_OBJECT.objectApiName, fields };
                  //console.log('@@@ recordInput ',JSON.stringify(recordInput));
                  
                  createRecord(recordInput)
                      .then(account => {
                          console.log('createRecord ',JSON.stringify(account));
                          this.selectedAccountId = account.id;
                          this.dispatchEvent(
                              new ShowToastEvent({
                                  title: 'Success',
                                  message: 'Account created',
                                  variant: 'success',
                              }),
                          );
                      }).catch(error => {
                          this.dispatchEvent(
                              new ShowToastEvent({
                                  title: 'Error creating record',
                                  message: error.body.message,
                                  variant: 'error',
                              }),
                          );
                      });
              }
          }
      }*/

  //----D&B Account
  handleShowDB(event) {
    this.isOpenDB = true;
  }

  handleCreateAccountDB(event) {
    console.log("Account Fire" + JSON.stringify(event.detail));
    if (event.detail.accountdb) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "success",
          message:
            "The " +
            event.detail.accountdb.Name +
            " has been created successfully",
          variant: "success"
        })
      );
    }
    //console.log('event.detail.accountdb.Id' + event.detail.accountdb.Id);
    var isRefresh = true;
    if (this.selectedAccountId == null) {
      isRefresh = false;
    }
    this.selectedAccountId = event.detail.accountdb.Id;
    if (isRefresh) {
      this.template.querySelector('c-custom-compact-lwc').getCompactTitle();
    }

    this.handleGetAccountInfo();
    this.isOpenDB = false;
  }

  handleCancelDB(event) {
    this.isOpenDB = false;
    //reset attributes
  }

  handleClick(event) {
    if (event.detail !== 1) {
      if (event.detail.status === "confirm") {
        this.saveAccount();
      } else if (event.detail.status === "cancel") {
        this.isChangeOnAccount = false;
      }
    }
    this.isDialogVisible = false;
    var status = QUOTE_PROCESS_STATUS_SUBMISSION_INFO;
    //Added by Vinayesh. Need to move change quote proces to separate method 
    //as being used in multiple places.
    if(this.productName == PCC_PRODUCT_NAME){
      status = QUOTE_PROCESS_STATUS_CLEARANCE;
   }
    var infos = { status: status, accountId: this.selectedAccountId };
    const evt = new CustomEvent("changequoteprocessstatus", {
      detail: infos
    });
    this.dispatchEvent(evt);
  }
  //Account Loss detail
  @track isLoading = true;
  @track saving = false;
  @track openAccountLossDetail = false;
  @track openModalCreateAccountLossDetail = false;
  @track modeEditAccountLossDetail = false;
  @track modeCreatedAccountLossDetail = false;
  @api _data;
  get data() {
    return this._data;
  }
  set data(value) {
    this._data = value;
  }
  // @track columns = [
  //     {
  //         label: 'Account Loss Detail ID', fieldName: 'linkAccountLossDetailName', type: 'url',
  //         typeAttributes: { label: { fieldName: 'name' }, target: '_blank' }
  //     },
  //     { label: 'Loss Amount', fieldName: 'lossAmount', type: 'text' },
  //     { label: 'Number of Losses', fieldName: 'numberOfLosses', type: 'text' },
  //     { label: 'Product', fieldName: 'product', type: 'text' },
  //     { label: 'Status', fieldName: 'status', type: 'text' },
  //     { label: 'Year', fieldName: 'year', type: 'text' },
  //     {
  //         type: 'action',
  //         typeAttributes: {
  //             rowActions: actions,
  //         }
  //     },
  // ];
  @track columns = [
    {
      label: "Account Loss Detail ID",
      fieldName: "linkAccountLossDetailName",
      type: "url",
      typeAttributes: { label: { fieldName: "name" }, target: "_blank" }
    },
    { label: "Year", fieldName: "year", type: "text", sortable: true },
    { label: "Product", fieldName: "product", type: "text" },
    { label: "Number of Losses", fieldName: "numberOfLosses", type: "text" },
    {
      label: "Number of Open Losses ",
      fieldName: "numberOfOpenLosses",
      type: "text"
    },
    { label: "Loss Amount", fieldName: "lossAmount", type: "text" },
    {
      type: "action",
      typeAttributes: {
        rowActions: actions
      }
    }
  ];

  defaultSortDirection = 'desc';
  sortDirection = 'desc';

  wireResults;
  @wire(getAccountLossDetailByAccount, { accId: "$selectedAccountId" })
  wiredAccountLossDetail(result) {
    this.wireResults = result;
    const { data, error } = result;
    if (data) {
      console.log("@@@ mydata", JSON.stringify(data));
      this.data = data;
      this.isLoading = false;
    } else if (error) {
      console.log(JSON.stringify(error));
    }
  }
  openAccountLossDetailModel() {
    this.openAccountLossDetail = true;
  }
  handleCancelAccountLossDetail() {
    this.openAccountLossDetail = false;
  }

  handleAddSuccess(event) {
    this.saving = true;
    updateQuoteInProgress({ selectedAccountId: this.selectedAccountId })
      .then((result) => {})
      .catch((error) => {
        console.log("@@@error: " + JSON.stringify(error));
      });
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Success",
        message: "Record saved successfully with id: " + event.detail.id,
        variant: "success"
      })
    );
    this.handleCancel();
    this.isLoading = false;
    refreshApex(this.wireResults);
    setTimeout(() => {
      this.saving = false;
    }, 500);
  }

  handleEditSuccess(event) {
    updateQuoteInProgress({ selectedAccountId: this.selectedAccountId })
      .then((result) => {})
      .catch((error) => {
        console.log("@@@error: " + JSON.stringify(error));
      });
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Success",
        message: "Record updated successfully with id: " + event.detail.id,
        variant: "success"
      })
    );
    this.handleCancel();
    refreshApex(this.wireResults);
    this.isLoading = false;
  }
  handleCancel() {
    this.openModalCreateAccountLossDetail = false;
    this.modeCreatedAccountLossDetail = false;
    this.modeEditAccountLossDetail = false;
  }
  handleSubmit(event) {
    event.preventDefault();
    this.isLoading = true;
    const fields = event.detail.fields;
    console.log("@@@ fields", JSON.stringify(fields));
    this.template.querySelector("lightning-record-form").submit(fields);
  }
  handleOnLoad(event) {
    const detail = JSON.parse(JSON.stringify(event.detail));
    const record = detail.record;
    this.recordTypeId = record.recordTypeId;
    const fields = record.fields;
    fields.Quote__c = this.quoteId;
    console.log("fields:" + JSON.stringify(fields));
  }

  @track isConfirmEditModalVisible = false;
  @track isCopyToSubmissionLossDetail = false;
  @track isCreateAccLossDetail;
  @track isEditAccLossDetail;
  handleOpenCreateModal() {
    checkQuotedQuote({
      selectedAccountId: this.selectedAccountId,
      recordId: this.recordId
    })
      .then((result) => {
        console.log("@@@result: " + JSON.stringify(result));
        if (result.data) {
          // If any Quote has Quote Status = Quoted, the Quotes will need to be changed back to in process. Show the same warning message.
          this.isConfirmEditModalVisible = true;
          this.isCreateAccLossDetail = true;
        } else {
          this.openModalCreateAccountLossDetail = true;
          this.modeCreatedAccountLossDetail = true;
        }
      })
      .catch((error) => {
        console.log("@@@error: " + JSON.stringify(error));
      });
  }

  handlerConfirmEdit(event) {
    let status = event.detail.status;
    if (status == "confirm") {
      this.openModalCreateAccountLossDetail = true;
      if (this.isCreateAccLossDetail) {
        this.modeCreatedAccountLossDetail = true;
      } else if (this.isEditAccLossDetail) {
        this.modeEditAccountLossDetail = true;
      }
    }
    if (status == "cancel") {
    }
    this.isConfirmEditModalVisible = false;
  }

  handleRowClick(evt) {
    this.selectedRowId = evt.detail;
    console.log("@@@handleRowClick", JSON.stringify(e.detail));
  }
  handleDeleteRowSelected(event) {
    this.isLoading = true;
    var rowId = event.detail;
    console.log("@@@ handleDeleteRowSelected", rowId);
    deleteRecord(rowId)
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "Record deleted",
            variant: "success"
          })
        );
        this.isLoading = false;
        refreshApex(this.wireResults);
      })
      .catch((error) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error deleting record",
            message: error.body.message,
            variant: "error"
          })
        );
      });
  }
  handleUpdateRowSelected(event) {
    checkQuotedQuote({
      selectedAccountId: this.selectedAccountId,
      recordId: this.recordId
    })
      .then((result) => {
        if (result.data) {
          // If any Quote has Quote Status = Quoted, the Quotes will need to be changed back to in process. Show the same warning message.
          this.isConfirmEditModalVisible = true;
          this.isEditAccLossDetail = true;
          this.selectedRowId = event.detail;
        } else {
          // If dont have any Quote has Quote Status = Quoted, open modal to update Account Loss Detail
          this.openModalCreateAccountLossDetail = true;
          this.modeEditAccountLossDetail = true;
          this.selectedRowId = event.detail;
        }
      })
      .catch((error) => {
        console.log("@@@error: " + JSON.stringify(error));
      });
    // this.openModalCreateAccountLossDetail = true;
    // this.modeEditAccountLossDetail = true;
    // this.selectedRowId = event.detail;
    // console.log('@@@ handleUpdateRowSelected', this.selectedRowId);
  }

  @track recordInfo = {
    fields: [
      { name: "FirstName", value: null, initValue: false },
      { name: "RecordTypeId", value: null, initValue: true },
      { name: "LastName", value: null, initValue: false },
      { name: "Phone", value: null, initValue: false },
      { name: "AccountId", value: null, initValue: true },
      { name: "Email", value: null, initValue: false },
      { name: "Type__c", value: null, initValue: false },
      { name: "MailingAddress", value: null, initValue: false },
      { name: "Mailing_County__c", value: null, initValue: false },
      { name: "Description", value: null, initValue: false }
    ]
  };
  get recordInfoDefined() {
    return (
      this.recordInfo !== undefined && this.recordInfo.fields !== undefined
    );
  }

  renderedCallback() {
    const style = document.createElement("style");
    style.innerText = `
        .customProductCss .slds-listbox {
           height: 100px;
          }
        `;
    this.template.querySelector("div").appendChild(style);
  }
  updateQuoteStatusforAQ(){
    updateQuoteStatusForAQ({sObjectId: this.recordId})
    .then(result => console.log('Success in Quote Update'))
    //.error(error => console.log('@@error'+JSON.stringify(error)))
    












    
  }
}