/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Handler for Product trigger
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author Hoang Bui        
* @created        2019-Aug-23
* @modified       2019-Aug-23
* ──────────────────────────────────────────────────────────────────────────────────────────────────
*/
public with sharing class ProductTriggerHandler extends TriggerHandler{
	private List<Product2> oldDataList;
	private List<Product2> newDataList;
	private Map<Id, Product2> newDataMap;
	private Map<Id, Product2> oldDataMap;

	
	public ProductTriggerHandler (){  
		this.oldDataList = (List<Product2>) Trigger.old;
		this.newDataList = (List<Product2>) Trigger.new;
		this.newDataMap = (Map<Id, Product2>) Trigger.newMap;
		this.oldDataMap = (Map<Id, Product2>) Trigger.oldMap;
	}

	public override void beforeInsert()	{
		CommonUtil.generateExternalID('Azure_Id__c', newDataList);
	}

	public override void beforeUpdate() {
		CommonUtil.generateExternalID('Azure_Id__c', newDataList);
	}

	public override void afterInsert(){
		addProductNameToObject('Rating_Modifier_Template__c.Modifier_Product__c',newDataList);
		addProductNameToObject('Rating_Modifiers__c.Product__c',newDataList);
		addProductNameToObject('Coverage__c.Coverage_Product__c',newDataList);
		addProductNameToObject('CoveragesLineItem__c.Coverage_Product__c',newDataList);
		addProductNameToObject('Endorsement_Line_Item__c.Coverage_Product__c',newDataList);
		addProductNameToObject('Eligibility_Status__c.Modifier_Product__c',newDataList);
		//Policy__c.Product_Name__c
	}

	public override void afterUpdate() {
		//updateProductNameFromObject('Rating_Modifier_Template__c.Modifier_Product__c',oldDataMap, newDataMap);
		updateProductNameFromObject('Modifier_Product',oldDataMap, newDataMap);//
		//
		//updateProductNameFromObject('Rating_Modifiers__c.Product__c',oldDataMap, newDataMap);
		//updateProductNameFromObject('Coverage__c.Coverage_Product__c', oldDataMap, newDataMap);
		//updateProductNameFromObject('CoveragesLineItem__c.Coverage_Product__c', oldDataMap, newDataMap);
		//updateProductNameFromObject('Endorsement_Line_Item__c.Coverage_Product__c', oldDataMap, newDataMap);
		//updateProductNameFromObject('Eligibility_Status__c.Modifier_Product__c', oldDataMap, newDataMap);
	}

	public override void afterDelete() {
		removeProductNameFromObject('Rating_Modifier_Template__c.Modifier_Product__c',oldDataList);
		removeProductNameFromObject('Rating_Modifiers__c.Product__c',oldDataList);
		removeProductNameFromObject('Coverage__c.Coverage_Product__c', oldDataList);
		removeProductNameFromObject('CoveragesLineItem__c.Coverage_Product__c', oldDataList);
		removeProductNameFromObject('Endorsement_Line_Item__c.Coverage_Product__c', oldDataList);
		removeProductNameFromObject('Eligibility_Status__c.Modifier_Product__c', oldDataList);
	}
	
	/**
	* ──────────────────────────────────────────────────────
	* Add product Name to Object API Name (e.g.: Rating_Modifiers__c.Product__c)
	*
	* ──────────────────────────────────────────────────────
	* @param items List Products from trigger.new
	* ──────────────────────────────────────────────────────
	*/
	public static List<String> addProductNameToObject(String apiName,List<Product2> items) {
		List<String> productNames = new List<String>();
		List<String> errors = new List<String>();
		try {
			for(Product2 item : items) {
				productNames.add(item.Name);
			}

			if (productNames.size() == 0) {
				return errors;
			}
			ProductTriggerHandler.callAddPicklistValues(apiName, productNames);

		} catch (Exception ex) {
			errors.add(ex.getMessage());
		}
		System.debug(errors);
		return errors;
	}
	

	/**
	* ──────────────────────────────────────────────────────
	* Remove product Name from Object API Name (e.g.: Rating_Modifiers__c.Product__c)
	*
	* ──────────────────────────────────────────────────────
	* @param items List Products from trigger.old
	* ──────────────────────────────────────────────────────
	*/
	public static List<String> RemoveProductNameFromObject(String apiName, List<Product2> items) {
		List<String> productNames = new List<String>();
		List<String> errors = new List<String>();
		try {
			for(Product2 item : items) {
				productNames.add(item.Name);
			}

			if (productNames.size() == 0) {
				return errors;
			}
			ProductTriggerHandler.callRemovePicklistValues(apiName, productNames);

		} catch (Exception ex) {
			errors.add(ex.getMessage());
		}
		System.debug(errors);
		return errors;
	}

	/**
	* ──────────────────────────────────────────────────────
	* Update Product Name from Object API Name (e.g.: Rating_Modifiers__c.Product__c)
	*
	* ──────────────────────────────────────────────────────
	* @param oldItems Map Products from trigger.oldMap
	* @param newItems Map Products from trigger.newMap
	* ──────────────────────────────────────────────────────
	*/
	public static List<String> UpdateProductNameFromObject(String apiName, Map<Id, Product2> oldItems, 
			Map<Id, Product2> newItems) {
		List<String> oldProducts = new List<String>();
		List<String> newProducts = new List<String>();
		List<String> errors = new List<String>();
		try {
			for(String item : newItems.keySet()) {
				// get old Product Name
    			Product2 oldItem = oldItems.get(item);
    			oldProducts.add(oldItem.Name);

    			// get new Product Name
    			Product2 newItem = newItems.get(item);
				newProducts.add(newItem.Name);
			}

			if (oldProducts.size() == 0 || newProducts.size() == 0) {
				errors.add('There\'s no updated product');
				return errors;
			}

			ProductTriggerHandler.callUpdatePicklistValues(apiName, oldProducts, newProducts);

		} catch (Exception ex) {
			errors.add(ex.getMessage());
		}
		System.debug(errors);
		return errors;
	}

	/**
	* ──────────────────────────────────────────────────────
	* Call addPicklistValues function from metadata api
	*
	* Use @future annotation to execute call out from trigger
	* ──────────────────────────────────────────────────────
	* @param apiName apiName name. Must include Object API Name (e.g.: Contract.Product_Name__c) 
	* @param productNames value to be added to picklist
	* ──────────────────────────────────────────────────────
	*/
	@future (callout = true)
	private static void callAddPicklistValues(String apiName, List<String> productNames) {
		List<String> errors = new List<String>();
		try {
			errors = MetadataUtil.addPicklistValues(apiName, productNames);
		} catch (Exception ex) {
			errors.add(ex.getMessage());
		}
		System.debug(errors);
	}

	/**
	* ─────────────────────────────────────────────────────────────
	* Call removePicklistValues function from metadata api
	*
	* Use @future annotation to execute call out from trigger
	* ─────────────────────────────────────────────────────────────
	* @param apiName apiName name. Must include Object API Name (e.g.: Contract.Product_Name__c) 
	* @param productNames value to be remove from picklist
	* ─────────────────────────────────────────────────────────────
	*/
	@future (callout = true)
	private static void callRemovePicklistValues(String apiName, List<String> productNames) {
		List<String> errors = new List<String>();
		try {
			errors = MetadataUtil.removePicklistValues(apiName, productNames);
		} catch (Exception ex) {
			errors.add(ex.getMessage());
		}
		System.debug(errors);
	}

	/**
	* ─────────────────────────────────────────────────────────────
	* Call updatePicklistValues function from metadata api
	*
	* Use @future annotation to execute call out from trigger
	* ─────────────────────────────────────────────────────────────
	* @param apiName apiName name. Must include Object API Name (e.g.: Contract.Product_Name__c) 
	* @param oldProducts value to be remove from picklist
	* @param newProducts value to be added to picklist
	* ─────────────────────────────────────────────────────────────
	*/
	@future (callout = true)
	private static void callUpdatePicklistValues(String apiName, List<String> oldProducts, List<String> newProducts) {
		List<String> errors = new List<String>();
		try {
			errors = MetadataUtil.updatePicklistValues(apiName, oldProducts, newProducts);
		} catch (Exception ex) {
			errors.add(ex.getMessage());
		}
		System.debug(errors);
	}
}