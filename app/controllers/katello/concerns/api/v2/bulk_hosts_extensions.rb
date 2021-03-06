module Katello
  module Concerns
    module Api::V2::BulkHostsExtensions
      extend ActiveSupport::Concern

      def find_bulk_hosts(permission, bulk_params, restrict_to = nil)
        #works on a structure of param_group bulk_params and transforms it into a list of systems
        organization = find_organization
        bulk_params[:included] ||= {}
        bulk_params[:excluded] ||= {}
        @hosts = []

        unless bulk_params[:included][:ids].blank?
          @hosts = ::Host::Managed.authorized(permission).where(:id => bulk_params[:included][:ids])
          @hosts = @hosts.where(:organization_id => organization.id) if organization
          @hosts = @hosts.where('id not in (?)', bulk_params[:excluded]) unless bulk_params[:excluded][:ids].blank?
          @hosts = restrict_to.call(@hosts) if restrict_to
        end

        if bulk_params[:included][:search]
          search_hosts = ::Host::Managed.where(:organization_id => organization_id) if params[:organization_id]
          search_hosts = search_hosts.search_for(bulk_params[:included][:search])
          @hosts += search_hosts
        end

        if bulk_params[:included][:ids].blank? && bulk_params[:included][:search].nil?
          fail HttpErrors::BadRequest, _("No hosts have been specified.")
        elsif @hosts.empty?
          fail HttpErrors::Forbidden, _("Action unauthorized to be performed on selected hosts.")
        end
        @hosts
      end

      def find_organization
        Organization.find_by_id(params[:organization_id])
      end
    end
  end
end
