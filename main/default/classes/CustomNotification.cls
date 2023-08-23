public with sharing class CustomNotification {
    
    
    Public static void requestSanctionClearance(String targetId , String accName){
        // Get the Id for our custom notification type
        CustomNotificationType notificationType = [SELECT Id, DeveloperName 
                                                    FROM CustomNotificationType 
                                                    WHERE DeveloperName='Sanctions_Notification_AQPI']; 
        
        
        // Create a new custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        
        // Set the contents for the notification
        notification.setTitle('Request Sanction Clearance');
        notification.setBody('A request to clear a potential sanction search Match has been requested for Account: '+accName);
        
        // Set the notification type and target
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(targetId);
        
        set<String> recipientsIds = new Set<String>();
        List<User> userList = [select id, name, email, isactive, profile.name, userrole.name, usertype from user where id 
                               IN(select userorgroupid 
                                  from groupmember 
                                  where group.name = 'AQ Clear Sanctions Request Group')];
        for(User u: userList){
            recipientsIds.add(u.id);
        }
        
        // Actually send the notification
        try {
            notification.send(recipientsIds);
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }
    Public static void notificationApprovingClearance(String targetId , String accName){
        
        CustomNotificationType notificationType = [SELECT Id, DeveloperName 
                                                    FROM CustomNotificationType 
                                                    WHERE DeveloperName='Clear_Sanction_Notify']; 
        
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle('Sanction Review: Cleared');
        notification.setBody('Your request to clear a potential sanction search Match has been authorised for Account: '+accName);
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(targetId);
        
        set<String> recipientsIds = new Set<String>();
        List<User> userList = [select id, name, email, isactive, profile.name, userrole.name, usertype from user where id 
                               IN(select userorgroupid 
                                  from groupmember 
                                  where group.name = 'Notify Sanctions Fail or Clear')];
        for(User u: userList){
            recipientsIds.add(u.id);
        }
      
        try {
            notification.send(recipientsIds);
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }
    
    Public static void notificationDeclineSanction(String targetId , String accName){
        
        CustomNotificationType notificationType = [SELECT Id, DeveloperName 
                                                    FROM CustomNotificationType 
                                                    WHERE DeveloperName='Decline_Sanction_Notify']; 
        
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle('Sanction Review: Confirmed');
        notification.setBody('Your request to clear a potential sanction search Match has been declined for Account: '+accName);
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(targetId);
        
        set<String> recipientsIds = new Set<String>();
        List<User> userList = [select id, name, email, isactive, profile.name, userrole.name, usertype from user where id 
                               IN(select userorgroupid 
                                  from groupmember 
                                  where group.name = 'Notify Sanctions Fail or Clear')];
        for(User u: userList){
            recipientsIds.add(u.id);
        }
        
        try {
            notification.send(recipientsIds);
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }
    
    
    
}