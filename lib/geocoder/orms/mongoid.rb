require 'mongoid_geo'
#module Geocoder
module Mongoid
  module Document

    ##
    # Implementation of 'included' hook method.
    #
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do

        # scope: geocoded objects
        scope :geocoded do
          where(
            geocoder_options[:latitude].exists => true,
            geocoder_options[:longitude].exists => true
          )
        end

        # scope: not-geocoded objects
        scope :not_geocoded do
          where(
            geocoder_options[:latitude].exists => false,
            geocoder_options[:longitude].exists => false
          )
        end
      end

      ##
      # Find all objects within a radius (in miles) of the given location
      # (address string). Location (the first argument) may be either a string
      # to geocode or an array of coordinates (<tt>[lat,long]</tt>).
      #
      scope :near do |location, options|
        latitude, longitude = location.is_a?(Array) ? location : Geocoder::Lookup.coordinates(location)
        if latitude and longitude
          radius = options[:radius]
          radius *= Geocoder::Calculations.km_in_mi if options[:units] == :km
          nearPoint = {:point => [latitude, longitude], :distance => radius}

          points = case options[:precision]
          when :high
            where(loc_attr.nearMax(:sphere) => nearPoint)
          else
            near(loc_attr.nearMax => nearPoint)
          end
          points = points.limit(options[:limit]) if options[:limit]
          points.to_a
        else
          {}
        end
      end

      ##
      # Find all objects near me
      #
      scope :nearHere do |options|      
        near [location.first, location.last], options
      end

      scope :withinCenter do |location, options|
        latitude, longitude = location.is_a?(Array) ? location : Geocoder::Lookup.coordinates(location)
        if latitude and longitude
          radius = options[:radius]
          radius *= Geocoder::Calculations.km_in_mi if options[:units] == :km

          circle =  {:center => [latitude, longitude], :radius => radius}

          points = case options[:precision]
          when :high
            where(loc_attr.withinCenter(:sphere) => circle)
          else
            where(loc_attr.withinCenter => circle)
          end
          points = points.limit(options[:limit]) if options[:limit]
          points.to_a
        else
          {}
        end
      end

      # expects options
      # :box => {:lower_left => [x, y], :upper_right => [x2, y2]}
      scope :withinBox do |location, options|
        latitude, longitude = location.is_a?(Array) ? location : Geocoder::Lookup.coordinates(location)
        if latitude and longitude
          # TODO should have extract_box method to handle this and support multiple variants!

          # box = BoundingBox.new lower_left, upper_right
          if options[:box]
            box = options[:box]

            lower_left = box[:lower_left]
            upper_right = box[:upper_right]

            box = [lower_left, upper_right]

            points = case options[:precision]
            when :high
              where(loc_attr.withinBox(:sphere) => box)
            else
              where(loc_attr.withinBox => box)
            end
            points = points.limit(options[:limit]) if options[:limit]
            points.to_a
          else
            {}
          end
        end
      end
    end 
  end
end
