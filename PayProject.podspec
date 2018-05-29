
Pod::Spec.new do |s|
s.name         = "PayProject"
s.version      = "0.0.1"
s.summary      = "支付"
s.homepage     = "https://github.com/GuiFoA/YLEdgeLabel.git"
s.license      = { :type => 'MIT', :file => 'LICENSE' }
s.author       = { "Yang Lin" => "lin897839@gmail.com" }
s.source       = { :git => "https://github.com/randy-Zhang/PayProject.git", :tag => "0.0.1" }
s.platform     = :ios, '8.0'
s.requires_arc = true
s.source_files = 'PayProject/*.{h,m}'
s.requires_arc = true
end
