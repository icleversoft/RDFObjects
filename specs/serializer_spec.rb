require File.dirname(__FILE__) + '/../lib/rdf_objects'
include RDFObject
require 'rexml/document'
describe "RDFObjects should" do
  it "serialize a single object to n-triples" do
    resource = Resource.new('http://example.org/ex/1234')
    resource.relate("[rdf:type]","[foaf:Person]")
    foaf_name = RDF::Literal.new("John Doe")
    foaf_name.language = "en"
    resource.assert("[foaf:name]", foaf_name)
    resource.relate("[foaf:pastProject]","http://dbtune.org/musicbrainz/resource/artist/ddd553d4-977e-416c-8f57-e4b72c0fc746")
    resource.relate("[foaf:homepage]","http://www.theejohndoe.com/")
    ntriples = resource.to_ntriples
    ntriples.should be_kind_of(String)
    ntriples.split("\n").length.should equal(4)
    ntriples[0,29].should ==("<http://example.org/ex/1234> ")
  end
  it "parse the outputted ntriples into an identical resource" do
    resource = Resource.new('http://example.org/ex/1234')
    resource.relate("[rdf:type]","[foaf:Person]")
    foaf_name = RDF::Literal.new("John Doe")
    foaf_name.language = :en
    resource.assert("[foaf:name]", foaf_name)
    resource.relate("[foaf:pastProject]","http://dbtune.org/musicbrainz/resource/artist/ddd553d4-977e-416c-8f57-e4b72c0fc746")
    resource.relate("[foaf:homepage]","http://www.theejohndoe.com/")
    ntriples = resource.to_ntriples
    collection = Parser.parse(ntriples)
    collection['http://example.org/ex/1234'].should ==(resource)
  end
  it "serialize a collection to n-triples" do
    nt = open(File.dirname(__FILE__) + '/files/lcsh.nt').read
    resources = Parser.parse(nt)
    ntriples = resources.to_ntriples
    ntriples.should be_kind_of(String)
    ntriples.split("\n").length.should ==(nt.split("\n").length)
  end  
  
  it "parse the outputted ntriples into an identical collection" do    
    nt = open(File.dirname(__FILE__) + '/files/lcsh.nt').read
    resources = RDFObject::Parser.parse(nt)
    ntriples = resources.to_ntriples
    collection = RDFObject::Parser.parse(ntriples) 
    resources.should ==(collection)
  end
  
  it "serialize a single object to rdf/xml" do
    resource = Resource.new('http://example.org/ex/1234')
    resource.relate("[rdf:type]","[foaf:Person]")
    foaf_name = RDF::Literal.new("John Doe")
    foaf_name.language = :en
    resource.assert("[foaf:name]", foaf_name)
    resource.relate("[foaf:pastProject]","http://dbtune.org/musicbrainz/resource/artist/ddd553d4-977e-416c-8f57-e4b72c0fc746")
    resource.relate("[foaf:homepage]","http://www.theejohndoe.com/")    
    resource.to_xml.should be_kind_of(String)
    lambda { REXML::Document.new(resource.to_xml)}.should_not raise_error
    collection = Parser.parse(resource.to_xml)
    collection['http://example.org/ex/1234'].should ==(resource)
  end
  it "serialize a collection to rdf/xml" do
    nt = open(File.dirname(__FILE__) + '/files/lcsh.nt').read
    resources = RDFObject::Parser.parse(nt)   
    resources.to_xml.should be_kind_of(String)
    lambda { REXML::Document.new(resources.to_xml)}.should_not raise_error    
    collection = Parser.parse(resources.to_xml)
    collection.should ==(resources)
  end 
  
  it "should serialize a blank node to ntriples" do
    bnode = BlankNode.new("blankNode")
    bnode.relate("[rdf:type]", "http://www.w3.org/2002/07/owl#Thing")
    bnode.to_ntriples.should == "_:blankNode <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2002/07/owl#Thing> .\n"
  end
  it "should serialize a blank node to rdf/xml" do
    bnode = BlankNode.new("blankNode")
    bnode.relate("[rdf:type]", "http://www.w3.org/2002/07/owl#Thing")
    xml =<<XML
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"><rdf:Description rdf:nodeID="blankNode"><rdf:type rdf:resource="http://www.w3.org/2002/07/owl#Thing" /></rdf:Description></rdf:RDF>
XML
    bnode.to_xml.should ==(xml.strip)
  end
  
  it "should turn literals into strings when outputting ntriples" do
    resource = Resource.new('http://example.org/ex/1234')
    mod = DateTime.parse('2010-04-19T09:39:00Z')
    resource.assert("http://purl.org/dc/terms/modified", mod)
    resource.to_ntriples.should ==("<http://example.org/ex/1234> <http://purl.org/dc/terms/modified> \"2010-04-19T09:39:00+00:00\"^^<http://www.w3.org/2001/XMLSchema#dateTime> .\n")
  end
  
  it "should output a resource as valid JSON RDF" do
    resource = Resource.new('http://example.org/ex/1234')
    resource.relate("[rdf:type]","[foaf:Person]")
    foaf_name = RDF::Literal.new("John Doe")
    foaf_name.language = :en
    resource.assert("[foaf:name]", foaf_name)
    resource.relate("[foaf:pastProject]","http://dbtune.org/musicbrainz/resource/artist/ddd553d4-977e-416c-8f57-e4b72c0fc746")
    resource.relate("[foaf:homepage]","http://www.theejohndoe.com/")
    collection = Parser.parse(resource.to_json)
    collection[resource.uri].should ==(resource)
  end
  
  it "should output a collection as valid JSON RDF" do
    rss = open(File.dirname(__FILE__) + '/files/rss10-2.xml')
    collection = Parser.parse(rss)
    parsed_collection = Parser.parse(collection.to_json)
    parsed_collection.should ==(collection)
  end
  
  it "should properly serialize an RDF/XML with nested graphs" do
    resource = Resource.new('http://example.org/ex/1234')
    resource.assert("[dc:title]", "Resource #1")
    bnode = BlankNode.new
    bnode.assert("[dc:title]", "Resource #2")
    resource.relate("http://purl.org/dc/terms/hasPart", bnode)
    bnode.relate("http://purl.org/dc/terms/isPartOf", resource)
    bnode2 = BlankNode.new
    bnode2.assert("[dc:title]", "Resource #3")
    resource.relate("http://purl.org/dc/terms/hasPart", bnode2)
    bnode2.relate("http://purl.org/dc/terms/isPartOf", resource)    
    bnode2.relate("[rdfs:seeAlso]",bnode)
    bnode.relate("[rdfs:seeAlso]",bnode2)    
    resource.to_xml(3).should be_kind_of(String)
    collection = Parser.parse(resource.to_xml(3))
    collection[resource.uri].should ==(resource)
    collection[bnode.uri].should ==(bnode)
    collection[bnode2.uri].should ==(bnode2)    
  end
  
  it "should properly escape a Unicode string for ntriples" do
    str = "ЗИНГЕР, ИСААК БАШЕВИС, 1904-1992"
    resource = Resource.new('http://example.org/1')
    resource.assert("[foaf:name]", str)
    resource.to_ntriples.should eql("<http://example.org/1> <http://xmlns.com/foaf/0.1/name> \"\\u0417\\u0418\\u041d\\u0413\\u0415\\u0420, \\u0418\\u0421\\u0410\\u0410\\u041a \\u0411\\u0410\\u0428\\u0415\\u0412\\u0418\\u0421, 1904-1992\" .\n")
  end
end
