import { LightningElement, api, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import {
  updateRecord,
  createRecord,
  deleteRecord,
  getRecordNotifyChange
} from "lightning/uiRecordApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import dnoClearedValidationText from '@salesforce/label/c.D_O_Cleared_Validation_Text';
import isDNOCleared from "@salesforce/apex/SubmissionConsoleLwcController.isDNOCleared";
import getProduct from "@salesforce/apex/SubmissionConsoleLwcController.getProduct";
import checkDeclineProcessForAccountChange from "@salesforce/apex/SubmissionConsoleLwcController.checkDeclineProcessForAccountChange";
import getListSectionSetting from "@salesforce/apex/SubmissionConsoleLwcController.getListSectionSetting";
import getRecordInfos from "@salesforce/apex/SubmissionConsoleLwcController.getRecordInfos";
import getAccountInfos from "@salesforce/apex/SubmissionConsoleLwcController.getAccountInfos";
import getOpp from '@salesforce/apex/SubmissionConsoleLwcController.getOpp';
import getBrokerInfos from '@salesforce/apex/SubmissionConsoleLwcController.getBrokerInfos';
import getDefaultRecordType from "@salesforce/apex/SubmissionConsoleLwcController.getDefaultRecordType";
import checkBoundSubmission from "@salesforce/apex/SubmissionConsoleLwcController.CheckBoundSubmission";
import checkProhibitedClassStatusForIndustry from "@salesforce/apex/SubmissionConsoleLwcController.getProhibitedClassStatusForIndustry";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import CONTACT_OBJECT from "@salesforce/schema/Contact";
import { refreshApex } from "@salesforce/apex";
import getObjectRecordTypeId from "@salesforce/apex/SubmissionConsoleLwcController.getObjectRecordTypeId";
import ACC_LOSS_DETAIL_QUOTE_CHANGE_TO_INPROGESS_CONFIRMATION from "@salesforce/label/c.ACC_LOSS_DETAIL_QUOTE_CHANGE_TO_INPROGESS_CONFIRMATION";

import validateOpportunity from "@salesforce/apex/OpportunityInitFormCmpController.validateOpportunity";

const ACCOUNT_BUSINESS_RT = "Business";
const CONTACT_BUSINESS_RT = "Business";

import ID_FIELD from "@salesforce/schema/Opportunity.Id";
import INNOVISK_ENTITY from "@salesforce/schema/Opportunity.Innovisk_Entity_ID__c";
import MAIN_PROFESSION from "@salesforce/schema/Opportunity.Main_Profession__c";
import LARGEST_WORK_TYPE from "@salesforce/schema/Opportunity.Largest_Work_Type__c";
import RECORDTYPE_FIELD from '@salesforce/schema/Opportunity.RecordTypeId';
import TYPE_FIELD from '@salesforce/schema/Opportunity.Type';
import ACCOUNT_FIELD from "@salesforce/schema/Opportunity.AccountId";
import COVERAGE_PRODUCT_OPTIONS_FIELD from "@salesforce/schema/Opportunity.Coverage_Product_Options__c";
import PRODUCT_FIELD from "@salesforce/schema/Opportunity.Product__c";
import STAGENAME_FIELD from "@salesforce/schema/Opportunity.StageName";
import OPPORTUNITY_LOSS_REASON from "@salesforce/schema/Opportunity.Loss_Reason__c";
import CREATE_FROM_QP_FIELD from "@salesforce/schema/Opportunity.Create_From_Quote_Process__c";
import OPPORTUNITY_OBJECT from "@salesforce/schema/Opportunity";
import Attachment_Point_FIELD from "@salesforce/schema/Opportunity.Attachment_Point__c";
import TRANSACTION_STATUS_FIELD from "@salesforce/schema/Opportunity.Transaction_Status__c";
import CLOSEDATE_FIELD from "@salesforce/schema/Opportunity.CloseDate";
import EFFECTIVE_DATE_FIELD from "@salesforce/schema/Opportunity.Effective_Date__c";
import RECEIVED_DATE_FIELD from "@salesforce/schema/Opportunity.Received_Date__c";
import EXPIRATION_DATE_FIELD from "@salesforce/schema/Opportunity.Expiration_Date__c";


import BROKER_ACCOUNT_OBJECT from "@salesforce/schema/Broker_Account__c";

import BROKER_CONTACT_FIELD from "@salesforce/schema/Broker_Account__c.Broker_Contact__c";
import RELATIONSHIP_TYPE_FIELD from "@salesforce/schema/Broker_Account__c.Relationship_Type__c";
import IS_PRIMARY_BROKER_FIELD from "@salesforce/schema/Broker_Account__c.IsPrimaryBroker__c";
import OPPORTUNITY_ID_FIELD from "@salesforce/schema/Broker_Account__c.Opportunity__c";

import QP_STATUS_FIELD from '@salesforce/schema/Quote_Process__c.Status__c';
import QP_ACCOUNT_FIELD from '@salesforce/schema/Quote_Process__c.Account__c';
import QP_SUBMISSION_ID from '@salesforce/schema/Quote_Process__c.Submission__c';
import QP_ID_FIELD from '@salesforce/schema/Quote_Process__c.Id';

// import { publish, MessageContext } from 'lightning/messageService';
// import refreshComponent from '@salesforce/messageChannel/refreshComponent__c';
import EffectiveDate from "@salesforce/schema/Order.EffectiveDate";

import DEFAULT_SUBMISSION_NAME from '@salesforce/label/c.DEFAULT_SUBMISSION_NAME_PCC';
import cloneExcessQuoteHandler from "@salesforce/apex/QuoteCompareItemWrapper.cloneExcessQuoteHandler";
import validateSanctionCheckOnExistingAccount from "@salesforce/apex/CommonAccountUtil.validateSanctionCheckOnExistingAccount";

const PCC_PRODUCT_NAME = "Private Company Combo";

const QUOTE_PROCESS_STATUS_INSURED_INFO = "Insured Info";
const QUOTE_PROCESS_STATUS_SUBMISSION_INFO = "Submission Info";
const QUOTE_PROCESS_STATUS_UNDERWRITING_CONSOLE = "Underwriting Console";

const actions = [
  { label: "Edit", name: "edit" },
  { label: "Delete", name: "delete" }
];

export default class SubmissionConsoleLwc extends LightningElement {
  label = {
    ACC_LOSS_DETAIL_QUOTE_CHANGE_TO_INPROGESS_CONFIRMATION
  };

  selectedAccountId = null;
  selectedBrokerContact = null;
  savedBrokerContactId;
  @api oppId = null;
  oppRecordTypeId = null;
  stageName;
  @track sectionSettingsData;
  @track quoteProcessId;
  @track brokerId;
  @track accName;
  @track contactId;
  @track billingCounty = '';
  @track isShowLossDetail = true;
  @api submissionStage;
  @track disableFirstTab = false;
  @track mapData = [];
  origMapData = [];
  @track activeSections = [];
  @api recordId;
  @track isOpenDB = false;
  @track createRecord = false;
  @track isLoadingInit = true;
  @api quoteObj;
  //@track kycStatusOriginal;
  @track santionStatusOriginal;

  @track isAqueous;
  @track productName;
  @track productId;
  //Added by Vinayesh
  @track showClearance = false;
  @track accountData = [];
  @api submissionType;

  @track isHavingAmendment = false;
  isBrokerContactChanged = false;
  isAddressChanged = false;
  boundDisabled = false;

  //added By Jai on 09-Nov-2021 for User Story - 52958--- code start----
  @track insuredState = '';
  //added By Jai on 09-Nov-2021 for User Story - 52958--- code end------

  @track columns = [
    {
      label: "Submission Name", initialWidth: 400, fieldName: "recordLink", type: "url",
      typeAttributes: { label: { fieldName: "Name" }, tooltip: "Name", target: "_blank" }
    },
    { label: 'Account', initialWidth: 250, fieldName: 'Account_Name', type: "text" },
    { label: "Broker Agency", initialWidth: 250, fieldName: 'Broker_Agency', type: "text" },
    { label: "Broker Producer", initialWidth: 250, fieldName: 'Broker_Producer', type: "text" },
    { label: 'Effective Date', initialWidth: 200, fieldName: 'Effective_Date', type: "date" },
    { label: "Stage", fieldName: "StageName", type: "text" },
  ];

  //  @track columns = [
  //   {
  //    label: "Submission Name", fieldName: "recordLink",  type: "url",
  //    typeAttributes: { label: { fieldName: "Name" }, tooltip:"Name", target: "_blank" }
  //   },
  //   { label: 'Account', fieldName: 'Account_Name', type: "text" },
  //   { label: "Broker Agency", fieldName: 'Broker_Agency', type: "text" },
  //   { label: "Broker Producer", fieldName: 'Broker_Producer', type: "text" },
  //   { label: 'Effective Date', fieldName: 'Effective_Date', type: "date" },
  //   { label: "Stage",  fieldName: "StageName", type: "text" },
  //  ];

  /**
   * Get product data.
   * @param {*} param0 
   */
  @wire(getProduct, { recordId: '$recordId' })
  getProduct({ error, data }) {
    if (data) {
      this.productName = data.Name;
      this.productId = data.Id;
      if (this.productName == 'Professional Indemnity') {
        this.isAqueous = true;
        if (this.submissionStage == "Closed Won" || this.submissionStage == "Closed Lost" || this.submissionStage == "Declined"
          || this.submissionType == 'Full Amendment') {
          this.disableFirstTab = true;
        }
      }
      //Added by Vinayesh
      else if (this.productName == PCC_PRODUCT_NAME) {
          this.showClearance = true;
      }
    } else {
      console.log("error " + JSON.stringify(error));
    }
  }
  // @wire(MessageContext)
  // messageContext;


  /**
   * Get section settings data for component and populate with defaults or field values if any.
   * @param {*} result 
   */
  @wire(getListSectionSetting, { recordId: "$recordId" })
  wireRecordType(result) {
    this.sectionSettingsData = result;
    let data = result.data;
    if (data) {
      this.isLoadingInit = true;
      this.mapData = data.sections;
      this.activeSections = data.activeSections;
      this.selectedAccountId = data.accountId;
      //this.updateComponentReadOnly(this.isHavingAmendment);
      getRecordInfos({ recordId: this.recordId }).then((quoteProcess) => {
        this.quoteProcessId = quoteProcess.Id;
        this.selectedAccountId = quoteProcess.Account__c;
        if (quoteProcess.Submission__c)
          this.oppId = quoteProcess.Submission__c;

        this.getRecordTypeId();
        this.setDataDefaults();
        if (this.selectedAccountId) {
          this.recordInfo.fields.forEach((element) => {
            if (element.name == "RecordTypeId") {
              element.value = this.contactRecordTypeBusiness;
              element.disabled = true;
            }
            if (element.name == "AccountId") {
              element.value = this.selectedAccountId;
            }
          });

          // this.handleGetRecordsInfo();
        }
        this.handleGetRecordsInfo();
        // else{
        //   this.isLoadingInit = false;
        // }         
      });
    } else {
      this.isLoadingInit = false;
      console.log("vinay loading error " + JSON.stringify(result.error));
    }
  }


  /**
   * Event handler when lookup field changed.
   */
  isChangeAccountOrBroker = false;
  handleLookUpChildSelection(event) {
    if (event.detail.fieldNameAPI == 'Id') {
      this.isChangeAccountOrBroker = true;
      this.selectedAccountId = event.detail.selectedId;
      if (this.accountData) {
        if (this.accountData['Id'] != this.selectedAccountId) {
          this.isAccountOrAddressChanged = true;
        }
      }
      this.recordInfo.fields.forEach((element) => {
        if (element.name == "AccountId") {
          element.value = this.selectedAccountId;
        }
      });
      this.getAccountInfo();
    }
    if (event.detail.fieldNameAPI == 'Broker_Contact__c') {
      this.isChangeAccountOrBroker = true;
      this.selectedBrokerContact = event.detail.selectedId;
    }
    // added by Jai on 11-Nov-2021 for User Story - 52958 ---code start----
    if(this.selectedAccountId == ""){
      this.insuredState = "";
    }
    else if (event.detail.fieldNameAPI == 'Insured State') {
      this.insuredState = event.detail.selectedId;
    }
    if(this.selectedBrokerContact != '' && this.selectedBrokerContact != undefined && this.insuredState != '' && this.insuredState != undefined){
      this.showMReClearanceSection();
    }else{
      this.hideMReClearanceSection();
    }
    // added by Jai on 11-Nov-2021 for User Story - 52958 ---code end----
    this.template.querySelectorAll("c-generate-element-lwc").forEach(element => {
      if (element.fieldName == event.detail.fieldNameAPI) {
        element.fieldValue = event.detail.selectedId;
      }
    });

  }

  /**
   * Created by Jai on 11-Nov-2021 for User Story - 52958
   * Method remove MRe Clearance section.
   */
  hideMReClearanceSection(){
    var el = this.template.querySelector("div[class=mresection]");
    console.log('el',el);
    if(el != null){
      el.style.display = 'none';
    }
  }
  /**
   * Created by Jai on 11-Nov-2021 for User Story - 52958
   * Method show MRe Clearance section.
   */
   showMReClearanceSection(){
    var el = this.template.querySelector("div[class=mresection]");
    console.log('el',el);
    if(el != null){
      el.style.display = 'block';
    }
  }

  /**
   * Method to set default values for component initialization.
   */
  setDataDefaults() {
    //setBrokerDefaults();
    var listFields = [];
    var listSubFields = [];
    var mapDataJson = JSON.parse(JSON.stringify(this.mapData));

    mapDataJson.forEach(function (item) {
      if (item.mainSectionTitle == 'Broker Information' && item.mainSectionFields) {
        listFields.push(...item.mainSectionFields);
      }

      if (item.subSectionChilds && !item.isComponent) {
        item.subSectionChilds.forEach(function (item1) {
          if (item1.subSectionChildTitle == 'Broker Information' && item1.subSectionChildFields) {
            item1.subSectionChildFields.forEach(function (item2) {
              listSubFields.push(item2);
            });
          }
        });
      }

    });

    if (listFields) {
      listFields.forEach(function (item) {
        if (item) {
          if (item.sourceFieldApi == 'Relationship_Type__c') {
            item.value = 'Broker';
          }
          if (item.sourceFieldApi == 'IsPrimaryBroker__c') {
            item.value = true;
          }
        }
      });
    }

    if (listSubFields) {
      listSubFields.forEach(function (item) {
        if (item) {
          if (item.sourceFieldApi == 'Relationship_Type__c') {
            item.value = 'Broker';
          }
          if (item.sourceFieldApi == 'IsPrimaryBroker__c') {
            item.value = true;
          }
        }
      });
    }

    this.mapData = mapDataJson;
  }

  /**
   * Method to fetch data for the component.
   */
  async handleGetRecordsInfo() {
    this.isLoadingInit = true;
    await this.getAccountInfo();
    if (this.oppId) {
      await this.getBrokerAccount();
      await this.getOpportunity();
    }
    this.isLoadingInit = false;
  }

  /**
   * Method to fetch account data.
   */
  async getAccountInfo() {
    this.isLoadingInit = true;
    await getAccountInfos({ recordId: this.selectedAccountId })
      .then((account) => {
        this.accountData = account;
        //added By Jai on 12-Nov-2021 for User Story - 52958--- code start----
        var billingAddressStateCode = '';
        //added By Jai on 12-Nov-2021 for User Story - 52958--- code end------
        console.log('Account data--> ', JSON.stringify(this.accountData))
        var listMainFields = [];
        var listSubMainFields = [];
        var mapDataJson = JSON.parse(JSON.stringify(this.mapData));


        mapDataJson.forEach(function (item) {
          if (item.mainSectionTitle == 'Account Information' && item.mainSectionFields) {
            listMainFields.push(...item.mainSectionFields);
          }

          if (item.subSectionChilds && !item.isComponent) {
            item.subSectionChilds.forEach(function (item1) {
              if (item1.subSectionChildTitle == 'Account Information' && item1.subSectionChildFields) {
                item1.subSectionChildFields.forEach(function (item2) {
                  listSubMainFields.push(item2);
                });
              }
            });
          }
          console.log(
            "listSubMainFields: " + JSON.stringify(listSubMainFields)
          );
        });
        if (listMainFields) {
          listMainFields.forEach(function (item) {
            if (item) {
              item.value = account == null ? "" : account[item.sourceFieldApi];
              // added By Jai on 12-Nov-2021 for User Story - 52958--- code start----
              if(item.sourceFieldApi && item.sourceFieldApi == "BillingAddress"){
                console.log('item.value : ',item.value);
                if(item.value != "" && item.value.stateCode){
                  billingAddressStateCode = item.value.stateCode;
                }
              }
              // added By Jai on 12-Nov-2021 for User Story - 52958--- code end------
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
        // added By Jai on 12-Nov-2021 for User Story - 52958--- code start----
        if(billingAddressStateCode != ''){
          this.insuredState = billingAddressStateCode;
        }
        if(this.accountData == null || this.accountData == "" || this.accountData == undefined){
          this.insuredState = '';
        }
        if(this.selectedBrokerContact != '' && this.selectedBrokerContact != undefined && this.insuredState != '' && this.insuredState != undefined){
          this.showMReClearanceSection();
        }else{
          this.hideMReClearanceSection();
        }
        // added By Jai on 12-Nov-2021 for User Story - 52958--- code end----
        this.mapData = mapDataJson;
        this.mapData.forEach(function (item) {
          item.mainSectionFields.forEach(function (item1) {
          });
        });
        this.isLoadingInit = false;

      })
      .catch((error) => {
        this.isLoadingInit = false;
        console.log(
          "error handleLookUpChildSelection :" + JSON.stringify(error)
        );
      });
  }

  async getOpportunity() {
    this.isLoadingInit = true;
    await getOpp({
      oppId: this.oppId
    })
      .then((result) => {
        console.log('result', result);
        var oppRec = result ;
        this.stageName = result.StageName;
        this.setPCCReadOnlyFields();
        this.oppRecordTypeId = oppRec[RECORDTYPE_FIELD.fieldApiName];
        ////added by Jai to make editabe in case of an Amendment type quote
        if( oppRec.Quotes && oppRec.Quotes.length > 0 ){
          this.quoteObj = oppRec.Quotes[0];
          this.isHavingAmendment = true;
          this.boundDisabled = false;
          this.updateComponentReadOnly(this.isHavingAmendment);
        }
        ////added by Jai to make editabe in case of an Amendment type quote
        var listMainFields = [];
        var listSubMainFields = [];
        var mapDataJson = JSON.parse(JSON.stringify(this.mapData));

        mapDataJson.forEach(function (item) {
          if (item.mainSectionTitle == 'Submission Information' && item.mainSectionFields) {
            listMainFields.push(...item.mainSectionFields);
          }

          if (item.subSectionChilds && !item.isComponent) {
            item.subSectionChilds.forEach(function (item1) {
              if (item1.subSectionChildTitle == 'Submission Information' && item1.subSectionChildFields) {
                item1.subSectionChildFields.forEach(function (item2) {
                  listSubMainFields.push(item2);
                });
              }
            });
          }
        });
        if (listMainFields) {
          listMainFields.forEach(function (item) {
            if (item) {
              item.value = oppRec == null ? "" : oppRec[item.sourceFieldApi];
            }
          });
        }
        if (listSubMainFields) {
          listSubMainFields.forEach(function (item) {
            if (item) {
              item.value = oppRec == null ? "" : oppRec[item.sourceFieldApi];
            }
          });
        }
        this.mapData = mapDataJson;
        this.mapData.forEach(function (item) {
          item.mainSectionFields.forEach(function (item1) {
          });

        });

        //this.getBrokerAccount();
        this.origMapData = JSON.parse(JSON.stringify(this.mapData));
        console.log('vinay original map data: ' + JSON.stringify(this.origMapData));
        this.isLoadingInit = false;
      })
      .catch((error) => {
        this.isLoadingInit = false;
        console.log('@@@error 2: ' + JSON.stringify(error));
      })
  }

  async getBrokerAccount() {
    this.isLoadingInit = true;
    await getBrokerInfos({
      oppId: this.oppId
    })
      .then((result) => {
        var brokerAcc = result;
        if (!brokerAcc) {
          this.setDataDefaults();
        } else {
          this.brokerId = brokerAcc["Id"];
          this.savedBrokerContactId = brokerAcc[BROKER_CONTACT_FIELD.fieldApiName];
          this.selectedBrokerContact = brokerAcc[BROKER_CONTACT_FIELD.fieldApiName];

          var listMainFields = [];
          var listSubMainFields = [];
          var mapDataJson = JSON.parse(JSON.stringify(this.mapData));

          mapDataJson.forEach(function (item) {
            if (item.mainSectionTitle == 'Broker Information' && item.mainSectionFields) {
              listMainFields.push(...item.mainSectionFields);
            }

            if (item.subSectionChilds && !item.isComponent) {
              item.subSectionChilds.forEach(function (item1) {
                if (item1.subSectionChildFields && item1.subSectionChildTitle == "Broker Information") {
                  item1.subSectionChildFields.forEach(function (item2) {
                    listSubMainFields.push(item2);
                  });
                }
              });
            }
          });
          if (listMainFields) {
            listMainFields.forEach(function (item) {
              if (item) {
                item.value = brokerAcc == null ? "" : brokerAcc[item.sourceFieldApi];
              }
            });
          }
          if (listSubMainFields) {
            listSubMainFields.forEach(function (item) {
              if (item) {
                item.value = brokerAcc == null ? "" : brokerAcc[item.sourceFieldApi];
              }
            });
          }

          // added By Jai on 10-Nov-2021 for User Story - 52958--- code start----
          if(this.selectedBrokerContact){
            let obj = mapDataJson.find(i => i.mainSectionTitle === "Account Information");
            let tempList2 = obj.mainSectionFields;
            if(tempList2){
              let obj2 = tempList2.find(i => i.sourceFieldApi === "BillingAddress");
              if(obj2 && obj2.value && obj2.value.stateCode){
                this.insuredState = obj2.value.stateCode;
              }
            }
            this.showMReClearanceSection();
          }
          else{
            this.hideMReClearanceSection();
          }
          //added By Jai on 10-Nov-2021 for User Story - 52958--- code end------

          this.mapData = mapDataJson;
          this.mapData.forEach(function (item) {
            item.mainSectionFields.forEach(function (item1) {
            });

          });
        }
        this.isLoadingInit = false;
      })
      .catch((error) => {
        this.isLoadingInit = false;
        console.log('@@@error 2: ' + JSON.stringify(error));
      })
  }


  /**
   * Event handler for page next button click.
   */
  isChangeOnAccount = false;
  isDialogVisible = false;
  isChangeQuoteProcessStatus = false;

  async handleChangeQuoteProcessStatus() {
    //const dnoCleared = await isDNOCleared({ submissionId : this.oppId});
    // if(dnoCleared){
    //     this.isChangeQuoteProcessStatus = true;
      
        //Check change on Account form

        // this.template
        //   .querySelectorAll("c-insured-account-child-lwc")
        //   .forEach((element) => {
        //      if (!this.isChangeOnAccount)
        //               this.isChangeOnAccount = element.checkChangesOnAccount();

        //     //if(isChangeOnAccount) return false;
        //     //console.log('Change account:' + element.checkChangesOnAccount());
        //   });
        // if (this.isChangeOnAccount) {
        //   this.isDialogVisible = true;
        //   return;
        // }
        //End
    //     await this.handleSave();
    // }else
    //     this.showToast('Error', dnoClearedValidationText, 'error');

      this.isChangeQuoteProcessStatus = true;
      await this.handleSave();
      await validateSanctionCheckOnExistingAccount({accountId: this.selectedAccountId})
      .then((result) => {
        const event1 = new CustomEvent("refreshsanctionwarningbanner", {
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


  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(event);
  }

  checkIfAccountDataChanged(newData, oldData) {
    for (var field in oldData) {
      if (field == 'BillingAddress') {
        for (var addressField in oldData[field]) {
          var newAddressFieldValue = newData['Billing' + addressField.charAt(0).toUpperCase() + addressField.slice(1)];
          if (newAddressFieldValue != undefined && oldData[field][addressField] != newAddressFieldValue) {
            return true;
          }
        }
      }
    }
    for (var item in newData) {
      if (!item.includes('Billing') || item.includes('Billing_County__c')) {
        if ((newData[item] != oldData[item] && (oldData[item] != undefined)) || ((oldData[item] === undefined) && newData[item])) {
          return true;
        }
      }
    }
    return false;
  }



  /**
   * On Path button click this method is called from parent component.
   */
  isNavigateButtonClick = false;
  @api
  async handleSaveOnNavigate() {
    this.isNavigateButtonClick = true;
    return await this.handleSave();
  }


  /**
   * Method to save data for the component.
   * @returns true or false. If data not valid returns false. If valid data then performs save and returns true.
   */
  @api
  async handleSave() {
    var isAllValid = true;
    this.isPostSaveValid = true;
    this.checkAccountAddressChanged();

    if (this.isNavigateButtonClick || this.isChangeQuoteProcessStatus) {
      isAllValid = this.checkValidity();
    }
    else {
      isAllValid = this.checkAccountValidity();
    }

    
    //** When account or address changed we do not allow user to save before performing MRE clearance again */
    if (this.isAccountOrAddressChanged && !this.callClearance) {
       const declineProducts = await checkDeclineProcessForAccountChange({ oppId : this.oppId});
       //For Address change 'Decline' all products
       if(declineProducts){
        //Commenting declining products now because they will be declined when user performs Mre again.
        //  if (this.template.querySelector("c-combo-product-selection-lwc")) {
        //     await this.template.querySelector("c-combo-product-selection-lwc").declineAllProducts();
        //  }
          this.dispatchEvent(
            new ShowToastEvent({
              message: 'MRE Clearance needs to be checked again in case of Account or Address change.',
              variant: 'error',
            }),
          );
          this.template.querySelector("c-combo-product-selection-lwc").focusComponent();
          //this.validityUserMessage += 'MRE Clearance needs to be checked again in case of Account or Address change.';
          isAllValid = false;
       }    
    }

    if (!isAllValid) {
      //These boolean variables need to be set in resetSaveModes method.
      this.isChangeQuoteProcessStatus = false;
      this.isNavigateButtonClick = false;
      this.callClearance = false;
      if (this.validityUserMessage && this.validityUserMessage != '') {
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Required data not entered!',
            message: this.validityUserMessage,
            variant: 'error',
          }),
        );
      }
      return isAllValid;
    }


    if (isAllValid && this.validateDuplicate && this.isChangeAccountOrBroker) {
      this.isLoadingInit = true;
      isAllValid = await this.validateOpportunity();
      if (!isAllValid) {
        return isAllValid;
      }
    }
    this.isChangeOnAccount = false;
    this.isDialogVisible = false;
    this.isLoadingInit = true;

    var listMainFields = [];
    var mapDataJson = JSON.parse(JSON.stringify(this.mapData));
    mapDataJson.forEach(function (item) {
      if (item.mainSectionFields) {
        listMainFields = item.mainSectionFields;
      }
    });
    var accFields = {};
    var oppFields = {};
    var brokerFields = {};
    this.template
      .querySelectorAll('lightning-input-field')
      .forEach(element => {
        if (element.value) {
          oppFields[element.fieldName] = element.value;
        }
      });

    this.template
      .querySelectorAll('c-generate-element-lwc')
      .forEach(element => {
        var tmp = element.getValuesOnForm();
        if (tmp != null && tmp.objectName == 'Account') {
          // if (tmp.objectname == 'Account' && tmp.key == 'Id' && !tmp.value && !tmp.Name) {
          //     this.template.querySelectorAll("c-generate-element-lwc").forEach(element => {
          //         element.checkValidity();
          //         isAllValid = false;
          //     });
          // }

          if (tmp.type != 'address') {
            accFields[tmp.key] = tmp.value;
            if (tmp.Name) {
              accFields["Name"] = tmp.Name;
            }
          }
          if (tmp.type == 'address') {
            var addressFieldKey = tmp.key;
            addressFieldKey = addressFieldKey.replace('Address', '');
            var addressFieldJson = JSON.parse(JSON.stringify(tmp));
            var addressField = addressFieldJson['value'];
            if (addressField) {
              accFields[addressFieldKey + 'Street'] = addressField.street;
              accFields[addressFieldKey + 'City'] = addressField.city;
              accFields[addressFieldKey + 'StateCode'] = addressField.province;
              accFields[addressFieldKey + 'CountryCode'] = addressField.country;
              accFields[addressFieldKey + 'PostalCode'] = addressField.postalCode;
            }
            if (this.isAccountOrAddressChanged || !this.accountData) {
              accFields['Billing_County__c'] = addressField.county;
            }

          }
        }
        if (tmp != null && tmp.objectName == 'Opportunity') {

          if (tmp.format != 'address') {
            oppFields[tmp.key] = tmp.value;
          }
        }
        if (tmp != null && tmp.objectName == 'Broker_Account__c') {

          if (tmp.format != 'address') {
            if (tmp.key == 'Broker_Contact__c' && tmp.value != this.savedBrokerContactId) {
              this.isBrokerContactChanged = true;
            }
            brokerFields[tmp.key] = tmp.value;
          }
        }
      });

    let formEdited = this.checkFormDataEdited(accFields, oppFields, brokerFields);

    if (isAllValid && formEdited) {
      if (!this.selectedAccountId) {
        delete accFields["Id"];
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
        accFields["RecordTypeId"] = this.accountRecordTypeBusiness; //'01225000000EnmaAAC';//recordTypeId;
        accFields["IsSyncSanctionSearch__c"] = true;
        const recordInput = { apiName: ACCOUNT_OBJECT.objectApiName, fields: accFields };
        await createRecord(recordInput)
          .then((account) => {
            this.selectedAccountId = account.id;
            //this.handleGetAccountInfo();
            validateSanctionCheckOnExistingAccount({accountId: this.selectedAccountId})
            .then((result) => {
              const event1 = new CustomEvent("refreshsanctionwarningbanner", {
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

      } else {
        const recordInput = { fields: accFields };
        await updateRecord(recordInput)
          .then((account) => {
            validateSanctionCheckOnExistingAccount({accountId: this.selectedAccountId})
            .then((result) => {
              const event1 = new CustomEvent("refreshsanctionwarningbanner", {
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

      await this.updateSubmission(oppFields, brokerFields);

      await this.updateQuoteProcess(false);
      this.isChangeAccountOrBroker = false;
      if (this.isChangeQuoteProcessStatus || this.isNavigateButtonClick) {
        this.handleGetRecordsInfo();
      }
    }
    if (this.isChangeQuoteProcessStatus || this.isNavigateButtonClick) {
      // this.handleGetRecordsInfo();
      let postSaveIsValid = await this.checkPostSaveValidity();
      if (!postSaveIsValid) {
        isAllValid = false;
      }
    }

    if (!isAllValid) {
      this.isChangeQuoteProcessStatus = false;
      this.isNavigateButtonClick = false;
      this.callClearance = false;
      this.dispatchEvent(
        new ShowToastEvent({
          title: this.postSaveValidityUserMessage,
          variant: 'error',
        }),
      );
      // this.handleGetRecordsInfo();
      //this.refreshProductSelection();
    }
    else {
      if (formEdited) {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success!",
            message: "Record is saved !",
            variant: "success"
          })
        );
      }
      await this.postSaveActions();
    }
    this.isLoadingInit = false;
    return isAllValid;
  }

  /**
   * Method to perform post save actions like refresh screen and navigation.
   */
  async postSaveActions() {
    if (this.callClearance) {
      // if(this.isChangeAccountOrBroker){
      //   if(this.template.querySelector("c-combo-product-selection-lwc")){
      //     this.template.querySelector("c-combo-product-selection-lwc").populateClearanceCompletedProducts();
      //   }
      // }
      // if(this.isAddressChanged || this.isChangeAccountOrBroker){
      //    this.refreshProductSelection();
      // }
      this.isLoadingInit = false;
      if (this.template.querySelector("c-combo-product-selection-lwc")) {
        await this.template.querySelector("c-combo-product-selection-lwc").processClearanceApi(this.isAccountOrAddressChanged);
      }

      this.callClearance = false;
      this.isLoadingInit = true;
      
      this.handleGetRecordsInfo();
    }
    else if (this.isChangeQuoteProcessStatus) {

      await this.updateQuoteProcess(true);

      var status = QUOTE_PROCESS_STATUS_SUBMISSION_INFO;
      if (this.productName == PCC_PRODUCT_NAME) {
        status = QUOTE_PROCESS_STATUS_UNDERWRITING_CONSOLE;
      }

      this.isChangeQuoteProcessStatus = false;

      // var infos = { status: status, accountId: null};
      // const event = new CustomEvent("changequoteprocessstatus", {
      //   detail: infos
      // });
      // this.dispatchEvent(event);
      var infos = { status: status, oppId: this.oppId };
      const event = new CustomEvent("navigatenext", {
        detail: infos
      });
      this.dispatchEvent(event);

    }
    else if (this.isNavigateButtonClick) {
      this.isNavigateButtonClick = false;
    }
    else {
      this.handleGetRecordsInfo();
    }
    this.setPCCReadOnlyFields();
    //this.refreshProductSelection();
    //this.isChangeAccountOrBroker = false;
    this.isAddressChanged = false;
    this.isAccountOrAddressChanged = false;
    this.isLoadingInit = false;
    // this.handleGetRecordsInfo();
    //refreshApex(this.sectionSettingsData);

    //getRecordNotifyChange([{recordId: this.recordId}]);
    //c/commonRelatedListLwceval("$A.get('e.force:refreshView').fire();");
  }


  async updateSubmission(oppFields, brokerFields) {
    if (!this.oppId) {
      oppFields[ACCOUNT_FIELD.fieldApiName] = this.selectedAccountId;
      oppFields[PRODUCT_FIELD.fieldApiName] = this.productId;
      if (!oppFields[CLOSEDATE_FIELD.fieldApiName]) {
        var dayPlus90 = new Date();
        dayPlus90.setDate(new Date().getDate() + 90);
        oppFields[CLOSEDATE_FIELD.fieldApiName] = dayPlus90;
      }
      oppFields[STAGENAME_FIELD.fieldApiName] = "New";
      oppFields[TYPE_FIELD.fieldApiName] = "New Business";
      oppFields[INNOVISK_ENTITY.fieldApiName] = this.rctName;
      oppFields[CREATE_FROM_QP_FIELD.fieldApiName] = true;
      oppFields[RECORDTYPE_FIELD.fieldApiName] = this.rctId;

      //Deleting date fields if they dont have value as defaults are being set on opportunity object.
      if (!oppFields[EFFECTIVE_DATE_FIELD.fieldApiName]) {
        delete oppFields[EFFECTIVE_DATE_FIELD.fieldApiName];
      }
      if (!oppFields[RECEIVED_DATE_FIELD.fieldApiName]) {
        delete oppFields[RECEIVED_DATE_FIELD.fieldApiName];
      }
      if (!oppFields[EXPIRATION_DATE_FIELD.fieldApiName]) {
        delete oppFields[EXPIRATION_DATE_FIELD.fieldApiName];
      }
      const recordInput = { apiName: OPPORTUNITY_OBJECT.objectApiName, fields: oppFields };
      await createRecord(recordInput)
        .then((opp) => {
          this.oppId = opp.id;
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
      await this.updateBrokerAccount(brokerFields);
    } else {
      oppFields[ID_FIELD.fieldApiName] = this.oppId;
      oppFields[ACCOUNT_FIELD.fieldApiName] = this.selectedAccountId;
      const recordInput = { fields: oppFields };
      await updateRecord(recordInput)
        .then(() => {})
        .catch(error => {
          console.log('Error during submission update :' + JSON.stringify(error));
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Error update Submission',
              message: error.body.message,
              variant: 'error',
            }),
          );
        });
        /*******  Update Broker only if it is broker fields are enabled by Jai ******/
        var isBrokerUpdable = true;
        var mapDataJson = JSON.parse(JSON.stringify(this.mapData));
        mapDataJson.forEach(item => {
          if (item.subSectionChilds && !item.isComponent) {
            item.subSectionChilds.forEach(function (item1) {
              if (item1.subSectionChildFields) {
                item1.subSectionChildFields.forEach(function (sField) {
                  if( sField.sourceFieldApi == 'Broker_Contact__c' && sField.readOnly ){
                    isBrokerUpdable = false;
                  }                  
                });
              }
            });
          }
        });
        /*******  Update Broker only if it is broker fields are enabled by Jai******/
        if( isBrokerUpdable ){
          await this.updateBrokerAccount(brokerFields);
        }

    }
  }

  /**
   * Method for post save validations to be performed when user wants to navigate from this page.
   */
  postSaveValidityUserMessage = '';
  async checkPostSaveValidity() {
   let isValid = true;
   this.postSaveValidityUserMessage = '';
     
    if(this.isChangeQuoteProcessStatus || this.isNavigateButtonClick){
      const dnoCleared = await isDNOCleared({ submissionId : this.oppId});
      if(!dnoCleared){
         this.postSaveValidityUserMessage = dnoClearedValidationText;
         isValid = false;
         //this.showToast('Error', dnoClearedValidationText, 'error');
      }
    }

  
   //  if ((this.isNavigateButtonClick || this.isChangeQuoteProcessStatus) && this.template.querySelector("c-combo-product-selection-lwc")) {
   //    var clearanceDataAvailable = await this.template.querySelector("c-combo-product-selection-lwc").checkPoliAvailable();
   //    if (!clearanceDataAvailable) {
   //      this.postSaveValidityUserMessage += 'Please select Products for MRE Clearance before moving to Underwriting Console.';
   //      isValid = false;
   //    }
   //  }

    await checkProhibitedClassStatusForIndustry({ oppId: this.oppId })
      .then((result) => {
        if (result) {
          if (result != '') {
            this.postSaveValidityUserMessage += result;
            isValid = false;
          }
        }

      })
      .catch((error) => {
        console.log(
          "error prohibited product check :" + JSON.stringify(error)
        );
        isValid = false;
      });

   //  if (this.isAccountOrAddressChanged) {
   //    this.postSaveValidityUserMessage += 'MRE Clearance needs to be checked again in case of Account or Address change.';
   //    isValid = false;
   //  }

    return isValid;
  }


  /**
   * Validation check for form data.
   */
  validityUserMessage = '';
  checkValidity() {
    let isValid = true;
    this.validityUserMessage = '';

    isValid = this.checkAccountValidity();

    this.template.querySelectorAll("c-generate-element-lwc").forEach(element => {
      var tmp = element.getValuesOnForm();
      if (tmp.objectName == 'Broker_Account__c')
        if (tmp.objectName == 'Broker_Account__c' && tmp.key == 'Broker_Contact__c' && !tmp.value && (!tmp.Name || tmp.Name == '')) {
          if (this.validityUserMessage == '') {
            this.validityUserMessage = 'Please enter Broker';
          }
          else {
            this.validityUserMessage += ', Broker';
          }
          element.checkValidity();
          isValid = false;
        }
    });

    this.template.querySelectorAll('lightning-input-field').forEach(element => {
      let picklistValidity = element.reportValidity();
      if (!picklistValidity) {
        if (element.fieldName == 'Industry__c') {
          if (this.validityUserMessage == '') {
            this.validityUserMessage = 'Please select Industry and Service Classification';
          }
          else {
            this.validityUserMessage += ', Please select Industry and Service Classification';
          }
        }
        if (element.fieldName == 'Service_Classification__c') {
          if (this.validityUserMessage == '') {
            this.validityUserMessage = 'Please select Industry and Service Classification';
          }
          else {
            this.validityUserMessage += ', Please select Industry and Service Classification';
          }
        }

        isValid = false;
      }

    });

    return isValid;
  }

  /**
   * Validation check for non navigation related save.
   */
  checkAccountValidity() {
    let isValid = true;
    this.validityUserMessage = '';
    this.template.querySelectorAll("c-generate-element-lwc").forEach(element => {
      var tmp = element.getValuesOnForm();
      console.log('vinay address validity data: ' + JSON.stringify(tmp));
      if (tmp.objectName == 'Account' && tmp.key == 'Id' && !tmp.value && (!tmp.Name || tmp.Name == '')) {
        this.validityUserMessage = 'Please enter Account';
        element.checkValidity();
        isValid = false;
        return;
      }
      if (this.oppId && (tmp.key == 'Effective_Date__c') && !tmp.value) {
        this.validityUserMessage += ' Please enter Effective Date';
        element.checkValidity();
        isValid = false;
        return;
      }

      if (tmp && tmp.objectName == 'Account' && tmp.type == 'address') {
        var addressFieldKey = tmp.key;
        addressFieldKey = addressFieldKey.replace('Address', '');
        var addressFieldJson = JSON.parse(JSON.stringify(tmp));
        var addressField = addressFieldJson['value'];
        console.log('address state validity: ' + JSON.stringify(addressField));
        if (!addressField || !addressField.province) {
          if (this.validityUserMessage == '') {
            this.validityUserMessage = 'Please enter Address State';
          }
          else {
            this.validityUserMessage += ', Address State';
          }
          element.checkValidity();
          isValid = false;
        }

      }
    });

    return isValid;
  }


  /**
 * Check if address changed.
 */
  checkAccountAddressChanged() {
    this.template
      .querySelectorAll('c-generate-element-lwc')
      .forEach(element => {
        var tmp = element.getValuesOnForm();
        if (tmp != null && tmp.objectName == 'Account' && tmp.type == 'address' && this.accountData && this.accountData.BillingAddress != null) {
          console.log('Account Info-->', this.accountData.BillingAddress.street)
          //console.log('Address change-->', addressField.street)

          // check for Address change in MRE clearance

          var addressFieldKey = tmp.key;
          addressFieldKey = addressFieldKey.replace('Address', '');
          var addressFieldJson = JSON.parse(JSON.stringify(tmp));
          var addressField = addressFieldJson['value'];
          console.log('address changed check: ' + JSON.stringify(addressField));
          console.log('address changed check1: ' + JSON.stringify(this.accountData.BillingAddress));
          console.log('Clearance check at Sub console post Save')
          if (this.accountData.BillingAddress.street != addressField.street
            || this.accountData.BillingAddress.city != addressField.city
            || this.accountData.BillingAddress.postalCode != addressField.postalCode
            || this.accountData.BillingAddress.countryCode != addressField.country
            || this.accountData.BillingAddress.stateCode != addressField.province) {
            console.log('Address changed check at Sub Console');
            this.isAddressChanged = true;
            this.isAccountOrAddressChanged = true;
          }

        }
      });
  }

  //isFormEdited = false;
  /**
  * Check if selected account or Address changed.
  */
  checkFormDataEdited(accFields, oppFields, brokerFields) {
    let listOrigMainFields = [];
    let listOrigSubFields = [];
    // let listMainFields = [];
    // let listSubFields = [];
    this.origMapData.forEach(function (item) {
      if (item.mainSectionFields) {
        listOrigMainFields.push(...item.mainSectionFields);
      }

      if (item.subSectionChilds && !item.isComponent) {
        item.subSectionChilds.forEach(function (item1) {
          if (item1.subSectionChildFields) {
            listOrigSubFields.push(...item1.subSectionChildFields);
          }
        });
      }
    });

    let dataEdited = false;
    if (listOrigMainFields) {
      listOrigMainFields.forEach(function (item) {
        if (item) {
          if (item.sourceObject == 'Account') {
            if (item.format == 'Address') {
              if ((accFields['BillingStreet'] != item.value.street) && (accFields['BillingStreet'] || item.value.street) ||
                (accFields['BillingCity'] != item.value.city) && (accFields['BillingCity'] || item.value.city) ||
                (accFields['BillingStateCode'] != item.value.stateCode) && (accFields['BillingStateCode'] || item.value.stateCode) ||
                (accFields['BillingCountryCode'] != item.value.countryCode) && (accFields['BillingCountryCode'] || item.value.countryCode) ||
                (accFields['BillingPostalCode'] != item.value.postalCode) && (accFields['BillingPostalCode'] || item.value.postalCode)) {
                dataEdited = true;
              }
            }
            else {
              if ((accFields[item.sourceFieldApi] != item.value) && (accFields[item.sourceFieldApi] || item.value)) {
                dataEdited = true;
                console.log('vinay old form : ' + item.value);
                console.log('vinay new form : ' + accFields[item.sourceFieldApi]);
              }
            }
          }
          else {
            if ((oppFields[item.sourceFieldApi] != item.value) && (oppFields[item.sourceFieldApi] || item.value)) {
              dataEdited = true;
            }
          }
        }
      });
    }
    if (listOrigSubFields) {
      listOrigSubFields.forEach(function (item) {
        if (item) {
          if ((brokerFields[item.sourceFieldApi] != item.value) && (brokerFields[item.sourceFieldApi] || item.value)) {
            dataEdited = true;
          }
        }
      });
    }

    //this.isFormEdited = dataEdited;

    console.log('vinay check form edited: ' + this.isFormEdited);
    return dataEdited;
    // this.mapData.forEach(function (item) {
    //   if (item.mainSectionFields) {
    //     listMainFields.push(...item.mainSectionFields);
    //   }

    //   if (item.subSectionChilds && !item.isComponent) {
    //     item.subSectionChilds.forEach(function (item1) {
    //       if (item1.subSectionChildFields) {
    //           listSubFields.push(...item1.subSectionChildFields);
    //       }
    //     });
    //   }

    // });
  }


  isAccountOrAddressChanged = false;
  /**
  * Check if selected account or Address changed.
  */
  checkSelectedAccountOrAddressChanged() {
    this.template
      .querySelectorAll('c-generate-element-lwc')
      .forEach(element => {
        var tmp = element.getValuesOnForm();
        if (tmp != null && tmp.objectName == 'Account' && tmp.key == 'Id' && this.accountData && this.selectedAccountId) {
          console.log('[vinay check account changed: ' + this.accountData['Id']);
          if (this.accountData['Id'] != this.selectedAccountId) {
            this.isAccountOrAddressChanged = true;
          }
        }
        if (tmp != null && tmp.objectName == 'Account' && tmp.type == 'address' && this.accountData && this.accountData.BillingAddress != null) {
          console.log('Account Info-->', this.accountData.BillingAddress.street)
          //console.log('Address change-->', addressField.street)

          // check for Address change in MRE clearance

          var addressFieldKey = tmp.key;
          addressFieldKey = addressFieldKey.replace('Address', '');
          var addressFieldJson = JSON.parse(JSON.stringify(tmp));
          var addressField = addressFieldJson['value'];
          console.log('address changed check: ' + JSON.stringify(addressField));
          console.log('address changed check1: ' + JSON.stringify(this.accountData.BillingAddress));
          console.log('Clearance check at Sub console post Save')
          if (this.accountData.BillingAddress.street != addressField.street
            || this.accountData.BillingAddress.city != addressField.city
            || this.accountData.BillingAddress.postalCode != addressField.postalCode
            || this.accountData.BillingAddress.countryCode != addressField.country
            || this.accountData.BillingAddress.stateCode != addressField.province) {
            console.log('Address changed check at Sub Console')
            this.isAddressChanged = true;
            this.isAccountOrAddressChanged = true;
          }

        }
      });

    console.log('vinay check account changed: ' + this.isAccountOrAddressChanged);
  }

  /**
   * Validation check before clearance.
   */
  validityUserMessage = '';
  checkValidityForMreClearance() {
    let isValid = true;
    this.template.querySelectorAll("c-generate-element-lwc").forEach(element => {
      var tmp = element.getValuesOnForm();
      if (this.oppId && (tmp.key == 'Effective_Date__c') && !tmp.value) {
        element.checkValidity();
        this.showToast('', 'Please enter Effective Date before clearance check!', 'error');
        isValid = false;
      }
    });
    return isValid;
  }
  /**
   * Will contain list of all Events PRE Mre call
   */

  //  async handlePreMREEvents(){
  //    console.log('Pre save check??')
  //     this.callClearance = true
  //     // Save before calling MRE clearance    
  //     await this.handleSave();
  //  }

  /**
   * Event handler for clearance call.
   */
  @track callClearance = false;
  handleclearancevalidate() {
    this.isAddressChanged = false;
    this.callClearance = true;
    this.checkAccountAddressChanged();
    this.handleSave();
    // if(!this.oppId || !this.selectedAccountId || (this.oppId && this.isAddressChanged)){
    //   this.handleSave();
    // }
    // else{
    //    if(this.checkValidityForMreClearance()){
    //       if(this.template.querySelector("c-combo-product-selection-lwc")){
    //         // this.template.querySelector("c-combo-product-selection-lwc").processClearanceApi().then(result=>console.log(result));
    //         this.template.querySelector("c-combo-product-selection-lwc").processClearanceApi(this.isAddressChanged);
    //       }
    //       this.callClearance = false;
    //    }      
    // }
  }

  // handleClearanceValidateApi(){
  //   this.callClearance = true;
  //   if(!this.oppId){
  //     this.handleSave();
  //   }
  //   else{
  //      if(this.checkValidityForMreClearance()){
  //         if(this.template.querySelector("c-combo-product-selection-lwc")){
  //           // this.template.querySelector("c-combo-product-selection-lwc").processClearanceApi().then(result=>console.log(result));
  //           this.template.querySelector("c-combo-product-selection-lwc").processClearanceApi().then(()=> console.log('Api call done!!')).catch((error)=>console.log(error))
  //         }
  //         this.callClearance = false;
  //      }      
  //   }
  // }


  async updateBrokerAccount(brokerFields) {
    
    brokerFields[OPPORTUNITY_ID_FIELD.fieldApiName] = this.oppId;
    if (!this.brokerId && brokerFields[BROKER_CONTACT_FIELD.fieldApiName]) {
      // fields[IS_PRIMARY_BROKER_FIELD.fieldApiName] = this.isPrimaryBroker;
      //this.cyberIntelRequest(opp.id);
      const recordInputBroker = {
        apiName: BROKER_ACCOUNT_OBJECT.objectApiName,
        fields: brokerFields
      };
      await createRecord(recordInputBroker)
        .then((broker) => {
          this.brokerId = broker.id;

          //this.refreshProductSelection();
          //this.updateQuoteProcess();

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

    }
    else if (this.brokerId && brokerFields[BROKER_CONTACT_FIELD.fieldApiName]) {
      //Removing opp id field from update call.
      brokerFields["Id"] = this.brokerId;
      //delete brokerFields[BROKER_CONTACT_FIELD.fieldApiName];
      delete brokerFields[OPPORTUNITY_ID_FIELD.fieldApiName];
      const recordInput = { fields: brokerFields };
      await updateRecord(recordInput)
        .then(() => {
          //this.isBrokerContactChanged = false;
          //getRecordNotifyChange([{recordId: this.quoteProcessId}]);                 
        })
        .catch(error => {
          console.log('Error during submission update :' + JSON.stringify(error));
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Error update Submission',
              message: error.body.message,
              variant: 'error',
            }),
          );
        });
    }

  }

  /**
   * Update quote process when submission updated.
   */
  async updateQuoteProcess(navigateNext) {
    const fields = {};
    fields[QP_ID_FIELD.fieldApiName] = this.quoteProcessId;
    fields[QP_ACCOUNT_FIELD.fieldApiName] = this.selectedAccountId;
    fields[QP_SUBMISSION_ID.fieldApiName] = this.oppId;
    if (navigateNext) {
      if (this.isChangeQuoteProcessStatus) {
        if (this.productName == 'Private Company Combo') {
          fields[QP_STATUS_FIELD.fieldApiName] = QUOTE_PROCESS_STATUS_UNDERWRITING_CONSOLE;
        }
        else {
          fields[QP_STATUS_FIELD.fieldApiName] = QUOTE_PROCESS_STATUS_SUBMISSION_INFO;
        }
      }
    }
    const recordInput = { fields };
    await updateRecord(recordInput)
      .then(() => {
      })
      .catch(error => {
        console.log('Error during update Quote Process :' + JSON.stringify(error));
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Error update Quote Process',
            message: error.body.message,
            variant: 'error',
          }),
        );
      });
    // await this.updateQPFields(fields, postSaveIsValid);
  }


  @track diffAgencyPopUptitle;
  @track duplicatePopUptitle;
  @track infoMsg;
  @track isShowDuplicate;
  @track isShowDiffAgency;
  @track isContinueDisabled = false;
  validateDuplicate = true;
  showDuplicateTable = false;
  @track listDuplicateData = [];
  @track listDiffAgencyData = [];

  /**
   * Validate duplicate submission.
   */
  async validateOpportunity() {
    //console.log(' @@ ContactId'+this.selectedBrokerContact);
    if(!this.selectedAccountId) return true;
    let isNotDuplicate = true;
    await validateOpportunity({
      accountId: this.selectedAccountId,
      productId: this.productId,
      contactId: this.selectedBrokerContact,
      attachmentPoint: null
    })
      .then((data) => {
        if (data.status == true) {
          isNotDuplicate = true;
          //this.createOpportunityValidate(false);
        }
        else {
          let tempOppList = [];
          let tempOppAgencyList = [];
          if (data.oppList) {
            tempOppList = Object.assign([], data.oppList);
          }
          if (data.oppAgencyList) {
            tempOppAgencyList = Object.assign([], data.oppAgencyList);
          }

          if (tempOppList) {
            tempOppList = tempOppList.filter(opp => opp.Id != this.oppId);
            tempOppList = tempOppList.filter(opp => opp.Name != DEFAULT_SUBMISSION_NAME);
          }
          if (tempOppAgencyList) {
            tempOppAgencyList = tempOppAgencyList.filter(opp => opp.Id != this.oppId);
            tempOppAgencyList = tempOppAgencyList.filter(opp => opp.Name != DEFAULT_SUBMISSION_NAME);
          }
          //   if(data.oppAgencyList.length > 0){
          //     data.oppAgencyList = data.oppAgencyList.filter(opp => opp.Id != this.oppId);
          //  }


          if (tempOppList.length > 0 || tempOppAgencyList.length > 0) {
            this.isLoadingInit = false;
            this.isShowDiffAgency = tempOppAgencyList.length > 0; //data.isShowDiffAgency;
            this.isShowDuplicate = tempOppList.length > 0;//data.isShowDuplicate;//true;
            this.infoMsg = 'Click Submission name to go to existing Submission. Click Continue to create a new Submission';
            this.errorLabel = data.errorMessage;
            this.showDuplicateTable = data.showDuplicateList;

            if (this.showDuplicateTable) {
              if (this.isShowDuplicate) {
                var tempOppListDuplicate = [];
                for (var i = 0; i < tempOppList.length; i++) {
                  let tempRecord = Object.assign({}, tempOppList[i]);
                  tempRecord.recordLink = "/" + tempRecord.Id;
                  tempOppListDuplicate.push(tempRecord);
                }
                //     for (var i = 0; i < data.oppAgencyList.length; i++) {
                //       let tempRecord = Object.assign({}, data.oppAgencyList[i]);
                //       tempRecord.recordLink = "/" + tempRecord.Id;
                //       tempOppList.push(tempRecord);
                //  }
                this.listDuplicateData = tempOppListDuplicate;
                this.duplicatePopUptitle = data.duplicatePopUptitle;
              }

              if (this.isShowDiffAgency) {
                var tempOppAgencyListDuplicate = [];
                for (var i = 0; i < tempOppAgencyList.length; i++) {
                  let tempRecord = Object.assign({}, tempOppAgencyList[i]);
                  tempRecord.recordLink = "/" + tempRecord.Id;
                  tempOppAgencyListDuplicate.push(tempRecord);
                }
                this.listDiffAgencyData = tempOppAgencyListDuplicate;
                this.diffAgencyPopUptitle = data.diffAgencyPopUptitle;
              }
            }

            //if (data.oppId != null) this.oppId = data.oppId;
            //this.isConfirmOpenExistSubmission = true;
            isNotDuplicate = false;
          }
        }

      })
      .catch((error) => {
        this.error = error;
      });

    return isNotDuplicate;
  }

  /**
   * Event handle for continue button click on duplicate submission popup.
   */
  async handleCreateNew() {
    this.showDuplicateTable = false;
    this.validateDuplicate = false;
    await this.handleSave();
    this.validateDuplicate = true;
  }

  /**
   * Event to track change in the Industry and Service Classificcation required fields.
   * @param {:} event 
   */
  handlePicklistChange(event) {
    let currTarget = event.currentTarget;
    //currTarget.setCustomValidity("");
    if (!event.target.value) {
      currTarget.reportValidity();
    }
  }

  /**
   * Refresh product selection component on update of submission
   */
  refreshProductSelection() {
    if (this.template.querySelector("c-combo-product-selection-lwc")) {
      this.template.querySelector("c-combo-product-selection-lwc").refreshView();
    }
    //  const payload = { recordId: this.oppId };
    //  publish(this.messageContext, refreshComponent, payload);
  }

  /**
   * Event handler for close button click on duplicate submission popup.
   */
  handleClose() {
    // this.isNextDisabled=false;
    // this.isContinueDisabled=false;
    this.showDuplicateTable = false;
    this.isChangeQuoteProcessStatus = false;
    // this.isConfirmOpenExistSubmission = false;
  }

  @track isCelerity;
  @track rctName;
  @track rctId;
  getRecordTypeId() {
    getDefaultRecordType({ quoteProcessId: this.quoteProcessId })
      .then((result) => {
        if (result) {

          this.rctName = result.split('__')[1];
          this.rctId = result.split('__')[0];

          if (this.rctName == 'Celerity') {
            this.isCelerity = true;
            // this.attachment = 'Primary'; //Commented for US-40361
          }

        } else {
          console.log("getRecordType error:");
        }
      })
      .catch((error) => {
        console.log(
          "error getRecordType :" + JSON.stringify(error)
        );
      });
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
    } else {
      console.log("error " + JSON.stringify(error));
    }
  }

  connectedCallback() {
    console.log("RecordId " + this.recordId);
    this.accountRecordTypeBusiness = this.getRecordTypeByName(
      ACCOUNT_BUSINESS_RT,
      this.objectAccountInfo
    );
    this.contactRecordTypeBusiness = this.getRecordTypeByName(
      CONTACT_BUSINESS_RT,
      this.objectContactInfo
    );
    this.recordInfo.fields.forEach((element) => {
      if (element.name == "RecordTypeId") {
        element.value = this.contactRecordTypeBusiness;
        element.disabled = true;
      }
      if (element.name == "AccountId") {
        element.value = this.selectedAccountId;
      }
    });
  }

  renderedCallback() {
    if (this.oppId) {
      checkBoundSubmission({ oppId: this.oppId })
        .then((result) => {
            console.log('vinay check bound opp:' + result );
          // this.updateComponentReadOnly(this.isHavingAmendment);
            if( !this.isHavingAmendment ){ //added by Jai to make editabe in case of an Amendment type quote
                if (result && !this.boundDisabled ) {
                  console.log('vinay check bound disabled:' + this.boundDisabled);
                  this.boundDisabled = result;
                  this.updateComponentReadOnly(this.isHavingAmendment);
                }
                else {
                  this.boundDisabled = result;
                }
            }else{ //added by Jai to make editabe in case of an Amendment type quote
                this.boundDisabled = false;
            }
        });
    }
  }

  setPCCReadOnlyFields(){
    if((this.stageName == 'Closed Won' || this.stageName === 'Declined') && this.productName === PCC_PRODUCT_NAME){
      var mapDataJson = JSON.parse(JSON.stringify(this.mapData));
      mapDataJson.forEach(item => {
          let mainSectionFields = item.mainSectionFields;
          if(this.stageName === 'Declined')
            mainSectionFields = item.mainSectionFields.filter(sField => (sField.sourceFieldApi != 'StageName'));
          mainSectionFields.forEach(function (sField) {
            sField.readOnly = true;    
          });
          if (item.subSectionChilds && !item.isComponent) {
            item.subSectionChilds.forEach(function (item1) {
              if (item1.subSectionChildFields) {
                item1.subSectionChildFields.forEach(function (sField) {
                  sField.readOnly = true;
                });
              }
            });
          }
      });
      this.mapData = mapDataJson;
    }
  }

  /**
   * Make all fields except Stage read only for bound submission. Need to check if account fields can be editable.
   */
  updateComponentReadOnly( isAmendment) {
    var mapDataJson = JSON.parse(JSON.stringify(this.mapData));
    console.log('quoteObj=',this.quoteObj);
    var quoteType = this.quoteObj.Quote_Type__c;
    mapDataJson.forEach(item => {
      if( item.mainSectionTitle == 'Account Information'){
        if (item.mainSectionFields) {
          item.mainSectionFields.forEach(function (sField) {
            if( isAmendment ){
                sField.readOnly = false;
            }else{
              sField.readOnly = true;
            } 
            console.log('sField='+sField.sourceFieldApi, 'readonly='+sField.readOnly);
          });
        }
      }else if( item.mainSectionTitle == 'Submission Information'){
        if (item.mainSectionFields) {
          item.mainSectionFields.forEach(function (sField) {
            if( isAmendment ){
              if( quoteType == 'Amendment' ){ 
                if( sField.sourceFieldApi == 'Effective_Date__c' || sField.sourceFieldApi == 'Expiration_Date__c'  ){
                  sField.readOnly = true;
                }else{
                  sField.readOnly = false;
                }  
                //added by Jai to make editabe in case of an Amendment type quote
              }else{
                sField.readOnly = true;
              }
            }else{
              sField.readOnly = true;
            } 
            console.log('sField='+sField.sourceFieldApi, 'readonly='+sField.readOnly);
          });
        }
      }
      
      if (item.subSectionChilds && !item.isComponent) {
        item.subSectionChilds.forEach(function (item1) {
          if (item1.subSectionChildFields) {
            item1.subSectionChildFields.forEach(function (sField) {
              sField.readOnly = true;
            });
          }
        });
      }
    });
    console.log('sField= end');
    this.mapData = mapDataJson;
  }


  getRecordTypeByName(recordTypeName, objectInfo) {
    if (objectInfo) {
      const recordtypeinfo = objectInfo.data.recordTypeInfos;
      return Object.keys(recordtypeinfo).find(
        (rti) => recordtypeinfo[rti].name === recordTypeName
      );
    }
  }

  @track recordInfo = {
    fields: [
      { name: "FirstName", value: null, initValue: false },
      { name: "RecordTypeId", value: null, initValue: true },
      { name: "LastName", value: null, initValue: false },

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

}