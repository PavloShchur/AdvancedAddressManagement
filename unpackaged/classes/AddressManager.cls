public without sharing abstract class AddressManager {

    public List<Schema.FieldSetMember> addressFieldsA   { get { if( addressFieldsA   == null ) { addressFieldsA   = new List<Schema.FieldSetMember>(); } return addressFieldsA;   } set; }
    public List<Schema.FieldSetMember> addInfoFieldsAm  { get { if( addInfoFieldsAm  == null ) { addInfoFieldsAm  = new List<Schema.FieldSetMember>(); } return addInfoFieldsAm;  } set; }
    public List<Schema.FieldSetMember> relatedFieldsC   { get { if( relatedFieldsC   == null ) { relatedFieldsC   = new List<Schema.FieldSetMember>(); } return relatedFieldsC;   } set; }
    public List<Schema.FieldSetMember> selectedFieldsAm { get { if( selectedFieldsAm == null ) { selectedFieldsAm = new List<Schema.FieldSetMember>(); } return selectedFieldsAm; } set; }
    public List<Schema.FieldSetMember> selectedFieldsC  { get { if( selectedFieldsC  == null ) { selectedFieldsC  = new List<Schema.FieldSetMember>(); } return selectedFieldsC;  } set; }
    public List<Schema.FieldSetMember> selectedFieldsEditableAm { get { if( selectedFieldsEditableAm == null ) { selectedFieldsEditableAm = new List<Schema.FieldSetMember>(); } return selectedFieldsEditableAm; } set; }

    public void setFieldSetMember( List<Schema.FieldSetMember> fieldSetMemberList, Schema.FieldSet fieldSet ) {
        if( fieldSet != null ) {
            fieldSetMemberList.addAll( fieldSet.getFields() );
        }
    }

    public AddressManager() {
        populateFieldSets();
        init();
        initData();
        initPrepopulate();
    }

    private abstract void populateFieldSets();
    private abstract void init();
    private abstract void initData();
    private abstract void initPrepopulate();

    public Boolean hasError { get { if( hasError == null ) { hasError = false; } return hasError; } set; }
    public String customMessage { get; set; }

    //parent record
    public Id recordId { get; set; }
    public SObject record { get; set; }

    //address
    public Id addressId { get; set; }

    public Address__c addressRecord {
        get {
            if( addressRecord == null || addressRecord.Id != addressId ) {
                addressRecord = AddressServices.getAddressRecord( addressId, addressFieldsA, Utils.aamSettings );
                addressId = addressRecord.Id;
            }
            return addressRecord;
        }
        set {
            addressRecord = value;
            addressId = value != null ? value.Id : null;
        }
    }

    public transient String addressLines;
    public String getAddressLines() {
        return AddressServices.getAddressLines( addressRecord );
    }


    //address mapping
    public Id addressMappingId { get; set; }

    public Address_Mapping__c addressMappingRecord {
        get {
            if( addressMappingRecord == null ) {
                if( addressMappingId != null ) {
                    addressMappingRecord = AddressMappingServices.getAddressMappingRecord(
                        addressMappingId,
                        Utils.joinFieldsInFieldSets( addInfoFieldsAm, selectedFieldsAm ),
                        new List<Schema.SObjectField>{ Address_Mapping__c.Primary__c, Address_Mapping__c.Address_Type__c }
                    );
                } else {
                    addressMappingRecord = new Address_Mapping__c( Address__c = addressRecord.Id );
                }
            }
            return addressMappingRecord;
        }
        set;
    }

    public transient List<FieldInfo> addressMappingFields;
    public List<FieldInfo> getAddressMappingFields() {
        return Utils.getFieldInfos( addInfoFieldsAm, getAddressMappingHardcodedFields() );
    }

    public transient List<FieldInfo> addressMappingHardcodedFields;
    public virtual List<FieldInfo> getAddressMappingHardcodedFields() {
        return Utils.getFieldInfos( new List<Schema.SObjectField>{ Address_Mapping__c.Address_Type__c } );
    }

    public transient List<SelectOption> addressTypeValues;
    public List<SelectOption> getAddressTypeValues() {
        return populateAddressTypeOptions( String.isEmpty( addressMappingRecord.Address_Type__c ), '--None--' );
    }

    //related contacts (Account)
    public List<ContactWrapper> relatedContacts {
        get {
            if( relatedContacts == null ) {
                relatedContacts = getRelatedContacts();
            }
            return relatedContacts;
        }
        private set;
    }

    public virtual List<ContactWrapper> getRelatedContacts() {
        List<ContactWrapper> relatedContactsResult = new List<ContactWrapper>();
        if( recordId == null ) return relatedContactsResult;
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
        if( !String.isEmpty( Utils.aamSettings.Active_Contact_Definition_Field__c ) ) {
            query += 'AND ' +  Utils.aamSettings.Active_Contact_Definition_Field__c + ' = true ';
        }
        query += 'ORDER BY Name ASC';
        for( Contact contactFound : Database.query( query ) ) {
            relatedContactsResult.add( new ContactWrapper( contactFound ) );
        }
        return relatedContactsResult;
    }

    public Id linkContactId { get; set; }
    public virtual void linkContact() {
        linkContact( true );
    }

    public void linkContact( Boolean useParentMappingRecord ) {
        customMessage = null;
        if( linkContactId == null ) return;
        List<ContactWrapper> newSelectedContacts = new List<ContactWrapper>();
        for( ContactWrapper contactItem : relatedContacts ) {
            if( contactItem.record.Id == linkContactId ) {
                if( useParentMappingRecord ) {
                    contactItem.setSelected( true, addressMappingRecord );
                    contactItem.resetPrimary();
                } else {
                    contactItem.setSelected( true );
                }
                newSelectedContacts.add( contactItem );
                break;
            }
        }
        newSelectedContacts.addAll( selectedContacts );
        selectedContacts = newSelectedContacts;
    }

    public virtual void linkAllContacts() {
        linkAllContacts( true );
    }

    public void linkAllContacts( Boolean useParentMappingRecord ) {
        customMessage = null;
        Set<Id> alreadySelectedContactIds = new Set<Id>();
        for( ContactWrapper contactItem : selectedContacts ) {
            alreadySelectedContactIds.add( contactItem.record.Id );
        }
        List<ContactWrapper> newSelectedContacts = new List<ContactWrapper>();
        for( ContactWrapper contactItem : getFilteredRelatedContacts() ) {
            if( useParentMappingRecord ) {
                contactItem.setSelected( true, addressMappingRecord );
                contactItem.resetPrimary();
            } else {
                contactItem.setSelected( true );
            }
            if( !alreadySelectedContactIds.contains( contactItem.record.Id ) ) {
                newSelectedContacts.add( contactItem );
            }
        }
        newSelectedContacts.addAll( selectedContacts );
        selectedContacts = newSelectedContacts;
    }

    public transient Boolean areAllFilteredRelatedContactsSelected;
    public Boolean getAreAllFilteredRelatedContactsSelected() {
        return ContactWrapper.areAllContactsSelected( getFilteredRelatedContacts() );
    }

    public String filterTextRelatedContacts { get; set; }
    public void filterRelatedContacts() {
        customMessage = null;
    }

    public transient List<ContactWrapper> filteredRelatedContacts;
    public List<ContactWrapper> getFilteredRelatedContacts() {
        return ContactWrapper.getFilteredContacts( relatedContacts, filterTextRelatedContacts, relatedFieldsC );
    }


    //selected contacts (Account)
    public List<ContactWrapper> selectedContacts { get { if( selectedContacts == null ) { selectedContacts = new List<ContactWrapper>(); } return selectedContacts; } set; }

    public String headerAddressType { get; set; }
    public transient List<SelectOption> headerAddressTypes;
    public List<SelectOption> getHeaderAddressTypes() {
        Boolean allAddressesHaveSameType = true;
        String initialAddressType;
        for( ContactWrapper contactItem : getFilteredSelectedContacts() ) {
            if( initialAddressType == null ) {
                initialAddressType = contactItem.addressMapping.Address_Type__c;
            }
            if( initialAddressType == contactItem.addressMapping.Address_Type__c ) continue;
            allAddressesHaveSameType = false;
            break;
        }
        headerAddressType = allAddressesHaveSameType ? initialAddressType : null;
        return populateAddressTypeOptions( !allAddressesHaveSameType, '' );
    }

    public void setHeaderAddressTypes() {
        customMessage = null;
        if( headerAddressType == null ) return;
        for( ContactWrapper contactItem : getFilteredSelectedContacts() ) {
            contactItem.addressMapping.Address_Type__c = headerAddressType;
        }
    }

    public Boolean headerPrimary { get { return getHeaderPrimaries(); } set { headerPrimaryValue = value; } }
    public Boolean getHeaderPrimaries() {
        for( ContactWrapper contactItem : getFilteredSelectedContacts() ) {
            if( contactItem.addressMapping.Primary__c ) continue;
            return false;
        }
        return true;
    }

    public Boolean headerPrimaryValue { get; set; }
    public void setHeaderPrimaries() {
        customMessage = null;
        if( headerPrimaryValue == null ) return;
        for( ContactWrapper contactItem : getFilteredSelectedContacts() ) {
            contactItem.addressMapping.Primary__c = headerPrimaryValue;
        }
    }

    public Id unlinkContactId { get; set; }
    public virtual void unlinkContact() {
        unlinkContact( true );
    }

    public void unlinkContact( Boolean removeAddress ) {
        customMessage = null;
        if( unlinkContactId == null ) return;
        for( Integer i = 0; i < selectedContacts.size(); i++ ) {
            ContactWrapper contactItem = selectedContacts[i];
            if( contactItem.record.Id == unlinkContactId ) {
                contactItem.setSelected( false );
                if( removeAddress ) {
                    contactItem.removeAddress();
                }
                selectedContacts.remove( i );
            }
        }
    }

    public virtual void unlinkAllContacts() {
        unlinkAllContacts( true );
    }

    public void unlinkAllContacts( Boolean removeAddress ) {
        customMessage = null;
        Set<Id> alreadySelectedContactIds = new Set<Id>();
        for( ContactWrapper contactItem : getFilteredSelectedContacts() ) {
            alreadySelectedContactIds.add( contactItem.record.Id );
        }
        List<ContactWrapper> newSelectedContacts = new List<ContactWrapper>();
        for( ContactWrapper contactItem : selectedContacts ) {
            if( alreadySelectedContactIds.contains( contactItem.record.Id ) ) {
                contactItem.setSelected( false );
                if( removeAddress ) {
                    contactItem.removeAddress();
                }
            } else {
                newSelectedContacts.add( contactItem );
            }
        }
        selectedContacts = newSelectedContacts;
    }

    public String filterTextSelectedContacts { get; set; }
    public void filterSelectedContacts() {
        customMessage = null;
    }

    public transient List<ContactWrapper> filteredSelectedContacts;
    public List<ContactWrapper> getFilteredSelectedContacts() {
        return ContactWrapper.getFilteredContactsForSelectedContacts(
            selectedContacts, filterTextSelectedContacts, addressRecord, selectedFieldsC, selectedFieldsAm
        );
    }

    public transient String editableSelectedContactsFields;
    public String getEditableSelectedContactsFields() {
        String result = '';
        for( Schema.FieldSetMember field : selectedFieldsEditableAm ) {
            result += field.getFieldPath() + ', ';
        }
        return result;
    }

    //general methods
    public transient Aam_Settings__c settings;
    public Aam_Settings__c getSettings() {
        return Utils.aamSettings;
    }

    public String getObjectName() {
        return Utils.getObjectNameByIdOrPrefix( recordId );
    }

    public transient Boolean isContact;
    public Boolean getIsContact() {
        return getObjectName() == Contact.sObjectType.getDescribe().getName();
    }

    public transient Boolean isAccount;
    public Boolean getIsAccount() {
        return getObjectName() == Account.sObjectType.getDescribe().getName();
    }

    public PageReference cancel() {
        customMessage = null;
        return Utils.getReturnPageReference( recordId );
    }

    private List<SelectOption> populateAddressTypeOptions( Boolean addNone, String noneValue ) {
        List<SelectOption> options = new List<SelectOption>();
        if( addNone ) {
            options.add( new SelectOption( '', noneValue ) );
        }
        for( Schema.PicklistEntry picklistValue : Address_Mapping__c.Address_Type__c.getDescribe().getPicklistValues() ) {
            options.add( new SelectOption( picklistValue.getLabel(), picklistValue.getValue() ) );
        }
        return options;
    }

    public void reRender() {
        customMessage = null;
    }

}