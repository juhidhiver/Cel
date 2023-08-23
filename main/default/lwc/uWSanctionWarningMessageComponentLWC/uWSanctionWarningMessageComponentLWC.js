import { LightningElement,api,wire,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import checkUWSanctionStatus from '@salesforce/apex/SanctionMessageController.checkUWSanctionStatus';


export default class UWSanctionWarningMessageComponentLWC extends NavigationMixin(LightningElement) {

    @api recordId;
    @api responseData;
    @api hasSanctionFail;
    @track wiredata;

    @wire(checkUWSanctionStatus, {
        recordId: '$recordId'
    })
    fetchSanctionStatus(result) {
        this.wiredata = result;
        var data = result.data;
        var error = result.error;
        if (data) {
            this.handleData(data);
        }
    }

    handleData(data){
        console.log(' data.hasSanctionFail'+ data.hasSanctionFail)
        this.responseData = data;
        this.hasSanctionFail = data.hasSanctionFail;
    }

    @api
    handleRefreshSanctionWarningMessage() {
        refreshApex(this.wiredata);
        console.log('this.wiredata' + this.wiredata);
    }

   /************ New Code Starts 26/04/2022  ***************/
    @api
    handleSanctionWarningStatusCheck(accid){
        console.log('accid'+accid);
        checkUWSanctionStatus({recordId: accid}).then((result) => {
            this.wiredata = result;   
            if(result != null) {
             this.handleData(result);
           }
           else if(result==null){
            this.hasSanctionFail = false;  
           }
        })
        .catch((error) => {
          console.log("error"+JSON.stringify(error));
        });
    }
    /************ New Code End 26/04/2022  ***************/

    handleNavigation(event){
        var recordId = event.target.dataset.id;

        var quoteId = event.target.dataset.id;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            },
        }).then(url => {
            window.open(url, "_blank");
        });
    }

}