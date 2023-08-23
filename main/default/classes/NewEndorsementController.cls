/*************************************************
* Class Name: NewEndorsementController 
* Author:
* Date: 
* Requirement/Project Name: 
* Requirement/Project Description: 
* Revision: Quan Tran /  23 April 2019 /
*************************************************/
public with sharing class NewEndorsementController {

	@AuraEnabled
	public static List<PicklistOption> initData(String contractId, String productName, String status, Date effectiveDate, Date cancelDate){
		/* 19 Aug 2019: Hoang worked on New Endorsement Items
		3628: The Surety product needs to be able to have Flat Cancellation, Mid Term Cancellation and Reinstatement Endorsements enabled only. Amendment and Extension Endorsements are not available for Surety product
		3629: The Installation product needs to have the Flat Cancellation, Mid Term Cancellation, Reinstatement and Amendment Endorsements enabled
		*/
		List<PicklistOption> lstResult = CommonUtil.getPicklistEndorsementOperations(productName);
		/* End of Hoang */
        system.debug('lstResult-->'+lstResult);

        /* commented by Jai
		if(status == 'Cancelled'  && (cancelDate != null && cancelDate > effectiveDate)) {
			lstResult.add(new PicklistOption('Reinstatement','Reinstatement') );
        }else {
            system.debug('lstResult-->'+lstResult);
			for(Integer i = 0; i < lstResult.size(); i++){
                if(lstResult[i].value == 'Reinstatement') lstResult.remove(i);
                if(lstResult[i].value == 'Correction') lstResult.remove(i);                
                //if(lstResult[i].value == 'Flat Cancellation (Ab - Initio)') lstResult.remove(i);
                //if(lstResult[i].value == 'Renewal') lstResult.remove(i); //Saumyak Bug#35953 05-01-2021
			}
		}commented by Jai */
        
        if( !lstResult.isEmpty() ){
		    lstResult[0].isSelected = true;
        }
		return lstResult;
	}

    /*************************************************
    * Method Name: getEndorsementChangeDescription 
    * Author: Vinay Vernekar
    * Date: Sep 20, 2021
    * Revision: v1.0
    * This method is called from Aura component to fetch all Endorsement change description values and mappings with endorsement type
    *************************************************/
    @AuraEnabled
    public static EndrosementChangeDescriptionWrapper getEndorsementChangeDescription(){
        List<PicklistOption> options = new List<PicklistOption>();
		for(Schema.PicklistEntry pickListVal : Quote.Endorsement_Change_Description__c.getDescribe().getPicklistValues())
			options.add(new PicklistOption(pickListVal.getValue(), pickListVal.getLabel()));

        Map<String, List<String>> defaultChangeDescriptionMap = new Map<String, List<String>>();
        for(Amendment_Configuration__mdt config : Amendment_Configuration__mdt.getAll().values()){
            if(String.isNotEmpty(config.Default_Change_Description__c))
                defaultChangeDescriptionMap.put(config.Amendment_Name__c, config.Default_Change_Description__c.contains(';') ? config.Default_Change_Description__c.split(';') : new list<String>{config.Default_Change_Description__c});
        }

        return new EndrosementChangeDescriptionWrapper(options, defaultChangeDescriptionMap);
    }

    /*************************************************
    * Method Name: getEndorsementOperationsHelpText 
    * Author: Jai Singh
    * Date: Sep 17, 2021
    * Revision: v1.0
    * This method is called from Aura component to get help text for Product Setting
    *************************************************/
    @AuraEnabled
    public static map<String,String> getEndorsementOperationsHelpText(list<String> endorsementOperations ){
        return CommonUtil.getEndorsementOperationsHelpText(endorsementOperations);
    }
	
	/*************************************************
	* Method Name: getQuotesEdorsementCancelPicklist
	* Author: Quan Tran
	* Date: 23-April-2019
	* Params:
	* Return: array 
	* Exceptions:
	** Revision: 
	*************************************************/
	@AuraEnabled
	public static List<PicklistOption> getQuotesEdorsementCancelPicklist(){
        List<PicklistOption> plOptions = new List<PicklistOption>();
        plOptions = CommonUtil.getPicklistValueFromObjectField('Policy__c', 'Cancellation_Reason__c');
        for (Integer i = plOptions.size() - 1; i >= 0 ; --i) {
            if (plOptions.get(i).value == 'Cancellation ab initio' || plOptions.get(i).value == 'Cancellation mid term') {
                plOptions.remove(i); 
            }
        }
		return plOptions;
	}
    
   /*************************************************
	* Product: Aqueous
	*************************************************/
    @AuraEnabled
    public static Boolean checkOpenQuotes(String contractId){
        Boolean isOpenQuote = false;
        List<Opportunity> oppList = [Select Id,Policy__c From Opportunity where Policy__c =: contractId ORDER By CreatedDate DESC Limit 1];
        if(!oppList.isEmpty()){
            List<Quote> quoteList = [select Id, status from Quote where OpportunityId =: oppList[0].Id
                                     AND Status NOT IN ('Bound','Closed')];
                if(quoteList.size() > 0) isOpenQuote = true;
        }
        return isOpenQuote;
    }
    
    @AuraEnabled
    public static List<PicklistOption> getEndorsementReasons(){
        return CommonUtil.getPicklistValueFromObjectField('Quote', 'Endorsement_Reason__c');
    }
    
    @AuraEnabled
    public static Boolean checkEndorsementDate(string contractId,string effectiveDate){
        Date effectDate = CommonUtil.parseDateFromString(effectiveDate);
        system.debug('effectDate-->'+effectDate);
        Boolean isNotInLimit = false;
        List<Quote> quoteList = [select Id, status,Effective_Date__c,Policy__c,ExpirationDate from Quote where Policy__c =: contractId
                                 AND Status IN ('Bound') ORDER By CreatedDate DESC limit 1];
        if(!quoteList.isEmpty()){
            system.debug('quoteList-->'+quoteList[0].ExpirationDate);
            if(effectDate > quoteList[0].ExpirationDate || effectDate < quoteList[0].Effective_Date__c)
            isNotInLimit = true;
        } 
        return isNotInLimit;
    }
	/*************************************************
	* Method Name: ratingQuoteEndorsement
	* Author: Quang Pham
	* Date: 26-Apr-2019
	* Params: quoteId Quote Id
	* Return: if error then return message error else return blank
	* Exceptions:
	* Revision: 
	*************************************************/
	@AuraEnabled
	public static String ratingQuoteEndorsement(String quoteId) {
		// return CloneQuoteHandler.ratingQuoteEndorsement(quoteId);
		ResultResponse result = RateController.getRatingFromCallOut(quoteId);
		return result.errors.isEmpty() ? '' : result.errors[0];
	}

	/*************************************************
	* Method Name: bindQuoteEndorsement
	* Author: Quang Pham
	* Date: 26-Apr-2019
	* Params: quoteId Quote Id
	* Return: if error then return message error else return blank
	* Exceptions:
	* Revision: 
	*************************************************/
	@AuraEnabled
	public static String bindQuoteEndorsement(String quoteId, String strCancelDate, String contractCancellationReason) {
		Date contractCancelDate = null;
        if(String.isNotBlank(strCancelDate)) contractCancelDate = Date.valueOf(strCancelDate);
		String result = BindQuoteController.bindQuoteForEndorsement(quoteId, contractCancelDate, contractCancellationReason);
		system.debug('result='+result);
		return result;
	}

	//Added by Ravi
	@AuraEnabled
    public static ResultWrapper showQuotes(String policyId, String effDate, String endorsementType){
        ResultWrapper result = new ResultWrapper();
        
       /* set<string> quoteTypes = new set<string>{'New Business','Full Amendment'};

        if(endorsementType == 'Coverage Cancel & Replace'){
            quoteTypes.add('Coverage Amendment');
        }*/
        
        List<Quote> quoteList = [select Id,Name,Quote_Type__c,CreatedDate,Status,Effective_Date__c,ExpirationDate from Quote where Policy__c =:policyId 
                                 AND Status =: 'Bound'
                                 ORDER BY Createddate];
        if(quoteList.isEmpty()){
            result.error = 'Cancel & Replace cannot be performed on this Policy';
            return result;
        }  

        result.quoteList = quoteList;
        return result;
    }
    //For Skipping the before Trigger lock method BUG 57767
    public static Boolean skip_Val = false;
	//Added by Ravi
	@AuraEnabled
    public static ResultWrapper coverageCancelProcess(string selectedId,Date createdDate,string effectiveDate,string policyId){
        
        ResultWrapper result = new ResultWrapper();
        //Modified by Vinayesh for CD: 64
        //Modified by Vinayesh updated requirement in CD-71
        //List<Quote> quoteList = [select Id,Status,CreatedDate from Quote where Policy__c =: policyId AND CreatedDate >= :createdDate AND Status != 'Correction' AND Status != 'Closed'];
        List<Quote> quoteList = [select Id,Status,CreatedDate from Quote 
                                   where Policy__c =: policyId AND CreatedDate >= :createdDate 
                                     AND Status = 'Bound'];
        List<Quote> quoteListToClose = [select Id,Status,CreatedDate from Quote 
                                          where Policy__c =: policyId AND CreatedDate >= :createdDate 
                                             AND Status != 'Correction' AND Status != 'Closed' AND
                                               Status != 'Cancelled' AND Status != 'Bound'];
        if(selectedId == null){
            result.error = 'Please select a Quote for Cancel and Replace';
            return result;
        }
        Set<Id> quoteIds = new Set<Id>();
      //  Set<Id> selectId = new Set<Id>{selectedId};
            if(!quoteList.isEmpty()){
                for(Quote quote: quoteList){ 
                    quote.status = 'Cancelled';
                    quoteIds.add(quote.Id);
                }
            }
            system.debug('quoteList 173 -->'+quoteList);

        try{
            ResultWrapper returnValues = CloneService.coverageCancelProcessCEL(quoteIds,selectedId,policyId);
            system.debug('returnValues-->'+returnValues);
            if(string.isNotBlank(returnValues.oppId)){
                for(Quote quote: quoteListToClose){ 
                    quote.status = 'Closed';
                    quoteList.add(quote);
                }
                skip_Val = true;
                Update quoteList;
                skip_Val = false;
                result.oppId = returnValues.oppId;
            }else{
                 result.error = returnValues.error;
            }
        }catch(DMLException ex){
            result.error = ex.getDmlMessage(0);
            system.debug('exception 123'+ex.getLineNumber()+ex.getMessage());
            return result;
        }catch(exception ex){
            system.debug('exception 23'+ex.getLineNumber()+ex.getMessage());
            result.error = ex.getMessage();
        }

       return result;
    }

	/*************************************************
	* Method Name: createNewEndorsement
	* Author: Quang Pham
	* Date: 
	* Params:
	* Return: array 
	* Exceptions:
	** Revision: Quan Tran /  23 April 2019 / save Effective_Date__c of Contract object
	*************************************************/
	@AuraEnabled
	public static ResultWrapper createNewEndorsement(String policyId, String effDate, String endorsementType, String cancelEndorsement, String endorsementChangeDesc, String otherParams) {
		ResultWrapper result = new ResultWrapper();

		try {
			Date effectiveDate = CommonUtil.parseDateFromString(effDate);
            
                
			String clonedQuoteId = '';
            String clonedoppId = '';
		
            List<Quote> quotes = [Select Id,Quote_Type__c,Status,Endorsement_Effective_Date__c,OpportunityId,
                                    Opportunity.QP_link__c, Product_Name__c
									From Quote	Where Policy__c = :policyId And (Status = 'Bound' OR Status = 'Bound Pending') 
									And (Endorsement_Effective_Date__c <= :effectiveDate OR Endorsement_Effective_Date__c = Null)
                                    Order By Endorsement_Effective_Date__c Desc NULLS LAST,
											Endorsement_Quote_Bound_Date__c Desc NULLS LAST, LastModifiedDate Desc NULLS LAST //17-Oct-2019: Hoang sort by Quote_Bound_Date & LastModifiedDate
									Limit 1];
            // 14-09-2019 Quang Pham Clone Quote Bound has latest Endorsement Effective Date End

			if (quotes.isEmpty()){
				result.error = Label.EFFECTIVE_DATE_NOT_EXIST;
				return result;
			}
            else if(!quotes.isEmpty() && quotes[0].Status == 'Bound Pending'){
                result.error = Label.Amendment_on_Bound_Pending_Error;
				return result;
            }

			Map<String, Object> fieldUpdateMap = new Map<String, Object>();
			fieldUpdateMap.put('Contract_Cancellation_Reason__c', cancelEndorsement);
			//End
            
            fieldUpdateMap.put('Quote_Type__c', endorsementType);
            fieldUpdateMap.put('Endorsement_Change_Description__c', endorsementChangeDesc);
			fieldUpdateMap.put('Endorsement_Effective_Date__c', effectiveDate);
            Map<String,Object> otherParamsMap = (Map<String,Object>)JSON.deserializeUntyped(otherParams);

            if(otherParamsMap.containsKey('expDate')){
                string expDate = (String)otherParamsMap.get('expDate');
                if( String.isNotBlank(expDate) ){
                    date expirationDate = CommonUtil.parseDateFromString(expDate);
                    fieldUpdateMap.put('ExpirationDate', expirationDate);
                }
            }
            if(otherParamsMap.containsKey('ERP_Duration')){
                string ERP_Duration = (String)otherParamsMap.get('ERP_Duration');
                if( String.isNotBlank(ERP_Duration) ){
                    fieldUpdateMap.put('ERP_Duration__c', ERP_Duration);
                }
            }                   
            if(otherParamsMap.containsKey('rateCharged')){
                string rateCharged = (String)otherParamsMap.get('rateCharged');
                if( String.isNotBlank(rateCharged) ){
                    rateCharged=rateCharged.replace('%','');
                    fieldUpdateMap.put('Rate_Charged__c', Decimal.valueOf(rateCharged));
                }
            }

            // added by Jai on 20-Oct-2021
            if(otherParamsMap.containsKey('brokerContact')){
                string brokerContact = (String)otherParamsMap.get('brokerContact');
                if( String.isNotBlank(brokerContact) && endorsementType == 'Broker on Record Change'){
                    Contact con = [Select AccountId, Email From Contact Where Id=:brokerContact];
                    fieldUpdateMap.put('Broker__c', brokerContact);
                    fieldUpdateMap.put('Broker_Email__c', con.Email);
                    fieldUpdateMap.put('Commission_percentage__c', 0);
                    fieldUpdateMap.put('Commission__c', 0.00);
                    fieldUpdateMap.put('BypassRating__c', true);
                    String baResult = handleBrockerAccounts(brokerContact, quotes[0].OpportunityId);
                    if(baResult!=''){
                        result.error = baResult;
                        result.cloneQuoteId = '';
                        return result;
                    }
                }
            }
			system.debug('11 fieldUpdateMap  -- '+fieldUpdateMap);
			ResultResponse response = new ResultResponse();
			response = CloneQuoteHandler.cloneQuoteWithChildren(String.valueOf(quotes[0].Id),fieldUpdateMap);
                       
			Quote quoteClone = (Quote)response.data;
			if(quoteClone != null){
				clonedQuoteId = quoteClone.Id;
                clonedoppId = quoteClone.OpportunityId;
				result.error = '';
			}
			result.oppId = clonedoppId;
			result.cloneQuoteId = clonedQuoteId;
			// result.oppId = quotes[0].OpportunityId;
			// result.cloneQuoteId = quotes[0].Id;
            //added by Jai
            if( endorsementType == 'Midterm Cancellation'){
                update new Policy__c( Id = policyId, Expiration_Date__c = effectiveDate );
            }

            if( String.isNotBlank(quotes[0].Opportunity.QP_link__c) ){
                if( endorsementType == 'Midterm Cancellation' || 
                    endorsementType == 'Extended Reporting Period (ERP)' || 
                    endorsementType == 'Policy Duration Change' ||
                    endorsementType == 'Broker on Record Change' //Jai modified for 53346
                    )
                {
                    if( quotes[0].Product_Name__c.contains(Label.Product_Name_for_PCC) ){
                        update new Quote_Process__c( Id = quotes[0].Opportunity.QP_link__c, Status__C = 'Quote Console' );
                    }else{
                        update new Quote_Process__c( Id = quotes[0].Opportunity.QP_link__c, Status__c = 'Compare & Rate Quotes' );
                    }
                }

                if( endorsementType == 'Amendment' ){
                    if( quotes[0].Product_Name__c.contains(Label.Product_Name_for_PCC) ){
                        update new Quote_Process__c( Id = quotes[0].Opportunity.QP_link__c, Status__c = 'Quote Console' );
                    }else{
                        update new Quote_Process__c( Id = quotes[0].Opportunity.QP_link__c, Status__c = 'Compare & Rate Quotes' );
                    }
                }
                if( endorsementType == 'Update Insured Name or Address' ){
                    if( quotes[0].Product_Name__c.contains(Label.Product_Name_for_PCC) ){
                        update new Quote_Process__c( Id = quotes[0].Opportunity.QP_link__c, Status__c = 'Submission Console' );
                    }else{
                        update new Quote_Process__c( Id = quotes[0].Opportunity.QP_link__c, Status__c = 'Insured Info' );
                    } 
                }
            }

			return result;

		} catch (Exception ex) {
			result.error = CommonUtil.getExceptionMessage(ex);
			result.cloneQuoteId = '';
		}

		return result;
	}

    /**********************************
    * Method Name: fetchPolicyExistQuts
	* Author: Jai
	* Date: 04-OCT-2021 
	* Params: policyId
	* Return: policy record with quotes
    ************************************/
    @AuraEnabled
    public static Policy__c fetchPolicyExistQuts(String policyId){
        return [SELECT Expiration_Date__c, (SELECT Status, Quote_Type__c, Endorsement_Effective_Date__c, CreatedDate FROM Quotes__r) 
                FROM Policy__c
                WHERE Id =: policyId];
    }
    
    /**********************************
    * Method Name: fetchErpProductInfo
	* Author: Jai
	* Date: 13-OCT-2021
	* Return: List of product setting
    ************************************/
    @AuraEnabled
    public static Map<String, String> fetchErpProductInfo(String productName, String effDate,String policyId){
        Map<String, string> result=new  Map<String, string>();
        
        Product_Setting__mdt mdt=[SELECT DeveloperName, MasterLabel, Active__c, Applicable_ERP_Duration__c, Applicable_Rate_Charged__c,Applicable_ERP_Duration_Rate_Charged__c 
                                  FROM Product_Setting__mdt 
                                  WHERE MasterLabel =: productName Limit 1];
        result.put('productInfo', JSON.serialize(mdt));
        if(String.isNotBlank(effDate) && String.isNotBlank(policyId))
        {
            Date effectiveDate = CommonUtil.parseDateFromString(effDate);
            List<Quote> quotes = [Select Id,Quote_Type__c,Status,Endorsement_Effective_Date__c,OpportunityId,ERP_Duration__c,Rate_Charged__c, 
                                  Opportunity.QP_link__c, Product_Name__c
                                  From Quote	Where Policy__c = :policyId And (Status = 'Bound' OR Status = 'Bound Pending') 
                                  And (Endorsement_Effective_Date__c <= :effectiveDate OR Endorsement_Effective_Date__c = Null)
                                  Order By Endorsement_Effective_Date__c Desc NULLS LAST,
                                  Endorsement_Quote_Bound_Date__c Desc NULLS LAST, LastModifiedDate Desc NULLS LAST //17-Oct-2019: Hoang sort by Quote_Bound_Date & LastModifiedDate
                                  Limit 1];
            // 14-09-2019 Quang Pham Clone Quote Bound has latest Endorsement Effective Date End
            
            if (!quotes.isEmpty()){
                result.put('selectedDuration', quotes[0].ERP_Duration__c);
                result.put('selectedRate', String.valueOf(quotes[0].Rate_Charged__c));
            }
        }
        
        
        return result;
    }

    /**********************************
    * Method Name: handleBrockerAccounts
	* Author: Jai
	* Date: 20-OCT-2021
	* Description: This method creates new brocker account and set old brocker accounts to non-primary.
    ************************************/
    @AuraEnabled
    public static string handleBrockerAccounts(String conId, String oppId){
        String result='';
        Savepoint sp = Database.setSavepoint();
        List<Broker_Account__c> baList = [SELECT IsPrimaryBroker__c,Broker_Contact__c
                                            FROM Broker_Account__c 
                                            WHERE Opportunity__c =: oppId
                                            AND Relationship_Type__c = 'Broker'];

        List<Broker_Account__c> baUpdateList = new List<Broker_Account__c>();
        List<Broker_Account__c> baUpdateList2 = new List<Broker_Account__c>();  
        Boolean newPrimaryAdded = false;                               
        if(baList.size()>0){
            for(Broker_Account__c ba : baList){
                if(ba.IsPrimaryBroker__c && ba.Broker_Contact__c != conId){
                    ba.IsPrimaryBroker__c = false;
                    ba.Bypass_New_Broker_Validation__c = true;
                    baUpdateList.add(ba);
                }
                else if(!ba.IsPrimaryBroker__c && ba.Broker_Contact__c == conId){
                    ba.IsPrimaryBroker__c = true;
                    ba.Bypass_New_Broker_Validation__c = true;
                    baUpdateList.add(ba);
                    newPrimaryAdded = true;
                }  
            }
            if(!baUpdateList.isEmpty()){
                TriggerHandler.bypass('BrokerAccountTriggerHandler');
                update baUpdateList;
                TriggerHandler.clearBypass('BrokerAccountTriggerHandler');
            }
        }
        if( !newPrimaryAdded ){
            Broker_Account__c newBa = new Broker_Account__c(
                Broker_Contact__c = conId,
                IsPrimaryBroker__c = true,
                Relationship_Type__c = 'Broker',
                Opportunity__c = oppId,
                Bypass_New_Broker_Validation__c = true
            );
            try{
                TriggerHandler.bypass('BrokerAccountTriggerBaseHandler');
                insert newBa;
                TriggerHandler.clearBypass('BrokerAccountTriggerBaseHandler');
                
            }
            catch(exception ex){
                Database.rollback(sp);
                result = CommonUtil.getExceptionMessage(ex);
            }
        }
        return result;
        
    }

    /*************************************************
	* Class Name: EndrosementChangeDescriptionWrapper
	* Author: Vinay Vernekar
	* To hold the all values of endorsement change description values and mapping of endorsement type and their default change description values
	*************************************************/

    public class EndrosementChangeDescriptionWrapper {
        @AuraEnabled public List<PicklistOption> allValues {get; set;}
        @AuraEnabled public Map<String, List<String>> defaultValuesByType {get; set;}
        public EndrosementChangeDescriptionWrapper(List<PicklistOption> allValues, Map<String, List<String>> defaultValuesByType){
            this.allValues = allValues;
            this.defaultValuesByType = defaultValuesByType;
        }
    }

	public class ResultWrapper {
        @AuraEnabled public String cloneQuoteId {get; set;}
        @AuraEnabled public String resultAccId {get; set;}
        @AuraEnabled public String oppId {get; set;}
        @AuraEnabled public String error {get; set;}
        @AuraEnabled public List<AccountWrapper> accList {get; set;}
        @AuraEnabled public List<Quote> quoteList {get; set;}
        @AuraEnabled public Boolean showAccounts {get; set;}
        public ResultWrapper() {
            cloneQuoteId = '';
            error = '';
            showAccounts = false;
            oppId = '';
            accList = new List <AccountWrapper>();
        }
    }
    Public class AccountWrapper {
        @AuraEnabled public String accId {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String dunsNumber {get; set;}
        @AuraEnabled public String billingStreet {get; set;}
        @AuraEnabled public String type {get; set;}
    }
    

}