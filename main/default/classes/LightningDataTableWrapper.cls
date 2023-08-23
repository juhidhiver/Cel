public class LightningDataTableWrapper  
{
    @AuraEnabled
    public String name;
	@AuraEnabled
    public String nameAPI;
    @AuraEnabled
    public List<DatatableColumn> columns;
    @AuraEnabled
    public List<sObject> data;
    @AuraEnabled
    public Integer countList {
        get {return data.size();}
    }
    @AuraEnabled
    public String relationshipName;
	@AuraEnabled
    public String parentFieldAPI;
	@AuraEnabled
    public ObjectPermission permission;
	@AuraEnabled
    public String icon;

    public LightningDataTableWrapper() {
        data = new List<sObject>();
		//permission = QuoteInsuredItemsCmpController.getObjectPermission(name) ;
    }
   
    public class DatatableColumn {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String fieldName;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public Boolean sortable;

		@AuraEnabled
        public TypeAttributes typeAttributes;

		@AuraEnabled
        public DatatableColumnCellAttributes cellAttributes;

		public DatatableColumn() {
            typeAttributes = new TypeAttributesNumberUrl();
			cellAttributes = new DatatableColumnCellAttributes();
        }
	}

	public virtual class TypeAttributes {

	}

	public class TypeAttributesNumberUrl extends TypeAttributes {
			@AuraEnabled
			public DatatableColumnLabelAttributes label{get; set;}
			@AuraEnabled
			public String target{get; set;}
			@AuraEnabled
			public DatatableColumnTooltipAttributes tooltip{get; set;}
			@AuraEnabled
			public List<DatatableColumnAction> rowActions{get; set;}

			public TypeAttributesNumberUrl(){
				//target= '_blank';
				label = new DatatableColumnLabelAttributes();
			}
	}

	public class TypeAttributesNumber extends TypeAttributes {
		@AuraEnabled
		public Integer minimumIntegerDigits{get; set;}
		@AuraEnabled
		public Integer minimumFractionDigits{get; set;}
		@AuraEnabled
		public Integer maximumFractionDigits{get; set;}
		@AuraEnabled
		public Integer minimumSignificantDigits{get; set;}
		@AuraEnabled
		public Integer maximumSignificantDigits{get; set;}
	}

	public class TypeAttributesCurrency extends TypeAttributes {
		@AuraEnabled
		public Integer minimumIntegerDigits{get; set;}
		@AuraEnabled
		public Integer minimumFractionDigits{get; set;}
		@AuraEnabled
		public Integer maximumFractionDigits{get; set;}
		@AuraEnabled
		public Integer minimumSignificantDigits{get; set;}
		@AuraEnabled
		public Integer maximumSignificantDigits{get; set;}
		@AuraEnabled
		public String currencyCode{get; set;}
		@AuraEnabled
		public String currencyDisplayAs{get; set;}
	}

	public class DatatableColumnCellAttributes{
		@AuraEnabled
		public String alignment{get; set;}

		public DatatableColumnCellAttributes(){
			//alignment= 'left';
		}
	}

	public class DatatableColumnLabelAttributes{
		@AuraEnabled
		public String fieldName{get; set;}
	}

	public class DatatableColumnTooltipAttributes{
		@AuraEnabled
		public String fieldName{get; set;}
	}

	public class DatatableColumnAction{
		@AuraEnabled
		public String name{get; set;}
		@AuraEnabled
		public String label{get; set;}
		@AuraEnabled
		public Boolean disabled{get; set;}

		public DatatableColumnAction(){
			disabled=false;
		}
	}

	public class ObjectPermission{
		@AuraEnabled
		public Boolean isEditable{get; set;}
		@AuraEnabled
		public Boolean isDeletable{get; set;}
		@AuraEnabled
		public Boolean isCreatable{get; set;}

		public ObjectPermission(){
			isEditable = false;
			isDeletable = false;
			isCreatable = false;
		}
	}

	@AuraEnabled
	public static ObjectPermission getObjectPermission(String objName){
		ObjectPermission permission = new ObjectPermission();
		SObjectType objType = Schema.getGlobalDescribe().get(objName);
		if (objType == null) {
			return permission;
		}

		permission.isCreatable = objType.getDescribe().isCreateable();
		permission.isDeletable = objType.getDescribe().isDeletable();
		permission.isEditable = objType.getDescribe().isUpdateable();
	
		return permission;
	}
    
	public static DatatableColumn getTableRowActionByPermission(ObjectPermission permission) {
		DatatableColumn result = new DatatableColumn(); 
		List<DatatableColumnAction> actions = new List<DatatableColumnAction>();
		TypeAttributesNumberUrl attribute = new TypeAttributesNumberUrl();

		// invalid input
		if (permission == null) {
			return result;
		}

		DatatableColumnAction delAction = generateAction('Delete', 'delete', permission.isDeletable);
		DatatableColumnAction editAction = generateAction('Edit', 'edit', permission.isEditable);

		actions.add(delAction);
		actions.add(editAction);
		attribute.rowActions = actions;

		result.type = 'action';
		result.typeAttributes = attribute;

		return result;
	}

	private static DatatableColumnAction generateAction(String label, String name, Boolean isVisible) {
		DatatableColumnAction result = new DatatableColumnAction();
		result.label = label;
		result.name = name;
		result.disabled = !isVisible;

		return result;
	}

	public static TypeAttributesNumberUrl generateUrlAttribute(String fieldName, string target) {
		TypeAttributesNumberUrl result = new TypeAttributesNumberUrl();
		DatatableColumnLabelAttributes lblAttr = new DatatableColumnLabelAttributes();
		DatatableColumnTooltipAttributes tooltip = new DatatableColumnTooltipAttributes();
		lblAttr.fieldName = fieldName;
		tooltip.fieldName = fieldName;

		result.label = lblAttr;
		result.target = target;
		result.tooltip = tooltip;

		return result;
	}

	public static DatatableColumn generateRecordLinkColumn(String fieldName, String lbl) {
		DatatableColumn result = new DatatableColumn();
		result.typeAttributes = generateUrlAttribute(fieldName, '_blank');
		result.label = lbl;
		result.fieldName = 'linkName';
		result.type = 'url';
		return result;
	}

	public static TypeAttributesCurrency generateCurrencyAttribute() {
		TypeAttributesCurrency result = new TypeAttributesCurrency();
		result.currencyCode = UserInfo.getDefaultCurrency();

		return result;
	}

	public static TypeAttributesCurrency generateNumberAttribute(Integer scale, Integer precision) {
		TypeAttributesCurrency result = new TypeAttributesCurrency();
		result.minimumFractionDigits = precision;
		result.minimumIntegerDigits = scale - precision;
		return result;
	}

	public static DatatableColumnCellAttributes generateCurrencyCellAttribute() {
		DatatableColumnCellAttributes result = new DatatableColumnCellAttributes();
		result.alignment = 'left';

		return result;
	}

	public static String getColumnTypeByFieldType(String fieldType) {
		String result = '';
		switch on fieldType {
			when 'PICKLIST' {
				result = 'text';
			}
			when 'CURRENCY' {
				result = 'currency';
			}
			when 'DOUBLE' {
				result = 'number';
			}
			when 'BOOLEAN' {
				result = 'boolean';
			}
			when else {
				result = 'text';
			}
		}

		return result;
	}

	public static TypeAttributes generateTypeAttribute(Schema.DescribeFieldResult desField) {
		TypeAttributes result = new TypeAttributes();
		String colType = desField.getType().name();

		switch on colType {
			when 'currency' {
				result = generateCurrencyAttribute();
			}
			when 'number' {
				result = generateNumberAttribute(desField.getScale(), desField.getPrecision());
			}
			when else {
				
			}
		}
		return result;
	}

	public static DatatableColumnCellAttributes generateCellAttribute(String colType) {
		DatatableColumnCellAttributes result = new DatatableColumnCellAttributes();
		switch on colType {
			when 'currency' {
				result = generateCurrencyCellAttribute();
			}
			when 'number' {
				result = generateCurrencyCellAttribute();
			}
			when else {
				
			}
		}
		return result;
	}
}