({ 
	showModal : function(component) {
        console.log('@@@ ----------- LimitAndDeductiblesModalHelper.showModal ---------------');
        component.find("limitAndDeductiblesModal").show();
    },

    hideModal : function(component) {
        console.log('@@@ ----------- LimitAndDeductiblesModalHelper.hideModal ---------------');
        component.find("limitAndDeductiblesModal").hide();
    },
})