@isTest
public class UtilsTest {

    public static String aAddressLine1 = 'test';
    public static String aCity = 'test';
    public static String aCountry = 'GB';
    public static String amAddressType = AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS;
    public static Boolean amActive = true;
    public static Boolean amPrimary = false;

    public static Account account;
    public static Contact contact;

    public static Address__c address;
    public static Address__c createAddress() {
        address = new Address__c(
            Account__c = account != null ? account.Id : null,
            Address_Line_1__c = aAddressLine1,
            City__c = aCity,
            Country__c = aCountry
        );
        INSERT address;
        return address;
    }

    public static List<Address_Mapping__c> addressMappingsAccount;
    public static List<Address_Mapping__c> addressMappingsContact;

    public static List<Address_Mapping__c> createAddressMappings( Integer count ) {
        List<Address_Mapping__c> addressMappings = new List<Address_Mapping__c>();
        for( Integer i = 0; i < count; i++ ) {
            addressMappings.add(
                new Address_Mapping__c(
                    Address__c = address.Id,
                    Account__c = contact == null && account != null ? account.Id : null,
                    Contact__c = contact != null ? contact.Id : null,
                    Address_Type__c = amAddressType,
                    Active__c = amActive,
                    Primary__c = amPrimary
                )
            );
        }
        INSERT addressMappings;
        return addressMappings;
    }

    public static void createTestDataForAccount( Integer countAcc ) {
        if( countAcc > 0 ) {
            if( account == null ) {
                createAccount( true );
            }
            createAddress();
            addressMappingsAccount = createAddressMappings( countAcc );
        }
    }

    public static void createTestDataForContact( Integer countAcc, Integer countCont ) {
        createTestDataForAccount( countAcc );
        if( countCont > 0 ) {
            if( contact == null ) {
                contact = new Contact( LastName = 'test',
                                       AccountId = account.Id );
                INSERT contact;
            }
            addressMappingsContact = createAddressMappings( countCont );
        }
    }

    public static Account createAccount( Boolean doInsert ) {
        account = new Account( Name = 'test' );
        if( doInsert ) {
            INSERT account;
        }
        return account;
    }

    @isTest static void getObjectNameByIdOrPrefix() {
        String result;

        Test.startTest();
            result = Utils.getObjectNameByIdOrPrefix( '001' );
        Test.stopTest();

        System.assert( result != null );
        System.assert( result == 'Account' );
    }

    @isTest static void joinFieldValues() {
        String result;

        Test.startTest();
            result = Utils.joinFieldValues( new Address_Mapping__c( Address_Type__c = AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS ),
                                            SObjectType.Address_Mapping__c.FieldSets.Address_List_Search_Fields.getFields() );
        Test.stopTest();

        System.assert( result != null );
    }

    @isTest static void joinFieldsInFieldSets() {
        List<Schema.FieldSetMember> result;

        Test.startTest();
            result = Utils.joinFieldsInFieldSets( SObjectType.Address_Mapping__c.FieldSets.New_Address_Additional_Information_Field.getFields(),
                                                  SObjectType.Address_Mapping__c.FieldSets.New_Address_Selected_Contacts_Fields.getFields() );
        Test.stopTest();

        System.assert( result != null );
    }

    @isTest static void getFieldsFromFieldSet() {
        List<String> result;

        Test.startTest();
            result = Utils.getFieldsFromFieldSet( SObjectType.Address_Mapping__c.FieldSets.Address_List_Search_Fields.getFields(),
                                                  Utils.addFieldsToList( null, AddressMappingWrapper.FIELDS_NEEDED_ADDRESS_WRAPPER ),
                                                  true );
        Test.stopTest();

        System.assert( result != null );
        System.assert( !result.isEmpty() );
    }

    @isTest static void getFieldsFromFieldSet2() {
        List<String> result;

        Test.startTest();
            result = Utils.getFieldsFromFieldSet( SObjectType.Address_Mapping__c.FieldSets.Address_List_Search_Fields.getFields(),
                                                  Utils.addFieldsToList( null, AddressMappingWrapper.FIELDS_NEEDED_ADDRESS_WRAPPER ) );
        Test.stopTest();

        System.assert( result != null );
        System.assert( !result.isEmpty() );
    }

    @isTest static void getFieldsFromObjectFields() {
        List<String> result;

        Test.startTest();
            result = Utils.getFieldsFromObjectFields( new List<Schema.SObjectField>{ Address_Mapping__c.Account__c },
                                                      new List<Schema.SObjectField>{ Address_Mapping__c.Account__c },
                                                      true );
        Test.stopTest();

        System.assert( result != null );
        System.assert( !result.isEmpty() );
    }

    @isTest static void getFieldsFromObjectFields2() {
        List<String> result;

        Test.startTest();
            result = Utils.getFieldsFromObjectFields( new List<Schema.SObjectField>{ Address_Mapping__c.Account__c },
                                                      new List<Schema.SObjectField>{ Address_Mapping__c.Account__c } );
        Test.stopTest();

        System.assert( result != null );
        System.assert( !result.isEmpty() );
    }

    @isTest static void getRelationshipNameCstObject() {
        String result;

        Test.startTest();
            result = Utils.getRelationshipName( 'Address__c' );
        Test.stopTest();

        System.assert( result != null );
        System.assert( result == 'Address__r.Name' );
    }

    @isTest static void getRelationshipNameStdObject() {
        String result;

        Test.startTest();
            result = Utils.getRelationshipName( 'AccountId' );
        Test.stopTest();

        System.assert( result != null );
        System.assert( result == 'Account.Name' );
    }

    @isTest static void getFieldDataForSearch() {
        List<String> results = new List<String>();

        List<Schema.FieldSetMember> members = SObjectType.Address_Mapping__c.FieldSets.New_Address_Selected_Contacts_Fields.getFields();

        Contact c = new Contact();
        Address_Mapping__c am = new Address_Mapping__c();
        am.Contact__r = c;

        Test.startTest();
        for( Schema.FieldSetMember member : members ) {
            results.add( Utils.getFieldDataForSearch( am, members[0] ) );
        }
        Test.stopTest();

        if( !members.isEmpty() ) {
            System.assert( !results.isEmpty() );
        }
    }

    @isTest static void getObjectPrefix() {
        String result;

        Test.startTest();
            result = Utils.getObjectPrefix( Address_Mapping__c.SObjectType );
        Test.stopTest();

        System.assert( result != null );
    }

    @isTest static void getFieldNames() {
        Set<String> result;

        Test.startTest();
            result = Utils.getFieldNames( new List<Schema.DescribeFieldResult>{ Address_Mapping__c.Name.getDescribe() } );
        Test.stopTest();

        System.assert( result != null );
        System.assert( !result.isEmpty() );
        System.assert( result.contains( 'Name' ) );
    }

    @isTest static void getFieldNames2() {
        Set<String> result;

        FieldInfo fi = new FieldInfo( Address_Mapping__c.Name );

        Test.startTest();
            result = Utils.getFieldNames( new List<FieldInfo>{ fi } );
        Test.stopTest();

        System.assert( result != null );
        System.assert( !result.isEmpty() );
        System.assert( result.contains( 'Name' ) );
    }

    @isTest static void getFieldDescribes() {
        List<Schema.DescribeFieldResult> result;

        Test.startTest();
            result = Utils.getFieldDescribes( new List<Schema.SObjectField>{ Address_Mapping__c.Name } );
        Test.stopTest();

        System.assert( result != null );
        System.assert( !result.isEmpty() );
    }

    @isTest static void getFieldInfos() {
        List<FieldInfo> result;

        List<Schema.FieldSetMember> members = SObjectType.Address_Mapping__c.FieldSets.New_Address_Selected_Contacts_Fields.getFields();

        Test.startTest();
            result = Utils.getFieldInfos( members, null );
        Test.stopTest();

        System.assert( result != null );
        if( !members.isEmpty() ) {
            System.assert( !result.isEmpty() );
        }
    }

    @isTest static void getFieldInfos2() {
        List<FieldInfo> result;

        Test.startTest();
            result = Utils.getFieldInfos( new List<Schema.SObjectField>{ Address_Mapping__c.Name } );
        Test.stopTest();

        System.assert( result != null );
        System.assert( !result.isEmpty() );
    }

    @isTest static void updateCustomSettingsInstall() {
        Test.startTest();
            Utils.updateCustomSettings( true );
        Test.stopTest();

        Aam_Settings__c settings = Aam_Settings__c.getOrgDefaults();
        System.assert( settings.Id != null );
    }

    @isTest static void setCustomSettings() {
        Test.startTest();
            Utils.setCustomSettings( Aam_Settings__c.getOrgDefaults() );
        Test.stopTest();
    }

    @isTest static void addField() {
        List<String> result = new List<String>();

        Test.startTest();
            Utils.addField( result, 'test' );
        Test.stopTest();

        System.assert( !result.isEmpty() );
        System.assert( result[0] == 'test' );
    }

    @isTest static void addFieldsToList() {
        List<Schema.SObjectField> result;

        Test.startTest();
            result = Utils.addFieldsToList( new List<Schema.SObjectField>{ Address_Mapping__c.Name },
                                            new List<Schema.SObjectField>{ Address_Mapping__c.Id } );
        Test.stopTest();

        System.assert( result != null );
        System.assert( !result.isEmpty() );
    }

    @isTest static void getReturnPageReference() {
        PageReference result;

        Test.startTest();
            result = Utils.getReturnPageReference( '001000000000000' );
        Test.stopTest();

        System.assert( result != null );
    }

    @isTest static void getReturnPageReferenceRetUrl() {
        PageReference result;
        Test.setCurrentPageReference( Page.AddressList );
        System.currentPageReference().getParameters().put( Utils.PARAM_RET_URL, 'test' );

        Test.startTest();
            result = Utils.getReturnPageReference( '001000000000000' );
        Test.stopTest();

        System.assert( result != null );
    }

    @isTest static void recordsAreEqualPositive() {
        Address__c address1 = new Address__c( City__c = 'test' );
        Address__c address2 = new Address__c( City__c = 'test' );

        Set<Schema.SObjectField> fields = new Set<Schema.SObjectField>{ Address__c.City__c };

        Boolean result;

        Test.startTest();
            result = Utils.recordsAreEqual( address1, address2, fields );
        Test.stopTest();

        System.assert( result == true );
    }

    @isTest static void recordsAreEqualNegative() {
        Address__c address1 = new Address__c( City__c = 'test1' );
        Address__c address2 = new Address__c( City__c = 'test2' );

        Set<Schema.SObjectField> fields = new Set<Schema.SObjectField>{ Address__c.City__c };

        Boolean result;

        Test.startTest();
            result = Utils.recordsAreEqual( address1, address2, fields );
        Test.stopTest();

        System.assert( result == false );
    }

    @isTest static void joinFields() {
        Set<Schema.SObjectField> fields1 = new Set<Schema.SObjectField>{ Address__c.City__c };
        Set<Schema.SObjectField> fields2 = new Set<Schema.SObjectField>{ Address__c.Address_Line_1__c };

        Set<Schema.SObjectField> result;

        Test.startTest();
            result = Utils.joinFields( fields1, fields2 );
        Test.stopTest();

        System.assert( result != null );
        for( Schema.SObjectField field : fields1 ) {
            System.assert( result.contains( field ) );
        }
        for( Schema.SObjectField field : fields2 ) {
            System.assert( result.contains( field ) );
        }
    }

    @isTest static void addFieldsToQueryNoReferenceField() {
        Set<Schema.SObjectField> fields = new Set<Schema.SObjectField>{ Address__c.City__c, Address__c.Address_Line_1__c };
        String referenceField = null;

        String result;

        Test.startTest();
            result = Utils.addFieldsToQuery( referenceField, fields );
        Test.stopTest();

        System.assert( result != null );
        for( Schema.SObjectField field : fields ) {
            System.assert( result.contains( field.getDescribe().getName() ) );
        }
    }

    @isTest static void addFieldsToQueryWithReferenceField() {
        Set<Schema.SObjectField> fields = new Set<Schema.SObjectField>{ Address__c.City__c, Address__c.Address_Line_1__c };
        String referenceField = 'refField';

        String result;

        Test.startTest();
            result = Utils.addFieldsToQuery( referenceField, fields );
        Test.stopTest();

        System.assert( result != null );
        for( Schema.SObjectField field : fields ) {
            System.assert( result.contains( referenceField + '.' + field.getDescribe().getName() ) );
        }
    }

    @isTest static void createStringKey() {
        Address__c address1 = new Address__c( City__c = 'test1', Address_Line_1__c = 'test2' );
        Set<Schema.SObjectField> fields = new Set<Schema.SObjectField>{ Address__c.City__c, Address__c.Address_Line_1__c };

        String result;

        Test.startTest();
            result = Utils.createStringKey( address1, fields );
        Test.stopTest();

        System.assert( result != null );
        for( Schema.SObjectField field : fields ) {
            System.assert( result.contains( (String)address1.get( field.getDescribe().getName() ) ) );
        }
    }

}