import { LightningElement,track,api } from 'lwc';
import getAddressAutoComplete from '@salesforce/apex/GoogleMapsAutocomplete.getAddressAutoComplete';
import getPlaceDetails from '@salesforce/apex/GoogleMapsAutocomplete.getPlaceDetails';
export default class GoogleMapsAutocompleteLwc extends LightningElement {

    @track location;
    @track predictions;
    @track displaydiv;
    @track isValue = true;
    @track test11;
    @track inputClass = 'validate';
    @api lblSearch;
    @api disableAddress=false;

    handleOnClick(event) {
        this.inputClass = 'slds-has-focus validate';
    }

    handleOnChange(event) {
        this.location = event.target.value;
        this.displaydiv = false;
        this.getCities();
    }

    handleOnBlur(event) {
        console.log('on remove');
        this.displaydiv = false;
    }

    getCities(){
        console.log('5555555555555555');
      
        getAddressAutoComplete({
            input: this.location
        })
        .then(result => {
            console.log('9999:' + JSON.stringify(result));
            var placeDetails = JSON.parse(result); 
            if(placeDetails.status == 'OK'){
                this.displaydiv = true;
                console.log('77777777777777:' + JSON.stringify(result));
                //var resp = JSON.parse(result);	
                //console.log(resp.predictions);
                //console.log('2222222222222222:'+ placeDetails);
                this.predictions = placeDetails.predictions;
                //console.log('77777777777777:' + JSON.stringify(predictions));
               
            } else {
                this.displaydiv = false;
            }
            
        

        })
        .catch(error => {
            console.log('6666666666666666:' + error);
            this.error = error;
        });
        /*.then((result => {
                this.cardHeader = result;
            }) => {
            console.log('heheheheheheh');
            //return refreshApex(this.opptiesOverAmount);
        })
        .catch((error) => {
            this.message = 'Error received: code' + error.errorCode + ', ' +
                'message ' + error.body.message;
        });*/
        /*
        helper.callServer(component,"c.getSuggestions",function(response){
            var resp = JSON.parse(response);	
            console.log(resp.predictions);
            component.set('v.predictions',resp.predictions);	
        },params);*/
        
        this.isValue = true;
    }

    getCityDetails(event) {
        /*console.log('2222222222222222222222222222:' + event.target.value);
        var selectedItem = event.target.value;
        this.location = selectedItem;
        this.predictions = [];*/
        console.log('place Id eeeeee :');
        var selectedItem = event.currentTarget;
        console.log('place Id 2:');
        var placeid = selectedItem.dataset.placeid;
        console.log('place Id 3:');
        console.log('place Id :' + placeid);
        this.isValue = true;
        this.predictions = [];	
        this.displaydiv = false;
        getPlaceDetails({
            placeId:placeid
        })
        .then(result => { 
            console.log('Success Id :' + JSON.stringify(result));
            //var placeDetails = JSON.parse(result);
            //console.log('placeDetails:' + JSON.stringify(placeDetails)); 		 
            this.location = result.addressFull;
            //var params = {"data" : data,"columns" : this.columns, "currentpage" : this.currentPage};
            const event = new CustomEvent('selectedaddress', {
                detail: result
            });
            this.dispatchEvent(event);
            //this.displaydiv = 'display: none';
            this.test11 = result.addressFull;
           
            
           
        })
        .catch(error => {
            console.log('Error Id  555:' + error);
            this.error = error;
        });
        /*
        var selectedItem = event.currentTarget;
        var placeid = selectedItem.dataset.placeid;
     
        var params = {
           "placeId" : placeid  	
        } 
     
        helper.callServer(component,"c.getPlaceDetails",function(response){
            var placeDetails = JSON.parse(response); 		 
            component.set('v.location',placeDetails.result.name);	
            component.set('v.predictions',[]); 
        },params);*/
        //this.displaydiv = 'display: none';	
     
    }

    handleRemovePill(event) {
        console.log("In handleRemovePill");
        this.isValue = false;
        /*
        const valueSelectedEvent = new CustomEvent('selectedaddress', {
            detail: '',
        });
        this.dispatchEvent(valueSelectedEvent);*/
    }

    @api checkValidity() {
        var inputCmp = this.template.querySelector(".validate");
        var value = inputCmp.value;
        // is input is valid?
        if (!value) {
          inputCmp.setCustomValidity("Please Enter a valid Value");
        } else {
          inputCmp.setCustomValidity(""); // if there was a custom error before, reset it
        }
        inputCmp.reportValidity(); // Tells lightning-input to show the error right away without needing interaction
      }
}