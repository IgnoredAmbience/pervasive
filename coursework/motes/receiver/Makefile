SerialMsg.java: SerialMsg.h
	mig java -java-classname=SerialMsg -o SerialMsg.java SerialMsg.h SerialMsg

SerialMsg.class: SerialMsg.java
	javac SerialMsg.java

%:
	$(MAKE) -f Makefile.tos $<
