mediaSync
=========

Wrapper for rsync to send files from one server to another (files will not be perserved in orginating server)
Files can be renamed to match XBMC directory structures


Recommended to run in a screen session

Examples on how to use:


	mediasync A B - sync files that appear in directory A to B (Files will be deleted in A)
	mediasync -r A B - sync files that appear in directory A to B renaming files with XBMC directories
