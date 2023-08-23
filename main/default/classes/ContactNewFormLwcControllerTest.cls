@isTest
public class ContactNewFormLwcControllerTest { 
    @isTest
    public static void testGetRecordTypePicklist() {
        List<PicklistOption> plLst = ContactNewFormLwcController.getRecordTypePicklist();
        System.assertEquals(true, plLst.size() > 0);
    }
}