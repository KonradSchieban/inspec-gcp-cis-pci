# InSpec GCP CIS PCI Helper Resource Pack

Resource pack containing helper functions for profiles using https://github.com/GoogleCloudPlatform/inspec-gcp-cis-benchmark. 

## Sample usage

### Create a profile 

For example, using InSpec e.g.

```
inspec init profile myprofile --platform gcp
```

### Update the inspec.yml file

This should be updated to point here instead of directly to the InSpec GCP resource pack:

```
depends:
- name: inspec-gcp-cis-pci
  url: https://github.com/inspec/inspec-gcp-cis-pci/archive/master.tar.gz
```

### Use the helper functions

Now we could edit the controls to include lines such as:

```
gcp_project_id = attribute('gcp_project_id')

gke_cache = GKECache(project: gcp_project_id, gke_locations: ['us-central1-a'])
p gke_cache.gke_clusters_cache

gce_cache = GCECache(project: gcp_project_id, gke_locations: ['us-central1-a'])
p gce_cache.gce_instances_cache
```

and directly use these methods in downstream profiles. 

### Other notes

This approach and much of the code in the helper resource originated because of the PR here: https://github.com/inspec/inspec-gcp/pull/245/files and the issue of helper modules with InSpec discussed https://github.com/inspec/inspec/issues/4948.  
