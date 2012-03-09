SerialMsg.class: SerialMsg.java
	javac SerialMsg.java

SerialMsg.java: SerialMsg.h
	mig java -java-classname=SerialMsg -o SerialMsg.java SerialMsg.h SerialMsg

install:
	$(MAKE) -f Makefile.tos micaz install,28 mib520,/dev/ttyUSB0

micaz:
	$(MAKE) -f Makefile.tos micaz
