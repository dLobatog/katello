describe('Controller: ContentHostBaseSubscriptionsController', function() {
    var $scope,
        $controller,
        translate,
        ContentHost,
        HostSubscription,
        Subscription,
        Nutupane,
        expectedTable,
        expectedRows;

    beforeEach(module(
        'Bastion.content-hosts',
        'Bastion.subscriptions',
        'Bastion.test-mocks',
        'content-hosts/details/views/host-collections.html',
        'content-hosts/views/content-hosts.html',
        'content-hosts/views/content-hosts-table-full.html'
    ));

    beforeEach(inject(function($injector) {
        var $controller = $injector.get('$controller'),
            $q = $injector.get('$q');

        ContentHost = $injector.get('MockResource').$new();
        HostSubscription = $injector.get('MockResource').$new();
        $scope = $injector.get('$rootScope').$new();
        $location = $injector.get('$location');
        
        HostSubscription.autoAttach = function() {};

        expectedRows = [];
        expectedTable = {
            showColumns: function() {},
            getSelected: function() {
                return expectedRows;
            },
            rows: function () {
                return expectedRows;
            },
            selectAll: function() {},
            allSelected: false
        };
        Nutupane = function() {
            this.table = expectedTable;
            this.removeRow = function() {};
            this.get = function() {};
            this.query = function() {};
            this.refresh = function() {};
        };
        translate = function(message) {
            return message;
        };

        $scope.contentHost = new ContentHost({
            uuid: 12345,
            host: {id: 10},
            subscriptions: [{id: 1, quantity: 11}, {id: 2, quantity: 22}]
        });

        
        $controller('ContentHostBaseSubscriptionsController', {
            $scope: $scope,
            $location: $location,
            translate: translate,
            CurrentOrganization: 'organization',
            Subscription: Subscription,
            ContentHost: ContentHost,
            HostSubscription: HostSubscription,
            Nutupane: Nutupane
        });
    }));

    it("allows auto attaching subscriptions to the content host", function() {
        spyOn(HostSubscription, 'autoAttach');
        $scope.autoAttachSubscriptions();
        expect(HostSubscription.autoAttach).toHaveBeenCalledWith({id: $scope.contentHost.host.id}, jasmine.any(Function), jasmine.any(Function));
    });
});
