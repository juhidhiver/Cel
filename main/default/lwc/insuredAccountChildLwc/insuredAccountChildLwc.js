import { LightningElement,api,track } from 'lwc';

export default class InsuredAccountChildLwc extends LightningElement {

    @api item;
    @api isChangeOnAccount;
    @api selectedAccountId;
    @api childRecordTypeId;
    @api recordInfoDefined;
    @api submissionStage;
    @track disableFirstTab = false;
    @api isAqueous;
    @api recordInfo;
    @track contactId;
    @api submissionType;
    
    handleSelection(event) {
        this.contactId = event.detail.selectedId;
    }
    connectedCallback(){
        console.log("Child Stage -->",this.submissionStage);
        console.log("Child Prod -->",this.isAqueous);
        if(this.submissionStage == "Closed Won" || this.submissionStage == "Closed Lost" || this.submissionStage == "Declined"
        || this.submissionType == 'Full Amendment'){
            if(this.isAqueous){
                this.disableFirstTab = true;
            }
        }
        console.log("disableFirstTab Prod -->",this.disableFirstTab);
    }
    handleLookUpChildSelection(event) {
        let selectedId = event.detail.selectedId;
        const evt = new CustomEvent('handlelookupchildselection', {
            detail: {selectedId}
        });
        this.dispatchEvent(evt);
        /*
        this.selectedAccountId = event.detail.selectedId;
        this.handleGetAccountInfo();*/
    }
    @api handleGetAccountInfo() {
        this.recordInfo.fields.forEach(element => {
            if(element.name == 'RecordTypeId') {
                element.value = this.childRecordTypeId;
                element.disabled = true;
            }
            if(element.name == 'AccountId') {
                element.value = this.selectedAccountId;
            }
        });
        getAccountInfos({ recordId: this.selectedAccountId })
            .then((account) => {
                var listMainFields = [];
                var listSubMainFields = [];
                var mapDataJson = JSON.parse(JSON.stringify(this.mapData));
                console.log('mapDataJson', mapDataJson);

                mapDataJson.forEach(function (item) {
                    if (item.mainSectionFields) {
                        listMainFields = item.mainSectionFields;
                    }
                    console.log('listMainFields', listMainFields);
                    if (item.subSectionChilds && !item.isComponent) {
                        item.subSectionChilds.forEach(function (item1) {
                            if(item1.subSectionChildFields) {
                                item1.subSectionChildFields.forEach(function(item2) {
                                    listSubMainFields.push(item2);
                                });
                               
                            }
                        });

                    }

                });
                if (listMainFields) {
                    listMainFields.forEach(function (item) {
                        if (item) {
                            item.value = account == null ? '' : account[item.sourceFieldApi];
                        }
                    });
                }
                if (listSubMainFields) {
                    listSubMainFields.forEach(function (item) {
                        if (item) {
                            item.value = account == null ? '' : account[item.sourceFieldApi];
                        }
                    });
                }
                this.mapData = mapDataJson;
            })
            .catch(error => {
                console.log('error handleLookUpChildSelection :' + JSON.stringify(error));
            });
    }

    @api getValuesOnForm(){
        var result = [];
        this.template
        .querySelectorAll("c-generate-element-lwc")
        .forEach(element => {
            var tmp = element.getValuesOnForm();
            result.push(tmp);        
        });
        return result;
    }
    @api checkChangesOnAccount() {        
        //Check change on Account form
        var result = false;
        this.template
        .querySelectorAll("c-generate-element-lwc")
        .forEach(element => {
            if(element.checkChangesOnAccount()) {
                result = true;
            }
        });
        return result;
        //End
    }
}