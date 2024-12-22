#! /bin/bash

tbl_agency='CREATE TABLE agency (
	agency_id TEXT UNIQUE
	agency_name TEXT NOT NULL
	agency_url TEXT NOT NULL
	agency_timezone TEXT NOT NULL
	agency_lang TEXT
	agency_phone TEXT
	agency_fare_url TEXT
	agency_email TEXT
);';

tbl_attributions='CREATE TABLE attributions (
	attribution_id TEXT UNIQUE
	agency_id TEXT
	route_id TEXT
	trip_id TEXT
	organization_name TEXT NOT NULL
	is_producer INTEGER DEFAULT 0
	is_operator INTEGER DEFAULT 0
	is_authority INTEGER DEFAULT 0
	attribution_url TEXT
	attribution_email TEXT
	attribution_phone TEXT
);';

tbl_calendar='CREATE TABLE calendar (
	service_id TEXT NOT NULL UNIQUE
	monday INTEGER NOT NULL
	tuesday INTEGER NOT NULL
	wednesday INTEGER NOT NULL
	thursday INTEGER NOT NULL
	friday INTEGER NOT NULL
	saturday INTEGER NOT NULL
	sunday INTEGER NOT NULL
	start_date TEXT NOT NULL
	end_date TEXT NOT NULL
);';

tbl_feed_info="CREATE TABLE feed_info (
	feed_publisher_name TEXT NOT NULL
	feed_publisher_url TEXT NOT NULL
	feed_lang TEXT NOT NULL
	default_lang TEXT
	feed_start_date INTEGER
	feed_end_date INTEGER
	feed_version TEXT
	feed_contact_email TEXT
	feed_contact_url TEXT
);";

tbl_levels='CREATE TABLE levels (
	level_id TEXT NOT NULL UNIQUE
	level_index REAL NOT NULL
	level_name TEXT
);';

tbl_shapes='CREATE TABLE shapes (
	shape_id TEXT NOT NULL
	shape_pt_lat TEXT NOT NULL
	shape_pt_lon TEXT NOT NULL
	shape_pt_sequence INTEGER NOT NULL
	shape_dist_traveled REAL
);';

tbl_translations='CREATE TABLE translations (
	table_name TEXT NOT NULL
	field_name TEXT NOT NULL
	language TEXT NOT NULL
	translation TEXT NOT NULL
	record_id TEXT
	record_sub_id TEXT
	field_value TEXT
);';

tbl_calendar_dates='CREATE TABLE calendar_dates (
	service_id INTEGER NOT NULL
	date INTEGER NOT NULL
	exception_type INTEGER
	
	FOREIGN KEY (service_id) 	REFERENCES calendar (service_id) 	ON DELETE NO ACTION ON UPDATE NO ACTION
);';

tbl_routes='CREATE TABLE routes (
	route_id TEXT PRIMARY KEY
	agency_id TEXT NOT NULL
	route_short_name TEXT
	route_long_name TEXT NOT NULL
	route_desc TEXT
	route_type INTEGER
	route_url TEXT
	route_color TEXT
	route_text_color TEXT
	route_sort_order INTEGER
	continuous_pickup INTEGER
	continuous_drop_off INTEGER
	
	FOREIGN KEY (agency_id) 	REFERENCES agency (agency_id)			ON DELETE NO ACTION ON UPDATE NO ACTION
);';

tbl_stops='CREATE TABLE stops (
	stop_id TEXT PRIMARY KEY
	stop_code TEXT
	stop_name TEXT NOT NULL
	stop_desc TEXT
	stop_lat TEXT NOT NULL
	stop_lon TEXT NOT NULL
	zone_id TEXT
	stop_url TEXT
	location_type INTEGER DEFAULT 0
	parent_station INTEGER
	stop_timezone TEXT
	wheelchair_boarding INTEGER DEFAULT 0
	level_id TEXT
	platform_code TEXT
	
	FOREIGN KEY (level_id) 	REFERENCES levels (level_id)			ON DELETE NO ACTION ON UPDATE NO ACTION
);';

tbl_stop_times='CREATE TABLE stop_times (
	trip_id TEXT NOT NULL
	arrival_time TEXT NOT NULL
	departure_time TEXT NOT NULL
	stop_id TEXT NOT NULL
	stop_sequence INTEGER NOT NULL
	stop_headsign TEXT
	pickup_type INTEGER DEFAULT 0
	drop_off_type INTEGER DEFAULT 0
	continuous_pickup INTEGER DEFAULT 1
	continuous_drop_off INTEGER DEFAULT 1
	shape_dist_traveled REAL
	timepoint INTEGER
	
	FOREIGN KEY (trip_id)		REFERENCES trips (trip_id) 				ON DELETE NO ACTION ON UPDATE NO ACTION
	FOREIGN KEY (stop_id) 		REFERENCES stops (stop_id) 				ON DELETE NO ACTION ON UPDATE NO ACTION
);';

tbl_trips='CREATE TABLE trips (
	route_id TEXT NOT NULL
	service_id TEXT NOT NULL
	trip_id TEXT PRIMARY KEY
	trip_headsign TEXT
	trip_short_name TEXT
	direction_id INTEGER
	block_id INTEGER
	shape_id INTEGER
	wheelchair_accessible INTEGER DEFAULT 0
	bikes_allowed INTEGER DEFAULT 0
 	vehicle_category_id TEXT
	
	FOREIGN KEY (route_id) 		REFERENCES routes (route_id) 			ON DELETE NO ACTION ON UPDATE NO ACTION
	FOREIGN KEY (service_id) 	REFERENCES calendar_dates (service_id) 	ON DELETE NO ACTION ON UPDATE NO ACTION
	FOREIGN KEY (shape_id) 		REFERENCES shapes (shape_id) 			ON DELETE NO ACTION ON UPDATE NO ACTION
	FOREIGN KEY (block_id) 		REFERENCES trips (trip_id)				ON DELETE NO ACTION ON UPDATE NO ACTION
);';

tbl_transfers='CREATE TABLE transfers (
	from_stop_id TEXT NOT NULL
	to_stop_id TEXT NOT NULL
	from_trip_id TEXT NOT NULL
	to_trip_id TEXT NOT NULL
	from_route_id TEXT NOT NULL
	to_route_id TEXT NOT NULL
	transfer_type INTEGER DEFAULT 0
	min_transfer_time INTEGER
	
	FOREIGN KEY (from_stop_id) 	REFERENCES stops (stop_id)			ON DELETE NO ACTION ON UPDATE NO ACTION
	FOREIGN KEY (to_stop_id) 	REFERENCES stops (stop_id)			ON DELETE NO ACTION ON UPDATE NO ACTION
	FOREIGN KEY (from_trip_id) 	REFERENCES trip (trip_id)			ON DELETE NO ACTION ON UPDATE NO ACTION
	FOREIGN KEY (to_trip_id) 	REFERENCES trip (trip_id)			ON DELETE NO ACTION ON UPDATE NO ACTION
	FOREIGN KEY (from_route_id) REFERENCES routes (route_id)		ON DELETE NO ACTION ON UPDATE NO ACTION
	FOREIGN KEY (to_route_id) 	REFERENCES routes (route_id)		ON DELETE NO ACTION ON UPDATE NO ACTION
);';

tbl_frequencies='CREATE TABLE frequencies (
	trip_id TEXT NOT NULL
	start_time TEXT NOT NULL
	end_time NOT NULL
	headway_secs INTEGER NOT NULL
	exact_times INTEGER DEFAULT 0
	
	FOREIGN KEY (trip_id) 	REFERENCES trip (trip_id)				ON DELETE NO ACTION ON UPDATE NO ACTION
);';

tbl_fare_attributes='CREATE TABLE fare_attributes (
	fare_id TEXT NOT NULL UNIQUE
	price REAL NOT NULL
	currency_type TEXT NOT NULL
	payment_method INTEGER NOT NULL
	transfers INTEGER NOT NULL
	agency_id TEXT
	transfer_duration INTEGER
	
	FOREIGN KEY (agency_id) 	REFERENCES agency (agency_id)			ON DELETE NO ACTION ON UPDATE NO ACTION
);';

tbl_fare_rules='CREATE TABLE fare_rules (
	fare_id TEXT NOT NULL
	route_id TEXT
	origin_id TEXT
	destination_id TEXT
	contains_id TEXT
	
	FOREIGN KEY (fare_id) 		REFERENCES fare_attributes (fare_id)	ON DELETE NO ACTION ON UPDATE NO ACTION
	FOREIGN KEY (route_id) 		REFERENCES routes (route_id) 			ON DELETE NO ACTION ON UPDATE NO ACTION
	FOREIGN KEY (origin_id) 	REFERENCES stops (zone_id)				ON DELETE NO ACTION ON UPDATE NO ACTION
	FOREIGN KEY (destination_id)REFERENCES stops (zone_id)				ON DELETE NO ACTION ON UPDATE NO ACTION
	FOREIGN KEY (contains_id) 	REFERENCES stops (zone_id)				ON DELETE NO ACTION ON UPDATE NO ACTION
);';

tbl_pathways='CREATE TABLE pathways (
	pathway_id TEXT NOT NULL UNIQUE
	from_stop_id TEXT NOT NULL
	to_stop_id TEXT NOT NULL
	pathway_mode INTEGER NOT NULL
	is_bidirectional INTEGER NOT NULL
	length REAL
	traversal_time INTEGER
	stair_count INTEGER
	max_slope REAL
	min_width REAL
	signposted_as TEXT
	reversed_signposted_as TEXT
	
	FOREIGN KEY (from_stop_id) 	REFERENCES stops (stop_id)			ON DELETE NO ACTION ON UPDATE NO ACTION
	FOREIGN KEY (to_stop_id) 	REFERENCES stops (stop_id)			ON DELETE NO ACTION ON UPDATE NO ACTION
);';

idx_all='CREATE UNIQUE INDEX idx_agency_id 	ON agency (agency_id);
	CREATE INDEX idx_route_long_name 		ON routes (route_long_name);
	CREATE INDEX idx_departure_time 		ON stop_times (departure_time);
	CREATE INDEX idx_arrival_time 			ON stop_times (arrival_time);
	CREATE INDEX idx_date 					ON calendar_dates (date);
	CREATE INDEX idx_stop_name 				ON stops (stop_name);
	CREATE INDEX idx_shape_id 				ON shapes (shape_id, shape_pt_sequence);
	CREATE UNIQUE INDEX idx_service_id_cal 	ON calendar (service_id);
	CREATE UNIQUE INDEX idx_level_id 		ON levels (level_id);
	CREATE UNIQUE INDEX idx_attribution_id	ON attributions (attribution_id);
	CREATE UNIQUE INDEX idx_pathway_id		ON pathways (pathway_id);
	CREATE UNIQUE INDEX idx_fare_id			ON fare_attributes (fare_id);';

rm -f $1/trains.db;

gtfs_files="agency attributions calendar feed_info levels shapes translations calendar_dates routes stops stop_times trips transfers frequencies fare_attributes fare_rules pathways";

for file in $gtfs_files; do
	if [ ! -f $1./$file.txt ]; then
    	continue;
	fi	
	
	sed 's/\r//g' $1$file.txt > /tmp/$file.txt;
	
	header=$(head -n 1 "/tmp/$file.txt" | sed 's/\"//g');
	echo $file;
	
	data_sql=tbl_$file;
	sql=$(echo "${!data_sql}" | grep "CREATE");
	f_sql="";
	for c_header in ${header//,/ }; do
		tmp2=$(echo "${!data_sql}" | grep -w "$c_header" | grep -v "FOREIGN");
		tmp=$(echo "${!data_sql}" | grep "KEY ($c_header)");
		sql="$sql
		$tmp2,";
		
		if [[ ! -z $tmp ]]; then
			f_sql="$f_sql
			$tmp,";
		fi;
	done;
	if [[ ! -z $f_sql ]]; then
		sql="$sql
		$f_sql";
	fi;
	tmp3=$(echo "$idx_all" | grep -w "$file" | grep -w "${header//,/\\|}");
	sql="${sql::-1});
	$tmp3";
	
	# echo "$sql" | sqlite3 db.sqlite3;
	echo "$sql" | sqlite3 $1trains.db;
	
	tail -n +2 /tmp/$file.txt > /tmp/sqlite.tmp;
	# printf ".mode csv \n.separator \",\" \n.import /tmp/sqlite.tmp $file\n" | sqlite3 db.sqlite3;
	printf ".mode csv \n.separator \",\" \n.import /tmp/sqlite.tmp $file\n" | sqlite3 $1trains.db;
	
	rm -f /tmp/sqlite.tmp;
	rm -f /tmp/$file.txt;
done;
