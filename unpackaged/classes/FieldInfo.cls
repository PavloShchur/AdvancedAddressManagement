public without sharing class FieldInfo {

    public String fieldPath { get; set; }
    public String label { get; set; }
    public Boolean required { get; set; }
    public String type { get; set; }

    public FieldInfo( Schema.FieldSetMember field ) {
        if( field != null ) {
            this.fieldPath = field.getFieldPath();
            this.label = field.getLabel();
            this.required = field.getRequired() || field.getDbrequired();
            this.type = String.valueOf( field.getType() );
        }
    }

    public FieldInfo( Schema.SObjectField fieldSo ) {
        if( fieldSo != null ) {
            Schema.DescribeFieldResult field = fieldSo.getDescribe();
            this.fieldPath = field.getName();
            this.label = field.getLabel();
            this.required = field.isNillable();
            this.type = String.valueOf( field.getType() );
        }
    }

}