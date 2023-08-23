import { LightningElement, api, wire, track  } from 'lwc';
import { updateRecord, getRecordUi,getRecord,getFieldValue,deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const FIELDS = ['Rating_Modifier_Template__c.Modifier_Product__c','Rating_Modifier_Template__c.Page_Section__c',
                'Rating_Modifier_Template__c.Sub_Section__c','Rating_Modifier_Template__c.Sort_Order__c',
                'Rating_Modifier_Template__c.Display_Format__c'];

export default class RatingModifierTempItemSectionLwc extends LightningElement {
    @api name;
	@api sectionItems = []; 
	@api modifierProduct;
	@api mainName;
    @api subName;
    
    section;
	@track valueKey;
	@track label;
	@track order;
    @track displayformat;

	@track openEditmodel = false;
	@track openNewmodel = false;
	@track isDisableButton = false;
	@track isDialogVisible = false;
	@track confirmMessage;
    @track error;
    character =',';

	handleOptionChange(e) {
        let value = e.detail.value;
        const event = new CustomEvent('changekey', {
            detail: {value: value, sectionType: this.name},
        });
        this.dispatchEvent(event);
       
    }

    @wire(getRecord, { recordId: '$valueKey', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
			this.showToast('Error loading', message, 'error');
        } else if (data) {
            console.log(data);
            this.section = data;
			this.modifierProduct = this.section.fields.Modifier_Product__c.value;
			this.mainName = this.section.fields.Page_Section__c.value;
			this.subName = this.section.fields.Sub_Section__c.value;
            this.order = this.section.fields.Sort_Order__c.value;
            this.displayformat = this.section.fields.Display_Format__c.value;
	    }
    }

    get isMainSection() {
        return (this.name=='Page Section') ? true : false;
    }

    handleMode(event) {
		var modeEvent = event.target.title;
		console.log('title: '+ modeEvent);
		if(modeEvent.includes('Edit')){ 
			console.log('Edit mode: '+ this.label);
			this.isDisableButton=false;
            //if(this.label)  
            this.openEditmodel = true;  
		}
		if(modeEvent.includes('New')){
			console.log('New mode: '+ this.label);
			if(this.isMainSection) this.mainName = '';
			else this.subName = '';
			
			this.isDisableButton=false;
			this.openNewmodel = true; 
		}
		
	}
    
    handleEditSuccess(event) {
		this.isDisableButton=true;
     	var message= event.detail.id ;
		var value_ = this.isMainSection ? event.detail.fields['Page_Section__c'].value : event.detail.fields['Sub_Section__c'].value ;
		//console.log(JSON.stringify(event.detail, null, '\t'));
   		this.showToast('Saved', message, 'success');
		if(this.label != value_){
			console.log('send event to refresh data: ');
			var oldstr = this.isMainSection ? (this.modifierProduct + this.character + this.label) 
							: (this.modifierProduct + this.character + this.mainName + this.character + this.label);
			var newstr = value_;
			this.handleRefreshChange(oldstr, newstr);
		}
		this.closeModal();
    }

    handleNewSuccess(event) {
		this.isDisableButton=true;
     	var message= event.detail.id ;
		var value_ = this.isMainSection ? event.detail.fields['Page_Section__c'].value : event.detail.fields['Sub_Section__c'].value ;
	
		this.showToast('Saved', message, 'success');
		var newstr = this.isMainSection ? (this.modifierProduct + this.character + this.value_) 
								: (this.modifierProduct + this.character + this.mainName + this.character + this.value_);
		this.handleRefreshChange('', newstr);
		this.closeModal();
    }

    //For New or Edit action in Mainsection/Subsection 	
	handleSubmit(event) {
		event.preventDefault();
		const fields = event.detail.fields;// Get data from submitted form
		fields.Modifier_Product__c = this.modifierProduct;
		
		if(!this.isMainSection) 
			fields.Page_Section__c = this.mainName;
		
		console.log('After: '+ JSON.stringify(fields, null, '\t'));
		this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleRefreshChange(oldValue_, newValue_) {
        var infos = {oldValue : oldValue_, newValue : newValue_};
      const event = new CustomEvent('refreshchange', {
          detail: infos
      });
      this.dispatchEvent(event);
    }

    closeModal(event) {
		this.openEditmodel = false;
		this.openNewmodel = false; 
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