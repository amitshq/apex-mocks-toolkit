# Developer Usage Guide

How to actually use each class in this toolkit. [README.md](README.md) tells the story (the benchmark, the bug fixes, why each class exists); this doc is the reference — what to call, when, and why — for every class meant to be used in real code. Test classes (`*_Tests.cls`) aren't documented individually below since they're not part of the API surface, but every class here has one, and it's worth reading for more usage examples than fit in this doc.

## Table of contents

1. [CRUD layer — `ICrud` / `Crud` / `CrudMock` / `SecureCrud`](#1-crud-layer)
2. [Test data utilities — `TestingUtils` / `TypeUtils`](#2-test-data-utilities)
3. [Unit of Work — `IUnitOfWork` / `UnitOfWork`](#3-unit-of-work)
4. [Assignment strategies — `IAssigner` and friends](#4-assignment-strategies)
5. [Selector layer — `ISelector` / `Selector` / `AccountsSelector` / `SelectorMock`](#5-selector-layer)
6. [`GovernorLimitGuard`](#6-governorlimitguard)
7. [Benchmarking — `Stopwatch` / `CrudStubProvider`](#7-benchmarking)
8. [Trigger framework — `TriggerHandler` / `LeadTriggerHandler` / `LeadAssignmentConfig`](#8-trigger-framework)

---

## 1. CRUD layer

**Files:** [`ICrud.cls`](src/classes/ICrud.cls), [`Crud.cls`](src/classes/Crud.cls), [`CrudMock.cls`](src/classes/CrudMock.cls), [`SecureCrud.cls`](src/classes/SecureCrud.cls)

Depend on `ICrud`, never on `Crud` directly — that's what makes the mock swap possible.

```apex
public class AccountService {
    private final ICrud crud;

    public AccountService() {
        this(new Crud());
    }

    @testVisible
    private AccountService(ICrud crud) {
        this.crud = crud;
    }

    public void renameAndSave(Account account, String newName) {
        account.Name = newName;
        this.crud.doUpdate(account);
    }
}
```

### `Crud` — real DML

Every method has a single-record and a bulk overload. Bulk methods sort the list first to avoid "too many DML chunks" errors on heterogeneous `SObject` lists.

```apex
ICrud crud = new Crud();

crud.doInsert(new Account(Name = 'Acme'));
crud.doInsert(new List<Contact>{ contactOne, contactTwo });

crud.doUpdate(account);
crud.doUpsert(records, MyObject__c.External_Id__c); // records can span multiple types that share this field

crud.doDelete(account);      // recoverable, goes to the recycle bin
crud.doHardDelete(account);  // permanently purges — throws if it can't
```

### `CrudMock` — in-memory fake for tests

```apex
@isTest
static void it_should_update_the_account() {
    ICrud mockCrud = new CrudMock();
    AccountService service = new AccountService(mockCrud);
    Account account = new Account(Name = 'Old Name');

    service.renameAndSave(account, 'New Name');

    System.assertEquals(1, CrudMock.Updated.size());
    System.assertEquals('New Name', CrudMock.Updated.firstOrDefault.get('Name'));
}
```

No DML ever runs — inserted/upserted records get a fake-but-validly-shaped Id via `TestingUtils`, and every call is recorded into a static list. Statics reset automatically between test methods, so there's no manual cleanup.

The `RecordsWrapper` returned by `CrudMock.Inserted` / `.Updated` / `.Upserted` / `.Deleted` / `.Undeleted` supports:

```apex
CrudMock.Inserted.size()                              // count
CrudMock.Inserted.Accounts                             // filter by type (also .Contacts/.Leads/.Opportunities/.Tasks)
CrudMock.Inserted.hasId(someId)                        // by standard Id
CrudMock.Inserted.hasId(someExternalId, MyObj__c.Ext__c) // by any Id-typed field
CrudMock.Inserted.singleOrDefault                      // exactly 0 or 1, else throws CrudMock.InvalidOperationException
CrudMock.Inserted.firstOrDefault                       // null if empty, otherwise the first match
CrudMock.Inserted.Records                              // the raw List<SObject>
```

There's also a test-only singleton, `CrudMock.getMock()`, for sharing one mock instance implicitly across a test method (used by the benchmark suite) — it's `@testVisible`, so it's only callable from `@isTest` classes.

### `SecureCrud` — `Crud` with FLS/CRUD enforcement

Same `ICrud` interface, so it's a drop-in replacement anywhere `new Crud()` is used today.

```apex
SecureCrud crud = new SecureCrud();
crud.doInsert(someRecord); // fields the running user can't create are silently stripped, not inserted with garbage

SObjectAccessDecision decision = crud.getLastAccessDecision();
if (decision.getRemovedFields().isEmpty() == false) {
    System.debug('Stripped inaccessible fields: ' + decision.getRemovedFields());
}
```

Delete/hard-delete check object-level delete access up front and throw `SecureCrud.SecureCrudException` if the running user can't delete that type at all — there's no field to silently strip for a delete.

---

## 2. Test data utilities

**Files:** [`TestingUtils.cls`](src/classes/TestingUtils.cls), [`TypeUtils.cls`](src/classes/TypeUtils.cls)

### `TestingUtils` — fake Ids without touching the database

```apex
Account fakeAccount = new Account(Name = 'Test');
TestingUtils.generateId(fakeAccount);        // mutates in place; no-ops if it already has an Id
Id standaloneId = TestingUtils.generateId(Account.SObjectType); // just need an Id, no record

List<Contact> contacts = new List<Contact>{ new Contact(LastName = 'A'), new Contact(LastName = 'B') };
TestingUtils.generateIds(contacts);          // fills in whichever ones are missing an Id
```

Generated Ids are validly-shaped (correct key prefix + length) so they cast to `Id` and compare correctly, but aren't real records — this is exactly what `CrudMock` uses internally for `doInsert`/`doUpsert`.

### `TypeUtils` — dynamic Apex helpers

```apex
Account account = new Account(Name = 'Test');
List<SObject> typedList = TypeUtils.createSObjectList(account); // a real List<Account> under the hood, built via reflection

Object instance = TypeUtils.create('Account'); // Type.forName(...).newInstance()
```

Reach for this when you only know an `SObjectType` or instance at runtime and need a concretely-typed list or instance to satisfy a method signature.

---

## 3. Unit of Work

**Files:** [`IUnitOfWork.cls`](src/classes/IUnitOfWork.cls), [`UnitOfWork.cls`](src/classes/UnitOfWork.cls)

Batches registered changes into one insert, one update, and one delete per `commitWork()` call, instead of scattering DML calls through your code.

```apex
IUnitOfWork uow = new UnitOfWork();          // real DML via `new Crud()`
IUnitOfWork mockUow = new UnitOfWork(new CrudMock()); // for tests

Account newAccount = new Account(Name = 'Acme');
uow.registerNew(newAccount);

existingContact.Email = 'updated@acme.com';
uow.registerDirty(existingContact);

uow.registerDeleted(oldOpportunity);

uow.commitWork(); // one doInsert, one doUpdate, one doDelete call - registrations are cleared after
```

`registerDirty`/`registerDeleted` silently skip records with no `Id` — there's nothing to key the batch by. Registering a record as deleted also removes it from the dirty batch if it was there, so you can't accidentally update-then-delete the same row in one commit.

---

## 4. Assignment strategies

**Files:** [`IAssigner.cls`](src/classes/IAssigner.cls), [`RoundRobinAssigner.cls`](src/classes/RoundRobinAssigner.cls), [`RandomAssigner.cls`](src/classes/RandomAssigner.cls), [`LoadBalancedAssigner.cls`](src/classes/LoadBalancedAssigner.cls), [`AssignerException.cls`](src/classes/AssignerException.cls)

All three implementations share one call shape, so they're interchangeable:

```apex
List<Id> repIds = new List<Id>{ repA.Id, repB.Id, repC.Id };
IAssigner assigner = new RoundRobinAssigner(); // or RandomAssigner() / LoadBalancedAssigner()
assigner.assign(newLeads, repIds, Lead.OwnerId);
```

All three throw `AssignerException` if `assigneeIds` is null or empty.

### `RoundRobinAssigner` — cycles through assignees in order

```apex
new RoundRobinAssigner().assign(newLeads, repIds, Lead.OwnerId); // always starts at index 0
```

To resume where a previous batch left off (e.g. across separate transactions), use the 4-arg overload and persist the returned index yourself (Platform Cache, a Custom Setting, wherever fits your org):

```apex
RoundRobinAssigner assigner = new RoundRobinAssigner();
Integer nextIndex = assigner.assign(batchOne, repIds, Lead.OwnerId, 0);
// ... persist nextIndex somewhere ...
assigner.assign(batchTwo, repIds, Lead.OwnerId, nextIndex);
```

### `RandomAssigner` — uniformly random

```apex
new RandomAssigner().assign(newLeads, repIds, Lead.OwnerId);
```

No ordering guarantee, no state to persist — use it when an even long-run distribution matters more than per-batch predictability.

### `LoadBalancedAssigner` — assigns to whoever has the fewest records

```apex
Map<Id, Integer> openCaseCountsByOwnerId = new Map<Id, Integer>{ repA.Id => 12, repB.Id => 3 };
LoadBalancedAssigner assigner = new LoadBalancedAssigner(openCaseCountsByOwnerId); // seed real starting loads
assigner.assign(newCases, repIds, Case.OwnerId);

Map<Id, Integer> updatedLoad = assigner.getCurrentLoad(); // persist this if you'll assign more later
```

Use the no-arg constructor (`new LoadBalancedAssigner()`) if you don't have real starting counts and are fine with everyone starting at zero.

---

## 5. Selector layer

**Files:** [`ISelector.cls`](src/classes/ISelector.cls), [`Selector.cls`](src/classes/Selector.cls), [`AccountsSelector.cls`](src/classes/AccountsSelector.cls), [`SelectorMock.cls`](src/classes/SelectorMock.cls)

The read-side counterpart to `ICrud`/`Crud` — depend on `ISelector`, not a concrete selector, the same way you'd depend on `ICrud`.

```apex
ISelector selector = new AccountsSelector();
List<Account> accounts = (List<Account>) selector.selectById(accountIds);
```

### Writing your own selector

Extend `Selector` and declare the type and fields — the base class builds and runs the query:

```apex
public class ContactsSelector extends Selector {
    public override Schema.SObjectType getSObjectType() {
        return Contact.SObjectType;
    }

    public override List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{ Contact.Id, Contact.LastName, Contact.Email };
    }
}
```

### `SelectorMock` — in-memory fake for tests

```apex
@isTest
static void it_should_use_the_selected_accounts() {
    SelectorMock mockSelector = new SelectorMock();
    Account fakeAccount = new Account(Id = TestingUtils.generateId(Account.SObjectType), Name = 'Test');
    mockSelector.seed(new List<SObject>{ fakeAccount });

    MyService service = new MyService(mockSelector);
    service.doSomethingWith(fakeAccount.Id);

    System.assertEquals(1, mockSelector.selectByIdCallCount);
}
```

`seed()` before exercising the code under test; `selectById` returns whichever seeded records match the requested Ids, with no SOQL. `selectByIdCallCount` tracks invocations the same way `CrudMock`'s static lists track DML calls.

---

## 6. `GovernorLimitGuard`

**File:** [`GovernorLimitGuard.cls`](src/classes/GovernorLimitGuard.cls)

Check headroom against governor limits proactively instead of discovering it via a thrown `System.LimitException`:

```apex
GovernorLimitGuard guard = new GovernorLimitGuard();

for (List<SObject> chunk : chunkedRecords) {
    guard.throwIfDmlRowsNear(90); // throws GovernorLimitGuard.LimitGuardException at/above 90% used
    crud.doInsert(chunk);
}
```

Also available: `throwIfQueriesNear(threshold)`, `throwIfCpuTimeNear(threshold)`, and plain percent-used readers (`getDmlRowsPercentUsed()`, `getDmlStatementsPercentUsed()`, `getQueriesPercentUsed()`, `getQueryRowsPercentUsed()`, `getCpuTimePercentUsed()`, `getHeapSizePercentUsed()`) if you'd rather branch on the number yourself.

---

## 7. Benchmarking

**Files:** [`Stopwatch.cls`](src/classes/Stopwatch.cls), [`CrudStubProvider.cls`](src/classes/CrudStubProvider.cls)

### `Stopwatch` — measure CPU time instead of eyeballing debug logs

```apex
Stopwatch stopwatch = new Stopwatch().start();
doExpensiveWork();
stopwatch.stop();

System.debug('Took ' + stopwatch.getElapsedCpuTimeMillis() + ' ms of CPU time');
```

You can also read `getElapsedCpuTimeMillis()` while it's still running for a live reading. Calling it before `start()` throws `Stopwatch.StopwatchException`.

### `CrudStubProvider` — Salesforce's native `Test.createStub`, benchmark-ready

```apex
CrudStubProvider provider = new CrudStubProvider();
ICrud mockCrud = (ICrud) Test.createStub(Crud.class, provider);

mockCrud.doUpdate(someRecord);

System.assertEquals(1, provider.callCount);
```

It's `@isTest`-annotated, so it (and `Test.createStub` itself) can only be referenced from test context. See `ApexMocksTests.cls` for how it's used to benchmark against fflib and `CrudMock`.

---

## 8. Trigger framework

**Files:** [`TriggerHandler.cls`](src/classes/TriggerHandler.cls), [`LeadTriggerHandler.cls`](src/classes/LeadTriggerHandler.cls), [`LeadAssignmentConfig.cls`](src/classes/LeadAssignmentConfig.cls), [`LeadTrigger.trigger`](src/triggers/LeadTrigger.trigger)

### Writing a new trigger handler

Extend `TriggerHandler` and override only the lifecycle hooks you need (`beforeInsert`, `beforeUpdate`, `beforeDelete`, `afterInsert`, `afterUpdate`, `afterDelete`, `afterUndelete` — there's no `beforeUndelete` because the platform doesn't fire one):

```apex
public class OpportunityTriggerHandler extends TriggerHandler {
    protected override void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecordsById) {
        // ...
    }
}
```

Then a one-line trigger:

```apex
trigger OpportunityTrigger on Opportunity (after update) {
    new OpportunityTriggerHandler().run();
}
```

### `LeadTriggerHandler` — the worked example

Shows `IAssigner` and `UnitOfWork` composed in one real flow: new Leads get round-robin assigned (`beforeInsert`), then a follow-up `Task` is queued for the new owner and flushed through `UnitOfWork` (`afterInsert`).

```apex
// LeadAssignmentConfig.salesRepIds is empty by default - the handler no-ops until it's set.
// In a real org, seed it from wherever your rep roster lives (a query, Custom Metadata, etc.);
// here it's a plain static list so this toolkit stays pure Apex.
LeadAssignmentConfig.salesRepIds = new List<Id>{ repA.Id, repB.Id };

insert new Lead(LastName = 'Prospect', Company = 'Acme'); // LeadTrigger fires LeadTriggerHandler automatically
```

To swap the assignment strategy, nothing in `LeadTriggerHandler` needs to change — it depends on `IAssigner`, not `RoundRobinAssigner` specifically. If you want a different default, edit the zero-arg constructor in [`LeadTriggerHandler.cls`](src/classes/LeadTriggerHandler.cls:16).
