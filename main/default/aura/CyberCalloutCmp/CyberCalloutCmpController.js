({
  closeQA: function (component, event, helper) {
    var showToast = event.getParam('showToast');
    if (showToast) {
      console.log("MPL Product");
      var toastEvent = $A.get("e.force:showToast");
      toastEvent.setParams({
        "title": "Warning",
        "message": "Cyber Callout is only possible for Cyber Product or Undeclined Submission",
        "type": "info"
      });
      toastEvent.fire();
    }
    $A.get("e.force:closeQuickAction").fire();
    console.log('Hello from Aura');
  }
})