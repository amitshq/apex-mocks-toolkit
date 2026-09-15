@isTest
private class TestingUtils_Tests {
  @isTest
  static void it_should_generate_a_fake_id_with_the_correct_key_prefix() {
    Id fakeId = TestingUtils.generateId(Account.SObjectType);

    System.assertEquals(Account.SObjectType.getDescribe().getKeyPrefix(), String.valueOf(fakeId).left(3));
  }

  @isTest
  static void it_should_generate_unique_ids_on_successive_calls() {
    Id firstId = TestingUtils.generateId(Account.SObjectType);
    Id secondId = TestingUtils.generateId(Account.SObjectType);

    System.assertNotEquals(firstId, secondId);
  }

  @isTest
  static void it_should_set_an_id_on_a_record_missing_one() {
    Account account = new Account(Name = 'Test');

    TestingUtils.generateId(account);

    System.assertNotEquals(null, account.Id);
  }

  @isTest
  static void it_should_not_overwrite_an_existing_id_on_a_record() {
    Account account = new Account(Name = 'Test');
    TestingUtils.generateId(account);
    Id originalId = account.Id;

    TestingUtils.generateId(account);

    System.assertEquals(originalId, account.Id);
  }

  @isTest
  static void it_should_generate_ids_for_every_record_missing_one_in_a_list() {
    List<Account> accounts = new List<Account>{ new Account(Name = '1'), new Account(Name = '2') };

    TestingUtils.generateIds(accounts);

    for (Account account : accounts) {
      System.assertNotEquals(null, account.Id);
    }
  }

  @isTest
  static void it_should_not_regenerate_an_id_for_a_record_that_already_has_one() {
    Account account = new Account(Name = 'Test');
    TestingUtils.generateId(account);
    Id originalId = account.Id;

    TestingUtils.generateIds(new List<Account>{ account });

    System.assertEquals(originalId, account.Id);
  }
}
