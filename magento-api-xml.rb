require "xmlrpc/client"
require "base64"

class MagentoAPI

  def initialize(url, username, password)
    @server = XMLRPC::Client.new(url, "/api/xmlrpc/")
    # Login and get session id
    @session_id = @server.call("login", username, password)
    # Get the current store id from magento
    @current_store_id = @server.call("call", @session_id, "catalog_product.currentStore")
  end

  # Returns new product id
  def create_product sku, category_id, price, description, image_path
    # Layout traits for a sample product
    product_data = {:store => "admin", :store_id => @current_store_id, :product_type_id => "simple",
                    :product_name => sku, :enable_qty_increments => 0, :use_config_enable_qty_increments => 1,
                    :qty_increments => 0, :use_config_qty_increments => 1, :stock_status_changed_automatically => 1,
                    :use_config_manage_stock => 1, :manage_stock => 0, :use_config_notify_stock_qty => 1,
                    :is_in_stock => 0, :use_config_max_sale_qty => 1, :max_sale_qty => 0, :use_config_min_sale_qty => 1,
                    :min_sale_qty => 1, :use_config_backorders => 1, :backorders => 0, :is_qty_decimal => 0,
                    :use_config_min_qty => 1, :min_qty => 0, :qty => 0, :is_recurring => "No", :enable_googlecheckout => "No",
                    :tax_class_id => 2, :visibility => 4, :status => 1, :weight => 1, :gift_message_available => "No",
                    :websites => "base", :name => sku, :price => price, :description => description, :short_description => description}
    # Create a product using the above attributes (type, attribute_set_id, sku, product_data)
    new_product_id = @server.call("call", @session_id, "catalog_product.create", ["simple", 4, sku, product_data])
    # After creating the product assign that product to a category
    assign_product_to_category category_id, new_product_id
    if !image_path.nil?
      # After assigning to a category then upload the product image
      upload_image_to_product sku, image_path
    end
    return new_product_id
  rescue XMLRPC::FaultException => exception
    return exception
  end

  # Returns true or false on success or failure
  def assign_product_to_category category_id, product_id
    # Assign the product to a category
    @server.call("call", @session_id, "catalog_category.assignProduct", [category_id, product_id])
  rescue XMLRPC::FaultException => exception
    return exception
  end

  # Returns the name of the image uploaded
  def upload_image_to_product product_sku, image_path
    # Upload an image to the product
    @server.call("call", @session_id, "catalog_product_attribute_media.create", [product_sku, {"file" => {"content" => Base64.encode64(File.open(image_path, "rb").read), "mime" => "image/jpeg", "name" => File.basename(image_path, ".jpg")}, "exclude" => 0, "types" => ["image", "small_image", "thumbnail"]}])
  rescue XMLRPC::FaultException => exception
    return exception
  end

  # Returns true or false on success or failure
  def add_product_relation from_product_id, to_product_id
    # Add related products
    @server.call("call", @session_id, "catalog_product_link.assign", ["related", from_product_id, to_product_id])
  rescue XMLRPC::FaultException => exception
    return exception
  end

  # Returns product info about the product requested
  def get_product product_id
    # Retrieve the product that was just created
    @server.call("call", @session_id, "catalog_product.info", [product_id, @current_store_id, ["image"]])
  rescue XMLRPC::FaultException => exception
    return exception
  end

  # Returns all of the products in the cart
  def get_all_products
    # Get all the products
    @server.call("call", @session_id, "catalog_product.list")
  rescue XMLRPC::FaultException => exception
    return exception
  end

  # Returns the id of the new category
  def create_category category_parent_id, category_name
    # Create a new category
    @server.call("call", @session_id, "catalog_category.create", [category_parent_id, {:name => category_name, :is_active => 1, :include_in_menu => 1, :available_sort_by => "*", :default_sort_by => 0}])
  rescue XMLRPC::FaultException => exception
    return exception
  end
end
