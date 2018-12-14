Pod::Spec.new do |spec|
    spec.name               = 'MPDBManager'
    spec.version            = '1.0.0'
    spec.license            = 'BSD'
    spec.summary            = 'SQLITE database access based on FMDB + addidtions'
    spec.homepage           = 'https://github.com/shc-vj/MPDBManager.git' 
    spec.source             = {
        :git => "https://github.com/shc-vj/MPDBManager.git"
    }
    spec.authors             = 'Paweł Czernikowski'
    spec.requires_arc       = 'MPDBManager.m'
    spec.platforms          = {
        :ios => '8.0',
        :osx => '10.8'
    }
    spec.source_files       = 'src'

    spec.pod_target_xcconfig = {
    	'DEFINES_MODULE' => 'YES'
    }
    spec.user_target_xcconfig = {
        'CLANG_ENABLE_MODULES'                                  => 'YES',
        'CLANG_MODULES_AUTOLINK'                                => 'YES',
        'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES'
    }
    
    spec.dependency 'FMDB'
    
end
