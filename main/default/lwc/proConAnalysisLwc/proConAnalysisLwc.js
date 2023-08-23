import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCategories from '@salesforce/apex/ProConAnalysisLwcController.getCategories'
import getProsConsList from '@salesforce/apex/ProConAnalysisLwcController.getProsConsList'
import searchRatingModifier from '@salesforce/apex/ProConAnalysisLwcController.searchRatingModifier'
import saveRatingModifier from '@salesforce/apex/ProConAnalysisLwcController.saveRatingModifier'
import clearRatingModifier from '@salesforce/apex/ProConAnalysisLwcController.clearRatingModifier'
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/Opportunity.Id';
import PROS_FIELD from '@salesforce/schema/Opportunity.Pros__c';
import CONS_FIELD from '@salesforce/schema/Opportunity.Cons__c';
const FIELDS = ['Opportunity.Pros__c', 'Opportunity.Cons__c'];
export default class ProConAnalysisLwc extends LightningElement {
    @api opportunityId;
    @api disableProsAndCons;
    @track ratingModifierCategories = [];
    @track categoryValues = [];
    @track resultedRatingModifier = [];
    @track searchColumns = [
        { label: 'Category', fieldName: 'Sub_Section__c' },
        { label: 'Analysis Factor', fieldName: 'Name' }
    ]
    @track selectedRatingModifier = [];
    @track prosRatingModifiers = [];
    @track consRatingModifiers = [];

    @track prosRatModOnClick = [];
    @track consRatModOnClick = [];

    //list that save the id of added rating modifier
    listAddedRatingModifier = [];

    @track pros;
    @track cons;
    @track result;
    @track isCustomProsConsUpdate = false;
    @track isProsConsUpdate = false;

    connectedCallback() {
        getCategories({ opportunityId: this.opportunityId })
            .then(results => {
                var options = [];
                results.forEach(result => {
                    let option = { label: result, value: result };
                    options.push(option);
                });
                this.ratingModifierCategories = options;
            })

        getProsConsList({ opportunityId: this.opportunityId })
            .then(results => {
                var prosRatingModifiersTemp = [];
                var consRatingModifiersTemp = [];
                results.forEach(rating => {
                    if (rating.Rating_Modifier_Value__c == 'Pro') {
                        var prosRatingModifiersLenght = this.prosRatingModifiers.length;
                        prosRatingModifiersTemp.push({ id: rating.Id, label: rating.Name, value: rating.Id, selected: false, order: prosRatingModifiersLenght });
                    } else if (rating.Rating_Modifier_Value__c == 'Con') {
                        var consRatingModifiersLenght = this.consRatingModifiers.length;
                        consRatingModifiersTemp.push({ id: rating.Id, label: rating.Name, value: rating.Id, selected: false, order: consRatingModifiersLenght });
                    }
                })
                this.prosRatingModifiers = prosRatingModifiersTemp;
                this.consRatingModifiers = consRatingModifiersTemp;
            })
    }

    handleChange(event) {
        let prosConsCombobox = this.template.querySelector('[data-id="prosConsCmb"]');
        console.log("@@@prosConsCombobox: " + JSON.stringify(prosConsCombobox));
        prosConsCombobox.value = null;
        let value = event.detail.value;
        if (!this.categoryValues.includes(value))
            this.categoryValues.push(value);
        searchRatingModifier({
            opportunityId: this.opportunityId, searchCategories: this.categoryValues,
            listAddedRatingModifier: this.listAddedRatingModifier
        })
            .then(result => {
                this.resultedRatingModifier = JSON.parse(JSON.stringify(result));
            }
            );
    }

    handleRemoveSearchOption(event) {
        let prosConsCombobox = this.template.querySelector('[data-id="prosConsCmb"]');
        prosConsCombobox.value = null;
        let item = event.detail.name;
        this.categoryValues = this.categoryValues.filter(value => value != item);
        searchRatingModifier({
            opportunityId: this.opportunityId, searchCategories: this.categoryValues,
            listAddedRatingModifier: this.listAddedRatingModifier
        })
            .then(result => {
                this.resultedRatingModifier = JSON.parse(JSON.stringify(result));
            }
            );
    }

    getSelectedRatingModifier(event) {
        this.selectedRatingModifier = event.detail.selectedRows;
    }

    handleAddPros(event) {
        var prosRatingModifiersTmp = [];
        if (this.prosRatingModifiers.length > 0) {
            this.prosRatingModifiers.forEach(element => {
                prosRatingModifiersTmp.push(element);
            });
        }
        this.selectedRatingModifier.forEach(rating => {
            var prosRatingModifiersLenght = this.prosRatingModifiers.length;
            prosRatingModifiersTmp.push({ id: rating.Id, label: rating.Name, value: rating.Id, selected: false, order: prosRatingModifiersLenght });
            let temp = JSON.parse(JSON.stringify(this.resultedRatingModifier));
            temp = temp.filter(item => item.Id != rating.Id);
            this.resultedRatingModifier = temp;
            //check if not existed in list and add it
            if (!this.listAddedRatingModifier.includes(rating.Id))
                this.listAddedRatingModifier.push(rating.Id);
        })
        this.prosRatingModifiers = prosRatingModifiersTmp;
        this.selectedRatingModifier = [];
        this.isProsConsUpdate = true;
    }

    handleAddCons(event) {
        var consRatingModifiersTmp = [];
        if (this.consRatingModifiers.length > 0) {
            this.consRatingModifiers.forEach(element => {
                consRatingModifiersTmp.push(element);
            });
        }
        this.selectedRatingModifier.forEach(rating => {
            var consRatingModifiersLenght = this.consRatingModifiers.length;
            //this.prosRatingModifiers.push({label: rating.Name, value: rating.Id, id : rating.Id, selected : false , order : prosRatingModifiersLenght});
            consRatingModifiersTmp.push({ id: rating.Id, label: rating.Name, value: rating.Id, selected: false, order: consRatingModifiersLenght });
            let temp = JSON.parse(JSON.stringify(this.resultedRatingModifier));
            temp = temp.filter(item => item.Id != rating.Id);
            this.resultedRatingModifier = temp;
            //check if not existed in list and add it
            if (!this.listAddedRatingModifier.includes(rating.Id))
                this.listAddedRatingModifier.push(rating.Id);
        })
        this.selectedRatingModifier = [];
        this.consRatingModifiers = consRatingModifiersTmp;
        this.isProsConsUpdate = true;
    }

    handleChangeProsCons(event) {
        let temp = JSON.parse(JSON.stringify(event.detail.value));
        this.consRatingModifiers = temp;
    }
    handleClick(event) {
        this.template.querySelectorAll("lightning-dual-listbox").forEach(element => {
        });
    }
    renderedCallback() {
        console.log('@@@click element 55: ' + this.template.querySelector('.test1').innerHTML);
    }

    handleClearRatingModifier(event) {
        let ratModIds = [];
        this.prosRatingModifiers.forEach(rating => {
            ratModIds.push(rating.value);
        })
        this.consRatingModifiers.forEach(rating => {
            ratModIds.push(rating.value);
        })

        clearRatingModifier({ ratingModifierIds: ratModIds }).then(result => {
            if (result === 'success') {
                this.resultedRatingModifier = [];
                this.categoryValues = [];
                this.prosRatingModifiers = [];
                this.consRatingModifiers = [];
                //clear list added rating modifier
                this.listAddedRatingModifier = [];
                this.isProsConsUpdate = false;
                const evt = new ShowToastEvent({
                    title: 'Rating Modifiers Cleared',
                    message: 'All rating modifiers have been cleared!',
                    variant: 'success',
                });
                this.dispatchEvent(evt);
            } else {
                const evt = new ShowToastEvent({
                    title: 'Update Error',
                    message: result,
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            }
        });
    }

    handleRemoveRatingModifier(event) {
        let ratModIds = [];
        var prosRatModToRemove = [];
        var consRatModToRemove = [];
        this.prosRatModOnClick.forEach(rating => {
            ratModIds.push(rating.id);
            this.prosRatingModifiers.forEach(element => {
                if (rating.id === element.id) {
                    prosRatModToRemove.push(element);
                }
            });
        })
        this.consRatModOnClick.forEach(rating => {
            ratModIds.push(rating.id);
            this.consRatingModifiers.forEach(element => {
                if (rating.id === element.id) {
                    consRatModToRemove.push(element);
                }
            });
        })
        clearRatingModifier({ ratingModifierIds: ratModIds }).then(result => {
            if (result === 'success') {
                this.resultedRatingModifier = [];
                this.categoryValues = [];
                this.prosRatingModifiers = this.prosRatingModifiers.filter(item => prosRatModToRemove.indexOf(item) === -1);
                this.consRatingModifiers = this.consRatingModifiers.filter(item => !consRatModToRemove.includes(item));
                // reorder list
                this.renumberItems(this.prosRatingModifiers);
                this.sortItems(this.prosRatingModifiers);
                this.renumberItems(this.consRatingModifiers);
                this.sortItems(this.consRatingModifiers);
                //clear list added rating modifier
                this.listAddedRatingModifier = [];
                const evt = new ShowToastEvent({
                    title: 'Remove Successful',
                    message: 'Selected item has been removed!',
                    variant: 'success',
                });
                this.dispatchEvent(evt);
            } else {
                const evt = new ShowToastEvent({
                    title: 'Update Error',
                    message: result,
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            }
        });
    }

    handleSaveRatingModifier(event) {
        if (this.isCustomProsConsUpdate) {
            this.handleSaveProsAndCons();
            this.isCustomProsConsUpdate = false;
        }

        if (this.isProsConsUpdate) {
            let prosId = [];
            let consId = [];
            this.consRatingModifiers.forEach(element => {
                consId.push(element.id);
            });
            this.prosRatingModifiers.forEach(element => {
                prosId.push(element.id);
            });
            saveRatingModifier({ prosId: prosId, consId: consId }).then(result => {
                if (result === 'success') {
                    console.log('@@@save success');
                    const evt = new ShowToastEvent({
                        title: 'Update Success',
                        message: 'The rating modifiers have been updated',
                        variant: 'success',
                    });
                    this.dispatchEvent(evt);
                } else {
                    console.log('@@@error');
                    const evt = new ShowToastEvent({
                        title: 'Update Error',
                        message: result,
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                }
            });
            this.isProsConsUpdate = false;
        }
    }

    handleChangeValueEvent(event) {
        this.prosRatingModifiers = event.detail.leftValues;
        this.consRatingModifiers = event.detail.rightValues;
        this.isProsConsUpdate = true;
    }

    handleClickRatMods(event) {
        // on click pros rating Modifier
        this.prosRatModOnClick = event.detail.onClickItemListLeft;
        // on click cons rating Modifier
        this.consRatModOnClick = event.detail.onClickItemListRight;
        console.log('@@@prosRatModOnClick 1: ' + JSON.stringify(this.prosRatModOnClick));
        console.log('@@@consRatModOnClick 1: ' + JSON.stringify(this.consRatModOnClick));
    }

    sortItems(items) {
        if (items && items.length > 0) {
            items.sort(function (a, b) {
                return a.order > b.order ? 1 : -1;
            });
        }
        return items;
    }

    renumberItems(items) {
        if (items && items.length > 0) {
            items = this.sortItems(items);
            items.forEach(function (item, index) {
                item.order = index;
            });
        }
        return items;
    }
    @wire(getRecord, { recordId: '$opportunityId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (error) {
            console.log('From error:');
            console.log(error);
        }
        else if (data) {
            console.log('Values from Pros and Cons:', JSON.stringify(data));
            this.result = data;
            this.pros = this.result.fields.Pros__c.value;
            this.cons = this.result.fields.Cons__c.value;
        }
    }
    handleProsandConsChange(event) {
        const targetName = event.target.name;
        if (targetName === 'pros') {
            this.pros = event.target.value;
        }
        else if (targetName === 'cons') {
            this.cons = event.target.value;
        }
        this.isCustomProsConsUpdate = true;
    }
    handleSaveProsAndCons() {
        const fields = {};
        fields[PROS_FIELD.fieldApiName] = this.pros;
        fields[CONS_FIELD.fieldApiName] = this.cons;
        fields[ID_FIELD.fieldApiName] = this.opportunityId;
        const recordInput = { fields };
        updateRecord(recordInput)
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Custom Pros and Cons updated',
                    variant: 'success'
                })
            );
            // Display fresh data in the form
            //return refreshApex(this.wiredRecord);
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creating Custom Pros and Cons',
                    message: error,
                    variant: 'error'
                })
            );
        });
    }
}