@isTest
private class RequiredFieldRule_Tests {
  @isTest
  static void it_should_return_no_errors_when_the_field_is_populated() {
    RequiredFieldRule rule = new RequiredFieldRule(Account.Name);

    List<String> errors = rule.validate(new Account(Name = 'Acme'));

    System.assertEquals(0, errors.size());
  }

  @isTest
  static void it_should_return_an_error_when_the_field_is_null() {
    RequiredFieldRule rule = new RequiredFieldRule(Account.Name);

    List<String> errors = rule.validate(new Account());

    System.assertEquals(1, errors.size());
  }
}
