import { LightningElement, api, wire, track } from 'lwc';
import { updateRecord, getRecordUi,getRecord,getFieldValue,deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateSectionRelatedData from '@salesforce/apex/sectionSettingLwcController.updateSectionRelatedData';
import getSubSectionList from '@salesforce/apex/sectionSettingLwcController.getSubSectionList';
import getMainSectionList from '@salesforce/apex/sectionSettingLwcController.getMainSectionList';

const FIELDS = ['SectionSetting__c.Active__c','SectionSetting__c.Order__c','SectionSetting__c.Main_Section__c','SectionSetting__c.Sub_Section__c','SectionSetting__c.Criteria__c',];
export default class SectionSettingItemLwc extends LightningElement {
	@api name;
	@api sectionItems = []; 
	@api rt;
	@api component;
	@api mainName;
	@api subName;

	section;
	@track valueKey;
	@track label;
	@track criteria;
	@track order;
	@track active;

	@track openEditmodel = false;
	@track openNewmodel = false;
	@track isDisableButton = false;
	@track isDialogVisible = false;
	@track confirmMessage;
	@track error;
		
	character =',';

	@wire(getRecord, { recordId: '$valueKey', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
			this.showToast('Error loading contact', message, 'error');
        } else if (data) {
            this.section = data;
			this.rt = this.section.fields.Record_Type__c.value;
			this.component = this.section.fields.Component__c.value;
			this.mainName = this.section.fields.Main_Section__c.value;
			this.subName = this.section.fields.Sub_Section__c.value;
			this.criteria = this.section.fields.Criteria__c.value;
            this.order = this.section.fields.Order__c.value;
            this.active = this.section.fields.Active__c.value;
	    }
    }

	get isMainSection() {
     	return (this.name=='Main Section') ? true : false;
    }

	handleOptionChange(event) {
    	this.label = event.target.options.find(opt => opt.value === event.detail.value).label;
		this.valueKey = event.detail.value;
		this.subSectionName = event.detail.name;
		this.handleChangeKey();
    }

	handleChangeKey() {
	    var infos = {sectionName : this.label, type : this.name};
        const event = new CustomEvent('changekey', {
            detail: infos
        });
        this.dispatchEvent(event);
    }
	
	closeModal(event) {
		this.openEditmodel = false;
		this.openNewmodel = false; 
    }
	
	handleMode(event) {
		var modeEvent = event.target.title;
		console.log('title: '+ modeEvent);
		if(modeEvent.includes('Edit')){ 
			console.log('Edit mode: '+ this.label);
			this.isDisableButton=false;
			if(this.label)  this.openEditmodel = true;  
		}
		if(modeEvent.includes('New')){
			console.log('New mode: '+ this.label);
			if(this.isMainSection) this.mainName = '';
			else this.subName = '';
			
			this.isDisableButton=false;
			this.openNewmodel = true; 
		}
		if(modeEvent.includes('Delete')){
			if(this.isMainSection && this.mainName){
				this.confirmMessage = 'Are you sure you want to delete this Main Section: '+ this.mainName +'?';
				this.isDialogVisible = true;
			}
			else if(this.subName){
				this.confirmMessage = 'Are you sure you want to delete this Sub Section: '+ this.subName+'?';
				this.isDialogVisible = true;
			}	

		}	
		
	}
	
	//For New or Edit action in Mainsection/Subsection 	
	handleSubmit(event) {
		event.preventDefault();
		const fields = event.detail.fields;// Get data from submitted form
		fields.Record_Type__c = this.rt;
		fields.Component__c = this.component;
		
		if(!this.isMainSection) 
			fields.Main_Section__c = this.mainName;
		
		console.log('After: '+ JSON.stringify(fields, null, '\t'));
		this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleEditSuccess(event) {
		this.isDisableButton=true;
     	var message= event.detail.id ;
		var sectionName_ = this.isMainSection ? event.detail.fields['Main_Section__c'].value : event.detail.fields['Sub_Section__c'].value ;
		//console.log(JSON.stringify(event.detail, null, '\t'));
   		this.showToast('Saved', message, 'success');
		if(this.label != sectionName_){
			console.log('send event to refresh data: ');
			var oldstr = this.isMainSection ? (this.rt + this.character + this.component + this.character + this.label) 
							: (this.rt + this.character + this.component + this.character + this.mainName + this.character + this.label);
			var newstr = sectionName_;
			this.handleRefreshChange(oldstr, newstr);
		}
		this.closeModal();
    }

	handleNewSuccess(event) {
		this.isDisableButton=true;
     	var message= event.detail.id ;
		var sectionName_ = this.isMainSection ? event.detail.fields['Main_Section__c'].value : event.detail.fields['Sub_Section__c'].value ;
	
		this.showToast('Saved', message, 'success');
		var newstr = this.isMainSection ? (this.rt + this.character + this.component + this.character + this.sectionName_) 
								: (this.rt + this.character + this.component + this.character + this.mainName + this.character + this.sectionName_);
		this.handleRefreshChange('', newstr);
		this.closeModal();
    }

	handleRefreshChange(oldValue_, newValue_) {
	  	var infos = {oldValue : oldValue_, newValue : newValue_};
		const event = new CustomEvent('refreshchange', {
        	detail: infos
		});
		this.dispatchEvent(event);
    }

	handleDeleteSection(event){
		if (event.detail.status === 'confirm') {
			this.deleteSection();
		}
		this.isDialogVisible = false;
	}
	
	deleteSection() {
		var newVal = '';
		var oldVal = this.isMainSection ? (this.rt + this.character + this.component + this.character + this.mainName) 
							: (this.rt + this.character + this.component + this.character + this.mainName + this.character + this.subName);
		console.log('oldVal: '+oldVal);

		updateSectionRelatedData({ oldValue: oldVal, newValue: newVal})
		.then(result => {

			if(result.includes('deleted Main')) 
			{
				this.showToast('Success', 'the Main Section deleted.', 'success');
				this.fletchMainSectionList(this.rt, this.component);
			}else{
				this.showToast('Success', 'the Sub Section deleted.', 'success');
				this.fletchSubSectionList(this.rt, this.component, this.mainName);
				this.subName = newVal;
			}
		});
		
		
    }
 
	fletchSubSectionList(recordTypeName,componentName,mainSectionName) {
        getSubSectionList({ recordTypeName: recordTypeName, componentName: componentName, mainSectionName: mainSectionName})
		.then(result => {
			this.sectionItems = result;
		})
		.catch(error => {
			this.error = error;
		});
	}
	
	fletchMainSectionList(recordTypeName,componentName) {
        getMainSectionList({ recordTypeName: recordTypeName, componentName: componentName})
		.then(result => {
			this.sectionItems = result;
		})
		.catch(error => {
			this.error = error;
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
	
	
}