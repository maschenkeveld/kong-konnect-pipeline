#------------------------------------------------------------------------
# variables: root CA
ROOTCA_DAYS ?= 3650
ROOTCA_KEYSZ ?= 4096
ROOTCA_COUNTRY ?= "NL"
ROOTCA_STATE ?= "North Holland"
ROOTCA_LOCATION ?= "Amsterdam"
ROOTCA_ORG ?= "Kong"
ROOTCA_ORGUNIT ?= "CX"
ROOTCA_CN ?= Kong CX Root CA

#------------------------------------------------------------------------
# variables: intermediate CA
INTCA_DAYS ?= 3650
INTCA_KEYSZ ?= 4096
INTCA_COUNTRY ?= "NL"
INTCA_STATE ?= "North Holland"
INTCA_LOCATION ?= "Amsterdam"
INTCA_ORG ?= "Kong"
INTCA_ORGUNIT ?= "CX"
# INTCA_CN ?= Kong CX Intermediate CA

#------------------------------------------------------------------------
# variables: Client or Server
CS_DAYS ?= 3650
CS_COUNTRY ?= "NL"
CS_STATE ?= "North Holland"
CS_LOCATION ?= "Amsterdam"
CS_ORG ?= "Kong"
CS_ORGUNIT ?= "CX"
CS_PURPOSE ?= clientAndServer


root-ca.conf:
	@echo "[ req ]" > $@
	@echo "encrypt_key = no" >> $@
	@echo "prompt = no" >> $@
	@echo "utf8 = yes" >> $@
	@echo "default_md = sha256" >> $@
	@echo "default_bits = $(ROOTCA_KEYSZ)" >> $@
	@echo "req_extensions = req_ext" >> $@
	@echo "x509_extensions = req_ext" >> $@
	@echo "distinguished_name = req_dn" >> $@
	@echo "[ req_ext ]" >> $@
	@echo "subjectKeyIdentifier = hash" >> $@
	@echo "authorityKeyIdentifier = keyid:always,issuer" >> $@
	@echo "basicConstraints = critical, CA:true" >> $@
	@echo "keyUsage = critical, digitalSignature, cRLSign, keyCertSign" >> $@
	@echo "[ req_dn ]" >> $@
	@echo "C = $(ROOTCA_COUNTRY)" >> $@
	@echo "ST = $(ROOTCA_STATE)" >> $@
	@echo "L = $(ROOTCA_LOCATION)" >> $@
	@echo "O = $(ROOTCA_ORG)" >> $@
	@echo "OU = $(ROOTCA_ORGUNIT)" >> $@
	@echo "O = $(ROOTCA_ORG)" >> $@
	@echo "CN = $(ROOTCA_CN)" >> $@

%-int-ca/intermediate.conf: L=$(dir $@)
%-int-ca/intermediate.conf:
	@echo "[ req ]" > $@
	@echo "encrypt_key = no" >> $@
	@echo "prompt = no" >> $@
	@echo "utf8 = yes" >> $@
	@echo "default_md = sha256" >> $@
	@echo "default_bits = $(INTCA_KEYSZ)" >> $@
	@echo "req_extensions = req_ext" >> $@
	@echo "x509_extensions = x509_ext" >> $@
	@echo "distinguished_name = req_dn" >> $@
	@echo "[ req_ext ]" >> $@
	@echo "subjectKeyIdentifier = hash" >> $@
	@echo "basicConstraints = critical, CA:true, pathlen:0" >> $@
	@echo "keyUsage = critical, digitalSignature, nonRepudiation, keyEncipherment, keyCertSign" >> $@
	@echo "[ x509_ext ]" >> $@
	@echo "subjectKeyIdentifier = hash" >> $@
	@echo "authorityKeyIdentifier = keyid,issuer" >> $@
	@echo "basicConstraints = critical, CA:true, pathlen:0" >> $@
	@echo "keyUsage = critical, digitalSignature, nonRepudiation, keyEncipherment, keyCertSign" >> $@
	@echo "[ req_dn ]" >> $@
	@echo "C = $(INTCA_COUNTRY)" >> $@
	@echo "ST = $(INTCA_STATE)" >> $@
	@echo "L = $(INTCA_LOCATION)" >> $@
	@echo "O = $(INTCA_ORG)" >> $@
	@echo "OU = $(INTCA_ORGUNIT)" >> $@
	@echo "O = $(INTCA_ORG)" >> $@
	@echo "CN = Kong CX Intermediate CA - $*" >> $@

${INT_CA}/client-server/%/client-server.conf: L=$(dir $@)
${INT_CA}/client-server/%/client-server.conf:
	@echo "[ req ]" > $@
	@echo "encrypt_key = no" >> $@
	@echo "prompt = no" >> $@
	@echo "utf8 = yes" >> $@
	@echo "default_md = sha256" >> $@
	@echo "default_bits = $(INTCA_KEYSZ)" >> $@
	@echo "req_extensions = req_ext" >> $@
	@echo "x509_extensions = req_ext" >> $@
	@echo "distinguished_name = req_dn" >> $@
	@echo "[ req_ext ]" >> $@
	@echo "subjectKeyIdentifier = hash" >> $@
	@echo "basicConstraints = critical, CA:false" >> $@
	@echo "keyUsage = digitalSignature, keyEncipherment, keyAgreement" >> $@
ifeq ($(CS_PURPOSE), clientAndServer)
	@echo "extendedKeyUsage = serverAuth, clientAuth" >> $@;
else ifeq ($(CS_PURPOSE), client)
	@echo "extendedKeyUsage = clientAuth" >> $@;
else ifeq ($(CS_PURPOSE), server)
	@echo "extendedKeyUsage = serverAuth" >> $@;
endif
	@echo "subjectAltName=@san" >> $@
	@echo "[ san ]" >> $@
	$(eval counter=0)
	@$(foreach item,$(SANS), \
		$(eval counter=$(shell echo $$(( $(counter) + 1 )))) \
		echo "DNS.$(counter) = $(item)" >> $@ ;)
	@echo "[ req_dn ]" >> $@
	@echo "C = $(CS_COUNTRY)" >> $@
	@echo "ST = $(CS_STATE)" >> $@
	@echo "L = $(CS_LOCATION)" >> $@
	@echo "O = $(CS_ORG)" >> $@
	@echo "OU = $(CS_ORGUNIT)" >> $@
	@echo "CN = $*" >> $@