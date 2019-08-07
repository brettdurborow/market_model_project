function conn=connect_to_mysql(database_name)

% For testing purposes, we recreate the AMMD database on localhost.
conn=database(database_name,'pirenzi','S7mMLy9v','Vendor','MySQL','Server','localhost');
