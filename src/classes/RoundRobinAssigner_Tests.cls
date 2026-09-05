@isTest
private class RoundRobinAssigner_Tests {
    @isTest
    static void it_should_assign_records_in_round_robin_order() {
        List<Id> assigneeIds = new List<Id>{
            TestingUtils.generateId(User.SObjectType),
            TestingUtils.generateId(User.SObjectType),
            TestingUtils.generateId(User.SObjectType)
        };
        List<Account> accounts = new List<Account>();
        for(Integer i = 0; i < 7; i++) {
            accounts.add(new Account(Name = '' + i));
        }

        new RoundRobinAssigner().assign(accounts, assigneeIds, Account.OwnerId);

        for(Integer i = 0; i < accounts.size(); i++) {
            System.assertEquals(assigneeIds[Math.mod(i, assigneeIds.size())], accounts[i].OwnerId);
        }
    }

    @isTest
    static void it_should_continue_from_the_returned_index_on_the_next_call() {
        List<Id> assigneeIds = new List<Id>{ TestingUtils.generateId(User.SObjectType), TestingUtils.generateId(User.SObjectType) };
        RoundRobinAssigner assigner = new RoundRobinAssigner();
        List<Account> firstBatch = new List<Account>{ new Account(Name = '1'), new Account(Name = '2'), new Account(Name = '3') };
        List<Account> secondBatch = new List<Account>{ new Account(Name = '4') };

        Integer nextIndex = assigner.assign(firstBatch, assigneeIds, Account.OwnerId, 0);
        assigner.assign(secondBatch, assigneeIds, Account.OwnerId, nextIndex);

        // batch one: index 0,1,0 -> next index is 1
        System.assertEquals(1, nextIndex);
        System.assertEquals(assigneeIds[1], secondBatch[0].OwnerId);
    }

    @isTest
    static void it_should_default_to_starting_at_zero() {
        List<Id> assigneeIds = new List<Id>{ TestingUtils.generateId(User.SObjectType) };
        List<Account> accounts = new List<Account>{ new Account(Name = 'Test') };

        new RoundRobinAssigner().assign(accounts, assigneeIds, Account.OwnerId);

        System.assertEquals(assigneeIds[0], accounts[0].OwnerId);
    }

    @isTest
    static void it_should_throw_when_there_are_no_assignees() {
        try {
            new RoundRobinAssigner().assign(new List<Account>{ new Account(Name = 'Test') }, new List<Id>(), Account.OwnerId);
            System.assert(false, 'Expected an AssignerException to be thrown');
        } catch(AssignerException ex) {
            System.assert(true);
        }
    }

    @isTest
    static void it_should_not_fail_on_an_empty_record_list() {
        Integer nextIndex = new RoundRobinAssigner()
            .assign(new List<Account>(), new List<Id>{ TestingUtils.generateId(User.SObjectType) }, Account.OwnerId, 0);

        System.assertEquals(0, nextIndex);
    }
}
