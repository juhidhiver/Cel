({
    doInit : function(component) {
        component.set("v.isShowSpinner",true);
        var action = component.get("c.renewalController");
        action.setParams({ 
            policyId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState(); var error = '';
            if (state === "SUCCESS") {
                var resResult =  response.getReturnValue();
                console.log('resResult :'+JSON.stringify(resResult));
                console.log('NEW Opp Id :'+resResult.oppId);
                component.set("v.quoteList",resResult.quoteList);
                component.set("v.clonedOppId",resResult.oppId);
                if(resResult.error){
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
                    this.showToastMsg('error','Error',resResult.error);
                    
                }else{
                    if(resResult.masterBinder.length == 0){
                        this.deleteClonedOpp(component);
                        $A.get("e.force:closeQuickAction").fire();
                        $A.get('e.force:refreshView').fire();
                        this.showToastMsg('warning','Warning','No Primary/Excess Binders to Show');
                    }else{
                        var layer = resResult.layer;
                        console.log('layer',layer);
                        var primaryBinderList = [];
                        var excessBinderList = [];
                        for(var i=0;i<resResult.masterBinder.length;i++){
                            if(resResult.masterBinder[i].Layer__c.includes("Primary")){
                                primaryBinderList.push(resResult.masterBinder[i]);
                            }
                            if(resResult.masterBinder[i].Layer__c.includes("Excess")){
                                excessBinderList.push(resResult.masterBinder[i]);
                            }
                        }
                        
                        if(primaryBinderList.length == 1 && excessBinderList.length ==1){
                            console.log('Auto select binder');
                            component.set('v.rowSelectPrimary',primaryBinderList[0].Id);
                            component.set('v.rowSelectExcess',excessBinderList[0].Id);
                            this.handleRenewal(component);
                        }else{
                            //popUp
                            component.set("v.isShowSpinner",false);
                            console.log('primary size',primaryBinderList.length);
                            console.log('excess  size',excessBinderList.length);
                            if(!layer.includes("Excess")){//Primary
                                console.log('primary');
                                if(primaryBinderList.length > 0){
                                    if(primaryBinderList.length == 1){
                                        component.set('v.rowSelectPrimary',primaryBinderList[0].Id);
                                        this.handleRenewal(component);
                                    }else{
                                        component.set("v.primaryBinderList",primaryBinderList);
                                        component.set("v.isShowBindersPopup",true);
                                        component.set("v.selectedBinderPrimary",true);
                                    }
                                }else{
                                    this.deleteClonedOpp(component);
                                    $A.get("e.force:closeQuickAction").fire();
                                    $A.get('e.force:refreshView').fire();
                                     this.showToastMsg('warning','Warning','Primary binder not available');
                                }
                            }else if(!layer.includes("Primary")){//Excess
                                console.log('excess');
                                if(excessBinderList.length > 0){
                                    if(excessBinderList.length == 1){
                                        component.set('v.rowSelectExcess',excessBinderList[0].Id); 
                                        this.handleRenewal(component);
                                    }else{
                                        component.set("v.excessBinderList",excessBinderList);
                                        component.set("v.isShowBindersPopup",true);
                                        component.set("v.selectedBinderExcess",true);
                                    }

                                }else{
                                    this.deleteClonedOpp(component);
                                    $A.get("e.force:closeQuickAction").fire();
                                    $A.get('e.force:refreshView').fire();
                                     this.showToastMsg('warning','Warning','Excess binder not available');
                                } 
                            }else{
                                //Show both data
                                if(primaryBinderList.length > 0 && excessBinderList.length > 0){
                                    component.set("v.isShowBindersPopup",true);
                                    if(primaryBinderList.length == 1){
                                       component.set("v.isprimaryradio",primaryBinderList[0].Id); 
                                        component.set('v.rowSelectPrimary',primaryBinderList[0].Id);
                                    }
                                    if(excessBinderList.length == 1){
                                        component.set('v.isexcessradio',excessBinderList[0].Id);
                                        component.set('v.rowSelectExcess',excessBinderList[0].Id);
                                    }
                                    component.set("v.primaryBinderList",primaryBinderList);
                                    component.set("v.excessBinderList",excessBinderList);
                                    component.set("v.selectedBinderPrimary",true);
                                    component.set("v.selectedBinderExcess",true);
                                }else{
                                    this.deleteClonedOpp(component);
                                    $A.get("e.force:closeQuickAction").fire();
                                    $A.get('e.force:refreshView').fire();
                                    if(primaryBinderList.length == 0){
                                         this.showToastMsg('warning','Warning','Primary binder not available');
                                    }
                                    if(excessBinderList.length == 0){
                                          this.showToastMsg('warning','Warning','Excess binder not available');
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                error = action.getError()[0].message;
                console.log("Failed with state: " + state +  ", error message: " + error);
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
                this.showToastMsg('error','Error',error);
            }
        });
        
        $A.enqueueAction(action);
    },
    
    handleRenewal : function(component) {
        component.set("v.isShowSpinner",true);
        component.set("v.isShowBindersPopup",false);
        console.log('Primary: ',component.get('v.rowSelectPrimary'));
         console.log('Excess: ',component.get('v.rowSelectExcess'));
        console.log('cloned OPP createRENEWAL quote: ',component.get("v.clonedOppId"));
        var action = component.get("c.createRenewalQuote");
        action.setParams({
            clonedoppId : component.get("v.clonedOppId"),
            policyId : component.get("v.recordId"),
            quoteList: component.get("v.quoteList"),
            binderPrimary: component.get("v.rowSelectPrimary"),
            binderExcess: component.get("v.rowSelectExcess")
        });
        action.setCallback(this, function(response) {
            if (response.getState() == 'SUCCESS') {
                var error = '';
                var result = response.getReturnValue();
                console.log('result-->',JSON.stringify(result));
                if(result.error){
                    this.deleteClonedOpp(component);
                    this.showToastMsg('error','Error',result.error);
                }else{
                    if(result.isSuccess){
                        component.set("v.isPreRate",true);
                        component.set("v.listCloneQuoteId",result.listCloneQuoteId);
                        this.preRateRenewalQuote(component);
                        /*var navEvent = $A.get("e.force:navigateToSObject");
                        navEvent.setParams({
                            recordId: result.oppId,
                            slideDevName: "detail"
                        });
                        navEvent.fire();
                        this.showToastMsg('success','Success','Policy Renewed Successfully.');*/
                        
                    }
                }

            }else{
                this.deleteClonedOpp(component);
                error = action.getError()[0].message;
                this.showToastMsg('error','Error',error);
                console.log("Failed with state: " + state +  ", error message: " + error);
            }
            //$A.get("e.force:closeQuickAction").fire();
            //$A.get('e.force:refreshView').fire();
        });
        $A.enqueueAction(action);

        
    },
    
    preRateRenewalQuote : function(component) {
        // For Rating Renewal Quote
        var listCloneQuoteId = component.get("v.listCloneQuoteId");
        var action = component.get("c.ratingQuoteRenewal");
        action.setParams({
            listQuoteId : listCloneQuoteId
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            console.log('state'+state);
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                console.log('result'+result);
                if(result.errors){
                    this.showToastMsg('error','error',result.errors[0]);
                    var navEvent = $A.get("e.force:navigateToSObject");
                    navEvent.setParams({
                        recordId: component.get("v.clonedOppId"),
                        slideDevName: "detail"
                    });
                    navEvent.fire();
                    this.showToastMsg('success','Success','Policy Renewed Successfully.');
                }
                else{
                    if(result.isSuccess){
                        this.showToastMsg('success','Success','Rated Successfully.');
                        var navEvent = $A.get("e.force:navigateToSObject");
                        navEvent.setParams({
                            recordId: component.get("v.clonedOppId"),
                            slideDevName: "detail"
                        });
                        navEvent.fire();
                        this.showToastMsg('success','Success','Policy Renewed Successfully.');
                    }
                }
                
                
            }else{
                error = action.getError()[0].message;
                console.log("Failed with state: " + state +  ", error message: " + error);
            }
            $A.get("e.force:closeQuickAction").fire();
            $A.get('e.force:refreshView').fire();
        });
        $A.enqueueAction(action);
    },

    deleteClonedOpp : function(component) {
        var action = component.get("c.deleteClonedOpp");
        action.setParams({
            clonedoppId : component.get("v.clonedOppId")
        });
        action.setCallback(this, function(response) {
            if (response.getState() == 'SUCCESS') {
                var error = '';
                var result = response.getReturnValue();
                console.log('result-->',JSON.stringify(result));
                if(result.isSuccess){
                    $A.get("e.force:showToast").setParams({
                        "type": "warning",
                        "title":"Warning",
                        "message":"Renewal is Cancelled."
                    }).fire();
                }else{
                    console.log('No record to delete');
                }
            }else{
                error = action.getError()[0].message;
                console.log("Failed with state: " + state +  ", error message: " + error);
            }
            $A.get("e.force:closeQuickAction").fire();
            $A.get('e.force:refreshView').fire();
            
        });
        $A.enqueueAction(action);
    },
    
    showToastMsg : function(type, title,message) {
        $A.get("e.force:showToast").setParams({
            "type": type,
            "title": title,
            "message": message 
        }).fire();
    }
    
})