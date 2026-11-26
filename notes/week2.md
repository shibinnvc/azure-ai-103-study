# Week 2 - Compute, networking, storage, identity

## Daily plan (learn + practical; cost flag in brackets)
- [x] Day 1: Compute options (VM, containers, App Service, Functions). Practical: compare the four in the Pricing Calculator. [free]
- [x] Day 2: Networking basics (VNet, subnets, NSG, DNS). Practical: create a VNet + subnet + NSG with Bicep. [free]
- [x] Day 3: Storage (blob, files, queue, table; redundancy; tiers). Practical: storage account, container, upload a file. [tiny cost; delete after]
- [x] Day 4: Storage security (SAS, lifecycle rules). Practical: SAS token + lifecycle rule. [tiny cost; delete after]
- [x] Day 5: Identity (Entra ID, RBAC, managed identity). Practical: test user/group, assign Reader at resource-group scope. [free]
- [x] Day 6: Key Vault + managed identity. Practical: store a secret, read it with managed identity. [tiny cost; delete after]
- [x] Day 7: Review + quiz. Practical: redo the week as Bicep, deploy, delete. [delete everything]

## Learned
### Day 1 - Compute
- **VM (IaaS):** full control of the OS; billed per hour while it exists. Use for legacy apps or custom installers.
- **Containers (Container Apps/ACI/AKS):** portable apps; billed per second of vCPU/memory.
- **App Service (PaaS):** web apps/APIs that run continuously; billed per hour for the plan (Linux B1 = $13.14/month, Windows B1 = $60.59/month).
- **Functions (serverless):** small event-driven code; billed per execution and run time; first 1M executions and 400,000 GB-s per month free; $0 when idle.
- **Steady traffic all day -> App Service** (predictable, always warm). **Occasional event-driven jobs -> Functions.**
- **Gotcha:** stopping a VM from inside the OS keeps billing compute. Use **stop and deallocate** (portal/CLI) to stop compute charges; you still pay for the disk.

### Day 2 - Networking
- **VNet:** our private network in Azure (free). Resources inside can talk privately. **Subnet:** a section of it. **NSG:** allow/deny rules for traffic on a subnet (or NIC). **DNS:** turns names into IPs, controls no access. **Public IP:** internet-reachable address (small hourly cost).
- **NSG rules** are checked from the lowest priority number upward; the first match wins. Azure adds default rules at 65000+ (e.g. `AllowVnetInBound`), so a VNet is *not* a wall: subnets in the same VNet can reach each other unless an NSG denies it.
- **Lab design:** `vnet-learning` 10.0.0.0/16 with `snet-web` (nsg-web allows 443 from Internet) and `snet-db` (nsg-db allows 1433 only from 10.0.1.0/24, then denies all other inbound at 4000). Files: `infra/lab2-network.bicep`, `infra/modules/network.bicep`. Deployed, inspected in the portal (Resource visualizer), then deleted.
- **When to use a VNet:** VMs, private/internal resources, connecting to our own network (VPN/ExpressRoute), private endpoints, filtering traffic, separating environments. Not needed for simple public PaaS (Static Web Apps, Functions, App Service) while learning. Test: "would a public address be a problem?"
- **AWS equivalent:** VPC (security group + network ACL ~ NSG; VPC endpoint/PrivateLink ~ private endpoint).
- **Private endpoint:** gives a service (e.g. AI Search) a private address inside our VNet so it needs no public one.

### Day 3 - Storage
- **Storage account services:** Blob (files; what DocuMind uses), Files (shares), Queue (messages), Table (key-value).
- **Redundancy:** LRS (3 copies, one datacenter), ZRS (3 zones), GRS (+ paired region), GZRS (zones + paired region). Pick GRS/GZRS to survive a region failure; the secondary copy isn't readable unless RA-GRS. The portal may default to GRS, so check it.
- **Tiers:** Hot (cheapest reads), Cool (30 days min), Cold (90), Archive (180 min, offline, hours to rehydrate, early-deletion fee). Old contracts nobody reads -> Archive.
- **Billing items:** writes and list/create-container ops cost more than reads; data retrieval is $0 in Hot; data write is free.
- **Control plane vs data plane:** Owner can manage the account but cannot read/write blobs until given a data role (Storage Blob Data Contributor). Role assignments take ~20-60 seconds to apply.
- **Keyless:** uploaded/read with `--auth-mode login` (our Entra sign-in), no account keys.
- **Secure defaults:** `allowBlobPublicAccess=false`, TLS 1.2, HTTPS only, private container. An anonymous request returned `PublicAccessNotPermitted` (HTTP 409).
- **Lab:** `infra/lab3-storage.bicep` + `infra/modules/storage.bicep` (name from `uniqueString`). Deployed, uploaded `hello.txt`, read it back, then deleted everything (verified 0 groups/0 resources).
- **Auto-created group:** `NetworkWatcherRG` (free) appears when a VNet is created in a region; it was deleted and will return when needed.

### Day 4 - Storage security (SAS + lifecycle)
- **SAS** = a URL with a signature giving limited access (permissions, one blob or container, expiry) without sharing the account key. Treat the full URL like a password until it expires.
- **Types:** account SAS and service SAS are signed with the account key; **user delegation SAS** is signed with Entra credentials (recommended). Fields in the URL: `sp` permissions, `se` expiry, `sr` scope (b = blob), `skoid` signing identity, `sig` signature.
- **Mobile-app pattern:** the backend issues the SAS with its managed identity, write-only, for one blob name, 15 minutes.
- **Revoking:** user delegation SAS -> remove the signer's data role or `az storage account revoke-delegation-keys` (kills all of them at once). Account/service SAS -> only rotate the account key (breaks everything using it). Always prefer short expiries.
- **Tested (CLI + portal):** no token -> 409 `PublicAccessNotPermitted`; SAS read -> 200; SAS write -> 403 (read-only); other blob -> 403; after revoke -> `AuthenticationFailed` while the link was still unexpired.
- **Gotcha:** the portal fills the start time when the panel opens; an expiry already in the past gives a confusing `InvalidXmlNodeValue` error. Portal "Authentication method: Access key" vs "Entra user account": switch to Entra for keyless.
- **User-bound SAS** (portal option): the link only works for one named, signed-in Entra user.
- **Lifecycle rule** (`infra/modules/lifecycle.bicep`, `managementPolicies/default`): under `documents/`, Cool after 30 days, Archive after 90, delete after 365 days since modification. Runs about once a day, so it can't be seen working in one session.
- **Lab:** `infra/lab4-storage-security.bicep`. Deployed, tested, group deleted.

### Day 5 - Identity (Entra ID, RBAC, managed identity)
- **Entra ID** = directory of identities (who are you?). **RBAC** = what can you do. A role assignment = WHO (user/group/identity) + WHAT (role) + WHERE (scope). Scopes inherit downward: management group > subscription > resource group > resource.
- **Identities:** user, group, service principal (app with a secret/certificate you must rotate), **managed identity** (Azure creates and rotates the credential; system-assigned = tied to one resource, user-assigned = reusable).
- **Roles:** Owner (all + assign roles), **Contributor** (all except assigning roles, but CAN delete the resource group), Reader (view only), plus data roles (Storage Blob Data ...). In the portal Owner/Contributor are under "Privileged administrator roles".
- **Best practice:** assign roles to groups, at the smallest scope that works (least privilege). Read the verb: see = Reader, change = Contributor, give access = Owner.
- **Tested:** test user in group `lab5-readers`. Reader: saw only `rg-learning-lab5`, could read IAM, create storage account -> `AuthorizationFailed` (deployments/validate/action), delete group -> not authorized. Contributor: created a storage account, but IAM "Add role assignment" was greyed out.
- **Error message recipe:** "client X does not have authorization to perform action Y over scope Z" = who, what, where of the missing role.
- **Managed identity vs account key:** identity has no secret, least privilege, and a leaver doesn't force a key rotation; disable the person's account, the app's identity is separate.
- **SAS from a backend:** backend (managed identity, Storage Blob Delegator + data role) fetches a user delegation key occasionally and signs short-lived SAS tokens locally per user action.
- **Lesson learned:** the activity log can lag a few minutes, so a new resource may not show its creator right away.
- **Lab:** `infra/lab5-identity.bicep` (empty group); user, group and role assignments done in the portal. All deleted (group, user, resource group).

### Day 6 - Key Vault + managed identity
- **Key Vault** = one protected place for secrets (strings), keys (crypto keys that never leave) and certificates. Access via RBAC, logged, rotate in one place. Never put secrets in code, git or tags.
- **RBAC mode** (`enableRbacAuthorization: true`) replaces old access policies. Roles: **Key Vault Secrets Officer** (manage secrets), **Key Vault Secrets User** (read only).
- **Owner is control plane only:** an Owner got `ForbiddenByRbac` writing a secret until given Secrets Officer at the vault scope (data plane). Same split as storage on Day 3. Smallest fix = the data role at the narrowest scope.
- **Managed identity flow:** app -> Entra gets a token for the identity -> Key Vault checks RBAC -> value returned. No password anywhere.
- **Tested:** user-assigned identity `id-learning-app` + Secrets User -> a container (ACI, `az login --identity --client-id ...`) read the secret. After removing that one role assignment the same container got `ForbiddenByRbac`.
- **IDs:** a managed identity has a principalId (object id; roles attach to this) and a clientId (appId; used to sign in). `az role assignment list` shows the client id as principalName.
- **Gotchas:** newer Azure CLI rejects `az login --identity --username`; use `--client-id`. My test echo returned exit code 0 even though the read failed, so apps must check errors. Role changes take a minute or more; the container's log is empty until it finishes.
- **Soft delete / purge:** deleted vaults stay reserved (7-90 days). Purge protection blocks purging and can't be turned off, so it was left off in the lab; use it in production. We purged with `az keyvault purge`.
- **Needed:** `Microsoft.ContainerInstance` provider registered once per subscription.
- **Lab:** `infra/lab6-keyvault.bicep` + `infra/modules/keyvault.bicep`. Deployed, tested, deleted and purged (0 groups, 0 resources, 0 soft-deleted vaults).

### Day 7 - Review + combined Bicep deployment
- **Lab:** `infra/lab7-week2-review.bicep` composes the existing modules (network, storage, lifecycle, keyvault) in ONE deployment: what-if showed 10 changes (group, VNet, 2 NSGs, storage account + blob service + container + lifecycle policy, vault, identity). `az resource list` shows 6 because child resources aren't listed separately. Verified NSG rules, storage defaults, lifecycle rule, vault settings and tags; then deleted the group, purged the vault, and removed `NetworkWatcherRG` (auto-created, free).
- **Modules + outputs:** a module that uses another module's output (lifecycle uses storage.outputs.storageName) gets an automatic dependency, so order is handled for us.
- **Quiz result:** Q1 Functions (correct), Q3 GRS + Archive (correct; Archive isn't offered on ZRS/GZRS, so GRS), Q2 and Q4 corrected (NSG first match wins; upload needs Storage Blob Data Contributor, not read access). Q5-Q10 were not known, so they were taught:
  - Q5 Cut off a leaked user delegation SAS: `revoke-delegation-keys` or remove the signer's data role.
  - Q6 Lifecycle "30 days" counts from last modification (last access only if access tracking is on).
  - Q7 Deploy but not grant: Contributor, at the resource group, assigned to a group.
  - Q8 Password-free secret read needs a managed identity AND a role on the vault (e.g. Key Vault Secrets User).
  - Q9 Purge protection stays off in labs because it can't be turned off and blocks purging; use it in production.
  - Q10 Uploads = Blob storage, secret = Key Vault, runs a few times a day = Functions.
- **Re-test needed:** ask a fresh set of questions on Q5-Q10 topics before moving on.
- **Concept confusions cleared:** SAS = a link with a signature giving limited, time-boxed access. Entra ID is the directory/sign-in system; a managed identity is one kind of identity inside it, for Azure resources, with no secret.

## Questions
-
