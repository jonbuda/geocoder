module Geocoder
  module Model

    ##
    # Read the coordinates [lat,lon] of an object. This is not great but it
    # seems cleaner than polluting the instance method namespace.
    #
    def read_coordinates
      [:latitude, :longitude].map{ |i| send self.class.geocoder_options[i] }
    end

    ##
    # Is this object geocoded? (Does it have latitude and longitude?)
    #
    def geocoded?
      read_coordinates.compact.size > 0
    end

    ##
    # Calculate the distance from the object to a point (lat,lon).
    #
    # <tt>:units</tt> :: <tt>:mi</tt> (default) or <tt>:km</tt>
    #
    def distance_to(lat, lon, units = :mi)
      return nil unless geocoded?
      mylat,mylon = read_coordinates
      Geocoder::Calculations.distance_between(mylat, mylon, lat, lon, :units => units)
    end

    ##
    # Get other geocoded objects within a given radius.
    #
    # <tt>:units</tt> :: <tt>:mi</tt> (default) or <tt>:km</tt>
    #
    def nearbys(radius = 20, units = :mi)
      return [] unless geocoded?
      options = {:exclude => self, :units => units}
      self.class.near(read_coordinates, radius, options)
    end

    ##
    # Fetch coordinates and assign +latitude+ and +longitude+. Also returns
    # coordinates as an array: <tt>[lat, lon]</tt>.
    #
    def fetch_coordinates(save = false)
      address_method = self.class.geocoder_options[:user_address]
      unless address_method.is_a? Symbol
        raise Geocoder::ConfigurationError,
          "You are attempting to fetch coordinates but have not specified " +
          "a method which provides an address for the object."
      end
      coords = Geocoder::Lookup.coordinates(send(address_method))
      unless coords.blank?
        method = (save ? "update" : "write") + "_attribute"
        send method, self.class.geocoder_options[:latitude],  coords[0]
        send method, self.class.geocoder_options[:longitude], coords[1]
      end
      coords
    end

    ##
    # Fetch coordinates and update (save) +latitude+ and +longitude+ data.
    #
    def fetch_coordinates!
      fetch_coordinates(true)
    end

    ##
    # Fetch address and assign +address+ attribute. Also returns
    # address as a string.
    #
    def fetch_address(save = false)
      lat_attr = self.class.geocoder_options[:latitude]
      lon_attr = self.class.geocoder_options[:longitude]
      unless lat_attr.is_a?(Symbol) and lon_attr.is_a?(Symbol)
        raise Geocoder::ConfigurationError,
          "You are attempting to fetch an address but have not specified " +
          "attributes which provide coordinates for the object."
      end
      address = Geocoder::Lookup.address(send(lat_attr), send(lon_attr))
      unless address.blank?
        method = (save ? "update" : "write") + "_attribute"
        send method, self.class.geocoder_options[:fetched_address], address
      end
      address
    end

    ##
    # Fetch address and update (save) +address+ data.
    #
    def fetch_address!
      fetch_address(true)
    end
  end
end
