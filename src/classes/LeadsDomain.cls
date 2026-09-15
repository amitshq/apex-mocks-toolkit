public class LeadsDomain extends Domain {
  public LeadsDomain(List<SObject> records) {
    super(records);
  }

  protected override List<String> validateRecord(SObject record) {
    List<String> errors = new List<String>();
    Lead lead = (Lead) record;
    if (String.isBlank(lead.Company)) {
      errors.add('Lead ' + lead.LastName + ' is missing a Company');
    }
    return errors;
  }
}
