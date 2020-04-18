# frozen_string_literal: true

class GCPBaseCache < Inspec.resource(1)
  name 'GCPBaseCache'
  desc 'The GCP Base cache resource is inherited by more specific cache classes (e.g. GCE, GKE):
       The cache is consumed by the CIS and PCI Google Inspec profiles:
       https://github.com/GoogleCloudPlatform/inspec-gcp-cis-benchmark'
  attr_reader :gke_locations

  def initialize(project: '')
    @gcp_project_id = project
    @gke_locations = []
  end

  protected

  def get_all_gcp_locations
    locations = inspec.google_compute_zones(project: @gcp_project_id).zone_names
    locations += inspec.google_compute_regions(project: @gcp_project_id)
                       .region_names
    locations
  end

end

class GKECache < GCPBaseCache
  name 'GKECache'
  desc 'The GKE cache resource contains functions consumed by the CIS/PCI Google profiles:
       https://github.com/GoogleCloudPlatform/inspec-gcp-cis-benchmark'
  attr_reader :gke_locations, :gce_zones

  @@cached_gke_clusters = []
  @@gke_clusters_cached = false

  def initialize(project: '', gke_locations: [])
    @gcp_project_id = project
    @gke_locations = if gke_locations.join.empty?
                       get_all_gcp_locations
                     else
                       gke_locations
                     end
  end

  def get_gke_clusters_cache()
    if is_gke_cached == false
      set_gke_clusters_cache
    end
    @@cached_gke_clusters
  end

  def is_gke_cached
    @@gke_clusters_cached
  end

  def set_gke_clusters_cache()
    @@cached_gke_clusters = []
    collect_gke_clusters_by_location(@gke_locations)
    @@gke_clusters_cached = true
  end

  private

  def collect_gke_clusters_by_location(gke_locations)
    gke_locations.each do |gke_location|
      inspec.google_container_clusters(project: @gcp_project_id,
                                       location: gke_location).cluster_names
            .each do |gke_cluster|
        @@cached_gke_clusters.push({ cluster_name: gke_cluster, location: gke_location })
      end
    end
  end
end

class GCECache < GCPBaseCache
  name 'GCECache'
  desc 'The GCE cache resource contains functions consumed by the CIS/PCI Google profiles:
       https://github.com/GoogleCloudPlatform/inspec-gcp-cis-benchmark'
  attr_reader :gke_locations, :gce_zones

  @@cached_gce_instances = []
  @@gce_instances_cached = false

  def initialize(project: '', gce_zones: [])
    @gcp_project_id = project
    @gce_zones = if gce_zones.join.empty?
                   inspec.google_compute_zones(project: @gcp_project_id).zone_names
                 else
                   gce_zones
                 end
  end

  def get_gce_instances_cache()
    if is_gce_cached == false
      set_gce_instances_cache
    end
    @@cached_gce_instances
  end

  def is_gce_cached
    @@gce_instances_cached
  end

  def set_gce_instances_cache()
    @@cached_gce_instances = []
    # Loop/fetch/cache the names and locations of GKE clusters
    @gce_zones.each do |gce_zone|
      inspec.google_compute_instances(project: @gcp_project_id, zone: gce_zone)
            .instance_names.each do |instance|
        @@cached_gce_instances.push({ name: instance, zone: gce_zone })
      end
    end
    # Mark the cache as full
    @@gce_instances_cached = true
    @@cached_gce_instances
  end
end