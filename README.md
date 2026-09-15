# Apex Mocks Toolkit — FFLib vs CrudMock vs Native Stubs

Maintained by **Amit Kumar** ([amitgrazitti@gmail.com](mailto:amitgrazitti@gmail.com)).

This repository is a fork/continuation of James Simone's [apex-mocks-stress-test](https://github.com/jamessimone/apex-mocks-stress-test), which originally benchmarked `fflib-apex-mocks` against a hand-rolled `Crud`/`CrudMock` pair. The original benchmark and its write-up (kept below, in his own words, under "Introduction" / "My methodology" / "Result") are his — see [LICENSE](LICENSE) for the MIT terms both his original work and these additions are released under. Everything past that point has grown into a small CRUD/mocking toolkit, maintained here going forward.

**Looking for how to actually use a class?** See [USAGE.md](USAGE.md) for a per-class developer guide with code examples. This README is the map and the changelog; USAGE.md is the reference.

## Quick Start

```bash
git clone https://github.com/amitshq/apex-mocks-toolkit.git
cd apex-mocks-toolkit
```

`fflib-apex-mocks` isn't vendored in this repo (see `.gitignore`) — clone and deploy it separately first, or [`ApexMocksTests.cls`](src/classes/ApexMocksTests.cls) won't compile:

```bash
git clone https://github.com/apex-enterprise-patterns/fflib-apex-mocks.git
# see that repo's own README for its deploy instructions
```

Then deploy this repo (it uses the classic metadata-API layout — `src/package.xml` alongside `src/classes`, `src/triggers`, `src/objects`) and run its tests:

```bash
sf org login web --alias yourOrgAlias
sf project deploy start --metadata-dir src --target-org yourOrgAlias
sf apex run test --test-level RunLocalTests --target-org yourOrgAlias --result-format human --synchronous
```

`ApexMocksTests.cls`'s `LARGE_NUMBER` constant defaults to `10000`; the dramatic `System.LimitException` results in the original write-up further down used 100,000–1,000,000 — bump it yourself to reproduce those.

## What's in this toolkit

| Category | Classes | What it does |
| --- | --- | --- |
| CRUD | `ICrud`, `Crud`, `CrudMock`, `SecureCrud` | Mockable DML; `SecureCrud` adds FLS/CRUD enforcement |
| Queries | `ISelector`, `Selector`, `AccountsSelector`, `SelectorMock` | Mockable SOQL — the read-side mirror of CRUD |
| Callouts | `ICallout`, `Callout`, `CalloutMock`, `RetryableCallout`, `LeadEnrichmentClient` | Mockable HTTP callouts, with retry/backoff and a worked API-client example |
| Platform Events | `IEventPublisher`, `EventPublisher`, `EventPublisherMock`, `Lead_Assigned__e` | Mockable `EventBus.publish()` |
| Unit of Work | `IUnitOfWork`, `UnitOfWork` | Batches DML into one insert/update/delete per commit |
| Assignment | `IAssigner`, `RoundRobinAssigner`, `RandomAssigner`, `LoadBalancedAssigner`, `WeightedRoundRobinAssigner`, `CachedRoundRobinAssigner` | Interchangeable record-assignment strategies |
| Domain & validation | `IDomain`, `Domain`, `LeadsDomain`, `IValidationRule`, `Validator`, `RequiredFieldRule` | Record-level business rules, two composition styles |
| Factory | `Application` | One place every mock above gets swapped in tests |
| Trigger framework | `TriggerHandler`, `LeadTriggerHandler`, `LeadAssignmentConfig`, `LeadTrigger.trigger` | Dispatch base class + a worked example composing several rows above |
| Batch & async | `BatchBase`, `LeadReassignmentBatch`, `QueueableChainer` | `Database.Batchable`/`Queueable` helpers |
| Caching | `ICache`, `PlatformCache`, `CacheMock` | Mockable Platform Cache |
| Governor limits | `GovernorLimitGuard` | Proactive `Limits.*` checks instead of a thrown `System.LimitException` |
| Test data & utilities | `TestingUtils`, `TypeUtils`, `SObjectComparer` | Fake IDs, dynamic Apex, field-diffing |
| Benchmarking | `Stopwatch`, `CrudStubProvider`, `ApexMocksTests` | CPU timing, a native-stub mock, and the fflib-vs-CrudMock benchmark suite itself |

Every class above ships with its own `*_Tests.cls` (not listed individually here — see [USAGE.md](USAGE.md) for what each one covers). 80 classes, 1 trigger, 1 Platform Event, all on API 67.0.

## Changelog

<details>
<summary><strong>Round 1</strong> — bug fixes, API version bump, first new classes</summary>

**Fixed:** the hard-delete test asserting against a permanently-purged record; a missing anti-chunking sort on `doUpsert(records, externalIdField)`; silently-discarded `Database.emptyRecycleBin` failures; a `doUndelete`/`doUnDelete` casing inconsistency; an unguarded `String.repeat()` edge case in `TestingUtils.generateId`; a message-less `CrudMock.InvalidOperationException`; and a `package.json` license field that said `ISC` while [LICENSE](LICENSE) has always been MIT.

**Added:** `CrudStubProvider` (native `Test.createStub` as a third mocking approach), `UnitOfWork`, and the `IAssigner` trio (`RoundRobinAssigner`/`RandomAssigner`/`LoadBalancedAssigner`). Added missing test coverage for `TestingUtils`, `TypeUtils`, and `CrudMock.RecordsWrapper`. Bumped every class from API 47.0 (Winter '20) to 67.0.

</details>

<details>
<summary><strong>Round 2</strong> — SecureCrud, the trigger framework, Selector layer</summary>

**Added:** `SecureCrud` (FLS/CRUD enforcement, drop-in `ICrud`); `TriggerHandler` + `LeadTriggerHandler` (the first worked example composing `Crud`/`UnitOfWork`/`IAssigner`, wired to a real `LeadTrigger.trigger`); the Selector layer (`ISelector`/`Selector`/`AccountsSelector`/`SelectorMock`, the read-side mirror of CRUD); `GovernorLimitGuard`; and `Stopwatch`.

</details>

<details>
<summary><strong>Round 3</strong> — Callouts, Application factory, Domain/Validator, Platform Events, CI</summary>

**Added:** the Callout layer (`ICallout`/`Callout`/`CalloutMock`, no `Test.setMock` ceremony needed when mocking); `Application` (a factory/service-locator tying every mock together behind one override point); the Domain layer (`IDomain`/`Domain`/`LeadsDomain`); composable validation (`IValidationRule`/`Validator`/`RequiredFieldRule`); mockable Platform Events (`IEventPublisher`/`EventPublisher`/`EventPublisherMock`, backed by a real `Lead_Assigned__e` — the repo's first non-Apex-class metadata); and `QueueableChainer`.

**Also:** ran the whole codebase through `prettier-plugin-apex` for the first time (a devDependency since commit one, never used) — it caught a genuine, previously-undetected compile error (`GovernorLimitGuard.percentUsed` had a parameter named `limit`, a reserved word in Apex), now fixed. Added [`.github/workflows/ci.yml`](.github/workflows/ci.yml) to run that check on every push/PR going forward.

</details>

<details>
<summary><strong>Round 4</strong> — Caching, Batchable, a fourth Assigner, field diffing, callout retries</summary>

**Added:** `ICache`/`PlatformCache`/`CacheMock` plus `CachedRoundRobinAssigner` — actually implements the "persist the resume index" comment `RoundRobinAssigner` had carried since round 2; `BatchBase` + `LeadReassignmentBatch` — the `Database.Batchable` half of the original benchmark's "batch processes" motivation (`QueueableChainer` only covered the queueable half); `WeightedRoundRobinAssigner` — a fourth `IAssigner`, for uneven volume splits; `SObjectComparer` — a standalone field-diff utility for `TriggerHandler`'s update hooks; and `RetryableCallout` + `LeadEnrichmentClient` — retry/backoff on `ICallout`, plus the worked example that layer was missing.

**Also:** re-verified all 80 classes with `prettier-plugin-apex` before committing — zero parse errors.

</details>

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
