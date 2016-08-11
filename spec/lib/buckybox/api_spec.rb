require_relative "../../../lib/buckybox/api"

RSpec.describe BuckyBox::API, :vcr do
  let(:api) do
    BuckyBox::API.new(
      "API-Key" => ENV.fetch("BUCKYBOX_API_KEY", ""),
      "API-Secret" => ENV.fetch("BUCKYBOX_API_SECRET", ""),
    )
  end

  let(:box_id) { 217 }
  let(:delivery_service_id) { 91 }
  let(:customer_id) { 8859 }

  before do
    method = self.class.metadata[:parent_example_group][:description][1..-1]
    VCR.insert_cassette "/#{method}"
  end

  after do
    VCR.eject_cassette
  end

  shared_examples_for "a valid API response" do
    let(:response) { subject }

    specify { expect { response }.not_to raise_error }
    specify { expect([BuckyBox::API::Response, Array]).to include response.class }
  end

  describe "#boxes" do
    subject { api.boxes(embed: "images") }
    it_behaves_like "a valid API response"
  end

  describe "#box" do
    subject { api.box(box_id) }
    it_behaves_like "a valid API response"
  end

  describe "#delivery_services" do
    subject { api.delivery_services }
    it_behaves_like "a valid API response"
  end

  describe "#delivery_service" do
    subject { api.delivery_service(delivery_service_id) }
    it_behaves_like "a valid API response"
  end

  describe "#webstore" do
    subject { api.webstore }
    it_behaves_like "a valid API response"
  end

  describe "#customers" do
    subject { api.customers(email: "joe@buckybox.com") }
    it_behaves_like "a valid API response"
  end

  describe "#customer" do
    subject { api.customer(customer_id, embed: "address") }
    it_behaves_like "a valid API response"
  end

  describe "#authenticate_customer" do
    subject { api.authenticate_customer(email: "joe@buckybox.com", password: "nope") }
    it_behaves_like "a valid API response"
  end

  describe "#create_or_update_customer" do
    let(:customer) do
      {
        id: customer_id,
        first_name: "Joe",
      }
    end

    subject { api.create_or_update_customer(JSON.dump(customer)) }
    it_behaves_like "a valid API response"
  end

  describe "#create_order" do
    let(:order) do
      {
        customer_id: customer_id,
        box_id: box_id,
        start_date: "2016-08-09",
        week_days: [2],
        frequency: "single",
        payment_method: "cash_on_delivery",
      }
    end

    subject { api.create_order(JSON.dump(order)) }
    it_behaves_like "a valid API response"
  end
end
