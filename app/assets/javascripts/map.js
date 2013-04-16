function create() {
  // console.log(gon.cities);
  // console.log(gon.cityCoords);
  // console.log(gon.coordinates);
  cities = JSON.parse(gon.cities);
  cityCoords = JSON.parse(gon.cityCoords);
  cityMappings = JSON.parse(gon.cityMappings);
  var myLatLng = new google.maps.LatLng(0, -180);
  var mapOptions = {
    zoom: 3,
    center: myLatLng,
    mapTypeId: google.maps.MapTypeId.TERRAIN
  };
  var map = new google.maps.Map(document.getElementById("map-canvas"), mapOptions);
  var flightPlanCoordinates;
  var flightPath;
  for (var i in cityMappings) {
    names = JSON.parse(i);
    fromName = names[0];
    toName = names[1];
    flightPlanCoordinates = [
      new google.maps.LatLng(cityCoords[fromName]["lat"], cityCoords[fromName]["lng"]),
      new google.maps.LatLng(cityCoords[toName]["lat"], cityCoords[toName]["lng"])
    ];
    flightPath = new google.maps.Polyline({
      path: flightPlanCoordinates,
      strokeColor: "#FF0000",
      strokeOpacity: 1.0,
      strokeWeight: cityMappings[i] * .1
    });
    console.log("here we go");
    flightPath.setMap(map);
  }
  // var flightPlanCoordinates = [
  //   new google.maps.LatLng(37.772323, -122.214897),
  //   new google.maps.LatLng(-27.46758, 153.027892)
  // ];
  // var flightPath = new google.maps.Polyline({
  //   path: flightPlanCoordinates,
  //   strokeColor: "#FF0000",
  //   strokeOpacity: 1.0,
  //   strokeWeight: 1
  // });
  // flightPath.setMap(map);

  var citymap = {};
  for (var i in cities) {
    citymap[i] = {
      center: new google.maps.LatLng(cityCoords[i]["lat"], cityCoords[i]["lng"]),
      population: cities[i] * 10000
    }
  }
  // citymap['chicago'] = {
  //   center: new google.maps.LatLng(41.878113, -87.629798),
  //   population: 10000
  // };
  // citymap['newyork'] = {
  //   center: new google.maps.LatLng(40.714352, -74.005973),
  //   population: 10000
  // };
  // citymap['losangeles'] = {
  //   center: new google.maps.LatLng(34.052234, -118.243684),
  //   population: 100000
  // }
  var cityCircle;

  for (var city in citymap) {
    // Construct the circle for each value in citymap. We scale population by 20.
    var populationOptions = {
      strokeColor: "#FF0000",
      strokeOpacity: 0.8,
      strokeWeight: 1,
      fillColor: "#FF0000",
      fillOpacity: 0.35,
      map: map,
      center: citymap[city].center,
      radius: citymap[city].population
    };
    cityCircle = new google.maps.Circle(populationOptions);
  }
}