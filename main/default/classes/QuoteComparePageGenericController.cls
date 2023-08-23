/*************************************************
* Author: Hai Bui
* Date: 12-July-2020
* Description:
* Revision:
*************************************************/
public class QuoteComparePageGenericController  {

public class QuoteResultItemWrapper{
public List<QuoteCompareItemWrapper> quoteCompareItems {get; set;}
public List<String> childIds {get; set;}
public List<String> childNames {get; set;}
public List<MainSection> mainSections {get;set;}
public QuoteResultItemWrapper(){
    this.quoteCompareItems = new List<QuoteCompareItemWrapper>();
    this.childIds = new List<String>();
    this.childNames = new List<String>();
    this.mainSections = new List<MainSection>();
}
public QuoteResultItemWrapper(List<QuoteCompareItemWrapper> quoteCompareItems,List<MainSection> mainSections ,List<String> childIds, List<String> childName){
    this.quoteCompareItems = quoteCompareItems;
    this.childIds = childIds;
    this.childNames = childName;
    this.mainSections = mainSections;
}
}

public List<MainSection> mainSections {get; set;}
public List<String> childIds {get; set;}
public List<String> childNames {get; set;}
public List<Quote> childQuotes {get; set;}
public Map<String,Quote> mapQuoteName {get;set;}
public List<QuoteCompareItemWrapper> quoteCompareItems {get; set;}
public static String CURRENT_USER_PROFILE {get;set;}
/*************************************************
* Author: Hai Bui
* Date: 12-July-2020
* Params: String submissionId, String componentName
* Return: QuoteResultItemWrapper
* Description:
* Revision:
*************************************************/
public  QuoteResultItemWrapper getQuoteResultItemWrapper( String submissionId, String componentName, String layerName){
try{
    this.initDataForWrapper( submissionId, componentName, layerName);
    QuoteResultItemWrapper result = new QuoteResultItemWrapper(this.quoteCompareItems,this.mainSections,this.childIds,this.childNames);
    System.debug('QuoteResultItemWrapper'+Json.serialize(result));
    return result;
}catch (Exception ex){
    System.debug('== Exception == : ' + ex.getMessage() + ex.getLineNumber());
    return new QuoteResultItemWrapper();
}
}

public  QuoteResultItemWrapper getQuoteResultItemWrapperQC( String submissionId, String componentName){
try{
    this.initDataForWrapperQC( submissionId, componentName);
    QuoteResultItemWrapper result = new QuoteResultItemWrapper(this.quoteCompareItems,this.mainSections,this.childIds,this.childNames);
    System.debug('QuoteResultItemWrapper'+Json.serialize(result));
    return result;
}catch (Exception ex){
    System.debug('== Exception == : ' + ex.getMessage() + ex.getLineNumber());
    return new QuoteResultItemWrapper();
}
}

public static List<Quote> getQuoteRecords(Opportunity submission, String layerName){
List<Quote> results = new List<Quote>();
if(submission.StageName == 'Closed Won') {
    if(submission.Product_Name__c == 'Professional Indemnity'){
        List<Quote> boundQuotes =  [SELECT Id, name, status, Rating_Status__c, Last_Quote_Version__c, Layer__c,Quote_Type__c,
                                    UW_Reason__c, Overall_UW_Codes__c
                                    FROM Quote
                                    WHERE OpportunityId = :submission.Id
                                    AND Status = 'Bound'
                                    AND Layer__c =: layerName
                                    ORDER BY Endorsement_Quote_Bound_Date__c];
        List<Quote> amendmentQuotes = [SELECT Id, name, status, Rating_Status__c, Last_Quote_Version__c, Layer__c,Quote_Type__c,
                                        UW_Reason__c, Overall_UW_Codes__c
                                        FROM Quote
                                        WHERE OpportunityId = :submission.Id
                                        AND Layer__c =: layerName
                                        AND  Status != 'Bound' AND Status != 'Closed'
                                        AND Status != 'Rejected' ORDER BY CreatedDate];
        if(!boundQuotes.isEmpty()) results.addAll(boundQuotes);
        results.addAll(amendmentQuotes);
    }else{
        List<Quote> boundQuotes =  [SELECT Id, name, status, Rating_Status__c, Last_Quote_Version__c, Layer__c,Quote_Type__c,
                                    UW_Reason__c, Overall_UW_Codes__c
                                    FROM Quote
                                    WHERE OpportunityId = :submission.Id
                                    AND Status = 'Bound'
                                    AND Layer__c =: layerName
                                    ORDER BY Endorsement_Quote_Bound_Date__c Desc LIMIT 1];
        //Added by Vinayesh to show In progress quotes first in quote compare page.
        List<Quote> inProgQuotes = [SELECT Id, name, status, Rating_Status__c, Last_Quote_Version__c, Layer__c,Quote_Type__c,
                                        UW_Reason__c, Overall_UW_Codes__c
                                        FROM Quote
                                        WHERE OpportunityId = :submission.Id
                                        AND Layer__c =: layerName
                                        AND  (Status = 'In Progress' OR Status = 'Rated' OR Status = 'Quoted') ORDER BY CreatedDate ASC]; //50316
        List<Quote> amendmentQuotes = [SELECT Id, name, status, Rating_Status__c, Last_Quote_Version__c, Layer__c,Quote_Type__c,
                                        UW_Reason__c, Overall_UW_Codes__c
                                        FROM Quote
                                        WHERE OpportunityId = :submission.Id
                                        AND Layer__c =: layerName
                                        AND  Status != 'Bound' AND Status != 'Closed'
                                        AND Status != 'Rejected' AND Status != 'In Progress'
                                        AND  Status != 'Rated' AND Status != 'Quoted' ORDER BY CreatedDate ASC]; //50316
        if(!boundQuotes.isEmpty()) results.add(boundQuotes[0]);
        if(!inProgQuotes.isEmpty()) results.addAll(inProgQuotes);
        results.addAll(amendmentQuotes);
    }
    
}
else{
    if(submission.Product_Name__c == 'MPL Standalone' ||  submission.Product_Name__c == 'Cyber Standalone'){
        results = [SELECT Id, name, status, Rating_Status__c, Last_Quote_Version__c, Quote_Type__c, Layer__c,
                    UW_Reason__c, Overall_UW_Codes__c
                    FROM Quote
                    WHERE OpportunityId = :submission.Id                       			
                    AND Status != 'Closed' AND Layer__c =: layerName
                    ORDER BY CreatedDate ASC]; //50316
    }else{
        results = [SELECT Id, name, status, Rating_Status__c, Last_Quote_Version__c, Quote_Type__c, Layer__c,
                    UW_Reason__c, Overall_UW_Codes__c
                    FROM Quote
                    WHERE OpportunityId = :submission.Id                       			
                    AND Status != 'Closed' AND Layer__c =: layerName
                    AND Status != 'Rejected'  ORDER BY CreatedDate];
    }
}
return results;
}

public static List<Quote> getQuoteRecordsQC(Opportunity submission){
List<Quote> results = new List<Quote>();
Boolean ischangeOrder = false;
if(submission.StageName == 'Closed Won') {
    if(submission.Product_Name__c == 'Professional Indemnity'){
        
        List<Quote> filterQuote = [SELECT Id, name, status, Rating_Status__c, Last_Quote_Version__c, Quote_Type__c, Layer__c,
                                    UW_Reason__c, Overall_UW_Codes__c, Is_Inception_Date_Edited__c
                                    FROM Quote
                                    WHERE OpportunityId = :submission.Id];
        
        for(Quote quote :filterQuote){
            if(quote.Quote_Type__c == 'Flat Cancellation' || quote.Quote_Type__c == 'Reinstatement'){
                ischangeOrder = true;
                break;
            }
        }
        if(ischangeOrder){
            results = [SELECT Id, name, status, Rating_Status__c, Last_Quote_Version__c, Quote_Type__c, Layer__c,
                        UW_Reason__c, Overall_UW_Codes__c, Is_Inception_Date_Edited__c
                        FROM Quote
                        WHERE OpportunityId = :submission.Id ORDER BY CreatedDate DESC];
        }else{
            List<Quote> boundQuotes =  [SELECT Id, name, status, Rating_Status__c, Last_Quote_Version__c, Layer__c,Quote_Type__c,
                                        UW_Reason__c, Overall_UW_Codes__c, Is_Inception_Date_Edited__c
                                        FROM Quote
                                        WHERE OpportunityId = :submission.Id
                                        AND Status = 'Bound' 
                                        ORDER BY Endorsement_Quote_Bound_Date__c];
            List<Quote> amendmentQuotes = [SELECT Id, name, status, Rating_Status__c, Last_Quote_Version__c, Layer__c,Quote_Type__c,
                                            UW_Reason__c, Overall_UW_Codes__c, Is_Inception_Date_Edited__c
                                            FROM Quote
                                            WHERE OpportunityId = :submission.Id
                                            AND  Status != 'Bound' ORDER BY CreatedDate];
            if(!amendmentQuotes.isEmpty()) results.addAll(amendmentQuotes);
            if(!boundQuotes.isEmpty()) results.addAll(boundQuotes);
            //results.addAll(amendmentQuotes);
        }
    }else{
        List<Quote> boundQuotes =  [SELECT Id, name, status, Rating_Status__c, Last_Quote_Version__c, Layer__c,Quote_Type__c,
                                    UW_Reason__c, Overall_UW_Codes__c
                                    FROM Quote
                                    WHERE OpportunityId = :submission.Id
                                    AND Status = 'Bound'
                                    ORDER BY Endorsement_Quote_Bound_Date__c Desc];
        List<Quote> amendmentQuotes = [SELECT Id, name, status, Rating_Status__c, Last_Quote_Version__c, Layer__c,Quote_Type__c,
                                        UW_Reason__c, Overall_UW_Codes__c
                                        FROM Quote
                                        WHERE OpportunityId = :submission.Id
                                        AND  Status != 'Bound'  ORDER BY CreatedDate desc];

        /* Added by Jai to make for MTA tasks*/
        if( !amendmentQuotes.isEmpty() ){
            if(submission.Product_Name__c == 'MPL Standalone' ||  submission.Product_Name__c == 'Cyber Standalone' ||  submission.Product_Name__c == 'Private Company Combo'){
                integer foundMTAQuoteIndex;
                for(integer i = 0; i<amendmentQuotes.size(); i++ ){
                    Quote q = amendmentQuotes[i];
                    if( q.Status == 'In Progress' || q.Status == 'Quoted' || q.Status == 'Rated'){
                        if( q.Quote_Type__c == 'Amendment' || q.Quote_Type__c == 'Update Insured Name or Address' || q.Quote_Type__c == 'Policy Duration Change'){
                            results.add(q);
                            foundMTAQuoteIndex = i;
                            break;
                        }
                    }
                }
                if( foundMTAQuoteIndex != null ){
                    amendmentQuotes.remove(foundMTAQuoteIndex);
                }
            }
        }
        /* Added by Jai to make for MTA tasks*/
        if(!amendmentQuotes.isEmpty()) {
            results.addAll(amendmentQuotes);
        }
        if(!boundQuotes.isEmpty()) {
            results.addAll(boundQuotes);
        }
        //results.addAll(amendmentQuotes);
    }
    
}
else{
    if(submission.Product_Name__c == 'MPL Standalone' ||  submission.Product_Name__c == 'Cyber Standalone'){
        results = [SELECT Id, name, status, Rating_Status__c, Last_Quote_Version__c, Quote_Type__c, Layer__c,
                    UW_Reason__c, Overall_UW_Codes__c
                    FROM Quote
                    WHERE OpportunityId = :submission.Id                       			
                    AND Status != 'Closed' 
                    ORDER BY CreatedDate];
    
    }
    else if(submission.Product_Name__c == 'Private Company Combo'){
        results = [SELECT Id, name, status, Rating_Status__c, Last_Quote_Version__c, Quote_Type__c, Layer__c,
                    UW_Reason__c, Overall_UW_Codes__c, Is_Inception_Date_Edited__c
                    FROM Quote
                    WHERE OpportunityId = :submission.Id ORDER BY LastModifiedDate Desc];
    }
    else{
            results = [SELECT Id, name, status, Rating_Status__c, Last_Quote_Version__c, Quote_Type__c, Layer__c,
                    UW_Reason__c, Overall_UW_Codes__c, Is_Inception_Date_Edited__c
                    FROM Quote
                    WHERE OpportunityId = :submission.Id ORDER BY status Desc, CreatedDate Desc];
    }
}
return results;
}
/*************************************************
* Author: Hai Bui
* Date: 12-July-2020
* Params: String submissionId, String quoteNumber
* Return: QuoteResultItemWrapper
* Description:createNewQuote
* Revision:
*************************************************/
public static Quote createNewQuote(String  submissionId, Integer quoteNumber,String quoteLayer) {
List<Opportunity> opps = [SELECT Id, Name, StageName, Policy__c,Main_Profession__c,Largest_Work_Type__c,Product_Name__c,
                            (Select Id, Layer__c,Limit_Basis__c From Quotes Where Layer__c =: quoteLayer),
                            // AND  Status != 'Bound' AND Status != 'Closed' AND Status != 'Rejected'
                            Expiration_Date__c,Effective_Date__c, Type FROM Opportunity WHERE Id =: submissionId LIMIT 1];
List<string> uwName = new List<string>{'Construction contract law advisors' ,'Legal Department - but not lawyer/solicitor firms' ,'Environmental consultants'};
List<UW_Analysis__c>  uwAnalysis = [SELECT Id, UW_Analysis_Name__c, Criteria__c, UW_Analysis_Template__c 
                                    FROM UW_Analysis__c 
                                    Where Submission__c =:submissionId AND UW_Analysis_Name__c IN :uwName ] ;                      

String productName = opps[0].Product_Name__c;
Integer quoteCount = opps[0].Quotes.size();
system.debug('quoteCount -- '+quoteCount);
Quote newQuote = new Quote();
newQuote.Layer__c = quoteLayer;        
newQuote.OpportunityId = opps[0].Id;
String mainProfession = opps[0].Main_Profession__c;
//String workType = opps[0].Largest_Work_Type__c;
if(productName == 'Professional Indemnity'){
    //newQuote.PI_Limit_of_Indemnity__c = 1000000;
    newQuote.Coverage_Product_Options__c = 'Professional Indemnity';
    if(String.isNotBlank(mainProfession)){
        if(quoteLayer == 'Primary'){
            if(mainProfession=='Accountants') newQuote.Policy_Wording__c = System.Label.PW_Accountants;//'AQUW/AC/04.19 Accountants';
            if(mainProfession=='Architects') newQuote.Policy_Wording__c = System.Label.PW_Architects_Engineers;//'AQUW/AE/04.19 Architects & Engineers';
            if(mainProfession=='Design & Construct') newQuote.Policy_Wording__c = System.Label.PW_Design_Construction;//'AQUW/DC/04.19 Design & Construction';
            if(mainProfession=='Engineers') newQuote.Policy_Wording__c = System.Label.PW_Architects_Engineers;//'AQUW/AE/04.19 Architects & Engineers';
            if(mainProfession=='Insurance Brokers') newQuote.Policy_Wording__c = System.Label.PW_Insurance_Brokers;//'AQUW/IB/04.19 Insurance Brokers';
            if(mainProfession=='IT Consultants') newQuote.Policy_Wording__c = System.Label.PW_Technology_IT;//'AQUW/IT/04.19 Technology & IT';
            if(mainProfession=='Miscellaneous') newQuote.Policy_Wording__c = System.Label.PW_Miscellaneous_Professions;//'AQUW/MP/04.19 Miscellaneous Professions';
            if(mainProfession=='Property Professionals') newQuote.Policy_Wording__c = System.Label.PW_Property_Professionals;//'AQUW/PP/04.19 Property Professionals';
            if(mainProfession=='Media Professionals') newQuote.Policy_Wording__c = System.Label.PW_Media_Marketing_Communication;//'AQUW/AD/04.19 Media, Marketing & Communication';
        }else{
            newQuote.Policy_Wording__c = System.Label.PW_Excess_Layer;//'AQUW/EX/04.19 Excess Layer';
        }
        if(mainProfession=='Miscellaneous' && uwAnalysis.size()>0 ) {
            newQuote.Limit_Basis__c = 'All Single Claims - Defence Costs included in the Limit of Indemnity';
        }
    }  
                
    }
    //newQuote.name = (quoteNumber != null)? opps[0].Name + ' ' + (quoteNumber + 1) : opps[0].Name + ' 1';
    newQuote.name = (quoteLayer == 'Primary')? opps[0].Name + ' Primary ' + (quoteCount + 1): opps[0].Name + ' Excess ' + (quoteCount + 1);
    newQuote.Status = 'In Progress';
    if(productName != 'Professional Indemnity'){
        newQuote.Policy__c = opps[0].Policy__c;
    }
    newQuote.CloseDate__c = Date.today().addDays(30); //Fix bug #7397 - Khanh - 3-Jul-2020
    newQuote.ExpirationDate = opps[0].Expiration_Date__c;//Jul 06-2020 Hoang move this field from QuoteTriggerHandler
    newQuote.Effective_Date__c = opps[0].Effective_Date__c;
    if(opps[0].Type == 'Renewal'){
        newQuote.Quote_Type__c = 'Renewal';
    }
    if (opps[0].StageName == 'Closed Won'){//1-Jun-2020 Hoang added
        if(productName != 'Professional Indemnity') newQuote.Quote_Type__c = 'Amendment';
    }
    return newQuote;
}

/*************************************************
* Author: Hai Bui
* Date: 12-July-2020
* Params: String submissionId, String componentName
* Return:
* Description: init main sections sub sections fields quote compare items etc...
* Revision:
*************************************************/
public  void initDataForWrapper( String submissionId, String componentName, String layerName){
    try{
        Opportunity submission = [SELECT Id, Name, StageName, Policy__c, Product_Name__c, RecordType.Name
                                    FROM Opportunity
                                    WHERE Id =: submissionId LIMIT 1];
        String product = submission.Product_Name__c;
        String recordTypeName = submission.RecordType.Name;
        if(product.contains('Standalone')) {
            product = product.split(' Standalone')[0];
        }
        System.debug('##product-->'+product);
        System.debug('##layerName-->'+layerName);
        List<SectionSetting__c> sections =  [SELECT Is_Required__c,Profile_Name_for_Read_Only__c,Component__c, Main_Section__c,
                                                Sub_Section__c,  Custom_Field_Type__c, DisplayType__c,Quote_Layer__c,
                                                Format__c, Name, Order__c, Source_Field_API__c, Source_Field_Label__c,
                                                Source_Object__c, Type_Of_Section__c, Criteria__c, Endorsement_Type__c
                                                FROM  SectionSetting__c
                                                WHERE Component__c = :componentName
                                                AND Record_Type__c =: recordTypeName 
                                                AND Quote_Layer__c INCLUDES (:layerName)
                                                AND Active__c = true AND Product__c INCLUDES (:product)
                                                Order by  Order__c];
        System.debug('##sections-->'+sections);
        System.debug('##sections size-->'+sections.size());
        List<Profile> lstProfile = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
        CURRENT_USER_PROFILE = lstProfile[0].Name;
        if(sections.isEmpty()) return ;
        List<Quote> quoteRecords = getQuoteRecords(submission, layerName);
        mapQuoteName = new Map<String,Quote>();
        this.childQuotes = quoteRecords;
        Boolean showEndorsementDate = false;
        for(Quote q : quoteRecords) {
            mapQuoteName.put(q.Id,q);
            this.childIds.add(q.Id);
            this.childNames.add(q.name);
            if(q.Quote_Type__c != 'New Business' && q.Quote_Type__c != 'Renewal'){
                showEndorsementDate = true;
            }
        }
        
        if(!showEndorsementDate){
            for (Integer i = (sections.size()-1) ; i>= 0 ; i--){
                if(sections[i].Source_Field_API__c == 'Endorsement_Effective_Date__c'){
                    sections.remove(i);
                    break;
                }
            }
        }
        

        Map<String,List<SectionSetting__c>> mapSections = buildMapSections(sections);
        List<SectionSetting__c> mainSects = new List<SectionSetting__c>();
        List<SectionSetting__c> subSects = new List<SectionSetting__c>();
        List<SectionSetting__c> fieldsSections = new List<SectionSetting__c>();
        
        if(mapSections.containsKey('MainSection'))	mainSects = mapSections.get('MainSection');
        if(mapSections.containsKey('SubSection'))subSects = mapSections.get('SubSection');
        if(mapSections.containsKey('Field')) fieldsSections = mapSections.get('Field');
        
        Map<String,MainSection> mapMainSections = new Map<String, MainSection>();
        Map<String,SubSection> mapSubSections = new Map<String, SubSection>();
        //Init Main Sections Wrapper
        for(SectionSetting__c item : mainSects){
            MainSection obj = new MainSection(item);
            mapMainSections.put(item.Main_Section__c,obj);
        }
        //Init Sub Sections Wrapper
        for(SectionSetting__c item : subSects){
            SubSection obj = new SubSection(item);
            mapSubSections.put(item.Sub_Section__c,obj);
        }
        //Build Map key is section source object + section.sub Section/section.main Section
        Map<String,List<SectionSetting__c>> mapFieldsSections = new Map<String, List<SectionSetting__c>>();
        for(SectionSetting__c item : fieldsSections){
            if(String.isNotBlank(item.Sub_Section__c) ) {//field belong to sub section
                String key = item.Source_Object__c + ';' + item.Sub_Section__c;
                if(mapFieldsSections.containsKey(key)){
                    mapFieldsSections.get(key).add(item);
                }else{
                    mapFieldsSections.put(key, new List<SectionSetting__c>{item});
                }
            }
            if(String.isBlank(item.Sub_Section__c)) {//field belong to main section
                String key = item.Source_Object__c + ';' + item.Main_Section__c;
                if(mapFieldsSections.containsKey(key)){
                    mapFieldsSections.get(key).add(item);
                }else{
                    mapFieldsSections.put(key, new List<SectionSetting__c>{item});
                }
            }
        }
        //Generate fields then Add fields for sub section and main section
        for(String key : mapFieldsSections.keySet()){
            String sectionName = key.split(';')[1];
            List<Field> listFields = generateListFields(mapFieldsSections.get(key));
            if(mapMainSections.containsKey(sectionName)){
                mapMainSections.get(sectionName).fields.addAll(listFields);
            }
            if(mapSubSections.containsKey(sectionName)){
                mapSubSections.get(sectionName).fields.addAll(listFields);
            }
        }
        // Add sub section for main section
        for(String key :mapSubSections.keySet()){
            String mainSectionName = mapSubSections.get(key).mainSectionName;
            mapMainSections.get(mainSectionName).subSections.add(mapSubSections.get(key));
        }
        this.mainSections = mapMainSections.values();
        this.quoteCompareItems = generateQuoteCompareItem(mapMainSections);
        System.debug('== Quote Compare Items == ' + JSON.serialize(this.quoteCompareItems));
    }catch (Exception ex){
        System.debug(ex.getCause() + ex.getStackTraceString() + ex.getMessage());
    }
}


public  void initDataForWrapperQC( String submissionId, String componentName){
    try{
        Opportunity submission = [SELECT Id, Name, StageName, Policy__c, Product_Name__c, RecordType.Name, Account.BillingStateCode
                                  FROM Opportunity
                                  WHERE Id =: submissionId LIMIT 1];
        String product = submission.Product_Name__c;
        String recordTypeName = submission.RecordType.Name;
        String stateCode = submission.Account.BillingStateCode;
        if(product.contains('Standalone')) {
            product = product.split(' Standalone')[0];
        }
        System.debug('##product-->'+product);
        //System.debug('##layerName-->'+layerName);
      
        List<SectionSetting__c> sections =  [SELECT Is_Required__c,Profile_Name_for_Read_Only__c,Component__c, Main_Section__c,
                                            Sub_Section__c,  Custom_Field_Type__c, DisplayType__c,Quote_Layer__c,
                                            Format__c, Name, Order__c, Source_Field_API__c, Source_Field_Label__c,
                                            Source_Object__c, Type_Of_Section__c, Criteria__c, Endorsement_Type__c, State__c
                                            FROM  SectionSetting__c
                                            WHERE Component__c = :componentName
                                            AND Record_Type__c =: recordTypeName 
                                            AND Active__c = true AND Product__c INCLUDES (:product)
                                            Order by  Order__c];
       
        List<SectionSetting__c> tempSections = new List<SectionSetting__c>();
        if(product == GlobalVariables.PROD_NAME_FOR_PCC){
            if(stateCode != null){
                for(SectionSetting__c sc : sections){
                    if(sc.State__c == null || sc.State__c == '' || sc.State__c == stateCode){
                        tempSections.add(sc);
                    }
                }
                sections = tempSections;
            }
        }

        System.debug('##sections-->'+sections);
        System.debug('##sections size-->'+sections.size());
        List<Profile> lstProfile = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
        CURRENT_USER_PROFILE = lstProfile[0].Name;
        if(sections.isEmpty()) return ;
        List<Quote> quoteRecords = getQuoteRecordsQC(submission);
        mapQuoteName = new Map<String,Quote>();
        this.childQuotes = quoteRecords;
        for(Quote q : quoteRecords) {
            mapQuoteName.put(q.Id,q);
            this.childIds.add(q.Id);
            this.childNames.add(q.name);
        }
        
        Map<String,List<SectionSetting__c>> mapSections = buildMapSections(sections);
        List<SectionSetting__c> mainSects = new List<SectionSetting__c>();
        List<SectionSetting__c> subSects = new List<SectionSetting__c>();
        List<SectionSetting__c> fieldsSections = new List<SectionSetting__c>();
        
        if(mapSections.containsKey('MainSection'))	mainSects = mapSections.get('MainSection');
        if(mapSections.containsKey('SubSection'))subSects = mapSections.get('SubSection');
        if(mapSections.containsKey('Field')) fieldsSections = mapSections.get('Field');
        System.debug('##fieldsSections'+fieldsSections);
        
        Map<String,MainSection> mapMainSections = new Map<String, MainSection>();
        Map<String,SubSection> mapSubSections = new Map<String, SubSection>();
        //Init Main Sections Wrapper
        for(SectionSetting__c item : mainSects){
            MainSection obj = new MainSection(item);
            mapMainSections.put(item.Main_Section__c,obj);
        }
        //Init Sub Sections Wrapper
        for(SectionSetting__c item : subSects){
            SubSection obj = new SubSection(item);
            mapSubSections.put(item.Sub_Section__c,obj);
        }
        //Build Map key is section source object + section.sub Section/section.main Section
        Map<String,List<SectionSetting__c>> mapFieldsSections = new Map<String, List<SectionSetting__c>>();
        for(SectionSetting__c item : fieldsSections){
            if(String.isNotBlank(item.Sub_Section__c) ) {//field belong to sub section
                String key = item.Source_Object__c + ';' + item.Sub_Section__c;
                if(mapFieldsSections.containsKey(key)){
                    mapFieldsSections.get(key).add(item);
                }else{
                    mapFieldsSections.put(key, new List<SectionSetting__c>{item});
                }
            }
            if(String.isBlank(item.Sub_Section__c)) {//field belong to main section
                String key = item.Source_Object__c + ';' + item.Main_Section__c;
                if(mapFieldsSections.containsKey(key)){
                    mapFieldsSections.get(key).add(item);
                }else{
                    mapFieldsSections.put(key, new List<SectionSetting__c>{item});
                }
            }
        }
        //Generate fields then Add fields for sub section and main section
        for(String key : mapFieldsSections.keySet()){
            System.debug('##key'+key);
            String sectionName = key.split(';')[1];
            List<Field> listFields = generateListFields(mapFieldsSections.get(key));
            if(mapMainSections.containsKey(sectionName)){
                mapMainSections.get(sectionName).fields.addAll(listFields);
            }
            if(mapSubSections.containsKey(sectionName)){
                mapSubSections.get(sectionName).fields.addAll(listFields);
            }
        }
        // Add sub section for main section
        for(String key :mapSubSections.keySet()){
            String mainSectionName = mapSubSections.get(key).mainSectionName;
            mapMainSections.get(mainSectionName).subSections.add(mapSubSections.get(key));
        }
        this.mainSections = mapMainSections.values();
        this.quoteCompareItems = generateQuoteCompareItem(mapMainSections);
        System.debug('== Quote Compare Items == ' + JSON.serialize(this.quoteCompareItems));
    }catch (Exception ex){
        System.debug(ex.getCause() + ex.getStackTraceString() + ex.getMessage());
    }
}

/*************************************************
* Author: Hai Bui
* Date: 12-July-2020
* Params: List<SectionSetting__c> sections
* Return: Map<String,List<SectionSetting__c>>
* Description: build map to get list main sections sub sections fields
* Revision:
*************************************************/
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

public QuoteComparePageGenericController() {
    this.mainSections = new List<MainSection>();
    this.childIds = new List<String>();
    this.childNames = new List<String>();
    this.childQuotes = new List<Quote>();
    this.quoteCompareItems = new List<QuoteCompareItemWrapper>();
}
/*************************************************
* Author: Hai Bui
* Date: 12-July-2020
* Params: List<SectionSetting__c> sections
* Return: Map<String,List<SectionSetting__c>>
* Description: generate list Field which use to create Quote compare items fields
* Revision:
*************************************************/
public  List<Field> generateListFields(List<SectionSetting__c> sections){
    if(sections.isEmpty()) return null;
    String sourceObject = sections[0].Source_Object__c;
    if(sourceObject == 'Quote'){
        return  generateListFieldsForQuote(sections);
    }else{
        return generateListFieldsForCoverageLineItemsAndRatingFactor(sections);
    }
}
/*************************************************
* Author: Hai Bui
* Date: 12-July-2020
* Params: List<SObject>
* Return: Map<String,List<SectionSetting__c>>
* Description: getRecordsForRatingModifierAndCoverageLineItem
* Revision:
*************************************************/
public  List<SObject> getRecordsForRatingModifierAndCoverageLineItem(List<SectionSetting__c> sections){
    try{
        if (sections.isEmpty()) return null;
        String sourceObject = sections[0].Source_Object__c;
        List<String> listCriteria = new List<String>();
        String condition = getCondition(sections[0]);
        String fields = getFields(sections[0]);
        /*for (SectionSetting__c item : sections) {
String criteria = getCriteria(item.Criteria__c);
if(String.isNotBlank(criteria)) listCriteria.add(' ( ' + criteria.removeStart('AND').removeEnd('Order by Coverage_Sort_Order__c') + ' ) ');
}
String criteriaString = String.isNotBlank(String.join(listCriteria, 'OR'))? + 'AND' + String.join(listCriteria, 'OR') :'';
String sortOrder = '';
if(sourceObject =='CoveragesLineItem__c') sortOrder = 'Order by Coverage_Sort_Order__c'; */
        //String queryString = 'SELECT ' + fields + ' FROM ' + sourceObject +condition +criteriaString + sortOrder;
        String criteria = getCriteria(sections[0].Criteria__c);
        String queryString = 'SELECT ' + fields + ' FROM ' + sourceObject +condition +criteria;
        System.debug('##==queryString== ' + queryString);
        return Database.query(queryString);
    }catch (Exception ex){
        return new List<SObject>();
    }
    
}
/*************************************************
* Author: Hai Bui
* Date: 12-July-2020
* Params: String input
* Return: String
* Description: format criteria
* Revision:
*************************************************/
public String getCriteria(String input) {
    String criteria = '';
    if(input != null)
        criteria = input;
    return criteria;
}

/*************************************************
* Author: Hai Bui
* Date: 12-July-2020
* Params: List<sObject> results, List<SectionSetting__c> sections
* Return: Map<String, List<sObject>>
* Description: createMapForListObject which use to create Field for Compare Quotes component
* Revision:
*************************************************/
public Map<String, List<sObject>> createMapForListObject(List<sObject> results, List<SectionSetting__c> sections) {
    
    Map<String, List<sObject>> mapResults = new Map<String, List<sObject>>();
    if(sections.isEmpty()) return  mapResults;
    String idGet = 'Quote__c';
    String sourceObject = sections[0].Source_Object__c;
    if(sourceObject  == 'Quote')
        idGet = 'Id';
    Map<String,SObject> mapObjects  = new Map<String,SObject>();
    Map<String,List<SObject>> mapNameSObject  = new Map<String,List<SObject>>();
    
    for(SObject item : results) {
        String key = getMapName(item, sections[0]);
        if(mapNameSObject.containsKey(key)){
            mapNameSObject.get(key).add(item);
        }else{
            mapNameSObject.put(key,new List<SObject>{item});
        }
        mapObjects.put(item.get('Quote__c') + '',item);
    }
    
    for(String key : mapNameSObject.keySet()){
        mapResults.put(key,mapNameSObject.get(key));
    }
    return mapResults;
}
/*************************************************
* Author: Hai Bui
* Date: 12-July-2020
* Params: sObject result, SectionSetting__c section
* Return: String
* Description: get Field Name for Compare Quotes component
* Revision:
*************************************************/
public String getMapName(sObject result, SectionSetting__c section) {
    String mapName = '';
    if(section.Source_Object__c == 'CoveragesLineItem__c')
        mapName = String.valueOf(result.getSObject('Limits_Deductibles__r').get('Name'));
    if (section.Source_Object__c == 'Rating_Modifier_Factor__c')
        mapName = String.valueOf(result.getSObject('Rating_Modifier__r').get('Name'));
    if(section.Source_Object__c == 'Quote')
        mapName = section.Source_Field_Label__c;
    
    return mapName;
}
/*************************************************
* Author: Hai Bui
* Date: 12-July-2020
* Params: List<SectionSetting__c> sections
* Return: List<Field >
* Description: generateListFieldsForCoverageLineItemsAndRatingFactor
* Revision:
*************************************************/
public List<Field > generateListFieldsForCoverageLineItemsAndRatingFactor(List<SectionSetting__c> sections) {
    List<Field > lstField = new List<Field>();
    try {
        List<sObject> results = getRecordsForRatingModifierAndCoverageLineItem(sections);
        System.debug('##results'+results);
        System.debug('##results size'+results.size());
        String fields = getFields(sections[0]);
        Map<String, List<sObject>> mapListObject = createMapForListObjectSort(results, sections);
        for(SectionSetting__c section : sections){
            for(String key : mapListObject.keySet()) {
                System.debug('##mapListObject key:'+key);
                System.debug('##mapListObject key size:'+mapListObject.get(key).size());
                //key is section name
                String fieldGet = 'Quote__c';
                List<String> values = new List<String>();
                List<String> ids = new List<String>();
                List<String> listFormats = new List<String>();
                List<String> pickListOptions = new List<String>();
                String propCondition = '';
                String fieldLabel = key;
                String min, max;
                String quoteId = '';
                for(sObject res : mapListObject.get(key)) {
                    System.debug('##res :'+res);
                    quoteId = res.get(fieldGet) + '';
                    String value = CommonUtil.convertToString(String.valueOf(res.get(section.Source_Field_API__c)));
                    String id = CommonUtil.convertToString(String.valueOf(res.get('Id')));
                    String format = section.Format__c;
                    String pickList = '';
                    if(section.Source_Object__c == 'CoveragesLineItem__c') {
                        format = String.valueOf(res.get('Option_Type__c'));
                        pickList = String.valueOf(res.get('Option_Picklist__c'));
                        //min = String.valueOf(res.get('Min_amt__c'));
                        //max = String.valueOf(res.get('Max_amt__c'));
                    }
                    if(section.Source_Object__c == 'Rating_Modifier_Factor__c') {
                        System.debug('Object' + res.getSObject('Rating_Modifier__r'));
                        if(res.getSObject('Rating_Modifier__r') != null) {
                            //if(String.isBlank(min))
                            min = String.valueOf(res.getSObject('Rating_Modifier__r').get('Factor_Min__c'));
                            //if(String.isBlank(max))
                            max = String.valueOf(res.getSObject('Rating_Modifier__r').get('Factor_Max__c'));
                        }
                    }
                    System.debug('Min' + min);
                    System.debug('Max' + max);
                    if(format == null) format = 'Text';
                    if(pickList == null) pickList = '';
                    if(min == null) min = '';
                    if(max == null) max = '';
                    if(propCondition == '') propCondition = createFieldPropertyCondition(res, section);
                    values.add(value);
                    ids.add(id);
                    listFormats.add(format);
                    pickListOptions.add(pickList);
                }
                Field newField = new Field(section);
                newField.sourceFieldLabel = fieldLabel;
                newField.format = listFormats;
                newField.picklistOption = pickListOptions;
                newField.min = min;
                newField.max = max;
                FieldProperty fieldProp = new FieldProperty(ids, values, propCondition,fields );
                newField.setProperty(fieldProp);
                lstField.add(newField);
            }
            system.debug('## CLI lstField -- '+lstField);
            return lstField;
        }
        
    } catch(Exception ex) {
        System.debug('== Exception== : ' + ex.getMessage() + ' - ' + ex.getLineNumber());
    }
    return lstField;
}
/*************************************************
* Author: Hai Bui
* Date: 12-July-2020
* Params: sObject result, SectionSetting__c section
* Return: String
* Description: createFieldPropertyCondition
* Revision:
*************************************************/
public String createFieldPropertyCondition(sObject result, SectionSetting__c section) {
    String propCondition = '';
    if(section.Source_Object__c == 'CoveragesLineItem__c' && result.getSObject('Limits_Deductibles__r') != null) {
        propCondition =  'AND Limits_Deductibles__r.Name = \'' + String.valueOf(result.getSObject('Limits_Deductibles__r').get('Name')) + '\'';
        if(result.getSObject('Coverage__r') != null)
            propCondition += ' AND Coverage__r.Name = \'' + String.valueOf(result.getSObject('Coverage__r').get('Name')) + '\'';
        if(result.getSObject('Sub_Coverage__r') != null)
            propCondition += ' AND Sub_Coverage__r.Name = \'' + String.valueOf(result.getSObject('Sub_Coverage__r').get('Name')) + '\'';
    }
    if (section.Source_Object__c == 'Rating_Modifier_Factor__c' && result.getSObject('Rating_Modifier__r') != null)
        propCondition = ' AND Rating_Modifier__r.Rating_Modifier_Code__c = \'' + String.valueOf(result.getSObject('Rating_Modifier__r').get('Rating_Modifier_Code__c')) + '\'';
    
    return propCondition;
}
/*************************************************
* Author: Hai Bui
* Date: 12-July-2020
* Params: List<SectionSetting__c> sections
* Return: Field
* Description: generateListFieldsForQuote
* Revision:
*************************************************/
public List<Field > generateListFieldsForQuote(List<SectionSetting__c> sections) {
    List<Field > listFields = new List<Field>();
    try {
        if(sections.isEmpty()) return null;
        String condition = getCondition(sections[0]);
        Map<String,List<SObject>> mapResult  = getRecords(sections);//quote record
        List<SObject> results = mapResult.values()[0];
        String fieldGet = 'Id';
        Map<String, SObject> mapQuoteIdResult = new Map<String, SObject>();
        for (SObject item : results) {
            mapQuoteIdResult.put(item.get(fieldGet) + '', item);
        }
        System.debug('mapQuoteIdResult-->'+mapQuoteIdResult);
        for (SectionSetting__c section : sections) {
            List<String> values = new List<String>();
            List<String> fieldIds = new List<String>();
            List<String> listFormat = new List<String>();
            List<String> pickListOption = new List<String>();
            
            List<PicklistOption> picklistValues = new List<PicklistOption>();
            picklistValues = CommonUtil.getPicklistValueFromObjectField(section.Source_Object__c, section.Source_Field_API__c);
            String picklistValuesSemiColSeparated = '';
            for(PicklistOption picklist : picklistValues){
                picklistValuesSemiColSeparated += picklist.value+';';
            }
            picklistValuesSemiColSeparated = picklistValuesSemiColSeparated.removeEnd(';');                
            listFormat.add(section.Format__c);					
            for(String quoteId : this.childIds){
                String value  = String.isNotBlank(mapQuoteIdResult.get(quoteId).get(section.Source_Field_API__c) + '')
                    ? mapQuoteIdResult.get(quoteId).get(section.Source_Field_API__c) + '' : '';
                if(value == null || value == 'null') value = '';
                values.add(value);
                String fieldId =String.isNotBlank(String.valueOf(mapQuoteIdResult.get(quoteId).get('Id')))
                    ? String.valueOf(mapQuoteIdResult.get(quoteId).get('Id')) : '';
                fieldIds.add(fieldId);
                
                String fieldLayer  = String.isNotBlank(String.valueOf(mapQuoteIdResult.get(quoteId).get('Layer__c')))
                    ? String.valueOf(mapQuoteIdResult.get(quoteId).get('Layer__c')) : '';     
                System.debug('fieldLayer-->'+fieldLayer);
                /*if(section.Source_Field_API__c == 'Policy_Wording__c'){
                    if(fieldLayer == 'Primary') picklistValuesSemiColSeparated = picklistValuesSemiColSeparated.replace(';'+System.Label.PW_Excess_Layer,'');//(';AQUW/EX/04.19 Excess Layer','');                                                
                    if(fieldLayer == 'Excess')	picklistValuesSemiColSeparated = System.Label.PW_Excess_Layer;//'AQUW/EX/04.19 Excess Layer'; 	   
                } */
                
            }
            System.debug('picklistValuesSemiColSeparated-->'+picklistValuesSemiColSeparated);
            pickListOption.add(picklistValuesSemiColSeparated);
            List<String> temp = new List<String>(mapResult.keySet());
            String fieldsRequire = temp[0];
            FieldProperty fieldProp = getFieldProperty(values, fieldIds, condition,fieldsRequire);
            Field field = getField(section, listFormat, pickListOption, fieldProp);
            listFields.add(field);
        }
        
    } catch (Exception ex) {
        System.debug('Exception ' + ex.getLineNumber() + ' ' + ex.getMessage() +ex.getStackTraceString() +ex.getCause());
    }
    System.debug('==listFieldsQuote== : '+ JSON.serialize(listFields));
    return listFields;
}
/*************************************************
* Author: Hai Bui
* Date: 12-July-2020
* Params: SectionSetting__c section, List<String> formats
* Params: List<String> pickListOptions,   FieldProperty fieldProperty
* Return: Field
* Description: getField
* Revision:
*************************************************/
public  Field getField(SectionSetting__c section,
                        List<String> formats,
                        List<String> pickListOptions,
                        FieldProperty fieldProperty) {
                            Field result = new Field(section);
                            result.format = formats;
                            result.picklistOption = pickListOptions;
                            result.setProperty(fieldProperty);
                            return result;
                        }
/*************************************************
* Author: Hai Bui
* Date: 12-July-2020
* Params:   List<String> fieldValues,  List<String> fieldIds
* Params:   String condition, String fields
* Return: FieldProperty
* Description: getFieldProperty
* Revision:
*************************************************/
public static FieldProperty getFieldProperty(List<String> fieldValues,
                                                List<String> fieldIds,
                                                String condition,
                                                String fields) {
                                                    FieldProperty fieldProp =
                                                        new FieldProperty(fieldIds, fieldValues, condition, fields);
                                                    return fieldProp;
                                                }
/*************************************************
* Author: Hai Bui
* Date: 12-July-2020
* Params: List<SectionSetting__c> sections
* Return: List<SObject>
* Description: getRecords
* Revision:
*************************************************/
public Map<String,List<SObject>> getRecords(List<SectionSetting__c> sections){
    Map<String,List<SObject>> mapResult = new Map<String, List<SObject>>();
    try{
        if (sections.isEmpty()) return null;
        String sourceObject = sections[0].Source_Object__c;
        List<String> listCondition = new List<String>();
        String condition = getCondition(sections[0]);
        List<String> fields = new List<String>();
        fields.add('Id');
        fields.add('Layer__c');
        for (SectionSetting__c item : sections) {
            String criteria = getCriteria(item.Criteria__c);
            if(String.isNotBlank(criteria)) listCondition.add(' ( ' + criteria + ' ) ');
            if(item.Source_Object__c == 'Quote') {
                if(!fields.contains(item.Source_Field_API__c)) fields.add(item.Source_Field_API__c);
            }
        }
        String queryString = 'SELECT ' + String.join(fields,',') + ' FROM ' + sourceObject +condition+ String.join(listCondition, 'OR');
        mapResult.put(String.join(fields,','),Database.query(queryString));
        return mapResult;
    }catch (Exception ex){
        return mapResult;
    }
    
}
/*************************************************
* Author: Hai Bui
* Date: 12-July-2020
* Params: Map<String,MainSection> mapMainSections
* Return: List<QuoteCompareItemWrapper>
* Description: Generate Quote Compare item which use on Quote Compare Page
* Revision:
*************************************************/
public List<QuoteCompareItemWrapper> generateQuoteCompareItem(Map<String,MainSection> mapMainSections) {
    List<QuoteCompareItemWrapper> listCompareItem = new List<QuoteCompareItemWrapper>();
    for(Integer i = 0 ; i<=this.childIds.size() - 1 ; i++){
        String quoteId = childIds[i];
        QuoteCompareItemWrapper item = new QuoteCompareItemWrapper();
        item.quoteId  = quoteId;
        item.quoteName = mapQuoteName.get(quoteId).Name;
        item.quoteStatus = mapQuoteName.get(quoteId).Status;
        item.quoteRatingStatus =  mapQuoteName.get(quoteId).Rating_Status__c;
        item.quoteLayer = mapQuoteName.get(quoteId).Layer__c;
        item.quoteType = mapQuoteName.get(quoteId).Quote_Type__c;
        //Added by Jai 27-Oct-2021
        item.quoteRecord = mapQuoteName.get(quoteId);
        
        List<Quote_Version__c> quoteVersions = [SELECT Id, Quote__c, Name,
                                                (SELECT Id, Source_Object__c, Source_Field_API__c,
                                                    Value__c, Quote_Version__c, Object_Id__c , Label__c
                                                    FROM Quote_Version_Items__r	)
                                                FROM Quote_Version__c
                                                WHERE Quote__c =: quoteId
                                                ORDER BY Name];
        if(!quoteVersions.isEmpty()){
            item.quoteVersions = quoteVersions;
        }
        for(String key : mapMainSections.keySet()){
            MainSection mainSec = mapMainSections.get(key);
            QuoteCompareItemField mainTitle = new QuoteCompareItemField();//create title row
            item.quoteFields.add(mainTitle);
            item.quoteFields.addAll(generateCompareItemField(mainSec.fields,i,item.quoteLayer));
            if(mainSec!= null && !mainSec.subSections.isEmpty()){
                for(SubSection sub : mainSec.subSections){
                    QuoteCompareItemField subTitle = new QuoteCompareItemField();//create title row
                    item.quoteFields.add(subTitle);
                    item.quoteFields.addAll(generateCompareItemField(sub.fields,i,item.quoteLayer));
                }
            }
        }
        listCompareItem.add(item);
    }
    return listCompareItem;
}
/*************************************************
* Author: Hai Bui
* Date: 12-July-2020
* Params: List<Field> fields,Integer index
* Return: List<QuoteCompareItemField>
* Description: Generate generateCompareItemField  which use on Quote Compare Page
* Revision:
*************************************************/
public List<QuoteCompareItemField> generateCompareItemField(List<Field> fields,Integer index,String fieldLayer) {
    List<QuoteCompareItemField> results = new List<QuoteCompareItemField>();
    System.debug('fields-->'+fields);
    for(Field field : fields){
        QuoteCompareItemField itemField = new QuoteCompareItemField();
        itemField.readOnly = field.readOnly;
        itemField.sourceFieldAPI = field.sourceFieldAPI;
        itemField.endorsementType = field.endorsementType;
        itemField.sourceObject = field.sourceObject;
        itemField.displayType = field.displayType;
        itemField.fieldCondition = field.fieldCondition;
        itemField.fieldRequire = field.fieldRequire;
        itemField.fieldName = field.sourceFieldLabel;
        itemField.value = (field.values[index] == null || field.values[index] =='null') ? '' : field.values[index];
        itemField.fieldId = field.fieldIds[index];//root
        itemField.format = field.format[0];
        String picklistValuesSemiColSeparated = field.picklistOption[0];
        if(field.sourceFieldAPI == 'Policy_Wording__c'){
            if(fieldLayer == 'Primary') picklistValuesSemiColSeparated = picklistValuesSemiColSeparated.replace(';'+System.Label.PW_Excess_Layer,'');//(';AQUW/EX/04.19 Excess Layer','');                                                
            if(fieldLayer == 'Excess')	picklistValuesSemiColSeparated = System.Label.PW_Excess_Layer;//'AQUW/EX/04.19 Excess Layer'; 	   
        }
        itemField.picklistOption = picklistValuesSemiColSeparated;
        itemField.isField = true;
        itemField.min = field.min;
        itemField.max = field.max;
        itemField.mainSection = field.mainSection;
        itemField.quoteLayer = field.quoteLayer;
        results.add(itemField);
    }
    return results;
}
/*************************************************
* Author: Hai Bui
* Date: 12-July-2020
* Params: SectionSetting__c section
* Return: String
* Description: getFields to query records
* Revision:
*************************************************/
public String getFields(SectionSetting__c section) {
    String fields = '';
    List<String> listFields = new List<String>();
    listFields.add('Id');
    listFields.add(section.Source_Field_API__c);
    if(section.Source_Object__c == 'CoveragesLineItem__c') {
        listFields.add('Quote__c');
        listFields.add('Option_Type__c');
        listFields.add('Option_Picklist__c');
        listFields.add('Limits_Deductibles__r.Name');
        listFields.add('Coverage__r.name');
        listFields.add('Sub_Coverage__r.name');
        listFields.add('Min_amt__c');
        listFields.add('Max_amt__c');
    }
    if(section.Source_Object__c == 'Rating_Modifier_Factor__c') {
        listFields.add('Quote__c');
        listFields.add('Rating_Modifier__r.Name');
        listFields.add('Rating_Modifier__r.Rating_Modifier_Code__c');
        listFields.add('Rating_Modifier__r.Format__c');
        listFields.add('Rating_Modifier__r.Picklist_Values__c');
        listFields.add('Rating_Modifier__r.Factor_Max__c');
        listFields.add('Rating_Modifier__r.Factor_Min__c');
    }
    if(section.Source_Object__c == 'Quote_Option__c') {
        listFields.add('Quote__c');
        listFields.add('Name');
        listFields.add('Minimum_Premium__c');
        listFields.add('Book_Premium__c');
        listFields.add('Technical_Premium__c');
        listFields.add('Actual_Premium_Annual__c');
        listFields.add('Broker_Netted_Down_Premium_Annual__c');
        listFields.add('Fee_Annual__c');
        listFields.add('Technical_Premium_Discretion__c');
        listFields.add('Final_Discretion__c');
        listFields.add('Price_Adequacy__c');
        listFields.add('Actual_Premium_Final__c');
        listFields.add('Broker_Netted_Down_Premium_Final__c');
        listFields.add('Fee_Final__c');
        listFields.add('Bound__c');
        listFields.add('Selected__c');
        listFields.add('Azure_ID__c');
    }
    fields = String.join(listFields, ',') + ' ';
    return fields;
}
/*************************************************
* Author: Hai Bui
* Date: 12-July-2020
* Params: SectionSetting__c section
* Return: String
* Description: getCondition to query records
* Revision:
*************************************************/
public String getCondition(SectionSetting__c section) {
    String condition = '';
    if(section.Source_Object__c == 'CoveragesLineItem__c' || section.Source_Object__c == 'Quote_Option__c') {
        condition = ' WHERE ' + 'Quote__c IN (\''+ String.join(this.childIds, '\',\'') + '\') ';
    }
    if(section.Source_Object__c == 'Rating_Modifier_Factor__c') {
        List<String> displayFormatList = new List<String>{'Primary Modifiers', 'Secondary Modifiers', 'Factor Values Only','Default Only'};
            condition = ' WHERE ' + 'Quote__c IN (\''+ String.join(this.childIds, '\',\'') + '\') '
            + 'AND Rating_Modifier__r.Display_Format__c IN (\'' + String.join(displayFormatList, '\',\'') + '\') ';
    }
    if(section.Source_Object__c == 'Quote') {
        condition = ' WHERE ' + 'Id IN (\''+ String.join(this.childIds, '\',\'') + '\') ' + 'ORDER BY CreatedDate';
        //condition = ' WHERE ' + 'Id IN (\''+ String.join(this.childIds, '\',\'') + '\')' + ' And ';
    }
    return condition;
}

public Map<String, List<sObject>> createMapForListObjectSort(List<sObject> results, List<SectionSetting__c> sections) {
    Map<String, List<sObject>> mapListObject = new Map<String, List<sObject>>();
    if(sections.isEmpty()) return mapListObject;
    List<sObject> lstObject = new List<sObject>();
    String name =  '';
    String idGet = (sections[0].Source_Object__c == 'Quote') ? 'Id' : 'Quote__c';
    List<String> nameList = new List<String>();
    for(SObject item : results) {
        name = getMapName(item, sections[0]);
        if(!nameList.contains(name))nameList.add(name);
    }
    //use this loop to sort the record correspond with the quoteId and map it by name
    for(Integer i = 0; i < nameList.size(); i++) {
        lstObject = new List<sObject>();
        for(String quoteId : this.childIds) {
            for(Integer j = 0; j < results.size(); j++) {
                if(String.valueOf(results[j].get(idGet)) == quoteId) {
                    name = getMapName(results[j], sections[0]);
                    if(name == nameList[i]) {
                        lstObject.add(results[j]);
                        break;
                    }
                }
                //if quote don't have the field, create a null object
                if((j+1) == results.size()) {
                    lstObject.add(Schema.getGlobalDescribe().get(sections[0].Source_Object__c).newSObject());
                }
            }
            mapListObject.put(nameList[i], lstObject);
        }
    }
    return mapListObject;
}
/// Wrapper class section
public class MainSection {
    public String name {get; set;}
    public String displayType {get; set;}
    public Integer order {get; set;}
    public String quoteLayer {get; set;}
    public List<SubSection> subSections {get; set;}
    public List<Field> fields {get; set;}
    
    public MainSection() {
        this.name = '';
        this.displayType = '';
        this.quoteLayer = '';
        this.order = 0;
        this.subSections = new List<SubSection>();
        this.fields = new List<Field>();
    }
    
    public MainSection(SectionSetting__c section) {
        this.name = section.Main_Section__c;
        this.displayType = section.DisplayType__c;
        this.quoteLayer = section.Quote_Layer__c;
        this.order = Integer.valueOf(section.Order__c);
        this.subSections = new List<SubSection>();
        this.fields = new List<Field>();
    }
}

public class SubSection {
    public String name {get; set;}
    public String displayType {get; set;}
    public Integer order {get; set;}
    public List<Field> fields {get; set;}
    public String mainSectionName {get; set;}
    
    public SubSection() {
        this.name = '';
        this.displayType = '';
        this.order = 0;
        this.fields = new List<Field>();
        this.mainSectionName = '';
    }
    
    public SubSection(SectionSetting__c section) {
        this.name = section.Sub_Section__c;
        this.displayType = section.DisplayType__c;
        this.order = Integer.valueOf(section.Order__c);
        this.mainSectionName = section.Main_Section__c;
        this.fields = new List<Field>();
        
    }
}

public class Field {
    public String sourceFieldAPI {get; set;}
    public String endorsementType {get; set;}
    public String sourceFieldLabel {get; set;}
    public String sourceObject {get; set;}
    public List<String> format {get; set;}
    public String customFieldType {get; set;}
    public String displayType {get; set;}
    public Integer order {get; set;}
    public List<String> values {get; set;}
    public List<String> fieldIds {get; set;}
    public String fieldCondition {get; set;}
    public String fieldRequire {get; set;}
    public List<String> picklistOption {get; set;}
    public Boolean readOnly {get; set;} //hai added
    public String min {get;set;}
    public String max {get;set;}
    public List<String> listMin {get;set;}
    public List<String> listMax {get;set;}
    public String mainSection {get;set;}
    public String quoteLayer {get;set;}
    
    public Field() {
        this.readOnly = false;
        this.sourceFieldAPI = '';
        this.endorsementType = '';
        this.sourceFieldLabel = '';
        this.sourceObject = '';
        this.format = new List<String>();
        this.customFieldType = '';
        this.displayType = '';
        this.order = 0;
        this.values = new List<String>();
        this.fieldIds = new List<String>();
        this.fieldCondition = '';
        this.fieldRequire = '';
        this.pickListOption = new List<String>();
        this.listMin = new List<String>();
        this.listMax = new List<String>();
        this.mainSection = '';
        this.quoteLayer = '';
    }
    public Field(SectionSetting__c section) {
        if(String.isNotBlank(section.Profile_Name_for_Read_Only__c)) {
            if(section.Profile_Name_for_Read_Only__c == 'All'){
                this.readOnly = true;
            }else{
                this.readOnly = section.Profile_Name_for_Read_Only__c.contains(CURRENT_USER_PROFILE) ? true : false;
            }
        }
        Map<String, Schema.SObjectField> fieldsMap  = Schema.getGlobalDescribe().get(section.Source_Object__c).getDescribe().fields.getMap();
        if(!fieldsMap.get(section.Source_Field_API__c).getDescribe().isUpdateable() || fieldsMap.get(section.Source_Field_API__c).getDescribe().isCalculated()) {
            this.readOnly = true;
        }
        this.sourceFieldAPI = section.Source_Field_API__c;
        this.endorsementType = section.Endorsement_Type__c;
        this.sourceFieldLabel = section.Source_Field_Label__c;
        this.sourceObject = section.Source_Object__c;
        this.customFieldType = section.Custom_Field_Type__c;
        this.displayType = section.DisplayType__c;
        this.order = Integer.valueOf(section.Order__c);
        this.format = new List<String>();
        this.pickListOption = new List<String>();
        this.listMin = new List<String>();
        this.listMax = new List<String>();
        this.mainSection = section.Main_Section__c;
        this.quoteLayer = section.Quote_Layer__c;
    }
    
    public void setProperty(FieldProperty prop) {
        this.fieldIds = prop.fieldIds;
        this.values = prop.fieldValues;
        this.fieldCondition = prop.fieldCondition;
        this.fieldRequire = prop.fieldRequire;
    }
    
}

public class FieldProperty {
    public List<String> fieldIds {get; set;}
    public List<String> fieldValues {get; set;}
    public String fieldCondition {get; set;}
    public String fieldRequire {get; set;}
    public FieldProperty() {
        this.fieldIds = new List<String>();
        this.fieldValues = new List<String>();
        this.fieldCondition = '';
        this.fieldRequire = '';
    }
    
    public FieldProperty(List<String> ids, List<String> values, String condition, String require) {
        this.fieldIds = ids;
        this.fieldValues = values;
        this.fieldCondition = condition;
        this.fieldRequire = require;
    }
}

}