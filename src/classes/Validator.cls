/**
 * Runs a composable list of IValidationRules across a list of records,
 * collecting every failure before throwing once with a combined message -
 * unlike Domain (one hardcoded class per SObject type), rules here are
 * small, standalone, and mix-and-matched at the call site across any type.
 */
public class Validator {
  private final List<IValidationRule> rules;

  public Validator(List<IValidationRule> rules) {
    this.rules = rules;
  }

  public void validate(List<SObject> records) {
    List<String> errors = new List<String>();
    for (SObject record : records) {
      for (IValidationRule rule : this.rules) {
        errors.addAll(rule.validate(record));
      }
    }
    if (errors.isEmpty() == false) {
      throw new ValidatorException(String.join(errors, '; '));
    }
  }

  public class ValidatorException extends Exception {
  }
}
