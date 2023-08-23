({
    init : function(component, event, helper) {
        helper.getEmails(component, event);
        helper.checkForQuotes(component, event);
        helper.getEmailTempaltes(component, event);
        
        // var oppId = component.get("v.recordId");
        // var action = component.get("c.getOpportunityRecordType");
        // action.setParams({"oppId":oppId});
        // action.setCallback(this, function(response){            
        //     if(response.getState() === "SUCCESS"){
        //         var recordTypes = response.getReturnValue();
        //         console.log('recordTypes @@: -> ' + JSON.stringify(recordTypes));
        //         if(recordTypes == 'FEI')
        //             helper.getDocuments(component, event);
        //     }
        // });
        // $A.enqueueAction(action);  
    }, 
    
    sendEmailAction : function(component, event, helper) {
        console.log('click send');
        helper.sendEmails(component, event);
    },
    
    loadTemplate : function(component, event, helper) {
        console.log('inside load controller....');
        var templateId = component.get("v.selTempl");
        var oppId = component.get("v.recordId");
        var action = component.get("c.getTemplateName");
        action.setParams({templateId:templateId});
        action.setCallback(this, function(response){            
            if(response.getState() === "SUCCESS"){
                var tempName = response.getReturnValue();
                console.log('tempName @@: -> ' + tempName);
                if(tempName == 'Quote Email Excess' || tempName == 'Quote Email Primary'){
                    //var layer = '';
                    //show excess quoted quote list from submission
                    //layer  = (tempName == 'Quote Email Excess') ? 'Excess' : 'Primary'; 
                    //console.log('layer::'+layer);
                    var action = component.get("c.getQuoteList");
                    var result = '';
                    action.setParams({"oppId": oppId, "tempName": tempName});
                    action.setCallback(this, function(response){            
                        if(response.getState() === "SUCCESS"){
                            result = response.getReturnValue();
                            //component.set("v.quoteList", result);
                            console.log('result::'+JSON.stringify(result));
                            console.log('size::'+result.quoteList.length);
                            if(result.quoteList.length == 0){
                                console.log('inside single quote section--'+result.quoteId);
                                component.set("v.selectedQuoteId", result.quoteId);
                                helper.getTemplate(component, event);
                                console.log('result::'+JSON.stringify(result.quoteId));
                            }
                            else if(result.quoteId == ''){
                                console.log('inside list section');
                                component.set("v.quoteList", result.quoteList);
                                component.set('v.mycolumns', [
                                    {label: 'Quote Number', fieldName: 'QuoteNumber', type: 'text'},
                                    {label: 'Name', fieldName: 'Name', type: 'text'},
                                    {label: 'Status', fieldName: 'Status', type: 'text'}
                                ]);
                                component.set("v.isShowQuotes", true);
                                console.log('result::'+JSON.stringify(result.quoteList));
                            }}
                    });
                    $A.enqueueAction(action);
                }
                else if(tempName == 'Hold Cover Email' || tempName == 'Generic Email'){
                    var action = component.get("c.getQuoteList");
                    var result = '';
                    action.setParams({"oppId": oppId, "tempName": tempName});
                    action.setCallback(this, function(response){            
                        if(response.getState() === "SUCCESS"){
                            result = response.getReturnValue();
                            //component.set("v.quoteList", result);
                            console.log('result::'+JSON.stringify(result));
                            console.log('size::'+result.quoteList.length);
                            if(result.quoteList.length == 0){
                                console.log('inside single quote section hold cover--'+result.quoteId);
                                component.set("v.selectedQuoteId", result.quoteId);
                                helper.getTemplate(component, event);
                                console.log('result::'+JSON.stringify(result.quoteId));
                            }
                            else if(result.quoteId == ''){
                                console.log('inside list section hold cover');
                                component.set("v.quoteList", result.quoteList);
                                component.set('v.mycolumns', [
                                    {label: 'Quote Number', fieldName: 'QuoteNumber', type: 'text'},
                                    {label: 'Name', fieldName: 'Name', type: 'text'},
                                    {label: 'Status', fieldName: 'Status', type: 'text'}
                                ]);
                                component.set("v.isShowQuotes", true);
                                console.log('result::'+JSON.stringify(result.quoteList));
                            }}
                    });
                    $A.enqueueAction(action);
                }
                else{
                    helper.getTemplate(component, event);
                }
            }    
        });
        $A.enqueueAction(action);
        
    },
    
    closeDialog : function(component, event, helper)
    {
        helper.cancelAction(component, event);
    },
    
    //Upload files change Attachment
    handleFilesChange: function (component, event, helper) {
        // This will contain the List of File uploaded data and status
        var fileNames =[];
        var uploadFiles = event.getSource().get("v.files");
        //var allFiles;
        //console.log('uploadFiles::'+uploadFiles);
        
        console.log('uploadFiles1=',uploadFiles);
        console.log('uploadFilesLen=',uploadFiles.length);
        
        var errorFile = false;
        [].forEach.call(uploadFiles, function(file) {
            if(file.size == 0) {
                $A.get("e.force:showToast").setParams({
                    "type": "error",
                    "title":  "Error",
                    "message":  "File " + file.name + ' is empty!!'
                }).fire();
                errorFile = true;
            }
            if(file.size > 6291456) {
                $A.get("e.force:showToast").setParams({
                    "type": "error",
                    "title":  "Error",
                    "message":  "File " + file.name + ' 6MB limit exceeded!!'
                }).fire();
                errorFile = true;
            }
            if(errorFile == false) {
                fileNames.push(file.name);
                var reader = new FileReader();
                reader.onloadend =  $A.getCallback(function() {
                    var base64Data = reader.result;
                    var base64 = 'base64,';
                    var dataStart = base64Data.indexOf(base64) + base64.length;
                    base64Data= base64Data.substring(dataStart);
                    var attFiles = component.get("v.attFiles");
                    attFiles.push({
                        FileName:file.name,
                        Body: base64Data,
                        FileType: file.type
                    });
                    component.set("v.attFiles",attFiles);
                    console.log("attFiles",attFiles);
                });
                reader.readAsDataURL(file);
            }
        });
        
        if(errorFile == false) {
            var oldFiles = component.get("v.fileName");
            var uploadFilesName = oldFiles === "No File Selected.."? fileNames.join(", ") : oldFiles + ', ' +  fileNames.join(", ");
            //component.set("v.fileName", fileNames.join(", "));
            component.set("v.fileName", uploadFilesName);
            //component.set("v.files",attFiles);
        }
    },
    
    resetFile: function(component) {
        var resetFile = component.get("v.attFiles");
        component.set("v.attFiles", []);
        component.set("v.fileName", "No File Selected..");
        console.log("resetFile", resetFile);
    },
    previewFile: function(component) {
        console.log("previewFile--------");
    },
    onChangeInput: function(component) {
        console.log('onchange');
        //helper.validateMessage(component, event);
        var errors = [];
        //component.set("v.isLoading", true);
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
            var emailBody = component.get("v.templDetail.HtmlValue");
            console.log('emailBody=',emailBody);
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
            //component.set("v.isLoading", false);
            component.set("v.checkError", true);
            //component.set("v.hideError", false);
            component.set("v.errorMessage", errors); 
            console.log('errors::',errors);
            //return false;
        }else{
            component.set("v.checkError", false);
            errors = [];
        }
        },
            
            chooseQuote: function (component, event, helper) {
                var selectedRows = event.getParam('selectedRows');
                component.set('v.selectedQuoteId',selectedRows[0].Id);
                console.log('selectedQuoteId 4-->'+selectedRows[0].Id); 
                
            },
            clickConfirm : function (component, event, helper) {
                if(component.get("v.selectedQuoteId") == null || component.get("v.selectedQuoteId") == '' || component.get("v.selectedQuoteId") == undefined){
                    helper.showErrorMsg('Error', 'Please select atleast one Quote');
                }
                else{
                    component.set("v.isShowQuotes", false);
                    helper.getTemplate(component, event);
                }
                
            },
            closeModal: function (component, event, helper) {
            component.set("v.isShowQuotes", false);
        	}
            
        })