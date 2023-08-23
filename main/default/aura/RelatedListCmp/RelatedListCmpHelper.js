({
    getData: function(component) {
        this.showSpinner(component);
       
		var action = component.get("c.getDataTable");
        action.setParams({
            infoJSON : JSON.stringify({
                        "objectType" : component.get("v.objectType"),
                        "parentRecordId": component.get("v.recordId"),
                        "fields": component.get("v.customColumnsInput"),
                        "orderBy": component.get("v.orderBy"),
                        "recordId": null
            })
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();

                if (result == null) {
                    this.showToast('error', 'No response');
                    this.hideSpinner(component);
                    return;
                }

                // error while retrieving data
                if (!result.isSuccess) {
                    this.showToast('error', result.errors[0]);
                    this.hideSpinner(component);
                    return;
                }

                var table = result.data;
                var allData = table.data;
                // add link for id field
                allData.forEach(function(record) {
                	record.linkName = '/'+record.Id;
                }); 
                console.log(result);
                
				component.set("v.objectPermission", table.permission);
                component.set("v.columns", table.columns);
                component.set("v.allData", allData);
                component.set("v.parentFieldName", table.parentFieldAPI);
                component.set("v.relationshipName", table.relationshipName);
                
                this.hideSpinner(component);
            } else if (state === "ERROR") {
                this.handleResponseError(response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    
  	showRowEditDetails : function(row) {
        var editRecordEvent = $A.get("e.force:editRecord");
		editRecordEvent.setParams({
         "recordId": row.Id
		});
		editRecordEvent.fire();
    },
    handleDeleteAction: function(component, row) {
        var modalBody;
        $A.createComponents([
            ["c:DeleteConfirmationBodyCmp",{}],
            ["c:DeleteConfirmationFooterCmp", 
            {
                "rowId" : row.Id
            }]   
        ],
        function(components, status) {
            if (status === "SUCCESS") {
                var modalBody = components[0];
            	var modalFooter = components[1];
                component.find('overlayLib').showCustomModal({
                    header: "Deleting Confirmation",
                    body: modalBody,
               		footer: modalFooter,
                    showCloseButton: true,
                    cssClass: "mymodal",
                    closeCallback: function() {
                        
                    }
                })
            }
  		});
    },  
    handleDeleteRecord: function(component){
        component.find("objRecordDel").deleteRecord($A.getCallback(function(deleteResult) {
				if (deleteResult.state === "SUCCESS" || deleteResult.state === "DRAFT") {
					
				} else if (deleteResult.state === "INCOMPLETE") {
					//console.log("User is offline, device doesn't support drafts.");
				} else if (deleteResult.state === "ERROR") {
					//console.log('Problem deleting record, error: ' + JSON.stringify(deleteResult.error));
				} else {
					//console.log('Unknown problem, state: ' + deleteResult.state + ', error: ' + JSON.stringify(deleteResult.error));
				}              
		}));
    },
    removeRow: function(component,rowId) {
  		component.set("v.delRecordId", rowId);	
		component.find("objRecordDel").reloadRecord();
    },
    addRow: function(component,rowId) {
  		component.set("v.addRecordId", rowId);	
		component.find("objRecordAdd").reloadRecord();
    },

    sortData: function (component, fieldName, sortDirection) {
        this.showSpinner(component);
        var data = component.get("v.data");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse));
        component.set("v.data", data);
        this.hideSpinner(component);
    },

    sortBy: function (field, reverse, primer) {
        var key = primer ? function(x) {return primer(x[field])} : function(x) {return x[field]};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },

    showSpinner: function (component) {
        var spinner = component.find("spinner");
        $A.util.removeClass(spinner, "slds-hide");
    },

    hideSpinner: function (component) {
        var spinner = component.find("spinner");
        $A.util.addClass(spinner, "slds-hide");
    },

    showToast : function(type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Related List Message',
            message: message,
            duration:' 3000',
            key: 'info_alt',
            type: type,
            mode: 'pester'
        });
        toastEvent.fire();
    },

    handleResponseError: function (helper, errors) {
        if (errors) {
            if (errors[0] && errors[0].message) this.showToast('error', "Error message: " + errors[0].message);
        } else this.showToast('error', 'Unknown error.');
        
        this.hideSpinner(component);
    },
    
})