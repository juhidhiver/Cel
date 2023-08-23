({
    getEmailTempaltes : function(component, event) {
        var action = component.get("c.getEmailTemplates");
        var oppId = component.get("v.recordId");
        console.log('oppId:'+oppId);
        action.setParams({"oppId":oppId});
        action.setCallback(this,function(response){
            var loadResponse = response.getReturnValue();
            console.log('templates..!',loadResponse);
            
            if(!$A.util.isEmpty(loadResponse)){
                
                component.set('v.templates',loadResponse);
                
            }
        });
        $A.enqueueAction(action);
    },
    getEmails : function(component, event) {
        
        var oppId = component.get("v.recordId");
        
        if(!$A.util.isEmpty(oppId)){
            
            var action = component.get("c.getEmailList");
            action.setParams({"oppId":oppId});
            
            action.setCallback(this,function(response){
                var state = response.getState();
			    var errMsg = '';
                //component.set("v.isLoading", false);
                
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    console.log('@@@ getemail result= ' + JSON.stringify(result));
                    if (!result.isSuccess) {
                        errMsg = result.errMsg;
                    } else {
                        component.set('v.emailList',result.data);
                        component.set('v.ccEmailList', result.dataCClist);
                    }
    
                } else {
                    errMsg = action.getError()[0].message;
                    console.log("Failed with state: " + state +  ", error message: " + errMsg);
                }

                //show error
                if (!$A.util.isEmpty(errMsg)) {
                    // Close the action panel and refresh view
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
        
                    // Show toast
                    $A.get("e.force:showToast").setParams({
                        "type": (errMsg == '') ? "success" : "error",
                        "title": (errMsg == '') ? "Success" : "Error",
                        "message": (errMsg == '') ? "Sent mail successfully!" : errMsg
                    }).fire();
                }             
                
            });
            $A.enqueueAction(action);
        }
        
    },
    
    checkForQuotes: function(component, event) {
        
        var oppId = component.get("v.recordId");
         if(!$A.util.isEmpty(oppId)){
            
            var action = component.get("c.checkQuotesEmpty");
            action.setParams({"oppId":oppId});
            
            action.setCallback(this,function(response){
                var state = response.getState();
			    var errMsg = '';
                //component.set("v.isLoading", false);
                
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    console.log('@@@ is quote present==' + result);
                    if(result == false){
                        errMsg = 'Please create a quote before continuing to use the Email Template'
                    }
                } 

                //show error
                if (!$A.util.isEmpty(errMsg)) {
                    // Close the action panel and refresh view
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
        
                    // Show toast
                    $A.get("e.force:showToast").setParams({
                        "type": "error",
                        "title": "Error",
                        "message" : errMsg
                    }).fire();
                }             
                
            });
            $A.enqueueAction(action);
        }
        
    },
    
    validateMessage: function(component, event) {
        
    },

    sendEmails : function(component, event) {
        var errors = [];
        component.set("v.isLoading", true);
        var templateId = component.get("v.selTempl");
        var oppId = component.get("v.recordId");
        var emails = component.get("v.emailList");

        //Upload Attachment
        var attFiles = component.get("v.attFiles");
        console.log("fileListAtt",attFiles);
        
        var jsonAttFiles = [];
        attFiles.forEach(file => {
            jsonAttFiles.push(JSON.stringify(file));
        })
        console.log("JSONfileListAtt",jsonAttFiles);
        //Upload Attachment

        //CC & BCC emails
        var ccEmails = component.get("v.ccEmailList");
        var bccEmails = component.get("v.bccEmailList");
        console.log('ccEmails='+ ccEmails);
        console.log('bccEmails='+ bccEmails);
        //CC & BCC emails

        var emailTemp = component.get("v.templDetail");
        var emailSub = component.get("v.templDetail.Subject");
        //var emailBody = component.get("v.templDetail.HtmlValue");
        console.log('oppId='+ oppId);
        console.log('sel templateId='+ templateId);
        console.log('emailTemp.Subject'+emailTemp.Subject);

        if($A.util.isEmpty(emails)){
            errors.push("SendTo Recepient list cannot be blank");
        }
        if($A.util.isEmpty(emailSub)){
            errors.push("Email Subject cannot be blank");
        }
        /*if($A.util.isEmpty(emailBody)){
            errors.push("Email body cannot be blank");
        }*/
        console.log('errors.length::',errors.length);
        if(errors.length > 0){
            component.set("v.isLoading", false);
            component.set("v.checkError", true);
            //component.set("v.hideError", false);
            component.set("v.errorMessage", errors); 
            return false;
        }

        if((!$A.util.isEmpty(emails) && !$A.util.isEmpty(oppId) 
            && !$A.util.isEmpty(templateId) && !$A.util.isEmpty(emails) && errors.length==0)){                                 
            //console.log('sendEmailTemplate ');
            var action = component.get("c.sendEmailMsg");
            action.setParams({"templateId":templateId,
                                "emailTemp":emailTemp,
                                "emails" : emails.split(';'),
                                "ccEmails": ccEmails,
                                "bccEmails": bccEmails,
                                "attFiles": jsonAttFiles,
                                "recordId": oppId});
            
            action.setCallback(this,function(response){               
                var state = response.getState();
			    var errMsg = '';
                component.set("v.isLoading", false);
                
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    console.log('@@@ sendmail result= ' + JSON.stringify(result));
                    if (!result.isSuccess) {
                        errMsg = result.errMsg;
                    }
    
                } else {
                    errMsg = action.getError()[0].message;
                    console.log("Failed with state: " + state +  ", error message: " + errMsg);
                }
    
                // Close the action panel and refresh view
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
    
                // Show toast
                $A.get("e.force:showToast").setParams({
                    "type": (errMsg == '') ? "success" : "error",
                    "title": (errMsg == '') ? "Success" : "Error",
                    "message": (errMsg == '') ? "Sent mail successfully!" : errMsg
                }).fire();
                
            });
            $A.enqueueAction(action);
        }
        /*else {
            component.set("v.isLoading", false);
            component.set("v.isShowTemp",false);         
            //component.set("v.errorMsg", "Please provide Recipient, Template or Email Body");
        }*/
        
    },
    getTemplate : function(component, event) {       
        var templateId = component.get("v.selTempl");
        var oppId = component.get("v.recordId");
        console.log('oppId='+ oppId);
        console.log('sel templateId='+ templateId);
    	var selectedQuoteId = component.get("v.selectedQuoteId");
    	console.log('selectedQuoteId='+ selectedQuoteId);
		
        component.set("v.fileName", "No File Selected..");
        component.set("v.attFiles", []);

        component.set("v.isLoading", true);
        if(!$A.util.isEmpty(templateId)){
            
            var action = component.get("c.getTemplateDetails");
            action.setParams({"templateId": templateId,
                              "oppId": oppId,
                              "selectQuoteId" : selectedQuoteId});
            
            action.setCallback(this,function(response){
                
                var responseVal = response.getReturnValue();
                console.log('responseVal..@getTemplate ',responseVal);
                
                if(!$A.util.isEmpty(responseVal)){                  
                    component.set("v.templDetail",responseVal);
                    component.set("v.isShowTemp",true);                    
                }

                //
                var oppId = component.get("v.recordId");
                var action = component.get("c.getOpportunityRecordType");
                action.setParams({"oppId":oppId});
                action.setCallback(this, function(response){            
                    if(response.getState() === "SUCCESS"){
                        var recordTypes = response.getReturnValue();
                        console.log('recordTypes @@: -> ' + JSON.stringify(recordTypes));
                        if(recordTypes == 'Aqueous')
                            this.getDocuments(component, event);
                        else 
                            component.set("v.isLoading", false);
                    }
                });
                $A.enqueueAction(action);  
            });
            $A.enqueueAction(action);
        }
        else {
            component.set("v.isLoading", false);
            component.set("v.isShowTemp",false);
        }
    },

    getDocuments : function(component, event) {
        console.log('@@@ ------------- GenrateDoc.getDocument -------------');
        var oppId = component.get("v.recordId");
        var templateId = component.get("v.selTempl");
        var templateName = component.get('v.templates').find(template => template.Id == templateId).Name;
        var selectedQuoteId = component.get("v.selectedQuoteId");
        var action = component.get("c.getQuoteDocumentBySubmissionId");
		action.setParams({ 
            "oppId" : oppId,
            templateName : templateName,
            templateId : templateId,
            selectedQuoteId : selectedQuoteId
        });       
		action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('##state::'+state);
			if (state === "SUCCESS") {
                var resultResponse = response.getReturnValue();
                console.log('##resultResponse::'+resultResponse);
                if(resultResponse === undefined || resultResponse.length === 0)
                    component.set("v.isLoading", false);
                var docLength = resultResponse.length;
                var docCount = 0;
                resultResponse.forEach(result => {
                    console.log('@@@ result getDocument= ' + JSON.stringify(result));
                   
                    if (result.encodeBlobResponse && result.errMsg === undefined) {
                        setTimeout(function() {
                            var binary = atob(result.encodeBlobResponse.replace(/\s/g, ''));
                            var buffer = new ArrayBuffer(binary.length);
                            var view = new Uint8Array(buffer);
                            for (var i = 0; i < binary.length; i++) {
                                view[i] = binary.charCodeAt(i);
                            }
                            var blob = new Blob([view]);
                            component.set("v.documentsFile", blob);

                            var attFiles = component.get("v.attFiles");
                            attFiles.push({
                                FileName:result.docName,
                                Body: result.encodeBlobResponse
                            });
                            
                            var oldFiles = component.get("v.fileName");
                            var uploadFilesName = oldFiles === "No File Selected.."? result.docName : oldFiles + ', ' +  result.docName;
                            component.set("v.fileName", uploadFilesName);
                            component.set("v.attFiles",attFiles);
                            //component.set("v.isLoading", false);
                            docCount++;
                            if(docCount === docLength) {
                                component.set("v.isLoading", false);
                            }
                            
                        }, 500);	
                    } else {
                        docCount++;
                        if(docCount === docLength) {
                            component.set("v.isLoading", false);
                        }
                    }
                })
                
			}
	    });
		$A.enqueueAction(action);
    },

    cancelAction: function(component, event){
        $A.get("e.force:closeQuickAction").fire();
    },
    showErrorMsg : function(title, msg) {
        $A.get("e.force:showToast").setParams({
            "type": "error",
            "title": title,
            "message": msg 
        }).fire();
    }
    
})