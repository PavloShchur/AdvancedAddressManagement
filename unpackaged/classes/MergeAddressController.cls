global without sharing class MergeAddressController {

    public static final String MASTER_RECORD_LABEL = 'Master Record';

    @RemoteAction
    global static List<MergeAddressController.AccountSearchResult> findAccounts( String accountName ) {
        List<MergeAddressController.AccountSearchResult> result = new List<MergeAddressController.AccountSearchResult>();
        for( Account account : AccountServices.findAccounts( accountName ) ) {
            result.add( new MergeAddressController.AccountSearchResult( account ) );
        }
        return result;
    }

    public MergeAddressController() {
        step = 1;
        /*String accountId = ApexPages.currentPage().getParameters().get( 'accountid' );
        if( !String.isEmpty( accountId ) && accountId instanceOf Id && accountId.startsWith( '001' ) ) {
            this.accountId = accountId;
            goToStep2();
            return;
        }*/
    }

    public Integer step { get; set; }
    public Id accountId { get; set; }
    public String chosenAddresses { get; set; }
    public List<Id> addressIds {
        get {
            List<Id> result = new List<Id>();
            if( chosenAddresses == null ) return result;
            return chosenAddresses.split( ',' );
        }
    }

    //step 1
    public Account account {
        get {
            if( ( account == null || account.Id == null ) && accountId != null ) {
                List<Account> accounts = [ SELECT Name
                                           FROM Account
                                           WHERE Id = :accountId ];
                if( !accounts.isEmpty() ) {
                    account = accounts[0];
                }
            }
            return account;
        }
        private set;
    }

    public void goToStep2() {
        if( accountId == null ) {
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.Error, 'No Account selected' ) );
            return;
        }
        step = 2;
    }

    //step 2
    public String filterTextRelatedAddresses { get; set; }
    public void filterRelatedAddresses() {
    }

    public Set<Id> accountsInHierarchy {
        get {
            if( accountsInHierarchy == null ) {
                accountsInHierarchy = new Set<Id>();
            }
            if( accountsInHierarchy.isEmpty() ) {
                Id ultimateParentAccountId = AccountHierarchyServices.getUltimateParentAccountIds( new Set<Id>{ account.Id } ).get( account.Id );
                if( ultimateParentAccountId == null ) return accountsInHierarchy;
                HierarchyNode hierarchyNode = AccountHierarchyServices.getAccountHierarchies( new Set<Id>{ ultimateParentAccountId } ).get( ultimateParentAccountId );
                accountsInHierarchy = hierarchyNode.getAllHierarchyIds();
            }
            return accountsInHierarchy;
        }
        private set;
    }

    public transient List<Address__c> filteredRelatedAddresses;
    public List<Address__c> getFilteredRelatedAddresses() {
	        String query = 'SELECT ' + String.join(
	                                       new List<String>(
	                                           Utils.getFieldsFromFieldSet(
	                                               SObjectType.Address__c.FieldSets.Merge_Address_Address_Fields.getFields(),
	                                               null//new List<Schema.SObjectField>{}
	                                           )
	                                       ), ', '
	                                   ) + ' ';
	        query += 'FROM Address__c ';
	        List<String> queryWhere = new List<String>();
	        queryWhere.add( 'Account__c IN :accountsInHierarchy' );
	        if( !queryWhere.isEmpty() ) {
	            query += 'WHERE ' + String.join( queryWhere, ' AND ' ) + ' ';
	        }
	        query += 'ORDER BY Account__r.Name';
	        return AddressServices.getFilteredAddresses( Database.query( query ),
	                                                     filterTextRelatedAddresses,
	                                                     SObjectType.Address__c.FieldSets.Merge_Address_Address_Fields.getFields() );
    }

    public void goToStep3() {
        if( addressIds == null || addressIds.isEmpty() || addressIds.size() < 1 ) {
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.Error, 'Not correct selection of Address records' ) );
            return;
        }
        accountsInHierarchy = null; //clear memory
        chosenRelatedAddresses = retrieveChosenRelatedAddresses( addressIds );
        step = 3;
    }

    //step 3
    public AddressesWrapper chosenRelatedAddresses { get; set; }

    public static AddressesWrapper retrieveChosenRelatedAddresses( List<Id> addressIds ) {
        String query = 'SELECT ' + String.join(
                                       new List<String>(
                                           Utils.getFieldsFromFieldSet(
                                               SObjectType.Address__c.FieldSets.Merge_Address_Address_Fields_To_Choose.getFields(),
                                               Utils.addFieldsToList(
                                                 Utils.addFieldsToList(
                                                   null,
                                                   AddressServices.FIELDS_FOR_ADDRESS_MERGE_DISPLAY
                                                 ),
                                                 new List<Schema.SObjectField>{ Address__c.Account__c }
                                               )
                                           )
                                       ), ', '
                                   ) + ' ';
        query += 'FROM Address__c ';
        List<String> queryWhere = new List<String>();
        queryWhere.add( 'Id IN :addressIds' );
        if( !queryWhere.isEmpty() ) {
            query += 'WHERE ' + String.join( queryWhere, ' AND ' ) + ' ';
        }
        query += 'ORDER BY Account__r.Name';
        return new AddressesWrapper( Database.query( query ) );
    }

    public PageReference mergeAddresses() {
        Address__c addressToUpdate = new Address__c();
        List<Address__c> addressesToDelete = new List<Address__c>();
        for( FieldWrapper fieldWrapper : chosenRelatedAddresses.fields ) {
            if( !fieldWrapper.editable ) continue;
            for( Selector selector : fieldWrapper.selectors ) {
                if( fieldWrapper.name == MASTER_RECORD_LABEL ) {
                    if( !selector.selected ) {
                        addressesToDelete.add( new Address__c( Id = selector.recordId ) );
                    } else {
                        addressToUpdate.Id = selector.recordId;
                    }
                    continue;
                }

                if( !selector.selected ) continue;

                if( fieldWrapper.name == Address__c.Verified__c.getDescribe().getName() ) {
                    Boolean isVerified = (Boolean)chosenRelatedAddresses.getRecordIdToRecord().get( selector.recordId ).get( fieldWrapper.name );
                    addressToUpdate.Verified__c = isVerified;
                    addressToUpdate.Verified_By__c = isVerified ? UserInfo.getUserId() : null;
                    addressToUpdate.Verified_Date__c = isVerified ? Date.today() : null;
                    continue;
                }
                addressToUpdate.put( fieldWrapper.name, chosenRelatedAddresses.getRecordIdToRecord().get( selector.recordId ).get( fieldWrapper.name ) );
            }
        }

		MergeServices.MappingsMergeResult mergeResult = MergeServices.mergeMappings( addressToUpdate, addressesToDelete );
		SavePoint sp = Database.setSavepoint();
        try {
            UPDATE addressToUpdate;
            DELETE mergeResult.mappingsToDelete;
            UPDATE mergeResult.mappingsToUpdate;
            DELETE addressesToDelete;
        } catch( Exception e ) {
        	Database.rollback(sp);
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.Error, e.getMessage() ) );
            return null;
        }

        PageReference pr = new PageReference( '/' + addressToUpdate.Id );
        pr.setRedirect( true );
        return pr;
    }

    //common
    public PageReference cancel() {
        PageReference pr = new PageReference( '/' );
        pr.setRedirect( true );
        return pr;
    }

    public transient Aam_Settings__c settings;
    public Aam_Settings__c getSettings() {
        return Utils.aamSettings;
    }

    //auxiliary classes
    public class AddressesWrapper {
        public List<Address__c> records { get; set; }
        public List<FieldWrapper> fields { get; set; }

        public transient Map<Id, Address__c> recordIdToRecord;
        public Map<Id, Address__c> getRecordIdToRecord() {
            return new Map<Id, Address__c>( records );
        }

        public transient Map<Id, String> recordIdToAddress;
        public Map<Id, String> getRecordIdToAddress() {
            Map<Id, String> result = new Map<Id, String>();
            for( Address__c record : records ) {
                result.put( record.Id, Utils.joinFieldValues( record, AddressServices.FIELDS_FOR_ADDRESS_MERGE_DISPLAY ) );
            }
            return result;
        }

        public transient Map<Id, String> recordIdToAddressConcat;
        public Map<Id, String> getRecordIdToAddressConcat() {
            Map<Id, String> result = new Map<Id, String>();
            Map<Id, String> recordIdToAddress = getRecordIdToAddress();
            for( Id recordId : recordIdToAddress.keySet() ) {
                String address = recordIdToAddress.get( recordId );
                if( address.length() >= 100 ) {
                    address = address.left( 100 ) + '…';
                }
                result.put( recordId, address );
            }
            return result;
        }

        public AddressesWrapper( List<Address__c> records ) {
            Map<String, Schema.SObjectField> fieldsMap = Address__c.SObjectType.getDescribe().fields.getMap();
            this.records = records;
            this.fields = new List<FieldWrapper>();
            this.fields.add( new FieldWrapper( records, null, MASTER_RECORD_LABEL, true ) );
            for( Schema.FieldSetMember field : SObjectType.Address__c.FieldSets.Merge_Address_Address_Fields_To_Choose.getFields() ) {
                Boolean fieldIsWritable = false;
                for( Schema.SObjectField fieldSo : fieldsMap.values() ) {
                    if( field.getFieldPath() == fieldSo.getDescribe().getName() ) {
                        fieldIsWritable = fieldSo.getDescribe().isUpdateable();
                    }
                }
                this.fields.add( new FieldWrapper( records, field, null, fieldIsWritable ) );
            }
        }
    }

    public class FieldWrapper {
        private Schema.FieldSetMember field;
        private String customName;
        private Boolean fieldIsWritable;
        private Boolean fieldValuesAreDifferent;

        public List<Selector> selectors { get; set; }
        public Boolean editable { get { return customName == null ? fieldIsWritable && field.getRequired() : true; } }
        public String name { get { return customName == null ? field.getFieldPath() : customName; } }
        public String label { get { return customName == null ? field.getLabel() : customName; } }
        public Boolean isCustom { get { return customName != null; } }
        public Boolean isDifferent { get { return editable ? fieldValuesAreDifferent : false; } }

        public FieldWrapper( List<Address__c> records, Schema.FieldSetMember field, String customName, Boolean fieldIsWritable ) {
            this.field = field;
            this.customName = customName;
            this.fieldIsWritable = fieldIsWritable;

            this.selectors = new List<Selector>();
            this.fieldValuesAreDifferent = false;
            Boolean selected = true;
            Object fieldValue;
            for( Address__c record : records ) {
                this.selectors.add( new Selector( record, selected ) );
                selected = false;

                if( !this.isCustom && !this.fieldValuesAreDifferent ) {
                    if( fieldValue == null ) {
                        fieldValue = record.get( this.name );
                    } else if( fieldValue != record.get( this.name ) ) {
                        this.fieldValuesAreDifferent = true;
                    }
                }
            }
        }
    }

    public class Selector {
        public Boolean selected { get; set; }
        public Id recordId { get; set; }

        public Selector( Address__c record, Boolean selected ) {
            this.recordId = record.Id;
            this.selected = selected;
        }
    }

    global class AccountSearchResult {
        public String id { get; set; }
        public String name { get; set; }

        public AccountSearchResult( Account account ) {
            this.id = account.Id;
            this.name = account.Name;
        }
    }

}