/* --------------------------------------------------
Strike by Appiphony

Version: 0.10.0
Website: http://www.lightningstrike.io
GitHub: https://github.com/appiphony/Strike-Components
License: BSD 3-Clause License
-------------------------------------------------- */
public with sharing class strike_lookupController {
    @AuraEnabled
    public static String getRecentRecords(String jsonString) {
        system.debug('@@@ ---------------------- strike_lookupController.jsonString ----------------------');
        strike_responseData responseData = new strike_responseData();

        try {
            Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
            Map<Id, RecentlyViewed> recentlyViewedMap = new Map<Id, RecentlyViewed>([SELECT Id
                                                                                     FROM RecentlyViewed
                                                                                     WHERE Type = :((String)jsonMap.get('object'))]);
            List<Id> idList = new List<Id>(recentlyViewedMap.keySet());

            if (idList.size() > 0) {
                String filter = 'Id IN (\'' + String.join(idList, '\',\'') + '\')';

                if (strike_lookupController.fieldNotEmpty(jsonMap, 'filter')) {
                    filter += ' AND (' + jsonMap.get('filter') + ')';
                }

                jsonMap.put('filter', filter);

                responseData.results = getData(jsonMap);
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
        system.debug('@@@ ---------------------- strike_lookupController.getRecordLabel ----------------------');
        strike_responseData responseData = new strike_responseData();

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
        system.debug('@@@ ---------------------- strike_lookupController.getRecords ----------------------');
        strike_responseData responseData = new strike_responseData();
        
        try {
            Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
            system.debug('@@@ jsonMap= ' + jsonMap);
            responseData.results = getData(jsonMap);
            system.debug('@@@ responseData.results= ' + responseData.results);
        } catch (Exception e) {
            responseData.addError(e.getMessage());
        }

        return responseData.getJsonString();
    }

    /*private static Map<String, Object> getData(Map<String, Object> jsonMap) {
        system.debug('@@@ ---------------------- strike_lookupController.getData ----------------------');
        List<Map<String, Object>> data = new List<Map<String, Object>>();

        String objType = String.escapeSingleQuotes((String)jsonMap.get('object'));
        String query = strike_lookupController.getQuery(jsonMap);
        String searchField = String.escapeSingleQuotes((String)jsonMap.get('searchField'));
        String searchTerm = '';
        String subtitleField;

        system.debug('@@@ strike_lookupController.getData.objType= ' + objType);
        system.debug('@@@ strike_lookupController.getData.query= ' + query);
        system.debug('@@@ strike_lookupController.getData.searchField= ' + searchField);
        
        system.debug('@@@ strike_lookupController.getData.objType= ' + objType);

        if (strike_lookupController.fieldNotEmpty(jsonMap, 'subtitleField')) {
            subtitleField = String.escapeSingleQuotes((String)jsonMap.get('subtitleField'));
        }
        system.debug('@@@ strike_lookupController.getData.subtitleField= ' + subtitleField);

        if (strike_lookupController.fieldNotEmpty(jsonMap, 'searchTerm')) {
            searchTerm = String.escapeSingleQuotes((String)jsonMap.get('searchTerm'));
        }
        system.debug('@@@ strike_lookupController.getData.searchTerm= ' + searchTerm);

        if (String.isEmpty(subtitleField)) {
            for (sObject obj : Database.query(query)) {
                data.add(new Map<String, Object>{
                    'label' => strike_lookupController.getValue(obj, objType, searchField),
                    'value' => obj.get('Id')
                });
            }
        } else {
            for (sObject obj : Database.query(query)) {
                data.add(new Map<String, Object>{
                    'label' => strike_lookupController.getValue(obj, objType, searchField),
                    'sublabel' => strike_lookupController.getValue(obj, objType, subtitleField),
                    'value' => obj.get('Id')
                });
            }
        }

        return new Map<String, Object>{
                   'data' => data,
                   'searchTerm' => searchTerm
        };
    }*/

    /*private static Map<String, Object> getData(Map<String, Object> jsonMap) {
        system.debug('@@@ ---------------------- strike_lookupController.getData ----------------------');
        List<Map<String, Object>> data = new List<Map<String, Object>>();

        String searchTerm = '';
        if (strike_lookupController.fieldNotEmpty(jsonMap, 'searchTerm')) {
            searchTerm = String.escapeSingleQuotes((String)jsonMap.get('searchTerm'));
        }
        String country ='';
        if (strike_lookupController.fieldNotEmpty(jsonMap, 'country')) {
            country = String.escapeSingleQuotes((String)jsonMap.get('country'));
        }
        system.debug('@@@ strike_lookupController.getData.searchTerm= ' + searchTerm);

        //List<AddLocationController.DisplayResult> results = AddLocationController.searchLocation(searchTerm, country);
        List<AddLocationController.DisplayResult> results = AddLocationController.searchLocation(searchTerm);
        if (results != null && !results.isEmpty()) {
            for (AddLocationController.DisplayResult result : results) {
                data.add(new Map<String, Object>{
                    'label' => result.address,
                    'sublabel' => result.addressFull,
                    'value' => result.uniqueKey,
                    'resultString' => JSON.serialize(result)
                });
            }
        }   

        return new Map<String, Object>{
           'data' => data,
           'searchTerm' => searchTerm
        };
    }*/

    private static Map<String, Object> getData(Map<String, Object> jsonMap) {
        system.debug('@@@ ---------------------- strike_lookupController.getData ----------------------');
        List<Map<String, Object>> data = new List<Map<String, Object>>();

        String searchTerm = '';
        if (strike_lookupController.fieldNotEmpty(jsonMap, 'searchTerm')) {
            searchTerm = String.escapeSingleQuotes((String)jsonMap.get('searchTerm'));
        }
        
        system.debug('@@@ strike_lookupController.getData.searchTerm= ' + searchTerm);

        
        AddLocationController.LocationResponse locationRes = AddLocationController.searchLocation(searchTerm);
        System.debug('###locationRes=='+ locationRes);

        if (locationRes != null && !locationRes.predictions.isEmpty()) {
            for (AddLocationController.LocationResult result : locationRes.predictions) {
                data.add(new Map<String, Object>{
                    'label' => result.description,
                    'placeId' => result.place_id
                });
            }
        }

        return new Map<String, Object>{
           'data' => data,
           'searchTerm' => searchTerm
        };
    }

    /*private static String getQuery(Map<String, Object> jsonMap) {
        system.debug('@@@ ---------------------- strike_lookupController.getQuery ----------------------');
        Set<String> queryFields = new Set<String>{'Id'};
        List<String> filters = new List<String>();
        List<String> orders = new List<String>();

        String query;
        String obj = String.escapeSingleQuotes((String)jsonMap.get('object'));
        String subtitleField;

        if (strike_lookupController.fieldNotEmpty(jsonMap, 'subtitleField')) {
            subtitleField = String.escapeSingleQuotes((String)jsonMap.get('subtitleField'));
            queryFields.add(subtitleField);
        }

        if (strike_lookupController.fieldNotEmpty(jsonMap, 'searchField')) {
            queryFields.add(String.escapeSingleQuotes((String)jsonMap.get('searchField')));

            if (strike_lookupController.fieldNotEmpty(jsonMap, 'searchTerm')) {
                String searchField = String.escapeSingleQuotes((String)jsonMap.get('searchField'));
                String searchTerm = String.escapeSingleQuotes((String)jsonMap.get('searchTerm'));
                filters.add(searchField + ' LIKE \'%' + searchTerm + '%\'');
            }
        }

        if (strike_lookupController.fieldNotEmpty(jsonMap, 'filter')) {
            filters.add('(' + (String)jsonMap.get('filter') + ')');
        }

        // Huy add custom logic
        // Filter by record type
        if (strike_lookupController.fieldNotEmpty(jsonMap, 'recordTypeName')) {
            String recordTypeName = String.escapeSingleQuotes((String)jsonMap.get('recordTypeName'));
            filters.add('(RecordType.Name = ' + '\'' + recordTypeName + '\')');
        }

        // Filter by parent record Id (if exist)
        if (strike_lookupController.fieldNotEmpty(jsonMap, 'parentId')
        && (strike_lookupController.fieldNotEmpty(jsonMap, 'parentRelationshipField'))) {
            String parentId = String.escapeSingleQuotes((String)jsonMap.get('parentId'));
            String parentRelationshipField = String.escapeSingleQuotes((String)jsonMap.get('parentRelationshipField'));
            filters.add('(' + parentRelationshipField + ' = ' + '\'' + parentId + '\')');
        }
        // Huy end add custom logic

        system.debug('@@@ strike_lookupController.getQuery.filters final= ' + filters);
        if (strike_lookupController.fieldNotEmpty(jsonMap, 'order')) {
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

        if (strike_lookupController.fieldNotEmpty(jsonMap, 'limit')) {
            query += ' LIMIT ' + String.escapeSingleQuotes((String)jsonMap.get('limit'));
        }

        return query;
    }*/

    private static Boolean fieldNotEmpty(Map<String, Object> jsonMap, String field) {
        system.debug('@@@ ---------------------- strike_lookupController.fieldNotEmpty ----------------------');
        return jsonMap.containsKey(field) && !String.isEmpty((String)jsonMap.get(field));
    }

    /*private static String getValue(SObject obj, String objectType, String field) {
        system.debug('@@@ ---------------------- strike_lookupController.getValue ----------------------');
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
    }*/
}
/* --------------------------------------------------
Copyright 2017 Appiphony, LLC

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the 
following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following 
disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following 
disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote 
products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-------------------------------------------------- */