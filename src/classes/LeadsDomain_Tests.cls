@isTest
private class LeadsDomain_Tests {
  @isTest
  static void it_should_not_throw_when_all_records_are_valid() {
    LeadsDomain leads = new LeadsDomain(new List<SObject>{ new Lead(LastName = 'Test', Company = 'Acme') });

    try {
      leads.validate();
    } catch (Domain.DomainException ex) {
      System.assert(false, 'Did not expect a validation failure: ' + ex);
    }
  }

  @isTest
  static void it_should_throw_with_a_combined_message_when_records_are_invalid() {
    LeadsDomain leads = new LeadsDomain(new List<SObject>{ new Lead(LastName = 'Test1'), new Lead(LastName = 'Test2') });

    try {
      leads.validate();
      System.assert(false, 'Expected a Domain.DomainException to be thrown');
    } catch (Domain.DomainException ex) {
      System.assert(ex.getMessage().contains('Test1'));
      System.assert(ex.getMessage().contains('Test2'));
    }
  }

  @isTest
  static void it_should_not_throw_for_an_empty_list() {
    LeadsDomain leads = new LeadsDomain(new List<SObject>());

    try {
      leads.validate();
    } catch (Domain.DomainException ex) {
      System.assert(false, 'Did not expect a validation failure: ' + ex);
    }
  }
}
