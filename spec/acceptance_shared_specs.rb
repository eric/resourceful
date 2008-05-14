describe 'redirect', :shared => true do
  it 'should be followed by default on GET' do
    resp = @resource.get
    resp.should be_instance_of(Resourceful::Response)
    resp.code.should == 200
    resp.header['Content-Type'].should == ['text/plain']
  end

  %w{PUT POST DELETE}.each do |method|
    it "should not be followed by default on #{method}" do
      resp = @resource.send(method.downcase.intern)
      resp.should be_instance_of(Resourceful::Response)
      resp.code.should == @redirect_code
    end

    it "should redirect on #{method} if the redirection callback returns true" do
      @resource.on_redirect { true }
      resp = @resource.send(method.downcase.intern)
      resp.code.should == 200
    end

    it "should not redirect on #{method} if the redirection callback returns false" do
      @resource.on_redirect { false }
      resp = @resource.send(method.downcase.intern)
      resp.code.should == @redirect_code
    end
  end

end
