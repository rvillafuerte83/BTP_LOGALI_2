class lhc_Booking definition inheriting from cl_abap_behavior_handler.
  private section.

    methods calculateTotalPrice for determine on modify
      importing keys for Booking~calculateTotalPrice.

    methods setBookingDate for determine on save
      importing keys for Booking~setBookingDate.

    methods setBookingNumber for determine on save
      importing keys for Booking~setBookingNumber.

    methods validateConnection for validate on save
      importing keys for Booking~validateConnection.

    methods validateCurrencyCode for validate on save
      importing keys for Booking~validateCurrencyCode.

    methods validateCustomer for validate on save
      importing keys for Booking~validateCustomer.

endclass.

class lhc_Booking implementation.

  method calculateTotalPrice.

     read entities of ZR_TRAVEL_268 in local mode
          entity Booking by \_Travel
          fields ( TravelUUID )
          with corresponding #( keys )
          result data(travels).

     modify entities of  ZR_TRAVEL_268 in local mode
            entity Travel
            execute reCalcTotalPrice
            from corresponding #( travels ).

  endmethod.

  method setBookingDate.
  endmethod.

  method setBookingNumber.
  endmethod.

  method validateConnection.
  endmethod.

  method validateCurrencyCode.
  endmethod.

  method validateCustomer.
  endmethod.

endclass.
