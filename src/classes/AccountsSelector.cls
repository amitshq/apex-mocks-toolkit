public class AccountsSelector extends Selector {
  public override Schema.SObjectType getSObjectType() {
    return Account.SObjectType;
  }

  public override List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{ Account.Id, Account.Name, Account.OwnerId };
  }
}
