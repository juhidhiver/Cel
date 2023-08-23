public class QueryObject {
    public String name {get;set;}
    public List<String> fields {get;set;}
    public String condition {get;set;}
    public String orderByField {get;set;}
    public String orderType {get;set;}
    public Integer pageSize {get;set;}
    public Integer pageNumber {get;set;}

    public QueryObject() {
        this.name = '';
        this.fields = new List<String>();
        this.condition = '';
        this.orderByField = '';
        this.orderType = '';
        this.pageSize = 0;
        this.pageNumber = 0;
    }
}