import { api, LightningElement, track, wire } from 'lwc';
//import pageSectionMethod from '@salesforce/apex/ClearanceAccordianController.getPageSection';
import ratingModifierMethod from '@salesforce/apex/ClearanceAccordianController.getRatingModifiersrecords';
import saveClearanceData from '@salesforce/apex/ClearanceAccordianController.saveClearanceData';
import addRatingModifier from '@salesforce/apex/ClearanceAccordianController.addRatingModifier';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import TOOL_TIP_CONTENT from '@salesforce/label/c.PCC_Generic_Clearance_Warning_Message';
import { refreshApex } from "@salesforce/apex";
//import { formatLabel } from '../utils/labelUtils';
// Example :- import greeting from '@salesforce/label/c.greeting';

export default class ClearanceAccordianLWC extends LightningElement {
    //activeSectionsMessage = '';
    @api recordId;
    @api productName;
    @api oppId;
   
    @track ratingModifierList;
    @track eligibilityStatusMap = {};
    statusMsg;
    toolTipContent;
    activeSections = ['D&O','Underwriter Analysis']
    @track showSpinner = false;
    // Added to handle Dependent picklist values from html
    selectedValues = { controlling: undefined, dependent: undefined };
    @track dependentPicklistList = [];
    firstDependentPicklistList
    // formats allowed for Rich text area
    formats = ['font', 'size', 'bold', 'italic', 'underline',
    'strike', 'list', 'indent', 'align', 'link',
    'image', 'clean', 'table', 'header', 'color'];
    //Called onLoad on LWC component 
    hasRendered  = false;
    boundDisabledValue = false;
    set boundDisabled(value) {
        console.log('vinay bound value is ' + value);
        if(value){
            console.log('vinay bound disabled >>>>>' + value);
            this.template.querySelectorAll("lightning-input, lightning-combobox, lightning-textarea, lightning-input-rich-text").forEach(element => {
                    element.disabled = 'true';
                    this.hasRendered = true;
            });
        }
        this.boundDisabledValue = value;
    }
    @api get boundDisabled(){
        return this.boundDisabledValue;
    }
    connectedCallback(){
        refreshApex(this.wiredResult);
    }
    renderedCallback() {
        console.log('oppId >>>>>' + this.oppId);
        console.log('vinay bound disabled >>>>>' + this.boundDisabled);
        if(this.boundDisabled){
            this.template.querySelectorAll("lightning-input, lightning-combobox, lightning-textarea, lightning-input-rich-text").forEach(element => {
                   element.disabled = 'true';
                   this.hasRendered = true;
            });
        }
        //Defaulting the product names on Page Load , Later will be controlled by MRE Clearance button
        //this.productName = ['Crime', 'EPL', 'Fiduciary', 'D&O'];
        if(!this.hasRendered){
            
            this.template.querySelectorAll("lightning-input").forEach(element => {
                //console.log('vinay input data read only: ' + element.getAttribute('data-id'));
                if(element.getAttribute('data-read-only') == 'true'){ 
                    //element.setAttribute('read-only','true');
                  // console.log('vinay input data read only1: ' + element.getAttribute('data-read-only'));
                   //element.readOnly = 'true';
                   element.disabled = 'true';
                   this.hasRendered = true;
                 }
            });

          
            // this.template.querySelectorAll("lightning-input").forEach(element => {
            //     console.log('vinay input data read only: ' + element.getAttribute('data-read-only'));
            //     if(element.getAttribute('data-read-only') == true){ 
            //         element.setAttribute('read-only','true');  } });

            if(this.oppId){
                refreshApex(this.wiredResult);
            } 
        }
             
    }

    wiredResult = [];
    @wire (ratingModifierMethod, { opportunityId: '$oppId'})
      wiredRecords(result){
          this.wiredResult = result;
          this.showSpinner = true;
                if(result.data){
                    this.ratingModifierList = result.data.productWrapperList;
                    this.eligibilityStatusMap = result.data.eligibilityStatusWrapper;
                    this.handleStatusOnLoad();
                }
                else{
                    console.log('wire records error ', JSON.stringify(result.error));
                }
            } 

    /*
    Generic method used to fetch Clearance wrapper on basis of Opportunity Id and Product Names 
    */
    handleRatingModifier() {

        // ratingModifierMethod({ opportunityId: this.oppId, productNames: this.productName })
        //     .then(result => {

        //         this.ratingModifierList = result.productWrapperList;
        //         this.eligibilityStatusMap = result.eligibilityStatusWrapper;
        //         console.log('vinay rating mod1 ', JSON.stringify(result));
        //         this.handleStatusOnLoad()
        //     })
        //     .catch(error => {
        //         console.log('vinay rating mod error ', error);
        //     });

    }


    isFormEdited = false;
    /*
    Invoked on Input Field value change to bind the input value to the wrapper
    */
    handleEventChange(event) {
        //console.log(JSON.stringify(event.target.dataset,this.productName));
        this.isFormEdited = true;
        let productName = event.target.dataset.productName;
        let ratingModifierCode = event.target.dataset.id;
        let selectedValue = event.target.value;
        let index = event.target.dataset.index;
        let format = event.target.dataset.format;
        let isSubSection = event.target.dataset.child;
        //this.ratingModifierList[index].selectedValue = selectedValue;
        if(ratingModifierCode == 'PSEPL000005232421' || ratingModifierCode == 'PSEPL000005232422'){
           this.resetInputValidation();
        }

        let ratingModifiersWrapperList = this.ratingModifierList;
        let childRatingModifiers;
        let childIndex1, childIndex2;
        console.log('vinay isSubsection : ' + isSubSection);
        if(isSubSection == 'true'){
            for (let i = 0; i < ratingModifiersWrapperList.length; i++) {
                if (ratingModifiersWrapperList[i].productName === productName) {
                    for (let j = 0; j < ratingModifiersWrapperList[i].modifiersList.length; j++) {
                        if(ratingModifiersWrapperList[i].modifiersList[j].isChildSection){
                            childRatingModifiers = ratingModifiersWrapperList[i].modifiersList[j].childRatingModifiers;
                            childRatingModifiers[index].ratingModifiers.Rating_Modifier_Value__c = selectedValue;
                            childIndex1 = i;
                            childIndex2 = j;
                            /*
                            if(productName == 'EPL'){
                                let ftEmps, ptEmps, foreignEmps, ptRatio, foreignRatio;
                                let ratableIndex;
                                for (let k = 0; k < childRatingModifiers.length; k++){
                                    console.log('vinay calc name: ' + childRatingModifiers[k].ratingModifiers.Name);
                                    if(childRatingModifiers[k].ratingModifiers.Name == 'Full Time Employees'){
                                        ftEmps = childRatingModifiers[k].ratingModifiers.Rating_Modifier_Value__c;
                                    }
                                    if(childRatingModifiers[k].ratingModifiers.Name == 'Part Time Employees'){
                                        ptEmps = childRatingModifiers[k].ratingModifiers.Rating_Modifier_Value__c;
                                    }
                                    if(childRatingModifiers[k].ratingModifiers.Name == 'Average Part Time Ratio'){
                                        ptRatio = childRatingModifiers[k].ratingModifiers.Rating_Modifier_Value__c;
                                    }
                                    if(childRatingModifiers[k].ratingModifiers.Name == 'Foreign Employees'){
                                        foreignEmps = childRatingModifiers[k].ratingModifiers.Rating_Modifier_Value__c;
                                    }
                                    if(childRatingModifiers[k].ratingModifiers.Name == 'Foreign Ratio'){
                                        foreignRatio = childRatingModifiers[k].ratingModifiers.Rating_Modifier_Value__c;
                                    }
                                    if(childRatingModifiers[k].ratingModifiers.Name == 'Ratable Employees'){
                                        childRatingModifiers[k].ratingModifiers.Rating_Modifier_Value__c = '';
                                        ratableIndex = k;
                                    }
                                }
                                if(ftEmps && ptEmps && foreignEmps){
                                    ftEmps = Number(ftEmps);
                                    ptEmps = Number(ptEmps);
                                    foreignEmps = Number(foreignEmps);
                                    if(ptRatio){
                                        ptRatio = Number(ptRatio);
                                        if(!Number.isNaN(ptRatio) && !Number.isNaN(ptEmps)){
                                            ptEmps = ptEmps * ptRatio;
                                        }
                                    }
                                    if(foreignRatio){
                                        foreignRatio = Number(foreignRatio);
                                        if(!Number.isNaN(foreignRatio) && !Number.isNaN(foreignEmps)){
                                            foreignEmps = foreignEmps * foreignRatio;
                                        }
                                    }
                                    if(!Number.isNaN(ftEmps) && !Number.isNaN(ptEmps) && !Number.isNaN(foreignEmps)){
                                        let ratedEmps = ftEmps + ptEmps + foreignEmps;
                                        if(ratedEmps >= 2500){
                                            childRatingModifiers[ratableIndex].ratingModifiers.Rating_Modifier_Value__c = 'MAXIMUM 2,500';
                                        }
                                        else{
                                            childRatingModifiers[ratableIndex].ratingModifiers.Rating_Modifier_Value__c = parseInt(Math.round(ratedEmps));
                                        }
                                        
                                    }
                                }
                            }*/
                            break;
                        }
                        
                    }
                    break;
                }
            }

            //Binding the selected picklist value in the Wrapper
            // for (let i = 0; i < childRatingModifiers.length; i++) {
            //     childRatingModifiers[i].ratingModifiers.Rating_Modifier_Value__c = selectedValue;
            //     break;
            // }
           //console.log('vinay subsection bind value: ' + this.ratingModifierList[childIndex1].modifiersList[childIndex2].childRatingModifiers[index].ratingModifiers.Rating_Modifier_Value__c);
        }
        else{
             //Binding the selected picklist value in the Wrapper
             for (let i = 0; i < ratingModifiersWrapperList.length; i++) {
                if (ratingModifiersWrapperList[i].productName === productName) {
                    ratingModifiersWrapperList[i].modifiersList[index].ratingModifiers.Rating_Modifier_Value__c = selectedValue;
                    break;
                }
            }
            
        }
      
        this.ratingModifierList = ratingModifiersWrapperList;
        
        //Status should be shown only for picklist values 
        if (ratingModifierCode && format === 'Picklist') {
            this.handleStatus(selectedValue, ratingModifierCode, index, productName);
        }
    }
    /*
    Invoked on Notes change and update ProductWrapper list on Keyup
    */
    handleNotesChange(event){
        this.isFormEdited = true;
        let ratingModifiersWrapperList = this.ratingModifierList
        let productName = event.target.dataset.prodname
        let notesVal= event.target.value
        console.log('notesVal-->',notesVal)
        for (let i = 0; i < ratingModifiersWrapperList.length; i++) {
            if (ratingModifiersWrapperList[i].productName === productName) {
                ratingModifiersWrapperList[i].poliNotes = notesVal
                
                break;
            }
        }
        this.ratingModifierList = ratingModifiersWrapperList
    }
    /*
    Invoked on Accordian toggle selection . Can be removed as it is unused as of now
    */
    handleToggleSection(event) {

        let selectedValue = event.detail.openSections;
        console.log('selectedValue>>>', JSON.stringify(selectedValue));
    }

    /*
    Used to stamp the badge color attribute on basis of eligibility status value 
    */
    handleStatus(selectedValue, ratingModifierCode, index, productName) {
        let esKeys=[]
        let eligibilityStatusList = [];
        if (ratingModifierCode) {
        
            eligibilityStatusList = this.eligibilityStatusMap[ratingModifierCode];
        }
        else {
            esKeys= Object.keys(this.eligibilityStatusMap)
           eligibilityStatusList = Object.values(this.eligibilityStatusMap)


        }
        console.log('eligibilityStatusList-->', JSON.stringify(eligibilityStatusList))
        console.log('selectedValue-->', JSON.stringify(selectedValue))
        console.log('Prod Name-->', productName)
        console.log('eligibilityStatusList length-->', eligibilityStatusList.length)
        let eligibilityResult = '';
        if (eligibilityStatusList !== undefined ) {
            for (let i = 0; i < eligibilityStatusList.length; i++) {
                if (eligibilityStatusList[i].Rating_Modifier_Value__c === selectedValue) {
                    eligibilityResult = eligibilityStatusList[i].Eligibility_Status__c;
                    break;
                }
            }
        }

        if (eligibilityResult === '') {
            eligibilityResult = 'Proceed';
        }
        if (!selectedValue) {
            eligibilityResult = 'None'
        }

        // Will be used for Dependent picklist check
        let complexESList = []
        if (!productName || productName== null){
            for(let k = 0; k<eligibilityStatusList.length; k++ ){
                for(let l =0; l<eligibilityStatusList[k].length ;l++ ){
                    complexESList =[...complexESList,{prodName:eligibilityStatusList[k][l].Modifier_Product__c,modValue:eligibilityStatusList[k][l].Rating_Modifier_Value__c,esStatus:eligibilityStatusList[k][l].Eligibility_Status__c}]
                }
            }
        }
        
        for (let i = 0; i < this.ratingModifierList.length; i++) {
            if (!productName || productName== null) {
                for(let j = 0; j<this.ratingModifierList[i].modifiersList.length; j++ ){
                    if(this.ratingModifierList[i].modifiersList[j].dependPicklistApiName){
                        // Iterate over all Eligibilty Status
                        for(let k=0;k< complexESList.length; k++){
                            if(this.ratingModifierList[i].modifiersList[j].ratingModifiers.Product__c === complexESList[k].prodName
                                && selectedValue == complexESList[k].modValue){
                                    eligibilityResult =complexESList[k].esStatus
                                    console.log('eligibilityResult-->',eligibilityResult)
                                    this.ratingModifierList[i].modifiersList[j].ratingModifiers.Eligibility_Status__c = eligibilityResult;
                                    if (eligibilityResult == ('Proceed')) {
                                        this.ratingModifierList[i].modifiersList[j].badgeColor = 'slds-theme_success slds-truncate badgeClass';
                                    }
                                    if (eligibilityResult.toLowerCase().includes('Stop!'.toLowerCase())) {
                                        this.ratingModifierList[i].modifiersList[j].badgeColor = 'slds-theme_error slds-truncate badgeClass';
                                    }
                                    if (eligibilityResult.toLowerCase().includes('Proceed with caution'.toLowerCase()) || eligibilityResult.includes('Proceed with Caution')) {
                                        this.ratingModifierList[i].modifiersList[j].badgeColor = 'slds-theme_warning slds-truncate badgeClass';
                                    }
                                    if (eligibilityResult.toLowerCase().includes('Munich'.toLowerCase())) {
                                        this.ratingModifierList[i].modifiersList[j].badgeColor = ' badgeforMunich slds-truncate badgeClass';
                                    }
                                    if (eligibilityResult == 'Prohibited Class') {
                                        this.ratingModifierList[i].modifiersList[j].badgeColor = 'badgeforprohibited slds-truncate badgeClass';
                                    }
                                    if (eligibilityResult == 'No Information') {
                                        this.ratingModifierList[i].modifiersList[j].badgeColor = 'slds-badge_inverse slds-truncate badgeClass';
                                    }
                                    if (eligibilityResult == 'None') {
                                        this.ratingModifierList[i].modifiersList[j].badgeColor = 'slds-hide';
                                    }
                                    break;
                                }
                                else{
                                    // If not found then proceed
                                    this.ratingModifierList[i].modifiersList[j].ratingModifiers.Eligibility_Status__c = 'Proceed';
                                    
                                    this.ratingModifierList[i].modifiersList[j].badgeColor = 'slds-theme_success slds-truncate badgeClass';
                                }

                        }
                    }
                }
                    
            }
            else if (productName && this.ratingModifierList[i].productName === productName) {
                this.ratingModifierList[i].modifiersList[index].ratingModifiers.Eligibility_Status__c = eligibilityResult;
                if (eligibilityResult == ('Proceed')) {
                    this.ratingModifierList[i].modifiersList[index].badgeColor = 'slds-theme_success slds-truncate badgeClass';
                }
                if (eligibilityResult.toLowerCase().includes('Stop!'.toLowerCase())) {
                    this.ratingModifierList[i].modifiersList[index].badgeColor = 'slds-theme_error slds-truncate badgeClass';
                }
                if (eligibilityResult.toLowerCase().includes('Proceed with caution'.toLowerCase()) || eligibilityResult.includes('Proceed with Caution')) {
                    this.ratingModifierList[i].modifiersList[index].badgeColor = 'slds-theme_warning slds-truncate badgeClass';
                }
                if (eligibilityResult == 'No Information') {
                    this.ratingModifierList[i].modifiersList[index].badgeColor = 'slds-badge_inverse slds-truncate badgeClass';
                }
                if (eligibilityResult.toLowerCase().includes('Munich'.toLowerCase())) {
                    this.ratingModifierList[i].modifiersList[index].badgeColor = ' badgeforMunich slds-truncate';
                }
                if (eligibilityResult == 'Prohibited Class') {
                    this.ratingModifierList[i].modifiersList[index].badgeColor = 'badgeforprohibited slds-truncate';
                }
                if (eligibilityResult == 'None') {
                    this.ratingModifierList[i].modifiersList[index].badgeColor = 'slds-hide';
                }
                break;
            }
        }
    }


    bypassRequiredValidation = false;
     /*
        Method called when Save button clicked. This method doesnt do complete validation which is needed while navigating.
    */
    @api handleSaveButtonClick(){
        this.bypassRequiredValidation = true;
        this.handleSave();
        console.log('handling save1');
        this.bypassRequiredValidation = false;
        return true;
     }

    /*
    Method to save the UI values to rating modifiers object at backend 
    */
    @api async handleSave() {
        if(this.boundDisabled) return true;
        this.resetInputValidation();
        this.showSpinner = true;
        var readyToSave = true;
        if(!this.bypassRequiredValidation){
            readyToSave = this.validateRequiredField();
        }
        if(this.isFormEdited && readyToSave) {
            console.log('opportunityid-->',this.oppId )
            await saveClearanceData({ clearanceWrapperJson: JSON.stringify(this.ratingModifierList), opportunityid : this.oppId })
                .then(() => {
                    this.showSpinner = false;
                    const event = new ShowToastEvent({
                        "title": "Success!",
                        "message": "Record is saved !",
                        "variant": "Success"
                    });
                    
                    this.dispatchEvent(event);
                    refreshApex(this.wiredResult);
                })
                .catch((error) => {
                    this.showSpinner = false;
                    this.dispatchEvent(ShowToastEvent({
                        "title": "Error",
                        "message": error.message,
                        "variant": "error"
                    }))
                });

            await addRatingModifier({ opportunityId: this.oppId })
                .then(() => {
                    this.showSpinner = false;
                })
                .catch((error) => {
                    this.showSpinner = false;
                    this.dispatchEvent(ShowToastEvent({
                        "title": "Error",
                        "message": error.message,
                        "variant": "error"
                    }))
                });
             this.isFormEdited = false;

        } else{
            this.showSpinner = false;
        }
        return readyToSave;
    }

    //Reset custom validations before save
    resetInputValidation() {
      const fullTimeElement = this.template.querySelector('[data-id="PSEPL000005232421"]');
      const partTimeElement = this.template.querySelector('[data-id="PSEPL000005232422"]');
      if(!fullTimeElement) return;
      fullTimeElement.setCustomValidity("");
      partTimeElement.setCustomValidity("");
      fullTimeElement.reportValidity();
      partTimeElement.reportValidity();
    }

    //Check validations For Required fields before Save Operation
    validateRequiredField() {
        var result = true;
        console.log('inside required method');
        let errFields ='';

        let isInputsCorrect = [...this.template.querySelectorAll('lightning-combobox,lightning-input,lightning-textarea')].reduce(function (validSoFar, inputField) {
            inputField.reportValidity();
            if(!inputField.checkValidity()){
                if(!(errFields == '')) errFields += ', ';
                var modifierCode = inputField.dataset.id;
                if(modifierCode == 'PSDO00000121212'){
                    errFields += 'Annual Revenue';
                }
                if(modifierCode == 'PSFID000005989890'){
                    errFields += 'Plan Assets';
                }
            }
            return validSoFar && inputField.checkValidity();
        }, true);

        let errMsg = "Please complete all required field(s) before saving:-";
        //Check validity for full-time and part time employees.
        const fullTimeElement = this.template.querySelector('[data-id="PSEPL000005232421"]');
        const partTimeElement = this.template.querySelector('[data-id="PSEPL000005232422"]');
        if(fullTimeElement){
               if((!fullTimeElement.value || fullTimeElement.value == 0.0) && (!partTimeElement.value || partTimeElement.value == 0.0)){
                  if(!(errFields == '')) errFields += ', ';
                  isInputsCorrect = false;
                  errFields += "Full and/or Part Time Employees must be a minimum of 1";
                  fullTimeElement.setCustomValidity("Full and/or Part Time Employees must be a minimum of 1");
                  partTimeElement.setCustomValidity("Full and/or Part Time Employees must be a minimum of 1");
                  fullTimeElement.reportValidity();
                  partTimeElement.reportValidity();
            }
        }
       

        errMsg += errFields;
        if (!isInputsCorrect) {
            this.dispatchEvent(ShowToastEvent({
                "title": "Error",
                "message": errMsg,
                "variant": "error"
            }))
            result = false;
        }
        return result;
    }

    /*
    Invoked from parent component on click of MRE Clerance button to rerender the accordians
    */
    @api handleSelectedProduct(productName) {

        console.log('productName>>> ', productName);
        console.log('oppId>>>>', this.oppId);
        this.productName = productName;
        //commenting for sometime as buttons are not coming up onload
        this.handleRatingModifier();
    }
    /*
    Invoked on change of dependent picklist to bind the values in the wrapper
    */
    handlePicklist(event) {
        let selectedVals = event.detail.pickListValue
        console.log('Values-->', JSON.parse(JSON.stringify(selectedVals)))

        this.selectedValues = JSON.parse(JSON.stringify(selectedVals))
        console.log('Values @@', this.selectedValues)
        console.log('Test-->', this.selectedValues.dependent)
        if (this.selectedValues.dependent) {

            let productName = event.target.dataset.productName;
            let ratingModifierCode = event.target.dataset.id;
            let selectedValue = this.selectedValues.controlling + ':' + this.selectedValues.dependent
            let index = event.target.dataset.index;
            let ratingModifiersWrapperList = this.ratingModifierList;
            //Binding the selected picklist value in the Wrapper
            for (let i = 0; i < ratingModifiersWrapperList.length; i++) {
                // if(ratingModifiersWrapperList[i].productName === productName){
                //     ratingModifiersWrapperList[i].modifiersList[index].ratingModifiers.Controlling_Picklist_Value__c = this.selectedValues.controlling;
                //     ratingModifiersWrapperList[i].modifiersList[index].ratingModifiers.Dependent_Picklist_Value__c = this.selectedValues.dependent;
                //     break;
                // }
                for (let j = 0; j < ratingModifiersWrapperList[i].modifiersList.length; j++) {
                    if (ratingModifiersWrapperList[i].modifiersList[j].dependPicklistApiName) {
                        ratingModifiersWrapperList[i].modifiersList[j].ratingModifiers.Controlling_Picklist_Value__c = this.selectedValues.controlling;
                        ratingModifiersWrapperList[i].modifiersList[j].ratingModifiers.Dependent_Picklist_Value__c = this.selectedValues.dependent;
                        break;
                    }
                }

            }
            this.ratingModifierList = ratingModifiersWrapperList;
            console.log('updatedWrapper-->' + JSON.stringify(this.ratingModifierList));
            if (selectedValue) {
                this.handleStatus(selectedValue, null, null, null);
            }

        }

    }
    // To handle Badge css on load
    handleStatusOnLoad() {
        let cloneRatingModList = JSON.parse(JSON.stringify(this.ratingModifierList));
       
       // this.dependentPicklistList = [];
        for (let i = 0; i < cloneRatingModList.length; i++) {
           
            for (let j = 0; j < cloneRatingModList[i].modifiersList.length; j++) {
                //console.log('vinay dependent value :' + cloneRatingModList[i].modifiersList[j].ratingModifiers.Controlling_Picklist_Value__c);
                if(!cloneRatingModList[i].modifiersList[j].ratingModifiers) continue;
                //Setting Eligibility status for dependent picklist data
                if (cloneRatingModList[i].modifiersList[j].ratingModifiers.Controlling_Picklist_Value__c
                     && cloneRatingModList[i].modifiersList[j].ratingModifiers.Controlling_Picklist_Value__c != ''){
                        
                         if(!cloneRatingModList[i].modifiersList[j].ratingModifiers.Eligibility_Status__c){
                            
                                let eligibilityStatusList = [];                           
                                eligibilityStatusList = this.eligibilityStatusMap[cloneRatingModList[i].modifiersList[j].ratingModifiers.Rating_Modifier_Code__c];
                                
                                //let ratingModValue = cloneRatingModList[i].modifiersList[j].ratingModifiers.Controlling_Picklist_Value__c + ':' + cloneRatingModList[i].modifiersList[j].ratingModifiers.Dependent_Picklist_Value__c;
                               
                                for (let k = 0; k < eligibilityStatusList.length; k++) {
                                    
                                    if (eligibilityStatusList[k].Rating_Modifier_Value__c === cloneRatingModList[i].modifiersList[j].ratingModifiers.Rating_Modifier_Value__c) {
                                        //console.log('vinay dependent rating :' + cloneRatingModList[i].modifiersList[j].ratingModifiers.Eligibility_Status__c);
                                      
                                        cloneRatingModList[i].modifiersList[j].ratingModifiers.Eligibility_Status__c = eligibilityStatusList[k].Eligibility_Status__c;       
                                        break;
                                    }
                                }
                            }
                }
                     

                if (cloneRatingModList[i].modifiersList[j].ratingModifiers.Rating_Modifier_Value__c ) {
                    let item = cloneRatingModList[i].modifiersList[j].ratingModifiers.Eligibility_Status__c ? cloneRatingModList[i].modifiersList[j].ratingModifiers.Eligibility_Status__c : 'Proceed'
                    console.log('ES-->',item)
                    if (item == 'Proceed' ) {
                        cloneRatingModList[i].modifiersList[j].ratingModifiers.Eligibility_Status__c = 'Proceed' 
                        cloneRatingModList[i].modifiersList[j].badgeColor = 'slds-theme_success slds-truncate badgeClass';
                    }
                    else if (item.toLowerCase().includes('Stop!'.toLowerCase())) {
                        cloneRatingModList[i].modifiersList[j].badgeColor = 'slds-theme_error slds-truncate badgeClass';
                    }
                    else if (item.toLowerCase().includes('Proceed with caution'.toLowerCase()) || item.includes('Proceed with Caution')) {
                        cloneRatingModList[i].modifiersList[j].badgeColor = 'slds-theme_warning slds-truncate badgeClass';
                    }
                    else if (item.toLowerCase().includes('Munich'.toLowerCase())) {
                        cloneRatingModList[i].modifiersList[j].badgeColor = 'badgeforMunich slds-truncate ';
                    }
                    else if (item.toLowerCase().includes('Prohibited'.toLowerCase())){                       
                        cloneRatingModList[i].modifiersList[j].badgeColor = 'badgeforprohibited slds-truncate ';
                    }

                }
                //Preparing dependent picklist List to be displayed at the Top section
                // if (cloneRatingModList[i].modifiersList[j].controlPicklistApiName !== ''
                //     && cloneRatingModList[i].modifiersList[j].dependPicklistApiName !== ''
                //     && cloneRatingModList[i].modifiersList[j].objApiName !== '') {
                //     let tempObj = {};
                //     tempObj.controlPicklistApiName = cloneRatingModList[i].modifiersList[j].controlPicklistApiName;
                //     tempObj.dependPicklistApiName = cloneRatingModList[i].modifiersList[j].dependPicklistApiName;
                //     tempObj.objApiName = cloneRatingModList[i].modifiersList[j].objApiName;
                //     tempObj.Name = cloneRatingModList[i].modifiersList[j].ratingModifiers.Name;
                //     tempObj.index = j;
                //     tempObj.productName = cloneRatingModList[i].productName;
                //     tempObj.ratingModifierCode = cloneRatingModList[i].modifiersList[j].ratingModifiers.Rating_Modifier_Code__c;
                //     this.dependentPicklistList.push(tempObj);
                // }
            }
        }
        console.log('dependentlist--->' + JSON.stringify(this.dependentPicklistList));
        this.ratingModifierList = cloneRatingModList
        this.showSpinner = false;
        //this.firstDependentPicklistList = this.dependentPicklistList[0]
    }

    // Will be used to render Tooltip section
    showtooltip(event){
        let prodName = event.target.dataset.id
        console.log('prodnmae-->',prodName)
         this.template.querySelector(`[data-prname="${prodName}"]`).classList.remove('toggle')
      
    }

    hidetooltip(event){
        let prodName = event.target.dataset.id
        this.template.querySelector(`[data-prname="${prodName}"]`).classList.add('toggle')
        
    }
}