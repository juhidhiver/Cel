@isTest
public class GlobalStaticVarTest {
    @isTest static void globalStaticTest(){
        GlobalStaticVar.byPassQuoteTrigger = false;
        GlobalStaticVar.byPassQuoteTrigger = false;
         GlobalStaticVar.byPassSubjectivityTrigger = false;
         GlobalStaticVar.byPassSubjectivityTrigger = false;
        System.assert(GlobalStaticVar.byPassQuoteTrigger != null);
    }
}