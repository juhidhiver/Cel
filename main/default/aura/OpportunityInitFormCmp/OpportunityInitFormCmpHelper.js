({
	 openNewOpportunity : function(component, event, helper){
        //console.log("recordId="+component.get("v.recordId"));
        var newOpportunityEvent = $A.get("e.force:createRecord");
        var recordTypeId = component.get("v.recordTypeId");
        var productId = component.find('ProductName').get("v.value");
        var accountId = component.find('AccountId').get("v.value");
        
        //lookup name
        var action = component.get("c.getOpportunityInfo");
        action.setParams({
            accId : accountId, 
            productId : productId 
        });
        action.setCallback(this, function(response){
            //console.log('response.getState()='+response.getState());            
            if(response.getState() === "SUCCESS"){
                var oppInf = response.getReturnValue();
               	//console.log(oppInf);
                var closeDate = helper.addDate(new Date(),90,0,0);//Today + 90
                var effDate = helper.addDate(new Date(),1,0,0);//Today + 1
                var expDate = helper.addDate(effDate,0,0,1); //EffDate + 1 year
                var recDate = helper.addDate(new Date(),0,0,0);// Today 
                newOpportunityEvent.setParams({
                    "entityApiName": "Opportunity",
					//"navigationLocation":"LOOKUP",
                    "defaultFieldValues": {
                        'RecordTypeId' : recordTypeId,
                        'Product__c' : productId,
                        'AccountId' : accountId,
                        'Attachment_Point__c' : 'Primary',
                        //'Coverage_Product_Options__c': coverageProduct,
                        'Name' : oppInf.oppName,
                        'StageName': 'New',
                        'CloseDate': closeDate,
                        'Effective_Date__c' : effDate,
                        'Expiration_Date__c' : expDate,
                        'Received_Date__c' : recDate,
                        'AnnualRevenue__c' : oppInf.accInf.AnnualRevenue, 
                        'Cash_Flow_From_Operating_Activities__c' : oppInf.accInf.CashFlowFromOperatingActivities, 
                        'Current_Assets__c' : oppInf.accInf.CurrentAssets,
                        'Current_Liabilities__c': oppInf.accInf.CurrentLiabilities,
                        'Long_Term_Debt__c' : oppInf.accInf.LongTermDebt,
                        'Net_Income__c' : oppInf.accInf.NetIncome,
                        'Retained_Earnings__c' : oppInf.accInf.RetainedEarnings,
                        'Shareholders_Equity__c': oppInf.accInf.ShareholdersEquity,
                        'Total_Assets__c' : oppInf.accInf.TotalAssets,
                        'Total_Liabilities__c' : oppInf.accInf.TotalLiabilities,
                        'Total_Revenues__c' : oppInf.accInf.TotalRevenues    
                     }
                });
				//console.log('dead');
				newOpportunityEvent.fire(); 
			
            }
            
            component.set("v.showPopup",false);
        });
        $A.enqueueAction(action);       
    },
	handleShowModal: function(component, msg) {
        validateRecordEvent = $A.createComponent(
				"c:ConfirmationCmp", 
				{
					"message": msg
				}, 
				function(newButton, status) {
					if (status === "SUCCESS") {
                		component.find('overlayLib').showCustomModal({
							header: "Validated Confirmation",
							body: newButton,
							showCloseButton: true,
							cssClass: "mymodal",
							closeCallback: function() {
                            
							}
						})
					}
				}
			);
    },   

	getParameterByName: function(name) {
        try{
            name = name.replace(/[\[\]]/g, "\\$&");
            var url = window.location.href;
            var regex = new RegExp("[?&]" + name + "(=1\.([^&#]*)|&|#|$)");
            var results = regex.exec(url);
            if (!results) return null;
            if (!results[2]) return '';
            return decodeURIComponent(results[2].replace(/\+/g, " "));
        } catch (ex){
            return null;
        }
       
    },

    setPagref : function(component, event) {
        var valueOfContext = this.getParameterByName('inContextOfRef');
     
        if (valueOfContext == null){
            //set default page
            component.set("v.refPage", {type: 'standard__objectPage',
                                        attributes: {'objectApiName': 'Opportunity',
                                                'actionName': 'home'
                                            },
                                        state :{}
                                        }
                        );
            
            return ;
        }          
        var context = JSON.parse(window.atob(valueOfContext));
        if(context.attributes.actionName == "new") context.attributes.actionName = "home";//set to default           
        
        
        if(context.attributes.objectApiName == "Account") //set account Id
            component.set("v.accRecordId",context.attributes.recordId);
        
    },

	navigate : function(component, event) {
        var navService = component.find("navService");
        var pageReference = component.get("v.refPage");
		event.preventDefault();
		navService.navigate(pageReference);
	    
    },
	
	redirect: function (component, event){
        console.log("refPage="+JSON.stringify(component.get("v.refPage")));
        if(component.get("v.refPage")!=null ) this.navigate(component,event);
        else window.history.back();
    },
    
    addDate : function(fromDate, days, months, years) {
		var newDate = new Date(fromDate);
        newDate.setDate(newDate.getDate() + days);
        newDate.setMonth(newDate.getMonth() + months);
        newDate.setYear(newDate.getFullYear() + years);
        
        var result = $A.localizationService.formatDate(newDate, "YYYY-MM-DD");
        return result;
    },
    
   	checkEmptyString : function(str) {
        if (typeof str == 'undefined' || !str || str.length === 0 || str === "" || !/[^\s]/.test(str) || /^\s*$/.test(str) || str.replace(/\s/g,"") === "")
		{
			return true;
		}
		else
		{
			return false;
		}
    }
})