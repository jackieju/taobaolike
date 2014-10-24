require 'spider.rb'
require 'shopify_api/shopify_api.rb'
class LikeController < ApplicationController
    def current_shop
        @current_shop = cookies[:shop]
    end
    
    def create_shopify_product
        if access_token == nil
            error("no session, please reload page.")
            return
        end
        p "current_shop:#{current_shop}"
        url = "https://#{current_shop}/admin/product.json"
        product = {
          "product"=> {
            "title"=> "Burton Custom Freestlye 151",
            "body_html"=> "<strong>Good snowboard!</strong>",
            "vendor"=> "Burton",
            "product_type"=> "Snowboard",
            "variants"=>[
              {
                "option1"=> "First",
                "price"=> "10.00",
                "sku"=> 123
              },
              {
                "option1"=> "Second",
                "price"=> "20.00",
                "sku"=> "123"
              }
            ]
          }
        }
        resp = https_post(url, product.to_json, nil, { 'X-Shopify-Access-Token'=>access_token})
        p "resp=#{resp.inspect}"
        save_to_file(resp, "resp.txt")
        render :text=>resp
    end
    def create_shopify_product2
        p "===>create_shopify_product===>"
        p ShopifyAPI::Session.inspect
        begin
            ShopifyAPI::Session.setup({:api_key => $SETTINGS[:oauth_client_id], :secret =>$SETTINGS[:oauth_client_secret] })
            p "token #{session[:atoken]}"

            shopify_session = ShopifyAPI::Session.new("test-taobaolike.myshopify.com", session[:atoken])

            p shopify_session.inspect
            ShopifyAPI::Base.activate_session(shopify_session)
        rescue Exception=> e
            p "exception"
            err(e)
        end
        p "===>create_shopify_product2===>"
        # shop = ShopifyAPI::Shop.current
        # Create a new product
        new_product = ShopifyAPI::Product.new
        new_product.title = "Burton Custom Freestlye 151"
        new_product.product_type = "Snowboard"
        new_product.vendor = "Burton"
        new_product.save
        p "===>create_shopify_product3===>"
        
    end
    def copy
        p "=====>copy: #{params[:url]}"
        copy_from_url(params[:url])
        p "====>copy2"
        render :text=>"ok"
    end
    
    
        def copy_from_url(url)
          url.strip!
          
          # add http://
          if not (url =~ /http\:\/\//i)
              url = "http://"+url
          end
          
          _uri =URI.parse(url)
          uri =  URI.split(esc(url));
          url =~ /.*?:\/\/.*\//m
          context = $&
p "context:#{context}"
        begin
          res = getPage(url, 10, nil, nil)
          print "------->res:"+res.inspect+"\n"
        content = res.body
        p "res.body:#{res.body}"

          rescue Exception=>e
            err(e)
            content = "Cannot get page"
        end
          # get charset
          #p "==>content=#{content}"
        if (content =~/<meta.*?charset=[\'\"]*([-\w\d]+)[\'\"]*.*?>/mi)
          encode = $1.gsub(" ", "")
        else
          encode = "utf-8"
        end
          logger.info  "---->charset="+encode+"\n"
          p "=====>charset=#{encode}"
          if  not (encode =~ /~utf-8$/i)
    begin
      p "===>convert charset\n"
      if (encode =~ /gb2312/i)
          encode="GBK"
      end

            content = Iconv.conv('utf-8//IGNORE', encode+"//IGNORE", content)
             p "===>converted charset successfully\n"
    rescue Exception=>e
    	logger.info "===>exception:#{e.inspect}\n"
    	p "===>exception:#{e}\n"
    	p "===>content2=#{content}\n"
    	title = getTitle (content)
    	if (title)
    		begin
    			title = Iconv.conv('utf-8', encode, title)
    		rescue Exception=>ee
    			logger.info "===exception:#{e}\n"
    			p "===>exception:#{e}\n"
    			title = "Cannot get title"
    		end
    	else
    		title = "Cannot get title"
    	end
    	content = "Cannot get content"
    end
          end
          
          
          tbinfo = parse_taobao_item_page(content)
          
         # print "------>content_type:"+content.type_params[:charset]+"\n"
         # print "\n"
    	title = getTitle(content) if !title

           #  print "\n---------->content0:#{content}"

           #only get content within body tag
          content_re = /<body(.*?)>(.*)<\/body>/xmi
          m = content_re.match(content)     
          if m
             print "\n---------->m:#{m}\n"
           print "\n---------->m1:#{m[1]}\n"
            print "\n---------->m2:#{m[2]}\n"
          content = "<div id='body123' #{m[1]}>#{m[2]}<\/div>"
         end
          print "\n---------->content1:#{content}"

          # remove js from content
         content = content.gsub(/<script(.*?)<\/script>/mi, "")

         # fix img (add host if img/src doesn't have, to make it easy for downloading afterwards)
         # add host before "/"
         content = content.gsub(/(<img.*?src=[\"\'])\//){|m| "#{$1}#{uri[0]}:\/\/#{uri[2]}\/"}
         # add context path if no "/"
         content = content.gsub(/(<img.*?src=[\"\'])([^\/(http:\/\/)])/){|m| "#{$1}#{context}#{$2}"}
         #  print "\n---------->content:#{content}"


          # add one link to original page
          content = "<p style=\"background:\#ccccff\"><a href='#{params[:url]}' >#{params[:url]}</a></p>#{content}";
          item = Item.new({
              :tbid=>0,
              :shopid=>0,
              :title=>title,
              :url=>url,
              :prop=>''
          })
          item.save!()
          @item = item

          itemid = item[:id].to_s

        # download img and change src  
        FileUtils.makedirs("public/imgdb/#{itemid}")
        img_index = 0

        # download image, and replace image src
        content = content.gsub(/(<img.*?src=[\"\'])(.*?)([\"\'])/i){|m|
             p "==>2"+$2
             c = $2
             begin
                 fimg=download_img(_uri, itemid, $2, img_index)
                  img_index = img_index+1
                  c = "http://#{ENV['server_name']}:#{ENV['port']}/imgdb/#{itemid}/#{fimg}"
             rescue Exception=>e
                 p "===>exception:#{e.inspect}"
             end
             "#{$1}#{c}#{$3}"
        }

        # download img for background, and replace url
        content = content.gsub(/(body)(.*?{.*?background:.*?url\()(.*?)(\))/i){|m|
            p "==>22"+$3
            c = $3
            begin
                fimg=download_img(_uri, docid, $3, img_index)
                img_index = img_index+1
                c = "http://#{ENV['server_name']}:#{ENV['port']}/imgdb/#{docid}/#{fimg}"
            rescue Exception=>e
                p "===>exception:#{e.inspect}"
            end
            "div\#body123#{$2}#{c}#{$4}"
        }


          item[:content] = content
          p "ok"
          save_doc(item)
          # redirect_to :action=>'index', :item=>item

        end
        
        def save_doc (item)
            id=item[:id]
            content=item[:content]
            begin
              dir = id.to_i/100
              # dir = "/var/taobaolike/docs/#{dir.to_s}"
              dir = "public/tbitmes/#{dir.to_s}"
              FileUtils.makedirs(dir)
              logger.info("===========>#{dir}/#{id}<====")
              aFile = File.new("#{dir}/#{id}","w")
              aFile.puts content
              aFile.close
            rescue Exception=>e
              logger.error e
            end

            # item.save!()
          end
        
        def parse_taobao_item_page(content)
            ret = {}
       	    title_re = /<div class=\"tb-detail-hd\">\s*?<h1 data-spm=\"\d+?\">(.*?)\s*?<\/h1>\s*?<p>(.*?)<\/p>\s*?<\/div>/mi

              m = title_re.match(content)
              print "\n---------->mmm:#{m[0]}"
              print "\n---------->mmm:#{m[1]}"
              print "\n---------->mmm:#{m[2]}"
        

        	return ret
        end
end
