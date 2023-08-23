/**************************************************************************************************
 * Class Name: SubmissionNotesImportBatch_Test
 * Author: Gaurish G
 * Date: 11-Oct-2021
 * Description: Test class of "SubmissionNotesImportBatch" class
 **************************************************************************************************/
@isTest
public class SubmissionNotesImportBatch_Test {
    static testMethod void test1(){
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
        insert product;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        insert opportunity;
        
        Opportunity opportunity1 = TestUtil.createOpportunity('Opp Test1',acc.Id, product.Id);
        insert opportunity1;
        
        TempNoteContent__c tnc = new TempNoteContent__c(Error_Message__c='test',Content__c='test',Title__c='test');
        tnc.SubmissionId__c = opportunity.Id;
        insert tnc;
        
        Test.startTest();
        	SubmissionNotesImportBatch obj = new SubmissionNotesImportBatch();
        	Database.executeBatch(obj);
        Test.stopTest();
    }
}