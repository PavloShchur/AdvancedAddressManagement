public without sharing class Utils {

    public static final String SCHEDULE_HOURLY = '0 0 * * * ? *';
    public static final String PARAM_RET_URL = 'retURL';
    public static final String PARAM_ADDRESS_MAPPING_TYPE = 'type';
    public static final String PARAM_CONTACT_IDS = 'contactIds';
    public static final String PARAM_SPLITTER = ',';
    private static final String KEY_DELIMITER = '_';


    public static final Set<String> SUPPORTED_PARENT_OBJECTS = new Set<String>{
        Contact.sObjectType.getDescribe().getName(),
        Account.sObjectType.getDescribe().getName()
    };

    public static Map<String, String> prefixToObject {
        get {
            if( prefixToObject == null ) {
                prefixToObject = new Map<String, String>();
            }
            return prefixToObject;
        }
        set;
    }

    public static String generateHash( SObject record, List<Schema.SObjectField> fields ) {
        String hashVersion = '1=';
        String source = '';
        for( Schema.SObjectField fieldItem : fields ) {
            source += String.valueOf( record.get( fieldItem ) );
        }
        Blob hash = Crypto.generateDigest( 'SHA-256', Blob.valueOf( source ) );
        return hashVersion + EncodingUtil.base64Encode( hash );
    }

    public static String getObjectNameByIdOrPrefix( String recordIdOrPrefix ) {
        if( String.isEmpty( recordIdOrPrefix ) ) return null;
        String prefix = String.valueOf( recordIdOrPrefix ).substring( 0, 3 );
        String objectName = prefixToObject.get( prefix );
        if( objectName != null ) return objectName;
        for( Schema.SObjectType stype : Schema.getGlobalDescribe().values() ) {
            Schema.DescribeSObjectResult objectDescr = stype.getDescribe();
            String existingPrefix = objectDescr.getKeyPrefix();
            if( existingPrefix != null && existingPrefix.equals( prefix ) ) {
                prefixToObject.put( prefix, objectDescr.getName() );
                break;
            }
        }
        return prefixToObject.get( prefix );
    }

    public static String joinFieldValues( SObject record, List<Schema.FieldSetMember> fields ) {
        List<String> resultParts = new List<String>();
        String fieldData;
        for( Schema.FieldSetMember fieldItem : fields ) {
            if( fieldItem.getType() == Schema.DisplayType.BOOLEAN ) continue;
            fieldData = Utils.getFieldDataForSearch( record, fieldItem );
            if( fieldData == null ) continue;
            resultParts.add( fieldData );
        }
        return String.join( resultParts, ', ' );
    }

    public static List<Schema.FieldSetMember> joinFieldsInFieldSets( List<Schema.FieldSetMember> fields, List<Schema.FieldSetMember> additionalFields ) {
        List<Schema.FieldSetMember> result = new List<Schema.FieldSetMember>();
        Set<String> usedApiNames = new Set<String>();
        if( fields != null ) {
            for( Schema.FieldSetMember fieldItem : fields ) {
                if( usedApiNames.contains( fieldItem.getFieldPath() ) ) continue;
                usedApiNames.add( fieldItem.getFieldPath() );
                result.add( fieldItem );
            }
        }
        if( additionalFields != null ) {
            for( Schema.FieldSetMember fieldItem : additionalFields ) {
                if( usedApiNames.contains( fieldItem.getFieldPath() ) ) continue;
                usedApiNames.add( fieldItem.getFieldPath() );
                result.add( fieldItem );
            }
        }
        return result;
    }

    public static List<String> getFieldsFromFieldSet( List<Schema.FieldSetMember> fields, List<Schema.SObjectField> additionalFields, Boolean atLeastOneField ) {
        Set<String> result = new Set<String>();
        if( atLeastOneField == true ) {
            result.add( 'Id' );
        }
        if( additionalFields != null ) {
            result.addAll( getFieldsFromObjectFields( additionalFields, null, false ) );
        }
        if( fields == null ) return new List<String>( result );
        for( Schema.FieldSetMember field : fields ) {
            String fieldApiName = field.getFieldPath();
            result.add( fieldApiName );
            if( field.getType() == Schema.DisplayType.REFERENCE ) {
                result.add( getRelationshipName( fieldApiName ) );
            }
        }
        return new List<String>( result );
    }

    public static List<String> getFieldsFromFieldSet( List<Schema.FieldSetMember> fields, List<Schema.SObjectField> additionalFields ) {
        return getFieldsFromFieldSet( fields, additionalFields, true );
    }

    public static List<String> getFieldsFromObjectFields( List<Schema.SObjectField> fields, List<Schema.SObjectField> additionalFields, Boolean atLeastOneField ) {
        Set<String> result = new Set<String>();
        if( atLeastOneField == true ) {
            result.add( 'Id' );
        }
        if( additionalFields != null ) {
            result.addAll( getFieldsFromObjectFields( additionalFields, null, false ) );
        }
        if( fields == null ) return new List<String>( result );
        for( Schema.SObjectField field : fields ) {
            Schema.DescribeFieldResult fieldDesc = field.getDescribe();
            String fieldApiName = fieldDesc.getName();
            result.add( fieldApiName );
            if( fieldDesc.getType() == Schema.DisplayType.REFERENCE ) {
                result.add( getRelationshipName( fieldApiName ) );
            }
        }
        return new List<String>( result );
    }

    public static List<String> getFieldsFromObjectFields( List<Schema.SObjectField> fields, List<Schema.SObjectField> additionalFields ) {
        return getFieldsFromObjectFields( fields, additionalFields, true );
    }

    public static String getRelationshipName( String fieldApiName ) {
        return getRelationship( fieldApiName ) + '.Name';
    }

    public static String getRelationship( String fieldApiName ) {
        String result;
        if( fieldApiName.endsWith( '__c' ) ) {
            result = fieldApiName.substring( 0, fieldApiName.lastIndexOf( '__c' ) ) + '__r';
        } else {
            result = fieldApiName.substring( 0, fieldApiName.lastIndexOf( 'Id' ) );
        }
        return result;
    }

    public static String getFieldDataForSearch( SObject objectItem, Schema.FieldSetMember fieldItem ) {
        Schema.DisplayType fieldType = fieldItem.getType();
        String fieldApiName = fieldItem.getFieldPath();
        String fieldData;
        if( fieldType != Schema.DisplayType.REFERENCE ) {
            fieldData = (String)objectItem.get( fieldApiName );
        } else {
            SObject parentObject = ((SObject)objectItem).getSObject( getRelationship( fieldApiName ) );
            if( parentObject != null ) {
                fieldData = (String)parentObject.get( 'Name' );
            }
        }
        return fieldData;
    }

    public static String getObjectPrefix( Schema.SObjectType objectType ) {
        if( objectType == null ) return null;
        return objectType.getDescribe().getKeyPrefix();
    }

    public static Set<String> getFieldNames( List<Schema.DescribeFieldResult> fields ) {
        Set<String> result = new Set<String>();
        if( fields == null ) return result;
        for( Schema.DescribeFieldResult field : fields ) {
            result.add( field.getName() );
        }
        return result;
    }

    public static Set<String> getFieldNames( List<FieldInfo> fields ) {
        Set<String> result = new Set<String>();
        if( fields == null ) return result;
        for( FieldInfo field : fields ) {
            result.add( field.fieldPath );
        }
        return result;
    }

    public static List<Schema.DescribeFieldResult> getFieldDescribes( List<Schema.SObjectField> fields ) {
        List<Schema.DescribeFieldResult> result = new List<Schema.DescribeFieldResult>();
        if( fields == null ) return result;
        for( Schema.SObjectField field : fields ) {
            result.add( field.getDescribe() );
        }
        return result;
    }

    public static List<FieldInfo> getFieldInfos( List<Schema.FieldSetMember> fieldSetMembers, List<FieldInfo> hardcodedFieldInfos ) {
        List<FieldInfo> result = new List<FieldInfo>();
        if( fieldSetMembers == null ) return result;
        Set<String> hardcodedFields = getFieldNames( hardcodedFieldInfos );
        for( Schema.FieldSetMember fieldItem : fieldSetMembers ) {
            if( hardcodedFields.contains( fieldItem.getFieldPath() ) ) continue;
            result.add( new FieldInfo( fieldItem ) );
        }
        return result;
    }

    public static List<FieldInfo> getFieldInfos( List<Schema.SObjectField> fields ) {
        List<FieldInfo> result = new List<FieldInfo>();
        if( fields == null ) return result;
        for( Schema.SObjectField fieldItem : fields ) {
            result.add( new FieldInfo( fieldItem ) );
        }
        return result;
    }

    private static Map<Schema.SObjectField, Integer> fieldToNumValue = new Map<Schema.SObjectField, Integer>{
        Aam_Settings__c.Acc_New_Addr_Addr_Srch_H__c  => 149,
        Aam_Settings__c.Acc_New_Addr_Rel_Cont_H__c   => 226,
        Aam_Settings__c.Acc_New_Addr_Sel_Cont_H__c   => 226,
        Aam_Settings__c.Cont_New_Addr_Addr_Srch_H__c => 149,
        Aam_Settings__c.Cont_New_Addr_Rel_Addr_H__c  => 226,
        Aam_Settings__c.Acc_Mgmt_Addr_Rel_Cont_H__c  => 226,
        Aam_Settings__c.Acc_Mgmt_Addr_Sel_Cont_H__c  => 226,
        Aam_Settings__c.Acc_Deact_Addr_Rel_Cont_H__c => 226,
        Aam_Settings__c.Acc_Deact_Addr_Sel_Cont_H__c => 226,
        Aam_Settings__c.Acc_Merge_Addr_Addr_Srch_H__c => 374,
        Aam_Settings__c.Chunk_Size_For_Address_Batch__c => BatchRepairAddresses.CHUNK_SIZE_DEFAULT,
        Aam_Settings__c.Chunk_Size_For_Address_Mapping_Batch__c => BatchRepairAddressMappings.CHUNK_SIZE_DEFAULT
    };

    private static Map<Schema.SObjectField, String> fieldToStrValue = new Map<Schema.SObjectField, String>{
        Aam_Settings__c.Acc_Billing_Addr_Source__c  => 'Billing Address',
        Aam_Settings__c.Acc_Shipping_Addr_Source__c => 'Shipping Address',
        Aam_Settings__c.Cont_Mailing_Addr_Source__c => 'Mailing Address',
        Aam_Settings__c.Cont_Other_Addr_Source__c   => 'Other Address'
    };

    public static void updateCustomSettings( Boolean isInstall ) {
        Aam_Settings__c settings = Aam_Settings__c.getOrgDefaults();
        setCustomSettings( settings );
        if( isInstall ) {
            setInstallCustomSettings( settings );
        }
        UPSERT settings Aam_Settings__c.Id;
    }

    public static void setCustomSettings( Aam_Settings__c settings ) {
        updateCustomSettingsNumField( settings, Aam_Settings__c.Acc_New_Addr_Addr_Srch_H__c  );
        updateCustomSettingsNumField( settings, Aam_Settings__c.Acc_New_Addr_Rel_Cont_H__c   );
        updateCustomSettingsNumField( settings, Aam_Settings__c.Acc_New_Addr_Sel_Cont_H__c   );
        updateCustomSettingsNumField( settings, Aam_Settings__c.Cont_New_Addr_Addr_Srch_H__c );
        updateCustomSettingsNumField( settings, Aam_Settings__c.Cont_New_Addr_Rel_Addr_H__c  );
        updateCustomSettingsNumField( settings, Aam_Settings__c.Acc_Mgmt_Addr_Rel_Cont_H__c  );
        updateCustomSettingsNumField( settings, Aam_Settings__c.Acc_Mgmt_Addr_Sel_Cont_H__c  );
        updateCustomSettingsNumField( settings, Aam_Settings__c.Acc_Deact_Addr_Rel_Cont_H__c );
        updateCustomSettingsNumField( settings, Aam_Settings__c.Acc_Deact_Addr_Sel_Cont_H__c );
        updateCustomSettingsNumField( settings, Aam_Settings__c.Acc_Merge_Addr_Addr_Srch_H__c );
        updateCustomSettingsNumField( settings, Aam_Settings__c.Chunk_Size_For_Address_Batch__c );
        updateCustomSettingsNumField( settings, Aam_Settings__c.Chunk_Size_For_Address_Mapping_Batch__c );
    }

    public static void setInstallCustomSettings( Aam_Settings__c settings ) {
        updateCustomSettingsStrField( settings, Aam_Settings__c.Acc_Billing_Addr_Source__c  );
        updateCustomSettingsStrField( settings, Aam_Settings__c.Acc_Shipping_Addr_Source__c );
        updateCustomSettingsStrField( settings, Aam_Settings__c.Cont_Mailing_Addr_Source__c );
        updateCustomSettingsStrField( settings, Aam_Settings__c.Cont_Other_Addr_Source__c   );
        settings.Disable_Standard_Address_Population__c = false;
        settings.Disable_Contact_Reparenting_Function__c = false;
        settings.Disable_Account_Move_Delete_Function__c = false;
        settings.Cont_New_Addr_Primary_Defaults_To_All__c = true;
        settings.Enforce_Contact_Address_Deactivation__c = false;
    }

    private static void updateCustomSettingsNumField( Aam_Settings__c settings, Schema.SObjectField field ) {
        String fieldName = field.getDescribe().getName();
        Double fieldValue = (Double)settings.get( fieldName );
        if( fieldValue != null && fieldValue != 0 ) return;
        settings.put( fieldName, fieldToNumValue.get( field ) != null ? fieldToNumValue.get( field ) : 100 );
    }

    private static void updateCustomSettingsStrField( Aam_Settings__c settings, Schema.SObjectField field ) {
        String fieldName = field.getDescribe().getName();
        String fieldValue = (String)settings.get( fieldName );
        if( !String.isEmpty( fieldValue ) ) return;
        settings.put( fieldName, fieldToStrValue.get( field ) != null ? fieldToStrValue.get( field ) : '' );
    }

    public static void addField( List<String> fieldData, String fieldValue ) {
        if( fieldData == null || String.isEmpty( fieldValue ) ) return;
        fieldData.add( fieldValue );
    }

    public static List<Schema.SObjectField> addFieldsToList( List<Schema.SObjectField> originalFields, List<Schema.SObjectField> additionalFields ) {
        if( originalFields == null ) {
            originalFields = new List<Schema.SObjectField>();
        }
        if( additionalFields == null ) return originalFields;
        Set<Schema.SObjectField> originalFieldsSet = new Set<Schema.SObjectField>( originalFields );
        for( Schema.SObjectField additionalField : additionalFields ) {
            if( !originalFieldsSet.contains( additionalField ) ) {
                originalFields.add( additionalField );
                originalFieldsSet.add( additionalField );
            }
        }
        return originalFields;
    }

    public static PageReference getReturnPageReference( Id recordId ) {
        String retUrl = ApexPages.currentPage().getParameters().get( Utils.PARAM_RET_URL );
        if( !String.isEmpty( retUrl ) ) {
            retUrl = retUrl.unescapeHtml4();
        } else {
            retUrl = '/' + ( recordId != null ? recordId : '' );
        }
        PageReference pr = new PageReference( retUrl );
        pr.setRedirect( true );
        return pr;
    }

    public static Aam_Settings__c aamSettings {
        get {
            if( aamSettings == null ) {
                aamSettings = Aam_Settings__c.getInstance();
                Utils.setCustomSettings( aamSettings );
            }
            return aamSettings;
        }
        private set;
    }

    public static String joinStrings( List<String> parts, String separator ) {
        if( separator == null ) separator = ' ';
        if( parts == null ) return '';
        List<String> notEmptyParts = new List<String>();
        for( String part : parts ) {
            if( String.isEmpty( part ) ) continue;
            notEmptyParts.add( part );
        }
        return String.join( notEmptyParts, separator );
    }

    public static String joinFieldValues( SObject record, List<Schema.SObjectField> fields ) {
        if( record == null ) return '';
        List<String> addressParts = new List<String>();
        for( Schema.SObjectField field : fields ) {
            Schema.DescribeFieldResult fieldDescription = field.getDescribe();
            if( fieldDescription.getType() == Schema.DisplayType.BOOLEAN ) continue;
            addAddressPart( (String)record.get( fieldDescription.getName() ), addressParts );
        }
        return String.join( addressParts, ', ' );
    }

    public static void addAddressPart( String addressPart, List<String> addressParts ) {
        if( addressParts == null || String.isEmpty( addressPart ) ) return;
        addressParts.add( addressPart );
    }

    private static Map<String, Map<String, Boolean>> objectTypeToFieldNameToDoesExist = new Map<String, Map<String, Boolean>>();
    public static Boolean fieldExists( Schema.SObjectType objectType, String field ) {
        if( objectType == null || field == null ) return false;
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        String objectName = objectDescribe.getName();
        String fieldName = field.toLowerCase();
        if( objectTypeToFieldNameToDoesExist.get( objectName ) == null ) {
            objectTypeToFieldNameToDoesExist.put( objectName, new Map<String, Boolean>() );
        }
        Map<String, Boolean> fieldNameToDoesExist = objectTypeToFieldNameToDoesExist.get( objectName );
        if( fieldNameToDoesExist.get( fieldName ) == null ) {
            fieldNameToDoesExist.put( fieldName, objectDescribe.fields.getMap().keySet().contains( fieldName ) );
        }
        return fieldNameToDoesExist.get( fieldName );
    }

    public static void populateAddressFields( SObject record, Address_Mapping__c address, String fieldType ) {
        String streetName = Utils.joinStrings( new List<String>{ address.Address_Line_1__c,
                                                                 address.Address_Line_2__c,
                                                                 address.Address_Line_3__c,
                                                                 address.Address_Line_4__c },
                                               ', ' );
        record.put( fieldType + 'Street', !String.isEmpty( streetName ) ? streetName.left(255) : null );
        record.put( fieldType + 'City', !String.isEmpty( address.City__c ) ? address.City__c.left(40) : null );
        record.put( fieldType + 'Country', !String.isEmpty( address.Country_Name__c ) ? address.Country_Name__c.left(80) : null );
        if( fieldExists( record.getSObjectType(), fieldType + 'CountryCode' ) ) {
            record.put( fieldType + 'CountryCode', address.Country__c );
        }
        record.put( fieldType + 'PostalCode', !String.isEmpty( address.Postcode__c ) ? address.Postcode__c.left(20) : null );
        record.put( fieldType + 'State', !String.isEmpty( address.State_County__c ) ? address.State_County__c.left(80) : null );
        record.put( fieldType + '_Country_AAM__c', address.Address__r.Country_Mapping__c );
    }

    public static Boolean isFieldChanged( SObject newRecord, SObject oldRecord, Schema.SObjectField field ) {
        if( field == null || ( newRecord == null && oldRecord == null ) ) return false;
        if( newRecord == null || oldRecord == null ) return true;
        String fieldName = field.getDescribe().getName();
        return newRecord.get( fieldName ) != oldRecord.get( fieldName );
    }

    public static Boolean recordsAreEqual( SObject firstObject, SObject secondObject, Set<Schema.SObjectField> compareFields ) {
        for( Schema.SObjectField field : compareFields ) {
            if( firstObject.get( field.getDescribe().getName() ) == secondObject.get( field.getDescribe().getName() ) ) continue;
            return false;
        }
        return true;
    }

    public static Set<Schema.SObjectField> joinFields( Set<Schema.SObjectField> firstSet, Set<Schema.SObjectField> secondSet ) {
        Set<Schema.SObjectField> result = new Set<Schema.SObjectField>();
        if( firstSet != null ) {
            result.addAll( firstSet );
        }
        if( secondSet != null ) {
            result.addAll( secondSet );
        }
        return result;
    }

    public static String addFieldsToQuery( String referenceField, Set<Schema.SObjectField> fields ) {
        if( String.isEmpty( referenceField ) ) referenceField = '';
        if( !String.isEmpty( referenceField ) && !referenceField.endsWith( '.' ) ) referenceField += '.';
        List<String> result = new List<String>();
        for( Schema.SObjectField field : fields ) {
            result.add( referenceField + field.getDescribe().getName() );
        }
        return String.join( result, ', ');
    }

    public static String createStringKey( SObject record, Set<Schema.SObjectField> fields ) {
        List<String> results = new List<String>();
        for( Schema.SObjectField field : fields ) {
            results.add( (String)record.get( field.getDescribe().getName() ) );
        }
        return String.join(results, KEY_DELIMITER);
    }

    public static Set<String> getStringFieldValues(List<SObject> records, Schema.SObjectField field){
    	Set<String> fieldValues = new Set<String>();
    	String fieldName = field.getDescribe().getName();
    	for (SObject rec : records){
    		fieldValues.add( (String)rec.get( fieldName ) );
    	}
    	return fieldValues;
    }

    public static Datetime getCreatedDate(SObject record){
    	Datetime createdDate = (Datetime)record.get('CreatedDate');
    	return createdDate != null ? createdDate : Datetime.now();
    }

}