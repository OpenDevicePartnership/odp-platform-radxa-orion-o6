# PLATFORM NOTE:
# This build needs code that is provided in a monolithic delivery that can not be easily divided into
# a submodules that reside under this component.  Therefore, the PATH_CIX_REFERENCE_PROJECT path
# environment variable set in the main Makefile is being used to reach outside this component folder
# and into the common folder.

.PHONY: all

all:
	$(MAKE) -C $(PATH_CIX_REFERENCE_PROJECT)/mem_config
	mkdir -p $(BINS_DIR)
	mv $(PATH_CIX_REFERENCE_PROJECT)/mem_config/memory_config.bin $(BINS_DIR)/
