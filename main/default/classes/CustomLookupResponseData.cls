public with sharing class CustomLookupResponseData {
    public Boolean isSuccess;
    public Map<String, Object> results;
    public String errMsg;

    public CustomLookupResponseData() {
        this.isSuccess = true;
        this.results = new Map<String, Object>();
    }

    public void addError(String errMsg){
        this.errMsg = errMsg;
        this.isSuccess = false;
    }

    public String getJsonString() {
        return strike_utilities.serializeWithoutNamespace(this);
    }
}