@isTest
private class CachedRoundRobinAssigner_Tests {
  @isTest
  static void it_should_resume_from_the_cached_index_on_a_later_call() {
    CacheMock cache = new CacheMock();
    Id repA = TestingUtils.generateId(User.SObjectType);
    Id repB = TestingUtils.generateId(User.SObjectType);
    List<Id> repIds = new List<Id>{ repA, repB };
    CachedRoundRobinAssigner assigner = new CachedRoundRobinAssigner(cache, 'lead-assignment');

    assigner.assign(
      new List<SObject>{ new Account(Name = '1'), new Account(Name = '2'), new Account(Name = '3') },
      repIds,
      Account.OwnerId
    );
    List<SObject> secondBatch = new List<SObject>{ new Account(Name = '4') };
    assigner.assign(secondBatch, repIds, Account.OwnerId);

    // batch one: indexes 0,1,0 -> cached next index is 1 -> batch two starts at 1 = repB
    System.assertEquals(repB, ((Account) secondBatch[0]).OwnerId);
  }

  @isTest
  static void it_should_start_at_zero_when_nothing_is_cached_yet() {
    CacheMock cache = new CacheMock();
    Id onlyRep = TestingUtils.generateId(User.SObjectType);
    CachedRoundRobinAssigner assigner = new CachedRoundRobinAssigner(cache, 'lead-assignment');
    List<SObject> accounts = new List<SObject>{ new Account(Name = '1') };

    assigner.assign(accounts, new List<Id>{ onlyRep }, Account.OwnerId);

    System.assertEquals(onlyRep, ((Account) accounts[0]).OwnerId);
  }

  @isTest
  static void it_should_persist_the_index_under_the_given_cache_key() {
    CacheMock cache = new CacheMock();
    Id onlyRep = TestingUtils.generateId(User.SObjectType);
    CachedRoundRobinAssigner assigner = new CachedRoundRobinAssigner(cache, 'my-key');

    assigner.assign(new List<SObject>{ new Account(Name = '1') }, new List<Id>{ onlyRep }, Account.OwnerId);

    System.assertEquals(1, cache.get('my-key'));
  }
}
