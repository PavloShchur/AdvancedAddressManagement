@isTest
private class FieldInfoTest {

    @isTest static void initWithData() {
        Schema.FieldSetMember field;
        for( Schema.FieldSetMember fieldItem : SObjectType.Contact.FieldSets.New_Address_Related_Contacts_Fields.getFields() ) {
            field = fieldItem;
            break;
        }

        FieldInfo info;

        Test.startTest();
            info = new FieldInfo( field );
        Test.stopTest();

        if( field != null ) {
            System.assert( !String.isEmpty( info.fieldPath ) );
            System.assert( !String.isEmpty( info.label ) );
            System.assert( info.required != null );
            System.assert( !String.isEmpty( info.type ) );
        }
    }

}