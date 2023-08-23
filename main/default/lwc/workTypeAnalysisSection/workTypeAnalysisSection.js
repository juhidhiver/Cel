import { LightningElement, api, wire, track } from 'lwc';
import getUWAnalysisTemplates from '@salesforce/apex/UWAnalysisSectionController.getUWAnalysisTemplates';
import createUWAnalysisByTemplate from '@salesforce/apex/UWAnalysisSectionController.createUWAnalysisByTemplate';
import getUWAnalysis from '@salesforce/apex/UWAnalysisSectionController.getUWAnalysis';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import saveUWAnalysis from '@salesforce/apex/UWAnalysisSectionController.saveUWAnalysis';
import updateExistingReferredQuotes from '@salesforce/apex/SubmissionInfoLwcController.updateExistingReferredQuotes';
import ERROR_CANNOT_UPDATE_SUBMISSION_HAS_LOCKED_QUOTE from '@salesforce/label/c.ERROR_CANNOT_UPDATE_SUBMISSION_HAS_LOCKED_QUOTE';
import { deleteRecord } from 'lightning/uiRecordApi';
import getAnnualModifier from '@salesforce/apex/UWAnalysisSectionController.getAnnualModifier';

export default class WorkTypeAnalysisSection extends LightningElement {
    @api _opportunityId;
    @api _annualGrossFee;
    @api _saveUW;
    @api disableSaveButton;
    @api pageSectionName = 'Work Types';
    @api pageSectionDnCName = 'D&C Turnover Splits';

    @track searchTerm = '';
    @track proWorkSplitSectionName = '';
    @track addUWAnalysisModal = false;
    @track UWAnalysisTemplates = [];
    @track holdUWAnalysisTemplates = [];
    @track selectedUWTemplate = [];
    @track uwAnalysisList = [];
    @track uwAnalysisDnCTurnoverList = [];
    @track uwAnalysisTerritoryList = [];
    @track uwAnalysisProWorkSplitList = [];
    @track isDnCTurnover = false;
    @track isLoadingTable = false;
    @track totalRiskPercent;
    @track totalDnCAmount;
    @track totalDnCSplitPercent;
    @track totalProWorkSplitAmount;
    @track totalProWorkSplitSplitPercent;
    @track totalNotionalIncome;
    @track categories = [];
    @track categorySelected = [];
    sendNotionalEvent = false;
    mainProfession;

    @api get opportunityId() {
        return this._opportunityId;
    }
    set opportunityId(value) {
        this._opportunityId = value;
        this.getAllUWAnalysis();
    }

    @api get annualGrossFee() {
        return this._annualGrossFee;
    }
    set annualGrossFee(value) {
        this._annualGrossFee = value;
         
        /**** New Code For CD-145 ********/
        this.getAnnualRatingModifierData(value);
       // this.handleAnnualAmountChange();
       //this.getTotals();
       console.log('setter called');
        console.log('Anual Gros fee -', this._annualGrossFee);
    }

    /**** New Code For CD-145 ********/
    getAnnualRatingModifierData(value){
        getAnnualModifier({oppId: this._opportunityId}).then(data => {
            if(data){
                console.log('data[0].Rating_Modifier_Value__c'+data[0].Rating_Modifier_Value__c);
                console.log('value'+value);

             if((data[0].Rating_Modifier_Value__c == value) || (value==undefined)){
                 console.log('rating modifier is equal')
                 var uwAnalysisTerritoryList = [];
                 var uwAnalysisDnCTurnoverList = [];
                 var uwAnalysisProWorkSplitList = [];
                 var totalRiskPer = 0;
                 var totalDnCAmt = 0;
                 var totalDnCSplitPer = 0;
                 var totalProWorkSplitAmt = 0;
                 var totalProWorkSplitSplitPer = 0;
                 var totalNotional = 0;
                 this.uwAnalysisList.forEach(uwA => {
                     console.log('uwA'+uwA)
                     if (uwA.criteria == 'Territory') {
                         uwAnalysisTerritoryList.push(JSON.parse(JSON.stringify(uwA)));
                     } else if (uwA.criteria == 'D&C Turnover Split') {
                         uwAnalysisDnCTurnoverList.push(JSON.parse(JSON.stringify(uwA)));
                     } else {
                         uwAnalysisProWorkSplitList.push(JSON.parse(JSON.stringify(uwA)));
                     }
                 });
                 if (uwAnalysisDnCTurnoverList) {
                    uwAnalysisDnCTurnoverList.forEach(item => {
                        console.log('item DnC', item);
                        if (item.amount) totalDnCAmt = totalDnCAmt + parseFloat(item.amount);
                        if (item.splitPercentage) totalDnCSplitPer = totalDnCSplitPer + parseFloat(item.splitPercentage);
                        if (item.notonalIncome) totalNotional = totalNotional + parseFloat(item.notonalIncome);
                    });
               
                    if( totalDnCAmt ===  parseFloat(this._annualGrossFee) ){
                        totalDnCSplitPer = 100.00;
                    }
                }
                if (uwAnalysisProWorkSplitList) {
                    uwAnalysisProWorkSplitList.forEach(item => {
                        //console.log('item pro', item);
                        if (item.amount) totalProWorkSplitAmt = totalProWorkSplitAmt + parseFloat(item.amount);
                        if (item.splitPercentage) totalProWorkSplitSplitPer = totalProWorkSplitSplitPer + parseFloat(item.splitPercentage);
                    });
                    if( totalProWorkSplitAmt ===  parseFloat(this._annualGrossFee) ){
                        totalProWorkSplitSplitPer = 100.00;
                    }
                    
                }
                this.totalDnCSplitPercent = totalDnCSplitPer;
                this.totalProWorkSplitSplitPercent = totalProWorkSplitSplitPer;

                this.totalDnCSplitPercentDisplay = totalDnCSplitPer.toFixed(2);
                this.totalProWorkSplitSplitPercentDisplay = totalProWorkSplitSplitPer.toFixed(2);



             }
             else{
                    console.log('rating modifier not equal')
                    this.handleAnnualAmountChange();
             }

            }
        }).catch(error => {
            console.log(' error getting Rating modfier: ' + JSON.stringify(error));
        })

    }

    get option() {
        return this.categories;
    }

    handleAnnualAmountChange = () => {
        if (this._annualGrossFee) {
            this.template.querySelectorAll("lightning-input").forEach(each => {
                var name = each.name;
                console.log('each.name', each.name);
                if (name.includes("_split")) {
                    var newSplitPercentage = each.value
                    //Annual gross fees / turnover * Split %
                    console.log('newSplitPercentage'+newSplitPercentage);
                    var newAmount = ((this._annualGrossFee * newSplitPercentage) / 100);
                    console.log('._split newAmount', newAmount);
                    this.uwAnalysisList.forEach(item => {
                        if (item.identifier == name.split("_")[0]) {
                            item.splitPercentage = parseFloat(newSplitPercentage);
                            item.amount = parseFloat(newAmount);
                            if (item.criteria == 'D&C Turnover Split') {
                                if (item.amount) {
                                    console.log('._amount notonalIncome', (item.amount));
                                    //if(item.amount) console.log('it works the amount thingy');
                                    var calNotionalIncome = ((item.amount * item.ratingFactor) / 100);
                                    item.notonalIncome = calNotionalIncome;
                                } else {
                                    item.notonalIncome = 0;
                                }
                            }
                        }
                    })
                }
            });
        }
        setTimeout(() => { this.getTotals(); }, 2000);
    }

    sendEventToAllowSaveFromParent(){
        const sendEventToAllowSave = new CustomEvent("sendeventtoallowsave", {
            detail: true
        });
        this.dispatchEvent(sendEventToAllowSave);
    }

    getAllUWAnalysis = () => {
        this.isLoadingTable = !this.isLoadingTable;
        getUWAnalysis({ opportunityId: this._opportunityId })
            .then(uwAnalysisList => {
                this.uwAnalysisList = uwAnalysisList.uwAlyRecord;
                this.mainProfession = uwAnalysisList.mainProfession;
                this.proWorkSplitSectionName = uwAnalysisList.mainProfession;
                let option = { label: uwAnalysisList.mainProfession, value: uwAnalysisList.mainProfession };
                this.categories.push(option);
                console.log('## uwAnalysisListJSON: 11' + JSON.stringify(this.uwAnalysisList));

                this.uwAnalysisList.forEach(uwA => {
                    this.refreshUWListToShow(uwA);
                });
                this.uwAnalysisTerritoryList.sort(function (a, b) {
                    return a.sortOrder - b.sortOrder;
                });
                this.uwAnalysisProWorkSplitList.sort(function (a, b) {
                    return a.sortOrder - b.sortOrder;
                });

                if (this.uwAnalysisDnCTurnoverList.length) this.isDnCTurnover = true;
                console.log('uwAnalysisDnCTurnoverList.length  -', this.uwAnalysisDnCTurnoverList.length);
                this.getTotals();
                this.isLoadingTable = !this.isLoadingTable;
            })
            .catch(error => {
                console.log(' error getAllUWAnalysis: ' + JSON.stringify(error));
            })
    }

    refreshUWListToShow = (uwA) => {
        if (uwA.criteria == 'Territory') {
            this.uwAnalysisTerritoryList.push(uwA);
        } else if (uwA.criteria == 'D&C Turnover Split') {
            this.uwAnalysisDnCTurnoverList.push(uwA);
        } else {
            this.uwAnalysisProWorkSplitList.push(uwA);
        }
        //console.log('uwAnalysisTerritoryList -', this.uwAnalysisTerritoryList);
        //console.log('uwAnalysisDnCTurnoverList -', this.uwAnalysisDnCTurnoverList);
        //console.log('uwAnalysisProWorkSplitList -', this.uwAnalysisProWorkSplitList);
    }

    getTotals = () => {
        var totalRiskPer = 0;
        var totalDnCAmt = 0;
        var totalDnCSplitPer = 0;
        var totalProWorkSplitAmt = 0;
        var totalProWorkSplitSplitPer = 0;
        var totalNotional = 0;
        var uwAnalysisTerritoryList = [];
        var uwAnalysisDnCTurnoverList = [];
        var uwAnalysisProWorkSplitList = [];
        this.uwAnalysisList.forEach(uwA => {
            if (uwA.criteria == 'Territory') {
                uwAnalysisTerritoryList.push(uwA);
            } else if (uwA.criteria == 'D&C Turnover Split') {
                uwAnalysisDnCTurnoverList.push(uwA);
            } else {
                uwAnalysisProWorkSplitList.push(uwA);
            }
        });
        if (uwAnalysisDnCTurnoverList) {
            uwAnalysisDnCTurnoverList.forEach(item => {
                //console.log('item DnC', item);
                if (item.amount) totalDnCAmt = totalDnCAmt + parseFloat(item.amount);
                if (item.splitPercentage) totalDnCSplitPer = totalDnCSplitPer + parseFloat(item.splitPercentage);
                if (item.notonalIncome) totalNotional = totalNotional + parseFloat(item.notonalIncome);
            });
            //added by Jai
            if( totalDnCAmt ===  parseFloat(this._annualGrossFee) ){
                totalDnCSplitPer = 100.00;
            }
        }
        if (uwAnalysisTerritoryList) {
            uwAnalysisTerritoryList.forEach(item => {
                //console.log('item terr', item);
                if (item.splitPercentage) totalRiskPer = totalRiskPer + parseFloat(item.splitPercentage);
            });
        }
        if (uwAnalysisProWorkSplitList) {
            uwAnalysisProWorkSplitList.forEach(item => {
                //console.log('item pro', item);
                if (item.amount) totalProWorkSplitAmt = totalProWorkSplitAmt + parseFloat(item.amount);
                if (item.splitPercentage) totalProWorkSplitSplitPer = totalProWorkSplitSplitPer + parseFloat(item.splitPercentage);
            });
            //added by Jai
            if( totalProWorkSplitAmt ===  parseFloat(this._annualGrossFee) ){
                totalProWorkSplitSplitPer = 100.00;
            }
            
        }

        this.totalRiskPercent = totalRiskPer;
        this.totalDnCAmount = totalDnCAmt;
        this.totalDnCSplitPercent = totalDnCSplitPer;
        this.totalProWorkSplitAmount = totalProWorkSplitAmt.toFixed(2);
        this.totalProWorkSplitSplitPercent = totalProWorkSplitSplitPer;
       
        var formatter = new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'GBP',
            minimumFractionDigits: 2
          });   
          console.log('formatter---'+formatter); 
        
        this.totalRiskPercentDisplay = totalRiskPer.toFixed(2);
        this.totalDnCAmountDisplay = formatter.format(totalDnCAmt);
        this.totalDnCSplitPercentDisplay = totalDnCSplitPer.toFixed(2);
        this.totalProWorkSplitAmountDisplay = formatter.format(totalProWorkSplitAmt);
        this.totalProWorkSplitSplitPercentDisplay = totalProWorkSplitSplitPer.toFixed(2);
        this.totalNotionalIncomeDisplay = formatter.format(totalNotional);// Mary added 

        this.totalNotionalIncome = totalNotional.toFixed(2);
        console.log('totalNotional', this.totalNotionalIncome);
        if (this.sendNotionalEvent) {
            const sendTotalNotional = new CustomEvent("sendotalnotional", {
                detail: this.totalNotionalIncome
            });
            this.dispatchEvent(sendTotalNotional);
        }
        this.sendNotionalEvent = true;
    }
    @track totalProWorkSplitAmountDisplay;
    @track totalProWorkSplitSplitPercentDisplay;
    @track totalDnCAmountDisplay;
    @track totalDnCSplitPercentDisplay;
    @track totalRiskPercentDisplay;

    handleDelete(event) {
        var recordId = event.target.dataset.id;
        updateExistingReferredQuotes({ recordId: this._opportunityId })
        .then(result => {
            deleteRecord(recordId)
            .then(result => {
                this.removeDeleteRow(recordId);
                this.getTotals();
                this.showToast('Deleted', 'Record deleted', 'success');
            })
            .catch(error => {
                console.log('## Error in delete: ', error);
            })
        })
        .catch((error) => {
            var message = '';
            if (error.body.message.includes('ENTITY_IS_LOCKED')) {
                message = ERROR_CANNOT_UPDATE_SUBMISSION_HAS_LOCKED_QUOTE;
            }
            this.showToast('Error', message, "error");
        });
    }

    removeDeleteRow = (recordId) => {
        var uwList = [];
        var proWorkList = [];
        this.uwAnalysisProWorkSplitList.forEach(element => {
            if (element.identifier !== recordId) proWorkList.push(element);
        });
        this.uwAnalysisList.forEach(element => {
            if (element.identifier !== recordId) uwList.push(element);
        });
        this.uwAnalysisProWorkSplitList = proWorkList;
        this.uwAnalysisList = uwList;
    }

    handleAddNewRow(event) {
        updateExistingReferredQuotes({ recordId: this._opportunityId })
        .then(result => {
            this.addUWAnalysisModal = true;
            getUWAnalysisTemplates({ opportunityId: this._opportunityId })
            .then(uwTemplateList => {
                this.UWAnalysisTemplates = [];
                this.holdUWAnalysisTemplates = [];
                console.log('## uwTemplateList: ' + JSON.stringify(uwTemplateList));
                var tempList = [];
                uwTemplateList.forEach(uwTemplate => {
                    if(uwTemplate.Base_Rates__c){
                       uwTemplate.Base_Rates__c = uwTemplate.Base_Rates__c +'%';
                    }
                    if (this.uwAnalysisList.some(e => e.name === uwTemplate.UW_Analysis_Name__c)) {
                        console.log(' ## uwTemplate: ' + JSON.stringify(uwTemplate));
                    } else {
                        tempList.push(uwTemplate);
                    }
                });
                tempList.sort(function (a, b) {
                    if (a.UW_Analysis_Name__c < b.UW_Analysis_Name__c) { return -1; }
                    if (a.UW_Analysis_Name__c > b.UW_Analysis_Name__c) { return 1; }
                    return 0;
                });
                this.UWAnalysisTemplates = tempList;
                this.holdUWAnalysisTemplates = tempList;
                console.log('## tempList sort: ' + JSON.stringify(this.UWAnalysisTemplates));
            })
            .catch(error => {
                console.log('## error in adding new row: ' + JSON.stringify(error));
            })
        })
        .catch((error) => {
            var message = '';
            if (error.body.message.includes('ENTITY_IS_LOCKED')) {
                message = ERROR_CANNOT_UPDATE_SUBMISSION_HAS_LOCKED_QUOTE;
            }
            this.showToast('Error', message, "error");
        });
    }

    handleSearchTextChange(event) {
        this.searchTerm = event.target.value;
        if (this.searchTerm === '') {
            this.UWAnalysisTemplates = this.holdUWAnalysisTemplates;
        } else {
            var searchRows = [];
            this.holdUWAnalysisTemplates.forEach(element => {
                if (element.UW_Analysis_Name__c.toLowerCase().includes(this.searchTerm.toLowerCase())) {
                    searchRows.push(element);
                }
            });
            this.UWAnalysisTemplates = searchRows;
        }
    }

    selectRow(event) {
        if (event.target.checked) {
            this.selectedUWTemplate.push(event.target.value);
            if (this.selectedUWTemplate.length == this.UWAnalysisTemplates.length) {
                var selectAllChkBox = this.template.querySelector('.selectAllChkBox');
                selectAllChkBox.checked = event.target.checked;
            }
        }
        if (!event.target.checked) {
            var index = this.selectedUWTemplate.indexOf(event.target.value);
            if (index > -1) {
                this.selectedUWTemplate.splice(index, 1);
            }
            //this.selectedUWTemplate.pop(event.target.value);
            var selectAllChkBox = this.template.querySelector('.selectAllChkBox');
            selectAllChkBox.checked = event.target.checked;
        }
        console.log(' ## selectedUWTemplate 1: ' + JSON.stringify(this.selectedUWTemplate));
    }

    selectAllRow(event) {
        if (event.target.checked) {
            this.template.querySelectorAll('.chkBox').forEach(each => {
                each.checked = event.target.checked;
            })
            this.selectedUWTemplate = [];
            this.UWAnalysisTemplates.forEach(item => {
                this.selectedUWTemplate.push(item.Id);
            })
        } else {
            this.template.querySelectorAll('.chkBox').forEach(each => {
                each.checked = event.target.checked;
            })
            this.selectedUWTemplate = [];
        }
        console.log(' ## selectedUWTemplate 1: ' + JSON.stringify(this.selectedUWTemplate));
    }

    handleAddUWTemplates(event) {
        if (this.selectedUWTemplate.length > 0) {
            this.addUWAnalysisModal = !this.addUWAnalysisModal;
            createUWAnalysisByTemplate({ opportunityId: this._opportunityId, uwTemplateIds: this.selectedUWTemplate })
                .then(result => {
                    this.selectedUWTemplate = [];
                    this.uwAnalysisTerritoryList = [];
                    this.uwAnalysisDnCTurnoverList = [];
                    this.uwAnalysisProWorkSplitList = [];
                    this.uwAnalysisList = [];
                    this.getAllUWAnalysis();
                    this.showToast("Success", "Added successfully!", "success");
                })
                .catch(error => {
                    console.log('## error in creating UWAnalysis records: ' + JSON.stringify(error));
                })
        } else {
            this.showToast("Select Work Type", "Please select at least one work type", "error");
        }
    }

    handleOnChange(event) {
        if (!this._annualGrossFee) {
            setTimeout(() => { this.showToast("Annual gross fees/turnover required", "Please fill Annual gross fees/turnover to proceed", "warning"); }, 400);
            //return;
        }
        var inputName = event.target.name;
        var name = inputName.split('_')[0];
        var field = inputName.split('_')[1];
        console.log({ field, name, inputName });

        if (field == 'amount') {
            console.log({ field });
            this.template.querySelectorAll('.' + name + '_amount').forEach(each => {
                var newAmount = each.value;
                //Annual gross fees / turnover' / Income
                var newSplitPercentage = ((newAmount / this._annualGrossFee) * 100).toFixed(2);
                console.log('._amount newSplitPercentage', newSplitPercentage);
                this.uwAnalysisList.forEach(item => {
                    if (item.identifier === name) {
                        item.amount = parseFloat(newAmount);
                        item.splitPercentage = parseFloat(newSplitPercentage);
                        if (item.criteria == 'D&C Turnover Split') {
                            if (item.amount) {
                                console.log('._amount notonalIncome', (item.amount));
                                //if(item.amount) console.log('it works the amount thingy');
                                var calNotionalIncome = ((item.amount * item.ratingFactor) / 100);
                                item.notonalIncome = Number(calNotionalIncome).toFixed(2);
                            } else {
                                item.notonalIncome = 0.00;
                            }
                        }
                    }
                })
            });
            //this.handleAnnualAmountChange();  **Commented -- Amount change wasn't reflecting in split % **
            this.sendEventToAllowSaveFromParent();
        } else {
            this.template.querySelectorAll('.' + name + '_split').forEach(each => {
                var newSplitPercentage = each.value
                //Annual gross fees / turnover * Split %
                var newAmount = ((this._annualGrossFee * newSplitPercentage) / 100).toFixed(2);

                console.log('._split newAmount', newAmount);
                this.uwAnalysisList.forEach(item => {
                    if (item.identifier === name) {
                        item.splitPercentage = parseFloat(newSplitPercentage);
                        item.amount = parseFloat(newAmount);
                        if (item.criteria == 'D&C Turnover Split') {
                            if (item.amount) {
                                console.log('._amount notonalIncome', (item.amount));
                                //if(item.amount) console.log('it works the amount thingy');
                                var calNotionalIncome = ((item.amount * item.ratingFactor) / 100);
                                item.notonalIncome = Number(calNotionalIncome).toFixed(2);
                            } else {
                                item.notonalIncome = 0.00;
                            }
                        }
                    }
                })
            });           
            //this.handleAnnualAmountChange(); 
            this.sendEventToAllowSaveFromParent();
        }

        this.getTotals();
        //console.log('## uwAnalysisListJSON NEW' + JSON.stringify(this.uwAnalysisList));
    }

    @api validateToSave() {
        var validateSuccess = false;
        if (!this._annualGrossFee) {
            console.log('Enter Annual Gross Fee - ', this._annualGrossFee);
            this.showToast("Error", "Enter Annual Gross Fee", "error");
            return validateSuccess;
        }
        var totalAmount = this._annualGrossFee;

        if (parseFloat(this.totalRiskPercent).toFixed(2) != 100 ||  parseFloat(this.totalProWorkSplitSplitPercent).toFixed(2) != 100) {
            console.log('Percent not correct');
            this.showToast("Error", "Total % under Splits Table section must add up to 100%", "error");
            return validateSuccess;
        }
        console.log('this.totalDnCSplitPercent', this.totalDnCSplitPercent);
        console.log('this.totalDnCSplitPercentParse', parseFloat(this.totalDnCSplitPercent).toFixed(2));
        console.log('this.totalDnCAmount', this.totalDnCAmount);
        if (this.mainProfession == 'Design & Construct') {
            if (parseFloat(this.totalDnCSplitPercent).toFixed(2) != 100) {
                console.log('Percent not correct');
                this.showToast("Error", "Total % under Splits Table section must add up to 100%", "error");
                return validateSuccess;
            }
        }
        if (parseFloat(this.totalProWorkSplitAmount ).toFixed(2) != parseFloat(totalAmount).toFixed(2)) {
            console.log('Amount not correct -- ',parseFloat(this.totalProWorkSplitAmount).toFixed(2), ' totalAmount -- ', parseFloat(totalAmount).toFixed(2));
            this.showToast("Error", "Amount should add up to Annual Gross Fee", "error");
            return validateSuccess;
        }
        console.log('totalDnCAmount -- ', parseFloat(this.totalDnCAmount).toFixed(2), ' totalAmount -- ', totalAmount);
        if (this.mainProfession == 'Design & Construct') {
            if (parseFloat(this.totalDnCAmount ).toFixed(2)!=  parseFloat(totalAmount).toFixed(2)) {
                console.log('Amount not correct');
                this.showToast("Error", "Amount should add up to Annual Gross Fee", "error");
                return validateSuccess;
            }
        }
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        if (isInputsCorrect) {
            validateSuccess = true;
            // const saveuwrecord = new CustomEvent("saveuwrecord", { uwAnalysisJson: JSON.stringify(this.uwAnalysisList), opportunityId: this._opportunityId });
            // console.log('## save VALIDATE: ' + JSON.stringify(this.uwAnalysisList));
            // this.dispatchEvent(saveuwrecord);
            return validateSuccess;
        } else {
            return validateSuccess;
        }
    }

    handleSaveTableData = () => {
        //var isSuccess = this.validateToSave();
        //console.log({ isSuccess });
        //if (isSuccess) {
        updateExistingReferredQuotes({ recordId: this._opportunityId })
        .then(result => {
            saveUWAnalysis({ uwAnalysisJson: JSON.stringify(this.uwAnalysisList), opportunityId: this._opportunityId })
            .then(result => {
                console.log('## save: ' + JSON.stringify(this.uwAnalysisList));
                this.showToast("Success", "Splits Table Saved", "success");
            })
            .catch(error => {
                console.log('## error while save: ' + JSON.stringify(error));
            })
        })
        .catch((error) => {
            var message = '';
            if (error.body.message.includes('ENTITY_IS_LOCKED')) {
                message = ERROR_CANNOT_UPDATE_SUBMISSION_HAS_LOCKED_QUOTE;
            }
            this.showToast('Error', message, "error");
        });
        // }
    }

    @api handleSaveTableDataFromParent() {
        saveUWAnalysis({ uwAnalysisJson: JSON.stringify(this.uwAnalysisList), opportunityId: this._opportunityId })
            .then(result => {
                console.log('## save From PARENT: ' + JSON.stringify(this.uwAnalysisList));
                return JSON.stringify(this.uwAnalysisList);
            })
            .catch(error => {
                console.log('## error while save From PARENT: ' + JSON.stringify(error));
            })
    }

    closeModal() {
        this.selectedUWTemplate = [];
        this.searchTerm = '';
        this.addUWAnalysisModal = !this.addUWAnalysisModal;
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