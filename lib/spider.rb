

def download_img(page_uri, docid, image_url, index)
   
    if not (image_url=~/http\:\/\//i)
        if image_url =~/~\//i
             image_url = "#{page_uri.scheme}://#{page_uri.host}:#{page_uri.port}#{url}"
        else
             image_url = "#{page_uri.scheme}://#{page_uri.host}:#{page_uri.port}#{page_uri.path}/#{url}"
        end
    end
    url =   URI.escape(image_url)
       target_uri = URI.parse(url)
       p "==>downloading #{target_uri.host},#{target_uri.path},#{target_uri.query}"
       Net::HTTP.start(target_uri.host) { |http|
    if (target_uri.query and target_uri.query.length>0)
        resp = http.get("#{target_uri.path}?#{target_uri.query}")
    else
        resp = http.get("#{target_uri.path}")
    end
    
    i = image_url.rindex(".")
    image_fext = "#{image_url[i+1, image_url.size-i]}"
  
     # resp['Content-Type']=~ /image\/(.*)$/i
     # p "===> downloaded img #{url} to #{index}.#{$1}, content-type=#{resp['Content-Type']}" 
     
       fname = "#{index}.#{image_fext}"
      p "===> downloaded img #{url} to #{fname}, content-type=#{resp['Content-Type']}" 
       
      FileUtils.makedirs("#{$SETTINGS[:imgdb_fs_home]}/#{docid}")
     # open("#{$SETTINGS[:imgdb_fs_home]}/#{docid}/#{index}.#{$1}", "wb") { |file|
     open("#{$SETTINGS[:imgdb_fs_home]}/#{docid}/#{fname}", "wb") { |file|
         file.write(resp.body)
     }
     # return "#{index}.#{$1}"
     return fname
 }
end
    def esc(str)
      print "----->str1:#{str}\n"
        # str=str.gsub("&","&amp;")
        print "----->str2:#{str}\n"
       str.gsub(/([^ %&=;?:\/a-zA-Z0-9_.-]+)/n) do
      '%' + $1.unpack('H2' * $1.size).join('%').upcase
      end.tr(' ', '+')
    end

	def getTitle( content)
	 title_re = /<title>(.*?)<\/title>/mi

      m = title_re.match(content)
      print "\n---------->title:#{m}"
      if (m)
        title = m[1].gsub(/[\/|\\*\(\)?\[\];:'\",\.]/,"").gsub(/^[\s]+/, "").gsub(/[\s]+$/, "").gsub(/<!--(.*)-->/, "")
      else
        title = ""
      end

		return title
	end

    def getPage(url, limit, cookie, referer)
      url.strip!
      url = esc(url)
      print "--------------------------------->url1:#{url}\n"
      if not (url =~ /http\:\/\//i)
          url = "http://"+url
      end
      uri =URI.parse(url)
      p "host:#{uri.host}, #{uri.port}"
      http = Net::HTTP.new(uri.host, uri.port)
      headers = {}
      if cookie
          headers['Cookie'] = cookie
      end
      if referer
          headers['Referer'] = referer
      end
      p "==>uri.scheme=#{uri.scheme},uri.host=#{uri.host}, uri.path=#{uri.path}, uri.query=#{uri.query}"
      path = "/"
      if uri.path  and uri.path.length > 0
          path = uri.path
     end
     p "===>path=#{path}"
=begin
      resp, d = http.get(path, uri.query, headers)
#      p "---->resp.inspect=#{resp.response['set-cookie']}"
 #     p "---->resp.req=#{uri.host}\n#{uri.port}\n#{uri.path}\n#{uri.query}\n#{headers.inspect}"
      if (resp.response['set-cookie'])
          cookie1 = resp.response['set-cookie'].split('; ')[0]
      end

    case  resp
        when Net::HTTPSuccess     then return resp
        when Net::HTTPRedirection 
            if (limit<=0) 
              return resp 
            else 
              getPage(resp['location'], limit-1, cookie1, url)
            end
      end
      return resp
=end

      p "==>url:#{url}"
      res = Net::HTTP.get_response(URI.parse(url))
      cookie1 = nil
     cookie1 = res['set-cookie'].split('; ')[0] if res['set-cookie']
      p "--->cookie=#{cookie.inspect}"
      print "------->body:"+res.body+"\n"
      print "--------------------------------->locate:#{res['location']}\n";
      print "--------------------------------->response value:#{res.code}\n"

      case  res.code.to_i
        # when Net::HTTPSuccess     then return res
        # when Net::HTTPOK    then return res
        when 200 
            p "--->200--"
             return res
        # when Net::HTTPRedirection 
        when 302
            p "--->302---"
            if (limit<=0) 
              return res 
            else 
              return getPage(res['location'], limit-1, cookie1, url)
            end
      end
      
      return res

    end
    