/**************************************************************************************************
 * Class Name: CloseOpportunityBatchSchedulebleTest
 * Author: Hoang Bui
 * Date: 21-Oct-2019
 * Description: CloseOpportunityBatchSchedulebleTest Test
 **************************************************************************************************/
@isTest
private class CloseOpportunityBatchSchedulebleTest {
    
    @isTest static void ContructorTest() {
        CloseOpportunityBatchScheduleble sche = new CloseOpportunityBatchScheduleble();
        // Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        String schTime = '20 30 8 10 2 ?';
        String jobID = System.schedule('Test Close Opportunity', schTime, sche); 
    }
}