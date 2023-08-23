import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import fetchRecords from '@salesforce/apex/customSingleRelListCtrl.fetchRecords';
import getDocRevisionRecord from '@salesforce/apex/customSingleRelListCtrl.getDocRevisionRecord';

export default class CustomSingleRelatedList extends NavigationMixin(LightningElement) {

    @api showButton = false;
    @api disableButton = false;
    @api buttonLabel;
    @api recordId;
    @api objectAPIName;
    @api relationshipFieldAPIName;
    @api cardTitle;
    @api iconName;
    @api childRelationshipName;
    @api fieldConfigDetails;
    @api relatedListSoqlWhereCondition = '';
    @track returnedRecords = [];
    @track returnedRecordsFull = [];
    @track returnedRecordsSplitted = [];
    @track titleWithCount;
    @track showBody = false;
    @track showFooter = false;
    @track footerName = 'View More';
    @track recordCount;
    @track wiredata;
    @track alreadyAddedIndex = [];

    @wire(fetchRecords, { recordId: '$recordId',
                          objectName: '$objectAPIName',
                          fieldConfigDetails: '$fieldConfigDetails',
                          relationshipFieldName: '$relationshipFieldAPIName',
                          soqlAdditionalWhereCondition: '$relatedListSoqlWhereCondition'
                        }) 
    accountData( result ) {
        this.wiredata = result;
        var data = result.data;
        var error = result.error;
        if ( data ) {
            console.log('$$response=', data);
            if ( data.recordCount ) {
                this.showBody = true;
                this.recordCount = data.recordCount;
                if ( data.recordCount > 3 ) {
                    this.returnedRecordsFull = data.numberOfRecords;
                    this.showFooter = true;
                    this.titleWithCount = this.cardTitle + ' (3+)';
                    data.numberOfRecords.forEach((rec, index) => {
                     
                        let returnedRecord = Object.assign({},rec);
                        if(index <= 2 && ((this.alreadyAddedIndex==null && this.alreadyAddedIndex.length==0) 
                                || !this.alreadyAddedIndex.includes(index))){
                            this.alreadyAddedIndex.push(index);
                            this.returnedRecords.push(rec);
                        }
                    });
                    this.returnedRecordsSplitted = this.returnedRecords;
                }
                else{
                    this.titleWithCount = this.cardTitle + ' (' + data.recordCount + ')';
                    this.returnedRecords = data.numberOfRecords;
                }
            }
            else{
                this.titleWithCount = this.cardTitle + ' (0)';
            }
        }
       console.log('returnedRecords'+JSON.stringify(this.returnedRecords))
    }

    renderedCallback(){
        this.handleRefreshRelatedList();
    }

    navigateToRelatedList(){
        /*this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                relationshipApiName: this.childRelationshipName,
                actionName: 'view'
            },
        });*/
    }

    handleNavigation(event){
        var recordId = event.target.dataset.id;
        //console.log('$$$$test1',event.target.dataset.id);
        if(this.objectAPIName == 'Quote'){
            //var quoteId = event.target.dataset.id;
            /*this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: event.currentTarget.dataset.value,
                    actionName: 'view'
                },
            });*/
            let refreshQuote = new CustomEvent('refreshquotedetail', {  bubbles: true, composed: true, detail: { quoteId: recordId } });
            this.dispatchEvent(refreshQuote);
        }
        else if(this.objectAPIName =='Opportunity'){
            console.log('Opportnity')
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    objectApiName: 'Opportunity',
                    actionName: 'view'
                },
            }).then(url => {
                window.open(url, "_blank");
            });
        }
        else if(this.objectAPIName == 'Document_Revision__c'){
            //var selectedDocumentId = event.target.dataset.id;
            //console.log('$$$$test2',event.target.dataset.id);
            getDocRevisionRecord({ documentId: recordId })
            .then(result => {
                var docRevisionName = result.Name;
                var policyWordingDocUrl = result.Policy_Wording_Link__c;
                if(docRevisionName.startsWith("Policy Wording")){
                    if(policyWordingDocUrl){
                        this[NavigationMixin.Navigate]({
                            type: 'standard__webPage',
                            attributes: {
                                url: policyWordingDocUrl
                            }
                        });
                    }
                }
                else{
                    //var documentId = event.target.dataset.id;
                    let viewdocument = new CustomEvent('viewdocumentevt', { detail: { documentId: recordId } });
                    this.dispatchEvent(viewdocument);
                }

            });
        }
    }

    showOrHideRecords(){
        if(this.footerName == 'View More'){
            this.footerName = 'View Less';
            this.returnedRecords = this.returnedRecordsFull;
            this.titleWithCount = this.cardTitle + ' (' + this.recordCount + ')';
        }
        else{
            this.footerName = 'View More';
            this.returnedRecords = this.returnedRecordsSplitted;
            this.titleWithCount = this.cardTitle + ' (3+)';
        }
    }

    @api
    handleRefreshRelatedList(){
        refreshApex(this.wiredata);
        console.log('this.wiredata'+this.wiredata);
    }

    handleButtonClick() {
        if(this.buttonLabel == 'New Primary Quote'){
            const quoteCreationEvt = new CustomEvent(
                "quotecreation",
                {
                    detail: { layerName: 'Primary' }, bubbles: true, composed: true
                }
            );
            this.dispatchEvent(quoteCreationEvt);
        }
        else if(this.buttonLabel == 'New Excess Quote'){
            const quoteCreationEvt = new CustomEvent(
                "quotecreation",
                {
                    detail: { layerName: 'Excess' }, bubbles: true, composed: true
                }
            );
            this.dispatchEvent(quoteCreationEvt);
        }
        else if(this.buttonLabel == 'Generate Document'){
            let generatedocument = new CustomEvent('generatedocumentevt', { detail: 'Generate Document' });
            this.dispatchEvent(generatedocument);
        }
    }

}