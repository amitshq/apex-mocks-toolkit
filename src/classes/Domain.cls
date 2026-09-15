/**
 * The home for record-level business rules that don't belong scattered
 * across trigger handlers - the classic fflib_SObjectDomain idea, kept to
 * one method. Subclasses wrap a List<SObject> of one type and implement
 * validateRecord(); validate() collects every error across every record
 * and throws once with a combined message, rather than failing fast on
 * the first bad record.
 */
public abstract class Domain implements IDomain {
  protected final List<SObject> records;

  protected Domain(List<SObject> records) {
    this.records = records;
  }

  public virtual void validate() {
    List<String> errors = new List<String>();
    for (SObject record : this.records) {
      errors.addAll(this.validateRecord(record));
    }
    if (errors.isEmpty() == false) {
      throw new DomainException(String.join(errors, '; '));
    }
  }

  protected abstract List<String> validateRecord(SObject record);

  public class DomainException extends Exception {
  }
}
