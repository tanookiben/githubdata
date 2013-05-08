class LocationsController < ApplicationController

  def show
  	@date = parse_date(session[:date])
    # @cities, @cityCoords, @cityMappings = convert_coordinates()
    convert_coordinates

    gon.cities = @cities.to_json
    gon.cityCoords = @cityCoords.to_json
    gon.cityMappings = @cityMappings.to_json
  end

  private
    def find_users()
    	start = Time.now
      puts "-----start find_users()-----"

      octokit_setup

      require 'yajl'
      require 'zlib'
      require 'open-uri'
	      
      @link_count = 0
      @push_event_count = 0
      @user_locations = []

      @dataset = create_dataset(@date)

      @dataset.each do |datafile|
      	puts "Checking #{datafile}."

	      gz = open(datafile)
	      js = Zlib::GzipReader.new(gz).read
	      Yajl::Parser.parse(js) do |event|
	        if event["type"] != "PushEvent"
	          next # skip everything that isn't a PushEvent
	        else
	        	@push_event_count += 1
	        end

	        actor = event["actor_attributes"]["login"]
	        repository = event["repository"]
	        owner = repository["owner"]

	        if actor == owner
	          next # skip uninteresting commits
	        end

	        actor_location = event["actor_attributes"]["location"]
	        if actor_location.nil? || actor_location == ""
	          next # skip events with missing info
	        end

	        begin
	          # puts owner
	          owner_location = @client.user(owner).location

	          if owner_location.nil? || owner_location == ""
	            next # skip events with missing info
	          end

	          if actor_location.downcase == owner_location.downcase
	            next #skip uninteresting commits
	          end

	          # print "ACTOR LOCATION, ", actor_location, " ------- OWNER LOCATION, ", owner_location, "\n\n"
	          @user_locations << [actor_location, owner_location]
	          @link_count += 1
	        rescue
	          puts "Octokit error"
	        end
	      end
      end

      puts "-----end find_users()-----"
      finish = Time.now
      puts "find_users() took #{finish-start} seconds."
    end

    def find_location(locations)
    	start = Time.now
      # puts "-----start find_locations()-----"

      location_found = []

      #creates [name, Hash{lat => #, lng => #}]
      locations.each do |location|
        city = City.find_by_name(location)
        if city.nil?
          search = Geocoder.search("#{location}")
          search.each do |place|
            begin
              type = place.data["address_components"][0]["types"][0]
              if type == "locality"
                name = place.data["address_components"][0]["long_name"]
                coordinates = place.geometry["location"]
                location_found = [name, coordinates]
                City.create(name: name, lat: coordinates["lat"], lng: coordinates["lng"])
                puts "created city #{name}"
                break
              else
                next
              end
            rescue
              puts "Geocoder search error"
            end
          end
        else
          name = city.name
          coordinates = {"lat" => city.lat, "lng" => city.lng}
          location_found = [name, coordinates]
          break
        end
      end

      # puts "-----end find_locations()-----"
      # finish = Time.now
      # puts "find_locations() took #{finish-start} seconds."
      return location_found
    end

    def create_locations()
    	start = Time.now
      # puts "-----start create_locations()-----"

      # userLocations = find_users()
      find_users # set up @user_locations

      @found_locations = []
      @user_locations.each do |line|
        # print "USER LOCATIONS IN CREATE: ", line, "\n\n\n"
        pusher = line[0]
        owner = line[1]
        pusher_locations = pusher.split(", ")
        owner_locations = owner.split(", ")
        # print "PUSHER: ", pusher, "\n"
        # print "OWNER: ", owner, "\n\n"
        pusher_coordinates = find_location(pusher_locations)
        owner_coordinates = find_location(owner_locations)

        if pusher_coordinates == [] || owner_coordinates == []
        	next # location not found
        end
        if pusher_coordinates[0].downcase == owner_coordinates[0].downcase
        	next # same locations
        end

        @found_locations << [pusher_coordinates, owner_coordinates]
      end

      # puts "-----end create_locations()-----"
      # finish = Time.now
      # puts "create_locations() took #{finish-start} seconds."
    end

    def convert_coordinates()
    	start = Time.now
      puts "-----start convert_coordinates()-----"

      # file = File.open("coordinates.txt", "r")
      @cities = Hash.new
      @cityCoords = Hash.new
      @cityMappings = Hash.new

      create_locations

      @found_locations.each do |line|
      	from_name, from_coordinates, to_name, to_coordinates = parse_coordinates(line)
        # from = line[0]
        # from_name = from[0]
        # from_latitude = from[1]["lat"]
        # from_longitude = from[1]["lng"]
        # from_coordinates = {"lat" => from_latitude, "lng" => from_longitude}
        # to = line[1]
        # to_name = to[0]
        # to_latitude = to[1]["lat"]
        # to_longitude = to[1]["lng"]
        # to_coordinates = {"lat" => to_latitude, "lng" => to_longitude}
        # print "FROM LOCATION: ", from, " TO LOCATION: ", to, "\n\n"
        # print "FROM LOCATION NAME: ", from_name, " TO LOCATION NAME: ", to_name, "\n\n"

        if @cityCoords[from_name].nil? 
          @cityCoords[from_name] = from_coordinates
        end

        if @cityCoords[to_name].nil?
          @cityCoords[to_name] = to_coordinates
        end

        if @cities[from_name].nil?
          @cities[from_name] = 1
        else
          @cities[from_name] = @cities[from_name] + 1
        end
        if @cities[to_name].nil?
          @cities[to_name] = 1
        else
          @cities[to_name] = @cities[to_name] + 1
        end
        fromAndToCoordinates = [from_name, to_name]
        if @cityMappings[fromAndToCoordinates].nil?
          @cityMappings[fromAndToCoordinates] = 1
        else
          @cityMappings[fromAndToCoordinates] = @cityMappings[fromAndToCoordinates] + 1
        end
      end
      # print "CITY JSON: ", cities.to_json, "\n"
      # print "CITY COORD JSON ", cityCoords.to_json, "\n"
      # print "COORDINATES JSON ", cityMappings.to_json, "\n"

      puts "-----end convert_coordinates()-----"
      finish = Time.now
      puts "convert_coordinates() took #{finish-start} seconds."
    end

    def parse_coordinates(location)
    	from = location[0]
    	to = location[1]

    	from_name = from[0]
    	from_latitude = from[1]["lat"]
    	from_longitude = from[1]["lng"]

    	to_name = from[1]
    	to_latitude = from[1]["lat"]
    	to_longitude = from[1]["lng"]

    	from_coordinates = {"lat" => from_latitude, "lng" => from_longitude}
    	to_coordinates = {"lat" => to_latitude, "lng" => to_longitude}

    	return from_name, from_coordinates, to_name, to_coordinates
    end

    def octokit_setup
      if Rails.env.development?
        @client = Octokit::Client.new(:login => USERNAME, :password => PASSWORD)
      else
        @client = Octokit::Client.new(:login => ENV["USERNAME"], :password => ENV["PASSWORD"]])
      end
    end

end