/**
 * The simplest possible configuration seam for LeadTriggerHandler: a list
 * of sales rep Ids to round-robin new Leads across. In a real org this
 * would likely be sourced from a Custom Metadata Type or Custom Setting;
 * that's deliberately out of scope here so this toolkit stays pure Apex.
 * Tests set this list directly before inserting Leads (statics reset
 * between test methods, same as CrudMock's static lists).
 */
public class LeadAssignmentConfig {
  @testVisible
  public static List<Id> salesRepIds = new List<Id>();
}
