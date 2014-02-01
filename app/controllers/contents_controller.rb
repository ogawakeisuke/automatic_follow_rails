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

    response = access_token.get('http://api.tumblr.com/v2/user/dashboard?reblog_info=true')
    posts = JSON.parse(response.body)["response"]["posts"]
    
    @reblog_names = posts.collect { |p| p["reblogged_from_name"] }
    @reblog_names.compact!.uniq!


    @reblog_names.each do |reblog|
      access_token.post('http://api.tumblr.com/v2/user/follow', { :url => "http://#{reblog}.tumblr.com"})
    end
  end

end





