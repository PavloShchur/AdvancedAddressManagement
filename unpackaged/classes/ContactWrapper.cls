public without sharing class ContactWrapper {

    public Contact record { get { if( record == null ) { record = new Contact(); } return record; } set; }
    public Address_Mapping__c addressMapping { get; set; }
    private Boolean isSelected;

    public ContactWrapper( Contact record ) {
        this.record = record;
        this.isSelected = false;
    }

    public void setSelected( Boolean isSelected ) {
        this.isSelected = isSelected;
    }

    public void setSelected( Boolean isSelected, Address_Mapping__c addressMapping ) {
        setSelected( isSelected );
        if( this.isSelected == true ) {
            addAddress( addressMapping );
        }
    }

    public Boolean getSelected() {
        return isSelected;
    }

    public void addAddress( Address_Mapping__c addressMapping ) {
        addAddress( addressMapping, false );
    }

    public void addAddress( Address_Mapping__c addressMapping, Boolean cloneId ) {
        this.addressMapping = addressMapping.clone( cloneId );
        this.addressMapping.Contact__c = this.record.Id;
        this.addressMapping.Contact__r = this.record;
    }

    public void resetPrimary() {
        if( addressMapping == null ) return;
        addressMapping.Primary__c = false;
    }

    public void removeAddress() {
        addressMapping = null;
    }

    public static Boolean areAllContactsSelected( List<ContactWrapper> contacts ) {
        Boolean allContactsSelected = true;
        for( ContactWrapper contactItem : contacts ) {
            if( !contactItem.getSelected() ) {
                allContactsSelected = false;
                break;
            }
        }
        return allContactsSelected;
    }

    public static List<ContactWrapper> getFilteredContacts( List<ContactWrapper> allContacts, String filterText, List<Schema.FieldSetMember> fields ) {
        List<ContactWrapper> result = new List<ContactWrapper>();
        String fieldData;
        if( String.isEmpty( filterText ) ) return allContacts;
        for( ContactWrapper contactItem : allContacts ) {
            for( Schema.FieldSetMember fieldItem : fields ) {
                if( fieldItem.getType() == Schema.DisplayType.BOOLEAN ) continue;
                fieldData = Utils.getFieldDataForSearch( contactItem.record, fieldItem );
                if( fieldData == null || !fieldData.containsIgnoreCase( filterText ) ) continue;
                result.add( contactItem );
                break;
            }
        }
        return result;
    }

    public static List<ContactWrapper> getFilteredContactsForSelectedContacts( List<ContactWrapper> allContacts, String filterText, Address__c addressRecord, List<Schema.FieldsetMember> contactFields, List<Schema.FieldsetMember> addressMappingFields ) {
        List<ContactWrapper> result = new List<ContactWrapper>();
        String fieldData;
        if( String.isEmpty( filterText ) ) return allContacts;
        for( ContactWrapper contactItem : allContacts ) {
            Boolean isAdded = false;
            for( Schema.FieldSetMember fieldItem : contactFields ) {
                if( fieldItem.getType() == Schema.DisplayType.BOOLEAN ) continue;
                fieldData = Utils.getFieldDataForSearch( contactItem.record, fieldItem );
                if( fieldData == null || !fieldData.containsIgnoreCase( filterText ) ) continue;
                result.add( contactItem );
                isAdded = true;
                break;
            }
            if( !isAdded ) {
                String addressLines = AddressServices.getAddressLines( addressRecord );
                for( Schema.FieldSetMember fieldItem : addressMappingFields ) {
                    if( fieldItem.getType() == Schema.DisplayType.BOOLEAN ) continue;
                    String fieldApiName = fieldItem.getFieldPath();
                    fieldData = fieldApiName != Address_Mapping__c.Address_Lines__c.getDescribe().getName()
                                ? Utils.getFieldDataForSearch( contactItem.addressMapping, fieldItem )
                                : addressLines;
                    if( fieldData == null || !fieldData.containsIgnoreCase( filterText ) ) continue;
                    result.add( contactItem );
                    break;
                }
            }
        }
        return result;
    }

}