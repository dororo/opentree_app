require 'json'
require 'net/https'
require 'net/http'
require 'uri'
require 'openssl'

class FacebookImporter
  def initialize(person_id, token)
    @person_id = person_id
    @token = token
  end
    
  def get_relatives
    uri = URI.parse("https://graph.facebook.com/#{@person_id}/family?access_token=#{@token}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Get.new(uri.request_uri)
    
    response = http.request(request)
    relatives = JSON(response.body)
    
    relatives.fetch("data").each do |fbperson|
      @person_id = fbperson.fetch("id")
      @name = fbperson.fetch("name")
      @relation = fbperson.fetch("relationship")
      get_info(@person_id)
      
      
    end
    
  end
  
  def get_info(person_id)
    uri = URI.parse("https://graph.facebook.com/#{@person_id = person_id}?access_token=#{@token}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Get.new(uri.request_uri)
    
    response = http.request(request)
    fb_obj = JSON(response.body)
    
    p @person_id = fb_obj.fetch("id")
    p @firstname = fb_obj.fetch("first_name")
    p @lastname = fb_obj.fetch("last_name")
    p @sex = fb_obj.fetch("gender")
    p @person_link = fb_obj.fetch("link")
    get_thumbnail(@person_id)
    
    if !fb_obj.key?("birthday")
      p @birthdate = fb_obj.update({"birthday"=>"no birthdate avaiable"}).fetch("birthday")
    else
      p @birthdate = fb_obj.fetch("birthday") 
    end
     
    if !fb_obj.key?("hometown")
      fb_obj.update({"hometown"=>"no hometown"})
      p @hometown_id = "no id avaiable"
      p @hometown_name = "no name avaiable"
      p @hometown_link = "no link avaiable"
    else
      p @hometown_id = fb_obj.fetch("hometown").fetch("id")
      p @hometown_name = fb_obj.fetch("hometown").fetch("name")
      get_latlong(@hometown_id)
    end
    
    person = Person.find_or_initialize_by_url(@person_link)
    person.update_attributes(:url => @person_link, :firstname => @firstname, :lastname => @lastname, :thumbnail => @profile_pic_url, :birthdate => @birthdate)
    place = Location.find_or_initialize_by_url(@hometown_link)
    place.url = @hometown_link
    place.name = @hometown_name
    place.save
    person.residences.create(:location_id => place.id, :status => @relation)
    p person.inspect
  end
  
  def get_thumbnail(person_id)
    uri = URI.parse("https://graph.facebook.com/#{@person_id=person_id}/picture?access_token=#{@token}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Get.new(uri.request_uri)
    
    response = http.request(request)
    p @profile_pic_url = response.body
  end
  
  def get_latlong(hometown_id)
    uri = URI.parse("https://graph.facebook.com/#{@hometown_id=hometown_id}?access_token=#{@token}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Get.new(uri.request_uri)
    
    response = http.request(request)
    location_info = JSON(response.body)
    p @hometown_lat = location_info.fetch("location").fetch("latitude")
    p @hometown_long = location_info.fetch("location").fetch("longitude")
  end
  
end

test_person_id = "100000031321425" #me
test_token = "AAADRgAhoADABAPCYJ8KhqO7F7aiKqHN62y7vJiakaIjqtoRobcIxSBJOokylsWbpGZARaV6u6uZBrwAngwPjhnnAmTHtZCn2LWYExmlDwZDZD"

person = FacebookImporter.new(test_person_id, test_token)
person.get_relatives

