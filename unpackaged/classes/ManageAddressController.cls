public without sharing class ManageAddressController extends AddressManager {

    private void populateFieldSets() {
        setFieldSetMember( addressFieldsA,   SObjectType.Address__c.FieldSets.Manage_Address_Address_Fields );
        setFieldSetMember( addInfoFieldsAm,  SObjectType.Address_Mapping__c.FieldSets.Manage_Address_Additional_Information_Fi );
        setFieldSetMember( relatedFieldsC,   SObjectType.Contact.FieldSets.Manage_Address_Related_Contacts_Fields );
        setFieldSetMember( selectedFieldsAm, SObjectType.Address_Mapping__c.FieldSets.Manage_Address_Selected_Contacts_Fields );
        setFieldSetMember( selectedFieldsC,  SObjectType.Contact.FieldSets.Manage_Address_Selected_Contacts_Fields );
        setFieldSetMember( selectedFieldsEditableAm, SObjectType.Address_Mapping__c.FieldSets.Manage_Address_Selected_Contacts_Editabl );
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
    }

    //class specific methods
    //button actions
    public PageReference updateAddressContact() {
        customMessage = null;
        try {
            updatePrimaryOnAddressMapping();
            return cancel();
        } catch( Exception e ) {
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, e.getMessage() ) );
        }
        return null;
    }

    public PageReference updateAddressAccount() {
        customMessage = null;
        try {
            updatePrimaryOnAddressMapping();
            AddressMappingServices.createOrUpdateAddressMappingContact( addressId, selectedContacts );
            return cancel();
        } catch( Exception e ) {
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, e.getMessage() ) );
        }
        return null;
    }

    private void updatePrimaryOnAddressMapping() {
        List<Address_Mapping__c> originalMappings = [ SELECT Primary__c
                                                      FROM Address_Mapping__c
                                                      WHERE Id = : addressMappingRecord.Id ];
        if( !originalMappings.isEmpty() && originalMappings[0].Primary__c != addressMappingRecord.Primary__c ) {
            UPDATE new Address_Mapping__c( Id = addressMappingRecord.Id,
                                           Primary__c = addressMappingRecord.Primary__c );
        }
    }

}