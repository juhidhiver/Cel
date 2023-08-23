public with sharing class sectionSettingLwcController {
	static final String CHARACTER = ',';
	@AuraEnabled
    public static List<OptionWrapper> getComponentList(String recordTypeName) 
	{
	    Set<String> componentsSet = new Set<String>();
		List<OptionWrapper> componentList = new List<OptionWrapper>();
		for(SectionSetting__c obj : [SELECT Component__c FROM SectionSetting__c WHERE Record_Type__c=:recordTypeName AND Component__c!=null ]) 
		{
		    componentsSet.add(obj.Component__c);     
        } 
		
		for(String com :componentsSet){
			componentList.add(new OptionWrapper(com, com));
		}

		return componentList;
	}

	@AuraEnabled
	public static List<OptionWrapper> getProductList(String recordTypeName){
		Set<String> productSet = new Set<String>();
		List<OptionWrapper> productList = new List<OptionWrapper>();
		
		for(SectionSetting__c obj : [SELECT Product__c FROM SectionSetting__c
									 WHERE Record_Type__c = :recordTypeName AND Product__c!=null ]) 
		{
		    productSet.add(obj.Product__c);     
		}
		
		for(String prod :productSet){
			productList.add(new OptionWrapper(prod, prod));
		}
		system.debug('getProductList '+ productList);
		return productList;
	}

	@AuraEnabled
    public static List<OptionWrapper> getSectionList(String conditionGroup) 
	{
		List<String> lstStr = conditionGroup.split(CHARACTER);
		List<OptionWrapper> sectionList = new List<OptionWrapper>();
		if(lstStr.size()==2) //MainSection query
			for(SectionSetting__c obj : [SELECT Id, Main_Section__c	FROM SectionSetting__c WHERE Record_Type__c=:lstStr[0] 
										AND Component__c=:lstStr[1] AND Type_Of_Section__c='MainSection' //AND Active__c=true
										Order by Order__c]) 
			{
				  sectionList.add(new OptionWrapper(obj.Main_Section__c, obj.Id));    //label,value
			} 
		
		if(lstStr.size()==3) //SubSection query
		{
			sectionList.add(new OptionWrapper('', '')); 
			for(SectionSetting__c obj : [SELECT Id, Sub_Section__c FROM SectionSetting__c WHERE Record_Type__c=:lstStr[0] 
									AND Component__c=:lstStr[1] AND Main_Section__c=:lstStr[2] AND Type_Of_Section__c='SubSection' //AND Active__c=true
									Order by Order__c]) 
			{
				  sectionList.add(new OptionWrapper(obj.Sub_Section__c, obj.Id));    //label,value
			} 
		}
       return sectionList;
	}
	
    @AuraEnabled
    public static List<OptionWrapper> getMainSectionList(String recordTypeName, String componentName)
	{
		List<OptionWrapper> componentList = new List<OptionWrapper>();
		for(SectionSetting__c obj : [SELECT Id, Main_Section__c
				FROM SectionSetting__c WHERE Record_Type__c=:recordTypeName AND Component__c=:componentName 
				AND Type_Of_Section__c='MainSection' //AND Active__c=true
				Order by Order__c]) 
		{
              componentList.add(new OptionWrapper(obj.Main_Section__c, obj.Id));    //label,value
        } 
       return componentList;
	}
	
	@AuraEnabled
	public static List<OptionWrapper> getSubSectionList(String recordTypeName, String componentName,String mainSectionName)
	{
      	List<OptionWrapper> componentList = new List<OptionWrapper>();
		componentList.add(new OptionWrapper('', '')); 
		for(SectionSetting__c obj : [SELECT Id, Sub_Section__c, Main_Section__c 
				FROM SectionSetting__c WHERE Record_Type__c=:recordTypeName AND Component__c=:componentName AND Main_Section__c=:mainSectionName
				AND Type_Of_Section__c='SubSection' //AND Active__c=true
				Order by Order__c]) 
		{
              componentList.add(new OptionWrapper(obj.Sub_Section__c, obj.Id));    //mainSection, label,value
        } 

       return componentList;
	}

	@AuraEnabled
	public static List<SectionSetting__c> getFieldList(String groupdId) //input is Mainsection Id or SubSectionId
	{
        return [SELECT Id,Name,Record_Type__c, Product__c,Component__c,Main_Section__c,Sub_Section__c,Source_Field_API__c,
				Source_Field_Label__c, Source_Object__c,Format__c,DisplayType__c, Order__c,Active__c,Criteria__c,Lookup_To__c
				FROM SectionSetting__c WHERE Type_Of_Section__c='Field' AND Group_Field_Key__c=:groupdId //AND Active__c=true 
				Order by Order__c];
	}

	@AuraEnabled
	public static String updateSectionRelatedData(String oldValue, String newValue) //input is Mainsection Id or SubSectionId
	{
		//if newValue ='' --> delete event
		//if newValue !='' --> new or edit event
		String returnStr ='MainSection';
		system.debug('@@@ oldValue:'+ oldValue);
		system.debug('@@@ newValue:'+ newValue);
		List<SectionSetting__c> sectionList = new List<SectionSetting__c>();
		List<String> oldStrList = new List<String> ();
		List<String> newStrList = new List<String> ();
		if(oldValue.contains(CHARACTER)) oldStrList = oldValue.split(CHARACTER);
		if(newValue.contains(CHARACTER)) newStrList = newValue.split(CHARACTER);

		system.debug('@@@ updateSectionRelatedData:');
		system.debug('@@@ oldStrList:'+ oldStrList);
		system.debug('@@@ newStrList:'+ newStrList);
		//check Main or Sub Section base on newValue
		//....
		Boolean isMainSection = false;

		if(String.isBlank(newValue))//Delete case
		{
			if(oldStrList.size()==4) //--> delete Sub Section
			{
				sectionList = [SELECT Id FROM SectionSetting__c WHERE Record_Type__c=:oldStrList[0] 
							AND Component__c=:oldStrList[1] AND Main_Section__c=:oldStrList[2] AND Sub_Section__c=:oldStrList[3]];

			}else//delete Main Section
			{
				sectionList = [SELECT Id FROM SectionSetting__c WHERE Record_Type__c=:oldStrList[0] 
										AND Component__c=:oldStrList[1] AND Main_Section__c=:oldStrList[2] ];
				isMainSection = true;
			}
			
			if(!sectionList.isEmpty()) delete sectionList;
			
			returnStr = isMainSection ? 'deleted Main Section' : 'deleted Sub Section';

		}else //Edit or New case
		{
			if(String.isBlank(oldValue)) // New Section logic
				 returnStr = (newStrList.size()==4) ? 'added SubSection' : 'added MainSection';
			else//Edit Section logic
			{	
				system.debug('@@@ Edit Section logic:');
				system.debug('@@@ oldStrList size:' + oldStrList.size());
				if(oldStrList.size()==4) //--> edit Sub Section Name
				{
					system.debug('@@@ Edit Sub Section logic:');
					sectionList = [SELECT Id, Sub_Section__c FROM SectionSetting__c WHERE Record_Type__c=:oldStrList[0] 
								AND Component__c=:oldStrList[1] AND Main_Section__c=:oldStrList[2] AND Sub_Section__c=:oldStrList[3]];
					for(SectionSetting__c obj : sectionList) 
					{
						obj.Sub_Section__c =newValue; 
					} 
					returnStr ='edited SubSection';
				}else//edit Main Section name
				{
					system.debug('@@@ Edit Main Section logic:');
					sectionList = [SELECT Id, Main_Section__c FROM SectionSetting__c WHERE Record_Type__c=:oldStrList[0] 
											AND Component__c=:oldStrList[1] AND Main_Section__c=:oldStrList[2] ];
					for(SectionSetting__c obj : sectionList) 
					{
						obj.Main_Section__c =newValue; 
					} 
					returnStr ='edited MainSection';
				}
				if(!sectionList.isEmpty()) update sectionList;
			}
		}

		return returnStr;
	}

	@AuraEnabled
	public static String updateComponentRelatedData(String rt, String componentName, String mode) //input is Mainsection Id or SubSectionId
	{
		String result ='';
		
		List<String> lst = new List<String>();
		//system.debug('@@@ lst:' + lst.size());
		if(mode=='Edit'){
			if(componentName.contains(CHARACTER)) // Edit case
			{
				lst = componentName.split(CHARACTER);
				String oldValue = lst[0];
				String newvalue = lst[1];
				//Update all Main Section, Subsection, Fields of Component
				//Separate old value and new value by special character -
				List<SectionSetting__c> componentsList = [SELECT Component__c FROM SectionSetting__c WHERE Record_Type__c=:rt AND Component__c=:oldValue ];
				for(SectionSetting__c obj : componentsList) 
				{
					obj.Component__c =newvalue; 
				} 
				update componentsList;
				result ='Updated success';
			}else//Create new Component Mode
			{
				//Create new Main Section 
				SectionSetting__c newobj = new 	SectionSetting__c();
				newobj.Record_Type__c = rt;
				newobj.Component__c = componentName;
				newobj.Main_Section__c = 'Main Section - ' + componentName;
				newobj.Order__c = 1;
				newobj.Active__c = true;
				insert newobj;
				result ='Inserted success';
			}
		}
		if(String.isNotBlank(componentName) && mode == 'Delete')
		{
			List<SectionSetting__c> componentsList = [SELECT Component__c FROM SectionSetting__c WHERE Record_Type__c=:rt AND Component__c=:componentName ];
			delete componentsList;
			result ='Deleted success';
		}
		
		return result;
	}

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