public without sharing class AddressListController {

    private static final List<Schema.SObjectField> FIELDS_NEEDED_ADDRESS_LIST_PAGE = new List<Schema.SObjectField>{
        Address_Mapping__c.Address_Type__c,
        Address_Mapping__c.Primary__c,
        Address_Mapping__c.Map_Link__c,
        Address_Mapping__c.Address__c
    };

    public Id recordId { get; set; }

    public AddressListController() {
        this.recordId = ApexPages.currentPage().getParameters().get( 'id' );
    }

    public String getObjectName() {
        return Utils.getObjectNameByIdOrPrefix( recordId );
    }

    public Boolean getNewAddressLinkAvailable() {
        String objectName = getObjectName();
        if( objectName == Contact.sObjectType.getDescribe().getName() ) {
            List<Contact> contacts = [ SELECT AccountId FROM Contact WHERE Id = : recordId ];
            if( contacts.isEmpty() || contacts[0].AccountId == null ) {
                return false;
            }
        }
        return true;
    }

    public transient List<AddressMappingWrapper> addressMappings;
    public List<AddressMappingWrapper> getAddressMappings() {
        if( addressMappings != null ) return addressMappings;
        List<AddressMappingWrapper> results = new List<AddressMappingWrapper>();
        Map<String, List<AddressMappingWrapper>> addressTypeToAddressMappings = new Map<String, List<AddressMappingWrapper>>();
        Set<Id> accountAddressIds = new Set<Id>();
        String parentObjectName = getObjectName();

        if( !Utils.SUPPORTED_PARENT_OBJECTS.contains( parentObjectName ) ) return results;
        String query = 'SELECT ' + String.join(
                                       new List<String>(
                                           Utils.getFieldsFromFieldSet(
                                               SObjectType.Address_Mapping__c.FieldSets.Address_List_Search_Fields.getFields(),
                                               Utils.addFieldsToList( Utils.addFieldsToList( null, FIELDS_NEEDED_ADDRESS_LIST_PAGE ), AddressMappingWrapper.FIELDS_NEEDED_ADDRESS_WRAPPER )
                                           )
                                       ), ','
                                   ) + ' ';
        query +=       'FROM Address_Mapping__c ';
        query +=       'WHERE ' + parentObjectName + '__c = \'' + recordId + '\' ';
        query +=         'AND Active__c = true ';
        for( Address_Mapping__c mapping : Database.query( query ) ) {
            AddressMappingWrapper addressMappingWrapper = new AddressMappingWrapper( mapping );
            results.add( addressMappingWrapper );
            if( addressTypeToAddressMappings.get( mapping.Address_Type__c ) == null ) {
                addressTypeToAddressMappings.put( mapping.Address_Type__c, new List<AddressMappingWrapper>() );
            }
            addressTypeToAddressMappings.get( mapping.Address_Type__c ).add( addressMappingWrapper );
            accountAddressIds.add( mapping.Address__c );
        }

        for( String addressType : addressTypeToAddressMappings.keySet() ) {
            List<AddressMappingWrapper> addressMappingWrappers = addressTypeToAddressMappings.get( addressType );
            for( AddressMappingWrapper addressMappingWrapper : addressMappingWrappers ) {
                addressMappingWrapper.recordsOfSameType = addressMappingWrappers.size();
            }
        }

        if( getObjectName() == Account.sObjectType.getDescribe().getName() ) {
            Set<String> existingAddressMappingKeys = new Set<String>();
            query  = 'SELECT Address__c, Address_Type__c ';
            query += 'FROM Address_Mapping__c ';
            query += 'WHERE Address__c IN :accountAddressIds ';
            query += 'AND Contact__r.AccountId = \'' + recordId + '\' ';
            if( !String.isEmpty( Utils.aamSettings.Active_Contact_Definition_Field__c ) ) {
                query += 'AND Contact__r.' +  Utils.aamSettings.Active_Contact_Definition_Field__c + ' = true ';
            }
            query += 'AND Active__c = true';
            for( Address_Mapping__c addressMapping : Database.query( query ) ) {
                String key = addressMapping.Address__c + addressMapping.Address_Type__c;
                existingAddressMappingKeys.add( key );
            }
            for( AddressMappingWrapper result : results ) {
                String key = result.record.Address__c + result.record.Address_Type__c;
                if( existingAddressMappingKeys.contains( key ) ) {
                    result.hasContactsWithMappings = true;
                }
            }
        }

        results.sort();
        return results;
    }

    public String filterText { get; set; }
    public void filterRecords() {
    }

    public transient List<AddressMappingWrapper> filteredRecords;
    public List<AddressMappingWrapper> getFilteredRecords() {
        List<AddressMappingWrapper> addressMappingWrappers = getAddressMappings();
        List<AddressMappingWrapper> result = new List<AddressMappingWrapper>();
        if( String.isEmpty( filterText ) ) return addressMappingWrappers;
        List<Schema.FieldSetMember> fields = SObjectType.Address_Mapping__c.FieldSets.Address_List_Search_Fields.getFields();
        for( AddressMappingWrapper addressMappingWrapper : addressMappingWrappers ) {
            String searchString = Utils.joinFieldValues( addressMappingWrapper.record, fields );
            if( searchString.containsIgnoreCase( filterText ) ) {
                result.add( addressMappingWrapper );
            }
        }
        return result;
    }

    public Id deactivateAddressRecordId { get; set; }
    public void deactivateAddress() {
        if( deactivateAddressRecordId == null ) return;
        try {
            AddressMappingServices.deactivateAddressMappings( new Set<Id>{ deactivateAddressRecordId } );
        } catch( Exception e ) {
            if( e.getMessage().contains( AamException.ENTITY_IS_DELETED ) ) return;
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, e.getMessage() ) );
        }
    }

    //general methods
    public transient Aam_Settings__c settings;
    public Aam_Settings__c getSettings() {
        return Utils.aamSettings;
    }

}