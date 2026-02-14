.. _design/api:

=====================
LIBRA API Conventions
=====================

- All public API functions/macros start with ``libra_``; anything else is
  non-API and can change at any time.

- All public API variables start with ``LIBRA_``; anything else is non-API and
  can change at any time.

- All private API functions/macros start with ``_libra_``. They should never be
  used outside of LIBRA itself.

- All private API variables start with ``_LIBRA_``. They should never be used
  outside of LIBRA itself. Private API variables are ones which have some
  semantic significance beyond just a temp variable for calculations.
