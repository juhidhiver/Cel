({
    updateStageAndPopulateFields: function (component) {
        var action = component.get("c.updateStageAndPopulateFields");
        action.setParams({
            opportunityId: component.get("v.oppId")
        });
        action.setCallback(this, response => {
            var state = response.getState();
            if (state == "SUCCESS") {
                var opp = response.getReturnValue();

                var evt = $A.get("e.force:navigateToComponent");
                evt.setParams({
                    componentDef: "c:quoteComparisonMainLwc",
                    componentAttributes: {
                        quoteProcessSubmissionId: component.get("v.oppId")
                    }
                });

                evt.fire();
                console.log('@@@ opp ', opp);
            }
        });
        $A.enqueueAction(action);
    }
})