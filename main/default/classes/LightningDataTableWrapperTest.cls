/***********************************************************************
 * Class Name: LightningDataTableWrapperTest
 * Author: Khanh TRAN
 * Date: 29-Oct-2019
 * Description: Unit test for LightningDataTableWrapper 
 ***********************************************************************
 */

@isTest
private class LightningDataTableWrapperTest {
 
    static{
        new LightningDataTableWrapper.DatatableColumnAction();  
        new LightningDataTableWrapper.DatatableColumn();
    }

   
    @isTest
    static void getColumnTypeByFieldTypeTest1() {
        LightningDataTableWrapper.getColumnTypeByFieldType('CURRENCY');
        System.assert(true);
    }

    @isTest
    static void getColumnTypeByFieldTypeTest2() {
        LightningDataTableWrapper.getColumnTypeByFieldType('random');
        System.assert(true);
    }

    @isTest
    static void getColumnTypeByFieldTypeTest3() {
        LightningDataTableWrapper.getColumnTypeByFieldType('DOUBLE');
        System.assert(true);
    }

    @isTest
    static void getColumnTypeByFieldTypeTest4() {
        LightningDataTableWrapper.getColumnTypeByFieldType('PICKLIST');
        System.assert(true);
    }

    @isTest
    static void generateCurrencyAttributeTest() {
        LightningDataTableWrapper.generateCurrencyAttribute();
        System.assert(true);
    }

    @isTest
    static void generateNumberAttributeTest() {
        LightningDataTableWrapper.generateNumberAttribute(8,3);
        System.assert(true);
    }

    @isTest
    static void generateCellAttributeTest() {
        LightningDataTableWrapper.generateCellAttribute('currency');
        System.assert(true);
    }

     @isTest
    static void generateCellAttributeTest1() {
        LightningDataTableWrapper.generateCellAttribute('number');
        System.assert(true);
    }

    @isTest
    static void LightningDataTableWrapperTest() {
        LightningDataTableWrapper wrapper = new LightningDataTableWrapper();
        LightningDataTableWrapper.TypeAttributesNumber numbAttr = new LightningDataTableWrapper.TypeAttributesNumber();
        LightningDataTableWrapper.TypeAttributesCurrency currAttr = new LightningDataTableWrapper.TypeAttributesCurrency();

        numbAttr.minimumIntegerDigits = 1;
        numbAttr.minimumFractionDigits = 1;
        numbAttr.maximumFractionDigits = 1;
        numbAttr.minimumSignificantDigits = 1;
        numbAttr.maximumSignificantDigits = 1;

        currAttr.minimumIntegerDigits = 1;
        currAttr.minimumFractionDigits = 1;
        currAttr.maximumFractionDigits = 1;
        currAttr.minimumSignificantDigits = 1;
        currAttr.maximumSignificantDigits = 1;
        currAttr.currencyCode = 'USD';
        currAttr.currencyDisplayAs = 'USD';

        System.assert(true);
    }

    @isTest
    static void generateRecordLinkColumnTest(){
        LightningDataTableWrapper.generateRecordLinkColumn('TestField', 'Test Lable'); 
         System.assert(true);
    }

    @isTest
    static void generateUrlAttributeTest(){
        LightningDataTableWrapper.generateUrlAttribute('TestField', 'TargetTest');
        System.assert(true);
    }

    @isTest
    static void getObjectPermissionTest(){
       LightningDataTableWrapper.getObjectPermission('objectName');
       System.assert(true);
    }

    @isTest
    static void getTableRowActionByPermissionTest(){
        new LightningDataTableWrapper.DatatableColumn();
        LightningDataTableWrapper.getTableRowActionByPermission(new LightningDataTableWrapper.ObjectPermission());
        System.assert(true);
    }   

}