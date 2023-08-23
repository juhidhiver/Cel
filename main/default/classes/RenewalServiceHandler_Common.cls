public with sharing class RenewalServiceHandler_Common {

    public static List<Renewal__c> fetchRenewalRecords(String renewalRecordTypeId){
        return [SELECT Id, Broker__c, Broker__r.Broker_Contact__r.Account.Name, Insured_Account__c, 
                Insured_Account__r.Name,Policy__c, Policy__r.Policy_Number__c, Name, Policy__r.Account__c, Claim_Amount__c,Assigned_Underwriter__r.Name,
                Policy__r.Account__r.Name, Renewal_Warning__c, Status__c,Renewal_Date__c,Policy_Premium__c,
                Claims_Number__c, No_Recipients__c FROM Renewal__c WHERE recordtypeId =:renewalRecordTypeId And Renewal_Date__c = THIS_MONTH  ORDER BY Renewal_Date__c];
    }

    public static TabItem getListSectionSetting(String productName) {
        System.debug('>>>productName>>>'+productName);
        //Added by Vinayesh for testing. Needs to be modified.
        // if(productName == 'Private Company Combo'){
        //     productName = 'Cyber';
        // }
        TabItem tabItem = new TabItem();
        List<SectionSetting__c> listSectonSetting = [SELECT Id,Name,Main_Section__c,Order__c,
                                            Sub_Section__c,Source_Object__c,Source_Field_Label__c,
                                            Source_Field_API__c,Format__c, Component__c, DisplayType__c,
                                            Lookup_To__c, Is_Required__c,Profile_Name_for_Read_Only__c
                                            FROM SectionSetting__c
                                            WHERE Component__c = 'Auto Renewals'
                                            AND Product__c INCLUDES (:productName)
                                            ORDER BY Order__c ASC];    
		Map<Decimal, SectionSetting__c> orderSectionSettingMap = new Map<Decimal, SectionSetting__c>();
        Map<String,List<SectionSetting__c>> mapParentNoSub = new Map<String,List<SectionSetting__c>>();
        Map<String,List<SectionSetting__c>> mapParentWithSub = new Map<String,List<SectionSetting__c>>();
        Map<String,List<SectionSetting__c>> mapParentChildSub = new Map<String,List<SectionSetting__c>>();
        for(SectionSetting__c sectionSetting : listSectonSetting) {
			if(String.isBlank(sectionSetting.Source_Object__c) && String.isBlank(sectionSetting.Sub_Section__c)){
				orderSectionSettingMap.put(sectionSetting.Order__c, sectionSetting);
			}else{
                //if(String.isBlank(sectionSetting.Source_Object__c)) continue;
                if(String.isBlank(sectionSetting.Sub_Section__c)) {
                    if(mapParentNoSub.containsKey(sectionSetting.Main_Section__c)){
                        mapParentNoSub.get(sectionSetting.Main_Section__c).add(sectionSetting);
                    }else{
                        mapParentNoSub.put(sectionSetting.Main_Section__c, new List<SectionSetting__c>{sectionSetting});
                    }
                } else {
                    if(mapParentWithSub.get(sectionSetting.Main_Section__c) == null) {
                        mapParentWithSub.put(sectionSetting.Main_Section__c, new List<SectionSetting__c> {sectionSetting});
                    } else {
                        mapParentWithSub.get(sectionSetting.Main_Section__c).add(sectionSetting);
                    }
                }
            }
        }
        Map<String, List<SectionSetting__c>> mapSubChild = new Map<String, List<SectionSetting__c>>();
        for(String key1 : mapParentWithSub.keySet()) {
            for(SectionSetting__c sectionSetting : mapParentWithSub.get(key1)) {
                String key = sectionSetting.Main_Section__c + ';' + sectionSetting.Sub_Section__c;
                if(mapSubChild.get(key) == null) {       
                    mapSubChild.put(key, new List<SectionSetting__c> {sectionSetting});
                } else {
                    mapSubChild.get(key).add(sectionSetting);
                }
            }
        }
        Map<String, Section> mainTitleSectionMap = new Map<String, Section>();
        //List<Section> listSection = new List<Section>();
        for(String key1 : mapParentNoSub.keySet()) {
            Section a1 = new Section();
            List<WrapperField> list1 = new List<WrapperField>();
            //for(String key : mapParentNoSub.keySet()) {
                list1.addAll(convertToListWrapperField(mapParentNoSub.get(key1)));
            //}
            a1.mainSectionFields = list1;
            a1.mainSectionTitle = key1;
            //listSection.add(a1);
            
			mainTitleSectionMap.put(a1.mainSectionTitle, a1);
        }
        
        for(String key1 : mapParentWithSub.keySet()) {
            Section a = new Section();
            for(String key : mapSubChild.keySet()) {     
                String [] arr = key.split(';');
                //Child
                a.mainSectionTitle = arr[0];
                SubSectionChild subSectionChild = new SubSectionChild();
                subSectionChild.subSectionChildTitle = arr[1];
                List<WrapperField> subSectionChildFields = new List<WrapperField>();
                subSectionChildFields.addAll(convertToListWrapperField(mapSubChild.get(key)));
                subSectionChild.subSectionChildFields = subSectionChildFields;
                a.subSectionChilds.add(subSectionChild);
                //End        
            }
            //listSection.add(a);
            mainTitleSectionMap.put(a.mainSectionTitle, a);
        }
        System.debug('>>>mainTitleSectionMap>>>'+mainTitleSectionMap);
		List<Section> sectionOrdered = getSortedKeyset(mainTitleSectionMap, orderSectionSettingMap);
        System.debug('>>>sectionOrdered>>>'+sectionOrdered);
        tabItem.sections = sectionOrdered;
        tabItem.activeSections = getActiveSections(sectionOrdered);
        System.debug('End'+  Datetime.now().second());
        return tabItem;
    }

    private static List<WrapperField> convertToListWrapperField(List<SectionSetting__c> params) {
        
        List<Profile> lstProfile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        String currentProflieName = lstProfile[0].Name;
        
        List<WrapperField> listWrapperField = new List<WrapperField>();
        List<String> dependenList = new List<String>();
        for(SectionSetting__c sectionSetting : params) {
            WrapperField a = new WrapperField();
            a.sourceObject = sectionSetting.Source_Object__c;
            a.sourceFieldLabel = sectionSetting.Source_Field_Label__c;
            a.sourceFieldApi = sectionSetting.Source_Field_API__c;
            a.format = sectionSetting.Format__c;
            a.lookupTo = sectionSetting.Lookup_To__c;
            a.required = sectionSetting.Is_Required__c;
            a.sourceMainSectionTitle = sectionSetting.Main_Section__c; //Added by GP
            if(String.isNotBlank(sectionSetting.Profile_Name_for_Read_Only__c)) {
                if(sectionSetting.Profile_Name_for_Read_Only__c == 'All'){
                    a.readOnly = true;
                } else {
                    a.readOnly = sectionSetting.Profile_Name_for_Read_Only__c.contains(currentProflieName) ? true : false;
                }
            }
            if(sectionSetting.Format__c == 'Picklist'){
                SObjectType objType = Schema.getGlobalDescribe().get(sectionSetting.Source_Object__c);
                Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
                SObjectField controllingPicklist = fieldMap.get(sectionSetting.Source_Field_API__c).getDescribe().getController();
                if(controllingPicklist != null) {
                    a.isDependencyPicklist = true;
                    dependenList.add(controllingPicklist+'');
                }
            }
            listWrapperField.add(a);
        }
        for(WrapperField wrapperField : listWrapperField){
            if(dependenList.contains(wrapperField.sourceFieldApi)) wrapperField.isDependencyPicklist = true;
        }
        return listWrapperField;
    }

    public static List<Section> getSortedKeyset(Map<String, Section> mainTitleSectionMap, Map<Decimal, SectionSetting__c> orderSectionSettingMap) {
        List<Section> result = new List<Section>();
		List<String> mainTitleOrdered = new List<String>();
        List<Decimal> keySetList = new List<Decimal>();
        keySetList.addAll(orderSectionSettingMap.keySet());
        keySetList.sort();
        List<SectionSetting__c> listMainSectionOrdered = new List<SectionSetting__c>();
        for(Decimal key: keySetList){
            System.debug('orderSectionSettingMap.get(key).Main_Section__c'+orderSectionSettingMap.get(key).Main_Section__c);
            listMainSectionOrdered.add(orderSectionSettingMap.get(key));
        }
		for(SectionSetting__c section : listMainSectionOrdered){
            System.debug('>>>mainTitle>>>'+section.Main_Section__c);
            Section mainSection = mainTitleSectionMap.get(section.Main_Section__c);
            mainSection.displayType = section.DisplayType__c;
			result.add(mainSection);
        }
        return result;
    }

    public static List<String> getActiveSections(List<Section> sections) {
        List<String> result = new List<String>();
        for (Section section : sections) {
            //tuan.d.nguyen added 7-Dec-2020 start collapsed main section
            if(section.displayType != 'Collapsed') //tuan.d.nguyen added 7-Dec-2020 end
                result.add(section.mainSectionTitle);
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static AutoRenewalWrapper getRenewalWrappInfo (){
        List<UserAppInfo> userAppInfo = [SELECT Id, AppDefinitionId FROM UserAppInfo WHERE UserId = :UserInfo.getUserId() LIMIT 1];
        if(userAppInfo.size()>0){
            AppDefinition appDefinition = [SELECT DurableId, Label FROM AppDefinition Where DurableId = :userAppInfo[0].AppDefinitionId LIMIT 1];
            AutoRenewalWrapper wrapp = new AutoRenewalWrapper();
            wrapp.appName = appDefinition.Label;
            if(wrapp.appName=='Aqueous Underwriting'){
                wrapp.renewalRecordType =  Schema.SObjectType.Renewal__c.getRecordTypeInfosByDeveloperName().get('Aqueous').getRecordTypeId();
            }
            system.debug('wrapp'+wrapp);
            return wrapp ;
        }
       return null;
    }

    @AuraEnabled
    public static  List<Renewal__c> fetchFilteredRecords(String wrappObj,String renewalRecordTypeId){
        system.debug('wrappObj'+wrappObj);

        List<String> conditionalFields = new List<String>();

        FilteredWrapper filterObj  = (FilteredWrapper) System.JSON.deserialize(wrappObj, FilteredWrapper.class);

        String queryStr = 'SELECT Id, Broker__c, Broker__r.Broker_Contact__r.Account.Name, Insured_Account__c,Insured_Account__r.Name,';
        queryStr += 'Policy__c, Policy__r.Policy_Number__c, Name, Policy__r.Account__c,Claim_Amount__c,Assigned_Underwriter__r.Name,';
        queryStr += 'Policy__r.Account__r.Name, Renewal_Warning__c, Status__c,Renewal_Date__c,Policy_Premium__c,No_Recipients__c,';
        queryStr += 'Claims_Number__c FROM Renewal__c WHERE recordtypeId = '+ '\''+renewalRecordTypeId+'\''+' And CALENDAR_YEAR(Renewal_Date__c)='+filterObj.year;
        queryStr += ' AND CALENDAR_MONTH(Renewal_Date__c)='+Integer.valueOf(filterObj.month);
        

        if(filterObj.renewalWarning){
            conditionalFields.add(' Renewal_Warning__c = '+filterObj.renewalWarning);
         }
         if(filterObj.largeClaimWarning){
            conditionalFields.add(' Claim_Amount__c > 25000');
         }
         if(filterObj.hasClaimWarning){
            conditionalFields.add(' Claims_Number__c > 2 ');
         }
         if(filterObj.noRecepientWarning){
            conditionalFields.add(' No_Recipients__c = '+filterObj.noRecepientWarning);
         }
         if(filterObj.docRequiredWarning){
            conditionalFields.add(' Documents_Required__c = null');
         }
         if(filterObj.paymentWarning){
            conditionalFields.add(' Payment_Warning__c = '+filterObj.paymentWarning);
         }
         if(filterObj.brokerWarning){
            Boolean brokerWarn = filterObj.brokerWarning == true ? false : true;
            conditionalFields.add(' Broker_Appointed__c	 = '+ brokerWarn);
         }
         if(String.isNotBlank(filterObj.statusValue)){
            conditionalFields.add(' Status__c = '+'\''+filterObj.statusValue+'\'');
         }

         if(String.isNotBlank(filterObj.selectedBroker)){
            conditionalFields.add(' Broker__r.Broker_Contact__r.AccountId = '+'\''+filterObj.selectedBroker+'\'');
         }
         if(String.isNotBlank(filterObj.selectedInsured)){
            conditionalFields.add(' Insured_Account__c = '+'\''+filterObj.selectedInsured+'\'');
        }

         if(conditionalFields.size()>0){
           String conditionalQuery  = String.join(conditionalFields,' AND ');
           queryStr = queryStr + ' AND '+conditionalQuery;
         }

         system.debug('queryStr'+queryStr);
         List<Renewal__c> renewalList = Database.query(queryStr);

         system.debug('renewalList'+renewalList);

        system.debug('filterObj'+filterObj);

        return renewalList;
    }

    public static List<Renewal__c> createRenewalRecords(List<Policy__c> policyList,String prodName){

        Set<Id> submissionIds = new  Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> quoteIds = new Set<Id>();
        Set<Id> policyIds = new Set<Id>();
        
        Map<String,Broker_Account__c> oppBrokerMap = new Map<String,Broker_Account__c>();
        Map<String,AggregateResult> claimDataSummaryMap = new  Map<String,AggregateResult>();
        Map<String,Decimal> policyPremiumMap = new  Map<String,Decimal>();
        Map<String,Boolean> ratingModifierMap = new Map<String,Boolean>();
        Map<String,CoveragesLineItem__c> coverageMap = new Map<String,CoveragesLineItem__c>();
        Map<String,String> paymentStatusMap = new Map<String,String>();
        Map<String,Boolean> paymentWarningMap = new Map<String,Boolean>();
       // Map<String,Integer> mapOfAccountCon = new Map<String,Integer>();
        Map<String,Boolean> contactRoleMap = new Map<String,Boolean>();

        Set<Id> brokerIds = new Set<Id>();
        List<Renewal__c> renewalList = new List<Renewal__c>();

        Map<String,String> ratingModifierRatableExposure = new Map<String,String>();

        Map<String,Decimal> limitOfIndeminityMap = new Map<String,Decimal>();

        String recordTypeName =  String.isNotBlank(prodName) && prodName=='Professional Indemnity' ? 'Aqueous' : '';

        Id renewalRecordTypeId = Schema.SObjectType.Renewal__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();  



        for(Policy__c  policyRec  : policyList){
            policyIds.add(policyRec.Id);
            if(policyRec.Quotes__r.size()>0){
                submissionIds.add(policyRec.Quotes__r[0].OpportunityId);
                quoteIds.add(policyRec.Quotes__r[0].Id);
            }
            accountIds.add(policyRec.Account__c);
        }

        for(Broker_Account__c brokerRec  : [select Id,Opportunity__c,Broker_Contact__r.Account.Appointed__c,Broker_Contact__r.AccountId from Broker_Account__c where IsPrimaryBroker__c=true And Opportunity__c IN: submissionIds]){
            brokerIds.add(brokerRec.Broker_Contact__r.AccountId);
            oppBrokerMap.put(brokerRec.Opportunity__c,brokerRec);
        }
       /* for(Contact con : [select id,AccountId from contact where AccountId IN:brokerIds And Role__c='Renewals']){
            if(!mapOfAccountCon.containskey(con.AccountId)){
                mapOfAccountCon.put(con.AccountId,1);
            }
            else{
                Integer contactCount = mapOfAccountCon.get(con.AccountId);
                mapOfAccountCon.put(con.AccountId,contactCount+1);
            }
        }*/
        /***************** New Logic for No Recepients *******************/
        for(Contact con : [select id,AccountId from contact where Role__c='Renewals' And AccountId IN:brokerIds]){
            contactRoleMap.put(con.AccountId,false);
        }

        for(CoveragesLineItem__c covLineItem : [select id,Form_Number__c,Name,Quote__c,Option_Type__c,Option_Value_Default__c,Coverage__r.Name from  CoveragesLineItem__c where Quote__c IN: quoteIds And Form_Number__c='AQUW153']){
            coverageMap.put(covLineItem.Quote__c, covLineItem);
        }

        for(AggregateResult aggr : [select Account__c acc,SUM(Total_Incurred__c) sumInsured,COUNT(id) countIds from Claim_Data__c  GROUP BY Account__c HAVING Account__c IN:accountIds ]){
           claimDataSummaryMap.put((String)aggr.get('acc'),aggr);
        }
        for(Quote_Option__c quoteOption : [select id,NonProRated_BNDP__c,Broker_Netted_Down_Premium_Final__c,Quote__r.Quote_Type__c,Quote__c,Limit__c from Quote_Option__c where Quote__c IN:quoteIds And Bound__c = true]){
            
            limitOfIndeminityMap.put(quoteOption.Quote__c,quoteOption.Limit__c);
            policyPremiumMap.put(quoteOption.Quote__c,quoteOption.NonProRated_BNDP__c);        
        }

        for(Rating_Modifiers__c ratingModifier : [select id,Name,Opportunity__c,Rating_Modifier_Value__c from Rating_Modifiers__c where Opportunity__c IN: submissionIds And 
                                                 (Name='Is the business regulated by the Royal Institution of Chartered Surveyors?'  OR Name='Rateable Exposure')]){
            if(ratingModifier.Rating_Modifier_Value__c.toUpperCase() == 'YES' && ratingModifier.Name=='Is the business regulated by the Royal Institution of Chartered Surveyors?'){
                ratingModifierMap.put(ratingModifier.Opportunity__c,true);
            }
            else if(ratingModifier.Name=='Is the business regulated by the Royal Institution of Chartered Surveyors?'){
                ratingModifierMap.put(ratingModifier.Opportunity__c,false);  
            }

            if(ratingModifier.Name=='Rateable Exposure'){
            ratingModifierRatableExposure.put(ratingModifier.Opportunity__c,ratingModifier.Rating_Modifier_Value__c);
            }
        }

        for(Payment_Data__c paymentrec : [select id,Paid_Status__c,Quote__c,quote__r.Endorsement_Effective_Date__c,quote__r.Policy__r.Renewal_Date__c,quote__r.Quote_Type__c,Policy__c
                                          from Payment_Data__c where Policy__c IN: policyIds]){

            if(paymentrec.Paid_Status__c=='Not Paid' || paymentrec.Paid_Status__c=='Query'){
                paymentStatusMap.put(paymentrec.Policy__c,'Outstanding'); 

                if(paymentrec.quote__c != null && paymentrec.quote__r.Policy__c != null &&
                   paymentrec.quote__r.Quote_Type__c != 'New Business' && paymentrec.quote__r.Quote_Type__c != 'Renewal'
                   && paymentrec.quote__r.Policy__r.Renewal_Date__c.DaysBetween(paymentrec.quote__r.Endorsement_Effective_Date__c) <= 90 ) {
                   
                    paymentWarningMap.put(paymentrec.Policy__c,false);
                }
                else{
                    paymentWarningMap.put(paymentrec.Policy__c,true);
                }

            }

        }


        for(Policy__c policy : policyList){
            
            Renewal__c newRenewalRecord = new Renewal__c();

            newRenewalRecord.Renewal_Warning__c = policy.Account__r.Renewal_Warning__c;

            if(policy.Quotes__r.size()>0){
              newRenewalRecord.Broker__c = !oppBrokerMap.isEmpty() && oppBrokerMap.containsKey(policy.Quotes__r[0].OpportunityId) ? oppBrokerMap.get(policy.Quotes__r[0].OpportunityId).Id : null;

              newRenewalRecord.Limit_Of_Indemnity__c  =  !limitOfIndeminityMap.isEmpty() && limitOfIndeminityMap.containsKey(policy.Quotes__r[0].Id) ?  limitOfIndeminityMap.get(policy.Quotes__r[0].Id) : null;

              newRenewalRecord.No_Recipients__c = (!contactRoleMap.isEmpty() && !oppBrokerMap.isEmpty() && oppBrokerMap.containsKey(policy.Quotes__r[0].OpportunityId)
                                                    && contactRoleMap.containsKey(oppBrokerMap.get(policy.Quotes__r[0].OpportunityId).Broker_Contact__r.AccountId))
                                                    ? contactRoleMap.get(oppBrokerMap.get(policy.Quotes__r[0].OpportunityId).Broker_Contact__r.AccountId) : true;

              newRenewalRecord.Rateable_Exposure__c  =    !ratingModifierRatableExposure.isEmpty() && ratingModifierRatableExposure.containsKey(policy.Quotes__r[0].OpportunityId) ? ratingModifierRatableExposure.get(policy.Quotes__r[0].OpportunityId) : '';

              newRenewalRecord.Broker_Appointed__c = 	!oppBrokerMap.isEmpty() && oppBrokerMap.containsKey(policy.Quotes__r[0].OpportunityId) ? oppBrokerMap.get(policy.Quotes__r[0].OpportunityId).Broker_Contact__r.Account.Appointed__c : false;

              newRenewalRecord.Submission__c = policy.Quotes__r[0].OpportunityId;
              newRenewalRecord.Policy_Premium__c = !policyPremiumMap.isEmpty() && policyPremiumMap.containsKey(policy.Quotes__r[0].Id) ?  policyPremiumMap.get(policy.Quotes__r[0].Id) : null;
              newRenewalRecord.Latest_Bound_Quote__c = policy.Quotes__r[0].Id;

                if(policy.Quotes__r[0].Layer__c == 'Primary' && policy.Quotes__r[0].Opportunity.Main_Profession__c == 'Property Professionals'){

                    newRenewalRecord.RICS__c  =  !ratingModifierMap.isEmpty() && ratingModifierMap.containsKey(policy.Quotes__r[0].OpportunityId) ?  ratingModifierMap.get(policy.Quotes__r[0].OpportunityId) : false;
               }
               else{
                    newRenewalRecord.RICS__c = false;
               }

               newRenewalRecord.Claim_Amount__c =   !claimDataSummaryMap.isEmpty() && claimDataSummaryMap.containsKey(policy.Account__c) ? (Decimal)claimDataSummaryMap.get(policy.Account__c).get('sumInsured') : null;
               newRenewalRecord.Claims_Number__c =  !claimDataSummaryMap.isEmpty() && claimDataSummaryMap.containsKey(policy.Account__c) ? Integer.valueof(claimDataSummaryMap.get(policy.Account__c).get('countIds')) : 0;

               newRenewalRecord.Payment_Status__c = !paymentStatusMap.isEmpty() && paymentStatusMap.containsKey(policy.Id) ? paymentStatusMap.get(policy.Id) : 'Paid';

               newRenewalRecord.Payment_Warning__c = !paymentWarningMap.isEmpty() &&  paymentWarningMap.containsKey(policy.Id) ? paymentWarningMap.get(policy.Id) : false;

               if((newRenewalRecord.Claims_Number__c >= 3 || newRenewalRecord.Claim_Amount__c > 25000 ||  (policy.Account__c!=null &&  policy.Account__r.Renewal_Warning__c == true ) 
               || (!oppBrokerMap.isEmpty() && oppBrokerMap.containsKey(newRenewalRecord.Submission__c) && oppBrokerMap.get(newRenewalRecord.Submission__c).Broker_Contact__r.Account.Appointed__c  == false ) 
               || (!coverageMap.isEmpty() && coverageMap.containsKey( newRenewalRecord.Latest_Bound_Quote__c) && coverageMap.get( newRenewalRecord.Latest_Bound_Quote__c).Form_Number__c == 'AQUW153')
               ||  newRenewalRecord.No_Recipients__c==true)){
                 newRenewalRecord.Status__c = 'Suppressed';	
                }
              else{
                 newRenewalRecord.Status__c = 'Ready to Send';	
              }
 
              if(newRenewalRecord.Payment_Warning__c == true){
                  newRenewalRecord.Broker_Warning__c = 'This risk has outstanding payments which will need to be paid in order for us to renew. Please provide evidence of this with the renewal submission.';
              }
 
              if((!coverageMap.isEmpty() && coverageMap.containsKey(newRenewalRecord.Latest_Bound_Quote__c) && coverageMap.get( newRenewalRecord.Latest_Bound_Quote__c).Form_Number__c == 'AQUW153'
                && coverageMap.get( newRenewalRecord.Latest_Bound_Quote__c).Coverage__r.Name == 'Run Off Exclusion' &&  coverageMap.get( newRenewalRecord.Latest_Bound_Quote__c).Option_Type__c == 'Date'
                && coverageMap.get(newRenewalRecord.Latest_Bound_Quote__c).Option_Value_Default__c != null && Date.valueOf(coverageMap.get(newRenewalRecord.Latest_Bound_Quote__c).Option_Value_Default__c) < policy.Renewal_Date__c.addmonths(-12))) {
                 newRenewalRecord.AQUW153_Template__c = true;
              }
              else{
                newRenewalRecord.AQUW153_Template__c = false;
              }
            
            }
            newRenewalRecord.Insured_Account__c = policy.Account__c;
            newRenewalRecord.Renewal_Warning_Reason__c = policy.Account__r.Renewal_Warning_Reason__c;
   
            newRenewalRecord.Policy__c = policy.Id;
            newRenewalRecord.recordTypeId = renewalRecordTypeId;

            renewalList.add(newRenewalRecord);
        }

        return renewalList;

    }
    // Vivek Raturi on 15-07-2022 For 'suppresed' and 'ready to Send' butoons.
    public static void updateRenewalRecords(List<String> RenewalIds , String RenewalStatus){
        List<Renewal__c> RenewalRecordUpdateList = new List<Renewal__c>();
        for(Integer i=0; i<RenewalIds.size(); i++){
            Renewal__c UpdRen = new Renewal__c();
            UpdRen.Id = RenewalIds[i];
            UpdRen.Status__c = RenewalStatus;
            RenewalRecordUpdateList.add(UpdRen);    
        }
        update RenewalRecordUpdateList;
    }

    public static void sendEmail(String renewalId,Boolean isTest){
        
        system.debug('renewalId'+renewalId);
        
        List<EmailTemplate> emailtemplaterecord  =  [select id,htmlvalue from EmailTemplate where DeveloperName='AQ_Renewal_Invite_Email_Template'];
        
        List<Renewal__c> renewalList  = [select id,Broker__r.Broker_Contact__r.AccountId,Renewal_Date__c from Renewal__c where id =: renewalId];
        
        Integer renewalMonth = renewalList[0].Renewal_Date__c.Month();
        Integer renewalYear = renewalList[0].Renewal_Date__c.Year();
        String brokerAccount = renewalList[0].Broker__r.Broker_Contact__r.AccountId;

        List<Contact> contactList = new List<Contact>();
        List<Renewal__c> renewalListUpdate = new List<Renewal__c>();
        Set<String> documentNames = new Set<String>();   
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>{};


        
        
        List<Renewal__c> renewalRecords =  [select id,Policy__c,Policy__r.Policy_Number__c,Broker__c,Status__c,Broker__r.Broker_Contact__c,Insured_Account__r.Name,Broker__r.Broker_Contact__r.AccountId,
                                            Documents_Required__c,Additional_Information__c,RICS__c,Broker_Warning__c,Assigned_Underwriter__r.Name,Assigned_Underwriter__r.Email,Policy__r.Expiration_Date__c from Renewal__c 
                                            where Status__c='Ready To Send' And CALENDAR_MONTH(Renewal_Date__c) =: renewalMonth And CALENDAR_YEAR(Renewal_Date__c) =: renewalYear And 
                                            Broker__r.Broker_Contact__r.AccountId =:brokerAccount];

        if(!isTest){
           for(Contact con : [select id,Email from contact where Role__c='Renewals' And AccountId =:brokerAccount AND Email != null]){
            contactList.add(con);
           }
        }

        for(Renewal__c renewal : renewalRecords){
            if(String.isNotBlank(renewal.Documents_Required__c)){
            List<String> docReqList = new List<String>();
            if(renewal.Documents_Required__c.contains(';')){
                docReqList = renewal.Documents_Required__c.split(';');
            }
            else{
                docReqList.add(renewal.Documents_Required__c); 
            }
            documentNames.addAll(docReqList);
            }
            renewalListUpdate.add(new Renewal__c(Id=renewal.Id,Status__c='1st Notice Sent',Notice_Sent__c='1'));
        }

       Map<String,List<ContentVersion>> contentVersionMap = new  Map<String,List<ContentVersion>>();
       if(documentNames.size()>0){
        contentVersionMap  = RenewalServiceHandler_AQ.fetchDocumentRelatedFiles(documentNames);
       }
        
        List<User> currentUserList = [select id,email from user where id=:UserInfo.getUserId()];                                  
        
        String htmlbody = '<table style="border:1px solid black;border-collapse: collapse">';
        htmlbody +=   '<tr><th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none; padding: 10px">Policy Reference</th>';
        htmlbody +=   '<th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none; padding: 10px">Insured</th>';
        htmlbody +=   '<th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none; padding: 10px">Expiry Date</th>';
        htmlbody +=   '<th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none; padding: 10px">Information Required</th>';
        htmlbody +=   '<th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none; padding: 10px">RICS Regulated Question</th>';
        htmlbody +=   '<th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none; padding: 10px">Broker Warning</th>';
        htmlbody +=   '<th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none; padding: 10px">Underwriter</th><tr/>';
        
        Set<String> docExistForBroker = new Set<String>();   
        for(Renewal__c renewal  : renewalRecords){
            
            String rics = renewal.RICS__c == false ? 'No' : 'Yes';
            String brokerWarning = String.isNotBlank(renewal.Broker_Warning__c) ? renewal.Broker_Warning__c : ''; 
            String assignedUnderWriter = String.isNotBlank(renewal.Assigned_Underwriter__r.Name) ? renewal.Assigned_Underwriter__r.Name : '';
            String assignedUnderWriterEmail = String.isNotBlank(renewal.Assigned_Underwriter__r.Email) ? renewal.Assigned_Underwriter__r.Email : '';
            String insuredAccount = String.isNotBlank(renewal.Insured_Account__r.Name) ? renewal.Insured_Account__r.Name : '';

            String documentReq;
            if(String.isNotBlank(renewal.Documents_Required__c)){

                if(renewal.Documents_Required__c.contains(';')){
                    for(String doc : renewal.Documents_Required__c.split(';')){
                        if(documentReq != null){
                            documentReq =  documentReq + doc +'<br/>';
                        }
                        else{
                            documentReq =    doc + '<br/>';
                        }
                     //  documentReq   = documentReq !=null ?  documentReq + doc +'<br/>' : doc + '<br/>';
                    }
                }
                else{
                    documentReq = renewal.Documents_Required__c !=null ?  renewal.Documents_Required__c : '';   
                }
            }
            else{
                documentReq = renewal.Documents_Required__c !=null ?  renewal.Documents_Required__c : '';
            }
            
            htmlbody += '<tr>';
            htmlbody += '<td style="border:1px solid black;border-collapse: collapse; padding: 10px">'+renewal.Policy__r.Policy_Number__c+'</td>';
            htmlbody += '<td style="border:1px solid black;border-collapse: collapse; padding: 10px">'+insuredAccount+'</td>';
            htmlbody += '<td style="border:1px solid black;border-collapse: collapse; padding: 10px">'+renewal.Policy__r.Expiration_Date__c.format()+'</td>';
            htmlbody += '<td style="border:1px solid black;border-collapse: collapse; padding: 10px">'+documentReq+'<br/><br/>';
            htmlbody +=  String.isNotBlank(renewal.Additional_Information__c) ? '<b>Additional Information:</b>'+' '+renewal.Additional_Information__c : '' + '</td>';
            htmlbody += '<td style="border:1px solid black;border-collapse: collapse; padding: 10px">'+rics+ '</td>';
            htmlbody += '<td style="border:1px solid black;border-collapse: collapse; padding: 10px">'+brokerWarning+'</td>';
            htmlbody += '<td style="border:1px solid black;border-collapse: collapse; padding: 10px">'+assignedUnderWriter+' (' +assignedUnderWriterEmail+ ')</td>';
            htmlbody +=  '</tr>';

            List<String> docRequirementList = new List<String>();
            if(String.isNotBlank(renewal.Documents_Required__c)){
                if(renewal.Documents_Required__c.contains(';')){
                   docRequirementList = renewal.Documents_Required__c.split(';');
                }
                else{
                   docRequirementList.add(renewal.Documents_Required__c); 
               }
            }

            for(String docName : docRequirementList){
                if(!contentVersionMap.isEmpty() && contentVersionMap.containsKey(docName)){
                 List<ContentVersion> documentList    =  contentVersionMap.get(docName);

                for(ContentVersion  document : documentList) {
                 if(!docExistForBroker.contains(document.Id)){
                   Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                   attachment.setBody(document.VersionData);
                   attachment.setFileName(document.Title + '.'+document.FileExtension);
                // attachment.setContentType(document.FileType);
                   attachments.add(attachment);
                   docExistForBroker.add(document.Id);
                 }
                }
               }
             }
            
            
        }    
        
        htmlbody += '</table>';
        
        if(renewalRecords.size()>0){
            
            String emailBody   = emailtemplaterecord[0].htmlvalue.replace('{tablecontent}',htmlbody);

            List<Messaging.SingleEmailMessage> listOfEmailContent = new List<Messaging.SingleEmailMessage>();

            if(isTest){
                 Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                 mail.setSubject('RENEWAL INVITE EMAIL TEMPLATE');
                 mail.setHtmlBody(emailBody);                      
                 mail.setToAddresses(new String[]{currentUserList[0].Email});
                 if(attachments.size()>0){
                    mail.setFileAttachments(attachments);
                  }
                 listOfEmailContent.add(mail);
            }


            if(!isTest){

              OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where DisplayName =: Label.AQ_Renewal_Sender];

              for(Contact con : contactList){
                  Messaging.SingleEmailMessage mails = new Messaging.SingleEmailMessage();
                  mails.setSubject('RENEWAL INVITE EMAIL TEMPLATE');
                  mails.setHtmlBody(emailBody);                      
                  if(owea.size() > 0 ) {
                    mails.setOrgWideEmailAddressId(owea.get(0).Id);
                  }
                  mails.setToAddresses(new String[]{con.Email});
                  mails.setTargetObjectId(con.Id);
                  if(attachments.size()>0){
                    mails.setFileAttachments(attachments);
                  }
                  listOfEmailContent.add(mails);
              }
           }
            if(!listOfEmailContent.isEmpty()){
                try{
                  system.debug('listOfEmailContent'+listOfEmailContent.size());
                  Messaging.sendEmail(listOfEmailContent);
                }
                catch(Exception ex){
                    system.debug('Exception ex'+ex);
                }
            }    
            
        }   

        if(!isTest && renewalListUpdate.size()>0){
            update renewalListUpdate;
        }
        
        

    }
    
     public static List<Contact> fetchContactsofRenewal(String renewalId){
        
        system.debug('renewalId'+renewalId);
        
        List<EmailTemplate> emailtemplaterecord  =  [select id,htmlvalue from EmailTemplate where DeveloperName='AQ_Renewal_Invite_Email_Template'];
        
        List<Renewal__c> renewalList  = [select id,Broker__r.Broker_Contact__r.AccountId,Renewal_Date__c from Renewal__c where id =: renewalId];
        
        Integer renewalMonth = renewalList[0].Renewal_Date__c.Month();
        Integer renewalYear = renewalList[0].Renewal_Date__c.Year();
        String brokerAccount = renewalList[0].Broker__r.Broker_Contact__r.AccountId;
                 
       return [Select Id,Name,Email,Role__c From Contact Where AccountId =: brokerAccount];
     }
    
    public static void updateRoleOnContact(List<Id> removeRoleonContact, List<Id> addRoleonContact, String renewalId){
		system.debug('renwal id :'+ renewalId);        
        List<Renewal__c> renewalList  = [select id,Broker__r.Broker_Contact__r.AccountId,Renewal_Date__c from Renewal__c where id =: renewalId];
        
        Integer renewalMonth = renewalList[0].Renewal_Date__c.Month();
        Integer renewalYear = renewalList[0].Renewal_Date__c.Year();
        String brokerAccount = renewalList[0].Broker__r.Broker_Contact__r.AccountId;
        
        
        List<Renewal__c> renewalRecords =  [select id,No_Recipients__c  from Renewal__c 
                                            where Status__c IN ('Suppressed', 'Ready to Send') 
                                            And CALENDAR_MONTH(Renewal_Date__c) =: renewalMonth And CALENDAR_YEAR(Renewal_Date__c) =: renewalYear
                                            And Broker__r.Broker_Contact__r.AccountId =:brokerAccount];
        
        List<Contact> UpdateConList = new List<Contact>();
        List<Renewal__c> UpdateRenewalRecords = new List<Renewal__c>();
         if(addRoleonContact.size()>0){
            List<Contact> ConList = [Select Id,Name,Email,Role__c From Contact Where AccountId =: brokerAccount and Id=:addRoleonContact];
            if(ConList.size()>0){
                for(Contact con : ConList){                    
                    Contact c = new Contact();
                    c.Role__c = String.isNotBlank(con.Role__c) ? con.Role__c + ';Renewals' : 'Renewals'; 
                    c.Id = con.Id;
                    UpdateConList.add(c);
                }
            }
            for(Renewal__c ren : renewalRecords){
                Renewal__c r = new Renewal__c();
                r.No_Recipients__c = false;
                r.Id = ren.Id;
                UpdateRenewalRecords.add(r);
            }
        }
        if(UpdateConList.size()>0){
            Update UpdateConList;
        }
        if(removeRoleonContact.size()>0){
            List<Contact> ConList = [Select Id,Name,Email,Role__c From Contact Where AccountId =: brokerAccount and Id=:removeRoleonContact];
            system.debug('con 2: '+ ConList);
            if(ConList.size()>0){
                for(Contact con : ConList){
                    List<String> RoleList = con.Role__c.split(';');
                    system.debug('RoleList : ' + RoleList );
                    Contact c = new Contact();
                    for(Integer i=0; i<RoleList.size(); i++){
                        if(RoleList[i].contains('Renewals')){
                           RoleList.remove(i); 
                        }
                    }
                    c.Role__c = String.join(RoleList, ';' );  
                    c.Id = con.Id;                            
                    UpdateConList.add(c);
                    system.debug('RoleList : ' + RoleList + ' ---> ' +  c.Role__c + ' //--> ' + c);
                }
            }
        } 
       
        
        if(UpdateConList.size()>0){
            Update UpdateConList;
        }
        if(UpdateRenewalRecords.size()>0){
            Update UpdateRenewalRecords;
        }
    }


    public static List<String> getBrokersContacts(String renewalId){

        List<String> contactNames = new List<String>();
        List<Renewal__c> renewalList   =  [select id,Broker__r.Broker_Contact__r.AccountId from Renewal__c where Id =:renewalId];

        for(Contact con : [select id,Name from contact where Role__c='Renewals' And AccountId =:renewalList[0].Broker__r.Broker_Contact__r.AccountId]){
            contactNames.add(con.Name);
        }
     
      return contactNames;
    }


    public class TabItem {
        @AuraEnabled public List<String> activeSections         {get; set;}
        @AuraEnabled public List<Section> sections              {get; set;}

        public TabItem() {
            activeSections = new List<String>();
            sections = new List<Section>();
        }
    }
    public class Section {
        @AuraEnabled
        public String id                                    {get;set;}
        @AuraEnabled
        public String mainSectionTitle                      {get;set;}
        @AuraEnabled
        public List<WrapperField> mainSectionFields         {get;set;}
        @AuraEnabled
        public String subSectionTitle                       {get;set;}
        @AuraEnabled
        public List<SubSectionChild> subSectionChilds       {get;set;}
        @AuraEnabled
        public String displayType                           {get;set;}
    
        public Section() {
            this.subSectionChilds = new List<SubSectionChild>();
        }

    }

    public class SubSectionChild {
        @AuraEnabled
        public String subSectionChildTitle                   {get;set;}
        @AuraEnabled
        public List<WrapperField> subSectionChildFields      {get;set;}
        public SubSectionChild() {}
    }
    
    public class WrapperField {
        @AuraEnabled
        public String sourceMainSectionTitle            {get;set;} //Added by GP       
        @AuraEnabled
        public String sourceObject                      {get;set;}
        @AuraEnabled
        public String sourceFieldLabel                  {get;set;}
        @AuraEnabled
        public String sourceFieldApi                    {get;set;}
        @AuraEnabled
        public String format                            {get;set;}
        @AuraEnabled
        public String value                             {get;set;}
        @AuraEnabled
        public String lookupTo                          {get;set;}
        @AuraEnabled
        public Boolean isDependencyPicklist              {get;set;}
        //tuan.d.nguyen added 24-Jun-2020
        @AuraEnabled
        public Boolean readOnly                          {get;set;}
        @AuraEnabled
        public Boolean required                          {get;set;}
        @AuraEnabled
        public Boolean isDeclinedStageField              {get;set;}
        public WrapperField() {
            this.required = false;
            this.isDeclinedStageField = false;
        }
    }

    public class AutoRenewalWrapper{
        @AuraEnabled public String  appName;
        @AuraEnabled public String  renewalRecordType;
    }

    public class FilteredWrapper{
        @AuraEnabled public Integer year{get;set;}
        @AuraEnabled public String month{get;set;}
        @AuraEnabled public String selectedBroker{get;set;}
        @AuraEnabled public String selectedInsured{get;set;}
        @AuraEnabled public String statusValue{get;set;}
        @AuraEnabled public Boolean renewalWarning{get;set;}
        @AuraEnabled public Boolean largeClaimWarning{get;set;}
        @AuraEnabled public Boolean hasClaimWarning{get;set;}
        @AuraEnabled public Boolean noRecepientWarning{get;set;}
        @AuraEnabled public Boolean docRequiredWarning{get;set;}
        @AuraEnabled public Boolean paymentWarning{get;set;}
        @AuraEnabled public Boolean brokerWarning{get;set;}
    }

}