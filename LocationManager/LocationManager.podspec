Pod::Spec.new do |s|
s.name         = "PodTest"
s.version      = "1.0.0"
s.summary      = "A location manager."

s.homepage     = "https://github.com/MissWang/PodTest"
s.license      = 'MIT'
s.author       = { "XXX" => "196640996@qq.com" }
s.platform     = :ios, "7.0"
s.ios.deployment_target = "7.0"
s.source       = { :git => "https://github.com/MissWang/PodTest.git", :tag => s.version}
s.source_files  = 'LocationManager/LocationManager/*.{swift}'
s.requires_arc = true
end