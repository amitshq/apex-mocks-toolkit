@isTest
private class WeightedRoundRobinAssigner_Tests {
  @isTest
  static void it_should_assign_more_records_to_a_higher_weighted_assignee() {
    Id heavyRep = TestingUtils.generateId(User.SObjectType);
    Id lightRep = TestingUtils.generateId(User.SObjectType);
    WeightedRoundRobinAssigner assigner = new WeightedRoundRobinAssigner(new Map<Id, Integer>{ heavyRep => 2, lightRep => 1 });
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 6; i++) {
      accounts.add(new Account(Name = '' + i));
    }

    assigner.assign(accounts, new List<Id>{ heavyRep, lightRep }, Account.OwnerId);

    Integer heavyCount = 0;
    for (Account account : accounts) {
      if (account.OwnerId == heavyRep) {
        heavyCount++;
      }
    }
    System.assertEquals(4, heavyCount);
  }

  @isTest
  static void it_should_default_to_a_weight_of_one_for_unlisted_assignees() {
    Id repA = TestingUtils.generateId(User.SObjectType);
    Id repB = TestingUtils.generateId(User.SObjectType);
    WeightedRoundRobinAssigner assigner = new WeightedRoundRobinAssigner(new Map<Id, Integer>());
    List<Account> accounts = new List<Account>{ new Account(Name = '1'), new Account(Name = '2') };

    assigner.assign(accounts, new List<Id>{ repA, repB }, Account.OwnerId);

    System.assertEquals(repA, accounts[0].OwnerId);
    System.assertEquals(repB, accounts[1].OwnerId);
  }

  @isTest
  static void it_should_throw_when_no_assignees_have_a_positive_weight() {
    Id repWithZeroWeight = TestingUtils.generateId(User.SObjectType);
    WeightedRoundRobinAssigner assigner = new WeightedRoundRobinAssigner(new Map<Id, Integer>{ repWithZeroWeight => 0 });

    try {
      assigner.assign(new List<Account>{ new Account(Name = 'Test') }, new List<Id>{ repWithZeroWeight }, Account.OwnerId);
      System.assert(false, 'Expected an AssignerException to be thrown');
    } catch (AssignerException ex) {
      System.assert(true);
    }
  }
}
