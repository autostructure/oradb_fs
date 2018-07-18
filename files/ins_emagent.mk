# cus_emagent.mk - makefile to relink Enterprise Manager native executables
#
#
# 
# NOTE:         ORACLE_HOME must be either:
#               . set in the user's environment
#               . passed in on the command line
#               . defined in a modified version of this makefile

include  $(ORACLE_HOME)/sysman/lib/env_emagent.mk 

PRODADMIN = $(PRODLIBHOME)
PRODBINHOME = $(ORACLE_HOME)/bin/

# override standard macro to use ld
LDCCOM    = $(LINK) $(EXOSFLAGS) $(LINKLDLIBS)

#
# we redefine the order so that .so get picked up before .a
#
LDFLAGS=-o $@ $(LDPATHFLAG)$(LIBHOME) $(LDPATHFLAG)$(PRODLIBHOME) $(STUBSDIR) $(LDFLAGS_ARCH) $(LDARCH_FLAGS)

MAKEFILE=$(PRODLIBHOME)ins_emagent.mk

INSTALL_TARGS = clean agent collector

default: agent collector dbfetchlets

INSTALL_SHARED_TARGETS=libnmemso libnmeoci libnmefw \
	libnmefos libnmefsql libnmefud libnmefdms libnmefojmx libnmefut libnmefvr libnmefpfa\
	libnmevq libnmevsp libnmevc libnmadbg libnmadm libnmalk libnmastk libnmasf libnmarl libnmefsp\
	libnmefsqlt libnmefport \
    libnmcfhc libnmcfsga

INSTALL_EXE_TARGETS=emagent emdctl nmupm nmei ojmxtool \
	emagtm emagtmc nmocat e2eme nmosudo


agent:  $(INSTALL_SHARED_TARGETS) $(INSTALL_EXE_TARGETS) iemtgtctl
	$(SILENT) $(ECHO) "Enterprise Manager native components relinked"
	$(SILENT) $(ECHO) "IMPORTANT NOTE: To complete this Install/upgrade, please login as root and"
	$(SILENT) $(ECHO) "                execute the root.sh script."

collector:  $(INSTALL_SHARED_TARGETS) 
	$(MAKE) -f $(SYSMANLIB)ins_emagent.mk relink_exe EXENAME=nmccollector $(PL_LINK_OVERRIDES)
	$(SILENT) $(ECHO) "Enterprise Manager Direct Memory Access Collector relinked"

dbfetchlets: $(INSTALL_SHARED_TARGETS)
	$(SILENT) $(ECHO) "Enterprise Manager DB fetchlets relinked"

$(INSTALL_EXE_TARGETS):
	$(MAKE) -f $(SYSMANLIB)ins_emagent.mk relink_exe EXENAME=$@ $(PL_LINK_OVERRIDES)

$(INSTALL_SHARED_TARGETS):
	$(MAKE) -f $(SYSMANLIB)ins_emagent.mk relink_sharedobj SHAREDOBJ=$@ $(PL_LINK_OVERRIDES)

relink_exe: $(SYSMANBIN)$(EXENAME)
	-mv -f $(BINHOME)$(EXENAME) $(BINHOME)$(EXENAME)0
	-mv $(SYSMANBIN)$(EXENAME) $(BINHOME)

relink_sharedobj: $(SYSMANLIB)$(SHAREDOBJ).$(SO_EXT)
	-mv -f $(ORACLE_HOME)/$(LIBDIR)/$(SHAREDOBJ).$(SO_EXT) $(ORACLE_HOME)/$(LIBDIR)/$(SHAREDOBJ).$(SO_EXT).0
	-mv  $(SYSMANLIB)$(SHAREDOBJ).$(SO_EXT) $(ORACLE_HOME)/$(LIBDIR)/$(SHAREDOBJ).$(SO_EXT)

##############################################
#
# targets for relinking executables
#
##############################################

#=================
#  emcgtctl
#=================

iemtgtctl:
	$(MAKE) -f $(SYSMANLIB)ins_emagent.mk emtgtctl2 $(PL_LINK_OVERRIDES)
	-rm -f $(ORACLE_HOME)/bin/emtgtctl2
	-mv emtgtctl2 $(ORACLE_HOME)/bin/emtgtctl2
	$(CHMOD) 6751 $(ORACLE_HOME)/bin/emtgtctl2

emtgtctl2:
	$(MK_EMAGENT_NMETGCTL)

#==================
#  nmo
#=================

nmo:
	$(MAKE) -f $(SYSMANLIB)ins_emagent.mk relink_exe EXENAME=$@ $(PL_LINK_OVERRIDES)

$(SYSMANBIN)nmo:
	$(MK_EMAGENT_NMO)
	$(RMF) $(NMO_NONPRIV)
	$(CP) $(SYSMANBIN)nmo $(NMO_NONPRIV)

#====================
#  nmb
#===================

nmb:
	$(MAKE) -f $(SYSMANLIB)ins_emagent.mk relink_exe EXENAME=$@ $(PL_LINK_OVERRIDES)

$(SYSMANBIN)nmb:
	$(MK_EMAGENT_NMB)
	$(RMF) $(NMB_NONPRIV)
	$(CP) $(SYSMANBIN)nmb $(NMB_NONPRIV)

#====================
#  nmosudo
#===================

$(SYSMANBIN)nmosudo:
	$(MK_EMAGENT_NMOSUDO)


#================
# nmupm
#===============

$(SYSMANBIN)nmupm:
	$(MK_EMAGENT_NMUPM)

#================
# ojmxtool 
#===============

$(SYSMANBIN)ojmxtool:
	$(MK_EMAGENT_OJMXTOOL)

#========================
#  emagent
#========================

$(SYSMANBIN)emagent:
	$(MK_EMAGENT_CEMD)

#========================
#  emsubagent
#========================

emsubagent:
	$(MAKE) -f $(SYSMANLIB)ins_emagent.mk relink_exe EXENAME=$@ $(PL_LINK_OVERRIDES)

$(SYSMANBIN)emsubagent:
	$(MK_EMAGENT_SNMPMGR)

#==========================
#  nmei
#==========================

$(SYSMANBIN)nmei:
	$(MK_EMAGENT_NMEI)

#==========================
# nmum/emagtm
#=========================

$(SYSMANBIN)nmum $(SYSMANBIN)emagtm:
	$(MK_EMAGENT_NMUM)

#==========================
# nmum/emagtmc
#=========================

$(SYSMANBIN)nmumc $(SYSMANBIN)emagtmc:
	$(MK_EMAGENT_NMUMC)

#===========================
#  emdctl
#===========================

$(SYSMANBIN)emdctl:
	$(MK_EMAGENT_NMECTL) -lnnz11

#===========================
#  nmocat
#===========================

$(SYSMANBIN)nmocat:
	$(MK_EMAGENT_NMOCAT)

#=============================
#  agent main shared library
#==============================

$(SYSMANLIB)libnmemso.$(SO_EXT): $(LIBNMEMSO_DEF)
	$(MK_EMAGENT_LIBNMEMSO_SHLIB) $(LDLIBS)

#========================
#  e2eme :
#========================

# The linking library path order of the e2eme has to be inverted or the code
# is statically linked (ld finds the .a files before the .so ones)

$(SYSMANBIN)e2eme:
	$(MK_EMAGENT_E2EME)

#================
# NMHS
#===============

nmhs:
	$(MAKE) -f $(SYSMANLIB)ins_emagent.mk relink_exe EXENAME=$@ $(PL_LINK_OVERRIDES)

$(SYSMANBIN)nmhs:
	$(MK_EMAGENT_NMHS)
	$(RMF) $(NMHS_NONPRIV)
	$(CP) $(SYSMANBIN)nmhs $(NMHS_NONPRIV)

#=================
# nmccollector
#=================

$(SYSMANBIN)nmccollector:
	$(MK_EMAGENT_COLLECTOR)


######################################################
#
#


preinstall:
	-chmod 755 $(ORACLE_HOME)/bin
 
install: preinstall $(INSTALL_TARGS)

clean:


