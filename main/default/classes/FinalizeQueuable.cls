global with sharing class FinalizeQueuable implements System.Queueable,Database.AllowsCallouts {
    
    global final List<Quote> quo {get; set;}

    global FinalizeQueuable(List<Quote> quo){
        this.quo = quo;
    }
    
    public void execute(QueueableContext info){
       
        if(!quo.isEmpty()){

           Quote finalQ = FinalizeServiceHandler_Common.finalizeAndGenerateDoc(quo[0]);
            system.debug('finalQ-->'+finalQ);
        }
        }
    }