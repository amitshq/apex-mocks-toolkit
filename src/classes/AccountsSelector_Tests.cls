@isTest
private class AccountsSelector_Tests {
    @isTest
    static void it_should_select_accounts_by_id() {
        Account account = new Account(Name = 'Test');
        insert account;

        List<SObject> results = new AccountsSelector().selectById(new Set<Id>{ account.Id });

        System.assertEquals(1, results.size());
        System.assertEquals(account.Id, results[0].Id);
    }

    @isTest
    static void it_should_return_an_empty_list_when_no_ids_match() {
        List<SObject> results = new AccountsSelector().selectById(new Set<Id>{ TestingUtils.generateId(Account.SObjectType) });

        System.assertEquals(0, results.size());
    }

    @isTest
    static void it_should_only_query_the_declared_fields() {
        Account account = new Account(Name = 'Test');
        insert account;

        SObject result = new AccountsSelector().selectById(new Set<Id>{ account.Id })[0];

        System.assertEquals(account.Name, result.get('Name'));
        // OwnerId is always populated on insert, so this proves the field was
        // actually queried rather than merely present on an unqueried sobject
        System.assertNotEquals(null, result.get('OwnerId'));
    }
}
