
Pod::Spec.new do |s|
s.name         = "PayProject"
s.version      = "0.0.1"
s.summary      = "支付"
s.homepage     = "https://github.com/randy-Zhang/PayProject.git"
s.license      = { :type => 'MIT', :file => 'LICENSE' }
s.author       = { "Randy-Zhang" => "908990229@qq.com" }
s.source       = { :git => "https://github.com/randy-Zhang/PayProject.git", :tag => "0.0.1" }
s.platform     = :ios, '8.0'
s.requires_arc = true
s.source_files = 'PayProject/Manager/*.{h,m}'
s.requires_arc = true
end
