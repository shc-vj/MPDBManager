Pod::Spec.new do |spec|
    spec.name               = 'MPDBManager'
    spec.version            = '1.0.0'
    spec.license            = 'BSD'
    spec.summary            = 'SQLITE database access based on FMDB + addidtions'
    spec.homepage           = 'https://github.com/shc-vj/MPDBManager.git' 
    spec.source             = {
        :git => "https://github.com/shc-vj/MPDBManager.git",
        :tag => spec.version.to_s
    }
    spec.authors             = { 
        'Paweł Czernikowski'
    }
    spec.requires_arc       = true
    spec.platforms          = {
        :ios => '6.0',
        :osx => '10.7'
    }
    spec.source_files       = 'src'
    spec.public_header_files  = 'src/*'
end