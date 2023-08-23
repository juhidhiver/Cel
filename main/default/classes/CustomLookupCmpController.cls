public with sharing class CustomLookupCmpController {
    @AuraEnabled
    public static String getRecentRecords(String jsonString) {
        CustomLookupResponseData responseData = new CustomLookupResponseData();

        try {
            Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
            Map<Id, RecentlyViewed> recentlyViewedMap = new Map<Id, RecentlyViewed>([SELECT Id
                                                                                     FROM RecentlyViewed
                                                                                     WHERE Type = :((String)jsonMap.get('object'))]);
            
            List<Id> idList = new List<Id>(recentlyViewedMap.keySet());

            if (idList.size() > 0) {
                String filter = 'Id IN (\'' + String.join(idList, '\',\'') + '\')';

                if (CustomLookupCmpController.fieldNotEmpty(jsonMap, 'filter')) {
                    filter += ' AND (' + jsonMap.get('filter') + ')';
                }

                jsonMap.put('filter', filter);

                responseData.results = CustomLookupCmpController.getData(jsonMap);
            } else {
                responseData.results = new Map<String, Object>{
                    'data' => new List<String>(),
                    'searchTerm' => ''
                };
            }
        } catch (Exception e) {
            responseData.addError(e.getMessage());
        }

        return responseData.getJsonString();
    }

    @AuraEnabled
    public static String getRecordLabel(String jsonString) {
        CustomLookupResponseData responseData = new CustomLookupResponseData();

        try {
            Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(jsonString);

            String obj = (String)jsonMap.get('object');
            String objectLabel = Schema.describeSObjects(new List<String>{obj})[0].getLabel();

            responseData.results.put('objectLabel', objectLabel);
        } catch (Exception e) {
            responseData.addError(e.getMessage());
        }

        return responseData.getJsonString();
    }

    @AuraEnabled
    public static String getRecords(String jsonString) {
        CustomLookupResponseData responseData = new CustomLookupResponseData();

        
        try {
            Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
            responseData.results = CustomLookupCmpController.getData(jsonMap);
        } catch (Exception e) {
            responseData.addError(e.getMessage());
        }

        return responseData.getJsonString();
    }

    private static Map<String, Object> getData(Map<String, Object> jsonMap) {
        List<Map<String, Object>> data = new List<Map<String, Object>>();
        String subtitleField;
        String searchTerm = '';
        String objType = String.escapeSingleQuotes((String)jsonMap.get('object'));
        String searchField = String.escapeSingleQuotes((String)jsonMap.get('searchField'));
        if (CustomLookupCmpController.fieldNotEmpty(jsonMap, 'subtitleField')) {
            subtitleField = String.escapeSingleQuotes((String)jsonMap.get('subtitleField'));
        }
        if (CustomLookupCmpController.fieldNotEmpty(jsonMap, 'searchTerm')) {
            searchTerm = String.escapeSingleQuotes((String)jsonMap.get('searchTerm'));
        }
        List<SObject> results = new List<SObject>();
        String query = '';
        //Using SOSLQuery for Encryption
        if((objType == 'Account' || objType == 'Contact') && searchField =='Name'){
            query = CustomLookupCmpController.getQuerySOSL(jsonMap);
            if(!Search.query(query).isEmpty()) results = (sObject[])Search.query(query)[0];
            System.debug('>>>results>>>'+results);
        }else{
            query = CustomLookupCmpController.getQuery(jsonMap);
            results = Database.query(query);
        }
        System.debug('Query String' + query);
        if (String.isEmpty(subtitleField)) {
            for (sObject obj : results) {
                data.add(new Map<String, Object>{
                    'label' => CustomLookupCmpController.getValue(obj, objType, searchField),
                    'value' => obj.get('Id')
                });
            }
        } else {
            for (sObject obj :results) {
                data.add(new Map<String, Object>{
                    'label' => CustomLookupCmpController.getValue(obj, objType, searchField),
                    'sublabel' => CustomLookupCmpController.getValue(obj, objType, subtitleField),
                    'value' => obj.get('Id')
                });
            }
        }

        return new Map<String, Object>{
                   'data' => data,
                   'searchTerm' => searchTerm
        };
    }

    private static String getQuery(Map<String, Object> jsonMap) {
        Set<String> queryFields = new Set<String>{'Id'};
        List<String> filters = new List<String>();
        List<String> orders = new List<String>();

        String query;
        String obj = String.escapeSingleQuotes((String)jsonMap.get('object'));
        String subtitleField;

        if (CustomLookupCmpController.fieldNotEmpty(jsonMap, 'subtitleField')) {
            subtitleField = String.escapeSingleQuotes((String)jsonMap.get('subtitleField'));
            queryFields.add(subtitleField);
        }

        if (CustomLookupCmpController.fieldNotEmpty(jsonMap, 'searchField')) {
            queryFields.add(String.escapeSingleQuotes((String)jsonMap.get('searchField')));

            if (CustomLookupCmpController.fieldNotEmpty(jsonMap, 'searchTerm')) {
                String searchField = String.escapeSingleQuotes((String)jsonMap.get('searchField'));
                String searchTerm = String.escapeSingleQuotes((String)jsonMap.get('searchTerm'));

                filters.add(searchField + ' LIKE \'%' + searchTerm + '%\'');
            }
        }

        if (CustomLookupCmpController.fieldNotEmpty(jsonMap, 'filter')) {
            filters.add('(' + (String)jsonMap.get('filter') + ')');
        }

        if (CustomLookupCmpController.fieldNotEmpty(jsonMap, 'order')) {
            orders.add(String.escapeSingleQuotes((String)jsonMap.get('order')));
        }

        query = 'SELECT ' + String.join(new List<String>(queryFields), ', ');
        query += ' FROM ' + obj;

        if (filters.size() > 0) {
            query += ' WHERE ' + String.join(filters, ' AND ');
        }

        if (orders.size() > 0) {
            query += ' ORDER BY ' + String.join(orders, ', ');
        }

        if (CustomLookupCmpController.fieldNotEmpty(jsonMap, 'limit')) {
            query += ' LIMIT ' + String.escapeSingleQuotes((String)jsonMap.get('limit'));
        }

        return query;
    }

    private static String getQuerySOSL(Map<String, Object> jsonMap) {
        String mainSearchField = '';
        String mainSearchTerm = '';
        Set<String> queryFields = new Set<String>{'Id'};
        List<String> orders = new List<String>();

        String query;
        String obj = String.escapeSingleQuotes((String)jsonMap.get('object'));
        String subtitleField;

        if (CustomLookupCmpController.fieldNotEmpty(jsonMap, 'subtitleField')) {
            subtitleField = String.escapeSingleQuotes((String)jsonMap.get('subtitleField'));
            queryFields.add(subtitleField);
        }

        if (CustomLookupCmpController.fieldNotEmpty(jsonMap, 'searchField')) {
            queryFields.add(String.escapeSingleQuotes((String)jsonMap.get('searchField')));
            String searchField = String.escapeSingleQuotes((String)jsonMap.get('searchField'));
            mainSearchField = searchField;
            if (CustomLookupCmpController.fieldNotEmpty(jsonMap, 'searchTerm')) {
                String searchTerm = String.escapeSingleQuotes((String)jsonMap.get('searchTerm'));
                mainSearchTerm = searchTerm;
            }
        }

        if (CustomLookupCmpController.fieldNotEmpty(jsonMap, 'order')) {
            orders.add(String.escapeSingleQuotes((String)jsonMap.get('order')));
        }

        if(String.isNotBlank(mainSearchField)) {
            query = 'FIND {' + mainSearchTerm + '}';
            query += ' IN ' + mainSearchField + ' Fields';
            query += ' RETURNING ' + obj + ' (' + String.join(new List<String>(queryFields), ', ');
            if (CustomLookupCmpController.fieldNotEmpty(jsonMap, 'filter')) {
                System.debug('@@@filter: ' + CustomLookupCmpController.fieldNotEmpty(jsonMap, 'filter'));
                query += ' WHERE ' + (String)jsonMap.get('filter');
            }

            /*if (orders.size() > 0) {
                query += ' ORDER BY ' + String.join(orders, ', ');
            }*/
            if (CustomLookupCmpController.fieldNotEmpty(jsonMap, 'limit')) {
                query += ' LIMIT ' + String.escapeSingleQuotes((String)jsonMap.get('limit'));
            }
            query += ')';
        }
        return query;
    }

    private static Boolean fieldNotEmpty(Map<String, Object> jsonMap, String field) {
        return jsonMap.containsKey(field) && !String.isEmpty((String)jsonMap.get(field));
    }

    private static String getValue(SObject obj, String objectType, String field) {
        List<String> fieldPath = field.split('[.]');
        Object label = strike_utilities.convertObjectToMap(obj);
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectType).getDescribe().fields.getMap();

        for (String fieldName : fieldPath) {
            fieldName = fieldName.replaceAll('__r$', '__c');

            label = ((Map<String, Object>)label).get(fieldName);

            if (label == null) {
                return '';
            }

            if (fieldMap.containsKey(fieldName + 'Id')) {
                fieldName = fieldName + 'Id';
            }

            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
            String fieldType = String.valueOf(fieldDescribe.getType()).toUpperCase();

            if (fieldType == 'REFERENCE') {
                fieldMap = Schema.getGlobalDescribe().get(String.valueOf(fieldDescribe.getReferenceTo().get(0))).getDescribe().fields.getMap();
            } else if (fieldType == 'ADDRESS') {
                List<String> addressComponents = new List<String>();
                Map<String, Object> addr = (Map<String, Object>)label;

                if (addr.containsKey('street') && addr.get('street') != null) {
                    addressComponents.add((String)addr.get('street'));
                }

                if (addr.containsKey('city') && addr.get('city') != null) {
                    addressComponents.add((String)addr.get('city'));
                }

                if (addr.containsKey('state') && addr.get('state') != null) {
                    addressComponents.add((String)addr.get('state'));
                }

                if (addr.containsKey('country') && addr.get('country') != null) {
                    addressComponents.add((String)addr.get('country'));
                }

                if (addr.containsKey('postalCode') &&addr.get('postalCode') != null) {
                    addressComponents.add((String)addr.get('postalCode'));
                }

                // change later for user formatting?
                label = String.join(addressComponents, ', ');
            }
        }

        return String.valueOf(label);
    }

    @AuraEnabled (cacheable=true)
    public static String getNewObjIdFromToast(String objName,String objNameValue) 
	{
        try{
            String condition = 'Name =:objNameValue ORDER BY CreatedDate Desc limit 1';
            List<SObject> getList = Database.query( CommonUtil.buildQuery(new List<String>{'Id'}, objName, condition) );
            return (!getList.isEmpty()) ? getList[0].Id : '';
        }catch (Exception e){
            System.debug(e.getMessage());
        }
        return null;
    }

	@AuraEnabled
    public static String getObjLabel(String objAPINAme) {
        return ((SObject)Type.forName(objAPINAme).newInstance()).getSObjectType().getDescribe().getLabel();
    }
}