public class RequiredFieldRule implements IValidationRule {
  private final Schema.SObjectField requiredField;

  public RequiredFieldRule(Schema.SObjectField requiredField) {
    this.requiredField = requiredField;
  }

  public List<String> validate(SObject record) {
    List<String> errors = new List<String>();
    if (record.get(this.requiredField) == null) {
      errors.add(record.getSObjectType() + ' is missing required field ' + this.requiredField);
    }
    return errors;
  }
}
