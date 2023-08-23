import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import fetchLicenceInfo from "@salesforce/apex/submissionConsoleMReLwcController.fetchLicenceInfo";
import handleMReProcess from '@salesforce/apex/submissionConsoleMReLwcController.handleMReProcess';
import fetchMReAppointmentConfigs from '@salesforce/apex/submissionConsoleMReLwcController.fetchMReAppointmentConfigs';
import MRe_brokerAgencyBlankMessage from '@salesforce/label/c.MRe_no_Agency_for_Broker_Contact_Msg';

export default class SubmissionConsoleMReLwc extends LightningElement {

    brokerContactId;
    insuredStateCode;

    agencyId = '';
    brokerId = '';
    agencyLicenseId = '';
    brokerLicenseId = '';

    insuredStateConfig;
    brokerAgencyBlankMessage = MRe_brokerAgencyBlankMessage;

    @track isAgencyBlank = false;

    @track agencyLicense;
    @track isNotStartedAgency = false;
    @track isInProgressAgency = false;
    @track isVarifiedAgency = false;
    @track isAppointedAgency = false;
    @track isDeclinedAgency = false;

    @track brokerLicense;
    @track isNotStartedBroker = false;
    @track isInProgressBroker = false;
    @track isVarifiedBroker = false;
    @track isAppointedBroker = false;
    @track isDeclinedBroker = false;

    @track showTriggerMReProcessButton = false;
    @track showTriggerMReProcessModal = false;
    @track triggerMReProcessResult = '';

    @track isAppointmentNotNeededAgency = false;
    @track appointmentNotNeededAgencyMsg = '';

    @track isAppointmentNotNeededBroker = false;
    @track appointmentNotNeededBrokerMsg = '';

    @api oppId;

    @api get brokerContact(){
        return this.brokerContactId;
    }
    set brokerContact(value){
        this.brokerContactId = value;
        this.getBrokerContactInfo();
    }

    @api get insuredState(){
        return this.insuredStateCode;
    }
    set insuredState(value){
        this.insuredStateCode = value;
        this.handleInsuredState();
    }

    getMReAppointmentConfigs(){
        this.isAppointmentNotNeededAgency = false;
        this.isAppointmentNotNeededBroker = false;
        fetchMReAppointmentConfigs()
        .then((result) => {
            console.log('fetchMReAppointmentConfigs result -->' + JSON.stringify(result));
            if (result){
                this.insuredStateConfig = result.find(i => i.DeveloperName === this.insuredStateCode);
                if(this.insuredStateConfig){
                    if(this.insuredStateConfig.Appointment_Required_for_Individual__c == false){
                        this.isAppointmentNotNeededBroker = true;
                        this.appointmentNotNeededBrokerMsg = 'Appointment not needed.';
                    }
                    if(this.insuredStateConfig.Appointment_Required_for_Agency__c == false){
                        this.isAppointmentNotNeededAgency = true;
                        this.appointmentNotNeededAgencyMsg = 'Appointment not needed.';
                    }
                    if(!this.isAppointmentNotNeededBroker || !this.isAppointmentNotNeededAgency){
                        this.getLicenceInfo();
                    }
                }
                else{
                    this.isAppointmentNotNeededBroker = true;
                    this.appointmentNotNeededBrokerMsg = 'Appointment not needed.';
                    this.isAppointmentNotNeededAgency = true;
                    this.appointmentNotNeededAgencyMsg = 'Appointment not needed.';
                }
            }else{
                this.isAppointmentNotNeededBroker = true;
                this.appointmentNotNeededBrokerMsg = 'Appointment not needed.';
                this.isAppointmentNotNeededAgency = true;
                this.appointmentNotNeededAgencyMsg = 'Appointment not needed.';
            }
        })
        .catch((error) => {
            console.log('fetchMReAppointmentConfigs error : ' + JSON.stringify(error));
        })
    }

    getLicenceInfo(){
        this.isNotStartedAgency = false;
        this.isInProgressAgency = false;
        this.isVarifiedAgency = false;
        this.isAppointedAgency = false;
        this.isDeclinedAgency = false;

        this.isNotStartedBroker = false;
        this.isInProgressBroker = false;
        this.isVarifiedBroker = false;
        this.isAppointedBroker = false;
        this.isDeclinedBroker = false;
        
        this.showTriggerMReProcessButton = false;

        fetchLicenceInfo({
            recordId: this.brokerContactId,
            insuredState: this.insuredStateCode
        })
        .then((result) => {
            console.log('fetchLicenceInfo result -->' + JSON.stringify(result));
            if (result){
                if(!this.isAppointmentNotNeededBroker){
                    this.brokerLicense = result.brokerLicense;
                    let mReDetails2 = this.brokerLicense;
                    this.brokerLicenseId = mReDetails2.Id == undefined ? '': mReDetails2.Id;
                    this.brokerId = this.brokerContactId;
                    if(mReDetails2.MRe_Appointment_Status__c == 'In Progress'){
                        this.isInProgressBroker = true;
                    }else if(mReDetails2.MRe_Appointment_Status__c == 'Verified'){
                        this.isVarifiedBroker = true;
                    }else if(mReDetails2.MRe_Appointment_Status__c == 'Appointed'){
                        this.isAppointedBroker = true;
                    }else if(mReDetails2.MRe_Appointment_Status__c == 'Declined'){
                        this.isDeclinedBroker = true;
                    }else{
                        mReDetails2.MRe_Appointment_Status__c = 'Not Started';
                        this.brokerLicense = mReDetails2;
                        this.isNotStartedBroker = true;
                        this.showTriggerMReProcessButton = true;
                    }
                }

                if(!this.isAppointmentNotNeededAgency){
                    if( result.agencyId ){
                        this.isAgencyBlank = false;
                        this.agencyId = result.agencyId;
                        this.agencyLicense = result.agencyLicense;
                        let mReDetails = this.agencyLicense;
                        this.agencyLicenseId = mReDetails.Agency__c == undefined ? '' : mReDetails.Agency__c;
                        if(mReDetails.MRe_Appointment_Status__c == 'In Progress'){
                            this.isInProgressAgency = true;
                        }else if(mReDetails.MRe_Appointment_Status__c == 'Verified'){
                            this.isVarifiedAgency = true;
                        }else if(mReDetails.MRe_Appointment_Status__c == 'Appointed'){
                            this.isAppointedAgency = true;
                        }else if(mReDetails.MRe_Appointment_Status__c == 'Declined'){
                            this.isDeclinedAgency = true;
                        }else{
                            mReDetails.MRe_Appointment_Status__c = 'Not Started';
                            this.agencyLicense = mReDetails;
                            this.isNotStartedAgency = true;
                            this.showTriggerMReProcessButton = true;
                        }
                    }else{
                        this.isAgencyBlank = true;
                    }
                }
            }
        })
        .catch((error) => {
            console.log('fetchLicenceInfo error : ' + JSON.stringify(error));
        })
    }

    getBrokerContactInfo(){
        if(this.brokerContactId != '' && this.brokerContactId != undefined && this.insuredStateCode != '' && this.insuredStateCode != undefined){
            this.getMReAppointmentConfigs();
        }
    }

    handleInsuredState(){
        if(this.brokerContactId != '' && this.brokerContactId != undefined && this.insuredStateCode != '' && this.insuredStateCode != undefined){
            this.getMReAppointmentConfigs();
        }
    }

    handleTriggerMReProcess(){
        handleMReProcess({
            oppId: this.oppId,
            insuredState : this.insuredStateCode,
            agencyId: this.agencyId,
            brokerId: this.brokerId,
            agencyLicenseId: this.agencyLicenseId,
            brokerLicenseId:this.brokerLicenseId
        })
            .then((result) => {
            console.log('handleMReProcess result -->' + result)
            if (result.indexOf('Error : ') == -1) {
                /*this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success!",
                    message: "MRe Process completed.",
                    variant: "success"
                })
                );*/
                //result = result.replace(/(?:\r\n|\r|\n)/g, '<br>');
                //this.showTriggerMReProcessModal = true;
                this.triggerMReProcessResult = result;
                this.getLicenceInfo();
                // Outlook Email to be triggered for MRE process 
                var url = 'mailto:?subject=MRe Appointment Process Email&body='+encodeURIComponent(result) ;
                window.location.href = url;

            }else{
                this.dispatchEvent(
                new ShowToastEvent({
                    title: "MRe Process Error.",
                    message: result,
                    variant: "error"
                })
                );
            }
        })
        .catch((error) => {
            console.log('handleMReProcess error : ' + JSON.stringify(error));
        })
    }

    closeTriggerMReProcessModal(){
        this.showTriggerMReProcessModal = false;
    }
}