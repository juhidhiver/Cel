import { LightningElement, api, wire, track } from 'lwc';
import { updateRecord, getRecordUi,getRecord,deleteRecord  } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getComponentList from '@salesforce/apex/sectionSettingLwcController.getComponentList';
import getProductList from '@salesforce/apex/sectionSettingLwcController.getProductList';
import getMainSectionList from '@salesforce/apex/sectionSettingLwcController.getMainSectionList';
import getSubSectionList from '@salesforce/apex/sectionSettingLwcController.getSubSectionList';
import getFieldList from '@salesforce/apex/sectionSettingLwcController.getFieldList';
import updateSectionRelatedData from '@salesforce/apex/sectionSettingLwcController.updateSectionRelatedData';
import updateComponentRelatedData from '@salesforce/apex/sectionSettingLwcController.updateComponentRelatedData';

const actions = [
    { label: 'Edit', name: 'editRow' },
	{ label: 'Delete', name: 'deleteRow' },
	{ label: 'New', name: 'newRow' },
];

const FIELDS = ['SectionSetting__c.Main_Section__c','SectionSetting__c.Sub_Section__c','SectionSetting__c.Criteria__c',
				'SectionSetting__c.Active__c','SectionSetting__c.Order__c','SectionSetting__c.Source_Field_API__c',
				'SectionSetting__c.Source_Field_Label__c','SectionSetting__c.Source_Object__c','SectionSetting__c.Format__c',
				'SectionSetting__c.DisplayType__c','SectionSetting__c.Lookup_To__c'];

export default class SectionSettingLwc extends LightningElement {
    @track openMainAndSubSection = false;
	@track rtValue;
	@track isDialogVisible = false;
	@track deleteOption; //values: Component or Field
	@track confirmMessage;
		
	@track componentValue ;
	@track mainValue;
	@track subValue;
	@track fieldId;
	record = {};

	@track componentItems = []; //this will hold key, value pair
	@track productItems = []; //List product items
	@track productValues = []; //Values of selected products

	@track mainItems = []; 
	@track subItems = []; 
	@track fieldItems;


	@track componentHeader;
	@track componentValue_ ;
	character =';';

	@track isEditComponent = false;
	@track isCreateField = false;
	@track isEditField = false;
	@track isViewStructure = false;
	@track error;
	@track yourSelectedValues;

	// @track listItems = [
	// 	{ value: 'Cyber', label: 'Cyber' },
    //     { value: 'MPL', label: 'MPL' },
	// ];
	

	@track draftValues = [];
	@track columns = [
		{label: 'Field name',fieldName: 'Name'},
		{label: 'Products',fieldName: 'Product__c'},
		{label: 'Main Section',fieldName: 'Main_Section__c'},		
        {label: 'Sub Section',fieldName: 'Sub_Section__c'},
        {label: 'Source Object',fieldName: 'Source_Object__c', editable: true},
        {label: 'Source Field Label',fieldName: 'Source_Field_Label__c', editable: true},
        {label: 'Source Field API',fieldName: 'Source_Field_API__c', editable: true},
        {label: 'Format',fieldName: 'Format__c', editable: true},
        {label: 'Display Type',fieldName: 'DisplayType__c', editable: true},
		{label: 'Lookup To',fieldName: 'Lookup_To__c', editable: true},
        {label: 'Criteria',fieldName: 'Criteria__c', editable: true,type: 'text'},
        {label: 'Order',fieldName: 'Order__c', editable: true ,type: 'number'},
		{label: 'Active',fieldName: 'Active__c', editable: true,type: 'boolean'},
		{
            type: 'action',
            typeAttributes: { rowActions: actions },
        }
 
    ];

	get isDisableButton() {
	   	return (this.mainValue || this.subValue) ? false : true;
    }
  
    get rtOptions() {
        return [
            { label: 'Celerity', value: 'Celerity' },
            { label: 'Freberg', value: 'Freberg' },
            { label: 'Vindati', value: 'Vindati' },
        ];
    }
	
	get componentOptions() {
        return this.componentItems;
    }

	get productOptions(){
		return this.productItems;
	}

	get mainOptions() {
        return this.mainItems;
    }

	get subOptions() {
        return this.subItems;
    }

	handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        //this.record = row;
		this.fieldId = row.Id;
		this.deleteOption = 'Field';
		console.log('handleRowAction Id:  ' + this.fieldId);
        switch (actionName) {
			case 'newRow':
                this.isCreateField=true;
                break;
            case 'deleteRow':
				this.confirmMessage = 'Are you sure you want to delete this field?';
				this.isDialogVisible = true;
                break;
            case 'editRow':
				console.log('editRow Id:  ' + this.fieldId);
                this.isEditField=true;
                break;
            default:
        }
    }
	
	handleRowSave(event) {
		const recordInputs =  event.detail.draftValues.slice().map(draft => {
            const fields = Object.assign({}, draft);
            return { fields };
        });

        updateRecord(recordInput)
        .then(() => {
 			this.showToast('Success', 'Field updated', 'success');
			this.draftValues = [];  // Clear all draft values
			this.refreshFieldListAfterSuccess();
            
        }).catch(error => {
			this.showToast('Error creating record', error.body.message, 'error');
           
        });
    }
	
	handleRTChange(event) {
        // console.log('Change RT: ' + event.target.value);
        this.rtValue = event.detail.value;
		this.fletchComponentList(this.rtValue);
		this.fletchProductList(this.rtValue);
    }

	handleComponentChange(event) {
        this.componentValue = event.detail.value;
		this.componentValue_ = event.detail.value;
		this.fletchMainSectionList(this.rtValue, this.componentValue);
		this.openMainAndSubSection = true;
		this.mainValue = '';
		this.subValue = '';
		this.subItems = null;
		this.fieldItems = null;
    }
	
	handleSectionChange(event) {
		var sectionName = event.detail.sectionName;
		var sectionType = event.detail.type;
		if(sectionType=='Main Section') //Mainsection
		{
			this.mainValue = sectionName;
			this.fletchSubSectionList(this.rtValue,this.componentValue,this.mainValue);
			this.refreshFieldListAfterSuccess();
		}else //Sub Section
		{
			this.subValue = sectionName;
			this.refreshFieldListAfterSuccess();
		}
    }
	
	handleRefreshChange(event) {
		var newValue_ = event.detail.newValue;
		var oldValue_ = event.detail.oldValue;
		
		updateSectionRelatedData({ oldValue: oldValue_, newValue: newValue_})
		.then(result => {
			console.log('result: ' + result);
			if(result.includes('MainSection')) 
			{
				if(newValue_) this.mainValue =newValue_;
				console.log('handleRefreshChange in parent to refresh  MainSection data: ');
				this.fletchMainSectionList(this.rtValue, this.componentValue);
			}else{
				console.log('handleRefreshChange in parent to refresh  SubSection data: ');
				if(newValue_) this.subValue =newValue_;
				this.fletchSubSectionList(this.rtValue,this.componentValue,this.mainValue);
				this.refreshFieldListAfterSuccess();
			}
		})
		.catch(error => {
			this.error = error;
		});
		
    }
	
	// //For Products
	// get listProducts () {
    //    return this.listItems;
	// }

	get valueOptions(){
		return this.productValues;
	}
	

    // getSelectedItems () {
    //     this.yourSelectedValues = '';
    //     let self = this;
    //     this.template.querySelector ('c-multi-pick-list-lwc').getSelectedItems().forEach (function (eachItem) {
    //             console.log (eachItem.value);
    //             self.yourSelectedValues += eachItem.value + '; ';
    //     });
    // }

    // handleOnItemSelected (event) {
    //     if (event.detail) {
    //         this.yourSelectedValues = '';
    //         let self = this;
            
    //         event.detail.forEach (function (eachItem) {
    //                 console.log (eachItem.value);
    //                 self.yourSelectedValues += eachItem.value + '; ';
    //         });
    //     }
	// }
	
	fletchProductList(recordTypeName) {
		console.log('starting fletchProductList...');
        getProductList({ recordTypeName: recordTypeName})
		.then(result => {
			console.log('Im here with result: '+ result);
			this.productItems = result;
			this.productValues = result;
			// this.requiredOptions = result;
		})
		.catch(error => {
			this.error = error;
		});
	}
	
	

	fletchComponentList(recordTypeName) {
        getComponentList({ recordTypeName: recordTypeName})
		.then(result => {
			this.componentItems = result;
			// this.fletchProductList(recordTypeName);
		})
		.catch(error => {
			this.error = error;
		});
	}

	fletchMainSectionList(recordTypeName,componentName) {
        getMainSectionList({ recordTypeName: recordTypeName, componentName: componentName})
		.then(result => {
			this.mainItems = result;
		})
		.catch(error => {
			this.error = error;
		});
	}

	fletchSubSectionList(recordTypeName,componentName,mainSectionName) {
        getSubSectionList({ recordTypeName: recordTypeName, componentName: componentName, mainSectionName: mainSectionName})
		.then(result => {
			this.subItems = result;
		})
		.catch(error => {
			this.error = error;
		});
	}

	fletchFieldsList(groupdId) {
        getFieldList({ groupdId: groupdId})
		.then(result => {
			this.fieldItems = result;
		})
		.catch(error => {
			this.error = error;
		});
	}
	
	//////////// Event for Component Model ////////////
	handleComponentEvent(event) {
		var modeEvent = event.target.title;
		//console.log('modeEvent :' + modeEvent);
		this.componentHeader = modeEvent + ' Component';
		this.componentValue_ = modeEvent=='Edit'? this.componentValue : '';
		this.deleteOption = 'Component';
		if(modeEvent=='Delete' && this.componentValue) {
			this.confirmMessage = 'Are you sure you want to delete component: '+ this.componentValue +'?';
			this.isDialogVisible = true;
			
		}else if(this.rtValue){
			this.isEditComponent = true;
		}

    }

	closeComponentModal(event) {
		this.isEditComponent = false;
	}

	handleComponentInputChange(event){
        this.componentValue_ = event.target.value;
    }

	saveComponentModal(event) {
		var modeEvent = event.target.title;
		var concatValue = modeEvent.includes('Edit') ? (this.componentValue + this.character + this.componentValue_) : this.componentValue_;
		this.updateComponentCallbackData (this.rtValue,concatValue,'Edit');
		this.isEditComponent = false;
	}

	updateComponentCallbackData (rt,cp,md)
	{
		updateComponentRelatedData({rt: rt,componentName: cp,mode:md})
		.then(result => {
			this.showToast('Success', 'Record updated: ' + result, 'success');
			this.fletchComponentList(this.rtValue);
		})
		.catch(error => {
			this.error = error;
		});
	}
	//////////// End Event for Component Model ////////////

	//////////// Event for Field Model ////////////
	openCreateFieldModal(event) {
		this.isCreateField = true;
	}

	handleCreateFieldSubmitSuccess(event) {
 		event.preventDefault();
		const fields = event.detail.fields; // Get data from submitted form
		//console.log(JSON.stringify(fields, null, '\t'));
		fields.Record_Type__c = this.rtValue;
		fields.Component__c = this.componentValue;
		fields.Main_Section__c = this.mainValue;
		fields.Sub_Section__c = this.subValue;

		console.log(JSON.stringify(fields, null, '\t'));
		this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

	handleCreateFieldSuccess(event) {
		this.showToast('Success', 'Record created successfully with id: ' + event.detail.id, 'success');
		this.refreshFieldListAfterSuccess();
		this.isCreateField = false;
	}
	
	closeCreateFieldModal(event) {
		this.isCreateField = false;
	}

	closeEditFieldModal(event) {
		this.isEditField = false;
	}

	closeDeleteFieldModal(event) {
		this.isDialogVisible = false;
	}

    handleEditFieldSuccess(event) {
		this.showToast('Success', 'Record updated successfully', 'success');
		this.refreshFieldListAfterSuccess();
		this.isEditField = false;
    }

	handleSubmit(event) {
		event.preventDefault(); // stop the form from submitting
		const fields = event.detail.fields;
		console.log(JSON.stringify(fields));

		this.template.querySelector('lightning-record-edit-form').submit(fields);
		
	}
	
	
	deleteField(rowId) {
        deleteRecord(rowId)
            .then(() => {
				this.showToast('Success', 'Record deleted', 'success');
				this.refreshFieldListAfterSuccess();
	        })
            .catch(error => {
				this.showToast('Error loading contact', message, 'error');
            });
    }

	refreshFieldListAfterSuccess()
	{
		var tempstr = this.rtValue + this.componentValue + this.mainValue + this.subValue;
		this.fletchFieldsList(tempstr);
	}
	//////////// End Event for Field Model ////////////

	handleViewStruture(event) {
		this.isViewStructure = !this.isViewStructure;
	}

	closeViewStructureModal(){
		this.isViewStructure = !this.isViewStructure;
	}

	showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
	}
	
	//Delete Field or Component
	handleDeleteField(event){		
		if (event.detail.status === 'confirm') {
			switch (this.deleteOption) {
				case 'Component': //delete Component
					this.updateComponentCallbackData(this.rtValue, this.componentValue, 'Delete');
					break;		
				
				case 'Field': //delete row
					this.deleteField(this.fieldId);
					break;
			}
			
		}			
		this.isDialogVisible = false;
		
	}
}