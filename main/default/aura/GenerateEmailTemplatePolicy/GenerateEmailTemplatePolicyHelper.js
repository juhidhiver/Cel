({
    getEmails : function(component, event) {
        
        var policyId = component.get("v.recordId");
        
        if(!$A.util.isEmpty(policyId)){
            
            var action = component.get("c.getEmailList");
            action.setParams({"policyId":policyId});
            
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
        			var noAssignmentError = '';
                    if(errMsg == 'List has no rows for assignment to SObject'){
                        noAssignmentError = 'Email cannot be sent since no Active Submission/Transaction record found on this Policy';
                        //this.showErrorMsg('Error', 'Email cannot be sent since no Active Submission/Transaction record found on this Policy');
                    }
                     if(errMsg == ''){
                            this.showErrorMsg('Success', 'Sent mail successfully!');
                    	}
                        else if(errMsg == 'List has no rows for assignment to SObject'){
                            this.showErrorMsg('Error', noAssignmentError);
                    	}
                        else{
                            this.showErrorMsg('Error', errMsg);
                        }
                }             
                
            });
            $A.enqueueAction(action);
        }
        
    },
    showErrorMsg : function(title, msg) {
        $A.get("e.force:showToast").setParams({
            "type": "error",
            "title": title,
            "message": msg 
        }).fire();
    },
    getEmailTempaltes : function(component, event) {
        var action = component.get("c.getEmailTemplates");
        var policyId = component.get("v.recordId");
        console.log('policyId:'+policyId);
        action.setParams({"policyId":policyId});
        action.setCallback(this,function(response){
            var loadResponse = response.getReturnValue();
            console.log('templates..!',loadResponse);
            
            if(!$A.util.isEmpty(loadResponse)){

                this.getQuote(component, event,loadResponse)               

                //component.set('v.selTempl',loadResponse[0].Id);
                //var selTempId = component.get("v.selTempl");
                //console.log('selTempl::',selTempId); 
                //this.getTemplate(component, event);
            }
        }); 
        $A.enqueueAction(action);
        
    },
    
    getQuote : function(component, event,loadResponse) {
        var policyId = component.get("v.recordId");
        
        var action1 = component.get("c.getLatestQuote");
        action1.setParams({"policyId":policyId});
        action1.setCallback(this,function(response){
            
            if(response.getState() === "SUCCESS"){
                var quote = response.getReturnValue();
                var templates = loadResponse;
                component.set('v.templatesNames',templates);
                for(var i=0;i<templates.length;i++){
                    if(templates[i].Name=='Bind Amendment Template' || templates[i].Name=='Mid Term Cancellation Template' ||  templates[i].Name=='Flat Cancellation Template' ){
                        if(quote.Quote_Type__c =='Full Amendment' || quote.Quote_Type__c =='Coverage Amendment' || quote.Quote_Type__c=='Policy Duration Change'
                           || quote.Quote_Action__c == 'InsuredAccountUpdate'){
                            if(quote.Layer__c=='Primary'){
                                templates[i].Name = 'Bind Amendment Email'+'-'+'Primary';
                            }else if(quote.Layer__c=='Excess'){
                                templates[i].Name = 'Bind Amendment Email'+'-'+'Excess';   
                            }
                        }
                        else if(quote.Quote_Type__c =='Midterm Cancellation' || quote.Quote_Type__c =='Flat Cancellation'){
                            if(quote.Layer__c=='Primary'){
                                templates[i].Name = 'Bind Cancellation Email'+'-'+'Primary';
                            }else if(quote.Layer__c=='Excess'){
                                templates[i].Name = 'Bind Cancellation Email'+'-'+'Excess';   
                            }
                        }
                    }
                }
                component.set('v.templates',templates);
            }
            

        });
        $A.enqueueAction(action1);

    },
    
    getTemplate : function(component, event) {  
        console.log('Inside get temp helper......');
        var templateId = component.get("v.selTempl");
        var policyId = component.get("v.recordId");
        console.log('policyId='+ policyId);
        console.log('sel templateId='+ templateId);

        component.set("v.fileName", "No File Selected..");
        component.set("v.attFiles", []);

        component.set("v.isLoading", true);
        if(!$A.util.isEmpty(templateId)){
            
            var action = component.get("c.getTemplateDetails");
            action.setParams({"templateId": templateId,
                               "policyId": policyId});
            
            action.setCallback(this,function(response){
                
                var responseVal = response.getReturnValue();
                console.log('responseVal..@getTemplate ',responseVal);
                
                if(!$A.util.isEmpty(responseVal)){                  
                    component.set("v.templDetail",responseVal);
                    component.set("v.isShowTemp",true);                    
                }

                
                var policyId = component.get("v.recordId");
                var action = component.get("c.getPolicyRecordType");
                action.setParams({"policyId":policyId});
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
        var policyId = component.get("v.recordId");
        var templateId = component.get("v.selTempl");
        var templateName = component.get('v.templates').find(template => template.Id == templateId).Name;
        var action = component.get("c.getQuoteDocumentBySubmissionId");
		action.setParams({ 
            "policyId" : policyId,
            templateName : templateName,
            templateId : templateId
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
    getAmendmentTemp : function(component,event,helper){
        var templateId = component.get("v.selTempl");
        var policyId = component.get("v.recordId");
        console.log('policyId='+ policyId);
        console.log('sel templateId='+ templateId);
        
        component.set("v.fileName", "No File Selected..");
        component.set("v.attFiles", []);
        
        component.set("v.isLoading", true);
        if(!$A.util.isEmpty(templateId)){
            
            var action = component.get("c.getTemplateDetails");
            action.setParams({"templateId": templateId,
                              "policyId": policyId});
            
            action.setCallback(this,function(response){
                
                var responseVal = response.getReturnValue();
                console.log('responseVal..@getTemplate ',responseVal);
                
                if(!$A.util.isEmpty(responseVal)){                  
                    component.set("v.templDetail",responseVal);
                    component.set("v.isShowTemp",true);                    
                }
                
                
                var policyId = component.get("v.recordId");
                var action = component.get("c.getPolicyRecordType");
                action.setParams({"policyId":policyId});
                action.setCallback(this, function(response){            
                    if(response.getState() === "SUCCESS"){
                        var recordTypes = response.getReturnValue();
                        console.log('recordTypes @@: -> ' + JSON.stringify(recordTypes));
                        if(recordTypes == 'Aqueous')
                            this.getDocumentsForAmendments(component, event);
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
    getDocumentsForAmendments : function(component,event){
        
        var policyId = component.get("v.recordId");
        var templateId = component.get("v.selTempl");
        var templateName = component.get('v.templates').find(template => template.Id == templateId).Name;
        var action = component.get("c.getAmendmentDocuments");
        action.setParams({ 
            "policyId" : policyId,
            templateName : templateName
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
                    }
                    else{
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
        
    }
})