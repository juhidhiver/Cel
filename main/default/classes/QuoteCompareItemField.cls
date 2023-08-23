/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 02-25-2022
 * @last modified by  : Vinayesh
**/
public with sharing class QuoteCompareItemField {
    @AuraEnabled
    public String sourceFieldAPI {get; set;} 
    @AuraEnabled
    public String sourceObject {get; set;}
    @AuraEnabled
    public String endorsementType {get; set;}
    @AuraEnabled 
    public String format {get; set;} 
    // public String customFieldType {get; set;} 
    @AuraEnabled
    public String displayType {get; set;}
    @AuraEnabled
    public String value {get; set;}
    @AuraEnabled
    public String fieldId {get; set;}
    @AuraEnabled
    public String fieldName {get; set;}
    @AuraEnabled
    public String fieldCondition {get; set;}
    @AuraEnabled
    public String fieldRequire {get; set;}
    @AuraEnabled
    public String fieldCriteria {get; set;}
    @AuraEnabled
    public String picklistOption {get; set;}
    @AuraEnabled
    public Boolean isField {get;set;}
    @AuraEnabled
    public Integer index {get;set;}
    @AuraEnabled
    public Boolean readOnly {get;set;}
    // @AuraEnabled
    // public String url {get;set;}
    @AuraEnabled
    public String min {get;set;}
    @AuraEnabled
    public String max {get;set;}
    @AuraEnabled
    public String mainSection {get;set;}
    @AuraEnabled
    public String quoteLayer {get;set;}

    public QuoteCompareItemField() {
        this.readOnly = false;
        this.sourceFieldAPI = '';
        this.endorsementType = '';
        this.sourceObject = '';
        this.format = '';
        // this.customFieldType = '';
        this.displayType = '';
        this.value = '';
        this.fieldId = '';
        this.fieldName = '';
        this.fieldCondition = '';
        this.fieldRequire = '';
        this.pickListOption = '';
        this.isField = false;
        this.index = 0;
        //this.url = '';
        this.min = '';
        this.max = '';
        this.mainSection = '';
        this.quoteLayer = '';
    }
       
    //     public void setProperty(FieldProperty prop) {
    //         this.fieldIds = prop.fieldIds;
    //         this.values = prop.fieldValues;
    //         this.fieldCondition = prop.fieldCondition;
    //         this.fieldRequire = prop.fieldRequire;
    //     }

    // }
}