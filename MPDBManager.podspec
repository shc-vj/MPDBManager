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
    
    spec.platforms          = {
			:ios => '7.0',
			:osx => '10.8'
		}

    spec.subspec 'Core' do |sp1|
		sp1.requires_arc       = 'MPDBManager.m'
		sp1.platforms          = {
			:ios => '7.0',
			:osx => '10.8'
		}
		sp1.source_files       = 'src/Objc'

		sp1.user_target_xcconfig = {
			'CLANG_ENABLE_MODULES'                                  => 'YES',
			'CLANG_MODULES_AUTOLINK'                                => 'YES',
			'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES'
		}
	
		sp1.dependency 'FMDB'
	end
	
	spec.subspec 'Swift' do |sp2|
		sp2.platforms          = {
			:ios => '7.0',
			:osx => '10.8'
		}

		sp2.source_files		= 'src/Swift'
		sp2.dependency	'MPDBManager/Core'
	end
    
end
