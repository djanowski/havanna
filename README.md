Havanna
=======

Ruby workers with [Disque][disque].

Usage
-----

Create a worker:

```ruby
class Mailer
  def call(item)
    puts "Emailing #{item}..."

    # Actually do it.
  end
end
```

Havanna doesn't perform any kind of magic autodiscovery of
your workers. Similar to Rack's `config.ru`, Havanna has an
entry point file where you explicitly declare your workers.
This would be a valid `Havannafile`:

```ruby
require "app"

Havanna.run(Mailer)
```

Now on the command line, start your workers:

```
$ havanna start
```

In a different window, try queuing a job using Disque's
built-in client:

```
$ disque addjob Mailer foo@example.com 5000
```

Once you're up and running, deploy your workers with `-d`
for daemonization:

```
$ havanna start -d
```

Stop the worker pool by issuing a `stop` command:

```
$ havanna stop
```

This will wait for all workers to exit gracefully.

For more information, run:

```
$ havanna -h
```


Design notes
------------

Havanna assumes that your workers perform a fair amount of I/O (probably one
of the most common reasons to send jobs to the background). We will optimize
Havanna for this use case.

Currently, Havanna runs multiple threads per worker. However, we may `fork(2)`
if we find that's better for multiple-core utilization under MRI.


Alternatives
------------

It's very likely that Havanna is not for you. While I use it in production,
it's small and doesn't do much.

These are the alternatives I know of in Rubyland:

- [Disc][disc]: By my friend [pote][pote]. It supports more customization of
  workers and queues, takes configuration from environment variables and can
  take advantage of Celluloid if you're using it.

- [DisqueJockey][disque_jockey]: I don't know much about this one, but
  apparently it's even more configurable, has a DSL and (naturally) might be
  a better fit if you use/like Rails.


About the name
--------------

Havanna is inspired by [Ost][ost] and [ost(1)][ost-bin]. [soveran][soveran]
named Ost after a café, and I happened to be sitting at another café when I
started to work on this library. Its name: [Havanna][havanna].

By the way, before becoming a café, Havanna produced the best
*[alfajores][alfajores]* in Argentina. They only had one store in Mar del
Plata (~400km away from Buenos Aires), so it became a tradition to bring these
exquisite *alfajores* when you returned from a trip to the beach.  Several
years later they opened stores in Buenos Aires and elsewhere and became a
coffee shop.


[alfajores]:     https://www.google.com.ar/search?q=alfajor+argentino&tbm=isch
[disc]:          https://github.com/pote/disc
[disque]:        https://github.com/antirez/disque
[disque_jockey]: https://github.com/DevinRiley/disque_jockey
[havanna]:       https://www.google.com.ar/search?q=havanna+cafe&tbm=isch
[ost-bin]:       https://github.com/djanowski/ost-bin
[ost]:           https://github.com/soveran/ost
[pote]:          https://twitter.com/poteland
[soveran]:       https://twitter.com/soveran
