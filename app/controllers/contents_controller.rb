require 'open-uri'


class ContentsController < ApplicationController
  def index
  end

  def auth
    @key = params.fetch(:your_consumer_key)
    @secret = params.fetch(:your_consumer_secret)

    @key = MY_CONSUMER_KEY if Rails.env == "development"
    @secret = MY_CONSUMER_SECRET if Rails.env == "development"

    render :text => "error" and return if @secret.blank?

    session[:key] = @key
    session[:secret] = @secret

    @consumer = OAuth::Consumer.new(@key, @secret, { :site => "http://www.tumblr.com" })
    callback_url = "#{request.protocol + request.host_with_port}/contents/entry"
    @request_token = @consumer.get_request_token(:exclude_callback => true, :oauth_callback => callback_url)
    @request_token.authorize_url

    @oauth_verifier = @request_token.authorize_url
    session[:request_token] = @request_token
  end

  def entry
    oauth_verifier = params.fetch(:oauth_verifier)
    access_token = session[:request_token].get_access_token(:oauth_verifier => oauth_verifier)

    response = access_token.get('http://api.tumblr.com/v2/user/dashboard')
    render :json => JSON.parse(response.body) and return
    posts = JSON.parse(response.body)["response"]["psts"]
    @reblog_names = posts.collect { |p| p["post_author"] }
    @reblog_names.uniq!
    
    begin 
      test_person = @reblog_names.first
      access_token.post('http://api.tumblr.com/v2/user/follow', { :url => test_person})
    rescue => e
      render :text => e
    end
  end



private


  # def result
  #   escape_word =  URI.encode(input_word)    
  #   url= "http://api.tumblr.com/v2/tagged?tag=#{escape_word}&api_key=#{api_key}"
  
  #   uri = URI.parse(url).read
  #   res = JSON.parse(uri)

  #   responses = res["response"]
  #   @input_word = input_word
  #   @img_urls = []
  #   responses.each do |response|
  #     next unless response["photos"]
  #     @img_urls << response["photos"].first["original_size"]["url"]
  #   end

  #   render :pdf  => input_word, :layout => 'pdf', :encoding => 'UTF-8'
  # end

end





