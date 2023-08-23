({
    doInit: function (component, event, helper) {
        // component.set("v.accountId", '');
        // component.set("v.sobject", '');
        var pageRef = component.get("v.pageReference");
        console.log(JSON.stringify(pageRef));
        var state = pageRef.state; // state holds any query params
        console.log('state = ' + JSON.stringify(state));
        var base64Context = state.inContextOfRef;
        console.log('base64Context = ' + base64Context);
        if (base64Context.startsWith("1\.")) {
            base64Context = base64Context.substring(2);
            console.log('base64Context = ' + base64Context);
        }
        var addressableContext = JSON.parse(window.atob(base64Context));
        console.log('addressableContext = ' + JSON.stringify(addressableContext));
        component.set("v.accountId", addressableContext.attributes.recordId);
        component.set("v.sobject", addressableContext.attributes.objectApiName);
    },
    reInit : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    }
})