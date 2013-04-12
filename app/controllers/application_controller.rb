class ApplicationController < ActionController::Base
  protect_from_forgery
  def check_user(username)
    begin
      check = client.user(username)
    rescue
      return false
    end
    return true
  end

  def initialize()
    require 'yajl'
    require 'zlib'
    require 'open-uri'
    client = Octokit::Client.new(:login => "sicophrenic", :password => ")blzzrd12!(")
    gz = open('http://data.githubarchive.org/2013-04-08-23.json.gz')
    js = Zlib::GzipReader.new(gz).read

    locations = ""
    push_event_count = 0
    link_count = 0
    userLocations = []
    Yajl::Parser.parse(js) do |event|
      if link_count == 5
        break
      end

      if event["type"] != "PushEvent"
        # puts "|"
        next
      else
        push_event_count += 1
        # puts "."
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
        owner_location = client.user(owner).location

        if owner_location.nil? || owner_location == ""
          next
        end

        if actor_location.downcase == owner_location.downcase
          next
        end

        # File.open("location.txt", "a") do |f|
        #   f.write("#{actor_location}:#{owner_location}\n")
        # end
        # locations << ":#{actor_location}|#{owner_location}"
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
      # location.strip!
      search = Geocoder.search("#{location}")
      search.each do |place|
        begin
          type = place.data["address_components"][0]["types"][0]
          if type == "locality"
            name = place.data["address_components"][0]["long_name"]
            coordinates = place.geometry["location"]
            nameAndCoordinates << [name, coordinates]
          else
            next
          end
        rescue
          puts "ERROR ERROR ERROR ERROR ERROR"
        end
      end
    end
    return nameAndCoordinates
  end

  def create_locations()
    # File.open("cities.txt", "w")
    # File.open("coordinates.txt", "w")
    locations = []
    userLocations = check_user("sicophrenic")
    userLocations do |line|
      pusher = line[0]
      owner = line[1]
      pusher = pusher.split(", ")
      owner = owner.split(", ")
      pusher_coordinates = find_coordinates(pusher)
      owner_coordinates = find_coordinates(owner)
      pusher_coordinates.each do |x|
        owner_coordinates.each do |y|
          if x[0] == y[0]
            next
          else
            userLocations << [x, y]
            # File.open("cities.txt", "a") do |f|
            #   f.write("#{x[0]}, #{y[0]}\n")
            # end
            # File.open("coordinates.txt", "a") do |f|
            #   #from:to
            #   #lat,lng:lat,lng
            #   f.write("#{x[1]["lat"]},#{x[1]["lng"]}:#{y[1]["lat"]},#{y[1]["lng"]}\n")
            # end
          end
        end
      end
    end
    # return userLocations
  end

  def convert_coordinates()
    # file = File.open("coordinates.txt", "r")
    cities = Hash.new
    city_coord = Hash.new
    coordinates = Hash.new
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

      if city_coord[from_name].nil? 
        city_coord[from_name] = from_coordinates
      end

      if city_coord[to_name].nil?
        city_coord[to_name] = to_coordinates
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
      fromAndToCoordinates = [from_coordinates, to_coordinates]
      if coordinates[fromAndToCoordinates].nil?
        coordinates[fromAndToCoordinates] = 1
      else
        coordinates[fromAndToCoordinates] = coordinates[fromAndToCoordinates] + 1
      end
    end
    return cities.to_json, city_coord.to_json, coordinates.to_json
  end
end
