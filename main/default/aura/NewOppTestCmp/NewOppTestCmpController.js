({
    toastInfo:function (component, event, helper) {
        console.log('Message Event ' + JSON.stringify(event));
        var str = event.getParams().message;
        console.log('Message String ' + str);
        var index1 = str.lastIndexOf('Account' + ' "');
        var index2 = str.lastIndexOf('" was created.');
        var mySubString = str.substring(index1 + 'Account'.length + 2,  index2);
        component.set("v.toastMessage", mySubString);
        var action = component.get("c.getNewObjIdFromToast");
        action.setParams({ objName : 'Account',objNameValue :  mySubString });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
              component.set("v.createdRecord",{Name:mySubString, Id:response.getReturnValue()});
              console.log('New Record Created ' + JSON.stringify({Name:mySubString, Id:response.getReturnValue()}));
            }
        });
        $A.enqueueAction(action);
    }
})