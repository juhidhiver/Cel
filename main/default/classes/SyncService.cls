/**
 * @description       : Web Service Class for Calling Sync Callout
 * @author            : JUHI
 * @group             : 
 * @last modified on  : 27-07-2022
 * @last modified by  : JUHI
 * @Reffered in       : SyncQuoteBatch
**/
public class SyncService {
    
    //This method is used to call Sync Quote for Celerity 
    public static void SyncServiceCall_Cel(List<Quote> listQuote){
      SyncServiceHandler_CEL.SyncServiceCall_Cel(listQuote);
    }
   // This method is used to call Sync Quote for AQ
   public static void SyncServiceCall_AQ(List<Quote> listQuote){
      SyncServiceHandler_AQ.SyncServiceCall_AQ(listQuote);
    }
}