# frozen_string_literal: true

class GcpHelpers < Inspec.resource(1)
  name 'gcp_helpers'
  desc 'The GCP helpers resource contains functions consumed by the CIS/PCI Google profiles:
       https://github.com/GoogleCloudPlatform/inspec-gcp-cis-benchmark'
  attr_reader :gke_locations, :gce_zones

  def initialize(project: '')
    @gcp_project_id = project
    @gke_clusters_cached = false
    @gke_locations = []
    @gce_instances_cached = false
    @gce_zones = []
    @cached_gce_instances = {}
    @cached_gke_clusters = {}
  end

  def get_all_gcp_locations
    locations = inspec.google_compute_zones(project: @gcp_project_id).zone_names
    locations += inspec.google_compute_regions(project: @gcp_project_id)
                       .region_names
    locations
  end

  def collect_gke_clusters_by_location(gke_locations)
    gke_locations.each do |gke_location|
      inspec.google_container_clusters(project: @gcp_project_id,
                                       location: gke_location).cluster_names
            .each do |gke_cluster|
        @cached_gke_clusters.push({ cluster_name: gke_cluster, location: gke_location })
      end
    end
  end

  def get_gke_clusters(gcp_gke_locations)
    unless @gke_clusters_cached == true
      # Reset the list of cached clusters
      @cached_gke_clusters = []
      begin
        # If we weren't passed a specific list/array of zones/region names from
        # inputs, search everywhere
        @gke_locations = if gcp_gke_locations.join.empty?
                           get_all_gcp_locations(gcp_project_id)
                         else
                           gcp_gke_locations
                         end

        # Loop/fetch/cache the names and locations of GKE clusters
        collect_gke_clusters_by_location(gcp_project_id, @gke_locations)

        # Mark the cache as full
        @gke_clusters_cached = true
      rescue NoMethodError
        # During inspec check, the mock transport connection doesn't set up a
        # gcp_compute_client method
      end
    end
    # Return the list of clusters
    @cached_gke_clusters
  end

  def get_gce_instances(gce_zones)
    unless @gce_instances_cached == true
      # Set the list of cached intances
      @cached_gce_instances = []
      begin
        # If we weren't passed a specific list/array of zone names from inputs,
        # search everywhere
        @gce_zones = if gce_zones.join.empty?
                       inspec.google_compute_zones(project: @gcp_project_id).zone_names
                     else
                       gce_zones
                     end

        # Loop/fetch/cache the names and locations of GKE clusters
        @gce_zones.each do |gce_zone|
          inspec.google_compute_instances(project: @gcp_project_id, zone: gce_zone)
                .instance_names.each do |instance|
            @cached_gce_instances.push({ name: instance, zone: gce_zone })
          end
        end
        # Mark the cache as full
        @gce_instances_cached = true
      rescue NoMethodError
        # During inspec check, the mock transport connection doesn't set up a
        # gcp_compute_client method
      end
    end
    # Return the list of clusters
    @cached_gce_instances
  end
end
