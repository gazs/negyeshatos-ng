

client_ids =
  'localhost:3000': 'LKA10PKSU3VSYT1IONJK53LUAEEZQJQEZLZFTVG13K15FSWR'
  'negyeshatos.com': 'TR01LUT4VNRMYIOUBL0IG214MMUDBL3K0E0O14JTVTBBSJOP'


$(document).ready ->
  # models
  class POI extends Backbone.Model
    setLocation: (p) ->
      geokod p, (result) =>
        @set
          'name': undefined
          'location':
            'address':  result.formatted_address
            'lat':      result.geometry.location.lat()
            'lng':      result.geometry.location.lng()
            'accuracy': p.accuracy
    setAccuracy: (acc) ->
      @set
        'location':
          'address': @getAddress()
          'lat': @getLat()
          'lng': @getLng()
          'accuracy': acc
      
    getLat: ->
      @get('location').lat
    getLng: ->
      @get('location').lng
    getAddress: ->
      @get('name') || @get('location').address
    getAccuracy: ->
      @get('location').accuracy
    getLocationArr: ->
      [@getLat(), @getLng()]
    getLocationString: ->
      @getLat() + ',' + @getLng()
    GlatLng: (offsetLat=0, offsetLng=0) ->
      new google.maps.LatLng @getLat() + offsetLat, @getLng() + offsetLng

  # collections

  class POIs extends Backbone.Collection
    model: POI

  class Venues extends POIs
    url: "https://api.foursquare.com/v2/checkins/recent?oauth_token=#{localStorage.token}&callback=?"
    parse: (json) ->
      if json.meta.code is 200
        venyuz = []
        _(json.response.recent).map (checkin) ->
          if checkin.type is 'checkin'
            try
              venyu = _(venyuz).detect (v) ->
                return v.name is checkin.venue.name
              venyu.here.push checkin.user
              if venyu.lastSeen < checkin.createdAt
                venyu.lastSeen = checkin.createdAt
            catch e
              venyuz.push
                name: checkin.venue.name
                location: checkin.venue.location
                here: [checkin.user]
                lastSeen: checkin.createdAt
        venyuz
      else
        alert 'foursquare hiba'


  # views

  class VenueView extends Backbone.View
    #el kell még bele
    tagName: 'li'
    className: 'venue'
    template: _.template($('#venueTemplate').html())
    events:
      'click': 'action'
      'mousedown': 'toggle' #TODO: nem lehet ezt kevésbé redundánsan?
      'mouseup': 'toggle'
      'touchstart': 'toggle'
      'touchend': 'toggle'
    toggle: ->
      $(@el).toggleClass 'clicked'
    action: ->
      _.extend app.idemegyek, @model
      window.location.hash = "utvonal"
    initialize: ->
      _.bindAll this, 'render'
    render: ->
      $(@el).html(@template(@model.toJSON()))
      this

  class VenueList extends Backbone.View
    el: $('#venuesList')
    initialize: ->
      _.bindAll this, 'render'
      @model.bind 'refresh', @render
    addVenueToList: (v) ->
      venue = new VenueView
        model: v
      @.$('#venuesList ul').append(venue.render().el)
    render: ->
      $(@el).html("<ul id='venues'></ul>")
      @model.each(@addVenueToList)
      $('time.timeago').timeago()
      @

  # {map: map}
  class Marker extends Backbone.View
    initialize: (options) ->
      _.bindAll @, 'render'
      @model.bind 'change', @render
      @map = options.map
      @marker = new google.maps.Marker
        map: @map
        draggable: true
      google.maps.event.addListener @marker, 'dragend', (event) =>
        @model.setLocation
          lat:  event.latLng.lat()
          lng:  event.latLng.lng()
    render: ->
      @marker.setPosition @model.GlatLng()
      @marker.setTitle @model.getAddress()

  class MyLocationMarker extends Marker
    initialize: (options) ->
      @markerImage = new google.maps.MarkerImage(
        'img/potty.png'
        new google.maps.Size(16,16)
        new google.maps.Point(0,0)
        new google.maps.Point(5,5)
      )
      super options
    render: ->
      @marker.setIcon @markerImage
      #if @model.getAccuracy()
        #@circle = new google.maps.Circle
          #map: @map
          #radius: @model.getAccuracy()
          #fillColor: '#d4e1f8'
          #strokeWeight: 2
          #strokeColor: '#9cbff8'
        #@circle.bindTo 'center', @marker, 'position'
        #google.maps.event.addListener @marker, 'dragend', (event) =>
          #@model.setAccuracy null
      try
        if @map.getBounds().contains @model.GlatLng()
          @map.setCenter @model.GlatLng()
      catch e
        console.error e
      super

  class DestinationMarker extends Marker
    initialize: (options) ->
      super(options)
    render: ->
      try
        @infobubble.close()
      catch e
        true

      @infobubble = new InfoBubble
        content: "<a href='#utvonal'>#{@model.getAddress()}</a>"
        padding: 10
        backgroundColor: 'rgb(57,57,57)'
        maxwidth:'300px'
        arrowSize: 10
        hideCloseButton: true
        backgroundClassName: 'phoney'
        disableAutoPan: true
      @infobubble.open @map, @marker
      google.maps.event.addListener @marker, 'dragstart', (event) =>
        @infobubble.close()
      google.maps.event.addListener @marker, 'dragend', (event) =>
        #@infobubble.open @map, @marker
        @infobubble.setContent "<a href='#utvonal'>#{@model.getAddress()}</a>"
      @marker.setIcon('img/pin.png')
      super

  class Map extends Backbone.View
    mapId: 'map_canvas'
    initialize: ->
      _.bindAll @, 'render'
      @map = new google.maps.Map document.getElementById(@mapId),
        center: @collection.at(0).GlatLng()
        zoom: 13
        mapTypeId: google.maps.MapTypeId.ROADMAP
      @mylocationmarker = new MyLocationMarker
        model: app.ittvagyok
        map: @map
      @destinationmarker = new DestinationMarker
        model: app.idemegyek
        map: @map
      google.maps.event.addListener @map, 'click', (event) =>
        @destinationmarker.model.setLocation
          lat:  event.latLng.lat()
          lng:  event.latLng.lng()
      $('#' + @mapId).css
        height: window.innerHeight - 48 + 'px'
      $(window).bind (if 'onorientation' in window then 'orientationchange' else 'resize'), =>
        $('#' + @mapId).css
          height: window.innerHeight - 48 + 'px' #TODO: lehet ezt dryabbul?
    render: ->
      @mylocationmarker.render()
      try
        @destinationmarker.render()

  class LocationInput extends Backbone.View
    initialize: ->
      _.bindAll @, 'render', 'updateDestination', 'getRoute'
      @model.bind 'change', @render
      #@model.bind 'change', @getRoute
    render: ->
      $(@el).find('input').val(@model.getAddress())
    events:
      submit: 'updateLocation'
    updateLocation: ->
      @model.setLocation
        address: $(@el).find('input').val()
      window.location.hash = 'utvonal'

  # el
  class LocationDisplay extends Backbone.View
    initialize: ->
      _.bindAll @, 'render'
      @model.bind 'change', @render
    events:
      'click': 'edit'
    render: ->
      $(@el).html(@model.getAddress())
    edit: ->
      newaddress = prompt 'hol vagy?', @model.getAddress()
      @model.setLocation({address:newaddress}) if newaddress


  class Directions extends Backbone.View
    el: $("#utvonaldoboz")
    template: _.template($('#routeTemplate').html())
    initialize: ->
    render: ->
      #delete localStorage.utvonal
      planRoute {
        'from': @collection.at(0).getLocationArr()
        'to': @collection.at(1).getLocationArr()
      }, (route) =>
        $(@el).html @template
          name: @collection.at(1).getAddress()
          route: route.m_arrMains[0]
        pageLoading(1)
        mozogj "#masodiklepes"
        localStorage.utvonal = $(@el).html()
      , (error) ->
        alert('oda már nem jár a bkv')
        delete localStorage.utvonal
        pageLoading(1)


  # controllers
  class Controller extends Backbone.Controller
    routes:
      '': 'foursquareFriends'
      'access_token=:token': 'saveToken'
      'error=:err': 'foursquareError'
      'deleteToken': 'deleteToken'
      'barataim': 'foursquareFriends'
      'terkep': 'map'
      'utvonal': 'bkvRoute'
    saveToken: (token) ->
      localStorage.token = token
      app.venues.url = app.venues.url.replace 'undefined', token
      window.location.hash = 'barataim'
    deleteToken: ->
      delete localStorage.token
      window.location.hash = ''
    foursquareError: (err) ->
      alert err
      window.location.hash = ''
    foursquareFriends: ->
      mozogj '#elsolepes' #todo: jó irányba legyen a mozgás
      if debug? or localStorage.token
        pageLoading()
        app.venues.fetch
          success: -> pageLoading("done")
      else
        try
          $("#foursquare").html _.template $('#loginTemplate').html(), 
          client_id: client_ids[window.location.host]
        catch e
          alert "nem találtam megfelelő foursquare kulcsot."
    map: ->
      mozogj '#map'
      # hackish
      app.terkepnezet ||= new Map
        collection: app.ketpoi
      unless app.terkepnezet.mylocationmarker.marker.getPosition()
        app.terkepnezet.render()
    bkvRoute: ->
      try
        app.dirview.render()
        pageLoading()
      catch e
        if localStorage.utvonal?
          console.log("van útvonal cache-ben")
          $('#utvonaldoboz').html localStorage.utvonal
          mozogj '#masodiklepes'
        else
          window.location.hash = "#"



  # etc
  # ---
  #
  window.goldenRatio = (aplusb) ->
    (aplusb - aplusb/1.6803)

  window.pageLoading = (done) ->
    if done?
      document.body.removeChild document.getElementById 'a'
    else
      loadingtext = $('<div class="loading" id="a"><img src="img/loading.gif"></div>')
      loadingtext.css
        'position':'absolute'
        'left': $('body').width()/2 - 30 + 'px'
        'top': window.pageYOffset + goldenRatio(window.innerHeight) + 'px'
      $('body').append loadingtext

  window.historyStack = []
  window.mozogj = (toId) ->
    # balról jobbra
    elrendezes = ['#elsolepes', '#map', '#masodiklepes']
    from = $('.current').first()

    fromId = '#' + from.attr 'id'
    # fixme: nem kezeli azt az esetet, ha nincs ilyen id.
    if 0 < elrendezes.indexOf(toId) - elrendezes.indexOf(fromId)
      #jobbra
      $(from).removeClass('current').addClass('reverse')
      $(toId).addClass('current')
    else
      #balra
      $(from).removeClass('current')
      $(toId).removeClass('reverse').addClass('current')


  window.app = {}
  app.ittvagyok= new POI
    location:
      address: '()'
      lat: 47.494319
      lng: 19.059984
  app.idemegyek= new POI()
  app.ketpoi= new POIs [app.ittvagyok, app.idemegyek]
  app.venues= new Venues()
  app.venueslist= new VenueList
    model: app.venues
  app.dirview= new Directions
    collection: app.ketpoi
  app.ittvagyokdoboz= new LocationDisplay
    el: $('#ittvagyok')
    model: app.ittvagyok
  app.idemegyekdoboz= new LocationInput
    el: $('#quickbox')
    model: app.idemegyek
  app.controller= new Controller()

  Backbone.history.start()

  if $.os.ios
    $('body').addClass('ios')
  if $.os.android
    $('body').addClass('android')


  navigator.geolocation.getCurrentPosition(
    (position) ->
      app.ittvagyok.setLocation
        lat: position.coords.latitude
        lng: position.coords.longitude
        accuracy: position.coords.accuracy
    (error) ->
      app.ittvagyokdoboz.edit()
    {enableHighAccuracy: true}
  )
  
  window.applicationCache.addEventListener 'updateReady', ->
    if confirm 'Frissítés elérhető az alkalmazáshoz. Töltsem le most?'
      window.location.reload()
  , false

