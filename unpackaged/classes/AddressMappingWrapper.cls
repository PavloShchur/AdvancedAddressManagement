public without sharing class AddressMappingWrapper implements Comparable {

    public static final List<Schema.SObjectField> FIELDS_NEEDED_ADDRESS_WRAPPER = new List<Schema.SObjectField>{
        Address_Mapping__c.Address_Type__c,
        Address_Mapping__c.Address_Line_1__c,
        Address_Mapping__c.Address_Line_2__c,
        Address_Mapping__c.City__c,
        Address_Mapping__c.State_County__c,
        Address_Mapping__c.Postcode__c,
        Address_Mapping__c.Country__c,
        Address_Mapping__c.Primary__c
    };

    public Address_Mapping__c record { get { if( record == null ) { record = new Address_Mapping__c(); } return record; } set; }
    public Boolean hasContactsWithMappings { get { if( hasContactsWithMappings == null ) { hasContactsWithMappings = false; } return hasContactsWithMappings; } set; }
    public Integer recordsOfSameType { get { if( recordsOfSameType == null ) { recordsOfSameType = 0; } return recordsOfSameType; } set; }

    public String getAddress() {
        return AddressMappingServices.getAddress( record );
    }

    public AddressMappingWrapper( Address_Mapping__c record ) {
        this.record = record;
    }

    public Integer compareTo( Object compareToObj ) {
        AddressMappingWrapper compareTo = (AddressMappingWrapper)compareToObj;
        if( record.Address_Type__c == compareTo.record.Address_Type__c && record.Primary__c == compareTo.record.Primary__c ) {
            return record.Address_Line_1__c == compareTo.record.Address_Line_1__c
                   ? 0
                   : ( record.Address_Line_1__c == null
                       ? 1
                       : ( compareTo.record.Address_Line_1__c == null
                           ? -1
                           : ( record.Address_Line_1__c > compareTo.record.Address_Line_1__c
                               ? 1 : -1 ) ) );
        }
        if( record.Primary__c && record.Address_Type__c == AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS ) {
            return -1;
        }
        if( !record.Primary__c && record.Address_Type__c == AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS ) {
            if( compareTo.record.Primary__c && compareTo.record.Address_Type__c == AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS ) {
                return 1;
            }
            return -1;
        }
        if( compareTo.record.Address_Type__c == AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS ) {
            return 1;
        }
        if( record.Primary__c ) {
            if( compareTo.record.Primary__c &&
                ( ( record.Address_Type__c == null && compareTo.record.Address_Type__c != null ) ||
                  ( record.Address_Type__c != null && compareTo.record.Address_Type__c != null && record.Address_Type__c > compareTo.record.Address_Type__c ) ) ) {
                return 1;
            }
            return -1;
        } else {
            if( !compareTo.record.Primary__c &&
                ( ( record.Address_Type__c != null && compareTo.record.Address_Type__c == null ) ||
                  ( record.Address_Type__c != null && compareTo.record.Address_Type__c != null && record.Address_Type__c < compareTo.record.Address_Type__c ) ) ) {
                return -1;
            }
            return 1;
        }
    }

    public static List<AddressMappingWrapper> getFilteredAddressesForRelatedAddresses( List<AddressMappingWrapper> allAddresses, String filterText, String primaryFilter ) {
        List<AddressMappingWrapper> result = new List<AddressMappingWrapper>();
        List<AddressMappingWrapper> primaryAddresses = new List<AddressMappingWrapper>();
        for( AddressMappingWrapper addressItem : allAddresses ) {
            if( primaryFilter == NewAddressController.PRIMARY_OPTION && !addressItem.record.Primary__c ) continue;
            primaryAddresses.add( addressItem );
        }
        String fieldData;
        if( String.isEmpty( filterText ) ) return primaryAddresses;
        for( AddressMappingWrapper addressItem : primaryAddresses ) {
            for( Schema.FieldSetMember fieldItem : SObjectType.Address_Mapping__c.FieldSets.New_Address_Account_Addresses_Fields.getFields() ) {
                if( fieldItem.getType() == Schema.DisplayType.BOOLEAN ) continue;
                String fieldApiName = fieldItem.getFieldPath();
                fieldData = fieldApiName != Address_Mapping__c.Address_Lines__c.getDescribe().getName()
                            ? Utils.getFieldDataForSearch( addressItem.record, fieldItem )
                            : addressItem.getAddress();
                if( fieldData == null || !fieldData.containsIgnoreCase( filterText ) ) continue;
                result.add( addressItem );
                break;
            }
        }
        return result;
    }

}