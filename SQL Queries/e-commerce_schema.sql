-- E-Commerce SQL Data Analysis Project

-- This table stores customer personal details

CREATE TABLE customers(
	customer_id VARCHAR(32) PRIMARY KEY,
	customer_unique_id VARCHAR(32) NOT NULL,
	customer_zip_code_prefix VARCHAR(5),	
	customer_city VARCHAR(32),	
	customer_state VARCHAR(2)
);

-- This table stores customer order details 

CREATE TABLE orders(
	order_id VARCHAR(32) PRIMARY KEY, 	
	customer_id	VARCHAR(32),
	order_status VARCHAR(20),
	order_purchase_timestamp TIMESTAMP,	
	order_approved_at TIMESTAMP,	
	order_delivered_carrier_date TIMESTAMP,	
	order_delivered_customer_date TIMESTAMP,
	order_estimated_delivery_date DATE,
	FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
);


-- This table stores customer's order reviews

CREATE TABLE order_reviews(

	review_id VARCHAR(32),	
	order_id VARCHAR(32),	
	review_score SMALLINT CHECK (review_score BETWEEN 1 AND 5),	
	review_comment_title TEXT,	
	review_comment_message TEXT,	
	review_creation_date TIMESTAMP,	
	review_answer_timestamp TIMESTAMP,
	FOREIGN KEY(order_id) REFERENCES orders(order_id)

);


-- This table stores customer's order payments details

CREATE TABLE order_payments(
	order_id VARCHAR(32), 	
	payment_sequential SMALLINT,	
	payment_type VARCHAR(15),	
	payment_installments SMALLINT,	
	payment_value NUMERIC(10,2),
	FOREIGN KEY(order_id) REFERENCES orders(order_id)

);


-- This table stores product category name translation

CREATE TABLE product_category_name_translation(
	product_category_name TEXT PRIMARY KEY,
	product_category_name_english TEXT
);

--This table stores product details

CREATE TABLE products(
	product_id VARCHAR(32) PRIMARY KEY,
	product_category_name TEXT,
	product_name_length SMALLINT,
	product_description_length SMALLINT,
	product_photos_qty SMALLINT,
	product_weight_gm INT,
	product_length_cm SMALLINT,
	product_height_cm SMALLINT,
	product_width_cm SMALLINT,
    FOREIGN KEY(product_category_name) REFERENCES product_category_name_translation(product_category_name)
);

--This table stores sellers details

CREATE TABLE seller(
	seller_id VARCHAR(32) PRIMARY KEY,
	seller_zip_code_prefix VARCHAR(5),	
	seller_city VARCHAR(50),	 
	seller_state VARCHAR(2)
)

--This table stores order items details

CREATE TABLE order_items(
	order_id VARCHAR(32) REFERENCES orders(order_id),	
	order_item_id SMALLINT,	
	product_id VARCHAR(32) REFERENCES products(product_id),	 	
	seller_id VARCHAR(32) REFERENCES seller(seller_id),		
	shipping_limit_date	TIMESTAMP,
	Price NUMERIC(10,2),	
	freight_value NUMERIC(10,2)
)
















