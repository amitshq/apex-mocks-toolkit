@isTest
private class Validator_Tests {
  @isTest
  static void it_should_not_throw_when_all_rules_pass() {
    Validator validator = new Validator(new List<IValidationRule>{ new RequiredFieldRule(Lead.Company) });

    try {
      validator.validate(new List<SObject>{ new Lead(LastName = 'Test', Company = 'Acme') });
    } catch (Validator.ValidatorException ex) {
      System.assert(false, 'Did not expect a validation failure: ' + ex);
    }
  }

  @isTest
  static void it_should_throw_a_combined_message_when_a_rule_fails_for_multiple_records() {
    Validator validator = new Validator(new List<IValidationRule>{ new RequiredFieldRule(Lead.Company) });

    try {
      validator.validate(new List<SObject>{ new Lead(LastName = 'One'), new Lead(LastName = 'Two') });
      System.assert(false, 'Expected a Validator.ValidatorException to be thrown');
    } catch (Validator.ValidatorException ex) {
      System.assert(ex.getMessage().contains('Lead'));
    }
  }

  @isTest
  static void it_should_run_multiple_rules_against_the_same_record() {
    Validator validator = new Validator(
      new List<IValidationRule>{ new RequiredFieldRule(Lead.Company), new RequiredFieldRule(Lead.LastName) }
    );

    try {
      validator.validate(new List<SObject>{ new Lead() });
      System.assert(false, 'Expected a Validator.ValidatorException to be thrown');
    } catch (Validator.ValidatorException ex) {
      System.assert(ex.getMessage().contains('Company'));
      System.assert(ex.getMessage().contains('LastName'));
    }
  }

  @isTest
  static void it_should_not_throw_for_an_empty_record_list() {
    Validator validator = new Validator(new List<IValidationRule>{ new RequiredFieldRule(Lead.Company) });

    try {
      validator.validate(new List<SObject>());
    } catch (Validator.ValidatorException ex) {
      System.assert(false, 'Did not expect a validation failure: ' + ex);
    }
  }
}
