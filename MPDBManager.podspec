Pod::Spec.new do |spec|
    spec.name               = 'SBJson'
    spec.version            = '5.0.1'
    spec.license            = 'BSD'
    spec.summary            = 'Chunk-based JSON parser for Objective-C'
    spec.description        =  'Using this library you can reduce the apparent latency for each\n    download/parse cycle of documents over a slow connection. You can start\n    parsing and feed chunks of the parsed document to your app before the entire\n    document is downloaded.\n\n    Feed the parser one or more chunks of UTF8-encoded data and it will call a\n    block you provide with each root-level document or array. Or, optionally,\n    for each top-level entry in each root-level array.\n\n    This pod is identical to SBJson5, except that can be installed alongside\n    SBJson v3.x. or SBJson4. This is handy if you want to use version 5 but rely on a\n    library that depends on a previous version.\n'
    spec.homepage           = 'https://github.com/shc-vj/json-framework.git' 
    spec.source             = {
        :git => "https://github.com/shc-vj/json-framework.git",
        :tag => spec.version.to_s
    }
    spec.authors             = { 
        'Stig Brautaset' => 'stig@brautaset.org'
    }
    spec.requires_arc       = true
    spec.platforms          = {
        :ios => '5.0',
        :osx => '10.7'
    }
    spec.source_files       = 'Classes'
    spec.public_header_files  = 'Classes/SBJson5{,Parser,StreamParser,RecordParser,StreamWriter,Writer,StreamTokeniser}.h'
end
