import { LightningElement, api ,track} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import submitSubmissionToApprovalProcess from '@salesforce/apex/ReferralApprovalController.submitSubmissionToApprovalProcess';

export default class ReferralApprovalLwc extends LightningElement {

    @api rctId;
    @api quoteId;
    @api referralUserId;
    @api commentString = '';
    @api errorMessages ;
    @api referType = '';
    @api referOptions = [];
    handleCancel() {
        // handle cancel here
        this.dispatchEvent(new CustomEvent('closereferral'));
    }
    connectedCallback(){
        this.resetAttributes();


    }
    resetAttributes(){
        this.referralUserId = '';
        this.commentString = '';
    }

    validateInput(event){
        var errorTemp = [];
        if(!this.commentString) {
            errorTemp.push('Comments');
        }
        if(!this.referralUserId){
            errorTemp.push('Approver');
        }

        if(errorTemp.length >0 ){
            this.errorMessages = 'These required fields must be completed: ' + errorTemp.join(', ') + '.';
            console.log('Message' + JSON.stringify(this.errorMessages));
            return false;
        }else{
            this.errorMessages = null;
            return true;
        }
    }

    handleNext(){
        console.log("CHeck Console"+this.quoteId);
        if(!this.validateInput()) return; //valid input
        submitSubmissionToApprovalProcess({ quoteId: this.quoteId ,userId:this.referralUserId,comment: this.commentString, referType : this.referType})
            .then(result => {
                if(result.isSuccess){
                    //handle success
                    this.showToast('Success !','Your request is submitted successfully. ','success');
                    this.resetAttributes();
                    this.dispatchEvent(new CustomEvent('closereferral'));
                    //window.location.reload();
                }else{
                    this.showToast('Error !',result.errors[0],'error');
                    this.resetAttributes();
                    this.dispatchEvent(new CustomEvent('closereferral'));
                }
            }).catch(error => {
            console.log('Error' + JSON.stringify(error));
            this.showToast('Error !',error,'error');
        });

        /*
        if(isSuccess){
            //handle submit evt
        }else{
            this.showToast('Error','Something wrong','error');
        } */
    }
    handleChangeInput(event) {
        if (event.target.name == 'referralUser') {
            this.referralUserId = event.target.value;
        }
        if (event.target.name == 'comment') {
            this.commentString = event.target.value;
        }
        if (event.target.name =='referType'){
            this.referType = event.target.value;
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
}