import { LightningElement, api, wire, track } from 'lwc';
import getSubjectivityTemplateList from '@salesforce/apex/subjectivityController.getSubjectivityTemplateList';
import getProfessionName from '@salesforce/apex/subjectivityController.getProfessionName';
import createSubjectivitiesBySubjTemplate from '@salesforce/apex/subjectivityController.createSubjectivitiesBySubjTemplate';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ConfiguredSubjectivityModal extends LightningElement {
    //@api subjectivitySearchComponent = false;
    @api quoteId;
    @track quoteRec;
    @track subTempList=[];
    @track error;
    @track subTemplates = [];
    @track holdSubTemplates = [];
    @track sList = [];
    @track subList = [];
    @track selectedSubjTemplate = [];
    @track pageSectionName = 'Subjectivities';
    mainProfession;
    @track isLoadingModal;
    isRefreshValue = false;

    get option(){
        return [
            { label: this.mainProfession, value: this.mainProfession}
        ];
    }

    connectedCallback() {
        console.log('@@@quoteid:::'+this.quoteId);
        this.quoteRec = this.quoteId;

        getProfessionName({quoteId: this.quoteRec })
        .then(result => {
            this.mainProfession = result;
            console.log('@@@mainProfession:::'+this.mainProfession);
        })
        .catch(error => {
            this.error = error;
            this.subTempList = undefined;
            console.log('## error in adding main profession: ' + JSON.stringify(error));
        });
        
        getSubjectivityTemplateList({quoteId: this.quoteRec })
        .then(subTemplateList => {
            this.error = undefined;
            this.subTemplates = [];
                this.holdSubTemplates = [];
                console.log('## subTemplateList: ' + JSON.stringify(subTemplateList));
                var sList = [];
                subTemplateList.forEach(sTemplate => {
                    if (this.subList.some(e => e.name === sTemplate.Subjectivity_Name__c)) {
                        console.log(' ## sTemplate: ' + sTemplate);
                    } else {
                        sList.push(sTemplate);

                    }
                    //console.log(' ## sList: ' + JSON.stringify(sList));
                });
                sList.sort(function (a, b) {
                    if (a.Subjectivity_Name__c < b.Subjectivity_Name__c) { return -1; }
                    if (a.Subjectivity_Name__c > b.Subjectivity_Name__c) { return 1; }
                    return 0;
                });
                this.subTemplates = sList;
                this.holdSubTemplates = sList;
                console.log('@@@ sList sorted:: ' + JSON.stringify(this.subTemplates));
        })
        .catch(error => {
            this.error = error;
            this.subTempList = undefined;
            console.log('## error in adding new row: ' + JSON.stringify(error));
        });
    } 
    selectRow(event) {
        if (event.target.checked) {
            this.selectedSubjTemplate.push(event.target.value);
            if (this.selectedSubjTemplate.length == this.subTemplates.length) {
                var selectAllChkBox = this.template.querySelector('.selectAllChkBox');
                selectAllChkBox.checked = event.target.checked;
            }
        }
        if (!event.target.checked) {
            //this.selectedSubjTemplate.pop(event.target.value);
            this.removeA(this.selectedSubjTemplate, event.target.value );
            console.log('@@removed element::'+event.target.value);
            var selectAllChkBox = this.template.querySelector('.selectAllChkBox');
            selectAllChkBox.checked = event.target.checked;
        }
        console.log(' @@@ final selected subjTemplate: ' + JSON.stringify(this.selectedSubjTemplate));
    }

    removeA(arr) {
        var what, a = arguments, L = a.length, ax;
        while (L > 1 && arr.length) {
            what = a[--L];
            while ((ax= arr.indexOf(what)) !== -1) {
                arr.splice(ax, 1);
            }
        }
        return arr;
    }

    @api closeSubModal;
    closeModal() {
        this.selectedSubjTemplate = [];
        this.searchTerm = '';
        this.closeSubModal = false;
    // Creates the event with the data.
        const selectedEvent = new CustomEvent("closemodal", {
        detail: this.closeSubModal
        });
    // Dispatches the event.
        this.dispatchEvent(selectedEvent);
        const refreshEvent = new CustomEvent("refreshmodal", {
            detail: this.isRefreshValue
            });
        this.dispatchEvent(refreshEvent);
    }

    async handleAddSubjectivities(event) {
        if (this.selectedSubjTemplate.length > 0) {
            this.isLoadingModal = true;
            try {
                const operation = await createSubjectivitiesBySubjTemplate({ quoteId: this.quoteRec, subjTemplates: this.selectedSubjTemplate });
                if (operation == 'success') {
                    this.isLoadingModal = false;
                    this.showToast("Success", "Subjectivities added successfully.", "success");
                    console.log('@@Rows added::'+operation);
                    this.isRefreshValue = true;
                    console.log('@@this.isRefreshValue::'+this.isRefreshValue);
                }
            } catch (error) {
                var errorMsg = 'Error in adding Subjectivities.';
                console.log('## error in creating records: ' + JSON.stringify(error));
                if(error.body.pageErrors[0].message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                    var err = error.body.pageErrors[0].message;
                    errorMsg = err.substring(err.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION')+34,err.indexOf(': []'));
                }
                if(error.body.pageErrors[0].message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION, This Quote is locked for editing')){
                    var err = error.body.pageErrors[0].message;
                    errorMsg = 'This Quote is locked for editing when status is Quoted or Bound';
                }else if(error.body.pageErrors[0].statusCode.includes('ENTITY_IS_LOCKED')){
                    errorMsg = 'This record is locked. If you need to edit it, contact your admin';
                }
                this.showToast("Error", errorMsg, "error");
            }
            finally {
                console.log('close modal'); // Finally
                this.closeModal();
            }
        }
        else {
            this.showToast("Select Subjectivity", "Please select at least one Subjectivity", "error");
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

    selectAllRow(event) {
        if (event.target.checked) {
            this.template.querySelectorAll('.chkBox').forEach(each => {
                each.checked = event.target.checked;
            })
            this.selectedSubjTemplate = [];
            this.subTemplates.forEach(item => {
                this.selectedSubjTemplate.push(item.Id);
            })
        } else {
            this.template.querySelectorAll('.chkBox').forEach(each => {
                each.checked = event.target.checked;
            })
            this.selectedSubjTemplate = [];
        }
        console.log(' ## selectedSubjTemplate from SelectALL: ' + JSON.stringify(this.selectedSubjTemplate));
    }

    handleSearchTextChange(event) {
        this.searchTerm = event.target.value;
        if (this.searchTerm === '') {
            this.subTemplates = this.holdSubTemplates;
        } else {
            var searchRows = [];
            this.holdSubTemplates.forEach(element => {
                if (element.Subjectivity_Name__c.toLowerCase().includes(this.searchTerm.toLowerCase())) {
                    searchRows.push(element);
                }
            });
            this.subTemplates = searchRows;
        }
    }


}