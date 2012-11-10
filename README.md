# Spanx

Spank down IP spam: IP-based rate limiting for web applications behind HTTP server such as nginx or Apache.

Spanx is a simple Redis-based web request rate limiter, which integrates into any web application simply by monitoring
one or more HTTP server access log file(s) in real time (think Apache/nginx access.log).

Basic flow is as follows:

* Spanx tails the access.log file(s)
* parses out IP addresses of each request
* maintains a tally of request counts per IP, and per a time slice.
* Spanx is then able to detect when one or more IPs exceed the rate limiting configuration thresholds provided
(multiple thresholds are supported).
  * When such IP is detected, Spanx immediately writes it out into a block-list file (suitable for consumption by nginx or
apache, in format eg "deny 127.0.0.1;"), and then
  * executes a pre-configured command, presumed to reload HTTP server configuration (such as HUP nginx, etc) and activate new blocking rules.

Spanx additionally supports regular expression based white list file, that can be used to eliminate certain log lines
from the consideration (for example, you Googlebot based on User-Agent).

### Design

Spanx can be integrated as part of your application, or can run as a standalone ruby app.  Spanx requires ruby
1.9.3, and it uses ruby threads to work on a few things in parallel.

Spanx has two main components:

1. *watcher* is a process that monitors HTTP server log files, and updates Redis periodically with most recent counts.
   Watcher also writes out the blocked IP file, if blocked IPs are found in Redis database.

2. *analyzer* is a process that reads up to date information on IP addresses from Redis, and analyzes it. If any rate
   limit-exceeding IPs are found, it writes them to the Redis DB, with an expiration TTL set.

If you have only one web server, you can run both watcher and analyzer as a single ruby process.

If you have multiple web servers, you need to run watcher on each server, and analyzer only once (somewhere).

### Alerts

Besides actually writing out IPs to a block list file, Spanx supports notifiers that will be called when a new IP
is blocked.  Currently supported are audit log notifier (that writes that information to a log file), a Campfire
Chat notifier, which will print IP blocking information into your Campfire chat room, and an Email notifier. It is
very easy to write additional notifiers.

## Installation

Add this line to your application's Gemfile:

    gem 'spanx'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install spanx

### Dependencies

Spanx uses Redis to save state and do set logic on the information it finds.

## Usage

Spanx has a single executable with several sub-commands. In practice, multiple commands will
be run concurrently to do all of the necessary calculations.

Configuration can be provided via a YAML file (see example), and/or via command line options. Not
all configuration can be set via command line. If an option is provided in both YAML file and command line,
then latter is chosen.


### watch

This command watches an HTTP server log file and writes out blocked IPs to a file specified.

```bash
  Usage: [bundle exec] spanx watch [options]
    -f, --file ACCESS_LOG            Apache/nginx access log file to scan continuously
    -z, --analyze                    Analyze IPs also (as opposed to running `spanx analyze` in another process)
    -b, --block_file BLOCK_FILE      Output file to store NGINX block list
    -c, --config CONFIG              Path to config file (YML) (required)
    -d, --daemonize                  Detach from TTY and run as a daemon
    -g, --debug                      Log to STDOUT status of execution and some time metrics
    -r, --run <shell command>        Shell command to run anytime blocked ip file changes, for example "sudo pkill -HUP nginx"
    -w, --whitelist WHITELIST        File with newline separated reg exps, to exclude lines from access log
    -h, --help                       Show this message
```

### analyze

Analyzes IPs found by the `watch` command. If an IP exceeds its maximum count for a time
period check (as set in the config file), the IP is written into Redis with a TTL defined by the
period check.

```bash
Usage: [bundle exec] spanx analyze [options]
    -a, --audit AUDIT_FILE           Historical record of IP blocking decisions
    -c, --config CONFIG              Path to config file (YML) (required)
    -d, --daemonize
    -g, --debug                      Log status to STDOUT
    -h, --help                       Show this message
```

### flush

This removes the persistence data around current IP blocks. Use this
when you want to remove all data around current blocks without (or in
addition to) disabling the blocker.

```bash
Usage: [bundle exec] spanx flush [options]
    -c, --config CONFIG              Path to config file (YML) (required)
    -g, --debug                      Log status to STDOUT
    -h, --help                       Show this message
```

## Examples

If you have only one load balancer, you may want to centralize all work into a single process, as such:

```bash
 $ spanx watch -w /path/to/whitelist -c /path/to/spanx.conf.yml -z -d
```

With multiple load balancers, this may not be desirable. All hosts will need to process their own access
log, but a minimum number of hosts should analyze the IP traffic.

```bash
 lb1 $ spanx watch -c spanx.conf.yml -r "sudo pkill -HUP nginx" --debug 2>&1 >> /var/log/spanx.watch.log &
 lb2 $ spanx watch -c spanx.conf.yml -r "sudo pkill -HUP nginx" --debug 2>&1 >> /var/log/spanx.watch.log &

 lb2 $ spanx analyze -c spanx.conf.yml -a spanx.audit.log --debug 2>&1 >> /var/log/spanx.analyze.log &
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Maintainers

Konstantin Gredeskoul (@kigster) and Eric Saxby (@sax) at Wanelo, Inc (http://github.com/wanelo)

(c) 2012, All rights reserved.
