@isTest
private class TypeUtils_Tests {
  @isTest
  static void it_should_create_an_sobject_list_matching_the_records_type() {
    Account account = new Account(Name = 'Test');

    List<SObject> records = TypeUtils.createSObjectList(account);
    List<Account> accounts = (List<Account>) records;

    System.assertEquals(1, records.size());
    System.assertEquals(account, accounts[0]);
  }

  @isTest
  static void it_should_create_an_instance_of_the_named_type() {
    Object instance = TypeUtils.create('Account');

    System.assert(instance instanceof Account);
  }
}
