import { LightningElement, wire, api, track } from 'lwc';
import getMainSectionFromProductLwc from '@salesforce/apex/OpportunityModifiersCmpController.getMainSectionFromProductLwc';
import saveRecordTabLwc from '@salesforce/apex/OpportunityModifiersCmpController.saveRecordTabLwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class OpportunityModifiersTabLwc extends LightningElement {

    @api productName;// = 'MPL';
    @api opportunityId;// = '0062500000H5UVJAA3';
    @api mainSectionWraps = [];
    @api mainActiveSections = [];
    @track isOpenModal = false;

    @wire(getMainSectionFromProductLwc, { productName : '$productName', opportunityId : '$opportunityId'})
	getMainSectionFromProduct({error, data}){
       if(data){
            this.mainSectionWraps = data.data;
            this.mainActiveSections = data.data.mainActiveSections;
            var tmp = JSON.parse(JSON.stringify(data.data));
            var mainSecWrap = tmp.mainSections;
            for(var i = 0; i < mainSecWrap.length;i++ ) {
                var obj = JSON.parse(JSON.stringify(mainSecWrap[i].items));
                for(var j = 0; j < obj.length;j++ ) {
                    console.log('Format 1:' + obj[j].item.Format__c);
                    switch(obj[j].item.Format__c) {
                        case 'Picklist' : {
                            obj[j].item.isPicklist = true;
                            break;
                        }
                        case 'Radio Button' : {
                            obj[j].item.isRadioButton = true;
                            break;
                        }
                        case 'Currency' : {
                            obj[j].item.isCurrency = true;
                            break;
                        }
                        case 'Picklist' : {
                            obj[j].item.isPercentage = true;
                            break;
                        }
                        case 'Picklist' : {
                            obj[j].item.isInteger = true;
                        }
                        case 'Picklist' : {
                            obj[j].item.isNumber = true;
                            break;
                        }
                        case 'Text' : {
                            obj[j].item.isText = true;
                            break;
                        }

                    }
                    
                }
                mainSecWrap[i].items = obj;
                var subSecWrap = mainSecWrap[i].subSections;
                for(var j = 0; j < subSecWrap.length;j++ ) {
                    var subObj = JSON.parse(JSON.stringify(subSecWrap[j].items));
                    for(var k = 0; k < subObj.length;k++ ) {
                        switch(subObj[k].item.Format__c) {
                            case 'Picklist' : {
                                subObj[k].item.isPicklist = true;
                                break;
                            }
                            case 'Radio Button' : {
                                subObj[k].item.isRadioButton = true;
                                break;
                            }
                            case 'Currency' : {
                                subObj[k].item.isCurrency = true;
                                break;
                            }
                            case 'Picklist' : {
                                subObj[k].item.isPercentage = true;
                                break;
                            }
                            case 'Picklist' : {
                                subObj[k].item.isInteger = true;
                                break;
                            }
                            case 'Picklist' : {
                                subObj[k].item.isNumber = true;
                                break;
                            }
                            case 'Text' : {
                                subObj[k].item.isText = true;
                                break;
                            }
                        }
                    }
                    subSecWrap[j].items = subObj;               
                }
                
            }
            this.mainSectionWraps = tmp;
            // console.log('Final result:' + JSON.stringify(this.mainSectionWraps));
            /*
            tmp.mainSections.forEach(function(mainSecWrap) {
                mainSecWrap.forEach(function(obj) {
                    console.log('Format:' + obj.item.Format__c);
                });
                
            });*/
            //console.log('mainSectionWraps mainSectionWraps.mainSections:' + JSON.stringify(this.mainSectionWraps));
       }
       else if(error){
		  console.log('##error :' + JSON.stringify(error));
       }
    };
    handleChangeMain (event){
        var valueChange = event.target.value;
        var mainSectionWrs = JSON.parse(JSON.stringify(this.mainSectionWraps.mainSections)); 
       
        mainSectionWrs.forEach(mainSecWrap => {
            mainSecWrap.items.forEach(obj => {
                if(obj.item.Id === event.target.name){
                    obj.item.Rating_Modifier_Value__c = event.target.value;
                }
            });
        });
        
        this.mainSectionWraps.mainSections = mainSectionWrs;
        this.mainSectionWraps.mainSections.forEach(mainSecWrap => {
            mainSecWrap.items.forEach(obj => {
                // console.log("@@@obj: " + JSON.stringify(obj.Rating_Modifier_Value__c));
            });
            
        });
        
    }

    handleChangeChild (event){
        var valueChange = event.target.value;
        var mainSectionWr = JSON.parse(JSON.stringify(this.mainSectionWraps)); 

        mainSectionWr.mainSections.forEach(mainSecWrap => {
            mainSecWrap.subSections.forEach(subSec => {
                subSec.items.forEach(obj => {
                    if(obj.item.Id === event.target.name){
                        obj.item.Rating_Modifier_Value__c = event.target.value;
                    }
                })
            });
        });    
        this.mainSectionWraps = mainSectionWr;
    }

    saveRecord(){
        var mainSectionWr = this.mainSectionWraps; 
        saveRecordTabLwc({
            jsonTabWrap: JSON.stringify(mainSectionWr.mainSections),
            opportunityId: this.opportunityId
        })
        .then(() => {
            this.showToast("Success","Update records successfully!", "success");
            //return refreshApex(this.opptiesOverAmount);
        })
        .catch((error) => {
            var message = 'Error received: code' + error.errorCode + ', ' +
                'message ' + error.body.message;
            this.showToast("Error", message, "error");
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

    clickCheckRiskHealth(){
        // console.log("@@@open modal");
        //this.isOpenModal = !this.isOpenModal;
    }
}