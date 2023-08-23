public with sharing class PolicyTriggerHandler extends TriggerHandler{
	private List<Policy__c> oldDataList;
	private List<Policy__c> newDataList;
	private Map<Id, Policy__c> newDataMap;
	private Map<Id, Policy__c> oldDataMap;
	
    public PolicyTriggerHandler (){  
		this.oldDataList = (List<Policy__c>) Trigger.old;
		this.newDataList = (List<Policy__c>) Trigger.new;
		this.newDataMap = (Map<Id, Policy__c>) Trigger.newMap;
		this.oldDataMap = (Map<Id, Policy__c>) Trigger.oldMap;
    }

	public override void beforeInsert()	{
		system.debug('beforeInsert');
		//CommonUtil.generateExternalID('Azure_ID__c', newDataList);
		setInitialPremiumValue(newDataList);
		//populatePolicyNumber(newDataList);
	}

    public override void beforeUpdate(){
		system.debug('brfore update');
		//CommonUtil.generateExternalID('Azure_ID__c', newDataList);
		setInitialPremiumValue(newDataList);
    }

	public override void afterInsert(){}

	public override void afterUpdate(){
         callSyncQuoteBatch(this.newDataList);
    }
    
    /*public static void populatePolicyNumber(List<Policy__c> newPolicies) {
        system.debug('newPolicies' +newPolicies);
	    Map<String,Policy_Incremental_Setting__c> mapProductNamePolicySetting = new Map<String,Policy_Incremental_Setting__c>();
	    Map<String,Policy_Incremental_Setting__c> mapProductNameHasCustomFieldSetting = new Map<String,Policy_Incremental_Setting__c>();
      //  List<Quote> ExcessQuote = [Select Id, Layer__c FROM Quote Where Id =: newPolicies.Quotes__r[0]];
        Set<String> policyNumbers = new Set<String>(); 
        for(Policy__c policy : [Select Policy_Number__c, Id From Policy__c ]){
			policyNumbers.add(policy.Policy_Number__c);
        }
        
		for(Policy_Incremental_Setting__c obj : [SELECT Id,Product_Name__c,Policy_Format__c,
												Start_Number__c,End_Number__c,Active__c,Suffix__c, Spacing__c
												FROM Policy_Incremental_Setting__c WHERE Product_Name__c != 'Excess']) 
		{
            System.debug('obj.Product_Name__c '+obj.Product_Name__c);
			if(!obj.Product_Name__c.contains(':')) mapProductNamePolicySetting.put(obj.Product_Name__c, obj);
			else mapProductNameHasCustomFieldSetting.put(obj.Product_Name__c,obj);
	    }
	 
	    List<Policy_Incremental_Setting__c> updateList = new List<Policy_Incremental_Setting__c>();
	    for (Policy__c newPolicy : newPolicies) {
			 // Generate policy number base on product name for current Contract
	    	if(mapProductNamePolicySetting.containsKey(newPolicy.Product_Name__c)) {
	    		Policy_Incremental_Setting__c policySetting = mapProductNamePolicySetting.get(newPolicy.Product_Name__c);
	    		if(String.isBlank(newPolicy.Policy_Number__c)){
	    			//Long Ly - Task 05/31/2019 - Check number outside the range of the Start Number and End Number.
	    			if(String.isNotBlank(policySetting.End_Number__c)) {
	    				if((Integer.valueOf(policySetting.Start_Number__c) > Integer.valueOf(policySetting.End_Number__c))) {
	    					newPolicy.addError('Policy Number Range has exceeded. Please increase the End Number'); 
	    					continue;  
	    				}
	    			}
	    			//End
					updatePolicyFieldAndSetting(updateList, policySetting, newPolicy, 'Policy_Number__c', policyNumbers);

				}else{ //Binh Dang: 14 Oct 2019 - 6775: Update Policy Number for Renewal Case
					String oldPolicyNoPattern = newPolicy.Policy_Number__c.substringBefore('__');
					String suffix = String.isBlank(policySetting.Suffix__c) ? '' : policySetting.Suffix__c; 
					String spacing =  String.isBlank(policySetting.Spacing__c) ? '' : policySetting.Spacing__c; 
					String oldSuffix = oldPolicyNoPattern.right(suffix.length());
					String oldStart = oldPolicyNoPattern.left(oldPolicyNoPattern.length()-suffix.length());

					if(oldSuffix.isNumeric()){
						String inputStr = String.valueOf(Decimal.valueOf(oldSuffix) + 1);
						oldSuffix = inputStr.leftPad(suffix.length(), '0');
					}else {
						String inputStr = String.valueOf(returnNumberStringFromString(oldSuffix, true));
						oldSuffix = oldSuffix.replace(String.valueOf(returnNumberStringFromString(oldSuffix,false)), inputStr);
					}
					
					if(String.isNotBlank(spacing) && oldStart.contains(spacing)){//already added spacing
						spacing = '';
					} 
                    
                    // Added by Maeran Shaikh on 10/6/2021 for US: 47350
                    newPolicy.Parent_Policy_Number__c = oldStart + spacing + String.valueOf(Decimal.valueOf(oldSuffix) - 1).leftPad(suffix.length(), '0');
                    //newPolicy.Parent_Policy_Number__c = String.isNotBlank(newPolicy.Policy_Number__c)?newPolicy.Policy_Number__c:'';
                    
                    
					newPolicy.Policy_Number__c = oldStart + spacing + oldSuffix;
                    System.debug('newPolicy.Policy_Number__c'+newPolicy.Policy_Number__c);
				}
	    	}
			//5 Sept 2019: Update the incremental other custom fields on current Contract
			for(String key : mapProductNameHasCustomFieldSetting.keySet()){
				List<String> customList = key.split(':');
				if(customList[0] == newPolicy.Product_Name__c) 
				{
	    			Policy_Incremental_Setting__c policySetting2 = mapProductNameHasCustomFieldSetting.get(key);
	    			if(String.isNotBlank(policySetting2.End_Number__c)) {
	    				if((Integer.valueOf(policySetting2.Start_Number__c) > Integer.valueOf(policySetting2.End_Number__c))) {
	    					newPolicy.addError( customList[1] + ' Range has exceeded. Please increase the End Number'); 
	    					continue;  
	    				}
	    			}    
					updatePolicyFieldAndSetting(updateList, policySetting2, newPolicy, customList[1], null);
	    		}
			}
		}		
		if(!updateList.isEmpty()) update updateList; // Update latest sequence number back to custom setting
        System.debug('newPolicies'+newPolicies);
	}
    */
   /* public static void updatePolicyFieldAndSetting(List<Policy_Incremental_Setting__c> updateList, 
													Policy_Incremental_Setting__c policySetting, 
													Policy__c newPolicy, String fieldName, Set<String> policyNumbers)
	{
        String suffix;
        String spacing;
        String value;
        if(newPolicy.Product_Name__c == 'Cyber Standalone' || newPolicy.Product_Name__c == 'MPL Standalone'){
            if(newPolicy.Layer__c == 'Excess'){
                policySetting = [SELECT Id,Product_Name__c,Policy_Format__c,
												Start_Number__c,End_Number__c,Active__c,Suffix__c, Spacing__c
												FROM Policy_Incremental_Setting__c WHERE Product_Name__c = 'Excess'];
            }
		//Integer start = Integer.valueOf(policySetting.Start_Number__c);
		 suffix = String.isBlank(policySetting.Suffix__c) ? '' : policySetting.Suffix__c;
		 spacing =  String.isBlank(policySetting.Spacing__c) ? '' : policySetting.Spacing__c;
		 value= ((String.format(policySetting.Policy_Format__c, 
											  new List<String>{returnNumberStringFromString(policySetting.Start_Number__c,false)})) + spacing + suffix);
		system.debug('value -- '+value);
         	    //start++;
	    policySetting.Start_Number__c = returnNumberStringFromString(policySetting.Start_Number__c,true);
	    updateList.add(policySetting);
        }*/
        
        /*if(newPolicy.Layer__c == 'Excess')
        {
            system.debug('newPolicy.Product_Name__c -'+newPolicy.Product_Name__c);
                if(newPolicy.Product_Name__c == 'Cyber Standalone' || newPolicy.Product_Name__c == 'MPL Standalone') 
                {
                  Policy_Incremental_Setting__c ExcessPolNumber = [SELECT Id,Product_Name__c,Policy_Format__c,
												Start_Number__c,End_Number__c,Active__c,Suffix__c, Spacing__c
												FROM Policy_Incremental_Setting__c WHERE Product_Name__c = 'Excess'];
                 
                   system.debug('ExcessPolNumber -'+ExcessPolNumber);
                        
                    suffix = String.isBlank(ExcessPolNumber.Suffix__c) ? '' : ExcessPolNumber.Suffix__c;
                    spacing =  String.isBlank(ExcessPolNumber.Spacing__c) ? '' : ExcessPolNumber.Spacing__c;
                    value= ((String.format(ExcessPolNumber.Policy_Format__c, 
                                           new List<String>{returnNumberStringFromString(ExcessPolNumber.Start_Number__c,false)})) + spacing + suffix);
                    system.debug('Excess value -- '+value);
                    ExcessPolNumber.Start_Number__c = returnNumberStringFromString(ExcessPolNumber.Start_Number__c,true);
                    
                    updateList.add(ExcessPolNumber);
                         
                        }
        	
        }*/
      /*  newPolicy.put(fieldName,value);

	}*/

    /*
	public static String returnNumberStringFromString(String num, Boolean increase) {
	  String n = '';
	  Integer lenght =0;
	  for (Integer i=0; i<num.length(); i++) {
		  if (num.substring(i, i+1).isNumeric()){
				  n += num.substring(i, i+1);
				  lenght +=1;
		  }
	  }
		
	  Integer newValue = increase ? Integer.valueOf(n)+1 : Integer.valueOf(n);
	  String newString = String.valueOf(newValue);
	  return newString.leftPad(lenght, '0');
  }
*/
  private void setInitialPremiumValue(List<Policy__c> newDataList) {
	for(Policy__c policy : newDataList) {
		if(policy.Total_Premium__c != null && policy.Initial_Premium__c == null) {
			policy.Initial_Premium__c = policy.Total_Premium__c;
		}
	}
  }
    public static void callSyncQuoteBatch(List<Policy__c> newDataList){
       
        List<Quote> quotes  = new List<Quote>();
        
        for(Quote q : [select Id from Quote
                      WHERE (Product_Name__c = 'MPL Standalone' OR Product_Name__c = 'Cyber Standalone') and (Policy__c IN :newDataList)
                       ]){
                           quotes.add(q);
                       }

        System.enqueueJob(new SyncQuoteQueueable(quotes));
    }   
}