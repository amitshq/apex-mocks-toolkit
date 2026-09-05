@isTest
private class SelectorMock_Tests {
    @isTest
    static void it_should_return_seeded_records_matching_the_requested_ids() {
        SelectorMock mock = new SelectorMock();
        Account account = new Account(Id = TestingUtils.generateId(Account.SObjectType), Name = 'Test');
        mock.seed(new List<SObject>{ account });

        List<SObject> results = mock.selectById(new Set<Id>{ account.Id });

        System.assertEquals(1, results.size());
        System.assertEquals(account.Id, results[0].Id);
    }

    @isTest
    static void it_should_not_return_unseeded_records() {
        SelectorMock mock = new SelectorMock();

        List<SObject> results = mock.selectById(new Set<Id>{ TestingUtils.generateId(Account.SObjectType) });

        System.assertEquals(0, results.size());
    }

    @isTest
    static void it_should_track_how_many_times_selectbyid_was_called() {
        SelectorMock mock = new SelectorMock();

        mock.selectById(new Set<Id>());
        mock.selectById(new Set<Id>());

        System.assertEquals(2, mock.selectByIdCallCount);
    }
}
