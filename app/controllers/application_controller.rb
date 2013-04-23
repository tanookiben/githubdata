class ApplicationController < ActionController::Base
  protect_from_forgery

  def find_users()
    require 'yajl'
    require 'zlib'
    require 'open-uri'
    client = Octokit::Client.new(:login => USERNAME, :password => PASSWORD)
    gz = open('http://data.githubarchive.org/2013-04-08-12.json.gz')
    js = Zlib::GzipReader.new(gz).read

    locations = ""
    push_event_count = 0
    link_count = 0
    userLocations = []
    Yajl::Parser.parse(js) do |event|
      if event["type"] != "PushEvent"
        next
      end

      actor = event["actor_attributes"]["login"]
      repository = event["repository"]
      owner = repository["owner"]

      if actor == owner
        next
      end

      actor_location = event["actor_attributes"]["location"]
      if actor_location.nil? || actor_location == ""
        next
      end
      begin
        puts owner
        owner_location = client.user(owner).location

        if owner_location.nil? || owner_location == ""
          next
        end

        if actor_location.downcase == owner_location.downcase
          next
        end
        # print "ACTOR LOCATION, ", actor_location, " ------- OWNER LOCATION, ", owner_location, "\n\n"
        userLocations << [actor_location, owner_location]
        link_count += 1
      rescue
        puts "error"
      end
    end
    return userLocations
  end

  def find_locations(array)
    #creates [name, Hash{lat => #, lng => #}]
    nameAndCoordinates = []
    array.each do |location|
      if Rails.env == "production"
        city = City.find(:all, conditions: ["name ILIKE ?", "#{location}"])
      else
        city = City.find(:all, conditions: ["name LIKE ?", "#{location}"])
      end
      if city.empty?
        search = Geocoder.search("#{location}")
        search.each do |place|
          begin
            type = place.data["address_components"][0]["types"][0]
            if type == "locality"
              name = place.data["address_components"][0]["long_name"]
              coordinates = place.geometry["location"]
              nameAndCoordinates << [name, coordinates]
              City.create(name: name, lat: coordinates["lat"], lng: coordinates["lng"])
              break
            else
              next
            end
          rescue
            puts "ERROR ERROR ERROR ERROR ERROR"
          end
        end
      else
        name = city.first.name
        coordinates = {"lat" => city.first.lat, "lng" => city.first.lng}
        nameAndCoordinates << [name, coordinates]
        break
      end
    end
    return nameAndCoordinates
  end

  def create_locations()
    userLocations = find_users()
    fixedLocations = []
    userLocations.each do |line|
      # print "USER LOCATIONS IN CREATE: ", line, "\n\n\n"
      pusher = line[0]
      owner = line[1]
      pusher = pusher.split(", ")
      owner = owner.split(", ")
      # print "PUSHER: ", pusher, "\n"
      # print "OWNER: ", owner, "\n\n"
      pusher_coordinates = find_locations(pusher)
      owner_coordinates = find_locations(owner)
      pusher_coordinates.each do |x|
        owner_coordinates.each do |y|
          if x[0].downcase == y[0].downcase
            next
          else
            fixedLocations << [x, y]
          end
        end
      end
    end
    return fixedLocations
  end

  def convert_coordinates()
    # file = File.open("coordinates.txt", "r")
    cities = Hash.new
    cityCoords = Hash.new
    cityMappings = Hash.new
    locations = create_locations()
    locations.each do |line|
      from = line[0]
      from_name = from[0]
      from_latitude = from[1]["lat"]
      from_longitude = from[1]["lng"]
      from_coordinates = {"lat" => from_latitude, "lng" => from_longitude}
      to = line[1]
      to_name = to[0]
      to_latitude = to[1]["lat"]
      to_longitude = to[1]["lng"]
      to_coordinates = {"lat" => to_latitude, "lng" => to_longitude}
      # print "FROM LOCATION: ", from, " TO LOCATION: ", to, "\n\n"
      # print "FROM LOCATION NAME: ", from_name, " TO LOCATION NAME: ", to_name, "\n\n"

      if cityCoords[from_name].nil? 
        cityCoords[from_name] = from_coordinates
      end

      if cityCoords[to_name].nil?
        cityCoords[to_name] = to_coordinates
      end

      if cities[from_name].nil?
        cities[from_name] = 1
      else
        cities[from_name] = cities[from_name] + 1
      end
      if cities[to_name].nil?
        cities[to_name] = 1
      else
        cities[to_name] = cities[to_name] + 1
      end
      fromAndToCoordinates = [from_name, to_name]
      if cityMappings[fromAndToCoordinates].nil?
        cityMappings[fromAndToCoordinates] = 1
      else
        cityMappings[fromAndToCoordinates] = cityMappings[fromAndToCoordinates] + 1
      end
    end
    # print "CITY JSON: ", cities.to_json, "\n"
    # print "CITY COORD JSON ", cityCoords.to_json, "\n"
    # print "COORDINATES JSON ", cityMappings.to_json, "\n"
    return cities.to_json, cityCoords.to_json, cityMappings.to_json
  end
end
