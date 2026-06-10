LIST @bronze_divya;
LIST @bronze_divya/incoming/;
LIST @bronze_divya/archive/;
REMOVE @bronze_divya;

CREATE FILE FORMAT bronze_csv_file_format
  TYPE = 'CSV'
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF = ('NULL', 'null', '');




