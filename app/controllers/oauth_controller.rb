class OauthController < ApplicationController
    def oauth_redirect_uri
        "https://#{$SETTINGS[:host]}:#{$SETTINGS[:port]}/oauth/rt"
    end
    # url to get authorized code
    def oauth_url_authorize
        return "#{$SETTINGS[:oauth_server_url_authorize]}?response_type=code&client_id=#{$SETTINGS[:oauth_client_id]}&scope=ALL&redirect_uri=#{oauth_redirect_uri}"    
    end
    # url to get access token
    def oauth_url_token(code)
        # return "#{$SETTINGS[:oauth_server_url_token]}?code=#{code}&grant_type=authorization_code&client_id=#{$SETTINGS[:oauth_client_id]}&client_secret=#{$SETTINGS[:oauth_client_secret]}&redirect_uri=#{oauth_redirect_uri}"    
        return "#{$SETTINGS[:oauth_server_url_token]}?code=#{code}&client_id=#{$SETTINGS[:oauth_client_id]}&client_secret=#{$SETTINGS[:oauth_client_secret]}"    
    end
    def rt #receive authorized token
        p "receive code #{params[:code]}"
        authroized_code = params[:code]
        
        # request access token
        p "get access token: #{oauth_url_token(authroized_code)}"
        data = https_post(oauth_url_token(authroized_code), {
            "client_id"=>$SETTINGS[:oauth_client_id],
            "client_secret"=>$SETTINGS[:oauth_client_secret],
            "code"=>authroized_code
        })     
        p "data=>#{data}" 
        ret = JSON.parse(data)
        p "access token #{ret}"
        session[:atoken] = ret['access_token']
        session[:rtoken] = ret['refresh_token']
        p "access token2 #{session[:atoken]}"
        cookies[:atoken] = {
           :value => ret['access_token'],
           :expires => 1.year.from_now,
           :domain => request.host
        }

        redirect_to "/index.html?atoken=#{session[:atoken]}&shop=#{params[:shop]}"
        # render :text=>"ok"
    end
    
    # # check
    # def c
    #     session[:appid] = params[:appid]
    #     check_session_a
    # end
end
