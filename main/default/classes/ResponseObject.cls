public class ResponseObject {
    public String body {get;set;}
    public String status {get;set;}
    public Integer statusCode {get;set;}
    public List<String> errors {get;set;}

    public ResponseObject() {
        this.body = '';
        this.status = '';
        this.statusCode = 0;
        this.errors = new List<String>();
    }
    
    public ResponseObject(HttpResponse obj) {
        this.body = obj.getBody();
        this.status = obj.getStatus(); 
        this.statusCode = obj.getStatusCode();
        try {
            Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(obj.getBody());
            this.errors = new List<String>();

            String msg = (String)resultMap.get('message');
            String error = (String)resultMap.get('error');
            if(obj.getStatusCode() != 200){
                this.errors.add('Rating Fail Please Check API Log');
            }
            if (String.isNotBlank(msg)) this.errors.add(msg);
            if (String.isNotBlank(error)) this.errors.add(error);
        } catch(Exception ex) {
            System.debug(ex.getMessage() + ' - ' + ex.getLineNumber() + ' - ' + ex.getStackTraceString());
        }
    }
        

}