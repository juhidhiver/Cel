import { LightningElement, api, wire, track } from 'lwc';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { updateRecord, getRecordUi,getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import {
    ScenarioState,
    ScenarioLayout,
    MarkAsCompleteScenario,
    MarkAsCurrentScenario,
    SelectClosedScenario,
    ChangeClosedScenario,
    Step,
    getMasterRecordTypeId,
    getRecordTypeId
} from './utils';

// value to assign to the last step when user has to select a proper closed step
const OPEN_MODAL_TO_SELECT_CLOSED_STEP = 'pathAssistant_selectAClosedStepValue';

const FIELDS = [   
    'Opportunity.StageName'
];

export default class PathAssistantLwc extends LightningElement {
	oppId;
    //Added by Vinayesh
    productName;

    // boolean property to verify product: Aq/Celerity
    @api isAqueous = false;
    @api isPCC = false;

    // current object api name
    @api objectApiName;
    @api isValidate;
    // current record's id
    @api currentRecordId;

    // picklist field's API name used to render the path assistant
    @api picklistField;

    // closed OK step value. When selected will render a green progress bar
    @api closedOk;

    // closed KO step value. When selected will render a red progress bar
    @api closedKo;

    // label to give the last step
    @api lastStepLabel;

    // show/hide the update button
    @api hideUpdateButton;

    // show/hide a loading spinner
    @track spinner = false;

    // show/hide the modal to select a closed step
    @track openModal = false;

    // current object metadata info
    @track objectInfo;

    // current record
    @track record;

    // error message, when set will render the error panel
    @track errorMsg;

    // available picklist values for current record (based on record type)
    @track possibleSteps;

    // step selected by the user
    @track selectedStepValue;

    // current record's record type id
    _recordTypeId;

    // action that can be performed by the user
    _currentScenario;

    // user selected closed step
    _selectedClosedStepValue;

    // array of possible user interaction scenarios
    _scenarios = [];

    /**
     * Creates possible user interaction scenarios
     */
    constructor() {
        super();
        const token = '{0}';

        // note: all the hard coded strings passed to ScenarioLayout can be replaced with Custom Labels

        this._scenarios.push(
            new MarkAsCompleteScenario(
                new ScenarioLayout(
                    'Select Closed {0}',
                    'Mark {0} as Complete',
                    token
                )
            )
        );

        this._scenarios.push(
            new MarkAsCurrentScenario(
                new ScenarioLayout('', 'Mark as Current {0}', token)
            )
        );

        this._scenarios.push(
            new SelectClosedScenario(
                new ScenarioLayout(
                    'Select Closed {0}',
                    'Select Closed {0}',
                    token
                )
            )
        );

        this._scenarios.push(
            new ChangeClosedScenario(
                new ScenarioLayout(
                    'Select Closed {0}',
                    'Change Closed {0}',
                    token
                )
            )
        );

    }

    /* ========== WIRED METHODS ========== */

    @wire(getRecordUi, {
        recordIds: '$currentRecordId',
        layoutTypes: 'Full',
        modes: 'View'
    })
    wiredRecordUI({ error, data }) {
        if (error) {
            this.errorMsg = error.body.message;
        }

        if (data && data.records[this.currentRecordId]) {
            // set the record
            this.record = data.records[this.currentRecordId];
			
            // set the object info
            this.objectInfo = data.objectInfos[this.objectApiName];

            // set the current record type
            const rtId = getRecordTypeId(this.record);
            this._recordTypeId = rtId ? rtId : getMasterRecordTypeId(this.objectInfo);
			console.log('this._recordTypeId==', this._recordTypeId);
            console.log('fire event from wiredRecordUI:' + this.currentRecordId);
            if(this.record.fields) {
                this.selectedStepValue = this.record.fields['Status__c'].value;
                this.oppId = this.record.fields['Submission__c'].value;
                //Added by Vinayesh
                this.productName = this.record.fields['Product__c'].value;
            }
		
			console.log('##this.oppId:'+ this.oppId);
            console.log('vinay '+ this.oppId);
			this.handleChangeRefresh();
        }
    }

    // load picklist values available for current record type
    @wire(getPicklistValuesByRecordType, {
        objectApiName: '$objectApiName',
        recordTypeId: '$_recordTypeId'
    })
    wiredPicklistValues({ error, data }) {
        if (!this._recordTypeId) {
            // invalid call
            return;
        }

        if (error) {
            this.errorMsg = error.body.message;
        }

        if (data) {
            console.log('data steps::'+JSON.stringify(data));
            if (data.picklistFieldValues[this.picklistField]) {
                // stores possible steps
                this.possibleSteps = data.picklistFieldValues[
                    this.picklistField
                ].values.map((elem, idx) => {
                    return new Step(elem.value, elem.label, idx);
                });

                if(this.productName == 'Private Company Combo'){
                    //let labelToRemove = 'Insured Info';
                    this.possibleSteps = this.possibleSteps.filter((item) => {
                        return (item.label !== 'Insured Info' && item.label !== 'Submission Info' && item.label !== 'Underwriting Analysis');
                    });
                } else{
                    const labelToRemove = 'Submission Console';
                    this.possibleSteps = this.possibleSteps.filter((item) => item.label !== labelToRemove);
                }
                // checks that required values are included
                this._validateSteps();
            } else {
                this.errorMsg = `Impossible to load ${
                    this.picklistField
                } values for record type ${this._recordTypeId}`;
            }
        }
    }

	/**/
	@wire(getRecord, { recordId: '$oppId', fields: FIELDS })
    submission;

    get stage() {
        return this.submission.data.fields.StageName.value;
    }

	
    /* ========== PRIVATE METHODS ========== */

    /**
     * Based on current component state set the current scenario
     */
    @api
    _setCurrentScenario() {
        const state = new ScenarioState(
            this.isClosed,
            this.selectedStepValue,
            this.currentStep.value,
            OPEN_MODAL_TO_SELECT_CLOSED_STEP
        );

        for (let idx in this._scenarios) {
            if (this._scenarios[idx].appliesToState(state)) {
                this._currentScenario = this._scenarios[idx];
                break;
            }
        }
	}

    /**
     * Validate picklist values available for current record type.
     * ClosedOk and ClosedKo values should be available together at least with another
     * value.
     */
    _validateSteps() {
        let isClosedOkAvailable = false;
        let isClosedKoAvailable = false;

        this.possibleSteps.forEach(step => {
            isClosedKoAvailable |= step.equals(this.closedKo);
            isClosedOkAvailable |= step.equals(this.closedOk);
        });

        if (!isClosedOkAvailable) {
            this.errorMsg = `${
                this.closedOk
            } value is not available for record type ${this._recordTypeId}`;
        }

        if (!isClosedKoAvailable) {
            this.errorMsg = `${
                this.closedKo
            } value is not available for record type ${this._recordTypeId}`;
        }

        // checks steps contains at least three items (starting step plus the two closed ones)
        if (this.possibleSteps.length < 3) {
            // note: should I make this configurable?
            this.errorMsg = `Not enough picklist values are available for record type ${
                this._recordTypeId
            }.`;
        }
    }

    /**
     * Given a step returns the css class to apply in the rendered html element
     * @param {Object} step Step instance
     */
    _getStepElementCssClass(step) {
        /*if(this.selectedStepValue = 'Underwriting Analysis'){
            this.selectedStepValue  ='Underwritting Analysis'
        }*/
        let classText = 'slds-path__item';

        if (step.equals(this.closedOk)) {
            classText += ' slds-is-won';
        }

        if (step.equals(this.closedKo)) {
            classText += ' slds-is-lost';
        }

        if (step.equals(this.selectedStepValue)) {
            classText += ' slds-is-active';
        }

        if (step.equals(this.currentStep)) {
            classText += ' slds-is-current';

            if (!this.selectedStepValue) {
                // if user didn't select any step this is also the active one
                classText += ' slds-is-active';
            }
        } else if (step.isBefore(this.currentStep) && !this.isClosedKo) {
            classText += ' slds-is-complete';
        } else {
            // not yet completed or closedKo
            classText += ' slds-is-incomplete';
        }

        return classText;
    }

    /**
     * Reset the component state
     */
    _resetComponentState() {
        this.record = undefined;
        this.selectedStepValue = undefined;
        this._selectedClosedStepValue = undefined;
        this._currentScenario = undefined;
    }

    /**
     * Update current record with theStepValue specified step.
     * @param {String} stepValue Step value to set on current record
     */
    @api
       _updateRecord(stepValue) {
        // format the record for update call
        let toUpdate = {
            fields: {
                Id: this.currentRecordId
            }
        };

        // set new field value
        toUpdate.fields[this.picklistField] = stepValue;

        // starts spinner
        this.spinner = true;

       updateRecord(toUpdate)
            .then(() => {
                // close spinner
                this.spinner = false;
            })
            .catch(error => {
                this.errorMsg = error.body.message;
                this.spinner = false;
            });
		
        // reset component state
        this._resetComponentState();
    }

    /* ========== GETTER METHODS ========== */

    // returns current step of path assistant
    get currentStep() {
        for (let idx in this.possibleSteps) {
            if (
                this.possibleSteps[idx].equals(
                    this.record.fields[this.picklistField].value
                )
            ) {
                console.log('@@current step::'+JSON.stringify (this.possibleSteps[idx]));
                return this.possibleSteps[idx];
            }
        }
        // empty step
        return new Step();
    }

    // returns next step
    get nextStep() {
        return this.possibleSteps[this.currentStep.index + 1];
    }

    // get progress bar steps
     @api get steps() {
        let closedOkElem;
        let closedKoElem;

        // makes a copy of picklistValues. This is because during rendering phase we cannot alter the status of a tracked variable
        // const possibleSteps = JSON.parse(JSON.stringify(this.possibleSteps));

        let res = this.possibleSteps
            .filter(step => {
                // filters out closed steps
                if (step.equals(this.closedOk)) {
                    closedOkElem = step;
                    return false;
                }

                if (step.equals(this.closedKo)) {
                    closedKoElem = step;
                    return false;
                }
                //Logs by Vinayesh
                console.log('vinay ' + this.productName);
                console.log('vinay ' + step.label);

                if(((this.isAqueous || this.isPCC) && step.label == 'Compare & Rate Quotes') ||
                 (!(this.isAqueous || this.isPCC) && step.label == 'Quote Console') ||
                    (!(this.productName == 'Private Company Combo') && step.label == 'Underwriting Console')){ //Added by Vinayesh
                    console.log('$$$$Step001=',step);
                    return false;
                }

                return true;
            })
            .map(step => {
                // adds the classText property used to render correctly the element
                step.setClassText(this._getStepElementCssClass(step));
                return step;
            });
            console.log('$$$$res1=',res);
        let lastStep;

        if (this.isClosedOk) {
            lastStep = closedOkElem;
        } else if (this.isClosedKo) {
            lastStep = closedKoElem;
        } else {
            // record didn't reach a closed step
            // create a fake one that will allow users to pick either the closedOk or closedKo
            lastStep = new Step(
                OPEN_MODAL_TO_SELECT_CLOSED_STEP,
                this.lastStepLabel,
                Infinity
            );
        }

        lastStep.setClassText(this._getStepElementCssClass(lastStep));
        res.push(lastStep);
        return res;
    }

    // returns only closed steps
    get closedSteps() {
        return this.possibleSteps.filter(step => {
            return step.equals(this.closedKo) || step.equals(this.closedOk);
        });
    }

    // return action button text label
    get updateButtonText() {
        return this._currentScenario
            ? this._currentScenario.layout.getUpdateButtonText(
                  this.picklistFieldLabel
              )
            : '';
    }

    // returns the header for the modal
    get modalHeader() {
        return this._currentScenario
            ? this._currentScenario.layout.getModalHeader(
                  this.picklistFieldLabel
              )
            : '';
    }

    // returns the label for the select input field inside the modal
    get selectLabel() {
        return this.picklistFieldLabel;
    }

    // returns the label of the picklist field used to render the path
    get picklistFieldLabel() {
        return this.objectInfo.fields[this.picklistField].label;
    }

    // true if current record reached a closed step
    get isClosed() {
        return this.isClosedKo || this.isClosedOk;
    }

    // true if current record was closed OK
    get isClosedOk() {
        return this.currentStep.equals(this.closedOk);
    }

    // true if current record was closed KO
    get isClosedKo() {
        return this.currentStep.equals(this.closedKo);
    }
    // true when all required data is loaded
    get isLoaded() {
        const res = this.record && this.objectInfo && this.possibleSteps;
        if (res && !this._currentScenario) {
            // when fully loaded initialize the action
            this._setCurrentScenario();
        }
        return res;
    }

    // true if picklist field is empty and user didn't select any value yet
    get isUpdateButtonDisabled() {
        return !this.currentStep.hasValue() && !this.selectedStepValue;
    }

    // true if either spinner = true or component is not fully loaded
    get hasToShowSpinner() {
        return this.spinner || !this.isLoaded;
    }

    get genericErrorMessage() {
        // note: you can store this in a custom label if you need
        return 'An unexpected error occurred. Please contact your System Administrator.';
    }

    /* ========== EVENT HANDLER METHODS ========== */

    /**
     * Called when user press either the Cancel button or the Close icon
     * in the modal.
     */
    closeModal() {
        this.openModal = false;
    }

    /**
     * Called when user selects a value for the closed step
     * @param {Event} event Change Event
     */
    setClosedStep(event) {
        this._selectedClosedStepValue = event.target.value;
    }

    /**
     * Called when user clicks on a step
     * @param {Event} event Click event
     */
    handleStepSelected(event) {
        var stepSelect = event.currentTarget.getAttribute('data-value');
        console.log('stepSelect'+stepSelect);
        //console.log('stepLabel'+event.currentTarget.getAttribute('data-label'));
        if(!this.oppId && stepSelect !='Insured Info')
		{
            if(this.isAqueous || this.isPCC){
                var msg = (stepSelect == OPEN_MODAL_TO_SELECT_CLOSED_STEP) ? 'Quote Console' : stepSelect;
            }
            else{
                var msg = (stepSelect == OPEN_MODAL_TO_SELECT_CLOSED_STEP) ? 'Compare & Rate Quotes' : stepSelect;
            }
            console.log('##msg::'+msg);
            if(msg=='Underwritting Analysis'){
                msg = 'Underwriting Analysis';
            }
            this.showToast('','Need Submission for this ' + msg +' Stage','warning','dismissable');
            return;
        }

        if(!this.isAqueous){
            if(this.oppId && this.stage!='Qualified' && this.stage!='Closed Won' && this.stage!='Bound Pending' && this.stage!='Declined' && stepSelect == OPEN_MODAL_TO_SELECT_CLOSED_STEP)
            {
                this.showToast('','Please Qualify Submission','warning','dismissable');
                return;
            }

            //Check StageName Submission is not Qualified.
            
            if(this.oppId && this.stage == 'Unqualified' && this.stage!='Closed Won' && stepSelect == 'Underwritting Analysis')
            {
                this.showToast('','Stage Submission is Unqualified. Please Qualify Submission','warning','dismissable');
                return;
            }

            //Submission stage Closed lost-cannot move to next step
            if(this.oppId && this.stage!='Closed Won' && stepSelect == 'Underwritting Analysis')
            {
                if(this.stage == 'Closed Lost'){
                    this.showToast('','Submission is in ' + this.stage + '. You cannot move to the next stage.','warning','dismissable');
                    return;
                }
            }
        }
		
       /*if(this.oppId && (stepSelect =='Insured Info')){
        this.selectedStepValue = stepSelect;
      
        this._setCurrentScenario();
		console.log('fire event from pathAssistant:');
		console.log('Status' + JSON.stringify(this.steps));
		var currentStatus = (this.selectedStepValue === OPEN_MODAL_TO_SELECT_CLOSED_STEP) ? this.lastStepLabel : this.selectedStepValue;
		this._updateRecord(currentStatus);
        }*/
        

      if(this.oppId){
           
            console.log('stepSelect==>',stepSelect);
            console.log('this.oppId==>',this.oppId);
            console.log('this.lastStepLabel==>',this.lastStepLabel);
            const event1 = new CustomEvent('eventfirepathassistant', {
                detail: {
                selectedvalue: stepSelect,
                lastStepLabel:this.lastStepLabel
                }}
            );
            this.dispatchEvent(event1);
           
        }
       
            
       
    }

	handleChangeRefresh() {
		var getStatus = (this.selectedStepValue === OPEN_MODAL_TO_SELECT_CLOSED_STEP) ? this.lastStepLabel : this.selectedStepValue;
	    var infos = {currentStatus : getStatus};
        const event = new CustomEvent('changerefresh', {
            detail: infos
        });
        this.dispatchEvent(event);
    }
    /**
     * Called when user press the action button
     */
    handleUpdateButtonClick() {
        switch (this._currentScenario.constructor) {
            case MarkAsCompleteScenario:
                if (
                    this.nextStep.equals(this.closedKo) ||
                    this.nextStep.equals(this.closedOk)
                ) {
                    // in case next step is a closed one open the modal
                    this.openModal = true;
                } else {
                    // otherwise update the record directly
                    this._updateRecord(this.nextStep.value);
                }
                break;
            case MarkAsCurrentScenario:
                this._updateRecord(this.selectedStepValue);
                break;
            case SelectClosedScenario:
            case ChangeClosedScenario:
                this.openModal = true;
                break;
            default:
                break;
        }
    }

    /**
     * Called when user press Save button inside the modal
     */
    handleSaveButtonClick() {
        if (!this._selectedClosedStepValue) {
            return;
        }

        this._updateRecord(this._selectedClosedStepValue);
        this.openModal = false;
    }
    showToast(title, message, variant,modee) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

}