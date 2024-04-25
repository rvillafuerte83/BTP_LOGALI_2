class lhc_Travel definition inheriting from cl_abap_behavior_handler.
  private section.

    constants:
      begin of t_status,
        open     type c length 1 value 'O',
        accepted type c length 1 value 'A',
        rejected type c length 1 value 'X',
      end of t_status.

    methods acceptTravel for modify
      importing keys for action Travel~acceptTravel result result.

    methods rejectTravel for modify
      importing keys for action Travel~rejectTravel result result.

    methods get_instance_features for instance features
      importing keys request requested_features for Travel result result.

    methods get_global_authorizations for global authorization
      importing request requested_authorizations for Travel result result.

    methods get_instance_authorizations for instance authorization
      importing keys request requested_authorizations for Travel result result.

    methods deductDiscount for modify
      importing keys for action Travel~deductDiscount result result.

    methods reCalcTotalPrice for modify
      importing keys for action Travel~reCalcTotalPrice.


    methods Resume for modify
      importing keys for action Travel~Resume.

    methods calculateTotalPrice for determine on modify
      importing keys for Travel~calculateTotalPrice.

    methods setStatusToOpen for determine on modify
      importing keys for Travel~setStatusToOpen.

    methods setTravelNumber for determine on save
      importing keys for Travel~setTravelNumber.

    methods validateAgency for validate on save
      importing keys for Travel~validateAgency.

    methods validateCurrencyCode for validate on save
      importing keys for Travel~validateCurrencyCode.

    methods validateCustomer for validate on save
      importing keys for Travel~validateCustomer.

    methods validateDates for validate on save
      importing keys for Travel~validateDates.
    methods precheck_create for precheck
      importing entities for create Travel.

    methods precheck_update for precheck
      importing entities for update Travel.
    methods copyTravel for modify
      importing keys for action Travel~copyTravel.

endclass.

class lhc_Travel implementation.

  method get_instance_features.

    read entities of zr_travel_268 in local mode
         entity Travel
         fields ( OverallStatus )
         with corresponding #( keys )
         result data(travels)
         failed failed.

    result = value #( for ls_travel in travels (

                            %tky = ls_travel-%tky

                            %field-BookingFee = cond #( when ls_travel-OverallStatus = t_status-accepted
                                                        then if_abap_behv=>fc-f-read_only
                                                        else if_abap_behv=>fc-f-unrestricted )

                            %action-acceptTravel = cond #( when ls_travel-OverallStatus = t_status-accepted
                                                           then if_abap_behv=>fc-o-disabled
                                                           else if_abap_behv=>fc-o-enabled )

                            %action-rejectTravel = cond #( when ls_travel-OverallStatus = t_status-rejected
                                                           then if_abap_behv=>fc-o-disabled
                                                           else if_abap_behv=>fc-o-enabled )

                            %action-deductDiscount = cond #( when ls_travel-OverallStatus = t_status-accepted
                                                           then if_abap_behv=>fc-o-disabled
                                                           else if_abap_behv=>fc-o-enabled )

                            %assoc-_Booking = cond #( when ls_travel-OverallStatus = t_status-rejected
                                                      then if_abap_behv=>fc-o-disabled
                                                       else if_abap_behv=>fc-o-enabled )

                      ) ).


  endmethod.

  method get_global_authorizations.

    data(lv_technical_user) = cl_abap_context_info=>get_user_technical_name(  ).

    if requested_authorizations-%create eq if_abap_behv=>mk-on.

      if lv_technical_user eq 'CB9980007990'.
        result-%create = if_abap_behv=>auth-allowed.
      else.
        result-%create = if_abap_behv=>auth-unauthorized.
        data(lv_message) = abap_true.
      endif.

    endif.

    if requested_authorizations-%update      eq if_abap_behv=>mk-on or
       requested_authorizations-%action-Edit eq if_abap_behv=>mk-on.

      if lv_technical_user eq 'CB9980007990'.
        result-%update      = if_abap_behv=>auth-allowed.
        result-%action-Edit =  if_abap_behv=>auth-allowed.
      else.
        result-%update      = if_abap_behv=>auth-unauthorized.
        result-%action-Edit =  if_abap_behv=>auth-unauthorized.
        lv_message = abap_true.
      endif.

    endif.

    if requested_authorizations-%delete eq if_abap_behv=>mk-on.

      if lv_technical_user eq 'CB9980007990'.
        result-%delete = if_abap_behv=>auth-allowed.
      else.
        result-%delete = if_abap_behv=>auth-unauthorized.
        lv_message = abap_true.
      endif.

    endif.

    if lv_message = abap_true.
      append value #( %msg = new /dmo/cm_flight_messages(
                                  textid = /dmo/cm_flight_messages=>not_authorized
                                  severity = if_abap_behv_message=>severity-error )
                   %global = if_abap_behv=>mk-on ) to reported-travel.
    endif.

  endmethod.

  method get_instance_authorizations.

    data: update_requested type abap_bool,
          delete_requested type abap_bool,
          update_granted   type abap_bool,
          delete_granted   type abap_bool.

    check 1 = 2.

    read entities of zr_travel_268 in local mode
         entity Travel
         fields ( AgencyID )
         with corresponding #( keys )
         result data(travels)
         failed failed.

    check travels is not initial.

    data(lv_technical_user) = cl_abap_context_info=>get_user_technical_name(  ).

    update_requested = cond #( when requested_authorizations-%update = if_abap_behv=>mk-on
                                 or requested_authorizations-%action-Edit = if_abap_behv=>mk-on
                                then abap_true
                                else abap_false ).

    delete_requested = cond #( when requested_authorizations-%delete = if_abap_behv=>mk-on
                                then abap_true
                                else abap_false ).


    loop at travels into data(travel).

      if travel-AgencyID is not initial.

        if lv_technical_user eq 'CB9980007990' and travel-AgencyID ne '70025'. " WHAT EVER BUSINESS CASE
          update_granted = abap_true.
          delete_granted = abap_true.
        else.
          update_granted = delete_granted = abap_false.
        endif.

        if update_requested = abap_true.

          if update_granted = abap_false.
            append value #( %tky = travel-%tky
                            %msg = new /dmo/cm_flight_messages(
                                        textid = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                        agency_id = travel-AgencyID
                                        severity = if_abap_behv_message=>severity-error )
                             %element-AgencyID = if_abap_behv=>mk-on ) to reported-travel.
          endif.

        endif.

        if delete_requested = abap_true.

          if delete_granted = abap_false.
            append value #( %tky = travel-%tky
                            %msg = new /dmo/cm_flight_messages(
                                        textid = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                        agency_id = travel-AgencyID
                                        severity = if_abap_behv_message=>severity-error )
                             %element-AgencyID = if_abap_behv=>mk-on ) to reported-travel.
          endif.
        endif.

      else.

        update_granted = delete_granted = abap_true. "replace me with business check

        if update_granted = abap_false.
          append value #( %tky = travel-%tky
                            %msg = new /dmo/cm_flight_messages(
                                        textid = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                        agency_id = travel-AgencyID
                                        severity = if_abap_behv_message=>severity-error )
                             %element-AgencyID = if_abap_behv=>mk-on ) to reported-travel.
        endif.

      endif.

      append value #( let upd_auth = cond #( when update_granted = abap_true
                                             then if_abap_behv=>auth-allowed
                                             else if_abap_behv=>auth-unauthorized )
                          del_auth = cond #( when delete_granted = abap_true
                                             then if_abap_behv=>auth-allowed
                                             else if_abap_behv=>auth-unauthorized )
                      in
                      %tky         = travel-%tky
                      %update      = upd_auth
                      %action-Edit = upd_auth
                      %delete      = del_auth ) to result.

    endloop.

  endmethod.

  method acceptTravel.

*  EML - Entity Manipulation Language
    modify entities of zr_travel_268 in local mode
           entity Travel
           update
           fields ( OverallStatus )
           with value #( for key in keys ( %tky = key-%tky
                                           OverallStatus = t_status-accepted ) ).

    read entities of zr_travel_268 in local mode
         entity Travel
         all fields
         with corresponding #( keys )
         result data(lt_travels).

    result = value #( for ls_travel in lt_travels ( %tky =  ls_travel-%tky
                                                    %param = ls_travel ) ).

  endmethod.

  method deductDiscount.

    data travels_for_update type table for update zr_travel_268.
    data(keys_with_valid_discount) = keys.


    loop at keys_with_valid_discount assigning field-symbol(<keks_with_valid_discount>)
                                     where %param-discount_percent is initial or
                                           %param-discount_percent <= 0 or
                                           %param-discount_percent > 100.

      append value #( %tky = <keks_with_valid_discount>-%tky  ) to failed-travel.

      append value #( %tky = <keks_with_valid_discount>-%tky
                      %msg = new /dmo/cm_flight_messages(
                                       textid = /dmo/cm_flight_messages=>discount_invalid
                                       severity = if_abap_behv_message=>severity-error )
                            %element-TotalPrice = if_abap_behv=>mk-on
                            %op-%action-deductDiscount = if_abap_behv=>mk-on  ) to reported-travel.

      delete keys_with_valid_discount.

    endloop.

    check keys_with_valid_discount is not initial.

    read entities of zr_travel_268 in local mode
         entity Travel
         fields ( BookingFee )
         with corresponding #( keys_with_valid_discount )
         result data(travels).

    loop at travels assigning field-symbol(<travel>).

      data percentage type decfloat16.

      data(discount_percent) = keys_with_valid_discount[ key id
                                                             %tky = <travel>-%tky ]-%param-discount_percent.

      percentage = discount_percent / 100.

      data(reduce_fee) = <travel>-BookingFee * ( 1 - percentage ).

      append value #( %tky = <travel>-%tky
                      BookingFee = reduce_fee ) to travels_for_update.

    endloop.

    modify entities of zr_travel_268 in local mode
         entity Travel
         update fields ( BookingFee )
         with travels_for_update.

    read entities of zr_travel_268 in local mode
         entity Travel
         all fields
         with corresponding #( travels )
         result data(travels_with_discount).

    result = value #( for travel in travels_with_discount ( %tky   =  travel-%tky
                                                            %param = travel ) ).

  endmethod.

  method reCalcTotalPrice.

    types: begin of ty_amount_per_currencycode,
             amount        type /dmo/total_price,
             currency_code type /dmo/currency_code,
           end of ty_amount_per_currencycode.

    data amount_per_currencycode type standard table of ty_amount_per_currencycode.

    read entities of zr_travel_268 in local mode
         entity Travel
         fields ( BookingFee CurrencyCode )
         with corresponding #( keys )
         result data(travels).

    delete travels where CurrencyCode is initial.

    loop at travels assigning field-symbol(<travel>).

      amount_per_currencycode = value #( ( amount        = <travel>-BookingFee
                                           currency_code = <travel>-CurrencyCode ) ).

      read entities of zr_travel_268 in local mode
         entity Travel by \_Booking
         fields ( FlightPrice CurrencyCode )
         with value #( ( %tky =  <travel>-%tky ) )
         result data(bookings).

      loop at bookings into data(booking)
            where CurrencyCode is not initial.

        collect value ty_amount_per_currencycode( amount        = booking-FlightPrice
                                                  currency_code = booking-CurrencyCode ) into amount_per_currencycode.

      endloop.

      read entities of zr_travel_268 in local mode
           entity Booking by \_BookingSupplement
           fields ( BookSupplPrice CurrencyCode )
           with value #( for booking_n in bookings ( %tky =  booking_n-%tky ) )
           result data(bookingsupplements).

      loop at bookingsupplements into data(bookingsupplement)
           where CurrencyCode is not initial.

        collect value ty_amount_per_currencycode( amount        = bookingsupplement-BookSupplPrice
                                                  currency_code = bookingsupplement-CurrencyCode ) into amount_per_currencycode.

      endloop.

      clear <travel>-TotalPrice.

      loop at amount_per_currencycode into data(single_amount_per_currencycode).

        if single_amount_per_currencycode-currency_code = <travel>-CurrencyCode.
          <travel>-TotalPrice += single_amount_per_currencycode-amount.
        else.

          /dmo/cl_flight_amdp=>convert_currency(
            exporting
              iv_amount               = single_amount_per_currencycode-amount
              iv_currency_code_source = single_amount_per_currencycode-currency_code
              iv_currency_code_target = <travel>-CurrencyCode
              iv_exchange_rate_date   = cl_abap_context_info=>get_system_date(  )
            importing
              ev_amount               = data(total_booking_price_per_curr) ).

          <travel>-TotalPrice += total_booking_price_per_curr.

        endif.

      endloop.

    endloop.

    modify entities of zr_travel_268 in local mode
           entity Travel
           update
           fields ( TotalPrice )
           with corresponding #( travels ).

  endmethod.

  method rejectTravel.

    modify entities of zr_travel_268 in local mode
           entity Travel
           update
           fields ( OverallStatus )
           with value #( for key in keys ( %tky = key-%tky
                                           OverallStatus = t_status-rejected ) ).

    read entities of zr_travel_268 in local mode
         entity Travel
         all fields
         with corresponding #( keys )
         result data(lt_travels).

    result = value #( for ls_travel in lt_travels ( %tky =  ls_travel-%tky
                                                    %param = ls_travel ) ).

  endmethod.

  method Resume.
  endmethod.

  method calculateTotalPrice.

    modify entities of zr_travel_268 in local mode
          entity Travel
          execute reCalcTotalPrice
          from corresponding #( keys ).

  endmethod.

  method setStatusToOpen.

    read entities of zr_travel_268 in local mode
         entity Travel
         fields ( OverallStatus )
         with corresponding #( keys )
         result data(travels).

    delete travels where OverallStatus is not initial.

    check travels is not initial.

    modify entities of zr_travel_268 in local mode
           entity Travel
           update
           fields ( OverallStatus )
           with value #( for travel in travels ( %tky          = travel-%tky
                                                 OverallStatus = t_status-open ) ).

  endmethod.

  method setTravelNumber.

    read entities of zr_travel_268 in local mode
         entity Travel
         fields ( TravelID )
         with corresponding #( keys )
         result data(travels).

    delete travels where TravelID is not initial.

    check travels is not initial.

    select single from ztravel_268_a
           fields max( travel_id )
           into @data(lv_max_travelid).

*  lv_max_travelid = 4136.
*
*  TravelA 4136 + 1 = 4137
*  TravelB 4136 + 2 = 4138
*  TravelC 4136 + 3 = 4139

    modify entities of zr_travel_268 in local mode
           entity Travel
           update
           fields ( TravelID )
           with value #( for travel in travels index into i (
                                %tky = travel-%tky
                                TravelID = lv_max_travelid + i ) ).

  endmethod.

  method validateAgency.
  endmethod.

  method validateCurrencyCode.
  endmethod.

  method validateCustomer.

*    data(lv_country_code) = 'ES'.
*
*    authority-check object '/DMO/TRVL'
*                    id     '/DMO/CNTRY' field lv_country_code
*                    id     'ACTVT'      field '02'.
*
*    data(update_granted) = cond #( when sy-subrc = 0
*                                   then abap_true
*                                   else abap_false ).
    data customers type sorted table of /dmo/customer
                   with unique key client customer_id.

    read entities of zr_travel_268 in local mode
               entity Travel
               fields ( CustomerID )
               with corresponding #( keys )
               result data(travels).

    customers = corresponding #( travels discarding duplicates
                                 mapping customer_id = CustomerID except * ).
    delete customers where customer_id is initial.

    if customers is not initial.

      select from /dmo/customer as ddbb
             inner join @customers as rap on rap~customer_id eq ddbb~customer_id
             fields ddbb~customer_id
             into table @data(valid_customers).

    endif.

    loop at travels into data(travel).

      append value #( %tky        = travel-%tky
                      %state_area = 'VALIDATE_CUSTOMER' ) to reported-travel.

      if travel-CustomerID is initial.

        append value #( %tky        = travel-%tky ) to failed-travel.

        append value #( %tky        = travel-%tky
                        %state_area = 'VALIDATE_CUSTOMER'
                        %msg        = new /dmo/cm_flight_messages(
                                          textid = /dmo/cm_flight_messages=>enter_customer_id
                                          severity = if_abap_behv_message=>severity-error )
                        %element-CustomerID = if_abap_behv=>mk-on
                        ) to reported-travel.

      elseif travel-CustomerID is not initial and
             not line_exists( valid_customers[ customer_id = travel-CustomerID ] ).

        append value #( %tky        = travel-%tky ) to failed-travel.

        append value #( %tky        = travel-%tky
                        %state_area = 'VALIDATE_CUSTOMER'
                        %msg        = new /dmo/cm_flight_messages(
                                          textid = /dmo/cm_flight_messages=>enter_customer_id
                                          severity = if_abap_behv_message=>severity-error )
                        %element-CustomerID = if_abap_behv=>mk-on
                        ) to reported-travel.

      endif.


    endloop.

  endmethod.

  method validateDates.
  endmethod.

  method precheck_create.
  endmethod.

  method precheck_update.
  endmethod.

  method copyTravel.

    data: travels          type table for create zr_travel_268\\Travel,
          bookings_childs  type table for create zr_travel_268\\Travel\_Booking,
          booksuppl_childs type table for create zr_travel_268\\Booking\_BookingSupplement.

    read table keys with key %cid = '' into data(key_with_initial_cid).
    assert key_with_initial_cid is initial.

    read entities of zr_travel_268 in local mode
         entity Travel
         all fields
         with corresponding #( keys )
         result data(travel_read_result)
         failed failed.

    read entities of zr_travel_268 in local mode
       entity Travel by \_Booking
       all fields
       with corresponding #( travel_read_result )
       result data(book_read_result).

    read entities of zr_travel_268 in local mode
         entity Booking by \_BookingSupplement
         all fields
         with corresponding #( book_read_result )
         result data(booksuppl_read_result).


    loop at travel_read_result assigning field-symbol(<travel>).

      append value #( %cid  = keys[ key entity %key = <travel>-%key ]-%cid
                      %data = corresponding #( <travel> except TravelUUID ) ) to travels assigning field-symbol(<new_travel>).

      append value #( %cid_ref = keys[ key entity %key = <travel>-%key ]-%cid )
                   to bookings_childs assigning field-symbol(<booking_child>).

      <new_travel>-OverallStatus = t_status-open.
      <new_travel>-BeginDate = cl_abap_context_info=>get_system_date(  ).
      <new_travel>-EndDate   = cl_abap_context_info=>get_system_date(  ) + 30.

      loop at book_read_result assigning field-symbol(<booking>)
           where TravelUUID eq <travel>-TravelUUID.

        append value #( %cid  = keys[ key entity %key = <travel>-%key ]-%cid && <booking>-BookingUUID
                        %data = corresponding #( book_read_result[ key entity %key = <booking>-%key ] except TravelUUID
                                                                                                              BookingUUID ) )

              to <booking_child>-%target assigning field-symbol(<new_booking>).

        append value #( %cid_ref = keys[ key entity %key = <travel>-%key ]-%cid && <booking>-BookingUUID )
               to booksuppl_childs assigning field-symbol(<booksuppl_child>).

        <new_booking>-BookingStatus = 'N'.

        loop at booksuppl_read_result assigning field-symbol(<booksuppl>)
                where TravelUUID  eq <travel>-TravelUUID
                  and BookingUUID eq <booking>-BookingUUID.

          append value #( %cid = keys[ key entity %key = <travel>-%key ]-%cid &&
                                                         <booking>-BookingUUID &&
                                                         <booksuppl>-BooksupplUUID
                          %data = corresponding #( <booksuppl> except TravelUUID
                                                                      BookingUUID
                                                                      BooksupplUUID ) )
                      to  <booksuppl_child>-%target.

        endloop.
      endloop.
    endloop.

    modify entities of zr_travel_268 in local mode
           entity Travel
           create fields ( AgencyID
                           CustomerID
                           BeginDate
                           EndDate
                           BookingFee
                           TotalPrice
                           CurrencyCode
                           OverallStatus
                           Description )
           with travels

           create by \_Booking fields ( BookingID
                                        BookingDate
                                        CustomerID
                                        AirlineID
                                        ConnectionID
                                        FlightDate
                                        FlightPrice
                                        CurrencyCode
                                        BookingStatus )
           with bookings_childs

           entity Booking
           create by \_BookingSupplement fields ( BookingSupplementID
                                                  SupplementID
                                                  BookSupplPrice
                                                  CurrencyCode )
           with booksuppl_childs

           mapped data(mapped_created).

    mapped-travel = mapped_created-travel.

  endmethod.

endclass.
