({
	getcolumns: function (component) {
        component.set('v.columns', [
			{label: 'Product', fieldName: 'product', type: 'text' ,editable: false},
		    {label: 'Page Section', fieldName: 'pageSection', type: 'text' ,editable: false},
            {label: 'Sub Section', fieldName: 'subSection', type: 'text' ,editable: false},
		   	{label: 'Sort Order', fieldName: 'sortNo', type: 'number' ,editable: true} 
        ]);
    },
    fetchData: function (component) {
  		var action = component.get("c.getSortSubSections");
		action.setParams({"objId" : component.get("v.recordId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                component.set('v.data',data);
				//console.log('v.id:' + component.get("v.id"));
            }
            // error handling when state is "INCOMPLETE" or "ERROR"
        });
        $A.enqueueAction(action);
    }
})