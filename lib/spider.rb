

def download_img(uri, docid, url, index)
   
    if not (url=~/http\:\/\//i)
        if url =~/~\//i
             url = "#{uri.scheme}://#{uri.host}:#{uri.port}#{url}"
        else
             url = "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}/#{url}"
        end
    end
    url =   URI.escape(url)
       target_uri = URI.parse(url)
       p "==>downloading #{target_uri.host},#{target_uri.path},#{target_uri.query}"
       Net::HTTP.start(target_uri.host) { |http|
    if (target_uri.query and target_uri.query.length>0)
        resp = http.get("#{target_uri.path}?#{target_uri.query}")
    else
        resp = http.get("#{target_uri.path}")
    end
    

     resp['Content-Type']=~ /image\/(.*)$/i
     p "===> downloaded img #{url} to #{index}.#{$1}, content-type=#{resp['Content-Type']}" 
     open("public/imgdb/#{docid}/#{index}.#{$1}", "wb") { |file|
         file.write(resp.body)
     }
     return "#{index}.#{$1}"
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
    