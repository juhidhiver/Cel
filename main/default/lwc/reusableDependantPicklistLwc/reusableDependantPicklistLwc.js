import { LightningElement, api, track, wire } from 'lwc';
import { getPicklistValuesByRecordType, getObjectInfo } from 'lightning/uiObjectInfoApi';
export default class GenericDependentPicklist extends LightningElement {
   @api
   objectApiName;
   //An Api Name for Controlling PickList Field
   @api
   controllingPicklistApiName;
   //An Api Name for Dependent Picklist for any Object
   @api
   dependentPicklistApiName;
   // to show the label for the dependent field
   @api
   dependentPicklistLabel;
   // to show the label for the controlling field
   @api
   controllingPicklistLabel;
   //An Object to fill show user all available options
   @track
   optionValues = {controlling:[], dependent:[]};
   //To fill all controlling value and its related valid values
   allDependentOptions={};
   //To hold what value, the user selected.
   @track
   selectedValues = {controlling:undefined, dependent:undefined};
    //will be used to render for PCC screen basis its html
   @api
   isPccComponent= false
   //Will hold current value of controlling picklist passed from parent component
   @api
   selectedControllingValue ;
   currentDependentValue;
   @api
    get selectedDependentValue() {
        return this.currentDependentValue;
    }

    set selectedDependentValue(value) {
        try{
            if(value !== null){
                //Updating dependent list whenever controlling value is changed through code and not through UI
                //Eg - If wrapper is updated to reflect updated values 
                this.optionValues.dependent = [];
                this.optionValues.dependent = [{ label:'None', value:'' }];
                if(this.allDependentOptions.values !== undefined){
                    let controllerValues = this.allDependentOptions.controllerValues;
                    this.allDependentOptions.values.forEach( val =>{
                        val.validFor.forEach(key =>{
                            if(key === controllerValues[this.selectedControllingValue]){
                                this.isDisabled = false;
                                this.optionValues.dependent.push({label : val.label, value : val.value});
                            }
                        });
                    }); 
                }
            }
            this.currentDependentValue = value;
            this.setAttribute('selectedDependentValue', this.currentDependentValue);
        }catch(error){
            console.log(error.message);
        }
    }
   //will be used to make combobox read only as per requirement
   @api
   isReadOnly = false ;
   //Invoke in case of error.
   isError = false;
   errorMessage='';
   isPccComponent= false
   //To Disable Dependent PickList until the user won't select any parent picklist.
   isDisabled = true;
   @wire(getObjectInfo, {objectApiName : '$objectApiName'})
   objectInfo;
   @wire(getPicklistValuesByRecordType, { objectApiName: '$objectApiName', recordTypeId: '$objectInfo.data.defaultRecordTypeId'})
   fetchValues({error, data}){
       if(!this.objectInfo){
           this.isError = true;
           this.errorMessage = 'Please Check You Object Settings';
           return;
       }
       if(data && data.picklistFieldValues){
           try{
               console.log('data-->',data)
               this.setUpControllingPicklist(data);
               this.setUpDependentPickList(data);
               //Below code can be moved to different method during code clean up
               if(this.selectedControllingValue !== undefined && this.selectedDependentValue !== undefined){
                    //Pre populating values based on previous data and on component load
                    this.selectedValues.controlling = this.selectedControllingValue;
                    this.selectedValues.dependent = this.selectedDependentValue;
                    this.optionValues.dependent = [{ label:'None', value:'' }];
                    let controllerValues = this.allDependentOptions.controllerValues;
                    this.allDependentOptions.values.forEach( val =>{
                        val.validFor.forEach(key =>{
                            if(key === controllerValues[this.selectedControllingValue]){
                                this.isDisabled = false;
                                this.optionValues.dependent.push({label : val.label, value : val.value});
                            }
                        });
                    });
                    
                }
           }catch(err){
               this.isError = true;
               this.errorMessage = err.message;
               console.error(this.errorMessage)
           }
       }else if(error){
           this.isError = true;
           this.errorMessage = 'Object is not configured properly please check';
       }
   }
   //Method to set Up Controlling Picklist
   setUpControllingPicklist(data){
       this.optionValues.controlling = [{ label:'None', value:'' }];
       if(data.picklistFieldValues[this.controllingPicklistApiName]){
           data.picklistFieldValues[this.controllingPicklistApiName].values.forEach(option => {
               this.optionValues.controlling.push({label : option.label, value : option.value});
           });
           if(this.optionValues.controlling.length == 1)
               throw new Error('No Values Available for Controlling PickList');
       }else
           throw new Error('Controlling Picklist doesn\'t seems right');
   }
   //Method to set up dependent picklist
   setUpDependentPickList(data){
       console.log('dependent picklist api name',this.dependentPicklistApiName)
       if(data.picklistFieldValues[this.dependentPicklistApiName]){
           if(!data.picklistFieldValues[this.dependentPicklistApiName].controllerValues){
               throw new Error('Dependent PickList does not have any controlling values');
           }
           if(!data.picklistFieldValues[this.dependentPicklistApiName].values){
               throw new Error('Dependent PickList does not have any values');
           }
           this.allDependentOptions = data.picklistFieldValues[this.dependentPicklistApiName];
       }else{
           throw new Error('Dependent Picklist Doesn\'t seems right');
       }
   }
   handleControllingChange(event){
       const selected = event.target.value;
       if(selected && selected != 'None'){
           this.selectedValues.controlling = selected;
           this.selectedValues.dependent = null;
           this.selectedControllingValue = selected;
           this.selectedDependentValue = null;
           this.optionValues.dependent = [{ label:'None', value:'' }];
           let controllerValues = this.allDependentOptions.controllerValues;
           this.allDependentOptions.values.forEach( val =>{
               val.validFor.forEach(key =>{
                   if(key === controllerValues[selected]){
                       this.isDisabled = false;
                       this.optionValues.dependent.push({label : val.label, value : val.value});
                   }
               });
           });

           const selectedrecordevent = new CustomEvent(
                "selectedpicklists", {
                    detail : { pickListValue : this.selectedValues}
                }
            );
            this.dispatchEvent(selectedrecordevent);

           if(this.optionValues.dependent && this.optionValues.dependent.length > 1){

           }
           else{
               this.optionValues.dependent = [];
               this.isDisabled = true;
           }
       }else{
           this.isDisabled = true;
           this.selectedValues.dependent = [];
           this.selectedValues.controlling = [];
           this.selectedControllingValue = null;
           this.selectedDependentValue = null;
       }
   }
   handleDependentChange(event){
       this.selectedValues.dependent = event.target.value;
       this.selectedDependentValue = event.target.value;
       const selectedrecordevent = new CustomEvent(
           "selectedpicklists",
           {
               detail : { pickListValue : this.selectedValues}
           }
       );
       this.dispatchEvent(selectedrecordevent);
       //sendDataToParent();
   }
}