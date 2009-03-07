require 'pathname'
require Pathname(__FILE__).dirname + '../spec_helper'

require 'resourceful/rd_http_adapter'
require 'facets'

describe Resourceful::RdHttpAdapter do
  describe "(when making request)" do
    before do
      @adapter = Resourceful::RdHttpAdapter.new

      @request = request = ""
      @server_conn = stub("server_conn", :close => nil, :flush => nil)
      @server_conn.eigenclass.class_eval do
        define_method(:write) {|req| request << req}
      end

      Socket.stub!(:new).and_return(@server_conn)
    end

    it "should create a socket to correct host" do
      Socket.should_receive(:new).with("foo.invalid", anything)

      @adapter.make_request(:get, u("http://foo.invalid/"))
    end 

    it "should create a socket to correct implicit port" do
      Socket.should_receive(:new).with(anything, 80)

      @adapter.make_request(:get, u("http://foo.invalid/"))
    end 

    it "should create a socket to correct explicit port" do
      Socket.should_receive(:new).with(anything, 8080)
      @adapter.make_request(:get, u("http://foo.invalid:8080/"))
    end 

    def self.it_should_send_correct_method(method)
      it "should send correct request method for #{method} requests" do
        @adapter.make_request(method, u("http://foo.invalid/"))
        request_start_line.should match(/^#{method.to_s.upcase} /i)
      end
    end

    it_should_send_correct_method(:get)
    it_should_send_correct_method(:put)
    it_should_send_correct_method(:post)
    it_should_send_correct_method(:delete)
    it_should_send_correct_method(:head)

    it "should send correct request uri for implicit port" do
      @adapter.make_request(:get, u("http://foo.invalid/"))
      request_start_line.should match(%r{ http://foo.invalid/ }i)
    end

    it "should send correct request uri for explicit port" do
      @adapter.make_request(:get, u("http://foo.invalid:8080/"))
      request_start_line.should match(%r{ http://foo.invalid:8080/ }i)
    end

    it "should send correct HTTP version" do
      @adapter.make_request(:get, u("http://foo.invalid:8080/"))
      request_start_line.should match(%r{ HTTP/1.1$}i)  
    end 

    it "should send specified body" do
      @adapter.make_request(:post, u("http://foo.invalid/"), "hello there")
      request_lines.last.should eql("hello there")
    end 

    it "should have a blank line between the header and body" do
      @adapter.make_request(:post, u("http://foo.invalid/"), "hello there")
      request_lines[-2].should eql("")
    end 

    it "should have a blank line after header even when there is not body" do
      @adapter.make_request(:get, u("http://foo.invalid/"))
      request_lines.last.should eql("")
    end 

    it "should render header fields to request" do
      @adapter.make_request(:get, u("http://foo.invalid/"), nil, {'X-Test-Header' => "a header value"})
      request_lines.should include("X-Test-Header: a header value")
    end 

    it "should render compound header fields to request" do
      @adapter.make_request(:get, u("http://foo.invalid/"), nil, {'X-Test-Header' => ["header value 1", "header value 2"]})
      request_lines.should include("X-Test-Header: header value 1")
      request_lines.should include("X-Test-Header: header value 2")
    end 

    it "should set content-length header field if a body is specified" do
      @adapter.make_request(:post, u("http://foo.invalid/"), "hello there")
      request_lines.should include("Content-Length: 11")
    end 

    it "should not set content-length header field if a body is not specified" do
      @adapter.make_request(:post, u("http://foo.invalid/"))
      request_lines.grep(/Content-Length/).should be_empty
    end 


    it "should flush socket after it is done" do
      @server_conn.should_receive(:flush)
      @adapter.make_request(:get, u("http://foo.invalid/"))
    end

    it "should close socket after it is done" do
      @server_conn.should_receive(:close)
      @adapter.make_request(:post, u("http://foo.invalid/"))
    end
 
    def request_start_line
      request_lines.first
    end

    def request_lines
      @request.split("\r\n", -1)
    end
  end 

  def u(uri)
    Addressable::URI.parse(uri)
  end
end 
