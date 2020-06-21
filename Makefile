#

PREFIX=/usr/local
CMD=pki

.PHONY:	love
love:	all

.PHONY:	all
all:

.PHONY:	install
install:
	if [ 0 = "`id -u`" ]; then	\
		$(MAKE) '$(PREFIX)/bin/$(CMD)';	\
	else	\
		$(MAKE) '$(HOME)/bin/$(CMD)';	\
	fi

$(HOME)/bin:
	mkdir -p750 '$@'

$(HOME)/bin/$(CMD):	$(CMD).sh $(HOME)/bin
	cmp -s '$(CMD).sh' '$@' || ln -s --relative --backup=t '$(CMD).sh' '$@'

$(PREFIX)/bin/$(CMD):	$(CMD).sh
	cp --backup=t '$<' '$@'

