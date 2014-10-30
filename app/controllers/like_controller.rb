require 'spider.rb'
require 'shopify_api/shopify_api.rb'
class LikeController < ApplicationController
    def current_shop
        @current_shop = cookies[:shop]
    end
=begin
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
=end    
    def create_shopify_product(product)
        p "product=>"+product.to_json
        
        if access_token == nil
            error("no session, please reload page.")
            return false
        end
        p "current_shop:#{current_shop}"
        url = "https://#{current_shop}/admin/products.json"
        
        headers = { 'X-Shopify-Access-Token'=>access_token,
            "Accept" => "application/json",
            "Content-Type"=> "application/json"
            
             # "Content-Type"=> "application/x-www-form-urlencoded"
        }
        
        products = {
            :product=>product
        }
        
        save_to_file("body.json", products.to_json)
        resp = https_post(url, products.to_json, nil, headers)
        p "resp=#{resp.inspect}"
        save_to_file("resp.txt", resp)
        # render :text=>resp
        return true
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
        item = copy_from_url(params[:url])
        r = create_shopify_product(item)
        p "====>copy2 #{r}"
        if r== false
            return
        end
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
            @encode = $1.gsub(" ", "")
        else
            @encode = "utf-8"
        end
        logger.info  "---->charset="+@encode+"\n"
        p "=====>charset=#{@encode}"
        if  not (@encode =~ /~utf-8$/i)
            begin
                p "===>convert charset\n"
                if (@encode =~ /gb2312/i)
                    @encode="GBK"
                end

                content = Iconv.conv('utf-8//IGNORE', @encode+"//IGNORE", content)
                p "===>converted charset successfully\n"
            rescue Exception=>e
        	    logger.info "===>exception:#{e.inspect}\n"
        	    p "===>exception:#{e}\n"
        	    p "===>content2=#{content}\n"
        	    title = getTitle (content)
            	if (title)
            		begin
            			title = Iconv.conv('utf-8', @encode, title)
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
          
          p "--->content0:#{content}"

=begin          
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
=end
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

        tbinfo = parse_taobao_item_page(content, _uri, itemid)
        p "tbinfo:#{tbinfo.inspect}"
        localize_images(content, itemid, _uri)
        tbinfo[:localid] = itemid

        # item[:content] = content
        
        content.gsub!(/<div class=\"content\" id=\"J_DivItemDesc\">描述加载中<\/div>\s*?<\/div>/, " <div class=\"content\" id=\"J_DivItemDesc\">#{tbinfo[:body_html]}</div> </div> " )
        
        p "ok"
        save_doc(tbinfo, content)
        
        # redirect_to :action=>'index', :item=>item
        return tbinfo
        
    end
        
        def localize_images(content, itemid, page_uri)
            
            # fix img (add host if img/src doesn't have, to make it easy for downloading afterwards)
             # add host before "/"
             content = content.gsub(/(<img.*?src=[\"\'])\//){|m| "#{$1}#{uri[0]}:\/\/#{uri[2]}\/"}
             # add context path if no "/"
             content = content.gsub(/(<img.*?src=[\"\'])([^\/(http:\/\/)])/){|m| "#{$1}#{context}#{$2}"}
             #  print "\n---------->content:#{content}"
             
             
            # download img and change src  
             FileUtils.makedirs("#{$SETTINGS[:imgdb_fs_home]}/#{itemid}")
             img_index = 1

             # download image, and replace image src
             content = content.gsub(/(<img.*?src=[\"\'])(.*?)([\"\'])/i){|m|
                  p "==>2"+$2
                  c = $2
                  begin
                      fimg=download_img(page_uri, itemid, $2, img_index)
                       img_index = img_index+1
                       # c = "http://#{ENV['server_name']}:#{ENV['port']}/imgdb/#{itemid}/#{fimg}"
                       c = "#{$SETTINGS[:imgdb_url_prefix]}/imgdb/#{itemid}/#{fimg}"
                       
                  rescue Exception=>e
                      p "===>exception:#{e.inspect}"
                      err(e)
                  end
                  "#{$1}#{c}#{$3}"
             }

             # download img for background, and replace url
             content = content.gsub(/(body)(.*?{.*?background:.*?url\()(.*?)(\))/i){|m|
                 p "==>22"+$3
                 c = $3
                 begin
                     fimg=download_img(page_uri, itemid, $3, img_index)
                     img_index = img_index+1
                     # c = "http://#{ENV['server_name']}:#{ENV['port']}/imgdb/#{itemid}/#{fimg}"
                     c = "#{$SETTINGS[:imgdb_url_prefix]}/imgdb/#{itemid}/#{fimg}"
                     
                 rescue Exception=>e
                     p "===>exception:#{e.inspect}"
                     err(e)
                 end
                 "div\#body123#{$2}#{c}#{$4}"
             }

             
        end
        
        def save_doc (tbinfo, content)
            id=tbinfo[:localid]
            # content=tbinfo[:content]
            begin
              dir = id.to_i/100
              # dir = "/var/taobaolike/docs/#{dir.to_s}"
              dir = "#{$SETTINGS[:tb_item_db_home]}/#{dir.to_s}"
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
        
        def encode_with_utf8(content)
            p "=====>charset=#{@encode}"
            if  not (@encode =~ /~utf-8$/i)
                begin
                    p "===>convert charset\n"
                    if (@encode =~ /gb2312/i)
                        @encode="GBK"
                    end

                    content = Iconv.conv('utf-8//IGNORE', @encode+"//IGNORE", content)
                rescue Exceptione=>e
                    err(e)
                end
            end
            return content
        end
        def parse_taobao_item_page(content, page_uri, itemid)
             p "====>ppp:"+content
            ret = {}
            
            re = /<script>g_config\s*=\s*\{(.*?)\};/im
            m = re.match(content)
            m = m[1]
            re = /itemId:\"(\d+)\",/im
            m = re.match(content)
            ret[:tbitemid]=m[1]
            re = /shopId:\"(\d+)\",/im
            m = re.match(content)
            ret[:tbshopId]=m[1] 
           
            
             ret[:product_type] = "dfafs"
            
            
       	    title_re = /<div class=\"tb-detail-hd\">\s*?<h1 data-spm=\"\d+?\">(.*?)\s*?<\/h1>\s*?<p>(.*?)<\/p>\s*?<\/div>/mi
                
            m = title_re.match(content)
            if m == nil
              title_re2 = /<h3 class=\"tb-main-title\">\s*?(.*?)\s*<\/h3>[|(\s*?<p class=\"tb-subtitle\">\s*?(.*?)\s*<\/p>)]/mi
              m = title_re2.match(content)
            end
            p "---------->mmm:#{m[0]}"
            p "---------->mmm1:#{m[1]}"
            p "---------->mmm2:#{m[2]}"
        
            ret[:title] = m[1]
            ret[:subtitle] = m[2]
                
                
            # find taobao lazyload content
            content_url_re = /Hub\.config\.set\(.*?\"apiItemDesc\":\"(.*?)\",/im 
            m = content_url_re.match(content)
            p "---------->mmm:#{m[0]}"
            p "---------->mmm1:#{m[1]}"
            content_url = m[1]
            desc = getPage(content_url, 10, nil, nil)   
            desc_html = desc.body
            m = /var desc='(.*?)';/im.match(desc_html)
            desc_html = m[1]
            desc_html = encode_with_utf8(desc_html)
            p "==>desc_utf8:#{desc_html}"
            desc_html = localize_images(desc_html, itemid, page_uri)
            ret[:body_html] = desc_html
            
            # find main image
            re = /<img id=\"J_ImgBooth\" data-src=\"(.*?)\"\s*?\/>/im
            m = re.match(content)
            p "---------->mmm:#{m[0]}"
            p "---------->mmm1:#{m[1]}"
            main_image = m[1]
            # remove postfix for image size
            # http://img02.taobaocdn.com/bao/uploaded/i2/TB1l5qZGFXXXXblXXXXXXXXXXXX_!!0-item_pic.jpg_50x50.jpg
            # =>http://img02.taobaocdn.com/bao/uploaded/i2/TB1l5qZGFXXXXblXXXXXXXXXXXX_!!0-item_pic.jpg
            i = main_image.index(".jpg")
            main_image = "#{main_image[0, i]}.jpg"
            p "main_image=#{main_image}"
            fimg = download_img(page_uri, itemid, main_image, 0)  
            ret[:main_image] = "#{$SETTINGS[:imgdb_url_prefix]}/imgdb/#{itemid}/#{fimg}"
            ret[:images]=[]
            ret[:images].push({'src'=>ret[:main_image]})
            # find all images
            re = /(<ul id=\"J_UlThumb\".*?<\/ul>\s*?<script>)/im
            m = re.match(content)
            p "---------->mmm:#{m[0]}"
            content_image = m[0]
            re = /<a href=\"#\"><img data-src="(.*?)"\s*\/><\/a>/im
            content_image.scan(re){|m|
                p "---->m:#{m.inspect}"
                p "---------->mmm:#{m[0]}"
                p "---------->mmm:#{m[1]}"
                image = m[0]
                i = image.index(".jpg")
                image = "#{image[0, i]}.jpg"
                fimg = download_img(page_uri, itemid, image, 0)
                ret[:images].push({'src'=>"#{$SETTINGS[:imgdb_url_prefix]}/imgdb/#{itemid}/#{fimg}"})    
                p "--->image:#{fimg}"
            }      
            p "tbinfo2:#{ret.inspect}"
            # desc_re = /<div id=\"description\".*?>\s*?()\s*?<\/div>\*?<\/div>/im
            # m = desc_re.match(content)
            # 
            # p "---------->mmm:#{m[0]}"
            # p "---------->mmm1:#{m[1]}"
            # p "---------->mmm2:#{m[2]}"
=begin
  <div class="tb-gallery">
 <div class="tb-booth tb-pic tb-main-pic">
 <!-- the viewer -->
 <a href="http://www.taobao.com/view_image.php?pic=Wx0GGlFDXA1VUwMAWx0SCwkNGRFcVxxQW1UcCxMFRBkDCFdVV1cRRhpWRDg0Q1QMQ2lzfmsxKjIJACs8YGxrai0xKzwzNClTGQkfWkBdXjYCAwhCGRRf&title=s6e80taxz%2Fo1ODI40fLGpMOr0rvM5cewz7W0%2BLr7tfu94dGptdjRpQ%3D%3D&version=2&c=ZDliNTkyOGQ2NTU5NjEwMGI3MzY4YjUzYTEzN2Y1Zjg%3D&itemId=41916334072&shopId=106814608&sellerRate=22&fv=9" rel="nofollow" target="_blank">      <img id="J_ImgBooth" data-src="http://img02.taobaocdn.com/bao/uploaded/i2/TB1l5qZGFXXXXblXXXXXXXXXXXX_!!0-item_pic.jpg_400x400.jpg"  data-hasZoom="700" />
     </a>
 <div class="zoom-icon hidden tb-iconfont" id="J_ZoomIcon">&#337;</div>
</div>
<!-- thumbnail list -->
<ul id="J_UlThumb" class="tb-thumb tb-clearfix">
     <li class="tb-selected">
     <div class="tb-pic tb-s50">
 <a href="#"><img data-src="http://img02.taobaocdn.com/bao/uploaded/i2/TB1l5qZGFXXXXblXXXXXXXXXXXX_!!0-item_pic.jpg_50x50.jpg" /></a>
 </div>
   </li>
   <li >
     <div class="tb-pic tb-s50">
 <a href="#"><img data-src="http://img03.taobaocdn.com/imgextra/i3/1849936827/TB20oClaVXXXXbPXXXXXXXXXXXX_!!1849936827.jpg_50x50.jpg" /></a>
 </div>
   </li>
   <li >
     <div class="tb-pic tb-s50">
 <a href="#"><img data-src="http://img02.taobaocdn.com/imgextra/i2/1849936827/TB20GGraVXXXXXwXXXXXXXXXXXX_!!1849936827.jpg_50x50.jpg" /></a>
 </div>
   </li>
   <li >
     <div class="tb-pic tb-s50">
 <a href="#"><img data-src="http://img02.taobaocdn.com/imgextra/i2/1849936827/TB2Vy9iaVXXXXanXpXXXXXXXXXX_!!1849936827.jpg_50x50.jpg" /></a>
 </div>
   </li>
   <li >
     <div class="tb-pic tb-s50">
 <a href="#"><img data-src="http://img01.taobaocdn.com/imgextra/i1/1849936827/TB2xHOnaVXXXXbjXXXXXXXXXXXX_!!1849936827.jpg_50x50.jpg" /></a>
 </div>
   </li>
     </ul>
<script>
 (function(){if(this.WebP)return;this.WebP={},WebP._cb=function(e,t){this.isSupport=function(t){t(e)},t(e),(window.chrome||window.opera&&window.localStorage)&&window.localStorage.setItem("webpsupport",e)},WebP.isSupport=function(e){if(!e)return;if(!window.chrome&&!window.opera)return WebP._cb(!1,e);if(window.localStorage&&window.localStorage.getItem("webpsupport")!==null){var t=window.localStorage.getItem("webpsupport");WebP._cb(t==="true",e);return}var n=new Image;n.src="data:image/webp;base64,UklGRjoAAABXRUJQVlA4IC4AAACyAgCdASoCAAIALmk0mk0iIiIiIgBoSygABc6WWgAA/veff/0PP8bA//LwYAAA",n.onload=n.onerror=function(){WebP._cb(n.width===2&&n.height===2,e)}},WebP.run=function(e){this.isSupport(function(t){t&&e()})}})();
 (function(e,f){var d,c=function(g){return document.getElementById(g)},a=function(g){var h=g.getAttribute("data-src");if(!h){return}if(d&&e){h+="_.webp";f=true}g.src=f?h.replace(/img0(\d)\.taobaocdn\.com/,"gd$1.alicdn.com"):h},b=function(h){if(h){for(var g=0;g<h.length;g++){a(h[g])}}};WebP.isSupport(function(g){d=g;a(c("J_ImgBooth"));b(c("J_UlThumb").getElementsByTagName("img"));if(d){g_config.beacon.webp=1}})})(true,true);
</script>
  </div>
  
  <div id="J_Social" data-spm="20140010" class="tb-social tb-clearfix">
  <ul>
  <li class="tb-social-like">
  <a data-spm-click="gostr=/tbdetail;locaid=d1" href="javascript:;"
  shortcut-key="x"
  shortcut-label="喜欢宝贝"
  shortcut-effect="click">
  <i class="tb-icon"></i> 喜欢宝贝
  </a>

=end
=begin
<ul class="attributes-list">
    <li title=" 羊毛">靴筒内里材质: 羊毛</li><li title=" 羊皮毛一体">靴筒材质: 羊皮毛一体</li><li title=" 5828">货号: 5828</li><li title=" 2014年冬季">上市年份季节: 2014年冬季</li><li title=" 甜美">风格: 甜美</li><li title=" 羊皮 羊皮毛一体">帮面材质: 羊皮 羊皮毛一体</li><li title=" 羊毛">鞋面内里材质: 羊毛</li><li title=" 磨砂">皮质特征: 磨砂</li><li title=" 橡胶">鞋底材质: 橡胶</li><li title=" 中筒靴">筒高: 中筒靴</li><li title=" 圆头">鞋头款式: 圆头</li><li title=" 平跟(小于等于1cm)">跟高: 平跟(小于等于1cm)</li><li title=" 平跟">鞋跟款式: 平跟</li><li title=" 前系带">闭合方式: 前系带</li><li title=" 丝带">流行元素: 丝带</li><li title=" 缝制鞋">制作工艺: 缝制鞋</li><li title=" 黑色 豹纹 栗色 玫红色 西瓜红色 梦幻紫色 布纹色粉色豹纹 布纹色梦幻紫色 灰小宝 黑小贝 布纹色黑色">颜色分类: 黑色 豹纹 栗色 玫红色 西瓜红色 梦幻紫色 布纹色粉色豹纹 布纹色梦幻紫色 灰小宝 黑小贝 布纹色黑色</li><li title=" 36 37 38 39 40">尺码: 36 37 38 39 40</li><li title=" 冬季">适合季节: 冬季</li><li title=" 201-500元">价格区间: 201-500元</li><li title=" 1.2">毛重: 1.2</li>      
</ul>
=end
=begin
<div id="J_cookieDomain" data-value='.taobao.com'></div><div id="J_itemViewed" catId="50012028" data-value='{"url":"http://item.taobao.com/item.htm?id=41916334072","itemId":"41916334072","xid":"","pic":"i2/TB1l5qZGFXXXXblXXXXXXXXXXXX_!!0-item_pic.jpg","price":"24800","itemIdStr":"41916334072","title":"厂家直销5828羊皮毛一体前系带蝴蝶结雪地靴"}'></div><div id="J_showContract" data-value='{"1":"true","3":"false","2":"false","8":"false","7":"false","4":"false","5":"false","9":"false","J_TokenCatePathUrl":"http://detailskip.taobao.com/json/show_indemnification.htm?catpath=50006843-50012028","J_TokenInvoice":"false","open_security_btn":"true"}'></div>
=end
=begin
info
(function(){
      g_config.DyBase={iurl:"http://item.taobao.com",purl:"http://paimai.taobao.com",spurl:"http://archer.taobao.com",durl:"http://design.taobao.com",lgurl:"https://login.taobao.com/member/login.jhtml?redirectURL=http%3A%2F%2Flocal_jboss%2Fitem.htm%3Fspm%3Da230r.1.14.266.Pd3tHq%26id%3D35436933197%26ns%3D1%26abbucket%3D8%26mt%3D%26mt%3D",
surl:"http://upload.taobao.com", shurl:"http://shuo.taobao.com", murl:"http://meal.taobao.com" }; g_config.idata={
 item:{
 id:"35436933197", skuComponentFirst: 'true',
  sellerNickGBK:'xinyi1008',
 sellerNick:'xinyi1008',
 rcid:'50002768', cid:'50009106', virtQuantity:'99', holdQuantity:'0', edit:true, status:0,xjcc:false,
desc:false,
price:56.00,
 bnow:true, prepay:true, dbst:1411353903000,tka:false,
 chong:false, ju:false, iju: false, cu: false,  fcat:false, auto:"false", jbid:"",stepdata:{},
  jmark:"",   quickAdd: 1,
     pic: "http://img04.taobaocdn.com/bao/uploaded/i4/18516041611020409/T1OprNFXdaXXXXXXXX_!!0-item_pic.jpg"
}, seller:{
 id:391208516,
 mode: 0,   goldSeller:1,     tad:1,                  shopAge:4,
  status:0
}, shop:{
 id:"61013596",
 url: "http://xinyi1008.taobao.com/",
 pid:"625931249",
 sid:"7",
 xshop:true } } })();
=end            
=begin
sku 
Hub.config.set('sku',{
     promoteUrl:"http://marketing.taobao.com/home/promotion/item_promotion_list.do?itemId=35436933197",promoteReservePrice:"56.00",  
   rstShopId:61013596,    rstItemId:35436933197,
 rstdk: 0 ,
 rstShopcatlist:",925555267,",
 valLoginIndicator: "http://buy.taobao.com/auction/buy.htm?from=itemDetail&x_id=&id=35436933197",
 valFastBuyUrl: "http://buy.taobao.com/auction/fastbuy/fast_buy.htm",  valItemId: "35436933197",
 valImageInfo:{},
   "valCartInfo":{"hotItemsUrl":"http://detailskip.taobao.com/json/cart_recommend_items.htm?shop_id=61013596&seller_id_num=391208516","itemId" : "35436933197","dbNum" : "","cartUrl": "http://cart.taobao.com/cart.htm"},  "apiRelateMarket": "http://tui.taobao.com/recommend?appid=16&count=4&itemid=35436933197",
 "apiAddCart" : "http://cart.taobao.com/add_cart_item.htm?item_id=35436933197&bankfrom=",
 "valVipRate":0,
 "valPointRate" : "0",
       "wholeSibUrl":"http://detailskip.taobao.com/json/sib.htm?itemId=35436933197&sellerId=391208516&p=1&rcid=50002768&sts=504983552,1170940490753769476,1225330942399250560,13589963721932803&chnl=pc&price=5600&shopId=&vd=1&skil=false&pf=1&al=false&ap=0&ss=0&free=1&st=1&ct=1",        "apiItemViews": "http://count.tbcdn.cn/counter3?keys=ICVT_7_35436933197&inc=ICVT_7_35436933197&callback=page_viewcount&sign=7161917ad33be2a493c9729744504d16f2e28",  "apiItemReviews": "http://count.tbcdn.cn/counter3?keys=ICE_3_feedcount-35436933197",
 "apiItemCollects": "http://count.tbcdn.cn/counter3?keys=ICCP_1_35436933197",
 "apiBidCount": "http://detailskip.taobao.com/json/show_bid_count.htm?itemNumId=35436933197&old_quantity=7196&date=1413773103000",
       "valTimeLeft": "53693",
   "apiItemDesc":"http://dsc.taobaocdn.com/i6/350/361/35436933197/TB1UluHGpXXXXcZXVXX8qtpFXXX.desc%7Cvar%5Edesc%3Bsign%5E2cda67c63fa17879a247d4fb6dd7992f%3Blang%5Egbk%3Bt%5E1413384480",    "valItemIdStr":"35436933197",
 "valReviewsApi":"http://rate.taobao.com/detail_rate.htm?userNumId=391208516&auctionNumId=35436933197&showContent=1&currentPage=1&ismore=0&siteID=7",
 "reportApi": "http://item.taobao.com/json/report_api.htm",     "redirectUrl":  "http://item.taobao.com/report_redirect_url.htm" ,   "valShowReviews": false ,
 "valPostFee":{currCityDest:''},
     "apiItemInfo":"http://detailskip.taobao.com/json/ifq.htm?stm=1413773103000&id=35436933197&sid=391208516&sbn=0c2be31526a1c0cef49cf5a3decf1dcd&q=1&ex=0&exs=0&shid=&at=b&ct=1&t=1&reCode=2013.1.4.0",
         coupon:{"couponApi":"http://detailskip.taobao.com/json/activity.htm?itemId=35436933197&sellerId=391208516",
 "couponWidgetDomain":"http://a.tbcdn.cn",
 "cbUrl":"/cross.htm?type=weibo"},
       "valItemInfo":
 {
   "defSelected":
   [],

     "skuMap":
 {
     ";20509:28314;1627207:3232478;":
 {
 "skuId" : "54628573809",
 "oversold":
     "false"
 ,
     "price" : "56.00",
     "stock" :
       "99"
       }
   ,
     ";20509:28315;1627207:3232478;":
 {
 "skuId" : "54628573810",
 "oversold":
     "false"
 ,
     "price" : "56.00",
     "stock" :
       "99"
       }
   ,
     ";20509:28316;1627207:3232478;":
 {
 "skuId" : "54628573811",
 "oversold":
     "false"
 ,
     "price" : "56.00",
     "stock" :
       "99"
       }
   ,
     ";20509:28317;1627207:3232478;":
 {
 "skuId" : "54628573812",
 "oversold":
     "false"
 ,
     "price" : "56.00",
     "stock" :
       "99"
       }
   ,
     ";20509:28318;1627207:3232478;":
 {
 "skuId" : "57338405941",
 "oversold":
     "false"
 ,
     "price" : "56.00",
     "stock" :
       "99"
       }
       }
     
   }
});
           
=end        	
            return ret
        end
end
=begin
<script>g_config = {
 startTime:+new Date,
 prefetch:[],
 beacon:{},   timing:[],   clock:[],   t:"20131018",      ver:"1.9.41",
     st:"201404041900",
 shopVer:2,
 appId: 1 ,
 itemId:"41916334072",
 shopId:"106814608",
 pageId:"41916334072",
 assetsHost:"http://a.tbcdn.cn",
 sellerNick:"uz1114",
 sellerId:"1849936827",
 shopName: "UZ\u540D\u978B\u5E97",
 enable:true,  newDomain:true,  webp:true,  descWebP:false,   asyncStock:true,
 sibFirst:true,   cdn:true,  m_ratio:20,
 p:1.0,     type:"cex"
   ,counterApi:"http://count.tbcdn.cn/counter3?inc=ICVT_7_41916334072&sign=50488410f8bb14e7adc86b61fae7284685c8e&keys=DFX_200_1_41916334072,ICVT_7_41916334072,ICCP_1_41916334072,SCCP_2_106814608"
     ,rateCounterApi:"http://count.tbcdn.cn/counter3?keys=SM_368_sm-1849936827,ICE_3_feedcount-41916334072,SM_368_dsr-1849936827"
     ,priceCutUrl:"http://detailskip.taobao.com/json/pricecutStatic.htm?id=41916334072&rootCatId=50006843"
     ,toolbar:{delay:30, startTime:1415462400000,endTime:1415721600000}     ,lazyload:'#J_DivItemDesc'   ,ap_mods: {poc: [0.001],exit: [0.005],jstracker: [0.0001]}
 ,delayInsurance: false
,tadComponetCdn: true
   };
=end