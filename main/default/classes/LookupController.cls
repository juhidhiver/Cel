/**
 * @File Name          : LookupController.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 5/28/2020, 4:13:27 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    5/28/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public with sharing class LookupController {
    @AuraEnabled(cacheable=true)
  	public static List<sObject> lookUp(String searchTerm, string myObject, String filter) {
        String myQuery = '';
        string recordTypeName;
        if(myObject == 'Contact') recordTypeName = 'Broker';
        
        List<sObject> lookUpList = null;
        if(myObject == 'Account' || myObject == 'Contact') {
            boolean isSosl = true;
            
            List<String> fieldsToReturn = new List<String>{'Id','Name'};
                
                if (myObject == 'Contact'){
                    fieldsToReturn.add('Search_Label__c');
                    fieldsToReturn.add('Account.Appointed__c');
                    fieldsToReturn.add('Account.Pending_By_Aqueous__c');
                } 


                if(filter != null && filter != ''){
                myQuery = 'FIND {' + searchTerm + '}';
                myQuery += ' IN Name Fields';
               // myQuery += ' RETURNING ' + myObject + ' (' + String.join(new List<String>{'Id','Name'}, ', ');
                myQuery += ' RETURNING ' + myObject + ' (' + String.join(fieldsToReturn, ', ');
                myQuery += ' WHERE ' + filter;
                myQuery += ' LIMIT 5';
                myQuery += ')';
            } else {
                if(searchTerm == null || searchTerm == ''){
                    /*
                    myQuery = 'FIND {' + searchTerm + '}';
                    myQuery += ' IN Name Fields';
                    myQuery += ' RETURNING ' + myObject + ' (' + String.join(new List<String>{'Id','Name'}, ', ');
                    myQuery += ' WHERE LastViewedDate != NULL ORDER BY LastViewedDate DESC';
                    myQuery += ' LIMIT 5';
                    myQuery += ')';*/
                    //myQuery = 'Select Id, Name from '+myObject+' Where LastViewedDate != NULL ORDER BY LastViewedDate DESC LIMIT  5'; 
                    if(myObject == 'Account' && String.isNotBlank(recordTypeName)) {
                        myQuery = 'Select Id, Name from '+myObject+' Where LastViewedDate != NULL And RecordType.Name = \'' + recordTypeName + '\' ORDER BY LastViewedDate DESC LIMIT  5'; 
                    } else {
                        myQuery = 'Select Id, Name from '+myObject+' Where LastViewedDate != NULL ORDER BY LastViewedDate DESC LIMIT  5'; 
                    }
                    isSosl = false;
                } else {
                    if(myObject == 'Account' && String.isNotBlank(recordTypeName)){
                        myQuery = 'FIND {' + searchTerm + '}';
                        myQuery += ' IN Name Fields';
                        myQuery += ' RETURNING ' + myObject + ' (' + String.join(new List<String>{'Id','Name'}, ', ');
                        myQuery += ' WHERE RecordType.Name = :recordTypeName';
                        myQuery += ' LIMIT 5';
                        myQuery += ')';                        
                    }else{
                        myQuery = 'FIND {' + searchTerm + '}';
                        myQuery += ' IN Name Fields';
                        myQuery += ' RETURNING ' + myObject + ' (' + String.join(new List<String>{'Id','Name'}, ', ');
                        myQuery += ' LIMIT 5';
                        myQuery += ')';
                    }
                }
            }
            system.debug('myQuery:' + myQuery);            
            //To see recent broker contacts used - 27Oct20 - Khanh
            if(myObject == 'Contact' && (searchTerm == null || searchTerm == '') && filter.contains('RecordType.Name')) {
                isSosl = false;
                myQuery = 'Select Id, Name from '+myObject+' Where ' + filter + ' AND LastViewedDate != NULL ORDER BY LastViewedDate DESC LIMIT  5';  
            }
            
            if(isSosl) {
                if(!Search.query(myQuery).isEmpty()) lookUpList = (sObject[])Search.query(myQuery)[0];
            } else {
                lookUpList = database.query(myQuery);
            }
        } else {
            if(filter != null && filter != ''){
                myQuery = 'Select Id, Name from '+myObject+' Where Name Like  \'%' + searchTerm + '%\' AND '+filter+' LIMIT  5'; 
            }
            else {
                if(searchTerm == null || searchTerm == ''){
                    myQuery = 'Select Id, Name from '+myObject+' Where LastViewedDate != NULL ORDER BY LastViewedDate DESC LIMIT  5'; 
                }
                else {
                    myQuery = 'Select Id, Name from '+myObject+' Where Name Like  \'%' + searchTerm + '%\' LIMIT  5';
                }
            }
            lookUpList = database.query(myQuery);
        }
        system.debug('lookUpList-->'+lookUpList);
        return lookUpList;  
    }
    
    @AuraEnabled(cacheable=true)
    public static sObject getObjectById(String objectId, string myObject) {
      //  String myQuery = 'Select Id, Name from '+myObject+' Where Id = \'' + objectId + '\''; 
        List<String> fieldsToReturn = new List<String>{'Id','Name'};            
        String myQuery = 'Select ' + String.join(fieldsToReturn, ', ') + ' from '+myObject+' Where Id = \'' + objectId + '\''; 

        List<sObject> lookUpList = database.query(myQuery);
        return lookUpList[0];  
    }
    @AuraEnabled
    public static sObject getModifiedRecords(string myObject,string recordId) {
        String myQuery = 'Select Id,Name from user'+' Where Id = \'' + recordId + '\''; 
        system.debug('myQuery'+myQuery);
        List<sObject> lookUpList = database.query(myQuery);
        return lookUpList[0];  
    }
}