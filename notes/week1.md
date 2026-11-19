# Week 1 - Setup + cloud basics

## Done
- [x] Azure account created (pay-as-you-go, no credit)
- [ ] MFA on
- [x] Budget alert set ($2 monthly at billing-account scope; raise to ~$17-20 before Week 4)
- [ ] Model access/quota requested
- [x] Toolchain: az, bicep, git, python

## Daily plan (learn + free practical)
- [x] Day 1: Cloud models, shared responsibility. Practical: budget alert, CLI check.
- [x] Day 2: Benefits of cloud (scalability, elasticity, HA). Practical: `az account list-locations`; look at App Service scale options in the portal.
- [x] Day 3: IaaS/PaaS/SaaS, consumption pricing. Practical: create `rg-learning-lab1` with tags.
- [x] Day 4: Regions, region pairs, availability zones. Practical: assign "Require a tag" Policy; see a denial.
- [x] Day 5: Resource groups, subscriptions, ARM. Practical: Delete lock test.
- [x] Day 6: Review. Practical: redo group + tags + lock in Bicep; deploy; delete.
- [x] Day 7: Rest or practice assessment. Practical: Pricing Calculator estimate.

## Learned (what it is / when to use / pricing / gotcha)
### Day 1 - Cloud concepts
1. **Own servers vs cloud:** With our own servers it is hard to maintain them and handle high traffic. In the cloud we can scale up or down as traffic changes and pay only for what we use.
2. **Public + private (hybrid cloud):** We can use private and public cloud together. Hybrid = a mix of our own servers and the cloud.
3. **Shared responsibility:** If we create a VM in the cloud (IaaS), we patch the operating system ourselves. Microsoft only manages the hardware and datacenter.

### Day 2 - Benefits of cloud
- **Scalability:** we can add capacity when needed. Scale up = a bigger server; scale out = more servers.
- **Elasticity:** capacity grows and shrinks automatically with demand (e.g. extra servers on a sale day, removed afterward).
- **Difference:** scalability = you *can* add capacity; elasticity = it happens *automatically*, both up and down.
- **Others:** high availability (stays up when parts fail), reliability (recovers from failure), predictability (consistent performance and cost), security, governance (rules like Policy).
- **Region chosen for Weeks 1-3:** `centralindia` (Pune). Revisit for Week 4 AI models.

### Day 3 - IaaS, PaaS, SaaS and consumption pricing
- **PaaS:** choose it when we only need a platform to run our code (e.g. host a backend on App Service or Functions). Microsoft manages most of the platform, so we don't need full access.
- **IaaS:** choose it when we need complete control over the machine or want a separate system to host the backend.
- **Consumption pricing:** pay only for what we use. A Function app that gets no requests scales to zero and costs almost nothing. Gotcha: a Function app also needs a storage account, which has a small cost even when idle.
- **Practical:** resource group `rg-learning-lab1` created in Central India (via the portal) in "Study Subscription". Tags on it: `environment=study`, `owner=shibin`.

### Day 4 - Regions, region pairs, availability zones
- **Availability zone:** a separate datacenter inside one region (own power, cooling, network). Protects against one datacenter failing.
- **Region pair:** two regions in the same geography that back each other up. Protects against a whole region failing. (Central India pairs with South India.)
- **Why not the cheapest region:** some regions lack zones or a good pair (less resilience), plus latency to users, service/AI-model availability, compliance/data residency, and price.
- **Policy lab:** assigned "Require a tag and its value on resources" (project=learning) to `rg-learning-lab1`. Creating a storage account without the tag failed with `RequestDisallowedByPolicy` and our custom non-compliance message. This policy only *denies* new resources; it has no remediation and needs no managed identity.

### Day 5 - Resource groups, ARM, locks
- **Resource group:** a logical folder for related resources. Deleting the group deletes everything inside it.
- **Hierarchy:** billing account > subscription > resource group > resources (management groups sit above subscriptions).
- **ARM:** the single front door behind portal, CLI, Bicep and SDKs. Policy, RBAC and locks are enforced there, so no tool can bypass them.
- **Policy vs RBAC:** RBAC = who can do something; Policy = what is allowed. A Deny policy blocks even an Owner.
- **Locks:** Delete (blocks deletion) and Read-only (blocks changes, and can block actions like listing keys).
- **Lab:** added `lock-no-delete` to `rg-learning-lab1`; deleting the group failed ("has locks applied"). Removed the lock, then deleted the group. Verified from the CLI: group gone, nothing left billing. The Policy assignment went with the group.

### Day 6 - Bicep (infrastructure as code)
- **Bicep:** a short text language that describes the end state of Azure resources. It compiles to an ARM template, so ARM still enforces Policy, RBAC and locks.
- **Idempotent:** deploying the same file twice changes nothing (`what-if` showed `NoChange`).
- **`what-if`:** previews a deployment before it changes anything. Always run it first.
- **Scopes:** a resource group is created at *subscription* scope; a lock lives *inside* the group, so it is a module scoped to the group.
- **Files:** `infra/lab1.bicep` (group + tags, optional lock via `enableLock`) and `infra/modules/lock.bicep`.
- **Lab:** deployed the group, redeployed (no change), redeployed with `enableLock=true`, tried to delete (blocked by `ScopeLocked`), removed the lock, deleted the group.
- **Commands:** `az deployment sub what-if|create --location centralindia --template-file infra/lab1.bicep`.

### Day 7 - Pricing Calculator
- **Pricing Calculator:** estimates the monthly cost of a design *before* building it. Use it when planning a specific Azure workload. It is an **estimate, not a bill**: real cost depends on actual usage, and prices change.
- **TCO Calculator:** compares the cost of running a workload on our own servers vs in Azure. Use it to justify moving to the cloud.
- **Estimates we built:** App Service Free (F1) = $0; Basic B1 (Central India, 730 hrs) = $60.59/month on Windows ($0.083/hr) vs $13.14/month on Linux ($0.018/hr). The Windows price includes the licence, so the OS choice alone changes the bill by about 78%. Functions Consumption at 0 executions = $0 (first 1M executions and 400,000 GB-s per month free). Storage account (Central India, 5 GB, Hot, LRS) = about $1.25/month, of which only $0.10 is capacity; the rest is operations at default sample volumes.
- **Storage billing items:** writes and list/create-container ops cost more than reads; other ops are small; data retrieval is $0 in Hot (charged per GB in colder tiers); data write is free.

### Also learned
- **Cost Management:** We created a budget with alerts. It only sends emails; it does not cap spending. Budgets can sit at billing-account or subscription scope.

## Questions
-
