public with sharing class CommonProductUtil {
    
    /*************************************************
    * Method Name: addProductNameToObject
    * Author: 
    * Date: 
    * Params: String, list<product2>
    * Return: 
    * Exceptions:
    * Description: Add product Name to Object API Name (e.g.: Rating_Modifiers__c.Product__c)
    * Revision: 
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
			callAddPicklistValues(apiName, productNames);

		} catch (Exception ex) {
			errors.add(ex.getMessage());
		}
		System.debug(errors);
		return errors;
	}	

	/*************************************************
    * Method Name: RemoveProductNameFromObject
    * Author: 
    * Date: 
    * Params: String, list<product2>
    * Return: 
    * Exceptions:
    * Description: Remove product Name from Object API Name (e.g.: Rating_Modifiers__c.Product__c)
    * Revision: 
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
			callRemovePicklistValues(apiName, productNames);

		} catch (Exception ex) {
			errors.add(ex.getMessage());
		}
		System.debug(errors);
		return errors;
	}

	/*************************************************
    * Method Name: UpdateProductNameFromObject
    * Author: 
    * Date: 
    * Params: String, list<product2>
    * Return: 
    * Exceptions:
    * Description: Update Product Name from Object API Name (e.g.: Rating_Modifiers__c.Product__c)
    * Revision: 
    */
	public static List<String> updateProductNameFromObject(String apiName, Map<Id, Product2> oldItems, Map<Id, Product2> newItems) {
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

			callUpdatePicklistValues(apiName, oldProducts, newProducts);

		} catch (Exception ex) {
			errors.add(ex.getMessage());
		}
		System.debug(errors);
		return errors;
	}

	
	/*************************************************
    * Method Name: callAddPicklistValues
    * Author: 
    * Date: 
    * Params: String, list<String>
    * Return: 
    * Exceptions:
    * Description: Call addPicklistValues function from metadata api in future context
    * Revision: 
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

	

	/*************************************************
    * Method Name: callRemovePicklistValues
    * Author: 
    * Date: 
    * Params: String, list<String>
    * Return: 
    * Exceptions:
    * Description: Call removePicklistValues function from metadata api in future context
    * Revision: 
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