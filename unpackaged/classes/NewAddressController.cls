public without sharing class NewAddressController extends AddressManager {

    private void populateFieldSets() {
        setFieldSetMember( addressFieldsA,   SObjectType.Address__c.FieldSets.New_Address_Address_Fields );
        setFieldSetMember( addInfoFieldsAm,  SObjectType.Address_Mapping__c.FieldSets.New_Address_Additional_Information_Field );
        setFieldSetMember( relatedFieldsC,   SObjectType.Contact.FieldSets.New_Address_Related_Contacts_Fields );
        setFieldSetMember( selectedFieldsAm, SObjectType.Address_Mapping__c.FieldSets.New_Address_Selected_Contacts_Fields );
        setFieldSetMember( selectedFieldsC,  SObjectType.Contact.FieldSets.New_Address_Selected_Contacts_Fields );
        setFieldSetMember( selectedFieldsEditableAm, SObjectType.Address_Mapping__c.FieldSets.New_Address_Selected_Contacts_Editable_F );
    }

    private void init() {
        try {
            String parentRecordId = ApexPages.currentPage().getParameters().get( 'id' );
            if( String.isEmpty( parentRecordId ) || !(parentRecordId instanceOf Id) ||
                ( !parentRecordId.startsWith( Utils.getObjectPrefix( Account.sObjectType ) ) &&
                  !parentRecordId.startsWith( Utils.getObjectPrefix( Contact.sObjectType ) ) ) ) {
                Throw new AamException( AamException.OBJECT_NOT_SUPPORTED );
            }
            recordId = parentRecordId;
        } catch( Exception e ) {
            hasError = true;
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, e.getMessage() ) );
        }
    }

    private void initData() {
        try {
            String query = 'SELECT Name';
            if( getIsContact() ) {
                query += ', AccountId, Account.Name';
            }
            query += ' FROM ' + getObjectName();
            query += ' WHERE Id = \'' + recordId + '\'';
            List<SObject> records = Database.query( query );
            if( records.isEmpty() ) {
                Throw new AamException( AamException.NO_RECORD );
            }
            record = records[0];
        } catch( Exception e ) {
            hasError = true;
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, e.getMessage() ) );
        }
    }

    private void initPrepopulate() {
        try {
            String addressType = ApexPages.currentPage().getParameters().get( Utils.PARAM_ADDRESS_MAPPING_TYPE );
            if( String.isEmpty( addressType ) ) return;
            addressMappingRecord.Address_Type__c = addressType;
            String contactIdsStr = ApexPages.currentPage().getParameters().get( Utils.PARAM_CONTACT_IDS );
            if( String.isEmpty( contactIdsStr ) ) return;
            List<String> contactIds = contactIdsStr.split( ',' );
            if( contactIds.isEmpty() ) return;
            for( Integer i = contactIds.size() - 1; i >= 0; i-- ) {
                if( String.isEmpty( contactIds[i] ) || !( contactIds[i] instanceOf Id ) ) continue;
                linkContactId = contactIds[i];
                linkContact();
            }
        } catch( Exception e ) {
            hasError = true;
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, e.getMessage() ) );
        }
    }

    //class specific methods
    //related addresses (Contact)
    public transient List<AddressMappingWrapper> relatedAddresses;
    public List<AddressMappingWrapper> getRelatedAddresses() {
        List<AddressMappingWrapper> result = new List<AddressMappingWrapper>();
        if( getAccountId() == null ) return result;
        String query = 'SELECT ' + String.join(
                                       new List<String>(
                                           Utils.getFieldsFromFieldSet(
                                               SObjectType.Address_Mapping__c.FieldSets.New_Address_Account_Addresses_Fields.getFields(),
                                               Utils.addFieldsToList( Utils.addFieldsToList( null, AddressServices.FIELDS_NEEDED_RELATED_ADDRESSES ), AddressMappingWrapper.FIELDS_NEEDED_ADDRESS_WRAPPER ),
                                               true
                                           )
                                       ), ', '
                                   ) + ' ';
        query += 'FROM Address_Mapping__c ';
        query += 'WHERE Account__c = \'' + getAccountId() + '\' ';
        query +=   'AND Active__c = true ';
        query += 'ORDER BY Address_Line_1__c ASC';
        for( Address_Mapping__c addressItem : Database.query( query ) ) {
            result.add( new AddressMappingWrapper( addressItem ) );
        }
        result.sort();
        return result;
    }

    public String filterTextRelatedAddresses { get; set; }
    public void filterRelatedAddresses() {
        customMessage = null;
    }

    public transient List<AddressMappingWrapper> filteredRelatedAddresses;
    public List<AddressMappingWrapper> getFilteredRelatedAddresses() {
        return AddressMappingWrapper.getFilteredAddressesForRelatedAddresses( getRelatedAddresses(),
                                                                              filterTextRelatedAddresses,
                                                                              primaryFilterRelatedAddresses );
    }

    public static final String PRIMARY_OPTION = 'Primary';
    public static final String ALL_OPTION = 'All';

    public String primaryFilterRelatedAddresses {
        get {
            if( primaryFilterRelatedAddresses == null ) {
                primaryFilterRelatedAddresses = Utils.aamSettings.Cont_New_Addr_Primary_Defaults_To_All__c ? ALL_OPTION : PRIMARY_OPTION;
            }
            return primaryFilterRelatedAddresses;
        }
        set;
    }
    public transient List<SelectOption> primaryFilterRelatedAddressesOptions;
    public List<SelectOption> getPrimaryFilterRelatedAddressesOptions() {
        List<SelectOption> result = new List<SelectOption>();
        result.add( new SelectOption( PRIMARY_OPTION, PRIMARY_OPTION ) );
        result.add( new SelectOption( ALL_OPTION, ALL_OPTION ) );
        return result;
    }

    //address search management
    public transient Id accountId;
    public Id getAccountId() {
        if( getIsContact() ) {
            return (Id)record.get( 'AccountId' );
        } else if( getIsAccount() ) {
            return record.Id;
        }
        return null;
    }

    public transient List<Address__c> addresses;
    public List<Address__c> getAddresses() {
        return AddressServices.getRelatedAddressesInHierarchy( getAccountId(), addressRecord, getMinFieldsEntered(), false );
    }

    public String selectAddressId { get; set; }
    public void selectAddress() {
        customMessage = null;
        addressId = selectAddressId;
        selectAddressId = null;
    }

    public Integer getMinFieldsEntered() {
        return 2;
    }

    public Integer getNumFieldsEntered() {
        return AddressServices.getNumFieldsEntered( addressRecord );
    }

    public void clearAddress() {
        customMessage = null;
        addressId = null;
        addressRecord = null;
    }

    public void doSearch() {
        Address__c clonedAddressRecord = addressRecord.clone( false );
        clearAddress();
        Address__c newAddressRecord = new Address__c();
        for( Schema.FieldSetMember field : SObjectType.Address__c.FieldSets.New_Address_Address_Fields.getFields() ) {
            String fieldApiName = field.getFieldPath();
            newAddressRecord.put( fieldApiName, clonedAddressRecord.get( fieldApiName ) );
        }
        addressRecord = newAddressRecord;
    }

    //button actions
    public PageReference createAddressContact() {
        customMessage = null;
        try {
            Address__c newAddressRecord = createOrUpdateAddress();

            ContactWrapper contactItem = new ContactWrapper( new Contact( Id = recordId ) );
            contactItem.addressMapping = addressMappingRecord;
            AddressMappingServices.createOrUpdateAddressMappingContact( newAddressRecord.Id, new List<ContactWrapper>{ contactItem } );
            return cancel();
        } catch( Exception e ) {
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, e.getMessage() ) );
        }
        return null;
    }

    public PageReference createAddressAccount() {
        customMessage = null;
        try {
            Address__c newAddressRecord = createOrUpdateAddress();

            createOrUpdateAddressMappingAccount( newAddressRecord );
            if( customMessage != null ) return null;

            AddressMappingServices.createOrUpdateAddressMappingContact( newAddressRecord.Id, selectedContacts );
            return cancel();
        } catch( Exception e ) {
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, e.getMessage() ) );
        }
        return null;
    }

    private Address__c createOrUpdateAddress() {
        if( String.isEmpty( addressMappingRecord.Address_Type__c ) ) {
            Throw new AamException( 'Address type should be selected in order to create address links' );
        }
        if( String.isEmpty( getAccountId() ) ) {
            Throw new AamException( Label.Message_No_Account_Id_On_Contact );
        }
        Address__c newAddressRecord;
        Boolean doUpsert = false;
        if( addressId == null ) {
            //NO ADDRESS ID: DO SEARCH
            List<Address__c> foundAddresses = AddressServices.getRelatedAddressesInHierarchy( getAccountId(),
                                                                                              addressRecord,
                                                                                              null,
                                                                                              Utils.addFieldsToList( null, AddressServices.STATUS_FIELD ),
                                                                                              Utils.addFieldsToList( null, AddressServices.FIELDS_FOR_ADDRESS_MATCHING ),
                                                                                              true );
            if( !foundAddresses.isEmpty() ) {
                //FOUND AN ADDRESS
                newAddressRecord = foundAddresses[0];
            } else {
                //NO ADDRESS FOUND
                newAddressRecord = addressRecord.clone( false );
                newAddressRecord.Account__c = getAccountId();
                newAddressRecord.Status__c = AddressServices.STATUS_ACTIVE;
                doUpsert = true;
            }
        } else {
            newAddressRecord = addressRecord.clone( true );
        }
        if( newAddressRecord.Status__c == AddressServices.STATUS_INACTIVE ) {
            newAddressRecord.Status__c = AddressServices.STATUS_ACTIVE;
            doUpsert = true;
        }
        if( doUpsert ) {
            UPSERT newAddressRecord;
        }

        return newAddressRecord;
    }

    public void createOrUpdateAddressMappingAccount( Address__c newAddressRecord ) {
        List<Address_Mapping__c> duplicateAddressMappings = [ SELECT Id
                                                              FROM Address_Mapping__c
                                                              WHERE Address__c = :newAddressRecord.Id
                                                                AND Account__c = :recordId
                                                                AND Active__c = true
                                                                AND Address_Type__c = :addressMappingRecord.Address_Type__c ];
        if( duplicateAddressMappings.isEmpty() ) {
            Address_Mapping__c newAddressMapping = new Address_Mapping__c(
                Address__c = newAddressRecord.Id,
                Account__c = recordId,
                Address_Type__c = addressMappingRecord.Address_Type__c,
                Primary__c = addressMappingRecord.Primary__c,
                Active__c = true
            );
            INSERT newAddressMapping;
        } else {
            customMessage = Label.Message_Duplicate_Address_Link_On_Account;
        }
    }

}