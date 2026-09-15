@isTest
private class RandomAssigner_Tests {
  @isTest
  static void it_should_assign_every_record_to_one_of_the_provided_assignees() {
    Set<Id> assigneeIds = new Set<Id>{
      TestingUtils.generateId(User.SObjectType),
      TestingUtils.generateId(User.SObjectType),
      TestingUtils.generateId(User.SObjectType)
    };
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 20; i++) {
      accounts.add(new Account(Name = '' + i));
    }

    new RandomAssigner().assign(accounts, new List<Id>(assigneeIds), Account.OwnerId);

    for (Account account : accounts) {
      System.assertNotEquals(null, account.OwnerId);
      System.assert(assigneeIds.contains(account.OwnerId));
    }
  }

  @isTest
  static void it_should_assign_everything_to_the_only_assignee_when_there_is_just_one() {
    Id onlyAssigneeId = TestingUtils.generateId(User.SObjectType);
    List<Account> accounts = new List<Account>{ new Account(Name = '1'), new Account(Name = '2') };

    new RandomAssigner().assign(accounts, new List<Id>{ onlyAssigneeId }, Account.OwnerId);

    for (Account account : accounts) {
      System.assertEquals(onlyAssigneeId, account.OwnerId);
    }
  }

  @isTest
  static void it_should_throw_when_there_are_no_assignees() {
    try {
      new RandomAssigner().assign(new List<Account>{ new Account(Name = 'Test') }, new List<Id>(), Account.OwnerId);
      System.assert(false, 'Expected an AssignerException to be thrown');
    } catch (AssignerException ex) {
      System.assert(true);
    }
  }
}
