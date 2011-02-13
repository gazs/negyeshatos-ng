#Négyeshatos
#==========
#


# A HTML5 ApplicationCache egészen... érdekes. Papíron tök jó, hogy viszonylag sok adatot tudunk
# a kliensen tárolni viszonylag megbízhatóan, cserébe viszont fájhat a fejünk az olyan események
# lekezelésével, hogy például mit kell csinálni, ó jaj, ha frissíteni akarod a cache-ben levő,
# illetve az onnna betöltött fájlokat. Long story short, ha a cache-frissítő kód rosszul van a
# becache-elt fájlban, nem fogod tudni meggyőzni sehogyse a makacs böngészőt arról, hogy legyen
# szíves elfelejteni a hibás fájlt és újratölteni azt, amiben kijavítottad már.
window.applicationCache.addEventListener 'updateready', ->
  window.location.reload()
, false

# Elméletileg, ha jól értem, nem biztonsági rés az, hogy ide simán behányom a Foursquare-től kapott
# azonosítókat, mivel ezek csak a megjelölt oldalon használhatóak fel (ha más a használt redirect_url,
# hibát dob a Foursquare. Szóval kényelem történik. Remélem nem szívom meg ezzel.
client_ids =
  'localhost:3000': 'LKA10PKSU3VSYT1IONJK53LUAEEZQJQEZLZFTVG13K15FSWR'
  'negyeshatos.com': 'TR01LUT4VNRMYIOUBL0IG214MMUDBL3K0E0O14JTVTBBSJOP'
  # 'negyeshatos.com': '5D10T01NV0LF3X54FS2AW5IVN0CE5UOGE2QF0VLHQZ3T4ORA' #4s-hatos.appspot-é, végső költözés után átírandó

$(document).ready ->
  # A POI a legalapabb egység. Minden POI: hol vagy, hová mész, mire böksz a térképen, mit választasz a listáról
  class POI extends Backbone.Model
    setLocation: (p) ->
      geokod p, (result) =>
        @set
          'name': undefined # különben ütközhet, ha az idemegyek poi egy venue-tól örökölt már nevet
          'location':
            'address':  result.formatted_address
            'lat':      result.geometry.location.lat()
            'lng':      result.geometry.location.lng()
            'accuracy': p.accuracy # ezzel tudnánk szép karikákat rajzolni, hogy milyen pontos a GPS
                                   # de sajnos egyelőre több gond van vele, mint amennyit megold, szal
                                   # ki van kommentelve
    # setAccuracy: (acc) ->
    #   @set
    #     'location':
    #       'address': @getAddress()
    #       'lat': @getLat()
    #       'lng': @getLng()
    #       'accuracy': acc
      
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

  # Collections
  # ===========

  # Van olyan, hogy több POI-t egy csokorba fogunk. Sima ügy.
  class POIs extends Backbone.Collection
    model: POI

  # És van olyan, hogy egy csokor POI-t a Foursquare-ről kérünk le. Sima ügy.
  class Venues extends POIs
    # és mi van, ha nincs localStorage.token? Emiatt később fog fájni a fejünk, lásd lennebb
    url: "https://api.foursquare.com/v2/checkins/recent?oauth_token=#{localStorage.token}&display=touch&callback=?"
    parse: (json) ->
      if json.meta.code is 200
        venyuz = []
        _(json.response.recent).map (checkin) ->
          # Van olyan checkin, ami nem is checkin, hanem pl shout. Ehhez nem tartozik latlng
          if checkin.type is 'checkin'
            # Van már ilyen venue? Frissítsd ki van itt & mikor jelentkeztek be utoljára
            try
              venyu = _(venyuz).detect (v) ->
                return v.name is checkin.venue.name
              venyu.here.push checkin.user
              if venyu.lastSeen < checkin.createdAt
                venyu.lastSeen = checkin.createdAt
            # Nincs? Add hozzá.
            catch e
              venyuz.push
                name: checkin.venue.name
                location: checkin.venue.location
                here: [checkin.user]
                lastSeen: checkin.createdAt
        venyuz
      else
        alert 'foursquare hiba'


  # Views
  # =====

  # Egy Venue csíkban megjelenítve
  # kell neki: @el, @model(POI)
  class VenueView extends Backbone.View
    tagName: 'li'
    className: 'venue'
    template: _.template($('#venueTemplate').html())
    events:
      'click': 'action'
      #'mousedown': 'toggle' #TODO: nem lehet ezt kevésbé redundánsan?
      #'mouseup': 'toggle'
      #'touchstart': 'toggle'
      #'touchend': 'toggle'
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

  # Több Venue listája
  # kell: @el, @collection(venues)
  class VenueList extends Backbone.View
    el: $('#venuesList')
    initialize: ->
      _.bindAll this, 'render'
      @collection.bind 'refresh', @render
    addVenueToList: (v) ->
      venue = new VenueView
        model: v
      @.$('#venuesList ul').append(venue.render().el)
    render: ->
      $(@el).html("<div id='scroller'><ul id='venues'></ul></div>")
      $(@el).css
        height: (window.innerHeight - 78) + 'px'
      alert window.innerHeight
      myscroller = new iScroll 'scroller',
        desktopCompatibility: true
      document.addEventListener 'touchmove', (e) ->
        e.preventDefault()
      , false
      @collection.each(@addVenueToList)
      $('time.timeago').timeago()
      @

  # Egy pötty egy térképen. Arrébbtehető, ha leteszed, frissíti a modelljének a location paramétereit
  # kell: @map, @model(poi)
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

  # Az a pötty a térképen, ami megmutatja, hol vagy. Annyiban különbözik a másiktól, hogy más ikonja van.
  # Tudná a GPS pontosságát is jelölni egy körrel, csak az több gondot okozott, mint amennyit megoldott.
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
  
  # Piros gombostű formájú marker, amit ha leraksz, infobubble-t nyit, benne a POI címével
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

  # Egy térkép, ami két markert bír el. Az első marker kék bogyó (itt vagy), a másik piros tű (ide mész)
  # Ha elfordítod a készüléket, átméretezi magát. (Ha nem teljes képernyőn van a térkép, a scroll események
  # csúnyáncsúnyán be tudnak kavarni!
  # @mapId, @collection(kétpoi)
  class Map extends Backbone.View
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

  # Form, benne egy (1) szöveginputtal, aminek a submitjekor beállítja a hozzá kapcsolódó modell helyparamétereit
  # @el(form), @model(poi)
  class LocationInput extends Backbone.View
    initialize: ->
      _.bindAll @, 'render', 'updateLocation'
      @model.bind 'change', @render
    render: ->
      $(@el).find('input').val(@model.getAddress())
    events:
      submit: 'updateLocation'
    updateLocation: ->
      @model.setLocation
        address: $(@el).find('input').val()
      window.location.hash = 'utvonal'

  # Szövegdoboz, amire 1. mutatja hol vagy 2. rákattintva felpattanó ablakban állíthatod, hol vagy
  # @el, @model(poi)
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

  # Ez gyakorlatilag a második lépés. Nem csinál sokat, meghívja a bkv-s segédcuccot, majd beleömleszti a sablonba a választ.
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


  # Controller
  # ==========

  class Controller extends Backbone.Controller
    routes:
      '': 'foursquareFriends'
      'access_token=:token': 'saveToken'
      'error=:err': 'foursquareError'
      'deleteToken': 'deleteToken'
      'terkep': 'map'
      'utvonal': 'bkvRoute'
    # Induláskor nem volt token, a Collection viszont már elkészült. Muszáj felülírnunk.
    saveToken: (token) ->
      localStorage.token = token
      app.venues.url = app.venues.url.replace 'undefined', token
      window.location.hash = ''
    deleteToken: ->
      delete localStorage.token
      window.location.hash = ''
    foursquareError: (err) ->
      alert err
      window.location.hash = '#deleteToken'
    foursquareFriends: ->
      mozogj '#elsolepes'
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
      # Ne csináld újra a térképet 
      app.terkepnezet ||= new Map
        mapId: 'map_canvas'
        collection: app.ketpoi
      # Ha nincs markerem, akkor ne próbáld átrakni sehova.
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

  # Aranymetszés. Figyeltétek, hogy Macen az alert ablakok nem pontosan középen vannak, hanem kicsit... odébb?
  # Aranymetszés. Elvileg ettől sokkal szebb és esztétikusabb lesz, ha ide rakom. Próbacseresznye.
  window.goldenRatio = (aplusb) ->
    (aplusb - aplusb/1.6803)

  #Loading spinner. Ez lesz ugye aranymetszés szerint elhelyezve.
  window.pageLoading = (done) ->
    if done?
      # Szerintem itt van egy zepto bug. Nem lehet simán azt mondani, hogy $('#a').remove(), de miért?
      # Fenébe a szintaktikus cukorral.
      document.body.removeChild document.getElementById 'a'
    else
      loadingtext = $('<div class="loading" id="a"><img src="img/loading.gif"></div>')
      loadingtext.css
        'position':'absolute'
        'left': $('body').width()/2 - 30 + 'px'
        'top': window.pageYOffset + goldenRatio(window.innerHeight) + 'px'
      $('body').append loadingtext

  # Csúnyán hardkódolt mozgásirányokkal. Az általánosabb megoldáshoz nincsen elég agysejtem.
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


  # TODO: ez így nem szép. Hogyan szép? Biztos van rá valami pattern vagy okosság vagy egyéb,
  # ehelyett ide beömlesztek mindent egy kupacba. De legalább csak egy változót szemetelek még bele
  # a globális térbe.
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
    collection: app.venues
  app.dirview= new Directions
    collection: app.ketpoi
  app.ittvagyokdoboz= new LocationDisplay
    el: $('#ittvagyok')
    model: app.ittvagyok
  app.idemegyekdoboz= new LocationInput
    el: $('#quickbox')
    model: app.idemegyek
  app.controller= new Controller()

  # Ha nincs ez, nem fog sose elindulni a hashtag varázs
  Backbone.history.start()

  # Ha neadj' valaha szeretnék device-specifikus css-t
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
    {enableHighAccuracy: true, timeout: 20000}
  )
  

