({
	doInit : function(component) {
		console.log('@@@ ------------- GenrateDoc.getDocument -------------');
		component.set("v.isLoading", true);
		var action = component.get("c.getDocumentEncode");
		action.setParams({ 
			docId : component.get("v.recordId")
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				var result = response.getReturnValue();
				console.log('@@@ result getDocument= ' + JSON.stringify(result));
				if (result.encodeBlobResponse) {
		        	setTimeout(function() {
		        		var binary = atob(result.encodeBlobResponse.replace(/\s/g, ''));
						var buffer = new ArrayBuffer(binary.length);
						var view = new Uint8Array(buffer);
						for (var i = 0; i < binary.length; i++) {
							view[i] = binary.charCodeAt(i);
						}
						var blob = new Blob([view]);
						var url = URL.createObjectURL(blob);
						var link = document.createElement('a');
						link.href = url;
						link.download = result.docName;
						link.click();
		        	}, 500);	
				}
		        component.set("v.isLoading", false);
				$A.get("e.force:closeQuickAction").fire();
				$A.get("e.force:showToast").setParams({
					"type": (!result.errMsg) ? "success" : "error",
		            "title": (!result.errMsg) ? "Success" : "Error",
		            "message": (!result.errMsg) ? "Document has been downloaded sucessfully!" : result.errMsg
		        }).fire();
		        $A.get('e.force:refreshView').fire();
			}
	    });
		$A.enqueueAction(action);
	}
})