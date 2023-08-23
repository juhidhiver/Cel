public with sharing class ratingModiferTempSectionLwcController {

    //Get Page(Main) Section List
    @AuraEnabled
    public static List<OptionWrapper> getPageSectionListMulti(List<String> modifierProductName){
        String productNames = String.join(modifierProductName, ';');
        List<OptionWrapper> componentList = new List<OptionWrapper>();
        List<String> listPageSections = new List<String>();
		for(Rating_Modifier_Template__c obj : [SELECT Id, Page_Section__c
				FROM Rating_Modifier_Template__c WHERE Product__c INCLUDES (:productNames) 
				Order by Page_Section__c]) 
		{
            if(!listPageSections.contains(obj.Page_Section__c)) {
                componentList.add(new OptionWrapper(obj.Page_Section__c, obj.Page_Section__c));    //label,value
                listPageSections.add(obj.Page_Section__c);
            }
        } 
       return componentList;
    }
    
    //Get Sub Section List
    @AuraEnabled
    public static List<OptionWrapper> getSubSectionListMulti(List<String> modifierProductName, String pageSectionName){
            String productNames = String.join(modifierProductName, ';');
              List<OptionWrapper> componentList = new List<OptionWrapper>();
              List<String> listSubSections = new List<String>();
            componentList.add(new OptionWrapper('', '')); 
            for(Rating_Modifier_Template__c obj : [SELECT Id, Sub_Section__c, Page_Section__c 
                    FROM Rating_Modifier_Template__c WHERE Product__c INCLUDES (:productNames) AND Page_Section__c=:pageSectionName
                    Order by Sort_Order__c]) 
            {
                if(!listSubSections.contains(obj.Sub_Section__c)){
                    componentList.add(new OptionWrapper(obj.Sub_Section__c, obj.Sub_Section__c));    //mainSection, label,value
                    listSubSections.add(obj.Sub_Section__c);
                }
            } 
    
           return componentList;
    }

    //Get Fields List
    @AuraEnabled
	public static List<Rating_Modifier_Template__c> getFieldListMulti(List<String> modifierProductName, String pageSectionName, String subSectionName){
        String productNames = String.join(modifierProductName, ';');
        String condition = '';
        if(String.isNotBlank(pageSectionName))
            condition += ' AND Page_Section__c = \'' + pageSectionName + '\'';
        if(String.isNotBlank(subSectionName))
            condition += ' AND Sub_Section__c = \'' + subSectionName + '\'';
        String query = 'SELECT Id,Name,Comment__c,Display_Format__c,Eligibility_Weighting_Factor__c,Factor_Default_Value__c,Factor_Max__c,'+
                'Factor_Min__c,Modifier_Format__c,Picklist_Values__c,Page_Section__c,Picklist_Default_Value__c,'+
                'Picklist_Range__c,Rating_Modifier_Code__c,Sort_Order__c,Sub_Section__c,Product__c '+
				'FROM Rating_Modifier_Template__c WHERE Product__c INCLUDES (\'' + productNames + '\') ' + condition + ' ' +
                'Order by Sort_Order__c';
        return Database.query(query);
    }
    
    //Option Wrapper
    public class OptionWrapper {
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}

        public OptionWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
	}
}