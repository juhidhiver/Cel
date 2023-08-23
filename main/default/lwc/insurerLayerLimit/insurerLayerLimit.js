import { LightningElement, track,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getInsurerLayer from '@salesforce/apex/InsurerLayerLimitController.getInsurerLayer';
import saveInsurerLayer from '@salesforce/apex/InsurerLayerLimitController.saveInsurerLayer';
import deleteInsurer from '@salesforce/apex/InsurerLayerLimitController.deleteInsurer';
import fetchInsurerLimit from '@salesforce/apex/InsurerLayerLimitController.fetchInsurerLimit';


export default class InsurerLayerLimit extends LightningElement {

    @api quoteName;
    @api quoteId;
    @track rowList = []; 
    @track isLoading = false;
    @api nonEditable;


    rowvalue = {
        Layer__c: "",
        Quote__c: "",
        Insurer__c: "",
        Insurer_Layer_Limit__c: "",
        Insurer_Policy_Number__c: ""
    }
    
    connectedCallback(){
    this.getInsurerLayer();
    this.fetchInsurerLimit();
    }

    getInsurerLayer(){
        getInsurerLayer({ quoteId : this.quoteId})
        .then((result) =>{
        this.rowList = result;
          console.log('Quote: ' + JSON.stringify(this.quoteId));
          console.log('Value: ' + JSON.stringify(this.rowList));
        })
        .catch((error) => {
            console.log('error: ' + JSON.stringify(error));
        })
    }

    handleAddLayer(){
        var i;
        if(this.rowList.length > 0){
            i = this.rowList.length;
            this.rowvalue.Layer__c = 'Excess Layer Insurer - '+i;
            this.rowvalue.Quote__c = this.quoteId;
            this.rowList.push(JSON.parse(JSON.stringify(this.rowvalue)));
        }else{
            this.showToast('Error', 'Missing Primary Insurer', "error");
        }
           
        console.log('rowList ',JSON.stringify(this.rowList));
        
    }
    @track deleteId;
    removeRow(event){
        if(this.nonEditable){           
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'You cannot Delete Record for this Quote Status.',
                    variant: 'error'
                })
            );
            return;
        }
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id;
        
        if(this.rowList[key].Layer__c != 'Primary Insurer'){
            console.log('List 1-->'+JSON.stringify(this.rowList[key]));
            if(this.rowList[key].Id != '' && this.rowList[key].Id != null){
                console.log('List 2-->'+JSON.stringify(this.rowList[key]));
                this.deleteId = this.rowList[key].Id;
                this.deleteInsurer();
            }
            this.rowList.splice(key, 1);
           this.rowList = JSON.parse(JSON.stringify(this.rowList));
           }
        else{
            this.showToast('Error', 'Primary Insurer is Mandatory', "error");
            return;
        }
       
        this.rowList.forEach(function(element,index){
            if(index>0) {
            element.Layer__c = index +'st Excess Layer Insurer';
            }
        })
    } 

    deleteInsurer(){
        this.isLoading = true;
       deleteInsurer({ insurerId : this.deleteId})
       .then((result) =>{
           this.fetchInsurerLimit();
           this.deleteId = '';
           this.showToast('Success', 'Data Deleted Successfully', "success");
           this.isLoading = false;
           console.log('deleted');
       })
       .catch((error) => {
           this.showToast('Error', 'Error deleting Data', "error");
           console.log('error: ' + JSON.stringify(error));
       })
    }

    handleInsurerChange(event) {
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id;
        this.rowList[key].Insurer__c = event.target.value;
    }
    
    handlePolicyNumberChange(event) {
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id;
        this.rowList[key].Insurer_Policy_Number__c = event.target.value;
    }
    
    handleInsurerLayerLimit(event) {
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id;
        this.rowList[key].Insurer_Layer_Limit__c = event.target.value;
    }

    handleSaveLayer(){
        console.log('On Save');
        var isError = false;
        var isDataLarge = false;
        let totalInsurerLayerLimit = 0;

        if(!this.rowList.length > 0){
            this.showToast('Error', 'No Data to Save!', "Error");
            return;
        }
        this.rowList.forEach(element => {
            if(element.Insurer_Layer_Limit__c == '' || element.Insurer_Layer_Limit__c == null){
               isError = true;
            }else{
                //let convertedValue = Number.parseFloat(element.Insurer_Layer_Limit__c) / currencyMap[element.CurrencyIsoCode];
                totalInsurerLayerLimit = totalInsurerLayerLimit + Number.parseFloat(element.Insurer_Layer_Limit__c) ;
            }
        });
        if(isError){
            this.showToast('Error', 'Insurer Layer Limit is Mandatory!', "Error");
            return;
        }
        //Adding Validation if Total Underlying Value is less than 2 million post currency conversion
        if(totalInsurerLayerLimit < 2000000){
            this.showToast('Error', 'Total Underlying Value cannot be less than 2 Million', "Error");
            return;
        }

        this.rowList = JSON.parse(JSON.stringify(this.rowList));

        this.rowList.forEach(element => {
            console.log('Policy: ' + JSON.stringify(element.Insurer_Policy_Number__c));
            if(element.Insurer_Policy_Number__c != undefined && element.Insurer_Policy_Number__c != ''){
                if(element.Insurer_Policy_Number__c.length > 50){
                    isDataLarge = true;
                }
            }
        });
      if(isDataLarge){
        this.showToast('Error', 'Insurer Policy Number: Data value too large', "Error");
        return;
      }
        this.isLoading = true;
        this.rowList = JSON.parse(JSON.stringify(this.rowList));
        saveInsurerLayer({ insurerList : this.rowList})
        .then((result) =>{
            this.fetchInsurerLimit();
            this.getInsurerLayer();
            this.showToast('Success', 'Data Saved Successfully!', "Success");
            this.isLoading = false;
        })
        .catch((error) => {
            if(error.body.pageErrors[0].statusCode == 'FIELD_CUSTOM_VALIDATION_EXCEPTION'){
                var errMsg = '';
                if(error.body.pageErrors[0].message == "This Quote is locked for editing when status is 'Quoted' or 'Presented' or 'Bound'"){
                    errMsg = "This Quote is locked for editing when status is or 'Bound'"
                }else{
                    errMsg = error.body.pageErrors[0].message;
                }
                this.showToast('Error', errMsg, "error");                
            }else if(error.body.pageErrors[0].statusCode.includes('ENTITY_IS_LOCKED')){
                errMsg = 'This record is locked. If you need to edit it, contact your admin';
                this.showToast('Error', errMsg, "error");  
            }else{
                this.showToast('Error', 'Error Saving Data', "error");
            }            
            this.isLoading = false;
            console.log('error: ' + JSON.stringify(error));
        })
    }

    @track totalUnderlying;
    fetchInsurerLimit(){
        fetchInsurerLimit({ quoteId: this.quoteId })
        .then((result) =>{
          if (result) {
            this.totalUnderlying = result;
          }
        })
        .catch((error) => {
            console.log(" UnderlyingTotal Error:" + JSON.stringify(error));
        })  

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