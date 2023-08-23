import { LightningElement, track } from 'lwc';
import { updateRecord, getRecordUi,getRecord,deleteRecord  } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getPageSectionListMulti from '@salesforce/apex/ratingModiferTempSectionLwcController.getPageSectionListMulti';
import getFieldListMulti from '@salesforce/apex/ratingModiferTempSectionLwcController.getFieldListMulti';
import getSubSectionListMulti from '@salesforce/apex/ratingModiferTempSectionLwcController.getSubSectionListMulti';

const actions = [
    { label: 'Edit', name: 'editRow' },
	{ label: 'Delete', name: 'deleteRow' },
	{ label: 'New', name: 'newRow' },
];

const FIELDS = ['Rating_Modifier_Template__c.Modifier_Format__c',
                'Rating_Modifier_Template__c.Rating_Modifier_Code__c','Rating_Modifier_Template__c.Page_Section__c',
                'Rating_Modifier_Template__c.Sub_Section__c','Rating_Modifier_Template__c.Comment__c',
                'Rating_Modifier_Template__c.Display_Format__c','Rating_Modifier_Template__c.Eligibility_Weighting_Factor__c',
                'Rating_Modifier_Template__c.Factor_Default_Value__c','Rating_Modifier_Template__c.Factor_Max__c',
                'Rating_Modifier_Template__c.Factor_Min__c','Rating_Modifier_Template__c.Picklist_Values__c',
                'Rating_Modifier_Template__c.Picklist_Default_Value__c','Rating_Modifier_Template__c.Picklist_Range__c',
                'Rating_Modifier_Template__c.Sort_Order__c','Rating_Modifier_Template__c.Product__c'];

export default class RatingModifierTempSectionLwc extends LightningElement {
    @track openMainAndSubSection = false;
    @track isCreateField = false;
    @track isEditField = false;
    @track isDialogVisible = false;
    @track isViewStructure = false;

    @track mainValue;
	@track subValue;
    

    @track draftValues = [];
    @track mainItems = []; 
    @track subItems = []; 

    @track productMultiPicklist;
    @track fieldItems;
    @track error;
    @track confirmMessage;
    @track deleteOption; //values: Component or Field
    record = {};

    @track columns = [
        {label: 'Field name',fieldName: 'Name'},
        {label: 'Modifier Format',fieldName: 'Modifier_Format__c'},
        {label: 'Product',fieldName: 'Product__c'},
        {label: 'Rating Modifier Code',fieldName: 'Rating_Modifier_Code__c'},
        {label: 'Page Section',fieldName: 'Page_Section__c'},		
        {label: 'Sub Section',fieldName: 'Sub_Section__c'},
        {label: 'Comment',fieldName: 'Comment__c', editable: true},
        {label: 'Display Format',fieldName: 'Display_Format__c'},
        {label: 'Eligibility Weighting Factor',fieldName: 'Eligibility_Weighting_Factor__c',editable: true, type:'number'},
        {label: 'Factor Default Value',fieldName: 'Factor_Default_Value__c',editable: true, type:'number'},
        {label: 'Factor Max',fieldName: 'Factor_Max__c',editable: true, type:'number'},
        {label: 'Factor Min',fieldName: 'Factor_Min__c',editable: true, type:'number'},
        {label: 'Option Values',fieldName: 'Picklist_Values__c', editable: true},
        {label: 'Picklist Default Value',fieldName: 'Picklist_Default_Value__c',editable: true},
        {label: 'Picklist Range',fieldName: 'Picklist_Range__c',editable: true},
        {label: 'Sort Order',fieldName: 'Sort_Order__c',editable: true, type:'number'},
		{
            type: 'action',
            typeAttributes: { rowActions: actions },
        }
 
    ];

    //Disable Button
    get isDisableButton() {
        //return (this.mainValue || this.subValue) ? false : true;
        return (this.productMultiPicklist || this.mainValue) ? false : true;
    }

    //get Product value
    get options() {
        return [
            // { label: 'Cyber Standalone', value: 'Cyber Standalone' },
            // { label: 'MPL Standalone', value: 'MPL Standalone' },
            // { label: 'Private Company Combo', value: 'Private Company Combo' },
            { label: 'Cyber', value: 'Cyber' },
            { label: 'MPL', value: 'MPL' },
        ];
    }

    //Page Section
    get mainOptions() {
        return this.mainItems;
    }

    //Sub Section
	get subOptions() {
        return this.subItems;
    }

    //Handle Change Product value
    handleProductChangeMulti(event){
        console.log('Change Modifier Product: ' + event.target.value);
        this.productMultiPicklist = event.detail.value;
        this.fletchPageSectionListMulti(this.productMultiPicklist);
        this.openMainAndSubSection = true;
        this.mainValue = '';
		this.subValue = '';
		this.subItems = null;
        this.fieldItems = null;
    }

    //Handle Page Section & Sub Section Change
    handleSectionChange(event){
        let value = event.detail.value;
        var sectionType = event.detail.sectionType;
        console.log(sectionType);
		if(sectionType=='Page Section') //Mainsection
		{
			this.mainValue = value;
			this.fletchSubSectionListMulti(this.productMultiPicklist,this.mainValue);
			this.refreshFieldListAfterSuccess(); //Temps
		}else //Sub Section
		{
			this.subValue = value;
			this.refreshFieldListAfterSuccess();
		}
    }

    //Handle Save Row
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

    //Handle Row action Edit/New/Delete
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
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

    //Handle Create Fields Success
    handleCreateFieldSuccess(event) {
		this.showToast('Success', 'Record created successfully with id: ' + event.detail.id, 'success');
		this.refreshFieldListAfterSuccess();
		this.isCreateField = false;
    }

    //Handle Create Fields Submit Success
    handleCreateFieldSubmitSuccess(event) {
        event.preventDefault();
       const fields = event.detail.fields; // Get data from submitted form
       fields.Product__c = this.productMultiPicklist;
       fields.Page_Section__c = this.mainValue;
       fields.Sub_Section__c = this.subValue;

       console.log(JSON.stringify(fields, null, '\t'));
       this.template.querySelector('lightning-record-edit-form').submit(fields);
   }

   closeCreateFieldModal(event) {
       this.isCreateField = false;
   }

   closeEditFieldModal(event) {
    this.isEditField = false;
   }

   openCreateFieldModal(event) {
    this.isCreateField = true;
   }

   //Handle Submit
   handleSubmit(event) {
    event.preventDefault(); // stop the form from submitting
    const fields = event.detail.fields;
    console.log(JSON.stringify(fields));

    this.template.querySelector('lightning-record-edit-form').submit(fields);
    
   }
   
   //Handle Edit Field When Success
   handleEditFieldSuccess(event) {
    this.showToast('Success', 'Record updated successfully', 'success');
    this.refreshFieldListAfterSuccess();
    this.isEditField = false;
   }   

   //Detele Field Row
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

   	//Delete Field show DialogVisible
	handleDeleteField(event) {
        if (event.detail.status === 'confirm') {
			switch (this.deleteOption) {
				case 'Field': //delete row
					this.deleteField(this.fieldId);
					break;
			}
			
		}			
		this.isDialogVisible = false;
    }
        
    //Show Toast
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
    
    //Show View Structure
    handleViewStruture(event) {
        //this.isViewStructure = !this.isViewStructure;
        this.isViewStructure = true;
	}

    //Close Modal View Structure
	// closeViewStructureModal(){
    //     this.isViewStructure = !this.isViewStructure;
    //     //this.isViewStructure = false;
    // }
    closeModal(){
        this.isViewStructure = false;
    }
    
    //-----------------------fletch-------------------------------------------------

    //fletch Page Section List Multi
    fletchPageSectionListMulti(modifierProductName) {
        getPageSectionListMulti({ modifierProductName: modifierProductName})
		.then(result => {
            this.mainItems = result;
            this.refreshFieldListAfterSuccess();
		})
		.catch(error => {
			this.error = error;
		});
    }
    
    //fletch Sub Section List Multi
    fletchSubSectionListMulti(modifierProductName,pageSectionName) {
        getSubSectionListMulti({ modifierProductName: modifierProductName, pageSectionName: pageSectionName})
		.then(result => {
            this.subItems = result;
            this.refreshFieldListAfterSuccess();
		})
		.catch(error => {
			this.error = error;
		});
	}

    //fletch Fields List Load Datatable
    fletchFieldsListMulti(modifierProductName,pageSectionName,subSectionName) {
        getFieldListMulti({ modifierProductName: modifierProductName, pageSectionName: pageSectionName,subSectionName: subSectionName})
		.then(result => {
			this.fieldItems = result;
		})
		.catch(error => {
			this.error = error;
		});
    }
    
    refreshFieldListAfterSuccess() {
        this.fletchFieldsListMulti(this.productMultiPicklist, this.mainValue, this.subValue);
    }

}