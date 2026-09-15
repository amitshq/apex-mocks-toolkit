@isTest
private class LoadBalancedAssigner_Tests {
  @isTest
  static void it_should_distribute_evenly_across_assignees_starting_from_zero_load() {
    Id assigneeA = TestingUtils.generateId(User.SObjectType);
    Id assigneeB = TestingUtils.generateId(User.SObjectType);
    List<Id> assigneeIds = new List<Id>{ assigneeA, assigneeB };
    List<Account> accounts = new List<Account>{
      new Account(Name = '1'),
      new Account(Name = '2'),
      new Account(Name = '3'),
      new Account(Name = '4')
    };
    LoadBalancedAssigner assigner = new LoadBalancedAssigner();

    assigner.assign(accounts, assigneeIds, Account.OwnerId);

    System.assertEquals(assigneeA, accounts[0].OwnerId);
    System.assertEquals(assigneeB, accounts[1].OwnerId);
    System.assertEquals(assigneeA, accounts[2].OwnerId);
    System.assertEquals(assigneeB, accounts[3].OwnerId);
    Map<Id, Integer> finalLoad = assigner.getCurrentLoad();
    System.assertEquals(2, finalLoad.get(assigneeA));
    System.assertEquals(2, finalLoad.get(assigneeB));
  }

  @isTest
  static void it_should_take_starting_load_into_account() {
    Id busyAssignee = TestingUtils.generateId(User.SObjectType);
    Id freeAssignee = TestingUtils.generateId(User.SObjectType);
    LoadBalancedAssigner assigner = new LoadBalancedAssigner(new Map<Id, Integer>{ busyAssignee => 5, freeAssignee => 0 });
    Account account = new Account(Name = 'Test');

    assigner.assign(new List<Account>{ account }, new List<Id>{ busyAssignee, freeAssignee }, Account.OwnerId);

    System.assertEquals(freeAssignee, account.OwnerId);
  }

  @isTest
  static void it_should_throw_when_there_are_no_assignees() {
    try {
      new LoadBalancedAssigner().assign(new List<Account>{ new Account(Name = 'Test') }, new List<Id>(), Account.OwnerId);
      System.assert(false, 'Expected an AssignerException to be thrown');
    } catch (AssignerException ex) {
      System.assert(true);
    }
  }

  @isTest
  static void it_should_not_fail_on_an_empty_record_list() {
    LoadBalancedAssigner assigner = new LoadBalancedAssigner();

    assigner.assign(new List<Account>(), new List<Id>{ TestingUtils.generateId(User.SObjectType) }, Account.OwnerId);

    System.assert(assigner.getCurrentLoad().isEmpty() == false);
  }
}
