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
    // console.log("here we go");
    flightPath.setMap(map);
  }

  var citymap = {};
  for (var i in cities) {
    citymap[i] = {
      center: new google.maps.LatLng(cityCoords[i]["lat"], cityCoords[i]["lng"]),
      population: cities[i] * 5000
    }
  }
  var cityCircle;

  for (var city in citymap) {
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