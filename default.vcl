# Also see:
# http://symfony.com/doc/current/cookbook/cache/varnish.html
#
# Apache is listening on 8080

backend default {
    .host = "127.0.0.1";
    .port = "8080";
}

sub vcl_recv {
    // Add a Surrogate-Capability header to announce ESI support.
    set req.http.Surrogate-Capability = "abc=ESI/1.0";
}

sub vcl_fetch {
    /*
    Check for ESI acknowledgement
    and remove Surrogate-Control header
    */
    if (beresp.http.Surrogate-Control ~ "ESI/1.0") {
        unset beresp.http.Surrogate-Control;

        // For Varnish >= 3.0
        set beresp.do_esi = true;
        // For Varnish < 3.0
        // esi;
    }
    /* By default Varnish ignores Cache-Control: nocache
    (https://www.varnish-cache.org/docs/3.0/tutorial/increasing_your_hitrate.html#cache-control),
    so in order avoid caching it has to be done explicitly */
    if (beresp.http.Pragma ~ "no-cache" ||
         beresp.http.Cache-Control ~ "no-cache" ||
         beresp.http.Cache-Control ~ "private") {
        return (hit_for_pass);
    }
}

sub vcl_fetch {
  if (req.url !~ "^/gallery/*") {
    unset beresp.http.set-cookie;
    unset req.http.Cookie;
  }
}

sub vcl_recv {
    if (req.http.X-Forwarded-Proto == "https" ) {
        set req.http.X-Forwarded-Port = "443";
    } else {
        set req.http.X-Forwarded-Port = "80";
    }
}

// Purge
// Restrict purge to localhost
acl purge {
    "localhost";
}

sub vcl_recv {
    // Match PURGE request to avoid cache bypassing
    if (req.request == "PURGE") {
        // Match client IP to the ACL
        if (!client.ip ~ purge) {
            // Deny access
            error 405 "Not allowed.";
        }
        // Perform a cache lookup
        return(lookup);
    }
}

sub vcl_hit {
    // Match PURGE request
    if (req.request == "PURGE") {
        // Force object expiration for Varnish < 3.0
        set obj.ttl = 0s;
        // Do an actual purge for Varnish >= 3.0
        // purge;
        error 200 "Purged";
    }
}

sub vcl_miss {
    // Match PURGE request
    if (req.request == "PURGE") {
        // Indicate that the object isn't stored in cache
        error 404 "Not purged";
    }
}

// App specific filters
sub vcl_recv {
    if (req.url ~ "^/(admin/*|track/*)") {
        return(pass);
    }
}
