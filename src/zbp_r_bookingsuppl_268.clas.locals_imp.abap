class lhc_BookingSupplement definition inheriting from cl_abap_behavior_handler.
  private section.

    methods calculateTotalPrice for determine on modify
      importing keys for BookingSupplement~calculateTotalPrice.

    methods setBookSupplNumber for determine on save
      importing keys for BookingSupplement~setBookSupplNumber.

    methods validateCurrencyCode for validate on save
      importing keys for BookingSupplement~validateCurrencyCode.

    methods validateSupplement for validate on save
      importing keys for BookingSupplement~validateSupplement.

endclass.

class lhc_BookingSupplement implementation.

  method calculateTotalPrice.

    read entities of zr_travel_268 in local mode
         entity BookingSupplement by \_Travel
         fields ( TravelUUID )
         with corresponding #( keys )
         result data(travels).

    modify entities of zr_travel_268 in local mode
           entity Travel
           execute reCalcTotalPrice
           from corresponding #( travels ).

  endmethod.

  method setBookSupplNumber.
  endmethod.

  method validateCurrencyCode.
  endmethod.

  method validateSupplement.
  endmethod.

endclass.
