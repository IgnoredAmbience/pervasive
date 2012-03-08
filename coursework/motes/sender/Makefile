MOTE ?= 25

SerialMsg.java: SerialMsg.h
	mig java -java-classname=SerialMsg -o SerialMsg.java SerialMsg.h SerialMsg

SerialMsg.class: SerialMsg.java
	javac SerialMsg.java

install:
	$(MAKE) -f Makefile.tos micaz install,$(MOTE) mib520,/dev/ttyUSB2

micaz:
	$(MAKE) -f Makefile.tos micaz
