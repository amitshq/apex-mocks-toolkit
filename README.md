# Apex Mocks Toolkit — FFLib vs CrudMock vs Native Stubs

Maintained by **Amit Kumar** ([amitgrazitti@gmail.com](mailto:amitgrazitti@gmail.com)).

This repository is a fork/continuation of James Simone's [apex-mocks-stress-test](https://github.com/jamessimone/apex-mocks-stress-test), which originally benchmarked `fflib-apex-mocks` against a hand-rolled `Crud`/`CrudMock` pair. The original benchmark and its write-up (kept below, in his own words, under "Introduction" / "My methodology" / "Result") are his — see [LICENSE](LICENSE) for the MIT terms both his original work and these additions are released under. Everything past that point — the bug fixes, the new test coverage, and the new classes described below — is maintained here going forward.

**Looking for how to actually use a class?** See [USAGE.md](USAGE.md) for a per-class developer guide with code examples. This README covers the story and the changelog; USAGE.md is the reference.

## What's new in this repository

### Bug fixes

- **`it_should_do_crud_hard_delete` asserted the wrong thing.** [`Crud.doHardDelete`](src/classes/Crud.cls) soft-deletes a record and then permanently purges it via `Database.emptyRecycleBin`. The old test queried `ALL ROWS` afterward and asserted the (nonexistent) row's `IsDeleted` flag — a purged record isn't returned even by `ALL ROWS`, so this would throw `List index out of bounds: 0` on a real run. The test now asserts the record is gone.
- **`doUpsert(records, externalIdField)` skipped the anti-chunking sort.** Every other bulk method sorts the list first to avoid "too many DML chunks" errors on heterogeneous `SObject` lists; this overload — which specifically supports upserting mixed types that share a common external ID field — didn't. Fixed to sort like the rest.
- **`Database.emptyRecycleBin` results were discarded.** A failed hard-delete failed silently instead of raising, unlike every other DML call in `Crud`. It now throws a `DmlException` if any record fails to purge.
- **Cosmetic:** `doUndelete(SObject)` called `doUnDelete` (different casing) internally. Apex is case-insensitive so this ran fine, but it's now consistent.
- **Edge case:** `TestingUtils.generateId` would pass a negative length to `String.repeat()` if the internal counter ever exceeded 10^12 calls. It now throws a clear `TestingUtilsException` instead of an obscure runtime error (not reachable at the `LARGE_NUMBER` scales used in these tests, but now explicit rather than latent).
- **Missing exception context:** `CrudMock.RecordsWrapper.singleOrDefault` threw `InvalidOperationException` with no message. It now reports how many records were found.
- **`package.json` license mismatch:** declared `ISC` while [LICENSE](LICENSE) has always been MIT text. Corrected to `MIT`.

### New concepts added

- **[`CrudStubProvider`](src/classes/CrudStubProvider.cls) — a third mocking approach.** The original benchmark compared fflib against `CrudMock`; this adds Salesforce's own built-in `System.StubProvider`/`Test.createStub` API as a third contender, with a matching `nativestub_should_mock_dml_statements_update` benchmark test in [`ApexMocksTests.cls`](src/classes/ApexMocksTests.cls). It's a useful baseline: no external library, no custom recording pattern, just the platform's native stubbing.
- **[`IUnitOfWork`](src/classes/IUnitOfWork.cls) / [`UnitOfWork`](src/classes/UnitOfWork.cls) — batched DML.** A small Unit of Work implementation (`registerNew`/`registerDirty`/`registerDeleted`/`commitWork`) that sits on top of `ICrud`, so code can accumulate changes across a transaction and flush them as one insert/update/delete each, instead of scattering direct DML calls. It takes any `ICrud` in its constructor — `new Crud()` for real DML, `CrudMock.getMock()` in tests — so it composes with everything already in this repo. Covered by [`UnitOfWork_Tests.cls`](src/classes/UnitOfWork_Tests.cls).
- **Assignment strategies — [`IAssigner`](src/classes/IAssigner.cls) with three implementations.** A common pattern in Salesforce orgs is distributing incoming records (Leads, Cases, ...) across a pool of owners. Rather than one hardcoded round-robin, this is a small Strategy-pattern toolkit:
  - **[`RoundRobinAssigner`](src/classes/RoundRobinAssigner.cls)** — cycles through `assigneeIds` in order, wrapping around. Its 4-arg overload returns the index the next batch should resume from, so callers can persist that pointer (Platform Cache, a Custom Setting, wherever) across transactions instead of always restarting at 0.
  - **[`RandomAssigner`](src/classes/RandomAssigner.cls)** — assigns each record to a uniformly random assignee. No ordering guarantee, but simple and stateless.
  - **[`LoadBalancedAssigner`](src/classes/LoadBalancedAssigner.cls)** — assigns each record to whichever assignee currently holds the fewest records, tracking a running count as it goes. Seed it with real starting loads (e.g. open-case counts from a query) via its constructor, and read `getCurrentLoad()` afterward.

  All three share one call shape — `assigner.assign(records, assigneeIds, ownerField)` — so they're drop-in replacements for each other. Covered by [`RoundRobinAssigner_Tests.cls`](src/classes/RoundRobinAssigner_Tests.cls), [`RandomAssigner_Tests.cls`](src/classes/RandomAssigner_Tests.cls), and [`LoadBalancedAssigner_Tests.cls`](src/classes/LoadBalancedAssigner_Tests.cls).

  ```apex
  List<Id> repIds = new List<Id>{ repA.Id, repB.Id, repC.Id };
  new RoundRobinAssigner().assign(newLeads, repIds, Lead.OwnerId);
  new Crud().doInsert(newLeads);
  ```

### Test coverage added

`TestingUtils`, `TypeUtils`, and most of `CrudMock`'s `RecordsWrapper` API (`ofType`/`Accounts`/`Contacts`/`Leads`/`Opportunities`/`Tasks`, `hasId`, `singleOrDefault`, `firstOrDefault`) had no dedicated tests. Added `TestingUtils_Tests.cls`, `TypeUtils_Tests.cls`, and `CrudMock_Tests.cls`. The new `UnitOfWork` and assignment-strategy classes each ship with their own test class (`UnitOfWork_Tests`, `RoundRobinAssigner_Tests`, `RandomAssigner_Tests`, `LoadBalancedAssigner_Tests`) rather than being added untested.

### Metadata

All classes were pinned to API version 47.0 (Winter '20, ~6 years old). Bumped to 67.0 across every `-meta.xml` and `src/package.xml`.

### Still worth knowing

- `fflib-apex-mocks` is **not vendored** in this repo (see `.gitignore`) — per the methodology below, clone it separately before deploying, or `ApexMocksTests.cls` won't compile.
- `LARGE_NUMBER` in `ApexMocksTests.cls` defaults to `10000`. The dramatic results tables further down used 100,000–1,000,000; bump the constant yourself to reproduce those.
- `UnitOfWork` delegates to whatever `ICrud` it's given — pair it with `SecureCrud` (below) if you want FLS/CRUD enforcement on the writes it batches.

## Custom additions (round 2)

A second pass adding a handful of small, focused utilities — each closes a specific gap noted above rather than being generic filler.

### `SecureCrud` — closes the FLS/CRUD gap

[`SecureCrud`](src/classes/SecureCrud.cls) extends `Crud` and runs `Security.stripInaccessible` before every insert/update/upsert, and checks object-level delete access before delete/hard delete — a drop-in `ICrud` implementation, so anything already coded against the interface (including `UnitOfWork`) gets FLS enforcement for free by swapping `new Crud()` for `new SecureCrud()`. The most recent `SObjectAccessDecision` is exposed via `getLastAccessDecision()` for inspection. Covered by [`SecureCrud_Tests.cls`](src/classes/SecureCrud_Tests.cls), including a deterministic, org-independent test of the delete guard (Users can never be deleted via the API, so that's used to exercise the "not deletable" branch without needing a custom permission set).

### A worked example — `TriggerHandler` + `LeadTriggerHandler`

Until now, `Crud`, `UnitOfWork`, and the `IAssigner`s were independent utilities with nothing showing them composed. [`TriggerHandler`](src/classes/TriggerHandler.cls) is a minimal trigger dispatch base class (before/after insert/update/delete, after undelete); [`LeadTriggerHandler`](src/classes/LeadTriggerHandler.cls) extends it to round-robin assign every new Lead across [`LeadAssignmentConfig.salesRepIds`](src/classes/LeadAssignmentConfig.cls) in `beforeInsert`, then queues a follow-up `Task` for the new owner through `UnitOfWork` in `afterInsert` — `Crud` + `UnitOfWork` + `IAssigner` in one realistic flow. It's wired to a real [`LeadTrigger.trigger`](src/triggers/LeadTrigger.trigger), so `package.xml` now also declares the `ApexTrigger` metadata type. Both hooks are `@testVisible`, so [`LeadTriggerHandler_Tests.cls`](src/classes/LeadTriggerHandler_Tests.cls) covers the logic directly (fast, no real DML) as well as end-to-end (a real Lead insert, using the running test user as the only "rep" so the test stays portable across orgs).

### Selector layer — the missing "R" in CRUD

[`ISelector`](src/classes/ISelector.cls)/[`Selector`](src/classes/Selector.cls) mirror `ICrud`/`Crud` for reads: a subclass declares its `SObjectType` and fields, the base class builds and runs the query. [`AccountsSelector`](src/classes/AccountsSelector.cls) is the one worked example; [`SelectorMock`](src/classes/SelectorMock.cls) is the `CrudMock` counterpart — seed it with canned records, and `selectById` returns matches with no SOQL, tracking a call count the same way `CrudMock`'s lists do. Covered by [`AccountsSelector_Tests.cls`](src/classes/AccountsSelector_Tests.cls) and [`SelectorMock_Tests.cls`](src/classes/SelectorMock_Tests.cls). A natural next step (not done here) would be extending the fflib-vs-custom-mock benchmark to selectors the same way `ApexMocksTests` already does for DML.

### `GovernorLimitGuard` — a nod to the repo's origin story

This whole project exists because fflib mocking once ran a transaction into `System.LimitException`. [`GovernorLimitGuard`](src/classes/GovernorLimitGuard.cls) makes that checkable instead of something you discover via a thrown exception: `getDmlRowsPercentUsed()`/`getCpuTimePercentUsed()`/etc. read current usage as a percentage, and `throwIfDmlRowsNear(threshold)`-style guards let calling code bail out proactively. Covered by [`GovernorLimitGuard_Tests.cls`](src/classes/GovernorLimitGuard_Tests.cls).

### `Stopwatch` — formalizing the benchmark methodology

The original benchmark methodology was "run the tests, eyeball the debug log" (that's literally how the Run 1–10 tables below were produced). [`Stopwatch`](src/classes/Stopwatch.cls) wraps `Limits.getCpuTime()` so a test can report a number instead: `start()`/`stop()`, then `getElapsedCpuTimeMillis()`. `ApexMocksTests.cls` now has `it_should_report_cpu_time_for_crudmock_vs_fflib_side_by_side`, which measures both approaches with it directly. Covered by [`Stopwatch_Tests.cls`](src/classes/Stopwatch_Tests.cls).

## Custom additions (round 3)

A third pass — covering the two remaining "hard to test" surfaces (outbound callouts, Platform Events), a factory tying every mock together, and a couple of composable patterns for validation and business rules.

### `ICallout` / `Callout` / `CalloutMock` — the third native mocking story

DML has `ICrud`/`CrudMock`, queries have `ISelector`/`SelectorMock` — [`ICallout`](src/classes/ICallout.cls)/[`Callout`](src/classes/Callout.cls) complete the trio for outbound HTTP callouts. [`CalloutMock`](src/classes/CalloutMock.cls) configures canned `HttpResponse`s per endpoint (or a catch-all default) and records every sent request, with no `Test.setMock`/`HttpCalloutMock` ceremony needed in consuming code — a real callout never happens when the mock is used. `Callout` itself (the real implementation) is still tested the standard Apex way, with `Test.setMock`. Covered by [`Callout_Tests.cls`](src/classes/Callout_Tests.cls) and [`CalloutMock_Tests.cls`](src/classes/CalloutMock_Tests.cls).

### `Application` — one place every mock gets swapped

Until now, mocking anything meant manually injecting `CrudMock`/`SelectorMock`/etc. into each constructor by hand. [`Application`](src/classes/Application.cls) is a small factory/service-locator (the same idea fflib calls `Application`): `Application.Crud.newInstance()`, `Application.Selector.newInstance(Account.SObjectType)`, `Application.Callout.newInstance()`, `Application.UnitOfWork.newInstance()`, and `Application.EventPublisher.newInstance()` return the real implementation by default, or a test-configured mock (`Application.Crud.setMock(new CrudMock())`) when one's been set. `LeadTriggerHandler`'s default constructor now goes through `Application.UnitOfWork.newInstance()` instead of `new UnitOfWork()` directly, so this isn't just theoretical. Covered by [`Application_Tests.cls`](src/classes/Application_Tests.cls).

### `IDomain` / `Domain` — completing the Service/Domain/Selector trio

[`Domain`](src/classes/Domain.cls) is the classic `fflib_SObjectDomain` idea, kept to one method: subclasses wrap a `List<SObject>` of one type and implement `validateRecord()`; `validate()` collects every error across every record and throws once with a combined message, rather than failing on the first bad record. [`LeadsDomain`](src/classes/LeadsDomain.cls) is the worked example (a Lead needs a `Company`). It's intentionally **not** wired into `LeadTriggerHandler` this round — throwing a bare exception from a trigger produces an ugly unhandled error rather than a clean validation message (real usage would call `SObject.addError()` instead), and composing that properly felt like its own follow-up rather than something to bolt on here. Covered by [`LeadsDomain_Tests.cls`](src/classes/LeadsDomain_Tests.cls).

### `IValidationRule` / `Validator` — composable rules, a different axis than `Domain`

Where `Domain` is one hardcoded class per SObject type, [`IValidationRule`](src/classes/IValidationRule.cls)/[`Validator`](src/classes/Validator.cls) is a runtime rule list that mixes and matches across *any* type. [`RequiredFieldRule`](src/classes/RequiredFieldRule.cls) is the one rule provided — `new RequiredFieldRule(Lead.Company)` works identically against `Lead`, `Account`, or any other SObject, which is the whole point of pulling rules out into their own reusable classes instead of hardcoding them per domain. Covered by [`Validator_Tests.cls`](src/classes/Validator_Tests.cls) and [`RequiredFieldRule_Tests.cls`](src/classes/RequiredFieldRule_Tests.cls).

### `IEventPublisher` / `EventPublisher` / `EventPublisherMock` — mockable Platform Events

Testing Platform Event publishers in Apex is a known pain point (`Test.getEventBus().deliver()` gymnastics). [`EventPublisher`](src/classes/EventPublisher.cls) wraps `EventBus.publish()` behind [`IEventPublisher`](src/classes/IEventPublisher.cls), mirroring `ICrud`; [`EventPublisherMock`](src/classes/EventPublisherMock.cls) records published events in memory instead. This is also the first non-Apex-class metadata in the repo: a real Platform Event, [`Lead_Assigned__e`](src/objects/Lead_Assigned__e.object) (`Lead_Id__c`, `Assignee_Id__c`), so `EventPublisher_Tests.cls` can publish for real rather than only against a mock. `package.xml` now also declares the `CustomObject` metadata type. Covered by [`EventPublisher_Tests.cls`](src/classes/EventPublisher_Tests.cls) and [`EventPublisherMock_Tests.cls`](src/classes/EventPublisherMock_Tests.cls).

### `QueueableChainer` — giving `GovernorLimitGuard` a real caller

The *original* benchmark's stated motivation was "batch processes / queueable tasks which process large numbers of records," but nothing in the toolkit demonstrated chaining Queueables safely. [`QueueableChainer`](src/classes/QueueableChainer.cls) is a `Queueable` base class whose `execute()` runs the current link (`run()`), then only enqueues the next one (`getNext()`) if [`GovernorLimitGuard.throwIfQueueableJobsNear(90)`](src/classes/GovernorLimitGuard.cls) confirms there's headroom — otherwise it calls `onChainStopped()` instead of risking a `System.LimitException: Too many queueable jobs added`. `GovernorLimitGuard` picked up `getQueueableJobsPercentUsed()`/`throwIfQueueableJobsNear()` alongside its existing DML/query/CPU/heap checks to support this. Covered by [`QueueableChainer_Tests.cls`](src/classes/QueueableChainer_Tests.cls).

### Verified with a real Apex parser, not just reviewed by hand

`prettier-plugin-apex` (already a devDependency, previously unused — see CI below) turned out to be more than a formatter: it's built on a real Apex parser, and running it against every class in this repo caught a genuine, previously-undetected compile error — `GovernorLimitGuard.percentUsed` had a parameter named `limit`, which is a reserved word in Apex (part of the SOQL `LIMIT` clause grammar). That's now fixed, and every one of the 62 Apex files in this repo (61 classes + the trigger) has been confirmed to actually parse. The whole codebase was also run through `prettier --write` to match the `.prettierrc` this repo already declared but never used.

### CI — actually running the Prettier config that was just sitting there

`package.json` has listed `prettier-plugin-apex` as a devDependency since the very first commit, with a `.prettierrc` alongside it, but nothing ever ran it. [`.github/workflows/ci.yml`](.github/workflows/ci.yml) now runs `prettier --check` against every `.cls`/`.trigger` file on every push and PR to `master`. It installs Prettier with `--ignore-scripts` rather than a plain `npm install`, since this repo's `sfdx-cli` devDependency's postinstall script isn't needed for a formatting check and has been observed to fail in some environments.

---

## Original benchmark write-up (by James Simone)

> The section below is James Simone's original introduction, methodology, and results from the source repository. It's kept as-is, in the first person, for attribution and historical context.

## Introduction

FFLib was [publicized with some fanfare way back in 2014](https://code4cloud.wordpress.com/2014/05/09/simple-dependency-injection/):

> This approach even allows us to write DML free tests that never even touch the database, and consequently execute very quickly!

But is this claim ... true?

It was suggested on Reddit following the publication of my second blog post on [The Joys Of Apex](https://jamessimone.net/blog/) that I was "[doing it wrong](https://www.reddit.com/r/salesforce/comments/egrw71/the_joys_of_apex_mocking_dml_operations/)." I thought a lot about what [u/moose04](https://www.reddit.com/user/moose04/) was saying - perhaps it had been premature of me to dismiss what I saw as the same "creep spread" and Java boilerplate that I wasn't crazy about when I considered the merits of the built-in Salesforce stubbing methods. To be clear - it's still possible for that to be the case. That said, Salesforce is a platform that (I believe) thrives on the ability for developers to quickly test and iterate through theories. Why not use the very same platform we were discussing to stress test my implementation against the FFLib library?

## My methodology

1. Create a new salesforce instance ... I just [signed up](https://developer.salesforce.com/signup) for one and got my security token emailed to me.
2. Git cloned [fflib-apexmocks](https://github.com/apex-enterprise-patterns/fflib-apex-mocks).
3. Clean up all the junk - I just took the latest version of their classes and deleted the rest.
4. Added `Crud`, `Crud_Tests`, `CrudMock`, `ICrud`, `TypeUtils`, and `TestingUtils` from my private repo for testing.
5. Wrote some stress tests in `ApexMocksTests`.
6. Run `cp .envexample .env` and fill out your login data there.
7. Deployed it all using `yarn deploy` (you can toggle tests running using the RUN_TESTS flag in your .env file).
8. Ran the tests.

## Result

I wasn't sure what to expect when writing the stress tests. I wanted to choose deliberately long-running operations to simulate what somebody could expect for:

- CPU intensive transactions, particularly those involving complicated calculations
- Batch processes / queueable tasks which process large numbers of records (which I would hazard to say is a fairly common use-case in the SFDC ecosystem).

Here's what I found (note - I ran the tests ten times before taking this screenshot):

![Test results](./apex-mocks-test-failure.JPG)

(Run 1 was off my console, here's the other results ...)

Run 2 (with LARGE_NUMBER set to 1 million):

| Library  | Test                                       | Test Time                           |
| -------- | ------------------------------------------ | ----------------------------------- |
| CrudMock | crudmock_should_mock_dml_statements_update | 2.069s                              |
| fflib    | fflib_should_mock_dml_statements_update    | System.LimitException after 37.036s |

Run 3 (with LARGE_NUMBER set to 1 million):

| Library  | Test                                       | Test Time                          |
| -------- | ------------------------------------------ | ---------------------------------- |
| CrudMock | crudmock_should_mock_dml_statements_update | 1.955s                             |
| fflib    | fflib_should_mock_dml_statements_update    | System.LimitException after 38.21s |

Run 4 (with LARGE_NUMBER set to 100,000):

| Library  | Test                                       | Test Time |
| -------- | ------------------------------------------ | --------- |
| CrudMock | crudmock_should_mock_dml_statements_update | 0.295s    |
| fflib    | fflib_should_mock_dml_statements_update    | 9.585s    |

Run 5 (with LARGE_NUMBER set to 100,000):

| Library  | Test                                       | Test Time |
| -------- | ------------------------------------------ | --------- |
| CrudMock | crudmock_should_mock_dml_statements_update | 0.208s    |
| fflib    | fflib_should_mock_dml_statements_update    | 9.655s    |

Run 6 (with LARGE_NUMBER set to 100,000):

| Library  | Test                                       | Test Time |
| -------- | ------------------------------------------ | --------- |
| CrudMock | crudmock_should_mock_dml_statements_update | 1.835s    |
| fflib    | fflib_should_mock_dml_statements_update    | 16.639s   |

Run 7 (with LARGE_NUMBER set to 1 million):

| Library  | Test                                       | Test Time                        |
| -------- | ------------------------------------------ | -------------------------------- |
| CrudMock | crudmock_should_mock_dml_statements_update | 5.703s                           |
| fflib    | fflib_should_mock_dml_statements_update    | System.LimitException at 20.543s |

Run 8 (with LARGE_NUMBER set to 100,000):

| Library  | Test                                       | Test Time |
| -------- | ------------------------------------------ | --------- |
| CrudMock | crudmock_should_mock_dml_statements_update | 1.823s    |
| fflib    | fflib_should_mock_dml_statements_update    | 16.694s   |

Run 9 (with LARGE_NUMBER set to 100,000):

| Library  | Test                                         | Test Time                           |
| -------- | -------------------------------------------- | ----------------------------------- |
| CrudMock | crudmock_should_mock_dml_statements_update   | 1.796s                              |
| fflib    | fflib_should_mock_dml_statements_update      | System.LimitException after 15.994s |
| CrudMock | crudmock_should_mock_multiple_crud_instances | 14.206s                             |
| fflib    | fflib_should_mock_multiple_crud_instances    | 18.292s (passed, somehow)           |

Run 10 (LARGE_NUMBER set to 100,000):

| Library  | Test                                         | Test Time                           |
| -------- | -------------------------------------------- | ----------------------------------- |
| CrudMock | crudmock_should_mock_dml_statements_update   | .225s                               |
| fflib    | fflib_should_mock_dml_statements_update      | 9.655s                              |
| CrudMock | crudmock_should_mock_multiple_crud_instances | 1.711s                              |
| fflib    | fflib_should_mock_multiple_crud_instances    | System.LimitException after 16.212s |

Seasoned testing vets will note that there is some "burn-in" when testing on the SFDC platform; similar to the SSMS's optimizer, Apex tends to optimize over time. One of the first times I ran the first two tests, `crudmock_should_mock_dml_statements` and `fflib_should_mock_dml_statements`, the fflib test failed after 38 seconds and the CrudMock test passed in 1.955s).

The only time I successfully observed the CrudMock singleton test failing was when the value for `LARGE_NUMBER` was bumped up to 1 million (and, to be fair, it also ran several times successfully at that load).

Of course, it isn't reasonable to expect that these tests are exactly mirroring testing conditions. What is reasonable to expect is that the more complicated your test setup, the longer things are going to take using the FFLib library. The reason for that is simple - their mocks / stubs utilize deep call stacks:

- handleMethodCall
- mockNonVoidMethod
- recordMethod
- recordMethod again (overloaded)

That's just for an absurdly simple mocking setup, mocking one method. Again, the more you need to utilize mocking in your tests (particularly if you are testing objects passing through multiple handlers / triggers), the greater the overhead of the library on influencing your overall test time will be.

Thanks!
