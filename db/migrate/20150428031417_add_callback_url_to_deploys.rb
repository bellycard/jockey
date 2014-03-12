class AddCallbackUrlToDeploys < ActiveRecord::Migration
  def change
    add_column :deploys, :callback_url, :string
  end
end
