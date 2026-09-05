@isTest
private class CrudMock_Tests {
    @isTest
    static void it_should_track_upserted_deleted_and_undeleted_records() {
        CrudMock mock = new CrudMock();
        Account account = new Account(Name = 'Test');

        mock.doUpsert(account);
        mock.doDelete(account);
        mock.doUndelete(account);

        System.assertEquals(1, CrudMock.Upserted.size());
        System.assertEquals(1, CrudMock.Deleted.size());
        System.assertEquals(1, CrudMock.Undeleted.size());
    }

    @isTest
    static void it_should_ignore_the_external_id_field_argument_on_upsert() {
        CrudMock mock = new CrudMock();
        Account account = new Account(Name = 'Test');

        mock.doUpsert(new List<SObject>{ account }, Account.Id);

        System.assertEquals(1, CrudMock.Upserted.size());
        System.assertNotEquals(null, account.Id);
    }

    @isTest
    static void it_should_filter_records_by_sobject_type() {
        CrudMock mock = new CrudMock();
        mock.doInsert(new List<SObject>{
            new Account(Name = 'Test'),
            new Contact(LastName = 'Test'),
            new Lead(LastName = 'Test', Company = 'Test')
        });

        System.assertEquals(1, CrudMock.Inserted.Accounts.size());
        System.assertEquals(1, CrudMock.Inserted.Contacts.size());
        System.assertEquals(1, CrudMock.Inserted.Leads.size());
        System.assertEquals(0, CrudMock.Inserted.Opportunities.size());
        System.assertEquals(0, CrudMock.Inserted.Tasks.size());
    }

    @isTest
    static void it_should_find_records_by_id() {
        CrudMock mock = new CrudMock();
        Account account = new Account(Name = 'Test');
        mock.doInsert(account);

        System.assert(CrudMock.Inserted.hasId(account.Id));
        System.assert(CrudMock.Inserted.hasId(account.Id, Account.Id));
        System.assert(!CrudMock.Inserted.hasId(TestingUtils.generateId(Account.SObjectType)));
    }

    @isTest
    static void it_should_return_null_from_single_or_default_when_empty() {
        System.assertEquals(null, CrudMock.Inserted.singleOrDefault);
    }

    @isTest
    static void it_should_return_the_only_record_from_single_or_default() {
        CrudMock mock = new CrudMock();
        Account account = new Account(Name = 'Test');
        mock.doInsert(account);

        System.assertEquals(account.Id, CrudMock.Inserted.singleOrDefault.Id);
    }

    @isTest
    static void it_should_throw_when_single_or_default_matches_more_than_one_record() {
        CrudMock mock = new CrudMock();
        mock.doInsert(new List<SObject>{ new Account(Name = '1'), new Account(Name = '2') });

        try {
            SObject result = CrudMock.Inserted.singleOrDefault;
            System.assert(false, 'Expected a CrudMock.InvalidOperationException to be thrown');
        } catch(CrudMock.InvalidOperationException ex) {
            System.assert(ex.getMessage().contains('2'));
        }
    }

    @isTest
    static void it_should_return_null_from_first_or_default_when_empty() {
        System.assertEquals(null, CrudMock.Inserted.firstOrDefault);
    }

    @isTest
    static void it_should_return_the_first_record_from_first_or_default() {
        CrudMock mock = new CrudMock();
        mock.doInsert(new List<SObject>{ new Account(Name = '1'), new Account(Name = '2') });

        System.assertEquals('1', CrudMock.Inserted.firstOrDefault.get('Name'));
    }

    @isTest
    static void it_should_not_fail_when_deleting_a_null_or_empty_list() {
        CrudMock mock = new CrudMock();

        mock.doDelete((List<SObject>) null);
        mock.doDelete(new List<SObject>());

        System.assertEquals(0, CrudMock.Deleted.size());
    }

    @isTest
    static void it_should_track_hard_deleted_records_as_deleted() {
        CrudMock mock = new CrudMock();
        Account account = new Account(Name = 'Test');
        mock.doInsert(account);

        mock.doHardDelete(account);

        System.assertEquals(1, CrudMock.Deleted.size());
    }
}
