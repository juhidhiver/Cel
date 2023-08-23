trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert,after insert,after delete) {

    if(!CommonUtil.isTriggerBypass('ContentDocumentLinkTrigger')){
         new ContentDocumentLinkTriggerBaseHandler().run();  
        ContentDocumentLinkTriggerBaseHandler baseHanderObj = new ContentDocumentLinkTriggerBaseHandler();
        baseHanderObj.run(); 
        if( !ContentDocumentLinkTriggerBaseHandler.isBypassed('ContentDocumentLinkTriggerBaseHandler')){
            new ContentDocumentLinkTriggerBaseHandler().runBaseHandler();  
        }
    }
}