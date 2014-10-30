if ENV['RAILS_ENV'] == "development"
$SETTINGS=
     {
        :git_server=>"localhost",
        :repo_root=>"/var/mygithub",
        :workspace_root=>"./tmp/workspaces",
        :appstore_query_app_url=>"http://appstore.anywhere.cn/app/query_app",
        # :console_log=>"/home/jackie/jetty-distribution-9.1.4.v20140401/logs/%04d_%02d_%02d.stderrout.log"
        :console_log=>"/Users/i027910/Desktop/SAP/src/oce/log/development.log",
        :submit_url=>"http://127.0.0.1:3001/app/presubmit",
        :ui_root_dir=>"/opt/share/sfaattachment/T%s/rtspace",

        :oauth_server_url_authorize=>"https://test-taobaolike.myshopify.com/admin/oauth/authorize",
        :oauth_server_url_token=>"https://test-taobaolike.myshopify.com/admin/oauth/access_token",
        :oauth_client_secret=>"e18566da5282ecf67a3649e079db56a6",        
        :oauth_client_id=>"8a1e8ca0d914075ed99c42f34b5beffe",
        :host=>"shop.joyqom.com",
        :port=>"4433",
        
        # for taobao
        :imgdb_fs_home=>"/Users/i027910/www/s.joyqom.com/htdocs/imgdb",
        :imgdb_url_prefix=>"http://s.joyqom.com",
        :tb_item_db_home=>"/Users/i027910/www/s.joyqom.com/htdocs/tbitmes"
               
    }


else
    $SETTINGS=
         {
            :git_server=>"localhost",
            :repo_root=>"/var/mygithub",
            :workspace_root=>"./tmp/workspaces",
            # :appstore_query_app_url=>"http://127.0.0.1:3001/app/query_app",
            :appstore_query_app_url=>"http://appstore.anywhere.cn/app/query_app",
            :console_log=>"/home/jackie/jetty-distribution-9.1.4.v20140401/logs/%04d_%02d_%02d.stderrout.log",
            :submit_url=>"http://10.58.113.181:3001/app/presubmit",
            # ui full path:
            # /opt/share/sfaattachment/T1/rtspace/com.cid.oms/src/resources/UI-INF
            #/opt/share/sfaattachment is configed in sld
            # T1 is tenant id (not tenant name)
            # com.cid.oms is app bundle id (appid)
            # content under src is ui content
            :ui_root_dir=>"/opt/share/sfaattachment/T%s/rtspace",
            :oauth_server_url_authorize=>"https://10.58.118.63:8444/sld/oauth2/authorize",
            :oauth_server_url_token=>"https://10.58.118.63:8444/sld/oauth2/token",
            :oauth_client_secret=>"vkNfMXd0zN-zQ3-l3vFnokRBoqqF",
            :oauth_client_id=>"4874805429075418-yFNLByquAI63nUMkOxdZUoehmI0c85Um",
            :host=>"shop.joyqom.com",
            :port=>"4433",
            
            # for taobao
            :imgdb_fs_home=>"/Users/i027910/www/s.joyqom.com/htdocs/imgdb",
            :imgdb_url_prefix=>"http://s.joyqom.com",
            :tb_item_db_home=>"/Users/i027910/www/s.joyqom.com/htdocs/tbitmes"
        }
end


$FS_RT_ROOT = "/var/sa"
$FS_EXT_ROOT = "extension"
$FS_RT_EXT_ROOT = "#{$FS_RT_ROOT}/script/extroot"

    
