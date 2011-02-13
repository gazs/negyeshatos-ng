(function() {
  var client_ids;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
  window.applicationCache.addEventListener('updateready', function() {
    return window.location.reload();
  }, false);
  client_ids = {
    'localhost:3000': 'LKA10PKSU3VSYT1IONJK53LUAEEZQJQEZLZFTVG13K15FSWR',
    'negyeshatos.com': 'TR01LUT4VNRMYIOUBL0IG214MMUDBL3K0E0O14JTVTBBSJOP'
  };
  $(document).ready(function() {
    var Controller, DestinationMarker, Directions, LocationDisplay, LocationInput, Map, Marker, MyLocationMarker, POI, POIs, VenueList, VenueView, Venues;
    POI = (function() {
      function POI() {
        POI.__super__.constructor.apply(this, arguments);
      }
      __extends(POI, Backbone.Model);
      POI.prototype.setLocation = function(p) {
        return geokod(p, __bind(function(result) {
          return this.set({
            'name': void 0,
            'location': {
              'address': result.formatted_address,
              'lat': result.geometry.location.lat(),
              'lng': result.geometry.location.lng(),
              'accuracy': p.accuracy
            }
          });
        }, this));
      };
      POI.prototype.getLat = function() {
        return this.get('location').lat;
      };
      POI.prototype.getLng = function() {
        return this.get('location').lng;
      };
      POI.prototype.getAddress = function() {
        return this.get('name') || this.get('location').address;
      };
      POI.prototype.getAccuracy = function() {
        return this.get('location').accuracy;
      };
      POI.prototype.getLocationArr = function() {
        return [this.getLat(), this.getLng()];
      };
      POI.prototype.getLocationString = function() {
        return this.getLat() + ',' + this.getLng();
      };
      POI.prototype.GlatLng = function(offsetLat, offsetLng) {
        if (offsetLat == null) {
          offsetLat = 0;
        }
        if (offsetLng == null) {
          offsetLng = 0;
        }
        return new google.maps.LatLng(this.getLat() + offsetLat, this.getLng() + offsetLng);
      };
      return POI;
    })();
    POIs = (function() {
      function POIs() {
        POIs.__super__.constructor.apply(this, arguments);
      }
      __extends(POIs, Backbone.Collection);
      POIs.prototype.model = POI;
      return POIs;
    })();
    Venues = (function() {
      function Venues() {
        Venues.__super__.constructor.apply(this, arguments);
      }
      __extends(Venues, POIs);
      Venues.prototype.url = "https://api.foursquare.com/v2/checkins/recent?oauth_token=" + localStorage.token + "&display=touch&callback=?";
      Venues.prototype.parse = function(json) {
        var venyuz;
        if (json.meta.code === 200) {
          venyuz = [];
          _(json.response.recent).map(function(checkin) {
            var venyu;
            if (checkin.type === 'checkin') {
              try {
                venyu = _(venyuz).detect(function(v) {
                  return v.name === checkin.venue.name;
                });
                venyu.here.push(checkin.user);
                if (venyu.lastSeen < checkin.createdAt) {
                  return venyu.lastSeen = checkin.createdAt;
                }
              } catch (e) {
                return venyuz.push({
                  name: checkin.venue.name,
                  location: checkin.venue.location,
                  here: [checkin.user],
                  lastSeen: checkin.createdAt
                });
              }
            }
          });
          return venyuz;
        } else {
          return alert('foursquare hiba');
        }
      };
      return Venues;
    })();
    VenueView = (function() {
      function VenueView() {
        VenueView.__super__.constructor.apply(this, arguments);
      }
      __extends(VenueView, Backbone.View);
      VenueView.prototype.tagName = 'li';
      VenueView.prototype.className = 'venue';
      VenueView.prototype.template = _.template($('#venueTemplate').html());
      VenueView.prototype.events = {
        'click': 'action'
      };
      VenueView.prototype.toggle = function() {
        return $(this.el).toggleClass('clicked');
      };
      VenueView.prototype.action = function() {
        _.extend(app.idemegyek, this.model);
        return window.location.hash = "utvonal";
      };
      VenueView.prototype.initialize = function() {
        return _.bindAll(this, 'render');
      };
      VenueView.prototype.render = function() {
        $(this.el).html(this.template(this.model.toJSON()));
        return this;
      };
      return VenueView;
    })();
    VenueList = (function() {
      function VenueList() {
        VenueList.__super__.constructor.apply(this, arguments);
      }
      __extends(VenueList, Backbone.View);
      VenueList.prototype.el = $('#venuesList');
      VenueList.prototype.initialize = function() {
        _.bindAll(this, 'render');
        return this.collection.bind('refresh', this.render);
      };
      VenueList.prototype.addVenueToList = function(v) {
        var venue;
        venue = new VenueView({
          model: v
        });
        return this.$('#venuesList ul').append(venue.render().el);
      };
      VenueList.prototype.render = function() {
        var myscroller;
        $(this.el).html("<div id='scroller'><ul id='venues'></ul></div>");
        $(this.el).css({
          height: (window.innerHeight - 78) + 'px'
        });
        myscroller = new iScroll('scroller', {
          desktopCompatibility: false
        });
        document.addEventListener('touchmove', function(e) {
          return e.preventDefault();
        }, false);
        this.collection.each(this.addVenueToList);
        $('time.timeago').timeago();
        return this;
      };
      return VenueList;
    })();
    Marker = (function() {
      function Marker() {
        Marker.__super__.constructor.apply(this, arguments);
      }
      __extends(Marker, Backbone.View);
      Marker.prototype.initialize = function(options) {
        _.bindAll(this, 'render');
        this.model.bind('change', this.render);
        this.map = options.map;
        this.marker = new google.maps.Marker({
          map: this.map,
          draggable: true
        });
        return google.maps.event.addListener(this.marker, 'dragend', __bind(function(event) {
          return this.model.setLocation({
            lat: event.latLng.lat(),
            lng: event.latLng.lng()
          });
        }, this));
      };
      Marker.prototype.render = function() {
        this.marker.setPosition(this.model.GlatLng());
        return this.marker.setTitle(this.model.getAddress());
      };
      return Marker;
    })();
    MyLocationMarker = (function() {
      function MyLocationMarker() {
        MyLocationMarker.__super__.constructor.apply(this, arguments);
      }
      __extends(MyLocationMarker, Marker);
      MyLocationMarker.prototype.initialize = function(options) {
        this.markerImage = new google.maps.MarkerImage('img/potty.png', new google.maps.Size(16, 16), new google.maps.Point(0, 0), new google.maps.Point(5, 5));
        return MyLocationMarker.__super__.initialize.call(this, options);
      };
      MyLocationMarker.prototype.render = function() {
        this.marker.setIcon(this.markerImage);
        try {
          if (this.map.getBounds().contains(this.model.GlatLng())) {
            this.map.setCenter(this.model.GlatLng());
          }
        } catch (e) {

        }
        return MyLocationMarker.__super__.render.apply(this, arguments);
      };
      return MyLocationMarker;
    })();
    DestinationMarker = (function() {
      function DestinationMarker() {
        DestinationMarker.__super__.constructor.apply(this, arguments);
      }
      __extends(DestinationMarker, Marker);
      DestinationMarker.prototype.initialize = function(options) {
        return DestinationMarker.__super__.initialize.call(this, options);
      };
      DestinationMarker.prototype.render = function() {
        try {
          this.infobubble.close();
        } catch (e) {
          true;
        }
        this.infobubble = new InfoBubble({
          content: "<a href='#utvonal'>" + (this.model.getAddress()) + "</a>",
          padding: 10,
          backgroundColor: 'rgb(57,57,57)',
          maxwidth: '300px',
          arrowSize: 10,
          hideCloseButton: true,
          backgroundClassName: 'phoney',
          disableAutoPan: true
        });
        this.infobubble.open(this.map, this.marker);
        google.maps.event.addListener(this.marker, 'dragstart', __bind(function(event) {
          return this.infobubble.close();
        }, this));
        google.maps.event.addListener(this.marker, 'dragend', __bind(function(event) {
          return this.infobubble.setContent("<a href='#utvonal'>" + (this.model.getAddress()) + "</a>");
        }, this));
        this.marker.setIcon('img/pin.png');
        return DestinationMarker.__super__.render.apply(this, arguments);
      };
      return DestinationMarker;
    })();
    Map = (function() {
      function Map() {
        Map.__super__.constructor.apply(this, arguments);
      }
      __extends(Map, Backbone.View);
      Map.prototype.mapId = 'map_canvas';
      Map.prototype.initialize = function() {
        _.bindAll(this, 'render');
        this.map = new google.maps.Map(document.getElementById(this.mapId), {
          center: this.collection.at(0).GlatLng(),
          zoom: 13,
          mapTypeId: google.maps.MapTypeId.ROADMAP
        });
        this.mylocationmarker = new MyLocationMarker({
          model: app.ittvagyok,
          map: this.map
        });
        this.destinationmarker = new DestinationMarker({
          model: app.idemegyek,
          map: this.map
        });
        google.maps.event.addListener(this.map, 'click', __bind(function(event) {
          return this.destinationmarker.model.setLocation({
            lat: event.latLng.lat(),
            lng: event.latLng.lng()
          });
        }, this));
        $('#' + this.mapId).css({
          height: window.innerHeight - 48 + 'px'
        });
        return $(window).bind((__indexOf.call(window, 'onorientation') >= 0 ? 'orientationchange' : 'resize'), __bind(function() {
          return $('#' + this.mapId).css({
            height: window.innerHeight - 48 + 'px'
          });
        }, this));
      };
      Map.prototype.render = function() {
        this.mylocationmarker.render();
        try {
          return this.destinationmarker.render();
        } catch (_e) {}
      };
      return Map;
    })();
    LocationInput = (function() {
      function LocationInput() {
        LocationInput.__super__.constructor.apply(this, arguments);
      }
      __extends(LocationInput, Backbone.View);
      LocationInput.prototype.initialize = function() {
        _.bindAll(this, 'render', 'updateLocation');
        return this.model.bind('change', this.render);
      };
      LocationInput.prototype.render = function() {
        return $(this.el).find('input').val(this.model.getAddress());
      };
      LocationInput.prototype.events = {
        submit: 'updateLocation'
      };
      LocationInput.prototype.updateLocation = function() {
        this.model.setLocation({
          address: $(this.el).find('input').val()
        });
        return window.location.hash = 'utvonal';
      };
      return LocationInput;
    })();
    LocationDisplay = (function() {
      function LocationDisplay() {
        LocationDisplay.__super__.constructor.apply(this, arguments);
      }
      __extends(LocationDisplay, Backbone.View);
      LocationDisplay.prototype.initialize = function() {
        _.bindAll(this, 'render');
        return this.model.bind('change', this.render);
      };
      LocationDisplay.prototype.events = {
        'click': 'edit'
      };
      LocationDisplay.prototype.render = function() {
        return $(this.el).html(this.model.getAddress());
      };
      LocationDisplay.prototype.edit = function() {
        var newaddress;
        newaddress = prompt('hol vagy?', this.model.getAddress());
        if (newaddress) {
          return this.model.setLocation({
            address: newaddress
          });
        }
      };
      return LocationDisplay;
    })();
    Directions = (function() {
      function Directions() {
        Directions.__super__.constructor.apply(this, arguments);
      }
      __extends(Directions, Backbone.View);
      Directions.prototype.el = $("#utvonaldoboz");
      Directions.prototype.template = _.template($('#routeTemplate').html());
      Directions.prototype.initialize = function() {};
      Directions.prototype.render = function() {
        return planRoute({
          'from': this.collection.at(0).getLocationArr(),
          'to': this.collection.at(1).getLocationArr()
        }, __bind(function(route) {
          $(this.el).html(this.template({
            name: this.collection.at(1).getAddress(),
            route: route.m_arrMains[0]
          }));
          pageLoading(1);
          mozogj("#masodiklepes");
          return localStorage.utvonal = $(this.el).html();
        }, this), function(error) {
          alert('oda már nem jár a bkv');
          delete localStorage.utvonal;
          return pageLoading(1);
        });
      };
      return Directions;
    })();
    Controller = (function() {
      function Controller() {
        Controller.__super__.constructor.apply(this, arguments);
      }
      __extends(Controller, Backbone.Controller);
      Controller.prototype.routes = {
        '': 'foursquareFriends',
        'access_token=:token': 'saveToken',
        'error=:err': 'foursquareError',
        'deleteToken': 'deleteToken',
        'terkep': 'map',
        'utvonal': 'bkvRoute'
      };
      Controller.prototype.saveToken = function(token) {
        localStorage.token = token;
        app.venues.url = app.venues.url.replace('undefined', token);
        return window.location.hash = '';
      };
      Controller.prototype.deleteToken = function() {
        delete localStorage.token;
        return window.location.hash = '';
      };
      Controller.prototype.foursquareError = function(err) {
        alert(err);
        return window.location.hash = '#deleteToken';
      };
      Controller.prototype.foursquareFriends = function() {
        mozogj('#elsolepes');
        if ((typeof debug != "undefined" && debug !== null) || localStorage.token) {
          pageLoading();
          return app.venues.fetch({
            success: function() {
              return pageLoading("done");
            }
          });
        } else {
          try {
            return $("#foursquare").html(_.template($('#loginTemplate').html(), {
              client_id: client_ids[window.location.host]
            }));
          } catch (e) {
            return alert("nem találtam megfelelő foursquare kulcsot.");
          }
        }
      };
      Controller.prototype.map = function() {
        mozogj('#map');
        app.terkepnezet || (app.terkepnezet = new Map({
          collection: app.ketpoi
        }));
        if (!app.terkepnezet.mylocationmarker.marker.getPosition()) {
          return app.terkepnezet.render();
        }
      };
      Controller.prototype.bkvRoute = function() {
        try {
          app.dirview.render();
          return pageLoading();
        } catch (e) {
          if (localStorage.utvonal != null) {
            $('#utvonaldoboz').html(localStorage.utvonal);
            return mozogj('#masodiklepes');
          } else {
            return window.location.hash = "#";
          }
        }
      };
      return Controller;
    })();
    window.goldenRatio = function(aplusb) {
      return aplusb - aplusb / 1.6803;
    };
    window.pageLoading = function(done) {
      var loadingtext;
      if (done != null) {
        return document.body.removeChild(document.getElementById('a'));
      } else {
        loadingtext = $('<div class="loading" id="a"><img src="img/loading.gif"></div>');
        loadingtext.css({
          'position': 'absolute',
          'left': $('body').width() / 2 - 30 + 'px',
          'top': window.pageYOffset + goldenRatio(window.innerHeight) + 'px'
        });
        return $('body').append(loadingtext);
      }
    };
    window.mozogj = function(toId) {
      var elrendezes, from, fromId;
      elrendezes = ['#elsolepes', '#map', '#masodiklepes'];
      from = $('.current').first();
      fromId = '#' + from.attr('id');
      if (0 < elrendezes.indexOf(toId) - elrendezes.indexOf(fromId)) {
        $(from).removeClass('current').addClass('reverse');
        return $(toId).addClass('current');
      } else {
        $(from).removeClass('current');
        return $(toId).removeClass('reverse').addClass('current');
      }
    };
    window.app = {};
    app.ittvagyok = new POI({
      location: {
        address: '()',
        lat: 47.494319,
        lng: 19.059984
      }
    });
    app.idemegyek = new POI();
    app.ketpoi = new POIs([app.ittvagyok, app.idemegyek]);
    app.venues = new Venues();
    app.venueslist = new VenueList({
      collection: app.venues
    });
    app.dirview = new Directions({
      collection: app.ketpoi
    });
    app.ittvagyokdoboz = new LocationDisplay({
      el: $('#ittvagyok'),
      model: app.ittvagyok
    });
    app.idemegyekdoboz = new LocationInput({
      el: $('#quickbox'),
      model: app.idemegyek
    });
    app.controller = new Controller();
    Backbone.history.start();
    if ($.os.ios) {
      $('body').addClass('ios');
    }
    if ($.os.android) {
      $('body').addClass('android');
    }
    return navigator.geolocation.getCurrentPosition(function(position) {
      return app.ittvagyok.setLocation({
        lat: position.coords.latitude,
        lng: position.coords.longitude,
        accuracy: position.coords.accuracy
      });
    }, function(error) {
      return app.ittvagyokdoboz.edit();
    }, {
      enableHighAccuracy: true,
      timeout: 20000
    });
  });
}).call(this);
