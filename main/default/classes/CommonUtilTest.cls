@isTest
public class CommonUtilTest {

    @testSetup
    public static void setup() {
        TriggerSettings__c setting = new TriggerSettings__c();
		setting.BypassBrokerAccountTrigger__c = false;
        setting.BypassContactTrigger__c = true;
		insert setting;
        
        Account acc1 = new Account(); 
		acc1.Name = 'Test account 2';
		acc1.BillingStreet = '11 Tran Duy Hung';
		acc1.BillingCity = 'Westminster';
		acc1.BillingState = 'California';
		acc1.BillingPostalCode = '90000';
		acc1.BillingCountry = 'United States';
        //acc1.Billing_County__c;
		acc1.IsMailingSameWithBillingAddress__c = true;
		acc1.Date_Started__c = Date.today().addYears(-2);
		insert acc1;

        Product2 product = TestUtil.createProduct('MPL');
		insert product;
        
        // Create contact
		Contact con = new Contact(
			Lastname = 'Test broker',
			RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
		);
		insert con;
        
        List<Rating_Modifier_Template__c> lRMT = new List<Rating_Modifier_Template__c>();
        Rating_Modifier_Template__c rMT1 = TestUtil.createRatingModifierTemplate('New input Number','Cyber','Number');
        rMT1.Page_Section__c = Label.ELIGIBILITY_SECTION_HEADER;
        lRMT.add(rMT1);
        Rating_Modifier_Template__c rMT2 = TestUtil.createRatingModifierTemplate('New input integer','MPL','Integer');
        rMT2.Page_Section__c = Label.ELIGIBILITY_SECTION_HEADER;
        lRMT.add(rMT2);
        Rating_Modifier_Template__c rMT3 = TestUtil.createRatingModifierTemplate('New input integer','Cyber','Integer');
        rMT3.Page_Section__c = Label.ELIGIBILITY_SECTION_HEADER;
        lRMT.add(rMT3);
        Rating_Modifier_Template__c rMT4 = TestUtil.createRatingModifierTemplate('New input integer','MPL','Integer');
        rMT4.Page_Section__c = Label.ELIGIBILITY_SECTION_HEADER;
        lRMT.add(rMT4);
        Rating_Modifier_Template__c rMT5 = TestUtil.createRatingModifierTemplate(Label.NATURE_OF_INDUSTRY_OR_SECTOR,'Cyber','Number');
        rMT5.Page_Section__c = Label.ELIGIBILITY_SECTION_HEADER;
        lRMT.add(rMT5);
        Rating_Modifier_Template__c rMT6 = TestUtil.createRatingModifierTemplate(Label.ANNUAL_REVENUES,'Cyber','Number');
        rMT6.Page_Section__c = 'ramdomString';
        lRMT.add(rMT6);

        insert lRMT;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc1.Id, product.Id);
        insert opportunity;
        
        Rating_Modifiers__c ratingModifier2 = TestUtil.createRatingModifier('Rating field test2', 'MPL', opportunity.Id);
        insert ratingModifier2;
        
        Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
		quote.Coverage_Product_Options__c ='MPL';
        insert quote;


        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'Cyber');
        cov.Endorsement_Categories__c = 'Test Category';
        cov.Coverage_Type__c = 'Endorsement';
        insert cov;
        
        //create limit deductables
        Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
        insert ded;
        
        CoveragesLineItem__c cli = new CoveragesLineItem__c();
        cli.Quote__c = quote.Id;
        cli.Coverage_Product__c = cov.Coverage_Product__c;
        cli.Coverage__c = cov.Id;
        cli.Limits_Deductibles__c = ded.Id;
        insert cli;
    }
    
    @isTest
    public static void testUtilityMethod() {
        
        Test.startTest();
        CommonUtil.isSetEmpty(new Set<String>{''});
        
        CommonUtil.convertStringToDecimal('00459'); 
        
        CommonUtil.convertStringToInteger('12345');
        
        CommonUtil.convertNumberToString(345);
        
        CommonUtil.convertNumberToString(null);
        
        CommonUtil.convertDateToString(Date.today());
        
        CommonUtil.convertDateToString(null);
        
        CommonUtil.convertToString(new Account());
        
        CommonUtil.convertToString('');
        
        CommonUtil.convertToStringOrNull(new Account());
        
        CommonUtil.convertToStringOrNull('');
        
        CommonUtil.parseDateFromString('2020-08-08');
        
        CommonUtil.getPicklistValueFromObjectField('SectionSetting__c','Format__c');
        
        CommonUtil.getPicklistValueMapFromObjectField('Account','AccountSource');
        
        CommonUtil.getPicklistListFromObjectField('Contact','Home_State__c');
        
        CommonUtil.isTriggerBypass('QuoteTrigger');
        
        API_Configuration__mdt apiConfiguration = CommonUtil.getAPIconfiguration('Specifics_Quote');
        
        CommonUtil.getAPIconfiguration('');
        
        CommonUtil.getAPIconfigurations();
        
        CommonUtil.getProductSettingMap();
        
        CommonUtil.generateExternalID('Quote_Type__c',new List<sObject>{new Quote()});
        
        System.assert(apiConfiguration != null);
        Test.stopTest();
        
    }
    
    @isTest
    public static void testSendEmailWithPdf() {
        Test.startTest();
        EmailTemplate e = new EmailTemplate (developerName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test', Subject='Test Email',HtmlValue='<![CDATA[]]> <p>paragraph</p>',Body='This is a test');
        Contact con = [SELECT id FROM Contact LIMIT 1];
        Map<String,String> replaceMap = new Map<String,String>();
        replaceMap.put('<p>','paragraph start');
        replaceMap.put('</p>','paragraph end');
        replaceMap.put('test','testing');
        try {
           CommonUtil.sendEmailWithPdf(e,con.Id,'test',new List<String>{'www.testfake@fake.com'},
                                    Blob.ValueOf('This is a Test'),replaceMap); 
        } catch(Exception ex) {
            
        }
        System.assertEquals(1, Limits.getEmailInvocations());
        Test.stopTest();
    }
    
    @isTest
    public static void testBuildQuery() {
        QueryObject qObj = new QueryObject();
        qObj.Name = 'TestQueryObject';
        qObj.fields = new List<String>{'Id,Name,BillingCity'};
        qObj.condition = 'Name=\'Test account 2\'';
        qObj.orderByField = 'BillingCity';
        qObj.orderType = 'ASC';
        qObj.pageSize = 1;
        qObj.pageNumber = 1;
        
        CommonUtil.buildQuery(qObj);
        
        QueryObject qObj1 = new QueryObject();
        qObj1.Name = 'TestQueryObject';
        qObj1.fields = new List<String>{'Id,Name,BillingCity'};
        qObj1.condition = '';
        qObj1.orderByField = 'BillingCity';
        qObj1.orderType = 'ASC';
        qObj1.pageSize = 1;
        qObj1.pageNumber = 1;
        Test.startTest();
        String query = CommonUtil.buildQuery(qObj1);
        Test.stopTest();
        System.assert(query != null);
    }
    
    @isTest
    public static void testBuildQuerySelectAll() {
        Test.startTest();
        CommonUtil.buildQuerySelectAll('Account','Name=\'Test account 2\'');
        String query = CommonUtil.buildQuerySelectAll('','Name=\'Test account 2\'');
        Test.stopTest();
        System.assertEquals('', query);
    }
    
    @isTest
    public static void testGetObjectNameById() {
        Test.startTest();
        Contact con = [SELECT id FROM Contact LIMIT 1];
        String objectName = CommonUtil.getObjectNameById(con.Id);
        CommonUtil.getObjectNameById('');
        CommonUtil.getObjectNameById('1022');
        System.assertEquals('Contact', objectName);
        Test.stopTest();
    }
    
    @isTest
    public static void testGetRatingTemplatesByProducts() {
        Test.startTest();
        List<Rating_Modifier_Template__c> ratingModifierTemplate = CommonUtil.getRatingTemplatesByProducts(new List<String>{'MPL','Cyber'});
        System.assert(ratingModifierTemplate != null);
        Test.stopTest();
    }
    
    @isTest
    public static void testGetRatingModifiersByOppIds() {
        Test.startTest();
        Rating_Modifiers__c rm = [SELECT id FROM Rating_Modifiers__c LIMIT 1];
        List<Rating_Modifiers__c> ratingModifiers = CommonUtil.getRatingModifiersByOppIds(new Set<String>{rm.Id});
        System.assertEquals(0, ratingModifiers.size());
        Test.stopTest();
    }
    
    @isTest
    public static void testGetCoveragesLineItemsByQuotes() {
        Test.startTest();
        Quote quote = [SELECT id FROM Quote LIMIT 1];
        List<CoveragesLineItem__c> coverageLineItems = CommonUtil.getCoveragesLineItemsByQuotes(new List<String>{quote.Id});
        CommonUtil.getCoveragesLineItemsByQuotes(new List<String>{});
        System.assert(coverageLineItems.size() > 0);
        Test.stopTest();
    }
    
    @isTest
    public static void testGetRelationshipField() {
        Test.startTest();
        String realationshipField = CommonUtil.getRelationshipField('Account','Contact');
        System.assertEquals('AccountId', realationshipField);
        Test.stopTest();
    }
    
    @isTest
    public static void testGenerateDatatable() {
        Test.startTest();
        Account acc = [SELECT id FROM Account LIMIT 1];
        Contact con = [SELECT id FROM COntact LIMIT 1];
        Object obj = 'Id,Name,LastName';
        LightningDataTableWrapper dataTableWrapper = CommonUtil.generateDatatable(acc.Id,'Contact',obj,'Broker');
        
        CommonUtil.generateDatatable(acc.Id,'Contact',obj);
        System.assertEquals('Contact', dataTableWrapper.name);
        Test.stopTest();
    }
    
    @isTest
    public static void testGetReportFilterString() {
      Test.startTest();
      List<Reports.ReportFilter> filters = new List<Reports.ReportFilter>(); 
      Reports.ReportFilter newFilter = new Reports.ReportFilter();
      newFilter.setColumn('FirstName');
      newFilter.setOperator('equals');
      newFilter.setValue('Test');
      filters.add(newFilter);
      
      String reportFilter = CommonUtil.getReportFilterString('SampleReportofContacts',filters);
      System.assertEquals('', reportFilter);
      Test.stopTest();
    }
    
    @isTest
    public static void testGetUserIdInGroupByGroupName() {
        Test.startTest();
        Group grp = new Group();
        grp.name = 'Test Group1';
        grp.Type = 'Regular'; 
        Insert grp; 
 
        //Create Group Member
        GroupMember grpMem1 = new GroupMember();
        grpMem1.UserOrGroupId = UserInfo.getUserId();
        grpMem1.GroupId = grp.Id;
        Insert grpMem1;
 
        //Create Sub group
        Group subGrp  = new Group();
        subGrp.name = 'Test Group2';
        subGrp.Type = 'Regular'; 
        Insert subGrp;
        
        List<Id> ids = CommonUtil.getUserIdInGroupByGroupName('Test Group1');
        Test.stopTest();   
        System.assertEquals(1, ids.size());
    }
    
    @isTest
    public static void testGetCustomFieldsByObjectMap() {
        Test.startTest();
        CommonUtil.getCustomFieldsByObjectMap('Contact',new List<String>{'Id,Name,Home_State__c'});
        Map<String, String> customFields = CommonUtil.getCustomFieldsByObjectMap('Contact',new List<String>{});
        System.assert(!customFields.keySet().isEmpty());
        Test.stopTest();
    }
    
    @isTest
    public static void testGetMetaDataTypeSettingByField() {
        Test.startTest();
        CommonUtil.getMetaDataTypeSettingByField('Product_Setting__mdt','','Endorsement_Operation__c','Amendment,Reinstatement,Midterm Cancellation,Flat Cancellation');
        CommonUtil.getSettingByField('Product_Setting__mdt','','Endorsement_Operation__c','Amendment,Reinstatement,Midterm Cancellation,Flat Cancellation');
        CommonUtil.getSettingByField('Product_Setting__mdt','Eligibility_Status_API__c,Endorsement_Operation__c','Eligibility_Status_API__c','MPL_Eligibility_Status__c');
        sObject settings = CommonUtil.getSettingByField('Product_Setting__mdt','Endorsement_Operation__c','Eligibility_Status_API__c','MPL_Eligibility_Status__c');
        System.assert(settings != null);
        Test.stopTest();
    }
    
    @isTest
    public static void testCreateAuraHandledException() {
        Test.startTest();
        AuraHandledException auraException = CommonUtil.createAuraHandledException('AuraException','Aura Exception is there');
        System.assertEquals('Aura Exception is there', auraException.getMessage());
        Test.stopTest();
    }
    
    @isTest
    public static void testGetPicklistEndorsementOperations() {
        Test.startTest();
        List<PicklistOption> endorsementPicklist = CommonUtil.getPicklistEndorsementOperations('MPL Standalone');
        System.assert(endorsementPicklist.size() != null);
        Test.stopTest();
    }
    
    @isTest
    public static void testGetProductNameByQuoteId() {
        Test.startTest();
        Quote quote = [SELECT id FROM Quote LIMIT 1];
        String productName = CommonUtil.getProductNameByQuoteId(quote.Id);
        CommonUtil.getProductNameByQuoteId('');
        System.assertEquals('MPL', productName);
        Test.stopTest();
    }
    
    @isTest
    public static void testGetParentFieldFromChildObj() {
        Test.startTest();
        String parentField = CommonUtil.getParentFieldFromChildObj('Account','Contact');
        System.assertEquals('AccountId', parentField);
        Test.stopTest();
    }
    
    @isTest
    public static void testGetRelationShipNames() {
        Test.startTest();
        String relationshipName = CommonUtil.getRelationShipNames('Account','Contact');
        CommonUtil.parseDatetimeFromString('2019-02-20T07:06:37+00:00');
        CommonUtil.getPicklistEndorsementOperationsAQ('Amendment');
        CommonUtil.getProductSettingsAQ('Test');
        System.assertEquals('Contacts', relationshipName);
        Test.stopTest();
    }

    @isTest
    public static void testHelpText (){
        Test.startTest();
        List<PicklistOption> result = NewEndorsementController.initData('','MPL Standalone','Cancelled',Date.today(),null);
        list<String> endorsementOperations = new list<String> ();
        for(PicklistOption po : result){
            endorsementOperations.add(po.value);
        }
        NewEndorsementController.getEndorsementOperationsHelpText(endorsementOperations);
        EmailTemplate e = [Select Id, HtmlValue from EmailTemplate where TemplateType = 'Custom' limit 1 ];
        Quote q = [Select Id from Quote LIMIT 1];
        CommonUtil.sendEmail(e, q, new list<String>{'test123@innovisk.com'}, 'TEST Eamil' );
        

        Test.stopTest();
    }
}