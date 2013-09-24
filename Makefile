install:
	install mediasync.sh /usr/local/bin/mediasync
	install mediasync.logrotate /etc/logrotate.d/mediasync

uninstall:
	rm /usr/local/bin/mediasync
	rm /etc/logrotate.d/mediasync
