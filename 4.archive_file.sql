EXECUTE IMMEDIATE $$

BEGIN

    COPY FILES INTO @bronze_divya/archived/ FROM @bronze_divya/incoming/ 

        PATTERN = '.*orders_source.*\.csv'; 

    COPY FILES INTO @bronze_divya/archived/ FROM @bronze_divya/incoming/ 

        PATTERN = '.*customers_source.*\.csv'; 

    COPY FILES INTO @bronze_divya/archived/ FROM @bronze_divya/incoming/ 

        PATTERN = '.*products_source.*\.csv';

    COPY FILES INTO @bronze_divya/archived/ FROM @bronze_divya/incoming/ 

        PATTERN = '.*order_items_source.*\.csv';

    REMOVE @bronze_divya/incoming/ PATTERN = '.*orders_source.*\.csv';

    REMOVE @bronze_divya/incoming/ PATTERN = '.*customers_source.*\.csv';

    REMOVE @bronze_divya/incoming/ PATTERN = '.*products_source.*\.csv';

    REMOVE @bronze_divya/incoming/ PATTERN = '.*order_items_source.*\.csv';

    RETURN 'All source files (Orders, Customers, Products, Order Items) have been archived and cleared.';

END;

$$;

LIST @bronze_divya/archived;

LIST @bronze_divya/incoming;

 