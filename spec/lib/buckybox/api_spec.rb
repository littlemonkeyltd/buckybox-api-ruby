require_relative "../../../lib/buckybox/api"

RSpec.describe BuckyBox::API, :vcr do
  let(:api) do
    BuckyBox::API.new(
      "API-Key" => ENV.fetch("BUCKYBOX_API_KEY"),
      "API-Secret" => ENV.fetch("BUCKYBOX_API_SECRET"),
    )
  end

  before do
    method = self.class.metadata[:parent_example_group][:description][1..-1]
    VCR.insert_cassette("/#{method}", record: :once)
  end

  after do
    VCR.eject_cassette
  end

  shared_examples_for "a valid API response" do
    let(:response) { subject }

    specify { expect { response }.not_to raise_error }
    specify { expect(response).to be_an_instance_of SuperRecursiveOpenStruct }
  end

  shared_examples_for "an invalid API response" do
    let(:response) { subject }

    it "returns an error when posting invalid params" do
      expect { response }.to raise_error BuckyBox::API::ResponseError
    end
  end

  describe "#boxes" do
    subject { api.boxes(embed: "images") }
    it_behaves_like "a valid API response"
  end

  describe "#box" do
    subject { api.box(ENV.fetch("BUCKYBOX_BOX_ID"), {}) }
    it_behaves_like "a valid API response"

    it "raises NotFoundError if not found" do
      expect { api.box(0) }.to raise_error BuckyBox::API::NotFoundError
    end
  end

  describe "#delivery_services" do
    subject { api.delivery_services }
    it_behaves_like "a valid API response"
  end

  describe "#delivery_service" do
    subject { api.delivery_service(ENV.fetch("BUCKYBOX_DELIVERY_SERVICE_ID")) }
    it_behaves_like "a valid API response"
  end

  describe "#webstore" do
    subject { api.webstore }
    it_behaves_like "a valid API response"
  end

  describe "#customers" do
    subject { api.customers }
    it_behaves_like "a valid API response"
  end

  describe "#customer" do
    subject { api.customer(ENV.fetch("BUCKYBOX_CUSTOMER_ID")) }
    it_behaves_like "a valid API response"
  end

  describe "#authenticate_customer" do
    subject { api.authenticate_customer(email: "joe@example.net", password: "nope") }
    it_behaves_like "a valid API response"
  end

  describe "#create_or_update_customer" do
    subject { api.create_or_update_customer(JSON.dump({})) }
    it_behaves_like "an invalid API response"
  end

  describe "#create_order" do
    subject { api.create_order(JSON.dump({})) }
    it_behaves_like "an invalid API response"
  end
end
