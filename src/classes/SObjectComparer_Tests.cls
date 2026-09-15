@isTest
private class SObjectComparer_Tests {
  @isTest
  static void it_should_report_no_changed_fields_when_values_are_identical() {
    Account oldAccount = new Account(Name = 'Acme', Industry = 'Technology');
    Account newAccount = new Account(Name = 'Acme', Industry = 'Technology');

    Set<String> changed = SObjectComparer.getChangedFields(
      oldAccount,
      newAccount,
      new List<Schema.SObjectField>{ Account.Name, Account.Industry }
    );

    System.assertEquals(0, changed.size());
  }

  @isTest
  static void it_should_report_only_the_fields_that_actually_changed() {
    Account oldAccount = new Account(Name = 'Acme', Industry = 'Technology');
    Account newAccount = new Account(Name = 'Acme Corp', Industry = 'Technology');

    Set<String> changed = SObjectComparer.getChangedFields(
      oldAccount,
      newAccount,
      new List<Schema.SObjectField>{ Account.Name, Account.Industry }
    );

    System.assertEquals(1, changed.size());
    System.assert(changed.contains('Name'));
  }

  @isTest
  static void hasChanged_should_return_true_only_when_the_field_differs() {
    Account oldAccount = new Account(Name = 'Acme');
    Account newAccount = new Account(Name = 'Acme Corp');

    System.assert(SObjectComparer.hasChanged(oldAccount, newAccount, Account.Name));
    System.assert(SObjectComparer.hasChanged(oldAccount, newAccount, Account.Industry) == false);
  }
}
