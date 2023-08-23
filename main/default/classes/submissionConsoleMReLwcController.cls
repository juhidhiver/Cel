/**
 * @description       : This class contains method to handle functionality retaled to MRe Clearance (for User Story - 52958)
 * @author            : Jai
 * @group             : 
 * @Created on        : 05-11-2021
**/
public with sharing class submissionConsoleMReLwcController {
    
    /**
    * @description : This method called for broker contact details.
    * @author: Jai | 05-Nov-2021 
    * @param: contact Id, insured State
    * @return: wrapper of agency and broker licence
    **/

    @AuraEnabled
    public static wrLicense fetchLicenceInfo(String recordId, String insuredState){
        Agency_License__c agencyLicense = new Agency_License__c();
        Broker_License__c brokerLicense = new Broker_License__c();
        String agencyId = '';
        Contact brokerContact = [SELECT AccountId, 
                                (SELECT MRe_Appointment_Status__c, MRe_Email_Date__c, MRe_PIF_Submitted__c, License_State__c 
                                FROM Broker_Licenses__r 
                                WHERE License_Type__c = 'Admitted Lines' 
                                AND License_State__c=:insuredState 
                                AND RecordType.DeveloperName = 'MRe_Appointment'
                                LIMIT 1) 
                                FROM Contact 
                                WHERE Id =: recordId];
        if(brokerContact.Broker_Licenses__r.size()>0){
            brokerLicense = brokerContact.Broker_Licenses__r[0];
        }
        if(brokerContact.AccountId != null){
            agencyId = brokerContact.AccountId;
            List<Agency_License__c> tempAgencyLicense = [SELECT MRe_Appointment_Status__c, MRe_Email_Date__c, MRe_PIF_Submitted__c, License_State__c, Agency__c
                                                        FROM Agency_License__c 
                                                        WHERE Agency__c =: brokerContact.AccountId 
                                                        AND License_Type__c = 'Admitted Lines' 
                                                        AND RecordType.DeveloperName = 'MRe_Appointment'
                                                        AND License_State__c=:insuredState
                                                        LIMIT 1];
            if(tempAgencyLicense.size()>0){
                agencyLicense = tempAgencyLicense[0];
            }                                        
        }
        return new wrLicense(agencyLicense, brokerLicense, agencyId);
    }
    
    @TestVisible public class wrLicense{
        @AuraEnabled
        public Agency_License__c agencyLicense = new Agency_License__c();
        @AuraEnabled
        public Broker_License__c brokerLicense = new Broker_License__c();
        @AuraEnabled
        public String agencyId;
        public wrLicense(Agency_License__c agencyLicense, Broker_License__c brokerLicense, String agencyId){
            this.agencyLicense = agencyLicense;
            this.brokerLicense = brokerLicense;
            this.agencyId = agencyId;
        }
    }

    /**
    * @description : This method called for MRe Appointment Configuration details.
    * @author: Jai | 18-Nov-2021 
    * @param: contact Id, insured State
    * @return: MRe Appointment Configuration records
    **/

    @AuraEnabled
    public static List<MRe_Appointment_Configuration__mdt> fetchMReAppointmentConfigs(){
        return [SELECT Id,MasterLabel,DeveloperName, Is_Active__c, Appointment_Required_for_Agency__c, Appointment_Required_for_Individual__c 
                    from MRe_Appointment_Configuration__mdt
                    where Is_Active__c = true
                    ];
    }

    /**
    * @description : This method send email to broker and create acency and broker License record or update them.
    * @author: Jai | 05-Nov-2021 
    * @param: oppId, insuredState, agencyId, brokerId, agencyLicenseId, brokerLicenseId
    * @return: String 
    **/
    @AuraEnabled
    public static string handleMReProcess(String oppId, String insuredState, String agencyId, String brokerId, String agencyLicenseId, String brokerLicenseId){
        system.System.debug('agencyId : '+agencyId);
        system.System.debug('brokerId : '+brokerId);
        system.System.debug('agencyLicenseId : '+agencyLicenseId);
        system.System.debug('brokerLicenseId : '+brokerLicenseId);
        string result = '';
		string brokerName = '';
		List<Contact> brokerCon = [SELECT Name, AccountId, Email 
                                            FROM Contact 
                                            WHERE Id = : brokerId LIMIT 1];
        if(brokerCon.size()>0){
			brokerName = brokerCon[0].Name;
		}
        Savepoint sp = Database.setSavepoint();
        if(agencyId != ''){
            if(agencyLicenseId == ''){
                // create agency license record
                String recordTypeId = Schema.getGlobalDescribe().get('Agency_License__c').getDescribe().getRecordTypeInfosByDeveloperName().get('MRe_Appointment').getRecordTypeId();
                Agency_License__c agency = new Agency_License__c(
                    Agency__c = agencyId,
                    License_Type__c = 'Admitted Lines',
                    MRe_Appointment_Status__c='In Progress',
                    MRe_Email_Date__c=System.now(),
                    License_State__c=insuredState,
                    RecordTypeId = recordTypeId
                );
                insert agency;
            }else{
                // update agency license record
                List<String> appStatus = new List<String>{'Not Started','Declined'};
                List<Agency_License__c> agency = [SELECT MRe_Appointment_Status__c, MRe_Email_Date__c 
                                                    FROM Agency_License__c 
                                                    WHERE Id =: agencyLicenseId 
                                                    AND (MRe_Appointment_Status__c IN: appStatus OR MRe_Appointment_Status__c = null)
                                                    LIMIT 1];
                if(agency.size()>0){
                    agency[0].MRe_Appointment_Status__c='In Progress';
                    agency[0].MRe_Email_Date__c=System.now();
                    update agency;
                }
            }
        }
        if(brokerId != ''){
            if(brokerLicenseId == ''){
                // create broker license record
                String recordTypeId = Schema.getGlobalDescribe().get('Broker_License__c').getDescribe().getRecordTypeInfosByDeveloperName().get('MRe_Appointment').getRecordTypeId();
                Broker_License__c broker = new Broker_License__c(
                    Broker__c = brokerId,
                    License_Type__c = 'Admitted Lines',
                    MRe_Appointment_Status__c='In Progress',
                    MRe_Email_Date__c=System.now(),
                    License_State__c=insuredState,
                    RecordTypeId = recordTypeId
                );
                insert broker;
            }else{
                // update broker license record
                List<String> appStatus = new List<String>{'Not Started','Declined'};
                List<Broker_License__c> broker = [SELECT MRe_Appointment_Status__c, MRe_Email_Date__c 
                                                    FROM Broker_License__c 
                                                    WHERE Id =: brokerLicenseId 
                                                    AND (MRe_Appointment_Status__c IN: appStatus OR MRe_Appointment_Status__c = null)
                                                    LIMIT 1];
                if(broker.size()>0){
                    broker[0].MRe_Appointment_Status__c='In Progress';
                    broker[0].MRe_Email_Date__c=System.now();
                    update broker;
                }
            }
        }
        List<EmailTemplate> emailTemplate = [SELECT Body, Subject FROM EmailTemplate WHERE DeveloperName = 'MRe_Process_Email' LIMIT 1];
        if(emailTemplate.size()>0){
			list<String> toAddresses = Label.Broker_Begin_MRe_Send_Email_To.split(',');
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(toAddresses);
            String body = emailTemplate[0].Body.replace('{{broker}}',brokerName).replace('{{oppId}}',oppId);
            String subject = emailTemplate[0].Subject;
            email.setPlainTextBody(body);
            email.setSubject(subject);
            try{
                //Messaging.sendEmail(new List<Messaging.Email>{email});
                //result = 'success';
                result = body;
            }
            catch(exception ex){
                result = 'Error : '+ex.getMessage();
                Database.RollBack(sp);
            }
        }
        else{
            result = 'Error : No email template found.';
            Database.RollBack(sp);
        }
        return result;
    }
}