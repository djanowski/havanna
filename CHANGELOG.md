1.1.0 - 2015-08-05
==================

* Havanna now exits forcefully when receiving INT or TERM twice within 5
  seconds.

* Workers listed in `Havannafile` must respond to `#to_h`. If you were using
  your own classes, make them inherit from `Havanna::Worker`.
