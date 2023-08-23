({
	navigateToRecord : function(component,sfRecId){
        try{
            var navService = component.find("navService");
            var pageReference = {
                type: 'standard__recordPage',
                attributes: {
                    recordId : sfRecId,
                    actionName: 'view'
                }
            };
            navService.navigate(pageReference);
        }catch(e){
            console.log(e);
        }
    }
})