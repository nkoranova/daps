# Copyright (C) 2012 SUSE Linux Products GmbH
#
# Author: Frank Sundermeyer
#
# filelist generation for DAPS
#
# Please submit feedback or patches to
# <fsundermeyer at opensuse dot org>
#

# includes are set in selector.mk
# include $(DAPSROOT)/make/setfiles.mk
# include $(DAPSROOT)/make/images.mk

ENTITIES_DOC := $(addprefix $(DOC_DIR)/xml/,\
	      $(shell $(LIBEXEC_DIR)/getentityname.py $(DOCFILES)))

USED_FILES    := $(ENTITIES_DOC) $(DOCCONF) $(MAIN) $(DOCFILES) $(USED_ALL)

# Using tar is the easiest way to search for files excluding versioning system
# files and directories. A simple tar cv >/dev/null does not work, because
# it does not let you pipe the output, so we are using two tar calls
#
UNUSED_IMAGES := $(shell tar cP --exclude-vcs \
		    $(IMG_SRCDIR) | tar tP | sed '/\/$$/d' | tr '\n' ' ')
UNUSED_XML    := $(shell tar cP --exclude-vcs \
		    $(DOC_DIR)/xml | tar tP | sed '/\/$$/d' | tr '\n' ' ')
UNUSED_FILES := $(filter-out $(USED_FILES), $(UNUSED_IMAGES) $(UNUSED_XML))

ifeq ($(LIST_NOIMG),1)
  USED_FILES   := $(filter-out $(USED_ALL),$(USED_FILES))
  UNUSED_FILES := $(filter-out $(UNUSED_IMAGES),$(UNUSED_FILES))
endif
ifeq ($(LIST_NOENT),1)
  USED_FILES := $(filter-out $(ENTITIES_DOC),$(USED_FILES))
endif
ifeq ($(LIST_NODC),1)
  USED_FILES := $(filter-out $(DOCCONF),$(USED_FILES))
endif
ifeq ($(LIST_NOXML),1)
  USED_FILES   := $(filter-out $(DOCFILES) $(MAIN),$(USED_FILES))
  UNUSED_FILES := $(filter-out $(UNUSED_XML),$(UNUSED_FILES))
endif

# List files from xml and images/src referenced by $DOCFILE or $MAIN
#
.PHONY: list-srcfiles
list-srcfiles: 
  ifeq ($(PRETTY_FILELIST), 1)
	@echo -e "$(subst $(SPACE),\n,$(sort $(USED_FILES)))"
  else
	@echo $(sort $(USED_FILES))
  endif

# List files from xml and images/src _not_ referenced by $DOCFILE or $MAIN
#
.PHONY: list-srcfiles-unused
list-srcfiles-unused:
  ifeq ($(PRETTY_FILELIST), 1)
	@echo -e "$(subst $(SPACE),\n,$(sort $(UNUSED_FILES)))"
  else
	@echo $(sort $(UNUSED_FILES))
  endif


# The targets
#
# list-images-missing
# list-images-multisrc
#
# can be found in images.mk