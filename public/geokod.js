// megadandó paraméterek: vagy lat & lng, vagy address 
var geokod = function(params, callback) {
  try {
  var koder = new google.maps.Geocoder();
  var latLng  = params.lat ? 
     new google.maps.LatLng(params.lat, params.lng) : undefined;

  koder.geocode({
      language: "hu",
      region: "hu",
      bounds: params.address ? new google.maps.LatLngBounds(
        //// ezek biza Pest határai Szergej és Larry szerint
        new google.maps.LatLng(47.3515010, 18.9251690), 
        new google.maps.LatLng(47.6133620, 19.3339160)) : undefined,
      address: params.address,
      latLng: latLng
    },
    function (result, status) {
      callback(result[0]);
    });
  } catch(e) {
    console.error(e);
  }
}
