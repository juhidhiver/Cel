public with sharing class QuoteOptionsPreBindTableController {
    public QuoteOptionsPreBindTableController() {

    }

    @AuraEnabled( cacheable=true )
    public static RelatedListWrapper fetchQuoteOptions(String quoteId){

        RelatedListWrapper objWrap = new RelatedListWrapper();
        List<RecordDetails> lstRecordDetailsWrapper = new List<RecordDetails>();
        String componentName = 'Quote Console';
        String recordTypeName = 'Aqueous';
        String mainSection = 'Quote Options';

        Quote objQuote = [Select Id, OpportunityId, layer__c from Quote where Id = :quoteId];
        
        String layerName = objQuote.layer__c;
        String product = 'Professional Indemnity';
        List<SectionSetting__c> sections =  [SELECT Is_Required__c,Profile_Name_for_Read_Only__c,Component__c, Main_Section__c,
                                                 Sub_Section__c,  Custom_Field_Type__c, DisplayType__c,Quote_Layer__c,
                                                 Format__c, Name, Order__c, Source_Field_API__c, Source_Field_Label__c,
                                                 Source_Object__c, Type_Of_Section__c, Criteria__c, Endorsement_Type__c
                                                 FROM  SectionSetting__c
                                                 WHERE Component__c = :componentName
                                                 AND Record_Type__c =: recordTypeName
                                                 AND Main_Section__c =: mainSection
                                                 AND Quote_Layer__c INCLUDES (:layerName)
                                                 AND Active__c = true AND Product__c INCLUDES (:product)
                                                 Order by  Order__c];
        
        Map<String,List<SectionSetting__c>> mapSections = buildMapSections(sections);
        List<SectionSetting__c> mainSects = new List<SectionSetting__c>();
        List<SectionSetting__c> subSects = new List<SectionSetting__c>();
        List<SectionSetting__c> fieldsSections = new List<SectionSetting__c>();
        if(mapSections.containsKey('MainSection'))	mainSects = mapSections.get('MainSection');
        if(mapSections.containsKey('SubSection'))subSects = mapSections.get('SubSection');
        if(mapSections.containsKey('Field')) fieldsSections = mapSections.get('Field');

        List<Quote_Option__c> listQuoteOptions = [Select Id, Limit__c, Minimum_Premium__c, Book_Premium__c, Technical_Premium__c
                                                    , Book_Premium_Annual__c, Minimum_Premium_Annual__c, Technical_Premium_Annual__c
                                                    , Actual_Premium_Annual__c, Broker_Netted_Down_Premium_Annual__c, Fee_Annual__c
                                                    , Technical_Premium_Discretion__c, Final_Discretion__c, Price_Adequacy__c
                                                    , Actual_Premium_Final__c, Broker_Netted_Down_Premium_Final__c, Fee_Final__c
                                                    , Bound__c, Selected__c, Option_Type__c, Final_Technical_Premium__c
                                                    , Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c, Override_Fee_Percent__c from Quote_Option__c 
                                                    where Selected__c = true AND Quote__c = :quoteId Order By Option_Type__c Asc, Limit__c Asc];

        objWrap.lstRecords = listQuoteOptions;
        for(Quote_Option__c objRecord: listQuoteOptions){
            if(objRecord.Bound__c){
                objWrap.idOfBoundQuoteOption = objRecord.Id;
            }
            RecordDetails objRecordDetailsWrapper = new RecordDetails();
            objRecordDetailsWrapper.fieldId = objRecord.Id;
            objRecordDetailsWrapper.optionType = objRecord.Option_Type__c;
            List<FieldConfigurations> lstFieldDetailsWrapper = new List<FieldConfigurations>();
            for(SectionSetting__c strField: fieldsSections){
                FieldConfigurations objFieldWrapper = new FieldConfigurations();
                objFieldWrapper.fieldLabel = strField.Source_Field_Label__c;
                objFieldWrapper.fieldAPIName = strField.Source_Field_API__c;
                objFieldWrapper.value = objRecord.get(objFieldWrapper.fieldAPIName) == null? '':objRecord.get(objFieldWrapper.fieldAPIName);
                objFieldWrapper.format = strField.Format__c;
                lstFieldDetailsWrapper.add(objFieldWrapper);
            }
            objRecordDetailsWrapper.fieldDetails = lstFieldDetailsWrapper;
            lstRecordDetailsWrapper.add(objRecordDetailsWrapper);
        }
        objWrap.numberOfRecords = lstRecordDetailsWrapper;
        return objWrap;


    }

    @AuraEnabled
    public static QuoteOptionsPreBindWrapper updateQuoteOptions(String quoteId, String quoteOptionId){
        System.debug('%%%%QuoteId === '+quoteId);
        System.debug('%%%%quoteOptionId === '+quoteOptionId);
        QuoteOptionsPreBindWrapper objWrapper = new QuoteOptionsPreBindWrapper();
        List<Quote> lstQuote = [Select Id, Actual_Premium__c, Broker_Netted_Down_Premium__c, Fee__c
                                , Status, Name, Rating_Status__c,Accept_Terror_Premium__c,Endorsement_Quote_Bound_Date__c
                                , Quote_Type__c,Non_Prorated_Quote_Premium__c, Parent_Quote__c, Product_Name__c, Opportunity.Id
                                , Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c
                                , Override_Fee_Percent__c, IPT_on_Broker_Netted_Down_Premium__c
                                , Total_Cost_to_Client__c, Technical_Fee__c, Technical_Premium__c from Quote where Id =: quoteId ];
        List<Quote_Option__c> lstQuoteOptions = [SELECT Id, Bound__c, Actual_Premium__c, Broker_Netted_Down_Premium__c
                                                , Fee__c, Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c
                                                , Override_Fee_Percent__c, IPT_on_Broker_Netted_Down_Premium__c,NonProrated_Actual_Premium__c,NonProRated_BNDP__c
                                                , Total_Cost_to_Client__c, Technical_Fee__c, Technical_Premium__c  FROM Quote_Option__c WHERE Quote__c = :quoteId];
        Quote_Option__c boundQuoteOption = new Quote_Option__c();
        if(!lstQuoteOptions.isEmpty()){
            for(Quote_Option__c objQuoteOption: lstQuoteOptions){
                if(objQuoteOption.Id == quoteOptionId){
                    objQuoteOption.Bound__c = true;
                    boundQuoteOption = objQuoteOption;
                }
                else{
                    objQuoteOption.Bound__c = false;
                }
            }
            update lstQuoteOptions;
        }
        objWrapper.quoteOptionsList = lstQuoteOptions;
        return objWrapper;
    }

    @AuraEnabled
    public static QuoteOptionsPreBindWrapper syncQuoteToMiddleware(String quoteId, String quoteOptionId){
        System.debug('%%%%QuoteId === '+quoteId);
        System.debug('%%%%quoteOptionId === '+quoteOptionId);
        QuoteOptionsPreBindWrapper objWrapper = new QuoteOptionsPreBindWrapper();
        List<Quote> lstQuote = [Select Id, Actual_Premium__c, Broker_Netted_Down_Premium__c, Fee__c
                                , Status, Name, Rating_Status__c,Accept_Terror_Premium__c,Endorsement_Quote_Bound_Date__c
                                , Quote_Type__c,Non_Prorated_Quote_Premium__c, Parent_Quote__c, Product_Name__c, Opportunity.Id
                                , Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c
                                , Override_Fee_Percent__c, IPT_on_Broker_Netted_Down_Premium__c
                                , Total_Cost_to_Client__c, Technical_Fee__c, Technical_Premium__c from Quote where Id =: quoteId ];
        Quote_Option__c boundQuoteOption = [SELECT Id, Bound__c, Actual_Premium__c, Broker_Netted_Down_Premium__c
                                                , Fee__c, Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c
                                                , Override_Fee_Percent__c, IPT_on_Broker_Netted_Down_Premium__c,NonProrated_Actual_Premium__c,NonProRated_BNDP__c
                                                , Total_Cost_to_Client__c, Technical_Fee__c, Technical_Premium__c  FROM Quote_Option__c WHERE Quote__c = :quoteId AND Bound__c = true];
        
        //Changing asynchronous sync call to synchronous
        API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration('Quote_Sync');

        try{
            HttpRequest req = new HttpRequest();
            HttpResponse res = new HttpResponse();
            req = getHttpRequest(apiSetting, lstQuote[0]);  
            Http h = new Http();
            res = h.send(req);
            objWrapper.jobIdOfSyncCall = res.getStatusCode();
            system.debug('QuoteSync --'+res);
            ApiUtil.logAPICall(req,res,'Sync Quote Status','QuoteOptionsPreBindTableController', apiSetting.HeaderParams__c, 'Outbound');
        }
        catch (Exception ex) {
            System.debug('Exception-->'+ex.getMessage());
        }

        if(boundQuoteOption != null && !lstQuote.isEmpty()){
            List<Factor_Summary__c> listFactorSummary = [Select Id, Code__c, Value__c from Factor_Summary__c where Quote_Option__c = :boundQuoteOption.Id AND Code__c = 'Rate'];
            for(Quote objQuote : lstQuote){
                objQuote.Actual_Premium__c = boundQuoteOption.Actual_Premium__c;
                objQuote.Broker_Netted_Down_Premium__c = boundQuoteOption.Broker_Netted_Down_Premium__c;
                objQuote.Fee__c = boundQuoteOption.Fee__c;
                objQuote.IPT_on_Broker_Netted_Down_Premium__c = boundQuoteOption.IPT_on_Broker_Netted_Down_Premium__c;
                objQuote.Total_Cost_to_Client__c = boundQuoteOption.Total_Cost_to_Client__c;
                objQuote.Technical_Fee__c = boundQuoteOption.Technical_Fee__c;
                objQuote.Technical_Premium__c = boundQuoteOption.Technical_Premium__c;
                objQuote.NonProrated_Actual_Premium__c = boundQuoteOption.NonProrated_Actual_Premium__c;
                objQuote.NonProRated_BNDP__c = boundQuoteOption.NonProRated_BNDP__c;
                if(objQuote.Quote_Type__c == 'New Business' || objQuote.Quote_Type__c == 'Renewal')
                {
                objQuote.Transaction_Premium_AQ__c = boundQuoteOption.NonProRated_BNDP__c;//mary 
                }
                if(!listFactorSummary.isEmpty()){
                    objQuote.Rate__c = Decimal.valueOf(listFactorSummary[0].Value__c);
                }
            }
            update lstQuote;
        }

        return objWrapper;
    }

    public static HttpRequest getHttpRequest(API_Configuration__mdt apiSetting, Quote updatedQuote) {
        HttpRequest req = Invsk_Callout.getHttpRequest(apiSetting);
        String quoteSyncJson = ApiUtil.getRatingJson(updatedQuote.Id);
        req.setBody(quoteSyncJson);        
        return req;
    }

    /*public static String saveFreeFormOptions(RecordDetails recDetailWrapper){

        try{

            String quoteOptionId = recDetailWrapper.fieldId;

            Quote_Option__c objQuoteOption = [Select Id, Limit__c, Minimum_Premium__c, Book_Premium__c, Technical_Premium__c
                                                , Actual_Premium_Annual__c, Broker_Netted_Down_Premium_Annual__c, Fee_Annual__c
                                                , Technical_Premium_Discretion__c, Final_Discretion__c, Price_Adequacy__c
                                                , Actual_Premium_Final__c, Broker_Netted_Down_Premium_Final__c, Fee_Final__c
                                                , Bound__c, Selected__c, Option_Type__c from Quote_Option__c 
                                                where Id = :quoteOptionId];
            
            for(FieldConfigurations objfield : recDetailWrapper.fieldDetails){
                objQuoteOption.get(objfield.fieldAPIName) = objfield.value;
            }

            update objQuoteOption;

            return 'success';
        }
        catch(exception e){
            return e;
        }

    }*/

    public static Map<String,List<SectionSetting__c>> buildMapSections(List<SectionSetting__c> sections ) {
        
        Map<String,List<SectionSetting__c>> results = new Map<String,List<SectionSetting__c>>();
        for(SectionSetting__c item : sections) {
            String key = item.Type_Of_Section__c;
            if(results.containsKey(key)){
                results.get(key).add(item);
            }else{
                results.put(key,new List<SectionSetting__c>{item});
            }
        }
        
        return results;
    }

    public class RelatedListWrapper {
        @AuraEnabled
        public List <SObject> lstRecords;
        @AuraEnabled
        public Integer recordCount;
        @AuraEnabled
        public List<RecordDetails> numberOfRecords;
        @AuraEnabled
        public Id idOfBoundQuoteOption;
    }

    public class RecordDetails {
        @AuraEnabled
        public String fieldId;
        @AuraEnabled
        public String optionType;
        @AuraEnabled
        public List<FieldConfigurations> fieldDetails;
    }
    
    public class FieldConfigurations {
        @AuraEnabled
        public String fieldLabel;
        @AuraEnabled
        public String fieldAPIName;
        @AuraEnabled
        public Object value;
        @AuraEnabled
        public String format;
    }

    public class QuoteOptionsPreBindWrapper {
        @AuraEnabled
        public List<Quote_Option__c> quoteOptionsList;
        @AuraEnabled
        public Integer jobIdOfSyncCall;
    }
}