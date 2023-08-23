import { LightningElement, track, wire, api } from 'lwc';
import getSubmissionRelatedToAccount from '@salesforce/apex/ClaimDetailsSectionController.getSubmissionRelatedToAccount';
export default class ClaimsDetailsSection extends LightningElement {
    @api recordIdOpportunity; // declaring public to fetch the current recordID off Opp.
    @track claimsData; // declaring to save value which comes from apex method 
    @api _opportunityId;
    @api claimsDetailsSection ;
    @api noClaimToDisplay;
     @api countClaims = 0 ;
    claimtest;
    
    @track columns = [
        { label: 'Claim Data', fieldName: 'ClaimDataURL' , type : 'url',
        
            typeAttributes: {
                label: {
                    fieldName: 'Claim'
                },
                tooltip: {
                    fieldName: 'Claim'
                }
    
            },
            hideDefaultActions: true
        },
        { label: 'Policy Number', fieldName: 'PolicyURL' , type : 'url' ,
            typeAttributes: {
                label: {
                    fieldName: 'PolicyNum'
                },
                tooltip: {
                    fieldName: 'PolicyNum'
                },
                
        },
        hideDefaultActions: true
        },
        { label: 'Effective Date', fieldName: 'Policy_Effective_Date__c' , type : 'date' , hideDefaultActions: true,
            typeAttributes: {
                day: "numeric",
                month: "numeric",
                year: "numeric"
            }
        },
        { label: 'Claim status', fieldName: 'Claim_status__c' , type : 'text' , hideDefaultActions: true},
        { label: 'Total Incurred', fieldName: 'Total_Incurred__c' , type : 'number' , hideDefaultActions: true},
        { label: 'Indemnity - Paid', fieldName: 'Indemnity_Paid__c' , type : 'number', hideDefaultActions: true},
        { label: 'Indemnity - Reserve', fieldName: 'Indemnity_Reserve__c' , type : 'number', hideDefaultActions: true},
        { label: 'Fees - Paid', fieldName: 'Fees_Paid__c' , type : 'number', hideDefaultActions: true},
        { label: 'Fees - Reserve', fieldName: 'Fees_Reserve__c' , type : 'number', hideDefaultActions: true}
    
    ];

  
   
    @wire(getSubmissionRelatedToAccount, {oppId: '$recordIdOpportunity'})  // passing parameter to apex method
    WireClaimDataRecords({error, data}){ 
       let claimRecords = [];
       let count = 0 ; 
        if(data){
            let returnedClaimsData = data;
            if(returnedClaimsData)
            {
                returnedClaimsData.forEach((record) => {
                
                    let tempRec = Object.assign( {}, record );  // syntax- Object.assign(target, ...sources) copies enumerable(for loop's) and own properties from a source object to a target object
                    
                    if ( tempRec.Policy__c  ) {
                        tempRec.PolicyNum = tempRec.Policy__r.Policy_Number__c;
                        tempRec.PolicyURL = '/' + tempRec.Policy__c;
                    }
                    if ( tempRec.Name  ) {
                       tempRec.Claim = tempRec.Name;
                       tempRec.ClaimDataURL = '/' + tempRec.Id;
                    }
                    claimRecords.push( tempRec );
                });
            }
            this.claimsData = claimRecords ;
            //this.claimsDetailsSection = 'Claim Details'+ ' ('+returnedClaimsData.length +')' ;
            this.claimsDetailsSection = returnedClaimsData.length ;
            const showEventClaim = new CustomEvent('getclaimsrecordcount', { detail: this.claimsDetailsSection});
            this.dispatchEvent(showEventClaim);
            console.log(this.claimsData);

            this.error = undefined;
        }else{
            this.error = error;
            this.claimsData = undefined;
            console.log('err claim data '+error);
        }
    }

 

   
    
    
}