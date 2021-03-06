# encoding: utf-8

require "katello_test_helper"

module Katello
  class Api::V2::HostsBulkActionsControllerTest < ActionController::TestCase
    include Support::ForemanTasks::Task

    def permissions
      @view_permission = :view_hosts
      @update_permission = :edit_hosts
      @destroy_permission = :destroy_hosts
    end

    def models
      @view = katello_content_views(:library_view)
      @view_2 = katello_content_views(:acme_default)
      @library = katello_environments(:library)

      @host1 = FactoryGirl.create(:host, :with_content, :organization => @view.organization, :content_view => @view, :lifecycle_environment => @library)
      @host2 = FactoryGirl.create(:host, :with_content, :organization => @view.organization, :content_view => @view, :lifecycle_environment => @library)
      @host_ids = [@host1.id, @host2.id]

      @org = @view.organization
      @host_collection1 = katello_host_collections(:simple_host_collection)
      @host_collection1.hosts << @host1
      @host_collection2 = katello_host_collections(:another_simple_host_collection)
    end

    def setup
      setup_controller_defaults_api
      login_user(User.find(users(:admin)))
      @request.env['HTTP_ACCEPT'] = 'application/json'

      setup_foreman_routes
      permissions
      models
    end

    def test_add_host_collection
      assert_equal 1, @host1.host_collections.count # system initially has simple_host_collection
      put :bulk_add_host_collections, :included => {:ids => @host_ids},
                                      :organization_id => @org.id,
                                      :host_collection_ids => [@host_collection1.id, @host_collection2.id]

      assert_response :success
      assert_equal 2, @host1.host_collections.count
    end

    def test_remove_host_collection
      assert_equal 1, @host1.host_collections.count # system initially has simple_host_collection
      put :bulk_remove_host_collections, :included => {:ids => @host_ids},
                                         :organization_id => @org.id,
                                         :host_collection_ids => [@host_collection1.id, @host_collection2.id]

      assert_response :success
      assert_equal 0, @host1.host_collections.count
    end

    def test_install_package
      BulkActions.any_instance.expects(:install_packages).once.returns(Job.new)

      put :install_content,  :included => {:ids => @host_ids}, :organization_id => @org.id,
          :content_type => 'package', :content => ['foo']

      assert_response :success
    end

    def test_update_package
      BulkActions.any_instance.expects(:update_packages).once.returns(Job.new)

      put :update_content, :included => {:ids => @host_ids}, :organization_id => @org.id,
          :content_type => 'package', :content => ['foo']

      assert_response :success
    end

    def test_remove_package
      BulkActions.any_instance.expects(:uninstall_packages).once.returns(Job.new)

      put :remove_content, :included => {:ids => @host_ids}, :organization_id => @org.id,
          :content_type => 'package', :content => ['foo']

      assert_response :success
    end

    def test_install_package_group
      BulkActions.any_instance.expects(:install_package_groups).once.returns(Job.new)

      put :install_content, :included => {:ids => @host_ids}, :organization_id => @org.id,
          :content_type => 'package_group', :content => ['foo group']

      assert_response :success
    end

    def test_update_package_group
      BulkActions.any_instance.expects(:update_package_groups).once.returns(Job.new)

      put :update_content, :included => {:ids => @host_ids}, :organization_id => @org.id,
          :content_type => 'package_group', :content => ['foo group']

      assert_response :success
    end

    def test_remove_package_group
      BulkActions.any_instance.expects(:uninstall_package_groups).once.returns(Job.new)

      put :remove_content, :included => {:ids => @host_ids}, :organization_id => @org.id,
          :content_type => 'package_group', :content => ['foo group']

      assert_response :success
    end

    def test_install_errata
      errata = katello_errata("bugfix")
      @host1.content_facet.applicable_errata << errata
      @controller.expects(:async_task).with(::Actions::BulkAction, ::Actions::Katello::Host::Erratum::ApplicableErrataInstall,
                                            [@host1], [errata.uuid]).returns({})

      put :install_content, :included => {:ids => [@host1.id]}, :organization_id => @org.id,
          :content_type => 'errata', :content => [errata.errata_id]

      assert_response :success
    end

    def test_destroy_hosts
      assert_async_task(::Actions::BulkAction, ::Actions::Katello::Host::Destroy, [@host1, @host2])

      put :destroy_hosts, :included => {:ids => @host_ids}, :organization_id => @org.id
      assert_response :success
    end

    def test_content_view_environment
      assert_async_task(::Actions::BulkAction, ::Actions::Katello::Host::UpdateContentView, [@host1, @host2], @view_2.id, @library.id)

      put :environment_content_view, :included => {:ids => @host_ids}, :organization_id => @org.id,
          :environment_id => @library.id, :content_view_id => @view_2.id

      assert_response :success
    end

    def test_permissions
      good_perms = [@update_permission]
      bad_perms = [@view_permission, @destroy_permission]

      assert_protected_action(:bulk_add_host_collections, good_perms, bad_perms) do
        put :bulk_add_host_collections,  :included => {:ids => @host_ids},
                                         :organization_id => @org.id,
                                         :host_collection_ids => [@host_collection1.id, @host_collection2.id]
      end

      assert_protected_action(:bulk_remove_host_collections, good_perms, bad_perms) do
        put :bulk_remove_host_collections,  :included => {:ids => @host_ids},
                                            :organization_id => @org.id,
                                            :host_collection_ids => [@host_collection1.id, @host_collection2.id]
      end

      assert_protected_action(:install_content, good_perms, bad_perms) do
        put :install_content, :included => {:ids => @host_ids}, :organization_id => @org.id,
            :content_type => 'package', :content => ['foo']
      end

      assert_protected_action(:update_content, good_perms, bad_perms) do
        put :update_content, :included => {:ids => @host_ids}, :organization_id => @org.id,
            :content_type => 'package', :content => ['foo']
      end

      assert_protected_action(:remove_content, good_perms, bad_perms) do
        put :remove_content, :included => {:ids => @host_ids}, :organization_id => @org.id,
            :content_type => 'package', :content => ['foo']
      end

      good_perms = [@destroy_permission]
      bad_perms = [@view_permission, @update_permission]

      assert_protected_action(:destroy_hosts, good_perms, bad_perms) do
        put :destroy_hosts, :included => {:ids => @host_ids}, :organization_id => @org.id
      end
    end

    def test_environment_content_view_permission
      good_perms = [@update_permission]
      bad_perms = [@view_permission, @destroy_permission]

      assert_protected_action(:environment_content_view, good_perms, bad_perms) do
        put :environment_content_view, :included => {:ids => @host_ids}, :organization_id => @org.id,
            :environment_id => @library.id, :content_view_id => @view.id
      end
    end

    def test_available_incremental_updates
      ContentViewVersion.any_instance.stubs(:package_count).returns(0)
      ContentViewVersion.any_instance.stubs(:errata_count).returns(0)
      ContentViewVersion.any_instance.stubs(:puppet_module_count).returns(0)

      @view_repo = Katello::Repository.find(katello_repositories(:rhel_6_x86_64_library_view_1))

      @host1.content_facet.applicable_errata = @view_repo.errata

      @cv = katello_content_views(:library_dev_view)
      @env = katello_environments(:dev)

      unavailable = @host1.content_facet.applicable_errata -
          @host1.content_facet.installable_errata(@env, @cv)
      @missing_erratum = unavailable.first

      assert @missing_erratum
      post :available_incremental_updates, :included => {:ids => [@host1.id]}, :organization_id => @org.id, :errata_ids => [@missing_erratum.uuid]
      assert_response :success
    end
  end
end
