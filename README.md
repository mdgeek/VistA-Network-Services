# VistA Network Services (NETSERV)

It occurred to me while tweaking several different M-based web servers to get them to work properly under heavy loads
that VistA has a lot of applications that use TCP for communication.  We have several web servers and I've lost count
of how many RPC brokers.  They all roll their own solution for TCP connectivity.  Why don't we separate TCP connection
management from the applications that need it.  That is what inspired me to write this package.  I took TCP connection
management ideas from several existing packages (M Web Server, WebMan, CIA Broker among them) and put them all in
one place.  Having done that, I created web server and RPC broker applications that leverage it (I know, more flavors
of these applications), again drawing ideas from existing packages.

This project is still in evolution.  I am doing load testing on it.  I still need to implement some limits on spawned
processes to prevent DOS attacks from crippling the system.  But it works!  Feel free to try it out.
