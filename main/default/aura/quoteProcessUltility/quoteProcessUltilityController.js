({
    minimizeUtility : function(component, event, helper) {
        var utilityAPI = component.find("utilitybar");
        utilityAPI.minimizeUtility();
    },
    setPanelHeight: function(component,event,helper){
        var utilityAPI = component.find("utilitybar");
        utilityAPI.setPanelHeight({heightPX: 480});
        utilityAPI.setPanelWidth({widthPX: 1230});
    },
    close: function(component,event,helper){
        var utilityAPI = component.find("utilitybar");
        utilityAPI.setPanelHeight({heightPX: 255});
        utilityAPI.setPanelWidth({widthPX: 500});
    }
})