var ASTORIA = [47.496299,19.059992],
    NORMAFA = [47.542403,19.042879];

// ezekre a változókra hivatkozik az útvonaltervező a válaszában:
var g_arrAddressList = [],
    g_Route = [],
    kamu = function () {
      return true;
    }, 
    ShowAddress = kamu,
     FillAddress = kamu,
     FillRoute = kamu, 
     HereIam = kamu

 
var planRoute = function (params, callback, error) {
     // params:
     //  from: [lat,lng],
     //  to: [lat,lng],
     //  maxwalkdistance: 500,
     //  time: "YYYY/MM/DD/HH:MM"
     try {
       var eov1 = ll2eov(params.from),
       eov2 = ll2eov(params.to);
     }
     catch(err) {
       // frankly my dear, i don't give a damn.
       if (error) {
         error(err);
       }
       return false;
     }

     // a jQuery ajax.js-éből ollózva. önállóság fuckyeah.
     var script = document.createElement("script"),
     head = document.getElementsByTagName("head")[0] || document.documentElement,
     data = {
       "Command": "Traffic",
       "sessionID": "1449_2119731_5134837", 
       "iCommandID": 1640,
       "appID": "bkv",
       "lang": "hu",
       "arrIDs": "0|1",
       "arrX": [eov1[0], eov2[0]].join("|"), 
       "arrY": [eov1[1], eov2[1]].join("|"),
       "arrParsed": "undefined|undefined", 
       "strTrafficType": "bkv",
       "iCarOptim": 0,
       "iBkvOptim": 0,
       "strTime": params.time || "2010/10/24/19:23", 
       "iMaxWalkDist": params.maxwalkdistance || 500
     },
     urlParameters = [];

     for (key in data) {
       if (data.hasOwnProperty(key)) {
         urlParameters.push(encodeURI(key + "=" + data[key]))
       }
     }
     endpoint = "http://bkv.utvonalterv.hu/NoTile.ashx?";
     script.src = endpoint + urlParameters.join("&");
     script.async = "async";
     script.onerror = function(err) {
       alert("nem megy a bkv útvonaltervező. (valószínűleg nem az én hibám, de izé, bocs)");
     }
     script.onload = script.onreadystatechange = function(_, isAbort) {
       if ( !script.readyState || /loaded|complete/.test(script.readyState) ) {
         script.onload = script.onreadystatechange = null;
         if (head && script.parentNode) {
           head.removeChild(script);
         }
         script = undefined;
         if (!isAbort) {
           // valójában már nem is kéne callbackelnem, mi? mehetne simán ide a cucc
           callback(g_Route);
         }
       }
     }
     head.insertBefore(script, head.firstChild)
   };

var ll2eov = function (coords) {
  // ez a bkv útvonaltervezőjének baltával szétszedett kódja
  // ha nem is olvashatóvá, de áttekinthetővé téve
  var x = coords[1],
      y = coords[0];
  if (x > 18.67 && x < 19.73 && y > 47.07 && y < 47.78 &&
      !isNaN(x) && !isNaN(y)) { 
      var rad, rk, k2, exc, Lk, R, red, fk, FI, LA, f, l;
      rad = Math.PI / 180,
      rk1 = 1.0031100083,
      k2 = 1.0007197049,
      exc = 0.0818205679,
      Lk = 19.0485718 * rad,
      R = 6379743,
      red = 0.99993,
      fk = 47.1 * rad,
      FI = y * rad,
      LA = x * rad,
      f = (Math.atan(rk1 * Math.pow(Math.tan(Math.PI / 4 + FI / 2), k2) *
                 Math.pow((1 - exc * Math.sin(FI)) / (1 + exc * Math.sin(FI)), 
                 k2 * exc / 2)) - Math.PI / 4) * 2,
      l = (LA - Lk) * k2,
      eovxC = function (FI, LA) {
        return (R * red * Math.atan(Math.sin(l) / (Math.tan(f) * Math.sin(fk) + 
                Math.cos(l) * Math.cos(fk))) + 650000);
      },
      eovyC = function (FI, LA) {
        return (R / 2 * red * Math.log((1 + Math.cos(fk) * Math.sin(f) - 
                Math.sin(fk) * Math.cos(f) * Math.cos(l)) / (1 - Math.cos(fk) * 
                Math.sin(f) + Math.sin(fk) * Math.cos(f) * Math.cos(l))) + 
                200000);
      };
      x = Math.round(eovxC(FI, LA));
      y = Math.round(eovyC(FI, LA)); 
      return [x, y];
    }
    else { 
      throw "NemBudapestVagyRosszKoordinatak";
  }
} 
