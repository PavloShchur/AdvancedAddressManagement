public without sharing class DeactivateAddressController extends AddressManager {

    private void populateFieldSets() {
        setFieldSetMember( addressFieldsA,           SObjectType.Address__c.FieldSets.Deactivate_Address_Address_Fields );
        setFieldSetMember( addInfoFieldsAm,          SObjectType.Address_Mapping__c.FieldSets.Deactivate_Address_Additional_Informatio );
        setFieldSetMember( relatedFieldsC,           SObjectType.Contact.FieldSets.Deactivate_Address_Related_Contacts_Fiel );
        setFieldSetMember( selectedFieldsAm,         SObjectType.Address_Mapping__c.FieldSets.Deactivate_Address_Selected_Contacts_Fie );
        setFieldSetMember( selectedFieldsC,          SObjectType.Contact.FieldSets.Deactivate_Address_Selected_Contacts_Fie );
        setFieldSetMember( selectedFieldsEditableAm, null );
    }

    private void init() {
        try {
            String parentRecordId = ApexPages.currentPage().getParameters().get( 'id' );
            if( String.isEmpty( parentRecordId ) || !(parentRecordId instanceOf Id) ||
                ( !parentRecordId.startsWith( Utils.getObjectPrefix( Address_Mapping__c.sObjectType ) ) ) ) {
                Throw new AamException( AamException.OBJECT_NOT_SUPPORTED );
            }
            addressMappingId = parentRecordId;
        } catch( Exception e ) {
            hasError = true;
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, e.getMessage() ) );
        }
    }

    private void initData() {
        try {
            List<Address_Mapping__c> addressMappings = [ SELECT Address__c, Contact__c, Account__c
                                                         FROM Address_Mapping__c
                                                         WHERE Id = : addressMappingId ];
            if( addressMappings.isEmpty() || ( addressMappings[0].Contact__c == null && addressMappings[0].Account__c == null ) ) {
                Throw new AamException( AamException.NO_RECORD );
            }
            addressId = addressMappings[0].Address__c;
            if( addressMappings[0].Contact__c != null ) {
                recordId = addressMappings[0].Contact__c;
            } else if( addressMappings[0].Account__c != null ) {
                recordId = addressMappings[0].Account__c;
            }
            String query = 'SELECT Name';
            query += ' FROM ' + getObjectName();
            query += ' WHERE Id = \'' + recordId + '\'';
            List<SObject> records = Database.query( query );
            if( records.isEmpty() ) {
                Throw new AamException( AamException.NO_RECORD );
            }
            record = records[0];
        } catch( Exception e ) {
            hasError = true;
        }
    }

    private void initPrepopulate() {
        if( getSettings().Enforce_Contact_Address_Deactivation__c ) {
            linkAllContacts();
        }
    }

    public override List<FieldInfo> getAddressMappingHardcodedFields() {
        return new List<FieldInfo>();
    }

    public override List<ContactWrapper> getRelatedContacts() {
        List<ContactWrapper> relatedContactsResult = new List<ContactWrapper>();
        if( recordId == null || addressId == null ) return relatedContactsResult;
        Map<Id, List<Address_Mapping__c>> contactIdToAddressMapping = new Map<Id, List<Address_Mapping__c>>();
        for( Address_Mapping__c similarAddressMapping : AddressMappingServices.getAddressMappingRecords( addressRecord,
                                                                                                         addressMappingRecord,
                                                                                                         Utils.joinFieldsInFieldSets( addInfoFieldsAm, selectedFieldsAm ),
                                                                                                         new List<Schema.SObjectField>{ Address_Mapping__c.Contact__c }
                                                                                                       ) ) {
            if( contactIdToAddressMapping.get( similarAddressMapping.Contact__c ) == null ) {
                contactIdToAddressMapping.put( similarAddressMapping.Contact__c, new List<Address_Mapping__c>() );
            }
            contactIdToAddressMapping.get( similarAddressMapping.Contact__c ).add( similarAddressMapping );
        }
        if( contactIdToAddressMapping.isEmpty() ) return relatedContactsResult;
        String query = 'SELECT ' + String.join(
                                       new List<String>(
                                           Utils.getFieldsFromFieldSet(
                                               Utils.joinFieldsInFieldSets( relatedFieldsC, selectedFieldsC ),
                                               new List<Schema.SObjectField>{ Contact.Name },
                                               true
                                           )
                                       ), ', '
                                   ) + ' ';
        query += 'FROM Contact ';
        query += 'WHERE AccountId = \'' + recordId + '\' ';
        Aam_Settings__c settingsInstance = getSettings();
        if( !String.isEmpty( settingsInstance.Active_Contact_Definition_Field__c ) ) {
            query += 'AND ' +  settingsInstance.Active_Contact_Definition_Field__c + ' = true ';
        }
        Set<Id> contactIds = contactIdToAddressMapping.keySet();
        query += 'AND Id IN :contactIds ';
        query += 'ORDER BY Name ASC';
        for( Contact contactFound : Database.query( query ) ) {
            for( Address_Mapping__c similarAddressMapping : contactIdToAddressMapping.get( contactFound.Id ) ) {
                ContactWrapper contactWrapper = new ContactWrapper( contactFound );
                contactWrapper.addAddress( similarAddressMapping, true );
                relatedContactsResult.add( contactWrapper );
            }
        }
        return relatedContactsResult;
    }

    public override void linkContact() {
        linkContact( false );
    }

    public override void linkAllContacts() {
        linkAllContacts( false );
    }

    public override void unlinkContact() {
        unlinkContact( false );
    }

    public override void unlinkAllContacts() {
        unlinkAllContacts( false );
    }

    //class specific methods
    public PageReference deactivateAddressAccount() {
        try {
            deactivateAddressMappings();
            return cancel();
        } catch( Exception e ) {
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, e.getMessage() ) );
        }
        return null;
    }

    public PageReference deactivateAndCreateAddressAccount() {
        try {
            deactivateAddressMappings();
            return goToNewAddressPage();
        } catch( Exception e ) {
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, e.getMessage() ) );
        }
        return null;
    }

    private void deactivateAddressMappings() {
        Set<Id> mappingsToDeactivate = new Set<Id>();
        mappingsToDeactivate.add( addressMappingId ); //for Account
        for( ContactWrapper contactWrapperItem : selectedContacts ) {
            mappingsToDeactivate.add( contactWrapperItem.addressMapping.Id ); //for related Contacts
        }
        AddressMappingServices.deactivateAddressMappings( mappingsToDeactivate );
    }

    private PageReference goToNewAddressPage() {
        customMessage = null;
        PageReference pr = Page.NewAddress;
        pr.setRedirect( true );
        pr.getParameters().put( 'Id', recordId );
        pr.getParameters().put( Utils.PARAM_ADDRESS_MAPPING_TYPE, addressMappingRecord.Address_Type__c );
        if( !selectedContacts.isEmpty() ) {
            Set<Id> selectedContactIds = new Set<Id>();
            for( ContactWrapper contactWrapperItem : selectedContacts ) {
                selectedContactIds.add( contactWrapperItem.record.Id );
            }
            pr.getParameters().put( Utils.PARAM_CONTACT_IDS, String.join( new List<Id>( selectedContactIds ), Utils.PARAM_SPLITTER ) );
        }
        return pr;
    }

}